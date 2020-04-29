import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum WebViewType {
  generic,
  attack,
  profile,
  travelAgency,
  docTorn,
}

class TornWebView extends StatefulWidget {
  final String targetId;
  final String targetName;
  final String genericTitle;
  final WebViewType webViewType;
  final Function tornCallback;

  /// [targetId] and [targetName] make sense for targets and attacks.
  /// [tornCallback] is used to update the target card when we go back
  /// [webViewType] determines the actual URL and logic
  TornWebView({
    this.targetId = '',
    this.targetName = '',
    this.genericTitle,
    this.tornCallback,
    this.webViewType = WebViewType.profile,
  });

  @override
  _TornWebViewState createState() => _TornWebViewState();
}

class _TornWebViewState extends State<TornWebView> {
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
      case WebViewType.attack:
        _initialUrl = 'https://www.torn.com/loader.php?sid=attack&user2'
            'ID=${widget.targetId}';
        _pageTitle = 'Attack ${widget.targetName}';
        break;
      case WebViewType.profile:
        _initialUrl =
            'https://www.torn.com/profiles.php?XID=${widget.targetId}';
        _pageTitle = '${widget.targetName}\'s profile';
        break;
      case WebViewType.travelAgency:
        _initialUrl = 'https://www.torn.com/travelagency.php';
        _pageTitle = 'Travel Agency';
        break;
      case WebViewType.docTorn:
        _initialUrl = 'https://doctorn.rocks/travel-hub/';
        _pageTitle = 'Travel Hub';
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
              if (widget.tornCallback != null) {
                widget.tornCallback();
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
