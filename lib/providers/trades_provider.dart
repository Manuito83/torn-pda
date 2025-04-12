import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;

import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_in.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_item.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
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
  List<TradeItem> rightOriginalItemsBeforeTornExchange = [];
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

// Lists of individual item names that make up each type of set.
// When TE says "Flower Set", we subtract one of each name below.
const List<String> flowerSetItems = [
  'Dahlia',
  'Orchid',
  'African Violet',
  'Cherry Blossom',
  'Peony',
  'Ceibo Flower',
  'Edelweiss',
  'Crocus',
  'Heather',
  'Tribulus Omanense',
  'Banana Orchid'
];

const List<String> plushieSetItems = [
  'Jaguar Plushie',
  'Lion Plushie',
  'Panda Plushie',
  'Monkey Plushie',
  'Chamois Plushie',
  'Wolverine Plushie',
  'Nessie Plushie',
  'Red Fox Plushie',
  'Camel Plushie',
  'Kitten Plushie',
  'Teddy Bear Plushie',
  'Sheep Plushie',
  'Stingray Plushie'
];

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

    // We parse the money amounts (left/right) from the DOM.
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

    // Helper to add general ("Color 2") items by parsing the DOM.
    // Cross-references the global items list to assign a market price.
    void addColor2Items(dom.Element itemLine, ItemsModel allTornItems, List<TradeItem> sideItems) {
      final thisItem = TradeItem();
      final row = pda_parser.HtmlParser.fix(itemLine.innerHtml.trim());
      thisItem.name = row.split(" x")[0].trim();
      row.split(" x").length > 1 ? thisItem.quantity = int.parse(row.split(" x")[1]) : thisItem.quantity = 1;

      // Attempt to find a marketValue in allTornItems.
      allTornItems.items!.forEach((key, value) {
        if (thisItem.name == value.name) {
          thisItem.id = int.parse(key);
          thisItem.marketPricePerUnit = value.marketValue ?? 0;
          thisItem.totalBuyPrice = thisItem.marketPricePerUnit * thisItem.quantity;
        }
      });
      sideItems.add(thisItem);
    }

    // If we have item elements, fetch and parse them.
    if (leftItemsElements.isNotEmpty || rightItemsElements.isNotEmpty) {
      dynamic allTornItems;
      try {
        allTornItems = await ApiCallsV1.getItems();
      } catch (e) {
        print(e);
      }

      if (allTornItems is ApiError) {
        return;
      } else if (allTornItems is ItemsModel) {
        // Parse items on the left.
        for (final itemLine in leftItemsElements) {
          addColor2Items(itemLine, allTornItems, tradesContainer.leftItems);
        }
        // Parse items on the right.
        for (final itemLine in rightItemsElements) {
          addColor2Items(itemLine, allTornItems, tradesContainer.rightItems);
        }

        // We need to save the original rightItems before applying the Torn Exchange
        // data so that we can send them unaltered to AWH
        tradesContainer.rightOriginalItemsBeforeTornExchange = tradesContainer.rightItems;

        // Check Arson Warehouse.
        tradesContainer.awhActive = await Prefs().getAWHEnabled();

        // If Torn Exchange is enabled, we integrate TE’s data.
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
            try {
              // TE might send items like ["African Violet", "Flower Set"] with prices & quantities.
              // We merge them into our existing rightItems, subtracting the relevant items if TE says there’s a set,
              // and preserving any leftover items that TE doesn’t mention.
              // This also ensures we keep original market prices for items that TE sets to zero.

              // Apply Torn Exchange data to our existing rightItems
              tradesContainer.rightItems = applyTornExchangeIn(
                tradesContainer.rightItems,
                tornExchangeIn,
              );

              // Calculate TE totals (prices and profit).
              int totalPrices = 0;
              int totalProfit = 0;
              for (int i = 0; i < tornExchangeIn.prices.length; i++) {
                totalPrices += tornExchangeIn.prices[i] * tornExchangeIn.quantities[i];
                totalProfit += tornExchangeIn.profitPerItem[i];
              }

              // Build a user-friendly list of TE items (only those with price > 0, if desired).
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
                    ..profit = tornExchangeIn.profitPerItem[i],
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

    // Parse property items (Color 3).
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

    // Parse share items (Color 4).
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
        thisShare.totalBuyPrice = int.parse(matches.elementAt(0).group(4)!.replaceAll(',', ''));
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

  /// applyTornExchangeIn merges Torn Exchange data with our existing item list.
  /// Torn Exchange can return both individual items (e.g., "African Violet") and set items (e.g., "Flower Set").
  /// If a set is found, we subtract one quantity from each of the individual items that form that set.
  /// Also, if TE provides a non-zero price, we use it; if it’s zero, we keep our original market price.
  /// This ensures that leftover items (not used in any set) remain visible with their original price.
  List<TradeItem> applyTornExchangeIn(
    List<TradeItem> originalItems,
    TornExchangeInModel tornExchangeIn,
  ) {
    // Clone the original list so we can modify quantities.
    List<TradeItem> tempItems = originalItems.map((item) {
      return TradeItem()
        ..id = item.id
        ..name = item.name
        ..quantity = item.quantity
        ..marketPricePerUnit = item.marketPricePerUnit
        ..totalBuyPrice = item.totalBuyPrice
        ..happiness = item.happiness;
    }).toList();

    // finalItems will contain:
    // 1) All items TE explicitly recognizes (sets or individual)
    // 2) The leftover items from tempItems that still have quantity > 0.
    List<TradeItem> finalItems = [];

    for (int i = 0; i < tornExchangeIn.items.length; i++) {
      final name = tornExchangeIn.items[i];
      final quantity = tornExchangeIn.quantities[i];
      final tePrice = tornExchangeIn.prices[i];

      // If TE indicates a Flower or Plushie Set, subtract those items.
      // If it’s a simple item name, subtract that specific name.
      if (name == 'Flower Set') {
        _subtractFromList(tempItems, flowerSetItems, quantity);
      } else if (name == 'Plushie Set') {
        _subtractFromList(tempItems, plushieSetItems, quantity);
      } else {
        _subtractFromList(tempItems, [name], quantity);
      }

      // Try to find a fallback price in tempItems if TE’s price is zero.
      int fallbackPrice = 0;
      final idxInTemp = tempItems.indexWhere((it) => it.name == name);
      if (idxInTemp != -1) {
        fallbackPrice = tempItems[idxInTemp].marketPricePerUnit;
      }

      // Build the recognized item for TE
      final recognizedItem = TradeItem()
        ..name = name
        ..quantity = quantity
        ..marketPricePerUnit = fallbackPrice
        ..totalBuyPrice = (tePrice != 0) ? tePrice * quantity : fallbackPrice * quantity;

      finalItems.add(recognizedItem);
    }

    // After subtracting the TE usage, add any leftover items.
    // If leftover quantity is > 0, we keep it with its original price.
    for (var leftover in tempItems) {
      if (leftover.quantity > 0) {
        finalItems.add(leftover);
      }
    }

    return finalItems;
  }

  /// Helper method that subtracts `quantityToSubtract` from items in `items`
  /// if their name is in `namesToFind`. We use this to handle sets or single items.
  void _subtractFromList(List<TradeItem> items, List<String> namesToFind, int quantityToSubtract) {
    for (String name in namesToFind) {
      final idx = items.indexWhere((it) => it.name == name);
      if (idx != -1) {
        final found = items[idx];
        if (found.quantity >= quantityToSubtract) {
          found.quantity -= quantityToSubtract;
        } else {
          found.quantity = 0;
        }
      }
    }
  }
}
