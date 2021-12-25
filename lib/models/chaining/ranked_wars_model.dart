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

  Map<String, RankedWar> rankedwars;

  factory RankedWarsModel.fromJson(Map<String, dynamic> json) => RankedWarsModel(
        rankedwars: json["rankedwars"] == null
            ? null
            : Map.from(json["rankedwars"]).map((k, v) => MapEntry<String, RankedWar>(k, RankedWar.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "rankedwars":
            rankedwars == null ? null : Map.from(rankedwars).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class RankedWar {
  RankedWar({
    this.factions,
    this.war,
  });

  Map<String, Faction> factions;
  War war;

  factory RankedWar.fromJson(Map<String, dynamic> json) => RankedWar(
        factions: json["factions"] == null
            ? null
            : Map.from(json["factions"]).map((k, v) => MapEntry<String, Faction>(k, Faction.fromJson(v))),
        war: json["war"] == null ? null : War.fromJson(json["war"]),
      );

  Map<String, dynamic> toJson() => {
        "factions":
            factions == null ? null : Map.from(factions).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "war": war == null ? null : war.toJson(),
      };
}

class Faction {
  Faction({
    this.name,
    this.score,
    this.chain,
  });

  String name;
  int score;
  int chain;

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
        name: json["name"] == null ? null : json["name"],
        score: json["score"] == null ? null : json["score"],
        chain: json["chain"] == null ? null : json["chain"],
      );

  Map<String, dynamic> toJson() => {
        "name": name == null ? null : name,
        "score": score == null ? null : score,
        "chain": chain == null ? null : chain,
      };
}

class War {
  War({
    this.start,
    this.end,
    this.target,
    this.winner,
  });

  int start;
  int end;
  int target;
  int winner;

  factory War.fromJson(Map<String, dynamic> json) => War(
        start: json["start"] == null ? null : json["start"],
        end: json["end"] == null ? null : json["end"],
        target: json["target"] == null ? null : json["target"],
        winner: json["winner"] == null ? null : json["winner"],
      );

  Map<String, dynamic> toJson() => {
        "start": start == null ? null : start,
        "end": end == null ? null : end,
        "target": target == null ? null : target,
        "winner": winner == null ? null : winner,
      };
}
