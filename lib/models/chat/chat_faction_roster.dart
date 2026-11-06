import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_html_text.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/utils/country_check.dart';

class ChatEnemyChain {
  const ChatEnemyChain({required this.hits, required this.breaksAt});

  final int hits;
  final DateTime breaksAt;
}

ChatEnemyChain? chatEnemyChain(FactionOngoingChain chain, DateTime now) {
  if (chain.current <= 0 || chain.timeout <= 0) return null;
  return ChatEnemyChain(
    hits: chain.current,
    breaksAt: now.add(Duration(seconds: chain.timeout)),
  );
}

String? chatEnemyChainLine(ChatEnemyChain? chain, DateTime now) {
  final left = chain?.breaksAt.difference(now);
  if (left == null || left.inSeconds <= 0) return null;
  return 'Enemy chain ${chain!.hits} - ${chatClock(left)} left';
}

bool chatIsLead(String? position) => const {'leader', 'co-leader', 'director'}.contains(position?.toLowerCase());

/// "3 online", "15 in hospital", "6 abroad"
List<({String label, int count})> chatRosterCounts(List<FactionMember> members) {
  if (members.isEmpty) return const [];
  final online = members.where((m) => m.lastAction.status == 'Online').length;
  final hospital = members.where((m) => m.status.state == 'Hospital').length;
  final abroad = members.where((m) => m.status.state == 'Abroad' || m.status.state == 'Traveling').length;
  return [
    (label: 'online', count: online),
    if (hospital > 0) (label: 'in hospital', count: hospital),
    if (abroad > 0) (label: 'abroad', count: abroad),
  ];
}

int _until(FactionMember m) => m.status.until is int ? m.status.until as int : int.tryParse('${m.status.until}') ?? 0;

bool chatRosterAway(FactionMember m) => m.status.state == 'Traveling' || m.status.state == 'Abroad';

String chatRosterCountry(FactionMember m) => countryCheck(state: m.status.state, description: m.status.description);

/// Foreign country, null when in Torn
(String, TravelDirection)? chatRosterTrip(FactionMember m) {
  final description = m.status.description.trim();
  switch (m.status.state) {
    case 'Traveling':
      return parseTrip(description) ?? (chatRosterCountry(m), TravelDirection.outbound);
    case 'Abroad' || 'Hospital':
      final country = chatRosterCountry(m);
      return country == 'Torn' || country == 'error' ? null : (country, TravelDirection.none);
  }
  return null;
}

/// Group to value, like presence: online
bool chatRosterMatches(FactionMember m, Map<String, String> filters, String query) {
  for (final MapEntry(:key, :value) in filters.entries) {
    final fits = switch (key) {
      'presence' => m.lastAction.status.toLowerCase() == value,
      'state' => m.status.state.toLowerCase() == value,
      'travel' => value == 'away' ? chatRosterAway(m) : !chatRosterAway(m) && chatRosterCountry(m) == 'Torn',
      'country' => chatRosterCountry(m) == value,
      _ => true,
    };
    if (!fits) return false;
  }
  final q = query.trim().toLowerCase();
  return q.isEmpty || m.name.toLowerCase().contains(q) || '${m.id}'.contains(q);
}

List<FactionMember> chatRosterSorted(List<FactionMember> members, String sort, {required bool reversed}) {
  final holders = <String, int>{};
  for (final m in members) {
    holders[m.position] = (holders[m.position] ?? 0) + 1;
  }
  int rankOf(FactionMember m) => switch (m.position.toLowerCase()) {
    'leader' => -2,
    'co-leader' => -1,
    _ => holders[m.position]!,
  };
  ChatPlayerStatus? statusOf(FactionMember m) =>
      ChatPlayerStatus.from(m.status.state, m.status.description, m.status.until);
  int outside(FactionMember m) => m.status.state == 'Hospital' ? 0 : 1;

  final int Function(FactionMember, FactionMember) first = switch (sort) {
    'hospital' => (a, b) => _until(a).compareTo(_until(b)),
    'action' => (a, b) => b.lastAction.timestamp.compareTo(a.lastAction.timestamp),
    'level' => (a, b) => b.level.compareTo(a.level),
    'position' => (a, b) {
      final rank = rankOf(a).compareTo(rankOf(b));
      return rank != 0 ? rank : a.position.compareTo(b.position);
    },
    'days' => (a, b) => b.daysInFaction.compareTo(a.daysInFaction),
    'name' => (a, b) => 0,
    _ => (a, b) {
      final rank = (statusOf(a)?.rank ?? 99).compareTo(statusOf(b)?.rank ?? 99);
      return rank != 0 ? rank : _until(a).compareTo(_until(b));
    },
  };

  return [...members]..sort((a, b) {
    if (sort == 'hospital' && (outside(a) == 1 || outside(b) == 1)) {
      if (outside(a) != outside(b)) return outside(a) - outside(b);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    final order = first(a, b);
    if (order != 0) return reversed ? -order : order;
    final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return reversed && sort == 'name' ? -name : name;
  });
}

/// "6y 0m 18d", "3m 12d", "12d"
String chatRosterTenure(int days) {
  const year = 365.25, month = year / 12;
  final years = days ~/ year;
  final rest = (days - years * year).floor();
  final months = rest ~/ month;
  final left = (rest - months * month).floor();
  if (years > 0) return '${years}y ${months}m ${left}d';
  return months > 0 ? '${months}m ${left}d' : '${left}d';
}

/// "Hospital 4m 10s", "To Japan"
String chatRosterStatus(FactionMember m, DateTime now, {bool spoken = false}) {
  final status = m.status;
  final description = chatHtmlText(status.description).trim();
  switch (status.state) {
    case 'Hospital' || 'Jail':
      final left = _until(m) - now.millisecondsSinceEpoch ~/ 1000;
      if (!spoken) return left > 0 ? '${status.state} ${ChatStatus.duration(left)}' : status.state;
      final country = chatRosterCountry(m);
      return [
        status.state == 'Hospital' && country != 'Torn' && country != 'error' ? 'Hospital in $country' : status.state,
        if (left <= 0) 'out now' else 'out in ${_minutes(left)}',
      ].join(' - ');
    case 'Traveling':
      final (country, direction) = chatRosterTrip(m)!;
      if (direction == TravelDirection.outbound) return 'To $country';
      return spoken ? 'Returning from $country' : 'From $country';
    case 'Abroad':
      return 'In ${chatRosterCountry(m)}';
    case 'Okay':
      return 'Okay';
  }
  return description.isEmpty ? status.state : description;
}

final _profileLink = RegExp(r'<a [^>]*XID=(\d{1,10})(?!\d)[^>]*>([^<]*)</a>');

typedef ChatRosterCause = ({String before, String by, int? byId, String after});

/// "Attacked by X", with X's id when linked
ChatRosterCause? chatRosterCause(FactionMember m) {
  if (m.status.state != 'Hospital' && m.status.state != 'Jail') return null;
  final details = m.status.details is String ? (m.status.details as String).trim() : '';
  if (details.isEmpty) return null;
  final link = _profileLink.firstMatch(details);
  if (link == null) return (before: chatHtmlText(details), by: '', byId: null, after: '');
  return (
    before: chatHtmlText(details.substring(0, link.start)),
    by: chatHtmlText(link[2]!),
    byId: int.tryParse(link[1]!),
    after: chatHtmlText(details.substring(link.end)),
  );
}

String _minutes(int seconds) {
  final minutes = (seconds + 59) ~/ 60;
  final hours = minutes ~/ 60;
  String unit(int n, String name) => '$n $name${n == 1 ? '' : 's'}';
  if (hours == 0) return unit(minutes, 'minute');
  return minutes % 60 == 0 ? unit(hours, 'hour') : '${unit(hours, 'hour')} ${unit(minutes % 60, 'minute')}';
}
