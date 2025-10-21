// To parse this JSON data, do
//
//     final wolverinesReviveModel = wolverinesReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

WolverinesReviveModel wolverinesReviveModelFromJson(String str) => WolverinesReviveModel.fromJson(json.decode(str));

String wolverinesReviveModelToJson(WolverinesReviveModel data) => json.encode(data.toJson());

class WolverinesReviveModel {
  String? vendor;
  int? tornId;
  String? username;
  String? source;
  String? type;

  WolverinesReviveModel({
    this.vendor,
    this.tornId,
    this.username,
    this.source,
    this.type,
  });

  factory WolverinesReviveModel.fromJson(Map<String, dynamic> json) => WolverinesReviveModel(
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
