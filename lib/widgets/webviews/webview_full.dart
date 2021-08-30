// Dart imports:
import 'dart:async';
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
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
// Project imports:
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/jail/jail_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/pages/city/city_options.dart';
import 'package:torn_pda/pages/crimes/crimes_options.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:torn_pda/pages/trades/trades_options.dart';
import 'package:torn_pda/pages/vault/vault_options_page.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/city/city_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/jail/jail_widget.dart';
import 'package:torn_pda/widgets/other/profile_check.dart';
import 'package:torn_pda/widgets/quick_items/quick_items_widget.dart';
import 'package:torn_pda/widgets/trades/trades_widget.dart';
import 'package:torn_pda/widgets/vault/vault_widget.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';

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
  final String customTitle;
  final String customUrl;
  final Function customCallBack;
  final bool dialog;
  final bool useTabs;
  final bool chatRemovalActive;
  final GlobalKey<WebViewFullState> key;

  const WebViewFull({
    this.customUrl = 'https://www.torn.com',
    this.customTitle = '',
    this.customCallBack,
    this.dialog = false,
    this.useTabs = false,
    this.chatRemovalActive = false,
    this.key,
  }) : super(key: key);

  @override
  WebViewFullState createState() => WebViewFullState();
}

class WebViewFullState extends State<WebViewFull> with WidgetsBindingObserver {
  InAppWebViewController webView;
  var _initialWebViewOptions = InAppWebViewGroupOptions();

  URLRequest _initialUrl;
  String _pageTitle = "";
  String _currentUrl = '';

  bool _backButtonPopsContext = true;

  var _travelAbroad = false;
  var _travelHomeIconTriggered = false;

  var _crimesActive = false;
  final _crimesController = ExpandableController();

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
  final _quickItemsController = ExpandableController();

  Widget _jailExpandable = const SizedBox.shrink();
  DateTime _jailOnResourceTriggerTime; // Null check afterwards (avoid false positives)
  JailModel _jailModel;

  DateTime _forumsTriggerTime;
  DateTime _urlTriggerTime;

  // Allow onProgressChanged to call several sections, for better responsiveness,
  // while making sure that we don't call the API each time
  bool _crimesTriggered = false;
  bool _quickItemsTriggered = false;
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

  double progress = 0;

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

  bool _omitTabHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _localChatRemovalActive = widget.chatRemovalActive;

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _clearCacheFirstOpportunity = _settingsProvider.clearCacheNextOpportunity;

    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
    _initialUrl = URLRequest(url: Uri.parse(widget.customUrl));
    _pageTitle = widget.customTitle;

    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    _findController.addListener(onFindInputTextChange);

    _initialWebViewOptions = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        clearCache: _clearCacheFirstOpportunity,
        useOnLoadResource: true,

        /// [useShouldInterceptAjaxRequest] This is deactivated sometimes as it interferes with
        /// hospital timer, company applications, etc. There is a but on iOS if we activate it
        /// and deactivate it dynamically, where onLoadResource stops triggering!
        //useShouldInterceptAjaxRequest: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        supportMultipleWindows: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsLinkPreview: _settingsProvider.iosAllowLinkPreview,
      ),
    );

    _pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.orange[800],
        size: AndroidPullToRefreshSize.DEFAULT,
        backgroundColor: _themeProvider.background,
        enabled: _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.icon || false,
        slingshotDistance: 150,
        distanceToTriggerSync: 150,
      ),
      onRefresh: () async {
        await reload();
      },
    );

    //AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  @override
  void dispose() {
    webView = null;
    _findController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      webView.pauseTimers();
    } else {
      webView.resumeTimers();
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
          : Colors.grey[900],
      child: SafeArea(
        top: _settingsProvider.appBarTop || true,
        child: Scaffold(
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
            color: Colors.grey[900],
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
        color: _themeProvider.background,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                setState(() {
                  _findInPageActive = false;
                });
                _findController.text = "";
                webView.clearMatches();
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
      color: _themeProvider.currentTheme == AppTheme.light ? Colors.white : _themeProvider.background,
      height: 38,
      child: GestureDetector(
        onLongPress: () => _openUrlDialog(),
        onPanEnd: _settingsProvider.useTabsHideFeature && _settingsProvider.useTabsBrowserDialog
            ? (DragEndDetails details) async {
                _webViewProvider.toggleHideTabs();
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
                padding: const EdgeInsets.only(top: 2),
                child: GestureDetector(
                  child: Text(
                    "Close",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _themeProvider.mainText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _travelHomeIcon(),
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
            child: progress < 1.0
                ? LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.blueGrey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange[300]),
                  )
                : Container(height: 2),
          )
        else
          const SizedBox.shrink(),
        // Crimes widget. NOTE: this one will open at the bottom if
        // appBar is at the bottom, so it's duplicated below the actual
        // webView widget
        _profileAttackWidget,
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
                    appBarTop: _settingsProvider.appBarTop,
                    browserDialog: widget.dialog,
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
                    appBarTop: _settingsProvider.appBarTop,
                    browserDialog: widget.dialog,
                    webviewType: 'inapp',
                  )
                : const SizedBox.shrink(),
          )
        else
          const SizedBox.shrink(),
        // Trades widget
        _tradesExpandable,
        // Vault widget
        _vaultExpandable,
        // City widget
        _cityExpandable,
        // Jail widget
        _jailExpandable,
        // Actual WebView
        Expanded(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: _initialUrl,
                initialUserScripts: _userScriptsProvider.getContinuousSources(
                  apiKey: _userProvider.basic.userApiKey,
                ),
                // Temporarily deactivated as it is affecting chats
                pullToRefreshController: _pullToRefreshController,
                initialOptions: _initialWebViewOptions,
                // EVENTS
                onWebViewCreated: (c) {
                  webView = c;
                  _terminalProvider.terminal = "Terminal";
                },
                onCreateWindow: (c, request) {
                  if (!mounted) return;
                  // If we are not using tabs in the current browser, just load the URL (otherwise, if we try
                  // to open a window, a new tab is created but we can't see it and looks like a glitch)
                  if ((widget.dialog && !_settingsProvider.useTabsBrowserDialog) ||
                      (!widget.dialog && !_settingsProvider.useTabsFullBrowser)) {
                    _loadUrl(request.request.url.toString());
                  } else {
                    // If we are using tabs, add a tab
                    _webViewProvider.addTab(url: request.request.url.toString());
                    _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
                  }
                  return;
                },
                onLoadStart: (c, uri) async {
                  if (!mounted) return;

                  try {
                    _currentUrl = uri.toString();

                    // Userscripts
                    UserScriptChanges changes = _userScriptsProvider.getCondSources(
                      url: uri.toString(),
                      apiKey: _userProvider.basic.userApiKey,
                    );
                    if (Platform.isAndroid) {
                      // Not supported on iOS
                      for (var group in changes.scriptsToRemove) {
                        c.removeUserScriptsByGroupName(groupName: group);
                      }
                    }
                    await c.addUserScripts(userScripts: changes.scriptsToAdd);

                    _hideChat();

                    final html = await webView.getHtml();
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
                        this.progress = progress / 100;
                      });
                    }

                    if (progress > 75) _pullToRefreshController.endRefreshing();

                    // onProgressChanged gets called before onLoadStart, so it works
                    // both to add or remove widgets. It is much faster.
                    _assessSectionsWithWidgets();
                    // We reset here the triggers for the sections that are called every
                    // time so that they can be called again
                    _resetSectionsWithWidgets();
                  } catch (e) {
                    // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
                    // the checks performed in this method
                  }
                },
                onLoadStop: (c, uri) async {
                  if (!mounted) return;

                  try {
                    _currentUrl = uri.toString();

                    _hideChat();
                    _highlightChat();

                    final html = await webView.getHtml();
                    final document = parse(html);

                    // Force to show title
                    await _getPageTitle(document, showTitle: true);

                    if (widget.useTabs) {
                      _reportUrlVisit(uri);
                    }

                    _assessGeneral(document);

                    // This is used in case the user presses reload. We need to wait for the page
                    // load to be finished in order to scroll
                    if (_scrollAfterLoad) {
                      webView.scrollTo(x: _scrollX, y: _scrollY, animated: false);
                      _scrollAfterLoad = false;
                    }
                  } catch (e) {
                    // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
                    // the checks performed in this method
                  }
                },
                onLoadResource: (c, resource) async {
                  if (!mounted) return;

                  try {
                    /// iOS FORUMS DETECTION
                    /// onLoadStop does not trigger in Forums for iOS
                    if (Platform.isIOS) {
                      if (resource.initiatorType == "xmlhttprequest" &&
                          resource.url.toString().contains("forums.php")) {
                        // Trigger once
                        if (_tradesOnResourceTriggerTime != null &&
                            (DateTime.now().difference(_forumsTriggerTime).inSeconds) < 1) {
                          return;
                        }
                        _forumsTriggerTime = DateTime.now();
                        var uri = (await webView.getUrl());
                        _reportUrlVisit(uri);
                      }
                    }

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

                    // Properties (vault) for initialisation and live transactions
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
                        // so that the new html elements appear and we can analyse them
                        Future.delayed(const Duration(seconds: 2)).then((value) async {
                          // Reset _vaultTriggered so that we can call _assessVault() again
                          _reassessVault();
                        });
                      }
                    }

                    // Jail for initialisation and live transactions
                    if (resource.url.toString().contains("jailview.php")) {
                      // Trigger once
                      if (_jailOnResourceTriggerTime != null &&
                          DateTime.now().difference(_jailOnResourceTriggerTime).inMilliseconds < 500) {
                        return;
                      }
                      _jailOnResourceTriggerTime = DateTime.now();

                      final html = await webView.getHtml();
                      dom.Document document = parse(html);

                      List<dom.Element> query;
                      for (var i = 0; i < 60; i++) {
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
                  } catch (e) {
                    // Prevents issue if webView is closed too soon, in between the 'mounted' check and the rest of
                    // the checks performed in this method
                  }

                  return;
                },
                onConsoleMessage: (controller, consoleMessage) async {
                  if (consoleMessage.message != "") {
                    if (!consoleMessage.message.contains("Refused to connect to 'https://stats.g.doubleclick") &&
                        !consoleMessage.message.contains("Refused to connect to 'https://bat.bing.com")) {
                      _terminalProvider.addInstruction(consoleMessage.message);
                    }
                    // ignore: avoid_print
                    print("TORN PDA CONSOLE: ${consoleMessage.message}");
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
          ),
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
                    appBarTop: _settingsProvider.appBarTop,
                    browserDialog: widget.dialog,
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
                    appBarTop: _settingsProvider.appBarTop,
                    browserDialog: widget.dialog,
                    webviewType: 'inapp',
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

  void _reportUrlVisit(Uri uri) {
    // For certain URLs (e.g. forums in iOS) we might be reporting this twice. Once from onLoadStop and again
    // from onResourceLoad. The check in the provider (for onLoadStop triggering several times) is not enough 
    // to prevent adding extra pages to history (when it's the first page loading, it's only omitted once).
    if (_urlTriggerTime != null && (DateTime.now().difference(_urlTriggerTime).inSeconds) < 1) {
      return;
    }
    _urlTriggerTime = DateTime.now();

    _webViewProvider.reportTabPageTitle(widget.key, _pageTitle);
    if (!_omitTabHistory) {
      // Note: cannot be used in OnLoadStart because it won't trigger for certain pages (e.g. forums)
      _webViewProvider.reportTabLoadUrl(widget.key, uri.toString());
    } else {
      _omitTabHistory = false;
    }
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
              webView.clearMatches();
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
          actions: <Widget>[
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
            }
          : null,
      genericAppBar: AppBar(
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: _backButtonPopsContext ? const Icon(Icons.close) : const Icon(Icons.arrow_back_ios),
          onPressed: () async {
            // Normal behaviour is just to pop and go to previous page
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: <Widget>[
          _travelHomeIcon(),
          _crimesInfoIcon(),
          _crimesMenuIcon(),
          _quickItemsMenuIcon(),
          _vaultsPopUpIcon(),
          _tradesMenuIcon(),
          _vaultOptionsIcon(),
          _cityMenuIcon(),
          _bazaarFillIcon(),
          if (_webViewProvider.chatRemovalEnabledGlobal) _hideChatIcon() else const SizedBox.shrink(),
          Padding(
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
          )
        ],
      ),
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
    _assessBackButtonBehaviour();
    _assessTravel(document);
    _assessBazaarOwn(document);
    _assessBazaarOthers(document);
  }

  Future _assessSectionsWithWidgets() async {
    bool anySectionTriggered = false;
    bool getItems = false;
    bool getCrimes = false;
    bool getCity = false;
    bool getTrades = false;
    bool getVault = false;
    bool getProfile = false;
    bool getAttack = false;

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
      // This is different to the others, here we call only so that properties is deactivated
      _jailExpandable = const SizedBox.shrink();
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
      if ((!_currentUrl.contains(attackUrl) && _attackTriggered) ||
          (_currentUrl.contains(attackUrl) && !_attackTriggered) ||
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
      if (getCity) _assessCity(doc, pageTitle);
      if (getTrades) _decideIfCallTrades(doc: doc, pageTitle: pageTitle);
      if (getVault) _assessVault(doc: doc, pageTitle: pageTitle);
      if (getProfile) _assessProfileAttack();
      if (getAttack) _assessProfileAttack();
    }
  }

  void _resetSectionsWithWidgets() {
    if (_currentUrl.contains('item.php') && _quickItemsTriggered) {
      _crimesTriggered = false;
      _vaultTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains('crimes.php') && _crimesTriggered) {
      _quickItemsTriggered = false;
      _vaultTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains('properties.php') && _vaultTriggered) {
      _crimesTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains('city.php') && _cityTriggered) {
      _crimesTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains("trade.php") && _tradesTriggered) {
      _crimesTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains("torn.com/profiles.php?XID=") && _profileTriggered) {
      _crimesTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _tradesTriggered = false;
      _cityTriggered = false;
      _attackTriggered = false;
    } else if (_currentUrl.contains("loader.php?sid=attack&user2ID=") && _attackTriggered) {
      _crimesTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _tradesTriggered = false;
      _cityTriggered = false;
      _profileTriggered = false;
    } else {
      _crimesTriggered = false;
      _vaultTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
      _profileTriggered = false;
      _attackTriggered = false;
    }
  }

  Future _assessBackButtonBehaviour() async {
    // If we are NOT moving to a place with a vault, we show an X and close upon button press
    if (!_currentUrl.contains('properties.php#/p=options&tab=vault') &&
        !_currentUrl.contains('factions.php?step=your#/tab=armoury&start=0&sub=donate') &&
        !_currentUrl.contains('companies.php#/option=funds')) {
      _backButtonPopsContext = true;
    }
    // However, if we are in a place with a vault AND we come from Trades, we'll change
    // the back button behaviour to ensure we are returning to Trades
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
        await http.post(
          Uri.parse('https://yata.yt/api/v1/travel/import/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: foreignStockOutModelToJson(stockModel),
        );
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
      //var pageTitle = (await _getPageTitle(document)).toLowerCase();
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

  Widget _crimesInfoIcon() {
    if (_crimesActive) {
      return IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () {
          BotToast.showText(
            text: 'If you need more information about a crime, maintain the '
                'quick crime button pressed for a few seconds and a tooltip '
                'will be shown!',
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700],
            duration: const Duration(seconds: 8),
            contentPadding: const EdgeInsets.all(10),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
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
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.fingerprint, color: Colors.white),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
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
      userApiKey: _userProvider.basic.userApiKey,
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
    //var pageTitle = (await _getPageTitle(document)).toLowerCase();
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
    // also trigger and the user will have 60 seconds to load the map (after that, only reloading
    // or browsing out/in of city will force a reload)
    List<dom.Element> query;
    for (var i = 0; i < 60; i++) {
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
      final dynamic apiResponse = await TornApiCaller.items(_userProvider.basic.userApiKey).getItems;
      if (apiResponse is ItemsModel) {
        final tornItems = apiResponse.items.values.toList();
        final itemsFound = <Item>[];
        for (final mapItem in mapItemsList) {
          final Item itemMatch = tornItems[int.parse(mapItem) - 1];
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
      //var pageTitle = (await _getPageTitle(document)).toLowerCase();
      if (!pageTitle.contains('items')) {
        setState(() {
          _quickItemsController.expanded = false;
          _quickItemsActive = false;
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
      final key = _userProvider.basic.userApiKey;
      quickItemsProvider.loadItems(apiKey: key);

      setState(() {
        _quickItemsController.expanded = true;
        _quickItemsActive = true;
      });
    }
  }

  Widget _quickItemsMenuIcon() {
    if (_quickItemsActive) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: OpenContainer(
          transitionDuration: const Duration(milliseconds: 500),
          transitionType: ContainerTransitionType.fadeThrough,
          openBuilder: (BuildContext context, VoidCallback _) {
            return QuickItemsOptions();
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
              child: Image.asset('images/icons/quick_items.png', color: Colors.white),
            );
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // ASSESS PROFILES
  Future _assessProfileAttack() async {
    if (mounted) {
      if (!_currentUrl.contains('loader.php?sid=attack&user2ID=') &&
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
            );
          });
        } catch (e) {
          userId = 0;
        }
      } else if (_currentUrl.contains('loader.php?sid=attack&user2ID=')) {
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
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return WebviewUrlDialog(
          title: _pageTitle,
          url: url.toString(),
          inAppWebview: webView,
          callFindInPage: _activateFindInPage,
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
      webView.findAllAsync(find: _findController.text);
    }
  }

  void _findNext({@required bool forward}) {
    webView.findNext(forward: forward);
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
  Future assessGym() async {
    if (!_settingsProvider.warnAboutExcessEnergy && !_settingsProvider.warnAboutChains) return;

    final easyUrl = _currentUrl.replaceAll('#', '');
    if (easyUrl.contains('www.torn.com/gym.php')) {
      final stats = await TornApiCaller.bars(_userProvider.basic.userApiKey).getBars;
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
            _webViewProvider.showGymMessage(message, widget.key);
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
      _jailExpandable = JailWidget(
        webview: webView,
        fireScriptCallback: _fireJailScriptCallback,
      );
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

  // Called from parent though GlobalKey state
  void loadFromExterior({@required String url, @required bool omitHistory}) {
    _omitTabHistory = omitHistory;
    _loadUrl(url);
  }

  void pauseTimers() {
    if (Platform.isAndroid) {
      webView?.android?.pause();
    }
  }

  void resumeTimers() {
    if (Platform.isAndroid) {
      webView?.android?.resume();
    }
  }

  void _loadUrl(String inputUrl) {
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

    var uri = Uri.parse(inputUrl);
    webView.loadUrl(urlRequest: URLRequest(url: uri));
  }

  Future<bool> _willPopCallback() async {
    _tryGoBack();
    return false;
  }
}
