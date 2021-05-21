// To parse this JSON data, do
//
//     final stockMarketUserModel = stockMarketUserModelFromJson(jsonString);

import 'dart:convert';

StockMarketUserModel stockMarketUserModelFromJson(String str) => StockMarketUserModel.fromJson(json.decode(str));

String stockMarketUserModelToJson(StockMarketUserModel data) => json.encode(data.toJson());

class StockMarketUserModel {
  StockMarketUserModel({
    this.stocks,
  });

  Map<String, Stock> stocks;

  factory StockMarketUserModel.fromJson(Map<String, dynamic> json) => StockMarketUserModel(
    stocks: json["stocks"] == null ? null : Map.from(json["stocks"]).map((k, v) => MapEntry<String, Stock>(k, Stock.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "stocks": stocks == null ? null : Map.from(stocks).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class Stock {
  Stock({
    this.stockId,
    this.totalShares,
    this.transactions,
  });

  int stockId;
  int totalShares;
  Map<String, Transaction> transactions;

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    stockId: json["stock_id"] == null ? null : json["stock_id"],
    totalShares: json["total_shares"] == null ? null : json["total_shares"],
    transactions: json["transactions"] == null ? null : Map.from(json["transactions"]).map((k, v) => MapEntry<String, Transaction>(k, Transaction.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "stock_id": stockId == null ? null : stockId,
    "total_shares": totalShares == null ? null : totalShares,
    "transactions": transactions == null ? null : Map.from(transactions).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class Transaction {
  Transaction({
    this.shares,
    this.boughtPrice,
    this.timeBought,
  });

  int shares;
  double boughtPrice;
  int timeBought;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    shares: json["shares"] == null ? null : json["shares"],
    boughtPrice: json["bought_price"] == null ? null : json["bought_price"].toDouble(),
    timeBought: json["time_bought"] == null ? null : json["time_bought"],
  );

  Map<String, dynamic> toJson() => {
    "shares": shares == null ? null : shares,
    "bought_price": boughtPrice == null ? null : boughtPrice,
    "time_bought": timeBought == null ? null : timeBought,
  };
}
