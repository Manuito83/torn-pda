import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/profile/bazaar_model.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/widgets/profile/bazaar_dialog.dart';

class BazaarStatusCard extends StatelessWidget {
  final BazaarModel bazaarModel;
  final Function launchBrowser;

  const BazaarStatusCard({@required this.bazaarModel, @required this.launchBrowser, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check null as it loads after a while, then empty to see if bazaar is open
    if (bazaarModel == null || bazaarModel.bazaar.isEmpty) return SizedBox.shrink();

    int totalItems = 0;
    int totalMoney = 0;

    bazaarModel.bazaar.forEach((element) {
      totalItems += element.quantity;
      totalMoney += element.quantity * element.price;
    });

    var bazaarNumber = "";
    bazaarModel.bazaar.length == 1 ? bazaarNumber = "1 item" : bazaarNumber = "$totalItems items";

    var bazaarPendingString = "";
    bazaarPendingString = "\$${formatProfit(inputInt: totalMoney)}";

    openTapCallback() {
      launchBrowser(url: 'https://www.torn.com/bazaar.php', dialogRequested: true);
    }

    openLongPressCallback() {
      launchBrowser(url: 'https://www.torn.com/bazaar.php', dialogRequested: false);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text("Bazaar:"),
          ),
          Text(bazaarNumber),
          Text(" ($bazaarPendingString)"),
          SizedBox(width: 8),
          GestureDetector(
            child: Icon(
              MdiIcons.storefrontOutline,
              size: 20,
            ),
            onTap: () {
              return showDialog<void>(
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
