// To parse this JSON data, do
//
//     final arsonWarehouseOut = arsonWarehouseOutFromJson(jsonString);

import 'dart:convert';

ArsonWarehouseOut arsonWarehouseOutFromJson(String str) => ArsonWarehouseOut.fromJson(json.decode(str));

String arsonWarehouseOutToJson(ArsonWarehouseOut data) => json.encode(data.toJson());

class ArsonWarehouseOut {
  ArsonWarehouseOut({
    this.version,
    this.tradeId,
    this.sellerName,
    this.items,
  });

  int version;
  int tradeId;
  String sellerName;
  List<AwhItem> items;

  factory ArsonWarehouseOut.fromJson(Map<String, dynamic> json) => ArsonWarehouseOut(
    version: json["version"] == null ? null : json["version"],
    tradeId: json["trade_id"] == null ? null : json["trade_id"],
    sellerName: json["seller_name"] == null ? null : json["seller_name"],
    items: json["items"] == null ? null : List<AwhItem>.from(json["items"].map((x) => AwhItem.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "version": version == null ? null : version,
    "trade_id": tradeId == null ? null : tradeId,
    "seller_name": sellerName == null ? null : sellerName,
    "items": items == null ? null : List<dynamic>.from(items.map((x) => x.toJson())),
  };
}

class AwhItem {
  AwhItem({
    this.name,
    this.quantity,
  });

  String name;
  int quantity;

  factory AwhItem.fromJson(Map<String, dynamic> json) => AwhItem(
    name: json["name"] == null ? null : json["name"],
    quantity: json["quantity"] == null ? null : json["quantity"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "quantity": quantity == null ? null : quantity,
  };
}
