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

  List<DisplayCabinet>? display;
  List<InventoryItem>? inventory;

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
        display: json["display"] == null
            ? null
            : List<DisplayCabinet>.from(json["display"].map((x) => DisplayCabinet.fromJson(x))),
        inventory: json["inventory"] == null || json["inventory"] is String
            ? null
            : List<InventoryItem>.from(json["inventory"].map((x) => InventoryItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "display": display == null ? null : List<dynamic>.from(display!.map((x) => x.toJson())),
        "inventory": inventory == null ? null : List<dynamic>.from(inventory!.map((x) => x.toJson())),
      };
}

class DisplayCabinet {
  DisplayCabinet({
    this.id,
    this.uid,
    this.name,
    this.type,
    this.quantity,
    this.circulation,
    this.marketPrice,
  });

  int? id;
  int? uid;
  String? name;
  String? type;
  int? quantity;
  int? circulation;
  int? marketPrice;

  factory DisplayCabinet.fromJson(Map<String, dynamic> json) => DisplayCabinet(
        id: json["ID"],
        uid: json["UID"],
        name: json["name"],
        type: json["type"],
        quantity: json["quantity"],
        circulation: json["circulation"],
        marketPrice: json["market_price"],
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "UID": uid,
        "name": name,
        "type": type,
        "quantity": quantity,
        "circulation": circulation,
        "market_price": marketPrice,
      };
}

class InventoryItem {
  InventoryItem({
    this.id,
    this.uid,
    this.name,
    this.type,
    this.quantity,
    this.equipped,
    this.marketPrice,
  });

  int? id;
  int? uid;
  String? name;
  String? type;
  int? quantity;
  int? equipped;
  int? marketPrice;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json["ID"],
        uid: json["UID"],
        name: json["name"],
        type: json["type"],
        quantity: json["quantity"],
        equipped: json["equipped"],
        marketPrice: json["market_price"],
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "UID": uid,
        "name": name,
        "type": type,
        "quantity": quantity,
        "equipped": equipped,
        "market_price": marketPrice,
      };
}
