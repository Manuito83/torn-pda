// To parse this JSON data, do
//
//     final nukeReviveModel = nukeReviveModelFromJson(jsonString);

import 'dart:convert';

NukeReviveModel nukeReviveModelFromJson(String str) => NukeReviveModel.fromJson(json.decode(str));

String nukeReviveModelToJson(NukeReviveModel data) => json.encode(data.toJson());

class NukeReviveModel {
  NukeReviveModel({
    this.uid,
    this.player,
    this.faction,
    this.country,
  });

  String uid;
  String player;
  String faction;
  String country;

  factory NukeReviveModel.fromJson(Map<String, dynamic> json) => NukeReviveModel(
    uid: json["uid"] == null ? null : json["uid"],
    player: json["Player"] == null ? null : json["Player"],
    faction: json["Faction"] == null ? null : json["Faction"],
    country: json["Country"] == null ? null : json["Country"],
  );

  Map<String, dynamic> toJson() => {
    "uid": uid == null ? null : uid,
    "Player": player == null ? null : player,
    "Faction": faction == null ? null : faction,
    "Country": country == null ? null : country,
  };
}
