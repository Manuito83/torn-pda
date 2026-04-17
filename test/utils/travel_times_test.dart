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
        26,
      );
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Japan',
          ticket: TravelTicket.standard,
        ),
        225,
      );
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'South Africa',
          ticket: TravelTicket.standard,
        ),
        297,
      );
    });

    test('business ticket is fastest', () {
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Japan',
          ticket: TravelTicket.business,
        ),
        68,
      );
      expect(
        TravelTimes.travelTimeMinutesOneWay(
          countryName: 'Mexico',
          ticket: TravelTicket.business,
        ),
        8,
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
        225,
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
}
