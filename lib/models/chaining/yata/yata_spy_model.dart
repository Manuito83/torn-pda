// To parse this JSON data, do
//
//     final yataSpyModel = yataSpyModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

YataSpyModel yataSpyModelFromJson(String str) => YataSpyModel.fromJson(json.decode(str));

String yataSpyModelToJson(YataSpyModel data) => json.encode(data.toJson());

class YataSpyModel {
  YataSpyModel({
    this.strength,
    this.speed,
    this.defense,
    this.dexterity,
    this.total,
    this.strengthTimestamp,
    this.speedTimestamp,
    this.defenseTimestamp,
    this.dexterityTimestamp,
    this.totalTimestamp,
    this.update,
    this.targetName,
    this.targetId,
    this.targetFactionName,
    this.targetFactionId,
  });

  int? strength;
  int? speed;
  int? defense;
  int? dexterity;
  int? total;
  int? strengthTimestamp;
  int? speedTimestamp;
  int? defenseTimestamp;
  int? dexterityTimestamp;
  int? totalTimestamp;
  int? update;
  String? targetName;
  String? targetId;
  String? targetFactionName;
  int? targetFactionId;

  factory YataSpyModel.fromJson(Map<String, dynamic> json) => YataSpyModel(
        strength: json["strength"],
        speed: json["speed"],
        defense: json["defense"],
        dexterity: json["dexterity"],
        total: json["total"],
        strengthTimestamp: json["strength_timestamp"],
        speedTimestamp: json["speed_timestamp"],
        defenseTimestamp: json["defense_timestamp"],
        dexterityTimestamp: json["dexterity_timestamp"],
        totalTimestamp: json["total_timestamp"],
        update: json["update"],
        targetName: json["target_name"],
        targetId: json["target_id"],
        targetFactionName: json["target_faction_name"],
        targetFactionId: json["target_faction_id"],
      );

  Map<String, dynamic> toJson() => {
        "strength": strength,
        "speed": speed,
        "defense": defense,
        "dexterity": dexterity,
        "total": total,
        "strength_timestamp": strengthTimestamp,
        "speed_timestamp": speedTimestamp,
        "defense_timestamp": defenseTimestamp,
        "dexterity_timestamp": dexterityTimestamp,
        "total_timestamp": totalTimestamp,
        "update": update,
        "target_name": targetName,
        "target_id": targetId,
        "target_faction_name": targetFactionName,
        "target_faction_id": targetFactionId,
      };
}
