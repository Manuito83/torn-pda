// To parse this JSON data, do
//
//     final tacFilters = tacFiltersFromJson(jsonString);

// Dart imports:
import 'dart:convert';

TacFilters tacFiltersFromJson(String str) => TacFilters.fromJson(json.decode(str));

String tacFiltersToJson(TacFilters data) => json.encode(data.toJson());

class TacFilters {
  TacFilters({
    this.minLevel = 20,
    this.maxLevel = 80,
    this.maxLife = 3000,
    this.battleStats = 3,
    this.rank = 12,
    this.optimalLevel = 3,
    this.useOptimal = false,
  });

  int minLevel;
  int maxLevel;
  int maxLife;
  int battleStats;
  int rank;
  int optimalLevel;
  bool useOptimal;

  factory TacFilters.fromJson(Map<String, dynamic> json) => TacFilters(
    minLevel: json["minLevel"] == null ? null : json["minLevel"],
    maxLevel: json["maxLevel"] == null ? null : json["maxLevel"],
    maxLife: json["maxLife"] == null ? null : json["maxLife"],
    battleStats: json["battleStats"] == null ? null : json["battleStats"],
    rank: json["rank"] == null ? null : json["rank"],
    optimalLevel: json["optimalLevel"] == null ? null : json["optimalLevel"],
    useOptimal: json["useOptimal"] == null ? null : json["useOptimal"],
  );

  Map<String, dynamic> toJson() => {
    "minLevel": minLevel == null ? null : minLevel,
    "maxLevel": maxLevel == null ? null : maxLevel,
    "maxLife": maxLife == null ? null : maxLife,
    "battleStats": battleStats == null ? null : battleStats,
    "rank": rank == null ? null : rank,
    "optimalLevel": optimalLevel == null ? null : optimalLevel,
    "useOptimal": useOptimal == null ? null : useOptimal,
  };

}
