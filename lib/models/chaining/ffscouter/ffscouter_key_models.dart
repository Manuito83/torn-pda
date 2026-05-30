import 'dart:convert';

/// Response model for the FFScouter check-key endpoint.
/// `GET /api/v1/check-key?key=<key>`
class FFScouterCheckKeyResponse {
  final String? key;
  final bool isRegistered;
  final int? registeredAt;
  final int? lastUsed;

  /// Active premium (personal or faction)
  final bool isPremium;
  final int? premiumExpiresAt;
  final int? factionId;
  final int? factionPremiumExpiresAt;

  /// Where premium comes from
  final String? premiumEntitlementSource;

  FFScouterCheckKeyResponse({
    this.key,
    required this.isRegistered,
    this.registeredAt,
    this.lastUsed,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.factionId,
    this.factionPremiumExpiresAt,
    this.premiumEntitlementSource,
  });

  factory FFScouterCheckKeyResponse.fromJson(Map<String, dynamic> json) => FFScouterCheckKeyResponse(
    key: json["key"],
    isRegistered: json["is_registered"] ?? false,
    registeredAt: json["registered_at"],
    lastUsed: json["last_used"],
    isPremium: json["is_premium"] ?? false,
    premiumExpiresAt: json["premium_expires_at"],
    factionId: json["faction_id"],
    factionPremiumExpiresAt: json["faction_premium_expires_at"],
    premiumEntitlementSource: json["premium_entitlement_source"],
  );
}

FFScouterCheckKeyResponse ffScouterCheckKeyFromJson(String str) => FFScouterCheckKeyResponse.fromJson(json.decode(str));

/// Response model for the FFScouter register endpoint.
/// POST /api/v1/register
class FFScouterRegisterResponse {
  final bool success;
  final String? key;
  final String? message;

  FFScouterRegisterResponse({required this.success, this.key, this.message});

  factory FFScouterRegisterResponse.fromJson(Map<String, dynamic> json) =>
      FFScouterRegisterResponse(success: json["success"] ?? false, key: json["key"], message: json["message"]);
}

FFScouterRegisterResponse ffScouterRegisterFromJson(String str) => FFScouterRegisterResponse.fromJson(json.decode(str));
