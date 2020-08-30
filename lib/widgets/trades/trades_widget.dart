import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';

class TradesWidget extends StatefulWidget {
  @override
  _TradesWidgetState createState() => _TradesWidgetState();
}

class _TradesWidgetState extends State<TradesWidget> {
  final _scrollController = ScrollController();
  final _moneyFormat = new NumberFormat("#,##0", "en_US");
  final _moneyDecimalFormat = new NumberFormat("#,##0.##", "en_US");

  TradesProvider _tradesProv;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tradesProv = Provider.of<TradesProvider>(context, listen: true);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: true,
          tapBodyToCollapse: true,
        ),
        header: Column(
          children: <Widget>[
            if (!_tradesProv.container.ttActive)
              Text(
                'Trade Calculator',
                style: TextStyle(
                  color: Colors.orange,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(width: 80),
                  Text(
                    'Trade Calculator',
                    style: TextStyle(
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 5),
                          child: Image(
                            image: AssetImage('images/icons/torntrader_logo.png'),
                            width: 16,
                            color: Colors.pink,
                            fit: BoxFit.fill,
                          ),
                        ),
                        if (_tradesProv.container.ttServerError ||
                            _tradesProv.container.ttAuthError)
                          Row(
                            children: [
                              Text(
                                'ERROR',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: IconButton(
                                  padding: EdgeInsets.all(0),
                                  iconSize: 20,
                                  onPressed: () {
                                    String errorString = "";
                                    if (_tradesProv.container.ttServerError) {
                                      errorString = "There was an error contacting Torn Trader, "
                                          "please try again later!";
                                    } else if (_tradesProv.container.ttAuthError) {
                                      errorString = "There was an error authenticating in Torn "
                                          "Trades, is your account active?";
                                    }
                                    BotToast.showText(
                                      text: errorString,
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.orange[800],
                                      duration: Duration(seconds: 5),
                                      contentPadding: EdgeInsets.all(10),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.info_outline,
                                    size: 15,
                                    color: Colors.orange,
                                  ),
                                ),
                              )
                            ],
                          )
                        else
                          Text(
                            'SYNC',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
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
                indent: MediaQuery.of(context).size.width / 4,
                endIndent: MediaQuery.of(context).size.width / 4,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints.loose(Size.fromHeight(
                      (MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          AppBar().preferredSize.height)) /
                  3),
              child: Scrollbar(
                controller: _scrollController,
                isAlwaysShown: true,
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
      for (var item in _tradesProv.container.leftItems) {
        total += item.totalPrice;
      }
      for (var property in _tradesProv.container.leftProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    } else {
      total += _tradesProv.container.rightMoney;
      for (var item in _tradesProv.container.rightItems) {
        total += item.totalPrice;
      }
      for (var property in _tradesProv.container.rightProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    }

    Widget propertyIcon() {
      if (!hasProperty) {
        return SizedBox.shrink();
      } else {
        return Row(
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

    Widget clipboardIcon = SizedBox(
      height: 20,
      width: 20,
      child: IconButton(
        padding: EdgeInsets.all(0),
        iconSize: 20,
        onPressed: () {
          String amountCopied;
          if (_tradesProv.container.ttActive && side == 'right') {
            amountCopied = _tradesProv.container.ttTotalMoney;
          } else {
            amountCopied = _moneyFormat.format(total);
          }
          _copyToClipboard(amountCopied, amountCopied);
        },
        icon: Icon(
          Icons.content_copy,
          size: 15,
          color: Colors.grey,
        ),
      ),
    );

    // This prevents showing totals as 0 when the widget is first loaded with existing items
    if (_tradesProv.container.firstLoad) {
      return SizedBox.shrink();
    }

    if (!_tradesProv.container.ttActive ||
        (_tradesProv.container.ttActive &&
            (_tradesProv.container.ttServerError || _tradesProv.container.ttAuthError))) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          side == 'left'
              ? Padding(padding: const EdgeInsets.only(right: 5), child: clipboardIcon)
              : SizedBox.shrink(),
          Flexible(
            child: Text(
              '\$${_moneyFormat.format(total)}',
              textAlign: side == 'left' ? TextAlign.start : TextAlign.end,
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          propertyIcon(),
          side == 'right'
              ? Padding(padding: const EdgeInsets.only(left: 5), child: clipboardIcon)
              : SizedBox.shrink(),
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
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            propertyIcon(),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _tradesProv.container.ttTotalMoney,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Colors.pink[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${_tradesProv.container.ttProfit} profit',
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
            SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: const EdgeInsets.only(right: 5), child: clipboardIcon),
                SizedBox(
                  height: 20,
                  width: 20,
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    iconSize: 20,
                    onPressed: () {
                      _copyToClipboard(_tradesProv.container.ttUrl, "Receipt URL");
                    },
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      size: 15,
                      color: Colors.pink[400],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  height: 20,
                  width: 20,
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    iconSize: 20,
                    onPressed: () {
                      // TODO
                    },
                    icon: Icon(
                      Icons.message_outlined,
                      size: 15,
                      color: Colors.pink[400],
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
    var items = List<Widget>();
    int sideMoney;
    List<TradeItem> sideItems;
    List<TradeItem> sideProperties;
    List<TradeItem> sideShares;
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

    // CASH
    if (sideMoney > 0) {
      noItemsFound = false;
      items.add(
        Text(
          '\$${_moneyFormat.format(sideMoney)} in cash',
          style: TextStyle(
            color: Colors.green,
            fontSize: 13,
          ),
        ),
      );
      items.add(SizedBox(height: 10));
    }

    // Item name
    for (var item in sideItems) {
      String itemName = item.name;
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
          style: TextStyle(
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
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(SizedBox(height: 10));
    }

    // PROPERTIES
    for (var property in sideProperties) {
      String propertyName = property.name;
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
            SizedBox(width: 5),
            Text(
              propertyName,
              style: TextStyle(
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
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(SizedBox(height: 10));
    }

    // SHARES
    for (var share in sideShares) {
      String shareName = share.name;
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
            SizedBox(width: 5),
            Text(
              shareName,
              style: TextStyle(
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
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
      );

      items.add(SizedBox(height: 10));
    }

    if (noItemsFound) {
      items.add(
        Text(
          'No items found',
          style: TextStyle(color: Colors.orange, fontSize: 13),
        ),
      );
    }

    return items;
  }

  Future _copyToClipboard(String copy, String toast) async {
    Clipboard.setData(ClipboardData(text: copy));
    BotToast.showText(
      text: toast + " copied to the clipboard!",
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green,
      duration: Duration(seconds: 5),
      contentPadding: EdgeInsets.all(10),
    );
  }
}
