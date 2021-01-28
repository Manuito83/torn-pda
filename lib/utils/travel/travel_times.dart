import 'package:torn_pda/models/travel/foreign_stock_in.dart';

enum TravelTicket {
  private,
}

class TravelTimes {

  static int travelTime(ForeignStock foreignStock) {
    // TODO: make global
    var _travelTicket = TravelTicket.private;

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

    switch (_travelTicket) {
      case TravelTicket.private:
        tripJapan = 158 * 60;
        tripHawaii = 94 * 60;
        tripChina = 169 * 60;
        tripArgentina = 117 * 60;
        tripUK = 111 * 60;
        tripCayman = 25 * 60;
        tripSouthAfrica = 208 * 60;
        tripSwitzerland = 123 * 60;
        tripMexico = 18 * 60;
        tripUAE = 190 * 60;
        tripCanada = 29 * 60;
        break;
    }

    switch (foreignStock.country) {
      case CountryName.ARGENTINA:
        return tripArgentina;
        break;
      case CountryName.CANADA:
        return tripCanada;
        break;
      case CountryName.CAYMAN_ISLANDS:
        return tripCayman;
        break;
      case CountryName.CHINA:
        return tripChina;
        break;
      case CountryName.HAWAII:
        return tripHawaii;
        break;
      case CountryName.JAPAN:
        return tripJapan;
        break;
      case CountryName.MEXICO:
        return tripMexico;
        break;
      case CountryName.SOUTH_AFRICA:
        return tripSouthAfrica;
        break;
      case CountryName.SWITZERLAND:
        return tripSwitzerland;
        break;
      case CountryName.UAE:
        return tripUAE;
        break;
      case CountryName.UNITED_KINGDOM:
        return tripUK;
        break;
    }

    return 0;
  }

}