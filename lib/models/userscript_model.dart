// To parse this JSON data, do
//
//     final userScriptModel = userScriptModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

UserScriptModel userScriptModelFromJson(String str) => UserScriptModel.fromJson(json.decode(str));

String userScriptModelToJson(UserScriptModel data) => json.encode(data.toJson());

class UserScriptModel {
  UserScriptModel({
    this.enabled,
    this.urls,
    this.name,
    this.exampleCode = 0,
    this.version = 0,
    this.edited,
    this.source,
  });

  bool enabled;
  List<dynamic> urls;
  String name;
  int exampleCode;
  int version;
  bool edited;
  String source;

  factory UserScriptModel.fromJson(Map<String, dynamic> json) => UserScriptModel(
    enabled: json["enabled"] == null ? null : json["enabled"],
    urls: json["urls"] == null ? null : json["urls"],
    name: json["name"] == null ? null : json["name"],
    exampleCode: json["exampleCode"] == null ? null : json["exampleCode"],
    version: json["version"] == null ? null : json["version"],
    edited: json["edited"] == null ? null : json["edited"],
    source: json["source"] == null ? null : json["source"],
  );

  Map<String, dynamic> toJson() => {
    "enabled": enabled == null ? null : enabled,
    "urls": urls == null ? null : urls,
    "name": name == null ? null : name,
    "exampleCode": exampleCode == null ? null : exampleCode,
    "version": version == null ? null : version,
    "edited": edited == null ? null : edited,
    "source": source == null ? null : source,
  };
}
