import 'package:torn_pda/models/territory_map/assault_math.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

const lockAfterWar = Duration(hours: 72);

enum LockReason { assault, afterWar }

class TerritoryLock {
  const TerritoryLock({required this.until, required this.reason, required this.warId});

  final DateTime until;
  final LockReason reason;
  final int warId;
}

DateTime? _lockEnd(RecentWar war) => war.endedAt?.add(lockAfterWar);

// Ongoing assaults count from their projected end
TerritoryLock? territoryLock(String code, List<TerritoryWar> wars, List<RecentWar> recentWars, DateTime now) {
  for (final war in wars) {
    if (war.territory != code) continue;
    return TerritoryLock(until: warEnd(war).at.add(lockAfterWar), reason: LockReason.assault, warId: war.id);
  }
  TerritoryLock? lock;
  for (final war in recentWars) {
    final until = _lockEnd(war);
    if (war.territory != code || until == null || !until.isAfter(now)) continue;
    if (lock == null || until.isAfter(lock.until)) {
      lock = TerritoryLock(until: until, reason: LockReason.afterWar, warId: war.id);
    }
  }
  return lock;
}

DateTime? factionLock(int factionId, String code, List<RecentWar> recentWars, DateTime now) {
  DateTime? latest;
  for (final war in recentWars) {
    final until = _lockEnd(war);
    if (war.territory != code || warLoser(war) != factionId || until == null || !until.isAfter(now)) continue;
    if (latest == null || until.isAfter(latest)) latest = until;
  }
  return latest;
}

Set<String> lockedCodes(MapState state, DateTime now) => {
  for (final war in state.wars) war.territory,
  for (final war in state.recentWars)
    if (_lockEnd(war)?.isAfter(now) ?? false) war.territory,
};
