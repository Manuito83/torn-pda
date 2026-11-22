import 'package:torn_pda/models/territory_map/assault_locks.dart';
import 'package:torn_pda/models/territory_map/assault_math.dart';
import 'package:torn_pda/models/territory_map/faction_graph.dart';
import 'package:torn_pda/models/territory_map/map_economy.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

class FactionTarget {
  const FactionTarget({
    required this.code,
    required this.ownerId,
    required this.lockedUntil,
    required this.target,
    required this.respect,
    required this.racketValue,
  });

  final String code;
  final int ownerId;

  // Null when it can be assaulted now
  final DateTime? lockedUntil;
  final int target;
  final int respect;
  final int? racketValue;

  bool get isOpen => lockedUntil == null;

  double get dailyValue => respect + (racketValue ?? 0) / 10000;
}

List<FactionTarget> factionTargets(int factionId, MapState state, Map<String, Territory> territories, DateTime now) {
  final own = (territoriesOf(state.ownership)[factionId] ?? const []).toSet();
  final candidates = <String>{for (final code in own) ...?territories[code]?.neighbors}.difference(own);

  final targets = <FactionTarget>[];
  for (final code in candidates) {
    final territory = territories[code];
    if (territory == null) continue;
    final territoryUntil = territoryLock(code, state.wars, state.recentWars, now)?.until;
    final factionUntil = factionLock(factionId, code, state.recentWars, now);
    final lockedUntil = factionUntil != null && (territoryUntil == null || factionUntil.isAfter(territoryUntil))
        ? factionUntil
        : territoryUntil;
    final racket = state.rackets[code];
    targets.add(
      FactionTarget(
        code: code,
        ownerId: state.ownership[code]?.factionId ?? 0,
        lockedUntil: lockedUntil,
        target: targetFor(territory.slots),
        respect: territory.respect,
        racketValue: racket == null ? null : racketDailyValue(racket),
      ),
    );
  }
  targets.sort((a, b) {
    if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
    final byValue = b.dailyValue.compareTo(a.dailyValue);
    return byValue != 0 ? byValue : a.code.compareTo(b.code);
  });
  return targets;
}
