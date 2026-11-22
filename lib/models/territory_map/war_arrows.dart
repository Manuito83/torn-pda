import 'package:torn_pda/models/territory_map/assault_math.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';

enum AssaultMomentum { advancing, slow, blocked, stalled }

class AssaultArrow {
  const AssaultArrow({
    required this.warId,
    required this.factionId,
    required this.from,
    required this.to,
    required this.adjacent,
    required this.momentum,
    required this.progress,
  });

  final int warId;
  final int factionId;

  // Null when the aggressor holds nothing
  final String? from;
  final String to;
  final bool adjacent;
  final AssaultMomentum momentum;

  // 0 to 1
  final double progress;
}

double assaultProgress(TerritoryWar war, DateTime now) {
  if (war.target <= 0) return 0;
  return (projectedScore(war, now) / war.target).clamp(0.0, 1.0);
}

// In screen pixels
({double width, double headLength, double headWidth}) arrowShape(double length, {double weight = 1}) {
  final width = (length * 0.12).clamp(4.0, 11.0) * weight;
  return (width: width, headLength: width * 1.9, headWidth: width * 2.4);
}

AssaultMomentum assaultMomentum(TerritoryWar war, DateTime now) {
  final attackers = war.aggressor.wall;
  if (isStalled(war, now)) return AssaultMomentum.stalled;
  if (attackers == 0) return AssaultMomentum.slow;
  if (pace(attackers, war.defender.wall) <= 0) return AssaultMomentum.blocked;
  return warEnd(war).reachesTarget ? AssaultMomentum.advancing : AssaultMomentum.slow;
}

// Nearest aggressor territory, neighbors first
({String code, bool adjacent})? assaultOrigin(
  TerritoryWar war,
  Map<String, Territory> territories,
  Map<String, Ownership> ownership,
) {
  final target = territories[war.territory];
  if (target == null) return null;
  final aggressor = war.aggressor.factionId;

  String? nearest(Iterable<String> codes) {
    String? best;
    var bestDistance = double.infinity;
    for (final code in codes) {
      final territory = territories[code];
      if (territory == null || code == target.code || ownership[code]?.factionId != aggressor) continue;
      final distance = (territory.label - target.label).distanceSquared;
      if (distance < bestDistance || (distance == bestDistance && code.compareTo(best!) < 0)) {
        bestDistance = distance;
        best = code;
      }
    }
    return best;
  }

  final neighbor = nearest(target.neighbors);
  if (neighbor != null) return (code: neighbor, adjacent: true);
  final any = nearest(ownership.keys);
  return any == null ? null : (code: any, adjacent: false);
}

List<AssaultArrow> assaultArrows(MapState state, Map<String, Territory> territories, DateTime now) {
  final arrows = <AssaultArrow>[];
  for (final war in state.wars) {
    if (!territories.containsKey(war.territory)) continue;
    final origin = assaultOrigin(war, territories, state.ownership);
    arrows.add(
      AssaultArrow(
        warId: war.id,
        factionId: war.aggressor.factionId,
        from: origin?.code,
        to: war.territory,
        adjacent: origin?.adjacent ?? false,
        momentum: assaultMomentum(war, now),
        progress: assaultProgress(war, now),
      ),
    );
  }
  return arrows;
}
