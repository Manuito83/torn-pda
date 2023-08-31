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
        minLevel: json["minLevel"],
        maxLevel: json["maxLevel"],
        maxLife: json["maxLife"],
        battleStats: json["battleStats"],
        rank: json["rank"],
        optimalLevel: json["optimalLevel"],
        useOptimal: json["useOptimal"],
      );

  Map<String, dynamic> toJson() => {
        "minLevel": minLevel,
        "maxLevel": maxLevel,
        "maxLife": maxLife,
        "battleStats": battleStats,
        "rank": rank,
        "optimalLevel": optimalLevel,
        "useOptimal": useOptimal,
      };
}
