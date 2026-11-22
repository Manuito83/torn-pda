import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/surroundings_relief.dart';

void main() {
  final relief = reliefFromGzip(File('assets/territory_map/surroundings-height-v1.bin').readAsBytesSync());
  final s = surroundingsFromGzip(File('assets/territory_map/surroundings-v1.json.bin').readAsBytesSync());

  test('blends the four corners and stays flat off the grid', () {
    final r = Relief(left: 0, top: 0, cell: 10, columns: 2, rows: 2, heights: Float32List.fromList([0, 10, 20, 30]));
    expect(reliefAt(r, 5, 5), 15);
    expect(reliefAt(r, 10, 0), 10);
    expect(reliefAt(r, -1, 5), 0);
  });

  test('hills rise outside, the city edge and the sea stay flat', () {
    expect(reliefAt(relief, 3050, -2300), greaterThan(300));
    expect(reliefAt(relief, 400, 4440), greaterThan(120));
    expect(reliefAt(relief, 4080, 5380), greaterThan(50));
    expect(reliefAt(relief, 3000, 0), 0);
    expect(reliefAt(relief, 6256, 1500), 0);
    expect(reliefAt(relief, 3000, 7000), 0);
  });

  test('lines keep the edges and widen away from the city', () {
    final lines = reliefLines(-4000, 0, 3000, 9000, [-2500, 6000]);
    for (final edge in [-4000.0, -2500.0, 0.0, 3000.0, 6000.0, 9000.0]) {
      expect(lines, contains(edge));
    }
    for (var i = 1; i < lines.length; i++) {
      expect(lines[i], greaterThan(lines[i - 1]));
    }
    final first = lines.indexOf(3000);
    expect(lines[first + 1] - 3000, lessThan(lines.last - lines[lines.length - 2]));
  });

  test('each cell takes its photo from one atlas piece and none covers the city', () {
    final mesh = ReliefMesh(relief, s);
    bool split(List<double> at, double from, double to) => at.any((edge) => from < edge && edge < to);
    final columns = mesh.xs.length;
    for (final at in mesh.cells) {
      final c = at % columns, r = at ~/ columns;
      expect(split(mesh.atlasX.at, mesh.xs[c], mesh.xs[c + 1]), isFalse);
      expect(split(mesh.atlasY.at, mesh.ys[r], mesh.ys[r + 1]), isFalse);
      final center = ((mesh.xs[c] + mesh.xs[c + 1]) / 2, (mesh.ys[r] + mesh.ys[r + 1]) / 2);
      expect(s.bounds.contains(Offset(center.$1, center.$2)), isFalse);
    }
    // Continuous across a piece edge
    final edge = mesh.atlasX.at[1];
    expect(atlasPixel(mesh.atlasX, edge - 1e-6), closeTo(atlasPixel(mesh.atlasX, edge + 1e-6), 1e-3));
  });

  test('cells far from the camera come first', () {
    final mesh = ReliefMesh(relief, s);
    final order = Int32List(mesh.cells.length);
    double y(int cell) => mesh.ys[mesh.cells[cell] ~/ mesh.xs.length];
    reliefFarFirst(mesh, 0, order);
    expect(y(order.first), lessThan(y(order.last)));
    reliefFarFirst(mesh, pi, order);
    expect(y(order.first), greaterThan(y(order.last)));
  });

  test('fog clear by the target, thick towards the horizon', () {
    expect(reliefFog(0), 0);
    expect(reliefFog(-3000), 0);
    var last = 0.0;
    for (var beyond = 0.0; beyond < 15000; beyond += 500) {
      expect(reliefFog(beyond), greaterThanOrEqualTo(last));
      last = reliefFog(beyond);
    }
    expect(last, greaterThan(0.9));
  });
}
