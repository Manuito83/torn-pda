import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/flight_labels.dart';
import 'package:torn_pda/models/territory_map/map_labels.dart';

const _area = Rect.fromLTWH(0, 0, 400, 400);

PlaneMark _plane(int id, String name, Offset at) => PlaneMark(
  flight: Flight(id: id, name: name, from: 'Torn', to: 'Japan'),
  at: at,
  heading: 0,
);

double _width(String text) => text.length * 6.0;

void main() {
  test('a name that hits something is shortened, then hidden', () {
    final space = LabelSpace()
      ..clear(_area)
      ..block(const Rect.fromLTWH(125, 111, 20, 13));
    final names = placePlaneNames(
      space,
      [
        _plane(1, 'Kestrel_88', const Offset(100, 100)),
        _plane(2, 'Rook', const Offset(100, 105)),
        _plane(3, 'ThunderHorse_99', const Offset(300, 300)),
        _plane(4, 'Wren', const Offset(398, 200)),
        _plane(5, 'Pike91', const Offset(500, 200)),
      ],
      _width,
      chosen: 3,
    );
    expect(names.shown.map((n) => n.text), ['Kestr…']);
    expect(names.hidden, 2);
  });

  test('a crowd shows 7 rays and a count, 15 when closer', () {
    final widths = List.filled(20, 40.0);
    final far = placeStar(LabelSpace()..clear(_area), const Offset(200, 200), widths, perDegree: 5, moreWidth: 30);
    expect(far.names.length, 7);
    expect(far.hidden, 13);
    expect(far.more, isNotNull);

    final close = placeStar(LabelSpace()..clear(_area), const Offset(200, 200), widths, perDegree: 13, moreWidth: 30);
    expect(close.names.length, 15);
    expect(close.hidden, 5);
  });

  test('a small group gets one ray each and no count', () {
    final star = placeStar(
      LabelSpace()..clear(_area),
      const Offset(200, 200),
      [40, 40, 40],
      perDegree: 5,
      moreWidth: 30,
    );
    expect(star.names.map((n) => n.index), [0, 1, 2]);
    expect(star.more, isNull);
    expect(star.hidden, 0);
  });

  test('names that do not fit by the edge are counted', () {
    final star = placeStar(
      LabelSpace()..clear(_area),
      const Offset(60, 200),
      List.filled(8, 60.0),
      perDegree: 5,
      moreWidth: 30,
    );
    expect(star.names.length, lessThan(8));
    expect(star.hidden, 8 - star.names.length);
    expect(star.more, isNotNull);
    expect(star.names.first.index, 0);
  });

  test('a tap goes to the name before the plane around it', () {
    const taps = <FlightTap>[
      (box: Rect.fromLTWH(81, 81, 38, 38), member: 1, place: null, focus: false, name: false),
      (box: Rect.fromLTWH(105, 112, 40, 13), member: 2, place: null, focus: false, name: true),
      (box: Rect.fromLTWH(189, 189, 22, 22), member: null, place: 'Japan', focus: true, name: false),
    ];
    expect(flightTapAt(taps, const Offset(110, 115))?.member, 2);
    expect(flightTapAt(taps, const Offset(95, 95))?.member, 1);
    expect(flightTapAt(taps, const Offset(200, 212))?.place, 'Japan');
    expect(flightTapAt(taps, const Offset(300, 300)), isNull);
  });
}
