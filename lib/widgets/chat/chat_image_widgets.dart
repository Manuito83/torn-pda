import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_upload_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/download_error.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatUploadSetupNotice extends StatelessWidget {
  const ChatUploadSetupNotice({super.key, required this.host, this.blockedMessage, this.excluded, this.onPicked});

  final ChatImageHost host;

  final String? blockedMessage;

  final ChatImageHost? excluded;

  /// After a pick or a saved key
  final VoidCallback? onPicked;

  /// A blocked service is not offered again
  static List<ChatImageHost> choices({ChatImageHost? excluded}) => [
    for (final h in ChatImageHost.values)
      if (h != excluded) h,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final blocked = blockedMessage != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          blocked ? 'Could not upload the image' : 'Images need an upload service',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 2),
        Text(
          blockedMessage ?? '${host.label} needs its ${host.credentialName} first. Pick a service',
          style: small,
        ),
        if (blocked) Text('Try another one:', style: small),
        for (final h in choices(excluded: blocked ? host : excluded))
          Semantics(
            container: true,
            inMutuallyExclusiveGroup: true,
            checked: !blocked && h == host,
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  !blocked && h == host ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                ),
                title: Text(h.label),
                subtitle: Text(
                  '${h.note} - up to ${h.maxMegabytes} MB',
                  style: small,
                ),
                onTap: () {
                  NativeChat.prefs.setImageHost(h);
                  onPicked?.call();
                },
              ),
            ),
          ),
        Wrap(
          children: [
            if (!blocked && host.needsCredential)
              TextButton.icon(
                onPressed: () async {
                  await ChatUploadSettingsPage.editCredential(context, host);
                  onPicked?.call();
                },
                icon: const Icon(Icons.key_rounded, size: 18),
                label: Text('Paste the ${host.credentialName}'),
              ),
            if (!blocked && host.needsCredential)
              TextButton.icon(
                onPressed: () => ChatUploadSettingsPage.openRegister(host),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text('Register at ${host.label}'),
              ),
            TextButton.icon(
              onPressed: () {
                NativeChat.hideQuickWindows();
                final navigator = NativeChat.navigatorKey?.currentState ?? Navigator.of(context);
                showChatSettings(navigator, imageUpload: true);
              },
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Image upload settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatImages {
  ChatImages._();

  static const int maxBytes = 8 * 1024 * 1024;
  static const int _cacheBytes = 40 * 1024 * 1024;
  static final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  static final Map<String, Future<Uint8List>> _loading = {};

  static final Set<String> shown = {};

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      maxRedirects: 3,
    ),
  );

  // Hosts here can see the viewer's IP
  static final RegExp autoLoadHosts = RegExp(
    r'^(i\.imgur\.com|i\.ibb\.co|files\.catbox\.moe|litter\.catbox\.moe|media\.tenor\.com'
    r'|media\d*\.giphy\.com|cdn\.discordapp\.com|media\.discordapp\.net)$',
  );

  /// Anything unsure counts as public
  static bool closedRoom(ChatRoom? room) =>
      room != null && (room.isDm || room.type == ChatRoomType.custom || room.id == 'faction' || room.id == 'company');

  static bool autoLoads(ChatLink link, ChatRoom? room) {
    final prefs = NativeChat.prefs;
    if (!(closedRoom(room) ? prefs.imagesPrivate : prefs.imagesPublic)) return false;
    return link.isTorn || autoLoadHosts.hasMatch(link.uri.host.toLowerCase());
  }

  static Uint8List? cached(String url) {
    final bytes = _cache.remove(url);
    if (bytes != null) _cache[url] = bytes;
    return bytes;
  }

  static Future<Uint8List> load(String url) => _loading[url] ??= _fetch(url).whenComplete(() {
    _loading.remove(url);
  });

  static Future<Uint8List> _fetch(String url) async {
    final cancel = CancelToken();
    final response = await ChatLinkPreviews.getPublic<List<int>>(
      _dio,
      Uri.parse(url.replaceFirst(RegExp('^http:', caseSensitive: false), 'https:')),
      cancelToken: cancel,
      onReceiveProgress: (received, total) {
        if (total > maxBytes || received > maxBytes) cancel.cancel('too big');
      },
    );
    final type = response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';
    if (!type.startsWith('image/') && !type.startsWith('application/octet-stream')) {
      throw const FormatException('not an image');
    }
    final bytes = Uint8List.fromList(response.data ?? const []);
    if (bytes.isEmpty) throw const FormatException('empty');
    _cache[url] = bytes;
    var total = _cache.values.fold<int>(0, (sum, b) => sum + b.length);
    while (total > _cacheBytes && _cache.length > 1) {
      total -= _cache.remove(_cache.keys.first)!.length;
    }
    return bytes;
  }
}

class ChatImageCard extends StatefulWidget {
  const ChatImageCard({super.key, required this.link, required this.color, this.roomId});

  final ChatLink link;
  final Color color;
  final String? roomId;

  @override
  State<ChatImageCard> createState() => _ChatImageCardState();
}

class _ChatImageCardState extends State<ChatImageCard> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    if (ChatImages.shown.contains(widget.link.url) || _auto) _show();
  }

  bool get _auto => ChatImages.autoLoads(
    widget.link,
    widget.roomId == null ? null : NativeChat.controller.roomById(widget.roomId!),
  );

  @override
  void didUpdateWidget(ChatImageCard old) {
    super.didUpdateWidget(old);
    if (old.link.url == widget.link.url) return;
    _bytes = null;
    if (ChatImages.shown.contains(widget.link.url) || _auto) _show();
  }

  void _show() {
    final url = widget.link.url;
    final cached = ChatImages.cached(url);
    _bytes = cached != null ? SynchronousFuture(cached) : ChatImages.load(url);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.link.url));
    chatToast('Link copied', seconds: 1);
  }

  Widget _card({required String title, required Widget action, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final color = widget.color;
    final segments = widget.link.uri.pathSegments.where((s) => s.isNotEmpty);
    return Material(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: _copy,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 20, color: color.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.65), fontSize: 10),
                    ),
                    Text(
                      widget.link.uri.host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                    if (segments.isNotEmpty)
                      Text(
                        segments.last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              action,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final top = widget.link.isTorn ? 'Torn image' : 'Image';
    final bytes = _bytes;
    if (bytes == null) {
      void show() {
        ChatImages.shown.add(widget.link.url);
        setState(_show);
      }

      return Semantics(
        image: true,
        label: 'Image from ${widget.link.uri.host}, not loaded',
        onTap: show,
        onTapHint: 'show',
        onLongPress: _copy,
        onLongPressHint: 'copy link',
        excludeSemantics: true,
        child: _card(
          title: top,
          onTap: show,
          action: TextButton(
            onPressed: show,
            style: TextButton.styleFrom(
              foregroundColor: color,
              visualDensity: VisualDensity.compact,
              backgroundColor: color.withValues(alpha: 0.1),
            ),
            child: const Text('Show'),
          ),
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _card(
            title: describeDownloadError(snapshot.error!).blocked
                ? 'The site may be blocked in your country'
                : 'Could not load the image',
            onTap: () => NativeChat.openLink(widget.link.url),
            action: IconButton(
              tooltip: 'Retry',
              icon: Icon(Icons.refresh_rounded, size: 20, color: color.withValues(alpha: 0.8)),
              onPressed: () => setState(_show),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Container(
            width: 160,
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: color.withValues(alpha: 0.7)),
            ),
          );
        }
        final side = (240 * MediaQuery.devicePixelRatioOf(context)).round();
        return GestureDetector(
          onTap: () => _openChatImageViewer(context, widget.link, data),
          onLongPress: _copy,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240, maxHeight: 220, minWidth: 48, minHeight: 48),
              child: Image(
                image: ResizeImage(MemoryImage(data), width: side, height: side, policy: ResizeImagePolicy.fit),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: 'Image from ${widget.link.uri.host}',
                errorBuilder: (context, _, _) => _card(
                  title: 'Not a valid image',
                  onTap: () => NativeChat.openLink(widget.link.url),
                  action: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openChatImageViewer(BuildContext context, ChatLink link, Uint8List bytes) async {
  var navigator = Navigator.maybeOf(context);
  if (navigator == null) {
    NativeChat.hideQuickWindows();
    navigator = NativeChat.navigatorKey?.currentState;
  }
  await navigator?.push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ChatImageViewer(link: link, bytes: bytes),
    ),
  );
}

class ChatImageViewer extends StatefulWidget {
  const ChatImageViewer({super.key, required this.link, required this.bytes});

  final ChatLink link;
  final Uint8List bytes;

  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer> {
  final TransformationController _zoom = TransformationController();
  TapDownDetails? _doubleTap;
  bool _saving = false;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      _zoom.value = Matrix4.identity();
      return;
    }
    final at = _doubleTap?.localPosition ?? Offset.zero;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-at.dx * 1.5, -at.dy * 1.5, 0, 1)
      ..scaleByDouble(2.5, 2.5, 1, 1);
  }

  Future<void> _download() async {
    final share = context.read<SettingsProvider>().downloadActionShare;
    final origin = Rect.fromLTWH(0, 0, MediaQuery.sizeOf(context).width, MediaQuery.sizeOf(context).height / 2);
    setState(() => _saving = true);
    try {
      final segments = widget.link.uri.pathSegments.where((s) => s.isNotEmpty);
      final name = (segments.isEmpty ? 'image.png' : segments.last).replaceAll(RegExp(r'[^\w.-]'), '_');
      if (share) {
        final folder = '${(await getTemporaryDirectory()).path}/downloads';
        final file = await File('$folder/$name').create(recursive: true);
        await file.writeAsBytes(widget.bytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], sharePositionOrigin: origin));
      } else {
        await Gal.putImageBytes(widget.bytes, name: name.replaceFirst(RegExp(r'\.[^.]*$'), ''));
        chatToast('Saved to gallery', seconds: 2);
      }
    } on GalException catch (e) {
      chatToast(switch (e.type) {
        GalExceptionType.accessDenied => 'No access to the gallery. Allow it in the system settings',
        GalExceptionType.notEnoughSpace => 'Not enough space to save the image',
        _ => 'Could not save the image',
      }, seconds: 4);
    } catch (_) {
      chatToast('Could not save the image', seconds: 3);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final side = (size.longestSide * MediaQuery.devicePixelRatioOf(context) * 2).round().clamp(1024, 4096);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.link.uri.host, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Open link',
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () => NativeChat.openLink(widget.link.url),
          ),
          IconButton(
            tooltip: 'Download',
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: _saving ? null : _download,
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: (details) => _doubleTap = details,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _zoom,
          maxScale: 8,
          child: SizedBox.expand(
            child: Image(
              image: ResizeImage(MemoryImage(widget.bytes), width: side, height: side, policy: ResizeImagePolicy.fit),
              fit: BoxFit.contain,
              semanticLabel: 'Image from ${widget.link.uri.host}',
              errorBuilder: (context, _, _) => const Center(
                child: Text('Not a valid image', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
