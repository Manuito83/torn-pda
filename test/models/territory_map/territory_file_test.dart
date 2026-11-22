import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

import 'sample_data.dart';

String oneTerritory(String path) => '''
  {"format": 1, "version": 2, "bounds": [0, 0, 50, 10], "territories": {"ISL": {
    "sector": 1, "size": 1, "density": 1, "slots": 1, "respect": 1, "label": [5, 5], "neighbors": [],
    "path": $path}}}''';

void main() {
  group('parseTerritoryFile', () {
    test('bundled asset', () {
      final file = wholeCity();
      expect(file.version, 1);
      expect(file.territories.length, 4108);

      final baa = file.territories['BAA']!;
      expect([baa.sector, baa.size, baa.density, baa.slots, baa.respect], [6, 3, 1, 11, 28]);
      expect(baa.label, const Offset(502.7, 297.3));
      expect(baa.neighbors, ['PUB', 'QUB', 'RUB', 'MUB', 'TCG']);
      expect(baa.points[0], closeTo(473.0, 0.01));
      expect(baa.points[1], closeTo(302.2, 0.01));
      expect(baa.bounds.left, closeTo(473.0, 0.01));
      expect(baa.bounds.right, closeTo(531.7, 0.01));
      expect(baa.bounds.top, closeTo(278.2, 0.01));
      expect(baa.bounds.bottom, closeTo(316.8, 0.01));
    });

    test('islands', () {
      final island = parseTerritoryFile(
        oneTerritory('''["M", 0, 0, "L", 10, 0, "L", 10, 10, "L", 0, 10, "Z",
          "M", 40, 0, "C", 45, -2, 48, 0, 50, 0, "L", 50, 10, "L", 40, 10, "Z"]'''),
      ).territories['ISL']!;
      final path = buildTerritoryPath(island);

      expect(path.contains(const Offset(5, 5)), isTrue);
      expect(path.contains(const Offset(45, 5)), isTrue);
      expect(path.contains(const Offset(25, 5)), isFalse);
      expect(island.bounds, const Rect.fromLTRB(0, -2, 50, 10));
    });

    test('a sector on the city edge has no border along it', () {
      const city = Rect.fromLTRB(-1, 0, 50, 10);
      final file = parseTerritoryFile(
        oneTerritory('''["M", -0.3, 2, "L", 10, 2, "L", 10, 8, "L", -0.3, 8, "Z",
          "M", 20, 2, "L", 30, 2, "L", 30, 8, "L", 20, 8, "Z"]'''),
      );
      final outline = buildTerritoryOutline(file.territories['ISL']!, city)!;
      final lengths = [for (final m in outline.computeMetrics()) m.length];
      expect(lengths[0], closeTo(10.3 + 6 + 10.3, 1e-3));
      expect(lengths[1], closeTo(32, 1e-3));

      final inside = parseTerritoryFile(oneTerritory('["M", 20, 2, "L", 30, 2, "L", 30, 8, "Z"]'));
      expect(buildTerritoryOutline(inside.territories['ISL']!, city), isNull);
    });

    test('bundled asset: sectors cut by the city edge', () {
      final file = wholeCity();
      final open = [
        for (final t in file.territories.values)
          if (buildTerritoryOutline(t, file.bounds) != null) t.code,
      ];
      expect(open, hasLength(134));
      expect(open, contains('BQF'));
    });

    test('territory without path', () {
      expect(() => parseTerritoryFile(oneTerritory('[]')), throwsFormatException);
      expect(() => parseTerritoryFile(oneTerritory('["Z"]')), throwsFormatException);
    });
  });
}
