class FFScouterHitClaim {
  final String claimId;
  final int createdAt;
  final int expiresAt;
  final int? claimerId;
  final String? claimerName;
  final int targetId;

  FFScouterHitClaim({
    required this.claimId,
    required this.createdAt,
    required this.expiresAt,
    this.claimerId,
    this.claimerName,
    required this.targetId,
  });

  factory FFScouterHitClaim.fromJson(Map<String, dynamic> json, {int fallbackTargetId = 0}) {
    final claimer = json["claimer"] is Map ? json["claimer"] as Map : const {};
    final target = json["target"] is Map ? json["target"] as Map : const {};
    return FFScouterHitClaim(
      claimId: json["claim_id"]?.toString() ?? "",
      createdAt: json["created_at"] ?? 0,
      expiresAt: json["expires_at"] ?? 0,
      claimerId: claimer["player_id"],
      claimerName: claimer["name"],
      targetId: target["player_id"] ?? fallbackTargetId,
    );
  }
}

class FFScouterHitClaims {
  final int ttlSeconds;
  final List<FFScouterHitClaim> claims;

  FFScouterHitClaims({required this.ttlSeconds, required this.claims});

  // "faction" comes as a map of arrays, or as [] when empty
  factory FFScouterHitClaims.fromJson(Map<String, dynamic> json) {
    final claims = <FFScouterHitClaim>[];
    final root = json["claims"] is Map ? json["claims"] as Map : const {};
    final faction = root["faction"];
    final groups = faction is Map ? faction.values : (faction is List ? [faction] : const []);
    for (final group in groups) {
      if (group is List) {
        claims.addAll(group.whereType<Map>().map((e) => FFScouterHitClaim.fromJson(e.cast())));
      } else if (group is Map) {
        claims.add(FFScouterHitClaim.fromJson(group.cast()));
      }
    }
    return FFScouterHitClaims(ttlSeconds: _ttl(json), claims: claims);
  }

  static int _ttl(Map<String, dynamic> json) {
    final configuration = json["configuration"] is Map ? json["configuration"] as Map : const {};
    return configuration["claim_ttl_seconds"] ?? 900;
  }
}

class FFScouterHitClaimResult {
  final int ttlSeconds;
  final FFScouterHitClaim? claim;
  final List<FFScouterHitClaim> otherClaims;

  FFScouterHitClaimResult({required this.ttlSeconds, this.claim, this.otherClaims = const []});

  factory FFScouterHitClaimResult.fromJson(Map<String, dynamic> json) {
    final claim = json["claim"] is Map ? FFScouterHitClaim.fromJson((json["claim"] as Map).cast()) : null;
    return FFScouterHitClaimResult(
      ttlSeconds: FFScouterHitClaims._ttl(json),
      claim: claim,
      otherClaims: json["other_claims_for_target"] is List
          ? (json["other_claims_for_target"] as List)
                .whereType<Map>()
                .map((e) => FFScouterHitClaim.fromJson(e.cast(), fallbackTargetId: claim?.targetId ?? 0))
                .toList()
          : const [],
    );
  }
}
