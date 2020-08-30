// To parse this JSON data, do
//
//     final tornTraderInModel = tornTraderInModelFromJson(jsonString);

import 'dart:convert';

TornTraderInModel tornTraderInModelFromJson(String str) => TornTraderInModel.fromJson(json.decode(str));

String tornTraderInModelToJson(TornTraderInModel data) => json.encode(data.toJson());

class TornTraderInModel {
  TornTraderInModel({
    // State
    this.serverError = false,
    this.authError = false,

    this.trade,
  });

  // State
  bool serverError;
  bool authError;

  Trade trade;

  factory TornTraderInModel.fromJson(Map<String, dynamic> json) => TornTraderInModel(
    trade: json["trade"] == null ? null : Trade.fromJson(json["trade"]),
  );

  Map<String, dynamic> toJson() => {
    "trade": trade == null ? null : trade.toJson(),
  };
}

class Trade {
  Trade({
    this.tradeUrl,
    this.tradeTotal,
    this.items,
    this.tradeMessages,
    this.totalProfit,
  });

  String tradeUrl;
  String tradeTotal;
  List<ttInItem> items;
  List<TradeMessage> tradeMessages;
  String totalProfit;

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
    tradeUrl: json["trade_url"] == null ? null : json["trade_url"],
    tradeTotal: json["trade_total"] == null ? null : json["trade_total"],
    items: json["items"] == null ? null : List<ttInItem>.from(json["items"].map((x) => ttInItem.fromJson(x))),
    tradeMessages: json["trade_messages"] == null ? null : List<TradeMessage>.from(json["trade_messages"].map((x) => TradeMessage.fromJson(x))),
    totalProfit: json["total_profit"] == null ? null : json["total_profit"],
  );

  Map<String, dynamic> toJson() => {
    "trade_url": tradeUrl == null ? null : tradeUrl,
    "trade_total": tradeTotal == null ? null : tradeTotal,
    "items": items == null ? null : List<dynamic>.from(items.map((x) => x.toJson())),
    "trade_messages": tradeMessages == null ? null : List<dynamic>.from(tradeMessages.map((x) => x.toJson())),
    "total_profit": totalProfit == null ? null : totalProfit,
  };
}

class ttInItem {
  ttInItem({
    this.name,
    this.id,
    this.price,
    this.quantity,
    this.total,
    this.profit,
  });

  String name;
  int id;
  String price;
  int quantity;
  String total;
  int profit;

  factory ttInItem.fromJson(Map<String, dynamic> json) => ttInItem(
    name: json["name"] == null ? null : json["name"],
    id: json["id"] == null ? null : json["id"],
    price: json["price"] == null ? null : json["price"],
    quantity: json["quantity"] == null ? null : json["quantity"],
    total: json["total"] == null ? null : json["total"],
    profit: json["profit"] == null ? null : json["profit"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "id": id == null ? null : id,
    "price": price == null ? null : price,
    "quantity": quantity == null ? null : quantity,
    "total": total == null ? null : total,
    "profit": profit == null ? null : profit,
  };
}

class TradeMessage {
  TradeMessage({
    this.name,
    this.message,
  });

  String name;
  String message;

  factory TradeMessage.fromJson(Map<String, dynamic> json) => TradeMessage(
    name: json["name"] == null ? null : json["name"],
    message: json["message"] == null ? null : json["message"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "message": message == null ? null : message,
  };
}
