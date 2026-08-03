// To parse this JSON data, do
//
//     final asclepiusReviveModel = asclepiusReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

AsclepiusReviveModel asclepiusReviveModelFromJson(String str) => AsclepiusReviveModel.fromJson(json.decode(str));

String asclepiusReviveModelToJson(AsclepiusReviveModel data) => json.encode(data.toJson());

class AsclepiusReviveModel {
  String? vendor;
  int? tornId;
  String? username;
  String? source;
  String? type;

  AsclepiusReviveModel({this.vendor, this.tornId, this.username, this.source, this.type});

  factory AsclepiusReviveModel.fromJson(Map<String, dynamic> json) => AsclepiusReviveModel(
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
