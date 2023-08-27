// To parse this JSON data, do
//
//     final jailModel = jailModelFromJson(jsonString);

import 'dart:convert';

JailModel jailModelFromJson(String str) => JailModel.fromJson(json.decode(str));

String jailModelToJson(JailModel data) => json.encode(data.toJson());

class JailModel {
  JailModel({
    this.filtersEnabled = true,
    this.levelMin = 1,
    this.levelMax = 100,
    this.timeMin = 0,
    this.timeMax = 100,
    this.scoreMin = 0,
    this.scoreMax = 250000,
    this.bailTicked = false,
    this.bustTicked = false,
    this.excludeSelf = false,
    this.excludeName = "",
  });

  bool filtersEnabled;
  int levelMin;
  int levelMax;
  int timeMin;
  int timeMax;
  int scoreMin;
  int scoreMax;
  bool bailTicked;
  bool bustTicked;
  bool excludeSelf;
  String excludeName;

  factory JailModel.fromJson(Map<String, dynamic> json) => JailModel(
        filtersEnabled: json["enabled"] ?? true,
        levelMin: json["levelMin"] ?? 1,
        levelMax: json["levelMax"] ?? 100,
        timeMin: json["timeMin"] ?? 0,
        timeMax: json["timeMax"] ?? 100,
        scoreMin: json["scoreMin"] ?? 0,
        scoreMax: json["scoreMax"] ?? 250000,
        bailTicked: json["bailTicked"] ?? false,
        bustTicked: json["bustTicked"] ?? false,
        excludeSelf: json["excludeMin"] ?? false,
        excludeName: json["excludeName"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "enabled": filtersEnabled,
        "levelMin": levelMin,
        "levelMax": levelMax,
        "timeMin": timeMin,
        "timeMax": timeMax,
        "scoreMin": scoreMin,
        "scoreMax": scoreMax,
        "bailTicked": bailTicked,
        "bustTicked": bustTicked,
        "excludeSelf": excludeSelf,
        "excludeName": excludeName,
      };
}
