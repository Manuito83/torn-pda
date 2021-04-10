// To parse this JSON data, do
//
//     final skillsModel = skillsModelFromJson(jsonString);

import 'dart:convert';

SkillsModel skillsModelFromJson(String str) => SkillsModel.fromJson(json.decode(str));

String skillsModelToJson(SkillsModel data) => json.encode(data.toJson());

class SkillsModel {
  SkillsModel({
    this.hunting,
    this.racing,
    this.reviving,
  });

  String hunting;
  String racing;
  String reviving;

  factory SkillsModel.fromJson(Map<String, dynamic> json) => SkillsModel(
    hunting: json["hunting"] == null ? null : json["hunting"],
    racing: json["racing"] == null ? null : json["racing"],
    reviving: json["reviving"] == null ? null : json["reviving"],
  );

  Map<String, dynamic> toJson() => {
    "hunting": hunting == null ? null : hunting,
    "racing": racing == null ? null : racing,
    "reviving": reviving == null ? null : reviving,
  };
}
