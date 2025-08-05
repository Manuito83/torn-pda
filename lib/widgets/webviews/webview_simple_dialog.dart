// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/config/webview_config.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

import 'package:torn_pda/utils/shared_prefs.dart';

Future<void> openWebViewSimpleDialog({
  BuildContext? context,
  String? initUrl,
  Function? callBack,
  bool captchaWorkflow = false,
}) async {
  if (callBack == null && captchaWorkflow) {
    log("Error: no callback provided with captchaWorkflow!");
    return;
  }

  final double width = MediaQuery.of(context!).size.width;
  double hPad = 15;
  double frame = 6;

  if (width < 400) {
    hPad = 6;
    frame = 2;
  }

  final String restoredTheme = await Prefs().getAppTheme();

  return showDialog(
    useRootNavigator: false,
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Container(
          color: restoredTheme == "extraDark" ? const Color(0xFF131313) : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
            child: WebViewSimpleDialog(
              customUrl: initUrl,
              captchaWorkflow: captchaWorkflow,
              callback: callBack,
            ),
          ),
        ),
      );
    },
  );
}

class WebViewSimpleDialog extends StatefulWidget {
  final String? customUrl;
  final bool? captchaWorkflow;
  final Function? callback;

  const WebViewSimpleDialog({
    this.customUrl,
    this.captchaWorkflow,
    this.callback,
    super.key,
  });

  @override
  WebViewSimpleDialogState createState() => WebViewSimpleDialogState();
}

class WebViewSimpleDialogState extends State<WebViewSimpleDialog> {
  late InAppWebViewController webView;
  var _initialWebViewSettings = InAppWebViewSettings();

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  URLRequest? _initialUrl;

  // We need to destroy the webview before closing the dialog
  // See: https://github.com/flutter/flutter/issues/112542
  bool _requestClose = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _initialUrl = URLRequest(url: WebUri(widget.customUrl!));
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;

    _initialWebViewSettings = InAppWebViewSettings(
      transparentBackground: true,
      useOnLoadResource: true,
      //javaScriptCanOpenWindowsAutomatically: true,
      userAgent: Platform.isAndroid
          ? "Mozilla/5.0 (Linux; Android Torn PDA) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Version/4.0 Chrome/91.0.4472.114 Mobile Safari/537.36 ${WebviewConfig.agent}"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) "
              "CriOS/103.0.5060.54 Mobile/15E148 Safari/604.1 ${WebviewConfig.agent}",
      //supportMultipleWindows: true,
      initialScale: _settingsProvider.androidBrowserScale,
      useWideViewPort: false,

      allowsLinkPreview: _settingsProvider.iosAllowLinkPreview,
      disableLongPressContextMenuOnLinks: true,
      ignoresViewportScaleLimits: _settingsProvider.iosBrowserPinch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: buildScaffold(context),
    );
  }

  Widget buildScaffold(BuildContext context) {
    return PopScope(
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : Colors.grey[900]
            : _themeProvider.currentTheme == AppTheme.dark
                ? Colors.grey[900]
                : Colors.black,
        child: SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: _themeProvider.canvas,
            body: Container(
              // Background color for all browser widgets
              color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : _themeProvider.canvas,
              child: Column(
                children: [
                  Expanded(child: mainWebViewColumn()),
                  _quickBrowserBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickBrowserBottomBar() {
    return Container(
      color: _themeProvider.secondBackground,
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: IconButton(
              onPressed: () => webView.goBack(),
              icon: Icon(
                Icons.arrow_back_ios,
                color: _themeProvider.mainText,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                child: Container(
                  height: 30,
                  color: Colors.transparent, // Background to extend the buttons detection area
                  child: Center(
                    child: Text(
                      "CLOSE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _themeProvider.mainText,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                onTap: () async {
                  setState(() {
                    _requestClose = true;
                  });
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: IconButton(
              onPressed: () => webView.goForward(),
              icon: Icon(
                Icons.arrow_forward_ios,
                color: _themeProvider.mainText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Column mainWebViewColumn() {
    return Column(
      children: [
        Expanded(
          child: _requestClose ? const SizedBox.shrink() : _mainWebView(),
        ),
        // Widgets that go at the bottom if we have changes appbar to bottom
      ],
    );
  }

  InAppWebView _mainWebView() {
    return InAppWebView(
      initialUrlRequest: _initialUrl,
      initialSettings: _initialWebViewSettings,
      onWebViewCreated: (c) {
        webView = c;
      },
      /*
      onLoadStart: (c, uri) async {
        //
      },
      onProgressChanged: (c, progress) async {
        //
      },
      onLoadStop: (c, uri) async {
        //
      },
      onConsoleMessage: (controller, consoleMessage) {
        //
      },
      */
      onLoadResource: (c, resource) async {
        // If this is a widget captcha, try to capture the success message to request auth again
        if (widget.captchaWorkflow!) {
          if (resource.url.toString().contains("favicon.ico")) {
            // Try to get captcha success message twice in a row
            fireCallbackOnCaptchaSuccess(String value) {
              if (value.isNotEmpty && value.contains('"success"')) {
                widget.callback!("captchaWorkflow");
                Navigator.pop(context);
              }
            }

            webView.getHtml().then(
              (value) async {
                if (value != null) {
                  fireCallbackOnCaptchaSuccess(value);
                  return;
                }
                await Future.delayed(const Duration(milliseconds: 500));
                webView.getHtml().then((value) {
                  if (value != null) {
                    fireCallbackOnCaptchaSuccess(value);
                    return;
                  }
                });
              },
            );
          }
        }
        return;
      },
    );
  }
}
