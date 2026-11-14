import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';

enum ChatAwayKind { mentions, leaders, attacks, words }

class ChatAway {
  const ChatAway({
    required this.away,
    required this.total,
    required this.more,
    required this.counts,
    required this.firsts,
    required this.anchorId,
  });

  static const Duration minAway = Duration(minutes: 30);

  final Duration away;
  final int total;

  /// Older messages are not loaded
  final bool more;
  final Map<ChatAwayKind, int> counts;

  /// Oldest message of each group
  final Map<ChatAwayKind, String> firsts;

  final String anchorId;

  static bool appliesTo(String roomId) => roomId == 'faction' || roomId == 'company' || roomId.startsWith('dm:');

  /// "5h 20m", "45m", "1d 3h"
  static String span(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    if (d.inHours > 0) return minutes > 0 ? '${d.inHours}h ${minutes}m' : '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  String get totalLabel => '$total${more ? '+' : ''} ${total == 1 && !more ? 'message' : 'messages'}';

  static String chipLabel(ChatAwayKind kind, int n) => switch (kind) {
    ChatAwayKind.mentions => '$n mention you',
    ChatAwayKind.leaders => '$n from leaders',
    ChatAwayKind.attacks => '$n attack ${n == 1 ? 'link' : 'links'}',
    ChatAwayKind.words => '$n highlight ${n == 1 ? 'word' : 'words'}',
  };

  List<ChatAwayKind> get shown => [
    for (final k in ChatAwayKind.values)
      if ((counts[k] ?? 0) > 0) k,
  ];

  /// "38 new - 2 mention you"
  String inboxLine(int totalOverride) {
    final n = totalOverride > total ? totalOverride : total;
    return ['$n${more ? '+' : ''} new', for (final k in shown) chipLabel(k, counts[k]!)].join(' - ');
  }

  /// Null if nothing worth jumping to
  static ChatAway? build({
    required List<ChatMessage> messages,
    required DateTime since,
    required DateTime now,
    required int? myUserId,
    required bool hasOlder,
    required bool Function(ChatMessage m) mention,
    required bool Function(ChatMessage m) word,
    Set<int> leaders = const {},
  }) {
    final away = now.difference(since);
    if (away < minAway) return null;
    final counts = {for (final k in ChatAwayKind.values) k: 0};
    final firsts = <ChatAwayKind, String>{};
    String? first;
    var total = 0;
    for (final m in messages) {
      final fromOthers = m.state == ChatMessageState.sent && !m.isLocal && !m.isSystem && m.sender.id != myUserId;
      if (!fromOthers || !m.createdAt.isAfter(since)) continue;
      total++;
      first ??= m.id;
      void add(ChatAwayKind kind) {
        counts[kind] = counts[kind]! + 1;
        firsts.putIfAbsent(kind, () => m.id);
      }

      if (mention(m)) add(ChatAwayKind.mentions);
      if (leaders.contains(m.sender.id)) add(ChatAwayKind.leaders);
      if (ChatLink.split(m.content).whereType<ChatLink>().any((l) => l.kind == ChatLinkKind.attack)) {
        add(ChatAwayKind.attacks);
      }
      if (word(m)) add(ChatAwayKind.words);
    }
    if (first == null || counts.values.every((n) => n == 0)) return null;
    final oldest = messages.firstOrNull;
    final more = hasOlder && oldest != null && oldest.createdAt.isAfter(since);
    return ChatAway(away: away, total: total, more: more, counts: counts, firsts: firsts, anchorId: first);
  }
}
