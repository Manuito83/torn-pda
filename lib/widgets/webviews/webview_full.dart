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
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/html_parser.dart' as pdaParser;
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_options.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/widgets/trades_widget.dart';

class TradeItem {
  String name;
  int quantity;
  int priceUnit;
  int totalPrice;
}

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

  var _tradesActive = false;
  Widget _tradesExpandable = SizedBox.shrink();
  var _tradesController = ExpandableController();

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.customUrl;
    _pageTitle = widget.customTitle;
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

                      webView.addJavaScriptHandler(
                        handlerName: 'stocksChannel',
                        callback: (args) {
                          _sendStockInformation(args[0]);
                        },
                      );

                      _assessGeneral();
                    },
                    onConsoleMessage: (InAppWebViewController c, consoleMessage) {
                      //print("TORN PDA JS CONSOLE: " + consoleMessage.message);
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
      _assessTravelStocks();
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

  Future _assessTravelStocks() async {
    // TODO: WTF? This can go. Try.
    await webView.evaluateJavascript(source: addForeignStocksEventJS());
    await webView.evaluateJavascript(source: getForeignStocksJS());
  }

  void _sendStockInformation(String html) async {
    var document = parse(html);
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
    if (h4 != null) {
      var pageTitle = h4.innerHtml.substring(0).toLowerCase().trim();
      var easyUrl = _currentUrl.replaceAll('#', '').replaceAll('/', '').split('&');
      if (!pageTitle.contains('trade') ||
          !easyUrl[0].contains('trade.php') ||
          (!easyUrl[0].contains('step=initiateTrade') && !easyUrl[0].contains('step=view'))) {
        if (_tradesActive) {
          _tradesActive = false;
          _toggleTradesExpandable(active: false);
        }
        return;
      }
    } else {
      return;
    }

    // Final items
    int leftMoney;
    int rightMoney;
    var leftItems = List<TradeItem>();
    var rightItems = List<TradeItem>();

    // Because only the frame reloads, if we can't find anything
    // we'll wait 1 second, get the html again and query again
    var totalFinds = document
        .querySelectorAll(".color1 .left , .color2 .left , .color1 .right , .color2 .right");

    var leftMoneyElements;
    var leftItemsElements;
    var rightMoneyElements;
    var rightItemsElements;
    if (totalFinds.length == 0) {
      await Future.delayed(const Duration(seconds: 1));
      var updatedHtml = await webView.getHtml();
      var updatedDoc = parse(updatedHtml);
      leftMoneyElements = updatedDoc.querySelectorAll(".left .color1 .name");
      leftItemsElements = updatedDoc.querySelectorAll(".left .color2 .name");
      rightMoneyElements = updatedDoc.querySelectorAll(".right .color1 .name");
      rightItemsElements = updatedDoc.querySelectorAll(".right .color2 .name");
    }

    // Left side money
    if (leftMoneyElements.length > 0) {
      var row = leftMoneyElements[0] as dom.Element;
      RegExp regExp = new RegExp(r"([0-9][,]{0,3})+");
      try {
        var match = regExp.stringMatch(row.innerHtml);
        leftMoney = int.parse(match.replaceAll(",", ""));
      } catch (e) {
        leftMoney = 0;
      }
    }

    // Right side money
    if (rightMoneyElements.length > 0) {
      var row = rightMoneyElements[0] as dom.Element;
      RegExp regExp = new RegExp(r"([0-9][,]{0,3})+");
      try {
        var match = regExp.stringMatch(row.innerHtml);
        rightMoney = int.parse(match.replaceAll(",", ""));
      } catch (e) {
        rightMoney = 0;
      }
    }

    // Sum of left side items
    if (leftItemsElements.length > 0 || rightItemsElements.length > 0) {
      var userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
      var allTornItems = await TornApiCaller.items(userProvider.myUser.userApiKey).getItems;
      if (allTornItems is ApiError) {
        return;
      } else if (allTornItems is ItemsModel) {
        // Loop left
        for (var leftRow in leftItemsElements) {
          var thisItem = TradeItem();
          var row = pdaParser.HtmlParser.fix(leftRow.innerHtml.trim());
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
          leftItems.add(thisItem);
        }
        // Loop right
        for (var rightRow in rightItemsElements) {
          var thisItem = TradeItem();
          var row = pdaParser.HtmlParser.fix(rightRow.innerHtml.trim());
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

          rightItems.add(thisItem);
        }
      }
    }

    if (leftMoney != null ||
        rightMoney != null ||
        leftItems.length != 0 ||
        rightItems.length != 0) {
      _toggleTradesExpandable(
        active: true,
        leftMoney: leftMoney,
      );
    } else {
      _toggleTradesExpandable(active: false);
    }
  }

  /// Optional parameters required when [active] is true
  void _toggleTradesExpandable({
    @required bool active,
    int leftMoney,
  }) {
    setState(() {
      if (!active) {
        _tradesActive = false;
        _tradesExpandable = SizedBox.shrink();
      } else {
        _tradesActive = true;
        _tradesController.expanded = true;
        _tradesExpandable = ExpandablePanel(
          theme: ExpandableThemeData(
            hasIcon: false,
            tapBodyToCollapse: false,
            tapHeaderToExpand: false,
          ),
          collapsed: SizedBox.shrink(),
          controller: _tradesController,
          header: SizedBox.shrink(),
          expanded: TradesWidget(
            leftMoney: leftMoney,
          ),
        );
      }
    });
  }

  // UTILS
  Future<bool> _willPopCallback() async {
    if (widget.customCallBack != null) {
      widget.customCallBack();
    }
    return true;
  }
}
