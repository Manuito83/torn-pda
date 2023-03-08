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
    this.spies,
  });

  bool status;
  String message;
  User user;
  List<SpyElement> spies;

  factory TornStatsSpiesModel.fromJson(Map<String, dynamic> json) => TornStatsSpiesModel(
        status: json["status"] == null ? null : json["status"],
        message: json["message"] == null ? null : json["message"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        spies: json["spies"] == null ? null : List<SpyElement>.from(json["spies"].map((x) => SpyElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status == null ? null : status,
        "message": message == null ? null : message,
        "user": user == null ? null : user.toJson(),
        "spies": spies == null ? null : List<dynamic>.from(spies.map((x) => x.toJson())),
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

  int strength;
  int speed;
  int defense;
  int dexterity;
  int total;
  int timestamp;
  String playerName;
  String playerId;
  int playerLevel;
  String playerFaction;

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
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
        playerName: json["player_name"] == null ? null : json["player_name"],
        playerId: json["player_id"] == null ? null : json["player_id"],
        playerLevel: json["player_level"] == null ? null : json["player_level"],
        playerFaction: json["player_faction"] == null ? null : json["player_faction"],
      );

  Map<String, dynamic> toJson() => {
        "strength": strength == null ? null : strength,
        "speed": speed == null ? null : speed,
        "defense": defense == null ? null : defense,
        "dexterity": dexterity == null ? null : dexterity,
        "total": total == null ? null : total,
        "timestamp": timestamp == null ? null : timestamp,
        "player_name": playerName == null ? null : playerName,
        "player_id": playerId == null ? null : playerId,
        "player_level": playerLevel == null ? null : playerLevel,
        "player_faction": playerFaction == null ? null : playerFaction,
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

  int strength;
  int speed;
  int defense;
  int dexterity;
  int total;

  factory User.fromJson(Map<String, dynamic> json) => User(
        strength: json["strength"] == null ? null : json["strength"],
        speed: json["speed"] == null ? null : json["speed"],
        defense: json["defense"] == null ? null : json["defense"],
        dexterity: json["dexterity"] == null ? null : json["dexterity"],
        total: json["total"] == null ? null : json["total"],
      );

  Map<String, dynamic> toJson() => {
        "strength": strength == null ? null : strength,
        "speed": speed == null ? null : speed,
        "defense": defense == null ? null : defense,
        "dexterity": dexterity == null ? null : dexterity,
        "total": total == null ? null : total,
      };
}
