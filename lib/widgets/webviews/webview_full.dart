import 'dart:async';
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/pages/city/city_options.dart';
import 'package:torn_pda/widgets/city/city_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/pages/crimes/crimes_options.dart';
import 'package:torn_pda/widgets/quick_items/quick_items_widget.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/pages/trades/trades_options.dart';
import 'package:torn_pda/widgets/trades/trades_widget.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:dotted_border/dotted_border.dart';

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
  String _initialUrl = "";
  String _pageTitle = "";
  String _currentUrl = '';

  final _customURLController = new TextEditingController();
  var _customURLKey = GlobalKey<FormState>();

  final _customShortcutNameController = new TextEditingController();
  final _customShortcutURLController = new TextEditingController();
  var _customShortcutNameKey = GlobalKey<FormState>();
  var _customShortcutURLKey = GlobalKey<FormState>();

  bool _backButtonPopsContext = true;

  var _travelActive = false;

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

  var _cityEnabled = false;
  var _cityIconActive = false;
  bool _cityPreferencesLoaded = false;
  var _errorCityApi = false;
  var _cityItemsFound = <Item>[];
  var _cityController = ExpandableController();

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
  ThemeProvider _themeProvider;
  ShortcutsProvider _shortcutsProvider;

  @override
  void initState() {
    super.initState();
    _loadChatPreferences();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _initialUrl = widget.customUrl;
    _pageTitle = widget.customTitle;
  }

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
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
                    direction: _settingsProvider.appBarTop
                        ? AxisDirection.down
                        : AxisDirection.up,
                    widget: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SpeechBubble(
                        nipLocation: _settingsProvider.appBarTop
                            ? NipLocation.TOP
                            : NipLocation.BOTTOM,
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
          ? Colors.blueGrey
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
                      Container(
                        color: _themeProvider.currentTheme == AppTheme.light
                            ? Colors.white
                            : _themeProvider.background,
                        height: 38,
                        child: GestureDetector(
                          onLongPress: () => _openCustomUrlDialog(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.arrow_back_ios_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          _tryGoBack();
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.arrow_forward_ios_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          tryGoForward();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: FlatButton(
                                    child: Text("Close"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _chatRemovalEnabled
                                        ? _hideChatIcon()
                                        : SizedBox.shrink(),
                                    IconButton(
                                      icon: Icon(Icons.refresh),
                                      onPressed: () async {
                                        _scrollX = await webView.getScrollX();
                                        _scrollY = await webView.getScrollY();
                                        await webView.reload();
                                        _scrollAfterLoad = true;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : mainWebViewColumn(),
          ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.deepOrange[300]),
                      )
                    : Container(height: 2),
              )
            : SizedBox.shrink(),
        // Crimes widget. NOTE: this one will open at the bottom if
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
                        controller: webView,
                        appBarTop: _settingsProvider.appBarTop,
                        browserDialog: widget.dialog,
                      )
                    : SizedBox.shrink(),
              )
            : SizedBox.shrink(),
        // Trades widget
        _tradesExpandable,
        // City widget
        ExpandablePanel(
          theme: ExpandableThemeData(
            hasIcon: false,
            tapBodyToCollapse: false,
            tapHeaderToExpand: false,
          ),
          collapsed: SizedBox.shrink(),
          controller: _cityController,
          header: SizedBox.shrink(),
          expanded: _cityIconActive
              ? CityWidget(
                  controller: webView,
                  cityItems: _cityItemsFound,
                  error: _errorCityApi)
              : SizedBox.shrink(),
        ),
        // Actual WebView
        Expanded(
          child: InAppWebView(
            initialUrl: _initialUrl,
            initialHeaders: {},
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                // This is deactivated as it interferes with hospital timer,
                // company applications, etc.
                //useShouldInterceptAjaxRequest: true,
                debuggingEnabled: true,
              ),
              android: AndroidInAppWebViewOptions(
                //builtInZoomControls: false,
                useHybridComposition: true,
                //useWideViewPort: false,
                //loadWithOverviewMode: true,
                //displayZoomControls: true,
              ),
            ),
            /*
                  shouldInterceptAjaxRequest:
                      (InAppWebViewController c, AjaxRequest x) async {
                    // This will intercept ajax calls performed when the bazaar reached 100 items
                    // and needs to be reloaded, so that we can remove and add again the fill buttons
                    if (x == null) return x;
                    if (x.data == null) return x;
                    if (x.url == null) return x;

                    if (x.data.contains("step=getList&type=All&start=") &&
                        x.url.contains('inventory.php') &&
                        _bazaarActive &&
                        _bazaarFillActive) {
                      webView.evaluateJavascript(
                          source: removeBazaarFillButtonsJS());
                      Future.delayed(const Duration(seconds: 2))
                          .then((value) {
                        webView.evaluateJavascript(
                            source: addBazaarFillButtonsJS());
                      });
                    }
                    return x;
                  },
                  */
            onWebViewCreated: (InAppWebViewController c) {
              webView = c;
            },
            onLoadStart: (InAppWebViewController c, String url) async {
              _hideChat();

              _currentUrl = url;

              var html = await webView.getHtml();
              var document = parse(html);
              _assessGeneral(document);
            },
            onProgressChanged: (InAppWebViewController c, int progress) async {
              _hideChat();

              setState(() {
                this.progress = progress / 100;
              });

              // onProgressChanged gets called before onLoadStart, so it works
              // both to add or remove widgets. It is much faster.
              _assessSectionsWithWidgets();
              // We reset here the triggers for the sections that are called every
              // time so that they can be called again
              _resetSectionsWithWidgets();
            },
            onLoadStop: (InAppWebViewController c, String url) async {
              _currentUrl = url;

              _hideChat();
              _highlightChat();

              var html = await webView.getHtml();
              var document = parse(html);
              // Force to show title
              _getPageTitle(document, showTitle: true);
              _assessGeneral(document);

              // This is used in case the user presses reload. We need to wait for the page
              // load to be finished in order to scroll
              if (_scrollAfterLoad) {
                webView.scrollTo(x: _scrollX, y: _scrollY, animated: false);
                _scrollAfterLoad = false;
              }
            },
            // Allows IOS to open links with target=_blank
            onCreateWindow:
                (InAppWebViewController c, CreateWindowRequest req) {
              webView.loadUrl(url: req.url);
              return;
            },
            onConsoleMessage: (InAppWebViewController c, consoleMessage) async {
              if (consoleMessage.message != "")
                print("TORN PDA JS CONSOLE: " + consoleMessage.message);

              /// TRADES
              /// We are calling trades from here because onLoadStop does not
              /// work inside of Trades for iOS. Also, both in Android and iOS
              /// we need to catch deletions that happen with a console message
              /// of "hash.step".
              if (consoleMessage.message.contains('hash.step') &&
                  _currentUrl.contains('trade.php')) {
                _tradesTriggered = true;
                _currentUrl = await webView.getUrl();
                var html = await webView.getHtml();
                var document = parse(html);
                var pageTitle = (await _getPageTitle(document)).toLowerCase();
                _assessTrades(document, pageTitle);
              }
            },
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
                        controller: webView,
                        appBarTop: _settingsProvider.appBarTop,
                        browserDialog: widget.dialog,
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
    var senderColor =
        'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, 1)';
    String hlMap =
        '[ { name: "${_userProvider.myUser.name}", highlight: "$background", sender: "$senderColor" } ]';

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
    return CustomAppBar(
      onHorizontalDragEnd: (DragEndDetails details) async {
        await _goBackOrForward(details);
      },
      genericAppBar: AppBar(
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        brightness: Brightness.dark,
        leading: IconButton(
            icon: _backButtonPopsContext
                ? Icon(Icons.close)
                : Icon(Icons.arrow_back_ios),
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
            _openCustomUrlDialog();
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
          _cityMenuIcon(),
          _bazaarFillIcon(),
          _chatRemovalEnabled ? _hideChatIcon() : SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: GestureDetector(
              child: Icon(Icons.refresh),
              onTap: () async {
                _scrollX = await webView.getScrollX();
                _scrollY = await webView.getScrollY();
                await webView.reload();
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
        ],
      ),
    );
  }

  Future _goBackOrForward(DragEndDetails details) async {
    if (details.primaryVelocity < 0) {
      await tryGoForward();
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

  Future tryGoForward() async {
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

    if (anySectionTriggered) {
      dom.Document doc;
      var pageTitle = "";
      var html = await webView.getHtml();
      doc = parse(html);
      pageTitle = (await _getPageTitle(doc)).toLowerCase();

      if (getItems) _assessQuickItems(doc, pageTitle);
      if (getCrimes) _assessCrimes(doc, pageTitle);
      if (getCity) _assessCity(doc, pageTitle);
      if (getTrades) _decideIfCallTrades(doc: doc, pageTitle: pageTitle);
    }
  }

  void _resetSectionsWithWidgets() {
    if (_currentUrl.contains('item.php') && _quickItemsTriggered) {
      _crimesTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
    } else if (_currentUrl.contains('crimes.php') && _crimesTriggered) {
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
    } else if (_currentUrl.contains('city.php') && _cityTriggered) {
      _crimesTriggered = false;
      _quickItemsTriggered = false;
      _tradesTriggered = false;
    } else if (_currentUrl.contains("trade.php") && _tradesTriggered) {
      _crimesTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
    } else {
      _crimesTriggered = false;
      _quickItemsTriggered = false;
      _cityTriggered = false;
      _tradesTriggered = false;
    }
  }

  void _assessBackButtonBehaviour() async {
    // If we are NOT moving to a place with a vault, we show an X and close upon button press
    if (!_currentUrl.contains('properties.php#/p=options&tab=vault') &&
        !_currentUrl.contains(
            'factions.php?step=your#/tab=armoury&start=0&sub=donate') &&
        !_currentUrl.contains('companies.php#/option=funds')) {
      _backButtonPopsContext = true;
    }
    // However, if we are in a place with a vault AND we come from Trades, we'll change
    // the back button behaviour to ensure we are returning to Trades
    else {
      var history = await webView.getCopyBackForwardList();
      // Check if we have more than a single page in history (otherwise we don't come from Trades)
      if (history.currentIndex > 0) {
        if (history.list[history.currentIndex - 1].url.contains('trade.php')) {
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
    var query = document.querySelectorAll(".travel-home");

    if (query.length > 0) {
      _insertTravelFillMaxButtons();
      _sendStockInformation(document);
      if (mounted) {
        setState(() {
          _travelActive = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _travelActive = false;
        });
      }
    }
  }

  Future _insertTravelFillMaxButtons() async {
    await webView.evaluateJavascript(source: buyMaxJS());
  }

  void _sendStockInformation(dom.Document document) async {
    var elements = document.querySelectorAll('.item-info-wrap');

    if (elements.length > 0) {
      try {
        // Parse stocks
        var stockModel = ForeignStockOutModel();
        var userProfile =
            await TornApiCaller.ownProfile(_userProvider.myUser.userApiKey)
                .getOwnProfile;
        if (userProfile is OwnProfileModel) {
          stockModel.authorName = userProfile.name;
          stockModel.authorId = userProfile.playerId;
        }

        stockModel.country = document
            .querySelector(".content-title > h4")
            .innerHtml
            .substring(0, 4)
            .toLowerCase()
            .trim();

        RegExp expId = new RegExp(r"[0-9]+");
        for (var el in elements) {
          var stockItem = ForeignStockOutItem();
          stockItem.id =
              int.parse(expId.firstMatch(el.querySelector('[id^=item]').id)[0]);
          stockItem.quantity = int.parse(el
              .querySelector(".stck-amount")
              .innerHtml
              .replaceAll(RegExp(r"[^0-9]"), ""));
          stockItem.cost = int.parse(el
              .querySelector(".c-price")
              .innerHtml
              .replaceAll(RegExp(r"[^0-9]"), ""));
          stockModel.items.add(stockItem);
        }

        // Send to server
        await http.post(
          'https://yata.alwaysdata.net/api/v1/travel/import/',
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
    if (_travelActive) {
      return IconButton(
        icon: Icon(Icons.home),
        onPressed: () async {
          await webView.evaluateJavascript(source: travelReturnHomeJS());
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  // CRIMES
  Future _assessCrimes(dom.Document document, String pageTitle) async {
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
    var easyUrl =
        _currentUrl.replaceAll('#', '').replaceAll('/', '').split('&');
    if (pageTitle.contains('trade') && _currentUrl.contains('trade.php')) {
      // Activate trades icon even before starting a trade, so that it can be deactivated
      if (mounted) {
        setState(() {
          _tradesIconActive = true;
        });
      }
      _lastTradeCallWasIn = true;
      if (!easyUrl[0].contains('step=initiateTrade') &&
          !easyUrl[0].contains('step=view')) {
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
      _tradeCalculatorEnabled =
          await SharedPreferencesModel().getTradeCalculatorEnabled();
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
    var totalFinds = document.querySelectorAll(
        ".color1 .left , .color2 .left , .color1 .right , .color2 .right");

    try {
      if (totalFinds.length == 0) {
        await Future.delayed(const Duration(seconds: 1));
        var updatedHtml = await webView.getHtml();
        var updatedDoc = parse(updatedHtml);
        leftMoneyElements =
            updatedDoc.querySelectorAll("#trade-container .left .color1 .name");
        leftItemsElements =
            updatedDoc.querySelectorAll("#trade-container .left .color2 .name");
        leftPropertyElements =
            updatedDoc.querySelectorAll("#trade-container .left .color3 .name");
        leftSharesElements =
            updatedDoc.querySelectorAll("#trade-container .left .color4 .name");
        rightMoneyElements = updatedDoc
            .querySelectorAll("#trade-container .right .color1 .name");
        rightItemsElements = updatedDoc
            .querySelectorAll("#trade-container .right .color2 .name");
        rightPropertyElements = updatedDoc
            .querySelectorAll("#trade-container .right .color3 .name");
        rightSharesElements = updatedDoc
            .querySelectorAll("#trade-container .right .color4 .name");
      } else {
        leftMoneyElements =
            document.querySelectorAll("#trade-container .left .color1 .name");
        leftItemsElements =
            document.querySelectorAll("#trade-container .left .color2 .name");
        leftPropertyElements =
            document.querySelectorAll("#trade-container .left .color3 .name");
        leftSharesElements =
            document.querySelectorAll("#trade-container .left .color4 .name");
        rightMoneyElements =
            document.querySelectorAll("#trade-container .right .color1 .name");
        rightItemsElements =
            document.querySelectorAll("#trade-container .right .color2 .name");
        rightPropertyElements =
            document.querySelectorAll("#trade-container .right .color3 .name");
        rightSharesElements =
            document.querySelectorAll("#trade-container .right .color4 .name");
      }
    } catch (e) {
      return;
    }

    // Trade Id
    try {
      RegExp regId = new RegExp(r"(?:&ID=)([0-9]+)");
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
      userApiKey: _userProvider.myUser.userApiKey,
      playerId: _userProvider.myUser.playerId,
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
            url: "https://www.torn.com/properties.php#/p=options&tab=vault");
        break;
      case "Faction vault":
        webView.loadUrl(
            url:
                "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate");
        break;
      case "Company vault":
        webView.loadUrl(
            url: "https://www.torn.com/companies.php#/option=funds");
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
            playerId: _userProvider.myUser.playerId,
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
    _tradeCalculatorEnabled =
        await SharedPreferencesModel().getTradeCalculatorEnabled();
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
          _currentUrl = await webView.getUrl();
          var html = await webView.getHtml();
          var d = parse(html);
          var t = (await _getPageTitle(d)).toLowerCase();
          _assessTrades(d, t);
        }
      }
    }
  }

  // CITY
  Future _assessCity(dom.Document document, String pageTitle) async {
    //var pageTitle = (await _getPageTitle(document)).toLowerCase();
    if (!pageTitle.contains('city')) {
      setState(() {
        _cityIconActive = false;
        _cityController.expanded = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _cityIconActive = true;
      });
    }

    // Stops any successive calls once we are sure that the section is the
    // correct one. onLoadStop will reset this for the future.
    // Otherwise we would call the API every time onProgressChanged ticks
    if (_cityTriggered) {
      return;
    }
    _cityTriggered = true;

    // We only get this once and if we are inside the city
    // It's also in the callback from city options
    if (!_cityPreferencesLoaded) {
      await _cityPreferencesLoad();
      _cityPreferencesLoaded = true;
    }

    // Retry several times and allow the map to load. If the user lands in the city list, this will
    // also trigger and the user will have 60 seconds to load the map (after that, only reloading
    // or browsing out/in of city will force a reload)
    List<dom.Element> query;
    for (var i = 0; i < 60; i++) {
      if (!mounted) break;

      query = document.querySelectorAll("#map .leaflet-marker-pane *");
      if (query.length > 0) {
        print('City tries: $i in $i seconds (max 60 sec)');
        break;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        var updatedHtml = await webView.getHtml();
        document = parse(updatedHtml);
      }
    }
    if (query.length == 0) {
      // Set false so that the page can be reloaded if city widget didn't load
      _cityTriggered = false;
      return;
    }

    // Assess if we need to show the widget, now that we are in the city
    // By placing this check here, we also avoid showing the widget if we entered via Quick Links
    // in the city
    if (mounted) {
      setState(() {
        if (!_cityEnabled) {
          _cityController.expanded = false;
          return;
        }
        _cityController.expanded = true;
      });
    }

    var mapItemsList = <String>[];
    for (var mapFind in query) {
      mapFind.attributes.forEach((key, value) {
        if (key == "src" &&
            value.contains("https://www.torn.com/images/items/")) {
          mapItemsList.add(value.split("items/")[1].split("/")[0]);
        }
      });
    }

    // Pass items to widget (if nothing found, widget's list will be empty)
    try {
      dynamic apiResponse =
          await TornApiCaller.items(_userProvider.myUser.userApiKey).getItems;
      if (apiResponse is ItemsModel) {
        var tornItems = apiResponse.items.values.toList();
        var itemsFound = <Item>[];
        for (var mapItem in mapItemsList) {
          Item itemMatch = tornItems[int.parse(mapItem) - 1];
          itemsFound.add(itemMatch);
        }
        if (mounted) {
          setState(() {
            _cityItemsFound = itemsFound;
            _errorCityApi = false;
          });
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

  Future _cityPreferencesLoad() async {
    _cityEnabled = await SharedPreferencesModel().getCityEnabled();
    await webView.reload();
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
      return FlatButton(
        onPressed: () async {
          _bazaarFillActive
              ? await webView.evaluateJavascript(
                  source: removeBazaarFillButtonsJS())
              : await webView.evaluateJavascript(
                  source: addBazaarFillButtonsJS());

          if (mounted) {
            setState(() {
              _bazaarFillActive
                  ? _bazaarFillActive = false
                  : _bazaarFillActive = true;
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
  Future _assessQuickItems(dom.Document document, String pageTitle) async {
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
      var key = _userProvider.myUser.userApiKey;
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
              child: Image.asset('images/icons/quick_items.png',
                  color: Colors.white),
            );
          },
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _hideChatIcon() {
    if (!_chatRemovalActive) {
      return Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: Icon(MdiIcons.chatOutline),
          onTap: () async {
            webView.evaluateJavascript(source: removeChatJS());
            SharedPreferencesModel().setChatRemovalActive(true);
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
            SharedPreferencesModel().setChatRemovalActive(false);
            setState(() {
              _chatRemovalActive = false;
            });
          },
        ),
      );
    }
  }

  Future _loadChatPreferences() async {
    var removalEnabled = await SharedPreferencesModel().getChatRemovalEnabled();
    var removalActive = await SharedPreferencesModel().getChatRemovalActive();
    setState(() {
      _chatRemovalEnabled = removalEnabled;
      _chatRemovalActive = removalActive;
    });
  }

  Future<void> _openCustomUrlDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: _themeProvider.background,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "URL OPTIONS",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Flexible(
                              child: Form(
                                key: _customURLKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // To make the card compact
                                  children: <Widget>[
                                    TextFormField(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _themeProvider.mainText,
                                      ),
                                      controller: _customURLController,
                                      maxLength: 300,
                                      maxLines: 1,
                                      textInputAction: TextInputAction.go,
                                      onFieldSubmitted: (value) {
                                        onCustomURLSubmitted();
                                      },
                                      decoration: InputDecoration(
                                        counterText: "",
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'Custom URL',
                                      ),
                                      validator: (value) {
                                        if (value.replaceAll(' ', '').isEmpty) {
                                          return "Cannot be empty!";
                                        }
                                        // Try to force https
                                        if (value
                                            .toLowerCase()
                                            .contains('http://')) {
                                          _customURLController.text.replaceAll(
                                              'http://', 'https://');
                                        }
                                        if (!value
                                            .toLowerCase()
                                            .contains('https://')) {
                                          _customURLController.text =
                                              'https://' +
                                                  _customURLController.text;
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.double_arrow_outlined),
                              onPressed: () async {
                                onCustomURLSubmitted();
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        RaisedButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            //mainAxisAlignment: MainAxisAlign,
                            children: [
                              Icon(Icons.paste),
                              SizedBox(width: 5),
                              Text('Copy current URL'),
                            ],
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _currentUrl));
                            if (_currentUrl.length > 60) {
                              _currentUrl =
                                  _currentUrl.substring(0, 60) + "...";
                            }
                            BotToast.showText(
                              text: "Current URL copied to "
                                  "the clipboard [$_currentUrl]",
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.green,
                              duration: Duration(seconds: 5),
                              contentPadding: EdgeInsets.all(10),
                            );
                            _customURLController.text = "";
                            Navigator.of(context).pop();
                          },
                        ),
                        SizedBox(height: 10),
                        RaisedButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            //mainAxisAlignment: MainAxisAlign,
                            children: [
                              Icon(Icons.favorite_border_outlined),
                              SizedBox(width: 5),
                              Text('Save shortcut'),
                            ],
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openCustomShortcutDialog(_pageTitle, _currentUrl);
                            _customURLController.text = "";
                          },
                        ),
                        SizedBox(height: 8),
                        FlatButton(
                          child: Text("Close"),
                          onPressed: () {
                            _customURLController.text = "";
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
                      radius: 22,
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          "images/icons/pda_icon.png",
                          width: 18,
                          height: 18,
                          color: _themeProvider.mainText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onCustomURLSubmitted() {
    if (_customURLKey.currentState.validate()) {
      webView.loadUrl(url: _customURLController.text);
      _customURLController.text = "";
      Navigator.of(context).pop();
    }
  }

  Future<void> _openCustomShortcutDialog(String title, String url) {
    _customShortcutNameController.text = title;
    _customShortcutURLController.text = url;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: _themeProvider.background,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Add a name and URL for your custom shortcut. Note: "
                            "ensure URL begins with 'https://'",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Form(
                          key: _customShortcutNameKey,
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min, // To make the card compact
                            children: <Widget>[
                              TextFormField(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _themeProvider.mainText,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                controller: _customShortcutNameController,
                                maxLength: 20,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  counterText: "",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Name',
                                ),
                                validator: (value) {
                                  if (value.replaceAll(' ', '').isEmpty) {
                                    return "Cannot be empty!";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Flexible(
                              child: Form(
                                key: _customShortcutURLKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // To make the card compact
                                  children: <Widget>[
                                    TextFormField(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _themeProvider.mainText,
                                      ),
                                      controller: _customShortcutURLController,
                                      maxLength: 300,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'URL',
                                      ),
                                      validator: (value) {
                                        if (value.replaceAll(' ', '').isEmpty) {
                                          return "Cannot be empty!";
                                        }
                                        if (!value
                                            .toLowerCase()
                                            .contains('https://')) {
                                          if (value
                                              .toLowerCase()
                                              .contains('http://')) {
                                            return "Invalid, HTTPS needed!";
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Text("Add"),
                              onPressed: () {
                                if (!_customShortcutURLKey.currentState
                                    .validate()) {
                                  return;
                                }
                                if (!_customShortcutNameKey.currentState
                                    .validate()) {
                                  return;
                                }

                                var customShortcut = Shortcut()
                                  ..name = _customShortcutNameController.text
                                  ..nickname =
                                      _customShortcutNameController.text
                                  ..url = _customShortcutURLController.text
                                  ..iconUrl = 'images/icons/pda_icon.png'
                                  ..color = Colors.orange[500]
                                  ..isCustom = true;

                                _shortcutsProvider
                                    .activateShortcut(customShortcut);
                                Navigator.of(context).pop();
                                _customShortcutNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                            FlatButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _customShortcutNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
                      radius: 22,
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          "images/icons/pda_icon.png",
                          width: 18,
                          height: 18,
                          color: _themeProvider.mainText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // UTILS
  Future<bool> _willPopCallback() async {
    await _tryGoBack();
    return false;
  }
}
