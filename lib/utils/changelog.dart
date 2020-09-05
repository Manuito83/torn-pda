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
