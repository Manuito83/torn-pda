import 'dart:async';
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/own_profile_model.dart';
import 'package:torn_pda/models/trades/trade_item_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/html_parser.dart' as pdaParser;
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_options.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/widgets/trades/trades_options.dart';
import 'package:torn_pda/widgets/trades/trades_widget.dart';

class WebViewFull extends StatefulWidget {
  final String customTitle;
  final String customUrl;
  final Function customCallBack;

  WebViewFull({
    this.customUrl = 'https://www.torn.com',
    this.customTitle = '',
    this.customCallBack,
  });

  @override
  _WebViewFullState createState() => _WebViewFullState();
}

class _WebViewFullState extends State<WebViewFull> {
  InAppWebViewController webView;
  String _initialUrl = "";
  String _pageTitle = "";
  String _currentUrl = '';

  var _travelActive = false;

  var _crimesActive = false;
  var _crimesController = ExpandableController();

  var _tradesFullActive = false;
  var _tradesIconActive = false;
  Widget _tradesExpandable = SizedBox.shrink();
  Timer _tradesTimer;
  bool _tradesPreferencesLoaded = false;
  bool _tradeCalculatorActive = false;
  bool _tradeRefreshActive = false;

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.customUrl;
    _pageTitle = widget.customTitle;
  }

  @override
  void dispose() {
    if (_tradesTimer != null) {
      _tradesTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (widget.customCallBack != null) {
                  widget.customCallBack();
                }
                Navigator.pop(context);
              }),
          title: Text(_pageTitle),
          actions: <Widget>[
            _travelHomeIcon(),
            _crimesInfoIcon(),
            _crimesMenuIcon(),
            _crimesMenuIcon(),
            _tradesMenuIcon(),
          ],
        ),
        body: Container(
          color: Colors.grey[900],
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Column(
              children: [
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
                // Actual WebView
                Expanded(
                  child: InAppWebView(
                    initialUrl: _initialUrl,
                    initialHeaders: {},
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        debuggingEnabled: true,
                        preferredContentMode: UserPreferredContentMode.DESKTOP,
                      ),
                      android: AndroidInAppWebViewOptions(
                        useWideViewPort: true,
                        loadWithOverviewMode: true,
                        builtInZoomControls: true,
                        displayZoomControls: true,
                      ),
                    ),
                    onWebViewCreated: (InAppWebViewController c) {
                      webView = c;
                    },
                    onLoadStop: (InAppWebViewController c, String url) {
                      _currentUrl = url;
                      _assessGeneral();
                    },
                    /*
                    onConsoleMessage: (InAppWebViewController c, consoleMessage) {
                      print("TORN PDA JS CONSOLE: " + consoleMessage.message);
                    },
                    */
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future _assessGeneral() async {
    var html = await webView.getHtml();
    var document = parse(html);
    _assessTravel(document);
    _assessCrimes(document);
    _assessTrades(document);
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

        var userDetailsProvider = Provider.of<UserDetailsProvider>(context, listen: false);
        var userProfile =
            await TornApiCaller.ownProfile(userDetailsProvider.myUser.userApiKey).getOwnProfile;
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
          'https://yata.alwaysdata.net/bazaar/abroad/import/',
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
  Future _assessCrimes(dom.Document document) async {
    var h4 = document.querySelector(".content-title > h4");
    var pageTitle = '';
    if (h4 != null) {
      pageTitle = h4.innerHtml.substring(0).toLowerCase().trim();
    }

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
            padding: const EdgeInsets.only(right: 20),
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
  Future _assessTrades(dom.Document document) async {
    // Check that we are in Trades, but also inside an existing trade
    // (step=view) or just created one (step=initiateTrade)
    var h4 = document.querySelector(".content-title > h4");
    if (h4 == null) {
      return;
    } else {
      var pageTitle = h4.innerHtml.substring(0).toLowerCase().trim();
      var easyUrl = _currentUrl.replaceAll('#', '').replaceAll('/', '').split('&');
      if (pageTitle.contains('trade') && easyUrl[0].contains('trade.php')) {
        // Activate trades icon even before starting a trade, so that it can be deactivated
        _tradesIconActive = true;
        if (!easyUrl[0].contains('step=initiateTrade') && !easyUrl[0].contains('step=view')) {
          if (_tradesFullActive) {
            _toggleTradesExpandable(active: false);
          }
          return;
        }
      } else {
        if (_tradesFullActive) {
          _toggleTradesExpandable(active: false);
        }
        _tradesIconActive = false;
        return;
      }
    }

    // We only get this once and if we are inside a trade
    // It's also in the callback from trades options
    if (!_tradesPreferencesLoaded) {
      await _tradesPreferencesLoad();
      _tradesPreferencesLoaded = true;
    }
    if (!_tradeCalculatorActive) {
      if (_tradesFullActive) {
        _toggleTradesExpandable(active: false);
      }
      return;
    }

    // Final items
    int leftMoney = 0;
    var leftItems = List<TradeItem>();
    var leftProperties = List<TradeItem>();
    var leftShares = List<TradeItem>();
    int rightMoney = 0;
    var rightItems = List<TradeItem>();
    var rightProperties = List<TradeItem>();
    var rightShares = List<TradeItem>();

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

    // Color 1 is money
    int colors1(List<dom.Element> sideMoneyElement) {
      var row = sideMoneyElement[0];
      RegExp regExp = new RegExp(r"([0-9][,]{0,3})+");
      try {
        var match = regExp.stringMatch(row.innerHtml);
        return int.parse(match.replaceAll(",", ""));
      } catch (e) {
        return 0;
      }
    }

    if (leftMoneyElements.length > 0) {
      leftMoney = colors1(leftMoneyElements);
    }

    if (rightMoneyElements.length > 0) {
      rightMoney = colors1(rightMoneyElements);
    }

    // Color 2 is general items
    void addColor2Items(dom.Element itemLine, ItemsModel allTornItems, List<TradeItem> sideItems) {
      var thisItem = TradeItem();
      var row = pdaParser.HtmlParser.fix(itemLine.innerHtml.trim());
      thisItem.name = row.split(" x")[0].trim();
      row.split(" x").length > 1
          ? thisItem.quantity = int.parse(row.split(" x")[1])
          : thisItem.quantity = 1;
      allTornItems.items.forEach((key, value) {
        if (thisItem.name == value.name) {
          thisItem.priceUnit = value.marketValue;
          thisItem.totalPrice = thisItem.priceUnit * thisItem.quantity;
        }
      });
      sideItems.add(thisItem);
    }

    if (leftItemsElements.length > 0 || rightItemsElements.length > 0) {
      var userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
      var allTornItems = await TornApiCaller.items(userProvider.myUser.userApiKey).getItems;
      if (allTornItems is ApiError) {
        return;
      } else if (allTornItems is ItemsModel) {
        // Loop left
        for (var itemLine in leftItemsElements) {
          addColor2Items(itemLine, allTornItems, leftItems);
        }
        // Loop right
        for (var itemLine in rightItemsElements) {
          addColor2Items(itemLine, allTornItems, rightItems);
        }
      }
    }

    // Color 3 is properties
    void addColor3Items(dom.Element propertyLine, List<TradeItem> sideProperty) {
      var thisProperty = TradeItem();
      var row = pdaParser.HtmlParser.fix(propertyLine.innerHtml.trim());
      thisProperty.name = row.split(" (")[0].trim();
      RegExp regExp = new RegExp(r"[0-9]+ happiness");
      try {
        var match = regExp.stringMatch(propertyLine.innerHtml);
        thisProperty.happiness = match.substring(0);
      } catch (e) {
        thisProperty.happiness = '';
      }
      sideProperty.add(thisProperty);
    }

    if (leftPropertyElements.length > 0 || rightPropertyElements.length > 0) {
      for (var propertyLine in leftPropertyElements) {
        addColor3Items(propertyLine, leftProperties);
      }
      for (var propertyLine in rightPropertyElements) {
        addColor3Items(propertyLine, rightProperties);
      }
    }

    // Color 4 is general items
    void addColor4Items(dom.Element shareLine, List<TradeItem> sideShares) {
      var thisShare = TradeItem();
      var row = pdaParser.HtmlParser.fix(shareLine.innerHtml.trim());
      thisShare.name = row.split(" x")[0].trim();

      try {
        RegExp regQuantity = new RegExp(
            r"([A-Z]{3}) (?:x)([0-9]+) (?:at) (?:\$)((?:[0-9]|[.]|[,])+) (?:\()(?:\$)((?:[0-9]|[,])+)");
        var matches = regQuantity.allMatches(shareLine.innerHtml);
        thisShare.name = matches.elementAt(0).group(1);
        thisShare.quantity = int.parse(matches.elementAt(0).group(2));
        var singlePriceSplit = matches.elementAt(0).group(3).split('.');
        thisShare.shareUnit = double.parse(singlePriceSplit[0].replaceAll(',', '')) +
            double.parse('0.${singlePriceSplit[1]}');
        thisShare.totalPrice = int.parse(matches.elementAt(0).group(4).replaceAll(',', ''));
      } catch (e) {
        thisShare.quantity = 0;
      }
      sideShares.add(thisShare);
    }

    if (leftSharesElements.length > 0 || rightSharesElements.length > 0) {
      for (var shareLine in leftSharesElements) {
        addColor4Items(shareLine, leftShares);
      }
      for (var shareLine in rightSharesElements) {
        addColor4Items(shareLine, rightShares);
      }
    }

    // Activate trades widget
    _toggleTradesExpandable(
      active: true,
      leftMoney: leftMoney,
      leftItems: leftItems,
      leftProperties: leftProperties,
      leftShares: leftShares,
      rightMoney: rightMoney,
      rightItems: rightItems,
      rightProperties: rightProperties,
      rightShares: rightShares,
    );
  }

  /// Optional parameters required when [active] is true
  void _toggleTradesExpandable({
    @required bool active,
    int leftMoney,
    List<TradeItem> leftItems,
    List<TradeItem> leftProperties,
    List<TradeItem> leftShares,
    int rightMoney,
    List<TradeItem> rightItems,
    List<TradeItem> rightProperties,
    List<TradeItem> rightShares,
  }) {
    if (!active) {
      setState(() {
        _tradesFullActive = false;
        _tradesExpandable = SizedBox.shrink();
      });
      if (_tradesTimer != null) {
        _tradesTimer.cancel();
      }
    } else {
      setState(() {
        _tradesFullActive = true;
        _tradesExpandable = TradesWidget(
          leftMoney: leftMoney,
          leftItems: leftItems,
          leftProperties: leftProperties,
          leftShares: leftShares,
          rightMoney: rightMoney,
          rightItems: rightItems,
          rightProperties: rightProperties,
          rightShares: rightShares,
        );
      });
      // Make sure timer is not active, then activate it again so that we refresh
      // the page in case of item deletions
      if (_tradesTimer != null) {
        _tradesTimer.cancel();
      }
      if (_tradeRefreshActive) {
        _tradesTimer = Timer.periodic(Duration(seconds: 10), (Timer t) => _reloadTrades());
      }
    }
  }

  Future _reloadTrades() async {
    var html = await webView.getHtml();
    var document = parse(html);
    _assessTrades(document);
  }

  Widget _tradesMenuIcon() {
    if (_tradesIconActive) {
      return OpenContainer(
        transitionDuration: Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return TradesOptions(
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
            padding: const EdgeInsets.only(right: 20),
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
    _tradeCalculatorActive = await SharedPreferencesModel().getTradeCalculatorActive();
    _tradeRefreshActive = await SharedPreferencesModel().getTradeCalculatorRefresh();
    _reloadTrades();
  }

  // UTILS
  Future<bool> _willPopCallback() async {
    if (widget.customCallBack != null) {
      widget.customCallBack();
    }
    return true;
  }
}
