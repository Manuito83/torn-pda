import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/surroundings_quality.dart';

void main() {
  test('phones get the step their memory allows', () {
    const gib = 1 << 30;
    // 3, 4, 6 and 12 GB phones
    expect(surroundingsQualityFor((2.7 * gib).round()), SurroundingsQuality.minimal);
    expect(surroundingsQualityFor((3.6 * gib).round()), SurroundingsQuality.light);
    expect(surroundingsQualityFor((5.4 * gib).round()), SurroundingsQuality.full);
    expect(surroundingsQualityFor((11.2 * gib).round()), SurroundingsQuality.full);
    expect(surroundingsQualityFor(null), SurroundingsQuality.light);
  });

  test('iPhones report their real memory', () {
    const gib = 1 << 30;
    expect(surroundingsQualityFor(2 * gib, exact: true), SurroundingsQuality.minimal);
    expect(surroundingsQualityFor(3 * gib, exact: true), SurroundingsQuality.light);
    expect(surroundingsQualityFor(4 * gib, exact: true), SurroundingsQuality.full);
  });
}
