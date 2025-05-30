// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
//import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/main.dart';
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
import 'package:torn_pda/config/webview_config.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
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
import 'package:torn_pda/utils/html_parser.dart' as pda_parser;
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/webview/webview_handlers.dart';
import 'package:torn_pda/utils/webview/webview_utils.dart';
import 'package:torn_pda/widgets/bounties/bounties_widget.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/city/city_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/faction_crimes_widget.dart';
import 'package:torn_pda/widgets/dotted_border.dart';
import 'package:torn_pda/widgets/gym/steadfast_widget.dart';
import 'package:torn_pda/widgets/jail/jail_widget.dart';
import 'package:torn_pda/widgets/profile_check/profile_check.dart';
import 'package:torn_pda/widgets/quick_items/quick_items_widget.dart';
import "package:torn_pda/widgets/settings/userscripts_add_dialog.dart";
import 'package:torn_pda/widgets/trades/trades_widget.dart';
import 'package:torn_pda/widgets/vault/vault_widget.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:torn_pda/widgets/webviews/memory_widget_browser.dart';
import 'package:torn_pda/widgets/webviews/tabs_hide_reminder.dart';
import 'package:torn_pda/widgets/webviews/webview_shortcuts_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_terminal.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HealingPages {
  String? description;
  String? url;

  HealingPages({this.description}) {
    switch (description) {
      case "Personal":
        url = 'https://www.torn.com/item.php#medical-items';
      case "Faction":
        url = 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical';
    }
  }
}

class VaultsOptions {
  String? description;

  VaultsOptions({this.description}) {
    switch (description) {
      case "Personal vault":
        break;
      case "Faction vault":
        break;
      case "Company vault":
        break;
      case "Personal vault (new tab)":
        break;
      case "Faction vault (new tab)":
        break;
      case "Company vault (new tab)":
        break;
    }
  }
}

final chainingAidPopupChoices = <HealingPages>[
  HealingPages(description: "Personal"),
  HealingPages(description: "Faction"),
];

class WebViewFull extends StatefulWidget {
  final int? windowId;
  final String customTitle;
  final String? customUrl;
  //final bool dialog;
  final bool useTabs;
  final bool chatRemovalActive;
  final bool allowDownloads;

  @override
  final GlobalKey<WebViewFullState>? key;

  // Chaining
  final bool isChainingBrowser;
  final ChainingPayload? chainingPayload;

  const WebViewFull({
    this.windowId,
    this.customUrl = 'https://www.torn.com',
    this.customTitle = '',
    //this.dialog = false,
    this.useTabs = false,
    this.chatRemovalActive = false,
    this.allowDownloads = true,
    this.key,

    // Chaining
    this.isChainingBrowser = false,
    this.chainingPayload,
  }) : super(key: key);

  @override
  WebViewFullState createState() => WebViewFullState();
}

class WebViewFullState extends State<WebViewFull> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // DEBUG SCRIPT INJECTION (logs)
  final bool _debugScriptsInjection = false;

  InAppWebViewController? webViewController;
  var _initialWebViewSettings = InAppWebViewSettings();

  //int _loadTimeMill = 0;

  CookieManager cm = CookieManager.instance();

  bool _firstLoadRevertBackground = true;
  bool _firstLoadRestoreDownloads = true;

  // Allow navigation once even with a full locked page
  bool _forceAllowWhenLocked = false;
  bool _firstLoadCompleted = false;
  DateTime? _lastFullLockBackgroundTabOpen;

  URLRequest? _initialUrl;
  String? _pageTitle = "";
  String _currentUrl = '';

  bool _backButtonPopsContext = true;

  var _travelAbroad = false;
  var _travelHomeIconTriggered = false;

  var _crimesActive = false;
  final _crimesController = ExpandableController();

  Widget _gymExpandable = const SizedBox.shrink();

  var _tradesFullActive = false;
  var _tradesIconActive = false;
  Widget _tradesExpandable = const SizedBox.shrink();
  bool _tradesPreferencesLoaded = false;
  bool _tradeCalculatorEnabled = false;
  DateTime? _tradesOnResourceTriggerTime; // Null check afterwards (avoid false positives)

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
  DateTime? _vaultOnResourceTriggerTime; // Null check afterwards (avoid false positives)

  DateTime? _assessGymAndHuntingEnergyWarningTriggerTime;
  DateTime? _assessTravelAgencyEnergyNerveLifeWarningTriggerTime;

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
  DateTime? _quickItemsFactionOnResourceTriggerTime; // Null check afterwards (avoid false positives)

  // NNB is called from onPageVisit and onLoadStart, so API fetch and script activation have several checks
  DateTime? _nnbTriggeredTime;
  late DateTime _yataTriggeredTime;
  late DateTime _tsTriggeredTime;
  final _ocNnbController = ExpandableController();
  String _ocSource = "";

  Widget _jailExpandable = const SizedBox.shrink();
  DateTime? _jailOnResourceTriggerTime; // Null check afterwards (avoid false positives)
  JailModel? _jailModel;

  Widget _bountiesExpandable = const SizedBox.shrink();
  DateTime? _bountiesOnResourceTriggerTime; // Null check afterwards (avoid false positives)
  BountiesModel? _bountiesModel;

  DateTime? _urlTriggerTime;

  DateTime? _foreignStocksSentTime;

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

  final List<String> _lastAttackedTargets = <String>[];
  final List<String> _lastAttackedMembers = <String>[];

  UserDetailsProvider? _userProvider;
  final UserController _u = Get.find<UserController>();
  late TerminalProvider _terminalProvider;

  late WebViewProvider _webViewProvider;

  final _popupOptionsChoices = <VaultsOptions>[
    VaultsOptions(description: "Personal vault"),
    VaultsOptions(description: "Faction vault"),
    VaultsOptions(description: "Company vault"),
    VaultsOptions(description: "Personal vault (new tab)"),
    VaultsOptions(description: "Faction vault (new tab)"),
    VaultsOptions(description: "Company vault (new tab)"),
  ];

  bool _scrollAfterLoad = false;
  int? _scrollY = 0;
  int? _scrollX = 0;

  double _progress = 0;

  late SettingsProvider _settingsProvider;
  late UserScriptsProvider _userScriptsProvider;
  late ThemeProvider _themeProvider;

  PullToRefreshController? _pullToRefreshController;

  bool _findInPageActive = false;
  bool _wasFullScreenActiveWhenFindActivated = false;
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  var _findFirstSubmitted = false;
  var _findPreviousText = "";
  final _findInteractionController = Platform.isWindows ? null : FindInteractionController();

  bool _omitTabHistory = false;

  // This is only temporary by design - warning should not pop up only once, but it also doesn't need to be shown
  // every time the user reloads the page.
  bool _bugReportsWarningPrompted = false;

  // Chaining configuration
  bool _isChainingBrowser = false;
  ChainingPayload? _chainingPayload;

  final _chainWidgetController = ExpandableController();
  final _chainWidgetKey = GlobalKey();
  ChainStatusController _chainStatusProvider = Get.find<ChainStatusController>();
  late TargetsProvider _targetsProvider;
  WarController? _w;
  int _attackNumber = 0;
  String? _factionName = "";
  int? _lastOnline = 0;
  bool _nextButtonPressed = false;
  // Chaining configuration ends

  // Native Auth management
  late NativeUserProvider _nativeUser;
  late NativeAuthProvider _nativeAuth;

  // Time triggers for login error
  int _loginErrorRetrySeconds = 0;
  DateTime? _loginErrorToastTimer;

  // Showcases
  final GlobalKey _showCaseTitleBar = GlobalKey();
  final GlobalKey _showCaseCloseButton = GlobalKey();
  final GlobalKey _showCasePlayPauseChain = GlobalKey();
  final GlobalKey _showCaseTradeOptions = GlobalKey();

  final _scrollControllerBugsReport = ScrollController();

  bool _showMemoryWidget = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // We will later changed this for a listenable one in build()
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;

    _localChatRemovalActive = widget.chatRemovalActive;

    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    _nativeUser = context.read<NativeUserProvider>();
    _nativeAuth = context.read<NativeAuthProvider>();

    _initialUrl = URLRequest(url: WebUri(widget.customUrl!));

    _isChainingBrowser = widget.isChainingBrowser;
    if (_isChainingBrowser) {
      _chainingPayload = widget.chainingPayload;
      _w = Get.find<WarController>();
      String? title = _chainingPayload!.attackNameList[0];
      _pageTitle = title;
      // Decide if voluntarily skipping first target (always when it's a panic target)
      _assessFirstTargetsOnLaunch();
      if (_chainStatusProvider.watcherActive) {
        _chainWidgetController.expanded = true;
      }
      _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
      if (_chainingPayload!.war) {
        _lastAttackedMembers.clear();
        _lastAttackedMembers.add(_chainingPayload!.attackIdList[0]);
      } else {
        _lastAttackedTargets.clear();
        _lastAttackedTargets.add(_chainingPayload!.attackIdList[0]);
      }
    } else {
      _pageTitle = widget.customTitle;
    }

    _findController.addListener(onFindInputTextChange);

    _initialWebViewSettings = InAppWebViewSettings(
      cacheEnabled: _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
          ? _settingsProvider.webviewCacheEnabled
          : _settingsProvider.webviewCacheEnabledRemoteConfig == "on"
              ? true
              : false,
      transparentBackground: true,
      useOnLoadResource: true,
      useShouldOverrideUrlLoading: true,
      javaScriptCanOpenWindowsAutomatically: true,
      userAgent: Platform.isAndroid
          ? "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 "
              "Mobile Safari/537.36 ${WebviewConfig.agent} ${WebviewConfig.userAgentForUser}"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) "
              "CriOS/132.0.6834.100 Mobile/15E148 Safari/604.1 ${WebviewConfig.agent} ${WebviewConfig.userAgentForUser}",

      /// [useShouldInterceptAjaxRequest] This is deactivated sometimes as it interferes with
      /// hospital timer, company applications, etc. There is a bug on iOS if we activate it
      /// and deactivate it dynamically, where onLoadResource stops triggering!
      //useShouldInterceptAjaxRequest: false,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      cacheMode: _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
          ? _settingsProvider.webviewCacheEnabled
              ? CacheMode.LOAD_DEFAULT
              : CacheMode.LOAD_NO_CACHE
          : _settingsProvider.webviewCacheEnabledRemoteConfig == "on"
              ? CacheMode.LOAD_DEFAULT
              : CacheMode.LOAD_NO_CACHE,
      safeBrowsingEnabled: false,
      // [supportMultipleWindows]:
      // If enabled on iOS, it will trigger onCreateWindow but also browse
      // in the current tab. Android will only trigger onCreateWindow.
      supportMultipleWindows: Platform.isAndroid,
      initialScale: _settingsProvider.androidBrowserScale,
      useWideViewPort: false,
      allowsLinkPreview: _settingsProvider.iosAllowLinkPreview,
      disableLongPressContextMenuOnLinks: true,
      ignoresViewportScaleLimits: _settingsProvider.iosBrowserPinch,
      disallowOverScroll: _settingsProvider.iosDisallowOverscroll,
      overScrollMode: OverScrollMode.NEVER,
      // These two allow video playing for crimes
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      //
      useOnDownloadStart: widget.allowDownloads,
      minimumFontSize: Platform.isAndroid ? _settingsProvider.androidBrowserTextScale : 0,
    );

    _pullToRefreshController = Platform.isWindows
        ? null
        : PullToRefreshController(
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
      WidgetsBinding.instance.removeObserver(this);
      _findController.dispose();
      _findFocus.dispose();

      _chainWidgetController.dispose();
      _crimesController.dispose();
      _quickItemsController.dispose();
      _quickItemsFactionController.dispose();
      _ocNnbController.dispose();

      _scrollControllerBugsReport.dispose();

      webViewController?.dispose();

      super.dispose();
    } catch (e, t) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at WebviewFull dispose");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
      logToUser("PDA Crash at WebviewFull dispose: $e, $t");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isWindows) return;

    if (Platform.isAndroid) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        if (_webViewProvider.browserDoNotPauseWebview) return;
        webViewController?.pauseTimers();
      } else {
        webViewController?.resumeTimers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    _terminalProvider = Provider.of<TerminalProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);

    return ShowCaseWidget(
      builder: (_) {
        if (_webViewProvider.browserShowInForeground) {
          launchShowCases(_);
        }
        return buildScaffold(context);
      },
    );
  }

  // ! Ensure that any showcases here are also taken into account in the showcases in [webview_stackview.dart],
  // ! as the ones here need to fire first. Then only the others are allowed to fire.
  void launchShowCases(BuildContext _) {
    if (!_webViewProvider.browserShowInForeground) return;

    Future.delayed(const Duration(seconds: 1), () async {
      final List showCases = <GlobalKey<State<StatefulWidget>>>[];

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

      if (!_settingsProvider.showCases.contains("webview_tradesOptions")) {
        _settingsProvider.addShowCase = "webview_tradesOptions";
        showCases.add(_showCaseTradeOptions);
      }

      if (showCases.isNotEmpty) {
        ShowCaseWidget.of(_).startShowCase(showCases as List<GlobalKey<State<StatefulWidget>>>);
      }
    });
  }

  Widget buildScaffold(BuildContext context) {
    final bool dialog = _webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2;

    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        top: !dialog && !(_settingsProvider.fullScreenOverNotch && _webViewProvider.currentUiMode == UiMode.fullScreen),
        bottom:
            !dialog && !(_settingsProvider.fullScreenOverBottom && _webViewProvider.currentUiMode == UiMode.fullScreen),
        left: assessSafeAreaSide(dialog, "left"),
        right: assessSafeAreaSide(dialog, "right"),
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
                  if (_webViewProvider.currentUiMode == UiMode.window &&
                      _webViewProvider.bottomBarStyleEnabled &&
                      _webViewProvider.browserBottomBarStylePlaceTabsAtBottom)
                    _bottomBarStyleBottomBar(),
                  SizedBox(
                    height: !_webViewProvider.bottomBarStyleEnabled
                        ? 0
                        : _webViewProvider.hideTabs || !_settingsProvider.useTabsFullBrowser
                            ? 0
                            : 40,
                  ),
                  if (_webViewProvider.currentUiMode == UiMode.window &&
                      _webViewProvider.bottomBarStyleEnabled &&
                      !_webViewProvider.browserBottomBarStylePlaceTabsAtBottom)
                    _bottomBarStyleBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool assessSafeAreaSide(bool dialog, String safeSide) {
    if (safeSide == "left" &&
        _webViewProvider.webViewSplitActive &&
        _webViewProvider.splitScreenPosition == WebViewSplitPosition.right) {
      return false;
    } else if (safeSide == "right" &&
        _webViewProvider.webViewSplitActive &&
        _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
      return false;
    } else {
      if (!dialog) {
        if (!(_settingsProvider.fullScreenOverSides && _webViewProvider.currentUiMode == UiMode.fullScreen)) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
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
                if (_findInteractionController == null) return;
                setState(() {
                  _findInPageActive = false;
                });
                _findController.text = "";
                _findInteractionController!.clearMatches();
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
                padding: EdgeInsets.only(top: !_webViewProvider.webViewSplitActive ? 8 : 13),
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
                  descTextStyle: const TextStyle(fontSize: 13),
                  tooltipPadding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    child: Container(
                      color: Colors.transparent, // Background to extend the buttons detection area
                      child: Column(
                        children: [
                          if (!_webViewProvider.webViewSplitActive)
                            Column(
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
                              ],
                            ),
                          if ((_currentUrl.contains("www.torn.com/loader.php?sid=attack&user2ID=") ||
                                  _currentUrl.contains("www.torn.com/loader2.php?sid=getInAttack&user2ID=")) &&
                              _userProvider!.basic?.faction?.factionId != 0)
                            Text(
                              "ASSIST",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: !_webViewProvider.webViewSplitActive ? 7 : 12,
                              ),
                            )
                          else
                            Text(
                              "OPTIONS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _themeProvider.mainText,
                                fontSize: !_webViewProvider.webViewSplitActive ? 7 : 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      if (_webViewProvider.webViewSplitActive) {
                        openUrlDialog();
                        return;
                      }

                      if (!_webViewProvider.webViewSplitActive) {
                        _webViewProvider.browserShowInForeground = false;
                      }

                      _checkIfTargetsAttackedAndRevertChaining();
                    },
                  ),
                ),
              ),
            ),
            if (_isChainingBrowser)
              Row(children: _chainingActionButtons())
            else
              SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_settingsProvider.removeTravelQuickReturnButton) _travelHomeIcon(),
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
                    valueColor: AlwaysStoppedAnimation<Color?>(Colors.deepOrange[300]),
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
                  theme: const ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: const SizedBox.shrink(),
                  controller: _chainWidgetController,
                  header: const SizedBox.shrink(),
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
                          controller: webViewController,
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
                          inAppWebViewController: webViewController,
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
                          inAppWebViewController: webViewController,
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
                          controller: webViewController,
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
                          inAppWebViewController: webViewController,
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
                          inAppWebViewController: webViewController,
                          faction: true,
                        )
                      : const SizedBox.shrink(),
                )
              else
                const SizedBox.shrink(),
              // Terminal
              WebviewTerminal(
                webviewKey: widget.key,
                terminalProvider: _terminalProvider,
                webViewController: webViewController,
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
          webViewEnvironment: _webViewProvider.webViewEnvironment, // Only assigned in Windows
          initialSettings: _initialWebViewSettings,
          // EVENTS
          onWebViewCreated: (c) async {
            webViewController = c;

            // Clear cache (except for cookies) for each new session
            if (!_settingsProvider.webviewCacheEnabled && !Platform.isWindows) {
              await InAppWebViewController.clearAllCache();
            }

            // Userscripts initial load
            if (Platform.isAndroid || ((Platform.isIOS || Platform.isWindows) && widget.windowId == null)) {
              UnmodifiableListView<UserScript> handlersScriptsToAdd = _userScriptsProvider.getHandlerSources(
                apiKey: _userProvider?.basic?.userApiKey ?? "",
              );
              await webViewController!.addUserScripts(userScripts: handlersScriptsToAdd);

              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: _initialUrl!.url.toString(),
                pdaApiKey: _userProvider?.basic?.userApiKey ?? "",
                time: UserScriptTime.start,
              );
              await webViewController!.addUserScripts(userScripts: scriptsToAdd);
            } else if (Platform.isIOS && widget.windowId != null) {
              _terminalProvider.addInstruction(
                  widget.key,
                  "TORN PDA NOTE: iOS does not support user scripts injection in new windows (like this one), but only in "
                  "full webviews. If you are trying to run a script, close this tab and open a new one from scratch.");
            } else if (Platform.isWindows && widget.windowId != null) {
              _terminalProvider.addInstruction(
                  widget.key,
                  "TORN PDA NOTE: Windows does not support user scripts injection in new windows (like this one), but only in "
                  "full webviews. If you are trying to run a script, close this tab and open a new one from scratch.");
            }

            // ### HANDLERS ###

            WebviewHandlers.addTornPDACheckHandler(webview: webViewController!);

            // Copy to clipboard from the log doesn't work so we use a handler from JS fired from Torn
            WebviewHandlers.addCopyToClipboardHandler(webview: webViewController!);

            WebviewHandlers.addPageReloadHandler(webview: webViewController!);

            WebviewHandlers.addThemeChangeHandler(
              webview: webViewController!,
              setStateCallback: setState,
              themeProvider: _themeProvider,
              settingsProvider: _settingsProvider,
            );

            WebviewHandlers.addNotificationHandlers(
              webview: webViewController!,
              notificationsPlugin: FlutterLocalNotificationsPlugin(),
              assessNotificationPermissions: _assessNotificationPermissions,
            );

            WebviewHandlers.addLoadoutChangeHandler(
              webview: webViewController!,
              reloadCallback: _reload,
            );

            WebviewHandlers.addScriptApiHandlers(webview: webViewController!);

            WebviewHandlers.addToastHandler(webview: webViewController!);
          },
          shouldOverrideUrlLoading: (c, action) async {
            final incomingUrl = action.request.url.toString();

            // Handle external schemes
            if (!incomingUrl.startsWith("http:") &&
                !incomingUrl.startsWith("https:") &&
                !incomingUrl.startsWith("tornpda:")) {
              try {
                await launchUrl(Uri.parse(incomingUrl), mode: LaunchMode.externalApplication);
              } catch (e) {
                log("Error launching intent: $e");

                // Extract the scheme from the URI
                String errorMessage = "Cannot find a compatible app for this link!";
                String scheme = Uri.parse(incomingUrl).scheme;

                if (scheme.isNotEmpty) {
                  errorMessage = "Cannot find a compatible app for link $scheme:";
                }

                BotToast.showText(
                  text: errorMessage,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                  contentPadding: const EdgeInsets.all(10),
                  clickClose: true,
                );
              }
              return NavigationActionPolicy.CANCEL;
            }

            if (_settingsProvider.hitInMiniProfileOpensNewTab) {
              if (await _hitShouldOpenNewTab(c, action)) {
                return NavigationActionPolicy.CANCEL;
              }
            }

            // On Android, if we are in the trade page and the user received an update via
            // window.location.reload(), we need to reload the page manually
            // It comes as a standard request (which contains the same URL as the current one)
            if (Platform.isAndroid &&
                action.request.url.toString() == _currentUrl &&
                action.request.url.toString().contains("trade.php") &&
                action.request.url.toString().contains("step=view")) {
              _reload();
            }

            // If a tab is fully locked, cancel navigation
            // Note: the mini profiles consideration (above) should come first
            final lockedTabCancels = _lockedTabShouldCancelsNavigation(action.request.url);
            if (lockedTabCancels) return NavigationActionPolicy.CANCEL;

            if (Platform.isAndroid || ((Platform.isIOS || Platform.isWindows) && widget.windowId == null)) {
              // Userscripts load before webpage begins loading
              UnmodifiableListView<UserScript> handlersScriptsToAdd = _userScriptsProvider.getHandlerSources(
                apiKey: _userProvider?.basic?.userApiKey ?? "",
              );
              await webViewController!.addUserScripts(userScripts: handlersScriptsToAdd);

              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: incomingUrl,
                pdaApiKey: _userProvider?.basic?.userApiKey ?? "",
                time: UserScriptTime.start,
              );
              await webViewController!.addUserScripts(userScripts: scriptsToAdd);

              // DEBUG
              if (_debugScriptsInjection) {
                final addList = [];
                for (final s in scriptsToAdd) {
                  addList.add(s.groupName);
                }
                log("Added normal scripts in shouldOverride: $addList");
                log("Added handlers scripts in shouldOverride: $handlersScriptsToAdd");
              }
            }

            if (incomingUrl.contains("http://")) {
              _loadUrl(incomingUrl.replaceAll("http:", "https:"));
              return NavigationActionPolicy.ALLOW;
            }

            // Profiles images in Torn (also used in the forums) come with a ?v= parameter at the end which makes
            // the WKWebview download the image instantly (or load a null page if downloads are disabled). So we
            // just get rid of the ?v= parameter and load it again without it
            if (incomingUrl.contains("profileimages.torn.com")) {
              final correctedUrl = incomingUrl.replaceAll(RegExp(r'\?v=\d+'), '');
              if (incomingUrl != correctedUrl) {
                // The incomingUrl contains the ?v= part, so we cancel the navigation.
                _loadUrl(correctedUrl);
                return NavigationActionPolicy.CANCEL;
              } else {
                // The incomingUrl does not contain the ?v= part (probably as we reloaded it), so we allow it.
                return NavigationActionPolicy.ALLOW;
              }
            }

            // Check for content-type header to prevent loading of non-JS files.
            // Add anyway if there's no header, as it's probably a userscript.
            if (incomingUrl.endsWith(".user.js") &&
                (action.request.headers?["content-type"]?.contains("text/javascript") ?? true)) {
              // First look for existing script with this url
              final existingScript = _userScriptsProvider.userScriptList.firstWhereOrNull((s) => s.url == incomingUrl);
              late String message;
              if (existingScript != null) {
                message = "UserScript already exists, opening dialog...";
                showDialog(
                    context: context,
                    builder: (_) => UserScriptsAddDialog(
                          editExisting: true,
                          editScript: existingScript,
                          defaultPage: 1,
                          // No need for default URL as it already exists in the script object
                        ));
              } else {
                message = "UserScript detected, opening dialog...";
                showDialog(
                    builder: (_) => UserScriptsAddDialog(
                          editExisting: false,
                          defaultUrl: incomingUrl,
                          defaultPage: 1,
                        ),
                    context: context);
              }
              BotToast.showText(
                text: message,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.blue,
                duration: const Duration(seconds: 3),
                contentPadding: const EdgeInsets.all(10),
                clickClose: true,
              );
              return NavigationActionPolicy.CANCEL;
            }

            return NavigationActionPolicy.ALLOW;
          },
          onCreateWindow: (c, request) async {
            if (!mounted) return true;
            final String url = request.request.url.toString().replaceAll("http:", "https:");

            // If we are not using tabs in the current browser, just load the URL (otherwise, if we try
            // to open a window, a new tab is created but we can't see it and looks like a glitch)
            if (!_settingsProvider.useTabsFullBrowser) {
              _loadUrl(url);
            } else {
              // We will do our best to open the URL in a new full webview (instead of a window),
              // to ensure that we can use the same features as in the main webview. Otherwise we face
              // issues when removing userscripts, for example.

              // But there are certain cases where the URL comes as 'null' (like when trying to
              // perform a Google Login with Android in Torn, or when a script tries to create a new window

              // If that's the case, we'll allow to open a new window by passing the windowId
              // to the _openNewTabFromWindowRequest method, instead of the usual 'null' if the URL is valid

              dynamic windowId;
              if (request.request.url == null) {
                windowId = request.windowId;
              }

              _openNewTabFromWindowRequest(url, windowId);
              return true;
            }
            return true;
          },
          onCloseWindow: (controller) async {
            await Future.delayed(const Duration(seconds: 2));
            _webViewProvider.removeTab(calledFromTab: true);
          },
          onLoadStart: (c, uri) async {
            log("Start URL: $uri");
            //_loadTimeMill = DateTime.now().millisecondsSinceEpoch;

            _webViewProvider.updateLastTabUse();

            _webViewProvider.verticalMenuClose();
            if (!mounted) return;

            if (Platform.isAndroid) {
              _revertTransparentBackground();
            }

            try {
              _currentUrl = uri.toString();

              hideChatOnLoad();

              final html = await webViewController!.getHtml();
              final document = parse(html);

              // Checks URL for [_assessGeneral]
              logToUser(
                "URL on Load Start: $_currentUrl",
                backgroundcolor: Colors.blue,
                borderColor: Colors.white,
                duration: 8,
              );

              _assessGeneral(document);

              assessGymAndHuntingEnergyWarning(uri.toString());
              assessTravelAgencyEnergyNerveLifeWarning(uri.toString());
            } catch (e) {
              // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
              // the checks performed in this method
            }

            // Needs to be done as early as possible, but iOS does not like onLoadStart for this script
            if (Platform.isAndroid) {
              evaluateGreasyForMockVM(uri, c);
            }
          },
          onProgressChanged: (c, progress) async {
            if (!mounted) return;

            try {
              _removeTravelAirplaneIfEnabled(c);

              hideChatOnLoad();

              if (mounted) {
                setState(() {
                  _progress = progress / 100;
                });
              }

              if (progress > 75) {
                _pullToRefreshController!.endRefreshing();

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

            if (_settingsProvider.browserCenterEditingTextField &&
                // We also need to allow this from the Firebase Remote Config just
                // in case it interferes with other HTML elements
                _settingsProvider.browserCenterEditingTextFieldRemoteConfigAllowed) {
              c.evaluateJavascript(
                source: '''
                    window.addEventListener('focusin', (event) => {
                      const target = event.target;

                      // Check if the target is an <input> element
                      const isInput = target.tagName === 'INPUT';

                      // Avoid checkboxes (e.g.: when selecting messages)
                      const isCheckbox = target.className.includes('checkbox');

                      const shouldScroll = isInput && !isCheckbox;

                      if (shouldScroll) {
                        setTimeout(() => {
                          target.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        }, 300);
                      }
                    });
                  ''',
              );
            }

            _firstLoadCompleted = true;

            // Ensure that transparent background is set to false after first load
            // In iOS we do it after load stop, otherwise a white flash is trigger in any case
            if (Platform.isIOS) {
              _revertTransparentBackground();
            }

            // iOS will start a download when we browser to an image with 'open image in new tab'
            // To prevent this from happening, in those cases we will open a new webview with useOnDownloadRequest
            // disabled, only to re-enable it later when we have loaded the new tab
            if (Platform.isIOS && !widget.allowDownloads) {
              _revertDownloads();
            }

            try {
              _currentUrl = uri.toString();

              // Needs to be done as early as possible, but iOS does not like onLoadStart for this script
              if (Platform.isIOS) {
                evaluateGreasyForMockVM(uri, c);
              }

              // Userscripts remove those no longer necessary
              List<String?> scriptsToRemove = _userScriptsProvider.getScriptsToRemove(
                url: uri.toString(),
              );
              if (Platform.isAndroid || ((Platform.isIOS || Platform.isWindows) && widget.windowId == null)) {
                for (final group in scriptsToRemove) {
                  await c.removeUserScriptsByGroupName(groupName: group!);
                }
              }

              // DEBUG
              if (_debugScriptsInjection) {
                log("Removed scripts in loadStop: $scriptsToRemove");
              }

              // Userscripts add those that inject at the end
              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: uri.toString(),
                pdaApiKey: _userProvider?.basic?.userApiKey ?? "",
                time: UserScriptTime.end,
              );
              // We need to inject directly, otherwise these scripts will only load in the next page visit
              for (final script in scriptsToAdd) {
                await webViewController!.evaluateJavascript(source: script.source);
              }

              // DEBUG
              if (_debugScriptsInjection) {
                final addList = [];
                for (final s in scriptsToAdd) {
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

              final html = await webViewController!.getHtml();
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

              _assessTravel(document);
              _assessGeneral(document);

              // This is used in case the user presses reload. We need to wait for the page
              // load to be finished in order to scroll
              if (_scrollAfterLoad) {
                webViewController!.scrollTo(x: _scrollX!, y: _scrollY!);
                _scrollAfterLoad = false;
              }

              if (_settingsProvider.restoreSessionCookie) {
                if (_currentUrl.contains("torn.com")) {
                  Cookie? session = await cm.getCookie(url: WebUri("https://www.torn.com"), name: "PHPSESSID");
                  if (session != null) {
                    Prefs().setWebViewSessionCookie(session.value);
                  }
                }
              }

              if (_webViewProvider.pendingThemeSync.isNotEmpty && _settingsProvider.syncTornWebTheme) {
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
                    DateTime.now().difference(_tradesOnResourceTriggerTime!).inSeconds < 2) {
                  return;
                }
                _tradesOnResourceTriggerTime = DateTime.now();

                _tradesTriggered = true;
                final html = await webViewController!.getHtml();
                final document = parse(html);
                final pageTitle = (await _getPageTitle(document))!.toLowerCase();
                if (Platform.isIOS) {
                  // iOS needs this check because the full trade URL won't trigger in onLoadStop
                  _currentUrl = (await webViewController!.getUrl()).toString();
                }
                _assessTrades(document, pageTitle);
              }

              // Properties (vault) for initialization and live transactions
              if (resource.url.toString().contains("properties.php") ||
                  (_currentUrl.contains("properties.php") && !_vaultTriggered)) {
                // We only allow this to trigger once, otherwise it wants to load dozens of times and causes
                // the webView to freeze for a bit
                if (_vaultOnResourceTriggerTime != null &&
                    DateTime.now().difference(_vaultOnResourceTriggerTime!).inSeconds < 2) {
                  return;
                }
                _vaultOnResourceTriggerTime = DateTime.now();

                if (!_vaultTriggered) {
                  final html = await webViewController!.getHtml();
                  final document = parse(html);
                  final pageTitle = (await _getPageTitle(document))!.toLowerCase();
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
                    DateTime.now().difference(_jailOnResourceTriggerTime!).inMilliseconds < 500) {
                  return;
                }
                _jailOnResourceTriggerTime = DateTime.now();

                // iOS needs URL report in jail pages
                if (Platform.isIOS) {
                  final uri = await webViewController!.getUrl();
                  _reportUrlVisit(uri);
                }

                final html = await webViewController!.getHtml();
                dom.Document document = parse(html);

                late List<dom.Element> query;
                for (var i = 0; i < 2; i++) {
                  if (!mounted) break;
                  query = document.querySelectorAll(".users-list > li");
                  if (query.isNotEmpty) {
                    break;
                  } else {
                    await Future.delayed(const Duration(seconds: 1));
                    if (!mounted) break;
                    final updatedHtml = await webViewController!.getHtml();
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
                    DateTime.now().difference(_bountiesOnResourceTriggerTime!).inMilliseconds < 500) {
                  return;
                }
                _bountiesOnResourceTriggerTime = DateTime.now();

                // iOS needs URL report in jail pages
                if (Platform.isIOS) {
                  final uri = await webViewController!.getUrl();
                  _reportUrlVisit(uri);
                }

                final html = await webViewController!.getHtml();
                dom.Document document = parse(html);

                late List<dom.Element> query;
                for (var i = 0; i < 2; i++) {
                  if (!mounted) break;
                  query = document.querySelectorAll(".bounties-list > li");
                  if (query.isNotEmpty) {
                    break;
                  } else {
                    await Future.delayed(const Duration(seconds: 1));
                    if (!mounted) break;
                    final updatedHtml = await webViewController!.getHtml();
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
                    DateTime.now().difference(_quickItemsFactionOnResourceTriggerTime!).inSeconds < 1) {
                  return;
                }

                _quickItemsFactionOnResourceTriggerTime = DateTime.now();

                // We are not reporting the URL if we change tabs
                // (it does not work on desktop either)
                final uri = await webViewController!.getUrl();
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
                  !consoleMessage.message.contains("Blocked a frame with origin") &&
                  !consoleMessage.message.contains("has been blocked by CORS policy") &&
                  !consoleMessage.message.contains("SecurityError: Failed to register a ServiceWorker") &&
                  !consoleMessage.message.contains("Error with Permissions-Policy header") &&
                  !consoleMessage.message.contains("srcset") &&
                  !consoleMessage.message.contains("Missed ID for Quote saving")) {
                _terminalProvider.addInstruction(widget.key, consoleMessage.message);
                log("TORN PDA CONSOLE: ${consoleMessage.message}");
              }
            }
          },
          onLongPressHitTestResult: (controller, result) async {
            if (result.extra == null) return;
            await _assessLongPressOptions(result, controller);
          },
          onDownloadStartRequest: (controller, request) async {
            if (request.mimeType != null && request.mimeType!.contains("image/")) {
              // We don't want to download images automatically
              final String u = request.url.toString().replaceAll("http:", "https:");

              // Avoid downloading the same image many times in a loop
              if (u == _currentUrl) {
                final InAppWebViewSettings newSettings = (await webViewController!.getSettings())!;
                newSettings.useOnDownloadStart = false;
                webViewController!.setSettings(settings: newSettings);
                _firstLoadRestoreDownloads = false;
                loadImageWithBackground(controller, u);
                return;
              }

              _webViewProvider.addTab(url: u, allowDownloads: Platform.isIOS ? false : true);
              _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
              return;
            } else if (request.url.toString().startsWith("blob:")) {
              final response = await webViewController?.callAsyncJavaScript(
                  functionBody: "return fetch(url).then(r => r.text());", arguments: {"url": request.url.toString()});
              if (response == null || response.value == null) return;
              await _downloadData(response.value, fileName: request.suggestedFilename);
            } else {
              await _downloadRequest(autoRequest: request);
            }
          },
          // Reload webview after memory leak
          onWebContentProcessDidTerminate: (c) {
            c.reload();
          },
          onReceivedHttpAuthRequest: (c, challenge) async {
            TextEditingController usernameController = TextEditingController();
            TextEditingController passwordController = TextEditingController();

            bool proceed = false;
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Authentication Required'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(labelText: 'User'),
                      ),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Send'),
                      onPressed: () {
                        proceed = true;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );

            if (proceed) {
              return HttpAuthResponse(
                username: usernameController.text.trim(),
                password: passwordController.text.trim(),
                action: HttpAuthResponseAction.PROCEED,
                permanentPersistence: true,
              );
            }

            return HttpAuthResponse(
              action: HttpAuthResponseAction.CANCEL,
            );
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
              _pullToRefreshController!.beginRefreshing();
            }
          },
          onDoubleTap: () {
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

  _openNewTabFromWindowRequest(String url, int? windowId) {
    _webViewProvider.addTab(url: url, windowId: windowId);
    _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
  }

  _removeTravelAirplaneIfEnabled(InAppWebViewController c) async {
    if (_settingsProvider.removeAirplane) {
      if ((await c.getUrl()).toString() == "https://www.torn.com/page.php?sid=travel") {
        webViewController!.evaluateJavascript(source: travelRemovePlaneJS());
      }
    }
  }

  bool _lockedTabShouldCancelsNavigation(WebUri? incomingUrl) {
    if (incomingUrl == null) return false;

    if (_forceAllowWhenLocked) {
      return false;
    }

    if (!_firstLoadCompleted) return false;

    if (_webViewProvider.tabList[_webViewProvider.currentTab].isLocked &&
        _webViewProvider.tabList[_webViewProvider.currentTab].isLockFull) {
      // Let it load the first page (_currentUrl will be empty)
      if (_currentUrl.isNotEmpty) {
        // Check navigation exceptions
        for (var pair in _settingsProvider.lockedTabsNavigationExceptions) {
          final url1 = pair[0].trim();
          final url2 = pair[1].trim();

          if (url1.isEmpty || url2.isEmpty) continue;

          // Allow navigation if the current URL matches one of the URLs in the pair
          // and the incoming URL matches the other in the same pair
          if ((_currentUrl.contains(url1) && incomingUrl.toString().contains(url2)) ||
              (_currentUrl.contains(url2) && incomingUrl.toString().contains(url1))) {
            return false;
          }
        }

        // Allow movement across sections like hospital, forums, etc.
        if (_currentUrl.contains(incomingUrl.path)) {
          return false;
        }

        if (_settingsProvider.showTabLockWarnings) {
          if (_webViewProvider.lastLockToastShown == null ||
              DateTime.now().difference(_webViewProvider.lastLockToastShown!).inSeconds > 2) {
            _webViewProvider.lastLockToastShown = DateTime.now();
            toastification.show(
              closeOnClick: true,
              alignment: Alignment.bottomCenter,
              title: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    const Icon(Icons.lock, color: Colors.red),
                    const SizedBox(height: 30),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Text(
                          "Override!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      onTap: () {
                        toastification.dismissAll();
                        _forceAllowWhenLocked = true;
                        webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri.uri(incomingUrl)));
                        Future.delayed(const Duration(seconds: 2), () {
                          _forceAllowWhenLocked = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              autoCloseDuration: const Duration(seconds: 3),
              animationDuration: const Duration(milliseconds: 0),
              showProgressBar: false,
              style: ToastificationStyle.simple,
              borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
            );
          }
        }

        if (_settingsProvider.fullLockNavigationAttemptOpensNewTab) {
          if (_lastFullLockBackgroundTabOpen == null ||
              DateTime.now().difference(_lastFullLockBackgroundTabOpen!).inSeconds > 2) {
            _webViewProvider.addTab(url: incomingUrl.toString());
            _lastFullLockBackgroundTabOpen = DateTime.now();
          }
        }

        return true;
      }
    }
    return false;
  }

  Future<void> loadImageWithBackground(
    InAppWebViewController controller,
    String imageUrl,
  ) async {
    String backgroundColor = _themeProvider.currentTheme == AppTheme.light ? '#FFFFFF' : '#000000';

    final String html = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      body {
        margin: 0;
        background-color: $backgroundColor;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }
      img {
        max-width: 100%;
        max-height: 100%;
      }
    </style>
  </head>
  <body>
    <img src="$imageUrl" />
  </body>
</html>
''';

    await controller.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri(imageUrl),
    );
  }

  void evaluateGreasyForMockVM(WebUri? uri, InAppWebViewController c) {
    if (uri?.host == "greasyfork.org") {
      c.evaluateJavascript(
          source: greasyForkMockVM(jsonEncode(
              _userScriptsProvider.userScriptList.map((s) => ({"name": s.name, "version": s.version})).toList())));
    }
  }

  Future<void> _assessLongPressOptions(InAppWebViewHitTestResult result, InAppWebViewController controller) async {
    final String resultExtra = result.extra ?? '';
    final bool isDifferentUrl = resultExtra.replaceAll("#", "") != _currentUrl;

    final bool isAnchor = result.type == InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE;
    final bool isImageAnchor = result.type == InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE;
    final bool isImage = result.type == InAppWebViewHitTestResultType.IMAGE_TYPE;

    final bool isProfileLink = resultExtra.contains("https://www.torn.com/profiles.php?XID=");
    final bool isAwardImage = resultExtra.contains("awardimages");
    final bool isHonorImage = resultExtra.contains("images/honors");

    // Evaluate if the result requires handling via long-press card
    final bool shouldHandleAnchor =
        isDifferentUrl && ((isAnchor && !isProfileLink) || (isImageAnchor && !isAwardImage && !isHonorImage));

    final bool shouldHandleImage = (isImage || isImageAnchor) && !isHonorImage;

    if (shouldHandleAnchor || shouldHandleImage) {
      final RequestFocusNodeHrefResult? focus = await controller.requestFocusNodeHref();

      // Ensure valid URL or image source before displaying card
      if ((shouldHandleAnchor && focus?.url != null) || (shouldHandleImage && focus?.src != null)) {
        _showLongPressCard(focus?.src, focus?.url);
      }
    }
  }

  /// Analysis of hit elements to change navigation behavior
  Future<bool> _hitShouldOpenNewTab(
    InAppWebViewController c,
    NavigationAction request,
  ) async {
    var hitResult = await c.getHitTestResult();
    if (hitResult?.extra == null) return false;

    // Mini Profiles
    if (request.request.url.toString().contains("https://www.torn.com/profiles.php?") &&
        hitResult!.extra!.contains("https://www.torn.com/images/honors")) {
      // Check for image types based on platform (simplifies the IF above)
      if ((Platform.isAndroid && hitResult.type != InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE) ||
          (Platform.isIOS && hitResult.type != InAppWebViewHitTestResultType.IMAGE_TYPE)) {
        return false;
      }

      final html = await webViewController?.getHtml();
      if (html == null || html.isEmpty) return false;
      final document = parse(html);
      final miniProfile = document.querySelector("[class*='profile-mini-_wrapper_']");
      if (miniProfile != null) {
        _webViewProvider.addTab(url: request.request.url.toString());
        if (_settingsProvider.hitInMiniProfileOpensNewTabAndChangeTab) {
          _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
        }
        return true;
      }
    }

    return false;
  }

  _addExtraHeightForPullToRefresh() {
    webViewController!.evaluateJavascript(source: addHeightForPullToRefresh());
  }

  Future removeAllUserScripts() async {
    if (Platform.isAndroid || ((Platform.isIOS || Platform.isWindows) && widget.windowId == null)) {
      try {
        await webViewController?.removeAllUserScripts();
      } catch (e) {
        log("Webview controller is null at userscripts removal");
      }
    }
  }

  Future assessErrorCases({dom.Document? document}) async {
    if (!_nativeUser.isNativeUserEnabled()) {
      return;
    }

    if (document == null) {
      final html = await webViewController?.getHtml();
      if (html == null || html.isEmpty) return;
      document = parse(html);
    }

    // If for some reason we are logged out of Torn, try to login again
    if (document.body!.innerHtml.contains("Email address or password incorrect") ||
        document.body!.innerHtml.contains("multiple failures from your IP address")) {
      BotToast.showText(
        clickClose: true,
        text: "Authentication error detected!\n\nIf you have inserted your username and password combination in Torn "
            "PDA's settings section, please verify that they are correct!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red,
        duration: const Duration(seconds: 6),
        contentPadding: const EdgeInsets.all(10),
      );
      return;
    }

    // If for some reason we are logged out of Torn, try to login again
    if (_nativeAuth.tryAutomaticLogins && document.querySelectorAll("[class*='logInWrap_']").isNotEmpty) {
      if (_loginErrorToastTimer == null || DateTime.now().difference(_loginErrorToastTimer!).inSeconds > 4) {
        if (_webViewProvider.browserShowInForeground) {
          BotToast.showText(
            text: "Trying to log back into Torn\n\n"
                "Please wait...!",
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.blue,
            duration: const Duration(seconds: 4),
            contentPadding: const EdgeInsets.all(10),
          );
        }
      }
      _loginErrorToastTimer = DateTime.now();

      // New attempts will be made in a row if unsuccessful, so make them wait longer
      // (this is the result of Torn going to an error page at first sometimes)
      _loginErrorRetrySeconds++;
      await Future.delayed(Duration(seconds: _loginErrorRetrySeconds));

      final newDoc = parse(await webViewController!.getHtml());
      if (newDoc.querySelectorAll("[class*='logInWrap_']").isEmpty ||
          newDoc.body!.innerHtml.contains("failures from your IP address")) {
        return;
      }

      final TornLoginResponseContainer loginResponse = await _nativeAuth.requestTornRecurrentInitData(
        context: context,
        loginData: GetInitDataModel(
          playerId: _userProvider!.basic!.playerId,
          sToken: _nativeUser.playerSToken,
        ),
      );

      if (loginResponse.success) {
        webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(loginResponse.authUrl)));
        await Future.delayed(const Duration(seconds: 4));
        _loginErrorRetrySeconds = 0;
      } else {
        BotToast.showText(
          text: "Browser error while authenticating: please log in again or verify your user / pass combination "
              "in the Settings section!",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.red,
          duration: const Duration(seconds: 4),
          contentPadding: const EdgeInsets.all(10),
        );
      }
    }
  }

  void _reportUrlVisit(Uri? uri) {
    // This avoids reporting url such as "https://www.torn.com/imarket.php#/0.5912994041327981", which are generated
    // when returning from a bazaar and go straight to the market, not allowing to return to the item search
    if (uri.toString().contains("imarket.php#/")) {
      final RegExp expHtml = RegExp(r"imarket\.php#\/[0-9||.]+$");
      final matches = expHtml.allMatches(uri.toString()).map((m) => m[0]);
      if (matches.isNotEmpty) {
        return;
      }
    }

    // For certain URLs (e.g. forums or personal stats in iOS) we might be reporting this twice.
    // Once from [onUpdateVisitedHistory] and again from [onResourceLoad].
    // There are also sections such as personal stats that trigger [onUpdateVisitedHistory] several times
    // when loading and when browsing backwards
    if (_urlTriggerTime != null && (DateTime.now().difference(_urlTriggerTime!).inSeconds) < 1.5) {
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
    final String hlMap = '[ "${_userProvider!.basic!.name}", ...${jsonEncode(_settingsProvider.highlightWordList)} ]';
    final String css = chatHighlightCSS(background: background, senderColor: senderColor);

    if (_settingsProvider.highlightChat) {
      webViewController!.evaluateJavascript(
        source: chatHighlightJS(highlights: hlMap),
      );

      if (!Platform.isWindows) {
        webViewController!.injectCSSCode(
          source: css,
        );
      } else {
        // Inject CSS using JavaScript
        final String jsToInjectCSS = '''
          (function() {
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = `$css`;
            document.head.appendChild(style);
          })();
        ''';

        webViewController!.evaluateJavascript(
          source: jsToInjectCSS,
        );
      }
    }
  }

  void hideChatOnLoad() {
    if ((_webViewProvider.chatRemovalEnabledGlobal && _localChatRemovalActive) ||
        _webViewProvider.chatRemovalWhileFullScreen) {
      webViewController!.evaluateJavascript(source: removeChatJS());
    }
  }

  void hideChatWhileFullScreen() {
    _localChatRemoveActiveBeforeFullScreen = _localChatRemovalActive;
    webViewController!.evaluateJavascript(source: removeChatJS());
  }

  void showChatAfterFullScreen() {
    _localChatRemovalActive = _localChatRemoveActiveBeforeFullScreen;
    if (!_localChatRemovalActive) {
      webViewController!.evaluateJavascript(source: restoreChatJS());
    }
  }

  CustomAppBar buildCustomAppBar() {
    if (_findInPageActive) {
      return CustomAppBar(
        genericAppBar: AppBar(
          elevation: _settingsProvider.appBarTop ? 2 : 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              if (_findInteractionController == null) return;

              setState(() {
                _findInPageActive = false;
              });

              if (_wasFullScreenActiveWhenFindActivated) {
                _webViewProvider.setCurrentUiMode(UiMode.fullScreen, context);
                _wasFullScreenActiveWhenFindActivated = false;
              }

              _findController.text = "";
              _findInteractionController!.clearMatches();
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
                    icon: const Icon(Icons.search, color: Colors.white),
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
                          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                          onPressed: () {
                            _findNext(forward: false);
                            _findFocus.unfocus();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
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

    final bool assistPossible = (_currentUrl.contains("www.torn.com/loader.php?sid=attack&user2ID=") ||
            _currentUrl.contains("www.torn.com/loader2.php?sid=getInAttack&user2ID=")) &&
        _userProvider!.basic?.faction?.factionId != 0;

    // Leading width calculation
    final bool hasBackIcon = !(_backButtonPopsContext && _webViewProvider.webViewSplitActive);
    final bool hasMemoryIcon = _settingsProvider.showMemoryInWebview;
    final int iconCount = (hasBackIcon ? 1 : 0) + (hasMemoryIcon ? 1 : 0);

    return CustomAppBar(
      onHorizontalDragEnd: (DragEndDetails details) {
        _goBackOrForward(details);
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
        primary: !_webViewProvider.webViewSplitActive,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leadingWidth: iconCount * 40,
        leading: !hasBackIcon && !hasMemoryIcon
            ? null
            : Row(
                children: [
                  if (hasBackIcon)
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: GestureDetector(
                        child: _backButtonPopsContext
                            ? const Icon(Icons.close, color: Colors.white)
                            : const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onTap: () async {
                          // Normal behavior is just to pop and go to previous page
                          if (_backButtonPopsContext) {
                            _webViewProvider.setCurrentUiMode(UiMode.window, context);
                            if (mounted) {
                              if (!_webViewProvider.webViewSplitActive) {
                                _webViewProvider.browserShowInForeground = false;
                              }

                              _checkIfTargetsAttackedAndRevertChaining();
                            }
                          } else {
                            // But we can change and go back to previous page in certain
                            // situations (e.g. when going for the vault while trading)
                            final backPossible = await webViewController!.canGoBack();
                            if (backPossible) {
                              webViewController!.goBack();
                            } else {
                              if (!mounted) return;
                              Navigator.pop(context);
                            }
                            _backButtonPopsContext = true;
                          }
                        },
                      ),
                    ),
                  if (hasMemoryIcon)
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: GestureDetector(
                        child: Icon(Icons.memory, color: _showMemoryWidget ? Colors.amber : null),
                        onTap: () {
                          _toggleMemoryWidget();
                        },
                      ),
                    ),
                ],
              ),
        title: GestureDetector(
          onTap: () {
            openUrlDialog();
          },
          onLongPress: () {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return WebviewShortcutsDialog(
                  inAppWebView: webViewController,
                );
              },
            );
          },
          child: LayoutBuilder(builder: (context, constraints) {
            // Layout builder to check the width of the app bar
            // and assess whether to show back/forward navigation buttons
            return Container(
              width: constraints.maxWidth,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (_showMemoryWidget)
                    Expanded(
                      child: DottedBorder(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: MemoryWidgetBrowser(),
                        ),
                        dashPattern: assistPossible ? const [1, 1] : const [1, 4],
                        color: assistPossible ? Colors.orange : Colors.white70,
                      ),
                    )
                  else
                    Flexible(
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
                            descTextStyle: const TextStyle(fontSize: 13),
                            tooltipPadding: const EdgeInsets.all(20),
                            child: _webViewProvider.tabList[_webViewProvider.currentTab].customName.isNotEmpty &&
                                    _webViewProvider.tabList[_webViewProvider.currentTab].customNameInTitle
                                ? Row(
                                    children: [
                                      const Icon(
                                        MdiIcons.text,
                                        size: 14,
                                        color: Colors.lime,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _webViewProvider.tabList[_webViewProvider.currentTab].customName,
                                        overflow: TextOverflow.fade,
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.white, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      if (assistPossible)
                                        Flexible(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "ASSIST",
                                                overflow: TextOverflow.fade,
                                                style: TextStyle(fontSize: 9, color: Colors.orange),
                                              ),
                                              Text(
                                                _pageTitle!,
                                                overflow: TextOverflow.fade,
                                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Flexible(
                                          child: Text(
                                            _pageTitle!,
                                            overflow: TextOverflow.fade,
                                            style: const TextStyle(fontSize: 16, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  if ((_settingsProvider.browserShowNavArrowsAppbar == "narrow" && constraints.maxWidth > 200) ||
                      (_settingsProvider.browserShowNavArrowsAppbar == "wide" && constraints.maxWidth > 400))
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: Colors.blueGrey,
                              onTap: () async {
                                await _tryGoBack();
                              },
                              child: SizedBox(
                                width: 40,
                                child: Icon(
                                  Icons.arrow_back_ios_outlined,
                                  color: _webViewProvider.returnBackPagesNumber() == 0 ? Colors.grey : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: Colors.blueGrey,
                              onTap: () async {
                                await _tryGoForward();
                              },
                              child: SizedBox(
                                width: 40,
                                child: Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  color: _webViewProvider.returnForwardPagesNumber() == 0 ? Colors.grey : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            );
          }),
        ),
        actions: _isChainingBrowser
            ? _chainingActionButtons()
            : <Widget>[
                _crimesMenuIcon(),
                _quickItemsMenuIcon(),
                if (!_settingsProvider.removeTravelQuickReturnButton) _travelHomeIcon(),
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

  void _toggleMemoryWidget() {
    _showMemoryWidget = !_showMemoryWidget;
    setState(() {});
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
                child: Icon(Icons.refresh,
                    color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white),
                onTap: () async {
                  try {
                    // Check if the webview is active
                    await webViewController!.getUrl();
                  } on FlutterError catch (e) {
                    if (e.message.contains("was used after being disposed")) {
                      _webViewProvider.rebuildUnresponsiveWebView(
                        isChainingBrowser: _isChainingBrowser,
                        chainingPayload: _chainingPayload,
                      );

                      logToUser(
                        "Found crashed browser, trying to rebuild!",
                        duration: 5,
                      );
                    }
                  }

                  if (!Platform.isWindows) {
                    _scrollX = await webViewController!.getScrollX();
                    _scrollY = await webViewController!.getScrollY();
                  }

                  await _reload();

                  if (!Platform.isWindows) {
                    _scrollAfterLoad = true;
                  }

                  BotToast.showText(
                    text: "Reloading...",
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.grey[600]!,
                    duration: const Duration(seconds: 1),
                    contentPadding: const EdgeInsets.all(10),
                  );
                },
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  _goBackOrForward(DragEndDetails details) async {
    bool rightToLeft = details.primaryVelocity! < 0;
    bool leftToRight = details.primaryVelocity! > 0;

    if (rightToLeft) {
      _settingsProvider.browserReverseNavitagtionSwipe ? _tryGoBack() : _tryGoForward();
    } else if (leftToRight) {
      _settingsProvider.browserReverseNavitagtionSwipe ? _tryGoForward() : _tryGoBack();
    }
  }

  Future _tryGoBack() async {
    _webViewProvider.verticalMenuClose();

    // It's much more precise to use the native implementation (when not using tabs),
    // since onLoadStop and onLoadResource won't trigger always and need exceptions
    if (widget.useTabs) {
      _webViewProvider.tryGoBack();
    } else {
      final bool success = await webViewController!.canGoBack();
      if (success) {
        await webViewController!.goBack();
      }
    }
  }

  Future _tryGoForward() async {
    _webViewProvider.verticalMenuClose();
    if (widget.useTabs) {
      _webViewProvider.tryGoForward();
    } else {
      final bool success = await webViewController!.canGoForward();
      if (success) {
        await webViewController!.goForward();
      }
    }
  }

  /// Note: several other modules are called in onProgressChanged, since it's
  /// faster. The ones here probably would not benefit from it.
  Future _assessGeneral(dom.Document document) async {
    _assessBackButtonBehavior();
    _assessBazaarOwn(document);
    _assessBazaarOthers(document);
    _assessBarsRedirect(document);
    _assessProfileAgeToWords();
    _assessBugReportsWarning();
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
        (!_currentUrl.contains('city.php') && (_cityTriggered || _cityIconActive))) {
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
      final html = await webViewController!.getHtml();
      if (html == null) return;

      doc = parse(html);
      pageTitle = (await _getPageTitle(doc))!.toLowerCase();

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
    } else if ((_currentUrl.contains("torn.com/profiles.php?XID=") ||
            _currentUrl.contains("torn.com/profiles.php?NID=")) &&
        _profileTriggered) {
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
      final history = (await webViewController!.getCopyBackForwardList())!;
      // Check if we have more than a single page in history (otherwise we don't come from Trades)
      if (history.currentIndex! > 0) {
        if (history.list![history.currentIndex! - 1].url.toString().contains('trade.php')) {
          _backButtonPopsContext = false;
        }
      }
    }
  }

  /// This will try first with H4 (works for most Torn sections) and revert
  /// to the URL if it doesn't find anything
  /// [showTitle] show ideally only be set to true in onLoadStop
  /// URLs might show up while loading the page in onProgressChange
  Future<String?> _getPageTitle(
    dom.Document document, {
    bool showTitle = false,
  }) async {
    String? title = '';

    dom.Element? h4 = document.querySelector(".content-title > h4");
    // Some desktop views might incorporate different elements for the title
    h4 ??= document.querySelector("[class^='titleContainer___'] h4");

    if (h4 != null) {
      title = pda_parser.HtmlParser.fix(h4.innerHtml.substring(0).trim());
    }

    if (h4 == null && showTitle) {
      title = (await webViewController!.getTitle())!;
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
    await webViewController!.evaluateJavascript(source: buyMaxAbroadJS());
  }

  Future _sendStockInformation(dom.Document document) async {
    final elements = document.querySelectorAll('.users-list > li');

    if (elements.isNotEmpty) {
      try {
        // Parse stocks
        final items = <ForeignStockOutItem>[];
        for (final el in elements) {
          int id = int.tryParse(el.querySelector(".details")!.attributes["itemid"]!) ?? 0;
          int quantity =
              int.tryParse(el.querySelector(".stck-amount")!.innerHtml.replaceAll(RegExp("[^0-9]"), "")) ?? 0;
          int cost = int.tryParse(el.querySelector(".c-price")!.innerHtml.replaceAll(RegExp("[^0-9]"), "")) ?? 0;

          if (id != 0 && cost != 0) {
            items.add(ForeignStockOutItem(id: id, quantity: quantity, cost: cost));
          }
        }

        final stockModel = ForeignStockOutModel(
          client: "Torn PDA",
          version: appVersion,
          authorName: "Manuito",
          authorId: 2225097,
          country: document.querySelector(".content-title > h4")!.text.trim().substring(0, 3).toLowerCase(),
          items: items,
        );

        Future<void> sendToYATA() async {
          String error = "";
          try {
            final response = await http
                .post(
                  Uri.parse('https://yata.yt/api/v1/travel/import/'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: foreignStockOutModelToJson(stockModel),
                )
                .timeout(const Duration(seconds: 8));

            log("YATA replied with status code ${response.statusCode}. Response: ${response.body}");
            if (response.statusCode != 200) {
              error = "Replied with status code ${response.statusCode}. Response: ${response.body}";
            }
          } catch (e) {
            log('Error sending request to YATA: $e');
            error = "Catched exception: $e";
          }

          if (error.isNotEmpty) {
            if (!Platform.isWindows) FirebaseCrashlytics.instance.log("Error sending Foreign Stocks to YATA");
            if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(error, null);
            logToUser("Error sending Foreign Stocks to YATA");
          }
        }

        Future<void> sendToPrometheus() async {
          String error = "";
          try {
            final response = await http
                .post(
                  Uri.parse('https://api.prombot.co.uk/api/travel'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: foreignStockOutModelToJson(stockModel),
                )
                .timeout(const Duration(seconds: 8));

            log("Prometeus replied with status code ${response.statusCode}. Response: ${response.body}");
            if (response.statusCode != 200) {
              error = "Replied with status code ${response.statusCode}. Response: ${response.body}";
            }
          } catch (e) {
            log('Error sending request to Prometheus: $e');
            error = "Catched exception: $e";
          }

          if (error.isNotEmpty) {
            if (!Platform.isWindows) FirebaseCrashlytics.instance.log("Error sending Foreign Stocks to Prometheus");
            if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError(error, null);
            logToUser("Error sending Foreign Stocks to Prometheus");
          }
        }

        if (stockModel.items.isEmpty) {
          log("Foreign stocks are empty!!");
          return;
        }

        // Avoid repetitive submissions
        if (_foreignStocksSentTime != null && (DateTime.now().difference(_foreignStocksSentTime!).inSeconds) < 3) {
          return;
        }
        _foreignStocksSentTime = DateTime.now();

        await Future.wait([
          sendToYATA(),
          sendToPrometheus(),
        ]);
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
                  contentColor: Colors.orange[800]!,
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
                await webViewController!.evaluateJavascript(source: travelReturnHomeJS());
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
        _gymExpandable = const GymWidget();
      });
    }
  }

  // TRADES
  Future _assessTrades(dom.Document document, String pageTitle) async {
    final easyUrl = _currentUrl.replaceAll('#', '').replaceAll('/', '').split('&');

    // Try to get the page title after the section loads
    if (_currentUrl.contains('trade') && pageTitle.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1500));
      final html = await webViewController!.getHtml();
      document = parse(html);
      pageTitle = (await _getPageTitle(document))!.toLowerCase();
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

      // This is a trade that was just finished (step=view instead of step=logview)
      // We hide the widget to avoid sides getting mixed up
      String? html = await webViewController!.getHtml();
      if (html != null && html.contains("The trade was accepted by")) {
        final nameBar = document.querySelector(".right .title-black")?.innerHtml ?? "";
        if (nameBar.contains("items traded")) {
          if (_tradesFullActive) {
            _toggleTradesWidget(active: false);
          }
          return;
        }
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
        final updatedHtml = await webViewController!.getHtml();
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
      sellerName = document.querySelector(".right .title-black")?.innerHtml ?? "";

      final sellerIdString = document.querySelectorAll("#trade-container .log li .desc a");
      for (final html in sellerIdString) {
        final RegExp regId = RegExp("XID=([0-9]+)");
        final matches = regId.allMatches(html.attributes["href"]!);
        final id = int.parse(matches.elementAt(0).group(1)!);
        if (id != _userProvider!.basic!.playerId) {
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
      tradeId = int.parse(matches.elementAt(0).group(1)!);
    } catch (e) {
      tradeId = 0;
    }

    // Activate trades widget
    _toggleTradesWidget(active: true);

    // Initialize trades provider, which in turn feeds the trades widget
    if (!mounted) return;
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    tradesProvider.updateTrades(
      playerId: _userProvider!.basic!.playerId!,
      playerName: _userProvider!.basic!.name!,
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
      tornExchangeActiveRemoteConfig: _settingsProvider.tornExchangeEnabledStatusRemoteConfig,
    );
  }

  void _toggleTradesWidget({required bool active}) {
    if (active) {
      if (mounted) {
        setState(() {
          _tradesFullActive = true;
          _tradesExpandable = TradesWidget(
            themeProv: _themeProvider,
            userProv: _userProvider,
            webView: webViewController,
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
          MdiIcons.cash100,
          color: _webViewProvider.bottomBarStyleEnabled ? _themeProvider.mainText : Colors.white,
        ),
        onSelected: _openVaultsOptions,
        itemBuilder: (BuildContext context) {
          return _popupOptionsChoices.map((VaultsOptions choice) {
            return PopupMenuItem<VaultsOptions>(
              value: choice,
              child: Row(
                children: [
                  Text(choice.description!),
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
      case "Faction vault":
        _loadUrl("https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate");
      case "Company vault":
        _loadUrl("https://www.torn.com/companies.php#/option=funds");
      case "Personal vault (new tab)":
        _webViewProvider.addTab(url: "https://www.torn.com/properties.php#/p=options&tab=vault");
      case "Faction vault (new tab)":
        _webViewProvider.addTab(url: "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate");
      case "Company vault (new tab)":
        _webViewProvider.addTab(url: "https://www.torn.com/companies.php#/option=funds");
    }
  }

  Widget _tradesMenuIcon() {
    if (_tradesIconActive) {
      return Showcase(
        key: _showCaseTradeOptions,
        title: 'Trading options!',
        description: '\nIf you are a trader, you can manage the different trading providers available in Torn PDA '
            'by tapping this icon (e.g.: Arson Warehouse and Torn Exchange)!\n\nThere\'s also additional options available, '
            'such as detailed profit information.\n\nIf you prefer, you can also deactivate the whole Trade Calculator '
            'widget to gain some space.',
        targetPadding: const EdgeInsets.all(10),
        disableMovingAnimation: true,
        textColor: _themeProvider.mainText,
        tooltipBackgroundColor: _themeProvider.secondBackground,
        descTextStyle: const TextStyle(fontSize: 13),
        tooltipPadding: const EdgeInsets.all(20),
        child: OpenContainer(
          transitionDuration: const Duration(milliseconds: 500),
          transitionType: ContainerTransitionType.fadeThrough,
          openBuilder: (BuildContext context, VoidCallback _) {
            return TradesOptions(
              playerId: _userProvider!.basic!.playerId,
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
        ),
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
  Future _decideIfCallTrades({dom.Document? doc, String pageTitle = ""}) async {
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
          _currentUrl = (await webViewController!.getUrl()).toString();
          final html = await webViewController!.getHtml();
          final d = parse(html);
          final t = (await _getPageTitle(d))!.toLowerCase();
          _assessTrades(d, t);
        }
      }
    }
  }

  // PROPERTIES
  Future _assessVault({dom.Document? doc, String pageTitle = "", bool fromReassess = false}) async {
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
    List<dom.Element>? allTransactions;
    for (var i = 0; i < 10; i++) {
      if (!mounted) break;
      allTransactions = doc!.querySelectorAll("ul.vault-trans-list > li:not(.title)");
      if (allTransactions.isNotEmpty) {
        break;
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) break;
        final updatedHtml = await webViewController!.getHtml();
        doc = parse(updatedHtml);
      }
    }

    if (allTransactions!.isEmpty) {
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
        playerId: _userProvider!.basic!.playerId,
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
    final html = await webViewController!.getHtml();
    final document = parse(html);
    final pageTitle = (await _getPageTitle(document))!.toLowerCase();
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
    late List<dom.Element> query;
    for (var i = 0; i < 30; i++) {
      if (!mounted) break;
      query = document.querySelectorAll("#map .leaflet-marker-pane *");
      if (query.isNotEmpty) {
        break;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) break;
        final updatedHtml = await webViewController!.getHtml();
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
        if (key == "src" && value.contains("/images/items/")) {
          mapItemsList.add(value.split("items/")[1].split("/")[0]);
        }
      });
    }

    // Pass items to widget (if nothing found, widget's list will be empty)
    try {
      final dynamic apiResponse = await ApiCallsV1.getItems();
      if (apiResponse is ItemsModel) {
        apiResponse.items!.forEach((key, value) {
          // Assign correct ids
          value.id = key;
        });
        final tornItems = apiResponse.items!.values.toList();
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
                controller: webViewController,
                cityItems: _cityItemsFound,
                error: _errorCityApi,
              );
            });
          }
        }
        webViewController!.evaluateJavascript(source: highlightCityItemsJS());
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
            padding: const EdgeInsets.all(8.0),
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
      await webViewController!.evaluateJavascript(source: addOthersBazaarFillButtonsJS());
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
                ? await webViewController!.evaluateJavascript(source: removeOwnBazaarFillButtonsJS())
                : await webViewController!.evaluateJavascript(source: addOwnBazaarFillButtonsJS());

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

  void _assessProfileAgeToWords() {
    if (_currentUrl.contains("www.torn.com/profiles.php?")) {
      webViewController?.evaluateJavascript(source: ageToWordsOnProfile());
    }
  }

  void _assessBugReportsWarning() {
    if (_currentUrl.contains("forums.php#/p=newthread&f=19&b=0&a=0") && !_bugReportsWarningPrompted) {
      _bugReportsWarningPrompted = true;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("WARNING"),
          content: Scrollbar(
            controller: _scrollControllerBugsReport,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollControllerBugsReport,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Torn PDA is a third-party application, and is not developed by Torn."),
                  const SizedBox(height: 10),
                  const Text("Please do not report PDA bugs here, as they will be closed by Torn staff. Any bugs "
                      "caused by the app should be reported to the developers via one of the buttons at"
                      "the bottom."),
                  const SizedBox(height: 10),
                  Text("Make sure that you have tested in "
                      "${Platform.isIOS ? "Safari" : "your system browser"}"
                      " first to see whether the issue persists. If you're not sure, reach out to us below."),
                  const SizedBox(height: 30),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      child: const Text("Forum Thread"),
                      onPressed: () {
                        _loadUrl("https://www.torn.com/forums.php#/p=threads&f=67&t=16163503");
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                        child: const Text("Discord"),
                        onPressed: () =>
                            launchUrl(Uri.parse("https://discord.gg/vyP23kJ"), mode: LaunchMode.externalApplication)),
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ])
                ]),
              ),
            ),
          ),
        ),
      );
    }
  }

  // ASSESS PROFILES
  Future _assessProfileAttack({required dom.Document document, String pageTitle = ""}) async {
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

            userId = int.parse(matches.elementAt(0).group(1)!);

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

            final result = await WebViewUtils.waitForElement(
              webViewController: webViewController!,
              selector: 'a.profile-image-wrapper[href*="XID="]',
              maxSeconds: 6,
              intervalSeconds: 1,
              returnElements: true,
            );

            if (result == null) throw ("No html tag found");

            document = result['document'] as dom.Document;
            final elements = result['elements'] as List<dom.Element>;
            final anchor = elements.first;
            final match = RegExp(r"XID=([^&]+)").firstMatch(anchor.attributes['href']!)!;
            userId = int.parse(match.group(1)!);

            setState(() {
              _profileAttackWidget = ProfileAttackCheckWidget(
                key: UniqueKey(),
                profileId: userId,
                apiKey: _userProvider?.basic?.userApiKey ?? "",
                profileCheckType: ProfileCheckType.profile,
                themeProvider: _themeProvider,
              );
            });
          }
        } catch (e, trace) {
          log("Issue locating NID user ID: $e, $trace", name: "Profile Check");
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
          userId = int.parse(matches.elementAt(0).group(1)!);
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

  Future _assessBarsRedirect(dom.Document document) async {
    final inTorn = _currentUrl.contains("torn.com");
    if (inTorn) {
      webViewController?.evaluateJavascript(
        source: barsDoubleClickRedirect(
          isIOS: Platform.isIOS,
        ),
      );
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
            webViewController!.evaluateJavascript(source: removeChatJS());
            _webViewProvider.reportChatRemovalChange(true, false);
            setState(() {
              _localChatRemovalActive = true;
            });
            _webViewProvider.verticalMenuClose();
          },
          onLongPress: () async {
            webViewController!.evaluateJavascript(source: removeChatJS());
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
              duration: const Duration(seconds: 2),
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
            webViewController!.evaluateJavascript(source: restoreChatJS());
            _webViewProvider.reportChatRemovalChange(false, false);
            setState(() {
              _localChatRemovalActive = false;
            });
            _webViewProvider.verticalMenuClose();
          },
          onLongPress: () async {
            webViewController!.evaluateJavascript(source: restoreChatJS());
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
              contentColor: Colors.grey[700]!,
              duration: const Duration(seconds: 2),
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

    if (Platform.isAndroid || Platform.isWindows) {
      UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
        url: webViewController!.getUrl().toString(),
        pdaApiKey: _userProvider?.basic?.userApiKey ?? "",
        time: UserScriptTime.start,
      );
      await webViewController!.addUserScripts(userScripts: scriptsToAdd);

      // DEBUG
      if (_debugScriptsInjection) {
        final addList = [];
        for (final s in scriptsToAdd) {
          addList.add(s.groupName);
        }
        log("Added scripts in Android reload: $addList");
      }

      webViewController!.reload();
    } else if (Platform.isIOS) {
      final currentURI = await webViewController!.getUrl();
      _loadUrl(currentURI.toString());
    }
  }

  Future reloadFromOutside() async {
    _scrollX = await webViewController!.getScrollX();
    _scrollY = await webViewController!.getScrollY();
    await _reload();
    _scrollAfterLoad = true;

    BotToast.showText(
      text: "Reloading...",
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.grey[600]!,
      duration: const Duration(seconds: 1),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Future<void> openUrlDialog() async {
    _webViewProvider.verticalMenuClose();
    final url = await webViewController!.getUrl();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return WebviewUrlDialog(
          title: _pageTitle,
          url: url.toString(),
          inAppWebview: webViewController,
          callFindInPage: _activateFindInPage,
          userProvider: _userProvider,
        );
      },
    );
  }

  void openCloseChainWidgetFromOutside() {
    _chainWidgetController.expanded ? _chainWidgetController.expanded = false : _chainWidgetController.expanded = true;
  }

  void _activateFindInPage(bool wasFullScreenActive) {
    setState(() {
      _findInPageActive = true;
    });
    _wasFullScreenActiveWhenFindActivated = wasFullScreenActive;
    _findFocus.requestFocus();
  }

  void _findAll() {
    if (_findInteractionController == null) return;
    if (_findController.text.isNotEmpty) {
      setState(() {
        _findFirstSubmitted = true;
      });
      _findInteractionController!.findAll(find: _findController.text);
    }
  }

  void _findNext({required bool forward}) {
    if (_findInteractionController == null) return;
    _findInteractionController!.findNext(forward: forward);
    if (_findFocus.hasFocus) _findFocus.unfocus();
  }

  void onFindInputTextChange() {
    if (_findController.text != _findPreviousText) {
      setState(() {
        _findFirstSubmitted = false;
      });
    }
  }

  // ASSESS GYM AND HUNTING WARNINGS FOR ENERGY
  Future assessGymAndHuntingEnergyWarning(String targetUrl) async {
    if (!mounted) return;

    if (_assessGymAndHuntingEnergyWarningTriggerTime != null &&
        DateTime.now().difference(_assessGymAndHuntingEnergyWarningTriggerTime!).inSeconds < 2) {
      return;
    }
    _assessGymAndHuntingEnergyWarningTriggerTime = DateTime.now();

    if (!_settingsProvider.warnAboutExcessEnergy && !_settingsProvider.warnAboutChains) return;

    final easyUrl = targetUrl.replaceAll('#', '');
    if (easyUrl.contains('www.torn.com/gym.php') || easyUrl.contains('index.php?page=hunting')) {
      final stats = await ApiCallsV1.getBarsAndPlayerStatus();
      if (stats is BarsStatusCooldownsModel) {
        var message = "";
        if (stats.chain!.current! > 10 && stats.chain!.cooldown == 0) {
          message = 'Caution: your faction is chaining!';
        } else if (stats.energy!.current! >= _settingsProvider.warnAboutExcessEnergyThreshold) {
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
              contentPadding: const EdgeInsets.all(10),
            );
          }
        }
      }
    }
  }

  // ASSESS GYM AND HUNTING WARNINGS FOR ENERGY
  Future assessTravelAgencyEnergyNerveLifeWarning(String targetUrl) async {
    if (!mounted) return;

    if (_assessTravelAgencyEnergyNerveLifeWarningTriggerTime != null &&
        DateTime.now().difference(_assessTravelAgencyEnergyNerveLifeWarningTriggerTime!).inSeconds < 2) {
      return;
    }
    _assessTravelAgencyEnergyNerveLifeWarningTriggerTime = DateTime.now();

    final easyUrl = targetUrl.replaceAll('#', '');
    if (easyUrl.contains('www.torn.com/travelagency.php')) {
      final stats = await ApiCallsV1.getBarsAndPlayerStatus();
      if (stats is! BarsStatusCooldownsModel) return;

      final List<Widget> warnRows = [];
      final List<Widget> cooldownRows = [];

      final energyCheck = _settingsProvider.travelEnergyExcessWarning;
      if (energyCheck) {
        final energyMin = _settingsProvider.travelEnergyRangeWarningThreshold.start ~/ 10 * 10;
        final energyMax = _settingsProvider.travelEnergyRangeWarningThreshold.end ~/ 10 * 10;

        final energyCurrent = stats.energy!.current!;
        final energyMaxUser = stats.energy!.maximum!;

        final isMaxOverThreshold = energyMax >= 110;

        final energyMinThreshold = (energyMin / 100) * energyMaxUser;
        final energyMaxThreshold = isMaxOverThreshold ? double.infinity : (energyMax / 100) * energyMaxUser;

        if (energyCurrent >= energyMinThreshold && energyCurrent <= energyMaxThreshold) {
          warnRows.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('images/icons/map/gym.png', width: 24),
                        const SizedBox(width: 20),
                        Flexible(
                          child: Text(
                            'Energy is too high '
                            '(${energyMax <= 100 ? "$energyMin% - $energyMax%" : "> $energyMin%"})!',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    child: Image.asset('images/icons/map/gym.png', width: 24, color: _themeProvider.mainText),
                    onTap: () {
                      _loadUrl("https://www.torn.com/gym.php");
                      toastification.dismissAll();
                    },
                  )
                ],
              ),
            ),
          );
        }
      }

      final nerveCheck = _settingsProvider.travelNerveExcessWarning;
      if (nerveCheck) {
        final nerveUserSelectedThreshold = _settingsProvider.travelNerveExcessWarningThreshold ~/ 10 * 10;
        final nerveCurrent = stats.nerve!.current!;
        final nerveMax = stats.nerve!.maximum!;
        final nerveWarningOnlyWhenAboveMax = nerveUserSelectedThreshold > 100;
        final nerveThresholdPercentage = (nerveUserSelectedThreshold / 100) * nerveMax;

        if ((nerveWarningOnlyWhenAboveMax && nerveCurrent > nerveMax) ||
            (!nerveWarningOnlyWhenAboveMax && nerveCurrent >= nerveThresholdPercentage)) {
          warnRows.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('images/icons/home/crimes.png', width: 24, color: Colors.red),
                        const SizedBox(width: 20),
                        Flexible(
                          child: Text(
                            'Nerve is too high '
                            '(${nerveUserSelectedThreshold ~/ 10 * 10 <= 100 ? "$nerveUserSelectedThreshold%" : "> max"})!',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    child: Image.asset('images/icons/home/crimes.png', width: 24, color: _themeProvider.mainText),
                    onTap: () {
                      _loadUrl("https://www.torn.com/loader.php?sid=crimes");
                      toastification.dismissAll();
                    },
                  )
                ],
              ),
            ),
          );
        }
      }

      final lifeCheck = _settingsProvider.travelLifeExcessWarning;
      if (lifeCheck) {
        final lifeUserSelectedThreshold = _settingsProvider.travelLifeExcessWarningThreshold ~/ 10 * 10;
        final lifeCurrent = stats.life!.current!;
        final lifeMax = stats.life!.maximum!;
        final lifeWarningOnlyWhenAboveMax = lifeUserSelectedThreshold > 100;
        final lifeThresholdPercentage = (lifeUserSelectedThreshold / 100) * lifeMax;

        if ((lifeWarningOnlyWhenAboveMax && lifeCurrent > lifeMax) ||
            (!lifeWarningOnlyWhenAboveMax && lifeCurrent >= lifeThresholdPercentage)) {
          warnRows.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('images/icons/heart.png', width: 24, color: Colors.blue),
                        const SizedBox(width: 20),
                        Flexible(
                          child: Text(
                            'Life is too high '
                            '(${lifeUserSelectedThreshold ~/ 10 * 10 <= 100 ? "$lifeUserSelectedThreshold%" : "> max"})!',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        child: Icon(Icons.inventory_2_outlined, size: 24, color: _themeProvider.mainText),
                        onTap: () {
                          _loadUrl("https://www.torn.com/item.php#medical-items");
                          toastification.dismissAll();
                        },
                      ),
                      if (stats.faction?.factionId != 0)
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            GestureDetector(
                              child: Image.asset('images/icons/faction.png', width: 20, color: _themeProvider.mainText),
                              onTap: () {
                                _loadUrl(
                                    "https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=medical");
                                toastification.dismissAll();
                              },
                            )
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }

      final drugsCooldownCheck = _settingsProvider.travelDrugCooldownWarning;
      if (drugsCooldownCheck) {
        if (stats.cooldowns!.drug == 0) {
          cooldownRows.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('images/icons/cooldowns/drug5.png', width: 24, color: Colors.grey),
                        const SizedBox(width: 20),
                        const Flexible(
                          child: Text(
                            'No drugs cooldown!',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        child: Icon(Icons.inventory_2_outlined, size: 24, color: _themeProvider.mainText),
                        onTap: () {
                          _loadUrl("https://www.torn.com/item.php#drugs-items");
                          toastification.dismissAll();
                        },
                      ),
                      if (stats.faction?.factionId != 0)
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            GestureDetector(
                              child: Image.asset('images/icons/faction.png', width: 20, color: _themeProvider.mainText),
                              onTap: () {
                                _loadUrl(
                                    "https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=drugs");
                                toastification.dismissAll();
                              },
                            )
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }

      final boosterCooldownCheck = _settingsProvider.travelBoosterCooldownWarning;
      if (boosterCooldownCheck) {
        if (stats.cooldowns!.booster == 0) {
          cooldownRows.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('images/icons/cooldowns/booster5.png', width: 24, color: Colors.grey),
                        const SizedBox(width: 20),
                        const Flexible(
                          child: Text(
                            'No booster cooldown!',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        child: Icon(Icons.inventory_2_outlined, size: 24, color: _themeProvider.mainText),
                        onTap: () {
                          _loadUrl("https://www.torn.com/item.php");
                          toastification.dismissAll();
                        },
                      ),
                      if (stats.faction?.factionId != 0)
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            GestureDetector(
                              child: Image.asset('images/icons/faction.png', width: 20, color: _themeProvider.mainText),
                              onTap: () {
                                _loadUrl("https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0");
                                toastification.dismissAll();
                              },
                            )
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }

      final walletMoneyCheck = _settingsProvider.travelWalletMoneyWarning;
      if (walletMoneyCheck) {
        if (stats.moneyOnhand != null && stats.moneyOnhand! < _settingsProvider.travelWalletMoneyWarningThreshold) {
          // Format threshold to show in the message
          final cash = formatBigNumbers(_settingsProvider.travelWalletMoneyWarningThreshold);
          warnRows.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.money, size: 24, color: Colors.green),
                        const SizedBox(width: 20),
                        Flexible(
                          child: Text(
                            'Low on cash! (< $cash)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stats.vaultAmount != null && stats.vaultAmount! > 0)
                    GestureDetector(
                      child: Icon(MdiIcons.safe, size: 24, color: _themeProvider.mainText),
                      onTap: () {
                        _loadUrl("https://www.torn.com/properties.php#/p=options&tab=vault");
                        toastification.dismissAll();
                      },
                    ),
                ],
              ),
            ),
          );
        }
      }

      if (warnRows.isNotEmpty || cooldownRows.isNotEmpty) {
        toastification.showCustom(
          autoCloseDuration: const Duration(seconds: 8),
          alignment: Alignment.center,
          builder: (BuildContext context, ToastificationItem holder) {
            return GestureDetector(
              onTap: () {
                toastification.dismiss(holder);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _themeProvider.cardColor,
                  border: Border.all(
                    color: Colors.orange.shade800,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'This could be a waste!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...warnRows,
                    if (warnRows.isNotEmpty && cooldownRows.isNotEmpty)
                      const SizedBox(
                        width: 50,
                        child: Divider(),
                      ),
                    ...cooldownRows,
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton(
                                onPressed: () {
                                  toastification.dismiss(holder);
                                },
                                child: Text(
                                  "CLOSE",
                                  style: TextStyle(color: _themeProvider.mainText, fontSize: 10),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    side: BorderSide(color: _themeProvider.mainText, width: 1.0),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  toastification.dismiss(holder);
                                  _settingsProvider.travelEnergyExcessWarning = false;
                                  _settingsProvider.travelNerveExcessWarning = false;
                                  _settingsProvider.travelLifeExcessWarning = false;
                                  _settingsProvider.travelDrugCooldownWarning = false;
                                  _settingsProvider.travelBoosterCooldownWarning = false;
                                  _settingsProvider.travelWalletMoneyWarning = false;
                                },
                                child: Text(
                                  "DISABLE",
                                  style: TextStyle(color: _themeProvider.mainText, fontSize: 10),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    side: BorderSide(color: _themeProvider.mainText, width: 1.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
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
          webview: webViewController,
          fireScriptCallback: _fireJailScriptCallback,
          playerName: _userProvider!.basic!.name!.toUpperCase(),
        );
      });
    }
    // Otherwise, we are changing pages or reloading. We just need to fire the script. Any changes in the script
    // while the widget is shown will be handled by the callback (which also triggers the script)
    else {
      _fireJailScriptCallback(_jailModel);
    }
  }

  void _fireJailScriptCallback(JailModel? jailModel) {
    if (jailModel == null) return;

    _jailModel = jailModel;
    webViewController!.evaluateJavascript(
      source: jailJS(
        filtersEnabled: _jailModel!.filtersEnabled,
        levelMin: _jailModel!.levelMin,
        levelMax: _jailModel!.levelMax,
        timeMin: _jailModel!.timeMin,
        timeMax: _jailModel!.timeMax,
        scoreMin: _jailModel!.scoreMin,
        scoreMax: _jailModel!.scoreMax,
        bailTicked: _jailModel!.bailTicked,
        bustTicked: _jailModel!.bustTicked,
        excludeSelf: _jailModel!.excludeSelf,
        excludeName: _jailModel!.excludeName,
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
          webview: webViewController,
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

  void _fireBountiesScriptCallback(BountiesModel? bountiesModel) {
    if (bountiesModel == null) return;

    _bountiesModel = bountiesModel;
    webViewController!.evaluateJavascript(
      source: bountiesJS(
        levelMax: _bountiesModel!.levelMax,
        removeNotAvailable: _bountiesModel!.removeRed,
      ),
    );
  }

  // ORGANIZED CRIMES NNB
  Future<void> _assessOCnnb(String calledUrl) async {
    if (_settingsProvider.playerInOCv2) return;

    if (_settingsProvider.naturalNerveBarSource == NaturalNerveBarSource.off) return;

    if (!calledUrl.contains("factions.php?step=your") || !calledUrl.contains("/tab=crimes")) {
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
    if (_nnbTriggeredTime != null && DateTime.now().difference(_nnbTriggeredTime!).inSeconds < 2) return;
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
          final String yataUrl = 'https://yata.yt/api/v1/faction/members/?key=${_u.alternativeYataKey}';
          final yataOCjson = await http.get(WebUri(yataUrl)).timeout(const Duration(seconds: 15));
          yataMembers = yataMembersModelFromJson(yataOCjson.body);
          Prefs().setNaturalNerveYataModel(yataMembersModelToJson(yataMembers));
          Prefs().setNaturalNerveYataTime(DateTime.now().millisecondsSinceEpoch);
        }

        yataMembers.members!.forEach((key, value) {
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
          final String tsUrl = 'https://www.tornstats.com/api/v2/${_u.alternativeTornStatsKey}/faction/crimes';
          final tsOCjson = await http.get(WebUri(tsUrl)).timeout(const Duration(seconds: 15));
          tsMembers = tornStatsMembersModelFromJson(tsOCjson.body);

          if (!tsMembers.status!) {
            BotToast.showText(
              text: "Could not load NNB from TornStats: ${tsMembers.message}",
              clickClose: true,
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.red[900]!,
              duration: const Duration(seconds: 5),
              contentPadding: const EdgeInsets.all(10),
            );
            return;
          }

          Prefs().setNaturalNerveTornStatsModel(tornStatsMembersModelToJson(tsMembers));
          Prefs().setNaturalNerveTornStatsTime(DateTime.now().millisecondsSinceEpoch);
        }

        tsMembers.members!.forEach((key, value) {
          // No need to account for unknown in TS, as the member won't be in the JSON (the script assigns 'unk')
          membersString += '"$key":"${value.naturalNerve}",';
        });
      }

      membersString += "}";

      // On iOS, when using the new menu icon for OC, the html doc does not respond for some reason
      // We just wait a second and then add the script (should not be noticeable)
      await Future.delayed(const Duration(milliseconds: 1000));
      webViewController!.evaluateJavascript(source: ocNNB(members: membersString, playerID: _u.playerId));
    } catch (e) {
      BotToast.showText(
        text: "Could not load NNB from $_ocSource: $e",
        clickClose: true,
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red[900]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  // Called from parent though GlobalKey state
  void loadFromExterior({required String? url, required bool omitHistory}) {
    _omitTabHistory = omitHistory;
    _loadUrl(url);
  }

  // Called from parent though GlobalKey state
  void convertToChainingBrowser({required ChainingPayload chainingPayload}) {
    _isChainingBrowser = true;
    _attackNumber = 0;
    _chainingPayload = chainingPayload;
    _w ??= Get.find<WarController>();
    String? title = chainingPayload.attackNameList[0];
    _pageTitle = title;
    _chainStatusProvider = Get.find<ChainStatusController>();
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

  /// Called from parent though GlobalKey state
  /// Do not call this directly, do it through the webview provider to ensure that the tab is also updated
  Future<void> cancelChainingBrowser() async {
    final html = await webViewController!.getHtml();
    final dom.Document document = parse(html);
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
      webViewController?.pause();
    }
  }

  Future<void> resumeThisWebview() async {
    if (Platform.isAndroid) {
      webViewController?.resume();
    } else if (Platform.isIOS) {
      webViewController?.resumeTimers();
    }

    // WkWebView on iOS might fail and return null after heavy load (memory, tabs, etc)
    try {
      Uri? resumedUrl = await webViewController?.getUrl();
      if (resumedUrl == null) {
        log("Reviving webView!");
        _webViewProvider.reviveUrl();
      }
    } catch (e) {
      _webViewProvider.reviveUrl();
    }
  }

  Future _loadUrl(String? inputUrl) async {
    if (webViewController == null) {
      return;
    }

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

    if (Platform.isAndroid || ((Platform.isIOS || Platform.isWindows) && widget.windowId == null)) {
      // Loads userscripts that are not triggered in shouldOverrideUrlLoading
      // (e.g.: when reloading a page or navigating back/forward)
      UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
        url: inputUrl,
        pdaApiKey: _userProvider?.basic?.userApiKey ?? "",
        time: UserScriptTime.start,
      );
      await webViewController?.addUserScripts(userScripts: scriptsToAdd);

      // DEBUG
      if (_debugScriptsInjection) {
        final addList = [];
        for (final s in scriptsToAdd) {
          addList.add(s.groupName);
        }
        log("Added scripts in _loadUrl: $addList");
      }
    }

    final uri = WebUri(inputUrl);
    webViewController!.loadUrl(urlRequest: URLRequest(url: uri));
  }

  String reportCurrentUrl() {
    return _currentUrl;
  }

  String? reportCurrentTitle() {
    return _pageTitle;
  }

  Future<void> _revertTransparentBackground() async {
    if (_firstLoadRevertBackground) {
      final InAppWebViewSettings newSettings = (await webViewController!.getSettings())!;
      newSettings.transparentBackground = false;
      webViewController!.setSettings(settings: newSettings);
      _firstLoadRevertBackground = false;
    }
  }

  Future<void> _revertDownloads() async {
    if (_firstLoadRestoreDownloads) {
      final InAppWebViewSettings newSettings = (await webViewController!.getSettings())!;
      newSettings.useOnDownloadStart = true;
      webViewController!.setSettings(settings: newSettings);
      _firstLoadRestoreDownloads = false;
    }
  }

  Future<void> setBrowserTextScale(int value) async {
    final InAppWebViewSettings newSettings = (await webViewController!.getSettings())!;
    newSettings.minimumFontSize = value;
    webViewController!.setSettings(settings: newSettings);
  }

  void _showLongPressCard(String? src, Uri? url) {
    BotToast.showCustomText(
      clickClose: true,
      crossPage: false,
      duration: const Duration(seconds: 5),
      toastBuilder: (textCancel) => Align(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              color: Colors.grey[700],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                      child: GestureDetector(
                        child: const Text(
                          "Copy link",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () {
                          final open = url?.toString() ?? src;
                          if (open == null) return;
                          Clipboard.setData(ClipboardData(text: open));
                          BotToast.showText(
                            text: "Link copied to the clipboard: $open",
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.grey[700]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                        },
                      ),
                    ),
                    if (src != null)
                      Column(
                        children: [
                          const SizedBox(width: 150, child: Divider(color: Colors.white)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: GestureDetector(
                              child: const Text(
                                "Open image in new tab",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              onTap: () async {
                                // If we are using tabs, add a tab
                                final String u = src.replaceAll("http:", "https:");
                                _webViewProvider.addTab(url: u, allowDownloads: Platform.isIOS ? false : true);
                                _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
                                textCancel();
                              },
                            ),
                          ),
                        ],
                      ),
                    if (src != null)
                      Column(
                        children: [
                          const SizedBox(width: 150, child: Divider(color: Colors.white)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: GestureDetector(
                              child: const Text(
                                "Download image",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              onTap: () async {
                                await _downloadRequest(dialogCancel: textCancel, manualSource: src);
                              },
                            ),
                          ),
                        ],
                      ),
                    if (_settingsProvider.useTabsFullBrowser)
                      Column(
                        children: [
                          const SizedBox(width: 150, child: Divider(color: Colors.white)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: GestureDetector(
                              child: const Text(
                                "Open link in new tab",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              onTap: () {
                                // If we are using tabs, add a tab
                                final String u = url.toString().replaceAll("http:", "https:");
                                _webViewProvider.addTab(url: u, allowDownloads: false);
                                if (_webViewProvider.automaticChangeToNewTabFromURL) {
                                  _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
                                }

                                textCancel();
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 150, child: Divider(color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                      child: GestureDetector(
                        child: const Text(
                          "Add as shortcut",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () async {
                          String? open = url?.toString() ?? src;

                          bool error = false;
                          if (open == null) error = true;
                          if (open != null) {
                            if (!open.contains("http")) {
                              error = true;
                            }
                          }

                          if (!error) {
                            final String u = open!.replaceAll("http:", "https:");
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
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.orange[800]!,
                              contentPadding: const EdgeInsets.all(10),
                            );
                          }
                          textCancel();
                        },
                      ),
                    ),
                    const SizedBox(width: 150, child: Divider(color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
                      child: GestureDetector(
                        child: const Text(
                          "External browser",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () async {
                          String? open = url?.toString() ?? src;
                          if (open != null) {
                            if (await canLaunchUrl(Uri.parse(open))) {
                              await launchUrl(Uri.parse(open), mode: LaunchMode.externalApplication);
                            }
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

  Future<String> _getDownloadFilePath(String fileName) async {
    if (Platform.isAndroid) {
      // If we share, use temporary directory (we will delete this upon every webview provider initialisation)
      if (_settingsProvider.downloadActionShare) {
        return "${(await getTemporaryDirectory()).path}/downloads/$fileName";
      } else {
        // If we save, use downloads directory unless it can't be found in Android (else, use the temp one)
        var temp = await getDownloadsDirectory();
        if (temp != null) {
          return "${temp.path}/$fileName";
        } else {
          return "${(await getTemporaryDirectory()).path}/downloads/$fileName";
        }
      }
    } else if (Platform.isIOS) {
      // iOS uses either the temp directory or the documents directory (which should always exist)
      if (_settingsProvider.downloadActionShare) {
        return "${(await getTemporaryDirectory()).path}/downloads/$fileName";
      } else {
        return "${(await getApplicationDocumentsDirectory()).path}/$fileName";
      }
    }
    return "";
  }

  Future<void> _downloadRequest({
    CancelFunc? dialogCancel,
    String? manualSource,
    DownloadStartRequest? autoRequest,
  }) async {
    final progressStream = StreamController<int>();
    final cancelToken = CancelToken();

    try {
      if (dialogCancel != null) {
        dialogCancel();
      }

      String url = "";
      String fileName = "";

      // If we come from the download dialog
      if (manualSource != null) {
        url = manualSource.replaceAll("http:", "https:");
        var uri = Uri.parse(url);
        String path = uri.path;
        fileName = path.substring(path.lastIndexOf('/') + 1);
      }
      // If we come from the onDownloadRequest
      else if (autoRequest != null) {
        url = autoRequest.url.toString().replaceAll("http:", "https:");
        fileName = autoRequest.suggestedFilename ?? "file";
      }

      // Get the correct path based on device
      String fileSavePath = await _getDownloadFilePath(fileName);

      var cancelToastCallback = BotToast.showCustomText(
        clickClose: false,
        crossPage: false,
        duration: null,
        toastBuilder: (hideToast) {
          return DownloadProgressToast(
            fileName: fileName,
            progress: progressStream.stream,
            cancelToken: cancelToken,
            cancelFunc: hideToast,
          );
        },
      );

      await Dio().download(
        url,
        fileSavePath,
        onReceiveProgress: (received, total) {
          int progress = ((received / total) * 100).toInt();
          progressStream.add(progress);
        },
        cancelToken: cancelToken,
      );

      // When the download is complete or an error occurs, dismiss and close the stream
      progressStream.close();
      cancelToastCallback();

      // Share the file
      if (_settingsProvider.downloadActionShare) {
        await Share.shareXFiles(
          [XFile(fileSavePath)],
          text: fileName,
          sharePositionOrigin: Rect.fromLTWH(
            0,
            0,
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height / 2,
          ),
        );
      }

      if (!_settingsProvider.downloadActionShare) {
        BotToast.showText(
          text: Platform.isIOS ? "Downloaded in app folder as $fileName" : "Downloaded as $fileSavePath",
          clickClose: true,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          duration: const Duration(seconds: 5),
          contentColor: Colors.blue[800]!,
          contentPadding: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      BotToast.showText(
        text: "Could not complete download: ${cancelToken.isCancelled ? "cancelled" : e}",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.orange[800]!,
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  Future<void> _downloadData(String data, {String? fileName}) async {
    try {
      final downloadPath = await _getDownloadFilePath(fileName ?? "file.txt");
      log("Downloading file ${fileName ?? "unnamed file"} to $downloadPath");
      final file = await File(downloadPath).create(recursive: true);
      await file.writeAsString(data);
      if (_settingsProvider.downloadActionShare) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: fileName,
          sharePositionOrigin: Rect.fromLTWH(
            0,
            0,
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height / 2,
          ),
        );
      } else {
        BotToast.showText(
          text: Platform.isIOS ? "Downloaded in app folder as $fileName" : "Downloaded as $downloadPath",
          clickClose: true,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          duration: const Duration(seconds: 5),
          contentColor: Colors.blue[800]!,
          contentPadding: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      BotToast.showText(
        text: "Could not complete download: $e",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.orange[800]!,
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  // Chaining menu
  List<Widget> _chainingActionButtons() {
    List<Widget> myButtons = [];

    //myButtons.add(_quickItemsMenuIcon());

    final Widget hideChatIcon = _webViewProvider.chatRemovalEnabledGlobal ? _hideChatIcon() : const SizedBox.shrink();
    myButtons.add(hideChatIcon);

    myButtons.add(_reloadIcon());

    myButtons.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          child: const Icon(MdiIcons.linkVariant),
          onTap: () {
            _chainWidgetController.expanded
                ? _chainWidgetController.expanded = false
                : _chainWidgetController.expanded = true;
          },
        ),
      ),
    );

    myButtons.add(_medicalActionButton());

    if (_attackNumber < _chainingPayload!.attackIdList.length - 1) {
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
      descTextStyle: const TextStyle(fontSize: 13),
      tooltipPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: Colors.orange,
            child: const Icon(MdiIcons.playPause, color: Colors.white),
            onTap: _nextButtonPressed ? null : nextChainAttack,
            onLongPress: () => _webViewProvider.cancelChainingBrowser(),
          ),
        ),
      ),
    );
  }

  Widget _endAttackButton() {
    return IconButton(
      icon: const Icon(MdiIcons.stop, color: Colors.white),
      onPressed: () {
        _webViewProvider.cancelChainingBrowser();
      },
    );
  }

  Widget _medicalActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: PopupMenuButton<HealingPages>(
        icon: const Icon(Icons.healing, color: Colors.white),
        onSelected: openHealingPage,
        itemBuilder: (BuildContext context) {
          return chainingAidPopupChoices.map((HealingPages choice) {
            return PopupMenuItem<HealingPages>(
              value: choice,
              child: Text(choice.description!),
            );
          }).toList();
        },
      ),
    );
  }

  Future<void> openHealingPage(HealingPages choice) async {
    String? goBackTitle = _pageTitle;
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

  Future<void> _assessFirstTargetsOnLaunch() async {
    if (_chainingPayload!.panic || (_settingsProvider.targetSkippingAll && _settingsProvider.targetSkippingFirst)) {
      // Counters for target skipping
      int targetsSkipped = 0;
      final originalPosition = _attackNumber;
      bool reachedEnd = false;
      final skippedNames = [];

      // We'll skip maximum of 10 targets
      for (var i = 0; i < 10; i++) {
        // Get the status of our next target
        final nextTarget = await ApiCallsV1.getTarget(playerId: _chainingPayload!.attackIdList[i]);

        if (nextTarget is TargetModel) {
          // If in hospital or jail (even in a different country), we skip
          if (nextTarget.status!.color == "red") {
            targetsSkipped++;
            skippedNames.add(nextTarget.name);
            _attackNumber++;
          }
          // If flying, we need to see if he is in a different country (if we are in the same
          // place, we can attack him)
          else if (nextTarget.status!.color == "blue") {
            final user = await ApiCallsV1.getTarget(playerId: _userProvider!.basic!.playerId.toString());
            if (user is TargetModel) {
              if (user.status!.description != nextTarget.status!.description) {
                targetsSkipped++;
                skippedNames.add(nextTarget.name);
                _attackNumber++;
              }
            }
          }
          // If we found a good target, we break here. But before, we gather
          // some more details if option is enabled
          else {
            if (_chainingPayload!.showOnlineFactionWarning) {
              _factionName = nextTarget.faction!.factionName;
              _lastOnline = nextTarget.lastAction!.timestamp;
            }
            break;
          }
          // If after looping we are over the target limit, it means we have reached the end
          // in which case we reset the position to the last target we attacked, and break
          if (_attackNumber >= _chainingPayload!.attackIdList.length) {
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
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );

        const nextBaseUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=';
        if (!mounted) return;
        await _loadUrl('$nextBaseUrl${_chainingPayload!.attackIdList[_attackNumber]}');
        if (_chainingPayload!.war) {
          _lastAttackedMembers.add(_chainingPayload!.attackIdList[_attackNumber]);
        } else {
          _lastAttackedTargets.add(_chainingPayload!.attackIdList[_attackNumber]);
        }

        setState(() {
          _pageTitle = '${_chainingPayload!.attackNameList[_attackNumber]}';
        });

        // Show note for next target
        if (_chainingPayload!.showNotes) {
          _showNoteToast();
        }

        return;
      }

      if (targetsSkipped > 0 && reachedEnd) {
        BotToast.showText(
          text: "No more targets, all remaining are either in jail, hospital or in a different "
              "country (${skippedNames.join(", ")})\n\nPress and hold the play/pause button to stop the chaining mode",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );

        return;
      }
    }

    // This will show the note of the first target, if applicable
    if (_chainingPayload!.showNotes) {
      if (_chainingPayload!.showOnlineFactionWarning) {
        final nextTarget = await ApiCallsV1.getTarget(playerId: _chainingPayload!.attackIdList[0]);
        if (nextTarget is TargetModel) {
          _factionName = nextTarget.faction!.factionName;
          _lastOnline = nextTarget.lastAction!.timestamp;
        }
      }
      _showNoteToast();
    }
  }

  /// Not to be used right after launch
  void nextChainAttack() {
    _launchNextAttack();

    if (_webViewProvider.webViewSplitActive) {
      _checkIfTargetsAttackedAndRevertChaining(split: true);
    }
  }

  /// Not to be used right after launch
  Future<void> _launchNextAttack() async {
    const nextBaseUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=';
    // Turn button grey
    setState(() {
      _nextButtonPressed = true;
    });

    if (_chainingPayload!.panic || _settingsProvider.targetSkippingAll) {
      // Counters for target skipping
      int targetsSkipped = 0;
      final originalPosition = _attackNumber;
      bool reachedEnd = false;
      final skippedNames = [];

      // We'll skip maximum of 8 targets
      for (var i = 0; i < 3; i++) {
        // Get the status of our next target
        final nextTarget = await ApiCallsV1.getTarget(playerId: _chainingPayload!.attackIdList[_attackNumber + 1]);

        if (nextTarget is TargetModel) {
          // If in hospital or jail (even in a different country), we skip
          if (nextTarget.status!.color == "red") {
            targetsSkipped++;
            skippedNames.add(nextTarget.name);
            _attackNumber++;
          }
          // If flying, we need to see if he is in a different country (if we are in the same
          // place, we can attack him)
          else if (nextTarget.status!.color == "blue") {
            final user = await ApiCallsV1.getTarget(playerId: _userProvider!.basic!.playerId.toString());
            if (user is TargetModel) {
              if (user.status!.description != nextTarget.status!.description) {
                targetsSkipped++;
                skippedNames.add(nextTarget.name);
                _attackNumber++;
              }
            }
          }
          // If we found a good target, we break here. But before, we gather
          // some more details if option is enabled
          else {
            if (_chainingPayload!.showOnlineFactionWarning) {
              _factionName = nextTarget.faction!.factionName;
              _lastOnline = nextTarget.lastAction!.timestamp;
            }
            break;
          }
          // If after looping we are over the target limit, it means we have reached the end
          // in which case we reset the position to the last target we attacked, and break
          if (_attackNumber >= _chainingPayload!.attackIdList.length - 1) {
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
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      }

      if (targetsSkipped > 0 && reachedEnd) {
        BotToast.showText(
          text: "No more targets, all remaining are either in jail, hospital or in a different "
              "country (${skippedNames.join(", ")})\n\nPress and hold the play/pause button to stop the chaining mode",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
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
      if (_chainingPayload!.showOnlineFactionWarning) {
        final nextTarget = await ApiCallsV1.getTarget(playerId: _chainingPayload!.attackIdList[_attackNumber + 1]);

        if (nextTarget is TargetModel) {
          _factionName = nextTarget.faction!.factionName;
          _lastOnline = nextTarget.lastAction!.timestamp;
        } else {
          _factionName = "";
          _lastOnline = 0;
        }
      }
    }

    _attackNumber++;
    if (!mounted) return;
    await _loadUrl('$nextBaseUrl${_chainingPayload!.attackIdList[_attackNumber]}');
    if (_chainingPayload!.war) {
      _lastAttackedMembers.add(_chainingPayload!.attackIdList[_attackNumber]);
    } else {
      _lastAttackedTargets.add(_chainingPayload!.attackIdList[_attackNumber]);
    }
    setState(() {
      _pageTitle = '${_chainingPayload!.attackNameList[_attackNumber]}';
    });
    _backButtonPopsContext = true;

    // Turn button back to usable
    setState(() {
      _nextButtonPressed = false;
    });

    // Show note for next target
    if (_chainingPayload!.showNotes) {
      _showNoteToast();
    }
  }

  /// Use [onlyOne] when we want to get rid of several notes (e.g. to skip the very first target(s)
  /// without showing the notes for the ones skipped)
  void _showNoteToast() {
    Color? cardColor;
    switch (_chainingPayload!.attackNotesColorList[_attackNumber]) {
      case 'z':
        cardColor = Colors.grey[700];
      case 'green':
        cardColor = Colors.green[900];
      case 'orange':
        cardColor = Colors.orange[900];
      case 'red':
        cardColor = Colors.red[900];
      default:
        cardColor = Colors.grey[700];
    }

    String extraInfo = "";
    if (_lastOnline! > 0 && !_chainingPayload!.war) {
      final now = DateTime.now();
      final lastOnlineDiff = now.difference(DateTime.fromMillisecondsSinceEpoch(_lastOnline! * 1000));
      if (lastOnlineDiff.inDays < 7) {
        if (_chainingPayload!.attackNotesList[_attackNumber]!.isNotEmpty) {
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
    if (_chainingPayload!.attackNotesList[_attackNumber]!.isEmpty &&
        !_chainingPayload!.showBlankNotes &&
        extraInfo.isEmpty) {
      return;
    }

    BotToast.showCustomText(
      clickClose: true,
      ignoreContentClick: true,
      duration: const Duration(seconds: 5),
      toastBuilder: (textCancel) => Align(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_chainingPayload!.attackNotesList[_attackNumber]!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          MdiIcons.notebookOutline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Note for ${_chainingPayload!.attackNameList[_attackNumber]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  if (_chainingPayload!.attackNotesList[_attackNumber]!.isNotEmpty) const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${_chainingPayload!.attackNotesList[_attackNumber]}$extraInfo',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
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
    if (!Platform.isWindows) {
      await InAppWebViewController.clearAllCache();
    }
    CookieManager cookieManager = CookieManager.instance();
    cookieManager.deleteAllCookies();
    webViewController!.evaluateJavascript(
      source: '''
        localStorage.clear();
        console.log("Cleared cache and local storage!");
      ''',
    );
    webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri("https://www.torn.com")));
  }

  _requestTornThemeChange({required bool dark}) {
    webViewController!.evaluateJavascript(
      source: '''
        var event = new CustomEvent("onChangeTornMode", {
          detail: { checked: $dark }
        });
        window.dispatchEvent(event);
      ''',
    );
  }

  updatePullToRefresh(BrowserRefreshSetting? value) async {
    if (value == BrowserRefreshSetting.pull || value == BrowserRefreshSetting.both) {
      _pullToRefreshController!.setEnabled(true);
    } else {
      _pullToRefreshController!.setEnabled(false);
    }
  }

  bool _fullScreenAndWidgetHide() {
    return _webViewProvider.currentUiMode == UiMode.fullScreen && _settingsProvider.fullScreenRemovesWidgets;
  }

  Future<void> closeBrowserFromOutside() async {
    _webViewProvider.setCurrentUiMode(UiMode.window, context);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      if (!_webViewProvider.webViewSplitActive) {
        _webViewProvider.browserShowInForeground = false;
      }
      _checkIfTargetsAttackedAndRevertChaining();
    }
  }

  /// Updates attacked targets if we are in a chaining browser and then cancels the chain
  void _checkIfTargetsAttackedAndRevertChaining({bool split = false}) {
    String message = "";
    if (_isChainingBrowser) {
      if (_chainingPayload!.war && _lastAttackedMembers.isNotEmpty) {
        message = split
            ? 'Updating member'
            : '${_lastAttackedMembers.length} attacked targets will auto update in a few seconds!';
        _w!.updateSomeMembersAfterAttack(lastAttackedMembers: _lastAttackedMembers);
        _lastAttackedMembers.clear();
      } else if (!_chainingPayload!.war && _lastAttackedTargets.isNotEmpty) {
        message = split
            ? 'Updating target'
            : '${_lastAttackedTargets.length} attacked targets will auto update in a few seconds!';
        _targetsProvider.updateTargetsAfterAttacks(lastAttackedTargets: _lastAttackedTargets);
        _lastAttackedTargets.clear();
      }
    }

    if (message.isNotEmpty) {
      BotToast.showText(
        text: message,
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[800]!,
        duration: Duration(seconds: split ? 1 : 4),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  _assessNotificationPermissions() async {
    if (Platform.isAndroid) {
      await assessExactAlarmsPermissionsAndroid(context, _settingsProvider);
    }
  }
}

class DownloadProgressToast extends StatefulWidget {
  final String fileName;
  final Stream<int> progress;
  final CancelToken cancelToken;
  final VoidCallback cancelFunc;

  DownloadProgressToast({
    required this.fileName,
    required this.progress,
    required this.cancelToken,
    required this.cancelFunc,
  });

  @override
  DownloadProgressToastState createState() => DownloadProgressToastState();
}

class DownloadProgressToastState extends State<DownloadProgressToast> {
  late StreamSubscription<int> _subscription;
  int last = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.progress.listen((data) {
      setState(() {
        last = data;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void hideToast() {
    widget.cancelFunc();
  }

  void cancelDownload() {
    widget.cancelToken.cancel("User canceled download");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width - 80;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: screenWidth,
        padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[700],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 5),
              Text(
                widget.fileName,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: last / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Hide", style: TextStyle(color: Colors.white)),
                    onPressed: hideToast,
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    onPressed: cancelDownload,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
