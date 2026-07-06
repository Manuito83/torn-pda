import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';

/// Bridge-less 1x1 WebView mounted once at the app root
class BrowserEnginePrewarm extends StatelessWidget {
  const BrowserEnginePrewarm({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();
    final allowed = context.select<SettingsProvider, bool>((s) => s.browserEnginePrewarmRemoteConfigAllowed);
    if (!allowed) return const SizedBox.shrink();
    return const _PrewarmWebView();
  }
}

class _PrewarmWebView extends StatefulWidget {
  const _PrewarmWebView();

  @override
  State<_PrewarmWebView> createState() => _PrewarmWebViewState();
}

class _PrewarmWebViewState extends State<_PrewarmWebView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 1,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("about:blank")),
        initialSettings: InAppWebViewSettings(javaScriptBridgeEnabled: false, transparentBackground: true),
      ),
    );
  }
}
