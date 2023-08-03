// To parse this JSON data, do
//
//     final userPerksModel = userPerksModelFromJson(jsonString);

import 'dart:convert';

UserPerksModel userPerksModelFromJson(String str) => UserPerksModel.fromJson(json.decode(str));

String userPerksModelToJson(UserPerksModel data) => json.encode(data.toJson());

class UserPerksModel {
  UserPerksModel({
    this.jobPerks,
    this.propertyPerks,
    this.stockPerks,
    this.meritPerks,
    this.educationPerks,
    this.enhancerPerks,
    this.companyPerks,
    this.factionPerks,
    this.bookPerks,
  });

  List<String>? jobPerks;
  List<String>? propertyPerks;
  List<String>? stockPerks;
  List<String>? meritPerks;
  List<String>? educationPerks;
  List<String>? enhancerPerks;
  List<String>? companyPerks;
  List<String>? factionPerks;
  List<dynamic>? bookPerks;

  factory UserPerksModel.fromJson(Map<String, dynamic> json) => UserPerksModel(
        jobPerks: json["job_perks"] == null ? null : List<String>.from(json["job_perks"].map((x) => x)),
        propertyPerks: json["property_perks"] == null ? null : List<String>.from(json["property_perks"].map((x) => x)),
        stockPerks: json["stock_perks"] == null ? null : List<String>.from(json["stock_perks"].map((x) => x)),
        meritPerks: json["merit_perks"] == null ? null : List<String>.from(json["merit_perks"].map((x) => x)),
        educationPerks:
            json["education_perks"] == null ? null : List<String>.from(json["education_perks"].map((x) => x)),
        enhancerPerks: json["enhancer_perks"] == null ? null : List<String>.from(json["enhancer_perks"].map((x) => x)),
        companyPerks: json["company_perks"] == null ? null : List<String>.from(json["company_perks"].map((x) => x)),
        factionPerks: json["faction_perks"] == null ? null : List<String>.from(json["faction_perks"].map((x) => x)),
        bookPerks: json["book_perks"] == null ? null : List<dynamic>.from(json["book_perks"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "job_perks": jobPerks == null ? null : List<dynamic>.from(jobPerks!.map((x) => x)),
        "property_perks": propertyPerks == null ? null : List<dynamic>.from(propertyPerks!.map((x) => x)),
        "stock_perks": stockPerks == null ? null : List<dynamic>.from(stockPerks!.map((x) => x)),
        "merit_perks": meritPerks == null ? null : List<dynamic>.from(meritPerks!.map((x) => x)),
        "education_perks": educationPerks == null ? null : List<dynamic>.from(educationPerks!.map((x) => x)),
        "enhancer_perks": enhancerPerks == null ? null : List<dynamic>.from(enhancerPerks!.map((x) => x)),
        "company_perks": companyPerks == null ? null : List<dynamic>.from(companyPerks!.map((x) => x)),
        "faction_perks": factionPerks == null ? null : List<dynamic>.from(factionPerks!.map((x) => x)),
        "book_perks": bookPerks == null ? null : List<dynamic>.from(bookPerks!.map((x) => x)),
      };
}
