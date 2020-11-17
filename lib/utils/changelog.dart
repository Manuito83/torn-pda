import 'package:flutter/material.dart';
import 'dart:io';

class ChangeLogItem {
  String version;
  var features = List<String>();
}

class ChangeLog extends StatefulWidget {
  @override
  _ChangeLogState createState() => _ChangeLogState();
}

class _ChangeLogState extends State<ChangeLog> {
  var _changeLogItems = Map<String, List<String>>();
  var _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _createItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _createItems() {
    var itemList = List<ChangeLogItem>();

    // VERSION 1.9.2
    var v1_9_2 = ChangeLogItem();
    v1_9_2.version = 'Torn PDA v1.9.2';
    String feat1_9_2_1 = "Profile: new shortcuts to your preferred game sections. Use the existing ones or configure your own. Short/long tap to open a quick or full browser";
    String feat1_9_2_2 = "Profile: added a new card for received messages";
    String feat1_9_2_3 = "Profile: added option to configure which cards are expanded or collapsed by default";
    String feat1_9_2_4 = "Profile: the Basic Information card can now be collapsed";
    String feat1_9_2_5 = "Browser: added loading progress bar (can be disabled)";
    String feat1_9_2_6 = "Browser: quick crimes are now placed at the bottom when using a bottom app bar";
    String feat1_9_2_7 = "Fixed error with chaining indications for players with no faction";
    v1_9_2.features.add(feat1_9_2_1);
    v1_9_2.features.add(feat1_9_2_2);
    v1_9_2.features.add(feat1_9_2_3);
    v1_9_2.features.add(feat1_9_2_4);
    v1_9_2.features.add(feat1_9_2_5);
    v1_9_2.features.add(feat1_9_2_6);
    v1_9_2.features.add(feat1_9_2_7);

    // VERSION 1.9.1
    var v1_9_1 = ChangeLogItem();
    v1_9_1.version = 'Torn PDA v1.9.1';
    String feat1_9_1_1 = "Profile: added several additional quick browser triggers (tap on the happy bar, life bar or the points icon)";
    String feat1_9_1_2 = "Profile: added addiction icon and information to miscellaneous";
    String feat1_9_1_3 = "Profile: added effective battle stats calculation";
    String feat1_9_1_4 = "Profile: added chain information and warning (in case you are heading to the gym and unaware of the chain)";
    String feat1_9_1_5 = "Chaining: added flags and travel direction for your targets";
    String feat1_9_1_6 = "Settings: you can now place the application bar at the bottom of the screen";
    String feat1_9_1_7 = "Fixed screen issues in several devices (wrong tap location, zoomed-in screen, loading times)";
    String feat1_9_1_8 = "Fixed scroll not returning to the correct place after refreshing a page in the browser";
    String feat1_9_1_9 = "Fixed issues with some devices and keyboards (special chars and autocorrect not displaying)";
    String feat1_9_1_10 = "Fixed dropdown menus not opening in some tablets";
    String feat1_9_1_11 = "Fixed empty notes being shown when attacking";
    String feat1_9_1_12 = "Fixed capitalization when adding notes";
    v1_9_1.features.add(feat1_9_1_1);
    v1_9_1.features.add(feat1_9_1_2);
    v1_9_1.features.add(feat1_9_1_3);
    v1_9_1.features.add(feat1_9_1_4);
    v1_9_1.features.add(feat1_9_1_5);
    v1_9_1.features.add(feat1_9_1_6);
    v1_9_1.features.add(feat1_9_1_7);
    v1_9_1.features.add(feat1_9_1_8);
    v1_9_1.features.add(feat1_9_1_9);
    v1_9_1.features.add(feat1_9_1_10);
    v1_9_1.features.add(feat1_9_1_11);
    v1_9_1.features.add(feat1_9_1_12);

    // VERSION 1.9.0
    var v1_9_0 = ChangeLogItem();
    v1_9_0.version = 'Torn PDA v1.9.0';
    String feat1_9_0_1 = "Alerts: added nerve to automatic alerts";
    String feat1_9_0_2 = "Quick actions: long press app icon (supported devices) to launch Torn from home screen";
    String feat1_9_0_3 = "Profile: tapping your energy or nerve bars will open a small browser to the gym or crimes, easier than ever";
    String feat1_9_0_4 = "Profile: added stats, points and other useful information";
    String feat1_9_0_5 = "Travel: you can now sort by quantity and see how many items of each type you already possess (can be disabled)";
    String feat1_9_0_6 = "Travel: when you click a flag, you'll also get a check on if you have sufficient money on hand to fill your capacity with the item you selected";
    String feat1_9_0_7 = "Bazaar: added button to fill maximum quantities automatically";
    String feat1_9_0_8 = "Browser: changed top-left icon to better show if the browser is going to close (X) or go back (arrow). If visiting a vault after a trade, it now goes back to Trades.";
    String feat1_9_0_9 = "Added TCT clock to main menu";
    String feat1_9_0_10 = "Improved API integration with YATA";
    v1_9_0.features.add(feat1_9_0_1);
    v1_9_0.features.add(feat1_9_0_2);
    v1_9_0.features.add(feat1_9_0_3);
    v1_9_0.features.add(feat1_9_0_4);
    v1_9_0.features.add(feat1_9_0_5);
    v1_9_0.features.add(feat1_9_0_6);
    v1_9_0.features.add(feat1_9_0_7);
    v1_9_0.features.add(feat1_9_0_8);
    v1_9_0.features.add(feat1_9_0_9);
    v1_9_0.features.add(feat1_9_0_10);

    // VERSION 1.8.6
    var v1_8_6 = ChangeLogItem();
    v1_8_6.version = 'Torn PDA v1.8.6';
    String feat1_8_6_1 = "Trading: if you are a professional trader and an user of Torn Trader, you can now activate a real time sync with your own prices, custom messages and receipt through the Trade Calculator (see options when in the Trade page in Torn to activate)";
    String feat1_8_6_2 = "Trading: a new icon will redirect you directly to your personal, faction or company vault after a trade, so that you can keep your money safe from muggers";
    String feat1_8_6_3 = "Profile: racing status added to the miscellaneous card";
    String feat1_8_6_4 = "Minor bug fixes";
    v1_8_6.features.add(feat1_8_6_1);
    v1_8_6.features.add(feat1_8_6_2);
    v1_8_6.features.add(feat1_8_6_3);
    v1_8_6.features.add(feat1_8_6_4);

    // VERSION 1.8.5
    var v1_8_5 = ChangeLogItem();
    v1_8_5.version = 'Torn PDA v1.8.5';
    String feat1_8_5_1 = "The colour of your targets' notes is now exported and imported to/from YATA (in the process, blue colour was transformed into orange for standardization)";
    String feat1_8_5_2 = "While chaining, you'll be shown your note for each target before attacking, so that you can adjust your strategy accordingly (can be disabled)";
    String feat1_8_5_3 = "You can now sort targets by note colour";
    String feat1_8_5_4 = "Fixed an issue where the target note could not be updated right after attacking";
    v1_8_5.features.add(feat1_8_5_1);
    v1_8_5.features.add(feat1_8_5_2);
    v1_8_5.features.add(feat1_8_5_3);
    v1_8_5.features.add(feat1_8_5_4);

    // VERSION 1.8.4
    var v1_8_4 = ChangeLogItem();
    v1_8_4.version = 'Torn PDA v1.8.4';
    String feat1_8_4_1 = "Chaining: you can now export and import all your targets to/from YATA, including personal notes";
    String feat1_8_4_2 = "Chaining: there is a new option to wipe all your targets (use carefully)";
    String feat1_8_4_3 = "Profile: you can now schedule travel notifications directly from the profile section";
    String feat1_8_4_4 = "Browser: swipe left/right in the top bar to browse forward/back. Also fixed an error that prevented some links (forum/profiles) from working properly.";
    String feat1_8_4_5 = "Travel: while checking foreign stock, press any flag to access the travel agency directly";
    String feat1_8_4_6 = "Visual enhancements to travel bar and chaining target's cards";
    String feat1_8_4_7 = "Corrected several other issues";
    v1_8_4.features.add(feat1_8_4_1);
    v1_8_4.features.add(feat1_8_4_2);
    v1_8_4.features.add(feat1_8_4_3);
    v1_8_4.features.add(feat1_8_4_4);
    v1_8_4.features.add(feat1_8_4_5);
    v1_8_4.features.add(feat1_8_4_6);
    v1_8_4.features.add(feat1_8_4_7);

    // VERSION 1.8.3
    var v1_8_3 = ChangeLogItem();
    v1_8_3.version = 'Torn PDA v1.8.3';
    String feat1_8_3_1 = "Chaining: added a chain watcher feature that can be activated both in "
        "the targets screen and while chaining";
    String feat1_8_3_2 = "Profile: when you are in hospital, you can now send Nuclear Central "
        "Hospital a revive request by clicking a button. This is an optional feature and "
        "a contract/payment will be required by them; Torn PDA does not get anything in return";
    String feat1_8_3_3 = "Profile: added travel arrival time information in the status card";
    v1_8_3.features.add(feat1_8_3_1);
    v1_8_3.features.add(feat1_8_3_2);
    v1_8_3.features.add(feat1_8_3_3);

    // VERSION 1.8.2
    var v1_8_2 = ChangeLogItem();
    v1_8_2.version = 'Torn PDA v1.8.2';
    String feat1_8_2_1 = "Chaining: targets that can't be attacked (red status or in a different country) "
        "will be skipped automatically. Maximum of 3 targets. This feature can be deactivated.";
    String feat1_8_2_2 = "Targets: added a hospital countdown and a clickable travel icon "
        "that shows your target's whereabouts";
    String feat1_8_2_3 = "Recent attacks: a new clickable faction icon will show you if the target "
        "you are adding to your chaining list is a member of a faction";
    String feat1_8_2_4 = "Profile: added a 'home' button and displaced the 'events' button to the events card";
    String feat1_8_2_5 = "You can now copy to the clipboard the full URL you are visiting in Torn's "
        "website by pressing the page title for a few seconds";
    String feat1_8_2_6 = "Bug fixes: travel percentage indicators and travel notification times "
        "were not working properly";
    v1_8_2.features.add(feat1_8_2_1);
    v1_8_2.features.add(feat1_8_2_2);
    v1_8_2.features.add(feat1_8_2_3);
    v1_8_2.features.add(feat1_8_2_4);
    v1_8_2.features.add(feat1_8_2_5);
    v1_8_2.features.add(feat1_8_2_6);

    // VERSION 1.8.1
    var v1_8_1 = ChangeLogItem();
    v1_8_1.version = 'Torn PDA v1.8.1';
    String feat1_8_1_1 = "Loot: increased trigger options for loot notifications";
    String feat1_8_1_2 = "Profile: corrected an issue causing delays when updating miscellaneous "
        "information";
    v1_8_1.features.add(feat1_8_1_1);
    v1_8_1.features.add(feat1_8_1_2);

    // VERSION 1.8.0
    var v1_8_0 = ChangeLogItem();
    v1_8_0.version = 'Torn PDA v1.8.0';
    String feat1_8_0_1 = "Added a city item finder when you visit the city in Torn, with a list of "
        "items found and highlights on the map";
    String feat1_8_0_2 = "Loot & Travel: you can now choose how long in advance will "
        "the notifications or other alerting methods be triggered";
    String feat1_8_0_3 = "Browser: added a page refresh button at the top";
    String feat1_8_0_4 = "Targets & Friends: you can now copy the ID to the clipboard";
    String feat1_8_0_5 = "Profile: added a MISC section with bank and education expiries";
    String feat1_8_0_6 = "Chaining: the bandage icon now gives access to your personal items, but "
        "also to your faction's armory";
    String feat1_8_0_7 = "Fixed issue with alerts not working. If you are affected, please "
        "reload your API Key (just tap on 'reload')";
    v1_8_0.features.add(feat1_8_0_1);
    v1_8_0.features.add(feat1_8_0_2);
    v1_8_0.features.add(feat1_8_0_3);
    v1_8_0.features.add(feat1_8_0_4);
    v1_8_0.features.add(feat1_8_0_5);
    v1_8_0.features.add(feat1_8_0_6);
    v1_8_0.features.add(feat1_8_0_7);

    // VERSION 1.7.1
    var v1_7_1 = ChangeLogItem();
    v1_7_1.version = 'Torn PDA v1.7.1';
    String feat1_7_1_1 = "Alerts section: added automatic alerts for hospital admission, "
        "revives and hospital release";
    String feat1_7_1_2 = "Profile section: added TCT clock at the top";
    String feat1_7_1_3 = "Chaining: added option to monitor your faction's chain while attacking "
        "several targets in a row";
    String feat1_7_1_4 = "Targets section: replaced target's ID string with an extended information "
        "page for targets; also made the faction icon clickable for more details";
    String feat1_7_1_5 = "Targets section: search form moved to the top, similar to the "
        "current layout in the Friends section";
    String feat1_7_1_6 = "Travel section: added current item capacity value in the travel capacity "
        "dialog, so there is no need to move the slider to check it";
    String feat1_7_1_7 = "Travel section: corrected an issue that prevented travel notifications "
        "from being manually activated in some cases";
    v1_7_1.features.add(feat1_7_1_1);
    v1_7_1.features.add(feat1_7_1_2);
    v1_7_1.features.add(feat1_7_1_3);
    v1_7_1.features.add(feat1_7_1_4);
    v1_7_1.features.add(feat1_7_1_5);
    v1_7_1.features.add(feat1_7_1_6);
    v1_7_1.features.add(feat1_7_1_7);

    // VERSION 1.7.0
    var v1_7_0 = ChangeLogItem();
    v1_7_0.version = 'Torn PDA v1.7.0';
    String feat1_7_0_1 = "Added Trade Calculator, with total price calculation for cash, items and "
        "shares, plus the ability to copy total figures for a quick trading. Also added trades as "
        "a quick link in the Profile section";
    String feat1_7_0_2 = "Decluttered the Travel section, with the foreign stocks page and "
        "notifications accessible through the floating button";
    String feat1_7_0_3 = "Changed cooldown countdown to show total hours and minutes";
    v1_7_0.features.add(feat1_7_0_1);
    v1_7_0.features.add(feat1_7_0_2);
    v1_7_0.features.add(feat1_7_0_3);

    // VERSION 1.6.2
    var v1_6_2 = ChangeLogItem();
    v1_6_2.version = 'Torn PDA v1.6.2';
    String feat1_6_2_1 = "Fixes error when loading API Key and the profile page for players "
        "that have deleted all their incoming events";
    v1_6_2.features.add(feat1_6_2_1);

    // VERSION 1.6.0
    var v1_6_0 = ChangeLogItem();
    v1_6_0.version = 'Torn PDA v1.6.0';
    String feat1_6_0_1 = "New NPC Loot section";
    String feat1_6_0_2 = "Added a quick crimes bar (internal app browser)";
    String feat1_6_0_3 = "Added option to fill max travel items taking into "
        "account current money and capacity, as well as a quick return button "
        "in the app bar";
    String feat1_6_0_4 = "Added energy in the automatic alerts section (beta)";
    String feat1_6_0_5 = "Fixed issue with travel bar and timer not updating "
        "correctly after the flight has departed";
    v1_6_0.features.add(feat1_6_0_1);
    v1_6_0.features.add(feat1_6_0_2);
    v1_6_0.features.add(feat1_6_0_3);
    v1_6_0.features.add(feat1_6_0_4);
    v1_6_0.features.add(feat1_6_0_5);

    // VERSION 1.5.0
    var v1_5_0 = ChangeLogItem();
    v1_5_0.version = 'Torn PDA v1.5.0';
    String feat1_5_0_1 = "New Alerts section with automatic notifications "
        "for travel";
    String feat1_5_0_2 = "You can now set a custom trigger for energy and "
        "nerve notifications in the profile page";
    String feat1_5_0_3 = "Several changes and another try at fixing issues "
        "reported by some players with the in-app browsers";
    String feat1_5_0_4 = "Several other bug fixes and changes";
    v1_5_0.features.add(feat1_5_0_1);
    v1_5_0.features.add(feat1_5_0_2);
    v1_5_0.features.add(feat1_5_0_3);
    v1_5_0.features.add(feat1_5_0_4);

    // VERSION 1.4.1
    var v1_4_1 = ChangeLogItem();
    v1_4_1.version = 'Torn PDA v1.4.1';
    String feat1_4_1_1 = "[Android] Now you can choose different notification "
        "styles (notification, alarm or timer) for each of the status bars and "
        "cooldowns available in the Profile section";
    String feat1_4_1_2 = "Added option to select a test in-app browser, with a "
        "different engine, to try to solve issues reported by some players";
    String feat1_4_1_3 = "Corrected Discord link in the About section";
    String feat1_4_1_4 = "Several other bug fixes thanks to player feedback";
    if (Platform.isAndroid) {
      v1_4_1.features.add(feat1_4_1_1);
    }
    v1_4_1.features.add(feat1_4_1_2);
    v1_4_1.features.add(feat1_4_1_3);
    v1_4_1.features.add(feat1_4_1_4);


    // VERSION 1.4.0
    var v1_4_0 = ChangeLogItem();
    v1_4_0.version = 'Torn PDA v1.4.0';
    String feat1_4_0_1 = "New 'About' section";
    String feat1_4_0_2 = "You can now choose between 12h/24h time systems & "
        "local time (LT) or Torn City TIme (TCT) time zones";
    String feat1_4_0_3 = "Added travel progress bar to the Travel section";
    String feat1_4_0_4 = "Fixed an issue causing user settings preferences not "
        "to be applied after restarting the application";
    String feat1_4_0_5 = "Fixed several issues reported in previous version "
        "(thanks Kivou + JDTech)";
    v1_4_0.features.add(feat1_4_0_1);
    v1_4_0.features.add(feat1_4_0_2);
    v1_4_0.features.add(feat1_4_0_3);
    v1_4_0.features.add(feat1_4_0_4);
    v1_4_0.features.add(feat1_4_0_5);

    // VERSION 1.3.0
    var v1_3_0 = ChangeLogItem();
    v1_3_0.version = 'Torn PDA v1.3.0';
    String feat1_3_0_1 = "New Friends section, with quick access to player "
        "details and in-game actions. Personal notes and "
        "backup functionality is also included";
    String feat1_3_0_2 = "New notifications (manually activated) added in the "
        "Profile section for energy, nerve, life and "
        "all cooldowns";
    String feat1_3_0_3 = "Energy and nerve had their colors corrected in the "
        "Profile section to adapt to game colors";
    String feat1_3_0_4 = "Other bug fixes and corrections thanks to "
        "players suggestions";
    v1_3_0.features.add(feat1_3_0_1);
    v1_3_0.features.add(feat1_3_0_2);
    v1_3_0.features.add(feat1_3_0_3);
    v1_3_0.features.add(feat1_3_0_4);

    // NEED TO ADD HERE!
    itemList.add(v1_9_2);
    itemList.add(v1_9_1);
    itemList.add(v1_9_0);
    itemList.add(v1_8_6);
    itemList.add(v1_8_5);
    itemList.add(v1_8_4);
    itemList.add(v1_8_3);
    itemList.add(v1_8_2);
    itemList.add(v1_8_1);
    itemList.add(v1_8_0);
    itemList.add(v1_7_1);
    itemList.add(v1_7_0);
    itemList.add(v1_6_2);
    itemList.add(v1_6_0);
    itemList.add(v1_5_0);
    itemList.add(v1_4_1);
    itemList.add(v1_4_0);
    itemList.add(v1_3_0);

    for (var i = 0; i < itemList.length; i++) {
      _changeLogItems.putIfAbsent(
          itemList[i].version, () => itemList[i].features);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Scrollbar(
                  controller: _scrollController,
                  isAlwaysShown: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(15, 25, 15, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _items(),
                      ),
                    ),
                  ),
                ),
              ),
              Divider(
                thickness: 1,
                color: Colors.blueGrey,
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: RaisedButton(
                  child: Text(
                    'Great!',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _items() {
    var itemList = List<Widget>();
    var itemNumber = 1;

    itemList.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Text("CHANGELOG"),
      ),
    );

    for (var entry in _changeLogItems.entries) {
      if (itemNumber > 1) {
        itemList.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 50,
            ),
            child: Divider(
              thickness: 1,
              color: Colors.blueGrey,
            ),
          ),
        );
      }
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            entry.key,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      for (var feat in entry.value) {
        itemList.add(
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _factionIcon(),
                Padding(padding: EdgeInsets.only(right: 12)),
                Flexible(
                  child: Text(
                    feat,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      itemNumber++;
    }
    return itemList;
  }

  Widget _factionIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        height: 18,
        width: 18,
        child: ImageIcon(
          AssetImage('images/icons/pda_icon.png'),
        ),
      ),
    );
  }
}
