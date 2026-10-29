import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';

class ChatRemoteRoom {
  final String id;
  final String label;
  final Color? color;

  const ChatRemoteRoom(this.id, this.label, [this.color]);
}

/// Known by id, plus Remote Config
class ChatRooms {
  static const String travel = ChatRoom.travelId;
  static const String newPlayers = 'newplayers';

  /// Ticker group for everything else
  static const String other = 'custom';

  static const Map<String, String> labels = {
    'faction': 'Faction',
    'company': 'Company',
    'dm': 'Private chats',
    'global': 'Global',
    'trade': 'Trade',
    'poker': 'Poker',
    travel: 'Travel',
    newPlayers: 'New players',
    'hospital': 'Hospital',
    'jail': 'Jail',
  };

  static const Map<String, String> _occasional = {
    'poker': 'Only at a poker table',
    travel: 'Only while flying',
    newPlayers: 'Only for new players',
    'hospital': 'Only while in hospital',
    'jail': 'Only while in jail',
  };

  static List<ChatRemoteRoom> remote = const [];

  static List<String> get groups => [...labels.keys, for (final r in remote) r.id];

  static ChatRemoteRoom? remoteOf(String id) {
    for (final r in remote) {
      if (r.id == id) return r;
    }
    return null;
  }

  static bool isKnown(String id) =>
      id.startsWith('dm:') || (id != 'dm' && labels.containsKey(id)) || remoteOf(id) != null;

  static String group(String roomId) => roomId.startsWith('dm:') ? 'dm' : (isKnown(roomId) ? roomId : other);

  static String labelOf(String group) => labels[group] ?? remoteOf(group)?.label ?? 'Other rooms';

  /// Null for rooms Torn always lists
  static String? whenListed(String id) => _occasional[id] ?? (remoteOf(id) != null ? 'Only when Torn shows it' : null);

  static List<String> get occasional => [..._occasional.keys, for (final r in remote) r.id];

  static List<ChatRemoteRoom> parse(String raw) {
    Object? json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (json is! List) return const [];
    final rooms = <ChatRemoteRoom>[];
    for (final e in json) {
      if (e is! Map) continue;
      final id = e['id'];
      final label = e['label'];
      if (id is! String || label is! String || id.trim().isEmpty || label.trim().isEmpty) continue;
      if (id == 'dm' || id == other || id.startsWith('dm:') || labels.containsKey(id)) continue;
      if (rooms.any((r) => r.id == id)) continue;
      final color = e['color'];
      rooms.add(
        ChatRemoteRoom(
          id,
          label.trim(),
          color is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)
              ? Color(0xFF000000 | int.parse(color.substring(1), radix: 16))
              : null,
        ),
      );
    }
    return rooms;
  }
}

enum ChatRoomState { live, frozen, hidden }

class ChatFreeze {
  final DateTime since;

  /// Null until unfrozen by hand
  final DateTime? until;

  final ChatMuteFor? choice;

  const ChatFreeze(this.since, [this.until, this.choice]);

  bool activeAt(DateTime now) => until == null || until!.isAfter(now);

  static Map<String, ChatFreeze> decode(Iterable<String> entries) {
    final frozen = <String, ChatFreeze>{};
    for (final e in entries) {
      final parts = e.split('|');
      final choice = parts.length >= 4 ? ChatMuteFor.values.asNameMap()[parts.last] : null;
      if (choice != null) parts.removeLast();
      if (parts.length < 3) continue;
      final since = int.tryParse(parts[parts.length - 2]);
      final until = int.tryParse(parts.last);
      final id = parts.sublist(0, parts.length - 2).join('|');
      if (since == null || id.isEmpty) continue;
      frozen[id] = ChatFreeze(
        DateTime.fromMillisecondsSinceEpoch(since),
        until == null ? null : DateTime.fromMillisecondsSinceEpoch(until),
        choice,
      );
    }
    return frozen;
  }

  static List<String> encode(Map<String, ChatFreeze> frozen) => [
    for (final e in frozen.entries)
      '${e.key}|${e.value.since.millisecondsSinceEpoch}|${e.value.until?.millisecondsSinceEpoch ?? ''}'
      '${e.value.choice == null ? '' : '|${e.value.choice!.name}'}',
  ];

  static String thawText(Duration frozenFor) {
    final span = frozenFor.inHours >= 1 ? '${frozenFor.inHours}h' : '${math.max(1, frozenFor.inMinutes)}m';
    return 'Frozen for $span, messages from that time were not loaded';
  }
}
