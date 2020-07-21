import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/own_profile_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_options.dart';
import 'package:http/http.dart' as http;

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
                    onConsoleMessage:
                        (InAppWebViewController c, consoleMessage) {
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
  }

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
        var userProfile = await TornApiCaller.ownProfile(userDetailsProvider.myUser.userApiKey).getOwnProfile;
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
        for (var e in elements) {
          var stockItem = ForeignStockOutItem();
          stockItem.id =
              int.parse(expId.firstMatch(e.querySelector('[id^=item]').id)[0]);
          stockItem.quantity = int.parse(e
              .querySelector(".stck-amount")
              .innerHtml
              .replaceAll(RegExp(r"[^0-9]"), ""));
          stockItem.cost = int.parse(e
              .querySelector(".c-price")
              .innerHtml
              .replaceAll(RegExp(r"[^0-9]"), ""));
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

  Future<bool> _willPopCallback() async {
    if (widget.customCallBack != null) {
      widget.customCallBack();
    }
    return true;
  }
}
