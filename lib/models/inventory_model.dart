// To parse this JSON data, do
//
//     final inventoryModel = inventoryModelFromJson(jsonString);

import 'dart:convert';

InventoryModel inventoryModelFromJson(String str) => InventoryModel.fromJson(json.decode(str));

String inventoryModelToJson(InventoryModel data) => json.encode(data.toJson());

class InventoryModel {
  InventoryModel({
    this.inventory,
  });

  List<Inventory> inventory;

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
    inventory: json["inventory"] == null ? null : List<Inventory>.from(json["inventory"].map((x) => Inventory.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "inventory": inventory == null ? null : List<dynamic>.from(inventory.map((x) => x.toJson())),
  };
}

class Inventory {
  Inventory({
    this.id,
    this.name,
    this.type,
    this.quantity,
    this.equipped,
    this.marketPrice,
  });

  int id;
  String name;
  String type;
  int quantity;
  int equipped;
  int marketPrice;

  factory Inventory.fromJson(Map<String, dynamic> json) => Inventory(
    id: json["ID"] == null ? null : json["ID"],
    name: json["name"] == null ? null : json["name"],
    type: json["type"] == null ? null : json["type"],
    quantity: json["quantity"] == null ? null : json["quantity"],
    equipped: json["equipped"] == null ? null : json["equipped"],
    marketPrice: json["market_price"] == null ? null : json["market_price"],
  );

  Map<String, dynamic> toJson() => {
    "ID": id == null ? null : id,
    "name": name == null ? null : name,
    "type": type == null ? null : type,
    "quantity": quantity == null ? null : quantity,
    "equipped": equipped == null ? null : equipped,
    "market_price": marketPrice == null ? null : marketPrice,
  };
}
