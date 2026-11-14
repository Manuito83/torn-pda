import 'dart:convert';

import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

/// DM push settings, safe in the background
class ChatPushRules {
  const ChatPushRules({
    this.ignored = const {},
    this.muted = const {},
    this.mutedUntil = const {},
    this.levels = const {},
    this.quiet,
    this.tones = const {},
    this.soundForAll,
  });

  factory ChatPushRules.of(ChatPrefs prefs) {
    bool dm(String id) => id.startsWith('dm:');
    return ChatPushRules(
      ignored: prefs.ignored.keys.toSet(),
      muted: prefs.muted.where(dm).toSet(),
      mutedUntil: {
        for (final e in prefs.mutedUntil.entries)
          if (dm(e.key)) e.key: e.value,
      },
      levels: {
        for (final e in prefs.alertLevels.entries)
          if (dm(e.key)) e.key: e.value,
      },
      quiet: prefs.quietHours ? (prefs.quietFrom, prefs.quietTo) : null,
      tones: {
        for (final e in prefs.tones.entries)
          if (dm(e.key)) e.key: e.value,
      },
      soundForAll: prefs.allSound,
    );
  }

  /// Anything unreadable lets every push through
  factory ChatPushRules.decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map;
      final quiet = map['quiet'] as List?;
      return ChatPushRules(
        ignored: {for (final id in map['ignored'] as List) id as int},
        muted: {for (final id in map['muted'] as List) '$id'},
        mutedUntil: {
          for (final e in (map['until'] as Map).entries)
            '${e.key}': DateTime.fromMillisecondsSinceEpoch(e.value as int),
        },
        levels: {
          for (final e in (map['levels'] as Map).entries) '${e.key}': ChatAlertLevel.values.byName('${e.value}'),
        },
        quiet: quiet == null ? null : (quiet[0] as int, quiet[1] as int),
        tones: decodeChatTones([for (final t in map['tones'] as List) '$t']),
        soundForAll: ChatSound.values.where((s) => s.name == map['sound']).firstOrNull,
      );
    } catch (_) {
      return const ChatPushRules();
    }
  }

  final Set<int> ignored;
  final Set<String> muted;
  final Map<String, DateTime> mutedUntil;
  final Map<String, ChatAlertLevel> levels;

  /// Minutes since midnight, null when off
  final (int, int)? quiet;
  final Map<String, ChatTone> tones;

  /// Null keeps the default per room
  final ChatSound? soundForAll;

  String encode() => jsonEncode({
    'ignored': ignored.toList(),
    'muted': muted.toList(),
    'until': {for (final e in mutedUntil.entries) e.key: e.value.millisecondsSinceEpoch},
    'levels': {for (final e in levels.entries) e.key: e.value.name},
    'quiet': quiet == null ? null : [quiet!.$1, quiet!.$2],
    'tones': encodeChatTones(tones),
    'sound': soundForAll?.name,
  });

  bool allows(int senderId, DateTime now) {
    final range = quiet;
    if (ignored.contains(senderId)) return false;
    if (range != null && ChatPrefs.inQuietRange(range.$1, range.$2, now.hour * 60 + now.minute)) return false;
    final room = ChatRoom.dmId(senderId);
    final silenced = muted.contains(room) || (mutedUntil[room]?.isAfter(now) ?? false);
    return ChatAlertMatcher.shouldAlert(levels[room] ?? ChatAlertLevel.all, muted: silenced, match: null);
  }

  ChatTone toneFor(int senderId) =>
      (tones[ChatRoom.dmId(senderId)] ?? ChatTone.standard).resolve(soundForAll, ChatRoom.dmId(senderId));
}
