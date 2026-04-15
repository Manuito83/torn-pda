import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';

/// Tests for [formatProfit] — compact money display for the travel screen.
///
/// Run with:  flutter test test/utils/profit_formatter_test.dart

void main() {
  group('formatProfit', () {
    test('billions', () {
      expect(formatProfit(inputInt: 1500000000), '1.5B');
      expect(formatProfit(inputInt: 2000000000), '2B');
    });

    test('millions', () {
      expect(formatProfit(inputInt: 5000000), '5M');
      expect(formatProfit(inputInt: 1500000), '1.5M');
    });

    test('hundred-thousands', () {
      expect(formatProfit(inputInt: 100000), '100K');
      expect(formatProfit(inputInt: 500000), '500K');
    });

    test('thousands', () {
      expect(formatProfit(inputInt: 5000), '5K');
      expect(formatProfit(inputInt: 1500), '1.5K');
    });

    test('small values stay as-is', () {
      expect(formatProfit(inputInt: 500), '500.0');
      expect(formatProfit(inputInt: 0), '0.0');
    });

    test('accepts double input', () {
      expect(formatProfit(inputDouble: 2500000.0), '2.5M');
    });

    test('negative values', () {
      expect(formatProfit(inputInt: -5000000), '-5M');
      expect(formatProfit(inputInt: -1500), '-1.5K');
    });
  });
}
