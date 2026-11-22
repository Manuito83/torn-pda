import 'package:diacritic/diacritic.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

const _maxHits = 30;

class SearchHit {
  const SearchHit.territory(String this.code) : factionId = null;
  const SearchHit.faction(int this.factionId) : code = null;

  final String? code;
  final int? factionId;
}

String plainText(String text) => removeDiacritics(text).toLowerCase();

List<SearchHit> searchMap(
  String query,
  Iterable<String> codes,
  Map<int, MapFaction> factions,
  Map<int, List<String>> owned,
) {
  final text = plainText(query.trim());
  if (text.isEmpty) return const [];
  final code = text.toUpperCase();

  final exactCode = codes.where((c) => c == code);
  final codePrefix = codes.where((c) => c != code && c.startsWith(code)).toList()..sort();
  final exactTag = <int>[];
  final nameContains = <int>[];
  for (final faction in factions.values) {
    if (faction.tag != null && plainText(faction.tag!) == text) {
      exactTag.add(faction.id);
    } else if (faction.name != null && plainText(faction.name!).contains(text)) {
      nameContains.add(faction.id);
    }
  }

  int byTerritories(int a, int b) {
    final count = (owned[b]?.length ?? 0).compareTo(owned[a]?.length ?? 0);
    return count != 0 ? count : a.compareTo(b);
  }

  exactTag.sort(byTerritories);
  nameContains.sort(byTerritories);
  return [
    ...exactCode.map(SearchHit.territory),
    ...exactTag.map(SearchHit.faction),
    ...codePrefix.map(SearchHit.territory),
    ...nameContains.map(SearchHit.faction),
  ].take(_maxHits).toList();
}
