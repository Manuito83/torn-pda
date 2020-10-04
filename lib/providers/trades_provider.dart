import 'package:flutter/material.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/trades/torntrader/torntrader_in.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/external/torntrader_comm.dart';
import 'package:torn_pda/utils/html_parser.dart' as pdaParser;
import 'package:html/dom.dart' as dom;
import 'package:torn_pda/utils/shared_prefs.dart';

class TradesContainer {
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
  String ttUrl = "";
  bool ttServerError = false;
  bool ttAuthError = false;
  var ttItems = List<ttInItem>();
  var ttMessages = List<TradeMessage>();
}

class TradesProvider extends ChangeNotifier {
  int playerId;
  var container = TradesContainer();

  void updateTrades(
      {@required playerId,
      @required String userApiKey,
      @required String sellerName,
      @required int tradeId,
      @required List<dom.Element> leftMoneyElements,
      @required List<dom.Element> leftItemsElements,
      @required List<dom.Element> leftPropertyElements,
      @required List<dom.Element> leftSharesElements,
      @required List<dom.Element> rightMoneyElements,
      @required List<dom.Element> rightItemsElements,
      @required List<dom.Element> rightPropertyElements,
      @required List<dom.Element> rightSharesElements}) async {
    this.playerId = playerId;
    var newModel = TradesContainer();

    // Color 1 is money
    int colors1(List<dom.Element> sideMoneyElement) {
      var row = sideMoneyElement[0];
      RegExp regExp = new RegExp(r"([0-9][,]{0,3})+");
      try {
        var match = regExp.stringMatch(row.innerHtml);
        return int.parse(match.replaceAll(",", ""));
      } catch (e) {
        return 0;
      }
    }

    if (leftMoneyElements.length > 0) {
      newModel.leftMoney = colors1(leftMoneyElements);
    }

    if (rightMoneyElements.length > 0) {
      newModel.rightMoney = colors1(rightMoneyElements);
    }

    // Color 2 is general items
    void addColor2Items(dom.Element itemLine, ItemsModel allTornItems, List<TradeItem> sideItems) {
      var thisItem = TradeItem();
      var row = pdaParser.HtmlParser.fix(itemLine.innerHtml.trim());
      thisItem.name = row.split(" x")[0].trim();
      row.split(" x").length > 1
          ? thisItem.quantity = int.parse(row.split(" x")[1])
          : thisItem.quantity = 1;
      allTornItems.items.forEach((key, value) {
        if (thisItem.name == value.name) {
          thisItem.id = int.parse(key);
          thisItem.priceUnit = value.marketValue;
          thisItem.totalPrice = thisItem.priceUnit * thisItem.quantity;
        }
      });
      sideItems.add(thisItem);
    }

    if (leftItemsElements.length > 0 || rightItemsElements.length > 0) {
      var allTornItems;
      try {
        allTornItems = await TornApiCaller.items(userApiKey).getItems;
      } catch (e) {
        print(e);
      }

      if (allTornItems is ApiError) {
        return;
      } else if (allTornItems is ItemsModel) {
        // Loop left
        for (var itemLine in leftItemsElements) {
          addColor2Items(itemLine, allTornItems, newModel.leftItems);
        }
        // Loop right
        for (var itemLine in rightItemsElements) {
          addColor2Items(itemLine, allTornItems, newModel.rightItems);
        }

        // TORN TRADER init here (it only takes into account elements sold to us,
        // so we'll only pass this information
        var tornTraderActive = await SharedPreferencesModel().getTornTraderEnabled();
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
              ..ttTotalMoney = tornTraderIn.trade.tradeTotal.replaceAll(" ", "")
              ..ttProfit = tornTraderIn.trade.totalProfit.replaceAll(" ", "")
              ..ttUrl = tornTraderIn.trade.tradeUrl
              ..ttItems = tornTraderIn.trade.items
              ..ttMessages = tornTraderIn.trade.tradeMessages;
          }
        }
      }
    }

    // Color 3 is properties
    void addColor3Items(dom.Element propertyLine, List<TradeItem> sideProperty) {
      var thisProperty = TradeItem();
      var row = pdaParser.HtmlParser.fix(propertyLine.innerHtml.trim());
      thisProperty.name = row.split(" (")[0].trim();
      RegExp regExp = new RegExp(r"[0-9]+ happiness");
      try {
        var match = regExp.stringMatch(propertyLine.innerHtml);
        thisProperty.happiness = match.substring(0);
      } catch (e) {
        thisProperty.happiness = '';
      }
      sideProperty.add(thisProperty);
    }

    if (leftPropertyElements.length > 0 || rightPropertyElements.length > 0) {
      for (var propertyLine in leftPropertyElements) {
        addColor3Items(propertyLine, newModel.leftProperties);
      }
      for (var propertyLine in rightPropertyElements) {
        addColor3Items(propertyLine, newModel.rightProperties);
      }
    }

    // Color 4 is general items
    void addColor4Items(dom.Element shareLine, List<TradeItem> sideShares) {
      var thisShare = TradeItem();
      var row = pdaParser.HtmlParser.fix(shareLine.innerHtml.trim());
      thisShare.name = row.split(" x")[0].trim();

      try {
        RegExp regQuantity = new RegExp(
            r"([A-Z]{3}) (?:x)([0-9]+) (?:at) (?:\$)((?:[0-9]|[.]|[,])+) (?:\()(?:\$)((?:[0-9]|[,])+)");
        var matches = regQuantity.allMatches(shareLine.innerHtml);
        thisShare.name = matches.elementAt(0).group(1);
        thisShare.quantity = int.parse(matches.elementAt(0).group(2));
        var singlePriceSplit = matches.elementAt(0).group(3).split('.');
        thisShare.shareUnit = double.parse(singlePriceSplit[0].replaceAll(',', '')) +
            double.parse('0.${singlePriceSplit[1]}');
        thisShare.totalPrice = int.parse(matches.elementAt(0).group(4).replaceAll(',', ''));
      } catch (e) {
        thisShare.quantity = 0;
      }
      sideShares.add(thisShare);
    }

    if (leftSharesElements.length > 0 || rightSharesElements.length > 0) {
      for (var shareLine in leftSharesElements) {
        addColor4Items(shareLine, newModel.leftShares);
      }
      for (var shareLine in rightSharesElements) {
        addColor4Items(shareLine, newModel.rightShares);
      }
    }

    newModel.firstLoad = false;
    container = newModel;
    notifyListeners();
  }
}
