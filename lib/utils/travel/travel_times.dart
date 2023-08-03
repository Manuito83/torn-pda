// Project imports:
import 'package:torn_pda/models/travel/foreign_stock_in.dart';

enum TravelTicket {
  standard,
  private,
  wlt,
  business,
}

class TravelTimes {
  static CountryName getCountry({required String plainName}) {
    switch (plainName) {
      case "Torn":
        return CountryName.TORN;
      case "Argentina":
        return CountryName.ARGENTINA;
      case "Canada":
        return CountryName.CANADA;
      case "Cayman Islands":
        return CountryName.CAYMAN_ISLANDS;
      case "China":
        return CountryName.CHINA;
      case "Hawaii":
        return CountryName.HAWAII;
      case "Japan":
        return CountryName.JAPAN;
      case "Mexico":
        return CountryName.MEXICO;
      case "South Africa":
        return CountryName.SOUTH_AFRICA;
      case "Switzerland":
        return CountryName.SWITZERLAND;
      case "UAE":
        return CountryName.UAE;
      case "United Kingdom":
        return CountryName.UNITED_KINGDOM;
    }
    return CountryName.TORN;
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

    var travelTicket = ticket;

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

    switch (travelTicket!) {
      case TravelTicket.standard:
        tripJapan = 225;
        tripHawaii = 134;
        tripChina = 242;
        tripArgentina = 167;
        tripUK = 159;
        tripCayman = 35;
        tripSouthAfrica = 297;
        tripSwitzerland = 175;
        tripMexico = 26;
        tripUAE = 271;
        tripCanada = 41;
        break;
      case TravelTicket.private:
        tripJapan = 158;
        tripHawaii = 94;
        tripChina = 169;
        tripArgentina = 117;
        tripUK = 111;
        tripCayman = 25;
        tripSouthAfrica = 208;
        tripSwitzerland = 123;
        tripMexico = 18;
        tripUAE = 190;
        tripCanada = 29;
        break;
      case TravelTicket.wlt:
        tripJapan = 113;
        tripHawaii = 67;
        tripChina = 121;
        tripArgentina = 83;
        tripUK = 80;
        tripCayman = 18;
        tripSouthAfrica = 149;
        tripSwitzerland = 88;
        tripMexico = 13;
        tripUAE = 135;
        tripCanada = 20;
        break;
      case TravelTicket.business:
        tripJapan = 68;
        tripHawaii = 40;
        tripChina = 72;
        tripArgentina = 50;
        tripUK = 48;
        tripCayman = 11;
        tripSouthAfrica = 89;
        tripSwitzerland = 53;
        tripMexico = 8;
        tripUAE = 81;
        tripCanada = 12;
        break;
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
