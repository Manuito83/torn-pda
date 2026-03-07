import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;

import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/trades/trade_price_provider.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_in.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_item.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/models/trades/trade_sync_item.dart';
import 'package:torn_pda/models/trades/torn_w3b/torn_w3b_receipt.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/utils/external/torn_exchange_comm.dart';
import 'package:torn_pda/utils/external/torn_w3b_comm.dart';
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

  // Active trade sync provider
  TradePriceProvider tradePriceProvider = TradePriceProvider.none;
  String tradePriceProviderName = "";
  bool tradePriceProviderActive = false;
  bool tradePriceProviderProfitActive = false;
  bool tradePriceProviderSupportsProviderProfit = false;
  String tradePriceProviderTotalMoney = "";
  String tradePriceProviderProfit = "";
  bool tradePriceProviderServerError = false;
  String tradePriceProviderServerErrorReason = "";
  List<TradeSyncItem> tradePriceProviderItems = <TradeSyncItem>[];
  List<String> tradePriceProviderWarningsNotFound = <String>[];
  List<String> tradePriceProviderWarningsNotPriced = <String>[];
  Map<int, int> tradePriceProviderSpecialMarketPrices = <int, int>{};
  TradeSyncReceiptRequest? tradePriceProviderReceiptRequest;
  TradeSyncReceiptData? tradePriceProviderReceiptData;

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

const int flowerSetTradeSyncItemId = -1;
const int plushieSetTradeSyncItemId = -2;

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

  void updateTradeSyncReceiptData(TradeSyncReceiptData receiptData) {
    container
      ..tradePriceProviderReceiptData = receiptData
      ..tradePriceProviderTotalMoney = receiptData.totalValue.toString()
      ..tradePriceProviderItems = receiptData.items;

    notifyListeners();
  }

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

        // Check Arson Warehouse (disabled).
        // tradesContainer.awhActive = await Prefs().getAWHEnabled();

        final selectedProvider = await Prefs().getTradePriceProvider();
        final tornExchangeActive =
            selectedProvider == TradePriceProvider.tornExchange && tornExchangeActiveRemoteConfig;
        final tornW3bActive = selectedProvider == TradePriceProvider.tornW3b;
        final tornExchangeProfitActive = await Prefs().getTornExchangeProfitEnabled();

        if (rightItemsElements.isNotEmpty) {
          if (tornExchangeActive) {
            await _populateTornExchangeData(
              tradesContainer: tradesContainer,
              playerId: playerId,
              playerName: playerName,
              sellerName: sellerName,
              tradeId: tradeId,
              tornExchangeProfitActive: tornExchangeProfitActive,
            );
          } else if (tornW3bActive) {
            await _populateTornW3bData(
              tradesContainer: tradesContainer,
              playerId: playerId,
              playerName: playerName,
              sellerName: sellerName,
              tradeId: tradeId,
              tornExchangeProfitActive: tornExchangeProfitActive,
            );
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

  Future<void> _populateTornExchangeData({
    required TradesContainer tradesContainer,
    required int playerId,
    required String playerName,
    required String sellerName,
    required int tradeId,
    required bool tornExchangeProfitActive,
  }) async {
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

      _setActiveTradeSyncError(
        tradesContainer,
        provider: TradePriceProvider.tornExchange,
        profitActive: tornExchangeProfitActive,
        errorReason: tornExchangeIn.serverErrorReason,
      );
      return;
    }

    try {
      tradesContainer.rightItems = applyTornExchangeIn(
        tradesContainer.rightItems,
        tornExchangeIn,
      );

      int totalPrices = 0;
      int totalProfit = 0;
      for (int i = 0; i < tornExchangeIn.prices.length; i++) {
        totalPrices += tornExchangeIn.prices[i] * tornExchangeIn.quantities[i];
        totalProfit += tornExchangeIn.profitPerItem[i];
      }

      List<TornExchangeItem> tornExchangeItems = [];
      List<TradeSyncItem> tradeSyncItems = [];
      for (int i = 0; i < tornExchangeIn.items.length; i++) {
        if (tornExchangeIn.prices[i] == 0) continue;

        tornExchangeItems.add(
          TornExchangeItem()
            ..name = tornExchangeIn.items[i]
            ..quantity = tornExchangeIn.quantities[i]
            ..price = tornExchangeIn.prices[i]
            ..totalPrice = tornExchangeIn.prices[i] * tornExchangeIn.quantities[i]
            ..profit = tornExchangeIn.profitPerItem[i],
        );

        tradeSyncItems.add(
          TradeSyncItem(
            name: tornExchangeIn.items[i],
            quantity: tornExchangeIn.quantities[i],
            price: tornExchangeIn.prices[i],
            totalPrice: tornExchangeIn.prices[i] * tornExchangeIn.quantities[i],
            providerProfit: tornExchangeIn.profitPerItem[i],
            hasProviderProfit: true,
          ),
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

      tradesContainer
        ..tradePriceProvider = TradePriceProvider.tornExchange
        ..tradePriceProviderName = TradePriceProvider.tornExchange.label
        ..tradePriceProviderActive = true
        ..tradePriceProviderProfitActive = tornExchangeProfitActive
        ..tradePriceProviderSupportsProviderProfit = true
        ..tradePriceProviderTotalMoney = totalPrices.toString()
        ..tradePriceProviderProfit = totalProfit.toString()
        ..tradePriceProviderServerError = false
        ..tradePriceProviderServerErrorReason = ''
        ..tradePriceProviderItems = tradeSyncItems
        ..tradePriceProviderWarningsNotFound = []
        ..tradePriceProviderWarningsNotPriced = []
        ..tradePriceProviderReceiptData = null
        ..tradePriceProviderReceiptRequest = TradeSyncReceiptRequest(
          ownerUserId: playerId,
          ownerUsername: playerName,
          sellerUserId: tradesContainer.sellerId,
          sellerUsername: sellerName,
          tradeId: tradeId,
          items: List<TradeSyncReceiptRequestItem>.generate(
            tornExchangeIn.items.length,
            (index) => TradeSyncReceiptRequestItem(
              name: tornExchangeIn.items[index],
              quantity: tornExchangeIn.quantities[index],
              price: tornExchangeIn.prices[index],
            ),
          ),
        );
    } catch (e) {
      tradesContainer
        ..tornExchangeActive = true
        ..tornExchangeProfitActive = tornExchangeProfitActive
        ..tornExchangeServerError = tornExchangeIn.serverError
        ..tornExchangeServerErrorReason = tornExchangeIn.serverErrorReason;

      _setActiveTradeSyncError(
        tradesContainer,
        provider: TradePriceProvider.tornExchange,
        profitActive: tornExchangeProfitActive,
        errorReason: tornExchangeIn.serverErrorReason,
      );
    }
  }

  Future<void> _populateTornW3bData({
    required TradesContainer tradesContainer,
    required int playerId,
    required String playerName,
    required String sellerName,
    required int tradeId,
    required bool tornExchangeProfitActive,
  }) async {
    final request = TradeSyncReceiptRequest(
      ownerUserId: playerId,
      ownerUsername: playerName,
      sellerUserId: tradesContainer.sellerId,
      sellerUsername: sellerName,
      tradeId: tradeId,
      items: tradesContainer.rightItems
          .map(
            (item) => TradeSyncReceiptRequestItem(
              itemId: item.id,
              name: item.name,
              quantity: item.quantity,
            ),
          )
          .toList(),
    );

    try {
      Map<int, int> marketplacePrices = {};
      try {
        marketplacePrices = await TornW3bComm.getMarketplacePrices();
      } catch (_) {}

      if (marketplacePrices.isNotEmpty) {
        _applyW3bMarketplacePrices(tradesContainer.rightItems, marketplacePrices);
        _applyW3bMarketplacePrices(tradesContainer.rightOriginalItemsBeforeTornExchange, marketplacePrices);
      }

      final response = await TornW3bComm.generateReceipt(
        playerId,
        TornW3bReceiptRequest(
          items: request.items
              .map(
                (item) => TornW3bReceiptRequestItem(
                  itemId: item.itemId > 0 ? item.itemId : null,
                  name: item.itemId > 0 ? null : item.name,
                  quantity: item.quantity,
                ),
              )
              .toList(),
          username: playerName,
          tradeId: tradeId,
          includeMessage: true,
        ),
      );

      final tradeSyncItems = _buildW3bTradeSyncItems(
        response.receipt.items,
        request.items,
      );

      final receiptId = _receiptIdFromUrl(response.receiptUrl);
      final receiptMessage = _defaultReceiptMessage(
        providerName: TradePriceProvider.tornW3b.label,
        receiptUrl: response.receiptUrl,
      );

      tradesContainer
        ..tradePriceProvider = TradePriceProvider.tornW3b
        ..tradePriceProviderName = TradePriceProvider.tornW3b.label
        ..tradePriceProviderActive = true
        ..tradePriceProviderProfitActive = tornExchangeProfitActive
        ..tradePriceProviderSupportsProviderProfit = false
        ..tradePriceProviderTotalMoney = response.receipt.totalValue.toString()
        ..tradePriceProviderProfit = ''
        ..tradePriceProviderServerError = false
        ..tradePriceProviderServerErrorReason = ''
        ..tradePriceProviderItems = tradeSyncItems
        ..tradePriceProviderWarningsNotFound = response.warnings.notFound
        ..tradePriceProviderWarningsNotPriced = response.warnings.notPriced
        ..tradePriceProviderSpecialMarketPrices = {
          for (final entry in marketplacePrices.entries)
            if (entry.key < 0) entry.key: entry.value,
        }
        ..tradePriceProviderReceiptRequest = request
        ..tradePriceProviderReceiptData = TradeSyncReceiptData(
          receiptId: receiptId,
          message: receiptMessage,
          url: response.receiptUrl,
          totalValue: response.receipt.totalValue,
          canEdit: true,
          items: tradeSyncItems,
        );
    } catch (e) {
      _setActiveTradeSyncError(
        tradesContainer,
        provider: TradePriceProvider.tornW3b,
        profitActive: tornExchangeProfitActive,
        errorReason: e.toString(),
      );
    }
  }

  void _applyW3bMarketplacePrices(List<TradeItem> items, Map<int, int> marketplacePrices) {
    for (final item in items) {
      if (item.id <= 0) {
        continue;
      }

      final marketPrice = marketplacePrices[item.id];
      if (marketPrice == null || marketPrice <= 0) {
        continue;
      }

      item.marketPricePerUnit = marketPrice;
      item.totalBuyPrice = marketPrice * item.quantity;
    }
  }

  List<TradeSyncItem> _buildW3bTradeSyncItems(
    List<TornW3bReceiptResponseItem> responseItems,
    List<TradeSyncReceiptRequestItem> requestItems,
  ) {
    final tradeSyncItems = <TradeSyncItem>[];

    for (int index = 0; index < responseItems.length; index++) {
      final responseItem = responseItems[index];
      final requestItem = index < requestItems.length ? requestItems[index] : null;

      final itemId = responseItem.itemId > 0 ? responseItem.itemId : (requestItem?.itemId ?? 0);
      final quantity = responseItem.quantity > 0 ? responseItem.quantity : (requestItem?.quantity ?? 0);
      final totalPrice = responseItem.totalValue;
      final resolvedPrice = responseItem.priceUsed > 0
          ? responseItem.priceUsed
          : (quantity > 0 && totalPrice > 0)
              ? (totalPrice / quantity).round()
              : 0;

      tradeSyncItems.add(
        TradeSyncItem(
          itemId: itemId,
          name: responseItem.name.isNotEmpty ? responseItem.name : (requestItem?.name ?? ''),
          quantity: quantity,
          price: resolvedPrice,
          totalPrice: totalPrice > 0 ? totalPrice : resolvedPrice * quantity,
        ),
      );
    }

    return tradeSyncItems;
  }

  void _setActiveTradeSyncError(
    TradesContainer tradesContainer, {
    required TradePriceProvider provider,
    required bool profitActive,
    required String errorReason,
  }) {
    tradesContainer
      ..tradePriceProvider = provider
      ..tradePriceProviderName = provider.label
      ..tradePriceProviderActive = true
      ..tradePriceProviderProfitActive = profitActive
      ..tradePriceProviderSupportsProviderProfit = provider.supportsProviderProfit
      ..tradePriceProviderServerError = true
      ..tradePriceProviderServerErrorReason = errorReason
      ..tradePriceProviderItems = []
      ..tradePriceProviderWarningsNotFound = []
      ..tradePriceProviderWarningsNotPriced = []
      ..tradePriceProviderReceiptRequest = null
      ..tradePriceProviderReceiptData = null;
  }

  String _receiptIdFromUrl(String url) {
    final parsed = Uri.tryParse(url);

    if (parsed == null || parsed.pathSegments.isEmpty) {
      return '';
    }

    return parsed.pathSegments.last;
  }

  String _defaultReceiptMessage({
    required String providerName,
    required String receiptUrl,
  }) {
    return 'Thanks for the trade! Your $providerName receipt is available at $receiptUrl';
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
