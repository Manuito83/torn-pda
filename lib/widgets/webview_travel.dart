import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/travel/foreign_stock_out.dart';
import 'package:torn_pda/models/user_details_model.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

enum WebViewTypeTravel {
  generic,
  travelAgency,
  docTorn,
  arsonWarehouse,
}

class TornWebViewTravel extends StatefulWidget {
  final String genericTitle;
  final WebViewTypeTravel webViewType;
  final Function genericCallBack;

  /// [genericCallBack] is used to update when we go back
  /// [webViewType] determines the actual URL and logic
  TornWebViewTravel({
    this.genericTitle,
    this.genericCallBack,
    this.webViewType = WebViewTypeTravel.travelAgency,
  });

  @override
  _TornWebViewTravelState createState() => _TornWebViewTravelState();
}

class _TornWebViewTravelState extends State<TornWebViewTravel> {
  WebViewController _controller;

  String _initialUrl = "";
  String _pageTitle = "";

  @override
  void initState() {
    super.initState();
    switch (widget.webViewType) {
      case WebViewTypeTravel.generic:
        _initialUrl = 'https://www.torn.com/';
        _pageTitle = '${widget.genericTitle}';
        break;
      case WebViewTypeTravel.travelAgency:
        _initialUrl = 'https://www.torn.com/travelagency.php';
        _pageTitle = 'Travel Agency';
        break;
      case WebViewTypeTravel.docTorn:
        _initialUrl = 'https://doctorn.rocks/travel-hub/';
        _pageTitle = 'DoctorN';
        break;
      case WebViewTypeTravel.arsonWarehouse:
        _initialUrl = 'https://arsonwarehouse.com/foreign-stock';
        _pageTitle = 'Arson Warehouse';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.genericCallBack != null) {
                widget.genericCallBack();
              }
              Navigator.pop(context);
            }),
        title: Text(_pageTitle),
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          top: false,
          right: false,
          left: false,
          bottom: true,
          child: Builder(
            builder: (BuildContext context) {
              return WebView(
                initialUrl: _initialUrl,
                javascriptMode: JavascriptMode.unrestricted,
                javascriptChannels: <JavascriptChannel>[
                  JavascriptChannel(
                    name: 'Source',
                    onMessageReceived: (JavascriptMessage msg) {
                      _sendStockInformation(msg.message);
                    },
                  ),
                ].toSet(),
                onWebViewCreated: (WebViewController c) {
                  _controller = c;
                },
                onPageFinished: (value) => _loadSourceCode(),
                gestureNavigationEnabled: true,
              );
            },
          ),
        ),
      ),
    );
  }

  void _loadSourceCode() async {
    await _controller.evaluateJavascript(
        'Source.postMessage(document.documentElement.outerHTML)');
  }

  void _sendStockInformation(String source) async {
    var document = parse(source);
    var elements = document.querySelectorAll('.item-info-wrap');

    if (elements.length > 0) {
      try {
        // Parse stocks
        var stockModel = ForeignStockOutModel();

        var userDetailsProvider =
            Provider.of<UserDetailsProvider>(context, listen: false);
        var userProfile =
            await TornApiCaller.userDetails(userDetailsProvider.myUser.userApiKey)
                .getUserDetails;
        if (userProfile is UserDetailsModel) {
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
}
