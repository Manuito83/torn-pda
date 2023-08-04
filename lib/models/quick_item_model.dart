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

  bool? active;
  bool? visible;
  int? number;
  String? name;
  String? description;
  int? inventory;
  bool? isLoadout;
  int? loadoutNumber;
  String? loadoutName;
  bool? isEnergyPoints;
  bool? isNervePoints;

  factory QuickItem.fromJson(Map<String, dynamic> json) => QuickItem(
        active: json["active"],
        visible: json["visible"],
        number: json["number"],
        name: json["name"],
        description: json["description"],
        inventory: json["inventory"],
        isLoadout: json["isLoadout"] ?? false,
        loadoutNumber: json["loadoutNumber"] == -1 ? null : json["loadoutNumber"],
        loadoutName: json["loadoutName"] == "" ? null : json["loadoutName"],
        isEnergyPoints: json["isEnergyPoints"] ?? false,
        isNervePoints: json["isNervePoints"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "active": active,
        "visible": visible,
        "number": number,
        "name": name,
        "description": description,
        "inventory": inventory,
        "isLoadout": isLoadout,
        "loadoutNumber": loadoutNumber,
        "loadoutName": loadoutName,
        "isEnergyPoints": isEnergyPoints ?? false,
        "isNervePoints": isNervePoints ?? false,
      };
}
