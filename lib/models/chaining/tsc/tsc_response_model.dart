// To parse this JSON data, do
//
//     final tscResponse = tscResponseFromJson(jsonString);

import 'dart:convert';

TscResponse tscResponseFromJson(String str) => TscResponse.fromJson(json.decode(str));

String tscResponseToJson(TscResponse data) => json.encode(data.toJson());

class TscResponse {
  bool success;
  String message;
  Spy? spy;
  int? code;

  TscResponse({
    required this.success,
    required this.message,
    this.spy,
    this.code,
  });

  factory TscResponse.fromJson(Map<String, dynamic> json) => TscResponse(
        success: json["success"],
        message: json["message"],
        spy: json["spy"] == null ? null : Spy.fromJson(json["spy"]),
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "spy": spy?.toJson(),
        "code": code,
      };
}

class Spy {
  int userId;
  String userName;
  Estimate estimate;
  StatInterval statInterval;

  Spy({
    required this.userId,
    required this.userName,
    required this.estimate,
    required this.statInterval,
  });

  factory Spy.fromJson(Map<String, dynamic> json) => Spy(
        userId: json["userId"],
        userName: json["userName"],
        estimate: Estimate.fromJson(json["estimate"]),
        statInterval: StatInterval.fromJson(json["statInterval"]),
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "userName": userName,
        "estimate": estimate.toJson(),
        "statInterval": statInterval.toJson(),
      };
}

class Estimate {
  String stats;
  DateTime lastUpdated;

  Estimate({
    required this.stats,
    required this.lastUpdated,
  });

  factory Estimate.fromJson(Map<String, dynamic> json) => Estimate(
        stats: json["stats"],
        lastUpdated: DateTime.parse(json["lastUpdated"]),
      );

  Map<String, dynamic> toJson() => {
        "stats": stats,
        "lastUpdated": lastUpdated.toIso8601String(),
      };
}

class StatInterval {
  String min;
  String max;
  double battleScore;
  String fairFight;
  dynamic lastUpdated;

  StatInterval({
    required this.min,
    required this.max,
    required this.battleScore,
    required this.fairFight,
    required this.lastUpdated,
  });

  factory StatInterval.fromJson(Map<String, dynamic> json) => StatInterval(
        min: json["min"],
        max: json["max"],
        battleScore: json["battleScore"].toDouble(),
        fairFight: json["fairFight"],
        lastUpdated: json["lastUpdated"],
      );

  Map<String, dynamic> toJson() => {
        "min": min,
        "max": max,
        "battleScore": battleScore,
        "fairFight": fairFight,
        "lastUpdated": lastUpdated,
      };
}
