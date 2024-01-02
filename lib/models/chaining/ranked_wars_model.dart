// To parse this JSON data, do
//
//     final rankedWarsModel = rankedWarsModelFromJson(jsonString);

import 'dart:convert';

RankedWarsModel rankedWarsModelFromJson(String str) => RankedWarsModel.fromJson(json.decode(str));

String rankedWarsModelToJson(RankedWarsModel data) => json.encode(data.toJson());

class RankedWarsModel {
  RankedWarsModel({
    this.rankedwars,
  });

  Map<String, RankedWar>? rankedwars;

  factory RankedWarsModel.fromJson(Map<String, dynamic> json) => RankedWarsModel(
        rankedwars: json["rankedwars"] == null
            ? null
            : json["rankedwars"].isEmpty
                ? <String, RankedWar>{}
                : Map.from(json["rankedwars"]).map((k, v) => MapEntry<String, RankedWar>(k, RankedWar.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "rankedwars":
            rankedwars == null ? null : Map.from(rankedwars!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class RankedWar {
  RankedWar({
    this.factions,
    this.war,
  });

  Map<String, WarFaction>? factions;
  War? war;

  factory RankedWar.fromJson(Map<String, dynamic> json) => RankedWar(
        factions: json["factions"] == null
            ? null
            : Map.from(json["factions"]).map((k, v) => MapEntry<String, WarFaction>(k, WarFaction.fromJson(v))),
        war: json["war"] == null ? null : War.fromJson(json["war"]),
      );

  Map<String, dynamic> toJson() => {
        "factions":
            factions == null ? null : Map.from(factions!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "war": war?.toJson(),
      };
}

class WarFaction {
  WarFaction({
    this.name,
    this.score,
    this.chain,
  });

  String? name;
  int? score;
  int? chain;

  factory WarFaction.fromJson(Map<String, dynamic> json) => WarFaction(
        name: json["name"],
        score: json["score"],
        chain: json["chain"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "score": score,
        "chain": chain,
      };
}

class War {
  War({
    this.start,
    this.end,
    this.target,
    this.winner,
  });

  int? start;
  int? end;
  int? target;
  int? winner;

  factory War.fromJson(Map<String, dynamic> json) => War(
        start: json["start"],
        end: json["end"],
        target: json["target"],
        winner: json["winner"],
      );

  Map<String, dynamic> toJson() => {
        "start": start,
        "end": end,
        "target": target,
        "winner": winner,
      };
}
