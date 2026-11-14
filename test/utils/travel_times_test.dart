import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/travel/foreign_stock_in.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';

/// Tests for [TravelTimes] — country lookup and travel duration tables.
///
/// Run with:  flutter test test/utils/travel_times_test.dart

void main() {
  // -------------------------------------------------------------------------
  // getCountry
  // -------------------------------------------------------------------------
  group('getCountry', () {
    test('maps every known country name to its enum', () {
      final mapping = {
        'Argentina': CountryName.ARGENTINA,
        'Canada': CountryName.CANADA,
        'Cayman Islands': CountryName.CAYMAN_ISLANDS,
        'China': CountryName.CHINA,
        'Hawaii': CountryName.HAWAII,
        'Japan': CountryName.JAPAN,
        'Mexico': CountryName.MEXICO,
        'South Africa': CountryName.SOUTH_AFRICA,
        'Switzerland': CountryName.SWITZERLAND,
        'UAE': CountryName.UAE,
        'United Kingdom': CountryName.UNITED_KINGDOM,
        'Torn': CountryName.TORN,
      };

      for (final entry in mapping.entries) {
        expect(
          TravelTimes.getCountry(plainName: entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('unknown name defaults to Torn', () {
      expect(TravelTimes.getCountry(plainName: 'Narnia'), CountryName.TORN);
    });
  });

  // -------------------------------------------------------------------------
  // travelTimeMinutesOneWay
  // -------------------------------------------------------------------------
  group('travelTimeMinutesOneWay', () {
    test('Torn returns 0 for any ticket', () {
      for (final ticket in TravelTicket.values) {
        expect(
          TravelTimes.travelTimeMinutesOneWay(
            countryCode: CountryName.TORN,
            ticket: ticket,
          ),
          0,
          reason: 'ticket: $ticket',
        );
      }
    });

    test('countryName takes precedence over countryCode', () {
      // Pass Japan by name but Torn by code — name should win.
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Japan',
          countryCode: CountryName.TORN,
          ticket: TravelTicket.standard,
        ),
        213,
      );
    });
  });

  // -------------------------------------------------------------------------
  // ticketFromApiMethod
  // -------------------------------------------------------------------------
  group('ticketFromApiMethod', () {
    test('maps the API names, where Airstrip and Private are the traps', () {
      expect(TravelTimes.ticketFromApiMethod('Standard'), TravelTicket.standard);
      expect(TravelTimes.ticketFromApiMethod('Airstrip'), TravelTicket.private);
      expect(TravelTimes.ticketFromApiMethod('Private'), TravelTicket.wlt);
      expect(TravelTimes.ticketFromApiMethod('Business'), TravelTicket.business);
    });

    test('unknown or missing method maps to nothing', () {
      expect(TravelTimes.ticketFromApiMethod('Broomstick'), isNull);
      expect(TravelTimes.ticketFromApiMethod(null), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // inferOriginCountry
  // -------------------------------------------------------------------------
  group('inferOriginCountry', () {
    int minutes(int m) => m * 60;

    test('an unambiguous duration names its country', () {
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: minutes(213), apiMethod: 'Standard'),
        'Japan',
      );
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: minutes(106), apiMethod: 'Airstrip'),
        'United Kingdom',
      );
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: minutes(257), apiMethod: 'Standard'),
        'UAE',
      );
    });

    test('the 3% variance is tolerated', () {
      final varied = (minutes(213) * 1.025).round();
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: varied, apiMethod: 'Standard'),
        'Japan',
      );
    });

    test('the UK-Argentina overlap window stays anonymous', () {
      // 155.5 min sits inside both standard bands
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: 9330, apiMethod: 'Standard'),
        isNull,
      );
    });

    test('a book-shortened flight matches nothing', () {
      // UK standard with the -25% book: 113.25 min
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: 6795, apiMethod: 'Standard'),
        isNull,
      );
    });

    test('a book-shortened flight matches once the reduction is known', () {
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: 6795, apiMethod: 'Standard', reductionPercent: 25),
        'United Kingdom',
      );
    });

    test('unknown method or bad duration stays anonymous', () {
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: minutes(213), apiMethod: null),
        isNull,
      );
      expect(
        TravelTimes.inferOriginCountry(durationSeconds: 0, apiMethod: 'Standard'),
        isNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  // travel time reduction
  // -------------------------------------------------------------------------
  group('travel time reduction', () {
    test('parseReduction sums matching perks and ignores the rest', () {
      expect(
        TravelTimes.parseReduction([
          '+ 25% travel time reduction',
          '+ 10.5% Travel Time Reduction',
          '+ 10% gym gains',
        ]),
        35.5,
      );
      expect(TravelTimes.parseReduction(['+ 10% gym gains']), 0);
    });

    test('a 25% reduction shortens the table time', () {
      int minutes(String country, TravelTicket ticket) =>
          TravelTimes.travelTimeMinutesOneWay(countryName: country, ticket: ticket, reductionPercent: 25);
      expect(minutes('Argentina', TravelTicket.standard), 119);
      expect(minutes('Japan', TravelTicket.private), 112);
      expect(minutes('Torn', TravelTicket.standard), 0);
    });

    test('the profile call hands the perk reduction to the caller', () {
      final withPerks = ApiCallsV2.parseProfileMisc({
        'perks': {
          'education_perks': ['+ 25% travel time reduction'],
          'job_perks': ['+ 10% gym gains'],
        },
      });
      expect(withPerks!.travelTimeReduction, 25);
      expect(ApiCallsV2.parseProfileMisc({})!.travelTimeReduction, isNull);
    });
  });
}
