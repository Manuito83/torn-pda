// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Project imports:
import 'package:torn_pda/models/profile/bazaar_model.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';

class BazaarDialog extends StatefulWidget {
  final BazaarModel bazaarModel;
  final Function openTapCallback;
  final Function openLongPressCallback;

  BazaarDialog({
    @required this.bazaarModel,
    @required this.openTapCallback,
    @required this.openLongPressCallback,
  });

  @override
  _BazaarDialogState createState() => _BazaarDialogState();
}

class _BazaarDialogState extends State<BazaarDialog> {
  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  int _totalItems = 0;
  int _totalPending = 0;

  @override
  void initState() {
    super.initState();
    // Calculate total items once
    widget.bazaarModel.bazaar.forEach((element) {
      _totalItems += element.quantity;
      _totalPending += element.quantity * element.price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(MdiIcons.storefrontOutline, size: 22),
                  SizedBox(width: 6),
                  Text("Bazaar open"),
                  SizedBox(width: 6),
                  GestureDetector(
                    child: Icon(MdiIcons.openInApp, size: 18),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.openTapCallback();
                    },
                    onLongPress: () {
                      Navigator.of(context).pop();
                      widget.openLongPressCallback();
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$_totalItems ${_totalItems > 1 ? 'items' : 'item'}",
                    style: TextStyle(fontSize: 13)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Total value \$${formatProfit(inputInt: _totalPending)}",
                    style: TextStyle(fontSize: 13)),
              ],
            ),
            SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _bazaarItems(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _bazaarItems() {
    var items = <Widget>[];

    // Currency configuration
    final costCurrency = new NumberFormat("#,##0", "en_US");

    widget.bazaarModel.bazaar.forEach((element) {
      var marketDiff = element.marketPrice - element.price;
      Color marketColor = Colors.green;
      var marketString = "";
      if (marketDiff.isNegative) {
        marketString = "\$${costCurrency.format(marketDiff.abs())} above market";
      } else {
        marketColor = Colors.orange[800];
        marketString = "\$${costCurrency.format(marketDiff.abs())} below market";
      }

      items.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'images/torn_items/small/${element.id}_small.png',
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace stackTrace) {
                        return SizedBox.shrink();
                      },
                    ),
                    Text(
                      "${element.name} x${element.quantity}",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text(
                        "@ \$${costCurrency.format(element.price)}",
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        marketString,
                        style: TextStyle(
                          color: marketColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
    return items;
  }
}
