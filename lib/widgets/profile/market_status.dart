import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/widgets/profile/market_dialog.dart';

class MarketStatusCard extends StatelessWidget {
  final UserItemMarketResponse marketModel;
  final Function launchBrowser;

  const MarketStatusCard({required this.marketModel, required this.launchBrowser, super.key});

  @override
  Widget build(BuildContext context) {
    if (marketModel.itemmarket.isEmpty) return const SizedBox.shrink();

    int totalItems = 0;
    int totalMoney = 0;

    for (final item in marketModel.itemmarket) {
      totalItems += item.amount;
      totalMoney += item.amount * item.price;
    }

    var marketNumber = "";
    marketModel.itemmarket.length == 1 ? marketNumber = "1 item" : marketNumber = "$totalItems items";

    var marketPendingString = "";
    marketPendingString = "\$${formatProfit(inputInt: totalMoney)}";

    openTapCallback() {
      launchBrowser(url: 'https://www.torn.com/page.php?sid=ItemMarket#/viewListing', shortTap: true);
    }

    openLongPressCallback() {
      launchBrowser(url: 'https://www.torn.com/page.php?sid=ItemMarket#/viewListing', shortTap: false);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(
            width: 60,
            child: Text("Market:"),
          ),
          Text(marketNumber),
          Text(" ($marketPendingString)"),
          const SizedBox(width: 8),
          Semantics(
            label: 'Open market dialog',
            child: GestureDetector(
              child: const Icon(
                MdiIcons.basketOutline,
                size: 20,
              ),
              onTap: () {
                showDialog<void>(
                  useRootNavigator: false,
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return MarketDialog(
                      market: marketModel.itemmarket,
                      openTapCallback: openTapCallback,
                      openLongPressCallback: openLongPressCallback,
                      items: totalItems,
                      money: totalMoney,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
