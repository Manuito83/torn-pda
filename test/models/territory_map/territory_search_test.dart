import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_search.dart';

MapFaction faction(int id, String? name, String? tag) =>
    MapFaction(id: id, name: name, tag: tag, tagImage: null, respect: null, rank: null, members: null);

void main() {
  const codes = ['BAA', 'BAB', 'BAAX', 'CAB'];
  final factions = {
    1: faction(1, 'Baa Baa Black Sheep', 'BBS'),
    2: faction(2, 'Café Society', 'BAA'),
    3: faction(3, 'Caffeine', 'cafe'),
    4: faction(4, 'Another Café', 'AC'),
    5: faction(5, null, null),
  };
  final owned = {
    1: ['CAB'],
    3: ['BAB'],
    4: ['BAA', 'BAAX'],
  };

  List<Object?> search(String query) =>
      searchMap(query, codes, factions, owned).map((hit) => hit.code ?? hit.factionId).toList();

  test('exact code first, then tag, then prefix, then names', () {
    expect(search('baa'), ['BAA', 2, 'BAAX', 1]);
  });

  test('tags ignore case', () {
    expect(search('Bbs').first, 1);
  });

  test('names ignore accents and sort by territories', () {
    expect(search('cafe'), [3, 4, 2]);
    expect(search('Café'), [3, 4, 2]);
  });

  test('empty query finds nothing', () {
    expect(search('  '), isEmpty);
  });
}
