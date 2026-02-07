/// Cached FFScouter battle score entry for a single player.
/// Stored locally with a timestamp so we can enforce a 24h TTL.
class FFScouterCacheEntry {
  int playerId;
  int? bsEstimate;
  String? bsEstimateHuman;
  double? fairFight;
  int? lastUpdatedByFFScouter; // epoch seconds from FFScouter API
  int cachedAt; // epoch seconds when we stored this locally

  FFScouterCacheEntry({
    required this.playerId,
    this.bsEstimate,
    this.bsEstimateHuman,
    this.fairFight,
    this.lastUpdatedByFFScouter,
    required this.cachedAt,
  });

  factory FFScouterCacheEntry.fromJson(Map<String, dynamic> json) => FFScouterCacheEntry(
        playerId: json["player_id"] ?? 0,
        bsEstimate: json["bs_estimate"],
        bsEstimateHuman: json["bs_estimate_human"],
        fairFight: json["fair_fight"]?.toDouble(),
        lastUpdatedByFFScouter: json["last_updated_by_ffscouter"],
        cachedAt: json["cached_at"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "player_id": playerId,
        "bs_estimate": bsEstimate,
        "bs_estimate_human": bsEstimateHuman,
        "fair_fight": fairFight,
        "last_updated_by_ffscouter": lastUpdatedByFFScouter,
        "cached_at": cachedAt,
      };

  /// Whether this cache entry is still fresh (less than 24 hours old)
  bool get isFresh {
    final age = DateTime.now().millisecondsSinceEpoch ~/ 1000 - cachedAt;
    return age < 86400; // 24 hours
  }

  /// Human-readable display string for the battle score
  String get displayText {
    if (bsEstimateHuman != null && bsEstimateHuman!.isNotEmpty) return bsEstimateHuman!;
    if (bsEstimate != null) return _formatBigNumber(bsEstimate!);
    return "N/A";
  }

  static String _formatBigNumber(int n) {
    if (n >= 1000000000) return "${(n / 1000000000).toStringAsFixed(1)}B";
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}k";
    return n.toString();
  }
}
