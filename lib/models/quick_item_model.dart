// To parse this JSON data, do
//
//     final quickItem = quickItemFromJson(jsonString);

// Dart imports:
import 'dart:convert';

QuickItem quickItemFromJson(String str) => QuickItem.fromJson(json.decode(str));

String quickItemToJson(QuickItem data) => json.encode(data.toJson());

class QuickItem {
  QuickItem({
    this.active = false,
    this.visible = true,
    this.number = 0,
    this.name = "",
    this.description = "",
    this.inventory = 0,
    this.isLoadout = false,
    this.loadoutNumber = -1,
    this.loadoutName = "",
  });

  bool active;
  bool visible;
  int number;
  String name;
  String description;
  int inventory;
  bool isLoadout;
  int loadoutNumber;
  String loadoutName;

  factory QuickItem.fromJson(Map<String, dynamic> json) => QuickItem(
        active: json["active"] == null ? null : json["active"],
        visible: json["visible"] == null ? null : json["visible"],
        number: json["number"] == null ? null : json["number"],
        name: json["name"] == null ? null : json["name"],
        description: json["description"] == null ? null : json["description"],
        inventory: json["inventory"] == null ? null : json["inventory"],
        isLoadout: json["isLoadout"] == null ? null : json["isLoadout"],
        loadoutNumber: json["loadoutNumber"] == null ? null : json["loadoutNumber"],
        loadoutName: json["loadoutName"] == null ? null : json["loadoutName"],
      );

  Map<String, dynamic> toJson() => {
        "active": active == null ? null : active,
        "visible": visible == null ? null : visible,
        "number": number == null ? null : number,
        "name": name == null ? null : name,
        "description": description == null ? null : description,
        "inventory": inventory == null ? null : inventory,
        "isLoadout": isLoadout == null ? null : isLoadout,
        "loadoutNumber": loadoutNumber == null ? null : loadoutNumber,
        "loadoutName": loadoutName == null ? null : loadoutName,
      };
}
