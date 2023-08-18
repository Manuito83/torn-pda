// To parse this JSON data, do
//
//     final tacModel = tacModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

TacInModel tacModelFromJson(String str) => TacInModel.fromJson(json.decode(str));

String tacModelToJson(TacInModel data) => json.encode(data.toJson());

class TacInModel {
  TacInModel({
    // Logic
    this.incorrectPremium = false, // If requested optimal and user is not premium

    this.premium,
    this.targets,
  });

  bool? incorrectPremium;

  int? premium;
  Map<String, Target>? targets;

  factory TacInModel.fromJson(Map<String, dynamic> json) => TacInModel(
        incorrectPremium: json["incorrectPremium"],
        premium: json["premium"],
        targets: json["targets"] == null
            ? null
            : Map.from(json["targets"]).map((k, v) => MapEntry<String, Target>(k, Target.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "incorrectPremium": incorrectPremium,
        "premium": premium,
        "targets": targets == null ? null : Map.from(targets!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Target {
  Target({
    // Logic
    this.optimal,
    this.username,
    this.userlevel,
    this.estimatedstats,
    this.battlestats,
    this.rank,
    this.fairfight,
    this.respect,
  });

  bool? optimal;

  String? username;
  int? userlevel;
  int? estimatedstats;
  String? battlestats;
  String? rank;
  double? fairfight;
  double? respect;

  factory Target.fromJson(Map<String, dynamic> json) => Target(
        optimal: json["optimal"],
        username: json["username"],
        userlevel: json["userlevel"],
        estimatedstats: json["estimatedstats"],
        battlestats: json["battlestats"],
        rank: json["rank"],
        fairfight: json["fairfight"]?.toDouble(),
        respect: json["respect"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "optimal": optimal,
        "username": username,
        "userlevel": userlevel,
        "estimatedstats": estimatedstats,
        "battlestats": battlestats,
        "rank": rank,
        "fairfight": fairfight,
        "respect": respect,
      };
}
