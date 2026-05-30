import 'dart:convert';

List<FFScouterPlayerStats> ffScouterStatsFromJson(String str) =>
    List<FFScouterPlayerStats>.from(json.decode(str).map((x) => FFScouterPlayerStats.fromJson(x)));

class FFScouterPlayerStats {
  int? playerId;
  double? fairFight;
  int? bsEstimate;
  String? bsEstimateHuman;
  int? lastUpdated;

  /// Public battle-stat score (free tier)
  int? bssPublic;

  /// "bss" for public data, "premium" when premium overrides apply
  String? source;

  /// Teaser: premium insights exist (shown to non-premium too)
  bool premiumInsightsAvailable;

  /// Premium-only stat distribution
  FFScouterDistribution? distribution;

  FFScouterPlayerStats({
    this.playerId,
    this.fairFight,
    this.bsEstimate,
    this.bsEstimateHuman,
    this.lastUpdated,
    this.bssPublic,
    this.source,
    this.premiumInsightsAvailable = false,
    this.distribution,
  });

  factory FFScouterPlayerStats.fromJson(Map<String, dynamic> json) => FFScouterPlayerStats(
    playerId: json["player_id"],
    fairFight: json["fair_fight"]?.toDouble(),
    bsEstimate: json["bs_estimate"],
    bsEstimateHuman: json["bs_estimate_human"],
    lastUpdated: json["last_updated"],
    bssPublic: json["bss_public"],
    source: json["source"],
    premiumInsightsAvailable: json["premium_insights_available"] ?? false,
    distribution: json["distribution"] != null ? FFScouterDistribution.fromJson(json["distribution"]) : null,
  );

  /// Premium-only payload, so the caller's key is premium
  bool get provesPremium => source == "premium" || distribution != null;

  Map<String, dynamic> toJson() => {
    "player_id": playerId,
    "fair_fight": fairFight,
    "bs_estimate": bsEstimate,
    "bs_estimate_human": bsEstimateHuman,
    "last_updated": lastUpdated,
    "bss_public": bssPublic,
    "source": source,
    "premium_insights_available": premiumInsightsAvailable,
    "distribution": distribution?.toJson(),
  };
}

/// Premium-only stat distribution for a target
class FFScouterDistribution {
  final int? lastUpdated;

  /// Human-readable summary, e.g. "STR (60%) SPD (30%)"
  final String? distributionHuman;

  /// Per-stat percentages by name. A map so new stats need no model change
  final Map<String, int>? statsPercentage;

  FFScouterDistribution({this.lastUpdated, this.distributionHuman, this.statsPercentage});

  factory FFScouterDistribution.fromJson(Map<String, dynamic> json) {
    Map<String, int>? perc;
    final raw = json["stats_percentage"];
    if (raw is Map) {
      perc = {};
      raw.forEach((k, v) {
        if (v is num) perc![k.toString()] = v.round();
      });
      if (perc.isEmpty) perc = null;
    }
    return FFScouterDistribution(
      lastUpdated: json["last_updated"],
      distributionHuman: json["distribution_human"],
      statsPercentage: perc,
    );
  }

  bool get hasData =>
      (distributionHuman != null && distributionHuman!.isNotEmpty) ||
      (statsPercentage != null && statsPercentage!.isNotEmpty);

  Map<String, dynamic> toJson() => {
    "last_updated": lastUpdated,
    "distribution_human": distributionHuman,
    "stats_percentage": statsPercentage,
  };
}

class FFScouterErrorResponse {
  int? code;
  String? error;

  FFScouterErrorResponse({this.code, this.error});

  factory FFScouterErrorResponse.fromJson(Map<String, dynamic> json) =>
      FFScouterErrorResponse(code: json["code"], error: json["error"]);
}
