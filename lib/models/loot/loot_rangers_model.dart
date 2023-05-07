// To parse this JSON data, do
//
//     final lootRangers = lootRangersFromJson(jsonString);

import 'dart:convert';

LootRangers lootRangersFromJson(String str) => LootRangers.fromJson(json.decode(str));

String lootRangersToJson(LootRangers data) => json.encode(data.toJson());

class LootRangers {
  Time time;
  Map<String, Npc> npcs;
  List<int> order;

  LootRangers({
    this.time,
    this.npcs,
    this.order,
  });

  factory LootRangers.fromJson(Map<String, dynamic> json) => LootRangers(
        time: Time.fromJson(json["time"]),
        npcs: Map.from(json["npcs"]).map((k, v) => MapEntry<String, Npc>(k, Npc.fromJson(v))),
        order: List<int>.from(json["order"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "time": time.toJson(),
        "npcs": Map.from(npcs).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "order": List<dynamic>.from(order.map((x) => x)),
      };
}

class Npc {
  String name;
  int hospOut;
  bool clear;

  Npc({
    this.name,
    this.hospOut,
    this.clear,
  });

  factory Npc.fromJson(Map<String, dynamic> json) => Npc(
        name: json["name"],
        hospOut: json["hosp_out"],
        clear: json["clear"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "hosp_out": hospOut,
        "clear": clear,
      };
}

class Time {
  int clear;
  int current;

  Time({
    this.clear,
    this.current,
  });

  factory Time.fromJson(Map<String, dynamic> json) => Time(
        clear: json["clear"],
        current: json["current"],
      );

  Map<String, dynamic> toJson() => {
        "clear": clear,
        "current": current,
      };
}
