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

  List<FFScouterSpy> spies;
  FFScouterEstimate? bssEstimate;
  FFScouterEstimate? premiumEstimate;
  FFScouterEstimate? spyEstimate;

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
    this.spies = const [],
    this.bssEstimate,
    this.premiumEstimate,
    this.spyEstimate,
  });

  factory FFScouterPlayerStats.fromJson(Map<String, dynamic> json) {
    final estimates = json["available_estimates"] is Map ? json["available_estimates"] as Map : const {};
    return FFScouterPlayerStats(
      playerId: json["player_id"],
      fairFight: json["fair_fight"]?.toDouble(),
      bsEstimate: json["bs_estimate"],
      bsEstimateHuman: json["bs_estimate_human"],
      lastUpdated: json["last_updated"],
      bssPublic: json["bss_public"],
      source: json["source"],
      premiumInsightsAvailable: json["premium_insights_available"] ?? false,
      distribution: json["distribution"] != null ? FFScouterDistribution.fromJson(json["distribution"]) : null,
      spies: json["spies"] is List
          ? (json["spies"] as List).whereType<Map>().map((e) => FFScouterSpy.fromJson(e.cast())).toList()
          : const [],
      bssEstimate: FFScouterEstimate.tryParse(estimates["bss"], "bss"),
      premiumEstimate: FFScouterEstimate.tryParse(estimates["premium"], "premium"),
      spyEstimate: FFScouterEstimate.tryParse(estimates["spies"], "spies"),
    );
  }

  List<FFScouterEstimate> get availableEstimates =>
      [premiumEstimate, bssEstimate, spyEstimate].whereType<FFScouterEstimate>().toList();

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

class FFScouterEstimate {
  final String kind;
  final int? bsEstimate;
  final String? bsEstimateHuman;
  final int? lastUpdated;
  final double? fairFight;
  final String? source;

  FFScouterEstimate({
    required this.kind,
    this.bsEstimate,
    this.bsEstimateHuman,
    this.lastUpdated,
    this.fairFight,
    this.source,
  });

  static FFScouterEstimate? tryParse(dynamic json, String kind) {
    if (json is! Map) return null;
    return FFScouterEstimate(
      kind: kind,
      bsEstimate: json["bs_estimate"],
      bsEstimateHuman: json["bs_estimate_human"],
      lastUpdated: json["last_updated"],
      fairFight: (json["fair_fight"] as num?)?.toDouble(),
      source: json["source"],
    );
  }
}

class FFScouterSpy {
  final int? strength;
  final int? speed;
  final int? defense;
  final int? dexterity;
  final int? total;
  final int? lastUpdated;
  final String? source;
  final int? sourceFactionId;

  FFScouterSpy({
    this.strength,
    this.speed,
    this.defense,
    this.dexterity,
    this.total,
    this.lastUpdated,
    this.source,
    this.sourceFactionId,
  });

  factory FFScouterSpy.fromJson(Map<String, dynamic> json) => FFScouterSpy(
    strength: json["strength"],
    speed: json["speed"],
    defense: json["defense"],
    dexterity: json["dexterity"],
    total: json["total"],
    lastUpdated: json["last_updated"],
    source: json["source"],
    sourceFactionId: json["source_faction_id"],
  );
}

class FFScouterErrorResponse {
  int? code;
  String? error;
  String? source;
  int? tornCode;
  int? retryAfterSeconds;

  FFScouterErrorResponse({this.code, this.error, this.source, this.tornCode, this.retryAfterSeconds});

  factory FFScouterErrorResponse.fromJson(Map<String, dynamic> json) => FFScouterErrorResponse(
    code: json["code"],
    error: json["error"],
    source: json["source"],
    tornCode: json["torn_code"],
    retryAfterSeconds: json["retry_after_seconds"],
  );

  String get displayMessage {
    final message = error ?? "Unknown error";
    if (source == "torn" && tornCode != null) return "$message (Torn API error $tornCode)";
    return message;
  }
}

class FFScouterStatsHistory {
  final int? playerId;
  final List<FFScouterStatsHistoryPoint> points;

  FFScouterStatsHistory({this.playerId, required this.points});

  factory FFScouterStatsHistory.fromJson(Map<String, dynamic> json) {
    final points = json["history"] is List
        ? (json["history"] as List)
              .whereType<Map>()
              .map((e) => FFScouterStatsHistoryPoint.fromJson(e.cast()))
              .where((p) => p.bsEstimate != null && p.bsEstimate! > 0)
              .toList()
        : <FFScouterStatsHistoryPoint>[];
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return FFScouterStatsHistory(playerId: json["player_id"], points: points);
  }
}

class FFScouterStatsHistoryPoint {
  final int timestamp;
  final int? bsEstimate;
  final String? bsEstimateHuman;

  FFScouterStatsHistoryPoint({required this.timestamp, this.bsEstimate, this.bsEstimateHuman});

  factory FFScouterStatsHistoryPoint.fromJson(Map<String, dynamic> json) => FFScouterStatsHistoryPoint(
    timestamp: json["timestamp"] ?? 0,
    bsEstimate: json["bs_estimate"],
    bsEstimateHuman: json["bs_estimate_human"],
  );
}
