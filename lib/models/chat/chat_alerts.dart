import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_models.dart';

enum ChatAlertLevel { all, mentions, none }

enum ChatMuteFor {
  hour('1 hour'),
  eightHours('8 hours'),
  tomorrow('Until tomorrow'),
  always('Until I unmute');

  const ChatMuteFor(this.label);

  final String label;

  String get freezeLabel => this == always ? 'Until I unfreeze' : label;

  DateTime? until(DateTime now) => switch (this) {
    hour => now.add(const Duration(hours: 1)),
    eightHours => now.add(const Duration(hours: 8)),
    // Small hours still count as tonight
    tomorrow => DateTime(now.year, now.month, now.day + (now.hour < 4 ? 0 : 1), 8),
    always => null,
  };
}

DateTime? chatLandingTime(BarsStatusCooldownsModel? bars, DateTime now) {
  final landing = bars?.travel?.timestamp ?? 0;
  if (bars?.status?.state != 'Traveling' || landing * 1000 <= now.millisecondsSinceEpoch) return null;
  return DateTime.fromMillisecondsSinceEpoch(landing * 1000);
}

class ChatMatch {
  final bool mention;
  final String? keyword;

  const ChatMatch({this.mention = false, this.keyword});
}

class ChatAlert {
  final ChatMessage message;

  /// Null when alerting on every message
  final ChatMatch? match;
  bool seen;

  final bool demo;

  ChatAlert(this.message, this.match, {this.seen = false, this.demo = false});
}

/// Whole words, any case
class ChatAlertMatcher {
  ChatAlertMatcher({String? name, List<String> keywords = const []})
    : _name = name == null || name.trim().isEmpty ? null : _word(name.trim()),
      _keywords = {for (final k in keywords.map((k) => k.trim()).where((k) => k.isNotEmpty)) k: _word(k)};

  final RegExp? _name;
  final Map<String, RegExp> _keywords;

  bool get isEmpty => _name == null && _keywords.isEmpty;

  ChatMatch? match(String content) {
    final mention = _name?.hasMatch(content) ?? false;
    String? keyword;
    for (final e in _keywords.entries) {
      if (e.value.hasMatch(content)) {
        keyword = e.key;
        break;
      }
    }
    return mention || keyword != null ? ChatMatch(mention: mention, keyword: keyword) : null;
  }

  static RegExp _word(String term) =>
      RegExp('(?<![\\p{L}\\p{N}_])${RegExp.escape(term)}(?![\\p{L}\\p{N}_])', caseSensitive: false, unicode: true);

  static bool shouldAlert(ChatAlertLevel level, {required bool muted, required ChatMatch? match}) {
    if (level == ChatAlertLevel.none) return false;
    final mentioned = match?.mention ?? false;
    if (muted) return level == ChatAlertLevel.mentions && mentioned;
    return level == ChatAlertLevel.all || mentioned;
  }
}
