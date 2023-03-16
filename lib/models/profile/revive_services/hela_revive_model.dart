// To parse this JSON data, do
//
//     final helaReviveModel = helaReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

HelaReviveModel helaReviveModelFromJson(String str) => HelaReviveModel.fromJson(json.decode(str));

String helaReviveModelToJson(HelaReviveModel data) => json.encode(data.toJson());

class HelaReviveModel {
  String vendor;
  int tornId;
  String username;
  String source;
  String type;

  HelaReviveModel({
    this.vendor,
    this.tornId,
    this.username,
    this.source,
    this.type,
  });

  factory HelaReviveModel.fromJson(Map<String, dynamic> json) => HelaReviveModel(
        vendor: json["vendor"] == null ? null : json["vendor"],
        tornId: json["tornid"] == null ? null : json["tornid"],
        username: json["username"] == null ? null : json["username"],
        source: json["source"] == null ? null : json["source"],
        type: json["type"] == null ? null : json["type"],
      );

  Map<String, dynamic> toJson() => {
        "vendor": vendor == null ? null : vendor,
        "tornid": tornId == null ? null : tornId,
        "username": username == null ? null : username,
        "source": source == null ? null : source,
        "type": type == null ? null : type,
      };
}
