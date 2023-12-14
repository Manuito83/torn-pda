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
  Results results;
  List<dynamic> prerequisites;

  Education({
    required this.name,
    required this.description,
    required this.code,
    required this.moneyCost,
    required this.tier,
    required this.duration,
    required this.results,
    required this.prerequisites,
  });

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        name: json["name"],
        description: json["description"],
        code: json["code"],
        moneyCost: json["money_cost"],
        tier: json["tier"],
        duration: json["duration"],
        results: Results.fromJson(json["results"]),
        prerequisites: List<dynamic>.from(json["prerequisites"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "code": code,
        "money_cost": moneyCost,
        "tier": tier,
        "duration": duration,
        "results": results.toJson(),
        "prerequisites": List<dynamic>.from(prerequisites.map((x) => x)),
      };
}

class Results {
  List<String>? intelligence;
  List<String>? endurance;
  List<String>? perk;
  List<String>? manualLabor;

  Results({
    this.intelligence,
    this.endurance,
    this.perk,
    this.manualLabor,
  });

  factory Results.fromJson(Map<String, dynamic> json) => Results(
        intelligence: json["intelligence"] == null ? [] : List<String>.from(json["intelligence"]!.map((x) => x)),
        endurance: json["endurance"] == null ? [] : List<String>.from(json["endurance"]!.map((x) => x)),
        perk: json["perk"] == null ? [] : List<String>.from(json["perk"]!.map((x) => x)),
        manualLabor: json["manual_labor"] == null ? [] : List<String>.from(json["manual_labor"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "intelligence": intelligence == null ? [] : List<dynamic>.from(intelligence!.map((x) => x)),
        "endurance": endurance == null ? [] : List<dynamic>.from(endurance!.map((x) => x)),
        "perk": perk == null ? [] : List<dynamic>.from(perk!.map((x) => x)),
        "manual_labor": manualLabor == null ? [] : List<dynamic>.from(manualLabor!.map((x) => x)),
      };
}
