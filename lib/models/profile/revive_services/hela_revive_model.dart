// To parse this JSON data, do
//
//     final helaReviveModel = helaReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

HelaReviveModel helaReviveModelFromJson(String str) => HelaReviveModel.fromJson(json.decode(str));

String helaReviveModelToJson(HelaReviveModel data) => json.encode(data.toJson());

class HelaReviveModel {
  String? vendor;
  int? tornId;
  String? username;
  String? source;
  String? type;

  HelaReviveModel({
    this.vendor,
    this.tornId,
    this.username,
    this.source,
    this.type,
  });

  factory HelaReviveModel.fromJson(Map<String, dynamic> json) => HelaReviveModel(
        vendor: json["vendor"],
        tornId: json["tornid"],
        username: json["username"],
        source: json["source"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "vendor": vendor,
        "tornid": tornId,
        "username": username,
        "source": source,
        "type": type,
      };
}
