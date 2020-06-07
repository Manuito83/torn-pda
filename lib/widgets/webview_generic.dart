import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum WebViewType {
  generic,
  profile,
  travelAgency,
  docTorn,
  arsonWarehouse,
}

class TornWebViewGeneric extends StatefulWidget {
  final String profileId;
  final String profileName;
  final String genericTitle;
  final WebViewType webViewType;
  final Function genericCallBack;

  /// [profileId] and [profileName] make sense for targets and attacks.
  /// [genericCallBack] is used to update the target card when we go back
  /// [webViewType] determines the actual URL and logic
  TornWebViewGeneric({
    this.profileId = '',
    this.profileName = '',
    this.genericTitle,
    this.genericCallBack,
    this.webViewType = WebViewType.profile,
  });

  @override
  _TornWebViewGenericState createState() => _TornWebViewGenericState();
}

class _TornWebViewGenericState extends State<TornWebViewGeneric> {
  WebViewController _controller;

  String _initialUrl = "";
  String _pageTitle = "";

  @override
  void initState() {
    super.initState();
    switch (widget.webViewType) {
      case WebViewType.generic:
        _initialUrl = 'https://www.torn.com/';
        _pageTitle = '${widget.genericTitle}';
        break;
      case WebViewType.profile:
        _initialUrl =
            'https://www.torn.com/profiles.php?XID=${widget.profileId}';
        _pageTitle = '${widget.profileName}\'s profile';
        break;
      case WebViewType.travelAgency:
        _initialUrl = 'https://www.torn.com/travelagency.php';
        _pageTitle = 'Travel Agency';
        break;
      case WebViewType.docTorn:
        _initialUrl = 'https://doctorn.rocks/travel-hub/';
        _pageTitle = 'DoctorN';
        break;
      case WebViewType.arsonWarehouse:
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
      body: Builder(
        builder: (BuildContext context) {
          return WebView(
            initialUrl: _initialUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController c) {
              _controller = c;
            },
            gestureNavigationEnabled: true,
          );
        },
      ),
    );
  }
}
