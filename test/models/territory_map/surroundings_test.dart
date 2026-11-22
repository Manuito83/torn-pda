import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';

void main() {
  test('dashes carry on round a bend', () {
    final pieces = dashLine(Float32List.fromList([0, 0, 30, 0, 30, 30]), 14, 12);
    expect(pieces.map((p) => p.toList()), [
      [0, 0, 14, 0],
      [26, 0, 30, 0, 30, 10],
      [30, 22, 30, 30],
    ]);
  });

  test('the view stops short of the far photo', () {
    final s = surroundingsFromGzip(File('assets/territory_map/surroundings-v1.json.bin').readAsBytesSync());
    expect(viewReach(s.bounds, s.horizon, s.far), const Rect.fromLTRB(-3900, -7850, 10160, 11260));
  });

  test('a tap on a closure picks its sector, on a block nothing', () {
    final s = surroundingsFromGzip(File('assets/territory_map/surroundings-v1.json.bin').readAsBytesSync());
    expect(closureAt(s, const Offset(2443, -41)), 'BQF');

    final block = s.shapes[StripShape.blocks0]!.first;
    var x = 0.0, y = 0.0;
    for (var i = 0; i < block.length; i += 2) {
      x += block[i];
      y += block[i + 1];
    }
    final middle = Offset(x / (block.length / 2), y / (block.length / 2));
    expect(insideRing(middle.dx, middle.dy, block), isTrue);
    expect(closureAt(s, middle), isNull);
  });
}
