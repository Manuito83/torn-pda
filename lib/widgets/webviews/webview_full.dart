// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
//import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:torn_pda/models/bounties/bounties_model.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
// Project imports:
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/jail/jail_model.dart';
import 'package:torn_pda/models/oc/ts_members_model.dart';
import 'package:torn_pda/models/oc/yata_members_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/pages/city/city_options.dart';
import 'package:torn_pda/pages/crimes/crimes_options.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:torn_pda/pages/trades/trades_options.dart';
import 'package:torn_pda/pages/vault/vault_options_page.dart';
import 'package:torn_pda/private/webview_config.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_models.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/bounties/bounties_widget.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/city/city_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/faction_crimes_widget.dart';
import 'package:torn_pda/widgets/gym/steadfast_widget.dart';
import 'package:torn_pda/widgets/jail/jail_widget.dart';
import 'package:torn_pda/widgets/profile_check/profile_check.dart';
import 'package:torn_pda/widgets/quick_items/quick_items_widget.dart';
import 'package:torn_pda/widgets/trades/trades_widget.dart';
import 'package:torn_pda/widgets/vault/vault_widget.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:torn_pda/widgets/webviews/tabs_hide_reminder.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torn_pda/utils/html_parser.dart' as pdaParser;

class HealingPages {
  String description;
  String url;

  HealingPages({this.description}) {
    switch (description) {
      case "Personal":
        url = 'https://www.torn.com/item.php#medical-items';
        break;
      case "Faction":
        url = 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical';
        break;
    }
  }
}

class VaultsOptions {
  String description;

  VaultsOptions({this.description}) {
    switch (description) {
      case "Personal vault":
        break;
      case "Faction vault":
        break;
      case "Company vault":
        break;
    }
  }
}

class WebViewFull extends StatefulWidget {
  final int windowId;
  final String customTitle;
  final String customUrl;
  //final bool dialog;
  final bool useTabs;
  final bool chatRemovalActive;
  final GlobalKey<WebViewFullState> key;

  // Chaining
  final bool isChainingBrowser;
  final ChainingPayload chainingPayload;

  const WebViewFull({
    this.windowId,
    this.customUrl = 'https://www.torn.com',
    this.customTitle = '',
    //this.dialog = false,
    this.useTabs = false,
    this.chatRemovalActive = false,
    this.key,

    // Chaining
    this.isChainingBrowser = false,
    this.chainingPayload,
  }) : super(key: key);

  @override
  WebViewFullState createState() => WebViewFullState();
}

class WebViewFullState extends State<WebViewFull> with WidgetsBindingObserver {
  // DEBUG SCRIPT INJECTION (logs)
  bool _debugScriptsInjection = false;

  InAppWebViewController webView;
  var _initialWebViewSettings = InAppWebViewSettings();

  //int _loadTimeMill = 0;

  CookieManager cm = CookieManager.instance();

  bool _firstLoad = true;

  URLRequest _initialUrl;
  String _pageTitle = "";
  String _currentUrl = '';

  bool _backButtonPopsContext = true;

  var _travelAbroad = false;
  var _travelHomeIconTriggered = false;

  var _crimesActive = false;
  final _crimesController = ExpandableController();

  Widget _gymExpandable = SizedBox.shrink();

  var _tradesFullActive = false;
  var _tradesIconActive = false;
  Widget _tradesExpandable = const SizedBox.shrink();
  bool _tradesPreferencesLoaded = false;
  bool _tradeCalculatorEnabled = false;
  DateTime _tradesOnResourceTriggerTime; // Null check afterwards (avoid false positives)

  DateTime _lastTradeCall = DateTime.now().subtract(const Duration(minutes: 1));
  // Sometimes the first call to trades will not detect that we are in, hence
  // travel icon won't show and [_decideIfCallTrades] won't trigger again. This
  // way we allow it to trigger again.
  bool _lastTradeCallWasIn = false;

  bool _vaultEnabled = false;
  bool _vaultPreferencesLoaded = false;
  bool _vaultIconActive = false;
  bool _vaultDetected = false;
  Widget _vaultExpandable = const SizedBox.shrink();
  DateTime _vaultTriggeredTime = DateTime.now().subtract(const Duration(minutes: 1));
  DateTime _vaultOnResourceTriggerTime; // Null check afterwards (avoid false positives)

  var _cityEnabled = false;
  var _cityIconActive = false;
  bool _cityPreferencesLoaded = false;
  var _errorCityApi = false;
  var _cityItemsFound = <Item>[];
  Widget _cityExpandable = const SizedBox.shrink();

  var _bazaarActiveOwn = false;
  var _bazaarFillActive = false;

  var _localChatRemovalActive = false;
  var _localChatRemoveActiveBeforeFullScreen = false;

  var _quickItemsActive = false;
  var _quickItemsFactionActive = false;
  final _quickItemsController = ExpandableController();
  final _quickItemsFactionController = ExpandableController();
  DateTime _quickItemsFactionOnResourceTriggerTime; // Null check afterwards (avoid false positives)

  // NNB is called from onPageVisit and onLoadStart, so API fetch and script activation have several checks
  DateTime _nnbTriggeredTime;
  DateTime _yataTriggeredTime;
  DateTime _tsTriggeredTime;
  final _ocNnbUrl = "factions.php?step=your#/tab=crimes";
  final _ocNnbController = ExpandableController();
  String _ocSource = "";

  Widget _jailExpandable = const SizedBox.shrink();
  DateTime _jailOnResourceTriggerTime; // Null check afterwards (avoid false positives)
  JailModel _jailModel;

  Widget _bountiesExpandable = const SizedBox.shrink();
  DateTime _bountiesOnResourceTriggerTime; // Null check afterwards (avoid false positives)
  BountiesModel _bountiesModel;

  DateTime _urlTriggerTime;

  // Allow onProgressChanged to call several sections, for better responsiveness,
  // while making sure that we don't call the API each time
  bool _crimesTriggered = false;
  bool _gymTriggered = false;
  bool _quickItemsTriggered = false;
  bool _quickItemsFactionTriggered = false; // Only in onLoadResource
  bool _cityTriggered = false;
  bool _tradesTriggered = false;
  bool _vaultTriggered = false;
  bool _ocNnbTriggered = false;

  Widget _profileAttackWidget = const SizedBox.shrink();
  var _lastProfileVisited = "";
  var _profileTriggered = false;
  var _attackTriggered = false;

  List<String> _lastAttackedTargets = <String>[];
  List<String> _lastAttackedMembers = <String>[];

  UserDetailsProvider _userProvider;
  UserController _u = Get.put(UserController());
  TerminalProvider _terminalProvider;

  WebViewProvider _webViewProvider;

  final _popupOptionsChoices = <VaultsOptions>[
    VaultsOptions(description: "Personal vault"),
    VaultsOptions(description: "Faction vault"),
    VaultsOptions(description: "Company vault"),
  ];

  bool _scrollAfterLoad = false;
  int _scrollY = 0;
  int _scrollX = 0;

  double _progress = 0;

  SettingsProvider _settingsProvider;
  UserScriptsProvider _userScriptsProvider;
  ThemeProvider _themeProvider;

  PullToRefreshController _pullToRefreshController;

  bool _findInPageActive = false;
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  var _findFirstSubmitted = false;
  var _findPreviousText = "";
  final _findInteractionController = FindInteractionController();

  bool _omitTabHistory = false;

  // Chaining configuration
  bool _isChainingBrowser = false;
  ChainingPayload _chainingPayload;
  final _chainingAidPopupChoices = <HealingPages>[
    HealingPages(description: "Personal"),
    HealingPages(description: "Faction"),
  ];
  final _chainWidgetController = ExpandableController();
  final _chainWidgetKey = GlobalKey();
  ChainStatusProvider _chainStatusProvider;
  TargetsProvider _targetsProvider;
  WarController _w;
  int _attackNumber = 0;
  String _factionName = "";
  int _lastOnline = 0;
  bool _nextButtonPressed = false;
  // Chaining configuration ends

  // Native Auth management
  NativeUserProvider _nativeUser;
  NativeAuthProvider _nativeAuth;

  // Time triggers for login error
  int _loginErrorRetrySeconds = 0;
  DateTime _loginErrorToastTimer;

  // Showcases
  GlobalKey _showCaseTitleBar = GlobalKey();
  GlobalKey _showCaseCloseButton = GlobalKey();
  GlobalKey _showCasePlayPauseChain = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WebView.debugLoggingSettings.enabled = false;

    _localChatRemovalActive = widget.chatRemovalActive;

    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    _nativeUser = context.read<NativeUserProvider>();
    _nativeAuth = context.read<NativeAuthProvider>();

    _initialUrl = URLRequest(url: WebUri(widget.customUrl));

    _isChainingBrowser = widget.isChainingBrowser;
    if (_isChainingBrowser) {
      _chainingPayload = widget.chainingPayload;
      _w = Get.put(WarController());
      String title = _chainingPayload.attackNameList[0];
      _pageTitle = title;
      // Decide if voluntarily skipping first target (always when it's a panic target)
      _assessFirstTargetsOnLaunch();
      _chainStatusProvider = context.read<ChainStatusProvider>();
      if (_chainStatusProvider.watcherActive) {
        _chainWidgetController.expanded = true;
      }
      _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
      if (_chainingPayload.war) {
        _lastAttackedMembers.clear();
        _lastAttackedMembers.add(_chainingPayload.attackIdList[0]);
      } else {
        _lastAttackedTargets.clear();
        _lastAttackedTargets.add(_chainingPayload.attackIdList[0]);
      }
    } else {
      _pageTitle = widget.customTitle;
    }

    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    _findController.addListener(onFindInputTextChange);

    _initialWebViewSettings = InAppWebViewSettings(
      cacheEnabled: false,
      transparentBackground: true,
      useOnLoadResource: true,
      useShouldOverrideUrlLoading: true,
      javaScriptCanOpenWindowsAutomatically: true,
      userAgent: Platform.isAndroid
          ? "Mozilla/5.0 (Linux; Android Torn PDA) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Version/4.0 Chrome/91.0.4472.114 Mobile Safari/537.36 ${WebviewConfig.agent}"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) "
              "CriOS/103.0.5060.54 Mobile/15E148 Safari/604.1 ${WebviewConfig.agent}",

      /// [useShouldInterceptAjaxRequest] This is deactivated sometimes as it interferes with
      /// hospital timer, company applications, etc. There is a bug on iOS if we activate it
      /// and deactivate it dynamically, where onLoadResource stops triggering!
      //useShouldInterceptAjaxRequest: false,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      cacheMode: CacheMode.LOAD_NO_CACHE,
      safeBrowsingEnabled: false,
      //useHybridComposition: true,
      supportMultipleWindows: true,
      initialScale: _settingsProvider.androidBrowserScale,
      useWideViewPort: false,
      allowsLinkPreview: _settingsProvider.iosAllowLinkPreview,
      disableLongPressContextMenuOnLinks: true,
      ignoresViewportScaleLimits: _settingsProvider.iosBrowserPinch,
      disallowOverScroll: _settingsProvider.iosDisallowOverscroll,
      overScrollMode: OverScrollMode.NEVER,
    );

    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.orange[800],
        size: PullToRefreshSize.DEFAULT,
        backgroundColor: _themeProvider.secondBackground,
        enabled: _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.icon || false,
        slingshotDistance: 300,
        distanceToTriggerSync: 300,
      ),
      onRefresh: () async {
        await _reload();
      },
    );
  }

  @override
  void dispose() {
    try {
      webView = null;
      _findController.dispose();
      _chainWidgetController.dispose();
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    } catch (e) {
      FirebaseCrashlytics.instance.log("PDA Crash at WebviewFull dispose");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", null);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isAndroid) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        webView?.pauseTimers();
      } else {
        webView?.resumeTimers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    _terminalProvider = Provider.of<TerminalProvider>(context);

    return ShowCaseWidget(
      builder: Builder(builder: (_) {
        if (_webViewProvider.browserShowInForeground) {
          launchShowCases(_);
        }
        return buildScaffold(context);
      }),
    );
  }

  // ! Ensure that any showcases here are also taken into account in the showcases in [webview_stackview.dart],
  // ! as the ones here need to fire first. Then only the others are allowed to fire.
  void launchShowCases(BuildContext _) {
    if (!_webViewProvider.browserShowInForeground) return;

    Future.delayed(Duration(seconds: 1), () async {
      List showCases = <GlobalKey<State<StatefulWidget>>>[];

      if (_webViewProvider.bottomBarStyleEnabled) {
        if (!_settingsProvider.showCases.contains("webview_closeButton")) {
          _settingsProvider.addShowCase = "webview_closeButton";
          showCases.add(_showCaseCloseButton);
        }
      } else {
        if (!_settingsProvider.showCases.contains("webview_titleBar")) {
          _settingsProvider.addShowCase = "webview_titleBar";
          showCases.add(_showCaseTitleBar);
        }
      }

      if (widget.isChainingBrowser &&
          _webViewProvider.currentTab == 0 &&
          !_settingsProvider.showCases.contains("webview_playPauseChain")) {
        _settingsProvider.addShowCase = "webview_playPauseChain";
        showCases.add(_showCasePlayPauseChain);
      }

      if (showCases.isNotEmpty) {
        ShowCaseWidget.of(_).startShowCase(showCases);
      }
    });
  }

  Widget buildScaffold(BuildContext context) {
    bool dialog = _webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2;

    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.of(context).orientation == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        top: !dialog && !(_settingsProvider.fullScreenOverNotch && _webViewProvider.currentUiMode == UiMode.fullScreen),
        bottom:
            !dialog && !(_settingsProvider.fullScreenOverBottom && _webViewProvider.currentUiMode == UiMode.fullScreen),
        left:
            !dialog && !(_settingsProvider.fullScreenOverSides && _webViewProvider.currentUiMode == UiMode.fullScreen),
        right:
            !dialog && !(_settingsProvider.fullScreenOverSides && _webViewProvider.currentUiMode == UiMode.fullScreen),
        child: Consumer<WebViewProvider>(
          builder: (context, wv, child) => Scaffold(
            resizeToAvoidBottomInset:
                // Dialog displaces the webview up by default
                !(_webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2),
            backgroundColor: _themeProvider.canvas,
            appBar: _webViewProvider.bottomBarStyleEnabled || wv.currentUiMode == UiMode.fullScreen
                // Show appBar only if we are not showing the webView in a dialog style
                ? null
                : _settingsProvider.appBarTop
                    ? buildCustomAppBar()
                    : null,
            bottomNavigationBar: _webViewProvider.bottomBarStyleEnabled
                ? null
                :
                // With appbar bottom, add appbar and some space for tabs
                !_settingsProvider.appBarTop && _webViewProvider.currentUiMode == UiMode.window
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: AppBar().preferredSize.height,
                            child: buildCustomAppBar(),
                          ),
                          SizedBox(
                            height: _webViewProvider.hideTabs || !_settingsProvider.useTabsFullBrowser ? 0 : 40,
                          ),
                        ],
                      )
                    :
                    // With appbar top, still add some space below for tabs
                    SizedBox(
                        height: _webViewProvider.hideTabs || !_settingsProvider.useTabsFullBrowser ? 0 : 40,
                      ),
            body: Container(
                // Background color for all browser widgets
                color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.grey[900],
                child: Column(
                  children: [
                    Expanded(child: mainWebViewColumn()),
                    SizedBox(
                      height: !_webViewProvider.bottomBarStyleEnabled
                          ? 0
                          : _webViewProvider.hideTabs || !_settingsProvider.useTabsFullBrowser
                              ? 0
                              : 40,
                    ),
                    if (_webViewProvider.currentUiMode == UiMode.window && _webViewProvider.bottomBarStyleEnabled)
                      _bottomBarStyleBottomBar(),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  Widget _bottomBarStyleBottomBar() {
    if (_findInPageActive) {
      return Container(
        color: _themeProvider.secondBackground,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                setState(() {
                  _findInPageActive = false;
                });
                _findController.text = "";
                _findInteractionController.clearMatches();
                _findFirstSubmitted = false;
              },
            ),
            Flexible(
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: TextField(
                              onEditingComplete: () {
                                _findPreviousText = _findController.text;
                                _findAll();
                                _findFocus.unfocus();
                              },
                              controller: _findController,
                              focusNode: _findFocus,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "What are you looking for?",
                                hintStyle: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                              style: TextStyle(
                                color: _themeProvider.mainText,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _findPreviousText = _findController.text;
                    _findAll();
                    _findFocus.unfocus();
                  },
                ),
                if (_findFirstSubmitted)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: () {
                          _findNext(forward: false);
                          _findFocus.unfocus();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: () {
                          _findNext(forward: true);
                          _findFocus.unfocus();
                        },
                      ),
                    ],
                  )
              ],
            )
          ],
        ),
      );
    }

    return Container(
      color: _themeProvider.currentTheme == AppTheme.light ? Colors.white : _themeProvider.secondBackground,
      height: 38,
      child: GestureDetector(
        onLongPress: () => openUrlDialog(),
        onPanEnd: _settingsProvider.useTabsHideFeature && _settingsProvider.useTabsFullBrowser
            ? (DragEndDetails details) async {
                _webViewProvider.toggleHideTabs();
                if (await Prefs().getReminderAboutHideTabFeature() == false) {
                  Prefs().setReminderAboutHideTabFeature(true);
                  return showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const TabsHideReminderDialog();
                    },
                  );
                }
              }
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      splashColor: Colors.blueGrey,
                      child: const SizedBox(
                        width: 35,
                        child: Icon(
                          Icons.arrow_back_ios_outlined,
                          size: 20,
                        ),
                      ),
                      onTap: () async {
                        _tryGoBack();
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      splashColor: Colors.blueGrey,
                      child: const SizedBox(
                        width: 35,
                        child: Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 20,
                        ),
                      ),
                      onTap: () async {
                        _tryGoForward();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Showcase(
                  key: _showCaseCloseButton,
                  title: 'Options menu',
                  description: '\nLong press the bottom bar of the quick browser to open a '
                      'menu with additional options, including faction attack assists calls!\n\n'
                      'Swipe down/up to hide or show your tab bar!',
                  targetPadding: const EdgeInsets.only(top: 8),
                  disableMovingAnimation: true,
                  textColor: _themeProvider.mainText,
                  tooltipBackgroundColor: _themeProvider.secondBackground,
                  descTextStyle: TextStyle(fontSize: 13),
                  tooltipPadding: EdgeInsets.all(20),
                  child: GestureDetector(
                    child: Container(
                      color: Colors.transparent, // Background to extend the buttons detection area
                      child: Column(
                        children: [
                          Text(
                            "CLOSE",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _themeProvider.mainText,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(
                            width: 15,
                            child: Divider(
                              height: 3,
                              thickness: 1,
                              color: _themeProvider.mainText,
                            ),
                          ),
                          if ((_currentUrl.contains("www.torn.com/loader.php?sid=attack&user2ID=") ||
                                  _currentUrl.contains("www.torn.com/loader2.php?sid=getInAttack&user2ID=")) &&
                              _userProvider.basic?.faction?.factionId != 0)
                            Text(
                              "ASSIST",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 7,
                              ),
                            )
                          else
                            Text(
                              "OPTIONS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _themeProvider.mainText,
                                fontSize: 7,
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      _webViewProvider.browserShowInForeground = false;
                      _checkIfTargetsAttackedAndRevertChaining();
                    },
                  ),
                ),
              ),
            ),
            _isChainingBrowser
                ? Row(children: _chainingActionButtons())
                : SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _travelHomeIcon(),
                        _crimesMenuIcon(),
                        _cityMenuIcon(),
                        _quickItemsMenuIcon(),
                        _vaultsPopUpIcon(),
                        _tradesMenuIcon(),
                        _bazaarFillIcon(),
                        _vaultOptionsIcon(),
                        if (_webViewProvider.chatRemovalEnabledGlobal) _hideChatIcon() else const SizedBox.shrink(),
                        _reloadIcon(),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Column mainWebViewColumn() {
    return Column(
      children: [
        if (_settingsProvider.loadBarBrowser)
          SizedBox(
            height: 2,
            child: _progress < 1.0
                ? LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.blueGrey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange[300]),
                  )
                : Container(height: 2),
          )
        else
          const SizedBox.shrink(),
        // ### WIDGETS

        // Profile attack
        Visibility(
          visible: !_fullScreenAndWidgetHide(),
          child: Column(
            children: [
              _profileAttackWidget,
              if (_isChainingBrowser)
                ExpandablePanel(
                  theme: ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: SizedBox.shrink(),
                  controller: _chainWidgetController,
                  header: SizedBox.shrink(),
                  expanded: ChainWidget(
                    key: _chainWidgetKey,
                    alwaysDarkBackground: true,
                  ),
                ),
              // Crimes widget. NOTE: this one will open at the bottom if
              // appBar is at the bottom, so it's duplicated below the actual
              // webView widget
              if (_settingsProvider.appBarTop)
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: const SizedBox.shrink(),
                  controller: _crimesController,
                  header: const SizedBox.shrink(),
                  expanded: _crimesActive
                      ? CrimesWidget(
                          controller: webView,
                        )
                      : const SizedBox.shrink(),
                )
              else
                const SizedBox.shrink(),
              ExpandablePanel(
                theme: const ExpandableThemeData(
                  hasIcon: false,
                  tapBodyToCollapse: false,
                  tapHeaderToExpand: false,
                ),
                collapsed: const SizedBox.shrink(),
                controller: _ocNnbController,
                header: const SizedBox.shrink(),
                expanded: _ocNnbTriggered
                    ? FactionCrimesWidget(
                        source: _ocSource,
                      )
                    : const SizedBox.shrink(),
              ),
              // Quick items widget. NOTE: this one will open at the bottom if
              // appBar is at the bottom, so it's duplicated below the actual
              // webView widget
              if (_settingsProvider.appBarTop)
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: const SizedBox.shrink(),
                  controller: _quickItemsController,
                  header: const SizedBox.shrink(),
                  expanded: _quickItemsActive
                      ? QuickItemsWidget(
                          inAppWebViewController: webView,
                          faction: false,
                        )
                      : const SizedBox.shrink(),
                )
              else
                const SizedBox.shrink(),
              if (_settingsProvider.appBarTop)
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: const SizedBox.shrink(),
                  controller: _quickItemsFactionController,
                  header: const SizedBox.shrink(),
                  expanded: _quickItemsFactionActive
                      ? QuickItemsWidget(
                          inAppWebViewController: webView,
                          faction: true,
                        )
                      : const SizedBox.shrink(),
                )
              else
                const SizedBox.shrink(),
              // Gym widget
              _gymExpandable,
              // Trades widget
              _tradesExpandable,
              // Vault widget
              _vaultExpandable,
              // City widget
              _cityExpandable,
              // Jail widget
              _jailExpandable,
              // Bounties widget
              _bountiesExpandable,
            ],
          ),
        ),

        // ### ACTUAL WEBVIEW
        Expanded(child: _mainWebViewStack()),

        // ### Widgets that go at the bottom if we have changes appbar to bottom
        Visibility(
          visible: !_fullScreenAndWidgetHide(),
          child: Column(
            children: [
              if (!_settingsProvider.appBarTop)
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: const SizedBox.shrink(),
                  controller: _crimesController,
                  header: const SizedBox.shrink(),
                  expanded: _crimesActive
                      ? CrimesWidget(
                          controller: webView,
                        )
                      : const SizedBox.shrink(),
                )
              else
                const SizedBox.shrink(),
              if (!_settingsProvider.appBarTop)
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: const SizedBox.shrink(),
                  controller: _quickItemsController,
                  header: const SizedBox.shrink(),
                  expanded: _quickItemsActive
                      ? QuickItemsWidget(
                          inAppWebViewController: webView,
                          faction: false,
                        )
                      : const SizedBox.shrink(),
                )
              else
                const SizedBox.shrink(),
              if (!_settingsProvider.appBarTop)
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: const SizedBox.shrink(),
                  controller: _quickItemsFactionController,
                  header: const SizedBox.shrink(),
                  expanded: _quickItemsFactionActive
                      ? QuickItemsWidget(
                          inAppWebViewController: webView,
                          faction: true,
                        )
                      : const SizedBox.shrink(),
                )
              else
                const SizedBox.shrink(),
              // Terminal
              Consumer<SettingsProvider>(
                builder: (_, value, __) {
                  if (value.terminalEnabled) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.green[900]),
                      ),
                      height: 100,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _terminalProvider.terminal,
                                  style: const TextStyle(color: Colors.green, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Stack _mainWebViewStack() {
    return Stack(
      children: [
        InAppWebView(
          windowId: widget.windowId,
          initialUrlRequest: _initialUrl,
          pullToRefreshController: _pullToRefreshController,
          findInteractionController: _findInteractionController,
          initialSettings: _initialWebViewSettings,
          // EVENTS
          onWebViewCreated: (c) async {
            webView = c;
            _terminalProvider.terminal = "Terminal";

            // Userscripts initial load
            if (Platform.isAndroid || (Platform.isIOS && widget.windowId == null)) {
              UnmodifiableListView<UserScript> handlersScriptsToAdd = _userScriptsProvider.getHandlerSources(
                apiKey: _userProvider?.basic?.userApiKey ?? "",
              );
              await webView.addUserScripts(userScripts: handlersScriptsToAdd);

              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: _initialUrl.url.toString(),
                apiKey: _userProvider?.basic?.userApiKey ?? "",
                time: UserScriptTime.start,
              );
              await webView.addUserScripts(userScripts: scriptsToAdd);
            } else if (Platform.isIOS && widget.windowId != null) {
              _terminalProvider.addInstruction(
                  "TORN PDA NOTE: iOS does not support user scripts injection in new windows (like this one), but only in "
                  "full webviews. If you are trying to run a script, close this tab and open a new one from scratch.");
            }

            // Copy to clipboard from the log doesn't work so we use a handler from JS fired from Torn
            webView.addJavaScriptHandler(
              handlerName: 'copyToClipboard',
              callback: (args) {
                String copy = args.toString();
                if (copy.startsWith("[")) {
                  copy = copy.replaceFirst("[", "");
                  copy = copy.substring(0, copy.length - 1);
                }
                Clipboard.setData(ClipboardData(text: copy));
              },
            );

            // Theme change received from web
            webView.addJavaScriptHandler(
              handlerName: 'webThemeChange',
              callback: (args) {
                if (!_settingsProvider.syncTheme) return;
                if (args.contains("dark")) {
                  // Only change to dark themes if we are currently in light (the web will respond with a
                  // theme change event when we initiate the change, and it could revert to the default dark)
                  if (_themeProvider.currentTheme == AppTheme.light) {
                    if (_settingsProvider.darkThemeToSyncFromWeb == "dark") {
                      _themeProvider.changeTheme = AppTheme.dark;
                      log("Web theme changed to dark!");
                    } else {
                      _themeProvider.changeTheme = AppTheme.extraDark;
                      log("Web theme changed to extra dark!");
                    }
                  }
                } else if (args.contains("light")) {
                  _themeProvider.changeTheme = AppTheme.light;
                  log("Web theme changed to light!");
                }

                setState(() {
                  SystemChrome.setSystemUIOverlayStyle(
                    SystemUiOverlayStyle(
                      statusBarColor: _themeProvider.statusBar,
                      systemNavigationBarColor: MediaQuery.of(context).orientation == Orientation.landscape
                          ? _themeProvider.canvas
                          : _themeProvider.statusBar,
                      systemNavigationBarIconBrightness: MediaQuery.of(context).orientation == Orientation.landscape
                          ? _themeProvider.currentTheme == AppTheme.light
                              ? Brightness.dark
                              : Brightness.light
                          : Brightness.light,
                      statusBarBrightness: _themeProvider.currentTheme == AppTheme.light
                          ? MediaQuery.of(context).orientation == Orientation.portrait
                              ? Brightness.dark
                              : Brightness.light
                          : Brightness.dark,
                      statusBarIconBrightness: MediaQuery.of(context).orientation == Orientation.portrait
                          ? Brightness.light
                          : Brightness.light,
                    ),
                  );
                });
              },
            );

            _addLoadoutChangeHandler(webView);

            _addScriptApiHandlers(webView);
          },
          shouldOverrideUrlLoading: (c, request) async {
            if (Platform.isAndroid || (Platform.isIOS && widget.windowId == null)) {
              // Userscripts load before webpage begins loading
              UnmodifiableListView<UserScript> handlersScriptsToAdd = _userScriptsProvider.getHandlerSources(
                apiKey: _userProvider?.basic?.userApiKey ?? "",
              );
              await webView.addUserScripts(userScripts: handlersScriptsToAdd);

              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: request.request.url.toString(),
                apiKey: _userProvider?.basic?.userApiKey ?? "",
                time: UserScriptTime.start,
              );
              await webView.addUserScripts(userScripts: scriptsToAdd);

              // DEBUG
              if (_debugScriptsInjection) {
                var addList = [];
                for (var s in scriptsToAdd) {
                  addList.add(s.groupName);
                }
                log("Added normal scripts in shouldOverride: $addList");
                log("Added handlers scripts in shouldOverride: $handlersScriptsToAdd");
              }
            }

            if (request.request.url.toString().contains("http://")) {
              _loadUrl(request.request.url.toString().replaceAll("http:", "https:"));
              return NavigationActionPolicy.CANCEL;
            }

            return NavigationActionPolicy.ALLOW;
          },
          onCreateWindow: (c, request) async {
            if (!mounted) return true;
            // If we are not using tabs in the current browser, just load the URL (otherwise, if we try
            // to open a window, a new tab is created but we can't see it and looks like a glitch)
            if (!_settingsProvider.useTabsFullBrowser) {
              String url = request.request.url.toString().replaceAll("http:", "https:");
              _loadUrl(url);
            } else {
              // If we are using tabs, add a tab
              String url = request.request.url.toString().replaceAll("http:", "https:");
              _webViewProvider.addTab(url: url, windowId: request.windowId);
              _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
            }
            return true;
          },
          onCloseWindow: (controller) async {
            await Future.delayed(Duration(seconds: 2));
            _webViewProvider.removeTab(calledFromTab: true);
          },
          onLoadStart: (c, uri) async {
            log("Start URL: ${uri}");
            //_loadTimeMill = DateTime.now().millisecondsSinceEpoch;

            _webViewProvider.verticalMenuClose();
            if (!mounted) return;

            if (Platform.isAndroid) {
              _revertTransparentBackground();
            }

            try {
              _currentUrl = uri.toString();

              final html = await webView.getHtml();

              hideChatOnLoad();

              final document = parse(html);
              _assessGeneral(document);
            } catch (e) {
              // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
              // the checks performed in this method
            }
          },
          onProgressChanged: (c, progress) async {
            if (!mounted) return;

            try {
              if (_settingsProvider.removeAirplane) {
                webView.evaluateJavascript(source: travelRemovePlaneJS());
              }

              hideChatOnLoad();

              if (mounted) {
                setState(() {
                  this._progress = progress / 100;
                });
              }

              if (progress > 75) {
                _pullToRefreshController.endRefreshing();

                // onProgressChanged gets called before onLoadStart, so it works
                // both to add or remove widgets. It is much faster.
                _assessSectionsWithWidgets();
                // We reset here the triggers for the sections that are called every
                // time so that they can be called again
                _resetSectionsWithWidgets();
              }
            } catch (e) {
              // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
              // the checks performed in this method
            }
          },
          onLoadStop: (c, uri) async {
            if (!mounted) return;

            // Ensure that transparent background is set to false after first load
            // In iOS we do it after load stop, otherwise a white flash is trigger in any case
            if (Platform.isIOS) {
              _revertTransparentBackground();
            }

            try {
              _currentUrl = uri.toString();

              // Userscripts remove those no longer necessary
              List<String> scriptsToRemove = _userScriptsProvider.getScriptsToRemove(
                url: uri.toString(),
              );
              if (Platform.isAndroid || (Platform.isIOS && widget.windowId == null)) {
                for (var group in scriptsToRemove) {
                  await c.removeUserScriptsByGroupName(groupName: group);
                }
              }

              // DEBUG
              if (_debugScriptsInjection) {
                log("Removed scripts in loadStop: $scriptsToRemove");
              }

              // Userscripts add those that inject at the end
              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: uri.toString(),
                apiKey: _userProvider?.basic?.userApiKey ?? "",
                time: UserScriptTime.end,
              );
              // We need to inject directly, otherwise these scripts will only load in the next page visit
              for (var script in scriptsToAdd) {
                await webView.evaluateJavascript(
                  source: _userScriptsProvider.adaptSource(script.source, _userProvider?.basic?.userApiKey ?? ""),
                );
              }

              // DEBUG
              if (_debugScriptsInjection) {
                var addList = [];
                for (var s in scriptsToAdd) {
                  addList.add(s.groupName);
                }
                log("Added scripts in shouldOverride: $addList");
              }

              hideChatOnLoad();
              _highlightChat();

              // If we are using pull-to-refresh in a short page (that does not scroll), add a bit of body
              // height so that the pull-to-refresh triggers properly
              if (_settingsProvider.browserRefreshMethod != BrowserRefreshSetting.icon) {
                _addExtraHeightForPullToRefresh();
              }

              final html = await webView.getHtml();
              final document = parse(html);

              // Force to show title
              if (!_isChainingBrowser) {
                _pageTitle = await _getPageTitle(document, showTitle: true);
              }

              if (widget.useTabs) {
                // Report title will only be used from onLoadStop, since onResourceLoad might trigger
                // it too early (before it has changed)
                _reportPageTitle();
              }
              _assessGeneral(document);

              // This is used in case the user presses reload. We need to wait for the page
              // load to be finished in order to scroll
              if (_scrollAfterLoad) {
                webView.scrollTo(x: _scrollX, y: _scrollY, animated: false);
                _scrollAfterLoad = false;
              }

              if (_settingsProvider.restoreSessionCookie) {
                if (_currentUrl.contains("torn.com")) {
                  Cookie session = await cm.getCookie(url: WebUri("https://www.torn.com"), name: "PHPSESSID");
                  if (session != null) {
                    Prefs().setWebViewSessionCookie(session.value);
                  }
                }
              }

              if (_webViewProvider.pendingThemeSync.isNotEmpty && _settingsProvider.syncTheme) {
                if (_currentUrl.contains("www.torn.com")) {
                  if (_webViewProvider.pendingThemeSync == "light") {
                    _requestTornThemeChange(dark: false);
                  } else {
                    _requestTornThemeChange(dark: true);
                  }
                  _webViewProvider.pendingThemeSync = "";
                }
              }

              assessErrorCases(document: document);
            } catch (e) {
              // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
              // the checks performed in this method
            }

            //log("Stop @ ${DateTime.now().millisecondsSinceEpoch - _loadTimeMill} ms");
          },
          onUpdateVisitedHistory: (c, uri, androidReload) async {
            if (!mounted) return;
            _reportUrlVisit(uri);
            _assessOCnnb(uri.toString()); // Using a more direct call for OCnnb
            return;
          },
          onLoadResource: (c, resource) async {
            if (!mounted) return;

            try {
              /// TRADES
              /// We are calling trades from here because onLoadStop does not
              /// work inside of Trades for iOS. Also, both in Android and iOS
              /// we need to catch deletions.
              // Two possible scenarios.
              // 1. Upon first call, "trade.php" might not always be in the resource. To avoid this,
              //    we check for url once, limiting it to TradesTriggered
              // 2. For the rest of the cases (updates, additions), we use the resource
              if (resource.url.toString().contains("trade.php") ||
                  (_currentUrl.contains("trade.php") && !_tradesTriggered)) {
                // We only allow this to trigger once, otherwise it wants to load dozens of times and causes
                // the webView to freeze for a bit
                if (_tradesOnResourceTriggerTime != null &&
                    DateTime.now().difference(_tradesOnResourceTriggerTime).inSeconds < 2) return;
                _tradesOnResourceTriggerTime = DateTime.now();

                _tradesTriggered = true;
                final html = await webView.getHtml();
                final document = parse(html);
                final pageTitle = (await _getPageTitle(document)).toLowerCase();
                if (Platform.isIOS) {
                  // iOS needs this check because the full trade URL won't trigger in onLoadStop
                  _currentUrl = (await webView.getUrl()).toString();
                }
                _assessTrades(document, pageTitle);
              }

              // Properties (vault) for initialization and live transactions
              if (resource.url.toString().contains("properties.php") ||
                  (_currentUrl.contains("properties.php") && !_vaultTriggered)) {
                // We only allow this to trigger once, otherwise it wants to load dozens of times and causes
                // the webView to freeze for a bit
                if (_vaultOnResourceTriggerTime != null &&
                    DateTime.now().difference(_vaultOnResourceTriggerTime).inSeconds < 2) return;
                _vaultOnResourceTriggerTime = DateTime.now();

                if (!_vaultTriggered) {
                  final html = await webView.getHtml();
                  final document = parse(html);
                  final pageTitle = (await _getPageTitle(document)).toLowerCase();
                  _assessVault(doc: document, pageTitle: pageTitle);
                } else {
                  // If it's triggered, it's because we are inside and we performed an operation
                  // (deposit or withdrawal). In this case, we need to give a couple of seconds
                  // so that the new html elements appear and we can analyze them
                  Future.delayed(const Duration(seconds: 2)).then((value) async {
                    // Reset _vaultTriggered so that we can call _assessVault() again
                    _reassessVault();
                  });
                }
              }

              // Jail for initialization and live transactions
              if (resource.url.toString().contains("jailview.php")) {
                // Trigger once
                if (_jailOnResourceTriggerTime != null &&
                    DateTime.now().difference(_jailOnResourceTriggerTime).inMilliseconds < 500) {
                  return;
                }
                _jailOnResourceTriggerTime = DateTime.now();

                // iOS needs URL report in jail pages
                if (Platform.isIOS) {
                  var uri = (await webView.getUrl());
                  _reportUrlVisit(uri);
                }

                final html = await webView.getHtml();
                dom.Document document = parse(html);

                List<dom.Element> query;
                for (var i = 0; i < 2; i++) {
                  if (!mounted) break;
                  query = document.querySelectorAll(".users-list > li");
                  if (query.isNotEmpty) {
                    break;
                  } else {
                    await Future.delayed(const Duration(seconds: 1));
                    if (!mounted) break;
                    final updatedHtml = await webView.getHtml();
                    document = parse(updatedHtml);
                  }
                }
                if (query.isNotEmpty) {
                  _assessJail(document);
                }
              }

              // Bounties for initialization and live transactions
              if (resource.url.toString().contains("bounties.php")) {
                // Trigger once
                if (_bountiesOnResourceTriggerTime != null &&
                    DateTime.now().difference(_bountiesOnResourceTriggerTime).inMilliseconds < 500) {
                  return;
                }
                _bountiesOnResourceTriggerTime = DateTime.now();

                // iOS needs URL report in jail pages
                if (Platform.isIOS) {
                  var uri = (await webView.getUrl());
                  _reportUrlVisit(uri);
                }

                final html = await webView.getHtml();
                dom.Document document = parse(html);

                List<dom.Element> query;
                for (var i = 0; i < 2; i++) {
                  if (!mounted) break;
                  query = document.querySelectorAll(".bounties-list > li");
                  if (query.isNotEmpty) {
                    break;
                  } else {
                    await Future.delayed(const Duration(seconds: 1));
                    if (!mounted) break;
                    final updatedHtml = await webView.getHtml();
                    document = parse(updatedHtml);
                  }
                }
                if (query.isNotEmpty) {
                  _assessBounties(document);
                }
              }

              // Quick items armoury tab (faction)
              if (resource.initiatorType == "xmlhttprequest" && resource.url.toString().contains("factions.php") ||
                  (!resource.url.toString().contains("factions.php") && _quickItemsFactionTriggered)) {
                // We only allow this to trigger once, otherwise it wants to load dozens of times and causes
                // the webView to freeze for a bit
                if (_quickItemsFactionOnResourceTriggerTime != null &&
                    DateTime.now().difference(_quickItemsFactionOnResourceTriggerTime).inSeconds < 1) {
                  return;
                }

                _quickItemsFactionOnResourceTriggerTime = DateTime.now();

                // We are not reporting the URL if we change tabs
                // (it does not work on desktop either)
                var uri = (await webView.getUrl());
                _currentUrl = uri.toString();

                if (_currentUrl.contains('tab=armoury') && !_quickItemsFactionTriggered) {
                  _assessFactionQuickItems();
                } else if (!_currentUrl.contains('tab=armoury') && _quickItemsFactionTriggered) {
                  _assessFactionQuickItems(deactivate: true);
                }
              }
            } catch (e) {
              // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
              // the checks performed in this method
            }

            return;
          },
          onConsoleMessage: (controller, consoleMessage) async {
            if (consoleMessage.message != "") {
              if (!consoleMessage.message.contains("Refused to connect to ") &&
                  !consoleMessage.message.contains("Uncaught (in promise) TypeError") &&
                  !consoleMessage.message.contains("Blocked a frame with origin") &&
                  !consoleMessage.message.contains("Error with Permissions-Policy header")) {
                _terminalProvider.addInstruction(consoleMessage.message);
                log("TORN PDA CONSOLE: ${consoleMessage.message}");
              }
            }
          },
          onLongPressHitTestResult: (controller, result) async {
            if (result.extra == null) return;

            bool notCurrentUrl = result.extra.replaceAll("#", "") != _currentUrl;
            bool isAnchorType = result.type == InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE;
            bool isImageAnchorType = result.type == InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE;
            bool notProfileLink = !result.extra.contains("https://www.torn.com/profiles.php?XID=");
            bool notAwardImage = !result.extra.contains("awardimages");

            if (notCurrentUrl && ((isAnchorType && notProfileLink) || (isImageAnchorType && notAwardImage))) {
              var focus = await controller.requestFocusNodeHref();
              if (focus.url != null) {
                _showLongPressCard(focus.src, focus.url);
              }
            }
          },
          /*
            shouldInterceptAjaxRequest: (InAppWebViewController c, AjaxRequest x) async {
              // MAIN AJAX REQUEST RETURN
              return x;
            },
          */
        ),
        // Container that covers Torn's top bar to serve as a gesture detector
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (_) async {
            // Pull to refresh for short pages (since v3.1.0 we also add an extra height to short pages via scripts)
            if (_settingsProvider.browserRefreshMethod != BrowserRefreshSetting.icon) {
              await _reload();
              _pullToRefreshController.beginRefreshing();
            }
          },
          onDoubleTap: () {
            // Return to windowed mode
            if (_webViewProvider.currentUiMode == UiMode.fullScreen) {
              _webViewProvider.verticalMenuClose();
              _webViewProvider.setCurrentUiMode(UiMode.window, context);
              if (_settingsProvider.fullScreenRemovesChat) {
                _webViewProvider.showAllChatsFullScreen();
              }
            }
          },
          child: Container(
            height: 32,
          ),
        ),
      ],
    );
  }

  void _addScriptApiHandlers(InAppWebViewController webView) {
    // API HANDLERS
    webView.addJavaScriptHandler(
      handlerName: 'PDA_httpGet',
      callback: (args) async {
        http.Response resp = await http.get(WebUri(args[0]));
        return _makeScriptApiResponse(resp);
      },
    );

    webView.addJavaScriptHandler(
      handlerName: 'PDA_httpPost',
      callback: (args) async {
        Object body = args[2];
        if (body is Map<String, dynamic>) {
          body = Map<String, String>.from(body);
        }
        http.Response resp = await http.post(WebUri(args[0]), headers: Map<String, String>.from(args[1]), body: body);
        return _makeScriptApiResponse(resp);
      },
    );

    // JS HANDLER
    webView.addJavaScriptHandler(
      handlerName: 'PDA_evaluateJavascript',
      callback: (args) async {
        webView.evaluateJavascript(source: args[0]);
        return;
      },
    );
  }

  _addExtraHeightForPullToRefresh() {
    webView.evaluateJavascript(source: addHeightForPullToRefresh());
  }

  void _addLoadoutChangeHandler(InAppWebViewController webView) {
    webView.addJavaScriptHandler(
      handlerName: 'loadoutChangeHandler',
      callback: (args) async {
        if (args.isNotEmpty) {
          String message = args[0];
          if (message.contains("equippedSet")) {
            final regex = RegExp(r'"equippedSet":(\d)');
            final match = regex.firstMatch(message);
            final loadout = match.group(1);
            _reload();
            BotToast.showText(
              text: "Loadout $loadout activated!",
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue[600],
              duration: Duration(seconds: 1),
              contentPadding: EdgeInsets.all(10),
            );
            return;
          }
        }

        BotToast.showText(
          text: "There was a problem activating the loadout, are you already using it?",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.red[600],
          duration: Duration(seconds: 2),
          contentPadding: EdgeInsets.all(10),
        );
      },
    );
  }

  Map<String, dynamic> _makeScriptApiResponse(http.Response resp) {
    // Create a return value that mimics GM_xmlHttpRequest()
    return {
      'status': resp.statusCode,
      'statusText': resp.reasonPhrase,
      'responseText': resp.body,
      'responseHeaders': resp.headers.keys.map((key) => '${key}: ${resp.headers[key]}').join("\r\n")
    };
  }

  void removeAllUserScripts() async {
    await webView.removeAllUserScripts();
  }

  Future assessErrorCases({dom.Document document}) async {
    if (!_nativeUser.isNativeUserEnabled()) {
      return;
    }

    if (document == null) {
      final html = await webView?.getHtml();
      if (html == null || html.isEmpty) return;
      document = parse(html);
    }

    // If for some reason we are logged out of Torn, try to login again
    if (document.body.innerHtml.contains("Email address or password incorrect") ||
        document.body.innerHtml.contains("multiple failures from your IP address")) {
      BotToast.showText(
        clickClose: true,
        text: "Authentication error detected!\n\nIf you have inserted your username and password combination in Torn "
            "PDA's settings section, please verify that they are correct!",
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red,
        duration: Duration(seconds: 6),
        contentPadding: EdgeInsets.all(10),
      );
      return;
    }

    // If for some reason we are logged out of Torn, try to login again
    if (_nativeAuth.tryAutomaticLogins && document.querySelectorAll("[class*='logInWrap_']").isNotEmpty) {
      if (_loginErrorToastTimer == null || DateTime.now().difference(_loginErrorToastTimer).inSeconds > 4) {
        if (_webViewProvider.browserShowInForeground) {
          BotToast.showText(
            text: "Trying to log back into Torn\n\n"
                "Please wait...!",
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.blue,
            duration: Duration(seconds: 4),
            contentPadding: EdgeInsets.all(10),
          );
        }
      }
      _loginErrorToastTimer = DateTime.now();

      // New attempts will be made in a row if unsuccessful, so make them wait longer
      // (this is the result of Torn going to an error page at first sometimes)
      _loginErrorRetrySeconds++;
      await Future.delayed(Duration(seconds: _loginErrorRetrySeconds));

      final newDoc = parse(await webView.getHtml());
      if (newDoc.querySelectorAll("[class*='logInWrap_']").isEmpty ||
          newDoc.body.innerHtml.contains("failures from your IP address")) return;

      TornLoginResponseContainer loginResponse = await _nativeAuth.requestTornRecurrentInitData(
        context: context,
        loginData: GetInitDataModel(
          playerId: _userProvider.basic.playerId,
          sToken: _nativeUser.playerSToken,
        ),
      );

      if (loginResponse.success) {
        webView.loadUrl(urlRequest: URLRequest(url: WebUri(loginResponse.authUrl)));
        await Future.delayed(const Duration(seconds: 4));
        _loginErrorRetrySeconds = 0;
      } else {
        BotToast.showText(
          text: "Browser error while authenticating: please log in again or verify your user / pass combination "
              "in the Settings section!",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.red,
          duration: Duration(seconds: 4),
          contentPadding: EdgeInsets.all(10),
        );
      }
    }
  }

  void _reportUrlVisit(Uri uri) {
    // This avoids reporting url such as "https://www.torn.com/imarket.php#/0.5912994041327981", which are generated
    // when returning from a bazaar and go straight to the market, not allowing to return to the item search
    if (uri.toString().contains("imarket.php#/")) {
      RegExp expHtml = RegExp(r"imarket\.php#\/[0-9||.]+$");
      var matches = expHtml.allMatches(uri.toString()).map((m) => m[0]);
      if (matches.length > 0) {
        return;
      }
    }

    // For certain URLs (e.g. forums in iOS) we might be reporting this twice. Once from onLoadStop and again
    // from onResourceLoad. The check in the provider (for onLoadStop triggering several times) is not enough
    // to prevent adding extra pages to history (when it's the first page loading, it's only omitted once).
    if (_urlTriggerTime != null && (DateTime.now().difference(_urlTriggerTime).inSeconds) < 1) {
      return;
    }
    _urlTriggerTime = DateTime.now();
    //log(uri.toString());

    if (!_omitTabHistory) {
      // Note: cannot be used in OnLoadStart because it won't trigger for certain pages (e.g. forums)
      _webViewProvider.reportTabLoadUrl(widget.key, uri.toString());
    } else {
      _omitTabHistory = false;
    }
  }

  void _reportPageTitle() {
    _webViewProvider.reportTabPageTitle(widget.key, _pageTitle);
  }

  void _highlightChat() {
    if (!_currentUrl.contains('torn.com')) return;

    final intColor = Color(_settingsProvider.highlightColor);
    final background = 'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, ${intColor.opacity})';
    final senderColor = 'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, 1)';
    final String hlMap =
        '[ { name: "${_userProvider.basic.name}", highlight: "$background", sender: "$senderColor" } ]';

    if (_settingsProvider.highlightChat) {
      webView.evaluateJavascript(
        source: chatHighlightJS(highlightMap: hlMap),
      );
    }
  }

  void hideChatOnLoad() {
    if ((_webViewProvider.chatRemovalEnabledGlobal && _localChatRemovalActive) ||
        _webViewProvider.chatRemovalWhileFullScreen) {
      webView.evaluateJavascript(source: removeChatOnLoadStartJS());
    }
  }

  void hideChatWhileFullScreen() {
    _localChatRemoveActiveBeforeFullScreen = _localChatRemovalActive;
    webView.evaluateJavascript(source: removeChatJS());
  }

  void showChatAfterFullScreen() {
    _localChatRemovalActive = _localChatRemoveActiveBeforeFullScreen;
    if (!_localChatRemovalActive) {
      webView.evaluateJavascript(source: restoreChatJS());
    }
  }

  CustomAppBar buildCustomAppBar() {
    if (_findInPageActive) {
      return CustomAppBar(
        genericAppBar: AppBar(
          elevation: _settingsProvider.appBarTop ? 2 : 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              setState(() {
                _findInPageActive = false;
              });
              _findController.text = "";
              _findInteractionController.clearMatches();
              _findFirstSubmitted = false;
            },
          ),
          title: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: TextField(
                          onEditingComplete: () {
                            _findPreviousText = _findController.text;
                            _findAll();
                            _findFocus.unfocus();
                          },
                          controller: _findController,
                          focusNode: _findFocus,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "What are you looking for?",
                            hintStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[300], fontSize: 12),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: _isChainingBrowser
              ? _chainingActionButtons()
              : <Widget>[
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _findPreviousText = _findController.text;
                      _findAll();
                      _findFocus.unfocus();
                    },
                  ),
                  if (_findFirstSubmitted)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up),
                          onPressed: () {
                            _findNext(forward: false);
                            _findFocus.unfocus();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onPressed: () {
                            _findNext(forward: true);
                            _findFocus.unfocus();
                          },
                        ),
                      ],
                    )
                ],
        ),
      );
    }

    bool assistPossible = (_currentUrl.contains("www.torn.com/loader.php?sid=attack&user2ID=") ||
            _currentUrl.contains("www.torn.com/loader2.php?sid=getInAttack&user2ID=")) &&
        _userProvider.basic?.faction?.factionId != 0;

    return CustomAppBar(
      onHorizontalDragEnd: (DragEndDetails details) async {
        await _goBackOrForward(details);
      },
      onPanEnd: _settingsProvider.useTabsHideFeature && _settingsProvider.useTabsFullBrowser
          ? (DragEndDetails details) async {
              _webViewProvider.toggleHideTabs();
              if (await Prefs().getReminderAboutHideTabFeature() == false) {
                Prefs().setReminderAboutHideTabFeature(true);
                return showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const TabsHideReminderDialog();
                  },
                );
              }
            }
          : null,
      genericAppBar: AppBar(
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: _backButtonPopsContext ? const Icon(Icons.close) : const Icon(Icons.arrow_back_ios),
          onPressed: () async {
            // Normal behavior is just to pop and go to previous page
            if (_backButtonPopsContext) {
              _webViewProvider.setCurrentUiMode(UiMode.window, context);
              if (mounted) {
                _webViewProvider.browserShowInForeground = false;
                _checkIfTargetsAttackedAndRevertChaining();
              }
            } else {
              // But we can change and go back to previous page in certain
              // situations (e.g. when going for the vault while trading)
              final backPossible = await webView.canGoBack();
              if (backPossible) {
                webView.goBack();
              } else {
                if (!mounted) return;
                Navigator.pop(context);
              }
              _backButtonPopsContext = true;
            }
          },
        ),
        title: GestureDetector(
          onTap: () {
            openUrlDialog();
          },
          child: DottedBorder(
            padding: assistPossible ? const EdgeInsets.all(3) : const EdgeInsets.all(6),
            dashPattern: assistPossible ? const [1, 1] : const [1, 4],
            color: assistPossible ? Colors.orange : Colors.white70,
            child: ClipRRect(
              child: Showcase(
                key: _showCaseTitleBar,
                title: 'Options menu',
                description: '\nTap the page title to open a menu with additional options, '
                    'including faction attack assists calls!\n\n'
                    'Swipe left/right to browse back/forward\n\n'
                    'Swipe down/up to hide or show your tab bar!',
                targetPadding: const EdgeInsets.all(10),
                disableMovingAnimation: true,
                textColor: _themeProvider.mainText,
                tooltipBackgroundColor: _themeProvider.secondBackground,
                descTextStyle: TextStyle(fontSize: 13),
                tooltipPadding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    assistPossible
                        ? Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "ASSIST",
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(fontSize: 9, color: Colors.orange),
                                ),
                                Text(
                                  _pageTitle,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : Flexible(
                            child: Text(
                              _pageTitle,
                              overflow: TextOverflow.fade,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: _isChainingBrowser
            ? _chainingActionButtons()
            : <Widget>[
                _crimesMenuIcon(),
                _quickItemsMenuIcon(),
                _travelHomeIcon(),
                _vaultsPopUpIcon(),
                _tradesMenuIcon(),
                _vaultOptionsIcon(),
                _bazaarFillIcon(),
                _cityMenuIcon(),
                if (_webViewProvider.chatRemovalEnabledGlobal) _hideChatIcon() else const SizedBox.shrink(),
                _reloadIcon(),
              ],
      ),
    );
  }

  Widget _reloadIcon() {
    return _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.pull
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: Colors.orange,
                child: const Icon(Icons.refresh),
                onTap: () async {
                  _scrollX = await webView.getScrollX();
                  _scrollY = await webView.getScrollY();
                  await _reload();
                  _scrollAfterLoad = true;

                  BotToast.showText(
                    text: "Reloading...",
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.grey[600],
                    duration: const Duration(seconds: 1),
                    contentPadding: const EdgeInsets.all(10),
                  );
                },
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Future _goBackOrForward(DragEndDetails details) async {
    if (details.primaryVelocity < 0) {
      await _tryGoForward();
    } else if (details.primaryVelocity > 0) {
      await _tryGoBack();
    }
  }

  Future _tryGoBack() async {
    _webViewProvider.verticalMenuClose();

    // It's much more precise to use the native implementation (when not using tabs),
    // since onLoadStop and onLoadResource won't trigger always and need exceptions
    if (widget.useTabs) {
      _webViewProvider.tryGoBack();
    } else {
      bool success = await webView.canGoBack();
      if (success) {
        await webView.goBack();
      }
    }
  }

  Future _tryGoForward() async {
    _webViewProvider.verticalMenuClose();
    if (widget.useTabs) {
      _webViewProvider.tryGoForward();
    } else {
      bool success = await webView.canGoForward();
      if (success) {
        await webView.goForward();
      }
    }
  }

  /// Note: several other modules are called in onProgressChanged, since it's
  /// faster. The ones here probably would not benefit from it.
  Future _assessGeneral(dom.Document document) async {
    _assessBackButtonBehavior();
    _assessTravel(document);
    _assessBazaarOwn(document);
    _assessBazaarOthers(document);
    _assessBarsRedirect(document);
  }

  Future _assessSectionsWithWidgets() async {
    bool anySectionTriggered = false;
    bool getItems = false;
    bool getCrimes = false;
    bool getGym = false;
    bool getCity = false;
    bool getTrades = false;
    bool getVault = false;
    bool getProfile = false;
    bool getAttack = false;
    bool getJail = false;
    bool getBounties = false;

    if ((_currentUrl.contains('item.php') && !_quickItemsTriggered) ||
        (!_currentUrl.contains('item.php') && _quickItemsTriggered)) {
      anySectionTriggered = true;
      getItems = true;
    }

    if ((_currentUrl.contains('crimes.php') && !_crimesTriggered) ||
        (!_currentUrl.contains('crimes.php') && _crimesTriggered)) {
      anySectionTriggered = true;
      getCrimes = true;
    }

    if ((_currentUrl.contains('gym.php') && !_gymTriggered) || (!_currentUrl.contains('gym.php') && _gymTriggered)) {
      anySectionTriggered = true;
      getGym = true;
    }

    if ((_currentUrl.contains('city.php') && !_cityTriggered) ||
        (!_currentUrl.contains('city.php') && _cityTriggered)) {
      anySectionTriggered = true;
      getCity = true;
    }

    if (!_currentUrl.contains("trade.php") && _tradesTriggered) {
      // This is different to the others, here we call only so that trades is deactivated
      anySectionTriggered = true;
      getTrades = true;
    }

    if (!_currentUrl.contains("properties.php") && (_vaultTriggered || _vaultIconActive)) {
      // This is different to the others, here we call only so that properties is deactivated
      anySectionTriggered = true;
      getVault = true;
    }

    if (!_currentUrl.contains("jailview.php") && (_jailExpandable is JailWidget)) {
      // This is different to the others, here we call only so that jail is deactivated
      _jailExpandable = const SizedBox.shrink();
    } else if (_currentUrl.contains("jailview.php") && (_jailExpandable is! JailWidget)) {
      // Note: jail is also in onResource. This will make sure jail activates correctly
      // in some devices
      getJail = true;
    }

    if (!_currentUrl.contains("bounties.php") && (_bountiesExpandable is BountiesWidget)) {
      // This is different to the others, here we call only so that bounties is deactivated
      _bountiesExpandable = const SizedBox.shrink();
    } else if (_currentUrl.contains("bounties.php") && (_bountiesExpandable is! BountiesWidget)) {
      // Note: bounties is also in onResource. This will make sure bounties activates correctly
      // in some devices
      getBounties = true;
    }

    // Using a more direct call for OC NNB
    // The script handles repetitions and we handle how many times API are called
    _assessOCnnb(_currentUrl);

    if (_settingsProvider.extraPlayerInformation) {
      const profileUrl = 'torn.com/profiles.php?XID=';
      const profileUrl2 = 'torn.com/profiles.php?NID=';
      if (((!_currentUrl.contains(profileUrl) && !_currentUrl.contains(profileUrl2)) && _profileTriggered) ||
          ((_currentUrl.contains(profileUrl) || _currentUrl.contains(profileUrl2)) && !_profileTriggered) ||
          ((_currentUrl.contains(profileUrl) || _currentUrl.contains(profileUrl2)) &&
              _currentUrl != _lastProfileVisited)) {
        anySectionTriggered = true;
        getProfile = true;
      }

      const attackUrl = 'loader.php?sid=attack&user2ID=';
      const attackUrl2 = 'loader2.php?sid=getInAttack&user2ID=';
      if ((!_currentUrl.contains(attackUrl) && _attackTriggered) ||
          (!_currentUrl.contains(attackUrl2) && _attackTriggered) ||
          (_currentUrl.contains(attackUrl) && !_attackTriggered) ||
          (_currentUrl.contains(attackUrl2) && !_attackTriggered) ||
          (_currentUrl.contains(attackUrl) && _currentUrl != _lastProfileVisited)) {
        anySectionTriggered = true;
        getAttack = true;
      }
    }

    if (anySectionTriggered) {
      dom.Document doc;
      var pageTitle = "";
      final html = await webView.getHtml();
      doc = parse(html);
      pageTitle = (await _getPageTitle(doc)).toLowerCase();

      if (getItems) _assessQuickItems(pageTitle);
      if (getCrimes) _assessCrimes(pageTitle);
      if (getGym) _assessGym(pageTitle);
      if (getCity) _assessCity(doc, pageTitle);
      if (getTrades) _decideIfCallTrades(doc: doc, pageTitle: pageTitle);
      if (getVault) _assessVault(doc: doc, pageTitle: pageTitle);
      if (getProfile) _assessProfileAttack(document: doc, pageTitle: pageTitle);
      if (getAttack) _assessProfileAttack(document: doc, pageTitle: pageTitle);
      if (getJail) _assessJail(doc);
      if (getBounties) _assessBounties(doc);
    }
  }

  void _resetSectionsWithWidgets() {
    if (_currentUrl.contains('item.php') && _quickItemsTriggered) {
      _crimesTriggered = false;
      _gymTriggered = false;
      _vaultTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains('crimes.php') && _crimesTriggered) {
      _quickItemsTriggered = false;
      _gymTriggered = false;
      _vaultTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains('gym.php') && _gymTriggered) {
      _crimesTriggered = false;
      _quickItemsTriggered = false;
      _vaultTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains('properties.php') && _vaultTriggered) {
      _crimesTriggered = false;
      _gymTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains('city.php') && _cityTriggered) {
      _crimesTriggered = false;
      _gymTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains("trade.php") && _tradesTriggered) {
      _crimesTriggered = false;
      _gymTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains("torn.com/profiles.php?XID=") && _profileTriggered) {
      _crimesTriggered = false;
      _gymTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _tradesTriggered = false;
      _cityTriggered = false;
      _attackTriggered = false;
    } else if ((_currentUrl.contains("loader.php?sid=attack&user2ID=") ||
            _currentUrl.contains("loader2.php?sid=getInAttack&user2ID=")) &&
        _attackTriggered) {
      _crimesTriggered = false;
      _gymTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _tradesTriggered = false;
      _cityTriggered = false;
      _profileTriggered = false;
    } else {
      _crimesTriggered = false;
      _gymTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    }
  }

  Future _assessBackButtonBehavior() async {
    // We show an X and close upon button press if
    //   - we are not moving to a place with a vault; or
    //   - we are not moving to items/armoury with an active chaining browser
    if ((!_currentUrl.contains('properties.php#/p=options&tab=vault') &&
            !_currentUrl.contains('factions.php?step=your#/tab=armoury&start=0&sub=donate') &&
            !_currentUrl.contains('companies.php#/option=funds')) &&
        (!_currentUrl.contains('items.php') && !_currentUrl.contains('factions.php') && !_isChainingBrowser)) {
      _backButtonPopsContext = true;
    }
    // However, if we come from Trades, we'll also change
    // the back button behavior to ensure we are returning to Trades
    else {
      final history = await webView.getCopyBackForwardList();
      // Check if we have more than a single page in history (otherwise we don't come from Trades)
      if (history.currentIndex > 0) {
        if (history.list[history.currentIndex - 1].url.toString().contains('trade.php')) {
          _backButtonPopsContext = false;
        }
      }
    }
  }

  /// This will try first with H4 (works for most Torn sections) and revert
  /// to the URL if it doesn't find anything
  /// [showTitle] show ideally only be set to true in onLoadStop
  /// URLs might show up while loading the page in onProgressChange
  Future<String> _getPageTitle(
    dom.Document document, {
    bool showTitle = false,
  }) async {
    String title = '';
    final h4 = document.querySelector(".content-title > h4");
    if (h4 != null) {
      title = pdaParser.HtmlParser.fix(h4.innerHtml.substring(0).trim());
    }

    if (h4 == null && showTitle) {
      title = await webView.getTitle();
      if (title.contains(' |')) {
        title = title.split(' |')[0];
      }
    }

    // If title is missing, we only show the domain
    if (title.contains('https://www.')) {
      title = title.replaceAll('https://www.', '');
    } else if (title.contains('https://')) {
      title = title.replaceAll('https://', '');
    }

    if (title != null) {
      if (title.toLowerCase().contains('error') || title.toLowerCase().contains('please validate')) {
        if (mounted) {
          setState(() {
            _pageTitle = 'Torn';
          });
        }
      } else {
        if (mounted && showTitle) {
          setState(() {
            _pageTitle = title;
          });
        }
      }
    }
    return title;
  }

  // TRAVEL
  Future _assessTravel(dom.Document document) async {
    final abroad = document.querySelectorAll(".travel-home");
    if (abroad.isNotEmpty) {
      _insertTravelFillMaxButtons();
      _sendStockInformation(document);
      if (mounted) {
        setState(() {
          _travelAbroad = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _travelAbroad = false;
        });
      }
    }
  }

  Future _insertTravelFillMaxButtons() async {
    await webView.evaluateJavascript(source: buyMaxAbroadJS());
  }

  Future _sendStockInformation(dom.Document document) async {
    final elements = document.querySelectorAll('.users-list > li');

    if (elements.isNotEmpty) {
      try {
        // Parse stocks
        final stockModel = ForeignStockOutModel();
        stockModel.authorName = "Manuito";
        stockModel.authorId = 2225097;

        stockModel.country =
            document.querySelector(".content-title > h4").innerHtml.substring(0, 4).toLowerCase().trim();

        for (final el in elements) {
          final stockItem = ForeignStockOutItem();

          stockItem.id = int.tryParse(el.querySelector(".details").attributes["itemid"]);
          stockItem.quantity =
              int.tryParse(el.querySelector(".stck-amount").innerHtml.replaceAll(RegExp("[^0-9]"), ""));
          stockItem.cost = int.tryParse(el.querySelector(".c-price").innerHtml.replaceAll(RegExp("[^0-9]"), ""));

          if (stockItem.id != null && stockItem.quantity != null && stockItem.cost != null) {
            stockModel.items.add(stockItem);
          }
        }

        // Send to server
        await http
            .post(
              Uri.parse('https://yata.yt/api/v1/travel/import/'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: foreignStockOutModelToJson(stockModel),
            )
            .timeout(Duration(seconds: 15));
      } catch (e) {
        // Error parsing
      }
    }
  }

  Widget _travelHomeIcon() {
    // We use two buttons with a trigger, so that we need to press twice
    if (_travelAbroad) {
      if (!_travelHomeIconTriggered) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: Colors.blueGrey,
              child: Icon(
                Icons.home,
                color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
              ),
              onTap: () async {
                setState(() {
                  _travelHomeIconTriggered = true;
                });
                BotToast.showText(
                  text: 'Tap again to travel back!',
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.orange[800],
                  duration: const Duration(seconds: 3),
                  contentPadding: const EdgeInsets.all(10),
                );
                Future.delayed(const Duration(seconds: 3)).then((value) {
                  if (mounted) {
                    setState(() {
                      _travelHomeIconTriggered = false;
                    });
                  }
                });
              },
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: Colors.blueGrey,
              child: const Icon(
                Icons.home,
                color: Colors.orange,
              ),
              onTap: () async {
                await webView.evaluateJavascript(source: travelReturnHomeJS());
                Future.delayed(const Duration(seconds: 3)).then((value) {
                  if (mounted) {
                    setState(() {
                      _travelHomeIconTriggered = false;
                    });
                  }
                });
              },
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  // CRIMES
  Future _assessCrimes(String pageTitle) async {
    if (mounted) {
      if (!pageTitle.contains('crimes')) {
        setState(() {
          _crimesController.expanded = false;
          _crimesActive = false;
        });
        return;
      }

      // Stops any successive calls once we are sure that the section is the
      // correct one. onLoadStop will reset this for the future.
      //
      if (_crimesTriggered) {
        return;
      }
      _crimesTriggered = true;

      setState(() {
        _crimesController.expanded = true;
        _crimesActive = true;
      });
    }
  }

  Widget _crimesMenuIcon() {
    if (_crimesActive) {
      return OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return CrimesOptions();
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        openColor: _themeProvider.canvas,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(
                MdiIcons.fingerprint,
                color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // GYM
  Future _assessGym(String pageTitle) async {
    if (mounted) {
      if (!pageTitle.contains('gym')) {
        setState(() {
          _gymTriggered = false;
          _gymExpandable = const SizedBox.shrink();
        });
        return;
      }

      // Stops any successive calls once we are sure that the section is the
      // correct one. onLoadStop will reset this for the future.
      if (_gymTriggered) {
        return;
      }
      _gymTriggered = true;

      setState(() {
        _gymExpandable = GymWidget();
      });
    }
  }

  // TRADES
  Future _assessTrades(dom.Document document, String pageTitle) async {
    final easyUrl = _currentUrl.replaceAll('#', '').replaceAll('/', '').split('&');

    // Try to get the page title after the section loads
    if (_currentUrl.contains('trade') && pageTitle.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1500));
      final html = await webView.getHtml();
      document = parse(html);
      pageTitle = (await _getPageTitle(document)).toLowerCase();
    }

    if (pageTitle.contains('trade') && _currentUrl.contains('trade.php')) {
      // Activate trades icon even before starting a trade, so that it can be deactivated
      if (mounted) {
        setState(() {
          _tradesIconActive = true;
        });
      }
      _lastTradeCallWasIn = true;
      if (!easyUrl[0].contains('step=initiateTrade') && !easyUrl[0].contains('step=view')) {
        if (_tradesFullActive) {
          _toggleTradesWidget(active: false);
        }
        return;
      }
    } else {
      if (_tradesFullActive) {
        _toggleTradesWidget(active: false);
      }
      if (mounted) {
        setState(() {
          _tradesIconActive = false;
        });
      }
      _lastTradeCallWasIn = false;
      return;
    }

    // We only get this once and if we are inside a trade
    // It's also in the callback from trades options
    if (!_tradesPreferencesLoaded) {
      _tradeCalculatorEnabled = await Prefs().getTradeCalculatorEnabled();
      _tradesPreferencesLoaded = true;
    }
    if (!_tradeCalculatorEnabled) {
      if (_tradesFullActive) {
        _toggleTradesWidget(active: false);
      }
      return;
    }

    String sellerName;
    int sellerId = 0;
    int tradeId;
    // Element containers
    List<dom.Element> leftMoneyElements;
    List<dom.Element> leftItemsElements;
    List<dom.Element> leftPropertyElements;
    List<dom.Element> leftSharesElements;
    List<dom.Element> rightMoneyElements;
    List<dom.Element> rightItemsElements;
    List<dom.Element> rightPropertyElements;
    List<dom.Element> rightSharesElements;

    // Because only the frame reloads, if we can't find anything
    // we'll wait 1 second, get the html again and query again
    final totalFinds = document.querySelectorAll(".color1 .left , .color2 .left , .color1 .right , .color2 .right");

    try {
      if (totalFinds.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1500));
        final updatedHtml = await webView.getHtml();
        final updatedDoc = parse(updatedHtml);
        document = updatedDoc;
      }

      leftMoneyElements = document.querySelectorAll("#trade-container .left .color1 .name");
      leftItemsElements = document.querySelectorAll("#trade-container .left .color2 .name");
      leftPropertyElements = document.querySelectorAll("#trade-container .left .color3 .name");
      leftSharesElements = document.querySelectorAll("#trade-container .left .color4 .name");
      rightMoneyElements = document.querySelectorAll("#trade-container .right .color1 .name");
      rightItemsElements = document.querySelectorAll("#trade-container .right .color2 .name");
      rightPropertyElements = document.querySelectorAll("#trade-container .right .color3 .name");
      rightSharesElements = document.querySelectorAll("#trade-container .right .color4 .name");
      sellerName = document.querySelector(".right .title-black").innerHtml ?? "";

      final sellerIdString = document.querySelectorAll("#trade-container .log li .desc a");
      for (final html in sellerIdString) {
        final RegExp regId = RegExp("XID=([0-9]+)");
        final matches = regId.allMatches(html.attributes["href"]);
        final id = int.parse(matches.elementAt(0).group(1));
        if (id != _userProvider.basic.playerId) {
          sellerId = id;
          break;
        }
      }
    } catch (e) {
      return;
    }

    // Trade Id
    try {
      final RegExp regId = RegExp("&ID=([0-9]+)");
      final matches = regId.allMatches(_currentUrl);
      tradeId = int.parse(matches.elementAt(0).group(1));
    } catch (e) {
      tradeId = 0;
    }

    // Activate trades widget
    _toggleTradesWidget(active: true);

    // Initialize trades provider, which in turn feeds the trades widget
    if (!mounted) return;
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    tradesProvider.updateTrades(
      playerId: _userProvider.basic.playerId,
      sellerName: sellerName,
      sellerId: sellerId,
      tradeId: tradeId,
      leftMoneyElements: leftMoneyElements,
      leftItemsElements: leftItemsElements,
      leftPropertyElements: leftPropertyElements,
      leftSharesElements: leftSharesElements,
      rightMoneyElements: rightMoneyElements,
      rightItemsElements: rightItemsElements,
      rightPropertyElements: rightPropertyElements,
      rightSharesElements: rightSharesElements,
    );
  }

  void _toggleTradesWidget({@required bool active}) {
    if (active) {
      if (mounted) {
        setState(() {
          _tradesFullActive = true;
          _tradesExpandable = TradesWidget(
            themeProv: _themeProvider,
            userProv: _userProvider,
            webView: webView,
          );
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _tradesFullActive = false;
          _tradesExpandable = const SizedBox.shrink();
        });
      }
    }
  }

  Widget _vaultsPopUpIcon() {
    if (_tradesIconActive) {
      return PopupMenuButton<VaultsOptions>(
        icon: Icon(
          MdiIcons.cashUsdOutline,
          color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
        ),
        onSelected: _openVaultsOptions,
        itemBuilder: (BuildContext context) {
          return _popupOptionsChoices.map((VaultsOptions choice) {
            return PopupMenuItem<VaultsOptions>(
              value: choice,
              child: Row(
                children: [
                  Text(choice.description),
                ],
              ),
            );
          }).toList();
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future _openVaultsOptions(VaultsOptions choice) async {
    switch (choice.description) {
      case "Personal vault":
        _loadUrl("https://www.torn.com/properties.php#/p=options&tab=vault");
        break;
      case "Faction vault":
        _loadUrl("https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate");
        break;
      case "Company vault":
        _loadUrl("https://www.torn.com/companies.php#/option=funds");
        break;
    }
  }

  Widget _tradesMenuIcon() {
    if (_tradesIconActive) {
      return OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return TradesOptions(
            playerId: _userProvider.basic.playerId,
            callback: _tradesPreferencesLoad,
          );
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        openColor: _themeProvider.canvas,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(
                MdiIcons.accountSwitchOutline,
                color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future _tradesPreferencesLoad() async {
    _tradeCalculatorEnabled = await Prefs().getTradeCalculatorEnabled();
    _decideIfCallTrades();
  }

  // Avoid continuous calls to trades from different activators
  Future _decideIfCallTrades({dom.Document doc, String pageTitle = ""}) async {
    final now = DateTime.now();
    final diff = now.difference(_lastTradeCall);
    if (diff.inSeconds > 1 || !_lastTradeCallWasIn) {
      _lastTradeCall = now;

      // Call trades. If we come from onProgressChanged we already have document
      // and title (quicker). Otherwise, we need to get them (if we come from trade options)
      if (mounted) {
        if (doc != null && pageTitle.isNotEmpty) {
          _assessTrades(doc, pageTitle);
        } else {
          _currentUrl = (await webView.getUrl()).toString();
          final html = await webView.getHtml();
          final d = parse(html);
          final t = (await _getPageTitle(d)).toLowerCase();
          _assessTrades(d, t);
        }
      }
    }
  }

  // PROPERTIES
  Future _assessVault({dom.Document doc, String pageTitle = "", bool fromReassess = false}) async {
    if (!pageTitle.toLowerCase().contains('properties')) {
      setState(() {
        _vaultIconActive = false;
        _vaultExpandable = const SizedBox.shrink();
      });
      return;
    }

    setState(() {
      _vaultIconActive = true;
    });

    // We only get this once and if we are inside the vault
    // It's also in the callback from vault options
    if (!_vaultPreferencesLoaded) {
      await _reassessVault();
      _vaultPreferencesLoaded = true;
    }

    if (!_vaultEnabled) {
      setState(() {
        _vaultExpandable = const SizedBox.shrink();
      });
      return;
    }

    // Stops any successive calls
    if (_vaultTriggered) return;
    _vaultTriggered = true;

    // Prevents double activation because onLoadResource triggers twice when the vault loads for the
    // first time, with one activation coming from reassessVault() and resetting _vaultTriggered
    if (fromReassess && DateTime.now().difference(_vaultTriggeredTime).inSeconds < 3) return;
    _vaultTriggeredTime = DateTime.now();

    // Android should get all elements every time, as it takes 100ms to load. iOS loads at the
    // very beginning and might need a few tries. So we give 5 seconds.
    List<dom.Element> allTransactions;
    for (var i = 0; i < 10; i++) {
      if (!mounted) break;
      allTransactions = doc.querySelectorAll("ul.vault-trans-list > li:not(.title)");
      if (allTransactions.isNotEmpty) {
        break;
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) break;
        final updatedHtml = await webView.getHtml();
        doc = parse(updatedHtml);
      }
    }

    if (allTransactions.isEmpty) {
      _vaultDetected = false;
      return;
    } else {
      _vaultDetected = true;
    }

    // Activate the vault widget itself. UniqueKey so that we load a new widget when values change
    setState(() {
      _vaultExpandable = VaultWidget(
        key: UniqueKey(),
        vaultHtml: allTransactions,
        playerId: _userProvider.basic.playerId,
        userProvider: _userProvider,
      );
    });
  }

  Widget _vaultOptionsIcon() {
    if (_vaultIconActive) {
      return OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return VaultOptionsPage(
            vaultDetected: _vaultDetected,
            callback: _reassessVault,
          );
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        openColor: _themeProvider.canvas,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(
                MdiIcons.safeSquareOutline,
                color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future _reassessVault() async {
    if (!mounted) return;
    _vaultEnabled = await Prefs().getVaultEnabled();
    // Reset _vaultTriggered so that we can call _assessVault() again
    _vaultTriggered = false;
    final html = await webView.getHtml();
    final document = parse(html);
    final pageTitle = (await _getPageTitle(document)).toLowerCase();
    _assessVault(doc: document, pageTitle: pageTitle, fromReassess: true);
  }

  // CITY
  Future _assessCity(dom.Document document, String pageTitle) async {
    if (!pageTitle.contains('city') || pageTitle.contains('raceway')) {
      setState(() {
        _cityIconActive = false;
        _cityExpandable = const SizedBox.shrink();
      });
      return;
    }

    setState(() {
      _cityIconActive = true;
    });

    // Stops any successive calls
    if (_cityTriggered) {
      return;
    }
    _cityTriggered = true;

    // We only get this once and if we are inside the city
    // It's also in the callback from city options
    if (!_cityPreferencesLoaded) {
      await _cityPreferencesLoad(init: true);
      _cityPreferencesLoaded = true;
    }

    if (!_cityEnabled) {
      setState(() {
        _cityExpandable = const SizedBox.shrink();
      });
      return;
    }

    // Retry several times and allow the map to load. If the user lands in the city list, this will
    // also trigger and the user will have 30 seconds to load the map (after that, only reloading
    // or browsing out/in of city will force a reload)
    List<dom.Element> query;
    for (var i = 0; i < 30; i++) {
      if (!mounted) break;
      query = document.querySelectorAll("#map .leaflet-marker-pane *");
      if (query.isNotEmpty) {
        break;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) break;
        final updatedHtml = await webView.getHtml();
        document = parse(updatedHtml);
      }
    }

    if (query.isEmpty) {
      // Set false so that the page can be reloaded if city widget didn't load
      _cityTriggered = false;
      return;
    }

    final mapItemsList = <String>[];
    for (final mapFind in query) {
      mapFind.attributes.forEach((key, value) {
        if (key == "src" && value.contains("https://www.torn.com/images/items/")) {
          mapItemsList.add(value.split("items/")[1].split("/")[0]);
        }
      });
    }

    // Pass items to widget (if nothing found, widget's list will be empty)
    try {
      final dynamic apiResponse = await Get.find<ApiCallerController>().getItems();
      if (apiResponse is ItemsModel) {
        apiResponse.items.forEach((key, value) {
          // Assign correct ids
          value.id = key;
        });
        final tornItems = apiResponse.items.values.toList();
        final itemsFound = <Item>[];
        for (final mapItem in mapItemsList) {
          final Item itemMatch = tornItems.firstWhere((element) => element.id == mapItem);
          itemsFound.add(itemMatch);
        }
        if (mounted) {
          // This last check prevents city widget from loading if we are leaving the city
          // before it had time to load (which could collude with other widgets)
          if (!_cityTriggered) {
            setState(() {
              _cityExpandable = const SizedBox.shrink();
            });
          } else {
            setState(() {
              _cityItemsFound = itemsFound;
              _errorCityApi = false;
              _cityExpandable = CityWidget(
                controller: webView,
                cityItems: _cityItemsFound,
                error: _errorCityApi,
              );
            });
          }
        }
        webView.evaluateJavascript(source: highlightCityItemsJS());
      } else {
        if (mounted) {
          setState(() {
            _errorCityApi = true;
          });
        }
      }
    } catch (e) {
      return;
    }
  }

  Widget _cityMenuIcon() {
    if (_cityIconActive) {
      return OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return CityOptions(
            callback: _cityPreferencesLoad,
          );
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        openColor: _themeProvider.canvas,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(
                MdiIcons.cityVariantOutline,
                color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future _cityPreferencesLoad({bool init = false}) async {
    _cityEnabled = await Prefs().getCityEnabled();
    // Reset city so that it can be assessed again
    _cityTriggered = false;
    // Do not reload upon first city activation, otherwise we get a reload glitch. Do it only
    // after we have activated/deactivated the city
    if (!init) {
      await _reload();
    }
  }

  // BAZAAR (OWN)
  Future _assessBazaarOwn(dom.Document document) async {
    final easyUrl = _currentUrl.replaceAll('#', '');
    if (easyUrl.contains('bazaar.php/add')) {
      _bazaarActiveOwn = true;
    } else {
      _bazaarActiveOwn = false;
    }
  }

  // BAZAAR (OTHERS)
  Future _assessBazaarOthers(dom.Document document) async {
    final easyUrl = _currentUrl.replaceAll('#', '');
    if (easyUrl.contains('bazaar.php?userId=')) {
      await webView.evaluateJavascript(source: addOthersBazaarFillButtonsJS());
    }
  }

  Widget _bazaarFillIcon() {
    if (_bazaarActiveOwn) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: _webViewProvider.bottomBarStyleEnabled ? 0 : 20,
        ),
        child: GestureDetector(
          onTap: () async {
            _bazaarFillActive
                ? await webView.evaluateJavascript(source: removeOwnBazaarFillButtonsJS())
                : await webView.evaluateJavascript(source: addOwnBazaarFillButtonsJS());

            if (mounted) {
              setState(() {
                _bazaarFillActive ? _bazaarFillActive = false : _bazaarFillActive = true;
              });
            }
          },
          child: Text(
            "FILL",
            style: TextStyle(
              color: _bazaarFillActive
                  ? Colors.yellow[600]
                  : _webViewProvider.bottomBarStyleEnabled
                      ? _themeProvider.mainText
                      : Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // QUICK ITEMS
  Future _assessQuickItems(String pageTitle) async {
    if (mounted) {
      if (!pageTitle.contains('items')) {
        setState(() {
          _quickItemsController.expanded = false;
          _quickItemsActive = false;
          _quickItemsTriggered = false;
        });
        return;
      }

      // Stops any successive calls once we are sure that the section is the
      // correct one. onLoadStop will reset this for the future.
      // Otherwise we would call the API every time onProgressChanged ticks
      if (_quickItemsTriggered) {
        return;
      }
      _quickItemsTriggered = true;

      final quickItemsProvider = context.read<QuickItemsProvider>();
      quickItemsProvider.loadItems();

      setState(() {
        _quickItemsController.expanded = true;
        _quickItemsActive = true;
      });
    }
  }

  // QUICK ITEMS
  Future _assessFactionQuickItems({bool deactivate = false}) async {
    if (mounted) {
      if (deactivate) {
        setState(() {
          _quickItemsFactionController.expanded = false;
          _quickItemsFactionActive = false;
          _quickItemsFactionTriggered = false;
        });
        return;
      }

      // Stops any successive calls once we are sure that the section is the
      // correct one. onLoadStop will reset this for the future.
      // Otherwise we would call the API every time onProgressChanged ticks
      if (_quickItemsFactionTriggered) {
        return;
      }
      _quickItemsFactionTriggered = true;

      final quickItemsProviderFaction = context.read<QuickItemsProviderFaction>();
      quickItemsProviderFaction.loadItems();

      setState(() {
        _quickItemsFactionController.expanded = true;
        _quickItemsFactionActive = true;
      });
    }
  }

  Widget _quickItemsMenuIcon() {
    if (_quickItemsActive || _quickItemsFactionActive) {
      return OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return QuickItemsOptions(
            isFaction: _quickItemsFactionActive,
          );
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        openColor: _themeProvider.canvas,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Image.asset(
                'images/icons/quick_items.png',
                color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // ASSESS PROFILES
  Future _assessProfileAttack({dom.Document document, String pageTitle = ""}) async {
    if (mounted) {
      if (!_currentUrl.contains('loader.php?sid=attack&user2ID=') &&
          !_currentUrl.contains('loader2.php?sid=getInAttack&user2ID=') &&
          !_currentUrl.contains('torn.com/profiles.php?XID=') &&
          !_currentUrl.contains('torn.com/profiles.php?NID=')) {
        _profileTriggered = false;
        _profileAttackWidget = const SizedBox.shrink();
        return;
      }

      int userId = 0;

      if (_currentUrl.contains('torn.com/profiles.php?XID=') || _currentUrl.contains('torn.com/profiles.php?NID=')) {
        if (_profileTriggered && _currentUrl == _lastProfileVisited) {
          return;
        }
        _profileTriggered = true;
        _lastProfileVisited = _currentUrl;

        try {
          if (_currentUrl.contains('torn.com/profiles.php?XID=')) {
            final RegExp regId = RegExp(r"php\?XID=([0-9]+)");
            final matches = regId.allMatches(_currentUrl);

            userId = int.parse(matches.elementAt(0).group(1));
            setState(() {
              _profileAttackWidget = ProfileAttackCheckWidget(
                key: UniqueKey(),
                profileId: userId,
                apiKey: _userProvider?.basic?.userApiKey ?? "",
                profileCheckType: ProfileCheckType.profile,
                themeProvider: _themeProvider,
              );
            });
          } else if (_currentUrl.contains('torn.com/profiles.php?NID=')) {
            // When the URL is constructed with name instead of ID (e.g.: when the heart icon is pressed),
            // we capture the ID from the profile element, ensuring that it's besides the correct name

            final RegExp regId = RegExp(r"php\?NID=([^&]+)");
            final matches = regId.allMatches(_currentUrl);
            String username = matches.elementAt(0).group(1);

            dom.Element userInfoValue = document.querySelector('div.user-info-value');
            String textContent = userInfoValue.querySelector('span.bold').text.trim();
            final RegExp regUsername = RegExp(r'(' + username + r')\s*\[([0-9]+)\]');
            final match = regUsername.firstMatch(textContent);
            if (match != null) {
              setState(() {
                _profileAttackWidget = ProfileAttackCheckWidget(
                  key: UniqueKey(),
                  profileId: int.parse(match.group(2)),
                  apiKey: _userProvider?.basic?.userApiKey ?? "",
                  profileCheckType: ProfileCheckType.profile,
                  themeProvider: _themeProvider,
                );
              });
            }
          } else {
            userId = 0;
          }
        } catch (e) {
          userId = 0;
        }
      } else if (_currentUrl.contains('loader.php?sid=attack&user2ID=') ||
          _currentUrl.contains('loader2.php?sid=getInAttack&user2ID=')) {
        if (_attackTriggered && _currentUrl == _lastProfileVisited) {
          return;
        }
        _attackTriggered = true;
        _lastProfileVisited = _currentUrl;

        try {
          final RegExp regId = RegExp("&user2ID=([0-9]+)");
          final matches = regId.allMatches(_currentUrl);
          userId = int.parse(matches.elementAt(0).group(1));
          setState(() {
            _profileAttackWidget = ProfileAttackCheckWidget(
              key: UniqueKey(),
              profileId: userId,
              apiKey: _userProvider?.basic?.userApiKey ?? "",
              profileCheckType: ProfileCheckType.attack,
              themeProvider: _themeProvider,
            );
          });
        } catch (e) {
          userId = 0;
        }
      }
    }
  }

  // TRAVEL
  Future _assessBarsRedirect(dom.Document document) async {
    final inTorn = _currentUrl.contains("torn.com");
    if (inTorn) {
      webView?.evaluateJavascript(source: barsDoubleClickRedirect());
    }
  }

  // HIDE CHAT
  Widget _hideChatIcon() {
    if (!_localChatRemovalActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          child: Icon(
            MdiIcons.chatOutline,
            color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
          ),
          onTap: () async {
            webView.evaluateJavascript(source: removeChatJS());
            _webViewProvider.reportChatRemovalChange(true, false);
            setState(() {
              _localChatRemovalActive = true;
            });
            _webViewProvider.verticalMenuClose();
          },
          onLongPress: () async {
            webView.evaluateJavascript(source: removeChatJS());
            _webViewProvider.reportChatRemovalChange(true, true);
            setState(() {
              _localChatRemovalActive = true;
            });
            _webViewProvider.verticalMenuClose();

            BotToast.showText(
              crossPage: false,
              text: "Default chat hide enabled (new tabs)",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue,
              duration: const Duration(seconds: 1),
              contentPadding: const EdgeInsets.all(10),
            );
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          child: Icon(
            MdiIcons.chatRemoveOutline,
            color: Colors.orange[500],
          ),
          onTap: () async {
            webView.evaluateJavascript(source: restoreChatJS());
            _webViewProvider.reportChatRemovalChange(false, false);
            setState(() {
              _localChatRemovalActive = false;
            });
            _webViewProvider.verticalMenuClose();
          },
          onLongPress: () async {
            webView.evaluateJavascript(source: restoreChatJS());
            _webViewProvider.reportChatRemovalChange(false, true);
            setState(() {
              _localChatRemovalActive = false;
            });
            _webViewProvider.verticalMenuClose();

            BotToast.showText(
              crossPage: false,
              text: "Default chat hide disabled",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.grey[700],
              duration: const Duration(seconds: 1),
              contentPadding: const EdgeInsets.all(10),
            );
          },
        ),
      );
    }
  }

  Future _reload() async {
    // Reset city so that it can be reloaded and icons don't disappear
    if (_cityTriggered) _cityTriggered = false;

    if (Platform.isAndroid) {
      UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
        url: await webView.getUrl().toString(),
        apiKey: _userProvider?.basic?.userApiKey ?? "",
        time: UserScriptTime.start,
      );
      await webView.addUserScripts(userScripts: scriptsToAdd);

      // DEBUG
      if (_debugScriptsInjection) {
        var addList = [];
        for (var s in scriptsToAdd) {
          addList.add(s.groupName);
        }
        log("Added scripts in Android reload: $addList");
      }

      webView.reload();
    } else if (Platform.isIOS) {
      var currentURI = await webView.getUrl();
      _loadUrl(currentURI.toString());
    }
  }

  Future reloadFromOutside() async {
    _scrollX = await webView.getScrollX();
    _scrollY = await webView.getScrollY();
    await _reload();
    _scrollAfterLoad = true;

    BotToast.showText(
      text: "Reloading...",
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.grey[600],
      duration: const Duration(seconds: 1),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Future<void> openUrlDialog() async {
    _webViewProvider.verticalMenuClose();
    final url = await webView.getUrl();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return WebviewUrlDialog(
          title: _pageTitle,
          url: url.toString(),
          inAppWebview: webView,
          callFindInPage: _activateFindInPage,
          userProvider: _userProvider,
        );
      },
    );
  }

  void _activateFindInPage() {
    setState(() {
      _findInPageActive = true;
    });
    _findFocus.requestFocus();
  }

  void _findAll() {
    if (_findController.text.isNotEmpty) {
      setState(() {
        _findFirstSubmitted = true;
      });
      _findInteractionController.findAll(find: _findController.text);
    }
  }

  void _findNext({@required bool forward}) {
    _findInteractionController.findNext(forward: forward);
    if (_findFocus.hasFocus) _findFocus.unfocus();
  }

  void onFindInputTextChange() {
    if (_findController.text != _findPreviousText) {
      setState(() {
        _findFirstSubmitted = false;
      });
    }
  }

  // ASSESS GYM
  Future assessEnergyWarning() async {
    if (!mounted) return;
    if (!_settingsProvider.warnAboutExcessEnergy && !_settingsProvider.warnAboutChains) return;

    final easyUrl = _currentUrl.replaceAll('#', '');
    if (easyUrl.contains('www.torn.com/gym.php') || easyUrl.contains('index.php?page=hunting')) {
      final stats = await Get.find<ApiCallerController>().getBars();
      if (stats is BarsModel) {
        var message = "";
        if (stats.chain.current > 10 && stats.chain.cooldown == 0) {
          message = 'Caution: your faction is chaining!';
        } else if (stats.energy.current >= _settingsProvider.warnAboutExcessEnergyThreshold) {
          message = 'Caution: high energy detected, you might be stacking!';
        }

        if (message.isNotEmpty) {
          if (widget.useTabs) {
            // This avoid repeated BotToast messages if several tabs are open to the gym
            _webViewProvider.showEnergyWarningMessage(message, widget.key);
          } else {
            BotToast.showText(
              crossPage: false,
              text: message,
              align: Alignment.center,
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue,
              duration: const Duration(seconds: 2),
              contentPadding: const EdgeInsets.all(10),
            );
          }
        }
      }
    }
  }

  // JAIL
  void _assessJail(dom.Document doc) {
    // If it's the first time we enter (we have no jailModel) or if we are reentering (expandable is empty), we call
    // the widget and get values from shared preferences.
    if (_jailModel == null || _jailExpandable is! JailWidget) {
      setState(() {
        _jailExpandable = JailWidget(
          webview: webView,
          fireScriptCallback: _fireJailScriptCallback,
          playerName: _userProvider.basic.name.toUpperCase(),
        );
      });
    }
    // Otherwise, we are changing pages or reloading. We just need to fire the script. Any changes in the script
    // while the widget is shown will be handled by the callback (which also triggers the script)
    else {
      _fireJailScriptCallback(_jailModel);
    }
  }

  void _fireJailScriptCallback(JailModel jailModel) {
    if (jailModel == null) return;

    _jailModel = jailModel;
    webView.evaluateJavascript(
      source: jailJS(
        levelMin: _jailModel.levelMin,
        levelMax: _jailModel.levelMax,
        timeMin: _jailModel.timeMin,
        timeMax: _jailModel.timeMax,
        scoreMin: _jailModel.scoreMin,
        scoreMax: _jailModel.scoreMax,
        bailTicked: _jailModel.bailTicked,
        bustTicked: _jailModel.bustTicked,
        excludeSelf: _jailModel.excludeSelf,
        excludeName: _jailModel.excludeName,
      ),
    );
  }

  // BOUNTIES
  void _assessBounties(dom.Document doc) {
    // If it's the first time we enter (we have no bountiesModel) or if we are reentering (expandable is empty), we call
    // the widget and get values from shared preferences.
    if (_bountiesModel == null || _bountiesExpandable is! BountiesWidget) {
      setState(() {
        _bountiesExpandable = BountiesWidget(
          webview: webView,
          fireScriptCallback: _fireBountiesScriptCallback,
        );
      });
    }
    // Otherwise, we are changing pages or reloading. We just need to fire the script. Any changes in the script
    // while the widget is shown will be handled by the callback (which also triggers the script)
    else {
      _fireBountiesScriptCallback(_bountiesModel);
    }
  }

  void _fireBountiesScriptCallback(BountiesModel bountiesModel) {
    if (bountiesModel == null) return;

    _bountiesModel = bountiesModel;
    webView.evaluateJavascript(
      source: bountiesJS(
        levelMax: _bountiesModel.levelMax,
        removeNotAvailable: _bountiesModel.removeRed,
      ),
    );
  }

  // ORGANIZED CRIMES NNB
  void _assessOCnnb(String calledUrl) async {
    if (_settingsProvider.naturalNerveBarSource == NaturalNerveBarSource.off) return;

    if (!calledUrl.contains(_ocNnbUrl)) {
      // Return calls and reset widget if we are in another URL
      if (_ocNnbTriggered) _ocNnbTriggered = false;
      if (_ocNnbController.expanded) {
        setState(() {
          _ocNnbController.expanded = false;
        });
      }
      return;
    }

    // API are protected by timing, and NNB script is protected by saved variable
    // But we also double check here to avoid several activations (prob. not necessary)
    if (_nnbTriggeredTime != null && DateTime.now().difference(_nnbTriggeredTime).inSeconds < 2) return;
    _nnbTriggeredTime = DateTime.now();

    log(DateTime.now().toString());

    _ocNnbTriggered = true;
    setState(() {
      _ocNnbController.expanded = true;
    });

    String membersString = "{";
    try {
      if (_settingsProvider.naturalNerveBarSource == NaturalNerveBarSource.yata) {
        _ocSource = "YATA";

        YataMembersModel yataMembers;
        final t = await Prefs().getNaturalNerveYataTime();
        _yataTriggeredTime = DateTime.fromMillisecondsSinceEpoch(t);
        if (DateTime.now().difference(_yataTriggeredTime).inHours < 2) {
          final yataSaved = await Prefs().getNaturalNerveYataModel();
          yataMembers = yataMembersModelFromJson(yataSaved);
          log("Using saved YATA members for NNB");
        } else {
          log("Fetching new YATA members for NNB");
          String yataUrl = 'https://yata.yt/api/v1/faction/members/?key=${_u.alternativeYataKey}';
          final yataOCjson = await http.get(WebUri(yataUrl)).timeout(Duration(seconds: 15));
          yataMembers = yataMembersModelFromJson(yataOCjson.body);
          Prefs().setNaturalNerveYataModel(yataMembersModelToJson(yataMembers));
          Prefs().setNaturalNerveYataTime(DateTime.now().millisecondsSinceEpoch);
        }

        yataMembers.members.forEach((key, value) {
          if (value.nnbShare == 1) {
            membersString += '"${value.id}":"${value.nnb}",';
          } else {
            membersString += '"${value.id}":"unk",';
          }
        });
      } else if (_settingsProvider.naturalNerveBarSource == NaturalNerveBarSource.tornStats) {
        _ocSource = "Torn Stats";

        TornStatsMembersModel tsMembers;
        final t = await Prefs().getNaturalNerveTornStatsTime();
        _tsTriggeredTime = DateTime.fromMillisecondsSinceEpoch(t);

        if (DateTime.now().difference(_tsTriggeredTime).inHours < 2) {
          final tsSaved = await Prefs().getNaturalNerveTornStatsModel();
          tsMembers = tornStatsMembersModelFromJson(tsSaved);
          log("Using saved YATA members for NNB");
        } else {
          log("Fetching new TS members for NNB");
          String tsUrl = 'https://www.tornstats.com/api/v2/${_u.alternativeTornStatsKey}/faction/crimes';
          final tsOCjson = await http.get(WebUri(tsUrl)).timeout(Duration(seconds: 15));
          tsMembers = tornStatsMembersModelFromJson(tsOCjson.body);

          if (!tsMembers.status) {
            BotToast.showText(
              text: "Could not load NNB from TornStats: ${tsMembers.message}",
              clickClose: true,
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.red[900],
              duration: Duration(seconds: 5),
              contentPadding: EdgeInsets.all(10),
            );
            return;
          }

          Prefs().setNaturalNerveTornStatsModel(tornStatsMembersModelToJson(tsMembers));
          Prefs().setNaturalNerveTornStatsTime(DateTime.now().millisecondsSinceEpoch);
        }

        tsMembers.members.forEach((key, value) {
          // No need to account for unknown in TS, as the member won't be in the JSON (the script assigns 'unk')
          membersString += '"${key}":"${value.naturalNerve}",';
        });
      }

      membersString += "}";

      // On iOS, when using the new menu icon for OC, the html doc does not respond for some reason
      // We just wait a second and then add the script (should not be noticeable)
      await Future.delayed(Duration(milliseconds: 1000));
      webView.evaluateJavascript(source: ocNNB(members: membersString));
    } catch (e) {
      BotToast.showText(
        text: "Could not load NNB from $_ocSource: ${e}",
        clickClose: true,
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red[900],
        duration: Duration(seconds: 5),
        contentPadding: EdgeInsets.all(10),
      );
    }
  }

  // Called from parent though GlobalKey state
  void loadFromExterior({@required String url, @required bool omitHistory}) {
    _omitTabHistory = omitHistory;
    _loadUrl(url);
  }

  // Called from parent though GlobalKey state
  void convertToChainingBrowser({ChainingPayload chainingPayload}) {
    _isChainingBrowser = true;
    _attackNumber = 0;
    _chainingPayload = chainingPayload;
    if (_w == null) {
      _w = Get.put(WarController());
    }
    String title = chainingPayload.attackNameList[0];
    _pageTitle = title;
    _chainStatusProvider = context.read<ChainStatusProvider>();
    if (_chainStatusProvider.watcherActive) {
      _chainWidgetController.expanded = true;
    }
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    if (chainingPayload.war) {
      _lastAttackedMembers.clear();
      _lastAttackedMembers.add(chainingPayload.attackIdList[0]);
    } else {
      _lastAttackedTargets.clear();
      _lastAttackedTargets.add(chainingPayload.attackIdList[0]);
    }
  }

  // Called from parent though GlobalKey state
  void cancelChainingBrowser() async {
    final html = await webView.getHtml();
    dom.Document document = parse(html);
    _pageTitle = await _getPageTitle(document);
    // Reports page title so that tab names are updated immediately
    // (otherwise, the last target remains as page title)
    _webViewProvider.reportTabPageTitle(widget.key, _pageTitle);
    setState(() {
      _isChainingBrowser = false;
    });
  }

  /// Note: it is not possible to use pauseTimers in iOS
  /// since it will always pause the current webview
  void pauseThisWebview() {
    if (Platform.isAndroid) {
      webView?.pause();
    }
  }

  void resumeThisWebview() async {
    if (Platform.isAndroid) {
      webView?.resume();
    } else if (Platform.isIOS) {
      webView?.resumeTimers();
    }

    // WkWebView on iOS might fail and return null after heavy load (memory, tabs, etc)
    try {
      Uri resumedUrl = await webView?.getUrl();
      if (resumedUrl == null) {
        log("Reviving webView!");
        _webViewProvider.reviveUrl();
      }
    } catch (e) {
      _webViewProvider.reviveUrl();
    }
  }

  void _loadUrl(String inputUrl) async {
    // If the input URL is invalid, we will see if there was one saved as _currentUrl
    // http and https are valid because we'll change them later
    if (inputUrl == null || inputUrl.isEmpty) {
      if (_currentUrl.isNotEmpty && _currentUrl.contains("http")) {
        inputUrl = _currentUrl;
      } else {
        return;
      }
    }

    inputUrl.replaceAll("http://", "https://");

    if (Platform.isAndroid || (Platform.isIOS && widget.windowId == null)) {
      // Loads userscripts that are not triggered in shouldOverrideUrlLoading
      // (e.g.: when reloading a page or navigating back/forward)
      UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
        url: inputUrl,
        apiKey: _userProvider?.basic?.userApiKey ?? "",
        time: UserScriptTime.start,
      );
      await webView.addUserScripts(userScripts: scriptsToAdd);

      // DEBUG
      if (_debugScriptsInjection) {
        var addList = [];
        for (var s in scriptsToAdd) {
          addList.add(s.groupName);
        }
        log("Added scripts in _loadUrl: $addList");
      }
    }

    var uri = WebUri(inputUrl);
    webView.loadUrl(urlRequest: URLRequest(url: uri));
  }

  String reportCurrentUrl() {
    return _currentUrl;
  }

  String reportCurrentTitle() {
    return _pageTitle;
  }

  void _revertTransparentBackground() async {
    if (_firstLoad) {
      InAppWebViewSettings newSettings = await webView.getSettings();
      newSettings.transparentBackground = false;
      webView.setSettings(settings: newSettings);
      _firstLoad = false;
    }
  }

  void _showLongPressCard(String src, Uri url) {
    BotToast.showCustomText(
      onlyOne: false,
      clickClose: true,
      ignoreContentClick: false,
      crossPage: false,
      duration: Duration(seconds: 5),
      toastBuilder: (textCancel) => Align(
        alignment: Alignment(0, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              color: Colors.grey[700],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                      child: GestureDetector(
                        child: Text(
                          "Copy link",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () {
                          var open = url.toString() ?? src;
                          Clipboard.setData(ClipboardData(text: open));
                          BotToast.showText(
                            text: "Link copied to the clipboard: ${open}",
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.grey[700],
                            duration: Duration(seconds: 2),
                            contentPadding: EdgeInsets.all(10),
                          );
                        },
                      ),
                    ),
                    if (src != null)
                      Column(
                        children: [
                          SizedBox(width: 150, child: Divider(color: Colors.white)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: GestureDetector(
                              child: Text(
                                "Open image in new tab",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              onTap: () {
                                // If we are using tabs, add a tab
                                String u = src.replaceAll("http:", "https:");
                                _webViewProvider.addTab(url: u);
                                _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
                                textCancel();
                              },
                            ),
                          ),
                        ],
                      ),
                    if (_settingsProvider.useTabsFullBrowser)
                      Column(
                        children: [
                          SizedBox(width: 150, child: Divider(color: Colors.white)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: GestureDetector(
                              child: Text(
                                "Open link in new tab",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              onTap: () {
                                // If we are using tabs, add a tab
                                String u = url.toString().replaceAll("http:", "https:");
                                _webViewProvider.addTab(url: u);
                                _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
                                textCancel();
                              },
                            ),
                          ),
                        ],
                      ),
                    SizedBox(width: 150, child: Divider(color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                      child: GestureDetector(
                        child: Text(
                          "Add as shortcut",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () async {
                          String open = url.toString() ?? src;

                          bool error = false;
                          if (open == null) error = true;
                          if (open != null) {
                            if (!open.contains("http")) {
                              error = true;
                            }
                          }

                          if (!error) {
                            String u = open.replaceAll("http:", "https:");
                            return showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return CustomShortcutDialog(
                                  themeProvider: _themeProvider,
                                  title: "",
                                  url: u,
                                );
                              },
                            );
                          } else {
                            BotToast.showText(
                              text: "URL error!",
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.orange[800],
                              duration: Duration(seconds: 2),
                              contentPadding: EdgeInsets.all(10),
                            );
                          }
                          textCancel();
                        },
                      ),
                    ),
                    SizedBox(width: 150, child: Divider(color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                      child: GestureDetector(
                        child: Text(
                          "External browser",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () async {
                          var open = url.toString() ?? src;
                          if (await canLaunchUrl(Uri.parse(open))) {
                            await launchUrl(Uri.parse(open), mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chaining menu
  List<Widget> _chainingActionButtons() {
    List<Widget> myButtons = [];

    //myButtons.add(_quickItemsMenuIcon());

    Widget hideChatIcon = _webViewProvider.chatRemovalEnabledGlobal ? _hideChatIcon() : SizedBox.shrink();
    myButtons.add(hideChatIcon);

    myButtons.add(_reloadIcon());

    myButtons.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          child: Icon(MdiIcons.linkVariant),
          onTap: () {
            _chainWidgetController.expanded
                ? _chainWidgetController.expanded = false
                : _chainWidgetController.expanded = true;
          },
        ),
      ),
    );

    myButtons.add(_medicalActionButton());

    if (_attackNumber < _chainingPayload.attackIdList.length - 1) {
      myButtons.add(_nextAttackActionButton());
    } else {
      myButtons.add(_endAttackButton());
    }

    return myButtons;
  }

  Widget _nextAttackActionButton() {
    return Showcase(
      key: _showCasePlayPauseChain,
      title: 'Chain Forward/Stop!',
      description: '\nYou can now continue your chain even if you close the browser.\n\n'
          'If you would like to stop your chain at some point, long-press this button '
          'to revert to a standard browser tab!',
      targetPadding: const EdgeInsets.all(10),
      disableMovingAnimation: true,
      textColor: _themeProvider.mainText,
      tooltipBackgroundColor: _themeProvider.secondBackground,
      descTextStyle: TextStyle(fontSize: 13),
      tooltipPadding: EdgeInsets.all(20),
      child: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Icon(MdiIcons.playPause),
        ),
        onTap: _nextButtonPressed ? null : () => _launchNextAttack(),
        onLongPress: () => _webViewProvider.cancelChainingBrowser(),
      ),
    );
  }

  Widget _endAttackButton() {
    return IconButton(
      icon: Icon(MdiIcons.stop),
      onPressed: () {
        _webViewProvider.cancelChainingBrowser();
      },
    );
  }

  Widget _medicalActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: PopupMenuButton<HealingPages>(
        icon: Icon(Icons.healing),
        onSelected: _openHealingPage,
        itemBuilder: (BuildContext context) {
          return _chainingAidPopupChoices.map((HealingPages choice) {
            return PopupMenuItem<HealingPages>(
              value: choice,
              child: Text(choice.description),
            );
          }).toList();
        },
      ),
    );
  }

  void _openHealingPage(HealingPages choice) async {
    String goBackTitle = _pageTitle;
    // Check if the proper page loads (e.g. if we have started an attack, it won't let us change to another page!).
    // Note: this is something that can't be done from one target to another,
    // but only between different sections (not sure why).
    await _loadUrl('${choice.url}');
    await Future.delayed(const Duration(seconds: 1), () {});
    if (goBackTitle != _currentUrl) {
      setState(() {
        _pageTitle = 'Items';
        _backButtonPopsContext = false;
      });
    }
  }

  void _assessFirstTargetsOnLaunch() async {
    if (_chainingPayload.panic || (_settingsProvider.targetSkippingAll && _settingsProvider.targetSkippingFirst)) {
      // Counters for target skipping
      int targetsSkipped = 0;
      var originalPosition = _attackNumber;
      bool reachedEnd = false;
      var skippedNames = [];

      // We'll skip maximum of 3 targets
      for (var i = 0; i < 3; i++) {
        // Get the status of our next target
        var nextTarget = await Get.find<ApiCallerController>().getTarget(playerId: _chainingPayload.attackIdList[i]);

        if (nextTarget is TargetModel) {
          // If in hospital or jail (even in a different country), we skip
          if (nextTarget.status.color == "red") {
            targetsSkipped++;
            skippedNames.add(nextTarget.name);
            _attackNumber++;
          }
          // If flying, we need to see if he is in a different country (if we are in the same
          // place, we can attack him)
          else if (nextTarget.status.color == "blue") {
            var user =
                await Get.find<ApiCallerController>().getTarget(playerId: _userProvider.basic.playerId.toString());
            if (user is TargetModel) {
              if (user.status.description != nextTarget.status.description) {
                targetsSkipped++;
                skippedNames.add(nextTarget.name);
                _attackNumber++;
              }
            }
          }
          // If we found a good target, we break here. But before, we gather
          // some more details if option is enabled
          else {
            if (_chainingPayload.showOnlineFactionWarning) {
              _factionName = nextTarget.faction.factionName;
              _lastOnline = nextTarget.lastAction.timestamp;
            }
            break;
          }
          // If after looping we are over the target limit, it means we have reached the end
          // in which case we reset the position to the last target we attacked, and break
          if (_attackNumber >= _chainingPayload.attackIdList.length) {
            _attackNumber = originalPosition;
            reachedEnd = true;
            break;
          }
        }
        // If there is an error getting a target, don't skip
        else {
          _factionName = "";
          _lastOnline = 0;
          break;
        }
      }

      if (targetsSkipped > 0 && !reachedEnd) {
        BotToast.showText(
          text: "Skipped ${skippedNames.join(", ")}, either in jail, hospital or in a different "
              "country",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 5),
          contentPadding: EdgeInsets.all(10),
        );

        var nextBaseUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=';
        if (!mounted) return;
        await _loadUrl('$nextBaseUrl${_chainingPayload.attackIdList[_attackNumber]}');
        if (_chainingPayload.war) {
          _lastAttackedMembers.add(_chainingPayload.attackIdList[_attackNumber]);
        } else {
          _lastAttackedTargets.add(_chainingPayload.attackIdList[_attackNumber]);
        }

        setState(() {
          _pageTitle = '${_chainingPayload.attackNameList[_attackNumber]}';
        });

        // Show note for next target
        if (_chainingPayload.showNotes) {
          _showNoteToast();
        }

        return;
      }

      if (targetsSkipped > 0 && reachedEnd) {
        BotToast.showText(
          text: "No more targets, all remaining are either in jail, hospital or in a different "
              "country (${skippedNames.join(", ")})",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 5),
          contentPadding: EdgeInsets.all(10),
        );

        return;
      }
    }

    // This will show the note of the first target, if applicable
    if (_chainingPayload.showNotes) {
      if (_chainingPayload.showOnlineFactionWarning) {
        var nextTarget = await Get.find<ApiCallerController>().getTarget(playerId: _chainingPayload.attackIdList[0]);
        if (nextTarget is TargetModel) {
          _factionName = nextTarget.faction.factionName;
          _lastOnline = nextTarget.lastAction.timestamp;
        }
      }
      _showNoteToast();
    }
  }

  /// Not to be used right after launch
  void _launchNextAttack() async {
    var nextBaseUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=';
    // Turn button grey
    setState(() {
      _nextButtonPressed = true;
    });

    if (_chainingPayload.panic || _settingsProvider.targetSkippingAll) {
      // Counters for target skipping
      int targetsSkipped = 0;
      var originalPosition = _attackNumber;
      bool reachedEnd = false;
      var skippedNames = [];

      // We'll skip maximum of 3 targets
      for (var i = 0; i < 3; i++) {
        // Get the status of our next target
        var nextTarget =
            await Get.find<ApiCallerController>().getTarget(playerId: _chainingPayload.attackIdList[_attackNumber + 1]);

        if (nextTarget is TargetModel) {
          // If in hospital or jail (even in a different country), we skip
          if (nextTarget.status.color == "red") {
            targetsSkipped++;
            skippedNames.add(nextTarget.name);
            _attackNumber++;
          }
          // If flying, we need to see if he is in a different country (if we are in the same
          // place, we can attack him)
          else if (nextTarget.status.color == "blue") {
            var user =
                await Get.find<ApiCallerController>().getTarget(playerId: _userProvider.basic.playerId.toString());
            if (user is TargetModel) {
              if (user.status.description != nextTarget.status.description) {
                targetsSkipped++;
                skippedNames.add(nextTarget.name);
                _attackNumber++;
              }
            }
          }
          // If we found a good target, we break here. But before, we gather
          // some more details if option is enabled
          else {
            if (_chainingPayload.showOnlineFactionWarning) {
              _factionName = nextTarget.faction.factionName;
              _lastOnline = nextTarget.lastAction.timestamp;
            }
            break;
          }
          // If after looping we are over the target limit, it means we have reached the end
          // in which case we reset the position to the last target we attacked, and break
          if (_attackNumber >= _chainingPayload.attackIdList.length - 1) {
            _attackNumber = originalPosition;
            reachedEnd = true;
            break;
          }
        }
        // If there is an error getting a target, don't skip
        else {
          _factionName = "";
          _lastOnline = 0;
          break;
        }
      }

      if (targetsSkipped > 0 && !reachedEnd) {
        BotToast.showText(
          text: "Skipped ${skippedNames.join(", ")}, either in jail, hospital or in a different "
              "country",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 5),
          contentPadding: EdgeInsets.all(10),
        );
      }

      if (targetsSkipped > 0 && reachedEnd) {
        BotToast.showText(
          text: "No more targets, all remaining are either in jail, hospital or in a different "
              "country (${skippedNames.join(", ")})",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 5),
          contentPadding: EdgeInsets.all(10),
        );

        setState(() {
          _nextButtonPressed = false;
        });
        return;
      }
    }
    // If skipping is disabled but notes are not, we still get information
    // from the API
    else {
      if (_chainingPayload.showOnlineFactionWarning) {
        var nextTarget =
            await Get.find<ApiCallerController>().getTarget(playerId: _chainingPayload.attackIdList[_attackNumber + 1]);

        if (nextTarget is TargetModel) {
          _factionName = nextTarget.faction.factionName;
          _lastOnline = nextTarget.lastAction.timestamp;
        } else {
          _factionName = "";
          _lastOnline = 0;
        }
      }
    }

    _attackNumber++;
    if (!mounted) return;
    await _loadUrl('$nextBaseUrl${_chainingPayload.attackIdList[_attackNumber]}');
    if (_chainingPayload.war) {
      _lastAttackedMembers.add(_chainingPayload.attackIdList[_attackNumber]);
    } else {
      _lastAttackedTargets.add(_chainingPayload.attackIdList[_attackNumber]);
    }
    setState(() {
      _pageTitle = '${_chainingPayload.attackNameList[_attackNumber]}';
    });
    _backButtonPopsContext = true;

    // Turn button back to usable
    setState(() {
      _nextButtonPressed = false;
    });

    // Show note for next target
    if (_chainingPayload.showNotes) {
      _showNoteToast();
    }
  }

  /// Use [onlyOne] when we want to get rid of several notes (e.g. to skip the very first target(s)
  /// without showing the notes for the ones skipped)
  void _showNoteToast() {
    Color cardColor;
    switch (_chainingPayload.attackNotesColorList[_attackNumber]) {
      case 'z':
        cardColor = Colors.grey[700];
        break;
      case 'green':
        cardColor = Colors.green[900];
        break;
      case 'orange':
        cardColor = Colors.orange[900];
        break;
      case 'red':
        cardColor = Colors.red[900];
        break;
      default:
        cardColor = Colors.grey[700];
    }

    String extraInfo = "";
    if (_lastOnline > 0 && !_chainingPayload.war) {
      var now = DateTime.now();
      var lastOnlineDiff = now.difference(DateTime.fromMillisecondsSinceEpoch(_lastOnline * 1000));
      if (lastOnlineDiff.inDays < 7) {
        if (_chainingPayload.attackNotesList[_attackNumber].isNotEmpty) {
          extraInfo += "\n\n";
        }
        if (lastOnlineDiff.inHours < 1) {
          extraInfo += "Online less than an hour ago!";
        } else if (lastOnlineDiff.inHours == 1) {
          extraInfo += "Online 1 hour ago!";
        } else if (lastOnlineDiff.inHours > 1 && lastOnlineDiff.inHours < 24) {
          extraInfo += "Online ${lastOnlineDiff.inHours} hours ago!";
        } else if (lastOnlineDiff.inDays == 1) {
          extraInfo += "Online yesterday!";
        } else if (lastOnlineDiff.inDays > 1) {
          extraInfo += "Online ${lastOnlineDiff.inDays} days ago!";
        }
        if (_factionName != "None" && _factionName != "") {
          extraInfo += "\nBelongs to faction $_factionName";
        }
      }
    }

    // Do nothing if note is empty
    if (_chainingPayload.attackNotesList[_attackNumber].isEmpty &&
        !_chainingPayload.showBlankNotes &&
        extraInfo.isEmpty) {
      return;
    }

    BotToast.showCustomText(
      onlyOne: false,
      clickClose: true,
      ignoreContentClick: true,
      duration: Duration(seconds: 5),
      toastBuilder: (textCancel) => Align(
        alignment: Alignment(0, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_chainingPayload.attackNotesList[_attackNumber].isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          MdiIcons.notebookOutline,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Note for ${_chainingPayload.attackNameList[_attackNumber]}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  if (_chainingPayload.attackNotesList[_attackNumber].isNotEmpty) SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${_chainingPayload.attackNotesList[_attackNumber]}$extraInfo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  clearCacheAndReload() async {
    await webView.clearCache();
    webView.loadUrl(urlRequest: URLRequest(url: WebUri("https://www.torn.com")));
  }

  _requestTornThemeChange({@required bool dark}) {
    webView.evaluateJavascript(
      source: '''
        var event = new CustomEvent("onChangeTornMode", {
          detail: { checked: $dark }
        });
        window.dispatchEvent(event);
      ''',
    );
  }

  updatePullToRefresh(BrowserRefreshSetting value) async {
    if (value == BrowserRefreshSetting.pull || value == BrowserRefreshSetting.both) {
      _pullToRefreshController.setEnabled(true);
    } else {
      _pullToRefreshController.setEnabled(false);
    }
  }

  bool _fullScreenAndWidgetHide() {
    return _webViewProvider.currentUiMode == UiMode.fullScreen && _settingsProvider.fullScreenRemovesWidgets;
  }

  void closeBrowserFromOutside() async {
    _webViewProvider.setCurrentUiMode(UiMode.window, context);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      _webViewProvider.browserShowInForeground = false;
      _checkIfTargetsAttackedAndRevertChaining();
    }
  }

  /// Updates attacked targets if we are in a chaining browser and then cancels the chain
  void _checkIfTargetsAttackedAndRevertChaining() {
    String message = "";
    if (_isChainingBrowser) {
      if (_chainingPayload.war && _lastAttackedMembers.length > 0) {
        message = '${_lastAttackedMembers.length} attacked targets will auto update in a few seconds!';
        _w.updateSomeMembersAfterAttack(lastAttackedMembers: _lastAttackedMembers);
        _lastAttackedMembers.clear();
      } else if (!_chainingPayload.war && _lastAttackedTargets.length > 0) {
        message = '${_lastAttackedTargets.length} attacked targets will auto update in a few seconds!';
        _targetsProvider.updateTargetsAfterAttacks(lastAttackedTargets: _lastAttackedTargets);
        _lastAttackedTargets.clear();
      }
    }

    if (message.isNotEmpty) {
      BotToast.showText(
        text: message,
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[800],
        duration: Duration(seconds: 4),
        contentPadding: EdgeInsets.all(10),
      );
    }
  }
}
