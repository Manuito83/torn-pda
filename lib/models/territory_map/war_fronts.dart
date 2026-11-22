import 'package:collection/collection.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

const frontDays = Duration(days: 7);

typedef Conquest = ({String code, int factionId, DateTime at});

class FrontStep {
  const FrontStep({required this.code, required this.from, required this.at});

  final String code;

  // Null on the first conquest
  final String? from;
  final DateTime at;
}

class WarFront {
  WarFront(this.factionId, this.steps);

  final int factionId;

  // Oldest first
  final List<FrontStep> steps;

  DateTime get lastAt => steps.last.at;
}

// Both sources carry the same war once
List<Conquest> conquestsSince(DateTime since, Iterable<RecentWar> wars, Iterable<MapChange> changes) {
  final byWar = <int, Conquest>{};
  for (final change in changes) {
    if (classify(change) != ChangeKind.conquest || change.at.isBefore(since)) continue;
    byWar[change.warId!] = (code: change.territory!, factionId: change.factionId, at: change.at);
  }
  for (final war in wars) {
    final at = war.endedAt;
    if (war.result != WarResult.successAssault || at == null || at.isBefore(since)) continue;
    byWar[war.id] = (code: war.territory, factionId: war.aggressorId, at: at);
  }
  return byWar.values.toList()..sort((a, b) => a.at.compareTo(b.at));
}

// Chained conquests of neighboring territories
List<WarFront> warFronts(List<Conquest> conquests, Map<String, Territory> territories, {int minSteps = 2}) {
  final fronts = <WarFront>[];
  for (final conquest in conquests) {
    final neighbors = territories[conquest.code]?.neighbors ?? const <String>[];
    WarFront? front;
    String? from;
    for (final candidate in fronts) {
      if (candidate.factionId != conquest.factionId) continue;
      if (front != null && !candidate.lastAt.isAfter(front.lastAt)) continue;
      final parent = candidate.steps.lastWhereOrNull((s) => neighbors.contains(s.code));
      if (parent == null) continue;
      front = candidate;
      from = parent.code;
    }
    final step = FrontStep(code: conquest.code, from: from, at: conquest.at);
    front == null ? fronts.add(WarFront(conquest.factionId, [step])) : front.steps.add(step);
  }

  return fronts.where((f) => f.steps.length >= minSteps).toList()..sort((a, b) => b.lastAt.compareTo(a.lastAt));
}
