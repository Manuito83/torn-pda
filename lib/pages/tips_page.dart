// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:app_settings/app_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/fullscreen_explanation.dart';
import 'package:torn_pda/widgets/webviews/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

enum TipClass {
  general,
  browserGeneral,
  browserTabs,
  appwidget,
  travel,
  profile,
  factionCommunication,
  chaining,
  chainingWar,
  spies,
  trading,
  deepLinks,
  userScripts,
}

abstract class TipTextBuilder {
  TipTextBuilder({
    this.headerValue = "",
    this.isExpanded = false,
  });

  String headerValue;
  bool isExpanded;

  Text? buildExpandedText();

  Text buildHeaderText() {
    return Text(
      headerValue,
      style: const TextStyle(
        fontSize: 15,
      ),
    );
  }
}

class ExpandableTip extends TipTextBuilder {
  ExpandableTip({this.expandedValue, super.headerValue, super.isExpanded});

  String? expandedValue;

  @override
  Text buildExpandedText() {
    return Text(
      expandedValue!,
      style: const TextStyle(
        fontSize: 13,
      ),
    );
  }
}

class ComplexExpandableTip extends TipTextBuilder {
  ComplexExpandableTip({Text Function()? buildExpandedText, super.headerValue, super.isExpanded}) {
    _buildExpandedTextFn = buildExpandedText;
  }

  Function? _buildExpandedTextFn;

  @override
  Text? buildExpandedText() {
    return _buildExpandedTextFn!();
  }
}

class TipsPage extends StatefulWidget {
  @override
  TipsPageState createState() => TipsPageState();
}

class TipsPageState extends State<TipsPage> {
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;
  late WebViewProvider _webViewProvider;

  var _generalTipList = <TipTextBuilder>[];
  var _browserGeneralTipList = <TipTextBuilder>[];
  var _browserTabsTipList = <TipTextBuilder>[];
  var _appwidgetTipsList = <TipTextBuilder>[];
  var _travelTipsList = <TipTextBuilder>[];
  var _profileTipsList = <TipTextBuilder>[];
  var _factionCommunicationTipsList = <TipTextBuilder>[];
  var _chainingTipsList = <TipTextBuilder>[];
  var _chainingWarTipsList = <TipTextBuilder>[];
  var _spiesTipsList = <TipTextBuilder>[];
  var _tradingTipsList = <TipTextBuilder>[];
  var _deepLinksTipsList = <TipTextBuilder>[];
  var _userScriptsTipsList = <TipTextBuilder>[];

  @override
  void initState() {
    super.initState();
    _generalTipList = buildGeneralTips();
    _browserGeneralTipList = buildBrowserGeneralTips();
    _browserTabsTipList = buildBrowserTabsTips();
    _appwidgetTipsList = buildAppwidgetSectionTips();
    _travelTipsList = buildTravelSectionTips();
    _profileTipsList = buildProfileSectionTips();
    _factionCommunicationTipsList = buildFactionCommunicationTips();
    _chainingTipsList = buildChainingTips();
    _chainingWarTipsList = buildChainingWarTips();
    _spiesTipsList = buildSpiesTips();
    _tradingTipsList = buildTradingTips();
    _deepLinksTipsList = buildDeepLinksTips();
    _userScriptsTipsList = buildUserScriptsTipsList();

    analytics.setCurrentScreen(screenName: 'tips');

    routeWithDrawer = true;
    routeName = "tips";
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: const Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "Frequently asked questions and tips",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                const Text("GENERAL"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.general),
                const SizedBox(height: 25),
                const Text("BROWSER - GENERAL"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.browserGeneral),
                const SizedBox(height: 25),
                const Text("BROWSER - TABS"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.browserTabs),
                const SizedBox(height: 25),
                if (Platform.isAndroid)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("HOME SCREEN WIDGET"),
                      const SizedBox(height: 10),
                      tipsPanels(TipClass.appwidget),
                    ],
                  ),
                const SizedBox(height: 25),
                const Text("TRAVEL SECTION"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.travel),
                const SizedBox(height: 25),
                const Text("PROFILE SECTION"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.profile),
                const SizedBox(height: 25),
                const Text("FACTION COMMUNICATION"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.factionCommunication),
                const SizedBox(height: 25),
                const Text("CHAINING - GENERAL"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.chaining),
                const SizedBox(height: 25),
                const Text("CHAINING - WAR"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.chainingWar),
                const SizedBox(height: 25),
                const Text("SPIES"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.spies),
                const SizedBox(height: 25),
                const Text("TRADING"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.trading),
                const SizedBox(height: 25),
                const Text("APP LINKS"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.deepLinks),
                const SizedBox(height: 25),
                const Text("USERSCRIPTS"),
                const SizedBox(height: 10),
                tipsPanels(TipClass.userScripts),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 80,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.webViewSplitActive &&
                    _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
      title: const Text('Torn PDA - Tips'),
    );
  }

  Widget tipsPanels(TipClass tipClass) {
    var listToShow = <TipTextBuilder>[];
    switch (tipClass) {
      case TipClass.general:
        listToShow = _generalTipList;
      case TipClass.browserGeneral:
        listToShow = _browserGeneralTipList;
      case TipClass.browserTabs:
        listToShow = _browserTabsTipList;
      case TipClass.appwidget:
        listToShow = _appwidgetTipsList;
      case TipClass.travel:
        listToShow = _travelTipsList;
      case TipClass.profile:
        listToShow = _profileTipsList;
      case TipClass.factionCommunication:
        listToShow = _factionCommunicationTipsList;
      case TipClass.chaining:
        listToShow = _chainingTipsList;
      case TipClass.chainingWar:
        listToShow = _chainingWarTipsList;
      case TipClass.spies:
        listToShow = _spiesTipsList;
      case TipClass.trading:
        listToShow = _tradingTipsList;
      case TipClass.deepLinks:
        listToShow = _deepLinksTipsList;
      case TipClass.userScripts:
        listToShow = _userScriptsTipsList;
    }

    return ExpansionPanelList(
      expandedHeaderPadding: const EdgeInsets.all(0),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          listToShow[index].isExpanded = isExpanded;
        });
      },
      children: listToShow.map<ExpansionPanel>((TipTextBuilder tip) {
        return ExpansionPanel(
          canTapOnHeader: true,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(title: tip.buildHeaderText());
          },
          body: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 15),
            child: ListTile(title: tip.buildExpandedText()),
          ),
          isExpanded: tip.isExpanded,
        );
      }).toList(),
    );
  }

  List<ExpandableTip> buildGeneralTips() {
    final tips = <ExpandableTip>[];

    tips.add(
      ExpandableTip(
        headerValue: "App bar position",
        expandedValue: "You can optionally position the main app bar at the top (default) or bottom (as requested "
            "by some users, as it is easier to reach in bigger screens). This can be changed in the Settings section.",
      ),
    );

    tips.add(
      ExpandableTip(
        headerValue: "Torn native login",
        expandedValue: "By providing Torn PDA with your Torn username and password in Settings, Torn PDA will make "
            "use of Torn's native login system to periodically request authorization and keep you logged in at all times."
            "\n\nAlso, in the event that the app recognizes a logout condition, it will be able to log you back in "
            "in a matter of seconds without any interaction from your side."
            "\n\nPlease note that this login workflow has been designed with Torn's dev team, so it's officially "
            "approved. In any case, Torn PDA will not store your original credentials anywhere."
            "\n\nVisit the Settings section for more information on how to proceed.",
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

  List<ComplexExpandableTip> buildBrowserGeneralTips() {
    final tips = <ComplexExpandableTip>[];
    tips.add(
      ComplexExpandableTip(
        headerValue: "What browser should I use?",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "You can choose between 'external' and 'in-app' browser. "
                  "This is accomplished in the Settings section.\n\n"
                  "The earlier will open your mobile phone's default browser application, but you will lose most "
                  "functionalities in Torn PDA (such as quick crimes, trades calculator, city finder...)",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "How do I access the browser?",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "There are several ways:\n\n"
                  "If you would like to browse to a specific section in Torn, you can tap or long-press most of "
                  "the widgets in the apps (e.g.: life and nerve bars). This will automatically switch to the browser "
                  "view and navigate to your desired section.\n\n"
                  "If you just want to open Torn to resume your browsing session where you left it, you can just tap "
                  "the white Torn PDA icon in the app bar, which will show the browser as it was left the last time.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Short tap vs. long-press",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "The browser will open both after a short tap or a long-press in any of the widgets that redirect "
                  "to Torn, as explained in the previous Tip. By default, a short-tap will open the browser in a windowed "
                  "mode, whereas a long-press will launch it in full screen mode.\n\n"
                  "You can change this behavior in Settings. There is also more information about the full screen mode "
                  "in another Tip below.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Browser styles",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "There are three different browser styles in Torn PDA: the 'default', the 'bottom bar' "
                  "and the 'dialog' styles. "
                  "\n\nThey resemble the looks of the former 'full' and 'quick' browsers in previous versions of the "
                  "app, but they all share the same functionality today (including chaining).\n\n"
                  "The 'default' style makes use of the app bar (positioned at the top or at the bottom, "
                  "depending on the user settings) to show the page title and main icons. Be aware that in this "
                  "style, you need to swipe left/right across the title bar if you wish to browser forward or back. "
                  "Or, alternatively (valid for all styles) you can double tap the active tab to gain access to "
                  "back/forward navigation as well.\n\n"
                  "The 'bottom' bar style places a smaller bar at the bottom to gain some space, but does not show "
                  "the page title. Instead, a long press in the 'CLOSE' button is necessary to access some of the "
                  "options that are available in the 'default' style with a tab in the title bar. In this style you'll "
                  "also have a couple of extra icons available to browse back or forward.\n\n"
                  "The 'dialog' style is similar to the bottom bar style, but the browser is positioned inside of "
                  "a dialog, which makes it a bit narrower and looks exactly as the old 'quick browser'.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Chaining tab",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text:
                  "Whenever you access the browser from a target attack request (in the Chaining section), your first "
                  "browser tab will be converted to a special 'chaining tab', with additional icons at the top (*) that "
                  "will allow you to continue from one target to another, until you reach the end of your list.\n\n"
                  "Please be aware that you can stop your chain session at any time by long-pressing the play/pause "
                  "button at the right corner (*) of your app bar.\n\n"
                  "It is not recommended to use this tab for normal day-to-day widget usage (such us quick items, "
                  "crimes, etc.) since it can lack some of the normal features in certain cases. Instead, it is better "
                  "to stop the chain session or use another tab.\n\n"
                  "(*): Please note that chain control buttons are also accesible if you tap/double tap your first browser "
                  "tab while chaining, which makes them also easily accesible if you are using the full screen mode.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "How can I browse back or forward?",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "There are several ways: you can either swipe your finger right or left across the title bar "
                  "or double-tap any tab (while selected) and use the arrows in the vertical menu that appears.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "How do I browse to a custom URL?",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "Default style browser: short tap the title bar to open a small dialog with several options.\n\n"
                  "'Bottom-bar' or 'dialog' styles: long-press the CLOSE button to open a small dialog with several options.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "How do I copy the current URL?",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "Full browser: short tap the title bar to open a small dialog with several options.\n\n",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Save the current URL as a shortcut or navigate to an existing one",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "If you are using tabs, a quick menu icon (three dots) will appear to the right. "
                  "Tapping it will a vertical menu, with several shortcut options (heart icons).\n\n"
                  "Alternatively, if you are not using tabs, you can also tap the title bar to open a "
                  "dialog with several options.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Ellipsis (...) button",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "This '...' button appears in your tab bar and is relevant to access several functions. If used "
                  "correctly, it can also speed up several tasks.\n\n"
                  "You can tap it to show a quick list of quick actions, including shortcuts, access to the full screen "
                  "mode and a tap wipe tool.\n\nThere are also a few important quick shortcuts:\n\n"
                  "Double tap the button any time to get quick access to the shortcuts dialog\n\n"
                  "When in full screen mode, long-press the button (it will be shown circled and with an orange color) "
                  "to revert to windowed mode immediately",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Pull to refresh",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "You can activate the pull to refresh functionality for the main browser in Settings.\n\n"
                  "There are certain (short) pages in Torn, with no scroll, that might not activate this feature; "
                  "if that's the case, try pulling down from Torn's appbar at the very top!",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Full screen mode",
        buildExpandedText: () {
          return Text.rich(
            TextSpan(
              text: "The browser supports full screen, which can be activated from the quick menu tab in the "
                  "tab bar. \n\nTo access this feature, you need to have 'tabs' enabled in the "
                  "Advanced Browser Settings section (in the app's Settings menu).",
              style: const TextStyle(
                fontSize: 13,
              ),
              children: [
                const TextSpan(
                  text: "\n\nFor more information, please ",
                ),
                TextSpan(
                  text: "tab here",
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      return showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const FullScreenExplanationDialog();
                        },
                      );
                    },
                ),
                const TextSpan(
                  text: "!",
                ),
              ],
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Use terminal (developers only)",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "There is a Terminal window (read only) available for development use (so that you can see "
                  "scripts or section outputs). To activate it, short tap the title bar to open a small dialog "
                  "with several options.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    return tips;
  }

  List<ExpandableTip> buildBrowserTabsTips() {
    final tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Close tab",
        expandedValue: "To close a tab, you have two options: you can either DOUBLE TAP it to access the vertical "
            "menu and do it from there (with the red bin icon), or alternatively with a TRIPLE TAP, which will close "
            "the selected tab instantly (except for the first one, which is persistent).",
      ),
    );
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
        headerValue: "Duplicate tabs",
        expandedValue: "If you want to quickly save a tab, double-tap it and look for the duplicate (copy/paste) icon,",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Toggle between icons and page titles in the tabs bar",
        expandedValue: "By long-pressing the add tab button (+), you can switch between icons and page "
            "title in your tabs.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Hide tabs temporarily",
        expandedValue: "You can temporarily hide tabs so that they don't take space."
            "\n\nIf you are using the 'default' browser style: tap and hold the title bar, then slide up or down.\n\n"
            "If you are using the 'bottom-bar' or 'dialog' styles: tab and hold the CLOSE button, then slide up or down.",
      ),
    );
    return tips;
  }

  List<ComplexExpandableTip> buildAppwidgetSectionTips() {
    final tips = <ComplexExpandableTip>[];
    tips.add(
      ComplexExpandableTip(
        headerValue: "Battery restrictions",
        buildExpandedText: () {
          return Text.rich(
            TextSpan(
              text: "Please be aware that the home screen widget has been built taking battery consumption into "
                  "consideration. It fetches the API and updates the layout once every few minutes, trying to minimize the "
                  "use of background tasks.\n\n"
                  "However, depending on your device model or launcher selection, further restrictions might be applied; if "
                  "that is the case, the widget might not update as much as expected.\n\n"
                  "This is also the case for widget initialization after the device is rebooted, which is restricted by "
                  "some launchers.\n\n"
                  "Check your ",
              style: const TextStyle(
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: "Android's app settings",
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      AppSettings.openAppSettings();
                    },
                ),
                const TextSpan(
                  text: ".",
                ),
              ],
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Widget interaction",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "As in the app, you can interact with almost every item in the widget (e.g.: tap the energy "
                  "bar to launch the app and access the gym).\n\n"
                  "Also, your 9 top shortcuts in the main shortcuts list (which you can configure in Settings) will "
                  "be shown in the widget. If you can't see the shortcuts in the widget, "
                  "ensure you expand it vertically!",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    tips.add(
      ComplexExpandableTip(
        headerValue: "Widget theme",
        buildExpandedText: () {
          return const Text.rich(
            TextSpan(
              text: "You can change the home widget theme in the Settings menu in Torn PDA!",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );

    return tips;
  }

  List<ExpandableTip> buildTravelSectionTips() {
    final tips = <ExpandableTip>[];
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
        expandedValue: "When abroad, you will be able to see a house icon in the app bar that "
            "will start your flight back immediately (press it twice!).",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildProfileSectionTips() {
    final tips = <ExpandableTip>[];
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
            "available with pre-configured shortcuts. Tapping or long-pressing shortcut tiles "
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
            "You can use several reviving partners (you can activate or deactivate them separately in Settings).\n\n"
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

  List<ExpandableTip> buildFactionCommunicationTips() {
    final tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Request attack assistance from your faction mates",
        expandedValue: "When you are in the attack screen, the browser's URL menu (accessed by short tapping "
            "the title bar in the 'default' browser style or the CLOSE button in the two other styles) will show a "
            "new button, marked in red, labelled 'FACTION ASSISTANCE'.\n\n"
            "Tapping this button will send a notification to all your faction mates that use Torn PDA and have the "
            "'Faction assist messages' option enabled in the Alerts section.\n\n"
            "By tapping the notification they will be able to join your attack and provide assistance.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Toggle attack assist messages",
        expandedValue: "You can toggle this option in the Alerts section.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildChainingTips() {
    final tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Panic Mode (chain watcher)",
        expandedValue: "By enabling Panic Mode, a new 'P' icon will appear in the chain widget, which in turn will "
            "allow you to toggle the Panic Mode on/off when you desire.\n\n"
            "When Panic Mode is active, regardless of your alerts' configuration below, only the panic "
            "alert will sound. If you have targets configured, the browser will automatically open to "
            "the first available (non blue/red) one. Think about using easy/quick targets.\n\n"
            "This can be specially useful when chain watching while asleep, working, etc.\n\n"
            "Remember you need to leave Torn PDA open, "
            "with the screen active, for the Panic Mode to work as well.\n\n"
            "NOTE: the browser used by Panic Mode does not contain any of the features (widgets, etc.) "
            "of the standard browser, as it is designed to load as quickly as possible.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Add targets to Panic Mode",
        expandedValue: "You can add or remove targets from the Panic Mode list either via the chain widget's "
            "options menu or by swiping left on any target card.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Targets cards with blue (right) border",
        expandedValue: "A blue border on the right hand side of your standard/war targets' cards means that they "
            "are part of your Panic Mode targets.",
      ),
    );
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

  List<ExpandableTip> buildChainingWarTips() {
    final tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "What is this section for?",
        expandedValue: "The War section, inside of Chaining, is designed to help with faction warring. You can "
            "add entire enemy factions, sort their members, hide the ones you don't want to see, and use the list as "
            "you would with the standard chaining list to attack several players in a row.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How can I add new factions?",
        expandedValue: "Tap on the faction icon in the app bar and a new dialog will appear.\n\n"
            "You can use the faction's ID if you know it. Otherwise, click on the person icon to the right: "
            "this will allow you to enter the ID of any player that belongs to the faction instead.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Why is some information (e.g. life and stats) missing?",
        expandedValue: "When you add a faction, some of its members information won't be retrieved from the API "
            "to avoid unnecessary API calls. However, this information will be updated as soon as you "
            "update an individual target or perform a global update (via the app bar).",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Updating faction targets",
        expandedValue: "There are a couple of ways to update war targets.\n\nWith a short tap, you can perform "
            "a quick update with minimal target information (some stats and life information won't be available).\n\n"
            "A long-press will start a slower but full update of all targets.\n\n"
            "Alternatively, you can update targets individually. This also show expanded information.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Can I hide an entire faction temporarily?",
        expandedValue: "Yes. Tap on the faction icon in the app bar and then use the 'eye' icon.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Can I hide a target?",
        expandedValue: "Yes. Swipe right the target's card to hide it.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How can I unhide targets?",
        expandedValue: "Tap in the options (gear) icon in the app bar. If there are any hidden targets, you'll "
            "be able to unhide them from there.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Where's the last online information gone?",
        expandedValue: "You've got a good indication on the user's online status by looking at the indicator in the "
            "third row of each card: grey (offline), orange (idle) and green (online).\n\n"
            "If you need more details (like the number of hours offline), tap the indicator and a message will appear.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How are factions updated (members joining/leaving)",
        expandedValue: "Torn PDA will update each faction's roster upon entering the Chaining section (at intervals "
            "not lower than 1 hour) or whenever a global update is performed by the user.",
      ),
    );
    return tips;
  }

  List<ExpandableTip> buildSpiesTips() {
    final tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "What are spies? How are exact enemy stats retrieved?",
        expandedValue: "If your faction maintains a list of spies in YATA or Torn Stats, Torn PDA can retrieve it "
            "and show exact stats in several sections (the Profile Widget in the browser, and the War and Retalation "
            "sections inside of Chaining).\n\nPlease bear in mind that you might need to have "
            "special permissions in YATA or Torn Stats in order for this to work (ask your faction leader about it!)."
            "\n\nIn short, you will be able to see other players battlestats as spied in game. Some providers also "
            "store the date of when the stats were spied, in which case Torn PDA also shows this information."
            "\n\nYou can switch between YATA and Torn Stats as your source of spies in Settings."
            "\n\nIf exact stats can't be obtained, then Torn PDA will calculate approximate stats.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "Are spies retrieved and updated automatically?",
        expandedValue: "No. Although this was an automatic process in the past (before v3.2.0), waiting for the spies "
            "providers to update proved to cause some delays in certain situations (during weekends, big wars or "
            "competitions), which in turn was making Torn PDA's interface slower as it was waiting for this data."
            "\n\nTo avoid this, spies need to be updated manually. Please remember to do so as instructed by "
            "your faction, or before chaining, warring, etc.",
      ),
    );
    tips.add(
      ExpandableTip(
        headerValue: "How can I manage my spies, update them or change providers?",
        expandedValue: "You can do all this in the Settings section (look for the spies subsection). You will be able "
            "to see what your current provider is, how many spies are synced, when were they retrieved for the last time, "
            "swap providers and update your spies list.\n\n"
            "For convenience, this is also accesible through the options (gear) icon in the War and Retals sections "
            "(inside of Chaining).",
      ),
    );

    return tips;
  }

  List<ExpandableTip> buildTradingTips() {
    final tips = <ExpandableTip>[];
    tips.add(
      ExpandableTip(
        headerValue: "Trading calculator",
        expandedValue: "If you visit a trade in game, a Trade Calculator widget will open. Tap on "
            "it to expand it for more details!",
      ),
    );
    /*
    tips.add(
      ExpandableTip(
        headerValue: "Sync with Torn Trader",
        expandedValue: "If you are a user of Torn Trader, tap on the options icon while in the Trades section in game. "
            "You will be able to activate the synchronization with this service and use most of it features from the Torn PDA!",
      ),
    );
    */
    tips.add(
      ExpandableTip(
        headerValue: "Sync with Arson Warehouse",
        expandedValue:
            "If you are a user of Arson Warehouse (AWH), tap on the options icon while in the Trades section in game. "
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

  List<TipTextBuilder> buildDeepLinksTips() {
    final tips = <TipTextBuilder>[];
    tips.add(
      ComplexExpandableTip(
        headerValue: "Deep/custom app links",
        buildExpandedText: () {
          return Text.rich(
            TextSpan(
              text: "Torn PDA supports what's called deep linking or custom URLs. You can create a link outside "
                  "of the application with the following scheme 'tornpda://', where the rest of the URL remains unchanged."
                  "\n\nExample: 'tornpda://www.torn.com/gym.php' should be recognized as a valid URL and open Torn PDA with "
                  "a browser pointing to the gym."
                  "\n\nIn order for this to work in some browser (e.g.: Chrome), you'll need to adapt "
                  "your link to be similar to this example:\n\n",
              style: const TextStyle(
                fontSize: 13,
              ),
              children: [
                const TextSpan(
                  text:
                      '<a href="intent://tornpda://www.cnn.com#Intent;package=com.manuito.tornpda;scheme=tornpda;end">click</a>',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const TextSpan(
                  text: "\n\nYou can find more information about this scheme in Chrome's ",
                ),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      const String url = "https://developer.chrome.com/docs/multidevice/android/intents/";
                      context.read<WebViewProvider>().openBrowserPreference(
                            context: context,
                            url: url,
                            browserTapType: BrowserTapType.short,
                          );
                    },
                    onLongPress: () {
                      const String url = "https://developer.chrome.com/docs/multidevice/android/intents/";
                      context.read<WebViewProvider>().openBrowserPreference(
                            context: context,
                            url: url,
                            browserTapType: BrowserTapType.long,
                          );
                    },
                    child: const Text(
                      'official documentation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const TextSpan(
                  text: ".",
                ),
              ],
            ),
          );
        },
      ),
    );
    return tips;
  }

  List<TipTextBuilder> buildUserScriptsTipsList() {
    final tips = <TipTextBuilder>[];
    tips.add(
      ComplexExpandableTip(
        headerValue: "Userscripts development",
        buildExpandedText: () {
          return Text.rich(
            TextSpan(
              text: "You can use custom userscripts with Torn PDA. For more information, please visit the "
                  "userscripts section in Settings & Advanced Browser Settings.\n\n"
                  "As a general rule, Torn PDA supports standard Javascript and jQuery, but it does not include any "
                  "external libraries that are served in frameworks such as GM or TM. Therefore, if you are trying to "
                  "use a script that was developed for another platform or that won't work in your browser console, "
                  "you might need to adapt the code.\n\n"
                  "Make sure to read carefully the disclaimer, as it contains instructions and limitations in case "
                  "you would like to install new userscripts. In the disclaimer you will also find handy information "
                  "if you are an advanced programmer and would like to understand how to implement some complex "
                  "scenarios in your scripts that work with Torn PDA (including GET, POST, JS evaluation and some "
                  "Grease Monkey handlers).\n\n"
                  "There is a list of several userscripts examples at ",
              style: const TextStyle(
                fontSize: 13,
              ),
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      const url = 'https://github.com/Manuito83/torn-pda';
                      context.read<WebViewProvider>().openBrowserPreference(
                            context: context,
                            url: url,
                            browserTapType: BrowserTapType.short,
                          );
                    },
                    onLongPress: () {
                      const url = 'https://github.com/Manuito83/torn-pda';
                      context.read<WebViewProvider>().openBrowserPreference(
                            context: context,
                            url: url,
                            browserTapType: BrowserTapType.long,
                          );
                    },
                    child: const Text(
                      'our Github repository',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const TextSpan(
                  text: ".",
                ),
              ],
            ),
          );
        },
      ),
    );
    return tips;
  }
}
