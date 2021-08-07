// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/settings_provider.dart';

enum TipClass {
  general,
  browserGeneral,
  browserTabs,
  travel,
  profile,
  chaining,
  trading,
}

class ExpandableTip {
  ExpandableTip({
    this.expandedValue,
    this.headerValue,
    this.isExpanded = false,
  });

  String expandedValue;
  String headerValue;
  bool isExpanded;
}

class TipsPage extends StatefulWidget {
  @override
  _TipsPageState createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  SettingsProvider _settingsProvider;

  var _generalTipList = <ExpandableTip>[];
  var _browserGeneralTipList = <ExpandableTip>[];
  var _browserTabsTipList = <ExpandableTip>[];
  var _travelTipsList = <ExpandableTip>[];
  var _profileTipsList = <ExpandableTip>[];
  var _chainingTipsList = <ExpandableTip>[];
  var _tradingTipsList = <ExpandableTip>[];

  @override
  void initState() {
    super.initState();
    _generalTipList = buildGeneralTips();
    _browserGeneralTipList = buildBrowserGeneralTips();
    _browserTabsTipList = buildBrowserTabsTips();
    _travelTipsList = buildTravelSectionTips();
    _profileTipsList = buildProfileSectionTips();
    _chainingTipsList = buildChainingTips();
    _tradingTipsList = buildTradingTips();

    analytics.logEvent(name: 'section_changed', parameters: {'section': 'tips'});
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Frequently asked questions and tips",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 25),
              Text("GENERAL"),
              SizedBox(height: 10),
              tipsPanels(TipClass.general),
              SizedBox(height: 25),
              Text("BROWSER - GENERAL"),
              SizedBox(height: 10),
              tipsPanels(TipClass.browserGeneral),
              SizedBox(height: 25),
              Text("BROWSER - TABS"),
              SizedBox(height: 10),
              tipsPanels(TipClass.browserTabs),
              SizedBox(height: 25),
              Text("TRAVEL SECTION"),
              SizedBox(height: 10),
              tipsPanels(TipClass.travel),
              SizedBox(height: 25),
              Text("PROFILE SECTION"),
              SizedBox(height: 10),
              tipsPanels(TipClass.profile),
              SizedBox(height: 25),
              Text("CHAINING"),
              SizedBox(height: 10),
              tipsPanels(TipClass.chaining),
              SizedBox(height: 25),
              Text("TRADING"),
              SizedBox(height: 10),
              tipsPanels(TipClass.trading),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Icon(Icons.dehaze),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      title: Text('Torn PDA - Tips'),
    );
  }

  Widget tipsPanels(TipClass tipClass) {
    var listToShow = <ExpandableTip>[];
    switch (tipClass) {
      case TipClass.general:
        listToShow = _generalTipList;
        break;
      case TipClass.browserGeneral:
        listToShow = _browserGeneralTipList;
        break;
      case TipClass.browserTabs:
        listToShow = _browserTabsTipList;
        break;
      case TipClass.travel:
        listToShow = _travelTipsList;
        break;
      case TipClass.profile:
        listToShow = _profileTipsList;
        break;
      case TipClass.chaining:
        listToShow = _chainingTipsList;
        break;
      case TipClass.trading:
        listToShow = _tradingTipsList;
        break;
    }

    return ExpansionPanelList(
      expandedHeaderPadding: const EdgeInsets.all(0),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          listToShow[index].isExpanded = !isExpanded;
        });
      },
      children: listToShow.map<ExpansionPanel>((ExpandableTip tip) {
        return ExpansionPanel(
          canTapOnHeader: true,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(
                tip.headerValue,
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            );
          },
          body: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 15),
            child: ListTile(
              title: Text(
                tip.expandedValue,
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
          ),
          isExpanded: tip.isExpanded,
        );
      }).toList(),
    );
  }

  List<ExpandableTip> buildGeneralTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "App bar position",
        expandedValue: "You can optionally position the main app bar at the top (default) or bottom (as requested "
            "by some users, as it is easier to reach in bigger screens). This can be changed in the Settings section.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Torn user/pass autocomplete",
        expandedValue: "Android: long-press the username field and then the three vertical dots. You should be able "
            "to activate autocomplete from then on.\n\n"
            "iOS: you should be able to autocomplete the user/pass from iCloud's or any other keychain (e.g. Chrome).\n\n"
            "NOTE: this functionality is from the OS (Android/iOS), Torn PDA will never store your Torn username or password.",
      ),
    );
    if (Platform.isAndroid) {
      tips.add(
        ExpandableTip(
          headerValue: "Android notification channels",
          expandedValue:
              "All apps developed for Android 8 (Oreo) and newer versions can optionally add separated notifications channels "
              "so that users can customize the sound, vibration and visual alerts for each notification."
              "\n\nTorn PDA adds three notification channels for each type of notification (this is to separate vibration in short, medium and long), "
              "which you can customize accessing Android's Settings / All Apps / Torn PDA / Notifications.",
        ),
      );
    }
    return tips;
  }

  List<ExpandableTip> buildBrowserGeneralTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "What browser should I use?",
        expandedValue: "You can choose between 'external' and 'in-app' browser. "
            "This is accomplished in the Settings section.\n\n"
            "The earlier will open your mobile phone's default browser application, but you will lose most "
            "functionalities in Torn PDA (such as quick crimes, trades calculator, city finder...)",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Chaining browser",
        expandedValue:
            "Please be aware that the browser used in the chaining section is focused on improving the chaining experience.\n\nIt does not "
            "have as many features as the standard browser that you can use in other sections of the app. One exception is the "
            "Quick Items feature, since this can be helpful while chaining.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Quick browser and full browser",
        expandedValue: "There are two ways of using the 'in-app' browser in Torn PDA: 'quick' and 'full' browser.\n\n"
            "By default, a short tap in buttons, bars or icons will open the 'quick browser', which loads faster "
            "and allows to accomplish actions quicker. However, the options bar and its icons are only visible in the "
            "'full browser' version, which can be opened with a long-press in the same places.\n\n"
            "This also applies, for example, for the main 'T' menu in the Profile section. After expanding it, you can "
            "short tap or long-press to use the quick or full browsers.\n\n"
            "In the Settings section you can disable the quick browser if you prefer to always use the full one.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How can I browse back or forward?",
        expandedValue:
            "If using the full browser, swipe your finger right or left across the title bar to browse back or "
            "forward respectively. If using the quick browser, there are dedicated icons at the bottom.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How do I browse to a custom URL?",
        expandedValue: "Full browser: short tap the title bar to open a small dialog with several options.\n\n"
            "Quick browser: long-press the bottom bar (where the 'close' button is) to open the same dialog.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How do I copy the current URL?",
        expandedValue: "Full browser: short tap the title bar to open a small dialog with several options.\n\n"
            "Quick browser: long-press the bottom bar (where the 'close' button is) to open the same dialog.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Save the current URL as a shortcut or navigate to an existing one",
        expandedValue: "Full browser: short tap the title bar to open a small dialog with several options.\n\n"
            "Quick browser: long-press the bottom bar (where the 'close' button is) to open the same dialog.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Use terminal (developers only)",
        expandedValue: "There is a Terminal window (read only) available for development use (so that you can see "
            "scripts or section outputs). To activate it:"
            "\n\nFull browser: short tap the title bar to open a small dialog with several options.\n\n"
            "Quick browser: long-press the bottom bar (where the 'close' button is) to open the same dialog.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildBrowserTabsTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Change tabs order",
        expandedValue: "To move a tab in the bar, maintain the tab pressed for a couple of seconds and then drag it "
            "to the desired position.\n\nNote: the position of the first tab can't be changed.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Use the chat in different tabs",
        expandedValue: "You can activate or deactivate the chat in separate tabs by short-tapping the chat icon "
            "(enabled in Settings by default)."
            "\n\nIf you wish to change the standard behaviour of the chat when a new tab is opened, long-press the "
            "chat icon in any tab and you'll get a confirmation message of the change.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Duplicate first tab",
        expandedValue: "If you want to quickly save your first tab, long-press it for a couple of seconds "
            "and it will be cloned into the bar.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Toggle between icons and page titles in tabs",
        expandedValue: "By long-pressing the add tab button (+), you can switch between icons and page "
            "title in your tabs.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Hide tabs temporarily",
        expandedValue: "You can temporarily hide tabs so that the don't take space."
            "\n\nFull browser: tap and hold the title bar, then slide up or down.\n\n"
            "Quick browser: tap and hold the bottom bar (where the 'close' button is), then slide up or down.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildTravelSectionTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Tap on flag icons",
        expandedValue: "When checking the foreign stocks, tapping on the flag of a particular item will "
            "transport you to the Travel Agency and check whether you have enough money available (this is "
            "based on your 'items capacity', which you can set at the options bar).",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Quick return",
        expandedValue: "When abroad, if using the full browser, you will be able to see a house icon that "
            "will start your flight back immediately.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildProfileSectionTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Tap on bars",
        expandedValue: "Try tapping or long-pressing main bars (energy, nerve, happy, life) to "
            "access their main sections in Torn.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Using shortcuts",
        expandedValue: "You can add as many custom shortcuts as you like. There is also a long list "
            "available with preconfigured shortcuts. Tapping or long-pressing shortcut tiles "
            "will open a quick or full browser.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Basic Info icons",
        expandedValue: "Try tapping or long-pressing the cash and points icons!",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Medic call",
        expandedValue:
            "When you are in hospital, you'll get the chance to call a reviver by using the icon that appears in the Profile section (status card).\n\n"
            "You can use one of two partners: Central Hospital or Universal Health Care (activate or deactivate them in options in the Profile section).\n\n"
            "Your call will automatically alert all available revivers in the selected partner's Discord channel.\n\n"
            "Have a look at the information contained in the revive dialog and be aware that this is a paid service!",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Why can't I see organized crimes in the Profile Section?",
        expandedValue:
            "In order to see organized crimes predictions, you need to have AA (API Access) permission from your faction leaders.\n\n"
            "This is a Torn restriction built to ensure that faction leaders can control the access their members have to certain information through the API.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildChainingTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Sync targets with YATA",
        expandedValue: "You can export and import your targets to and from YATA. Look for the 'Y' icon in the "
            "main app bar when in the Targets section.",
      ),
    );
    /*
    tips.add(
      ExpandableTip(
        headerValue: "Use Torn Attack Central",
        expandedValue:
            "You can get suggested targets from Torn Attack Central (see their website for more information).\n\nYou can "
            "access this feature through the third bottom tab, named 'TAC', in the Chaining section. If it's not there, please "
            "enter the options menu in the main Targets screen to activate it.",
      ),
    );
    */
    return tips;
  }

  List<ExpandableTip> buildTradingTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Trading calculator",
        expandedValue: "If you visit a trade in game, a Trade Calculator widget will open. Tap on "
            "it to expand it for more details!",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Sync with Torn Trader",
        expandedValue: "If you are a user of Torn Trader, tap on the options icon while in the Trades section in game. "
            "You will be able to activate the synchronization with this service and use most of it features from the Torn PDA!",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Quick vault access",
        expandedValue:
            "While in the Trade section in game, you'll have a button for quick access to your vaults available in the main app bar.\n\n"
            "After tapping on it you will be redirected to your choice and the full browser close icon will change from a cross to an arrow, "
            "indicating that it will redirect you back to the trade instead of closing the browser.",
      ),
    );
    return tips;
  }
}
