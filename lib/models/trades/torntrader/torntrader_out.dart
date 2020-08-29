// To parse this JSON data, do
//
//     final tornTradesOut = tornTradesOutFromJson(jsonString);

import 'dart:convert';

TornTraderOutModel tornTradesOutFromJson(String str) => TornTraderOutModel.fromJson(json.decode(str));

String tornTradesOutToJson(TornTraderOutModel data) => json.encode(data.toJson());

class TornTraderOutModel {
  TornTraderOutModel({
    this.token,
    this.buyer,
    this.seller,
    this.tradeId,
    this.items,
    this.appVersion,
  });

  String token;
  int buyer;
  String seller;
  int tradeId;
  List<Item> items;
  String appVersion;

  factory TornTraderOutModel.fromJson(Map<String, dynamic> json) => TornTraderOutModel(
    token: json["token"] == null ? null : json["token"],
    buyer: json["buyer"] == null ? null : json["buyer"],
    seller: json["seller"] == null ? null : json["seller"],
    tradeId: json["trade_id"] == null ? null : json["trade_id"],
    items: json["items"] == null ? null : List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
    appVersion: json["app_version"] == null ? null : json["app_version"],
  );

  Map<String, dynamic> toJson() => {
    "token": token == null ? null : token,
    "buyer": buyer == null ? null : buyer,
    "seller": seller == null ? null : seller,
    "trade_id": tradeId == null ? null : tradeId,
    "items": items == null ? null : List<dynamic>.from(items.map((x) => x.toJson())),
    "app_version": appVersion == null ? null : appVersion,
  };
}

class Item {
  Item({
    this.name,
    this.quantity,
    this.id,
  });

  String name;
  int quantity;
  int id;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    name: json["name"] == null ? null : json["name"],
    quantity: json["quantity"] == null ? null : json["quantity"],
    id: json["id"] == null ? null : json["id"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "quantity": quantity == null ? null : quantity,
    "id": id == null ? null : id,
  };
}

