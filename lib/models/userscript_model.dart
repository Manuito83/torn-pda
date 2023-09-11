// To parse this JSON data, do
//
//     final userScriptModel = userScriptModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

UserScriptModel userScriptModelFromJson(String str) => UserScriptModel.fromJson(json.decode(str));

String userScriptModelToJson(UserScriptModel data) => json.encode(data.toJson());

enum UserScriptTime { start, end }

class UserScriptModel {
  UserScriptModel({
    this.enabled,
    this.urls,
    this.name,
    this.exampleCode = 0,
    this.version = 0,
    this.edited,
    this.source,
    this.time = UserScriptTime.end,
  });

  bool? enabled;
  List<dynamic>? urls;
  String? name;
  int? exampleCode;
  int? version;
  bool? edited;
  String? source;
  UserScriptTime time;

  factory UserScriptModel.fromJson(Map<String, dynamic> json) => UserScriptModel(
        enabled: json["enabled"],
        urls: json["urls"],
        name: json["name"],
        exampleCode: json["exampleCode"],
        version: json["version"],
        edited: json["edited"],
        source: json["source"],
        time: json["time"] == null
            ? UserScriptTime.end
            : json["time"] == "start"
                ? UserScriptTime.start
                : UserScriptTime.end,
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "urls": urls,
        "name": name,
        "exampleCode": exampleCode,
        "version": version,
        "edited": edited,
        "source": source,
        "time": time == UserScriptTime.start ? "start" : "end",
      };
}
