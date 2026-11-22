import 'package:torn_pda/models/territory_map/assault_math.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

class WarProgress {
  WarProgress({required this.score, required this.ends, required this.reachesTarget, required this.remaining});

  final int score;
  final DateTime ends;
  final bool reachesTarget;
  final Duration remaining;
}

bool isFactionWar(TerritoryWar war, int factionId) =>
    factionId != 0 && (war.aggressor.factionId == factionId || war.defender.factionId == factionId);

// Own faction first, then the soonest end
List<TerritoryWar> sortedWars(List<TerritoryWar> wars, int myFactionId) {
  final ends = {for (final war in wars) war.id: warEnd(war).at};
  return [...wars]..sort((a, b) {
    final mineA = isFactionWar(a, myFactionId);
    if (mineA != isFactionWar(b, myFactionId)) return mineA ? -1 : 1;
    return ends[a.id]!.compareTo(ends[b.id]!);
  });
}

// Walls, not the measured rate
WarProgress warProgressAt(TerritoryWar war, DateTime now) {
  final end = warEnd(war);
  return WarProgress(
    score: projectedScore(war, now),
    ends: end.at,
    reachesTarget: end.reachesTarget,
    remaining: end.at.isAfter(now) ? end.at.difference(now) : Duration.zero,
  );
}
