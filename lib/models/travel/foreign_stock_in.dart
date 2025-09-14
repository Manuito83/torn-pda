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
