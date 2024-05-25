// To parse this JSON data, do
//
//     final tornStatsChartUpdate = tornStatsChartUpdateFromJson(jsonString);

import 'dart:convert';

TornStatsChartUpdate tornStatsChartUpdateFromJson(String str) => TornStatsChartUpdate.fromJson(json.decode(str));

String tornStatsChartUpdateToJson(TornStatsChartUpdate data) => json.encode(data.toJson());

class TornStatsChartUpdate {
  String? age;
  bool? status;
  String? message;
  int? deltaStrength;
  int? deltaDefense;
  int? deltaDexterity;
  int? deltaSpeed;

  TornStatsChartUpdate({
    this.age,
    this.status,
    this.message,
    this.deltaStrength,
    this.deltaDefense,
    this.deltaDexterity,
    this.deltaSpeed,
  });

  factory TornStatsChartUpdate.fromJson(Map<String, dynamic> json) => TornStatsChartUpdate(
        age: json["age"],
        status: json["status"],
        message: json["message"],
        deltaStrength: json["deltaStrength"],
        deltaDefense: json["deltaDefense"],
        deltaDexterity: json["deltaDexterity"],
        deltaSpeed: json["deltaSpeed"],
      );

  Map<String, dynamic> toJson() => {
        "age": age,
        "status": status,
        "message": message,
        "deltaStrength": deltaStrength,
        "deltaDefense": deltaDefense,
        "deltaDexterity": deltaDexterity,
        "deltaSpeed": deltaSpeed,
      };
}
