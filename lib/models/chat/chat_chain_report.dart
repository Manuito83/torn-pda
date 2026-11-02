import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_money.dart';

final NumberFormat _respect = NumberFormat('#,##0.00', 'en_US');

/// "1,842.40"
String chatRespect(num n) => _respect.format(n);

int _int(Object? v) => v is num ? v.toInt() : 0;

double _double(Object? v) => v is num ? v.toDouble() : 0;

class ChatChainHits {
  const ChatChainHits({
    this.total = 0,
    this.leave = 0,
    this.mug = 0,
    this.hospitalize = 0,
    this.assists = 0,
    this.retaliations = 0,
    this.overseas = 0,
    this.war = 0,
    this.draws = 0,
    this.escapes = 0,
    this.losses = 0,
    this.bonuses = 0,
  });

  factory ChatChainHits.fromJson(Map json) => ChatChainHits(
    total: _int(json['total']),
    leave: _int(json['leave']),
    mug: _int(json['mug']),
    hospitalize: _int(json['hospitalize']),
    assists: _int(json['assists']),
    retaliations: _int(json['retaliations']),
    overseas: _int(json['overseas']),
    war: _int(json['war']),
    draws: _int(json['draws']),
    escapes: _int(json['escapes']),
    losses: _int(json['losses']),
    bonuses: _int(json['bonuses']),
  );

  final int total;
  final int leave;
  final int mug;
  final int hospitalize;
  final int assists;
  final int retaliations;
  final int overseas;
  final int war;
  final int draws;
  final int escapes;
  final int losses;
  final int bonuses;

  /// The ones that count for the chain
  int get won => leave + mug + hospitalize;
}

class ChatChainAttacker {
  const ChatChainAttacker({
    required this.id,
    required this.respect,
    required this.average,
    required this.best,
    required this.hits,
  });

  final int id;
  final double respect;
  final double average;
  final double best;
  final ChatChainHits hits;
}

class ChatChainBonus {
  const ChatChainBonus({required this.chain, required this.attackerId, required this.defenderId, required this.respect});

  final int chain;
  final int attackerId;
  final int defenderId;
  final double respect;
}

class ChatChainReport {
  const ChatChainReport({
    required this.id,
    required this.start,
    required this.end,
    required this.chain,
    required this.respect,
    required this.targets,
    required this.best,
    required this.hits,
    required this.bonuses,
    required this.attackers,
    required this.nonAttackers,
    required this.json,
  });

  /// The `chainreport` object, null if unreadable
  static ChatChainReport? parse(Object? json) {
    if (json is! Map<String, dynamic> || json['id'] is! int || json['details'] is! Map) return null;
    final details = json['details'] as Map;
    List<Map> listOf(String key) => json[key] is List ? (json[key] as List).whereType<Map>().toList() : const [];
    final attackers = [
      for (final a in listOf('attackers'))
        if (a['id'] is int)
          ChatChainAttacker(
            id: a['id'] as int,
            respect: _double(a['respect'] is Map ? a['respect']['total'] : null),
            average: _double(a['respect'] is Map ? a['respect']['average'] : null),
            best: _double(a['respect'] is Map ? a['respect']['best'] : null),
            hits: ChatChainHits.fromJson(a['attacks'] is Map ? a['attacks'] as Map : const {}),
          ),
    ]..sort((a, b) => b.respect.compareTo(a.respect));
    return ChatChainReport(
      id: json['id'] as int,
      start: _int(json['start']),
      end: _int(json['end']),
      chain: _int(details['chain']),
      respect: _double(details['respect']),
      targets: _int(details['targets']),
      best: _double(details['best']),
      hits: ChatChainHits.fromJson(details),
      bonuses: [
        for (final b in listOf('bonuses'))
          ChatChainBonus(
            chain: _int(b['chain']),
            attackerId: _int(b['attacker_id']),
            defenderId: _int(b['defender_id']),
            respect: _double(b['respect']),
          ),
      ]..sort((a, b) => b.chain.compareTo(a.chain)),
      attackers: attackers,
      nonAttackers: [
        if (json['non_attackers'] is List)
          for (final id in json['non_attackers'] as List)
            if (id is int) id,
      ],
      json: json,
    );
  }

  final int id;
  final int start;
  final int end;
  final int chain;
  final double respect;
  final int targets;
  final double best;
  final ChatChainHits hits;

  /// Biggest first
  final List<ChatChainBonus> bonuses;

  /// By respect
  final List<ChatChainAttacker> attackers;

  final List<int> nonAttackers;

  final Map<String, dynamic> json;

  Duration get length => Duration(seconds: end - start);

  /// Zero [start] or [hits] are not checked
  bool isFor({required int start, required int hits, required DateTime now}) =>
      end > 0 &&
      end * 1000 <= now.millisecondsSinceEpoch &&
      (start <= 0 || this.start == start) &&
      (hits <= 0 || chain == hits);
}

enum ChatReportStatus { waiting, ready, failed }

class ChatReportView {
  const ChatReportView(this.status, {this.report, this.next, this.checking = false, this.reason, this.askedAt});

  final ChatReportStatus status;
  final ChatChainReport? report;

  /// Next automatic check, none after key errors
  final DateTime? next;
  final bool checking;

  /// Why it failed, as Torn put it
  final String? reason;
  final DateTime? askedAt;

  ChatReportView checkingNow(DateTime at) =>
      ChatReportView(status, report: report, next: next, checking: true, reason: reason, askedAt: at);
}

/// Key or access errors need the player
bool chatReportKeyError(int? code) => const {2, 7, 10, 16}.contains(code);

/// "Torn error 5 - too many requests"
String chatReportReason(int? code, String reason) {
  if (code == null || code >= 100) return reason;
  return reason.isEmpty ? 'Torn error $code' : 'Torn error $code - $reason';
}

/// Least time between asks by hand
const Duration chatReportCheckGap = Duration(seconds: 10);

/// "1st", "22nd", "13th"
String chatOrdinal(int n) {
  final teen = n % 100 >= 11 && n % 100 <= 13;
  return '$n${teen ? 'th' : const {1: 'st', 2: 'nd', 3: 'rd'}[n % 10] ?? 'th'}';
}

String chatHits(int n) => n == 1 ? '1 hit' : '$n hits';

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
      : 'You: ${chatCount(score(own).round())} score, ${chatHits(own['attacks'] is int ? own['attacks'] as int : 0)} (${chatOrdinal(place + 1)})';
  return [
    'War over: $result${chatCount(ours['score'])} to ${chatCount(theirs['score'])}',
    ?you,
    'only you see this',
  ].join(' - ');
}

String chatChainOverLine(ChatChainReport report, int? myId) {
  final attackers = report.attackers;
  final place = attackers.indexWhere((a) => a.id == myId);
  final own = place < 0 ? null : attackers[place];
  final you = myId == null
      ? null
      : own == null
      ? 'You: no hits'
      : 'You: ${chatHits(own.hits.total)}, ${chatCount(own.respect.round())} respect (${chatOrdinal(place + 1)} of ${attackers.length})';
  return [
    'Chain over: ${chatHits(report.chain)}, ${chatCount(report.respect.round())} respect',
    ?you,
    'only you see this',
  ].join(' - ');
}

/// Every 30 s at first, then every minute
Duration chatChainReportWait(Duration sinceCooldown) =>
    sinceCooldown < const Duration(minutes: 5) ? const Duration(seconds: 30) : const Duration(seconds: 60);

/// Failures flagged true, zeros left out
List<(String, bool)> chatChainBreakdown(ChatChainAttacker a) {
  final h = a.hits;
  String count(int n, String one, [String? many]) => '${chatCount(n)} ${n == 1 ? one : many ?? one}';
  return [
    if (h.leave > 0) (count(h.leave, 'leave'), false),
    if (h.mug > 0) (count(h.mug, 'mug'), false),
    if (h.hospitalize > 0) (count(h.hospitalize, 'hosp'), false),
    if (h.bonuses > 0) (count(h.bonuses, 'bonus', 'bonuses'), false),
    if (h.retaliations > 0) (count(h.retaliations, 'retaliation', 'retaliations'), false),
    if (h.overseas > 0) (count(h.overseas, 'overseas'), false),
    if (h.war > 0) (count(h.war, 'war'), false),
    if (h.assists > 0) (count(h.assists, 'assist', 'assists'), false),
    if (a.respect > 0) ...[('avg ${chatRespect(a.average)}', false), ('best ${chatRespect(a.best)}', false)],
    if (h.losses > 0) (count(h.losses, 'loss', 'losses'), true),
    if (h.draws > 0) (count(h.draws, 'draw', 'draws'), true),
    if (h.escapes > 0) (count(h.escapes, 'escape', 'escapes'), true),
  ];
}
