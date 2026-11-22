import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

// Unowned territories never link factions
Map<int, Set<int>> factionAdjacency(Map<String, Ownership> ownership, Map<String, Territory> territories) {
  final adjacency = <int, Set<int>>{};
  for (final territory in territories.values) {
    final owner = ownership[territory.code]?.factionId ?? 0;
    if (owner == 0) continue;
    final neighbors = adjacency.putIfAbsent(owner, () => <int>{});
    for (final code in territory.neighbors) {
      final other = ownership[code]?.factionId ?? 0;
      if (other == 0 || other == owner) continue;
      neighbors.add(other);
      adjacency.putIfAbsent(other, () => <int>{}).add(owner);
    }
  }
  return adjacency;
}

Map<int, List<String>> territoriesOf(Map<String, Ownership> ownership) {
  final result = <int, List<String>>{};
  ownership.forEach((code, row) {
    if (row.factionId != 0) result.putIfAbsent(row.factionId, () => []).add(code);
  });
  for (final codes in result.values) {
    codes.sort();
  }
  return result;
}
