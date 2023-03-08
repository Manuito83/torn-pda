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
    this.isEnergyPoints = false,
    this.isNervePoints = false,
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
  bool isEnergyPoints;
  bool isNervePoints;

  factory QuickItem.fromJson(Map<String, dynamic> json) => QuickItem(
        active: json["active"] == null ? null : json["active"],
        visible: json["visible"] == null ? null : json["visible"],
        number: json["number"] == null ? null : json["number"],
        name: json["name"] == null ? null : json["name"],
        description: json["description"] == null ? null : json["description"],
        inventory: json["inventory"] == null ? null : json["inventory"],
        isLoadout: json["isLoadout"] == null ? false : json["isLoadout"],
        loadoutNumber: json["loadoutNumber"] == -1 ? null : json["loadoutNumber"],
        loadoutName: json["loadoutName"] == "" ? null : json["loadoutName"],
        isEnergyPoints: json["isEnergyPoints"] == null ? false : json["isEnergyPoints"],
        isNervePoints: json["isNervePoints"] == null ? false : json["isNervePoints"],
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
        "isEnergyPoints": isEnergyPoints == null ? false : isEnergyPoints,
        "isNervePoints": isNervePoints == null ? false : isNervePoints,
      };
}
