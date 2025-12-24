import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TravelHandler {
  final InAppWebViewController? webViewController;
  final Function(bool) onTravelStatusChanged;

  DateTime? _foreignStocksSentTime;

  TravelHandler({
    required this.webViewController,
    required this.onTravelStatusChanged,
  });

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
              cost = int.tryParse(text.replaceAll(RegExp(r"[^0-9]"), "")) ?? 0;
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

        await Future.wait([
          sendToYATA(),
          sendToPrometheus(),
        ]);
      } catch (e) {
        // Error parsing
      }
    }
  }
}
