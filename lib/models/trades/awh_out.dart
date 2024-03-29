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
    this.me,
    this.them,
    this.theirItems,
    this.myItems,
  });

  int? version;
  int? tradeId;
  int? me;
  String? them;
  List<AwhItem>? theirItems;
  List<AwhItem>? myItems;

  factory ArsonWarehouseOut.fromJson(Map<String, dynamic> json) => ArsonWarehouseOut(
    version: json["version"],
    tradeId: json["trade_id"],
    me: json["me"],
    them: json["them"],
    theirItems: json["their_items"] == null ? null : List<AwhItem>.from(json["their_items"].map((x) => AwhItem.fromJson(x))),
    myItems: json["my_items"] == null ? null : List<AwhItem>.from(json["my_items"].map((x) => AwhItem.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "version": version,
    "trade_id": tradeId,
    "me": me,
    "them": them,
    "their_items": theirItems == null ? null : List<dynamic>.from(theirItems!.map((x) => x.toJson())),
    "my_items": myItems == null ? null : List<dynamic>.from(myItems!.map((x) => x.toJson())),
  };
}

class AwhItem {
  AwhItem({
    this.name,
    this.quantity,
  });

  String? name;
  int? quantity;

  factory AwhItem.fromJson(Map<String, dynamic> json) => AwhItem(
    name: json["name"],
    quantity: json["quantity"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "quantity": quantity,
  };
}
