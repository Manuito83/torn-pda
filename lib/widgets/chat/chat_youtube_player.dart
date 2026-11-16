import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_youtube.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openInYoutube(String url) async {
  NativeChat.playingVideo.value = null;
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  await NativeChat.openLink(url);
}

/// Player plus its title and buttons
class ChatYoutubeInline extends StatelessWidget {
  const ChatYoutubeInline({
    super.key,
    required this.videoId,
    required this.url,
    required this.title,
    required this.color,
  });

  final String videoId;
  final String url;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChatInsertFrame(
      color: color,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ChatYoutubePlayer(key: ValueKey(videoId), videoId: videoId, url: url),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Open in YouTube',
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  onPressed: () => openInYoutube(url),
                ),
                IconButton(
                  tooltip: 'Stop the video',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => NativeChat.playingVideo.value = null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatYoutubePlayer extends StatefulWidget {
  const ChatYoutubePlayer({super.key, required this.videoId, required this.url});

  final String videoId;
  final String url;

  @override
  State<ChatYoutubePlayer> createState() => _ChatYoutubePlayerState();
}

class _ChatYoutubePlayerState extends State<ChatYoutubePlayer> with WidgetsBindingObserver {
  late final InAppWebViewSettings _settings;
  Timer? _timeout;
  Worker? _pip;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _settings = InAppWebViewSettings(
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      transparentBackground: true,
      supportZoom: false,
      useShouldOverrideUrlLoading: true,
      javaScriptBridgeForMainFrameOnly: true,
      hardwareAcceleration: context.read<WebViewProvider>().webViewHardwareLayerActive,
      isInspectable: kDebugMode || settings.browserRemoteDebugging,
      // Never take the app down
      useOnRenderProcessGone: true,
    );
    _timeout = Timer(const Duration(seconds: 20), _fail);
    WidgetsBinding.instance.addObserver(this);
    if (Get.isRegistered<PipController>()) {
      _pip = ever(Get.find<PipController>().inPip, (bool on) {
        if (on) NativeChat.playingVideo.value = null;
      });
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _pip?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) NativeChat.playingVideo.value = null;
  }

  void _fail() {
    _timeout?.cancel();
    if (mounted && !_failed) setState(() => _failed = true);
  }

  void _onPlayer(List<dynamic> args) {
    final message = args.isEmpty ? null : args.first;
    if (message is! Map) return;
    if (message['state'] == 'ready') _timeout?.cancel();
    if (message['state'] == 'error') _fail();
  }

  NavigationActionPolicy _navigate(NavigationAction action) {
    final url = action.request.url;
    if (!action.isForMainFrame || url == null || url.scheme == 'about') return NavigationActionPolicy.ALLOW;
    if (url.toString().replaceFirst(RegExp(r'/$'), '') == ChatYoutube.origin) return NavigationActionPolicy.ALLOW;
    openInYoutube(url.scheme.startsWith('http') ? url.toString() : widget.url);
    return NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _error(context);
    return InAppWebView(
      initialData: InAppWebViewInitialData(data: ChatYoutube.page(widget.videoId), baseUrl: WebUri(ChatYoutube.origin)),
      initialSettings: _settings,
      onWebViewCreated: (c) => c.addJavaScriptHandler(handlerName: 'pdaYoutube', callback: _onPlayer),
      shouldOverrideUrlLoading: (_, action) async => _navigate(action),
      onWebContentProcessDidTerminate: (_) => _fail(),
      onRenderProcessGone: (_, _) => _fail(),
    );
  }

  Widget _error(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("This video can't play here", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
            TextButton.icon(
              onPressed: () => openInYoutube(widget.url),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open in YouTube'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
