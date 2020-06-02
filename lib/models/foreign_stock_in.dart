// To parse this JSON data, do
//
//     final foreingStockInModel = foreingStockInModelFromJson(jsonString);

import 'dart:convert';

ForeignStockInModel foreignStockInModelFromJson(String str) => ForeignStockInModel.fromJson(json.decode(str));

String foreignStockInModelToJson(ForeignStockInModel data) => json.encode(data.toJson());

class ForeignStockInModel {
  List<Stock> stocks;

  ForeignStockInModel({
    this.stocks,
  });

  factory ForeignStockInModel.fromJson(Map<String, dynamic> json) => ForeignStockInModel(
    stocks: json["stocks"] == null ? null : List<Stock>.from(json["stocks"].map((x) => Stock.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "stocks": stocks == null ? null : List<dynamic>.from(stocks.map((x) => x.toJson())),
  };
}

class Stock {
  // External, but NOT exported to Shared Preferences!
  int value = 0;
  int profit = 0;

  CountryName countryName;
  int itemId;
  String itemName;
  String itemType;
  int abroadCost;
  int abroadQuantity;
  int timestamp;

  Stock({
    this.countryName,
    this.itemId,
    this.itemName,
    this.itemType,
    this.abroadCost,
    this.abroadQuantity,
    this.timestamp,
  });

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    countryName: json["country_name"] == null ? null : countryNameValues.map[json["country_name"]],
    itemId: json["item_id"] == null ? null : json["item_id"],
    itemName: json["item_name"] == null ? null : json["item_name"],
    itemType: json["item_type"] == null ? null : json["item_type"],
    abroadCost: json["abroad_cost"] == null ? null : json["abroad_cost"],
    abroadQuantity: json["abroad_quantity"] == null ? null : json["abroad_quantity"],
    timestamp: json["timestamp"] == null ? null : json["timestamp"],
  );

  Map<String, dynamic> toJson() => {
    "country_name": countryName == null ? null : countryNameValues.reverse[countryName],
    "item_id": itemId == null ? null : itemId,
    "item_name": itemName == null ? null : itemName,
    "item_type": itemType == null ? null : itemType,
    "abroad_cost": abroadCost == null ? null : abroadCost,
    "abroad_quantity": abroadQuantity == null ? null : abroadQuantity,
    "timestamp": timestamp == null ? null : timestamp,
  };
}

enum CountryName { ARGENTINA, CANADA, CAYMAN_ISLANDS, CHINA, HAWAII, JAPAN, MEXICO, SOUTH_AFRICA, SWITZERLAND, UAE, UNITED_KINGDOM }

final countryNameValues = EnumValues({
  "Argentina": CountryName.ARGENTINA,
  "Canada": CountryName.CANADA,
  "Cayman Islands": CountryName.CAYMAN_ISLANDS,
  "China": CountryName.CHINA,
  "Hawaii": CountryName.HAWAII,
  "Japan": CountryName.JAPAN,
  "Mexico": CountryName.MEXICO,
  "South Africa": CountryName.SOUTH_AFRICA,
  "Switzerland": CountryName.SWITZERLAND,
  "UAE": CountryName.UAE,
  "United Kingdom": CountryName.UNITED_KINGDOM
});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}
