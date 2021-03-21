// To parse this JSON data, do
//
//     final userScriptModel = userScriptModelFromJson(jsonString);

import 'dart:convert';

UserScriptModel userScriptModelFromJson(String str) => UserScriptModel.fromJson(json.decode(str));

String userScriptModelToJson(UserScriptModel data) => json.encode(data.toJson());

class UserScriptModel {
  UserScriptModel({
    this.enabled,
    this.urls,
    this.name,
    this.source,
  });

  bool enabled;
  List<dynamic> urls;
  String name;
  String source;

  factory UserScriptModel.fromJson(Map<String, dynamic> json) => UserScriptModel(
    enabled: json["enabled"] == null ? null : json["enabled"],
    urls: json["urls"] == null ? null : json["urls"],
    name: json["name"] == null ? null : json["name"],
    source: json["source"] == null ? null : json["source"],
  );

  Map<String, dynamic> toJson() => {
    "enabled": enabled == null ? null : enabled,
    "urls": urls == null ? null : urls,
    "name": name == null ? null : name,
    "source": source == null ? null : source,
  };
}
