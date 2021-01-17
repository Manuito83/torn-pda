// To parse this JSON data, do
//
//     final tacModel = tacModelFromJson(jsonString);

import 'dart:convert';

TacInModel tacModelFromJson(String str) => TacInModel.fromJson(json.decode(str));

String tacModelToJson(TacInModel data) => json.encode(data.toJson());

class TacInModel {
  TacInModel({
    this.premium,
    this.targets,
  });

  int premium;
  Map<String, Target> targets;

  factory TacInModel.fromJson(Map<String, dynamic> json) => TacInModel(
    premium: json["premium"] == null ? null : json["premium"],
    targets: json["targets"] == null ? null : Map.from(json["targets"]).map((k, v) => MapEntry<String, Target>(k, Target.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "premium": premium == null ? null : premium,
    "targets": targets == null ? null : Map.from(targets).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
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
  });

  bool optimal;

  String username;
  int userlevel;
  int estimatedstats;
  String battlestats;
  String rank;

  factory Target.fromJson(Map<String, dynamic> json) => Target(
    username: json["username"] == null ? null : json["username"],
    userlevel: json["userlevel"] == null ? null : json["userlevel"],
    estimatedstats: json["estimatedstats"] == null ? null : json["estimatedstats"],
    battlestats: json["battlestats"] == null ? null : json["battlestats"],
    rank: json["rank"] == null ? null : json["rank"],
  );

  Map<String, dynamic> toJson() => {
    "username": username == null ? null : username,
    "userlevel": userlevel == null ? null : userlevel,
    "estimatedstats": estimatedstats == null ? null : estimatedstats,
    "battlestats": battlestats == null ? null : battlestats,
    "rank": rank == null ? null : rank,
  };
}
