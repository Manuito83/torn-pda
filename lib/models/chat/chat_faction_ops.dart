import 'package:intl/intl.dart';

enum ChatChainLevel { ok, caution, danger, cooldown }

class ChatChain {
  const ChatChain({required this.hits, required this.seconds, this.cooldown = false});

  final int hits;
  final int seconds;
  final bool cooldown;

  // API counts, not the local clock
  bool get alive => !cooldown && hits > 0;

  bool get running => !cooldown && hits > 0 && seconds > 0;

  // Same cut points as the floating window
  ChatChainLevel get level {
    if (cooldown) return ChatChainLevel.cooldown;
    if (hits >= 10 && seconds < 60) return ChatChainLevel.danger;
    if (hits >= 10 && seconds < 150) return ChatChainLevel.caution;
    return ChatChainLevel.ok;
  }
}

/// Fires once per drop under the threshold
class ChatChainAlarm {
  double? threshold;
  bool _armed = true;

  bool check(ChatChain chain) {
    final limit = threshold;
    if (limit == null || !chain.running || chain.hits < 10 || chain.seconds > limit) {
      _armed = true;
      return false;
    }
    if (!_armed) return false;
    _armed = false;
    return true;
  }
}

class ChatRetal {
  const ChatRetal({required this.id, required this.name, required this.expiry});

  final int id;
  final String name;
  final DateTime expiry;
}

class ChatWar {
  const ChatWar({
    required this.ours,
    required this.theirs,
    required this.enemy,
    required this.start,
    this.target,
    this.enemyId,
  });

  final int ours;
  final int theirs;
  final String enemy;
  final DateTime start;
  final int? target;
  final int? enemyId;
}

/// "0:45", "4:30" or "1:02:03"
String chatClock(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  final mm = (s ~/ 60 % 60).toString();
  final ss = (s % 60).toString().padLeft(2, '0');
  if (s < 3600) return '$mm:$ss';
  return '${s ~/ 3600}:${mm.padLeft(2, '0')}:$ss';
}

/// "45m" or "5h 12m"
String chatSpan(Duration d) {
  final m = d.isNegative ? 0 : d.inMinutes;
  return m < 60 ? '${m}m' : '${m ~/ 60}h ${m % 60}m';
}

String chatChainLine(int seconds) => 'Chain at ${chatClock(Duration(seconds: seconds))}';

/// Shown in steps of ten seconds
String chatRetalLine(ChatRetal retal, DateTime now) {
  final left = retal.expiry.difference(now).inSeconds;
  return 'Retal available: ${retal.name}, ${chatClock(Duration(seconds: left - left % 10))} left';
}

final NumberFormat _count = NumberFormat.decimalPattern('en_US');

String _ordinal(int n) {
  final teen = n % 100 >= 11 && n % 100 <= 13;
  return '$n${teen ? 'th' : const {1: 'st', 2: 'nd', 3: 'rd'}[n % 10] ?? 'th'}';
}

String _hits(int n) => n == 1 ? '1 hit' : '$n hits';

/// Null when the report cannot be read
String? chatChainOverLine(Map<String, dynamic> json, int? myId) {
  final report = json['chainreport'];
  if (report is! Map || report['details'] is! Map) return null;
  final details = report['details'] as Map;
  final (hits, respect) = (details['chain'], details['respect']);
  if (hits is! int || respect is! num) return null;
  final attackers = report['attackers'] is List ? (report['attackers'] as List).whereType<Map>().toList() : <Map>[];
  num worth(Map a) => a['respect'] is Map && a['respect']['total'] is num ? a['respect']['total'] as num : 0;
  attackers.sort((a, b) => worth(b).compareTo(worth(a)));
  final place = attackers.indexWhere((a) => a['id'] == myId);
  final own = place < 0 ? null : attackers[place];
  final ownHits = own?['attacks'] is Map ? (own!['attacks'] as Map)['total'] : null;
  final you = myId == null
      ? null
      : ownHits is int
      ? 'You: ${_hits(ownHits)}, ${_count.format(worth(own!).round())} respect (${_ordinal(place + 1)} of ${attackers.length})'
      : 'You: no hits';
  return [
    'Chain over: ${_hits(hits)}, ${_count.format(respect.round())} respect',
    ?you,
    'only you see this',
  ].join(' - ');
}

/// Latest finished war id and end
(int, int)? chatLastWar(Map<String, dynamic> json) {
  final list = json['rankedwars'];
  (int, int)? best;
  for (final w in list is List ? list.whereType<Map>() : const <Map>[]) {
    final (id, end) = (w['id'], w['end']);
    if (id is int && end is int && end > (best?.$2 ?? 0)) best = (id, end);
  }
  return best;
}

String? chatWarOverLine(Map<String, dynamic> json, int? myId, int myFactionId) {
  final report = json['rankedwarreport'];
  final sides = report is Map && report['factions'] is List ? (report['factions'] as List).whereType<Map>() : null;
  final ours = sides?.where((f) => f['id'] == myFactionId).firstOrNull;
  final theirs = sides?.where((f) => f['id'] != myFactionId).firstOrNull;
  if (report is! Map || ours == null || theirs == null || ours['score'] is! num || theirs['score'] is! num) return null;
  final members = ours['members'] is List ? (ours['members'] as List).whereType<Map>().toList() : <Map>[];
  num score(Map m) => m['score'] is num ? m['score'] as num : 0;
  members.sort((a, b) => score(b).compareTo(score(a)));
  final place = members.indexWhere((m) => m['id'] == myId);
  final own = place < 0 ? null : members[place];
  final result = switch (report['winner']) {
    final int w when w == myFactionId => 'won ',
    final int w when w > 0 => 'lost ',
    _ => '',
  };
  final you = myId == null
      ? null
      : own == null
      ? 'You: no hits'
      : 'You: ${_count.format(score(own).round())} score, ${_hits(own['attacks'] is int ? own['attacks'] as int : 0)} (${_ordinal(place + 1)})';
  return [
    'War over: $result${_count.format(ours['score'])} to ${_count.format(theirs['score'])}',
    ?you,
    'only you see this',
  ].join(' - ');
}
