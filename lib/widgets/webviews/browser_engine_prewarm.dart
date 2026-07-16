import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';

/// Warms the Android WebView engine right before the first real browser webview is built
/// The first bridge-enabled webview of a cold process can race Chromium's browser startup: registering
/// document-start scripts before startup completes throws "Must be started before we block!" and the
/// platform view create fails (#2843, blank webview)
class BrowserEnginePrewarmController {
  BrowserEnginePrewarmController._();
  static final BrowserEnginePrewarmController instance = BrowserEnginePrewarmController._();

  final ValueNotifier<bool> shouldMount = ValueNotifier<bool>(false);
  Completer<void>? _loaded;

  /// Completes when the engine is warm (the prewarm finished loading about:blank). Never holds the
  /// browser open for longer than [timeout].
  Future<void> ensureWarm({Duration timeout = const Duration(seconds: 5)}) {
    if (_loaded != null) return _loaded!.future;
    final completer = Completer<void>();
    _loaded = completer;
    // Mutating the notifier during build would drop the rebuild in release; defer out of the build
    Future.microtask(() => shouldMount.value = true);
    Timer(timeout, () {
      if (completer.isCompleted) return;
      try {
        if (!Platform.isWindows) {
          FirebaseCrashlytics.instance.recordError("Prewarm ensureWarm timeout", null, fatal: false);
        }
      } catch (_) {}
      completer.complete();
    });
    return completer.future;
  }

  void _onLoadStop() {
    if (_loaded != null && !_loaded!.isCompleted) _loaded!.complete();
  }
}

/// Mounted once at the app root
class BrowserEnginePrewarm extends StatelessWidget {
  const BrowserEnginePrewarm({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();
    final allowed = context.select<SettingsProvider, bool>((s) => s.browserEnginePrewarmRemoteConfigAllowed);
    if (!allowed) return const SizedBox.shrink();
    final renderGoneAllowed = context.select<SettingsProvider, bool>(
      (s) => s.browserRenderProcessGoneRemoteConfigAllowed,
    );
    return ValueListenableBuilder<bool>(
      valueListenable: BrowserEnginePrewarmController.instance.shouldMount,
      builder: (context, mount, _) {
        if (!mount) return const SizedBox.shrink();
        return SizedBox(
          width: 1,
          height: 1,
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri("about:blank")),
            initialSettings: InAppWebViewSettings(
              javaScriptBridgeEnabled: false,
              transparentBackground: true,
              useOnRenderProcessGone: renderGoneAllowed,
            ),
            onLoadStop: (c, u) => BrowserEnginePrewarmController.instance._onLoadStop(),
          ),
        );
      },
    );
  }
}
