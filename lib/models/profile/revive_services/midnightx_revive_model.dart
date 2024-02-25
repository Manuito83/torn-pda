// To parse this JSON data, do
//
//     final midnightXReviveModel = midnightXReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

MidnightXReviveModel midnightXReviveModelFromJson(String str) => MidnightXReviveModel.fromJson(json.decode(str));

String midnightXReviveModelToJson(MidnightXReviveModel data) => json.encode(data.toJson());

class MidnightXReviveModel {
  String? vendor;
  int? tornId;
  String? username;
  String? source;
  String? type;

  MidnightXReviveModel({
    this.vendor,
    this.tornId,
    this.username,
    this.source,
    this.type,
  });

  factory MidnightXReviveModel.fromJson(Map<String, dynamic> json) => MidnightXReviveModel(
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
