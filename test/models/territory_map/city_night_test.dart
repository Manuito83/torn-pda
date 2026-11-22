import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_night.dart';

import 'sample_data.dart';

void main() {
  test('night follows Torn time, not the phone time zone', () {
    final dusk = DateTime.utc(2026, 11, 10, 19, 30);
    expect(nightLevelAt(dusk.toLocal()), nightLevelAt(dusk));
    expect(nightLevelAt(dusk).dark, closeTo(0.5, 0.02));
    expect(nightLevelAt(DateTime.utc(2026, 11, 10, 12)), daylight);
    expect(nightLevelAt(DateTime.utc(2026, 11, 10, 23).toLocal()).dark, 1);
  });

  test('dusk and dawn fade in a few steps', () {
    expect(nightAt(6.5), closeTo(0.5, 0.001));
    expect(nightAt(4), 1);
    expect(lightsAt(2), lessThan(lightsAt(21)));
    final steps = {
      for (var s = 0; s < 3 * 3600; s += 10) nightLevelAt(DateTime.utc(2026, 11, 10, 18).add(Duration(seconds: s))),
    };
    expect(steps.length, lessThanOrEqualTo(51));
    expect(steps.length, greaterThan(20));
  });

  test('windows stay out of holes and grow with density', () {
    final sparse = cityWindows([courtyard()]);
    final dense = cityWindows([courtyard(density: 3)]);
    for (var i = 0; i < dense.points.length; i += 2) {
      final x = dense.points[i], y = dense.points[i + 1];
      expect(inCourtyardHole(x, y), isFalse);
      expect(x >= 0 && x <= 200 && y >= 0 && y <= 200, isTrue);
    }
    expect(dense.thresholds.length, greaterThan(sparse.thresholds.length));
    expect(dense.ranges['AAA'], (0, dense.thresholds.length));
  });
}
