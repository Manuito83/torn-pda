import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_time.dart';

const int chatPastChainsPageSize = 20;

class ChatPastChain {
  const ChatPastChain({
    required this.id,
    required this.chain,
    required this.respect,
    required this.start,
    required this.end,
  });

  final int id;
  final int chain;
  final double respect;
  final int start;
  final int end;

  Duration get length => Duration(seconds: end > start ? end - start : 0);
}

class ChatPastChainsPage {
  const ChatPastChainsPage(this.chains, this.older);

  /// Newest first
  final List<ChatPastChain> chains;

  /// Next older page, null at the end
  final Map<String, String>? older;
}

/// Null if unreadable
ChatPastChainsPage? chatParsePastChains(Map<String, dynamic>? json) {
  final list = json?['chains'];
  if (list is! List) return null;
  num number(Object? value) => value is num ? value : 0;
  final chains = [
    for (final c in list.whereType<Map>())
      if (c['id'] is int)
        ChatPastChain(
          id: c['id'] as int,
          chain: number(c['chain']).toInt(),
          respect: number(c['respect']).toDouble(),
          start: number(c['start']).toInt(),
          end: number(c['end']).toInt(),
        ),
  ]..sort((a, b) => b.start.compareTo(a.start));
  final metadata = json?['_metadata'];
  final links = metadata is Map ? metadata['links'] : null;
  return ChatPastChainsPage(chains, _olderQuery(links is Map ? links['prev'] : null));
}

const _pagingKeys = {'limit', 'sort', 'from', 'to'};

Map<String, String>? _olderQuery(Object? link) {
  final uri = link is String ? Uri.tryParse(link) : null;
  if (uri == null) return null;
  final query = {
    for (final MapEntry(:key, :value) in uri.queryParameters.entries)
      if (_pagingKeys.contains(key)) key: value,
  };
  return query.isEmpty ? null : query;
}

List<ChatPastChain> chatMergePastChains(List<ChatPastChain> have, List<ChatPastChain> more) {
  final known = {for (final c in have) c.id};
  return [...have, ...more.where((c) => known.add(c.id))]..sort((a, b) => b.start.compareTo(a.start));
}

String chatPastChainWhen(ChatPastChain chain) {
  final at = DateTime.fromMillisecondsSinceEpoch(chain.start * 1000, isUtc: true);
  return [
    DateFormat('d MMM y', 'en_US').format(at),
    chatTctText(at),
    if (chain.end > chain.start) chatSpan(chain.length),
  ].join(' - ');
}

String chatPastChainHits(ChatPastChain chain) => '${chatCount(chain.chain)} ${chain.chain == 1 ? 'hit' : 'hits'}';
