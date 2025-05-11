// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';

class WebViewFullAwh extends StatefulWidget {
  final String customTitle;
  final String customUrl;
  final String sellerName;
  final int sellerId;
  final Function awhMessageCallback;

  const WebViewFullAwh({
    required this.customUrl,
    required this.customTitle,
    required this.sellerName,
    required this.sellerId,
    required this.awhMessageCallback,
  });

  @override
  WebViewFullAwhState createState() => WebViewFullAwhState();
}

class WebViewFullAwhState extends State<WebViewFullAwh> {
  InAppWebViewController? webView;
  var _initialWebViewSettings = InAppWebViewSettings();
  URLRequest? _initialUrl;
  String _pageTitle = "";

  double progress = 0;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _initialUrl = URLRequest(url: WebUri(widget.customUrl));
    _pageTitle = widget.customTitle;
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _initialWebViewSettings = InAppWebViewSettings();
  }

  @override
  void dispose() {
    webView?.dispose();
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
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        right: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
        left: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildCustomAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildCustomAppBar(),
                )
              : null,
          body: Container(
            // Background color for all browser widgets
            color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.grey[900],
            child: mainWebViewColumn(),
          ),
        ),
      ),
    );
  }

  Column mainWebViewColumn() {
    return Column(
      children: [
        if (_settingsProvider.loadBarBrowser)
          SizedBox(
            height: 2,
            child: progress < 1.0
                ? LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.blueGrey[100],
                    valueColor: AlwaysStoppedAnimation<Color?>(Colors.deepOrange[300]),
                  )
                : Container(height: 2),
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: _initialUrl,
            initialSettings: _initialWebViewSettings,
            onWebViewCreated: (c) {
              webView = c;
              // For Arson Warehouse
              webView!.addJavaScriptHandler(
                handlerName: 'copyToClipboard',
                callback: (args) {
                  if (args.isNotEmpty) {
                    // Copy custom message or total
                    String toastMessage = "";
                    if (args[1] == "total") {
                      toastMessage = "Total of \$${args[0]} copied to the clipboard!";
                      Clipboard.setData(ClipboardData(text: args[0]));
                    } else if (args[1] == "message") {
                      if (widget.sellerId > 0) {
                        toastMessage = "Message copied, close this window to message ${widget.sellerName}!";
                        Clipboard.setData(ClipboardData(text: args[0]));
                        widget.awhMessageCallback();
                      } else {
                        toastMessage = "Message copied to the clipboard!";
                        Clipboard.setData(ClipboardData(text: args[0]));
                      }
                    }

                    BotToast.showText(
                      text: toastMessage,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: Colors.green[800]!,
                      contentPadding: const EdgeInsets.all(10),
                    );
                  }
                },
              );
            },
            onCreateWindow: (c, request) async {
              // Allows IOS to open links with target=_blank
              webView!.loadUrl(urlRequest: request.request);
              return true;
            },
            onLoadStart: (c, uri) async {},
            onProgressChanged: (c, progress) async {
              if (mounted) {
                setState(() {
                  this.progress = progress / 100;
                });
              }
            },
            onLoadStop: (c, uri) async {},
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            // Try to avoid errors when closing on iOS
            await Future.delayed(const Duration(milliseconds: 100));
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
        title: Text(_pageTitle),
        actions: const <Widget>[],
      ),
    );
  }

  Future<bool> _willPopCallback() async {
    return false;
  }
}
