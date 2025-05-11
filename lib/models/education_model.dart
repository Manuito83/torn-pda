// To parse this JSON data, do
//
//     final tornEducationModel = tornEducationModelFromJson(jsonString);

import 'dart:convert';

TornEducationModel tornEducationModelFromJson(String str) => TornEducationModel.fromJson(json.decode(str));

String tornEducationModelToJson(TornEducationModel data) => json.encode(data.toJson());

class TornEducationModel {
  Map<String, Education> education;

  TornEducationModel({
    required this.education,
  });

  factory TornEducationModel.fromJson(Map<String, dynamic> json) => TornEducationModel(
        education: Map.from(json["education"]).map((k, v) => MapEntry<String, Education>(k, Education.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "education": Map.from(education).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Education {
  String name;
  String description;
  String code;
  int moneyCost;
  int tier;
  int duration;
  List<dynamic> prerequisites;

  Education({
    required this.name,
    required this.description,
    required this.code,
    required this.moneyCost,
    required this.tier,
    required this.duration,
    required this.prerequisites,
  });

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        name: json["name"],
        description: json["description"],
        code: json["code"],
        moneyCost: json["money_cost"],
        tier: json["tier"],
        duration: json["duration"],
        prerequisites: List<dynamic>.from(json["prerequisites"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "code": code,
        "money_cost": moneyCost,
        "tier": tier,
        "duration": duration,
        "prerequisites": List<dynamic>.from(prerequisites.map((x) => x)),
      };
}
