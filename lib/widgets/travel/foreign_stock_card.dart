import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/travel/foreign_stock_in.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/inventory_model.dart';
import 'dart:ui';

class ForeignStockCard extends StatefulWidget {
  final ForeignStock foreignStock;
  final bool inventoryEnabled;
  final InventoryModel inventoryModel;
  final ItemsModel allTornItems;
  final int capacity;
  final int moneyOnHand;
  final Function flagPressedCallback;

  ForeignStockCard({
    @required this.foreignStock,
    @required this.inventoryEnabled,
    @required this.inventoryModel,
    @required this.capacity,
    @required this.allTornItems,
    @required this.moneyOnHand,
    @required this.flagPressedCallback,
  });

  @override
  _ForeignStockCardState createState() => _ForeignStockCardState();
}

class _ForeignStockCardState extends State<ForeignStockCard> {
  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      collapsed: _fullCard(expanded: true),
      expanded: _fullCard(expanded: false),
    );
  }

  Card _fullCard({bool expanded}) {

    Widget footer = SizedBox.shrink();
    if (expanded) {
      Text("cuac");
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _firstRow(widget.foreignStock),
                    SizedBox(height: 10),
                    _secondRow(widget.foreignStock),
                  ],
                ),
                _countryFlag(widget.foreignStock),
              ],
            ),
            footer,
          ],
        ),
      ),
    );
  }

  Row _firstRow(ForeignStock stock) {
    var invQuantity = 0;
    if (widget.inventoryEnabled) {
      for (var invItem in widget.inventoryModel.inventory) {
        if (invItem.id == stock.id) {
          invQuantity = invItem.quantity;
          break;
        }
      }
    }

    return Row(
      children: <Widget>[
        Image.asset('images/torn_items/small/${stock.id}_small.png'),
        Padding(
          padding: EdgeInsets.only(right: 10),
        ),
        Column(
          children: [
            SizedBox(
              width: 100,
              child: Text(stock.name),
            ),
            widget.inventoryEnabled
                ? SizedBox(
                    width: 100,
                    child: Text(
                      "(inv: x$invQuantity)",
                      style: TextStyle(fontSize: 11),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(right: 15),
        ),
        SizedBox(
          width: 55,
          child: Text(
            'x${stock.quantity}',
            style: TextStyle(
              color: stock.quantity > 0 ? Colors.green : Colors.red,
              fontWeight:
                  stock.quantity > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        _returnLastUpdated(stock.timestamp),
      ],
    );
  }

  Row _secondRow(ForeignStock stock) {
    // Currency configuration
    final costCurrency = new NumberFormat("#,##0", "en_US");

    // Item cost
    Widget costWidget;
    costWidget = Text(
      '\$${costCurrency.format(stock.cost)}',
      style: TextStyle(fontWeight: FontWeight.bold),
    );

    // Profit and profit per hour
    Widget profitWidget;
    Widget profitPerMinuteWidget;
    final profitColor = stock.value <= 0 ? Colors.red : Colors.green;

    String profitFormatted = calculateProfit(stock.value.abs());
    if (stock.value <= 0) {
      profitFormatted = '-\$$profitFormatted';
    } else {
      profitFormatted = '+\$$profitFormatted';
    }

    profitWidget = Text(
      profitFormatted,
      style: TextStyle(color: profitColor),
    );

    // Profit per hour
    String profitPerHourFormatted =
        calculateProfit((stock.profit * widget.capacity).abs());
    if (stock.profit <= 0) {
      profitPerHourFormatted = '-\$$profitPerHourFormatted';
    } else {
      profitPerHourFormatted = '+\$$profitPerHourFormatted';
    }

    profitPerMinuteWidget = Text(
      '($profitPerHourFormatted/hour)',
      style: TextStyle(color: profitColor),
    );

    return Row(
      children: <Widget>[
        costWidget,
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: profitWidget,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: profitPerMinuteWidget,
        ),
      ],
    );
  }

  String calculateProfit(int moneyInput) {
    final profitCurrencyHigh = new NumberFormat("#,##0.0", "en_US");
    final costCurrencyLow = new NumberFormat("#,##0", "en_US");
    String profitFormat;

    // Money standards to reduce string length (adding two zeros for .00)
    final billion = 1000000000;
    final million = 1000000;
    final thousand = 1000;

    // Profit
    if (moneyInput < -billion || moneyInput > billion) {
      final profitBillion = moneyInput / billion;
      profitFormat = '${profitCurrencyHigh.format(profitBillion)}B';
    } else if (moneyInput < -million || moneyInput > million) {
      final profitMillion = moneyInput / million;
      profitFormat = '${profitCurrencyHigh.format(profitMillion)}M';
    } else if (moneyInput < -thousand || moneyInput > thousand) {
      final profitThousand = moneyInput / thousand;
      profitFormat = '${profitCurrencyHigh.format(profitThousand)}K';
    } else {
      profitFormat = '${costCurrencyLow.format(moneyInput)}';
    }
    return profitFormat;
  }

  Widget _countryFlag(ForeignStock stock) {
    String countryCode;
    String flag;
    switch (stock.country) {
      case CountryName.JAPAN:
        countryCode = 'JPN';
        flag = 'images/flags/stock/japan.png';
        break;
      case CountryName.HAWAII:
        countryCode = 'HAW';
        flag = 'images/flags/stock/hawaii.png';
        break;
      case CountryName.CHINA:
        countryCode = 'CHN';
        flag = 'images/flags/stock/china.png';
        break;
      case CountryName.ARGENTINA:
        countryCode = 'ARG';
        flag = 'images/flags/stock/argentina.png';
        break;
      case CountryName.UNITED_KINGDOM:
        countryCode = 'UK';
        flag = 'images/flags/stock/uk.png';
        break;
      case CountryName.CAYMAN_ISLANDS:
        countryCode = 'CAY';
        flag = 'images/flags/stock/cayman.png';
        break;
      case CountryName.SOUTH_AFRICA:
        countryCode = 'AFR';
        flag = 'images/flags/stock/south-africa.png';
        break;
      case CountryName.SWITZERLAND:
        countryCode = 'SWI';
        flag = 'images/flags/stock/switzerland.png';
        break;
      case CountryName.MEXICO:
        countryCode = 'MEX';
        flag = 'images/flags/stock/mexico.png';
        break;
      case CountryName.UAE:
        countryCode = 'UAE';
        flag = 'images/flags/stock/uae.png';
        break;
      case CountryName.CANADA:
        countryCode = 'CAN';
        flag = 'images/flags/stock/canada.png';
        break;
    }

    return GestureDetector(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(countryCode),
          Image.asset(
            flag,
            width: 30,
          ),
        ],
      ),
      onLongPress: () {
        _launchMoneyWarning(stock);
        widget.flagPressedCallback(true, false);
      },
      onTap: () {
        _launchMoneyWarning(stock);
        widget.flagPressedCallback(true, true);
      },
    );
  }

  void _launchMoneyWarning(ForeignStock stock) {
    // Currency configuration
    final costCurrency = new NumberFormat("#,##0", "en_US");

    var moneyOnHand = widget.moneyOnHand;
    String moneyToBuy = '';
    Color moneyToBuyColor = Colors.grey;
    if (moneyOnHand >= stock.cost * widget.capacity) {
      moneyToBuy =
          'You HAVE the \$${costCurrency.format(stock.cost * widget.capacity)} necessary to '
          'buy $widget.capacity ${stock.name}';
      moneyToBuyColor = Colors.green;
    } else {
      moneyToBuy =
          'You DO NOT HAVE the \$${costCurrency.format(stock.cost * widget.capacity)} '
          'necessary to buy $widget.capacity ${stock.name}. Add another '
          '\$${costCurrency.format((stock.cost * widget.capacity) - moneyOnHand)}';
      moneyToBuyColor = Colors.red;
    }

    BotToast.showText(
      text: moneyToBuy,
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: moneyToBuyColor,
      duration: Duration(seconds: 6),
      contentPadding: EdgeInsets.all(10),
    );
  }

  Row _returnLastUpdated(int timeStamp) {
    var inputTime = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    var timeDifference = DateTime.now().difference(inputTime);
    var timeString;
    var color;
    if (timeDifference.inMinutes < 1) {
      timeString = 'now';
      color = Colors.green;
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      timeString = '1 min';
      color = Colors.green;
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      timeString = '${timeDifference.inMinutes} min';
      color = Colors.green;
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      timeString = '1 hour';
      color = Colors.orange;
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      timeString = '${timeDifference.inHours} hours';
      color = Colors.red;
    } else if (timeDifference.inDays == 1) {
      timeString = '1 day';
      color = Colors.green;
    } else {
      timeString = '${timeDifference.inDays} days';
      color = Colors.green;
    }
    return Row(
      children: <Widget>[
        Icon(
          Icons.access_time,
          size: 14,
          color: color,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            timeString,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}
