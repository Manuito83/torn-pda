import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ForeignStocksWebviewHandler {
  final InAppWebViewController? webViewController;
  final Function(bool) onTravelStatusChanged;
  final SettingsProvider settingsProvider;

  DateTime? _foreignStocksSentTime;

  ForeignStocksWebviewHandler({
    required this.webViewController,
    required this.onTravelStatusChanged,
    required this.settingsProvider,
  });

  int _parseCost(String text) {
    text = text.replaceAll('\$', '').trim().toLowerCase();
    double multiplier = 1;
    if (text.endsWith('m')) {
      multiplier = 1000000;
      text = text.substring(0, text.length - 1);
    } else if (text.endsWith('b')) {
      multiplier = 1000000000;
      text = text.substring(0, text.length - 1);
    } else if (text.endsWith('k')) {
      multiplier = 1000;
      text = text.substring(0, text.length - 1);
    }

    text = text.replaceAll(',', '');
    final value = double.tryParse(text) ?? 0;
    return (value * multiplier).toInt();
  }

  Future<void> assessTravel(dom.Document document) async {
    var abroad = document.querySelectorAll(".travel-home, .travel-home-header-button");
    if (abroad.isEmpty) {
      int attempts = 0;
      while (attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        final html = await webViewController?.getHtml();
        if (html != null) {
          document = parse(html);
          abroad = document.querySelectorAll(".travel-home, .travel-home-header-button");
          if (abroad.isNotEmpty) break;
        }
        attempts++;
      }
    }

    if (abroad.isNotEmpty) {
      _handleTravelUI();
      _sendStockInformation(document);
      onTravelStatusChanged(true);
    } else {
      onTravelStatusChanged(false);
    }
  }

  Future<void> _handleTravelUI() async {
    final shouldHideInfo = await Prefs().getRemoveForeignItemsDetails();
    final preventBasketKeyboard = await Prefs().getPreventBasketKeyboard();
    if (shouldHideInfo) {
      await webViewController?.evaluateJavascript(source: hideItemInfoJS());
    }
    await webViewController?.evaluateJavascript(source: buyMaxAbroadJS(preventBasketKeyboard: preventBasketKeyboard));
  }

  Future<void> _sendStockInformation(dom.Document document) async {
    // Find item elements
    var elements = <dom.Element>[];

    // Find wrappers
    var wrappers = document.querySelectorAll('div[class*="stockTableWrapper"]');
    for (var wrapper in wrappers) {
      // Find rows (divs with class row___)
      elements.addAll(wrapper.querySelectorAll('div[class*="row___"]'));
    }

    // Retry if empty as it might take additional time to load after [assessTravel] is called
    if (elements.isEmpty) {
      int attempts = 0;
      while (attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 250));
        final html = await webViewController?.getHtml();
        if (html != null) {
          document = parse(html);
          elements.clear();
          wrappers = document.querySelectorAll('div[class*="stockTableWrapper"]');
          for (var wrapper in wrappers) {
            elements.addAll(wrapper.querySelectorAll('div[class*="row___"]'));
          }
          if (elements.isNotEmpty) break;
        }
        attempts++;
      }
    }

    if (elements.isNotEmpty) {
      try {
        // Parse stocks
        final items = <ForeignStockOutItem>[];
        for (final el in elements) {
          int id = 0;
          int quantity = -1;
          int cost = 0;

          // ID
          final img = el.querySelector("img.torn-item");
          if (img != null) {
            final src = img.attributes['src'] ?? "";
            final match = RegExp(r'/items/(\d+)/').firstMatch(src);
            if (match != null) {
              id = int.tryParse(match.group(1)!) ?? 0;
            }
          }

          // Cost & Stock
          final spans = el.querySelectorAll("span");
          for (final span in spans) {
            final text = span.text.trim();
            // Cost
            if (text.contains('\$') && span.attributes['aria-hidden'] != 'true') {
              cost = _parseCost(text);
            }
            // Stock
            if (text.toLowerCase().contains('stock')) {
              final parent = span.parent;
              if (parent != null) {
                quantity = int.tryParse(parent.text.replaceAll(RegExp(r"[^0-9]"), "")) ?? 0;
              }
            }
          }

          if (quantity == -1) quantity = 0;

          if (id != 0 && cost != 0) {
            items.add(ForeignStockOutItem(id: id, quantity: quantity, cost: cost));
          }
        }

        // Country
        String country = "";
        final h4 = document.querySelector("[class*='titleContainer'] h4");
        if (h4 != null) {
          country = h4.text.trim().substring(0, 3).toLowerCase();
        } else {
          // Fallback
          final oldH4 = document.querySelector(".content-title > h4");
          if (oldH4 != null) {
            country = oldH4.text.trim().substring(0, 3).toLowerCase();
          }
        }

        final stockModel = ForeignStockOutModel(
          client: "Torn PDA",
          version: appVersion,
          authorName: "Manuito",
          authorId: 2225097,
          country: country,
          items: items,
        );

        if (kDebugMode) {
          await _printItemFoundFlutterSide(stockModel);
        }

        Future<void> sendToYATA() async {
          String error = "";
          try {
            final response = await http
                .post(
                  Uri.parse('https://yata.yt/api/v1/travel/import/'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: foreignStockOutModelToJson(stockModel),
                )
                .timeout(const Duration(seconds: 8));

            log("YATA replied with status code ${response.statusCode}. Response: ${response.body}");
            if (response.statusCode != 200) {
              error = "Replied with status code ${response.statusCode}. Response: ${response.body}";
            }
          } catch (e) {
            log('Error sending request to YATA: $e');
            error = "Catched exception: $e";
          }

          if (error.isNotEmpty) {
            if (!Platform.isWindows) FirebaseCrashlytics.instance.log("Error sending Foreign Stocks to YATA");
            if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(error, null);
            logToUser("Error sending Foreign Stocks to YATA");
          }
        }

        Future<void> sendToPrometheus() async {
          String error = "";
          try {
            final response = await http
                .post(
                  Uri.parse('https://api.prombot.co.uk/api/travel'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: foreignStockOutModelToJson(stockModel),
                )
                .timeout(const Duration(seconds: 8));

            log("Prometeus replied with status code ${response.statusCode}. Response: ${response.body}");
            if (response.statusCode != 200) {
              error = "Replied with status code ${response.statusCode}. Response: ${response.body}";
            }
          } catch (e) {
            log('Error sending request to Prometheus: $e');
            error = "Catched exception: $e";
          }

          if (error.isNotEmpty) {
            if (!Platform.isWindows) FirebaseCrashlytics.instance.log("Error sending Foreign Stocks to Prometheus");
            if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(error, null);
            logToUser("Error sending Foreign Stocks to Prometheus");
          }
        }

        if (stockModel.items.isEmpty) {
          log("Foreign stocks are empty!!");
          return;
        }

        // Avoid repetitive submissions
        if (_foreignStocksSentTime != null && (DateTime.now().difference(_foreignStocksSentTime!).inSeconds) < 3) {
          return;
        }
        _foreignStocksSentTime = DateTime.now();

        var futures = <Future>[];
        if (settingsProvider.yataUploadEnabledRemoteConfig) {
          futures.add(sendToYATA());
        }
        if (settingsProvider.prometheusUploadEnabledRemoteConfig) {
          futures.add(sendToPrometheus());
        }

        await Future.wait(futures);
      } catch (e) {
        // Error parsing
      }
    }
  }

  Future<void> _printItemFoundFlutterSide(ForeignStockOutModel stockModel) async {
    var logMsg = StringBuffer();
    logMsg.writeln('\n--------------------------------------------------');
    logMsg.writeln('SENDING TRAVEL DATA');
    logMsg.writeln('Country: ${stockModel.country}');
    logMsg.writeln('Client: ${stockModel.client} (v${stockModel.version})');
    logMsg.writeln('Author: ${stockModel.authorName} (${stockModel.authorId})');
    logMsg.writeln('--------------------------------------------------');

    Map<String, String> itemNames = {};
    try {
      var apiResult = await ApiCallsV1.getItems();
      if (apiResult is ItemsModel && apiResult.items != null) {
        for (var item in stockModel.items) {
          if (apiResult.items!.containsKey(item.id.toString())) {
            itemNames[item.id.toString()] = apiResult.items![item.id.toString()]!.name ?? "Unknown";
          }
        }
      }
    } catch (e) {
      log("Error fetching items for debug log: $e");
    }

    if (itemNames.isNotEmpty) {
      logMsg.writeln('${"ID".padRight(10)} | ${"Name".padRight(25)} | ${"Cost".padRight(15)} | Quantity');
      logMsg.writeln('--------------------------------------------------');
      for (var item in stockModel.items) {
        String name = itemNames[item.id.toString()] ?? "Unknown";
        if (name.length > 24) name = "${name.substring(0, 21)}...";
        logMsg.writeln(
            '${item.id.toString().padRight(10)} | ${name.padRight(25)} | ${item.cost.toString().padRight(15)} | ${item.quantity}');
      }
    } else {
      logMsg.writeln('${"ID".padRight(10)} | ${"Cost".padRight(15)} | Quantity');
      logMsg.writeln('--------------------------------------------------');
      for (var item in stockModel.items) {
        logMsg.writeln('${item.id.toString().padRight(10)} | ${item.cost.toString().padRight(15)} | ${item.quantity}');
      }
    }
    logMsg.writeln('--------------------------------------------------');
    log(logMsg.toString());
  }
}
