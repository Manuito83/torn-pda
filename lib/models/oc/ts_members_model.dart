// To parse this JSON data, do
//
//     final tornStatsMembersModel = tornStatsMembersModelToJson(jsonString);

import 'dart:convert';

TornStatsMembersModel tornStatsMembersModelFromJson(String str) => TornStatsMembersModel.fromJson(json.decode(str));

String tornStatsMembersModelToJson(TornStatsMembersModel data) => json.encode(data.toJson());

enum NaturalNerveBarSource {
  off,
  yata,
  tornStats,
}

class TornStatsMembersModel {
  TornStatsMembersModel({
    this.status,
    this.message,
    this.members,
  });

  bool status;
  String message;
  Map<String, Member> members;

  factory TornStatsMembersModel.fromJson(Map<String, dynamic> json) => TornStatsMembersModel(
        status: json["status"] ?? false,
        message: json["message"] ?? "",
        members: json["members"] == null
            ? null
            : Map.from(json["members"]).map((k, v) => MapEntry<String, Member>(k, Member.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "members": Map.from(members).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Member {
  Member({
    this.name,
    this.naturalNerve,
    this.crimeSuccess,
    this.psychDegree,
    this.federalJudge,
    this.verified,
  });

  String name;
  int naturalNerve;
  int crimeSuccess;
  int psychDegree;
  int federalJudge;
  int verified;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        name: json["name"],
        naturalNerve: json["natural_nerve"],
        crimeSuccess: json["crime_success"],
        psychDegree: json["psych_degree"],
        federalJudge: json["federal_judge"],
        verified: json["verified"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "natural_nerve": naturalNerve,
        "crime_success": crimeSuccess,
        "psych_degree": psychDegree,
        "federal_judge": federalJudge,
        "verified": verified,
      };
}
