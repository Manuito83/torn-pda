// To parse this JSON data, do
//
//     final jailModel = jailModelFromJson(jsonString);

import 'dart:convert';

JailModel jailModelFromJson(String str) => JailModel.fromJson(json.decode(str));

String jailModelToJson(JailModel data) => json.encode(data.toJson());

class JailModel {
  JailModel({
    this.levelMin,
    this.levelMax,
    this.timeMin,
    this.timeMax,
    this.scoreMin,
    this.scoreMax,
    this.bailTicked,
    this.bustTicked,
    this.excludeSelf,
    this.excludeName,
  });

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
        "levelMin": levelMin == null ? null : levelMin,
        "levelMax": levelMax == null ? null : levelMax,
        "timeMin": timeMin == null ? null : timeMin,
        "timeMax": timeMax == null ? null : timeMax,
        "scoreMin": scoreMin == null ? null : scoreMin,
        "scoreMax": scoreMax == null ? null : scoreMax,
        "bailTicked": bailTicked == null ? null : bailTicked,
        "bustTicked": bustTicked == null ? null : bustTicked,
        "excludeSelf": excludeSelf == null ? null : excludeSelf,
        "excludeName": excludeName == null ? null : excludeName,
      };
}
