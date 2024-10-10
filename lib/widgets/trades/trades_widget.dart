// Flutter imports:
import 'dart:convert';

import 'package:animations/animations.dart';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/trades/awh_out.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_receipt.dart';
// Project imports:
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/external/torn_exchange_comm.dart';
import 'package:torn_pda/widgets/webviews/webview_full_awh.dart';

class TradesWidget extends StatefulWidget {
  final ThemeProvider? themeProv;
  final UserDetailsProvider? userProv;
  final InAppWebViewController? webView;

  const TradesWidget({
    required this.themeProv,
    required this.userProv,
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

  late bool _tornExchangeActive;
  late bool _tornExchangeProfitActive;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tradesProv = Provider.of<TradesProvider>(context);
    _tornExchangeActive = _tradesProv.container.tornExchangeActive &&
        Provider.of<SettingsProvider>(context).tornExchangeEnabledStatusRemoteConfig;
    _tornExchangeProfitActive = _tradesProv.container.tornExchangeProfitActive;
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
                if (!_tornExchangeActive)
                  const SizedBox(width: 90)
                else
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'TORN EXCHANGE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xffd186cf),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_tradesProv.container.tornExchangeServerError)
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
                                      if (_tradesProv.container.tornExchangeServerError) {
                                        errorString = "There was an error contacting Torn Exchange.\n\n"
                                            "Details: ${_tradesProv.container.tornExchangeServerErrorReason}";
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
              // Take into account Torn Exchange to leave more or less space
              constraints: _tornExchangeActive && (!_tradesProv.container.tornExchangeServerError)
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

  Widget _headerTotals(String side) {
    int total = 0;
    bool hasProperty = false;
    if (side == 'left') {
      total += _tradesProv.container.leftMoney;
      for (final item in _tradesProv.container.leftItems) {
        total += item.totalPrice;
      }
      for (final share in _tradesProv.container.leftShares) {
        total += share.totalPrice;
      }
      for (final property in _tradesProv.container.leftProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    } else {
      total += _tradesProv.container.rightMoney;
      for (final item in _tradesProv.container.rightItems) {
        total += item.totalPrice;
      }
      for (final share in _tradesProv.container.rightShares) {
        total += share.totalPrice;
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
        return Row(
          children: [
            const SizedBox(width: 5),
            const Text('(+', style: TextStyle(color: Colors.white)),
            Icon(
              MdiIcons.home,
              color: Colors.white,
              size: 14,
            ),
            const Text(')', style: TextStyle(color: Colors.white)),
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
          // Also takes into account Torn Exchange Server error, in which case we copy the standard value below
          if (_tornExchangeActive && !_tradesProv.container.tornExchangeServerError && side == 'right') {
            amountCopied = _tradesProv.container.tornExchangeTotalMoney.replaceAll("\$", "").replaceAll(",", "");
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

    if (!_tornExchangeActive || (_tornExchangeActive && (_tradesProv.container.tornExchangeServerError))) {
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
        // Do out best to parse the Torn Exchange total money and add money formatting
        String tornExchangeTotal = "";
        int? tornExchangeTotalMoney = int.tryParse(_tradesProv.container.tornExchangeTotalMoney);
        if (tornExchangeTotalMoney != null) {
          tornExchangeTotal = _moneyFormat.format(tornExchangeTotalMoney);
        } else {
          tornExchangeTotal = _tradesProv.container.tornExchangeTotalMoney;
        }

        String tornExchangeProfit = "";
        int? tornExchangeTotalProfit = int.tryParse(_tradesProv.container.tornExchangeProfit);
        if (tornExchangeTotalProfit != null) {
          tornExchangeProfit = _moneyFormat.format(tornExchangeTotalProfit);
        } else {
          tornExchangeProfit = _tradesProv.container.tornExchangeProfit;
        }

        // Alert the user at the top that some items (or shared, properties and money) are not within the TE price
        bool itemsNotConfiguredInTornExchange = false;

        for (var sellerItem in _tradesProv.container.rightItems) {
          bool thisFound = false;
          for (final tornExchangeItem in _tradesProv.container.tornExchangeItems) {
            if (sellerItem.name == tornExchangeItem.name) {
              thisFound = true;
              break;
            }
          }

          if (!thisFound) {
            itemsNotConfiguredInTornExchange = true;
            break;
          }
        }

        if (_tradesProv.container.rightMoney != 0 ||
            _tradesProv.container.rightProperties.isNotEmpty ||
            _tradesProv.container.rightShares.isNotEmpty) {
          itemsNotConfiguredInTornExchange = true;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '\$$tornExchangeTotal',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: itemsNotConfiguredInTornExchange ? Colors.orange : ttColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (itemsNotConfiguredInTornExchange)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.warning_amber_outlined, size: 16, color: Colors.orange),
                      const SizedBox(width: 5),
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
                  const SizedBox(height: 5),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '\$${_moneyFormat.format(total)} market price',
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
            if (_tornExchangeProfitActive)
              if (itemsNotConfiguredInTornExchange)
                Row(
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
                    Flexible(
                      child: Text(
                        '\$$tornExchangeProfit profit (TE)',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '\$${_moneyFormat.format(total - int.parse(_tradesProv.container.tornExchangeTotalMoney))} '
                        'profit (market)',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: const EdgeInsets.only(right: 10), child: clipboardIcon),
                SizedBox(
                  height: 23,
                  width: 23,
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    iconSize: 23,
                    onPressed: () async {
                      // Build trade receipt model
                      final receiptOut = TornExchangeReceiptOutModel(
                        ownerUserId: _tradesProv.container.tornExchangeBuyerId,
                        ownerUsername: _tradesProv.container.tornExchangeBuyerName,
                        sellerUsername: _tradesProv.container.sellerName,
                        prices: _tradesProv.container.tornExchangePrices,
                        itemQuantities: _tradesProv.container.tornExchangeQuantities,
                        itemNames: _tradesProv.container.tornExchangeNames,
                      );

                      final receipt = await TornExchangeComm.getReceipt(receiptOut);

                      if (receipt.serverError) {
                        BotToast.showText(
                          text: "There was an error getting your receipt, no information copied!",
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.red[800]!,
                          duration: const Duration(seconds: 5),
                          contentPadding: const EdgeInsets.all(10),
                        );
                      } else {
                        String message = receipt.tradeMessage;
                        int secondsToShow = 5;
                        if (message.isEmpty) {
                          message = "Thanks for the trade! Your receipt is available at "
                              "https://www.tornexchange.com/receipt/${receipt.receiptId}\n\n"
                              "Note: this is a default receipt template, you can create your own in Torn Exchange";
                          secondsToShow = 8;
                        }

                        _copyToClipboard(message, "Receipt copied to clipboard:\n\n$message", seconds: secondsToShow);
                      }
                    },
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      size: 23,
                      color: ttColor,
                    ),
                  ),
                ),
              ],
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

    // Torn Trades appears before rest of items
    if (_tornExchangeActive && side == 'right' && (!_tradesProv.container.tornExchangeServerError)) {
      final tornExchangeItems = _tradesProv.container.tornExchangeItems;

      for (final tornExchangeProduct in tornExchangeItems) {
        if (tornExchangeProduct.price == 0) {
          continue;
        }

        String itemName = tornExchangeProduct.name;
        if (tornExchangeProduct.quantity > 1) {
          itemName += ' x${tornExchangeProduct.quantity}';
        }

        items.add(Text(itemName, style: const TextStyle(color: ttColor, fontSize: 13)));

        // Item price
        final String itemPriceTotal = "\$${_moneyFormat.format(tornExchangeProduct.totalPrice)}";
        String itemPriceIndividual = "";
        if (tornExchangeProduct.quantity > 1) {
          itemPriceIndividual += '(@ \$${_moneyFormat.format(tornExchangeProduct.price)})';
        }

        // Torn Exchange profit
        String tornExchangeItemProfit = '\$${_moneyFormat.format(tornExchangeProduct.profit)}';

        // Market profit
        int thisItemTotalMarketProfit = 0;
        for (var marketItem in sideItems) {
          if (marketItem.name == tornExchangeProduct.name) {
            int thisItemMarketPrice = marketItem.priceUnit;
            int thisItemMarketQuantity = marketItem.quantity;
            thisItemTotalMarketProfit = (thisItemMarketPrice - tornExchangeProduct.price) * thisItemMarketQuantity;
            break;
          }
        }
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
              if (_tornExchangeProfitActive)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        '$tornExchangeItemProfit profit (TE)',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '$marketItemProfit profit (market)',
                        textAlign: TextAlign.end,
                        style: TextStyle(
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
        // so that only non-TornExchange products remain there
        final newSideItemList = List<TradeItem>.from(sideItems);
        for (final standardItem in sideItems) {
          if (standardItem.name == tornExchangeProduct.name) {
            newSideItemList.remove(standardItem);
          }
        }
        sideItems = List<TradeItem>.from(newSideItemList);

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  'ITEMS NOT CONFIGURED\nIN TORN EXCHANGE',
                  textAlign: TextAlign.end,
                  style: TextStyle(
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
          remainingTotal += rem.totalPrice;
        }
        for (final sha in sideShares) {
          remainingTotal += sha.totalPrice;
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
      String itemPrice = '\$${_moneyFormat.format(item.totalPrice)}';
      if (item.quantity > 1) {
        itemPrice += ' (@ \$${_moneyFormat.format(item.priceUnit)})';
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
            Icon(MdiIcons.home, size: 18, color: Colors.white),
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
            Icon(MdiIcons.chartTimelineVariant, size: 18, color: Colors.white),
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
      String sharePrice = '\$${_moneyFormat.format(share.totalPrice)}';
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
    for (final item in _tradesProv.container.rightItems) {
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
      ..me = widget.userProv!.basic!.playerId
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
      transitionDuration: const Duration(seconds: 1),
      transitionType: ContainerTransitionType.fadeThrough,
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
