// To parse this JSON data, do
//
//     final foreignStockInModel = foreignStockInModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

// Project imports:
import 'package:torn_pda/models/items_model.dart';

ForeignStockInModel foreignStockInModelFromJson(String str) => ForeignStockInModel.fromJson(json.decode(str));

String foreignStockInModelToJson(ForeignStockInModel data) => json.encode(data.toJson());

class ForeignStockInModel {
  ForeignStockInModel({
    this.countries,
    this.timestamp,
  });

  Map<String, CountryDetails>? countries;
  int? timestamp;

  factory ForeignStockInModel.fromJson(Map<String, dynamic> json) => ForeignStockInModel(
        countries: json["stocks"] == null
            ? null
            : Map.from(json["stocks"]).map((k, v) => MapEntry<String, CountryDetails>(k, CountryDetails.fromJson(v))),
        timestamp: json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "stocks":
            countries == null ? null : Map.from(countries!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "timestamp": timestamp,
      };
}

class CountryDetails {
  CountryDetails({
    this.update,
    this.stocks,
  });

  int? update;
  List<ForeignStock>? stocks;

  factory CountryDetails.fromJson(Map<String, dynamic> json) => CountryDetails(
        update: json["update"],
        stocks: json["stocks"] == null
            ? null
            : List<ForeignStock>.from(json["stocks"].map((x) => ForeignStock.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "update": update,
        "stocks": stocks == null ? null : List<dynamic>.from(stocks!.map((x) => x.toJson())),
      };
}

ForeignStock foreignStockFromJson(String str) => ForeignStock.fromJson(json.decode(str));
String foreignStockToJson(ForeignStock data) => json.encode(data.toJson());

class ForeignStock {
  ForeignStock({
    this.countryFullName,
    this.id,
    this.name,
    this.quantity,
    this.cost,
    this.countryCode,
  });

  // NOT INCLUDED WITH YATA IMPORT
  // Calculated, NOT exported to Shared Preferences!
  CountryName? country;
  String? countryCode;
  String? countryFullName;
  late DateTime arrivalTime;
  int? timestamp;
  ItemType? itemType;
  int value = 0;
  int profit = 0;
  int? inventoryQuantity = 0;

  int? id;
  String? name;
  int? quantity;
  int? cost;
  String? codeName;

  factory ForeignStock.fromJson(Map<String, dynamic> json) => ForeignStock(
        id: json["id"],
        name: json["name"],
        quantity: json["quantity"],
        cost: json["cost"],
        countryCode: json["countryCode"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "quantity": quantity,
        "cost": cost,
        "countryCode": countryCode,
      };
}

enum CountryName {
  ARGENTINA,
  CANADA,
  CAYMAN_ISLANDS,
  CHINA,
  HAWAII,
  JAPAN,
  MEXICO,
  SOUTH_AFRICA,
  SWITZERLAND,
  UAE,
  UNITED_KINGDOM,
  TORN,
}

/// Centralized country mapping utilities
/// Consolidates all country code/name conversions in one place
class CountryHelper {
  /// 3-letter API code to CountryName enum
  static const Map<String, CountryName> codeToCountry = {
    'arg': CountryName.ARGENTINA,
    'can': CountryName.CANADA,
    'cay': CountryName.CAYMAN_ISLANDS,
    'chi': CountryName.CHINA,
    'haw': CountryName.HAWAII,
    'jap': CountryName.JAPAN,
    'mex': CountryName.MEXICO,
    'sou': CountryName.SOUTH_AFRICA,
    'swi': CountryName.SWITZERLAND,
    'uae': CountryName.UAE,
    'uni': CountryName.UNITED_KINGDOM,
  };

  /// CountryName enum to full display name
  static const Map<CountryName, String> countryToFullName = {
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
    CountryName.UNITED_KINGDOM: 'UK',
    CountryName.TORN: 'Torn',
  };

  /// Full/plain name to CountryName enum
  static const Map<String, CountryName> nameToCountry = {
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
    'UK': CountryName.UNITED_KINGDOM,
    'Torn': CountryName.TORN,
  };

  /// Full name to 3-letter API code (for Firebase cache conversion)
  static const Map<String, String> nameToCode = {
    'Argentina': 'arg',
    'Canada': 'can',
    'Cayman Islands': 'cay',
    'China': 'chi',
    'Hawaii': 'haw',
    'Japan': 'jap',
    'Mexico': 'mex',
    'South Africa': 'sou',
    'Switzerland': 'swi',
    'UAE': 'uae',
    'UK': 'uni',
    'United Kingdom': 'uni',
  };

  /// Get CountryName from 3-letter code, returns null if not found
  static CountryName? fromCode(String? code) {
    if (code == null) return null;
    return codeToCountry[code.toLowerCase()];
  }

  /// Get CountryName from plain/full name, returns TORN if not found
  static CountryName fromName(String? name) {
    if (name == null) return CountryName.TORN;
    return nameToCountry[name] ?? CountryName.TORN;
  }

  /// Get full display name from CountryName
  static String getFullName(CountryName? country) {
    if (country == null) return 'Unknown';
    return countryToFullName[country] ?? 'Unknown';
  }

  /// Get 3-letter code from full name
  static String? getCodeFromName(String? name) {
    if (name == null) return null;
    return nameToCode[name];
  }
}
