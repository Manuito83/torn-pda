// To parse this JSON data, do
//
//     final nukeReviveModel = nukeReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

NukeReviveModel nukeReviveModelFromJson(String str) => NukeReviveModel.fromJson(json.decode(str));

String nukeReviveModelToJson(NukeReviveModel data) => json.encode(data.toJson());

class NukeReviveModel {
  NukeReviveModel({
    this.uid,
    this.player,
    this.faction,
    this.country,
    this.appInfo,
  });

  String? uid;
  String? player;
  String? faction;
  String? country;
  String? appInfo;

  factory NukeReviveModel.fromJson(Map<String, dynamic> json) => NukeReviveModel(
    uid: json["uid"],
    player: json["Player"],
    faction: json["Faction"],
    country: json["Country"],
    appInfo: json["AppInfo"],
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "Player": player,
    "Faction": faction,
    "Country": country,
    "AppInfo": appInfo,
  };
}
