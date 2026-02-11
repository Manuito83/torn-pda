import 'dart:convert';

List<FFScouterPlayerStats> ffScouterStatsFromJson(String str) =>
    List<FFScouterPlayerStats>.from(json.decode(str).map((x) => FFScouterPlayerStats.fromJson(x)));

class FFScouterPlayerStats {
  int? playerId;
  double? fairFight;
  int? bsEstimate;
  String? bsEstimateHuman;
  int? lastUpdated;

  FFScouterPlayerStats({
    this.playerId,
    this.fairFight,
    this.bsEstimate,
    this.bsEstimateHuman,
    this.lastUpdated,
  });

  factory FFScouterPlayerStats.fromJson(Map<String, dynamic> json) => FFScouterPlayerStats(
        playerId: json["player_id"],
        fairFight: json["fair_fight"]?.toDouble(),
        bsEstimate: json["bs_estimate"],
        bsEstimateHuman: json["bs_estimate_human"],
        lastUpdated: json["last_updated"],
      );

  Map<String, dynamic> toJson() => {
        "player_id": playerId,
        "fair_fight": fairFight,
        "bs_estimate": bsEstimate,
        "bs_estimate_human": bsEstimateHuman,
        "last_updated": lastUpdated,
      };
}

class FFScouterErrorResponse {
  int? code;
  String? error;

  FFScouterErrorResponse({this.code, this.error});

  factory FFScouterErrorResponse.fromJson(Map<String, dynamic> json) => FFScouterErrorResponse(
        code: json["code"],
        error: json["error"],
      );
}
