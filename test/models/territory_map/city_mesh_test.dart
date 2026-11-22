import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';

import 'sample_data.dart';

void main() {
  test('concave ring with a hole', () {
    final outer = <double>[0, 0, 30, 0, 30, 10, 10, 10, 10, 30, 0, 30];
    final hole = <double>[2, 2, 2, 6, 6, 6, 6, 2];
    expect(ringArea(outer), greaterThan(0));
    expect(ringArea(hole), lessThan(0));

    final coords = [...outer, ...hole];
    final triangles = triangulate(coords, 6, [6]);
    var area = 0.0;
    for (var k = 0; k < triangles.length; k += 3) {
      final a = triangles[k] * 2, b = triangles[k + 1] * 2, c = triangles[k + 2] * 2;
      area +=
          ((coords[b] - coords[a]) * (coords[c + 1] - coords[a + 1]) -
              (coords[b + 1] - coords[a + 1]) * (coords[c] - coords[a])) /
          2;
    }
    expect(area, closeTo(500 - 16, 1e-9));
  });

  test('simplify keeps corners and drops what sits on a line', () {
    final ring = <double>[0, 0, 5, 0.1, 10, 0, 10, 10, 0, 10];
    expect(simplifyRing(ring, 0.5), [0, 0, 10, 0, 10, 10, 0, 10]);
    expect(simplifyRing(ring, 0.05), ring);
  });

  test('every territory top covers its own area', () {
    final mesh = buildCityMesh(wholeCity());
    expect(mesh.length, 4108);
    for (final level in [mesh.full, mesh.moving]) {
      final wrong = <String>[];
      for (var t = 0; t < mesh.length; t++) {
        var rings = 0.0;
        for (var r = level.firstRing[t]; r < level.firstRing[t + 1]; r++) {
          rings += ringArea([
            for (var v = level.ringStart[r]; v < level.ringStart[r + 1]; v++) ...[level.x[v], level.y[v]],
          ]);
        }
        var tops = 0.0;
        for (var k = level.firstTriangle[t]; k < level.firstTriangle[t + 1]; k += 3) {
          final a = level.triangles[k], b = level.triangles[k + 1], c = level.triangles[k + 2];
          tops +=
              ((level.x[b] - level.x[a]) * (level.y[c] - level.y[a]) -
                  (level.y[b] - level.y[a]) * (level.x[c] - level.x[a])) /
              2;
        }
        if ((tops - rings).abs() > rings.abs() * 0.01) wrong.add(mesh.codes[t]);
      }
      expect(wrong, isEmpty);
    }
  });
}
