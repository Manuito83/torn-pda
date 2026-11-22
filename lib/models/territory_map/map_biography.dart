import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

class TerritoryBiography {
  TerritoryBiography({
    required this.wars,
    required this.conquests,
    required this.longestWar,
    required this.owners,
    required this.rackets,
    required this.bombs,
    required this.ownerCount,
  });

  // Newest first
  final List<RecentWar> wars;
  final int conquests;
  final RecentWar? longestWar;
  final List<MapChange> owners;
  final List<MapChange> rackets;
  final List<DirtyBomb> bombs;

  // Current owner included
  final int ownerCount;
}

TerritoryBiography territoryBiography(MapHistory history, String code, {int owner = 0}) {
  final wars = history.wars.where((w) => w.territory == code).toList()..sort((a, b) => b.start.compareTo(a.start));
  final owners = history.owners.where((c) => c.territory == code).toList()..sort((a, b) => b.at.compareTo(a.at));
  final ownerIds = {
    owner,
    for (final change in owners)
      if (change.kind == 'owner') ...[change.factionId, change.previousFactionId],
  }..remove(0);
  return TerritoryBiography(
    ownerCount: ownerIds.length,
    wars: wars,
    conquests: wars.where((w) => w.result == WarResult.successAssault).length,
    longestWar: longestOf(wars),
    owners: owners,
    rackets: history.rackets.where((c) => c.territory == code).toList()..sort((a, b) => b.at.compareTo(a.at)),
    bombs: history.bombs.where((b) => b.territories.contains(code)).toList()
      ..sort((a, b) => b.detonatedAt.compareTo(a.detonatedAt)),
  );
}

// A MapChange, RecentWar or DirtyBomb
typedef HistoryEntry = ({DateTime at, Object event});

// Newest first, diary rows only
List<HistoryEntry> territoryTimeline(TerritoryBiography bio) => [
  for (final change in [...bio.owners, ...bio.rackets])
    if (classify(change) != null) (at: change.at, event: change),
  for (final war in bio.wars) (at: war.start, event: war),
  for (final bomb in bio.bombs) (at: bomb.detonatedAt, event: bomb),
]..sort((a, b) => b.at.compareTo(a.at));

class FactionBiography {
  FactionBiography({
    required this.won,
    required this.lost,
    required this.truces,
    required this.conquered,
    required this.gainedOtherwise,
    required this.lostToConquest,
    required this.lostOtherwise,
    required this.bombs,
  });

  final int won;
  final int lost;
  final int truces;

  // Territory changes since recording started
  final int conquered;
  final int gainedOtherwise;
  final int lostToConquest;
  final int lostOtherwise;
  final List<DirtyBomb> bombs;
}

FactionBiography factionBiography(MapHistory history, int factionId) {
  var won = 0, lost = 0, truces = 0;
  for (final war in history.wars) {
    if (war.aggressorId != factionId && war.defenderId != factionId) continue;
    if (war.result == WarResult.peaceTreaty) truces++;
    final loser = warLoser(war);
    if (loser == null) continue;
    loser == factionId ? lost++ : won++;
  }

  var conquered = 0, gainedOtherwise = 0, lostToConquest = 0, lostOtherwise = 0;
  for (final change in history.owners) {
    if (change.kind != 'owner') continue;
    if (change.factionId == factionId) change.warId != null ? conquered++ : gainedOtherwise++;
    if (change.previousFactionId == factionId) change.warId != null ? lostToConquest++ : lostOtherwise++;
  }

  return FactionBiography(
    won: won,
    lost: lost,
    truces: truces,
    conquered: conquered,
    gainedOtherwise: gainedOtherwise,
    lostToConquest: lostToConquest,
    lostOtherwise: lostOtherwise,
    bombs: history.bombs.where((b) => b.factionId == factionId).toList(),
  );
}
