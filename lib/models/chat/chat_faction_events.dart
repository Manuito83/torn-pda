import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_models.dart';

const String chatFactionEventPrefix = 'local-news-';
const int chatFactionEventMax = 50;

// Kept only when naming the player
final RegExp _private = RegExp(
  r'\$\d|money|cash|funds|deposit|withdr|armory|armoury|loaned|retrieved|\bpoints\b',
  caseSensitive: false,
);
final RegExp _tags = RegExp(r'<[^>]*>');

bool isChatFactionEvent(ChatMessage m) => m.isLocal && m.id.startsWith(chatFactionEventPrefix);

/// Oldest first, believable times only
List<ChatMessage> chatFactionEvents(List<FactionNews> news, {required DateTime now, String? myName}) {
  final seen = <String>{};
  final lines = <ChatMessage>[];
  final latest = now.add(const Duration(minutes: 5));
  for (final n in news) {
    final text = n.text.replaceAll(_tags, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final at = DateTime.fromMillisecondsSinceEpoch(n.timestamp * 1000);
    if (text.isEmpty || n.timestamp <= 0 || at.isAfter(latest) || !seen.add(n.id)) continue;
    if (_private.hasMatch(text) && (myName == null || !text.contains(myName))) continue;
    lines.add(
      ChatMessage(
        id: '$chatFactionEventPrefix${n.id}',
        roomId: 'faction',
        sender: const ChatUser(id: 0, name: ''),
        content: text,
        createdAt: at,
        isSystem: true,
        isLocal: true,
      ),
    );
  }
  lines.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return lines.length > chatFactionEventMax ? lines.sublist(lines.length - chatFactionEventMax) : lines;
}

/// Key lacks access, not a glitch
bool chatFactionEventsDenied(int? errorId) => const {2, 6, 7, 16}.contains(errorId);
