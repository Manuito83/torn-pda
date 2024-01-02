// To parse this JSON data, do
//
//     final tornTraderInModel = tornTraderInModelFromJson(jsonString);

// Dart imports:
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

  Trade? trade;

  factory TornTraderInModel.fromJson(Map<String, dynamic> json) => TornTraderInModel(
        trade: json["trade"] == null ? null : Trade.fromJson(json["trade"]),
      );

  Map<String, dynamic> toJson() => {
        "trade": trade?.toJson(),
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

  String? tradeUrl;
  String? tradeTotal;
  List<TtInItem>? items;
  List<TradeMessage>? tradeMessages;
  String? totalProfit;

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
        tradeUrl: json["trade_url"],
        tradeTotal: json["trade_total"],
        items: json["items"] == null ? null : List<TtInItem>.from(json["items"].map((x) => TtInItem.fromJson(x))),
        tradeMessages: json["trade_messages"] == null
            ? null
            : List<TradeMessage>.from(json["trade_messages"].map((x) => TradeMessage.fromJson(x))),
        totalProfit: json["total_profit"],
      );

  Map<String, dynamic> toJson() => {
        "trade_url": tradeUrl,
        "trade_total": tradeTotal,
        "items": items == null ? null : List<dynamic>.from(items!.map((x) => x.toJson())),
        "trade_messages": tradeMessages == null ? null : List<dynamic>.from(tradeMessages!.map((x) => x.toJson())),
        "total_profit": totalProfit,
      };
}

class TtInItem {
  TtInItem({
    this.name,
    this.id,
    this.price,
    this.quantity,
    this.total,
    this.profit,
  });

  String? name;
  int? id;
  String? price;
  int? quantity;
  String? total;
  int? profit;

  factory TtInItem.fromJson(Map<String, dynamic> json) => TtInItem(
        name: json["name"],
        id: json["id"],
        price: json["price"],
        quantity: json["quantity"],
        total: json["total"],
        profit: json["profit"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "id": id,
        "price": price,
        "quantity": quantity,
        "total": total,
        "profit": profit,
      };
}

class TradeMessage {
  TradeMessage({
    this.name,
    this.message,
  });

  String? name;
  String? message;

  factory TradeMessage.fromJson(Map<String, dynamic> json) => TradeMessage(
        name: json["name"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "message": message,
      };
}
