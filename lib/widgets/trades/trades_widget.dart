// Flutter imports:
import 'dart:convert';

import 'package:animations/animations.dart';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/trades/awh_out.dart';
// Project imports:
import 'package:torn_pda/models/trades/trade_price_provider.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/models/trades/trade_sync_item.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/trades/trades_receipt_widget.dart';
import 'package:torn_pda/widgets/webviews/webview_full_awh.dart';

class TradesWidget extends StatefulWidget {
  final ThemeProvider? themeProv;
  final InAppWebViewController? webView;

  const TradesWidget({
    required this.themeProv,
    required this.webView,
  });

  @override
  TradesWidgetState createState() => TradesWidgetState();
}

class TradesWidgetState extends State<TradesWidget> {
  static const ttColor = Color(0xffd186cf);

  final _scrollController = ScrollController();
  final _moneyFormat = NumberFormat("#,##0", "en_US");
  final _moneyDecimalFormat = NumberFormat("#,##0.##", "en_US");

  late TradesProvider _tradesProv;

  late bool _tradeSyncActive;
  late bool _tradeSyncProfitActive;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tradesProv = Provider.of<TradesProvider>(context);
    _tradeSyncActive = _tradesProv.container.tradePriceProviderActive;
    _tradeSyncProfitActive = _tradesProv.container.tradePriceProviderProfitActive;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ExpandablePanel(
        collapsed: Container(),
        theme: const ExpandableThemeData(
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: true,
          tapBodyToCollapse: true,
        ),
        header: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (!_tradesProv.container.awhActive)
                  const SizedBox(width: 90)
                else
                  SizedBox(width: 90, child: _awhContainer()),
                const Column(
                  children: [
                    Text(
                      'Trade Calculator',
                      style: TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      '(TAP TO EXPAND)',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                if (!_tradeSyncActive)
                  const SizedBox(width: 90)
                else
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _tradesProv.container.tradePriceProviderName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _tradeSyncColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_tradesProv.container.tradePriceProviderServerError)
                            Row(
                              children: [
                                const Text(
                                  'ERROR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: IconButton(
                                    padding: const EdgeInsets.all(0),
                                    iconSize: 20,
                                    onPressed: () {
                                      String errorString = "";
                                      if (_tradesProv.container.tradePriceProviderServerError) {
                                        errorString =
                                            'There was an error contacting ${_tradesProv.container.tradePriceProviderName}.\n\n'
                                            'Details: ${_tradesProv.container.tradePriceProviderServerErrorReason}';
                                      }
                                      BotToast.showText(
                                        text: errorString,
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        contentColor: Colors.orange[800]!,
                                        duration: const Duration(seconds: 5),
                                        contentPadding: const EdgeInsets.all(10),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.info_outline,
                                      size: 15,
                                      color: Colors.orange,
                                    ),
                                  ),
                                )
                              ],
                            )
                          else
                            const Text(
                              "SYNC'D",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                        ],
                      ),
                    ],
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(child: _headerTotals('left')),
                  Flexible(child: _headerTotals('right')),
                ],
              ),
            ),
          ],
        ),
        expanded: Column(
          children: [
            Center(
              child: Divider(
                color: Colors.grey,
                indent: MediaQuery.sizeOf(context).width / 4,
                endIndent: MediaQuery.sizeOf(context).width / 4,
              ),
            ),
            ConstrainedBox(
              constraints: _tradeSyncActive && (!_tradesProv.container.tradePriceProviderServerError)
                  ? BoxConstraints.loose(
                      Size.fromHeight(
                            MediaQuery.sizeOf(context).height - kToolbarHeight * 3 - AppBar().preferredSize.height,
                          ) /
                          3,
                    )
                  : BoxConstraints.loose(
                      Size.fromHeight(
                            MediaQuery.sizeOf(context).height - kToolbarHeight - AppBar().preferredSize.height,
                          ) /
                          3,
                    ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sideDetailed('left'),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: sideDetailed('right'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tradeSyncColor() {
    return _tradesProv.container.tradePriceProvider == TradePriceProvider.tornW3b ? const Color(0xff4dd0e1) : ttColor;
  }

  bool _isTradeSyncGroupingItem(String itemName) {
    return itemName == 'Flower Set' || itemName == 'Plushie Set';
  }

  List<String>? _tradeSyncGroupingComponents(String itemName) {
    if (itemName == 'Flower Set') {
      return flowerSetItems;
    }

    if (itemName == 'Plushie Set') {
      return plushieSetItems;
    }

    return null;
  }

  List<TradeSyncItem> _displayTradeSyncItems(List<TradeSyncItem> providerItems) {
    if (_tradesProv.container.tradePriceProvider != TradePriceProvider.tornW3b) {
      return providerItems;
    }

    final workingItems = providerItems
        .map(
          (item) => TradeSyncItem(
            itemId: item.itemId,
            name: item.name,
            quantity: item.quantity,
            price: item.price,
            totalPrice: item.totalPrice,
            providerProfit: item.providerProfit,
            hasProviderProfit: item.hasProviderProfit,
          ),
        )
        .toList();

    final groupedItems = <TradeSyncItem>[];

    void consumeSet(String setName, List<String> componentNames) {
      // Build as many complete sets as possible from the provider's individual
      // items, then leave any extra flowers/plushies as standalone leftovers
      final componentItems = <TradeSyncItem>[];
      for (final componentName in componentNames) {
        final index = workingItems.indexWhere(
          (item) => item.name == componentName && item.quantity > 0,
        );
        if (index == -1) {
          return;
        }

        componentItems.add(workingItems[index]);
      }

      final completeSets =
          componentItems.map((item) => item.quantity).reduce((value, element) => value < element ? value : element);

      if (completeSets <= 0) {
        return;
      }

      final setPrice = componentItems.fold<int>(0, (sum, item) => sum + item.price);

      groupedItems.add(
        TradeSyncItem(
          itemId: setName == 'Flower Set' ? flowerSetTradeSyncItemId : plushieSetTradeSyncItemId,
          name: setName,
          quantity: completeSets,
          price: setPrice,
          totalPrice: setPrice * completeSets,
        ),
      );

      for (final componentItem in componentItems) {
        componentItem.quantity -= completeSets;
        componentItem.totalPrice = componentItem.price * componentItem.quantity;
      }
    }

    consumeSet('Flower Set', flowerSetItems);
    consumeSet('Plushie Set', plushieSetItems);

    for (final item in workingItems) {
      if (item.quantity <= 0) {
        continue;
      }

      groupedItems.add(
        TradeSyncItem(
          itemId: item.itemId,
          name: item.name,
          quantity: item.quantity,
          price: item.price,
          totalPrice: item.price * item.quantity,
          providerProfit: item.providerProfit,
          hasProviderProfit: item.hasProviderProfit,
        ),
      );
    }

    return groupedItems;
  }

  int _marketProfitForTradeSyncItem(List<TradeItem> sideItems, TradeSyncItem tradeSyncProduct) {
    final groupingComponents = _tradeSyncGroupingComponents(tradeSyncProduct.name);
    if (groupingComponents != null) {
      final specialSetMarketPrice =
          _tradesProv.container.tradePriceProviderSpecialMarketPrices[tradeSyncProduct.itemId];
      if (specialSetMarketPrice != null && specialSetMarketPrice > 0) {
        return (specialSetMarketPrice * tradeSyncProduct.quantity) - tradeSyncProduct.totalPrice;
      }

      int marketTotal = 0;

      for (final componentName in groupingComponents) {
        final componentItem = sideItems.cast<TradeItem?>().firstWhere(
              (item) => item?.name == componentName,
              orElse: () => null,
            );

        if (componentItem == null) {
          return 0;
        }

        marketTotal += componentItem.marketPricePerUnit * tradeSyncProduct.quantity;
      }

      return marketTotal - tradeSyncProduct.totalPrice;
    }

    for (final marketItem in sideItems) {
      if (_providerItemMatchesTradeItem(marketItem, tradeSyncProduct)) {
        final matchedQuantity =
            tradeSyncProduct.quantity <= marketItem.quantity ? tradeSyncProduct.quantity : marketItem.quantity;
        return (marketItem.marketPricePerUnit - tradeSyncProduct.price) * matchedQuantity;
      }
    }

    return 0;
  }

  List<TradeItem> _consumeTradeSyncItemFromSideItems(List<TradeItem> sideItems, TradeSyncItem tradeSyncProduct) {
    final updatedItems = sideItems
        .map(
          (item) => TradeItem()
            ..id = item.id
            ..name = item.name
            ..quantity = item.quantity
            ..marketPricePerUnit = item.marketPricePerUnit
            ..totalBuyPrice = item.totalBuyPrice
            ..happiness = item.happiness
            ..shareUnit = item.shareUnit,
        )
        .toList();

    final groupingComponents = _tradeSyncGroupingComponents(tradeSyncProduct.name);
    if (groupingComponents != null) {
      for (final componentName in groupingComponents) {
        final index = updatedItems.indexWhere((item) => item.name == componentName);
        if (index == -1) {
          continue;
        }

        updatedItems[index].quantity -= tradeSyncProduct.quantity;
        updatedItems[index].totalBuyPrice = updatedItems[index].marketPricePerUnit * updatedItems[index].quantity;
      }

      updatedItems.removeWhere((item) => item.quantity <= 0);
      return updatedItems;
    }

    final index = updatedItems.indexWhere((item) => _providerItemMatchesTradeItem(item, tradeSyncProduct));
    if (index == -1) {
      return updatedItems;
    }

    updatedItems[index].quantity -= tradeSyncProduct.quantity;
    updatedItems[index].totalBuyPrice = updatedItems[index].marketPricePerUnit * updatedItems[index].quantity;
    updatedItems.removeWhere((item) => item.quantity <= 0);
    return updatedItems;
  }

  bool _providerItemMatchesTradeItem(TradeItem tradeItem, TradeSyncItem providerItem) {
    if (tradeItem.id > 0 && providerItem.itemId > 0) {
      return tradeItem.id == providerItem.itemId;
    }

    return tradeItem.name == providerItem.name;
  }

  bool _itemsNotConfiguredInTradeSync() {
    bool itemsNotConfigured = _tradesProv.container.tradePriceProviderWarningsNotFound.isNotEmpty ||
        _tradesProv.container.tradePriceProviderWarningsNotPriced.isNotEmpty;

    for (final sellerItem in _tradesProv.container.rightItems) {
      bool thisFound = false;
      for (final providerItem in _tradesProv.container.tradePriceProviderItems) {
        if (_providerItemMatchesTradeItem(sellerItem, providerItem)) {
          thisFound = true;
          break;
        }
      }

      if (!thisFound) {
        itemsNotConfigured = true;
        break;
      }
    }

    if (_tradesProv.container.rightMoney != 0 ||
        _tradesProv.container.rightProperties.isNotEmpty ||
        _tradesProv.container.rightShares.isNotEmpty) {
      itemsNotConfigured = true;
    }

    return itemsNotConfigured;
  }

  Widget _headerTotals(String side) {
    int total = 0;
    bool hasProperty = false;
    if (side == 'left') {
      total += _tradesProv.container.leftMoney;
      for (final item in _tradesProv.container.leftItems) {
        total += item.totalBuyPrice;
      }
      for (final share in _tradesProv.container.leftShares) {
        total += share.totalBuyPrice;
      }
      for (final property in _tradesProv.container.leftProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    } else {
      total += _tradesProv.container.rightMoney;
      for (final item in _tradesProv.container.rightOriginalItemsBeforeTornExchange) {
        total += item.totalBuyPrice;
      }
      for (final share in _tradesProv.container.rightShares) {
        total += share.totalBuyPrice;
      }
      for (final property in _tradesProv.container.rightProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    }

    Widget propertyIcon() {
      if (!hasProperty) {
        return const SizedBox.shrink();
      } else {
        return const Row(
          children: [
            SizedBox(width: 5),
            Text('(+', style: TextStyle(color: Colors.white)),
            Icon(
              MdiIcons.home,
              color: Colors.white,
              size: 14,
            ),
            Text(')', style: TextStyle(color: Colors.white)),
          ],
        );
      }
    }

    final Widget clipboardIcon = SizedBox(
      height: 23,
      width: 23,
      child: IconButton(
        padding: const EdgeInsets.all(0),
        iconSize: 23,
        onPressed: () {
          String amountCopied;
          if (_tradeSyncActive && !_tradesProv.container.tradePriceProviderServerError && side == 'right') {
            amountCopied = _tradesProv.container.tradePriceProviderTotalMoney.replaceAll("\$", "").replaceAll(",", "");
            amountCopied = _moneyFormat.format(int.parse(amountCopied));
          } else {
            amountCopied = _moneyFormat.format(total);
          }
          _copyToClipboard(amountCopied, "The trade amount of $amountCopied was copied to clipboard!");
        },
        icon: const Icon(
          Icons.content_copy,
          size: 23,
          color: Colors.grey,
        ),
      ),
    );

    // This prevents showing totals as 0 when the widget is first loaded with existing items
    if (_tradesProv.container.firstLoad) {
      return const SizedBox.shrink();
    }

    if (!_tradeSyncActive || (_tradeSyncActive && (_tradesProv.container.tradePriceProviderServerError))) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (side == 'left')
            Padding(padding: const EdgeInsets.only(right: 5), child: clipboardIcon)
          else
            const SizedBox.shrink(),
          Flexible(
            child: Text(
              '\$${_moneyFormat.format(total)}',
              textAlign: side == 'left' ? TextAlign.start : TextAlign.end,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          propertyIcon(),
          if (side == 'right')
            Padding(padding: const EdgeInsets.only(left: 5), child: clipboardIcon)
          else
            const SizedBox.shrink(),
        ],
      );
    } else {
      if (side == 'left') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.only(right: 5), child: clipboardIcon),
            Flexible(
              child: Text(
                '\$${_moneyFormat.format(total)}',
                textAlign: side == 'left' ? TextAlign.start : TextAlign.end,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            propertyIcon(),
          ],
        );
      } else {
        String tradeSyncTotalString = "";
        int tradeSyncTotalMoney = int.tryParse(_tradesProv.container.tradePriceProviderTotalMoney) ?? -1;
        if (tradeSyncTotalMoney != -1) {
          tradeSyncTotalString = _moneyFormat.format(tradeSyncTotalMoney);
        } else {
          tradeSyncTotalString = _tradesProv.container.tradePriceProviderTotalMoney;
        }

        String tradeSyncProfit = "";
        int? tradeSyncTotalProfit = int.tryParse(_tradesProv.container.tradePriceProviderProfit);
        if (tradeSyncTotalProfit != null) {
          tradeSyncProfit = _moneyFormat.format(tradeSyncTotalProfit);
        } else {
          tradeSyncProfit = _tradesProv.container.tradePriceProviderProfit;
        }

        final itemsNotConfiguredInTradeSync = _itemsNotConfiguredInTradeSync();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'LIST',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            color: itemsNotConfiguredInTradeSync ? Colors.orange : _tradeSyncColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 8),
                      ),
                      Text(
                        '\$$tradeSyncTotalString',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: itemsNotConfiguredInTradeSync ? Colors.orange : _tradeSyncColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (itemsNotConfiguredInTradeSync)
              const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.warning_amber_outlined, size: 16, color: Colors.orange),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'EXPAND TO SEE\nMISSING ITEMS',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '\$${_moneyFormat.format(total)} market price',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: total <= tradeSyncTotalMoney ? Colors.orange : Colors.green,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (_tradeSyncProfitActive)
              if (itemsNotConfiguredInTradeSync)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Cannot calculate profit!',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_tradesProv.container.tradePriceProviderSupportsProviderProfit)
                      Flexible(
                        child: Text(
                          '\$$tradeSyncProfit profit (${_tradesProv.container.tradePriceProvider.shortLabel})',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        '\$${_moneyFormat.format(total - int.parse(_tradesProv.container.tradePriceProviderTotalMoney))} '
                        'profit (market)',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 5),
            TradeReceiptRow(
              clipboardIcon: clipboardIcon,
              tradePriceProvider: _tradesProv.container.tradePriceProvider,
              providerName: _tradesProv.container.tradePriceProviderName,
              receiptRequest: _tradesProv.container.tradePriceProviderReceiptRequest,
              initialReceiptData: _tradesProv.container.tradePriceProviderReceiptData,
              onReceiptUpdated: _tradesProv.updateTradeSyncReceiptData,
            ),
          ],
        );
      }
    }
  }

  List<Widget> sideDetailed(String side) {
    final items = <Widget>[];
    int sideMoney = 0;
    var sideItems = <TradeItem>[];
    var sideProperties = <TradeItem>[];
    var sideShares = <TradeItem>[];
    bool noItemsFound = true;

    if (side == 'left') {
      sideMoney = _tradesProv.container.leftMoney;
      sideItems = _tradesProv.container.leftItems;
      sideProperties = _tradesProv.container.leftProperties;
      sideShares = _tradesProv.container.leftShares;
    } else {
      sideMoney = _tradesProv.container.rightMoney;
      sideItems = _tradesProv.container.rightItems;
      sideProperties = _tradesProv.container.rightProperties;
      sideShares = _tradesProv.container.rightShares;
    }

    if (_tradeSyncActive && side == 'right' && (!_tradesProv.container.tradePriceProviderServerError)) {
      final tradeSyncItems = _displayTradeSyncItems(_tradesProv.container.tradePriceProviderItems);

      int tradeSyncListedItems = 0;
      for (final tradeSyncProduct in tradeSyncItems) {
        if (tradeSyncProduct.price == 0) {
          continue;
        }

        if (tradeSyncListedItems == 0) {
          items.add(Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'PRICED ITEMS',
              style: TextStyle(color: _tradeSyncColor(), fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ));
          tradeSyncListedItems = 1;
        }

        String itemName = tradeSyncProduct.name;
        if (tradeSyncProduct.quantity > 1) {
          itemName += ' x${tradeSyncProduct.quantity}';
        }

        items.add(Text(itemName, style: TextStyle(color: _tradeSyncColor(), fontSize: 13)));

        final String itemPriceTotal = "\$${_moneyFormat.format(tradeSyncProduct.totalPrice)}";
        String itemPriceIndividual = "";
        if (tradeSyncProduct.quantity > 1) {
          itemPriceIndividual += '(@ \$${_moneyFormat.format(tradeSyncProduct.price)})';
        }

        String providerItemProfit = '\$${_moneyFormat.format(tradeSyncProduct.providerProfit)}';

        final int thisItemTotalMarketProfit = _marketProfitForTradeSyncItem(sideItems, tradeSyncProduct);
        String marketItemProfit = '\$${_moneyFormat.format(thisItemTotalMarketProfit)}';

        items.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      itemPriceTotal,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      itemPriceIndividual,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              if (_tradeSyncProfitActive &&
                  (tradeSyncProduct.hasProviderProfit ||
                      !_isTradeSyncGroupingItem(tradeSyncProduct.name) ||
                      _tradesProv.container.tradePriceProvider == TradePriceProvider.tornW3b))
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tradeSyncProduct.hasProviderProfit)
                      Flexible(
                        child: Text(
                          '$providerItemProfit profit (${_tradesProv.container.tradePriceProvider.shortLabel})',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (!_isTradeSyncGroupingItem(tradeSyncProduct.name) ||
                        _tradesProv.container.tradePriceProvider == TradePriceProvider.tornW3b)
                      Flexible(
                        child: Text(
                          '$marketItemProfit profit (market)',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );

        items.add(const SizedBox(height: 10));

        // We need to remove this product from the ones we have in the normal list,
        // so that only non-provider products remain there.
        sideItems = _consumeTradeSyncItemFromSideItems(sideItems, tradeSyncProduct);

        // If we only find TornExchange items, the standard item list will be empty
        // and a warning will show. We need to prevent it with this setting
        noItemsFound = false;
      }

      // If after comparing there are still items in sideItems, there are items not captured
      // by Torn Trades, so we'll give a warning
      if (sideItems.isNotEmpty ||
          _tradesProv.container.rightMoney != 0 ||
          _tradesProv.container.rightProperties.isNotEmpty ||
          _tradesProv.container.rightShares.isNotEmpty) {
        items.add(
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: SizedBox(
              width: 80,
              child: Divider(color: Colors.orange),
            ),
          ),
        );
        items.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  'ITEMS NOT CONFIGURED\nIN ${_tradesProv.container.tradePriceProviderName.toUpperCase()}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                  ),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.warning_amber_outlined, size: 16, color: Colors.orange),
            ],
          ),
        );

        // Recalculate remaining total
        int remainingTotal = 0;
        remainingTotal += _tradesProv.container.rightMoney;
        for (final rem in sideItems) {
          remainingTotal += rem.totalBuyPrice;
        }
        for (final sha in sideShares) {
          remainingTotal += sha.totalBuyPrice;
        }
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '(additional \$${_moneyFormat.format(remainingTotal)} market value)',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 10,
              ),
            ),
          ),
        );
      }
    }

    // Item name
    for (final item in sideItems) {
      String? itemName = item.name;
      if (itemName == 'No items in trade') {
        continue;
      } else {
        noItemsFound = false;
      }

      if (item.quantity > 1) {
        itemName += ' x${item.quantity}';
      }

      items.add(
        Text(
          itemName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      );

      // Item price
      String itemPrice = '\$${_moneyFormat.format(item.totalBuyPrice)}';
      if (item.quantity > 1) {
        itemPrice += ' (@ \$${_moneyFormat.format(item.marketPricePerUnit)})';
      }

      items.add(
        Text(
          itemPrice,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(const SizedBox(height: 10));
    }

    // CASH
    if (sideMoney > 0) {
      noItemsFound = false;
      items.add(
        Text(
          '\$${_moneyFormat.format(sideMoney)} in cash',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 13,
          ),
        ),
      );
      items.add(const SizedBox(height: 10));
    }

    // PROPERTIES
    for (final property in sideProperties) {
      String? propertyName = property.name;
      if (propertyName == 'No properties in trade') {
        continue;
      } else {
        noItemsFound = false;
      }

      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(MdiIcons.home, size: 18, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              propertyName,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

      items.add(
        Text(
          property.happiness,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(const SizedBox(height: 10));
    }

    // SHARES
    for (final share in sideShares) {
      String? shareName = share.name;
      if (shareName == 'No shares in trade') {
        continue;
      } else {
        noItemsFound = false;
      }

      if (share.quantity > 1) {
        shareName += ' x${share.quantity}';
      } else if (share.quantity == 1) {
        shareName += ' x1';
      }

      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(MdiIcons.chartTimelineVariant, size: 18, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              shareName,
              style: const TextStyle(
                color: Colors.pink,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

      // Share price
      String sharePrice = '\$${_moneyFormat.format(share.totalBuyPrice)}';
      if (share.quantity > 1) {
        sharePrice += ' (@ \$${_moneyDecimalFormat.format(share.shareUnit)})';
      }

      items.add(
        Text(
          sharePrice,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(const SizedBox(height: 10));
    }

    if (noItemsFound) {
      items.add(
        const Text(
          'No items found',
          style: TextStyle(color: Colors.orange, fontSize: 13),
        ),
      );
    }

    return items;
  }

  Future _copyToClipboard(String copy, String toast, {int seconds = 5}) async {
    if (copy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: copy));
      BotToast.showText(
        clickClose: true,
        text: toast,
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.green,
        duration: Duration(seconds: seconds),
        contentPadding: const EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        clickClose: true,
        text: "There was an error, no information copied!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red[800]!,
        duration: Duration(seconds: seconds),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  Widget _awhContainer() {
    var dark = "";
    if (widget.themeProv!.currentTheme == AppTheme.dark) {
      dark = "dark&";
    }

    final awhBaseUrl = "https://arsonwarehouse.com/pda?$dark&trade=";
    final awhContainer = ArsonWarehouseOut();

    final theirItems = <AwhItem>[];
    for (final item in _tradesProv.container.rightOriginalItemsBeforeTornExchange) {
      if (!item.name.contains("No items in trade")) {
        final awhItem = AwhItem()
          ..name = item.name
          ..quantity = item.quantity;
        theirItems.add(awhItem);
      }
    }

    final myItems = <AwhItem>[];
    for (final item in _tradesProv.container.leftItems) {
      if (!item.name.contains("No items in trade")) {
        final awhItem = AwhItem()
          ..name = item.name
          ..quantity = item.quantity;
        myItems.add(awhItem);
      }
    }

    awhContainer
      ..me = UserHelper.playerId
      ..them = _tradesProv.container.sellerName
      ..tradeId = _tradesProv.container.tradeId
      ..version = 1
      ..theirItems = theirItems
      ..myItems = myItems;

    final awhJson = arsonWarehouseOutToJson(awhContainer);
    final bytes = utf8.encode(awhJson);
    final jsonEncoded = base64.encode(bytes);
    final ticketURL = awhBaseUrl + jsonEncoded;

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 300),
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext context, VoidCallback _) {
        return WebViewFullAwh(
          customUrl: ticketURL,
          customTitle: "Arson Warehouse",
          awhMessageCallback: _backFromAwhWithMessage,
          sellerName: _tradesProv.container.sellerName,
          sellerId: _tradesProv.container.sellerId,
        );
      },
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return SizedBox(
          height: 30,
          width: 40,
          child: Center(
            child: Image.asset(
              'images/icons/awh_logo.png',
              width: 35,
              color: Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Future<void> _backFromAwhWithMessage() async {
    await widget.webView!.evaluateJavascript(source: "chat.r(${_tradesProv.container.sellerId})");
  }
}
