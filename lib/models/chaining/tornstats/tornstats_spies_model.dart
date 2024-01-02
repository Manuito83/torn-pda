// To parse this JSON data, do
//
//     final tornStatsSpiesModel = tornStatsSpiesModelFromJson(jsonString);

import 'dart:convert';

TornStatsSpiesModel tornStatsSpiesModelFromJson(String str) => TornStatsSpiesModel.fromJson(json.decode(str));

String tornStatsSpiesModelToJson(TornStatsSpiesModel data) => json.encode(data.toJson());

class TornStatsSpiesModel {
  TornStatsSpiesModel({
    this.status,
    this.message,
    this.user,
    this.spies = const <SpyElement>[],
  });

  bool? status;
  String? message;
  User? user;
  List<SpyElement> spies;

  factory TornStatsSpiesModel.fromJson(Map<String, dynamic> json) => TornStatsSpiesModel(
        status: json["status"],
        message: json["message"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        spies: json["spies"] == null
            ? <SpyElement>[]
            : List<SpyElement>.from(json["spies"].map((x) => SpyElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "user": user?.toJson(),
        "spies": List<dynamic>.from(spies.map((x) => x.toJson())),
      };
}

class SpyElement {
  SpyElement({
    this.strength,
    this.speed,
    this.defense,
    this.dexterity,
    this.total,
    this.timestamp,
    this.playerName,
    this.playerId,
    this.playerLevel,
    this.playerFaction,
  });

  int? strength;
  int? speed;
  int? defense;
  int? dexterity;
  int? total;
  int? timestamp;
  String? playerName;
  String? playerId;
  int? playerLevel;
  String? playerFaction;

  factory SpyElement.fromJson(Map<String, dynamic> json) => SpyElement(
        strength: json["strength"] == null
            ? null
            : json["strength"] == 0
                ? -1
                : json["strength"],
        speed: json["speed"] == null
            ? null
            : json["speed"] == 0
                ? -1
                : json["speed"],
        defense: json["defense"] == null
            ? null
            : json["defense"] == 0
                ? -1
                : json["defense"],
        dexterity: json["dexterity"] == null
            ? null
            : json["dexterity"] == 0
                ? -1
                : json["dexterity"],
        total: json["total"] == null
            ? null
            : json["total"] == 0
                ? -1
                : json["total"],
        timestamp: json["timestamp"],
        playerName: json["player_name"],
        playerId: json["player_id"],
        playerLevel: json["player_level"],
        playerFaction: json["player_faction"],
      );

  Map<String, dynamic> toJson() => {
        "strength": strength,
        "speed": speed,
        "defense": defense,
        "dexterity": dexterity,
        "total": total,
        "timestamp": timestamp,
        "player_name": playerName,
        "player_id": playerId,
        "player_level": playerLevel,
        "player_faction": playerFaction,
      };
}

class User {
  User({
    this.strength,
    this.speed,
    this.defense,
    this.dexterity,
    this.total,
  });

  int? strength;
  int? speed;
  int? defense;
  int? dexterity;
  int? total;

  factory User.fromJson(Map<String, dynamic> json) => User(
        strength: json["strength"],
        speed: json["speed"],
        defense: json["defense"],
        dexterity: json["dexterity"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "strength": strength,
        "speed": speed,
        "defense": defense,
        "dexterity": dexterity,
        "total": total,
      };
}
