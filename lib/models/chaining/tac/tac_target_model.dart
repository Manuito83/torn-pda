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
    battleStats: json["battleStats"] == null ? null : json["battleStats"],
    estimatedStats: json["estimatedStats"] == null ? null : json["estimatedStats"],
    rank: json["rank"] == null ? null : json["rank"],
    userLevel: json["userLevel"] == null ? null : json["userLevel"],
    username: json["username"] == null ? null : json["username"],
    id: json["id"] == null ? null : json["id"],
    optimal: json["optimal"] == null ? null : json["optimal"],
    fairfight: json["fairfight"] == null ? null : json["fairfight"].toDouble(),
    respect: json["respect"] == null ? null : json["respect"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "battleStats": battleStats == null ? null : battleStats,
    "estimatedStats": estimatedStats == null ? null : estimatedStats,
    "rank": rank == null ? null : rank,
    "userLevel": userLevel == null ? null : userLevel,
    "username": username == null ? null : username,
    "id": id == null ? null : id,
    "optimal": optimal == null ? null : optimal,
    "fairfight": fairfight == null ? null : fairfight,
    "respect": respect == null ? null : respect,
  };
}
