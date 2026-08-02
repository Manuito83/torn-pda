// Project imports:
import 'package:torn_pda/models/travel/foreign_stock_in.dart';

enum TravelTicket { standard, private, wlt, business }

class TravelTimes {
  static const Map<CountryName, String> _apiNames = {
    CountryName.ARGENTINA: 'Argentina',
    CountryName.CANADA: 'Canada',
    CountryName.CAYMAN_ISLANDS: 'Cayman Islands',
    CountryName.CHINA: 'China',
    CountryName.HAWAII: 'Hawaii',
    CountryName.JAPAN: 'Japan',
    CountryName.MEXICO: 'Mexico',
    CountryName.SOUTH_AFRICA: 'South Africa',
    CountryName.SWITZERLAND: 'Switzerland',
    CountryName.UAE: 'UAE',
    CountryName.UNITED_KINGDOM: 'United Kingdom',
  };

  static TravelTicket? ticketFromApiMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'standard':
        return TravelTicket.standard;
      case 'airstrip':
        return TravelTicket.private;
      case 'private':
        return TravelTicket.wlt;
      case 'business':
        return TravelTicket.business;
    }
    return null;
  }

  static String? inferOriginCountry({required int durationSeconds, required String? apiMethod}) {
    final ticket = ticketFromApiMethod(apiMethod);
    if (ticket == null || durationSeconds <= 0) return null;

    String? match;
    for (final entry in _apiNames.entries) {
      final expected = travelTimeMinutesOneWay(countryCode: entry.key, ticket: ticket) * 60;
      if (expected <= 0) continue;
      final band = expected * 0.03 + 60;
      if ((durationSeconds - expected).abs() <= band) {
        if (match != null) return null;
        match = entry.value;
      }
    }
    return match;
  }

  /// Converts a plain country name to CountryName enum.
  /// Delegates to CountryHelper for centralized mapping.
  static CountryName getCountry({required String plainName}) {
    return CountryHelper.fromName(plainName);
  }

  /// Provide either a capitalized ("Argentina") name for [countryName] or a CountryName for [code]
  static int travelTimeMinutesOneWay({
    String countryName = "",
    CountryName? countryCode = CountryName.TORN,
    required TravelTicket? ticket,
  }) {
    CountryName? code = countryCode;

    if (countryName.isNotEmpty) {
      code = getCountry(plainName: countryName);
    }

    final travelTicket = ticket;

    int tripJapan = 0;
    int tripHawaii = 0;
    int tripChina = 0;
    int tripArgentina = 0;
    int tripUK = 0;
    int tripCayman = 0;
    int tripSouthAfrica = 0;
    int tripSwitzerland = 0;
    int tripMexico = 0;
    int tripUAE = 0;
    int tripCanada = 0;

    // Times from the Torn wiki, last checked after patch #438
    switch (travelTicket!) {
      case TravelTicket.standard:
        tripJapan = 213;
        tripHawaii = 127;
        tripChina = 229;
        tripArgentina = 158;
        tripUK = 151;
        tripCayman = 33;
        tripSouthAfrica = 282;
        tripSwitzerland = 166;
        tripMexico = 24;
        tripUAE = 257;
        tripCanada = 39;
      case TravelTicket.private:
        tripJapan = 149;
        tripHawaii = 89;
        tripChina = 160;
        tripArgentina = 111;
        tripUK = 106;
        tripCayman = 23;
        tripSouthAfrica = 197;
        tripSwitzerland = 116;
        tripMexico = 17;
        tripUAE = 180;
        tripCanada = 27;
      case TravelTicket.wlt:
        tripJapan = 107;
        tripHawaii = 63;
        tripChina = 114;
        tripArgentina = 79;
        tripUK = 75;
        tripCayman = 17;
        tripSouthAfrica = 141;
        tripSwitzerland = 83;
        tripMexico = 12;
        tripUAE = 128;
        tripCanada = 19;
      case TravelTicket.business:
        tripJapan = 64;
        tripHawaii = 38;
        tripChina = 69;
        tripArgentina = 47;
        tripUK = 45;
        tripCayman = 10;
        tripSouthAfrica = 85;
        tripSwitzerland = 50;
        tripMexico = 7;
        tripUAE = 77;
        tripCanada = 12;
    }

    switch (code!) {
      case CountryName.ARGENTINA:
        return tripArgentina;
      case CountryName.CANADA:
        return tripCanada;
      case CountryName.CAYMAN_ISLANDS:
        return tripCayman;
      case CountryName.CHINA:
        return tripChina;
      case CountryName.HAWAII:
        return tripHawaii;
      case CountryName.JAPAN:
        return tripJapan;
      case CountryName.MEXICO:
        return tripMexico;
      case CountryName.SOUTH_AFRICA:
        return tripSouthAfrica;
      case CountryName.SWITZERLAND:
        return tripSwitzerland;
      case CountryName.UAE:
        return tripUAE;
      case CountryName.UNITED_KINGDOM:
        return tripUK;
      case CountryName.TORN:
        // no travel time
        break;
    }

    return 0;
  }
}
