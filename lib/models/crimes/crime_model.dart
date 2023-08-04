// To parse this JSON data, do
//
//     final crime = crimeFromJson(jsonString);

// Dart imports:
import 'dart:convert';

Crime crimeFromJson(String str) => Crime.fromJson(json.decode(str));

String crimeToJson(Crime data) => json.encode(data.toJson());

class Crime {
  Crime({
    required this.nerve,
    required this.fullName,
    required this.shortName,
    required this.action,
    required this.active,
  });

  int? nerve;
  String? fullName;
  String? shortName;
  String? action;
  bool? active;

  factory Crime.fromJson(Map<String, dynamic> json) => Crime(
        nerve: json["nerve"],
        fullName: json["fullName"],
        shortName: json["shortName"],
        action: json["action"],
        active: json["active"],
      );

  Map<String, dynamic> toJson() => {
        "nerve": nerve,
        "fullName": fullName,
        "shortName": shortName,
        "action": action,
        "active": active,
      };
}
