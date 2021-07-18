import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/pages/travel/foreign_stock_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class ForeignStockButton extends StatelessWidget {
  final UserDetailsProvider userProv;
  final SettingsProvider settingsProv;
  final Function launchBrowserFull;
  final Function launchBrowserOption;
  final Function updateCallback;

  const ForeignStockButton({
    @required this.userProv,
    @required this.settingsProv,
    @required this.launchBrowserFull,
    @required this.launchBrowserOption,
    @required this.updateCallback,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: Duration(seconds: 1),
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: (BuildContext context, VoidCallback _) {
        return ForeignStockPage(apiKey: userProv.basic.userApiKey);
      },
      closedElevation: 3,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(56 / 2),
        ),
      ),
      onClosed: (ReturnFlagPressed returnFlag) async {
        if (returnFlag.flagPressed) {
          var url = 'https://www.torn.com/travelagency.php';
          if (settingsProv.currentBrowser == BrowserSetting.external) {
            if (await canLaunch(url)) {
              await launch(url, forceSafariVC: false);
            }
          } else {
            if (returnFlag.shortTap) {
              settingsProv.useQuickBrowser
                  ? await openBrowserDialog(
                      context,
                      url,
                      callBack: null,
                    )
                  : await launchBrowserOption(url);
              updateCallback();
            } else {
              launchBrowserFull('https://www.torn.com/travelagency.php');
            }
          }
        }
      },
      closedColor: Colors.orange,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return SizedBox(
          height: 30,
          width: 30,
          child: Center(
            child: Image.asset(
              'images/icons/box.png',
              width: 16,
            ),
          ),
        );
      },
    );
  }
}
