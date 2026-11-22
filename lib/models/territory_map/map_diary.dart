import 'package:intl/intl.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_search.dart';

const diaryMaxDays = 30;

// The function closes days 21 late
const _missingForGoodAfter = Duration(days: 22);
const _lateAfter = Duration(days: 2);
const _askLateEvery = Duration(hours: 3);
const _askAgainAfter = Duration(minutes: 1);

final _dayFormat = DateFormat('yyyy-MM-dd');

String dayKey(DateTime time) => _dayFormat.format(time.toUtc());

DateTime dayStart(String day) => DateTime.parse('${day}T00:00:00Z');

bool isMissingForGood(String day, DateTime now) => now.difference(dayStart(day)) > _missingForGoodAfter;

// Missing late days are asked slowly
bool shouldAskDay(String day, DateTime now, DateTime? askedAt, {required bool missing}) {
  if (askedAt == null) return true;
  final late = missing && now.difference(dayStart(day)) >= _lateAfter;
  return now.difference(askedAt) >= (late ? _askLateEvery : _askAgainAfter);
}

// Newest first, today included
List<String> diaryDays(DateTime from, DateTime now) {
  final oldest = now.subtract(const Duration(days: diaryMaxDays));
  var day = dayStart(dayKey(from.isBefore(oldest) ? oldest : from));
  final days = <String>[];
  while (!day.isAfter(now)) {
    days.insert(0, dayKey(day));
    day = day.add(const Duration(days: 1));
  }
  return days;
}

// Only gaps between published days count
bool hasMissingDays(List<String> days, Set<String> missing) {
  final found = days.where((d) => !missing.contains(d));
  if (found.isEmpty) return false;
  final oldestFound = found.last;
  return days.any((d) => missing.contains(d) && d.compareTo(oldestFound) > 0);
}

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

String diarySummary(Map<ChangeKind, int> counts) {
  int count(List<ChangeKind> kinds) => kinds.fold(0, (sum, k) => sum + (counts[k] ?? 0));
  final ended = count([
    ChangeKind.assaultSucceeded,
    ChangeKind.assaultFailed,
    ChangeKind.assaultTruce,
    ChangeKind.assaultEnded,
  ]);
  final failed = count([ChangeKind.assaultFailed]);
  final rackets = count([
    ChangeKind.racketNew,
    ChangeKind.racketUp,
    ChangeKind.racketDown,
    ChangeKind.racketLevel,
    ChangeKind.racketLost,
  ]);
  return [
    if (count([ChangeKind.conquest]) case final n when n > 0) _plural(n, 'conquest', 'conquests'),
    if (count([ChangeKind.transfer]) case final n when n > 0) _plural(n, 'transfer', 'transfers'),
    if (count([ChangeKind.claimed]) case final n when n > 0) '$n claimed',
    if (count([ChangeKind.abandoned]) case final n when n > 0) '$n dropped',
    if (count([ChangeKind.assaultStarted]) case final n when n > 0) _plural(n, 'assault started', 'assaults started'),
    if (ended > 0) failed > 0 ? '$ended ended ($failed failed)' : '$ended ended',
    if (rackets > 0) _plural(rackets, 'racket change', 'racket changes'),
    if (count([ChangeKind.bomb]) case final n when n > 0) _plural(n, 'bomb', 'bombs'),
  ].join(' - ');
}

String diaryText(MapChange change, ChangeKind kind, String Function(int factionId) tag) {
  final code = change.territory ?? '';
  final now = tag(change.factionId);
  final before = tag(change.previousFactionId);
  final extra = change.extra;
  final level = extra?['level'];
  final score = extra?['score'] as int?;
  final target = extra?['target'] as int?;
  final numbers = NumberFormat('#,##0', 'en_US');
  final finalScore = score == null || target == null ? '' : ' (${numbers.format(score)} / ${numbers.format(target)})';
  return switch (kind) {
    ChangeKind.conquest => '$now conquered $code from $before',
    ChangeKind.transfer => '$code transferred $before → $now',
    ChangeKind.abandoned => '$before dropped $code',
    ChangeKind.claimed => '$now claimed $code',
    ChangeKind.reacquired => '$now lost and retook $code',
    ChangeKind.irradiated => change.bombId == null ? '$code irradiation changed' : '$code irradiated',
    ChangeKind.assaultStarted => '$now started an assault on $code against $before',
    ChangeKind.assaultSucceeded => '$now won the assault on $code against $before',
    ChangeKind.assaultFailed => '$now failed the assault on $code against $before$finalScore',
    ChangeKind.assaultTruce => 'Truce on $code between $now and $before',
    ChangeKind.assaultEnded => 'Assault on $code by $now ended',
    ChangeKind.racketNew => 'New racket on $code for $now${extra?['name'] == null ? '' : ': ${extra!['name']}'}',
    ChangeKind.racketUp => '$code racket up to level $level',
    ChangeKind.racketDown => '$code racket down to level $level',
    ChangeKind.racketLevel => '$code racket changed level',
    ChangeKind.racketLost => '$code racket gone',
    ChangeKind.bomb => _bombText(change, now, numbers),
  };
}

String _bombText(MapChange change, String faction, NumberFormat numbers) {
  final codes = (change.extra?['territories'] as List<dynamic>?)?.join(', ');
  final respect = change.extra?['respect_lost'] as int?;
  final where = codes == null || codes.isEmpty ? '' : ' on $codes';
  if (respect == null) return 'Dirty bomb$where against $faction';
  return 'Dirty bomb$where: $faction lost ${numbers.format(respect)} respect';
}

typedef PeriodStats = ({
  Map<ChangeKind, int> counts,
  List<MapEntry<int, int>> gainers,
  List<MapEntry<int, int>> losers,
});

PeriodStats periodStats(Iterable<MapChange> changes, DateTime since, {int top = 5}) {
  final inPeriod = changes.where((c) => !c.at.isBefore(since));
  final gains = netGains(inPeriod).entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return (
    counts: summarize(inPeriod, since),
    gainers: gains.where((e) => e.value > 0).take(top).toList(),
    losers: gains.reversed.where((e) => e.value < 0).take(top).toList(),
  );
}

typedef FactionRecent = ({List<(MapChange, ChangeKind)> rows, int won, int lost});

bool involvesFaction(MapChange change, int factionId) =>
    change.factionId == factionId || change.previousFactionId == factionId;

// Changes newest first, diary rows only
FactionRecent factionRecent(Iterable<MapChange> changes, int factionId) {
  final rows = [
    for (final change in changes)
      if (involvesFaction(change, factionId))
        if (classify(change) case final kind?) (change, kind),
  ];
  final owners = rows.map((r) => r.$1).where((c) => c.source == 'ownership' && c.kind == 'owner');
  return (
    rows: rows,
    won: owners.where((c) => c.factionId == factionId).length,
    lost: owners.where((c) => c.previousFactionId == factionId).length,
  );
}

List<String> _kindWords(ChangeKind kind) => switch (kind) {
  ChangeKind.conquest => ['conquest', 'conquered'],
  ChangeKind.transfer => ['transfer', 'transferred'],
  ChangeKind.abandoned => ['dropped', 'abandoned'],
  ChangeKind.claimed => ['claimed'],
  ChangeKind.reacquired => ['lost', 'retook'],
  ChangeKind.irradiated => ['irradiated', 'radiation'],
  ChangeKind.assaultStarted => ['assault', 'started'],
  ChangeKind.assaultSucceeded => ['assault', 'won'],
  ChangeKind.assaultFailed => ['assault', 'failed'],
  ChangeKind.assaultTruce => ['assault', 'truce'],
  ChangeKind.assaultEnded => ['assault', 'ended'],
  ChangeKind.racketNew => ['racket', 'new'],
  ChangeKind.racketUp => ['racket', 'up'],
  ChangeKind.racketDown => ['racket', 'down'],
  ChangeKind.racketLevel => ['racket', 'level'],
  ChangeKind.racketLost => ['racket', 'gone'],
  ChangeKind.bomb => ['dirty', 'bomb'],
};

bool _matches(MapChange change, ChangeKind kind, List<String> words, MapFaction? Function(int factionId) faction) {
  final codes = [?change.territory, ...?(change.extra?['territories'] as List<dynamic>?)?.cast<String>()];
  final factions = [faction(change.factionId), faction(change.previousFactionId)].nonNulls;
  final kindWords = _kindWords(kind);
  return words.every((word) {
    if (codes.any((c) => plainText(c).startsWith(word))) return true;
    if (kindWords.any((k) => word.length >= 3 ? k.startsWith(word) : k == word)) return true;
    return factions.any((f) => plainText(f.tag ?? '').contains(word) || plainText(f.name ?? '').contains(word));
  });
}

// Newest first, diary rows only
List<(MapChange, ChangeKind)> diaryRows(
  DayChanges day, {
  String query = '',
  int factionId = 0,
  required MapFaction? Function(int factionId) faction,
}) {
  final words = plainText(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return [
    for (final change in day.changes.reversed)
      if (classify(change) case final kind?)
        if (factionId == 0 || involvesFaction(change, factionId))
          if (_matches(change, kind, words, faction)) (change, kind),
  ];
}
