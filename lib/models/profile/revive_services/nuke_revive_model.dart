// To parse this JSON data, do
//
//     final nukeReviveModel = nukeReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

NukeReviveModel nukeReviveModelFromJson(String str) => NukeReviveModel.fromJson(json.decode(str));

String nukeReviveModelToJson(NukeReviveModel data) => json.encode(data.toJson());

class NukeReviveModel {
  NukeReviveModel({
    this.tornPlayerId,
    this.tornPlayerName,
    this.factionId,
    this.tornPlayerCountry,
    this.appInfo,
  });

  int? tornPlayerId;
  String? tornPlayerName;
  int? factionId;
  String? tornPlayerCountry;
  String? appInfo;

  factory NukeReviveModel.fromJson(Map<String, dynamic> json) => NukeReviveModel(
        tornPlayerId: json["torn_player_id"],
        tornPlayerName: json["torn_player_name"],
        factionId: json["faction_id"],
        tornPlayerCountry: json["torn_player_country"],
        appInfo: json["app_info"],
      );

  Map<String, dynamic> toJson() => {
        "torn_player_id": tornPlayerId,
        "torn_player_name": tornPlayerName,
        "faction_id": factionId,
        "torn_player_country": tornPlayerCountry,
        "app_info": appInfo,
      };
}
