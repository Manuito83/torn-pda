import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/config/webview_config.dart';
import 'package:torn_pda/models/chat/chat_bazaar.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Small browser for chat links
class ChatLinkWindow extends StatefulWidget {
  const ChatLinkWindow({super.key, required this.url, required this.tap, required this.area});

  final String url;
  final int tap;
  final Rect area;

  static const Size size = Size(360, 520);

  @override
  State<ChatLinkWindow> createState() => _ChatLinkWindowState();
}

class _ChatLinkWindowState extends State<ChatLinkWindow> {
  late final InAppWebViewSettings _settings;
  InAppWebViewController? _web;
  late String _url = widget.url;
  String? _fill = NativeChat.linkWindow.value?.fill;
  String _title = '';
  double _progress = 0;
  bool _canBack = false;
  bool _expanded = false;
  Rect? _frame;
  int _build = 0;
  ModalRoute<dynamic>? _popRoute;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    final device = WebviewConfig.userAgentForUser.isNotEmpty
        ? WebviewConfig.userAgentForUser
        : '##deviceBrand=unknown##deviceModel=unknown##deviceSoftware=unknown##';
    _settings = InAppWebViewSettings(
      javaScriptBridgeEnabled: false,
      hardwareAcceleration: context.read<WebViewProvider>().webViewHardwareLayerActive,
      applicationNameForUserAgent: '${WebviewConfig.agent} $device'.trim(),
      initialScale: settings.androidBrowserScale,
      useWideViewPort: false,
      ignoresViewportScaleLimits: settings.iosBrowserPinch,
      isInspectable: kDebugMode || settings.browserRemoteDebugging,
      useOnRenderProcessGone: settings.browserRenderProcessGoneRemoteConfigAllowed,
    );
    _trackRoute();
    NativeChat.rootTop.addListener(_trackRoute);
  }

  @override
  void dispose() {
    NativeChat.rootTop.removeListener(_trackRoute);
    // ignore: deprecated_member_use
    if (_popRoute?.subtreeContext != null) _popRoute!.removeScopedWillPopCallback(_back);
    super.dispose();
  }

  // Beats PopScope to the back press
  void _trackRoute() {
    final top = NativeChat.rootTop.value;
    final route = top is ModalRoute ? top : null;
    if (route == _popRoute) return;
    // ignore: deprecated_member_use
    if (_popRoute?.subtreeContext != null) _popRoute!.removeScopedWillPopCallback(_back);
    // ignore: deprecated_member_use
    _popRoute = route?..addScopedWillPopCallback(_back);
  }

  Future<bool> _back() async {
    NativeChat.closeLinkWindow();
    return false;
  }

  @override
  void didUpdateWidget(ChatLinkWindow old) {
    super.didUpdateWidget(old);
    if (widget.tap == old.tap) return;
    _url = widget.url;
    _fill = NativeChat.linkWindow.value?.fill;
    final web = _web;
    if (web == null) {
      setState(() => _build++);
    } else {
      web.loadUrl(urlRequest: URLRequest(url: WebUri(_url)));
    }
  }

  void _visited(InAppWebViewController c, WebUri? url) {
    if (url != null && url.scheme.startsWith('http')) _url = url.toString();
    c.canGoBack().then((v) {
      if (mounted && v != _canBack) setState(() => _canBack = v);
    });
  }

  void _fillSearch(InAppWebViewController c, WebUri? url) {
    final name = _fill;
    if (name == null || url == null || url.host != 'www.torn.com' || !url.path.endsWith('bazaar.php')) return;
    if (url.queryParameters['userId'] != Uri.parse(widget.url).queryParameters['userId']) return;
    _fill = null;
    c.evaluateJavascript(source: ChatBazaar.fillScript(name));
  }

  Future<void> _toBrowser({required bool newTab}) async {
    final now = (await _web?.getUrl())?.toString() ?? _url;
    await NativeChat.openUrl(now.startsWith('http') ? now : _url, newTab: newTab);
  }

  Widget _iconButton(String tooltip, IconData icon, VoidCallback? onPressed) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      iconSize: 20,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final area = widget.area;
    final frame = _expanded
        ? area
        : ChatWindowFrame.fit(
            _frame ??
                Rect.fromCenter(
                  center: area.center,
                  width: ChatLinkWindow.size.width,
                  height: ChatLinkWindow.size.height,
                ),
            area,
          );
    final host = Uri.tryParse(_url)?.host ?? '';
    final moves = {
      if (!_expanded)
        for (final MapEntry(key: label, value: direction) in ChatWindowFrame.moves(frame, area).entries)
          CustomSemanticsAction(label: label): () =>
              setState(() => _frame = ChatWindowFrame.nudge(frame, area, direction)),
    };
    return Positioned.fromRect(
      rect: frame,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: BlockSemantics(
          child: Semantics(
            container: true,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: 'Link preview',
            onDismiss: NativeChat.closeLinkWindow,
            child: Material(
              color: scheme.surface,
              elevation: 10,
              shadowColor: Colors.black54,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: _expanded
                        ? null
                        : (d) => setState(() => _frame = ChatWindowFrame.fit(frame.shift(d.delta), area)),
                    onPanEnd: (d) {
                      final v = d.velocity.pixelsPerSecond;
                      if (v.dy > 700 && v.dy > v.dx.abs()) NativeChat.closeLinkWindow();
                    },
                    child: Container(
                      color: scheme.surfaceContainer,
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Row(
                            children: [
                              _iconButton('Back', Icons.arrow_back_rounded, _canBack ? () => _web?.goBack() : null),
                              Expanded(
                                child: Semantics(
                                  container: true,
                                  customSemanticsActions: moves,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _title.isEmpty ? host : _title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        host,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _iconButton(
                                _expanded ? 'Shrink' : 'Enlarge',
                                _expanded ? Icons.close_fullscreen_rounded : Icons.open_in_full_rounded,
                                () => setState(() => _expanded = !_expanded),
                              ),
                              _iconButton('Close', Icons.close_rounded, NativeChat.closeLinkWindow),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 2,
                    child: _progress < 1 ? LinearProgressIndicator(value: _progress, minHeight: 2) : null,
                  ),
                  Expanded(
                    child: InAppWebView(
                      key: ValueKey(_build),
                      initialUrlRequest: URLRequest(url: WebUri(_url)),
                      initialSettings: _settings,
                      onWebViewCreated: (c) => _web = c,
                      onTitleChanged: (c, title) {
                        if (mounted) setState(() => _title = title ?? '');
                      },
                      onProgressChanged: (c, progress) {
                        if (mounted) setState(() => _progress = progress / 100);
                      },
                      onUpdateVisitedHistory: (c, url, _) => _visited(c, url),
                      onLoadStop: (c, url) {
                        _visited(c, url);
                        _fillSearch(c, url);
                      },
                      onWebContentProcessDidTerminate: (c) => c.reload(),
                      onRenderProcessGone: (c, _) {
                        _web = null;
                        if (!mounted) return;
                        // Shared renderer died, only redraw if seen
                        if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
                          NativeChat.closeLinkWindow();
                        } else {
                          setState(() => _build++);
                        }
                      },
                    ),
                  ),
                  Container(
                    color: scheme.surfaceContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.tab_rounded, size: 18),
                            label: const Text('Main tab'),
                            onPressed: () => _toBrowser(newTab: false),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.add_box_outlined, size: 18),
                            label: const Text('New tab'),
                            onPressed: () => _toBrowser(newTab: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
