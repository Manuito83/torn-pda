import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebView2 extends StatefulWidget {
  final String customTitle;
  final String customUrl;
  final Function customCallBack;

  WebView2({
    this.customTitle = '',
    this.customCallBack,
    this.customUrl,
  });

  @override
  _WebView2State createState() => _WebView2State();
}

class _WebView2State extends State<WebView2> {
  InAppWebViewController webView;
  String _initialUrl = "";
  String _pageTitle = "";

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.customUrl;
    _pageTitle = widget.customTitle;

    // TODO: remove after testing
    print('TEST WebView used for $_initialUrl');
  }

  @override
  void dispose() {
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
        ),
        body: Container(
          color: Colors.black,
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: InAppWebView(
              initialUrl: _initialUrl,
              initialHeaders: {},
              initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                debuggingEnabled: true,
              )),
              onWebViewCreated: (InAppWebViewController controller) {
                webView = controller;
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _willPopCallback() async {
    widget.customCallBack();
    return true;
  }
}
