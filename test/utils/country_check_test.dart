import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/country_check.dart';

/// Tests for [countryCheck] and [isTraveling] — player location helpers.
///
/// Run with:  flutter test test/utils/country_check_test.dart

void main() {
  // -------------------------------------------------------------------------
  // countryCheck
  // -------------------------------------------------------------------------
  group('countryCheck', () {
    test('Abroad → extracts country from "In <country>"', () {
      expect(
        countryCheck(state: 'Abroad', description: 'In Argentina'),
        'Argentina',
      );
      expect(
        countryCheck(state: 'Abroad', description: 'In Japan'),
        'Japan',
      );
    });

    test('Traveling → extracts destination', () {
      expect(
        countryCheck(state: 'Traveling', description: 'Traveling to Mexico'),
        'Mexico',
      );
    });

    test('Traveling → returning to Torn', () {
      expect(
        countryCheck(state: 'Traveling', description: 'Returning to Torn from Japan'),
        'Torn',
      );
    });

    test('Hospital abroad → maps adjective to country', () {
      final cases = {
        'In a Swiss hospital': 'Switzerland',
        'In an Emirati hospital': 'UAE',
        'In a British hospital': 'United Kingdom',
        'In a Chinese hospital': 'China',
        'In a South African hospital': 'South Africa',
        'In an Argentinian hospital': 'Argentina',
        'In a Caymanian hospital': 'Cayman Islands',
        'In a Canadian hospital': 'Canada',
        'In a Mexican hospital': 'Mexico',
        'In a Japanese hospital': 'Japan',
        'In a Hawaiian hospital': 'Hawaii',
      };

      for (final entry in cases.entries) {
        expect(
          countryCheck(state: 'Hospital', description: entry.key),
          entry.value,
          reason: 'description: ${entry.key}',
        );
      }
    });

    test('Hospital in Torn', () {
      expect(
        countryCheck(state: 'Hospital', description: 'In a local hospital for 2 hours'),
        'Torn',
      );
    });

    test('other states default to Torn', () {
      expect(countryCheck(state: 'Okay', description: ''), 'Torn');
      expect(countryCheck(state: 'Idle', description: ''), 'Torn');
    });
  });

  // -------------------------------------------------------------------------
  // isTraveling
  // -------------------------------------------------------------------------
  group('isTraveling', () {
    test('returns true when state is Traveling', () {
      expect(isTraveling(state: 'Traveling'), isTrue);
    });

    test('returns false for other states', () {
      expect(isTraveling(state: 'Abroad'), isFalse);
      expect(isTraveling(state: 'Okay'), isFalse);
      expect(isTraveling(state: 'Hospital'), isFalse);
    });

    test('returns false for null', () {
      expect(isTraveling(state: null), isFalse);
    });
  });
}
