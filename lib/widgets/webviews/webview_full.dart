// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:expandable/expandable.dart';
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
import 'package:speech_bubble/speech_bubble.dart';
import 'package:torn_pda/models/bounties/bounties_model.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
// Project imports:
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/jail/jail_model.dart';
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
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/bounties/bounties_widget.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/city/city_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/gym/steadfast_widget.dart';
import 'package:torn_pda/widgets/jail/jail_widget.dart';
import 'package:torn_pda/widgets/other/profile_check.dart';
import 'package:torn_pda/widgets/quick_items/quick_items_widget.dart';
import 'package:torn_pda/widgets/trades/trades_widget.dart';
import 'package:torn_pda/widgets/vault/vault_widget.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:torn_pda/widgets/webviews/tabs_hide_reminder.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final Function customCallBack;
  final bool dialog;
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
    this.customCallBack,
    this.dialog = false,
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

  var _quickItemsActive = false;
  var _quickItemsFactionActive = false;
  final _quickItemsController = ExpandableController();
  final _quickItemsFactionController = ExpandableController();
  DateTime _quickItemsFactionOnResourceTriggerTime; // Null check afterwards (avoid false positives)

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

  Widget _profileAttackWidget = const SizedBox.shrink();
  var _lastProfileVisited = "";
  var _profileTriggered = false;
  var _attackTriggered = false;

  final _showOne = GlobalKey();
  UserDetailsProvider _userProvider;
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

  bool _clearCacheFirstOpportunity = false;

  bool _findInPageActive = false;
  final _findController = TextEditingController();
  final _findFocus = FocusNode();
  var _findFirstSubmitted = false;
  var _findPreviousText = "";
  final _findInteractionController = FindInteractionController();

  bool _omitTabHistory = false;

  // Chaining configuration
  bool _isChainingBrowser = false;
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

  // We need to destroy the webview before closing the dialog
  // See: https://github.com/flutter/flutter/issues/112542
  bool _dialogCloseButtonTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WebView.debugLoggingSettings.enabled = false;

    _localChatRemovalActive = widget.chatRemovalActive;

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _clearCacheFirstOpportunity = _settingsProvider.getClearCacheNextOpportunityAndReset;

    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    _initialUrl = URLRequest(url: WebUri(widget.customUrl));

    if (widget.isChainingBrowser) {
      _isChainingBrowser = true;
      _w = Get.put(WarController());
      String title = widget.chainingPayload.attackNameList[0];
      _pageTitle = title;
      // Decide if voluntarily skipping first target (always when it's a panic target)
      _assessFirstTargetsOnLaunch();
      _chainStatusProvider = context.read<ChainStatusProvider>();
      if (_chainStatusProvider.watcherActive) {
        _chainWidgetController.expanded = true;
      }
      _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
      if (widget.chainingPayload.war) {
        _w.lastAttackedTargets.clear();
        _w.lastAttackedTargets.add(widget.chainingPayload.attackIdList[0]);
      } else {
        _targetsProvider.lastAttackedTargets.clear();
        _targetsProvider.lastAttackedTargets.add(widget.chainingPayload.attackIdList[0]);
      }
    } else {
      _pageTitle = widget.customTitle;
    }

    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    _findController.addListener(onFindInputTextChange);

    _initialWebViewSettings = InAppWebViewSettings(
      cacheEnabled: false,
      transparentBackground: true,
      clearCache: _clearCacheFirstOpportunity,
      useOnLoadResource: true,
      useShouldOverrideUrlLoading: true,
      javaScriptCanOpenWindowsAutomatically: true,
      userAgent: Platform.isAndroid
          ? "Mozilla/5.0 (Linux; Android Torn PDA) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Version/4.0 Chrome/91.0.4472.114 Mobile Safari/537.36 ${WebviewConfig.agent}"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) "
              "CriOS/103.0.5060.54 Mobile/15E148 Safari/604.1 ${WebviewConfig.agent}",

      /// [useShouldInterceptAjaxRequest] This is deactivated sometimes as it interferes with
      /// hospital timer, company applications, etc. There is a but on iOS if we activate it
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
    );

    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.orange[800],
        size: PullToRefreshSize.DEFAULT,
        backgroundColor: _themeProvider.secondBackground,
        enabled: _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.icon || false,
        slingshotDistance: 150,
        distanceToTriggerSync: 150,
      ),
      onRefresh: () async {
        await reload();
      },
    );
  }

  @override
  void dispose() {
    webView = null;
    _findController.dispose();
    _chainWidgetController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    _terminalProvider = Provider.of<TerminalProvider>(context);

    return WillPopScope(
      onWillPop: _willPopCallback,
      // If we are launching from a dialog, it's important not to add the show case, in
      // case this is the first time, as there is no appBar to be found and it would
      // failed to open
      child: widget.dialog
          ? BubbleShowcase(
              // KEEP THIS UNIQUE
              bubbleShowcaseId: 'webview_dialog_showcase',
              // WILL SHOW IF VERSION CHANGED
              bubbleShowcaseVersion: 1,
              showCloseButton: false,
              doNotReopenOnClose: true,
              counterText: "",
              bubbleSlides: [
                AbsoluteBubbleSlide(
                  positionCalculator: (size) => const Position(),
                  child: AbsoluteBubbleSlideChild(
                    positionCalculator: (size) => Position(
                      top: size.height / 2,
                      left: (size.width - 200) / 2,
                    ),
                    widget: SpeechBubble(
                      width: 200,
                      nipHeight: 0,
                      color: Colors.green[800],
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'NEW!\n\n'
                          'Did you know?\n\n'
                          'Long press the bottom bar of the quick browser to open a '
                          'menu with additional options\n\n'
                          'GIVE IT A TRY!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              child: buildScaffold(context),
            )
          : BubbleShowcase(
              // KEEP THIS UNIQUE
              bubbleShowcaseId: 'webview_full_showcase',
              // WILL SHOW IF VERSION CHANGED
              bubbleShowcaseVersion: 2,
              showCloseButton: false,
              doNotReopenOnClose: true,
              counterText: "",
              bubbleSlides: [
                RelativeBubbleSlide(
                  shape: const Rectangle(spreadRadius: 10),
                  widgetKey: _showOne,
                  child: RelativeBubbleSlideChild(
                    direction: _settingsProvider.appBarTop ? AxisDirection.down : AxisDirection.up,
                    widget: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SpeechBubble(
                        nipLocation: _settingsProvider.appBarTop ? NipLocation.TOP : NipLocation.BOTTOM,
                        color: Colors.green[800],
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text(
                            'NEW!\n\n'
                            'Did you know?\n\n'
                            'Tap page title to open a menu with additional options\n\n'
                            'Swipe page title left/right to browse forward/back\n\n'
                            'GIVE IT A TRY!',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              child: buildScaffold(context),
            ),
    );
  }

  Widget buildScaffold(BuildContext context) {
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.of(context).orientation == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        top: _settingsProvider.appBarTop || true,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: widget.dialog
              // Show appBar only if we are not showing the webView in a dialog
              ? null
              : _settingsProvider.appBarTop
                  ? buildCustomAppBar()
                  : null,
          bottomNavigationBar: widget.dialog
              // Show appBar only if we are not showing the webView in a dialog
              ? null
              : !_settingsProvider.appBarTop
                  ? SizedBox(
                      height: AppBar().preferredSize.height,
                      child: buildCustomAppBar(),
                    )
                  : null,
          body: Container(
            // Background color for all browser widgets
            color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.grey[900],
            child: widget.dialog
                ? Column(
                    children: [
                      Expanded(child: mainWebViewColumn()),
                      _quickBrowserBottomBar(),
                    ],
                  )
                : mainWebViewColumn(),
          ),
        ),
      ),
    );
  }

  Widget _quickBrowserBottomBar() {
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
        onLongPress: () => _openUrlDialog(),
        onPanEnd: _settingsProvider.useTabsHideFeature && _settingsProvider.useTabsBrowserDialog
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
              width: 100,
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      splashColor: Colors.blueGrey,
                      child: const SizedBox(
                        width: 40,
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
                        width: 40,
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
                  onTap: () async {
                    setState(() {
                      _dialogCloseButtonTriggered = true;
                    });
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _travelHomeIcon(),
                  _crimesMenuIcon(),
                  _cityMenuIcon(),
                  _quickItemsMenuIcon(),
                  _vaultsPopUpIcon(),
                  _tradesMenuIcon(),
                  _vaultOptionsIcon(),
                  if (_webViewProvider.chatRemovalEnabledGlobal) _hideChatIcon() else const SizedBox.shrink(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.pull
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: Colors.blueGrey,
                              child: const Icon(Icons.refresh),
                              onTap: () async {
                                _scrollX = await webView.getScrollX();
                                _scrollY = await webView.getScrollY();
                                await reload();
                                _scrollAfterLoad = true;
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
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
        // Profile attack
        _profileAttackWidget,
        if (widget.isChainingBrowser)
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
        // Actual WebView
        Expanded(
          child: _dialogCloseButtonTriggered ? const SizedBox.shrink() : _mainWebViewStack(),
        ),
        // Widgets that go at the bottom if we have changes appbar to bottom
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
    );
  }

  Stack _mainWebViewStack() {
    return Stack(
      children: [
        InAppWebView(
          windowId: widget.windowId,
          initialUrlRequest: _initialUrl,
          initialUserScripts: _userScriptsProvider.getContinuousSources(
            apiKey: _userProvider.basic.userApiKey,
          ),
          pullToRefreshController: _pullToRefreshController,
          findInteractionController: _findInteractionController,
          initialSettings: _initialWebViewSettings,
          // EVENTS
          onWebViewCreated: (c) async {
            webView = c;
            _terminalProvider.terminal = "Terminal";

            // Userscripts initial load
            if (Platform.isAndroid || (Platform.isIOS && widget.windowId == null)) {
              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
              url: _initialUrl.url.toString(),
              apiKey: _userProvider.basic.userApiKey,
              time: UserScriptTime.start,
              );
              await webView.addUserScripts(userScripts: scriptsToAdd);
            } else if (Platform.isIOS && widget.windowId != null) {
              _terminalProvider.addInstruction("TORN PDA NOTE: iOS does not support user scripts injection in new windows (like this one), but only in "
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
                  if (_settingsProvider.themeToSync == "dark") {
                    _themeProvider.changeTheme = AppTheme.dark;
                    log("Web theme changed to dark!");
                  } else {
                    _themeProvider.changeTheme = AppTheme.extraDark;
                    log("Web theme changed to extra dark!");
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
                      statusBarBrightness: Brightness.dark,
                      statusBarIconBrightness: Brightness.light,
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
              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: request.request.url.toString(),
                apiKey: _userProvider.basic.userApiKey,
                time: UserScriptTime.start,
              );
              await webView.addUserScripts(userScripts: scriptsToAdd);
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
            if ((widget.dialog && !_settingsProvider.useTabsBrowserDialog) ||
                (!widget.dialog && !_settingsProvider.useTabsFullBrowser)) {
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
          onCloseWindow: (controller) {
            _webViewProvider.removeTab(calledFromTab: true);
          },
          onLoadStart: (c, uri) async {
            log("Start URL: ${uri}");
            //_loadTimeMill = DateTime.now().millisecondsSinceEpoch;

            if (!mounted) return;

            if (Platform.isAndroid) {
              _revertTransparentBackground();
            }

            try {
              _currentUrl = uri.toString();

              final html = await webView.getHtml();

              _hideChat();

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

              _hideChat();

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

              // Userscripts add those that inject at the end
              UnmodifiableListView<UserScript> scriptsToAdd = _userScriptsProvider.getCondSources(
                url: uri.toString(),
                apiKey: _userProvider.basic.userApiKey,
                time: UserScriptTime.end,
              );
              // We need to inject directly, otherwise these scripts will only load in the next page visit
              for (var script in scriptsToAdd) {
                await webView.evaluateJavascript(
                  source: _userScriptsProvider.adaptSource(script.source, _userProvider.basic.userApiKey),
                );
              }

              _hideChat();
              _highlightChat();

              final html = await webView.getHtml();
              final document = parse(html);

              // Force to show title
              if (!_isChainingBrowser) {
                _pageTitle = await _getPageTitle(document, showTitle: true);
              }

              if (widget.useTabs) {
                //_reportUrlVisit(uri);
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
            } catch (e) {
              // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
              // the checks performed in this method
            }

            //log("Stop @ ${DateTime.now().millisecondsSinceEpoch - _loadTimeMill} ms");
          },
          onUpdateVisitedHistory: (c, uri, androidReload) async {
            if (!mounted) return;
            _reportUrlVisit(uri);
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
              if (!consoleMessage.message.contains("Refused to connect to ")) {
                _terminalProvider.addInstruction(consoleMessage.message);
                log("TORN PDA CONSOLE: ${consoleMessage.message}");
              }
            }
          },
          onLongPressHitTestResult: (controller, result) async {
            var focus = await controller.requestFocusNodeHref();

            if (result.extra != null) {
              // If not in this page already
              if (result.extra.replaceAll("#", "") != _currentUrl &&
                  // And the link does not go to a profile (in which case the mini profile opens)
                  (result.type == InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE &&
                          !result.extra.contains("https://www.torn.com/profiles.php?XID=") ||
                      // Or, if it goes to an image, it's not an award image (let mini profiles work)
                      (result.type == InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE &&
                          !result.extra.contains("awardimages")))) {
                _showLongPressCard(focus.src, focus.url);
              }
            }
          },
          /*
              shouldInterceptAjaxRequest: (InAppWebViewController c, AjaxRequest x) async {
                // VAULT EVENTS
                if (_vaultTriggered) {
                  if (x.data.toString().contains("step=vaultProperty&withdraw") ||
                      x.data.toString().contains("step=vaultProperty&deposit")) {
                    // Wait a couple of seconds to let the html load
                    Future.delayed(Duration(seconds: 2)).then((value) async {
                      // Reset _vaultTriggered so that we can call _assessVault() again
                      _reassessVault();
                    });
                  }
                }
            
                /*
                // This will intercept ajax calls performed when the bazaar reached 100 items
                // and needs to be reloaded, so that we can remove and add again the fill buttons
                if (x == null) return x;
                if (x.data == null) return x;
                if (x.url == null) return x;
            
                if (x.data.contains("step=getList&type=All&start=") &&
                    x.url.contains('inventory.php') &&
                    _bazaarActive &&
                    _bazaarFillActive) {
                  webView.evaluateJavascript(source: removeBazaarFillButtonsJS());
                  Future.delayed(const Duration(seconds: 2)).then((value) {
                    webView.evaluateJavascript(source: addBazaarFillButtonsJS());
                  });
                }
                */
            
                // MAIN AJAX REQUEST RETURN
                return x;
              },
              */
        ),
        // Some pages (e.g. travel or by double clicking a cooldown icon) don't have any scroll and the
        // pull to refresh does not trigger. In this case, we setup an area at the top, over Torn's top bar
        // which should not be pulled with normal use. By dragging there, we can pull in these situations.
        if (_settingsProvider.browserRefreshMethod != BrowserRefreshSetting.icon)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (_) async {
              await reload();
              _pullToRefreshController.beginRefreshing();
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
            reload();
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

  void _hideChat() {
    if (_webViewProvider.chatRemovalEnabledGlobal && _localChatRemovalActive) {
      webView.evaluateJavascript(source: removeChatOnLoadStartJS());
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
              if (widget.customCallBack != null) {
                widget.customCallBack();
              }
              Navigator.pop(context);
            } else {
              // But we can change and go back to previous page in certain
              // situations (e.g. when going for the vault while trading),
              // in which case we need to return to previous target
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
            _openUrlDialog();
          },
          child: DottedBorder(
            padding: const EdgeInsets.all(6),
            dashPattern: const [1, 4],
            color: Colors.white70,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Row(
                key: _showOne,
                children: [
                  Flexible(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.pull
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: Colors.orange,
                child: const Icon(Icons.refresh),
                onTap: () async {
                  _scrollX = await webView.getScrollX();
                  _scrollY = await webView.getScrollY();
                  await reload();
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
            )
          : const SizedBox.shrink(),
    );
  }

  Future _goBackOrForward(DragEndDetails details) async {
    if (details.primaryVelocity < 0) {
      await _tryGoForward();
    } else if (details.primaryVelocity > 0) {
      await _tryGoBack();
    }
  }

  Future _tryGoBack() async {
    bool success = false;

    // It's much more precise to use the native implementation (when not using tabs),
    // since onLoadStop and onLoadResource won't trigger always and need exceptions
    if (widget.useTabs) {
      success = _webViewProvider.tryGoBack();
    } else {
      success = await webView.canGoBack();
    }

    if (success) {
      BotToast.showText(
        text: "Back",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        text: "Can't go back!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  Future _tryGoForward() async {
    bool success = false;
    if (widget.useTabs) {
      success = _webViewProvider.tryGoForward();
    } else {
      success = await webView.canGoForward();
    }

    if (success) {
      await webView.goForward();
      BotToast.showText(
        text: "Forward",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        text: "Can't go forward!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  /// Note: several other modules are called in onProgressChanged, since it's
  /// faster. The ones here probably would not benefit from it.
  Future _assessGeneral(dom.Document document) async {
    _assessBackButtonBehavior();
    _assessTravel(document);
    _assessBazaarOwn(document);
    _assessBazaarOthers(document);
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

    if (_settingsProvider.extraPlayerInformation) {
      const profileUrl = 'torn.com/profiles.php?XID=';
      if ((!_currentUrl.contains(profileUrl) && _profileTriggered) ||
          (_currentUrl.contains(profileUrl) && !_profileTriggered) ||
          (_currentUrl.contains(profileUrl) && _currentUrl != _lastProfileVisited)) {
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
      if (getProfile) _assessProfileAttack();
      if (getAttack) _assessProfileAttack();
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
  /// [showTitle] show ideally only be set to true in onLoadStop, or full
  /// URLs might show up while loading the page in onProgressChange
  Future<String> _getPageTitle(
    dom.Document document, {
    bool showTitle = false,
  }) async {
    String title = '';
    final h4 = document.querySelector(".content-title > h4");
    if (h4 != null) {
      title = h4.innerHtml.substring(0).trim();
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
        return Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: Colors.blueGrey,
            child: const Icon(
              Icons.home,
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
        );
      } else {
        return Material(
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
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.fingerprint, color: widget.dialog ? _themeProvider.mainText : Colors.white),
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
        await Future.delayed(const Duration(seconds: 2));
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
        icon: const Icon(MdiIcons.cashUsdOutline),
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
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.accountSwitchOutline),
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
        isBrowserDialog: widget.dialog,
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
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.safeSquareOutline),
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
    if (!pageTitle.contains('city')) {
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
      final dynamic apiResponse = await TornApiCaller().getItems();
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
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.cityVariantOutline),
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
      await reload();
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
      return TextButton(
        onPressed: () async {
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
            color: _bazaarFillActive ? Colors.yellow[600] : Colors.white,
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
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return SizedBox(
            height: 20,
            width: 20,
            child: Image.asset('images/icons/quick_items.png',
                color: widget.dialog ? _themeProvider.mainText : Colors.white),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // ASSESS PROFILES
  Future _assessProfileAttack() async {
    if (mounted) {
      if (!_currentUrl.contains('loader.php?sid=attack&user2ID=') &&
          !_currentUrl.contains('loader2.php?sid=getInAttack&user2ID=') &&
          !_currentUrl.contains('torn.com/profiles.php?XID=')) {
        _profileTriggered = false;
        _profileAttackWidget = const SizedBox.shrink();
        return;
      }

      int userId = 0;

      if (_currentUrl.contains('torn.com/profiles.php?XID=')) {
        if (_profileTriggered && _currentUrl == _lastProfileVisited) {
          return;
        }
        _profileTriggered = true;
        _lastProfileVisited = _currentUrl;

        try {
          final RegExp regId = RegExp(r"php\?XID=([0-9]+)");
          final matches = regId.allMatches(_currentUrl);
          userId = int.parse(matches.elementAt(0).group(1));
          setState(() {
            _profileAttackWidget = ProfileAttackCheckWidget(
              key: UniqueKey(),
              profileId: userId,
              apiKey: _userProvider.basic.userApiKey,
              profileCheckType: ProfileCheckType.profile,
              themeProvider: _themeProvider,
            );
          });
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
              apiKey: _userProvider.basic.userApiKey,
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

  // HIDE CHAT
  Widget _hideChatIcon() {
    if (!_localChatRemovalActive) {
      return Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: const Icon(MdiIcons.chatOutline),
          onTap: () async {
            webView.evaluateJavascript(source: removeChatJS());
            _webViewProvider.reportChatRemovalChange(true, false);
            setState(() {
              _localChatRemovalActive = true;
            });
          },
          onLongPress: () async {
            webView.evaluateJavascript(source: removeChatJS());
            _webViewProvider.reportChatRemovalChange(true, true);
            setState(() {
              _localChatRemovalActive = true;
            });

            BotToast.showText(
              crossPage: false,
              text: "Default chat hide enabled",
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
        padding: const EdgeInsets.only(left: 15),
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
          },
          onLongPress: () async {
            webView.evaluateJavascript(source: restoreChatJS());
            _webViewProvider.reportChatRemovalChange(false, true);
            setState(() {
              _localChatRemovalActive = false;
            });

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

  Future reload() async {
    // Reset city so that it can be reloaded and icons don't disappear
    if (_cityTriggered) _cityTriggered = false;

    if (Platform.isAndroid) {
      webView.reload();
    } else if (Platform.isIOS) {
      var currentURI = await webView.getUrl();
      _loadUrl(currentURI.toString());
    }
  }

  Future<void> _openUrlDialog() async {
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
      final stats = await TornApiCaller().getBars();
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
        scoreMax: _jailModel.scoreMax,
        bailTicked: _jailModel.bailTicked,
        bustTicked: _jailModel.bustTicked,
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
        removeRed: _bountiesModel.removeRed,
      ),
    );
  }

  // Called from parent though GlobalKey state
  void loadFromExterior({@required String url, @required bool omitHistory}) {
    _omitTabHistory = omitHistory;
    _loadUrl(url);
  }

  void pauseWebview() {
    if (Platform.isAndroid) {
      webView?.pause();
    }
  }

  void resumeWebview() async {
    if (Platform.isAndroid) {
      webView?.resume();
    }

    // WkWebView on iOS might fail and return null after heavy load (memory, tabs, etc)
    Uri resumedUrl = await webView.getUrl();
    if (resumedUrl == null) {
      log("Reviving webView!");
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
        apiKey: _userProvider.basic.userApiKey,
        time: UserScriptTime.end,
      );
      await webView.addUserScripts(userScripts: scriptsToAdd);
    }

    var uri = WebUri(inputUrl);
    webView.loadUrl(urlRequest: URLRequest(url: uri));
  }

  Future<bool> _willPopCallback() async {
    _tryGoBack();
    return false;
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
                    if ((widget.dialog && _settingsProvider.useTabsBrowserDialog) ||
                        (!widget.dialog && _settingsProvider.useTabsFullBrowser))
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

    myButtons.add(_quickItemsMenuIcon());

    Widget hideChatIcon = _webViewProvider.chatRemovalEnabledGlobal ? _hideChatIcon() : SizedBox.shrink();
    myButtons.add(hideChatIcon);

    myButtons.add(_reloadIcon());

    myButtons.add(
      GestureDetector(
        child: Icon(MdiIcons.linkVariant),
        onTap: () {
          _chainWidgetController.expanded
              ? _chainWidgetController.expanded = false
              : _chainWidgetController.expanded = true;
        },
      ),
    );

    myButtons.add(_medicalActionButton());

    if (_attackNumber < widget.chainingPayload.attackIdList.length - 1) {
      myButtons.add(_nextAttackActionButton());
    } else {
      myButtons.add(_endAttackButton());
    }

    return myButtons;
  }

  Widget _nextAttackActionButton() {
    return IconButton(
      icon: Icon(Icons.skip_next),
      onPressed: _nextButtonPressed ? null : () => _launchNextAttack(),
    );
  }

  Widget _endAttackButton() {
    return IconButton(
      icon: Icon(MdiIcons.stop),
      onPressed: () {
        setState(() {
          _isChainingBrowser = false;
          _webViewProvider.cancelChainingBrowser();
        });
      },
    );
  }

  Widget _medicalActionButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
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
    if (widget.chainingPayload.panic ||
        (_settingsProvider.targetSkippingAll && _settingsProvider.targetSkippingFirst)) {
      // Counters for target skipping
      int targetsSkipped = 0;
      var originalPosition = _attackNumber;
      bool reachedEnd = false;
      var skippedNames = [];

      // We'll skip maximum of 3 targets
      for (var i = 0; i < 3; i++) {
        // Get the status of our next target
        var nextTarget = await TornApiCaller().getTarget(playerId: widget.chainingPayload.attackIdList[i]);

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
            var user = await TornApiCaller().getTarget(playerId: _userProvider.basic.playerId.toString());
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
            if (widget.chainingPayload.showOnlineFactionWarning) {
              _factionName = nextTarget.faction.factionName;
              _lastOnline = nextTarget.lastAction.timestamp;
            }
            break;
          }
          // If after looping we are over the target limit, it means we have reached the end
          // in which case we reset the position to the last target we attacked, and break
          if (_attackNumber >= widget.chainingPayload.attackIdList.length) {
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
        await _loadUrl('$nextBaseUrl${widget.chainingPayload.attackIdList[_attackNumber]}');
        if (widget.chainingPayload.war) {
          _w.lastAttackedTargets.add(widget.chainingPayload.attackIdList[_attackNumber]);
        } else {
          _targetsProvider.lastAttackedTargets.add(widget.chainingPayload.attackIdList[_attackNumber]);
        }

        setState(() {
          _pageTitle = '${widget.chainingPayload.attackNameList[_attackNumber]}';
        });

        // Show note for next target
        if (widget.chainingPayload.showNotes) {
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
    if (widget.chainingPayload.showNotes) {
      if (widget.chainingPayload.showOnlineFactionWarning) {
        var nextTarget = await TornApiCaller().getTarget(playerId: widget.chainingPayload.attackIdList[0]);
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

    if (widget.chainingPayload.panic || _settingsProvider.targetSkippingAll) {
      // Counters for target skipping
      int targetsSkipped = 0;
      var originalPosition = _attackNumber;
      bool reachedEnd = false;
      var skippedNames = [];

      // We'll skip maximum of 3 targets
      for (var i = 0; i < 3; i++) {
        // Get the status of our next target
        var nextTarget =
            await TornApiCaller().getTarget(playerId: widget.chainingPayload.attackIdList[_attackNumber + 1]);

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
            var user = await TornApiCaller().getTarget(playerId: _userProvider.basic.playerId.toString());
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
            if (widget.chainingPayload.showOnlineFactionWarning) {
              _factionName = nextTarget.faction.factionName;
              _lastOnline = nextTarget.lastAction.timestamp;
            }
            break;
          }
          // If after looping we are over the target limit, it means we have reached the end
          // in which case we reset the position to the last target we attacked, and break
          if (_attackNumber >= widget.chainingPayload.attackIdList.length - 1) {
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
      if (widget.chainingPayload.showOnlineFactionWarning) {
        var nextTarget =
            await TornApiCaller().getTarget(playerId: widget.chainingPayload.attackIdList[_attackNumber + 1]);

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
    await _loadUrl('$nextBaseUrl${widget.chainingPayload.attackIdList[_attackNumber]}');
    if (widget.chainingPayload.war) {
      _w.lastAttackedTargets.add(widget.chainingPayload.attackIdList[_attackNumber]);
    } else {
      _targetsProvider.lastAttackedTargets.add(widget.chainingPayload.attackIdList[_attackNumber]);
    }
    setState(() {
      _pageTitle = '${widget.chainingPayload.attackNameList[_attackNumber]}';
    });
    _backButtonPopsContext = true;

    // Turn button back to usable
    setState(() {
      _nextButtonPressed = false;
    });

    // Show note for next target
    if (widget.chainingPayload.showNotes) {
      _showNoteToast();
    }
  }

  /// Use [onlyOne] when we want to get rid of several notes (e.g. to skip the very first target(s)
  /// without showing the notes for the ones skipped)
  void _showNoteToast() {
    Color cardColor;
    switch (widget.chainingPayload.attackNotesColorList[_attackNumber]) {
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
    if (_lastOnline > 0 && !widget.chainingPayload.war) {
      var now = DateTime.now();
      var lastOnlineDiff = now.difference(DateTime.fromMillisecondsSinceEpoch(_lastOnline * 1000));
      if (lastOnlineDiff.inDays < 7) {
        if (widget.chainingPayload.attackNotesList[_attackNumber].isNotEmpty) {
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
    if (widget.chainingPayload.attackNotesList[_attackNumber].isEmpty &&
        !widget.chainingPayload.showBlankNotes &&
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
                  if (widget.chainingPayload.attackNotesList[_attackNumber].isNotEmpty)
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
                          'Note for ${widget.chainingPayload.attackNameList[_attackNumber]}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  if (widget.chainingPayload.attackNotesList[_attackNumber].isNotEmpty) SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${widget.chainingPayload.attackNotesList[_attackNumber]}$extraInfo',
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
}
