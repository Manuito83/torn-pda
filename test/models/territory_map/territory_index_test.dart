import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/territory_index.dart';

import 'sample_data.dart';

void main() {
  final territories = wholeCity().territories;
  final index = TerritoryIndex(territories.values, {for (final t in territories.values) t.code: buildTerritoryPath(t)});

  test('territoryAt', () {
    expect(index.territoryAt(territories['BAA']!.label)?.code, 'BAA');
    expect(index.territoryAt(const Offset(474.0, 295.2)), isNull);
    expect(index.territoryAt(const Offset(478.0, 295.2))?.code, 'BAA');
    expect(index.territoryAt(const Offset(470.0, 295.2))?.code, 'TCG');
    expect(index.territoryAt(const Offset(-500, -500)), isNull);
  });

  test('visibleIn', () {
    for (final view in const [
      Rect.fromLTWH(400, 200, 300, 200),
      Rect.fromLTWH(3000, 1500, 64, 64),
      Rect.fromLTWH(-100, -100, 7000, 4000),
    ]) {
      final expected = {
        for (final t in territories.values)
          if (t.bounds.overlaps(view)) t.code,
      };
      expect({for (final t in index.visibleIn(view)) t.code}, expected);
    }
  });
}
