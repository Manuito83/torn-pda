// To parse this JSON data, do
//
//     final tornStatsSpyModel = tornStatsSpyModelFromJson(jsonString);

import 'dart:convert';

TornStatsSpyModel tornStatsSpyModelFromJson(String str) => TornStatsSpyModel.fromJson(json.decode(str));

String tornStatsSpyModelToJson(TornStatsSpyModel data) => json.encode(data.toJson());

class TornStatsSpyModel {
  TornStatsSpyModel({
    this.status,
    this.message,
    this.compare,
    this.spy,
    this.attacks,
  });

  bool? status;
  String? message;
  Compare? compare;
  Spy? spy;
  Attacks? attacks;

  factory TornStatsSpyModel.fromJson(Map<String, dynamic> json) => TornStatsSpyModel(
        status: json["status"],
        message: json["message"],
        compare: json["compare"] == null ? null : Compare.fromJson(json["compare"]),
        spy: json["spy"] == null ? null : Spy.fromJson(json["spy"]),
        attacks: json["attacks"] == null ? null : Attacks.fromJson(json["attacks"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "compare": compare == null ? null : compare!.toJson(),
        "spy": spy == null ? null : spy!.toJson(),
        "attacks": attacks == null ? null : attacks!.toJson(),
      };
}

class Attacks {
  Attacks({
    this.status,
    this.message,
  });

  bool? status;
  String? message;

  factory Attacks.fromJson(Map<String, dynamic> json) => Attacks(
        status: json["status"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
      };
}

class Compare {
  Compare({
    this.status,
    this.data,
  });

  bool? status;
  Data? data;

  factory Compare.fromJson(Map<String, dynamic> json) => Compare(
        status: json["status"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data == null ? null : data!.toJson(),
      };
}

class Data {
  Data({
    this.attacksWon,
    this.attacksLost,
  });

  AttacksLostClass? attacksWon;
  AttacksLostClass? attacksLost;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        attacksWon: json["Attacks Won"] == null ? null : AttacksLostClass.fromJson(json["Attacks Won"]),
        attacksLost: json["Attacks Lost"] == null ? null : AttacksLostClass.fromJson(json["Attacks Lost"]),
      );

  Map<String, dynamic> toJson() => {
        "Attacks Won": attacksWon == null ? null : attacksWon!.toJson(),
        "Attacks Lost": attacksLost == null ? null : attacksLost!.toJson(),
      };
}

class AttacksLostClass {
  AttacksLostClass({
    this.amount,
    this.difference,
  });

  int? amount;
  int? difference;

  factory AttacksLostClass.fromJson(Map<String, dynamic> json) => AttacksLostClass(
        amount: json["amount"],
        difference: json["difference"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "difference": difference,
      };
}

class Spy {
  Spy({
    this.type,
    this.status,
    this.message,
    this.playerName,
    this.playerId,
    this.playerLevel,
    this.playerFaction,
    this.targetScore,
    this.yourScore,
    this.fairFightBonus,
    this.difference,
    this.timestamp,
    this.strength,
    this.deltaStrength,
    this.defense,
    this.deltaDefense,
    this.speed,
    this.deltaSpeed,
    this.dexterity,
    this.deltaDexterity,
    this.total,
    this.deltaTotal,
  });

  String? type;
  bool? status;
  String? message;
  String? playerName;
  String? playerId;
  int? playerLevel;
  String? playerFaction;
  double? targetScore;
  double? yourScore;
  double? fairFightBonus;
  String? difference;
  int? timestamp;
  dynamic strength;
  int? deltaStrength;
  dynamic defense;
  int? deltaDefense;
  dynamic speed;
  int? deltaSpeed;
  dynamic dexterity;
  int? deltaDexterity;
  dynamic total;
  int? deltaTotal;

  factory Spy.fromJson(Map<String, dynamic> json) => Spy(
        type: json["type"],
        status: json["status"],
        message: json["message"],
        playerName: json["player_name"],
        playerId: json["player_id"],
        playerLevel: json["player_level"],
        playerFaction: json["player_faction"],
        targetScore: json["target_score"] == null ? null : json["target_score"].toDouble(),
        yourScore: json["your_score"] == null ? null : json["your_score"].toDouble(),
        fairFightBonus: json["fair_fight_bonus"] == null ? null : json["fair_fight_bonus"].toDouble(),
        difference: json["difference"],
        timestamp: json["timestamp"],
        strength: json["strength"] == null
            ? null
            : json["strength"] is String
                ? -1
                : json["strength"],
        deltaStrength: json["deltaStrength"],
        defense: json["defense"] == null
            ? null
            : json["defense"] is String
                ? -1
                : json["defense"],
        deltaDefense: json["deltaDefense"],
        speed: json["speed"] == null
            ? null
            : json["speed"] is String
                ? -1
                : json["speed"],
        deltaSpeed: json["deltaSpeed"],
        dexterity: json["dexterity"] == null
            ? null
            : json["dexterity"] is String
                ? -1
                : json["dexterity"],
        deltaDexterity: json["deltaDexterity"],
        total: json["total"] == null
            ? null
            : json["total"] is String
                ? -1
                : json["total"],
        deltaTotal: json["deltaTotal"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "status": status,
        "message": message,
        "player_name": playerName,
        "player_id": playerId,
        "player_level": playerLevel,
        "player_faction": playerFaction,
        "target_score": targetScore,
        "your_score": yourScore,
        "fair_fight_bonus": fairFightBonus,
        "difference": difference,
        "timestamp": timestamp,
        "strength": strength,
        "deltaStrength": deltaStrength,
        "defense": defense,
        "deltaDefense": deltaDefense,
        "speed": speed,
        "deltaSpeed": deltaSpeed,
        "dexterity": dexterity,
        "deltaDexterity": deltaDexterity,
        "total": total,
        "deltaTotal": deltaTotal,
      };
}
