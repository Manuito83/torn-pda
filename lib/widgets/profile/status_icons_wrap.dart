import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';

// ! Add new icons to the model as well
final allowedIcons = <String, Map<String, String>>{
  "icon3": {"url": "https://www.torn.com/donator.php?", "name": "Donator"},
  "icon4": {"url": "https://www.torn.com/donator.php?", "name": "Subscriber"},
  "icon12": {"url": "", "name": "Low life"},
  // Needs to add ID
  "icon13": {"url": "https://www.torn.com/bounties.php?userID=", "name": "Bounty"},
  "icon15": {"url": "https://www.torn.com/hospitalview.php", "name": "Hospital"},
  "icon16": {"url": "https://www.torn.com/jailview.php", "name": "Jail"},
  "icon17": {"url": "https://www.torn.com/loader.php?sid=racing", "name": "Racing in progress"},
  "icon18": {"url": "https://www.torn.com/loader.php?sid=racing", "name": "Racing completed"},
  "icon20": {"url": "https://www.torn.com/education.php#/step=main", "name": "Education completed"},
  "icon29": {"url": "https://www.torn.com/bank.php", "name": "Investment in progress"},
  "icon30": {"url": "https://www.torn.com/bank.php", "name": "Investment completed"},
  "icon31": {"url": "", "name": "Cayman Islands bank"},
  "icon32": {"url": "https://www.torn.com/properties.php#/p=options&tab=vault", "name": "Property vault"},
  "icon33": {"url": "https://www.torn.com/loan.php", "name": "Loan"},
  "icon37": {"url": "https://www.torn.com/trade.php", "name": "Trade in progress"},
  "icon39": {"url": "", "name": "Booster (0-6hr)"},
  "icon40": {"url": "", "name": "Booster (6-12hr)"},
  "icon41": {"url": "", "name": "Booster (12-18hr)"},
  "icon42": {"url": "", "name": "Booster (18-24hr)"},
  "icon43": {"url": "", "name": "Booster (24hr+)"},
  "icon44": {"url": "", "name": "Medical (0-90m)"},
  "icon45": {"url": "", "name": "Medical (90-180m)"},
  "icon46": {"url": "", "name": "Medical (180-270m)"},
  "icon47": {"url": "", "name": "Medical (270-360m)"},
  "icon48": {"url": "", "name": "Medical (360m+)"},
  "icon49": {"url": "", "name": "Drug (0-10m)"},
  "icon50": {"url": "", "name": "Drug (10-60m)"},
  "icon51": {"url": "", "name": "Drug (1-2hr)"},
  "icon52": {"url": "", "name": "Drug (2-5hr)"},
  "icon53": {"url": "", "name": "Drug (5hr+)"},
  "icon57": {"url": "", "name": "Addiction (1-4%)"},
  "icon58": {"url": "", "name": "Addiction (5-9%)"},
  "icon59": {"url": "", "name": "Addiction (10-19%)"},
  "icon60": {"url": "", "name": "Addiction (20-29%)"},
  "icon61": {"url": "", "name": "Addiction (30%+)"},
  "icon63": {"url": "", "name": "Radiation (1-17%)"},
  "icon64": {"url": "", "name": "Radiation (18-34%)"},
  "icon65": {"url": "", "name": "Radiation (35-50%)"},
  "icon66": {"url": "", "name": "Radiation (51-67%)"},
  "icon67": {"url": "", "name": "Radiation (68%+)"},
  "icon68": {"url": "", "name": "Reading book"},
  "icon75": {"url": "https://www.torn.com/factions.php?step=your#/", "name": "War (defending)"},
  "icon76": {"url": "https://www.torn.com/factions.php?step=your#/", "name": "War (assaulting)"},
  "icon78": {"url": "https://www.torn.com/properties.php#/p=options&tab=upkeep", "name": "Upkeep due (4-6%)"},
  "icon79": {"url": "https://www.torn.com/properties.php#/p=options&tab=upkeep", "name": "Upkeep due (6-8%)"},
  "icon80": {"url": "https://www.torn.com/properties.php#/p=options&tab=upkeep", "name": "Upkeep due (8%+)"},
  "icon81": {"url": "https://www.torn.com/factions.php?step=your#/", "name": "Faction recruit"},
  "icon83": {"url": "https://www.torn.com/companies.php", "name": "Company recruit"},
  "icon84": {"url": "https://www.torn.com/page.php?sid=stocks", "name": "Dividend ready"},
  "icon85": {"url": "https://www.torn.com/factions.php?step=your#/tab=crimes", "name": "OC being planned"},
  "icon86": {"url": "https://www.torn.com/factions.php?step=your#/tab=crimes", "name": "OC ready"},
};

class StatusIconsWrap extends StatefulWidget {
  StatusIconsWrap({
    Key? key,
    required this.user,
    required this.openBrowser,
    required this.settingsProvider,
  }) : super(key: key);

  final OwnProfileExtended? user;
  final Function openBrowser;
  final SettingsProvider? settingsProvider;

  @override
  _StatusIconsWrapState createState() => _StatusIconsWrapState();
}

class _StatusIconsWrapState extends State<StatusIconsWrap> {
  @override
  Widget build(BuildContext context) {
    List<Widget> iconList = <Widget>[];
    if (widget.user!.icons is TornIcons) {
      iconList = _fillIcons(widget.user!.icons as TornIcons);
    }

    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children: iconList,
    );
  }

  List<Widget> _fillIcons(TornIcons icons) {
    final iconList = <Widget>[];
    final parsedIcons = icons.toJson();

    parsedIcons.forEach((iconNumber, details) {
      if (details != null) {
        if (allowedIcons.containsKey(iconNumber) && !widget.settingsProvider!.iconsFiltered.contains(iconNumber)) {
          bool skip = false;

          // See https://www.torn.com/forums.php#/p=threads&f=19&t=16251998&b=0&a=0&start=0
          if (iconNumber == "icon12") {
            if (widget.user!.life!.current! > widget.user!.life!.maximum! / 4) {
              skip = true;
            }
          }

          //details = "Bank Investment - Current bank investment worth 194,587,366 - 0 hours, 16 minutes and 57 seconds";

          if (!skip) {
            final icon = Image.asset('images/icons/status/$iconNumber.png', width: 18);
            iconList.add(
              GestureDetector(
                child: icon,
                onTap: () {
                  BotToast.showText(
                    text: details.replaceAll(" 0 days, 0 hours, ", " ").replaceAll(" 0 days, ", " "),
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.blue[700]!,
                    duration: const Duration(seconds: 5),
                    contentPadding: const EdgeInsets.all(10),
                  );
                },
                onDoubleTap: () {
                  final String? url = _constructUrl(iconNumber);
                  widget.openBrowser(url: url, shortTap: true);
                },
                onLongPress: () {
                  final String? url = _constructUrl(iconNumber);
                  widget.openBrowser(url: url, shortTap: false);
                },
              ),
            );
          }
        }
      }
    });

    return iconList;
  }

  String? _constructUrl(String key) {
    String? url = "https://www.torn.com";
    if (allowedIcons[key]!["url"]!.isNotEmpty) {
      url = allowedIcons[key]!["url"];
      if (key == "icon13") {
        url = url! + widget.user!.playerId.toString();
      }
    }
    return url;
  }
}
