// To parse this JSON data, do
//
//     final combatReadyReviveModel = combatReadyReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

CombatReadyReviveModel combatReadyReviveModelFromJson(String str) => CombatReadyReviveModel.fromJson(json.decode(str));

String combatReadyReviveModelToJson(CombatReadyReviveModel data) => json.encode(data.toJson());

class CombatReadyReviveModel {
  String? userId;
  String? userName;
  String? faction;
  String? country;

  CombatReadyReviveModel({
    this.userId,
    this.userName,
    this.faction,
    this.country,
  });

  factory CombatReadyReviveModel.fromJson(Map<String, dynamic> json) => CombatReadyReviveModel(
        userId: json["userId"],
        userName: json["userName"],
        faction: json["faction"],
        country: json["country"],
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "userName": userName,
        "faction": faction,
        "country": country,
      };
}
