// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

class ChangeLogItem {
  var main = ChangeLogTitleDate();
  var features = <String>[];
}

class ChangeLogTitleDate {
  String version = "";
  String date = "";
}

class ChangeLog extends StatefulWidget {
  @override
  _ChangeLogState createState() => _ChangeLogState();
}

class _ChangeLogState extends State<ChangeLog> {
  var _changeLogItems = Map<ChangeLogTitleDate, List<String>>();
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
    var itemList = <ChangeLogItem>[];

    // VERSION 2.6.0
    var v2_6_0 = ChangeLogItem();
    v2_6_0.main.version = 'Torn PDA v2.6.0';
    v2_6_0.main.date = 'XX OCT 2021';
    String feat2_6_0_1 = "Chaining: added War section";
    v2_6_0.features.add(feat2_6_0_1);

    // VERSION 2.5.3
    var v2_5_3 = ChangeLogItem();
    v2_5_3.main.version = 'Torn PDA v2.5.3';
    v2_5_3.main.date = '01 OCT 2021';
    String feat2_5_3_1 = "Fixed travel max-buy button";
    String feat2_5_3_2 = "Fixed UI issues";
    v2_5_3.features.add(feat2_5_3_1);
    v2_5_3.features.add(feat2_5_3_2);

    // VERSION 2.5.2
    var v2_5_2 = ChangeLogItem();
    v2_5_2.main.version = 'Torn PDA v2.5.2';
    v2_5_2.main.date = '19 SEP 2021';
    String feat2_5_2_1 = "Added jail widget with quick bail/bust and filters";
    String feat2_5_2_2 = "Added app deep links (see Tips section)";
    String feat2_5_2_3 = "Added Reading Book icon";
    String feat2_5_2_4 = "Added return time information when travelling";
    String feat2_5_2_5 = "Added showcase on first tab use";
    String feat2_5_2_6 = "Added energy alerts for hunting";
    String feat2_5_2_7 = "Fixed some quick crimes (please remove/add the crime again if you were affected)";
    String feat2_5_2_8 = "Fixed forum history navigation";
    String feat2_5_2_9 = "Fixed user profile widget";
    String feat2_5_2_10 = "Fixed reported issues with tabs";
    String feat2_5_2_11 = "Fixed reported UI issues";
    v2_5_2.features.add(feat2_5_2_1);
    v2_5_2.features.add(feat2_5_2_2);
    v2_5_2.features.add(feat2_5_2_3);
    v2_5_2.features.add(feat2_5_2_4);
    v2_5_2.features.add(feat2_5_2_5);
    v2_5_2.features.add(feat2_5_2_6);
    v2_5_2.features.add(feat2_5_2_7);
    if (Platform.isIOS) v2_5_2.features.add(feat2_5_2_8);
    if (Platform.isIOS) v2_5_2.features.add(feat2_5_2_9);
    v2_5_2.features.add(feat2_5_2_10);
    v2_5_2.features.add(feat2_5_2_11);

    // VERSION 2.5.1
    var v2_5_1 = ChangeLogItem();
    v2_5_1.main.version = 'Torn PDA v2.5.1';
    v2_5_1.main.date = '25 AUG 2021';
    String feat2_5_1_1 = "Fixed some browsing issues when not using tabs in the quick browser";
    String feat2_5_1_2 = "Fixed browsing history not working properly after visiting certain pages";
    v2_5_1.features.add(feat2_5_1_1);
    v2_5_1.features.add(feat2_5_1_2);

    // VERSION 2.5.0
    var v2_5_0 = ChangeLogItem();
    v2_5_0.main.version = 'Torn PDA v2.5.0';
    v2_5_0.main.date = '20 AUG 2021';
    String feat2_5_0_1 = "Browser: added tabs (visit the Tips section for more information)";
    String feat2_5_0_2 = "Browser: added pull to refresh to the main browser (disabled by default)";
    String feat2_5_0_3 = "Profile: added section header with main icons and wallet information";
    String feat2_5_0_4 = "Profile: added pull to refresh in the Profile section";
    String feat2_5_0_5 = "Profile: added more detail to bazaar information";
    String feat2_5_0_6 = "Scripts: added Company Activity and fixed Racing Presets";
    String feat2_5_0_7 = "Chaining: removed Torn Attack Central (service discontinued)";
    String feat2_5_0_8 = "Fixed some userscripts with wildcards not correctly activating";
    String feat2_5_0_9 = "Fixed vault widget's loading time";
    String feat2_5_0_10 = "Fixed UI issues reported";
    v2_5_0.features.add(feat2_5_0_1);
    v2_5_0.features.add(feat2_5_0_2);
    v2_5_0.features.add(feat2_5_0_3);
    v2_5_0.features.add(feat2_5_0_4);
    v2_5_0.features.add(feat2_5_0_5);
    v2_5_0.features.add(feat2_5_0_6);
    v2_5_0.features.add(feat2_5_0_7);
    v2_5_0.features.add(feat2_5_0_8);
    v2_5_0.features.add(feat2_5_0_9);
    v2_5_0.features.add(feat2_5_0_10);

    // VERSION 2.4.3
    var v2_4_3 = ChangeLogItem();
    v2_4_3.main.version = 'Torn PDA v2.4.3';
    v2_4_3.main.date = '05 AUG 2021';
    String feat2_4_3_1 =
        "You can now optionally access the Stock Market section from the main menu (disabled by default)";
    String feat2_4_3_2 = "Added display cabinet items to the inventory count shown in the foreign stocks page";
    String feat2_4_3_3 =
        "Unedited example user scripts will now update automatically as necessary with each app update";
    String feat2_4_3_4 = "Fixed disabled user scripts reactivating when app is launched";
    String feat2_4_3_5 = "Fixed total bazaar value shown in the Profile section";
    String feat2_4_3_6 = "Fixed other reported UI issues";
    v2_4_3.features.add(feat2_4_3_1);
    v2_4_3.features.add(feat2_4_3_2);
    v2_4_3.features.add(feat2_4_3_3);
    v2_4_3.features.add(feat2_4_3_4);
    v2_4_3.features.add(feat2_4_3_5);
    v2_4_3.features.add(feat2_4_3_6);

    // VERSION 2.4.2
    var v2_4_2 = ChangeLogItem();
    v2_4_2.main.version = 'Torn PDA v2.4.2';
    v2_4_2.main.date = '28 JUL 2021';
    String feat2_4_2_1 = "Profile: added total bazaar value information";
    String feat2_4_2_2 = "Travel: you can now filter foreign stocks by inventory quantity";
    String feat2_4_2_3 = "Travel: MAX buy button can now also be used to buy additional items above the limit";
    String feat2_4_2_4 = "Travel: added custom (seat belt) sound for travel notifications";
    String feat2_4_2_5 = "Travel: added depletion rate information to foreign stocks";
    String feat2_4_2_6 =
        "Browser: you can now set the energy threshold to trigger the stacking warning when visiting the gym";
    String feat2_4_2_7 = "Browser: added terminal window for developers";
    String feat2_4_2_8 = "Fixed an issue preventing some userscripts from working if using wildcards in the URL";
    String feat2_4_2_9 = "Fixed other reported UI issues";
    String feat2_4_2_10 = "Note: TAC is now deactivated by default and will be removed soon, save any pending target!";
    v2_4_2.features.add(feat2_4_2_1);
    v2_4_2.features.add(feat2_4_2_2);
    v2_4_2.features.add(feat2_4_2_3);
    v2_4_2.features.add(feat2_4_2_4);
    v2_4_2.features.add(feat2_4_2_5);
    v2_4_2.features.add(feat2_4_2_6);
    v2_4_2.features.add(feat2_4_2_7);
    v2_4_2.features.add(feat2_4_2_8);
    v2_4_2.features.add(feat2_4_2_9);
    v2_4_2.features.add(feat2_4_2_10);

    // VERSION 2.4.1
    var v2_4_1 = ChangeLogItem();
    v2_4_1.main.version = 'Torn PDA v2.4.1';
    v2_4_1.main.date = '10 JUL 2021';
    String feat2_4_1_1 = "Fixed chat hiding and highlighting";
    v2_4_1.features.add(feat2_4_1_1);

    // VERSION 2.4.0
    var v2_4_0 = ChangeLogItem();
    v2_4_0.main.version = 'Torn PDA v2.4.0';
    v2_4_0.main.date = '05 JUL 2021';
    String feat2_4_0_1 = "Added alerts for stock exchange price gain/loss";
    String feat2_4_0_2 = "Added Arson Warehouse support in the Trade Calculator";
    String feat2_4_0_3 = "Loot: added Tiny";
    String feat2_4_0_4 = "Loot: click the NPC's portrait to visit the profile";
    String feat2_4_0_5 = "Profile: you can now choose which section to visit when tapping the life bar";
    String feat2_4_0_6 = "Profile: you can now edit active shortcuts (left swipe)";
    String feat2_4_0_7 = "Profile: added caution message if visiting the gym while stacking";
    String feat2_4_0_8 =
        "Chaining: chain watcher can now be seen anywhere in the app, also added improvements in timings and local notifications";
    String feat2_4_0_9 = "Chaining: you can now check targets' status after fetching them from TAC";
    String feat2_4_0_10 = "Chaining: added options (URL copy, navigation, shortcuts) to chaining browser";
    String feat2_4_0_11 = "Chaining: you can now tap anywhere in a target's card to trigger the attack browser";
    String feat2_4_0_12 = "Browser: added MAX buttons when buying from the bazaar";
    String feat2_4_0_13 = "Browser: you can now disable the native link preview windows when long-pressing";
    String feat2_4_0_14 = "Browser: TornCAT Player Filter script updated to include API comment";
    String feat2_4_0_15 = "Fixed issue with screen turning off when chain watcher is in use";
    String feat2_4_0_16 = "Fixed connectivity with some bluetooth devices";
    String feat2_4_0_17 = "Fixed foreign stock items identification and uploads";
    String feat2_4_0_18 = "Fixed issues caused by targets with life over max";
    String feat2_4_0_19 = "Fixed recent attacks cards errors in certain conditions";
    String feat2_4_0_20 = "Fixed other UI related issues reported by users";
    v2_4_0.features.add(feat2_4_0_1);
    v2_4_0.features.add(feat2_4_0_2);
    v2_4_0.features.add(feat2_4_0_3);
    v2_4_0.features.add(feat2_4_0_4);
    v2_4_0.features.add(feat2_4_0_5);
    v2_4_0.features.add(feat2_4_0_6);
    v2_4_0.features.add(feat2_4_0_7);
    v2_4_0.features.add(feat2_4_0_8);
    v2_4_0.features.add(feat2_4_0_9);
    v2_4_0.features.add(feat2_4_0_10);
    v2_4_0.features.add(feat2_4_0_11);
    v2_4_0.features.add(feat2_4_0_12);
    if (Platform.isIOS) v2_4_0.features.add(feat2_4_0_13);
    v2_4_0.features.add(feat2_4_0_14);
    v2_4_0.features.add(feat2_4_0_15);
    v2_4_0.features.add(feat2_4_0_16);
    v2_4_0.features.add(feat2_4_0_17);
    v2_4_0.features.add(feat2_4_0_18);
    v2_4_0.features.add(feat2_4_0_19);
    v2_4_0.features.add(feat2_4_0_20);

    // VERSION 2.3.5
    var v2_3_5 = ChangeLogItem();
    v2_3_5.main.version = 'Torn PDA v2.3.5';
    v2_3_5.main.date = '30 MAY 2021';
    String feat2_3_5_1 = "Browser: added vault share widget";
    String feat2_3_5_2 = "Settings: added auto rotation option";
    String feat2_3_5_3 = "Profile: added shortcuts below error message when Torn API is down";
    String feat2_3_5_4 = "Fixed duplicated notifications in some devices with the app on the foreground";
    String feat2_3_5_5 = "Fixed error when using Awards for the first time in a while";
    String feat2_3_5_6 = "Fixed chats hide option and name highlights";
    String feat2_3_5_7 = "Fixed other user interface issues";
    v2_3_5.features.add(feat2_3_5_1);
    v2_3_5.features.add(feat2_3_5_2);
    v2_3_5.features.add(feat2_3_5_3);
    v2_3_5.features.add(feat2_3_5_4);
    v2_3_5.features.add(feat2_3_5_5);
    v2_3_5.features.add(feat2_3_5_6);
    v2_3_5.features.add(feat2_3_5_7);

    // VERSION 2.3.4
    var v2_3_4 = ChangeLogItem();
    v2_3_4.main.version = 'Torn PDA v2.3.4';
    v2_3_4.main.date = '04 MAY 2021';
    String feat2_3_4_1 = "Alerts: added refills (energy, nerve, casino tokens).";
    String feat2_3_4_2 =
        "Browser: added search functionality (tap the title or long-press the quick browser bottom bar).";
    String feat2_3_4_3 =
        "Profile: added organized crimes calculation from events (if faction API access is unavailable).";
    String feat2_3_4_4 = "Profile: added bazaar status and dialog with details to the status card.";
    String feat2_3_4_5 = "Profile: you can now copy or share the information in the Basic Info card.";
    String feat2_3_4_6 = "Loot: added pull to refresh functionality.";
    String feat2_3_4_7 = "Browser: fixed issue preventing the Trade Calculator widget from activating.";
    String feat2_3_4_8 = "Scripts: updated TornCAT example and the repository with new scripts.";
    v2_3_4.features.add(feat2_3_4_1);
    v2_3_4.features.add(feat2_3_4_2);
    v2_3_4.features.add(feat2_3_4_3);
    v2_3_4.features.add(feat2_3_4_4);
    v2_3_4.features.add(feat2_3_4_5);
    v2_3_4.features.add(feat2_3_4_6);
    v2_3_4.features.add(feat2_3_4_7);
    v2_3_4.features.add(feat2_3_4_8);

    // VERSION 2.3.3
    var v2_3_3 = ChangeLogItem();
    v2_3_3.main.version = 'Torn PDA v2.3.3';
    v2_3_3.main.date = '22 APR 2021';
    String feat2_3_3_1 = "Added a 5 minutes option for manual Loot notifications.";
    String feat2_3_3_2 = "Added networth information to players' profiles (disabled by default).";
    String feat2_3_3_3 = "Adapted quick items result box to work with dark mode.";
    String feat2_3_3_4 = "Fixed an issue preventing Torn Trader from authenticating users.";
    v2_3_3.features.add(feat2_3_3_1);
    v2_3_3.features.add(feat2_3_3_2);
    v2_3_3.features.add(feat2_3_3_3);
    v2_3_3.features.add(feat2_3_3_4);

    // VERSION 2.3.2
    var v2_3_2 = ChangeLogItem();
    v2_3_2.main.version = 'Torn PDA v2.3.2';
    v2_3_2.main.date = '15 APR 2021';
    String feat2_3_2_1 =
        "Browser: added stats from YATA's spies database to players' profiles. You can now also optionally hide estimated stats (much less accurate) in Settings.";
    String feat2_3_2_2 =
        "Userscripts: added another few example scripts and corrected issues with the existing ones (you can import the new ones from the userscripts settings).";
    String feat2_3_2_3 =
        "Userscripts: created a list of tested scripts in the GitHub repository, also added a reference in Torn PDA and in the official forums.";
    String feat2_3_2_4 = "Userscripts: script execution is now isolated and no interference should occur between them.";
    String feat2_3_2_5 = "Loot: NPCs can now be filtered out.";
    String feat2_3_2_6 = "Shortcuts: Stock Market URL has been corrected and Portfolio has been removed.";
    String feat2_3_2_7 = "Profile: added racing, reviving and hunting skills to the basic info card.";
    String feat2_3_2_8 = "Travel: flag filters can now be sorted alphabetically and by flight time.";
    String feat2_3_2_9 = "Travel: the quick return icon now needs to be pressed twice to avoid erroneous activations.";
    String feat2_3_2_10 = "Travel: increased width of the capacity slider to make selection easier.";
    String feat2_3_2_11 =
        "Travel: the custom text notification dialog has been moved to the travel notification options page.";
    String feat2_3_2_12 = "Awards: added button to enable or disable all filters at once.";
    String feat2_3_2_13 = "Alerts: improved travel alerts reliability, even if the API goes down temporarily.";
    String feat2_3_2_14 =
        "Alerts: added troubleshooting dialog to reset user and notification channels if something isn't working correctly.";
    String feat2_3_2_15 = "Fixed URL copying issues in certain devices.";
    String feat2_3_2_16 = "Fixed Trade widget not activating in certain devices.";
    String feat2_3_2_17 = "Fixed crash when clearing browser cache in certain devices.";
    String feat2_3_2_18 = "Fixed scrolling issues causing the browser to freeze in certain sections of the website.";
    v2_3_2.features.add(feat2_3_2_1);
    v2_3_2.features.add(feat2_3_2_2);
    v2_3_2.features.add(feat2_3_2_3);
    v2_3_2.features.add(feat2_3_2_4);
    v2_3_2.features.add(feat2_3_2_5);
    v2_3_2.features.add(feat2_3_2_6);
    v2_3_2.features.add(feat2_3_2_7);
    v2_3_2.features.add(feat2_3_2_8);
    v2_3_2.features.add(feat2_3_2_9);
    v2_3_2.features.add(feat2_3_2_10);
    v2_3_2.features.add(feat2_3_2_11);
    v2_3_2.features.add(feat2_3_2_12);
    v2_3_2.features.add(feat2_3_2_13);
    v2_3_2.features.add(feat2_3_2_14);
    v2_3_2.features.add(feat2_3_2_15);
    v2_3_2.features.add(feat2_3_2_16);
    v2_3_2.features.add(feat2_3_2_17);
    v2_3_2.features.add(feat2_3_2_18);

    // VERSION 2.3.1
    var v2_3_1 = ChangeLogItem();
    v2_3_1.main.version = 'Torn PDA v2.3.1';
    v2_3_1.main.date = '02 APR 2021';
    String feat2_3_1_1 = "Added Easter Bunny (NPC).";
    String feat2_3_1_2 =
        "Browser: the pull to refresh feature has been temporarily deactivated due to unexpected behaviours.";
    String feat2_3_1_3 = "Events alerts reliability has been improved.";
    String feat2_3_1_4 = "Fixed user scripts page opening a blank menu.";
    String feat2_3_1_5 = "Fixed reported typos in the Profile section.";
    v2_3_1.features.add(feat2_3_1_1);
    v2_3_1.features.add(feat2_3_1_2);
    v2_3_1.features.add(feat2_3_1_3);
    v2_3_1.features.add(feat2_3_1_4);
    v2_3_1.features.add(feat2_3_1_5);

    // VERSION 2.2.0
    var v2_3_0 = ChangeLogItem();
    v2_3_0.main.version = 'Torn PDA v2.3.0';
    v2_3_0.main.date = '01 APR 2021';
    String feat2_3_0_1 = "Loot: added Fernando (NPC).";
    String feat2_3_0_2 =
        "Browser: added custom user scripts support (add your own in Settings / Browser Options). Preexisting scripts might require code changes to work in Torn PDA.";
    String feat2_3_0_3 = "Browser: added estimated stats to players' profiles.";
    String feat2_3_0_4 =
        "Browser: added extra information when attacking or visiting other players' profiles. You will be warned if they belong to your same faction or a friendly faction, if they are on your friends' list, etc. You can configure friendly factions in the advanced browser settings inside of the Settings section.";
    String feat2_3_0_5 =
        "Browser: added pull to refresh and optionally hide refresh icon (does not work in the chaining browser).";
    String feat2_3_0_6 =
        "Chaining: added extra information to targets' notes when chaining, showing if the target has been online recently and if it belongs to a faction. Applies to standard targets and TAC.";
    String feat2_3_0_7 = "Chaining: changed sorting by note color to match YATA's (G-Y-R-OFF or OFF-R-Y-G).";
    String feat2_3_0_8 = "Chaining: you can now filter targets by note color.";
    String feat2_3_0_9 = "Chaining: fixed TAC stats notes not showing correctly.";
    String feat2_3_0_10 =
        "Chaining: notes color now sync with YATA even if the note is empty. The notebook icon is now also colored accordingly";
    String feat2_3_0_11 = "Chaining: target cards now show flat respect. Added fair fight.";
    String feat2_3_0_12 = "Friends: the notebook icon is now colored according to the note's color, even if empty.";
    String feat2_3_0_13 = "Profile: added a check for property rental expiry (< 7 days) in the miscellaneous card";
    String feat2_3_0_14 =
        "Profile: the manual hospital release notification can now be configured to trigger several minutes in advance (similar to travel notifications).";
    String feat2_3_0_15 = "Profile: fixed company name when working for a public company.";
    String feat2_3_0_16 = "Profile: fixed participants readiness check for OCs.";
    String feat2_3_0_17 = "Travel: Improved foreign items layout for narrow screens.";
    String feat2_3_0_18 = "Settings: moved browser options to a dedicated section to reduce complexity.";
    String feat2_3_0_19 = "Corrected pixel density for certain devices.";
    String feat2_3_0_20 = "Corrected Torn links not working when the website returns an unsecure (http) url.";
    String feat2_3_0_21 = "Corrected targets sync issues caused by API changes.";
    v2_3_0.features.add(feat2_3_0_1);
    v2_3_0.features.add(feat2_3_0_2);
    v2_3_0.features.add(feat2_3_0_3);
    v2_3_0.features.add(feat2_3_0_4);
    v2_3_0.features.add(feat2_3_0_5);
    v2_3_0.features.add(feat2_3_0_6);
    v2_3_0.features.add(feat2_3_0_7);
    v2_3_0.features.add(feat2_3_0_8);
    v2_3_0.features.add(feat2_3_0_9);
    v2_3_0.features.add(feat2_3_0_10);
    v2_3_0.features.add(feat2_3_0_11);
    v2_3_0.features.add(feat2_3_0_12);
    v2_3_0.features.add(feat2_3_0_13);
    v2_3_0.features.add(feat2_3_0_14);
    v2_3_0.features.add(feat2_3_0_15);
    v2_3_0.features.add(feat2_3_0_16);
    v2_3_0.features.add(feat2_3_0_17);
    v2_3_0.features.add(feat2_3_0_18);
    v2_3_0.features.add(feat2_3_0_19);
    v2_3_0.features.add(feat2_3_0_20);
    v2_3_0.features.add(feat2_3_0_21);

    // VERSION 2.2.0
    var v2_2_0 = ChangeLogItem();
    v2_2_0.main.version = 'Torn PDA v2.2.0';
    v2_2_0.main.date = '25 FEB 2021';
    String feat2_2_0_1 = "Travel: added foreign stock graphs with last 36 hours data";
    String feat2_2_0_2 =
        "Travel: added restock and depletion times calculation, with flight departure times suggestions and manually activated notifications";
    String feat2_2_0_3 = "Travel: added automatic alerts for items restock (Alerts section)";
    String feat2_2_0_4 =
        "Travel: you can now specify your travel ticket type, which will affect departure and arrival times as well as profit calculation";
    String feat2_2_0_5 = "Travel: arrival times are now shown in the main stock card";
    String feat2_2_0_6 = "Travel: items can now be sorted by arrival time";
    String feat2_2_0_7 = "Travel: added calculation of money to carry and direct access to vaults";
    String feat2_2_0_8 =
        "Travel: the foreign stock page can now be refreshed by pulling. Also added a button in the app bar to manually refresh the API while in the Travel section";
    String feat2_2_0_9 = "Travel: you can now optionally hide the airplane while flying (Settings)";
    String feat2_2_0_10 = "Profile: you can now activate a manual notification for just before hospital release";
    String feat2_2_0_11 =
        "Profile: you can now activate a manual notification, alarm or timer for just before hospital release";
    String feat2_2_0_12 =
        "Profile: added Universal Health Care reviving services call when in hospital (activate in profile options)";
    String feat2_2_0_13 =
        "Profile: added Organized Crimes in Misc and Travel cards (note: you need Api Access permission from your faction)";
    String feat2_2_0_14 = "Profile: you can now manually sort the cards shown in the Profile section";
    String feat2_2_0_15 =
        "Profile: you can now optionally activate a minimalistic travel card which shows the same information the Travel section offers (and disable the latter entirely if you wish)";
    String feat2_2_0_16 = "Profile: added job points to the basic information card";
    String feat2_2_0_17 = "Chaining: added fair fight to recent attacks cards";
    String feat2_2_0_18 =
        "Chaining: added fair fight and respect calculation from TAC (realtime based on current chain hit number)";
    String feat2_2_0_19 = "Chaining: added notes for TAC targets";
    String feat2_2_0_20 = "City Finder now collapses (less intrusive)";
    String feat2_2_0_21 = "Added option to clear the browser's cache (Settings)";
    String feat2_2_0_22 =
        "Sound and vibration options for manually activated alarms have been moved to Settings and now apply equally to all alarms";
    String feat2_2_0_23 = "Fixed forums URL copying";
    String feat2_2_0_24 = "Fixed cooldowns time string";
    String feat2_2_0_25 = "Fixed targets wipe functionality";
    String feat2_2_0_26 = "Fixed other several minor bugs";
    v2_2_0.features.add(feat2_2_0_1);
    v2_2_0.features.add(feat2_2_0_2);
    v2_2_0.features.add(feat2_2_0_3);
    v2_2_0.features.add(feat2_2_0_4);
    v2_2_0.features.add(feat2_2_0_5);
    v2_2_0.features.add(feat2_2_0_6);
    v2_2_0.features.add(feat2_2_0_7);
    v2_2_0.features.add(feat2_2_0_8);
    v2_2_0.features.add(feat2_2_0_9);
    if (Platform.isIOS) v2_2_0.features.add(feat2_2_0_10);
    if (Platform.isAndroid) v2_2_0.features.add(feat2_2_0_11);
    v2_2_0.features.add(feat2_2_0_12);
    v2_2_0.features.add(feat2_2_0_13);
    v2_2_0.features.add(feat2_2_0_14);
    v2_2_0.features.add(feat2_2_0_15);
    v2_2_0.features.add(feat2_2_0_16);
    v2_2_0.features.add(feat2_2_0_17);
    v2_2_0.features.add(feat2_2_0_18);
    v2_2_0.features.add(feat2_2_0_19);
    v2_2_0.features.add(feat2_2_0_20);
    v2_2_0.features.add(feat2_2_0_21);
    if (Platform.isAndroid) v2_2_0.features.add(feat2_2_0_22);
    if (Platform.isIOS) v2_2_0.features.add(feat2_2_0_23);
    v2_2_0.features.add(feat2_2_0_24);
    v2_2_0.features.add(feat2_2_0_25);
    v2_2_0.features.add(feat2_2_0_26);

    // VERSION 2.1.1
    // ### ADDED FOR IOS ONLY ###
    var v2_1_1 = ChangeLogItem();
    v2_1_1.main.version = 'Torn PDA v2.1.1';
    v2_1_1.main.date = '30 JAN 2021';
    String feat2_1_1_1 = "Fixed Awards not loading correctly on iOS";
    v2_1_1.features.add(feat2_1_1_1);

    // VERSION 2.1.0
    var v2_1_0 = ChangeLogItem();
    v2_1_0.main.version = 'Torn PDA v2.1.0';
    v2_1_0.main.date = '21 JAN 2021';
    String feat2_1_0_1 = "Added Torn Attack Central mobile interface (see Chaining section)";
    String feat2_1_0_2 =
        "Automatic alerts: added Events (includes trading alerts as a special category), with some predefined filters";
    String feat2_1_0_3 = "You can now use your shortcuts directly from the browser (tap the page title)";
    String feat2_1_0_4 = "Added the quick items widget to the chaining browser";
    String feat2_1_0_5 = "Awards: activated pins sync with YATA";
    String feat2_1_0_6 = "Awards: fixed sorting by days left";
    String feat2_1_0_7 =
        "Notifications are now automatically removed from the notification bar when the application is launched (can be deactivated)";
    String feat2_1_0_8 =
        "Added notification channels (in Android's notifications settings) so that users can configure each notification (sound, alert type, etc.) individually";
    String feat2_1_0_9 = "You can now select the vibration pattern for notifications (Settings)";
    String feat2_1_0_10 = "Fixed Discord link";
    String feat2_1_0_11 = "Fixed issues when launching the external browser";
    String feat2_1_0_12 = "Fixed URL copying";
    String feat2_1_0_13 = "Fixed education warning when there are no pending courses";
    v2_1_0.features.add(feat2_1_0_1);
    v2_1_0.features.add(feat2_1_0_2);
    v2_1_0.features.add(feat2_1_0_3);
    v2_1_0.features.add(feat2_1_0_4);
    v2_1_0.features.add(feat2_1_0_5);
    v2_1_0.features.add(feat2_1_0_6);
    if (Platform.isAndroid) {
      v2_1_0.features.add(feat2_1_0_7);
      v2_1_0.features.add(feat2_1_0_8);
      v2_1_0.features.add(feat2_1_0_9);
    }
    v2_1_0.features.add(feat2_1_0_10);
    v2_1_0.features.add(feat2_1_0_11);
    v2_1_0.features.add(feat2_1_0_12);
    v2_1_0.features.add(feat2_1_0_13);

    // VERSION 2.0.0
    var v2_0_0 = ChangeLogItem();
    v2_0_0.main.version = 'Torn PDA v2.0.0';
    v2_0_0.main.date = '06 JAN 2021';
    String feat2_0_0_1 =
        "YATA Awards: new section that constitutes the first official YATA mobile interface. Data comes straight from your YATA account";
    String feat2_0_0_2 =
        "Quick Items: browse to the items section in Torn with the full browser and add your prefer items for a quick access later on";
    String feat2_0_0_3 =
        "Alerts: added messages to automatic alerts (tap the notification to browse straight to the message). Most other notifications can now also be tapped to get access to their relevant areas";
    String feat2_0_0_4 =
        "Tips: new section added to the main menu with some frequently asked questions and tips to get the maximum out or Torn PDA";
    String feat2_0_0_5 = "You can now highlight your name in chat (choose color or disable in Settings)";
    String feat2_0_0_6 = "Added a new button that allows to temporarily remove all chat windows from Torn";
    String feat2_0_0_7 =
        "New browser features: you can now browse to any URL or add a website as a shortcut to your Profile section directly from the browser (tap the browser page title in the full browser or long press the close button in the quick browser)";
    String feat2_0_0_8 =
        "Using the back button or back swipe while in the browser won't inadvertently close the browser any longer, but browse back if possible";
    String feat2_0_0_9 =
        "Most links in Torn PDA open the quick browser with a short tap or the full browser with a long-press. Quick browser can be deactivated in Settings if desired";
    String feat2_0_0_10 = "You can now select the number of events and messages to show in the Profile section";
    String feat2_0_0_11 = "Added confirmation dialog to prevent exiting Torn PDA inadvertently (can be disabled)";
    String feat2_0_0_12 = "Added Loot and Awards to the default launch section selector";
    String feat2_0_0_13 = "Browser widgets should open faster and more reliably";
    String feat2_0_0_14 = "Corrected travel money checks showing a warning when the exact amount was brought";
    String feat2_0_0_15 = "Corrected appbar icons and colors";
    v2_0_0.features.add(feat2_0_0_1);
    v2_0_0.features.add(feat2_0_0_2);
    v2_0_0.features.add(feat2_0_0_3);
    v2_0_0.features.add(feat2_0_0_4);
    v2_0_0.features.add(feat2_0_0_5);
    v2_0_0.features.add(feat2_0_0_6);
    v2_0_0.features.add(feat2_0_0_7);
    v2_0_0.features.add(feat2_0_0_8);
    v2_0_0.features.add(feat2_0_0_9);
    v2_0_0.features.add(feat2_0_0_10);
    v2_0_0.features.add(feat2_0_0_11);
    v2_0_0.features.add(feat2_0_0_12);
    v2_0_0.features.add(feat2_0_0_13);
    v2_0_0.features.add(feat2_0_0_14);
    v2_0_0.features.add(feat2_0_0_15);

    // VERSION 1.9.7
    var v1_9_7 = ChangeLogItem();
    v1_9_7.main.version = 'Torn PDA v1.9.7';
    v1_9_7.main.date = '09 DEC 2020';
    String feat1_9_7_1 = "Loot: fixed bug preventing notifications from working properly";
    String feat1_9_7_2 = "Text corrections";
    v1_9_7.features.add(feat1_9_7_1);
    v1_9_7.features.add(feat1_9_7_2);

    // VERSION 1.9.6
    var v1_9_6 = ChangeLogItem();
    v1_9_6.main.version = 'Torn PDA v1.9.6';
    v1_9_6.main.date = '06 DEC 2020';
    String feat1_9_6_1 = "Loot: added Scrooge (NPC)";
    String feat1_9_6_2 =
        "Profile: added wallet money to the Basic Info card. Short/long tap to access your vaults with quick or full browser";
    String feat1_9_6_3 =
        "Short or long tap the travel bar (in Profile & Travel) to launch the quick or full browser to Torn";
    String feat1_9_6_4 = "Alerts section can now be correctly scrolled in smaller screens";
    String feat1_9_6_5 = "Fixed other issues reported by users";
    v1_9_6.features.add(feat1_9_6_1);
    v1_9_6.features.add(feat1_9_6_2);
    v1_9_6.features.add(feat1_9_6_3);
    v1_9_6.features.add(feat1_9_6_4);
    v1_9_6.features.add(feat1_9_6_5);

    // VERSION 1.9.5
    var v1_9_5 = ChangeLogItem();
    v1_9_5.main.version = 'Torn PDA v1.9.5';
    v1_9_5.main.date = '30 NOV 2020';
    String feat1_9_5_1 = "Fixed shortcuts menu persistence after app is closed";
    String feat1_9_5_2 = "Fixed Discord link in About section";
    v1_9_5.features.add(feat1_9_5_1);
    v1_9_5.features.add(feat1_9_5_2);

    // VERSION 1.9.4
    var v1_9_4 = ChangeLogItem();
    v1_9_4.main.version = 'Torn PDA v1.9.4';
    v1_9_4.main.date = '28 NOV 2020';
    String feat1_9_4_1 = "Alerts: added drugs cooldown automatic alert";
    String feat1_9_4_2 = "Alerts: added racing automatic alert";
    String feat1_9_4_3 = "Profile: you can now choose between an horizontal slidable list or a grid view for shortcuts";
    String feat1_9_4_4 = "Browser: added quick controls (back, forward and refresh) for the quick browser";
    String feat1_9_4_5 =
        "Browser: improved speed and corrected several reported issues (i.e.: hospital timer and other sections not showing)";
    v1_9_4.features.add(feat1_9_4_1);
    v1_9_4.features.add(feat1_9_4_2);
    v1_9_4.features.add(feat1_9_4_3);
    v1_9_4.features.add(feat1_9_4_4);
    v1_9_4.features.add(feat1_9_4_5);

    // VERSION 1.9.3
    var v1_9_3 = ChangeLogItem();
    v1_9_3.main.version = 'Torn PDA v1.9.3';
    String feat1_9_3_1 =
        "Fixed error with messages titles, preventing some users from loading the Profile section entirely";
    String feat1_9_3_2 = "Corrected emojis representation in message titles";
    v1_9_3.features.add(feat1_9_3_1);
    v1_9_3.features.add(feat1_9_3_2);

    // VERSION 1.9.2
    var v1_9_2 = ChangeLogItem();
    v1_9_2.main.version = 'Torn PDA v1.9.2';
    String feat1_9_2_1 =
        "Profile: new shortcuts to your preferred game sections. Use the existing ones or configure your own. Short/long tap to open a quick or full browser";
    String feat1_9_2_2 = "Profile: added a new card for received messages";
    String feat1_9_2_3 = "Profile: added option to configure which cards are expanded or collapsed by default";
    String feat1_9_2_4 = "Profile: the Basic Information card can now be collapsed";
    String feat1_9_2_5 = "Browser: added loading progress bar (can be disabled)";
    String feat1_9_2_6 = "Browser: quick crimes are now placed at the bottom when using a bottom app bar";
    String feat1_9_2_7 = "Increased size of quick browser";
    String feat1_9_2_8 = "Fixed error with chaining indications for players with no faction";
    v1_9_2.features.add(feat1_9_2_1);
    v1_9_2.features.add(feat1_9_2_2);
    v1_9_2.features.add(feat1_9_2_3);
    v1_9_2.features.add(feat1_9_2_4);
    v1_9_2.features.add(feat1_9_2_5);
    v1_9_2.features.add(feat1_9_2_6);
    v1_9_2.features.add(feat1_9_2_7);
    v1_9_2.features.add(feat1_9_2_8);

    // VERSION 1.9.1
    var v1_9_1 = ChangeLogItem();
    v1_9_1.main.version = 'Torn PDA v1.9.1';
    String feat1_9_1_1 =
        "Profile: added several additional quick browser triggers (tap on the happy bar, life bar or the points icon)";
    String feat1_9_1_2 = "Profile: added addiction icon and information to miscellaneous";
    String feat1_9_1_3 = "Profile: added effective battle stats calculation";
    String feat1_9_1_4 =
        "Profile: added chain information and warning (in case you are heading to the gym and unaware of the chain)";
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
    v1_9_0.main.version = 'Torn PDA v1.9.0';
    String feat1_9_0_1 = "Alerts: added nerve to automatic alerts";
    String feat1_9_0_2 = "Quick actions: long press app icon (supported devices) to launch Torn from home screen";
    String feat1_9_0_3 =
        "Profile: tapping your energy or nerve bars will open a small browser to the gym or crimes, easier than ever";
    String feat1_9_0_4 = "Profile: added stats, points and other useful information";
    String feat1_9_0_5 =
        "Travel: you can now sort by quantity and see how many items of each type you already possess (can be disabled)";
    String feat1_9_0_6 =
        "Travel: when you click a flag, you'll also get a check on if you have sufficient money on hand to fill your capacity with the item you selected";
    String feat1_9_0_7 = "Bazaar: added button to fill maximum quantities automatically";
    String feat1_9_0_8 =
        "Browser: changed top-left icon to better show if the browser is going to close (X) or go back (arrow). If visiting a vault after a trade, it now goes back to Trades.";
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
    v1_8_6.main.version = 'Torn PDA v1.8.6';
    String feat1_8_6_1 =
        "Trading: if you are a professional trader and an user of Torn Trader, you can now activate a real time sync with your own prices, custom messages and receipt through the Trade Calculator (see options when in the Trade page in Torn to activate)";
    String feat1_8_6_2 =
        "Trading: a new icon will redirect you directly to your personal, faction or company vault after a trade, so that you can keep your money safe from muggers";
    String feat1_8_6_3 = "Profile: racing status added to the miscellaneous card";
    String feat1_8_6_4 = "Minor bug fixes";
    v1_8_6.features.add(feat1_8_6_1);
    v1_8_6.features.add(feat1_8_6_2);
    v1_8_6.features.add(feat1_8_6_3);
    v1_8_6.features.add(feat1_8_6_4);

    // VERSION 1.8.5
    var v1_8_5 = ChangeLogItem();
    v1_8_5.main.version = 'Torn PDA v1.8.5';
    String feat1_8_5_1 =
        "The colour of your targets' notes is now exported and imported to/from YATA (in the process, blue colour was transformed into orange for standardization)";
    String feat1_8_5_2 =
        "While chaining, you'll be shown your note for each target before attacking, so that you can adjust your strategy accordingly (can be disabled)";
    String feat1_8_5_3 = "You can now sort targets by note colour";
    String feat1_8_5_4 = "Fixed an issue where the target note could not be updated right after attacking";
    v1_8_5.features.add(feat1_8_5_1);
    v1_8_5.features.add(feat1_8_5_2);
    v1_8_5.features.add(feat1_8_5_3);
    v1_8_5.features.add(feat1_8_5_4);

    // VERSION 1.8.4
    var v1_8_4 = ChangeLogItem();
    v1_8_4.main.version = 'Torn PDA v1.8.4';
    String feat1_8_4_1 =
        "Chaining: you can now export and import all your targets to/from YATA, including personal notes";
    String feat1_8_4_2 = "Chaining: there is a new option to wipe all your targets (use carefully)";
    String feat1_8_4_3 = "Profile: you can now schedule travel notifications directly from the profile section";
    String feat1_8_4_4 =
        "Browser: swipe left/right in the top bar to browse forward/back. Also fixed an error that prevented some links (forum/profiles) from working properly.";
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
    v1_8_3.main.version = 'Torn PDA v1.8.3';
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
    v1_8_2.main.version = 'Torn PDA v1.8.2';
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
    v1_8_1.main.version = 'Torn PDA v1.8.1';
    String feat1_8_1_1 = "Loot: increased trigger options for loot notifications";
    String feat1_8_1_2 = "Profile: corrected an issue causing delays when updating miscellaneous "
        "information";
    v1_8_1.features.add(feat1_8_1_1);
    v1_8_1.features.add(feat1_8_1_2);

    // VERSION 1.8.0
    var v1_8_0 = ChangeLogItem();
    v1_8_0.main.version = 'Torn PDA v1.8.0';
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
    v1_7_1.main.version = 'Torn PDA v1.7.1';
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
    v1_7_0.main.version = 'Torn PDA v1.7.0';
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
    v1_6_2.main.version = 'Torn PDA v1.6.2';
    String feat1_6_2_1 = "Fixes error when loading API Key and the profile page for players "
        "that have deleted all their incoming events";
    v1_6_2.features.add(feat1_6_2_1);

    // VERSION 1.6.0
    var v1_6_0 = ChangeLogItem();
    v1_6_0.main.version = 'Torn PDA v1.6.0';
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
    v1_5_0.main.version = 'Torn PDA v1.5.0';
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
    v1_4_1.main.version = 'Torn PDA v1.4.1';
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
    v1_4_0.main.version = 'Torn PDA v1.4.0';
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
    v1_3_0.main.version = 'Torn PDA v1.3.0';
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
    itemList.add(v2_6_0);
    itemList.add(v2_5_3);
    itemList.add(v2_5_2);
    itemList.add(v2_5_1);
    itemList.add(v2_5_0);
    itemList.add(v2_4_3);
    itemList.add(v2_4_2);
    itemList.add(v2_4_1);
    itemList.add(v2_4_0);
    itemList.add(v2_3_5);
    itemList.add(v2_3_4);
    itemList.add(v2_3_3);
    itemList.add(v2_3_2);
    itemList.add(v2_3_1);
    itemList.add(v2_3_0);
    itemList.add(v2_2_0);
    if (Platform.isIOS) itemList.add(v2_1_1);
    itemList.add(v2_1_0);
    itemList.add(v2_0_0);
    itemList.add(v1_9_7);
    itemList.add(v1_9_6);
    itemList.add(v1_9_5);
    itemList.add(v1_9_4);
    itemList.add(v1_9_3);
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
      _changeLogItems.putIfAbsent(itemList[i].main, () => itemList[i].features);
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
                child: ElevatedButton(
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
    var itemList = <Widget>[];
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
          padding: const EdgeInsets.only(bottom: 0),
          child: Text(
            entry.key.version,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            entry.key.date,
            style: TextStyle(
              fontSize: 11,
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
