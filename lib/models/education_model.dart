// To parse this JSON data, do
//
//     final tornEducationModel = tornEducationModelFromJson(jsonString);

import 'dart:convert';

TornEducationModel tornEducationModelFromJson(String str) => TornEducationModel.fromJson(json.decode(str));

String tornEducationModelToJson(TornEducationModel data) => json.encode(data.toJson());

class TornEducationModel {
  TornEducationModel({
    this.education,
  });

  Map<String, Education> education;

  factory TornEducationModel.fromJson(Map<String, dynamic> json) => TornEducationModel(
    education: json["education"] == null ? null : Map.from(json["education"]).map((k, v) => MapEntry<String, Education>(k, Education.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "education": education == null ? null : Map.from(education).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class Education {
  Education({
    this.name,
    this.description,
    this.moneyCost,
    this.tier,
    this.duration,
    this.results,
    this.prerequisites,
  });

  String name;
  String description;
  int moneyCost;
  int tier;
  int duration;
  Results results;
  List<int> prerequisites;

  factory Education.fromJson(Map<String, dynamic> json) => Education(
    name: json["name"] == null ? null : json["name"],
    description: json["description"] == null ? null : json["description"],
    moneyCost: json["money_cost"] == null ? null : json["money_cost"],
    tier: json["tier"] == null ? null : json["tier"],
    duration: json["duration"] == null ? null : json["duration"],
    results: json["results"] == null ? null : Results.fromJson(json["results"]),
    prerequisites: json["prerequisites"] == null ? null : List<int>.from(json["prerequisites"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "description": description == null ? null : description,
    "money_cost": moneyCost == null ? null : moneyCost,
    "tier": tier == null ? null : tier,
    "duration": duration == null ? null : duration,
    "results": results == null ? null : results.toJson(),
    "prerequisites": prerequisites == null ? null : List<dynamic>.from(prerequisites.map((x) => x)),
  };
}

class Results {
  Results({
    this.intelligence,
    this.endurance,
    this.perk,
    this.manualLabor,
  });

  List<String> intelligence;
  List<String> endurance;
  List<String> perk;
  List<String> manualLabor;

  factory Results.fromJson(Map<String, dynamic> json) => Results(
    intelligence: json["intelligence"] == null ? null : List<String>.from(json["intelligence"].map((x) => x)),
    endurance: json["endurance"] == null ? null : List<String>.from(json["endurance"].map((x) => x)),
    perk: json["perk"] == null ? null : List<String>.from(json["perk"].map((x) => x)),
    manualLabor: json["manual_labor"] == null ? null : List<String>.from(json["manual_labor"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "intelligence": intelligence == null ? null : List<dynamic>.from(intelligence.map((x) => x)),
    "endurance": endurance == null ? null : List<dynamic>.from(endurance.map((x) => x)),
    "perk": perk == null ? null : List<dynamic>.from(perk.map((x) => x)),
    "manual_labor": manualLabor == null ? null : List<dynamic>.from(manualLabor.map((x) => x)),
  };
}
