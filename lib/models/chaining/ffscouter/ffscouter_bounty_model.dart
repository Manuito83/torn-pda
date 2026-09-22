List<Map<String, dynamic>> _maps(dynamic list) =>
    list is List ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : const [];

Map<String, dynamic> _map(dynamic value) => value is Map ? value.cast<String, dynamic>() : const {};

class FFScouterBountyTier {
  final int pricePerHit;
  final int remaining;

  FFScouterBountyTier({required this.pricePerHit, required this.remaining});

  factory FFScouterBountyTier.fromJson(Map<String, dynamic> json) =>
      FFScouterBountyTier(pricePerHit: json["price_per_hit"] ?? 0, remaining: json["quantity_remaining"] ?? 0);
}

class FFScouterBountyTarget {
  final int targetId;
  final String targetName;
  final int? estimate;
  final List<FFScouterBountyTier> tiers;
  final int maxPricePerHit;
  final int totalRemaining;
  final bool disabled;
  final String? disabledReason;

  FFScouterBountyTarget({
    required this.targetId,
    required this.targetName,
    this.estimate,
    required this.tiers,
    required this.maxPricePerHit,
    required this.totalRemaining,
    required this.disabled,
    this.disabledReason,
  });

  factory FFScouterBountyTarget.fromJson(Map<String, dynamic> json) => FFScouterBountyTarget(
    targetId: json["target_player_id"] ?? 0,
    targetName: json["target_name"] ?? "",
    estimate: json["estimate_available"] == true ? json["estimate"] : null,
    tiers: _maps(json["tiers"]).map(FFScouterBountyTier.fromJson).toList(),
    maxPricePerHit: json["max_price_per_hit"] ?? 0,
    totalRemaining: json["total_remaining"] ?? 0,
    disabled: json["disabled"] ?? false,
    disabledReason: json["disabled_reason"],
  );
}

class FFScouterBountyClaim {
  final String targetName;
  final int successfulChecks;
  final int requiredChecks;
  final String? lastFailureReason;
  final int creditedHits;

  FFScouterBountyClaim({
    required this.targetName,
    required this.successfulChecks,
    required this.requiredChecks,
    this.lastFailureReason,
    required this.creditedHits,
  });

  factory FFScouterBountyClaim.fromJson(Map<String, dynamic> json) => FFScouterBountyClaim(
    targetName: json["target_name"] ?? "",
    successfulChecks: json["successful_checks"] ?? 0,
    requiredChecks: json["required_checks"] ?? 0,
    lastFailureReason: json["last_failure_reason"],
    creditedHits: json["credited_hits"] ?? 0,
  );
}

class FFScouterBountyHit {
  final String targetName;
  final int reward;
  final String payoutStatus;

  FFScouterBountyHit({required this.targetName, required this.reward, required this.payoutStatus});

  factory FFScouterBountyHit.fromJson(Map<String, dynamic> json) => FFScouterBountyHit(
    targetName: json["target_name"] ?? "",
    reward: json["reward_amount"] ?? 0,
    payoutStatus: json["payout_status"] ?? "",
  );
}

class FFScouterBountyClaims {
  final List<FFScouterBountyClaim> pending;
  final List<FFScouterBountyHit> recentHits;

  FFScouterBountyClaims({required this.pending, required this.recentHits});

  factory FFScouterBountyClaims.fromJson(Map<String, dynamic> json) => FFScouterBountyClaims(
    pending: _maps(json["pending_claims"]).map(FFScouterBountyClaim.fromJson).toList(),
    recentHits: _maps(json["recent_hits"]).map(FFScouterBountyHit.fromJson).toList(),
  );
}

class FFScouterBountyBoard {
  final List<FFScouterBountyTarget> targets;
  final FFScouterBountyClaims claims;

  FFScouterBountyBoard({required this.targets, required this.claims});

  factory FFScouterBountyBoard.fromJson(Map<String, dynamic> json) => FFScouterBountyBoard(
    targets: _maps(_map(json["board"])["targets"]).map(FFScouterBountyTarget.fromJson).toList(),
    claims: FFScouterBountyClaims.fromJson(_map(json["claims"])),
  );
}

class FFScouterBountyQuote {
  final int subtotal;
  final int feeAmount;
  final double feePercent;
  final int totalPayable;
  final int expectedXanax;

  FFScouterBountyQuote({
    required this.subtotal,
    required this.feeAmount,
    required this.feePercent,
    required this.totalPayable,
    required this.expectedXanax,
  });

  factory FFScouterBountyQuote.fromJson(Map<String, dynamic> json) {
    final quote = _map(json["quote"]);
    return FFScouterBountyQuote(
      subtotal: quote["subtotal"] ?? 0,
      feeAmount: quote["fee_amount"] ?? 0,
      feePercent: (quote["fee_percent"] as num?)?.toDouble() ?? 0,
      totalPayable: quote["total_payable"] ?? 0,
      expectedXanax: quote["expected_xanax_quantity"] ?? 0,
    );
  }
}

class FFScouterBountyPayment {
  final String message;
  final int xanaxExpected;
  final int xanaxReceived;
  final int? deadline;

  FFScouterBountyPayment({
    required this.message,
    required this.xanaxExpected,
    required this.xanaxReceived,
    this.deadline,
  });

  factory FFScouterBountyPayment.fromJson(Map<String, dynamic> json) => FFScouterBountyPayment(
    message: json["message"] ?? "",
    xanaxExpected: json["xanax_expected"] ?? 0,
    xanaxReceived: json["xanax_received"] ?? 0,
    deadline: json["payment_deadline_at"],
  );
}

class FFScouterBountyNewOrder {
  final String reference;
  final String statusToken;
  final String statusUrl;
  final FFScouterBountyPayment payment;

  FFScouterBountyNewOrder({
    required this.reference,
    required this.statusToken,
    required this.statusUrl,
    required this.payment,
  });

  factory FFScouterBountyNewOrder.fromJson(Map<String, dynamic> json) {
    final order = _map(json["order"]);
    return FFScouterBountyNewOrder(
      reference: order["reference"] ?? "",
      statusToken: order["status_token"]?.toString() ?? "",
      statusUrl: order["status_url"] ?? "",
      payment: FFScouterBountyPayment.fromJson(_map(order["payment_instructions"])),
    );
  }
}

class FFScouterBountyOrderStatus {
  final String state;
  final String targetName;
  final int quantity;
  final int quantityCredited;
  final FFScouterBountyPayment payment;

  FFScouterBountyOrderStatus({
    required this.state,
    required this.targetName,
    required this.quantity,
    required this.quantityCredited,
    required this.payment,
  });

  factory FFScouterBountyOrderStatus.fromJson(Map<String, dynamic> json) {
    final order = _map(json["order"]);
    return FFScouterBountyOrderStatus(
      state: order["state"] ?? "",
      targetName: order["target_name"] ?? "",
      quantity: order["quantity"] ?? 0,
      quantityCredited: order["quantity_credited"] ?? 0,
      payment: FFScouterBountyPayment.fromJson(_map(json["payment_instructions"])),
    );
  }
}
