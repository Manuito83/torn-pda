import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';

class TradesWidget extends StatefulWidget {
  final int leftMoney;
  final List<TradeItem> leftItems;
  final List<TradeItem> leftProperties;
  final List<TradeItem> leftShares;
  final int rightMoney;
  final List<TradeItem> rightItems;
  final List<TradeItem> rightProperties;
  final List<TradeItem> rightShares;

  TradesWidget({
    @required this.leftMoney,
    @required this.leftItems,
    @required this.leftProperties,
    @required this.leftShares,
    @required this.rightMoney,
    @required this.rightItems,
    @required this.rightProperties,
    @required this.rightShares,
  });

  @override
  _TradesWidgetState createState() => _TradesWidgetState();
}

class _TradesWidgetState extends State<TradesWidget> {
  final _scrollController = ScrollController();
  final _moneyFormat = new NumberFormat("#,##0", "en_US");
  final _moneyDecimalFormat = new NumberFormat("#,##0.##", "en_US");

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Trade Calculator',
              style: TextStyle(
                color: Colors.orange,
              ),
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
      total += widget.leftMoney;
      for (var item in widget.leftItems) {
        total += item.totalPrice;
      }
      for (var property in widget.leftProperties) {
        if (property.name != 'No properties in trade') {
          hasProperty = true;
          break;
        }
      }
    } else {
      total += widget.rightMoney;
      for (var item in widget.rightItems) {
        total += item.totalPrice;
      }
      for (var property in widget.rightProperties) {
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
            Text('(+'),
            Icon(
              MdiIcons.home,
              size: 14,
            ),
            Text(')'),
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
          Clipboard.setData(ClipboardData(text: '${_moneyFormat.format(total)}'));
          BotToast.showText(
            text: "\$${_moneyFormat.format(total)} copied to the clipboard!",
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
        },
        icon: Icon(
          Icons.content_copy,
          size: 15,
          color: Colors.grey,
        ),
      ),
    );

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
  }

  List<Widget> sideDetailed(String side) {
    var items = List<Widget>();
    int sideMoney;
    List<TradeItem> sideItems;
    List<TradeItem> sideProperties;
    List<TradeItem> sideShares;
    bool noItemsFound = true;

    if (side == 'left') {
      sideMoney = widget.leftMoney;
      sideItems = widget.leftItems;
      sideProperties = widget.leftProperties;
      sideShares = widget.leftShares;
    } else {
      sideMoney = widget.rightMoney;
      sideItems = widget.rightItems;
      sideProperties = widget.rightProperties;
      sideShares = widget.rightShares;
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
            Icon(MdiIcons.home, size: 18),
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
            Icon(MdiIcons.chartTimelineVariant, size: 18),
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
}
