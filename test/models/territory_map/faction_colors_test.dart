import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/faction_colors.dart';
import 'package:torn_pda/models/territory_map/faction_graph.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

import 'sample_data.dart';

Map<String, Territory> clique(List<String> codes) => {
  for (final code in codes)
    code: territory(code, [
      for (final other in codes)
        if (other != code) other,
    ]),
};

List<int> idsWhere(bool Function(int id) test, int count, {int from = 1000}) {
  final ids = <int>[];
  for (var id = from; ids.length < count; id++) {
    if (test(id)) ids.add(id);
  }
  return ids;
}

void main() {
  test('similar', () {
    expect(similar(3, 13), isTrue);
    expect(similar(3, 24), isFalse);
    expect(similar(3, 4), isTrue);
    expect(similar(9, mineColor), isTrue);
    expect(similar(29, mineColor), isTrue);
    expect(similar(8, mineColor), isFalse);
  });

  group('assignFactionColors', () {
    test('neighbors never similar', () {
      final territories = sectorsOneAndTwo().territories;
      final ownership = sampleState().ownership;
      final colors = assignFactionColors(ownership, territories);

      final clashes = <String>[];
      factionAdjacency(ownership, territories).forEach((faction, neighbors) {
        for (final other in neighbors) {
          if (faction < other && similar(colors[faction]!, colors[other]!)) clashes.add('$faction-$other');
        }
      });
      expect(clashes, isEmpty);
    });

    test('input order', () {
      final territories = sectorsOneAndTwo().territories;
      final ownership = sampleState().ownership;
      final first = assignFactionColors(ownership, territories, myFactionId: 6799);
      final reversed = assignFactionColors(
        Map.fromEntries(ownership.entries.toList().reversed),
        Map.fromEntries(territories.entries.toList().reversed),
        myFactionId: 6799,
      );
      expect(reversed, first);
    });

    test('hashed color', () {
      final colors = assignFactionColors(
        {'A': owned(6799), 'B': owned(14821)},
        {'A': territory('A', []), 'B': territory('B', [])},
      );
      expect(colors, {6799: 17, 14821: 7});
    });

    test('locality', () {
      final territories = {
        ...clique(['A1', 'A2', 'A3', 'A4', 'A5']),
        ...clique(['B1', 'B2', 'B3', 'B4', 'B5']),
      };
      final ownership = {
        for (var i = 1; i <= 5; i++) 'A$i': owned(100 + i),
        for (var i = 1; i <= 5; i++) 'B$i': owned(200 + i),
      };
      final before = assignFactionColors(ownership, territories);
      final after = assignFactionColors({...ownership, 'A3': owned(150)}, territories);
      for (var i = 1; i <= 5; i++) {
        expect(after[200 + i], before[200 + i]);
      }
    });

    test('my faction color', () {
      final purpleIds = idsWhere((id) => preferredColor(id) % 10 == 9, 12);
      final territories = {
        'ME': territory('ME', [for (final id in purpleIds) 'T$id']),
        for (final id in purpleIds) 'T$id': territory('T$id', ['ME']),
      };
      final ownership = {'ME': owned(6799), for (final id in purpleIds) 'T$id': owned(id)};
      final colors = assignFactionColors(ownership, territories, myFactionId: 6799);

      expect(colors[6799], mineColor);
      for (final id in purpleIds) {
        expect(colors[id], isNot(mineColor));
        expect(colors[id]! % 10, isNot(9));
      }
    });

    test('boxed in by every color', () {
      const free = 13;
      final ids = idsWhere((id) => preferredColor(id) != free, 40);
      expect({for (final id in ids) preferredColor(id)}.length, paletteSize - 1);

      final territories = {
        'C': territory('C', [for (final id in ids) 'N$id']),
        for (final id in ids) 'N$id': territory('N$id', ['C']),
        for (final id in ids) 'F$id': territory('F$id', []),
      };
      final ownership = {
        'C': owned(1),
        for (final id in ids) 'N$id': owned(id),
        for (final id in ids) 'F$id': owned(id),
      };
      final colors = assignFactionColors(ownership, territories);
      expect(colors[1], free);
    });

    test('kept colors and a new neighbor', () {
      final territories = sectorsOneAndTwo().territories;
      final ownership = sampleState().ownership;
      final present = assignFactionColors(ownership, territories, myFactionId: 6799);
      final past = {
        ...ownership,
        ownership.keys.firstWhere(
          (c) => (territories[c]?.neighbors ?? []).any((n) => (ownership[n]?.factionId ?? 0) != 0),
        ): owned(424242),
      };
      final colors = assignFactionColors(past, territories, myFactionId: 6799, keep: present);

      final adjacency = factionAdjacency(past, territories);
      expect(adjacency[424242], isNotEmpty);
      for (final other in adjacency[424242]!) {
        expect(similar(colors[424242]!, colors[other]!), isFalse);
      }
      final changed = [
        for (final e in present.entries)
          if (colors.containsKey(e.key) && colors[e.key] != e.value) e.key,
      ];
      expect(changed, isEmpty);
    });

    test('kept colors that now clash', () {
      final territories = {
        'A1': territory('A1', ['B1']),
        'A2': territory('A2', []),
        'B1': territory('B1', ['A1']),
      };
      final colors = assignFactionColors(
        {'A1': owned(1), 'A2': owned(1), 'B1': owned(2)},
        territories,
        keep: {1: 4, 2: 4},
      );
      expect(colors[1], 4);
      expect(similar(colors[2]!, 4), isFalse);
    });

    test('unowned gap can share a color', () {
      final pair = idsWhere((id) => preferredColor(id) == preferredColor(1000), 2);
      final territories = {
        'A': territory('A', ['U']),
        'U': territory('U', ['A', 'B']),
        'B': territory('B', ['U']),
      };
      final colors = assignFactionColors({'A': owned(pair[0]), 'U': owned(0), 'B': owned(pair[1])}, territories);
      expect(colors[pair[0]], colors[pair[1]]);
    });
  });
}
