import 'package:flutter/services.dart';
import 'package:torn_pda/models/chat/chat_models.dart';

class ChatMentions {
  static final RegExp _open = RegExp(r'(?:^|\s)@([A-Za-z0-9_-]+)$');

  /// Null unless the cursor ends an "@name"
  static String? queryAt(TextEditingValue value) {
    final cursor = value.selection.baseOffset;
    if (!value.selection.isCollapsed || cursor < 0 || cursor > value.text.length) return null;
    return _open.firstMatch(value.text.substring(0, cursor))?.group(1);
  }

  static TextEditingValue insert(TextEditingValue value, String name) {
    final query = queryAt(value);
    if (query == null) return value;
    final cursor = value.selection.baseOffset;
    final start = cursor - query.length - 1;
    final after = value.text.substring(cursor);
    final mention = '@$name${after.startsWith(' ') ? '' : ' '}';
    return TextEditingValue(
      text: value.text.substring(0, start) + mention + after,
      selection: TextSelection.collapsed(offset: start + mention.length + (after.startsWith(' ') ? 1 : 0)),
    );
  }

  /// Newest first, without me or system lines
  static List<ChatUser> recentSenders(List<ChatMessage> messages, int? myUserId) {
    final seen = <int>{};
    return [
      for (final m in messages.reversed)
        if (!m.isSystem && m.sender.id > 0 && m.sender.id != myUserId && seen.add(m.sender.id)) m.sender,
    ];
  }

  static List<ChatUser> candidates(List<ChatMessage> messages, int? myUserId, [List<ChatUser> roster = const []]) => [
    ...recentSenders(messages, myUserId),
    for (final u in roster)
      if (u.id != myUserId) u,
  ];

  /// Prefix matches before inner ones, keeping order
  static List<ChatUser> rank(Iterable<ChatUser> users, String query, {int limit = 8}) {
    final q = query.toLowerCase();
    final seen = <int>{};
    final unique = [
      for (final u in users)
        if (seen.add(u.id)) u,
    ];
    return [
      ...unique.where((u) => u.name.toLowerCase().startsWith(q)),
      ...unique.where((u) => !u.name.toLowerCase().startsWith(q) && u.name.toLowerCase().contains(q)),
    ].take(limit).toList();
  }
}
