import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/widgets/profile/bazaar_dialog.dart';

class BazaarStatusCard extends StatelessWidget {
  final List<Bazaar>? bazaarModel;
  final Function launchBrowser;

  const BazaarStatusCard({required this.bazaarModel, required this.launchBrowser, super.key});

  @override
  Widget build(BuildContext context) {
    // Check null as it loads after a while, then empty to see if bazaar is open
    if (bazaarModel == null || bazaarModel!.isEmpty) return const SizedBox.shrink();

    int totalItems = 0;
    int totalMoney = 0;

    for (final element in bazaarModel!) {
      if (element.price is double) {
        element.price = element.price!.round();
      }

      totalItems += element.quantity!;
      totalMoney += element.quantity! * element.price!.round();
    }

    var bazaarNumber = "";
    bazaarModel!.length == 1 ? bazaarNumber = "1 item" : bazaarNumber = "$totalItems items";

    var bazaarPendingString = "";
    bazaarPendingString = "\$${formatProfit(inputInt: totalMoney)}";

    openTapCallback() {
      launchBrowser(url: 'https://www.torn.com/bazaar.php', shortTap: true);
    }

    openLongPressCallback() {
      launchBrowser(url: 'https://www.torn.com/bazaar.php', shortTap: false);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(
            width: 60,
            child: Text("Bazaar:"),
          ),
          Text(bazaarNumber),
          Text(" ($bazaarPendingString)"),
          const SizedBox(width: 8),
          GestureDetector(
            child: Icon(
              MdiIcons.storefrontOutline,
              size: 20,
            ),
            onTap: () {
              showDialog<void>(
                useRootNavigator: false,
                context: context,
                barrierDismissible: false, // user must tap button!
                builder: (BuildContext context) {
                  return BazaarDialog(
                    bazaarModel: bazaarModel,
                    openTapCallback: openTapCallback,
                    openLongPressCallback: openLongPressCallback,
                    items: totalItems,
                    money: totalMoney,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
