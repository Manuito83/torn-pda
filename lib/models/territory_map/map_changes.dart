import 'dart:convert';

import 'package:torn_pda/models/territory_map/map_state.dart';

enum ChangeKind {
  conquest,
  transfer,
  abandoned,
  claimed,
  reacquired,
  irradiated,
  assaultStarted,
  assaultSucceeded,
  assaultFailed,
  assaultTruce,
  assaultEnded,
  racketNew,
  racketUp,
  racketDown,
  racketLevel,
  racketLost,
  bomb,
}

class MapChange {
  MapChange({
    required this.at,
    required this.source,
    required this.territory,
    required this.kind,
    required this.factionId,
    required this.previousFactionId,
    required this.warId,
    required this.bombId,
    required this.extra,
  });

  final DateTime at;
  final String source;

  // Null on bomb rows
  final String? territory;
  final String kind;
  final int factionId;
  final int previousFactionId;
  final int? warId;
  final int? bombId;
  final Map<String, dynamic>? extra;
}

class DayChanges {
  DayChanges({
    required this.day,
    required this.revision,
    required this.generatedAt,
    required this.factions,
    required this.changes,
  });

  final String day;
  final int revision;
  final DateTime generatedAt;
  final Map<int, MapFaction> factions;
  final List<MapChange> changes;
}

// Only names and tags travel with changes
Map<int, MapFaction> parseFactionNames(Map<String, dynamic>? data) => {
  for (final e in (data ?? const {}).entries)
    int.parse(e.key): MapFaction(
      id: int.parse(e.key),
      name: e.value['name'] as String?,
      tag: e.value['tag'] as String?,
      tagImage: null,
      respect: null,
      rank: null,
      members: null,
    ),
};

// Faction ids may be null
MapChange mapChangeFrom(List<dynamic> row) => MapChange(
  at: unixTime(row[0]),
  source: row[1] as String,
  territory: row[2] as String?,
  kind: row[3] as String,
  factionId: row[4] as int? ?? 0,
  previousFactionId: row[5] as int? ?? 0,
  warId: row[6] as int?,
  bombId: row[7] as int?,
  extra: row.length > 8 ? row[8] as Map<String, dynamic>? : null,
);

DayChanges parseDayChanges(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  if (data['format'] != 1) {
    throw FormatException('Unknown changes format: ${data['format']}');
  }
  return DayChanges(
    day: data['day'] as String,
    revision: data['revision'] as int? ?? 1,
    generatedAt: unixTime(data['generated_at']),
    factions: parseFactionNames(data['factions'] as Map<String, dynamic>?),
    changes: [for (final row in (data['changes'] as List<dynamic>).cast<List<dynamic>>()) mapChangeFrom(row)],
  );
}

// Null for rows the diary hides
ChangeKind? classify(MapChange change) {
  switch (change.source) {
    case 'ownership':
      return switch (change.kind) {
        'owner' when change.factionId == 0 && change.previousFactionId == 0 => null,
        'owner' when change.warId != null => ChangeKind.conquest,
        'owner' when change.factionId == 0 => ChangeKind.abandoned,
        'owner' when change.previousFactionId == 0 => ChangeKind.claimed,
        'owner' => ChangeKind.transfer,
        'reacquired' => ChangeKind.reacquired,
        'irradiated' => ChangeKind.irradiated,
        _ => null,
      };
    case 'war':
      final parts = change.kind.split(':');
      if (parts.first == 'start') return ChangeKind.assaultStarted;
      if (parts.first != 'end') return null;
      return switch (warResultFrom(parts.last)) {
        WarResult.successAssault => ChangeKind.assaultSucceeded,
        WarResult.failAssault => ChangeKind.assaultFailed,
        WarResult.peaceTreaty => ChangeKind.assaultTruce,
        _ => ChangeKind.assaultEnded,
      };
    case 'racket':
      final level = change.extra?['level'] as int?;
      final previous = change.extra?['previous_level'] as int?;
      return switch (change.kind) {
        'new' => ChangeKind.racketNew,
        'removed' => ChangeKind.racketLost,
        'level' when level == null || previous == null || level == previous => ChangeKind.racketLevel,
        'level' => level! > previous! ? ChangeKind.racketUp : ChangeKind.racketDown,
        _ => null,
      };
    case 'bomb':
      return change.kind == 'new' ? ChangeKind.bomb : null;
  }
  return null;
}

Map<ChangeKind, int> summarize(Iterable<MapChange> changes, DateTime since) {
  final counts = <ChangeKind, int>{};
  for (final change in changes) {
    if (change.at.isBefore(since)) continue;
    final kind = classify(change);
    if (kind != null) counts.update(kind, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}

// Territories won minus lost, by faction
Map<int, int> netGains(Iterable<MapChange> changes) {
  final gains = <int, int>{};
  for (final change in changes) {
    if (change.source != 'ownership' || change.kind != 'owner') continue;
    if (change.factionId != 0) gains.update(change.factionId, (n) => n + 1, ifAbsent: () => 1);
    if (change.previousFactionId != 0) gains.update(change.previousFactionId, (n) => n - 1, ifAbsent: () => -1);
  }
  return gains;
}

// Ownership before the given changes
Map<String, Ownership> undoOwners(Map<String, Ownership> ownership, Iterable<MapChange> changes) {
  final result = Map.of(ownership);
  final newestFirst = changes.where((c) => c.source == 'ownership').toList()..sort((a, b) => b.at.compareTo(a.at));
  for (final change in newestFirst) {
    final now = result[change.territory];
    if (now == null) continue;
    result[change.territory!] = switch (change.kind) {
      'owner' => Ownership(factionId: change.previousFactionId, acquiredAt: null, irradiated: now.irradiated),
      'reacquired' => Ownership(factionId: now.factionId, acquiredAt: null, irradiated: now.irradiated),
      'irradiated' => Ownership(factionId: now.factionId, acquiredAt: now.acquiredAt, irradiated: !now.irradiated),
      _ => now,
    };
  }
  return result;
}
