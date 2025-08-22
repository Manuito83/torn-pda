// To parse this JSON data, do
//
//     final tornExchangeOutModel = tornExchangeOutModelFromJson(jsonString);

import 'dart:convert';

TornExchangeOutModel tornExchangeOutModelFromJson(String str) => TornExchangeOutModel.fromJson(json.decode(str));

String tornExchangeOutModelToJson(TornExchangeOutModel data) => json.encode(data.toJson());

class TornExchangeOutModel {
  List<String> items;
  List<int> quantities;
  String userName;
  String sellerName;
  String tradeId;

  TornExchangeOutModel({
    required this.items,
    required this.quantities,
    required this.userName,
    required this.sellerName,
    required this.tradeId,
  });

  factory TornExchangeOutModel.fromJson(Map<String, dynamic> json) => TornExchangeOutModel(
        items: List<String>.from(json["items"].map((x) => x)),
        quantities: List<int>.from(json["quantities"].map((x) => x)),
        userName: json["user_name"],
        sellerName: json["seller_name"],
        tradeId: json["trade_id"],
      );

  Map<String, dynamic> toJson() => {
        "items": List<dynamic>.from(items.map((x) => x)),
        "quantities": List<dynamic>.from(quantities.map((x) => x)),
        "user_name": userName,
        "seller_name": sellerName,
        "trade_id": tradeId,
      };
}
