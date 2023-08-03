// To parse this JSON data, do
//
//     final marketItemModel = marketItemModelFromJson(jsonString);

import 'dart:convert';

MarketItemModel marketItemModelFromJson(String str) => MarketItemModel.fromJson(json.decode(str));

String marketItemModelToJson(MarketItemModel data) => json.encode(data.toJson());

class MarketItemModel {
  MarketItemModel({
    this.bazaar,
    this.itemmarket,
  });

  List<Bazaar>? bazaar;
  List<Bazaar>? itemmarket;

  factory MarketItemModel.fromJson(Map<String, dynamic> json) => MarketItemModel(
        bazaar: json["bazaar"] == null ? null : List<Bazaar>.from(json["bazaar"].map((x) => Bazaar.fromJson(x))),
        itemmarket:
            json["itemmarket"] == null ? null : List<Bazaar>.from(json["itemmarket"].map((x) => Bazaar.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "bazaar": bazaar == null ? null : List<dynamic>.from(bazaar!.map((x) => x.toJson())),
        "itemmarket": itemmarket == null ? null : List<dynamic>.from(itemmarket!.map((x) => x.toJson())),
      };
}

class Bazaar {
  Bazaar({
    this.id,
    this.cost,
    this.quantity,
  });

  int? id;
  int? cost;
  int? quantity;

  factory Bazaar.fromJson(Map<String, dynamic> json) => Bazaar(
        id: json["ID"] == null ? null : json["ID"],
        cost: json["cost"] == null ? null : json["cost"],
        quantity: json["quantity"] == null ? null : json["quantity"],
      );

  Map<String, dynamic> toJson() => {
        "ID": id == null ? null : id,
        "cost": cost == null ? null : cost,
        "quantity": quantity == null ? null : quantity,
      };
}
