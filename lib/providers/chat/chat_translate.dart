import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ChatTranslation {
  const ChatTranslation({this.text, this.from, this.failed = false});

  static const ChatTranslation loading = ChatTranslation();

  final String? text;

  final String? from;
  final bool failed;

  bool get isLoading => text == null && !failed;
}

class ChatTranslator extends ChangeNotifier {
  ChatTranslator({Future<(String, String?)?> Function(String text, String target)? fetch})
    : _fetch = fetch ?? translate;

  static const int _maxCached = 200;

  static const Map<String, String> languages = {
    'en': 'English',
    'es': 'Español',
    'pt': 'Português',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'nl': 'Nederlands',
    'pl': 'Polski',
    'ro': 'Română',
    'sv': 'Svenska',
    'tr': 'Türkçe',
    'ru': 'Русский',
    'uk': 'Українська',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'id': 'Bahasa Indonesia',
    'vi': 'Tiếng Việt',
  };

  static final Dio _dio = Dio(
    BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 8)),
  );

  final Future<(String, String?)?> Function(String text, String target) _fetch;

  final LinkedHashMap<String, ChatTranslation> _cache = LinkedHashMap();
  final Set<String> _shown = {};

  static String deviceLanguage() => PlatformDispatcher.instance.locale.languageCode;

  /// Null when hidden
  ChatTranslation? shownFor(String messageId, String target) =>
      _shown.contains(messageId) ? _cache['$target|$messageId'] ?? ChatTranslation.loading : null;

  bool isShown(String messageId) => _shown.contains(messageId);

  void hide(String messageId) {
    if (_shown.remove(messageId)) notifyListeners();
  }

  Future<void> show(String messageId, String text, String target) async {
    final key = '$target|$messageId';
    _shown.add(messageId);
    final cached = _cache[key];
    if (cached != null && !cached.failed) {
      notifyListeners();
      return;
    }
    _cache[key] = ChatTranslation.loading;
    notifyListeners();
    (String, String?)? result;
    try {
      result = await _fetch(text, target);
    } catch (_) {
      result = null;
    }
    _cache.remove(key);
    _cache[key] = result == null
        ? const ChatTranslation(failed: true)
        : ChatTranslation(text: result.$1, from: result.$2);
    while (_cache.length > _maxCached) {
      _cache.remove(_cache.keys.first);
    }
    notifyListeners();
  }

  /// Google first, MyMemory when it fails
  static Future<(String, String?)?> translate(String text, String target) async =>
      parseGoogle(
        await _get('https://translate.googleapis.com/translate_a/single', {
          'client': 'gtx',
          'sl': 'auto',
          'tl': target,
          'dt': 't',
          'q': text,
        }),
      ) ??
      parseMyMemory(
        await _get('https://api.mymemory.translated.net/get', {'q': text, 'langpair': 'autodetect|$target'}),
      );

  static Future<dynamic> _get(String url, Map<String, dynamic> query) async {
    try {
      return (await _dio.get<dynamic>(url, queryParameters: query)).data;
    } on DioException {
      return null;
    }
  }

  static (String, String?)? parseGoogle(dynamic json) {
    if (json is! List || json.isEmpty || json.first is! List) return null;
    final text = [
      for (final segment in json.first as List)
        if (segment is List && segment.isNotEmpty && segment.first is String) segment.first as String,
    ].join();
    if (text.trim().isEmpty) return null;
    return (text, json.length > 2 && json[2] is String ? json[2] as String : null);
  }

  static (String, String?)? parseMyMemory(dynamic json) {
    if (json is! Map || json['responseStatus'] != 200) return null;
    final data = json['responseData'];
    if (data is! Map || data['translatedText'] is! String) return null;
    final text = data['translatedText'] as String;
    if (text.trim().isEmpty) return null;
    final from = data['detectedLanguage'];
    return (text, from is String && from.isNotEmpty ? from : null);
  }
}
