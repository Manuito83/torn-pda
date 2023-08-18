// To parse this JSON data, do
//
//     final tacTarget = tacTargetFromJson(jsonString);

// Dart imports:
import 'dart:convert';

TacTarget tacTargetFromJson(String str) => TacTarget.fromJson(json.decode(str));

String tacTargetToJson(TacTarget data) => json.encode(data.toJson());

class TacTarget {
  TacTarget({
    this.currentLife,
    this.maxLife,
    this.hospital,
    this.abroad,
    this.battleStats = "",
    this.estimatedStats = 0,
    this.rank = "",
    this.userLevel = 0,
    this.username = "",
    this.id = "",
    this.optimal = false,
    this.fairfight = 0,
    this.respect = 0,
  });

  // Does not get saved
  int? currentLife;
  int? maxLife;
  bool? hospital;
  bool? abroad;

  bool? optimal;
  String? id;
  String? username;
  int? userLevel;
  int? estimatedStats;
  String? battleStats;
  String? rank;
  double? fairfight;
  double? respect;

  factory TacTarget.fromJson(Map<String, dynamic> json) => TacTarget(
        battleStats: json["battleStats"],
        estimatedStats: json["estimatedStats"],
        rank: json["rank"],
        userLevel: json["userLevel"],
        username: json["username"],
        id: json["id"],
        optimal: json["optimal"],
        fairfight: json["fairfight"]?.toDouble(),
        respect: json["respect"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "battleStats": battleStats,
        "estimatedStats": estimatedStats,
        "rank": rank,
        "userLevel": userLevel,
        "username": username,
        "id": id,
        "optimal": optimal,
        "fairfight": fairfight,
        "respect": respect,
      };
}
