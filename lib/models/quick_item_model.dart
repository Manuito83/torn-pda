// To parse this JSON data, do
//
//     final quickItem = quickItemFromJson(jsonString);

// Dart imports:
import 'dart:convert';

// Project imports:
import 'package:torn_pda/models/items_model.dart';

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
    this.itemType,
    this.instanceId,
    this.armoryId,
    this.damage,
    this.accuracy,
    this.defense,
    this.isGrouped,
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
  ItemType? itemType;
  String? instanceId;
  String? armoryId;
  double? damage;
  double? accuracy;
  double? defense;
  bool? isGrouped;

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
        itemType: json["itemType"] == null ? null : typeValues.map[json["itemType"]],
        instanceId: json["instanceId"],
        armoryId: json["armoryId"],
        damage: (json["damage"] is num) ? (json["damage"] as num).toDouble() : null,
        accuracy: (json["accuracy"] is num) ? (json["accuracy"] as num).toDouble() : null,
        defense: (json["defense"] is num) ? (json["defense"] as num).toDouble() : null,
        isGrouped: json["isGrouped"],
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
        "itemType": itemType == null ? null : typeValues.reverse![itemType],
        "instanceId": instanceId,
        "armoryId": armoryId,
        "damage": damage,
        "accuracy": accuracy,
        "defense": defense,
        "isGrouped": isGrouped,
      };
}
