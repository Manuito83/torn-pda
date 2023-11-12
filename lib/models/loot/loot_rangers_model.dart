// To parse this JSON data, do
//
//     final lootRangers = lootRangersFromJson(jsonString);

import 'dart:convert';

LootRangers lootRangersFromJson(String str) => LootRangers.fromJson(json.decode(str));

String lootRangersToJson(LootRangers data) => json.encode(data.toJson());

class LootRangers {
  Time? time;
  Map<String, Npc>? npcs;
  List<int>? order;

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
        "time": time!.toJson(),
        "npcs": Map.from(npcs!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "order": List<dynamic>.from(order!.map((x) => x)),
      };
}

class Npc {
  String? name;
  int? hospOut;
  bool? clear;

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
  int? clear;
  int? current;
  bool attack;
  String? reason;

  Time({
    this.clear,
    this.current,
    this.attack = false,
    this.reason,
  });

  factory Time.fromJson(Map<String, dynamic> json) => Time(
        clear: json["clear"],
        current: json["current"],
        attack: json["attack"],
        reason: json["reason"],
      );

  Map<String, dynamic> toJson() => {
        "clear": clear,
        "current": current,
        "attack": attack,
        "reason": reason,
      };
}

String lootRangersDebug = """
{
  "time": {
    "clear": 0,
    "current": 1699785000,
    "attack": false,
    "reason": "whatever"
  },
  "npcs": {
    "4": {
      "name": "Duke",
      "hosp_out": 1699775129,
      "clear": true,
      "life": {
        "current": 5500000,
        "max": 5500000
      }
    },
    "15": {
      "name": "Leslie",
      "hosp_out": 1699750978,
      "clear": true,
      "life": {
        "current": 4000000,
        "max": 4000000
      }
    },
    "19": {
      "name": "Jimmy",
      "hosp_out": 1699775140,
      "clear": true,
      "life": {
        "current": 2000000,
        "max": 2000000
      }
    },
    "20": {
      "name": "Fernando",
      "hosp_out": 1699774903,
      "clear": true,
      "life": {
        "current": 2500000,
        "max": 2500000
      }
    },
    "21": {
      "name": "Tiny",
      "hosp_out": 1699775721,
      "clear": true,
      "life": {
        "current": 4500000,
        "max": 4500000
      }
    }
  },
  "order": [
    20,
    21,
    4,
    19,
    15
  ]
}
""";
