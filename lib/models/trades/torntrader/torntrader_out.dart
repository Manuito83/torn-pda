// To parse this JSON data, do
//
//     final tornTradesOut = tornTradesOutFromJson(jsonString);

// Dart imports:
import 'dart:convert';

TornTraderOutModel tornTraderOutFromJson(String str) => TornTraderOutModel.fromJson(json.decode(str));

String tornTraderOutToJson(TornTraderOutModel data) => json.encode(data.toJson());

class TornTraderOutModel {
  TornTraderOutModel({
    this.buyer,
    this.seller,
    this.tradeId,
    this.items,
    this.appVersion,
  });

  int? buyer;
  String? seller;
  int? tradeId;
  List<TtOutItem>? items;
  String? appVersion;

  factory TornTraderOutModel.fromJson(Map<String, dynamic> json) => TornTraderOutModel(
    buyer: json["buyer"],
    seller: json["seller"],
    tradeId: json["trade_id"],
    items: json["items"] == null ? null : List<TtOutItem>.from(json["items"].map((x) => TtOutItem.fromJson(x))),
    appVersion: json["app_version"],
  );

  Map<String, dynamic> toJson() => {
    "buyer": buyer,
    "seller": seller,
    "trade_id": tradeId,
    "items": items == null ? null : List<dynamic>.from(items!.map((x) => x.toJson())),
    "app_version": appVersion,
  };
}

class TtOutItem {
  TtOutItem({
    this.name,
    this.quantity,
    this.id,
  });

  String? name;
  int? quantity;
  int? id;

  factory TtOutItem.fromJson(Map<String, dynamic> json) => TtOutItem(
    name: json["name"],
    quantity: json["quantity"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "quantity": quantity,
    "id": id,
  };
}

