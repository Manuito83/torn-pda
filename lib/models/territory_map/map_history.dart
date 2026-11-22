import 'dart:convert';

import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

const recordYear = Duration(days: 365);

class MapHistory {
  MapHistory({
    required this.year,
    required this.generatedAt,
    required this.completeFrom,
    this.through,
    required this.wars,
    required this.owners,
    required this.rackets,
    required this.bombs,
    required this.factions,
  });

  final int year;
  final DateTime generatedAt;

  // Owners, rackets and bombs complete from here
  final DateTime completeFrom;

  // Last day in the file
  final String? through;
  final List<RecentWar> wars;
  final List<MapChange> owners;
  final List<MapChange> rackets;
  final List<DirtyBomb> bombs;
  final Map<int, MapFaction> factions;
}

MapHistory parseHistory(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  if (data['format'] != 1) {
    throw FormatException('Unknown history format: ${data['format']}');
  }
  List<List<dynamic>> rows(String key) => (data[key] as List<dynamic>? ?? const []).cast<List<dynamic>>();

  return MapHistory(
    year: data['year'] as int,
    generatedAt: unixTime(data['generated_at']),
    completeFrom: unixTime(data['complete_from']),
    through: switch (data['through']) {
      final String day when day.isNotEmpty => day,
      _ => null,
    },
    wars: [
      for (final r in rows('wars'))
        RecentWar(
          id: r[0] as int,
          territory: r[1] as String,
          start: unixTime(r[2]),
          endedAt: r[3] == null ? null : unixTime(r[3]),
          result: warResultFrom(r[4] as String?),
          aggressorId: r[5] as int,
          defenderId: r[6] as int,
          score: r[7] as int,
          target: r[8] as int,
          hasReport: r[9] == 1,
        ),
    ],
    owners: [
      for (final r in rows('owners')) mapChangeFrom([r[0], 'ownership', r[1], r[2], r[3], r[4], r[5], null]),
    ],
    rackets: [
      for (final r in rows('rackets'))
        mapChangeFrom([
          r[0],
          'racket',
          r[1],
          r[2],
          r[3],
          null,
          null,
          null,
          {'level': r[4], 'previous_level': r[5], 'name': r[6]},
        ]),
    ],
    bombs: [
      for (final r in rows('bombs'))
        DirtyBomb(
          id: r[0] as int,
          detonatedAt: unixTime(r[1]),
          factionId: r[2] as int,
          respectLost: r[3] as int,
          territories: (r[4] as List<dynamic>).cast<String>(),
        ),
    ],
    factions: parseFactionNames(data['factions'] as Map<String, dynamic>?),
  );
}

// Failed assaults always ran 72 h
RecentWar _warFromEnd(MapChange end, {DateTime? start, bool hasReport = false}) {
  final result = warResultFrom(end.kind.substring(4));
  return RecentWar(
    id: end.warId!,
    territory: end.territory!,
    start: start ?? (result == WarResult.failAssault ? end.at.subtract(warLength) : end.at),
    endedAt: start != null || result == WarResult.failAssault ? end.at : null,
    result: result,
    aggressorId: end.factionId,
    defenderId: end.previousFactionId,
    score: end.extra?['score'] as int? ?? 0,
    target: end.extra?['target'] as int? ?? 0,
    hasReport: hasReport,
  );
}

// A day's end completes an open year war
List<RecentWar> _mergeWars(List<RecentWar> yearWars, List<MapChange> changes) {
  bool isWar(MapChange c, String phase) => c.source == 'war' && c.kind.startsWith(phase) && c.warId != null;
  final starts = {
    for (final c in changes)
      if (isWar(c, 'start:')) c.warId!: c.at,
  };
  final ends = {
    for (final c in changes)
      if (isWar(c, 'end:') && c.territory != null) c.warId!: c,
  };
  final yearIds = {for (final war in yearWars) war.id};
  return [
    for (final war in yearWars)
      if (ends[war.id] case final end? when war.endedAt == null)
        _warFromEnd(end, start: war.start, hasReport: war.hasReport)
      else
        war,
    for (final end in ends.values)
      if (!yearIds.contains(end.warId)) _warFromEnd(end, start: starts[end.warId]),
  ];
}

DirtyBomb? _dayBomb(MapChange c) {
  final id = c.bombId;
  if (c.source != 'bomb' || c.kind != 'new' || id == null) return null;
  return DirtyBomb(
    id: id,
    detonatedAt: c.at,
    factionId: c.factionId,
    respectLost: c.extra?['respect_lost'] as int? ?? 0,
    territories: [...?(c.extra?['territories'] as List<dynamic>?)?.cast<String>()],
  );
}

// Day files win over the year files
MapHistory? mergeHistory(Iterable<MapHistory> years, Iterable<DayChanges> days, DateTime now) {
  if (years.isEmpty && days.isEmpty) return null;
  final covered = {for (final day in days) day.day};
  final fromDays = [for (final day in days) ...day.changes];
  List<MapChange> rows(List<MapChange> Function(MapHistory) of, String source) => [
    for (final year in years) ...of(year).where((c) => !covered.contains(dayKey(c.at))),
    ...fromDays.where((c) => c.source == source),
  ]..sort((a, b) => a.at.compareTo(b.at));

  final yearAgo = now.subtract(recordYear);
  final bombs = [for (final year in years) ...year.bombs];
  final bombIds = {for (final bomb in bombs) bomb.id};
  return MapHistory(
    year: now.year,
    generatedAt: now,
    completeFrom: years.isEmpty
        ? dayStart(covered.reduce((a, b) => a.compareTo(b) < 0 ? a : b))
        : years.map((y) => y.completeFrom).reduce((a, b) => a.isBefore(b) ? a : b),
    wars: _mergeWars([
      for (final year in years) ...year.wars,
    ], fromDays).where((w) => !w.start.isBefore(yearAgo)).toList(),
    owners: rows((y) => y.owners, 'ownership'),
    rackets: rows((y) => y.rackets, 'racket'),
    bombs: [
      ...bombs,
      for (final change in fromDays)
        if (_dayBomb(change) case final bomb? when !bombIds.contains(bomb.id)) bomb,
    ],
    factions: {
      for (final year in years) ...year.factions,
      for (final day in days) ...day.factions,
    },
  );
}

// Oldest first, today included
List<String> timelapseDays(DateTime from, DateTime now) => [
  for (var day = dayStart(dayKey(from)); !day.isAfter(now); day = day.add(const Duration(days: 1))) dayKey(day),
];

// Owners when the day ended
Map<String, Ownership> ownersAt(Map<String, Ownership> present, List<MapChange> owners, String day) {
  final end = dayStart(day).add(const Duration(days: 1));
  return undoOwners(present, owners.where((c) => !c.at.isBefore(end)));
}

String warOutcomeText(RecentWar war) => switch (war.result) {
  WarResult.successAssault => 'taken',
  WarResult.failAssault => 'held',
  WarResult.peaceTreaty => 'truce',
  WarResult.inProgress => 'in progress',
  WarResult.unknown => 'ended',
};

String historyWarText(RecentWar war, String Function(int factionId) tag) {
  final duration = war.duration;
  return '${tag(war.aggressorId)} vs ${tag(war.defenderId)}: ${warOutcomeText(war)}'
      '${duration == null ? '' : ' - ${chatSpan(duration)}'}';
}

RecentWar? longestOf(Iterable<RecentWar> wars) {
  RecentWar? longest;
  for (final war in wars) {
    final duration = war.duration;
    if (duration != null && (longest == null || duration > longest.duration!)) longest = war;
  }
  return longest;
}
