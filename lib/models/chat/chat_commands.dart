import 'package:torn_pda/models/chat/chat_quick_rows.dart';

typedef ChatCommandRun = ({int serial, String id, String args});

class ChatCommands {
  ChatCommands._();

  // Emoji and replies are rows, not actions
  static Iterable<String> actionsIn(List<String> order) =>
      order.where((id) => chatQuickActionIds.contains(id) && id != 'emoji' && id != 'replies');

  static final RegExp _typed = RegExp(r'^/([A-Za-z]*)(?:\s+([\s\S]*))?$');

  /// Null unless it starts with "/word"
  static ({String name, String args})? typed(String text) {
    final match = _typed.firstMatch(text);
    if (match == null) return null;
    return (name: match.group(1)!.toLowerCase(), args: (match.group(2) ?? '').trim());
  }

  /// Prefix matches first
  static List<String> matchActions(String name, Iterable<String> available) => [
    ...available.where((id) => id.startsWith(name)),
    ...available.where((id) => !id.startsWith(name) && id.contains(name)),
  ];

  static List<String> matchReplies(({String name, String args}) typed, List<String> replies) {
    final query = '${typed.name} ${typed.args}'.trim().toLowerCase();
    return replies.where((r) => r.toLowerCase().contains(query)).toList();
  }
}
