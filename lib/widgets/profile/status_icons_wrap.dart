import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';

class StatusIconsWrap extends StatelessWidget {
  StatusIconsWrap({
    Key key,
    @required this.user,
    @required this.openBrowser,
    @required this.settingsProvider,
  }) : super(key: key);

  final OwnProfileExtended user;
  final Function openBrowser;
  final SettingsProvider settingsProvider;

  final _allowedIcons = <String, String>{
    // Low life
    "icon12": "",
    // Bounty
    // Needs to add ID
    "icon13": "https://www.torn.com/bounties.php?userID=",
    // Hospital
    "icon15": "https://www.torn.com/hospitalview.php",
    // Jail
    "icon16": "https://www.torn.com/jailview.php",
    // Racing
    "icon17": "https://www.torn.com/loader.php?sid=racing",
    "icon18": "https://www.torn.com/loader.php?sid=racing",
    // Education over
    "icon20": "https://www.torn.com/education.php#/step=main",
    // Bank over
    "icon30": "https://www.torn.com/bank.php",
    // Trade
    "icon37": "https://www.torn.com/trade.php",
    // Booster
    "icon39": "",
    "icon40": "",
    "icon41": "",
    "icon42": "",
    "icon43": "",
    // Medical
    "icon44": "",
    "icon45": "",
    "icon46": "",
    "icon47": "",
    "icon48": "",
    // Drug
    "icon49": "",
    "icon50": "",
    "icon51": "",
    "icon52": "",
    "icon53": "",
    // Addiction
    "icon57": "",
    "icon58": "",
    "icon59": "",
    "icon60": "",
    "icon61": "",
    // Radiation
    "icon63": "",
    "icon64": "",
    "icon65": "",
    "icon66": "",
    "icon67": "",
    // Wall
    "icon75": "https://www.torn.com/factions.php?step=your#/",
    "icon76": "https://www.torn.com/factions.php?step=your#/",
    // Upkeep
    "icon78": "https://www.torn.com/properties.php#/p=options&tab=upkeep",
    "icon79": "https://www.torn.com/properties.php#/p=options&tab=upkeep",
    "icon80": "https://www.torn.com/properties.php#/p=options&tab=upkeep",
    // OC
    "icon85": "https://www.torn.com/factions.php?step=your#/tab=crimes",
    "icon86": "https://www.torn.com/factions.php?step=your#/tab=crimes",
  };

  @override
  Widget build(BuildContext context) {
    List<Widget> iconList = <Widget>[];
    if (user.icons is TornIcons) {
      iconList = _fillIcons(user.icons);
    }

    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children: iconList,
    );
  }

  List<Widget> _fillIcons(TornIcons icons) {
    final iconList = <Widget>[];
    var json = icons.toJson();

    json.forEach((key, value) {
      if (value != null) {
        if (_allowedIcons.containsKey(key)) {
          var icon = Image.asset('images/icons/status/${key}.png', width: 18);
          iconList.add(
            GestureDetector(
              child: icon,
              onTap: () {
                BotToast.showText(
                  text: value,
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.blue[700],
                  duration: Duration(seconds: 5),
                  contentPadding: EdgeInsets.all(10),
                );
              },
              onDoubleTap: () {
                String url = _constructUrl(key);
                bool dialog = settingsProvider.useQuickBrowser || false;
                openBrowser(url: url, dialogRequested: dialog);
              },
              onLongPress: () {
                String url = _constructUrl(key);
                bool dialog = false;
                openBrowser(url: url, dialogRequested: dialog);
              },
            ),
          );
        }
      }
    });

    return iconList;
  }

  String _constructUrl(String key) {
    String url = "https://www.torn.com";
    if (_allowedIcons[key].isNotEmpty) {
      url = _allowedIcons[key];
      if (key == "icon13") {
        url += user.playerId.toString();
      }
    }
    return url;
  }
}
