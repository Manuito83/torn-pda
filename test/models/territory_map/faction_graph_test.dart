import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/faction_graph.dart';

import 'sample_data.dart';

void main() {
  group('factionAdjacency', () {
    test('one-sided border', () {
      final territories = {
        'A': territory('A', ['B']),
        'B': territory('B', []),
      };
      final adjacency = factionAdjacency({'A': owned(1), 'B': owned(2)}, territories);
      expect(adjacency[1], {2});
      expect(adjacency[2], {1});
    });

    test('unowned gap does not link', () {
      final territories = {
        'A': territory('A', ['U']),
        'U': territory('U', ['A', 'B']),
        'B': territory('B', ['U']),
      };
      final adjacency = factionAdjacency({'A': owned(1), 'U': owned(0), 'B': owned(2)}, territories);
      expect(adjacency, {1: <int>{}, 2: <int>{}});
    });
  });

  test('territoriesOf', () {
    final groups = territoriesOf({'C': owned(1), 'A': owned(1), 'B': owned(2), 'D': owned(0)});
    expect(groups, {
      1: ['A', 'C'],
      2: ['B'],
    });
  });
}
