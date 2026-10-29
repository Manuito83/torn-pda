import 'dart:convert';

import 'package:torn_pda/models/chat/chat_models.dart';

/// Last inbox the player saw
class ChatInboxSnapshot {
  const ChatInboxSnapshot({required this.owner, required this.rooms, required this.last, required this.unread});

  static const int _maxPreview = 80;

  final int owner;

  final List<ChatRoom> rooms;
  final Map<String, ChatMessage> last;
  final Map<String, int> unread;

  List<String> get order => [for (final r in rooms) r.id];

  String encode() => jsonEncode({
    'owner': owner,
    'rooms': [for (final r in rooms) _room(r)],
    'last': {for (final e in last.entries) e.key: _message(e.value)},
    'unread': unread,
  });

  static ChatInboxSnapshot? decode(String? raw, int owner) {
    if (raw == null || raw.isEmpty || owner <= 0) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map || map['owner'] != owner) return null;
      final rooms = [for (final r in map['rooms'] as List) ?_roomFrom(r)];
      if (rooms.isEmpty) return null;
      final last = <String, ChatMessage>{};
      for (final e in (map['last'] as Map).entries) {
        if (_messageFrom('${e.key}', e.value) case final m?) last['${e.key}'] = m;
      }
      return ChatInboxSnapshot(
        owner: owner,
        rooms: rooms,
        last: last,
        unread: {for (final e in (map['unread'] as Map).entries) '${e.key}': e.value as int},
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, Object?> _room(ChatRoom r) => {
    'id': r.id,
    'name': r.name,
    'type': r.type.name,
    'write': r.canWrite,
    'icon': r.icon,
    if (!r.reportTyping) 'reportTyping': false,
    if (r.peer case final p?) 'peer': {'id': p.id, 'name': p.name, 'avatar': p.avatarUrl},
  };

  static ChatRoom? _roomFrom(dynamic json) {
    if (json is! Map || json['id'] is! String || json['name'] is! String) return null;
    final peer = json['peer'];
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ChatRoomType.values.firstWhere((t) => t.name == json['type'], orElse: () => ChatRoomType.official),
      canWrite: json['write'] != false,
      icon: json['icon'] as String?,
      reportTyping: json['reportTyping'] != false,
      peer: peer is Map && peer['id'] is int
          ? ChatUser(id: peer['id'] as int, name: '${peer['name']}', avatarUrl: peer['avatar'] as String?)
          : null,
    );
  }

  static Map<String, Object?> _message(ChatMessage m) => {
    'id': m.id,
    'sender': {'id': m.sender.id, 'name': m.sender.name},
    'text': m.content.length > _maxPreview ? m.content.substring(0, _maxPreview) : m.content,
    'at': m.createdAt.millisecondsSinceEpoch,
    'system': m.isSystem,
  };

  static ChatMessage? _messageFrom(String roomId, dynamic json) {
    if (json is! Map || json['id'] is! String || json['at'] is! int || json['sender'] is! Map) return null;
    final sender = json['sender'] as Map;
    return ChatMessage(
      id: json['id'] as String,
      roomId: roomId,
      sender: ChatUser(id: sender['id'] as int, name: '${sender['name']}'),
      content: '${json['text']}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
      isSystem: json['system'] == true,
    );
  }
}

// New rows keep their sorted slot
List<ChatRoom> holdOrder(List<ChatRoom> sorted, List<String> held) {
  final rank = {for (var i = 0; i < held.length; i++) held[i]: i};
  final known = sorted.where((r) => rank.containsKey(r.id)).toList()
    ..sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));
  var next = 0;
  return [for (final r in sorted) rank.containsKey(r.id) ? known[next++] : r];
}
