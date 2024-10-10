// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:html/dom.dart' as dom;

// Project imports:
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_in.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_item.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/external/torn_exchange_comm.dart';
import 'package:torn_pda/utils/html_parser.dart' as pda_parser;
import 'package:torn_pda/utils/shared_prefs.dart';

class TradesContainer {
  String sellerName = "";
  int sellerId = 0;
  int tradeId = 0;
  bool firstLoad = true;
  int leftMoney = 0;
  List<TradeItem> leftItems = [];
  List<TradeItem> leftProperties = [];
  List<TradeItem> leftShares = [];
  int rightMoney = 0;
  List<TradeItem> rightItems = [];
  List<TradeItem> rightProperties = [];
  List<TradeItem> rightShares = [];

  // Torn Exchange Config
  String tornExchangeBuyerName = "";
  int tornExchangeBuyerId = 0;
  bool tornExchangeActive = false;
  bool tornExchangeProfitActive = false;
  String tornExchangeTotalMoney = "";
  String tornExchangeProfit = "";
  bool tornExchangeServerError = false;
  String tornExchangeServerErrorReason = "";
  List<TornExchangeItem> tornExchangeItems = <TornExchangeItem>[];
  List<String> tornExchangeNames = [];
  List<int> tornExchangePrices = [];
  List<int> tornExchangeQuantities = [];

  // Arson Warehouse
  bool awhActive = false;
}

class TradesProvider extends ChangeNotifier {
  int? playerId;
  TradesContainer container = TradesContainer();

  Future<void> updateTrades({
    required int playerId,
    required String playerName,
    required String sellerName,
    required int sellerId,
    required int tradeId,
    required List<dom.Element> leftMoneyElements,
    required List<dom.Element> leftItemsElements,
    required List<dom.Element> leftPropertyElements,
    required List<dom.Element> leftSharesElements,
    required List<dom.Element> rightMoneyElements,
    required List<dom.Element> rightItemsElements,
    required List<dom.Element> rightPropertyElements,
    required List<dom.Element> rightSharesElements,
    required bool tornExchangeActiveRemoteConfig,
  }) async {
    this.playerId = playerId;

    final tradesContainer = TradesContainer()
      ..tradeId = tradeId
      ..sellerName = sellerName
      ..sellerId = sellerId;

    // Color 1 is money
    int colors1(List<dom.Element> sideMoneyElement) {
      final row = sideMoneyElement[0];
      final RegExp regExp = RegExp("([0-9][,]{0,3})+");
      try {
        final match = regExp.stringMatch(row.innerHtml)!;
        return int.parse(match.replaceAll(",", ""));
      } catch (e) {
        return 0;
      }
    }

    if (leftMoneyElements.isNotEmpty) {
      tradesContainer.leftMoney = colors1(leftMoneyElements);
    }

    if (rightMoneyElements.isNotEmpty) {
      tradesContainer.rightMoney = colors1(rightMoneyElements);
    }

    // Color 2 is general items
    void addColor2Items(dom.Element itemLine, ItemsModel allTornItems, List<TradeItem> sideItems) {
      final thisItem = TradeItem();
      final row = pda_parser.HtmlParser.fix(itemLine.innerHtml.trim());
      thisItem.name = row.split(" x")[0].trim();
      row.split(" x").length > 1 ? thisItem.quantity = int.parse(row.split(" x")[1]) : thisItem.quantity = 1;
      allTornItems.items!.forEach((key, value) {
        if (thisItem.name == value.name) {
          thisItem.id = int.parse(key);
          thisItem.priceUnit = value.marketValue ?? 0;
          thisItem.totalPrice = thisItem.priceUnit * thisItem.quantity;
        }
      });
      sideItems.add(thisItem);
    }

    if (leftItemsElements.isNotEmpty || rightItemsElements.isNotEmpty) {
      dynamic allTornItems;
      try {
        allTornItems = await Get.find<ApiCallerController>().getItems();
      } catch (e) {
        print(e);
      }

      if (allTornItems is ApiError) {
        return;
      } else if (allTornItems is ItemsModel) {
        // Loop left
        for (final itemLine in leftItemsElements) {
          addColor2Items(itemLine, allTornItems, tradesContainer.leftItems);
        }
        // Loop right
        for (final itemLine in rightItemsElements) {
          addColor2Items(itemLine, allTornItems, tradesContainer.rightItems);
        }

        // Initialize Arson Warehouse
        tradesContainer.awhActive = await Prefs().getAWHEnabled();

        // TORN EXCHANGE init here (it only takes into account elements sold to us, so we'll only pass this information
        var tornExchangeActive = await Prefs().getTornExchangeEnabled() && tornExchangeActiveRemoteConfig;
        var tornExchangeProfitActive = await Prefs().getTornExchangeProfitEnabled();
        if (rightItemsElements.isNotEmpty && tornExchangeActive) {
          TornExchangeInModel tornExchangeIn = await TornExchangeComm.submitItems(
            tradesContainer.rightItems,
            sellerName,
            tradeId,
            playerName,
          );

          if (tornExchangeIn.serverError) {
            tradesContainer
              ..tornExchangeActive = true
              ..tornExchangeProfitActive = tornExchangeProfitActive
              ..tornExchangeServerError = tornExchangeIn.serverError
              ..tornExchangeServerErrorReason = tornExchangeIn.serverErrorReason;
          } else {
            // We'll return an error like above if there's something wrong coming from Torn Exchange here
            try {
              int totalPrices = 0;
              for (int i = 0; i < tornExchangeIn.prices.length; i++) {
                totalPrices += tornExchangeIn.prices[i] * tornExchangeIn.quantities[i];
              }

              int totalProfit = 0;
              for (int i = 0; i < tornExchangeIn.prices.length; i++) {
                // Profit per items already comes multiplied from Torn Exchange
                totalProfit += tornExchangeIn.profitPerItem[i];
              }

              List<TornExchangeItem> tornExchangeItems = [];
              for (int i = 0; i < tornExchangeIn.items.length; i++) {
                // Skip items that have no price in Torn Exchange, so the user knows they are not included
                if (tornExchangeIn.prices[i] == 0) continue;

                tornExchangeItems.add(
                  TornExchangeItem()
                    ..name = tornExchangeIn.items[i]
                    ..quantity = tornExchangeIn.quantities[i]
                    ..price = tornExchangeIn.prices[i]
                    ..totalPrice = tornExchangeIn.prices[i] * tornExchangeIn.quantities[i]
                    ..profit = tornExchangeIn.profitPerItem[i], // Profits already come multiplied
                );
              }

              tradesContainer
                ..tornExchangeBuyerId = playerId
                ..tornExchangeBuyerName = playerName
                ..tornExchangeActive = true
                ..tornExchangeProfitActive = tornExchangeProfitActive
                ..tornExchangeTotalMoney = totalPrices.toString()
                ..tornExchangeProfit = totalProfit.toString()
                ..tornExchangeItems = tornExchangeItems
                ..tornExchangeNames = tornExchangeIn.items
                ..tornExchangeQuantities = tornExchangeIn.quantities
                ..tornExchangePrices = tornExchangeIn.prices;
            } catch (e) {
              tradesContainer
                ..tornExchangeActive = true
                ..tornExchangeProfitActive = tornExchangeProfitActive
                ..tornExchangeServerError = tornExchangeIn.serverError
                ..tornExchangeServerErrorReason = tornExchangeIn.serverErrorReason;
            }
          }
        }
      }
    }

    // Color 3 is properties
    void addColor3Items(dom.Element propertyLine, List<TradeItem> sideProperty) {
      final thisProperty = TradeItem();
      final row = pda_parser.HtmlParser.fix(propertyLine.innerHtml.trim());
      thisProperty.name = row.split(" (")[0].trim();
      final RegExp regExp = RegExp("[0-9]+ happiness");
      try {
        final match = regExp.stringMatch(propertyLine.innerHtml)!;
        thisProperty.happiness = match.substring(0);
      } catch (e) {
        thisProperty.happiness = '';
      }
      sideProperty.add(thisProperty);
    }

    if (leftPropertyElements.isNotEmpty || rightPropertyElements.isNotEmpty) {
      for (final propertyLine in leftPropertyElements) {
        addColor3Items(propertyLine, tradesContainer.leftProperties);
      }
      for (final propertyLine in rightPropertyElements) {
        addColor3Items(propertyLine, tradesContainer.rightProperties);
      }
    }

    // Color 4 is general items
    void addColor4Items(dom.Element shareLine, List<TradeItem> sideShares) {
      final thisShare = TradeItem();
      final row = pda_parser.HtmlParser.fix(shareLine.innerHtml.trim());
      thisShare.name = row.split(" x")[0].trim();

      try {
        final RegExp regQuantity =
            RegExp(r"([A-Z]{3}) (?:x)([0-9]+) (?:at) (?:\$)((?:[0-9]|[.]|[,])+) (?:\()(?:\$)((?:[0-9]|[,])+)");
        final matches = regQuantity.allMatches(shareLine.innerHtml);
        thisShare.name = matches.elementAt(0).group(1) ?? "?";
        thisShare.quantity = int.parse(matches.elementAt(0).group(2)!);
        final singlePriceSplit = matches.elementAt(0).group(3)!.split('.');
        thisShare.shareUnit =
            double.parse(singlePriceSplit[0].replaceAll(',', '')) + double.parse('0.${singlePriceSplit[1]}');
        thisShare.totalPrice = int.parse(matches.elementAt(0).group(4)!.replaceAll(',', ''));
      } catch (e) {
        thisShare.quantity = 0;
      }
      sideShares.add(thisShare);
    }

    if (leftSharesElements.isNotEmpty || rightSharesElements.isNotEmpty) {
      for (final shareLine in leftSharesElements) {
        addColor4Items(shareLine, tradesContainer.leftShares);
      }
      for (final shareLine in rightSharesElements) {
        addColor4Items(shareLine, tradesContainer.rightShares);
      }
    }

    tradesContainer.firstLoad = false;
    container = tradesContainer;
    notifyListeners();
  }
}
