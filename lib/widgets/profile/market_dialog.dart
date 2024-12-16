// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';

// Project imports:
import 'package:torn_pda/utils/travel/profit_formatter.dart';

class MarketDialog extends StatelessWidget {
  final List<UserItemMarketListing> market;
  final Function openTapCallback;
  final Function openLongPressCallback;
  final int items;
  final int money;

  final double hPad = 15;
  final double vPad = 20;
  final double frame = 10;

  const MarketDialog({
    required this.market,
    required this.openTapCallback,
    required this.openLongPressCallback,
    required this.items,
    required this.money,
  });

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
                  Icon(MdiIcons.basketOutline, size: 22),
                  const SizedBox(width: 6),
                  GestureDetector(
                    child: Icon(MdiIcons.openInApp, size: 18),
                    onTap: () {
                      Navigator.of(context).pop();
                      openTapCallback();
                    },
                    onLongPress: () {
                      Navigator.of(context).pop();
                      openLongPressCallback();
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$items ${items > 1 ? 'items' : 'item'}",
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  market.length == 1 ? "" : " (${market.length} stacks)",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Total value \$${formatProfit(inputInt: money)}", style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),
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
                    child: const Text("Close"),
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
    final items = <Widget>[];

    // Currency configuration
    final costCurrency = NumberFormat("#,##0", "en_US");

    for (final element in market) {
      final marketDiff = element.averagePrice! - element.price!;
      Color? marketColor = Colors.green;
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
                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                    Text(
                      "${element.item!.name!} x${element.amount!}",
                      style: const TextStyle(
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
                      const SizedBox(height: 5),
                      Text(
                        "@ \$${costCurrency.format(element.price)}"
                        "${element.amount! > 1 ? " ea. (\$${costCurrency.format(element.price! * element.amount!)})" : ""}",
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
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
    }
    return items;
  }
}
