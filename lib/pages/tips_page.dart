import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';

enum TipClass {
  general,
  browser,
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
  var _browserTipList = <ExpandableTip>[];
  var _travelTipsList = <ExpandableTip>[];
  var _profileTipsList = <ExpandableTip>[];
  var _chainingTipsList = <ExpandableTip>[];
  var _tradingTipsList = <ExpandableTip>[];

  @override
  void initState() {
    super.initState();
    _generalTipList = buildGeneralTips();
    _browserTipList = buildBrowserTips();
    _travelTipsList = buildTravelSectionTips();
    _profileTipsList = buildProfileSectionTips();
    _chainingTipsList = buildChainingTips();
    _tradingTipsList = buildTradingTips();
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
              Text("BROWSERS"),
              SizedBox(height: 10),
              tipsPanels(TipClass.browser),
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
      brightness: Brightness.dark,
      leading: IconButton(
        icon: Icon(Icons.dehaze),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
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
      case TipClass.browser:
        listToShow = _browserTipList;
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
        expandedValue:
            "You can optionally position the main app bar at the top (default) or bottom (as requested "
            "by some users, as it is easier to reach in bigger screens). This can be changed in the Settings section.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Torn user/pass autocomplete",
        expandedValue:
            "Android: long-press the username field and then the three vertical dots. You should be able "
            "to activate autocomplete from then on.\n\n"
            "iOS: you should be able to autocomplete the user/pass from iCloud's or any other keychain (e.g. Chrome).\n\n"
            "NOTE: this functionality is from the OS (Android/iOS), Torn PDA will never store your Torn username or password.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildBrowserTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "What browser should I use?",
        expandedValue:
            "You can choose between 'external' and 'in-app' browser. "
            "This is accomplished in the Settings section.\n\n"
            "The earlier will open your mobile phone's default browser application, but you will lose most "
            "functionalities in Torn PDA (such as quick crimes, trades calculator, city finder...)",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Quick browser and full browser",
        expandedValue:
            "There are two ways of using the 'in-app' browser in Torn PDA: 'quick' and 'full' browser.\n\n"
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
        expandedValue:
            "Full browser: short tap the title bar to open a small dialog with several options.\n\n"
            "Quick browser: long-press the bottom bar (where the 'close' button is) to open the same dialog.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How do I copy the current URL?",
        expandedValue:
            "Full browser: short tap the title bar to open a small dialog with several options.\n\n"
            "Quick browser: long-press the bottom bar (where the 'close' button is) to open the same dialog.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How do I save the current URL as a shortcut?",
        expandedValue:
            "Full browser: short tap the title bar to open a small dialog with several options.\n\n"
            "Quick browser: long-press the bottom bar (where the 'close' button is) to open the same dialog.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildTravelSectionTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Tap on flag icons",
        expandedValue:
            "When checking the foreign stocks, tapping on the flag of a particular item will "
            "transport you to the Travel Agency and check whether you have enough money available (this is "
            "based on your 'items capacity', which you can set at the options bar).",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Quick return",
        expandedValue:
            "When abroad, if using the full browser, you will be able to see a house icon that "
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
        expandedValue:
            "Try tapping or long-pressing main bars (energy, nerve, happy, life) to "
            "access their main sections in Torn.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Using shortcuts",
        expandedValue:
            "You can add as many custom shortcuts as you like. There is also a long list "
            "available with preconfigured shortcuts. Tapping or long-pressing shortcut tiles "
            "will open a quick or full browser.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Basic Info icons",
        expandedValue:
            "Try tapping or long-pressing the cash and points icons!",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildChainingTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Sync targets with YATA",
        expandedValue:
            "You can export and import your targets to and from YATA. Look for the 'Y' icon in the "
            "main app bar when in the Targets section.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildTradingTips() {
    var tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Trading calculator",
        expandedValue:
            "If you visit a trade in game, a Trade Calculator widget will open. Tap on "
            "it to expand it for more details!",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Sync with Torn Trader",
        expandedValue:
            "If you are a user of Torn Trader, tap on the options icon while in the Trades section in game. "
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
