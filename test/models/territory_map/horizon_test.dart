import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';

void main() {
  const city = Rect.fromLTRB(-1, 0, 6256, 3410);
  const horizon = (flat: 1000.0, length: 6400.0);

  test('squeezes towards the horizon like the generator', () {
    // World point, map point, size, haze
    const table = [
      (Offset(3000, -1000), Offset(3000, -1000), 1.0, 0.0339),
      (Offset(3000, -2000), Offset(3000, -1925.8), 0.8553, 0.0993),
      (Offset(3000, -5000), Offset(3000, -3974.3), 0.5353, 0.3644),
      (Offset(3000, -20000), Offset(3000, -7071.2), 0.0514, 0.9845),
      (Offset(-4000, 1700), Offset(-3395.4, 1700), 0.6259, 0.2716),
      (Offset(9000, 6000), Offset(8619.9, 5641.2), 0.6483, 0.2509),
    ];
    for (final (world, map, size, hazeThere) in table) {
      final view = squeezed(world, city, horizon);
      expect(view.at.dx, closeTo(map.dx, 0.05), reason: '$world');
      expect(view.at.dy, closeTo(map.dy, 0.05), reason: '$world');
      expect(view.size, closeTo(size, 5e-5), reason: '$world');
      expect(haze(view.distance), closeTo(hazeThere, 5e-5), reason: '$world');
    }
  });
}
