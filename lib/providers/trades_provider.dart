// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:html/dom.dart' as dom;

// Project imports:
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/trades/torntrader/torntrader_in.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
//import 'package:torn_pda/utils/external/torntrader_comm.dart';
import 'package:torn_pda/utils/html_parser.dart' as pdaParser;
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

  // TornTradesConfig
  bool ttActive = false;
  String ttTotalMoney = "";
  String ttProfit = "";
  String? ttUrl = "";
  bool ttServerError = false;
  bool ttAuthError = false;
  List<TtInItem>? ttItems = <TtInItem>[];
  List<TradeMessage>? ttMessages = <TradeMessage>[];

  // Arson Warehouse
  bool awhActive = false;
}

class TradesProvider extends ChangeNotifier {
  int? playerId;
  TradesContainer container = TradesContainer();

  Future<void> updateTrades({
    required int playerId,
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
  }) async {
    this.playerId = playerId;

    final newModel = TradesContainer()
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
      newModel.leftMoney = colors1(leftMoneyElements);
    }

    if (rightMoneyElements.isNotEmpty) {
      newModel.rightMoney = colors1(rightMoneyElements);
    }

    // Color 2 is general items
    void addColor2Items(dom.Element itemLine, ItemsModel allTornItems, List<TradeItem> sideItems) {
      final thisItem = TradeItem();
      final row = pdaParser.HtmlParser.fix(itemLine.innerHtml.trim());
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
      var allTornItems;
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
          addColor2Items(itemLine, allTornItems, newModel.leftItems);
        }
        // Loop right
        for (final itemLine in rightItemsElements) {
          addColor2Items(itemLine, allTornItems, newModel.rightItems);
        }

        // Initialize Arson Warehouse
        newModel.awhActive = await Prefs().getAWHEnabled();

        // TORN TRADER init here (it only takes into account elements sold to us,
        // so we'll only pass this information
        /*
        var tornTraderActive = false; //await Prefs().getTornTraderEnabled();
        if (rightItemsElements.isNotEmpty && tornTraderActive) {
          TornTraderInModel tornTraderIn = await TornTraderComm.submitItems(
            newModel.rightItems,
            sellerName,
            tradeId,
            playerId,
          );

          if (tornTraderIn.serverError || tornTraderIn.authError) {
            newModel
              ..ttActive = true
              ..ttServerError = tornTraderIn.serverError
              ..ttAuthError = tornTraderIn.authError;
          } else {
            newModel
              ..ttActive = true
              ..ttTotalMoney = tornTraderIn.trade!.tradeTotal!.replaceAll(" ", "")
              ..ttProfit = tornTraderIn.trade!.totalProfit!.replaceAll(" ", "")
              ..ttUrl = tornTraderIn.trade!.tradeUrl
              ..ttItems = tornTraderIn.trade!.items
              ..ttMessages = tornTraderIn.trade!.tradeMessages;
          }
        }
        */
      }
    }

    // Color 3 is properties
    void addColor3Items(dom.Element propertyLine, List<TradeItem> sideProperty) {
      final thisProperty = TradeItem();
      final row = pdaParser.HtmlParser.fix(propertyLine.innerHtml.trim());
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
        addColor3Items(propertyLine, newModel.leftProperties);
      }
      for (final propertyLine in rightPropertyElements) {
        addColor3Items(propertyLine, newModel.rightProperties);
      }
    }

    // Color 4 is general items
    void addColor4Items(dom.Element shareLine, List<TradeItem> sideShares) {
      final thisShare = TradeItem();
      final row = pdaParser.HtmlParser.fix(shareLine.innerHtml.trim());
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
        addColor4Items(shareLine, newModel.leftShares);
      }
      for (final shareLine in rightSharesElements) {
        addColor4Items(shareLine, newModel.rightShares);
      }
    }

    newModel.firstLoad = false;
    container = newModel;
    notifyListeners();
  }
}
