// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ChangeLogItem {
  String version = "";
  String date = "";
  List<dynamic> features = [];
  bool showInfoLine = false;
  String infoString = "";
}

class ComplexFeature {
  final String text;
  final String? explanation;
  final int? secondsToShow;
  final bool closeButton;

  ComplexFeature(
    this.text, {
    this.explanation,
    this.secondsToShow,
    this.closeButton = false,
  });
}

class ChangeLog extends StatefulWidget {
  @override
  ChangeLogState createState() => ChangeLogState();
}

class ChangeLogState extends State<ChangeLog> {
  final _changeLogItems = <ChangeLogItem, List<dynamic>>{};
  final _scrollController = ScrollController();

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
    final itemList = <ChangeLogItem>[];

    // v3.7.3 - Build 509 - 08/04/2025
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.7.3'
        ..date = '15 APR 2025'
        ..features = [
          "Alerts: company messages can now be filtered out in chat notifications",
          "Added Wiki to the main drawer menu",
          ComplexFeature(
            "Added accesible text color option",
            explanation: "See Settings / Theme.\n\n"
                "Activate this option to replace all colored texts with the default text color (white or black). "
                "\n\nThis can improve readability for users with color vision deficiencies, but might make "
                "it harder to identify the performance of some indicators."
                "\n\nNote: this option only applies to the app and not to the web, "
                "and is not yet available in all sections. You can contact us to offer further suggestions.",
          ),
          ComplexFeature(
            "Added notes to player profile widgets",
            explanation: "Enabled by default. See Settings / Advanced Browser Settings / Player Profiles\n\n"
                "If enabled, this will show a notes widget in the profile page "
                "for those players that you have added notes to (as friends, stakeouts or targets)"
                "\n\nThe notes icon is actionable (tap to change notes)",
          ),
          "Notes are now properly shared between targets, war target, stakeouts and friends",
          "Added new webview handlers to show a native toast and force a page reload from native code",
          "Flower and Plushie sets are now properly identified in Torn Exchange trades",
          "Fixed trade page not updating automatically when the other user updates the contents",
          "Fixed issues with HTML spacing in forums",
          "Fixed issues when hiding chat",
          if (Platform.isAndroid) "Fixed home screen widget sizing and update frequency issues",
        ],
    );

    // v3.7.2 - Build 505 - 22/03/2025
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.7.2'
        ..date = '01 APR 2025'
        ..features = [
          "Improved information provided for OC 2",
          ComplexFeature(
            "User scripts: added handlers to schedule notifications from JS code (see details)",
            explanation: "You can trigger native notifications from your user scripts using the "
                "new handlers available. This also includes alarms and timers for Android.\n\n"
                "Please refer to the disclaimer in the user scripts section, or visit Torn PDA's wiki or "
                "./docs section in Github for more information.\n\n"
                "A test website has also been created to help you understand the different features available.",
          ),
          ComplexFeature(
            "Browser: improved developer terminal (see details)",
            explanation: "The terminal can now be resized, shared and its text is selectable.\n\n"
                "You can also expand the terminal in a dialog covering the whole screen, which includes the capacity "
                "to enter text and execute commands.\n\n"
                "Terminals are now independent for each tab, and you can also clear them individually.",
          ),
          "Chaining: targets can now be sorted by time added",
          "Alerts: added events notification filter for market sales",
          if (Platform.isAndroid)
            "Fixed app widget not resizing properly to one row in certain devices (requires re-adding)",
          "Fixed browser opening images several times in a row",
          "Fixed airplane removal setting while traveling",
          "Fixed API key not working when pasted in certain devices",
        ],
    );

    // v3.7.1 - Build 497 - 20/02/2025
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.7.1'
        ..date = '25 FEB 2025'
        ..features = [
          "Alerts: faction messages can now be filtered out in chat notifications",
          ComplexFeature(
            "Added navigation arrows to the browser (see details)",
            explanation: "Forward and backward navigation arrows can now be shown in the browser "
                "when using the default browser style.\n\n"
                "The default configuration is to show them only in wide-screen mode, but you can "
                "force them to always be visible, even on narrower screens. In this case, please note that Torn PDA "
                "will do its best to accommodate the icons, but they may not always be displayed "
                "(e.g., when other icons need to be shown, such as when chaining).\n\n"
                "You can change this configuration in Settings / Advanced Browser Settings / Show Navigation Arrows",
          ),
          "Fixed chat notifications",
          "Fixed deep links issues",
          "Fixed deactivation of money on hand travel warning from dialog",
        ],
    );

    // v3.7.0 - Build 492 - 08/02/2025
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.7.0'
        ..date = '14 FEB 2025'
        ..features = [
          ComplexFeature(
            "Alerts: added notification for subscribed forum threads",
            explanation: "Disabled by default: you can enable it in Alerts"
                "\n\nNOTE: in order to reduce API load, checks will be performed "
                "every 15 minutes, so the notification may not be immediate "
                "after a new post is made",
          ),
          ComplexFeature(
            "Profile: added OC v2 information to the misc card",
            explanation: "Torn PDA will try to assess whether your faction has already switched to OC v2 "
                "every couple of days (in order to save API calls). Hoever, you can manually set the OC version in "
                "Settings / Organized Crime\n\n"
                "Should you wish to return to OC v1 (if you join a faction that hasn't changed yet), remember "
                "to revert the OC version in Settings",
          ),
          ComplexFeature(
            "Clock now highlights active events and competitions",
            explanation: "Enabled by default (can be disabled in Settings > Time).\n\n"
                "Tapping the clock will now display a toast notification when an event or competition is active, showing "
                "details and the remaining time until it ends.",
          ),
          "Added full-screen browser as default app launch option",
          "Added minimum money on hand to the travel warning dialog",
          if (Platform.isIOS) "Added additional app icons",
          "Scripts and UI fixes [Kwack]",
        ],
    );

    // v3.6.8 - Build 483 - 22/01/2025
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.6.8'
        ..date = '26 JAN 2025'
        ..features = [
          "Enhanced browser floating action button with additional customization options for buttons and actions",
          "Fixed player profile widget",
          "Fixed estimated stats calculation",
          "Fixed player level calculation for recent attacks [Tenren]",
          "Fixed relative time calculation for events in the past",
          "Fixed margin issues when browser is started in full screen mode with hidden tabs",
        ],
    );

    // v3.6.7 - Build 480 - 28/12/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.6.7'
        ..date = '30 DEC 2024'
        ..infoString = "Hotfix: resolved issues with the travel widget and graphic "
            "display problems on certain devices"
        ..features = [
          "Profile: added user's market items details",
          ComplexFeature(
            "Browser: added Floating Action Button (see Tips!)",
            explanation: "Disabled by default: you can enable it in Settings / Advanced Browser Settings"
                "\n\nIt is HIGHLY recommended that you visit the Tips section to understand "
                "how to properly use this feature to its full potential"
                "\n\nThe Floating Action Button is a feature that allows you to perform "
                "indirect actions on your tabs as well as some direct navigation actions. "
                "It has several functions that are important to know to get the most out of it.\n\n"
                "This can have many uses and help in a multitude of situations. It can also "
                "prevent involuntarily activating voice commands or assistants when double- "
                "or triple-tapping the bottom edge in some devices.",
          ),
          "Trades: added button to copy Torn Exchange receipt URL",
          "Fixed an issue preventing some web interactions in certain devices",
        ],
    );

    // v3.6.4 - Build 471 - 14/12/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.6.4'
        ..date = '15 DEC 2024'
        ..infoString = 'Hotfix: resolved incorrect estimated stats calculation in the War section'
        ..features = [
          "Fixed player profile widget",
          "Fixed chat notifications in split screen",
        ],
    );

    // v3.6.2 - Build 467 - 07/11/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.6.2'
        ..date = '09 DEC 2024'
        ..infoString = 'Hotfix: resolved an issue affecting the reordering of tabs'
        ..features = [
          "Added channel info to chat notifications",
          "Fixed notifications for own chat messages",
          "Fixed cooldown calculations for traveling",
          "Fixed deep links issues",
          "Fixed revive icon in Profile",
          "Fixed browser search",
        ],
    );

    // v3.6.0 - Build 463 - 01/11/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.6.0'
        ..date = '05 DEC 2024'
        ..features = [
          ComplexFeature(
            "Added chat notifications (disabled by default)",
            explanation: "You can toggle them in the Alerts section!",
          ),
          "Added browser links to the Events timeline in Profile",
          ComplexFeature(
            "Added option to remove unused tabs",
            explanation: "Manual trigger: use the triple-dotted icon in the browser's tab bar, "
                "then tab the red bin icon to see more options.\n\n"
                "Automatic task: activate a periodic removal in Settings / Advanced Browser Settings / Tabs",
          ),
          "War: added option to sort by travel distance",
          ComplexFeature(
            "Adapted auto-price script for new market [Kwack]",
            explanation: "With the introduction of the new market system, "
                "the old bazaar auto-price script has been adapted to work with "
                "this new market.\n\nIf you had the official script installed, "
                "you will receive a notification to update; if you installed "
                "it manually, you will need to update the code manually "
                "or restore the example scripts.",
          ),
          "Improved error handling for TSC [Mavri]",
          if (Platform.isIOS) "Added option to manually override themed app icon",
          if (Platform.isAndroid)
            ComplexFeature(
              "Added battery optimization checks for home widget",
              explanation: "A battery optimization check has been added to Tips and the app widget "
                  "installation process to warn the user about battery settings (since "
                  "they might restrict the widget's funcionality).\n\n"
                  "If you already have a home widget installed, this will cause "
                  "the original dialog to be launched the next time you open Torn PDA.",
            ),
          "Chaining browser can now be opened in full-screen mode (disabled by default)",
          ComplexFeature(
            "Added option to remove quick return button when traveling",
            explanation: "You can find this in Settings / Advanced Browser Settings / Travel\n\n"
                "Defaults to disabled (return button will show)",
          ),
          "Added app upgrade dialog",
          if (Platform.isAndroid) "Fixed high screen refresh support",
          "Fixed market information in the Items section",
          "Fixed targets backup import dialog",
          "Fixed multiple max buy buttons abroad",
          "Fixed Torn Stats pie chart representation",
        ],
    );

    // v3.5.2 - Build 450 - 13/10/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.5.2'
        ..date = '20 OCT 2024'
        ..features = [
          ComplexFeature(
            "Added option to reverse swipe navigation direction in browser title",
            explanation: "Go to Settings / Advanced Browser Settings\n\nLook for 'Gestures'",
          ),
          ComplexFeature(
            "Added option to open new tabs in the background",
            explanation: "Go to Settings / Advanced Browser Settings\n\nLook for 'Tabs'\n\n"
                "By default, when you open a new tab via the 'open in new tab' option, when long-pressing "
                "a link, the browser will change to the newly created tab. If you disable this, the new tab "
                "will be created but you will remain in the current one",
          ),
          ComplexFeature(
            "Added option to open background tab from tabs with a full lock",
            explanation: "Go to Settings / Advanced Browser Settings\n\nLook for 'Tab Locks'\n\n"
                'If enabled, a navigation attempt from a tab with a full lock will open a new tab in the background '
                '(the tab will be added but the browser will not switch to it automatically)\n\n'
                "(disabled by default)",
          ),
          if (Platform.isAndroid)
            ComplexFeature(
              "Improved home screen widget functionality",
              explanation: "Go to Settings / Home Screen Widget\n\n"
                  "An additional short layout with not shortcuts has been added\n\n"
                  "You can now choose the behavior when tapping on cooldowns and whether to browse to your own "
                  "items or to your faction's armoury",
            ),
          ComplexFeature(
            "Increased time selection for manual loot notifications",
            explanation: "Go to Loot / Time icon (top right)\n\n"
                '8 & 10 minutes options have been added',
          ),
          "Improved backwards navigation in certain sections",
          "Fixed initial load of tabs with a full lock",
          "Fixed energy and nerve bars double click redirects",
        ],
    );

    // v3.5.1 - Build 447 - 28/09/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.5.1'
        ..date = '01 OCT 2024'
        ..features = [
          "Added configurable tap actions for cooldown alerts",
          "Added support for basic HTTP authentication",
          if (Platform.isIOS) "Added icon theme support on iOS 18",
          "Fixed networth and wallet money in Profile [Kwack]",
          "Fixed missing pickpocketing information when sharing scores",
          if (Platform.isIOS) "Fixed status bar theme on iOS",
          "Fixed energy travel expenditure warning triggering when disabled",
          "Improved mouse compatibility",
          "Updated platform and packages",
        ],
    );

    // v3.5.0 - Build 444 - 07/09/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.5.0'
        ..date = '12 SEP 2024'
        ..features = [
          "Browser tabs can now be locked (see Tips)",
          "Browser tabs can now be given a custom name (see Tips)",
          "War targets' stats can now be shared (top gear icon)",
          "Added Scamming crime to Misc tab in Profile",
          "Added faction applications to alerts events filters",
          "Added min/max range to the travel expenditure warning (reset to default)",
          "Increased time selection for manual hospital release notifications",
          "Improved troubleshooting steps for issues with Alerts",
          "Improved browser reload capability when frozen",
          "Fixed browser not returning to full screen after web search",
          "Fixed other reported issues",
        ],
    );

    // v3.4.4 - Build 435 - 20/07/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.4.4'
        ..date = '01 AUG 2024'
        ..features = [
          "Added Travel Agency expenditure warning for bars and cooldowns (can be disabled)",
          "Fixed browser text search in full screen mode",
          "Fixed faction link to medical items for life notification",
        ],
    );

    // v3.4.3 - Build 432 - 03/07/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.4.3'
        ..date = '10 JUL 2024'
        ..features = [
          "Added new automatic alert for full life bar",
          "Foreign stock alerts can now be enabled for the current country only",
          "Added approximate restock time to depleted foreign stocks",
          "Added manual notification for race start (Profile Misc)",
          "Targets can now be sorted by time to hospital release",
          "Added YATA stats estimates to stats dialog",
          "Added bounty claims and referrals to alerts events filters",
          "Added clarification dialog for Torn forum bug posts created from Torn PDA [Kwack]",
          "Fixed downloads for blob files [Kwack]",
          "Fixed retaliation notifications not opening browser when the app is in the background",
          "Fixed delays in foreign stocks uploads to providers",
        ],
    );

    // v3.4.2 - Build 426 - 31/05/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.4.2'
        ..date = '04 JUN 2024'
        ..features = [
          "Added traveling filter in War",
          "Added highlight for user's own OC [Kwack]",
          "Added user's age in words in profiles [Kwack]",
          "Added option to manually report and update Torn Stats' chart",
          "Fixed issues with TSC model",
          "Fixed status color widget margins",
          "Fixed issues when restoring settings from cloud save [Kwack]",
        ],
    );

    // v3.4.1 - Build 415 - 05/05/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.4.1'
        ..date = '15 MAY 2024'
        ..features = [
          "War: added red status filter and notifications for jail and hospital release",
          "Fixed some erroneous values and profits shown in Foreign Stocks",
          "Fixed default launch section dropdown menu",
          "Fixed share dialog in certain devices",
        ],
    );

    // v3.4.0 - Build 412 - 21/04/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.4.0'
        ..date = '26 APR 2024'
        ..features = [
          "Added player status color counter widget in PDA icon and browser (can be disabled)",
          "Added Prometheus as a Foreign Stocks provider with automatic failover",
          "Fixed user backup share with other players",
          "Fixed issues with chat highlight [Kwack]",
          "Fixed issue with pinned war targets",
          if (Platform.isAndroid) "Fixed home widget manual reload button",
          "Fixed theme issues",
        ],
    );

    // v3.3.2 - Build 402 - 06/04/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.3.2'
        ..date = '15 APR 2024'
        ..features = [
          "Added bounty information to targets cards in Chaining (target update is required)",
          "Added colored shadow to status card (can be disabled)",
          "Stock market section: added pull to refresh",
          "Added new tab option when quickly accessing vaults from trades",
          "Fixed Items section filters (item types)",
          "Fixed Company Activity example user script",
          "Fixed mini-profiles not opening in new tab when enabled",
          "Fixed total spied stats count",
          "Fixed other reported issues",
        ],
    );

    // v3.3.1 - Build 394 - 01/04/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.3.1'
        ..date = '04 APR 2024'
        ..features = [
          "Added Torn Exchange sync in the trades widget",
          "Added Forgery crime to Misc tab in Profile",
          "Fixed chat highlight and added custom word list [Kwack]",
          "Added device theme sync (disabled by default)",
          "Adjusted foreign stocks charts timeframe based on number of recent restocks",
          if (Platform.isAndroid) "Browser font size can now be adjusted (Advanced Browser Settings)",
          "Added headers parameters to PDA_httpGet handler [tiksan]",
          "Fixed issues with time calculation",
          "Fixed spies update times",
          "Other several fixes",
        ],
    );

    // v3.3.0 - Build 382 - 18/02/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.3.0'
        ..date = '25 FEB 2024'
        ..features = [
          "Improved user script manager: includes remote fetching, auto update, auto JS file import and fixes [Kwack]",
          "Added private cloud backup and share functionality for specific Torn PDA settings",
          "Added Torn Spies Central information and merged stats dialogs into one",
          "Spies: added option to allow mixed sources, fixed persistence and other issues",
          "War cards can now be pinned (right swipe)",
          "Added option to delay API calls before hitting the API limit (disabled by default)",
          "Downloaded files trigger a share request automatically by default (see Tips for more info)",
          "Added option to enable or disable browser cache (enabled by default)",
          "Added pie option for Torn Stats chart",
          "Added API permission donor option for retaliation alerts",
          "Added Midnight X reviving services",
          "Fixed Awards images",
          "Fixed RW widget update in Profile",
          "Fixed other reported issues",
        ],
    );

    // v3.2.5 - Build 374 - 04/01/2024
    itemList.add(
      ChangeLogItem()
        ..version = 'Torn PDA v3.2.5'
        ..date = '08 JAN 2024'
        ..features = [
          "Improved browser performance and stability",
          "Fixed Company Stock Order example userscript [Kwack]",
          "Fixed energy stacking warning in certain devices",
        ],
    );

    // VERSION 3.2.4
    final v3_2_4 = ChangeLogItem();
    v3_2_4.version = 'Torn PDA v3.2.4';
    v3_2_4.date = '28 DEC 2023';
    const String feat3_2_4_1 = "Added Cracking to Basic Info card in Profile";
    const String feat3_2_4_2 = "Fixed browser crashes in certain devices";
    v3_2_4.features.add(feat3_2_4_1);
    v3_2_4.features.add(feat3_2_4_2);

    // VERSION 3.2.3
    final v3_2_3 = ChangeLogItem();
    v3_2_3.version = 'Torn PDA v3.2.3';
    v3_2_3.date = '20 DEC 2023';
    const String feat3_2_3_1 = "Added deep links and default app explanation in Tips";
    const String feat3_2_3_2 = "Fixed browser download issues on iOS";
    const String feat3_2_3_3 = "Fixed audio channels mixing in Chain Watcher";
    const String feat3_2_3_4 = "Fixed timezone references";
    const String feat3_2_3_5 = "Fixed issues with API model";
    const String feat3_2_3_6 = "Fixed random logouts";
    v3_2_3.features.add(feat3_2_3_1);
    if (Platform.isIOS) v3_2_3.features.add(feat3_2_3_2);
    v3_2_3.features.add(feat3_2_3_3);
    v3_2_3.features.add(feat3_2_3_4);
    v3_2_3.features.add(feat3_2_3_5);
    v3_2_3.features.add(feat3_2_3_6);

    // VERSION 3.2.2
    final v3_2_2 = ChangeLogItem();
    v3_2_2.version = 'Torn PDA v3.2.2';
    v3_2_2.date = '08 DEC 2023';
    String feat3_2_2_1 = Platform.isAndroid
        ? "Improved deep links native support (added info dialog if external browser is used)"
        : "Improved deep links native support";
    const String feat3_2_2_2 = "Adjusted material theme colors";
    const String feat3_2_2_3 = "Fixed NNB widget activation";
    const String feat3_2_2_4 = "Fixed localStorage not resetting when browser cache was cleared";
    const String feat3_2_2_5 = "Fixed random browser crashes reported on iOS";
    v3_2_2.features.add(feat3_2_2_1);
    v3_2_2.features.add(feat3_2_2_2);
    v3_2_2.features.add(feat3_2_2_3);
    v3_2_2.features.add(feat3_2_2_4);
    v3_2_2.features.add(feat3_2_2_5);

    // VERSION 3.2.1
    final v3_2_1 = ChangeLogItem();
    v3_2_1.version = 'Torn PDA v3.2.1';
    v3_2_1.date = '01 DEC 2023';
    const String feat3_2_1_1 =
        "Added Grease Monkey handlers to userscripts (read Disclaimer in userscripts section) - by Kwack";
    const String feat3_2_1_2 = "Added file download support to browser";
    const String feat3_2_1_3 = "Added Material theme support (disabled by default)";
    const String feat3_2_1_4 = "Tapping player name in mini-profiles opens new tab (disabled by default)";
    const String feat3_2_1_5 = "Increased to 10 the max. number of red/blue targets to be skipped while chaining";
    const String feat3_2_1_6 = "Added chain control buttons to main browser tab (single/double tap) while chaining";
    const String feat3_2_1_7 = "Added missing crimes to Basic Info card";
    const String feat3_2_1_8 = "Added additional information to Loot Rangers attack status in certain conditions";
    const String feat3_2_1_9 = "Added local time to War widget in Profile and fixed issue with alarms";
    const String feat3_2_1_10 = "Fixed stakeouts update when more than 10 targets are configured";
    const String feat3_2_1_11 = "Fixed issue when opening the spied stats dialog";
    const String feat3_2_1_12 = "Fixed issue updating new/former faction members in War";
    const String feat3_2_1_13 = "Fixed some shortcuts URLs (need to re-add)";
    const String feat3_2_1_14 = "Fixed time format (12/24h) setting in several sections";
    const String feat3_2_1_15 = "Fixed persistence of setting to only load tabs when used";
    const String feat3_2_1_16 = "Removed unusable inventory filter in Items";
    v3_2_1.features.add(feat3_2_1_1);
    v3_2_1.features.add(feat3_2_1_2);
    v3_2_1.features.add(feat3_2_1_3);
    v3_2_1.features.add(feat3_2_1_4);
    v3_2_1.features.add(feat3_2_1_5);
    v3_2_1.features.add(feat3_2_1_6);
    v3_2_1.features.add(feat3_2_1_7);
    v3_2_1.features.add(feat3_2_1_8);
    v3_2_1.features.add(feat3_2_1_9);
    v3_2_1.features.add(feat3_2_1_10);
    v3_2_1.features.add(feat3_2_1_11);
    v3_2_1.features.add(feat3_2_1_12);
    v3_2_1.features.add(feat3_2_1_13);
    v3_2_1.features.add(feat3_2_1_14);
    v3_2_1.features.add(feat3_2_1_15);
    v3_2_1.features.add(feat3_2_1_16);

    // VERSION 3.2.0
    final v3_2_0 = ChangeLogItem();
    v3_2_0.version = 'Torn PDA v3.2.0';
    v3_2_0.date = '15 NOV 2023';
    const String feat3_2_0_1 = "Reconfigured how spies are retrieved (now manually) to speed up loading times of the "
        "Profile Widget, as well as the War and Retalation sections. Make sure to check Tips and Settings for further information.";
    const String feat3_2_0_2 = "Added Chain Watcher alert if API fails under watch";
    const String feat3_2_0_3 = "Fixed chat hide feature";
    const String feat3_2_0_4 = "Fixed chat highlight feature";
    const String feat3_2_0_5 = "Fixed several issues caused by lack of inventory details";
    v3_2_0.features.add(feat3_2_0_1);
    v3_2_0.features.add(feat3_2_0_2);
    v3_2_0.features.add(feat3_2_0_3);
    v3_2_0.features.add(feat3_2_0_4);
    v3_2_0.features.add(feat3_2_0_5);

    // VERSION 3.1.9
    final v3_1_9 = ChangeLogItem();
    v3_1_9.version = 'Torn PDA v3.1.9';
    v3_1_9.date = '30 OCT 2023';
    const String feat3_1_9_1 = "Fixed sections affected by API changes in inventory";
    const String feat3_1_9_2 = "Fixed property vault widget assignments";
    const String feat3_1_9_3 = "Fixed long tap menu in quick profiles";
    const String feat3_1_9_4 = "Fixed War options menu and reviving providers";
    const String feat3_1_9_5 = "Fixed jail widget max score dialog";
    v3_1_9.features.add(feat3_1_9_1);
    v3_1_9.features.add(feat3_1_9_2);
    v3_1_9.features.add(feat3_1_9_3);
    v3_1_9.features.add(feat3_1_9_4);
    v3_1_9.features.add(feat3_1_9_5);

    // VERSION 3.1.8
    final v3_1_8 = ChangeLogItem();
    v3_1_8.version = 'Torn PDA v3.1.8';
    v3_1_8.date = '18 OCT 2023';
    const String feat3_1_8_1 = "Added crimes to Basic Info card in Profile";
    const String feat3_1_8_2 = "Browser tabs can be now positioned below the navigation bar in bottom-bar styles";
    const String feat3_1_8_3 = "Fixed Tips section";
    const String feat3_1_8_4 = "Fixed stock market price dialog";
    const String feat3_1_8_5 = "Fixed stats chart rounding";
    v3_1_8.features.add(feat3_1_8_1);
    v3_1_8.features.add(feat3_1_8_2);
    v3_1_8.features.add(feat3_1_8_3);
    v3_1_8.features.add(feat3_1_8_4);
    v3_1_8.features.add(feat3_1_8_5);

    // VERSION 3.1.7
    final v3_1_7 = ChangeLogItem();
    v3_1_7.version = 'Torn PDA v3.1.7';
    v3_1_7.date = '16 SEP 2023';
    const String feat3_1_7_1 = "Fixed city finder widget";
    const String feat3_1_7_2 = "Fixed recent attacks (incorrectly classified)";
    v3_1_7.features.add(feat3_1_7_1);
    v3_1_7.features.add(feat3_1_7_2);

    // VERSION 3.1.5 + HOTFIX (3.1.6)
    final v3_1_6 = ChangeLogItem();
    v3_1_6.version = 'Torn PDA v3.1.6';
    v3_1_6.date = '15 SEP 2023';
    v3_1_6.infoString = 'Hotfix to address blank screen issues';
    const String feat3_1_6_1 = "Added split screen mode between browser and app";
    const String feat3_1_6_2 = "Browser: long press in title opens shortcuts (default style)";
    const String feat3_1_6_3 = "Browser: the terminal can now be cleared";
    const String feat3_1_6_4 = "Jail widget: added option to disable filters";
    const String feat3_1_6_5 = "Added support for longer Torn Stats API keys";
    const String feat3_1_6_6 = "Fixed double tap in energy and nerve bars";
    const String feat3_1_6_7 = "Fixed issues when adding or updating targets and friends";
    const String feat3_1_6_8 = "Fixed retalation alerts (re-enable if still not working)";
    const String feat3_1_6_9 = "Fixed show oneself and score dialog settings in jail widget";
    const String feat3_1_6_10 = "Fixed JS handlers (get, post, inject) for scripts";
    const String feat3_1_6_11 = "Update packages";
    v3_1_6.features.add(feat3_1_6_1);
    v3_1_6.features.add(feat3_1_6_2);
    v3_1_6.features.add(feat3_1_6_3);
    v3_1_6.features.add(feat3_1_6_4);
    v3_1_6.features.add(feat3_1_6_5);
    v3_1_6.features.add(feat3_1_6_6);
    v3_1_6.features.add(feat3_1_6_7);
    v3_1_6.features.add(feat3_1_6_8);
    v3_1_6.features.add(feat3_1_6_9);
    v3_1_6.features.add(feat3_1_6_10);
    v3_1_6.features.add(feat3_1_6_11);

    // VERSION 3.1.4
    final v3_1_4 = ChangeLogItem();
    v3_1_4.version = 'Torn PDA v3.1.4';
    v3_1_4.date = '28 JUN 2023';
    const String feat3_1_4_1 = "Browser full screen: added gear icon to '...' vertical menu to access further options";
    const String feat3_1_4_2 = "Browser full screen: added two extra tabs to exit and reload the "
        "browser directly (both disabled by default)";
    const String feat3_1_4_3 = "Fixed stock market alerts page for users with no shares";
    const String feat3_1_4_4 = "Fixed profile check widget in named URLs";
    const String feat3_1_4_5 = "Fixed widgets and chats not correctly hiding in full screen browser";
    const String feat3_1_4_6 = "Fixed other reported issues";
    v3_1_4.features.add(feat3_1_4_1);
    v3_1_4.features.add(feat3_1_4_2);
    v3_1_4.features.add(feat3_1_4_3);
    v3_1_4.features.add(feat3_1_4_4);
    v3_1_4.features.add(feat3_1_4_5);
    v3_1_4.features.add(feat3_1_4_6);

    // VERSION 3.1.3
    final v3_1_3 = ChangeLogItem();
    v3_1_3.version = 'Torn PDA v3.1.3';
    v3_1_3.date = '22 JUN 2023';
    const String feat3_1_3_1 = "Fixed events duplication in Profile";
    v3_1_3.features.add(feat3_1_3_1);

    // VERSION 3.1.2
    final v3_1_2 = ChangeLogItem();
    v3_1_2.version = 'Torn PDA v3.1.2';
    v3_1_2.date = '20 JUN 2023';
    const String feat3_1_2_1 = "Added triple tap gesture to instantly close a browser tab";
    const String feat3_1_2_2 = "Fixed travel button browser redirection";
    const String feat3_1_2_3 = "Fixed profile pages redirection";
    const String feat3_1_2_4 = "Fixed section routing with back button press";
    v3_1_2.features.add(feat3_1_2_1);
    v3_1_2.features.add(feat3_1_2_2);
    v3_1_2.features.add(feat3_1_2_3);
    v3_1_2.features.add(feat3_1_2_4);

    // VERSION 3.1.1
    final v3_1_1 = ChangeLogItem();
    v3_1_1.version = 'Torn PDA v3.1.1';
    v3_1_1.date = '15 JUN 2023';
    const String feat3_1_1_1 = "Added browser styles (including the former quick browser appearance)";
    const String feat3_1_1_2 = "Changed gesture settings in the ellipsis (...) browser button to allow a "
        "faster access to shortcuts (please see Tips)";
    const String feat3_1_1_3 = "Added wallet money to home screen widget (optional)";
    const String feat3_1_1_4 = "Fixed some reported problems with unresponsive browser";
    const String feat3_1_1_5 = "Fixed redirection links in Profile and Loot";
    const String feat3_1_1_6 = "Fixed iOS 14 crashes";
    v3_1_1.features.add(feat3_1_1_1);
    v3_1_1.features.add(feat3_1_1_2);
    if (Platform.isAndroid) v3_1_1.features.add(feat3_1_1_3);
    v3_1_1.features.add(feat3_1_1_4);
    v3_1_1.features.add(feat3_1_1_5);
    if (Platform.isIOS) v3_1_1.features.add(feat3_1_1_6);

    // VERSION 3.1.0
    final v3_1_0 = ChangeLogItem();
    v3_1_0.version = 'Torn PDA v3.1.0';
    v3_1_0.date = '12 JUN 2023';
    const String feat3_1_0_1 = "Added home screen widget (see Tips)";
    const String feat3_1_0_2 = "Browser: complete workflow restructure (faster access and loading)";
    const String feat3_1_0_3 = "Browser: quick browser removed, full screen mode and vertical menus added";
    const String feat3_1_0_4 = "Browser: long-press menu now also adds a shortcut to the target link";
    const String feat3_1_0_5 = "Browser can now be chosen as the default app's launch section";
    const String feat3_1_0_6 = "Added Ranked War information and notifications to Profile page";
    const String feat3_1_0_7 = "Shortcuts page and all related options have been moved to Settings";
    const String feat3_1_0_8 = "Added dual score slider and option to ignore oneself to the Jail widget";
    const String feat3_1_0_9 = "Added company addiction to Profile";
    const String feat3_1_0_10 = "Added API call rate bar widget and warning";
    const String feat3_1_0_11 = "Full member update in War is now faster";
    const String feat3_1_0_12 = "Added competition information to targets and friends details";
    const String feat3_1_0_13 = "Added WTF Revive";
    const String feat3_1_0_14 = "Added other minor requested features and improvements";
    const String feat3_1_0_15 = "Fixed Loot Rangers loot order in certain conditions";
    const String feat3_1_0_16 = "Fixed issues redirecting to attack pages in certain conditions";
    const String feat3_1_0_17 = "Fixed issues when launching the app from a notification";
    const String feat3_1_0_18 = "Fixed pull-to-refresh in short pages";
    if (Platform.isAndroid) v3_1_0.features.add(feat3_1_0_1);
    v3_1_0.features.add(feat3_1_0_2);
    v3_1_0.features.add(feat3_1_0_3);
    v3_1_0.features.add(feat3_1_0_4);
    v3_1_0.features.add(feat3_1_0_5);
    v3_1_0.features.add(feat3_1_0_6);
    v3_1_0.features.add(feat3_1_0_7);
    v3_1_0.features.add(feat3_1_0_8);
    v3_1_0.features.add(feat3_1_0_9);
    v3_1_0.features.add(feat3_1_0_10);
    v3_1_0.features.add(feat3_1_0_11);
    v3_1_0.features.add(feat3_1_0_12);
    v3_1_0.features.add(feat3_1_0_13);
    v3_1_0.features.add(feat3_1_0_14);
    v3_1_0.features.add(feat3_1_0_15);
    v3_1_0.features.add(feat3_1_0_16);
    v3_1_0.features.add(feat3_1_0_17);
    v3_1_0.features.add(feat3_1_0_18);

    // VERSION 3.0.2
    final v3_0_2 = ChangeLogItem();
    v3_0_2.version = 'Torn PDA v3.0.2';
    v3_0_2.date = '25 APR 2023';
    const String feat3_0_2_1 = "Added option to disallow lateral overscroll issues with iOS 16 (see Settings)";
    const String feat3_0_2_2 = "Double tap energy and nerve bars in Torn to access gym and crimes";
    const String feat3_0_2_3 = "Trades can now be filtered out of events alerts";
    const String feat3_0_2_4 = "Updated missing Torn icons";
    const String feat3_0_2_5 = "Fixed issues when requesting spied stats";
    const String feat3_0_2_6 = "Fixed NNB layout margins";
    const String feat3_0_2_7 = "Fixed issues with several dialogs in the browser";
    const String feat3_0_2_8 = "Fixed information shown in Ranked Wars cards";
    const String feat3_0_2_9 = "Fixed rendering issues when sorting items";
    if (Platform.isIOS) v3_0_2.features.add(feat3_0_2_1);
    v3_0_2.features.add(feat3_0_2_2);
    v3_0_2.features.add(feat3_0_2_3);
    v3_0_2.features.add(feat3_0_2_4);
    v3_0_2.features.add(feat3_0_2_5);
    v3_0_2.features.add(feat3_0_2_6);
    v3_0_2.features.add(feat3_0_2_7);
    v3_0_2.features.add(feat3_0_2_8);
    v3_0_2.features.add(feat3_0_2_9);

    // VERSION 3.0.1
    final v3_0_1 = ChangeLogItem();
    v3_0_1.version = 'Torn PDA v3.0.1';
    v3_0_1.date = '01 APR 2023';
    v3_0_1.infoString = "Hotfix for issues with hidden foreign stocks and stakeouts";
    const String feat3_0_1_1 = "Added stakeouts section";
    const String feat3_0_1_2 = "Added native Torn authentication (see Settings)";
    const String feat3_0_1_3 = "Added alerts for medical and booster cooldowns";
    const String feat3_0_1_4 = "Added Loot Rangers attack information, alerts and notifications";
    const String feat3_0_1_5 = "Added quick favorites menu in the browser tab bar";
    const String feat3_0_1_6 = "Added natural nerve information to OC planning";
    const String feat3_0_1_7 = "Foreign stocks can now be hidden (right swipe)";
    const String feat3_0_1_8 = "Players can now be added to several lists from their profile widget";
    const String feat3_0_1_9 = "Ranked Wars sorting and own faction identification has been improved";
    const String feat3_0_1_10 = "Targets can now be sorted by note";
    const String feat3_0_1_11 = "Moved reviving services to Settings and added HeLa Revive";
    const String feat3_0_1_12 = "Simplified the 'max' button behavior when buying items abroad";
    const String feat3_0_1_13 = "Fixed dark theme sync with Torn";
    const String feat3_0_1_14 = "Fixed target level calculation in recent attacks";
    const String feat3_0_1_15 = "Fixed other reported issues";
    v3_0_1.features.add(feat3_0_1_1);
    v3_0_1.features.add(feat3_0_1_2);
    v3_0_1.features.add(feat3_0_1_3);
    v3_0_1.features.add(feat3_0_1_4);
    v3_0_1.features.add(feat3_0_1_5);
    v3_0_1.features.add(feat3_0_1_6);
    v3_0_1.features.add(feat3_0_1_7);
    v3_0_1.features.add(feat3_0_1_8);
    v3_0_1.features.add(feat3_0_1_9);
    v3_0_1.features.add(feat3_0_1_10);
    v3_0_1.features.add(feat3_0_1_11);
    v3_0_1.features.add(feat3_0_1_11);
    v3_0_1.features.add(feat3_0_1_12);
    v3_0_1.features.add(feat3_0_1_13);
    v3_0_1.features.add(feat3_0_1_14);
    v3_0_1.features.add(feat3_0_1_15);

    // VERSION 2.9.6
    final v2_9_6 = ChangeLogItem();
    v2_9_6.version = 'Torn PDA v2.9.6';
    v2_9_6.date = '20 FEB 2023';
    const String feat2_9_6_1 = "Fixed bounties filter";
    const String feat2_9_6_2 = "Improved Trades widget activation";
    const String feat2_9_6_3 = "Added deep links compatibility for Chrome href links (see Tips)";
    v2_9_6.features.add(feat2_9_6_1);
    v2_9_6.features.add(feat2_9_6_2);
    v2_9_6.features.add(feat2_9_6_3);

    // VERSION 2.9.5
    final v2_9_5 = ChangeLogItem();
    v2_9_5.version = 'Torn PDA v2.9.5';
    v2_9_5.date = '01 FEB 2023';
    v2_9_5.infoString = "Hotfix for crashes in some iOS devices when launching the browser";
    const String feat2_9_5_1 = "Added theme synchronization between app and web (can be disabled)";
    const String feat2_9_5_2 = "User scripts' injection time can now be selected. NOTE: this might be "
        "a breaking change for some scripts, that will require to be adapted. It is also recommended to restore "
        "the default script examples. Please read the documentation (in the user scripts section) for more information.";
    const String feat2_9_5_3 = "Added option to open tab in external browser (URL options dialog)";
    String feat2_9_5_4 = "";
    if (Platform.isAndroid) feat2_9_5_4 = "Fixed website Google login";
    if (Platform.isIOS) feat2_9_5_4 = "Fixed alternative website login";
    const String feat2_9_5_5 = "Fixed discreet notifications option (Settings) missing on iOS";
    const String feat2_9_5_6 = "Fixed log copy to clipboard";
    const String feat2_9_5_7 = "Fixed issue with missing shortcuts";
    const String feat2_9_5_8 = "Increased timeout with YATA to improve communication";
    const String feat2_9_5_9 = "Removed Torn Trader (service discontinued)";
    v2_9_5.features.add(feat2_9_5_1);
    v2_9_5.features.add(feat2_9_5_2);
    v2_9_5.features.add(feat2_9_5_3);
    v2_9_5.features.add(feat2_9_5_4);
    if (Platform.isIOS) v2_9_5.features.add(feat2_9_5_5);
    v2_9_5.features.add(feat2_9_5_6);
    v2_9_5.features.add(feat2_9_5_7);
    v2_9_5.features.add(feat2_9_5_8);
    v2_9_5.features.add(feat2_9_5_9);

    // VERSION 2.9.3
    final v2_9_3 = ChangeLogItem();
    v2_9_3.version = 'Torn PDA v2.9.3';
    v2_9_3.date = '15 NOV 2022';
    const String feat2_9_3_1 = "Targets can now be sorted by fair fight and last online timestamp";
    const String feat2_9_3_2 = "Fixed targets colors and sorting after importing from YATA";
    const String feat2_9_3_3 = "Fixed crashes when closing the quick browser in some devices";
    const String feat2_9_3_4 = "Fixed persistence issue when disabling user scripts";
    const String feat2_9_3_5 = "Fixed missing honor images";
    const String feat2_9_3_6 = "Fixed incorrect medical cooldown icon";
    const String feat2_9_3_7 = "Fixed other reported issues";
    v2_9_3.features.add(feat2_9_3_1);
    v2_9_3.features.add(feat2_9_3_2);
    v2_9_3.features.add(feat2_9_3_3);
    v2_9_3.features.add(feat2_9_3_4);
    v2_9_3.features.add(feat2_9_3_5);
    v2_9_3.features.add(feat2_9_3_6);
    v2_9_3.features.add(feat2_9_3_7);

    // VERSION 2.9.2
    final v2_9_2 = ChangeLogItem();
    v2_9_2.version = 'Torn PDA v2.9.2';
    v2_9_2.date = '05 NOV 2022';
    const String feat2_9_2_1 = "Added discreet option for alerts and notifications";
    const String feat2_9_2_2 = "War: added option to filter out traveling targets";
    const String feat2_9_2_3 = "Fixed browser refresh rate";
    const String feat2_9_2_4 = "Fixed some API parsing issues";
    const String feat2_9_2_5 = "Fixed incorrect header icons";
    const String feat2_9_2_6 = "Fixed profile details widget";
    const String feat2_9_2_7 = "Fixed retals section issues in landscape orientation";
    const String feat2_9_2_8 = "Fixed bazaar widget";
    v2_9_2.features.add(feat2_9_2_1);
    v2_9_2.features.add(feat2_9_2_2);
    v2_9_2.features.add(feat2_9_2_3);
    v2_9_2.features.add(feat2_9_2_4);
    v2_9_2.features.add(feat2_9_2_5);
    v2_9_2.features.add(feat2_9_2_6);
    v2_9_2.features.add(feat2_9_2_7);
    v2_9_2.features.add(feat2_9_2_8);

    // VERSION 2.9.1
    final v2_9_1 = ChangeLogItem();
    v2_9_1.version = 'Torn PDA v2.9.1';
    v2_9_1.date = '20 OCT 2022';
    const String feat2_9_1_1 = "Fixed steadfast widget";
    const String feat2_9_1_2 = "Fixed recent attacks sorting";
    const String feat2_9_1_3 = "Fixed issues reported with tabs";
    const String feat2_9_1_4 = "Fixed frame rate issues in certain devices";
    v2_9_1.features.add(feat2_9_1_1);
    v2_9_1.features.add(feat2_9_1_2);
    v2_9_1.features.add(feat2_9_1_3);
    v2_9_1.features.add(feat2_9_1_4);

    // VERSION 2.9.0
    final v2_9_0 = ChangeLogItem();
    v2_9_0.version = 'Torn PDA v2.9.0';
    v2_9_0.date = '04 OCT 2022';
    const String feat2_9_0_1 = "Alerts: added retaliation alerts";
    const String feat2_9_0_2 = "Chaining: added retaliation section";
    const String feat2_9_0_3 = "Fixed several reported issues";
    v2_9_0.features.add(feat2_9_0_1);
    v2_9_0.features.add(feat2_9_0_2);
    v2_9_0.features.add(feat2_9_0_3);

    // VERSION 2.8.9
    final v2_8_9 = ChangeLogItem();
    v2_8_9.version = 'Torn PDA v2.8.9';
    v2_8_9.date = '07 AUG 2022';
    const String feat2_8_9_1 =
        "Browser tabs now only initialise on first use (performance improvement, can be disabled)";
    const String feat2_8_9_2 = "Improved browser stability when using tabs in some devices";
    const String feat2_8_9_3 = "Added Hospital Filters example userscripts (by Kwack_Kwack)";
    const String feat2_8_9_4 = "Fixed targets export to YATA when using an alternative API key";
    v2_8_9.features.add(feat2_8_9_1);
    v2_8_9.features.add(feat2_8_9_2);
    v2_8_9.features.add(feat2_8_9_3);
    v2_8_9.features.add(feat2_8_9_4);

    // VERSION 2.8.8
    final v2_8_8 = ChangeLogItem();
    v2_8_8.version = 'Torn PDA v2.8.8';
    v2_8_8.date = '10 JUL 2022';
    const String feat2_8_8_1 = "Items: fixed section loading";
    const String feat2_8_8_2 = "Items: correctly accounts for items in the display cabinet";
    const String feat2_8_8_3 = "Browser: fixed external browser option in web contextual menu";
    const String feat2_8_8_4 = "Browser: fixed occasional freezes in some devices";
    v2_8_8.features.add(feat2_8_8_1);
    v2_8_8.features.add(feat2_8_8_2);
    v2_8_8.features.add(feat2_8_8_3);
    v2_8_8.features.add(feat2_8_8_4);

    // VERSION 2.8.7 (over 2.8.6)
    final v2_8_7 = ChangeLogItem();
    v2_8_7.version = 'Torn PDA v2.8.7';
    v2_8_7.date = '03 JUL 2022';
    v2_8_7.infoString = "Hotfix 2 for jail widget issues in some devices";
    const String feat2_8_7_1 = "Fixed user stale check and alerts persistence";
    v2_8_7.features.add(feat2_8_7_1);

    // VERSION 2.8.4 (over 2.8.3)
    final v2_8_4 = ChangeLogItem();
    v2_8_4.version = 'Torn PDA v2.8.4';
    v2_8_4.date = '18 JUN 2022';
    v2_8_4.infoString = "Hotfix for some user scripts not loading at start";
    const String feat2_8_4_1 = "Items: fixed owned items filtering";
    const String feat2_8_4_2 = "Browser: improved stability issues in some devices";
    v2_8_4.features.add(feat2_8_4_1);
    v2_8_4.features.add(feat2_8_4_2);

    // VERSION 2.8.2 (over v2.8.1)
    final v2_8_2 = ChangeLogItem();
    v2_8_2.version = 'Torn PDA v2.8.2';
    v2_8_2.date = '06 JUN 2022';
    v2_8_2.infoString = "Hotfix for war targets' data persistence";
    const String feat2_8_2_1 = "Browser: added Bounties filter widget";
    const String feat2_8_2_2 = "War: targets in a different country can now be filtered out";
    const String feat2_8_2_3 = "War: red (not-okay) targets can now be filtered out";
    const String feat2_8_2_4 = "War: factions can now be added from the Ranked Wars list";
    const String feat2_8_2_5 = "War: added persistence to filters";
    const String feat2_8_2_6 = "Fixed targets hospitalized in another country not showing as abroad";
    const String feat2_8_2_7 = "Fixed issue when sorting war targets by life";
    v2_8_2.features.add(feat2_8_2_1);
    v2_8_2.features.add(feat2_8_2_2);
    v2_8_2.features.add(feat2_8_2_3);
    v2_8_2.features.add(feat2_8_2_4);
    v2_8_2.features.add(feat2_8_2_5);
    v2_8_2.features.add(feat2_8_2_6);
    v2_8_2.features.add(feat2_8_2_7);

    // VERSION 2.8.0
    final v2_8_0 = ChangeLogItem();
    v2_8_0.version = 'Torn PDA v2.8.0';
    v2_8_0.date = '22 MAY 2022';
    const String feat2_8_0_1 = "Added NPC Loot automatic alerts";
    const String feat2_8_0_2 = "Quick items: divided faction refills in energy and nerve (need to be re-added)";
    const String feat2_8_0_3 =
        "Browser: Player Profile now includes Bazaar information (if net worth checks are enabled)";
    const String feat2_8_0_4 = "Userscripts: added handler to evaluate javascript code passed to the app "
        "(advanced - more details in the userscripts section)";
    const String feat2_8_0_5 = "Removed TornCAT Player Filter from default userscripts (discontinued by its developer)";
    v2_8_0.features.add(feat2_8_0_1);
    v2_8_0.features.add(feat2_8_0_2);
    v2_8_0.features.add(feat2_8_0_3);
    v2_8_0.features.add(feat2_8_0_4);
    v2_8_0.features.add(feat2_8_0_5);

    // VERSION 2.7.0 && 2.7.1 && 2.7.2 due to hotfix
    final v2_7_0 = ChangeLogItem();
    v2_7_0.showInfoLine = true; // REMOVE for others
    if (Platform.isAndroid) v2_7_0.infoString = "Hotfix 2 for stability issues still reported after release of v2.7.1";
    v2_7_0.version = 'Torn PDA v2.7.2';
    v2_7_0.date = '25 APR 2022';
    const String feat2_7_0_1 = "Browser: added quick items widget in faction armoury";
    const String feat2_7_0_2 = "Chaining: the browser now opens as a tab and incorporates all widgets";
    const String feat2_7_0_3 = "Chaining: fallen and fedded players are now hidden";
    const String feat2_7_0_4 = "War: added quick target filter for online status";
    const String feat2_7_0_5 = "Profile: added TornStats chart in the Basic Info card (can be disabled)";
    const String feat2_7_0_6 = "Alerts: increased time options for refills";
    const String feat2_7_0_7 = "Travel: foreign stock cards now include bars and cooldown analysis";
    const String feat2_7_0_8 = "Travel: added -/+ buttons to items capacity for easier selection";
    const String feat2_7_0_9 = "Added seconds to TCT clock (can be disabled)";
    const String feat2_7_0_10 = "Items can now also be filtered by owned/not owned";
    const String feat2_7_0_11 = "Trades: fixed connection with Torn Trader";
    const String feat2_7_0_12 = "Fixed white flash when using browser with dark themes";
    const String feat2_7_0_13 = "Fixed issues with war targets cards and total stats calculation";
    const String feat2_7_0_14 = "Fixed several other minor reported issues";
    v2_7_0.features.add(feat2_7_0_1);
    v2_7_0.features.add(feat2_7_0_2);
    v2_7_0.features.add(feat2_7_0_3);
    v2_7_0.features.add(feat2_7_0_4);
    v2_7_0.features.add(feat2_7_0_5);
    v2_7_0.features.add(feat2_7_0_6);
    v2_7_0.features.add(feat2_7_0_7);
    v2_7_0.features.add(feat2_7_0_8);
    v2_7_0.features.add(feat2_7_0_9);
    v2_7_0.features.add(feat2_7_0_10);
    v2_7_0.features.add(feat2_7_0_11);
    v2_7_0.features.add(feat2_7_0_12);
    v2_7_0.features.add(feat2_7_0_13);
    v2_7_0.features.add(feat2_7_0_14);

    // VERSION 2.6.7
    final v2_6_7 = ChangeLogItem();
    v2_6_7.version = 'Torn PDA v2.6.7';
    v2_6_7.date = '12 MAR 2022';
    const String feat2_6_7_1 = "Added points' market value in the networth card";
    const String feat2_6_7_2 = "Browser scale can now be changed (browser bar options)";
    const String feat2_6_7_3 = "Browser now accepts pinch gestures for zoom (disabled by default)";
    const String feat2_6_7_4 = "Fixed donator status in the misc card";
    const String feat2_6_7_5 = "Fixed webview background transparency";
    v2_6_7.features.add(feat2_6_7_1);
    if (Platform.isAndroid) v2_6_7.features.add(feat2_6_7_2);
    if (Platform.isIOS) v2_6_7.features.add(feat2_6_7_3);
    v2_6_7.features.add(feat2_6_7_4);
    v2_6_7.features.add(feat2_6_7_5);

    // VERSION 2.6.6
    final v2_6_6 = ChangeLogItem();
    v2_6_6.version = 'Torn PDA v2.6.6';
    v2_6_6.date = '28 FEB 2022';
    const String feat2_6_6_1 = "Added a darker and spookier theme";
    const String feat2_6_6_2 = "War targets can now be sorted by last online time";
    const String feat2_6_6_3 = "Added icons and misc info for donator and subscriber status";
    const String feat2_6_6_4 = "Fixed energy cans comparison with targets";
    const String feat2_6_6_5 = "Fixed the Sports Shop shortcut";
    v2_6_6.features.add(feat2_6_6_1);
    v2_6_6.features.add(feat2_6_6_2);
    v2_6_6.features.add(feat2_6_6_3);
    v2_6_6.features.add(feat2_6_6_4);
    v2_6_6.features.add(feat2_6_6_5);

    // VERSION 2.6.5
    final v2_6_5 = ChangeLogItem();
    v2_6_5.version = 'Torn PDA v2.6.5';
    v2_6_5.date = '❤ 14 FEB 2022 ❤';
    const String feat2_6_5_1 = "Loadouts can now be activated from the quick items widget";
    const String feat2_6_5_2 = "Settings: added support for alternative API keys for YATA and Torn Stats";
    const String feat2_6_5_3 = "Chaining: targets can now be added or removed from user profiles in Torn";
    const String feat2_6_5_4 = "Items: total owned value is now shown and sortable";
    const String feat2_6_5_5 = "Shortcuts: increased allowable name length (helpful if using a small font)";
    const String feat2_6_5_6 = "War: fixed hidden targets' dialog scroll";
    const String feat2_6_5_7 = "Bazaar: fixed auto price script";
    const String feat2_6_5_8 = "Browser: fixed browsing to custom URLs with mixed letter case";
    const String feat2_6_5_9 = "Browser: saving an image to the library should no longer crash the app";
    v2_6_5.features.add(feat2_6_5_1);
    v2_6_5.features.add(feat2_6_5_2);
    v2_6_5.features.add(feat2_6_5_3);
    v2_6_5.features.add(feat2_6_5_4);
    v2_6_5.features.add(feat2_6_5_5);
    v2_6_5.features.add(feat2_6_5_6);
    v2_6_5.features.add(feat2_6_5_7);
    v2_6_5.features.add(feat2_6_5_8);
    if (Platform.isIOS) v2_6_5.features.add(feat2_6_5_9);

    // VERSION 2.6.4
    final v2_6_4 = ChangeLogItem();
    v2_6_4.version = 'Torn PDA v2.6.4';
    v2_6_4.date = '16 JAN 2022';
    const String feat2_6_4_1 = "Stock market: added direct access to the stock market in Torn";
    const String feat2_6_4_2 = "Shortcuts: updated Bookies link (needs to be readded)";
    const String feat2_6_4_3 = "Userscripts: added JavaScript API to allow cross-origin http requests [by Knoxby]";
    const String feat2_6_4_4 = "War: reviving services are now accessible in the War page (Settings)";
    const String feat2_6_4_5 = "Items: fixed owned items not correctly filtering on launch";
    const String feat2_6_4_6 = "Quick items: fixed incorrect inventory quantities on launch";
    const String feat2_6_4_7 = "Spies: fixed some Torn Stats spied stats not showing for some players";
    const String feat2_6_4_8 = "Browser: fixed custom URL browsing";
    v2_6_4.features.add(feat2_6_4_1);
    v2_6_4.features.add(feat2_6_4_2);
    v2_6_4.features.add(feat2_6_4_3);
    v2_6_4.features.add(feat2_6_4_4);
    v2_6_4.features.add(feat2_6_4_5);
    v2_6_4.features.add(feat2_6_4_6);
    v2_6_4.features.add(feat2_6_4_7);
    v2_6_4.features.add(feat2_6_4_8);

    // VERSION 2.6.3
    final v2_6_3 = ChangeLogItem();
    v2_6_3.version = 'Torn PDA v2.6.3';
    v2_6_3.date = '01 JAN 2022';
    const String feat2_6_3_1 = "Added Ranked Wars section (Chaining - Wars)";
    const String feat2_6_3_2 = "Added steadfast information to the gym";
    const String feat2_6_3_3 = "Added status icons for banks, vault and loan (filter icons in Profile options)";
    const String feat2_6_3_4 =
        "You can now switch between YATA and Torn Stats as your source of spied stats (Settings)";
    const String feat2_6_3_5 = "Quick items and crimes can now also be configured from the quick browser";
    const String feat2_6_3_6 = "Fixed several reported issues";
    v2_6_3.features.add(feat2_6_3_1);
    v2_6_3.features.add(feat2_6_3_2);
    v2_6_3.features.add(feat2_6_3_3);
    v2_6_3.features.add(feat2_6_3_4);
    v2_6_3.features.add(feat2_6_3_5);
    v2_6_3.features.add(feat2_6_3_6);

    // VERSION 2.6.2
    final v2_6_2 = ChangeLogItem();
    v2_6_2.version = 'Torn PDA v2.6.2';
    v2_6_2.date = '25 DEC 2021';
    const String feat2_6_2_1 = "New section: Items";
    const String feat2_6_2_2 = "Added cans to estimated stats (needs war targets update)";
    v2_6_2.features.add(feat2_6_2_1);
    v2_6_2.features.add(feat2_6_2_2);

    // VERSION 2.6.1
    final v2_6_1 = ChangeLogItem();
    v2_6_1.version = 'Torn PDA v2.6.1';
    v2_6_1.date = '04 DEC 2021';
    const String feat2_6_1_1 =
        "Estimated stats now include xanax, refill, enhancer and SSL details (profiles and war targets)";
    const String feat2_6_1_2 =
        "Chaining: you can now optionally show empty notes (color reminder) when attacking a target "
        "(disabled by default)";
    const String feat2_6_1_3 = "Chaining: the faction assist requests now also sends extended information and stats";
    const String feat2_6_1_4 = "Browser: long-pressing a link in Torn will open a contextual menu with options";
    const String feat2_6_1_5 =
        "Browser: long-pressing a link in Torn will open a contextual menu with options (interferes "
        "with link preview, consider disabling it)";
    const String feat2_6_1_6 = "Browser: restore the previous browsing session, including browser type and active tab, "
        "by long-pressing the T menu floating icon in the Profile section";
    const String feat2_6_1_7 = "Browser: you can now choose the color of the tabs hide bar";
    const String feat2_6_1_8 = "Profile: properly separated jail from hospital manual notifications";
    const String feat2_6_1_9 = "Fixed incorrect spied stats total and dexterity comparison";
    const String feat2_6_1_10 = "Fixed life sorting for war targets";
    const String feat2_6_1_11 = "Fixed city items being incorrectly identified";
    const String feat2_6_1_12 = "Fixed mini profiles not properly redirecting in some devices";
    const String feat2_6_1_13 = "Fixed links in images not working properly";
    const String feat2_6_1_14 = "Fixed employee activity script";
    const String feat2_6_1_15 = "Fixed other UI issues";
    v2_6_1.features.add(feat2_6_1_1);
    v2_6_1.features.add(feat2_6_1_2);
    v2_6_1.features.add(feat2_6_1_3);
    if (Platform.isAndroid) v2_6_1.features.add(feat2_6_1_4);
    if (Platform.isIOS) v2_6_1.features.add(feat2_6_1_5);
    v2_6_1.features.add(feat2_6_1_6);
    v2_6_1.features.add(feat2_6_1_7);
    v2_6_1.features.add(feat2_6_1_8);
    v2_6_1.features.add(feat2_6_1_9);
    v2_6_1.features.add(feat2_6_1_10);
    v2_6_1.features.add(feat2_6_1_11);
    v2_6_1.features.add(feat2_6_1_12);
    v2_6_1.features.add(feat2_6_1_13);
    v2_6_1.features.add(feat2_6_1_14);
    v2_6_1.features.add(feat2_6_1_15);

    // VERSION 2.6.0
    final v2_6_0 = ChangeLogItem();
    v2_6_0.version = 'Torn PDA v2.6.0';
    v2_6_0.date = '08 NOV 2021';
    const String feat2_6_0_1 = "Chaining: added War section";
    const String feat2_6_0_2 = "Chaining: you can now send attack assistance notifications to your faction mates using "
        "Torn PDA (see Tips section - Faction Communication)";
    const String feat2_6_0_3 = "Chaining: you can now sort targets by life";
    const String feat2_6_0_4 = "Chaining: added option to skip first target as well (disabled by default)";
    const String feat2_6_0_5 =
        "Chaining: the tap area in cards to start an attack has been reduced to the gun sight icon "
        "and target name, to avoid conflicts with other icons";
    const String feat2_6_0_6 = "Chain widget: added Panic Mode";
    const String feat2_6_0_7 = "Chain widget: you can now choose the alert activation triggers";
    const String feat2_6_0_8 = "Alerts (refills): you can now choose the notification time";
    const String feat2_6_0_9 = "Alerts (stock market): added overall value and profit information";
    const String feat2_6_0_10 = "Alerts (stock market): alerts can now be based on gain/loss percentages";
    const String feat2_6_0_11 = "Friendly factions can now also be added using members' IDs";
    const String feat2_6_0_12 = "Fixed respect and fair fight not being properly recorded in some cases";
    const String feat2_6_0_13 = "Fixed chaining cooldown counter";
    v2_6_0.features.add(feat2_6_0_1);
    v2_6_0.features.add(feat2_6_0_2);
    v2_6_0.features.add(feat2_6_0_3);
    v2_6_0.features.add(feat2_6_0_4);
    v2_6_0.features.add(feat2_6_0_5);
    v2_6_0.features.add(feat2_6_0_6);
    v2_6_0.features.add(feat2_6_0_7);
    v2_6_0.features.add(feat2_6_0_8);
    v2_6_0.features.add(feat2_6_0_9);
    v2_6_0.features.add(feat2_6_0_10);
    v2_6_0.features.add(feat2_6_0_11);
    v2_6_0.features.add(feat2_6_0_12);
    v2_6_0.features.add(feat2_6_0_13);

    // VERSION 2.5.3
    final v2_5_3 = ChangeLogItem();
    v2_5_3.version = 'Torn PDA v2.5.3';
    v2_5_3.date = '01 OCT 2021';
    const String feat2_5_3_1 = "Fixed travel max-buy button";
    const String feat2_5_3_2 = "Fixed UI issues";
    v2_5_3.features.add(feat2_5_3_1);
    v2_5_3.features.add(feat2_5_3_2);

    // VERSION 2.5.2
    final v2_5_2 = ChangeLogItem();
    v2_5_2.version = 'Torn PDA v2.5.2';
    v2_5_2.date = '19 SEP 2021';
    const String feat2_5_2_1 = "Added jail widget with quick bail/bust and filters";
    const String feat2_5_2_2 = "Added app deep links (see Tips section)";
    const String feat2_5_2_3 = "Added Reading Book icon";
    const String feat2_5_2_4 = "Added return time information when traveling";
    const String feat2_5_2_5 = "Added showcase on first tab use";
    const String feat2_5_2_6 = "Added energy alerts for hunting";
    const String feat2_5_2_7 = "Fixed some quick crimes (please remove/add the crime again if you were affected)";
    const String feat2_5_2_8 = "Fixed forum history navigation";
    const String feat2_5_2_9 = "Fixed user profile widget";
    const String feat2_5_2_10 = "Fixed reported issues with tabs";
    const String feat2_5_2_11 = "Fixed reported UI issues";
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
    final v2_5_1 = ChangeLogItem();
    v2_5_1.version = 'Torn PDA v2.5.1';
    v2_5_1.date = '25 AUG 2021';
    const String feat2_5_1_1 = "Fixed some browsing issues when not using tabs in the quick browser";
    const String feat2_5_1_2 = "Fixed browsing history not working properly after visiting certain pages";
    v2_5_1.features.add(feat2_5_1_1);
    v2_5_1.features.add(feat2_5_1_2);

    // VERSION 2.5.0
    final v2_5_0 = ChangeLogItem();
    v2_5_0.version = 'Torn PDA v2.5.0';
    v2_5_0.date = '20 AUG 2021';
    const String feat2_5_0_1 = "Browser: added tabs (visit the Tips section for more information)";
    const String feat2_5_0_2 = "Browser: added pull to refresh to the main browser (disabled by default)";
    const String feat2_5_0_3 = "Profile: added section header with main icons and wallet information";
    const String feat2_5_0_4 = "Profile: added pull to refresh in the Profile section";
    const String feat2_5_0_5 = "Profile: added more detail to bazaar information";
    const String feat2_5_0_6 = "Scripts: added Company Activity and fixed Racing Presets";
    const String feat2_5_0_7 = "Chaining: removed Torn Attack Central (service discontinued)";
    const String feat2_5_0_8 = "Fixed some userscripts with wildcards not correctly activating";
    const String feat2_5_0_9 = "Fixed vault widget's loading time";
    const String feat2_5_0_10 = "Fixed UI issues reported";
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
    final v2_4_3 = ChangeLogItem();
    v2_4_3.version = 'Torn PDA v2.4.3';
    v2_4_3.date = '05 AUG 2021';
    const String feat2_4_3_1 =
        "You can now optionally access the Stock Market section from the main menu (disabled by default)";
    const String feat2_4_3_2 = "Added display cabinet items to the inventory count shown in the foreign stocks page";
    const String feat2_4_3_3 =
        "Unedited example user scripts will now update automatically as necessary with each app update";
    const String feat2_4_3_4 = "Fixed disabled user scripts reactivating when app is launched";
    const String feat2_4_3_5 = "Fixed total bazaar value shown in the Profile section";
    const String feat2_4_3_6 = "Fixed other reported UI issues";
    v2_4_3.features.add(feat2_4_3_1);
    v2_4_3.features.add(feat2_4_3_2);
    v2_4_3.features.add(feat2_4_3_3);
    v2_4_3.features.add(feat2_4_3_4);
    v2_4_3.features.add(feat2_4_3_5);
    v2_4_3.features.add(feat2_4_3_6);

    // VERSION 2.4.2
    final v2_4_2 = ChangeLogItem();
    v2_4_2.version = 'Torn PDA v2.4.2';
    v2_4_2.date = '28 JUL 2021';
    const String feat2_4_2_1 = "Profile: added total bazaar value information";
    const String feat2_4_2_2 = "Travel: you can now filter foreign stocks by inventory quantity";
    const String feat2_4_2_3 = "Travel: MAX buy button can now also be used to buy additional items above the limit";
    const String feat2_4_2_4 = "Travel: added custom (seat belt) sound for travel notifications";
    const String feat2_4_2_5 = "Travel: added depletion rate information to foreign stocks";
    const String feat2_4_2_6 =
        "Browser: you can now set the energy threshold to trigger the stacking warning when visiting the gym";
    const String feat2_4_2_7 = "Browser: added terminal window for developers";
    const String feat2_4_2_8 = "Fixed an issue preventing some userscripts from working if using wildcards in the URL";
    const String feat2_4_2_9 = "Fixed other reported UI issues";
    const String feat2_4_2_10 =
        "Note: TAC is now deactivated by default and will be removed soon, save any pending target!";
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
    final v2_4_1 = ChangeLogItem();
    v2_4_1.version = 'Torn PDA v2.4.1';
    v2_4_1.date = '10 JUL 2021';
    const String feat2_4_1_1 = "Fixed chat hiding and highlighting";
    v2_4_1.features.add(feat2_4_1_1);

    // VERSION 2.4.0
    final v2_4_0 = ChangeLogItem();
    v2_4_0.version = 'Torn PDA v2.4.0';
    v2_4_0.date = '05 JUL 2021';
    const String feat2_4_0_1 = "Added alerts for stock exchange price gain/loss";
    const String feat2_4_0_2 = "Added Arson Warehouse support in the Trade Calculator";
    const String feat2_4_0_3 = "Loot: added Tiny";
    const String feat2_4_0_4 = "Loot: click the NPC's portrait to visit the profile";
    const String feat2_4_0_5 = "Profile: you can now choose which section to visit when tapping the life bar";
    const String feat2_4_0_6 = "Profile: you can now edit active shortcuts (left swipe)";
    const String feat2_4_0_7 = "Profile: added caution message if visiting the gym while stacking";
    const String feat2_4_0_8 =
        "Chaining: chain watcher can now be seen anywhere in the app, also added improvements in timings and local notifications";
    const String feat2_4_0_9 = "Chaining: you can now check targets' status after fetching them from TAC";
    const String feat2_4_0_10 = "Chaining: added options (URL copy, navigation, shortcuts) to chaining browser";
    const String feat2_4_0_11 = "Chaining: you can now tap anywhere in a target's card to trigger the attack browser";
    const String feat2_4_0_12 = "Browser: added MAX buttons when buying from the bazaar";
    const String feat2_4_0_13 = "Browser: you can now disable the native link preview windows when long-pressing";
    const String feat2_4_0_14 = "Browser: TornCAT Player Filter script updated to include API comment";
    const String feat2_4_0_15 = "Fixed issue with screen turning off when chain watcher is in use";
    const String feat2_4_0_16 = "Fixed connectivity with some bluetooth devices";
    const String feat2_4_0_17 = "Fixed foreign stock items identification and uploads";
    const String feat2_4_0_18 = "Fixed issues caused by targets with life over max";
    const String feat2_4_0_19 = "Fixed recent attacks cards errors in certain conditions";
    const String feat2_4_0_20 = "Fixed other UI related issues reported by users";
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
    final v2_3_5 = ChangeLogItem();
    v2_3_5.version = 'Torn PDA v2.3.5';
    v2_3_5.date = '30 MAY 2021';
    const String feat2_3_5_1 = "Browser: added vault share widget";
    const String feat2_3_5_2 = "Settings: added auto rotation option";
    const String feat2_3_5_3 = "Profile: added shortcuts below error message when Torn API is down";
    const String feat2_3_5_4 = "Fixed duplicated notifications in some devices with the app on the foreground";
    const String feat2_3_5_5 = "Fixed error when using Awards for the first time in a while";
    const String feat2_3_5_6 = "Fixed chats hide option and name highlights";
    const String feat2_3_5_7 = "Fixed other user interface issues";
    v2_3_5.features.add(feat2_3_5_1);
    v2_3_5.features.add(feat2_3_5_2);
    v2_3_5.features.add(feat2_3_5_3);
    v2_3_5.features.add(feat2_3_5_4);
    v2_3_5.features.add(feat2_3_5_5);
    v2_3_5.features.add(feat2_3_5_6);
    v2_3_5.features.add(feat2_3_5_7);

    // VERSION 2.3.4
    final v2_3_4 = ChangeLogItem();
    v2_3_4.version = 'Torn PDA v2.3.4';
    v2_3_4.date = '04 MAY 2021';
    const String feat2_3_4_1 = "Alerts: added refills (energy, nerve, casino tokens).";
    const String feat2_3_4_2 =
        "Browser: added search functionality (tap the title or long-press the quick browser bottom bar).";
    const String feat2_3_4_3 =
        "Profile: added organized crimes calculation from events (if faction API access is unavailable).";
    const String feat2_3_4_4 = "Profile: added bazaar status and dialog with details to the status card.";
    const String feat2_3_4_5 = "Profile: you can now copy or share the information in the Basic Info card.";
    const String feat2_3_4_6 = "Loot: added pull to refresh functionality.";
    const String feat2_3_4_7 = "Browser: fixed issue preventing the Trade Calculator widget from activating.";
    const String feat2_3_4_8 = "Scripts: updated TornCAT example and the repository with new scripts.";
    v2_3_4.features.add(feat2_3_4_1);
    v2_3_4.features.add(feat2_3_4_2);
    v2_3_4.features.add(feat2_3_4_3);
    v2_3_4.features.add(feat2_3_4_4);
    v2_3_4.features.add(feat2_3_4_5);
    v2_3_4.features.add(feat2_3_4_6);
    v2_3_4.features.add(feat2_3_4_7);
    v2_3_4.features.add(feat2_3_4_8);

    // VERSION 2.3.3
    final v2_3_3 = ChangeLogItem();
    v2_3_3.version = 'Torn PDA v2.3.3';
    v2_3_3.date = '22 APR 2021';
    const String feat2_3_3_1 = "Added a 5 minutes option for manual Loot notifications.";
    const String feat2_3_3_2 = "Added networth information to players' profiles (disabled by default).";
    const String feat2_3_3_3 = "Adapted quick items result box to work with dark mode.";
    const String feat2_3_3_4 = "Fixed an issue preventing Torn Trader from authenticating users.";
    v2_3_3.features.add(feat2_3_3_1);
    v2_3_3.features.add(feat2_3_3_2);
    v2_3_3.features.add(feat2_3_3_3);
    v2_3_3.features.add(feat2_3_3_4);

    // VERSION 2.3.2
    final v2_3_2 = ChangeLogItem();
    v2_3_2.version = 'Torn PDA v2.3.2';
    v2_3_2.date = '15 APR 2021';
    const String feat2_3_2_1 =
        "Browser: added stats from YATA's spies database to players' profiles. You can now also optionally hide estimated stats (much less accurate) in Settings.";
    const String feat2_3_2_2 =
        "Userscripts: added another few example scripts and corrected issues with the existing ones (you can import the new ones from the userscripts settings).";
    const String feat2_3_2_3 =
        "Userscripts: created a list of tested scripts in the GitHub repository, also added a reference in Torn PDA and in the official forums.";
    const String feat2_3_2_4 =
        "Userscripts: script execution is now isolated and no interference should occur between them.";
    const String feat2_3_2_5 = "Loot: NPCs can now be filtered out.";
    const String feat2_3_2_6 = "Shortcuts: Stock Market URL has been corrected and Portfolio has been removed.";
    const String feat2_3_2_7 = "Profile: added racing, reviving and hunting skills to the basic info card.";
    const String feat2_3_2_8 = "Travel: flag filters can now be sorted alphabetically and by flight time.";
    const String feat2_3_2_9 =
        "Travel: the quick return icon now needs to be pressed twice to avoid erroneous activations.";
    const String feat2_3_2_10 = "Travel: increased width of the capacity slider to make selection easier.";
    const String feat2_3_2_11 =
        "Travel: the custom text notification dialog has been moved to the travel notification options page.";
    const String feat2_3_2_12 = "Awards: added button to enable or disable all filters at once.";
    const String feat2_3_2_13 = "Alerts: improved travel alerts reliability, even if the API goes down temporarily.";
    const String feat2_3_2_14 =
        "Alerts: added troubleshooting dialog to reset user and notification channels if something isn't working correctly.";
    const String feat2_3_2_15 = "Fixed URL copying issues in certain devices.";
    const String feat2_3_2_16 = "Fixed Trade widget not activating in certain devices.";
    const String feat2_3_2_17 = "Fixed crash when clearing browser cache in certain devices.";
    const String feat2_3_2_18 =
        "Fixed scrolling issues causing the browser to freeze in certain sections of the website.";
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
    final v2_3_1 = ChangeLogItem();
    v2_3_1.version = 'Torn PDA v2.3.1';
    v2_3_1.date = '02 APR 2021';
    const String feat2_3_1_1 = "Added Easter Bunny (NPC).";
    const String feat2_3_1_2 =
        "Browser: the pull to refresh feature has been temporarily deactivated due to unexpected behaviors.";
    const String feat2_3_1_3 = "Events alerts reliability has been improved.";
    const String feat2_3_1_4 = "Fixed user scripts page opening a blank menu.";
    const String feat2_3_1_5 = "Fixed reported typos in the Profile section.";
    v2_3_1.features.add(feat2_3_1_1);
    v2_3_1.features.add(feat2_3_1_2);
    v2_3_1.features.add(feat2_3_1_3);
    v2_3_1.features.add(feat2_3_1_4);
    v2_3_1.features.add(feat2_3_1_5);

    // VERSION 2.2.0
    final v2_3_0 = ChangeLogItem();
    v2_3_0.version = 'Torn PDA v2.3.0';
    v2_3_0.date = '01 APR 2021';
    const String feat2_3_0_1 = "Loot: added Fernando (NPC).";
    const String feat2_3_0_2 =
        "Browser: added custom user scripts support (add your own in Settings / Browser Options). Preexisting scripts might require code changes to work in Torn PDA.";
    const String feat2_3_0_3 = "Browser: added estimated stats to players' profiles.";
    const String feat2_3_0_4 =
        "Browser: added extra information when attacking or visiting other players' profiles. You will be warned if they belong to your same faction or a friendly faction, if they are on your friends' list, etc. You can configure friendly factions in the advanced browser settings inside of the Settings section.";
    const String feat2_3_0_5 =
        "Browser: added pull to refresh and optionally hide refresh icon (does not work in the chaining browser).";
    const String feat2_3_0_6 =
        "Chaining: added extra information to targets' notes when chaining, showing if the target has been online recently and if it belongs to a faction. Applies to standard targets and TAC.";
    const String feat2_3_0_7 = "Chaining: changed sorting by note color to match YATA's (G-Y-R-OFF or OFF-R-Y-G).";
    const String feat2_3_0_8 = "Chaining: you can now filter targets by note color.";
    const String feat2_3_0_9 = "Chaining: fixed TAC stats notes not showing correctly.";
    const String feat2_3_0_10 =
        "Chaining: notes color now sync with YATA even if the note is empty. The notebook icon is now also colored accordingly";
    const String feat2_3_0_11 = "Chaining: target cards now show flat respect. Added fair fight.";
    const String feat2_3_0_12 =
        "Friends: the notebook icon is now colored according to the note's color, even if empty.";
    const String feat2_3_0_13 =
        "Profile: added a check for property rental expiry (< 7 days) in the miscellaneous card";
    const String feat2_3_0_14 =
        "Profile: the manual hospital release notification can now be configured to trigger several minutes in advance (similar to travel notifications).";
    const String feat2_3_0_15 = "Profile: fixed company name when working for a public company.";
    const String feat2_3_0_16 = "Profile: fixed participants readiness check for OCs.";
    const String feat2_3_0_17 = "Travel: Improved foreign items layout for narrow screens.";
    const String feat2_3_0_18 = "Settings: moved browser options to a dedicated section to reduce complexity.";
    const String feat2_3_0_19 = "Corrected pixel density for certain devices.";
    const String feat2_3_0_20 = "Corrected Torn links not working when the website returns an unsecure (http) url.";
    const String feat2_3_0_21 = "Corrected targets sync issues caused by API changes.";
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
    final v2_2_0 = ChangeLogItem();
    v2_2_0.version = 'Torn PDA v2.2.0';
    v2_2_0.date = '25 FEB 2021';
    const String feat2_2_0_1 = "Travel: added foreign stock graphs with last 36 hours data";
    const String feat2_2_0_2 =
        "Travel: added restock and depletion times calculation, with flight departure times suggestions and manually activated notifications";
    const String feat2_2_0_3 = "Travel: added automatic alerts for items restock (Alerts section)";
    const String feat2_2_0_4 =
        "Travel: you can now specify your travel ticket type, which will affect departure and arrival times as well as profit calculation";
    const String feat2_2_0_5 = "Travel: arrival times are now shown in the main stock card";
    const String feat2_2_0_6 = "Travel: items can now be sorted by arrival time";
    const String feat2_2_0_7 = "Travel: added calculation of money to carry and direct access to vaults";
    const String feat2_2_0_8 =
        "Travel: the foreign stock page can now be refreshed by pulling. Also added a button in the app bar to manually refresh the API while in the Travel section";
    const String feat2_2_0_9 = "Travel: you can now optionally hide the airplane while flying (Settings)";
    const String feat2_2_0_10 = "Profile: you can now activate a manual notification for just before hospital release";
    const String feat2_2_0_11 =
        "Profile: you can now activate a manual notification, alarm or timer for just before hospital release";
    const String feat2_2_0_12 =
        "Profile: added Universal Health Care reviving services call when in hospital (activate in profile options)";
    const String feat2_2_0_13 =
        "Profile: added Organized Crimes in Misc and Travel cards (note: you need Api Access permission from your faction)";
    const String feat2_2_0_14 = "Profile: you can now manually sort the cards shown in the Profile section";
    const String feat2_2_0_15 =
        "Profile: you can now optionally activate a minimalistic travel card which shows the same information the Travel section offers (and disable the latter entirely if you wish)";
    const String feat2_2_0_16 = "Profile: added job points to the basic information card";
    const String feat2_2_0_17 = "Chaining: added fair fight to recent attacks cards";
    const String feat2_2_0_18 =
        "Chaining: added fair fight and respect calculation from TAC (realtime based on current chain hit number)";
    const String feat2_2_0_19 = "Chaining: added notes for TAC targets";
    const String feat2_2_0_20 = "City Finder now collapses (less intrusive)";
    const String feat2_2_0_21 = "Added option to clear the browser's cache (Settings)";
    const String feat2_2_0_22 =
        "Sound and vibration options for manually activated alarms have been moved to Settings and now apply equally to all alarms";
    const String feat2_2_0_23 = "Fixed forums URL copying";
    const String feat2_2_0_24 = "Fixed cooldowns time string";
    const String feat2_2_0_25 = "Fixed targets wipe functionality";
    const String feat2_2_0_26 = "Fixed other several minor bugs";
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
    final v2_1_1 = ChangeLogItem();
    v2_1_1.version = 'Torn PDA v2.1.1';
    v2_1_1.date = '30 JAN 2021';
    const String feat2_1_1_1 = "Fixed Awards not loading correctly on iOS";
    v2_1_1.features.add(feat2_1_1_1);

    // VERSION 2.1.0
    final v2_1_0 = ChangeLogItem();
    v2_1_0.version = 'Torn PDA v2.1.0';
    v2_1_0.date = '21 JAN 2021';
    const String feat2_1_0_1 = "Added Torn Attack Central mobile interface (see Chaining section)";
    const String feat2_1_0_2 =
        "Automatic alerts: added Events (includes trading alerts as a special category), with some predefined filters";
    const String feat2_1_0_3 = "You can now use your shortcuts directly from the browser (tap the page title)";
    const String feat2_1_0_4 = "Added the quick items widget to the chaining browser";
    const String feat2_1_0_5 = "Awards: activated pins sync with YATA";
    const String feat2_1_0_6 = "Awards: fixed sorting by days left";
    const String feat2_1_0_7 =
        "Notifications are now automatically removed from the notification bar when the application is launched (can be deactivated)";
    const String feat2_1_0_8 =
        "Added notification channels (in Android's notifications settings) so that users can configure each notification (sound, alert type, etc.) individually";
    const String feat2_1_0_9 = "You can now select the vibration pattern for notifications (Settings)";
    const String feat2_1_0_10 = "Fixed Discord link";
    const String feat2_1_0_11 = "Fixed issues when launching the external browser";
    const String feat2_1_0_12 = "Fixed URL copying";
    const String feat2_1_0_13 = "Fixed education warning when there are no pending courses";
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
    final v2_0_0 = ChangeLogItem();
    v2_0_0.version = 'Torn PDA v2.0.0';
    v2_0_0.date = '06 JAN 2021';
    const String feat2_0_0_1 =
        "YATA Awards: new section that constitutes the first official YATA mobile interface. Data comes straight from your YATA account";
    const String feat2_0_0_2 =
        "Quick Items: browse to the items section in Torn with the full browser and add your prefer items for a quick access later on";
    const String feat2_0_0_3 =
        "Alerts: added messages to automatic alerts (tap the notification to browse straight to the message). Most other notifications can now also be tapped to get access to their relevant areas";
    const String feat2_0_0_4 =
        "Tips: new section added to the main menu with some frequently asked questions and tips to get the maximum out or Torn PDA";
    const String feat2_0_0_5 = "You can now highlight your name in chat (choose color or disable in Settings)";
    const String feat2_0_0_6 = "Added a new button that allows to temporarily remove all chat windows from Torn";
    const String feat2_0_0_7 =
        "New browser features: you can now browse to any URL or add a website as a shortcut to your Profile section directly from the browser (tap the browser page title in the full browser or long press the close button in the quick browser)";
    const String feat2_0_0_8 =
        "Using the back button or back swipe while in the browser won't inadvertently close the browser any longer, but browse back if possible";
    const String feat2_0_0_9 =
        "Most links in Torn PDA open the quick browser with a short tap or the full browser with a long-press. Quick browser can be deactivated in Settings if desired";
    const String feat2_0_0_10 = "You can now select the number of events and messages to show in the Profile section";
    const String feat2_0_0_11 = "Added confirmation dialog to prevent exiting Torn PDA inadvertently (can be disabled)";
    const String feat2_0_0_12 = "Added Loot and Awards to the default launch section selector";
    const String feat2_0_0_13 = "Browser widgets should open faster and more reliably";
    const String feat2_0_0_14 = "Corrected travel money checks showing a warning when the exact amount was brought";
    const String feat2_0_0_15 = "Corrected appbar icons and colors";
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
    final v1_9_7 = ChangeLogItem();
    v1_9_7.version = 'Torn PDA v1.9.7';
    v1_9_7.date = '09 DEC 2020';
    const String feat1_9_7_1 = "Loot: fixed bug preventing notifications from working properly";
    const String feat1_9_7_2 = "Text corrections";
    v1_9_7.features.add(feat1_9_7_1);
    v1_9_7.features.add(feat1_9_7_2);

    // VERSION 1.9.6
    final v1_9_6 = ChangeLogItem();
    v1_9_6.version = 'Torn PDA v1.9.6';
    v1_9_6.date = '06 DEC 2020';
    const String feat1_9_6_1 = "Loot: added Scrooge (NPC)";
    const String feat1_9_6_2 =
        "Profile: added wallet money to the Basic Info card. Short/long tap to access your vaults with quick or full browser";
    const String feat1_9_6_3 =
        "Short or long tap the travel bar (in Profile & Travel) to launch the quick or full browser to Torn";
    const String feat1_9_6_4 = "Alerts section can now be correctly scrolled in smaller screens";
    const String feat1_9_6_5 = "Fixed other issues reported by users";
    v1_9_6.features.add(feat1_9_6_1);
    v1_9_6.features.add(feat1_9_6_2);
    v1_9_6.features.add(feat1_9_6_3);
    v1_9_6.features.add(feat1_9_6_4);
    v1_9_6.features.add(feat1_9_6_5);

    // VERSION 1.9.5
    final v1_9_5 = ChangeLogItem();
    v1_9_5.version = 'Torn PDA v1.9.5';
    v1_9_5.date = '30 NOV 2020';
    const String feat1_9_5_1 = "Fixed shortcuts menu persistence after app is closed";
    const String feat1_9_5_2 = "Fixed Discord link in About section";
    v1_9_5.features.add(feat1_9_5_1);
    v1_9_5.features.add(feat1_9_5_2);

    // VERSION 1.9.4
    final v1_9_4 = ChangeLogItem();
    v1_9_4.version = 'Torn PDA v1.9.4';
    v1_9_4.date = '28 NOV 2020';
    const String feat1_9_4_1 = "Alerts: added drugs cooldown automatic alert";
    const String feat1_9_4_2 = "Alerts: added racing automatic alert";
    const String feat1_9_4_3 =
        "Profile: you can now choose between an horizontal slidable list or a grid view for shortcuts";
    const String feat1_9_4_4 = "Browser: added quick controls (back, forward and refresh) for the quick browser";
    const String feat1_9_4_5 =
        "Browser: improved speed and corrected several reported issues (i.e.: hospital timer and other sections not showing)";
    v1_9_4.features.add(feat1_9_4_1);
    v1_9_4.features.add(feat1_9_4_2);
    v1_9_4.features.add(feat1_9_4_3);
    v1_9_4.features.add(feat1_9_4_4);
    v1_9_4.features.add(feat1_9_4_5);

    // VERSION 1.9.3
    final v1_9_3 = ChangeLogItem();
    v1_9_3.version = 'Torn PDA v1.9.3';
    const String feat1_9_3_1 =
        "Fixed error with messages titles, preventing some users from loading the Profile section entirely";
    const String feat1_9_3_2 = "Corrected emojis representation in message titles";
    v1_9_3.features.add(feat1_9_3_1);
    v1_9_3.features.add(feat1_9_3_2);

    // VERSION 1.9.2
    final v1_9_2 = ChangeLogItem();
    v1_9_2.version = 'Torn PDA v1.9.2';
    const String feat1_9_2_1 =
        "Profile: new shortcuts to your preferred game sections. Use the existing ones or configure your own. Short/long tap to open a quick or full browser";
    const String feat1_9_2_2 = "Profile: added a new card for received messages";
    const String feat1_9_2_3 = "Profile: added option to configure which cards are expanded or collapsed by default";
    const String feat1_9_2_4 = "Profile: the Basic Information card can now be collapsed";
    const String feat1_9_2_5 = "Browser: added loading progress bar (can be disabled)";
    const String feat1_9_2_6 = "Browser: quick crimes are now placed at the bottom when using a bottom app bar";
    const String feat1_9_2_7 = "Increased size of quick browser";
    const String feat1_9_2_8 = "Fixed error with chaining indications for players with no faction";
    v1_9_2.features.add(feat1_9_2_1);
    v1_9_2.features.add(feat1_9_2_2);
    v1_9_2.features.add(feat1_9_2_3);
    v1_9_2.features.add(feat1_9_2_4);
    v1_9_2.features.add(feat1_9_2_5);
    v1_9_2.features.add(feat1_9_2_6);
    v1_9_2.features.add(feat1_9_2_7);
    v1_9_2.features.add(feat1_9_2_8);

    // VERSION 1.9.1
    final v1_9_1 = ChangeLogItem();
    v1_9_1.version = 'Torn PDA v1.9.1';
    const String feat1_9_1_1 =
        "Profile: added several additional quick browser triggers (tap on the happy bar, life bar or the points icon)";
    const String feat1_9_1_2 = "Profile: added addiction icon and information to miscellaneous";
    const String feat1_9_1_3 = "Profile: added effective battle stats calculation";
    const String feat1_9_1_4 =
        "Profile: added chain information and warning (in case you are heading to the gym and unaware of the chain)";
    const String feat1_9_1_5 = "Chaining: added flags and travel direction for your targets";
    const String feat1_9_1_6 = "Settings: you can now place the application bar at the bottom of the screen";
    const String feat1_9_1_7 =
        "Fixed screen issues in several devices (wrong tap location, zoomed-in screen, loading times)";
    const String feat1_9_1_8 = "Fixed scroll not returning to the correct place after refreshing a page in the browser";
    const String feat1_9_1_9 =
        "Fixed issues with some devices and keyboards (special chars and autocorrect not displaying)";
    const String feat1_9_1_10 = "Fixed dropdown menus not opening in some tablets";
    const String feat1_9_1_11 = "Fixed empty notes being shown when attacking";
    const String feat1_9_1_12 = "Fixed capitalization when adding notes";
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
    final v1_9_0 = ChangeLogItem();
    v1_9_0.version = 'Torn PDA v1.9.0';
    const String feat1_9_0_1 = "Alerts: added nerve to automatic alerts";
    const String feat1_9_0_2 = "Quick actions: long press app icon (supported devices) to launch Torn from home screen";
    const String feat1_9_0_3 =
        "Profile: tapping your energy or nerve bars will open a small browser to the gym or crimes, easier than ever";
    const String feat1_9_0_4 = "Profile: added stats, points and other useful information";
    const String feat1_9_0_5 =
        "Travel: you can now sort by quantity and see how many items of each type you already possess (can be disabled)";
    const String feat1_9_0_6 =
        "Travel: when you click a flag, you'll also get a check on if you have sufficient money on hand to fill your capacity with the item you selected";
    const String feat1_9_0_7 = "Bazaar: added button to fill maximum quantities automatically";
    const String feat1_9_0_8 =
        "Browser: changed top-left icon to better show if the browser is going to close (X) or go back (arrow). If visiting a vault after a trade, it now goes back to Trades.";
    const String feat1_9_0_9 = "Added TCT clock to main menu";
    const String feat1_9_0_10 = "Improved API integration with YATA";
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
    final v1_8_6 = ChangeLogItem();
    v1_8_6.version = 'Torn PDA v1.8.6';
    const String feat1_8_6_1 =
        "Trading: if you are a professional trader and an user of Torn Trader, you can now activate a real time sync with your own prices, custom messages and receipt through the Trade Calculator (see options when in the Trade page in Torn to activate)";
    const String feat1_8_6_2 =
        "Trading: a new icon will redirect you directly to your personal, faction or company vault after a trade, so that you can keep your money safe from muggers";
    const String feat1_8_6_3 = "Profile: racing status added to the miscellaneous card";
    const String feat1_8_6_4 = "Minor bug fixes";
    v1_8_6.features.add(feat1_8_6_1);
    v1_8_6.features.add(feat1_8_6_2);
    v1_8_6.features.add(feat1_8_6_3);
    v1_8_6.features.add(feat1_8_6_4);

    // VERSION 1.8.5
    final v1_8_5 = ChangeLogItem();
    v1_8_5.version = 'Torn PDA v1.8.5';
    const String feat1_8_5_1 =
        "The color of your targets' notes is now exported and imported to/from YATA (in the process, blue color was transformed into orange for standardization)";
    const String feat1_8_5_2 =
        "While chaining, you'll be shown your note for each target before attacking, so that you can adjust your strategy accordingly (can be disabled)";
    const String feat1_8_5_3 = "You can now sort targets by note color";
    const String feat1_8_5_4 = "Fixed an issue where the target note could not be updated right after attacking";
    v1_8_5.features.add(feat1_8_5_1);
    v1_8_5.features.add(feat1_8_5_2);
    v1_8_5.features.add(feat1_8_5_3);
    v1_8_5.features.add(feat1_8_5_4);

    // VERSION 1.8.4
    final v1_8_4 = ChangeLogItem();
    v1_8_4.version = 'Torn PDA v1.8.4';
    const String feat1_8_4_1 =
        "Chaining: you can now export and import all your targets to/from YATA, including personal notes";
    const String feat1_8_4_2 = "Chaining: there is a new option to wipe all your targets (use carefully)";
    const String feat1_8_4_3 = "Profile: you can now schedule travel notifications directly from the profile section";
    const String feat1_8_4_4 =
        "Browser: swipe left/right in the top bar to browse forward/back. Also fixed an error that prevented some links (forum/profiles) from working properly.";
    const String feat1_8_4_5 =
        "Travel: while checking foreign stock, press any flag to access the travel agency directly";
    const String feat1_8_4_6 = "Visual enhancements to travel bar and chaining target's cards";
    const String feat1_8_4_7 = "Corrected several other issues";
    v1_8_4.features.add(feat1_8_4_1);
    v1_8_4.features.add(feat1_8_4_2);
    v1_8_4.features.add(feat1_8_4_3);
    v1_8_4.features.add(feat1_8_4_4);
    v1_8_4.features.add(feat1_8_4_5);
    v1_8_4.features.add(feat1_8_4_6);
    v1_8_4.features.add(feat1_8_4_7);

    // VERSION 1.8.3
    final v1_8_3 = ChangeLogItem();
    v1_8_3.version = 'Torn PDA v1.8.3';
    const String feat1_8_3_1 = "Chaining: added a chain watcher feature that can be activated both in "
        "the targets screen and while chaining";
    const String feat1_8_3_2 = "Profile: when you are in hospital, you can now send Nuclear Central "
        "Hospital a revive request by clicking a button. This is an optional feature and "
        "a contract/payment will be required by them; Torn PDA does not get anything in return";
    const String feat1_8_3_3 = "Profile: added travel arrival time information in the status card";
    v1_8_3.features.add(feat1_8_3_1);
    v1_8_3.features.add(feat1_8_3_2);
    v1_8_3.features.add(feat1_8_3_3);

    // VERSION 1.8.2
    final v1_8_2 = ChangeLogItem();
    v1_8_2.version = 'Torn PDA v1.8.2';
    const String feat1_8_2_1 = "Chaining: targets that can't be attacked (red status or in a different country) "
        "will be skipped automatically. Maximum of 3 targets. This feature can be deactivated.";
    const String feat1_8_2_2 = "Targets: added a hospital countdown and a clickable travel icon "
        "that shows your target's whereabouts";
    const String feat1_8_2_3 = "Recent attacks: a new clickable faction icon will show you if the target "
        "you are adding to your chaining list is a member of a faction";
    const String feat1_8_2_4 = "Profile: added a 'home' button and displaced the 'events' button to the events card";
    const String feat1_8_2_5 = "You can now copy to the clipboard the full URL you are visiting in Torn's "
        "website by pressing the page title for a few seconds";
    const String feat1_8_2_6 = "Bug fixes: travel percentage indicators and travel notification times "
        "were not working properly";
    v1_8_2.features.add(feat1_8_2_1);
    v1_8_2.features.add(feat1_8_2_2);
    v1_8_2.features.add(feat1_8_2_3);
    v1_8_2.features.add(feat1_8_2_4);
    v1_8_2.features.add(feat1_8_2_5);
    v1_8_2.features.add(feat1_8_2_6);

    // VERSION 1.8.1
    final v1_8_1 = ChangeLogItem();
    v1_8_1.version = 'Torn PDA v1.8.1';
    const String feat1_8_1_1 = "Loot: increased trigger options for loot notifications";
    const String feat1_8_1_2 = "Profile: corrected an issue causing delays when updating miscellaneous "
        "information";
    v1_8_1.features.add(feat1_8_1_1);
    v1_8_1.features.add(feat1_8_1_2);

    // VERSION 1.8.0
    final v1_8_0 = ChangeLogItem();
    v1_8_0.version = 'Torn PDA v1.8.0';
    const String feat1_8_0_1 = "Added a city item finder when you visit the city in Torn, with a list of "
        "items found and highlights on the map";
    const String feat1_8_0_2 = "Loot & Travel: you can now choose how long in advance will "
        "the notifications or other alerting methods be triggered";
    const String feat1_8_0_3 = "Browser: added a page refresh button at the top";
    const String feat1_8_0_4 = "Targets & Friends: you can now copy the ID to the clipboard";
    const String feat1_8_0_5 = "Profile: added a MISC section with bank and education expiries";
    const String feat1_8_0_6 = "Chaining: the bandage icon now gives access to your personal items, but "
        "also to your faction's armory";
    const String feat1_8_0_7 = "Fixed issue with alerts not working. If you are affected, please "
        "reload your API Key (just tap on 'reload')";
    v1_8_0.features.add(feat1_8_0_1);
    v1_8_0.features.add(feat1_8_0_2);
    v1_8_0.features.add(feat1_8_0_3);
    v1_8_0.features.add(feat1_8_0_4);
    v1_8_0.features.add(feat1_8_0_5);
    v1_8_0.features.add(feat1_8_0_6);
    v1_8_0.features.add(feat1_8_0_7);

    // VERSION 1.7.1
    final v1_7_1 = ChangeLogItem();
    v1_7_1.version = 'Torn PDA v1.7.1';
    const String feat1_7_1_1 = "Alerts section: added automatic alerts for hospital admission, "
        "revives and hospital release";
    const String feat1_7_1_2 = "Profile section: added TCT clock at the top";
    const String feat1_7_1_3 = "Chaining: added option to monitor your faction's chain while attacking "
        "several targets in a row";
    const String feat1_7_1_4 = "Targets section: replaced target's ID string with an extended information "
        "page for targets; also made the faction icon clickable for more details";
    const String feat1_7_1_5 = "Targets section: search form moved to the top, similar to the "
        "current layout in the Friends section";
    const String feat1_7_1_6 = "Travel section: added current item capacity value in the travel capacity "
        "dialog, so there is no need to move the slider to check it";
    const String feat1_7_1_7 = "Travel section: corrected an issue that prevented travel notifications "
        "from being manually activated in some cases";
    v1_7_1.features.add(feat1_7_1_1);
    v1_7_1.features.add(feat1_7_1_2);
    v1_7_1.features.add(feat1_7_1_3);
    v1_7_1.features.add(feat1_7_1_4);
    v1_7_1.features.add(feat1_7_1_5);
    v1_7_1.features.add(feat1_7_1_6);
    v1_7_1.features.add(feat1_7_1_7);

    // VERSION 1.7.0
    final v1_7_0 = ChangeLogItem();
    v1_7_0.version = 'Torn PDA v1.7.0';
    const String feat1_7_0_1 = "Added Trade Calculator, with total price calculation for cash, items and "
        "shares, plus the ability to copy total figures for a quick trading. Also added trades as "
        "a quick link in the Profile section";
    const String feat1_7_0_2 = "Decluttered the Travel section, with the foreign stocks page and "
        "notifications accessible through the floating button";
    const String feat1_7_0_3 = "Changed cooldown countdown to show total hours and minutes";
    v1_7_0.features.add(feat1_7_0_1);
    v1_7_0.features.add(feat1_7_0_2);
    v1_7_0.features.add(feat1_7_0_3);

    // VERSION 1.6.2
    final v1_6_2 = ChangeLogItem();
    v1_6_2.version = 'Torn PDA v1.6.2';
    const String feat1_6_2_1 = "Fixes error when loading API Key and the profile page for players "
        "that have deleted all their incoming events";
    v1_6_2.features.add(feat1_6_2_1);

    // VERSION 1.6.0
    final v1_6_0 = ChangeLogItem();
    v1_6_0.version = 'Torn PDA v1.6.0';
    const String feat1_6_0_1 = "New NPC Loot section";
    const String feat1_6_0_2 = "Added a quick crimes bar (internal app browser)";
    const String feat1_6_0_3 = "Added option to fill max travel items taking into "
        "account current money and capacity, as well as a quick return button "
        "in the app bar";
    const String feat1_6_0_4 = "Added energy in the automatic alerts section (beta)";
    const String feat1_6_0_5 = "Fixed issue with travel bar and timer not updating "
        "correctly after the flight has departed";
    v1_6_0.features.add(feat1_6_0_1);
    v1_6_0.features.add(feat1_6_0_2);
    v1_6_0.features.add(feat1_6_0_3);
    v1_6_0.features.add(feat1_6_0_4);
    v1_6_0.features.add(feat1_6_0_5);

    // VERSION 1.5.0
    final v1_5_0 = ChangeLogItem();
    v1_5_0.version = 'Torn PDA v1.5.0';
    const String feat1_5_0_1 = "New Alerts section with automatic notifications "
        "for travel";
    const String feat1_5_0_2 = "You can now set a custom trigger for energy and "
        "nerve notifications in the profile page";
    const String feat1_5_0_3 = "Several changes and another try at fixing issues "
        "reported by some players with the in-app browsers";
    const String feat1_5_0_4 = "Several other bug fixes and changes";
    v1_5_0.features.add(feat1_5_0_1);
    v1_5_0.features.add(feat1_5_0_2);
    v1_5_0.features.add(feat1_5_0_3);
    v1_5_0.features.add(feat1_5_0_4);

    // VERSION 1.4.1
    final v1_4_1 = ChangeLogItem();
    v1_4_1.version = 'Torn PDA v1.4.1';
    const String feat1_4_1_1 = "[Android] Now you can choose different notification "
        "styles (notification, alarm or timer) for each of the status bars and "
        "cooldowns available in the Profile section";
    const String feat1_4_1_2 = "Added option to select a test in-app browser, with a "
        "different engine, to try to solve issues reported by some players";
    const String feat1_4_1_3 = "Corrected Discord link in the About section";
    const String feat1_4_1_4 = "Several other bug fixes thanks to player feedback";
    if (Platform.isAndroid) {
      v1_4_1.features.add(feat1_4_1_1);
    }
    v1_4_1.features.add(feat1_4_1_2);
    v1_4_1.features.add(feat1_4_1_3);
    v1_4_1.features.add(feat1_4_1_4);

    // VERSION 1.4.0
    final v1_4_0 = ChangeLogItem();
    v1_4_0.version = 'Torn PDA v1.4.0';
    const String feat1_4_0_1 = "New 'About' section";
    const String feat1_4_0_2 = "You can now choose between 12h/24h time systems & "
        "local time (LT) or Torn City TIme (TCT) time zones";
    const String feat1_4_0_3 = "Added travel progress bar to the Travel section";
    const String feat1_4_0_4 = "Fixed an issue causing user settings preferences not "
        "to be applied after restarting the application";
    const String feat1_4_0_5 = "Fixed several issues reported in previous version "
        "(thanks Kivou + JDTech)";
    v1_4_0.features.add(feat1_4_0_1);
    v1_4_0.features.add(feat1_4_0_2);
    v1_4_0.features.add(feat1_4_0_3);
    v1_4_0.features.add(feat1_4_0_4);
    v1_4_0.features.add(feat1_4_0_5);

    // VERSION 1.3.0
    final v1_3_0 = ChangeLogItem();
    v1_3_0.version = 'Torn PDA v1.3.0';
    const String feat1_3_0_1 = "New Friends section, with quick access to player "
        "details and in-game actions. Personal notes and "
        "backup functionality is also included";
    const String feat1_3_0_2 = "New notifications (manually activated) added in the "
        "Profile section for energy, nerve, life and "
        "all cooldowns";
    const String feat1_3_0_3 = "Energy and nerve had their colors corrected in the "
        "Profile section to adapt to game colors";
    const String feat1_3_0_4 = "Other bug fixes and corrections thanks to "
        "players suggestions";
    v1_3_0.features.add(feat1_3_0_1);
    v1_3_0.features.add(feat1_3_0_2);
    v1_3_0.features.add(feat1_3_0_3);
    v1_3_0.features.add(feat1_3_0_4);

    // NEED TO ADD HERE!
    itemList.add(v3_2_4);
    itemList.add(v3_2_3);
    itemList.add(v3_2_2);
    itemList.add(v3_2_1);
    itemList.add(v3_2_0);
    itemList.add(v3_1_9);
    itemList.add(v3_1_8);
    itemList.add(v3_1_7);
    itemList.add(v3_1_6);
    itemList.add(v3_1_4);
    itemList.add(v3_1_3);
    itemList.add(v3_1_2);
    itemList.add(v3_1_1);
    itemList.add(v3_1_0);
    itemList.add(v3_0_2);
    itemList.add(v3_0_1);
    itemList.add(v2_9_6);
    itemList.add(v2_9_5);
    itemList.add(v2_9_3);
    itemList.add(v2_9_2);
    itemList.add(v2_9_1);
    itemList.add(v2_9_0);
    itemList.add(v2_8_9);
    itemList.add(v2_8_8);
    itemList.add(v2_8_7);
    itemList.add(v2_8_4);
    itemList.add(v2_8_2);
    itemList.add(v2_8_0);
    itemList.add(v2_7_0);
    itemList.add(v2_6_7);
    itemList.add(v2_6_6);
    itemList.add(v2_6_5);
    itemList.add(v2_6_4);
    itemList.add(v2_6_3);
    itemList.add(v2_6_2);
    itemList.add(v2_6_1);
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
      _changeLogItems.putIfAbsent(itemList[i], () => itemList[i].features);
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
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(15, 25, 15, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _items(),
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(
                thickness: 1,
                color: Colors.blueGrey,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: ElevatedButton(
                  child: const Text(
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
    final itemList = <Widget>[];
    var itemNumber = 1;

    itemList.add(
      const Padding(
        padding: EdgeInsets.only(bottom: 25),
        child: Text("CHANGELOG"),
      ),
    );

    for (final entry in _changeLogItems.entries) {
      if (itemNumber > 1) {
        itemList.add(
          const Padding(
            padding: EdgeInsets.symmetric(
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
          padding: const EdgeInsets.only(),
          child: Text(
            entry.key.version,
            style: const TextStyle(
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
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
        ),
      );

      // Info icon, if there is one
      if (entry.key.infoString.isNotEmpty) {
        itemList.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 10, 10, 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                ),
                const Padding(padding: EdgeInsets.only(right: 12)),
                Flexible(
                  child: Text(
                    entry.key.infoString,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // All other lines
      for (final feat in entry.value) {
        String featDescription = feat is ComplexFeature ? feat.text : feat;
        itemList.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: <Widget>[
                _pdaIcon(),
                const Padding(padding: EdgeInsets.only(right: 12)),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          featDescription,
                        ),
                      ),
                      if (feat is ComplexFeature && feat.explanation != null) _complexFeatureToast(feat),
                    ],
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

  /// If [secondsToShow] is null, the close button will be always shown
  Padding _complexFeatureToast(ComplexFeature feat) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: GestureDetector(
        child: Icon(Icons.info_outline),
        onTap: () {
          toastification.show(
            closeOnClick: true,
            alignment: Alignment.center,
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                feat.explanation!,
                maxLines: 100,
              ),
            ),
            autoCloseDuration: feat.secondsToShow == null ? null : Duration(seconds: feat.secondsToShow!),
            animationDuration: Duration(milliseconds: 200),
            showProgressBar: false,
            style: ToastificationStyle.flat,
            closeButtonShowType:
                feat.closeButton || feat.secondsToShow == null ? CloseButtonShowType.always : CloseButtonShowType.none,
            icon: Icon(Icons.info_outline),
            borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
          );
        },
      ),
    );
  }

  Widget _pdaIcon() {
    return const Padding(
      padding: EdgeInsets.only(right: 4),
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
