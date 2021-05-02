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
    this.targetFactionName,
    this.targetFactionId,
  });

  int strength;
  int speed;
  int defense;
  int dexterity;
  int total;
  int strengthTimestamp;
  int speedTimestamp;
  int defenseTimestamp;
  int dexterityTimestamp;
  int totalTimestamp;
  int update;
  String targetName;
  String targetFactionName;
  int targetFactionId;

  factory YataSpyModel.fromJson(Map<String, dynamic> json) => YataSpyModel(
    strength: json["strength"] == null ? null : json["strength"],
    speed: json["speed"] == null ? null : json["speed"],
    defense: json["defense"] == null ? null : json["defense"],
    dexterity: json["dexterity"] == null ? null : json["dexterity"],
    total: json["total"] == null ? null : json["total"],
    strengthTimestamp: json["strength_timestamp"] == null ? null : json["strength_timestamp"],
    speedTimestamp: json["speed_timestamp"] == null ? null : json["speed_timestamp"],
    defenseTimestamp: json["defense_timestamp"] == null ? null : json["defense_timestamp"],
    dexterityTimestamp: json["dexterity_timestamp"] == null ? null : json["dexterity_timestamp"],
    totalTimestamp: json["total_timestamp"] == null ? null : json["total_timestamp"],
    update: json["update"] == null ? null : json["update"],
    targetName: json["target_name"] == null ? null : json["target_name"],
    targetFactionName: json["target_faction_name"] == null ? null : json["target_faction_name"],
    targetFactionId: json["target_faction_id"] == null ? null : json["target_faction_id"],
  );

  Map<String, dynamic> toJson() => {
    "strength": strength == null ? null : strength,
    "speed": speed == null ? null : speed,
    "defense": defense == null ? null : defense,
    "dexterity": dexterity == null ? null : dexterity,
    "total": total == null ? null : total,
    "strength_timestamp": strengthTimestamp == null ? null : strengthTimestamp,
    "speed_timestamp": speedTimestamp == null ? null : speedTimestamp,
    "defense_timestamp": defenseTimestamp == null ? null : defenseTimestamp,
    "dexterity_timestamp": dexterityTimestamp == null ? null : dexterityTimestamp,
    "total_timestamp": totalTimestamp == null ? null : totalTimestamp,
    "update": update == null ? null : update,
    "target_name": targetName == null ? null : targetName,
    "target_faction_name": targetFactionName == null ? null : targetFactionName,
    "target_faction_id": targetFactionId == null ? null : targetFactionId,
  };
}
