import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/number_formatter.dart';

/// Tests for [formatBigNumbers] — the K / M / B shorthand formatter.
///
/// Run with:  flutter test test/utils/number_formatter_test.dart

void main() {
  group('formatBigNumbers', () {
    test('billions', () {
      expect(formatBigNumbers(1500000000), '1.5B');
      expect(formatBigNumbers(2000000000), '2.0B');
    });

    test('millions', () {
      expect(formatBigNumbers(2500000), '2.5M');
      expect(formatBigNumbers(1000000), '1.0M');
    });

    test('thousands', () {
      expect(formatBigNumbers(5000), '5.0K');
      expect(formatBigNumbers(1500), '1.5K');
    });

    test('below thousand stays as-is', () {
      expect(formatBigNumbers(500), '500');
      expect(formatBigNumbers(0), '0');
    });

    test('negative billions', () {
      expect(formatBigNumbers(-1500000000), '-1.5B');
    });

    test('negative millions', () {
      expect(formatBigNumbers(-2500000), '-2.5M');
    });

    test('negative thousands', () {
      expect(formatBigNumbers(-5000), '-5.0K');
    });
  });
}
