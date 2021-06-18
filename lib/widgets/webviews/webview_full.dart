// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:speech_bubble/speech_bubble.dart';

// Project imports:
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/pages/city/city_options.dart';
import 'package:torn_pda/pages/crimes/crimes_options.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:torn_pda/pages/trades/trades_options.dart';
import 'package:torn_pda/pages/vault/vault_options_page.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/city/city_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
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

  WebViewFull({
    this.customUrl = 'https://www.torn.com',
    this.customTitle = '',
    this.customCallBack,
    this.dialog = false,
  });

  @override
  _WebViewFullState createState() => _WebViewFullState();
}

class _WebViewFullState extends State<WebViewFull> {
  InAppWebViewController webView;
  var _initialWebViewOptions = InAppWebViewGroupOptions();

  URLRequest _initialUrl;
  String _pageTitle = "";
  String _currentUrl = '';

  bool _backButtonPopsContext = true;

  var _travelAbroad = false;
  var _travelHomeIconTriggered = false;

  var _crimesActive = false;
  var _crimesController = ExpandableController();

  var _tradesFullActive = false;
  var _tradesIconActive = false;
  Widget _tradesExpandable = SizedBox.shrink();
  bool _tradesPreferencesLoaded = false;
  bool _tradeCalculatorEnabled = false;

  DateTime _lastTradeCall = DateTime.now();
  // Sometimes the first call to trades will not detect that we are in, hence
  // travel icon won't show and [_decideIfCallTrades] won't trigger again. This
  // way we allow it to trigger again.
  bool _lastTradeCallWasIn = false;

  bool _vaultEnabled = false;
  bool _vaultPreferencesLoaded = false;
  bool _vaultIconActive = false;
  Widget _vaultExpandable = SizedBox.shrink();
  DateTime _vaultTriggeredTime = DateTime.now();

  var _cityEnabled = false;
  var _cityIconActive = false;
  bool _cityPreferencesLoaded = false;
  var _errorCityApi = false;
  var _cityItemsFound = <Item>[];
  Widget _cityExpandable = SizedBox.shrink();

  var _bazaarActive = false;
  var _bazaarFillActive = false;

  var _chatRemovalEnabled = false;
  var _chatRemovalActive = false;

  var _quickItemsActive = false;
  var _quickItemsController = ExpandableController();

  // Allow onProgressChanged to call several sections, for better responsiveness,
  // while making sure that we don't call the API each time
  bool _crimesTriggered = false;
  bool _quickItemsTriggered = false;
  bool _cityTriggered = false;
  bool _tradesTriggered = false;
  bool _vaultTriggered = false;

  Widget _profileAttackWidget = SizedBox.shrink();
  var _lastProfileVisited = "";
  var _profileTriggered = false;
  var _attackTriggered = false;

  var _showOne = GlobalKey();
  UserDetailsProvider _userProvider;

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

  //PullToRefreshController _pullToRefreshController;

  bool _clearCacheFirstOpportunity = false;

  bool _findInPageActive = false;
  final _findController = new TextEditingController();
  var _findFocus = new FocusNode();
  var _findFirstSubmitted = false;
  var _findPreviousText = "";

  @override
  void initState() {
    super.initState();
    _loadChatPreferences();
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
        useShouldInterceptAjaxRequest: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
    );

    /*
    _pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.orange[800],
        size: AndroidPullToRefreshSize.DEFAULT,
        backgroundColor: _themeProvider.background,
        enabled:
            _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.icon
                ? true
                : false,
        slingshotDistance: 150,
        distanceToTriggerSync: 150,
      ),
      onRefresh: () async {
        await reload();
      },
    );
    */

    //AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  @override
  void dispose() {
    webView = null;
    _findController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
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
                  positionCalculator: (size) => Position(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    left: 0,
                  ),
                  child: AbsoluteBubbleSlideChild(
                    positionCalculator: (size) => Position(
                      top: size.height / 2,
                      left: (size.width - 200) / 2,
                    ),
                    widget: SpeechBubble(
                      width: 200,
                      nipLocation: NipLocation.BOTTOM,
                      nipHeight: 0,
                      color: Colors.green[800],
                      child: Padding(
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
                  shape: Rectangle(spreadRadius: 10),
                  widgetKey: _showOne,
                  child: RelativeBubbleSlideChild(
                    direction: _settingsProvider.appBarTop ? AxisDirection.down : AxisDirection.up,
                    widget: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SpeechBubble(
                        nipLocation:
                            _settingsProvider.appBarTop ? NipLocation.TOP : NipLocation.BOTTOM,
                        color: Colors.green[800],
                        child: Padding(
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
        top: _settingsProvider.appBarTop ? false : true,
        bottom: true,
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
              icon: Icon(Icons.close),
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
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
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
                  icon: Icon(Icons.search),
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
                        icon: Icon(Icons.keyboard_arrow_up),
                        onPressed: () {
                          _findNext(forward: false);
                          _findFocus.unfocus();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down),
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
      color:
          _themeProvider.currentTheme == AppTheme.light ? Colors.white : _themeProvider.background,
      height: 38,
      child: GestureDetector(
        onLongPress: () => _openUrlDialog(),
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
                      customBorder: new CircleBorder(),
                      splashColor: Colors.blueGrey,
                      child: SizedBox(
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
                      customBorder: new CircleBorder(),
                      splashColor: Colors.blueGrey,
                      child: SizedBox(
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
                child: TextButton(
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: _themeProvider.mainText,
                    ),
                  ),
                  onPressed: () {
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
                  _chatRemovalEnabled ? _hideChatIcon() : SizedBox.shrink(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.pull
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: new CircleBorder(),
                              splashColor: Colors.blueGrey,
                              child: Icon(Icons.refresh),
                              onTap: () async {
                                _scrollX = await webView.getScrollX();
                                _scrollY = await webView.getScrollY();
                                await reload();
                                _scrollAfterLoad = true;
                              },
                            ),
                          )
                        : SizedBox.shrink(),
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
        _settingsProvider.loadBarBrowser
            ? Container(
                height: 2,
                child: progress < 1.0
                    ? LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.blueGrey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange[300]),
                      )
                    : Container(height: 2),
              )
            : SizedBox.shrink(),
        // Crimes widget. NOTE: this one will open at the bottom if
        // appBar is at the bottom, so it's duplicated below the actual
        // webView widget
        _profileAttackWidget,
        _settingsProvider.appBarTop
            ? ExpandablePanel(
                theme: ExpandableThemeData(
                  hasIcon: false,
                  tapBodyToCollapse: false,
                  tapHeaderToExpand: false,
                ),
                collapsed: SizedBox.shrink(),
                controller: _crimesController,
                header: SizedBox.shrink(),
                expanded: _crimesActive
                    ? CrimesWidget(
                        controller: webView,
                        appBarTop: _settingsProvider.appBarTop,
                        browserDialog: widget.dialog,
                      )
                    : SizedBox.shrink(),
              )
            : SizedBox.shrink(),
        // Quick items widget. NOTE: this one will open at the bottom if
        // appBar is at the bottom, so it's duplicated below the actual
        // webView widget
        _settingsProvider.appBarTop
            ? ExpandablePanel(
                theme: ExpandableThemeData(
                  hasIcon: false,
                  tapBodyToCollapse: false,
                  tapHeaderToExpand: false,
                ),
                collapsed: SizedBox.shrink(),
                controller: _quickItemsController,
                header: SizedBox.shrink(),
                expanded: _quickItemsActive
                    ? QuickItemsWidget(
                        inAppWebViewController: webView,
                        appBarTop: _settingsProvider.appBarTop,
                        browserDialog: widget.dialog,
                        webviewType: 'inapp',
                      )
                    : SizedBox.shrink(),
              )
            : SizedBox.shrink(),
        // Trades widget
        _tradesExpandable,
        // Vault widget
        _vaultExpandable,
        // City widget
        _cityExpandable,
        // Actual WebView
        Expanded(
          child: InAppWebView(
            initialUrlRequest: _initialUrl,
            initialUserScripts: _userScriptsProvider.getContinuousSources(
              apiKey: _userProvider.basic.userApiKey,
            ),
            // Temporarily deactivated as it is affecting chats
            //pullToRefreshController: _pullToRefreshController,
            initialOptions: _initialWebViewOptions,
            // EVENTS
            onWebViewCreated: (c) {
              webView = c;
            },
            onCreateWindow: (c, request) {
              // Allows IOS to open links with target=_blank
              webView.loadUrl(urlRequest: request.request);
              return;
            },
            onLoadStart: (c, uri) async {
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

              _currentUrl = uri.toString();

              var html = await webView.getHtml();
              var document = parse(html);
              _assessGeneral(document);
            },
            onProgressChanged: (c, progress) async {
              if (_settingsProvider.removeAirplane) {
                webView.evaluateJavascript(source: travelRemovePlaneJS());
              }

              _hideChat();

              if (mounted) {
                setState(() {
                  this.progress = progress / 100;
                });
              }

              //if (progress > 75) _pullToRefreshController.endRefreshing();

              // onProgressChanged gets called before onLoadStart, so it works
              // both to add or remove widgets. It is much faster.
              _assessSectionsWithWidgets();
              // We reset here the triggers for the sections that are called every
              // time so that they can be called again
              _resetSectionsWithWidgets();
            },
            onLoadStop: (c, uri) async {
              _currentUrl = uri.toString();

              _hideChat();
              _highlightChat();

              var html = await webView.getHtml();
              var document = parse(html);
              // Force to show title
              await (_getPageTitle(document, showTitle: true));
              _assessGeneral(document);

              // This is used in case the user presses reload. We need to wait for the page
              // load to be finished in order to scroll
              if (_scrollAfterLoad) {
                webView.scrollTo(x: _scrollX, y: _scrollY, animated: false);
                _scrollAfterLoad = false;
              }
            },
            onLoadResource: (c, resource) async {
              /// TRADES
              /// We are calling trades from here because onLoadStop does not
              /// work inside of Trades for iOS. Also, both in Android and iOS
              /// we need to catch deletions.
              if (_currentUrl.contains("trade.php")) {
                _tradesTriggered = true;
                var html = await webView.getHtml();
                var document = parse(html);
                var pageTitle = (await _getPageTitle(document)).toLowerCase();
                _assessTrades(document, pageTitle);
              }

              // Properties (vault) for initialisation and live transactions
              if (_currentUrl.contains("properties.php")) {
                if (!_vaultTriggered) {
                  var html = await webView.getHtml();
                  var document = parse(html);
                  var pageTitle = (await _getPageTitle(document)).toLowerCase();
                  _assessVault(doc: document, pageTitle: pageTitle);
                } else {
                  // If it's triggered, it's because we are inside and we performed an operation
                  // (deposit or withdrawal). In this case, we need to give a couple of seconds
                  // so that the new html elements appear and we can analyse them
                  Future.delayed(Duration(seconds: 2)).then((value) async {
                    // Reset _vaultTriggered so that we can call _assessVault() again
                    _reassessVault();
                  });
                }
              }
              return;
            },
            onConsoleMessage: (controller, consoleMessage) async {
              if (consoleMessage.message != "")
                print("TORN PDA JS CONSOLE: " + consoleMessage.message);
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
        ),
        // Widgets that go at the bottom if we have changes appbar to bottom
        !_settingsProvider.appBarTop
            ? ExpandablePanel(
                theme: ExpandableThemeData(
                  hasIcon: false,
                  tapBodyToCollapse: false,
                  tapHeaderToExpand: false,
                ),
                collapsed: SizedBox.shrink(),
                controller: _crimesController,
                header: SizedBox.shrink(),
                expanded: _crimesActive
                    ? CrimesWidget(
                        controller: webView,
                        appBarTop: _settingsProvider.appBarTop,
                        browserDialog: widget.dialog,
                      )
                    : SizedBox.shrink(),
              )
            : SizedBox.shrink(),
        !_settingsProvider.appBarTop
            ? ExpandablePanel(
                theme: ExpandableThemeData(
                  hasIcon: false,
                  tapBodyToCollapse: false,
                  tapHeaderToExpand: false,
                ),
                collapsed: SizedBox.shrink(),
                controller: _quickItemsController,
                header: SizedBox.shrink(),
                expanded: _quickItemsActive
                    ? QuickItemsWidget(
                        inAppWebViewController: webView,
                        appBarTop: _settingsProvider.appBarTop,
                        browserDialog: widget.dialog,
                        webviewType: 'inapp',
                      )
                    : SizedBox.shrink(),
              )
            : SizedBox.shrink(),
      ],
    );
  }

  void _highlightChat() {
    if (!_currentUrl.contains('torn.com')) return;

    var intColor = Color(_settingsProvider.highlightColor);
    var background =
        'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, ${intColor.opacity})';
    var senderColor = 'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, 1)';
    String hlMap =
        '[ { name: "${_userProvider.basic.name}", highlight: "$background", sender: "$senderColor" } ]';

    if (_settingsProvider.highlightChat) {
      webView.evaluateJavascript(
        source: (chatHighlightJS(highlightMap: hlMap)),
      );
    }
  }

  void _hideChat() {
    if (_chatRemovalEnabled && _chatRemovalActive) {
      webView.evaluateJavascript(source: removeChatOnLoadStartJS());
    }
  }

  CustomAppBar buildCustomAppBar() {
    if (_findInPageActive) {
      return CustomAppBar(
        genericAppBar: AppBar(
          elevation: _settingsProvider.appBarTop ? 2 : 0,
          brightness: Brightness.dark,
          leading: IconButton(
            icon: Icon(Icons.close),
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
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                            hintStyle: TextStyle(
                                fontStyle: FontStyle.italic, color: Colors.grey[300], fontSize: 12),
                          ),
                          style: TextStyle(
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
              icon: Icon(Icons.search),
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
                    icon: Icon(Icons.keyboard_arrow_up),
                    onPressed: () {
                      _findNext(forward: false);
                      _findFocus.unfocus();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down),
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
      genericAppBar: AppBar(
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        brightness: Brightness.dark,
        leading: IconButton(
            icon: _backButtonPopsContext ? Icon(Icons.close) : Icon(Icons.arrow_back_ios),
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
                var backPossible = await webView.canGoBack();
                if (backPossible) {
                  webView.goBack();
                } else {
                  Navigator.pop(context);
                }
                _backButtonPopsContext = true;
              }
            }),
        title: GestureDetector(
          onTap: () {
            _openUrlDialog();
          },
          child: DottedBorder(
            borderType: BorderType.Rect,
            padding: EdgeInsets.all(6),
            dashPattern: [1, 4],
            color: Colors.white70,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              child: Row(
                key: _showOne,
                children: [
                  Flexible(
                      child: Text(
                    _pageTitle,
                    overflow: TextOverflow.fade,
                  )),
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
          _chatRemovalEnabled ? _hideChatIcon() : SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _settingsProvider.browserRefreshMethod != BrowserRefreshSetting.pull
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: new CircleBorder(),
                      splashColor: Colors.orange,
                      child: Icon(Icons.refresh),
                      onTap: () async {
                        _scrollX = await webView.getScrollX();
                        _scrollY = await webView.getScrollY();
                        await reload();
                        _scrollAfterLoad = true;

                        BotToast.showText(
                          text: "Reloading...",
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.grey[600],
                          duration: Duration(seconds: 1),
                          contentPadding: EdgeInsets.all(10),
                        );
                      },
                    ),
                  )
                : SizedBox.shrink(),
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
    var canBack = await webView.canGoBack();
    if (canBack) {
      await webView.goBack();
      BotToast.showText(
        text: "Back",
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: Duration(seconds: 1),
        contentPadding: EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        text: "Can\'t go back!",
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: Duration(seconds: 1),
        contentPadding: EdgeInsets.all(10),
      );
    }
  }

  Future _tryGoForward() async {
    var canForward = await webView.canGoForward();
    if (canForward) {
      await webView.goForward();
      BotToast.showText(
        text: "Forward",
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: Duration(seconds: 1),
        contentPadding: EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        text: "Can\'t go forward!",
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: Duration(seconds: 1),
        contentPadding: EdgeInsets.all(10),
      );
    }
  }

  /// Note: several other modules are called in onProgressChanged, since it's
  /// faster. The ones here probably would not benefit from it.
  Future _assessGeneral(dom.Document document) async {
    _assessBackButtonBehaviour();
    _assessTravel(document);
    _assessBazaar(document);
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

    if (_settingsProvider.extraPlayerInformation) {
      var profileUrl = 'torn.com/profiles.php?XID=';
      if ((!_currentUrl.contains(profileUrl) && _profileTriggered) ||
          (_currentUrl.contains(profileUrl) && !_profileTriggered) ||
          (_currentUrl.contains(profileUrl) && _currentUrl != _lastProfileVisited)) {
        anySectionTriggered = true;
        getProfile = true;
      }

      var attackUrl = 'loader.php?sid=attack&user2ID=';
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
      var html = await webView.getHtml();
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

  void _assessBackButtonBehaviour() async {
    // If we are NOT moving to a place with a vault, we show an X and close upon button press
    if (!_currentUrl.contains('properties.php#/p=options&tab=vault') &&
        !_currentUrl.contains('factions.php?step=your#/tab=armoury&start=0&sub=donate') &&
        !_currentUrl.contains('companies.php#/option=funds')) {
      _backButtonPopsContext = true;
    }
    // However, if we are in a place with a vault AND we come from Trades, we'll change
    // the back button behaviour to ensure we are returning to Trades
    else {
      var history = await webView.getCopyBackForwardList();
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
    var h4 = document.querySelector(".content-title > h4");
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
      if (title.toLowerCase().contains('error') ||
          title.toLowerCase().contains('please validate')) {
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
    var abroad = document.querySelectorAll(".travel-home");
    if (abroad.length > 0) {
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
    await webView.evaluateJavascript(source: buyMaxJS());
  }

  void _sendStockInformation(dom.Document document) async {
    var elements = document.querySelectorAll('.users-list > li');

    if (elements.length > 0) {
      try {
        // Parse stocks
        var stockModel = ForeignStockOutModel();
        stockModel.authorName = "Manuito";
        stockModel.authorId = 2225097;

        stockModel.country = document
            .querySelector(".content-title > h4")
            .innerHtml
            .substring(0, 4)
            .toLowerCase()
            .trim();

        for (var el in elements) {
          var stockItem = ForeignStockOutItem();

          stockItem.id = int.tryParse(el.querySelector(".details").attributes["itemid"]);
          stockItem.quantity = int.tryParse(
              el.querySelector(".stck-amount").innerHtml.replaceAll(RegExp(r"[^0-9]"), ""));
          stockItem.cost = int.tryParse(
              el.querySelector(".c-price").innerHtml.replaceAll(RegExp(r"[^0-9]"), ""));

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
              customBorder: new CircleBorder(),
              splashColor: Colors.blueGrey,
              child: Icon(
                Icons.home,
              ),
              onTap: () async {
                setState(() {
                  _travelHomeIconTriggered = true;
                });
                BotToast.showText(
                  text: 'Tap again to travel back!',
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.orange[800],
                  duration: Duration(seconds: 3),
                  contentPadding: EdgeInsets.all(10),
                );
                Future.delayed(Duration(seconds: 3)).then((value) {
                  if (mounted) {
                    setState(() {
                      _travelHomeIconTriggered = false;
                    });
                  }
                });
              }),
        );
      } else {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: new CircleBorder(),
            splashColor: Colors.blueGrey,
            child: Icon(
              Icons.home,
              color: Colors.orange,
            ),
            onTap: () async {
              await webView.evaluateJavascript(source: travelReturnHomeJS());
              Future.delayed(Duration(seconds: 3)).then((value) {
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
      return SizedBox.shrink();
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
        icon: Icon(Icons.info_outline),
        onPressed: () {
          BotToast.showText(
            text: 'If you need more information about a crime, maintain the '
                'quick crime button pressed for a few seconds and a tooltip '
                'will be shown!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700],
            duration: Duration(seconds: 8),
            contentPadding: EdgeInsets.all(10),
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _crimesMenuIcon() {
    if (_crimesActive) {
      return OpenContainer(
        transitionDuration: Duration(milliseconds: 500),
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
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.fingerprint, color: Colors.white),
            ),
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  // TRADES
  Future _assessTrades(dom.Document document, String pageTitle) async {
    // Check that we are in Trades, but also inside an existing trade
    // (step=view) or just created one (step=initiateTrade)
    //var pageTitle = (await _getPageTitle(document)).toLowerCase();
    var easyUrl = _currentUrl.replaceAll('#', '').replaceAll('/', '').split('&');
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
    var totalFinds = document
        .querySelectorAll(".color1 .left , .color2 .left , .color1 .right , .color2 .right");

    try {
      if (totalFinds.length == 0) {
        await Future.delayed(const Duration(seconds: 1));
        var updatedHtml = await webView.getHtml();
        var updatedDoc = parse(updatedHtml);
        leftMoneyElements = updatedDoc.querySelectorAll("#trade-container .left .color1 .name");
        leftItemsElements = updatedDoc.querySelectorAll("#trade-container .left .color2 .name");
        leftPropertyElements = updatedDoc.querySelectorAll("#trade-container .left .color3 .name");
        leftSharesElements = updatedDoc.querySelectorAll("#trade-container .left .color4 .name");
        rightMoneyElements = updatedDoc.querySelectorAll("#trade-container .right .color1 .name");
        rightItemsElements = updatedDoc.querySelectorAll("#trade-container .right .color2 .name");
        rightPropertyElements =
            updatedDoc.querySelectorAll("#trade-container .right .color3 .name");
        rightSharesElements = updatedDoc.querySelectorAll("#trade-container .right .color4 .name");
      } else {
        leftMoneyElements = document.querySelectorAll("#trade-container .left .color1 .name");
        leftItemsElements = document.querySelectorAll("#trade-container .left .color2 .name");
        leftPropertyElements = document.querySelectorAll("#trade-container .left .color3 .name");
        leftSharesElements = document.querySelectorAll("#trade-container .left .color4 .name");
        rightMoneyElements = document.querySelectorAll("#trade-container .right .color1 .name");
        rightItemsElements = document.querySelectorAll("#trade-container .right .color2 .name");
        rightPropertyElements = document.querySelectorAll("#trade-container .right .color3 .name");
        rightSharesElements = document.querySelectorAll("#trade-container .right .color4 .name");
      }
    } catch (e) {
      return;
    }

    // Trade Id
    try {
      RegExp regId = new RegExp(r"&ID=([0-9]+)");
      var matches = regId.allMatches(_currentUrl);
      tradeId = int.parse(matches.elementAt(0).group(1));
    } catch (e) {
      tradeId = 0;
    }

    // Name of seller
    try {
      sellerName = document.querySelector(".right .title-black").innerHtml;
    } catch (e) {
      sellerName = "";
    }

    // Activate trades widget
    _toggleTradesWidget(active: true);

    // Initialize trades provider, which in turn feeds the trades widget
    var tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    tradesProvider.updateTrades(
      userApiKey: _userProvider.basic.userApiKey,
      playerId: _userProvider.basic.playerId,
      sellerName: sellerName,
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

  _toggleTradesWidget({@required bool active}) {
    if (active) {
      if (mounted) {
        setState(() {
          _tradesFullActive = true;
          _tradesExpandable = TradesWidget();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _tradesFullActive = false;
          _tradesExpandable = SizedBox.shrink();
        });
      }
    }
  }

  Widget _vaultsPopUpIcon() {
    if (_tradesIconActive) {
      return PopupMenuButton<VaultsOptions>(
        icon: Icon(MdiIcons.cashUsdOutline),
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
      return SizedBox.shrink();
    }
  }

  void _openVaultsOptions(VaultsOptions choice) async {
    switch (choice.description) {
      case "Personal vault":
        webView.loadUrl(
          urlRequest: URLRequest(
            url: Uri.parse("https://www.torn.com/properties.php#/p=options&tab=vault"),
          ),
        );
        break;
      case "Faction vault":
        webView.loadUrl(
          urlRequest: URLRequest(
            url: Uri.parse(
                "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate"),
          ),
        );
        break;
      case "Company vault":
        webView.loadUrl(
          urlRequest: URLRequest(
            url: Uri.parse("https://www.torn.com/companies.php#/option=funds"),
          ),
        );
        break;
    }
  }

  Widget _tradesMenuIcon() {
    if (_tradesIconActive) {
      return OpenContainer(
        transitionDuration: Duration(milliseconds: 500),
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
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.accountSwitchOutline),
            ),
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future _tradesPreferencesLoad() async {
    _tradeCalculatorEnabled = await Prefs().getTradeCalculatorEnabled();
    _decideIfCallTrades();
  }

  // Avoid continuous calls to trades from different activators
  Future _decideIfCallTrades({dom.Document doc, String pageTitle = ""}) async {
    var now = DateTime.now();
    var diff = now.difference(_lastTradeCall);
    if (diff.inSeconds > 1 || !_lastTradeCallWasIn) {
      _lastTradeCall = now;

      // Call trades. If we come from onProgressChanged we already have document
      // and title (quicker). Otherwise, we need to get them (if we come from trade options)
      if (mounted) {
        if (doc != null && pageTitle.isNotEmpty) {
          _assessTrades(doc, pageTitle);
        } else {
          _currentUrl = (await webView.getUrl()).toString();
          var html = await webView.getHtml();
          var d = parse(html);
          var t = (await _getPageTitle(d)).toLowerCase();
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
        _vaultExpandable = SizedBox.shrink();
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
        _vaultExpandable = SizedBox.shrink();
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
      if (allTransactions.length > 0) {
        break;
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) break;
        var updatedHtml = await webView.getHtml();
        doc = parse(updatedHtml);
      }
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
        transitionDuration: Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return VaultOptionsPage(
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
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.safeSquareOutline),
            ),
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future _reassessVault() async {
    _vaultEnabled = await Prefs().getVaultEnabled();
    // Reset _vaultTriggered so that we can call _assessVault() again
    _vaultTriggered = false;
    var html = await webView.getHtml();
    var document = parse(html);
    var pageTitle = (await _getPageTitle(document)).toLowerCase();
    _assessVault(doc: document, pageTitle: pageTitle, fromReassess: true);
  }

  // CITY
  Future _assessCity(dom.Document document, String pageTitle) async {
    //var pageTitle = (await _getPageTitle(document)).toLowerCase();
    if (!pageTitle.contains('city')) {
      setState(() {
        _cityIconActive = false;
        _cityExpandable = SizedBox.shrink();
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
        _cityExpandable = SizedBox.shrink();
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
      if (query.length > 0) {
        break;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) break;
        var updatedHtml = await webView.getHtml();
        document = parse(updatedHtml);
      }
    }

    if (query.length == 0) {
      // Set false so that the page can be reloaded if city widget didn't load
      _cityTriggered = false;
      return;
    }

    var mapItemsList = <String>[];
    for (var mapFind in query) {
      mapFind.attributes.forEach((key, value) {
        if (key == "src" && value.contains("https://www.torn.com/images/items/")) {
          mapItemsList.add(value.split("items/")[1].split("/")[0]);
        }
      });
    }

    // Pass items to widget (if nothing found, widget's list will be empty)
    try {
      dynamic apiResponse = await TornApiCaller.items(_userProvider.basic.userApiKey).getItems;
      if (apiResponse is ItemsModel) {
        var tornItems = apiResponse.items.values.toList();
        var itemsFound = <Item>[];
        for (var mapItem in mapItemsList) {
          Item itemMatch = tornItems[int.parse(mapItem) - 1];
          itemsFound.add(itemMatch);
        }
        if (mounted) {
          // This last check prevents city widget from loading if we are leaving the city
          // before it had time to load (which could collude with other widgets)
          if (!_cityTriggered) {
            setState(() {
              _cityExpandable = SizedBox.shrink();
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
        transitionDuration: Duration(milliseconds: 500),
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
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.cityVariantOutline),
            ),
          );
        },
      );
    } else {
      return SizedBox.shrink();
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

  // BAZAAR
  Future _assessBazaar(dom.Document document) async {
    var easyUrl = _currentUrl.replaceAll('#', '');
    if (easyUrl.contains('bazaar.php/add')) {
      _bazaarActive = true;
    } else {
      _bazaarActive = false;
    }
  }

  Widget _bazaarFillIcon() {
    if (_bazaarActive) {
      return TextButton(
        onPressed: () async {
          _bazaarFillActive
              ? await webView.evaluateJavascript(source: removeBazaarFillButtonsJS())
              : await webView.evaluateJavascript(source: addBazaarFillButtonsJS());

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
      return SizedBox.shrink();
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

      var quickItemsProvider = context.read<QuickItemsProvider>();
      var key = _userProvider.basic.userApiKey;
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
          transitionDuration: Duration(milliseconds: 500),
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
      return SizedBox.shrink();
    }
  }

  // ASSESS PROFILES
  Future _assessProfileAttack() async {
    if (mounted) {
      if (!_currentUrl.contains('loader.php?sid=attack&user2ID=') &&
          !_currentUrl.contains('torn.com/profiles.php?XID=')) {
        _profileTriggered = false;
        _profileAttackWidget = SizedBox.shrink();
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
          RegExp regId = new RegExp(r"php\?XID=([0-9]+)");
          var matches = regId.allMatches(_currentUrl);
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
          RegExp regId = new RegExp(r"&user2ID=([0-9]+)");
          var matches = regId.allMatches(_currentUrl);
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
    if (!_chatRemovalActive) {
      return Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: Icon(MdiIcons.chatOutline),
          onTap: () async {
            webView.evaluateJavascript(source: removeChatJS());
            Prefs().setChatRemovalActive(true);
            setState(() {
              _chatRemovalActive = true;
            });
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
            Prefs().setChatRemovalActive(false);
            setState(() {
              _chatRemovalActive = false;
            });
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
      webView.loadUrl(urlRequest: URLRequest(url: await webView.getUrl()));
    }
  }

  Future _loadChatPreferences() async {
    var removalEnabled = await Prefs().getChatRemovalEnabled();
    var removalActive = await Prefs().getChatRemovalActive();
    setState(() {
      _chatRemovalEnabled = removalEnabled;
      _chatRemovalActive = removalActive;
    });
  }

  Future<void> _openUrlDialog() async {
    var url = await webView.getUrl();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return WebviewUrlDialog(
          title: _pageTitle,
          url: url.toString(),
          webview: webView,
          callFindInPage: _activateFindInPage,
        );
      },
    );
  }

  _activateFindInPage() {
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

  void _findNext({@required bool forward}) async {
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

  // UTILS
  Future<bool> _willPopCallback() async {
    await _tryGoBack();
    return false;
  }
}
