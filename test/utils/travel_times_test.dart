import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/travel/foreign_stock_in.dart';
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
    test('standard ticket — spot-check known values', () {
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Mexico',
          ticket: TravelTicket.standard,
        ),
        24,
      );
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Japan',
          ticket: TravelTicket.standard,
        ),
        213,
      );
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'South Africa',
          ticket: TravelTicket.standard,
        ),
        282,
      );
    });

    test('business ticket is fastest', () {
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Japan',
          ticket: TravelTicket.business,
        ),
        64,
      );
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Mexico',
          ticket: TravelTicket.business,
        ),
        7,
      );
    });

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

    test('WLT is between private and standard', () {
      final std = TravelTimes.travelTimeMinutesOneWay(
        countryName: 'Japan',
        ticket: TravelTicket.standard,
      );
      final wlt = TravelTimes.travelTimeMinutesOneWay(
        countryName: 'Japan',
        ticket: TravelTicket.wlt,
      );
      final prv = TravelTimes.travelTimeMinutesOneWay(
        countryName: 'Japan',
        ticket: TravelTicket.private,
      );

      expect(wlt, lessThan(prv));
      expect(prv, lessThan(std));
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
}
