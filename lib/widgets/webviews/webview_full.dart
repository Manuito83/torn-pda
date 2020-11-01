import 'dart:async';
import 'dart:io';
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
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/city/city_options.dart';
import 'package:torn_pda/widgets/city/city_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_options.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/widgets/trades/trades_options.dart';
import 'package:torn_pda/widgets/trades/trades_widget.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';

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
  var _cityItemsFound = List<Item>();
  var _cityController = ExpandableController();

  var _bazaarActive = false;
  var _bazaarFillActive = false;

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

  SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _initialUrl = widget.customUrl;
    _pageTitle = widget.customTitle;
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
          ? buildScaffold(context)
          : BubbleShowcase(
              // KEEP THIS UNIQUE
              bubbleShowcaseId: 'webview_full_showcase',
              // WILL SHOW IF VERSION CHANGED
              bubbleShowcaseVersion: 1,
              showCloseButton: false,
              doNotReopenOnClose: true,
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
                      color: Colors.blue,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Did you know?\n\n'
                          'Long press section title to copy URL\n\n'
                          'Swipe left/right to browse forward/back',
                          style: TextStyle(color: Colors.white),
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

  SafeArea buildScaffold(BuildContext context) {
    return SafeArea(
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
          color: Colors.grey[900],
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Column(
              children: [
                widget.dialog
                    ? SizedBox.shrink()
                    : !_settingsProvider.appBarTop
                        ? SizedBox(height: 0)
                        : SizedBox.shrink(),
                // Crimes widget
                ExpandablePanel(
                  theme: ExpandableThemeData(
                    hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: SizedBox.shrink(),
                  controller: _crimesController,
                  header: SizedBox.shrink(),
                  expanded: CrimesWidget(controller: webView),
                ),
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
                  expanded: CityWidget(
                    controller: webView,
                    cityItems: _cityItemsFound,
                    error: _errorCityApi,
                  ),
                ),
                // Actual WebView
                Expanded(
                  child: InAppWebView(
                    initialUrl: _initialUrl,
                    initialHeaders: {},
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        useShouldInterceptAjaxRequest: true,
                        debuggingEnabled: true,
                        preferredContentMode: UserPreferredContentMode.DESKTOP,
                      ),
                      android: AndroidInAppWebViewOptions(
                        builtInZoomControls: false,
                        useHybridComposition: true,
                        //useWideViewPort: false,
                        //loadWithOverviewMode: true,
                        //displayZoomControls: true,
                      ),
                    ),
                    shouldInterceptAjaxRequest: (InAppWebViewController c, AjaxRequest x) async {
                      // This will intercept ajax calls performed when the bazaar reached 100 items
                      // and needs to be reloaded, so that we can remove and add again the fill buttons
                      if (x == null) return;
                      if (x.data == null) return;
                      if (x.url == null) return;

                      if (x.data.contains("step=getList&type=All&start=") &&
                          x.url.contains('inventory.php') &&
                          _bazaarActive &&
                          _bazaarFillActive) {
                        webView.evaluateJavascript(source: removeBazaarFillButtonsJS());
                        Future.delayed(const Duration(seconds: 2)).then((value) {
                          webView.evaluateJavascript(source: addBazaarFillButtonsJS());
                        });
                      }
                      return;
                    },
                    onWebViewCreated: (InAppWebViewController c) {
                      webView = c;
                    },
                    onLoadStart: (InAppWebViewController c, String url) {
                      _currentUrl = url;
                      _assessGeneral();
                    },
                    onLoadStop: (InAppWebViewController c, String url) {
                      _currentUrl = url;
                      _assessGeneral();

                      // This is used in case the user presses reload. We need to wait for the page
                      // load to be finished in order to scroll
                      if (_scrollAfterLoad) {
                        webView.scrollTo(x: _scrollX, y: _scrollY, animated: false);
                        _scrollAfterLoad = false;
                      }
                    },
                    // Allows IOS to open links with target=_blank
                    onCreateWindow: (InAppWebViewController c, CreateWindowRequest req) {
                      webView.loadUrl(url: req.url);
                      return;
                    },
                    onConsoleMessage: (InAppWebViewController c, consoleMessage) async {
                      print("TORN PDA JS CONSOLE: " + consoleMessage.message);

                      /// TRADES
                      ///   - IOS: onLoadStop does not work inside of Trades, that is why we
                      ///     redirect both with console messages (all 'hash.step') for trades
                      ///     identification, but also with _assessGeneral() so that we can remove
                      ///     the widget when an unrelated page is visited. Console messages also
                      ///     help with deletions updates when 'hash.step view' is shown.
                      ///   - Android: onLoadStop works, but we still need to catch deletions,
                      ///     so we only listen for 'hash.step view'.
                      if (Platform.isIOS) {
                        if (consoleMessage.message.contains('hash.step')) {
                          _decideIfCallTrades();
                        }
                      } else if (Platform.isAndroid) {
                        if (consoleMessage.message.contains('hash.step view')) {
                          _decideIfCallTrades();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  CustomAppBar buildCustomAppBar() {
    return CustomAppBar(
      key: _showOne,
      onHorizontalDragEnd: (DragEndDetails details) async {
        await _goBackOrForward(details);
      },
      genericAppBar: AppBar(
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
          child: Text(_pageTitle),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: _currentUrl));
            if (_currentUrl.length > 60) {
              _currentUrl = _currentUrl.substring(0, 60) + "...";
            }
            BotToast.showText(
              text: "Current URL copied to the clipboard [$_currentUrl]",
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green,
              duration: Duration(seconds: 5),
              contentPadding: EdgeInsets.all(10),
            );
          },
        ),
        actions: <Widget>[
          _travelHomeIcon(),
          _crimesInfoIcon(),
          _crimesMenuIcon(),
          _vaultsPopUpIcon(),
          _tradesMenuIcon(),
          _cityMenuIcon(),
          _bazaarFillIcon(),
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
    );
  }

  Future _goBackOrForward(DragEndDetails details) async {
    if (details.primaryVelocity < 0) {
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
    } else if (details.primaryVelocity > 0) {
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
  }

  Future _assessGeneral() async {
    var html = await webView.getHtml();
    var document = parse(html);

    // Assign page title
    String pageTitle = _getPageTitle(document);
    _assessBackButtonBehaviour();
    _assessTravel(document);
    _assessCrimes(document, pageTitle);
    _decideIfCallTrades();
    _assessCity(document, pageTitle);
    _assessBazaar(document);
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
        if (history.list[history.currentIndex - 1].url.contains('trade.php')) {
          _backButtonPopsContext = false;
        }
      }
    }
  }

  String _getPageTitle(dom.Document document) {
    var h4 = document.querySelector(".content-title > h4");
    String pageTitle = '';
    if (h4 != null) {
      pageTitle = h4.innerHtml.substring(0).trim();
      if (pageTitle.toLowerCase().contains('error') ||
          pageTitle.toLowerCase().contains('please validate')) {
        setState(() {
          _pageTitle = 'Torn';
        });
      } else {
        setState(() {
          _pageTitle = pageTitle;
        });
      }
    }
    return pageTitle;
  }

  // TRAVEL
  Future _assessTravel(dom.Document document) async {
    var query = document.querySelectorAll(".travel-home");

    if (query.length > 0) {
      _insertTravelFillMaxButtons();
      _sendStockInformation(document);
      setState(() {
        _travelActive = true;
      });
    } else {
      setState(() {
        _travelActive = false;
      });
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
            await TornApiCaller.ownProfile(_userProvider.myUser.userApiKey).getOwnProfile;
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
          stockItem.id = int.parse(expId.firstMatch(el.querySelector('[id^=item]').id)[0]);
          stockItem.quantity = int.parse(
              el.querySelector(".stck-amount").innerHtml.replaceAll(RegExp(r"[^0-9]"), ""));
          stockItem.cost =
              int.parse(el.querySelector(".c-price").innerHtml.replaceAll(RegExp(r"[^0-9]"), ""));
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
    pageTitle = pageTitle.toLowerCase();
    setState(() {
      if (_currentUrl.contains('https://www.torn.com/crimes.php') &&
          !pageTitle.contains('please validate') &&
          !pageTitle.contains('error') &&
          pageTitle.contains('crimes')) {
        _crimesController.expanded = true;
        _crimesActive = true;
      } else {
        _crimesController.expanded = false;
        _crimesActive = false;
      }
    });
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
              child: Icon(MdiIcons.fingerprint),
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
    pageTitle = pageTitle.toLowerCase();
    var easyUrl = _currentUrl.replaceAll('#', '').replaceAll('/', '').split('&');
    if (pageTitle.contains('trade') && _currentUrl.contains('trade.php')) {
      // Activate trades icon even before starting a trade, so that it can be deactivated
      setState(() {
        _tradesIconActive = true;
      });
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
      setState(() {
        _tradesIconActive = false;
      });
      _lastTradeCallWasIn = false;
      return;
    }

    // We only get this once and if we are inside a trade
    // It's also in the callback from trades options
    if (!_tradesPreferencesLoaded) {
      await _tradesPreferencesLoad();
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
      setState(() {
        _tradesFullActive = true;
        _tradesExpandable = TradesWidget();
      });
    } else {
      setState(() {
        _tradesFullActive = false;
        _tradesExpandable = SizedBox.shrink();
      });
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
        webView.loadUrl(url: "https://www.torn.com/properties.php#/p=options&tab=vault");
        break;
      case "Faction vault":
        webView.loadUrl(
            url: "https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=donate");
        break;
      case "Company vault":
        webView.loadUrl(url: "https://www.torn.com/companies.php#/option=funds");
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
    _tradeCalculatorEnabled = await SharedPreferencesModel().getTradeCalculatorEnabled();
    _decideIfCallTrades();
  }

  // Avoid continuous calls to trades from different activators
  Future _decideIfCallTrades() async {
    var now = DateTime.now();
    var diff = now.difference(_lastTradeCall);
    if (diff.inSeconds > 1 || !_lastTradeCallWasIn) {
      _lastTradeCall = now;

      // Call trades
      _currentUrl = await webView.getUrl();
      var html = await webView.getHtml();
      var document = parse(html);
      // Assign page title
      String pageTitle = _getPageTitle(document);
      _assessTrades(document, pageTitle);
    }
  }

  // CITY
  Future _assessCity(dom.Document document, String pageTitle) async {
    if (pageTitle != '') {
      pageTitle = pageTitle.toLowerCase();
    }

    if (!_currentUrl.contains('https://www.torn.com/city.php') ||
        !pageTitle.contains('city') ||
        pageTitle.contains('please validate') ||
        pageTitle.contains('error')) {
      setState(() {
        _cityIconActive = false;
        _cityController.expanded = false;
      });
      return;
    }

    setState(() {
      _cityIconActive = true;
    });

    // We only get this once and if we are inside the city
    // It's also in the callback from city options
    if (!_cityPreferencesLoaded) {
      await _cityPreferencesLoad();
      _cityPreferencesLoaded = true;
    }

    // Retry several times and allow the map to load
    List<dom.Element> query;
    for (var i = 0; i < 10; i++) {
      query = document.querySelectorAll("#map .leaflet-marker-pane *");
      if (query.length > 0) {
        break;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        var updatedHtml = await webView.getHtml();
        document = parse(updatedHtml);
      }
    }
    if (query.length == 0) {
      return;
    }

    // Assess if we need to show the widget, now that we are in the city
    // By placing this check here, we also avoid showing the widget if we entered via Quick Links
    // in the city
    setState(() {
      if (!_cityEnabled) {
        _cityController.expanded = false;
        return;
      }
      _cityController.expanded = true;
    });

    var mapItemsList = List<String>();
    for (var mapFind in query) {
      mapFind.attributes.forEach((key, value) {
        if (key == "src" && value.contains("https://www.torn.com/images/items/")) {
          mapItemsList.add(value.split("items/")[1].split("/")[0]);
        }
      });
    }

    // Pass items to widget (if nothing found, widget's list will be empty)
    try {
      dynamic apiResponse = await TornApiCaller.items(_userProvider.myUser.userApiKey).getItems;
      if (apiResponse is ItemsModel) {
        var tornItems = apiResponse.items.values.toList();
        var itemsFound = List<Item>();
        for (var mapItem in mapItemsList) {
          Item itemMatch = tornItems[int.parse(mapItem) - 1];
          itemsFound.add(itemMatch);
        }
        setState(() {
          _cityItemsFound = itemsFound;
          _errorCityApi = false;
        });
        webView.evaluateJavascript(source: highlightCityItemsJS());
      } else {
        setState(() {
          _errorCityApi = true;
        });
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
              ? await webView.evaluateJavascript(source: removeBazaarFillButtonsJS())
              : await webView.evaluateJavascript(source: addBazaarFillButtonsJS());

          setState(() {
            _bazaarFillActive ? _bazaarFillActive = false : _bazaarFillActive = true;
          });
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

  // UTILS
  Future<bool> _willPopCallback() async {
    if (widget.customCallBack != null) {
      widget.customCallBack();
    }
    return true;
  }
}
