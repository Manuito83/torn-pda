// To parse this JSON data, do
//
//     final tornExchangeReceiptOutModel = tornExchangeReceiptOutModelFromJson(jsonString);

import 'dart:convert';

TornExchangeReceiptOutModel tornExchangeReceiptOutModelFromJson(String str) =>
    TornExchangeReceiptOutModel.fromJson(json.decode(str));

String tornExchangeReceiptOutModelToJson(TornExchangeReceiptOutModel data) => json.encode(data.toJson());

class TornExchangeReceiptOutModel {
  String ownerUsername;
  int ownerUserId;
  String sellerUsername;
  List<int> prices;
  List<int> itemQuantities;
  List<String> itemNames;

  TornExchangeReceiptOutModel({
    required this.ownerUsername,
    required this.ownerUserId,
    required this.sellerUsername,
    required this.prices,
    required this.itemQuantities,
    required this.itemNames,
  });

  factory TornExchangeReceiptOutModel.fromJson(Map<String, dynamic> json) => TornExchangeReceiptOutModel(
        ownerUsername: json["owner_username"],
        ownerUserId: json["owner_user_id"],
        sellerUsername: json["seller_username"],
        prices: List<int>.from(json["prices"].map((x) => x)),
        itemQuantities: List<int>.from(json["item_quantities"].map((x) => x)),
        itemNames: List<String>.from(json["item_names"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "owner_username": ownerUsername,
        "owner_user_id": ownerUserId,
        "seller_username": sellerUsername,
        "prices": List<dynamic>.from(prices.map((x) => x)),
        "item_quantities": List<dynamic>.from(itemQuantities.map((x) => x)),
        "item_names": List<dynamic>.from(itemNames.map((x) => x)),
      };
}

// To parse this JSON data, do
//
//     final tornExchangeReceiptInModel = tornExchangeReceiptInModelFromJson(jsonString);

TornExchangeReceiptInModel tornExchangeReceiptInModelFromJson(String str) =>
    TornExchangeReceiptInModel.fromJson(json.decode(str));

String tornExchangeReceiptInModelToJson(TornExchangeReceiptInModel data) => json.encode(data.toJson());

class TornExchangeReceiptInModel {
  String receiptId;
  String tradeMessage;
  int profit;
  int total;
  // Error handling
  bool serverError = false;

  TornExchangeReceiptInModel({
    this.receiptId = "",
    this.tradeMessage = "",
    this.profit = 0,
    this.total = 0,
  });

  factory TornExchangeReceiptInModel.fromJson(Map<String, dynamic> json) => TornExchangeReceiptInModel(
        receiptId: json["receipt_id"],
        tradeMessage: json["trade_message"],
        profit: json["profit"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "receipt_id": receiptId,
        "trade_message": tradeMessage,
        "profit": profit,
        "total": total,
      };
}
