import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_pictures.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

import 'sample_data.dart';

void main() {
  final territories = {
    'AAA': territory('AAA', const [], bounds: const Rect.fromLTRB(0, 0, 100, 100)),
    'RCD': territory('RCD', const [], bounds: const Rect.fromLTRB(900, 0, 1000, 100)),
  };

  MapState stateWith({Map<String, Ownership> ownership = const {}, List<TerritoryWar> wars = const []}) => MapState(
    generatedAt: scoreTime,
    territoriesVersion: 1,
    readAt: const {},
    ownership: ownership,
    wars: wars,
    rackets: const {},
    factions: const {},
    bombs: const [],
  );

  test('a faction with no territory or war has no picture', () {
    final state = stateWith(ownership: {'AAA': owned(2)}, wars: [liveWar(aggressorId: 3)]);
    expect(factionPicture(7, state, territories, minSize: 0), isNull);
  });

  test('its wars widen the picture', () {
    final state = stateWith(
      ownership: {'AAA': owned(7)},
      wars: [liveWar(code: 'RCD', aggressorId: 7)],
    );
    final picture = factionPicture(7, state, territories, minSize: 0)!;
    expect(picture.area.left, lessThan(0));
    expect(picture.area.right, greaterThan(1000));
    expect(picture.shades.keys, {'AAA', 'RCD'});
    expect(picture.wars, hasLength(1));
  });

  test('a small faction gets at least the minimum size', () {
    final state = stateWith(ownership: {'AAA': owned(7)});
    final picture = factionPicture(7, state, territories, minSize: 500)!;
    expect(picture.area.size, const Size(500, 500));
    expect(picture.area.center, const Offset(50, 50));
  });

  test('fitAspect grows the short side around the center', () {
    final wide = fitAspect(const Rect.fromLTRB(0, 0, 100, 100), 2);
    expect(wide, const Rect.fromLTRB(-50, 0, 150, 100));
    final tall = fitAspect(const Rect.fromLTRB(0, 0, 400, 100), 2);
    expect(tall, const Rect.fromLTRB(0, -50, 400, 150));
  });
}
