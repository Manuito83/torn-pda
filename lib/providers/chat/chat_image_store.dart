import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';

typedef ChatImageFetch = Future<Uint8List?> Function(String url, int maxBytes);

class ChatImageStore {
  ChatImageStore({
    Future<Directory> Function()? locate,
    ChatImageFetch? fetch,
    this.maxBytes = 32 << 20,
    this.maxFileBytes = 4 << 20,
    this.recentMax = 40,
    this.retryAfter = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : _locate = locate ?? getApplicationCacheDirectory,
       _fetch = fetch ?? chatImageDownload,
       _clock = clock ?? DateTime.now;

  static final ChatImageStore instance = ChatImageStore();

  final int maxBytes;
  final int maxFileBytes;
  final int recentMax;
  final Duration retryAfter;

  final Future<Directory> Function() _locate;
  final ChatImageFetch _fetch;
  final DateTime Function() _clock;

  Future<Directory>? _opening;
  final Map<String, Future<Uint8List?>> _inflight = {};
  final Map<String, DateTime> _failedAt = {};
  final Set<String> _touched = {};
  int? _total;
  int _generation = 0;
  List<String>? _recent;
  Timer? _recentTimer;

  static String keyOf(String url) => sha1.convert(utf8.encode(url)).toString();

  static bool validUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
  }

  Future<Directory> _dir() => _opening ??= _prepare().catchError((Object e) {
    _opening = null;
    throw e;
  });

  Future<Directory> _prepare() async {
    final dir = Directory('${(await _locate()).path}/chat_images');
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String url) async => File('${(await _dir()).path}/${keyOf(url)}.img');

  Future<Uint8List?> bytes(String url) async {
    if (!validUrl(url)) return null;
    final cached = await _read(url);
    if (cached != null) return cached;
    final failed = _failedAt[url];
    if (failed != null && _clock().difference(failed) < retryAfter) return null;
    return _inflight[url] ??= _obtain(url).whenComplete(() {
      _inflight.remove(url);
    });
  }

  Future<Uint8List?> _read(String url) async {
    try {
      final file = await _file(url);
      if (!await file.exists()) return null;
      final data = await file.readAsBytes();
      if (data.isEmpty) {
        await file.delete();
        return null;
      }
      if (_touched.add(url)) await file.setLastModified(_clock());
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<bool> has(String url) async {
    try {
      return await (await _file(url)).exists();
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> _obtain(String url) async {
    final generation = _generation;
    Uint8List? data;
    try {
      data = await _fetch(url, maxFileBytes);
    } catch (_) {
      data = null;
    }
    if (data == null || data.isEmpty || data.length > maxFileBytes) {
      if (generation == _generation) _failedAt[url] = _clock();
      return null;
    }
    _failedAt.remove(url);
    await _write(url, data, generation);
    return data;
  }

  Future<void> _write(String url, Uint8List data, int generation) async {
    try {
      final file = await _file(url);
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(data, flush: true);
      if (generation != _generation) {
        await temp.delete();
        return;
      }
      await temp.rename(file.path);
      await file.setLastModified(_clock());
      _touched.add(url);
      _total = _total == null ? await _scan() : _total! + data.length;
      if (_total! > maxBytes) await _prune();
    } catch (_) {}
  }

  Future<int> _scan() async {
    var sum = 0;
    await for (final e in (await _dir()).list()) {
      if (e is File && e.path.endsWith('.img')) sum += await e.length();
    }
    return sum;
  }

  Future<void> _prune() async {
    try {
      final files = <(File, DateTime, int)>[];
      await for (final e in (await _dir()).list()) {
        if (e is File && e.path.endsWith('.tmp')) {
          await e.delete();
          continue;
        }
        if (e is! File || !e.path.endsWith('.img')) continue;
        final stat = await e.stat();
        files.add((e, stat.modified, stat.size));
      }
      var total = files.fold(0, (sum, f) => sum + f.$3);
      files.sort((a, b) => a.$2.compareTo(b.$2));
      final target = maxBytes * 3 ~/ 4;
      for (final f in files) {
        if (total <= target) break;
        await f.$1.delete();
        total -= f.$3;
      }
      _total = total;
    } catch (_) {
      _total = null;
    }
  }

  Future<void> forget(String url) async {
    try {
      final file = await _file(url);
      if (await file.exists()) {
        _total = null;
        await file.delete();
      }
    } catch (_) {}
  }

  Future<List<String>> _loadRecent() async {
    if (_recent case final list?) return list;
    var list = <String>[];
    try {
      final file = File('${(await _dir()).path}/recent.json');
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is List) list = [for (final u in raw) if (u is String) u];
      }
    } catch (_) {}
    return _recent ??= list;
  }

  Future<void> remember(String url) async {
    if (!validUrl(url)) return;
    try {
      final list = await _loadRecent();
      if (list.isNotEmpty && list.first == url) return;
      list
        ..remove(url)
        ..insert(0, url);
      if (list.length > recentMax) list.removeRange(recentMax, list.length);
      _recentTimer ??= Timer(const Duration(seconds: 3), flush);
    } catch (_) {}
  }

  /// Avatars shown lately, newest first
  Future<List<String>> recent() async {
    try {
      return List.of(await _loadRecent());
    } catch (_) {
      return const [];
    }
  }

  Future<void> flush() async {
    _recentTimer?.cancel();
    _recentTimer = null;
    final list = _recent;
    if (list == null) return;
    try {
      await File('${(await _dir()).path}/recent.json').writeAsString(jsonEncode(list), flush: true);
    } catch (_) {}
  }

  Future<void> clear() async {
    _generation++;
    _recentTimer?.cancel();
    _recentTimer = null;
    _recent = [];
    _total = 0;
    _touched.clear();
    _failedAt.clear();
    try {
      final dir = await _dir();
      await for (final e in dir.list()) {
        await e.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> warm(Iterable<String> urls) async {
    final seen = <String>{};
    for (final url in urls) {
      if (!seen.add(url) || !validUrl(url) || !await has(url)) continue;
      final done = Completer<void>();
      final stream = ChatImage(url, store: this).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, _) {
          if (!done.isCompleted) done.complete();
        },
        onError: (_, _) {
          if (!done.isCompleted) done.complete();
        },
      );
      stream.addListener(listener);
      await done.future.timeout(const Duration(seconds: 5), onTimeout: () {});
      stream.removeListener(listener);
    }
  }
}

final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.bytes,
  ),
);

/// Null unless an image; network errors throw
Future<Uint8List?> chatImageDownload(String url, int maxBytes) async {
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
  if (!type.startsWith('image/') && !type.startsWith('application/octet-stream')) return null;
  final data = response.data;
  if (data == null || data.isEmpty || data.length > maxBytes) return null;
  return Uint8List.fromList(data);
}

@immutable
class ChatImage extends ImageProvider<ChatImage> {
  const ChatImage(this.url, {this.store});

  static const int _maxWidth = 160;

  final String url;
  final ChatImageStore? store;

  @override
  Future<ChatImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(ChatImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _open(decode), scale: 1);

  Future<ui.Codec> _open(ImageDecoderCallback decode) async {
    final source = store ?? ChatImageStore.instance;
    final data = await source.bytes(url);
    if (data == null) throw StateError('Chat image not available');
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(data);
      return await decode(
        buffer,
        getTargetSize: (w, h) =>
            w > _maxWidth ? const ui.TargetImageSize(width: _maxWidth) : ui.TargetImageSize(width: w, height: h),
      );
    } catch (_) {
      await source.forget(url);
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) => other is ChatImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'ChatImage(${ChatImageStore.keyOf(url).substring(0, 8)})';
}
