import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

class CityRecords {
  CityRecords({
    required this.mostAssaulted,
    required this.longestWar,
    required this.oldestOwner,
    required this.topConquerors,
  });

  final ({String code, int assaults})? mostAssaulted;
  final RecentWar? longestWar;
  final ({String code, int factionId, DateTime since})? oldestOwner;
  final List<({int factionId, int conquests})> topConquerors;
}

CityRecords cityRecords(MapHistory history, Map<String, Ownership> ownership, {int limit = 5}) {
  final assaults = <String, int>{};
  final conquests = <int, int>{};
  for (final war in history.wars) {
    assaults.update(war.territory, (n) => n + 1, ifAbsent: () => 1);
    if (war.result == WarResult.successAssault) {
      conquests.update(war.aggressorId, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  ({String code, int assaults})? mostAssaulted;
  assaults.forEach((code, count) {
    if (mostAssaulted == null ||
        count > mostAssaulted!.assaults ||
        (count == mostAssaulted!.assaults && code.compareTo(mostAssaulted!.code) < 0)) {
      mostAssaulted = (code: code, assaults: count);
    }
  });

  ({String code, int factionId, DateTime since})? oldestOwner;
  ownership.forEach((code, row) {
    final since = row.acquiredAt;
    if (row.factionId == 0 || since == null) return;
    if (oldestOwner == null || since.isBefore(oldestOwner!.since)) {
      oldestOwner = (code: code, factionId: row.factionId, since: since);
    }
  });

  final top = [for (final e in conquests.entries) (factionId: e.key, conquests: e.value)]
    ..sort(
      (a, b) => b.conquests != a.conquests ? b.conquests.compareTo(a.conquests) : a.factionId.compareTo(b.factionId),
    );

  return CityRecords(
    mostAssaulted: mostAssaulted,
    longestWar: longestOf(history.wars),
    oldestOwner: oldestOwner,
    topConquerors: top.take(limit).toList(),
  );
}
