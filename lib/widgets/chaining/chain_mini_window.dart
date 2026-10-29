import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/config/webview_config.dart';
import 'package:torn_pda/main.dart' show navigatorKey;
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_engine.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/chain_web.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

const bool chainMiniEnabled = kDebugMode || bool.fromEnvironment('CHAIN_MINI');

const String chainMiniUrl = 'https://www.torn.com/factions.php?step=your#/war/chain';

// Lightest page with the sidebar bars
const String _barsPageUrl = 'https://www.torn.com/calendar.php';

// Torn hides the timer below 785 px
const String _viewportScript = r'''
(function () {
  var c = 'width=1000';
  function wide(m) {
    if (m.content !== c) m.content = c;
  }
  var mine = document.createElement('meta');
  mine.name = 'viewport';
  wide(mine);
  document.documentElement.appendChild(mine);
  var obs = new MutationObserver(function () {
    document.querySelectorAll('meta[name="viewport"]').forEach(wide);
  });
  obs.observe(document.documentElement, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ['content'],
  });
  window.addEventListener('load', function () {
    obs.disconnect();
  });
})();
''';

const String _isolateScript = r'''
(function () {
  if (window.__pdaChainMini) return window.__pdaChainMini();
  var BAR = 'a[class*="chainBar___"]';
  var base = document.createElement('style');
  base.textContent =
    'html, body { background: #1e1e1e !important; overflow: hidden !important; }' +
    'body * { visibility: hidden !important; }' +
    BAR + ', ' + BAR + ' * { visibility: visible !important; }' +
    BAR + ' { position: fixed !important; left: 0 !important; margin: 0 !important; z-index: 2147483647 !important; }';
  var fitted = document.createElement('style');
  (document.head || document.documentElement).append(base, fitted);
  var natural = 0;
  var tries = 0;
  function fit() {
    var b = document.querySelector(BAR);
    if (!b) {
      if (tries++ < 60) setTimeout(fit, 300);
      return;
    }
    if (!natural) natural = b.offsetHeight || 20;
    // Room for "1234 / 2500 (04:59)"
    var z = Math.min(innerHeight / natural, innerWidth / 155);
    var top = Math.max(0, (innerHeight - natural * z) / 2) / z;
    fitted.textContent = BAR + ' { width: ' + innerWidth / z + 'px !important; top: ' + top +
      'px !important; zoom: ' + z + ' !important; box-sizing: border-box !important; }';
  }
  window.addEventListener('resize', fit);
  window.__pdaChainMini = fit;
  fit();
})();
''';

enum _MiniState { loading, live, reload }

class ChainMiniWindow {
  ChainMiniWindow._();

  static final open = ValueNotifier<bool>(false);

  // Survive the unmount while browsing
  static Offset? pos;
  static int size = 1;

  // Remote Config can only turn it off
  static final available = ValueNotifier<bool>(chainMiniEnabled);

  // Needs the page reader
  static void setRemote({required bool mini, required bool web}) {
    available.value = chainMiniEnabled && mini && web;
    if (!available.value) open.value = false;
  }

  static void toggle() {
    if (available.value) open.value = !open.value;
  }

  static bool hiddenByBrowser(BuildContext context) =>
      context.select<WebViewProvider?, bool>((w) => w?.browserShowInForeground ?? false);
}

class ChainMiniHost extends StatelessWidget {
  const ChainMiniHost({super.key});

  @override
  Widget build(BuildContext context) {
    final hidden = ChainMiniWindow.hiddenByBrowser(context);
    final mini = ValueListenableBuilder<bool>(
      valueListenable: ChainMiniWindow.open,
      builder: (context, open, _) => open && !hidden ? const _ChainMiniFrame() : const SizedBox.shrink(),
    );
    if (!Get.isRegistered<PipController>()) return mini;
    final pip = Get.find<PipController>();
    return Positioned.fill(
      child: Obx(() => Offstage(offstage: pip.inPip.value, child: Stack(children: [mini]))),
    );
  }
}

class _ChainMiniFrame extends StatefulWidget {
  const _ChainMiniFrame();

  @override
  State<_ChainMiniFrame> createState() => _ChainMiniFrameState();
}

class _ChainMiniFrameState extends State<_ChainMiniFrame> with WidgetsBindingObserver {
  static const _widths = [200.0, 260.0, 340.0];
  static const _closeWidth = 26.0;
  static const _barAspect = 5.5;
  static const _labelHeight = 12.0;

  int _generation = 0;
  _MiniState _state = _MiniState.loading;
  InAppWebViewController? _controller;
  Timer? _noBar;

  double get _width => _widths[ChainMiniWindow.size];
  double get _height => (_width - _closeWidth) / _barAspect + _labelHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armNoBar();
  }

  // Counts from opening, not from load stop
  void _armNoBar() {
    _noBar?.cancel();
    _noBar = Timer(const Duration(seconds: 30), () {
      if (mounted && _state == _MiniState.loading) _toReload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noBar?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _publishShown();

  bool get _visible {
    if (!mounted || !ChainMiniWindow.open.value) return false;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return false;
    return !(Get.isRegistered<PipController>() && Get.find<PipController>().inPip.value);
  }

  // Stable identity for the controller
  late final bool Function() _onScreen = _isOnScreen;

  bool _isOnScreen() => _visible && _state == _MiniState.live;

  void _publishShown() {
    final shown = _visible;
    _controller?.evaluateJavascript(
      source:
          'window.__pdaChainShown = $shown; '
          'if ($shown && window.__pdaChainReader) window.__pdaChainReader.check(true);',
    );
  }

  void _onReading(JavaScriptHandlerFunctionData data) {
    if (!mounted) return;
    final raw = data.args.isEmpty ? null : data.args.first;
    // The sidebar renders after load
    if (raw is Map && raw['none'] == true) {
      if (_state == _MiniState.live) _toReload();
      return;
    }
    _noBar?.cancel();
    if (_state != _MiniState.live) {
      setState(() => _state = _MiniState.live);
      // The fit stops looking after 18 s
      _controller?.evaluateJavascript(source: _isolateScript);
    }
    if (Get.isRegistered<ChainStatusController>()) {
      Get.find<ChainStatusController>().applyWebChain(raw, onScreen: _onScreen);
    }
  }

  void _toReload() => setState(() {
    _controller = null;
    _state = _MiniState.reload;
  });

  void _reload() {
    setState(() {
      _controller = null;
      _state = _MiniState.loading;
      _generation++;
    });
    _armNoBar();
  }

  void _openInBrowser() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.context.read<WebViewProvider>().openBrowserPreference(
      context: nav.context,
      url: chainMiniUrl,
      browserTapType: BrowserTapType.short,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    var pos = ChainMiniWindow.pos ?? Offset(screen.width - _width - 12, screen.height - pad.bottom - _height - 96);
    pos = Offset(
      pos.dx.clamp(0, (screen.width - _width).clamp(0, double.infinity)),
      pos.dy.clamp(pad.top, (screen.height - _height - pad.bottom).clamp(pad.top, double.infinity)),
    );

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: _width,
      height: _height,
      child: Material(
        color: const Color(0xFF1E1E1E),
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _state == _MiniState.reload ? _reload : _openInBrowser,
                onLongPress: () =>
                    setState(() => ChainMiniWindow.size = (ChainMiniWindow.size + 1) % _widths.length),
                onPanUpdate: (d) => setState(() => ChainMiniWindow.pos = pos + d.delta),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: _labelHeight,
                      child: Padding(
                        padding: EdgeInsets.only(left: 6, top: 2),
                        child: Text(
                          'Live browser view',
                          style: TextStyle(color: Colors.white38, fontSize: 8, height: 1),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_state != _MiniState.reload) IgnorePointer(child: _webView()),
                          if (_state != _MiniState.live)
                            ColoredBox(
                              color: const Color(0xFF1E1E1E),
                              child: Center(
                                child: Text(
                                  _state == _MiniState.loading ? 'Loading...' : 'Tap to reload',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ChainMiniWindow.open.value = false,
              child: const SizedBox(
                width: _closeWidth,
                child: Icon(Icons.close, size: 16, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _userAgentSuffix {
    const unknown = '##deviceBrand=unknown##deviceModel=unknown##deviceSoftware=unknown##';
    final device = WebviewConfig.userAgentForUser.isNotEmpty ? WebviewConfig.userAgentForUser : unknown;
    return '${WebviewConfig.agent} $device'.trim();
  }

  Widget _webView() {
    final settings = context.read<SettingsProvider>();
    return InAppWebView(
      key: ValueKey(_generation),
      initialUrlRequest: URLRequest(url: WebUri(_barsPageUrl)),
      initialSettings: InAppWebViewSettings(
        transparentBackground: false,
        useOnRenderProcessGone: true,
        useShouldOverrideUrlLoading: true,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        supportZoom: false,
        builtInZoomControls: false,
        disableVerticalScroll: true,
        disableHorizontalScroll: true,
        overScrollMode: OverScrollMode.NEVER,
        preferredContentMode: Platform.isIOS ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.RECOMMENDED,
        applicationNameForUserAgent: _userAgentSuffix,
        textZoom: 100,
        mediaPlaybackRequiresUserGesture: true,
        isInspectable: kDebugMode || settings.browserRemoteDebugging,
        contentBlockers: [if (NativeChat.compiled) tchatBundleBlocker],
      ),
      initialUserScripts: UnmodifiableListView([
        UserScript(source: _viewportScript, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
        if (NativeChat.compiled) tchatGuardScript,
      ]),
      onWebViewCreated: (c) {
        _controller = c;
        c.addJavaScriptHandler(handlerName: chainWebHandler, callback: _onReading);
      },
      shouldOverrideUrlLoading: (c, action) async {
        final url = action.request.url;
        final isBarsPage = url?.host == 'www.torn.com' && url?.path == Uri.parse(_barsPageUrl).path;
        return isBarsPage && action.isForMainFrame ? NavigationActionPolicy.ALLOW : NavigationActionPolicy.CANCEL;
      },
      onLoadStop: (c, url) async {
        if (url?.path != Uri.parse(_barsPageUrl).path) {
          if (mounted) _toReload();
          return;
        }
        await c.evaluateJavascript(source: _isolateScript);
        await c.evaluateJavascript(source: 'window.__pdaChainShown = true;\n$chainWebReader');
      },
      onRenderProcessGone: (c, detail) {
        if (mounted) _toReload();
      },
    );
  }
}
