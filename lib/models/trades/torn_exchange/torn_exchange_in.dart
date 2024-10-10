// To parse this JSON data, do
//
//     final tornExchangeInModel = tornExchangeInModelFromJson(jsonString);

import 'dart:convert';

TornExchangeInModel tornExchangeInModelFromJson(String str) => TornExchangeInModel.fromJson(json.decode(str));

String tornExchangeInModelToJson(TornExchangeInModel data) => json.encode(data.toJson());

class TornExchangeInModel {
  String sellerName;
  String buyerName;
  List<String> items;
  List<int> quantities;
  List<int> prices;
  List<int> profitPerItem;
  List<String> imageUrl;
  List<int> marketPrices;

  // Not in JSON
  bool serverError;
  String serverErrorReason;

  TornExchangeInModel({
    this.sellerName = "",
    this.buyerName = "",
    this.items = const [],
    this.quantities = const [],
    this.prices = const [],
    this.profitPerItem = const [],
    this.imageUrl = const [],
    this.marketPrices = const [],
    this.serverError = false,
    this.serverErrorReason = "",
  });

  factory TornExchangeInModel.fromJson(Map<String, dynamic> json) => TornExchangeInModel(
        sellerName: json["seller_name"],
        buyerName: json["buyer_name"],
        items: List<String>.from(json["items"].map((x) => x)),
        quantities: List<int>.from(json["quantities"].map((x) => x)),
        prices: List<int>.from(json["prices"].map((x) => x)),
        profitPerItem: List<int>.from(json["profit_per_item"].map((x) => x)),
        imageUrl: List<String>.from(json["image_url"].map((x) => x)),
        marketPrices: List<int>.from(json["market_prices"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "seller_name": sellerName,
        "buyer_name": buyerName,
        "items": List<dynamic>.from(items.map((x) => x)),
        "quantities": List<dynamic>.from(quantities.map((x) => x)),
        "prices": List<dynamic>.from(prices.map((x) => x)),
        "profit_per_item": List<dynamic>.from(profitPerItem.map((x) => x)),
        "image_url": List<dynamic>.from(imageUrl.map((x) => x)),
        "market_prices": List<dynamic>.from(marketPrices.map((x) => x)),
      };
}
