// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';

class WebViewFullSingle extends StatefulWidget {
  final String customTitle;
  final String customUrl;
  final Function customCallBack;

  WebViewFullSingle({
    this.customUrl = 'https://www.torn.com',
    this.customTitle = '',
    this.customCallBack,
  });

  @override
  _WebViewFullSingleState createState() => _WebViewFullSingleState();
}

class _WebViewFullSingleState extends State<WebViewFullSingle> {
  InAppWebViewController webView;
  var _initialWebViewOptions = InAppWebViewGroupOptions();

  URLRequest _initialUrl;
  String _pageTitle = "";
  String _currentUrl = '';

  double progress = 0;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _initialUrl = URLRequest(url: Uri.parse(widget.customUrl));
    _pageTitle = widget.customTitle;
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _initialWebViewOptions = InAppWebViewGroupOptions(
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
    );
  }

  @override
  void dispose() {
    webView = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      // If we are launching from a dialog, it's important not to add the show case, in
      // case this is the first time, as there is no appBar to be found and it would
      // failed to open
      child: buildScaffold(context),

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
          appBar: _settingsProvider.appBarTop ? buildCustomAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildCustomAppBar(),
                )
              : null,
          body: Container(
            // Background color for all browser widgets
            color: Colors.grey[900],
            child: mainWebViewColumn(),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange[300]),
                      )
                    : Container(height: 2),
              )
            : SizedBox.shrink(),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: _initialUrl,
            initialOptions: _initialWebViewOptions,
            onWebViewCreated: (c) {
              webView = c;
            },
            onCreateWindow: (c, request) {
              // Allows IOS to open links with target=_blank
              webView.loadUrl(urlRequest: request.request);
              return;
            },
            onLoadStart: (c, uri) async {
              _currentUrl = uri.toString();
            },
            onProgressChanged: (c, progress) async {
              if (mounted) {
                setState(() {
                  this.progress = progress / 100;
                });
              }
            },
            onLoadStop: (c, uri) async {
              _currentUrl = uri.toString();
            },
          ),
        ),
        // Widgets that go at the bottom if we have changes appbar to bottom
      ],
    );
  }

  CustomAppBar buildCustomAppBar() {
    return CustomAppBar(
      genericAppBar: AppBar(
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        brightness: Brightness.dark,
        leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              Navigator.pop(context);
            }),
        title: Text(_pageTitle),
        actions: <Widget>[],
      ),
    );
  }

  Future<bool> _willPopCallback() async {
    return false;
  }
}
