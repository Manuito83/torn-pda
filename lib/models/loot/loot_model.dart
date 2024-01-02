// To parse this JSON data, do
//
//     final lootModel = lootModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

Map<String, LootModel> lootModelFromJson(String str) =>
    Map.from(json.decode(str)).map((k, v) => MapEntry<String, LootModel>(k, LootModel.fromJson(v)));

String lootModelToJson(Map<String, LootModel> data) =>
    json.encode(Map.from(data).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())));

class LootModel {
  LootModel({
    this.name,
    this.hospout,
    this.status,
    this.timings,
    this.levels,
  });

  String? name;
  int? hospout;
  String? status;
  Map<String, Timing>? timings;
  Levels? levels;

  factory LootModel.fromJson(Map<String, dynamic> json) => LootModel(
        name: json["name"],
        hospout: json["hospout"],
        status: json["status"],
        timings: json["timings"] == null
            ? null
            : Map.from(json["timings"]).map((k, v) => MapEntry<String, Timing>(k, Timing.fromJson(v))),
        levels: json["levels"] == null ? null : Levels.fromJson(json["levels"]),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "hospout": hospout,
        "status": status,
        "timings": timings == null ? null : Map.from(timings!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "levels": levels?.toJson(),
      };
}

class Levels {
  Levels({
    this.current,
    this.next,
  });

  int? current;
  int? next;

  factory Levels.fromJson(Map<String, dynamic> json) => Levels(
        current: json["current"],
        next: json["next"],
      );

  Map<String, dynamic> toJson() => {
        "current": current,
        "next": next,
      };
}

class Timing {
  Timing({
    this.due,
    this.ts,
  });

  int? due;
  int? ts;

  factory Timing.fromJson(Map<String, dynamic> json) => Timing(
        due: json["due"],
        ts: json["ts"],
      );

  Map<String, dynamic> toJson() => {
        "due": due,
        "ts": ts,
      };
}
