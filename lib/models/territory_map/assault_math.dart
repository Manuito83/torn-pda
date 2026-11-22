import 'package:torn_pda/models/territory_map/map_state.dart';

int targetFor(int slots) => 50000 * slots;

// Points a minute for the aggressor
int pace(int attackers, int defenders) => (attackers - defenders) * 60;

int projectedScore(TerritoryWar war, DateTime now) {
  final minutes = now.difference(war.scoreAt).inSeconds / 60;
  final extrapolated = minutes.clamp(0, staleDataAfter.inMinutes) * pace(war.aggressor.wall, war.defender.wall);
  return (war.aggressor.score + extrapolated).clamp(0, war.target).round();
}

Duration? timeToTarget(int remaining, int attackers, int defenders) {
  if (remaining <= 0) return Duration.zero;
  final perMinute = pace(attackers, defenders);
  if (perMinute <= 0) return null;
  return Duration(seconds: (remaining / perMinute * 60).ceil());
}

// Both sides share the wall slots
bool finishesWithin(int remaining, int attackers, int defenders, Duration left, int slots) {
  if (attackers + defenders > slots) return false;
  final toTarget = timeToTarget(remaining, attackers, defenders);
  return toTarget != null && toTarget <= left;
}

// Null when a full wall falls short
int? attackersNeeded(int remaining, int defenders, Duration within, int slots) {
  if (within.inSeconds <= 0) return null;
  if (remaining <= 0) return 0;
  final needed = (remaining / within.inSeconds + defenders).ceil();
  return needed + defenders > slots ? null : needed;
}

({DateTime at, bool reachesTarget}) warEnd(TerritoryWar war) {
  final toTarget = timeToTarget(war.target - war.aggressor.score, war.aggressor.wall, war.defender.wall);
  if (toTarget == null) return (at: war.scheduledEnd, reachesTarget: false);
  final atTarget = war.scoreAt.add(toTarget);
  if (atTarget.isAfter(war.scheduledEnd)) return (at: war.scheduledEnd, reachesTarget: false);
  return (at: atTarget, reachesTarget: true);
}
