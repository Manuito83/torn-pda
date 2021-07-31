// To parse this JSON data, do
//
//     final inventoryModel = inventoryModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

InventoryModel inventoryModelFromJson(String str) => InventoryModel.fromJson(json.decode(str));

String inventoryModelToJson(InventoryModel data) => json.encode(data.toJson());

class InventoryModel {
  InventoryModel({
    this.display,
    this.inventory,
  });

  List<Display> display;
  List<Inventory> inventory;

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
    display: json["display"] == null ? null : List<Display>.from(json["display"].map((x) => Display.fromJson(x))),
    inventory: json["inventory"] == null ? null : List<Inventory>.from(json["inventory"].map((x) => Inventory.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "display": display == null ? null : List<dynamic>.from(display.map((x) => x.toJson())),
    "inventory": inventory == null ? null : List<dynamic>.from(inventory.map((x) => x.toJson())),
  };
}

class Display {
  Display({
    this.id,
    this.name,
    this.type,
    this.quantity,
    this.circulation,
    this.marketPrice,
  });

  int id;
  String name;
  String type;
  int quantity;
  int circulation;
  int marketPrice;

  factory Display.fromJson(Map<String, dynamic> json) => Display(
    id: json["ID"] == null ? null : json["ID"],
    name: json["name"] == null ? null : json["name"],
    type: json["type"] == null ? null : json["type"],
    quantity: json["quantity"] == null ? null : json["quantity"],
    circulation: json["circulation"] == null ? null : json["circulation"],
    marketPrice: json["market_price"] == null ? null : json["market_price"],
  );

  Map<String, dynamic> toJson() => {
    "ID": id == null ? null : id,
    "name": name == null ? null : name,
    "type": type == null ? null : type,
    "quantity": quantity == null ? null : quantity,
    "circulation": circulation == null ? null : circulation,
    "market_price": marketPrice == null ? null : marketPrice,
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
