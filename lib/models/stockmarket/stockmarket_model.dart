// To parse this JSON data, do
//
//     final stockMarketModel = stockMarketModelFromJson(jsonString);

import 'dart:convert';

StockMarketModel stockMarketModelFromJson(String str) => StockMarketModel.fromJson(json.decode(str));

String stockMarketModelToJson(StockMarketModel data) => json.encode(data.toJson());

class StockMarketModel {
  StockMarketModel({
    this.stocks,
  });

  Map<String, StockMarketStock>? stocks;

  factory StockMarketModel.fromJson(Map<String, dynamic> json) => StockMarketModel(
    stocks: json["stocks"] == null ? null : Map.from(json["stocks"]).map((k, v) => MapEntry<String, StockMarketStock>(k, StockMarketStock.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "stocks": stocks == null ? null : Map.from(stocks!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class StockMarketStock {
  StockMarketStock({
    this.stockId,
    this.name,
    this.acronym,
    this.currentPrice,
    this.marketCap,
    this.totalShares,
    this.benefit,
  });

  // State
  int owned = 0;
  double? alertGain;
  double? alertLoss;
  late double gain;
  late double percentageGain;
  int? sharesOwned;

  int? stockId;
  String? name;
  String? acronym;
  double? currentPrice;
  int? marketCap;
  int? totalShares;
  Benefit? benefit;

  factory StockMarketStock.fromJson(Map<String, dynamic> json) => StockMarketStock(
    stockId: json["stock_id"],
    name: json["name"],
    acronym: json["acronym"],
    currentPrice: json["current_price"] == null ? null : json["current_price"].toDouble(),
    marketCap: json["market_cap"],
    totalShares: json["total_shares"],
    benefit: json["benefit"] == null ? null : Benefit.fromJson(json["benefit"]),
  );

  Map<String, dynamic> toJson() => {
    "stock_id": stockId,
    "name": name,
    "acronym": acronym,
    "current_price": currentPrice,
    "market_cap": marketCap,
    "total_shares": totalShares,
    "benefit": benefit == null ? null : benefit!.toJson(),
  };
}

class Benefit {
  Benefit({
    this.frequency,
    this.requirement,
    this.description,
  });

  int? frequency;
  int? requirement;
  String? description;

  factory Benefit.fromJson(Map<String, dynamic> json) => Benefit(
    frequency: json["frequency"],
    requirement: json["requirement"],
    description: json["description"],
  );

  Map<String, dynamic> toJson() => {
    "frequency": frequency,
    "requirement": requirement,
    "description": description,
  };
}
