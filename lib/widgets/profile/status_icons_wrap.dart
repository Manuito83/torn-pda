import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';

/// ! Add new icons to the model as well
final allowedIcons = <String, Map<String, String>>{
  "icon12": {"url": "", "name" : "Low life"},
  // Needs to add ID
  "icon13": {"url": "https://www.torn.com/bounties.php?userID=", "name" : "Bounty"},
  "icon15": {"url": "https://www.torn.com/hospitalview.php", "name" : "Hospital"},
  "icon16": {"url": "https://www.torn.com/jailview.php", "name" : "Jail"},
  "icon17": {"url": "https://www.torn.com/loader.php?sid=racing", "name" : "Racing in progress"},
  "icon18": {"url": "https://www.torn.com/loader.php?sid=racing", "name" : "Racing completed"},
  "icon20": {"url": "https://www.torn.com/education.php#/step=main", "name" : "Education completed"},
  "icon30": {"url": "https://www.torn.com/bank.php", "name" : "Investment completed"},
  "icon37": {"url": "https://www.torn.com/trade.php", "name" : "Trade in progress"},
  "icon39": {"url": "", "name" : "Booster (0-6hr)"},
  "icon40": {"url": "", "name" : "Booster (6-12hr)"},
  "icon41": {"url": "", "name" : "Booster (12-18hr)"},
  "icon42": {"url": "", "name" : "Booster (18-24hr)"},
  "icon43": {"url": "", "name" : "Booster (24hr+)"},
  "icon44": {"url": "", "name" : "Medical (0-6hr)"},
  "icon45": {"url": "", "name" : "Medical (6-12hr)"},
  "icon46": {"url": "", "name" : "Medical (12-18hr)"},
  "icon47": {"url": "", "name" : "Medical (18-24hr)"},
  "icon48": {"url": "", "name" : "Medical (24hr+)"},
  "icon49": {"url": "", "name" : "Drug (0-10m)"},
  "icon50": {"url": "", "name" : "Drug (10-60m)"},
  "icon51": {"url": "", "name" : "Drug (1-2hr)"},
  "icon52": {"url": "", "name" : "Drug (2-5hr)"},
  "icon53": {"url": "", "name" : "Drug (5hr+)"},
  "icon57": {"url": "", "name" : "Addiction (1-4%)"},
  "icon58": {"url": "", "name" : "Addiction (5-9%)"},
  "icon59": {"url": "", "name" : "Addiction (10-19%)"},
  "icon60": {"url": "", "name" : "Addiction (20-29%)"},
  "icon61": {"url": "", "name" : "Addiction (30%+)"},
  "icon63": {"url": "", "name" : "Radiation (1-17%)"},
  "icon64": {"url": "", "name" : "Radiation (18-34%)"},
  "icon65": {"url": "", "name" : "Radiation (35-50%)"},
  "icon66": {"url": "", "name" : "Radiation (51-67%)"},
  "icon67": {"url": "", "name" : "Radiation (68%+)"},
  "icon75": {"url": "https://www.torn.com/factions.php?step=your#/", "name" : "Wall (defensive)"},
  "icon76": {"url": "https://www.torn.com/factions.php?step=your#/", "name" : "Wall (offensive)"},
  "icon78": {"url": "https://www.torn.com/properties.php#/p=options&tab=upkeep", "name" : "Upkeep due (4-6%)"},
  "icon79": {"url": "https://www.torn.com/properties.php#/p=options&tab=upkeep", "name" : "Upkeep due (6-8%)"},
  "icon80": {"url": "https://www.torn.com/properties.php#/p=options&tab=upkeep", "name" : "Upkeep due (8%+)"},
  "icon84": {"url": "https://www.torn.com/page.php?sid=stocks", "name" : "Dividend ready"},
  "icon85": {"url": "https://www.torn.com/factions.php?step=your#/tab=crimes", "name" : "OC in progress"},
  "icon86": {"url": "https://www.torn.com/factions.php?step=your#/tab=crimes", "name" : "OC ready"},
};

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
    var parsedIcons = icons.toJson();

    parsedIcons.forEach((iconNumber, details) {
      if (details != null) {
        if (allowedIcons.containsKey(iconNumber) && !settingsProvider.iconsFiltered.contains(iconNumber)) {
          var icon = Image.asset('images/icons/status/${iconNumber}.png', width: 18);
          iconList.add(
            GestureDetector(
              child: icon,
              onTap: () {
                BotToast.showText(
                  text: details,
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
                String url = _constructUrl(iconNumber);
                bool dialog = settingsProvider.useQuickBrowser || false;
                openBrowser(url: url, dialogRequested: dialog);
              },
              onLongPress: () {
                String url = _constructUrl(iconNumber);
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
    if (allowedIcons[key]["url"].isNotEmpty) {
      url = allowedIcons[key]["url"];
      if (key == "icon13") {
        url += user.playerId.toString();
      }
    }
    return url;
  }
}
