// To parse this JSON data, do
//
//     final foreignStockInModel = foreignStockInModelFromJson(jsonString);

import 'dart:convert';

import 'package:torn_pda/models/items_model.dart';

ForeignStockInModel foreignStockInModelFromJson(String str) =>
    ForeignStockInModel.fromJson(json.decode(str));

String foreignStockInModelToJson(ForeignStockInModel data) => json.encode(data.toJson());

class ForeignStockInModel {
  ForeignStockInModel({
    this.countries,
    this.timestamp,
  });

  Map<String, CountryDetails> countries;
  int timestamp;

  factory ForeignStockInModel.fromJson(Map<String, dynamic> json) => ForeignStockInModel(
        countries: json["stocks"] == null
            ? null
            : Map.from(json["stocks"])
                .map((k, v) => MapEntry<String, CountryDetails>(k, CountryDetails.fromJson(v))),
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "stocks": countries == null
            ? null
            : Map.from(countries).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "timestamp": timestamp == null ? null : timestamp,
      };
}

class CountryDetails {
  CountryDetails({
    this.update,
    this.stocks,
  });

  int update;
  List<ForeignStock> stocks;

  factory CountryDetails.fromJson(Map<String, dynamic> json) => CountryDetails(
        update: json["update"] == null ? null : json["update"],
        stocks: json["stocks"] == null
            ? null
            : List<ForeignStock>.from(json["stocks"].map((x) => ForeignStock.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "update": update == null ? null : update,
        "stocks": stocks == null ? null : List<dynamic>.from(stocks.map((x) => x.toJson())),
      };
}

class ForeignStock {
  ForeignStock({
    this.id,
    this.name,
    this.quantity,
    this.cost,
  });

  // NOT INCLUDED WITH YATA IMPORT
  // Calculated, NOT exported to Shared Preferences!
  CountryName country;
  int timestamp;
  ItemType itemType;
  int value = 0;
  int profit = 0;

  int id;
  String name;
  int quantity;
  int cost;

  factory ForeignStock.fromJson(Map<String, dynamic> json) => ForeignStock(
        id: json["id"] == null ? null : json["id"],
        name: json["name"] == null ? null : json["name"],
        quantity: json["quantity"] == null ? null : json["quantity"],
        cost: json["cost"] == null ? null : json["cost"],
      );

  Map<String, dynamic> toJson() => {
        "id": id == null ? null : id,
        "name": name == null ? null : name,
        "quantity": quantity == null ? null : quantity,
        "cost": cost == null ? null : cost,
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
}
