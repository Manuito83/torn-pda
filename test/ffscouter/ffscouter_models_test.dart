import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_bounty_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_flights_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_hit_calling_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_key_models.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_notes_model.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_stats_model.dart';

/// Payloads are the examples of the FFScouter OpenAPI spec 1.7.0 (ffscouter.com/openapi/spec.yaml),
/// plus the empty shapes the live API returned when it was checked

Map<String, dynamic> _json(String raw) => json.decode(raw) as Map<String, dynamic>;

void main() {
  group('get-stats', () {
    test('reads spies and the estimate of every source', () {
      final stats = ffScouterStatsFromJson('''[{
        "player_id": 267456763, "fair_fight": 5.39, "bs_estimate": 2989885521, "bs_estimate_human": "2.99b",
        "bss_public": 123456, "last_updated": 1747333361, "source": "premium", "premium_insights_available": true,
        "distribution": {"last_updated": 1747333361, "distribution_human": "STR (60%) SPD (30%)",
          "stats_percentage": {"strength": 60, "speed": 30}},
        "spies": [{"strength": 1000000, "speed": 2000000, "defense": 3000000, "dexterity": 4000000,
          "total": 10000000000, "last_updated": 1747330000, "source": "tornstats", "source_faction_id": 12345}],
        "available_estimates": {
          "bss": {"bss_public": 123456, "bs_estimate": 2989885521, "bs_estimate_human": "2.99b",
            "last_updated": 1747333361, "fair_fight": 5.39},
          "premium": {"bs_estimate": 3100000000, "bs_estimate_human": "3.1b", "last_updated": 1747330000,
            "fair_fight": 6.12},
          "spies": {"bs_estimate": 10000000000, "bs_estimate_human": "10b", "last_updated": 1747330000,
            "source": "tornstats", "fair_fight": 8.45}}
      }]''').single;

      expect(stats.spies.single.total, 10000000000);
      expect(stats.spies.single.sourceFactionId, 12345);
      expect(stats.availableEstimates.map((e) => e.kind), ['premium', 'bss', 'spies']);
      expect(stats.premiumEstimate!.fairFight, 6.12);
      expect(stats.spyEstimate!.source, 'tornstats');
      expect(stats.provesPremium, isTrue);
    });

    test('a player without data has no estimates nor spies', () {
      final stats = ffScouterStatsFromJson('''[{
        "player_id": 142625381, "fair_fight": null, "bs_estimate": null, "bs_estimate_human": null,
        "bss_public": null, "last_updated": null, "source": "bss", "distribution": null,
        "premium_insights_available": false, "spies": [],
        "available_estimates": {"bss": null, "premium": null, "spies": null}
      }]''').single;

      expect(stats.spies, isEmpty);
      expect(stats.availableEstimates, isEmpty);
    });
  });

  test('errors say when Torn is the one failing', () {
    final ffscouter = FFScouterErrorResponse.fromJson(
      _json('{"code": 21, "error": "Rate limit exceeded. Please retry shortly.", "retry_after_seconds": 12}'),
    );
    expect(ffscouter.retryAfterSeconds, 12);
    expect(ffscouter.displayMessage, 'Rate limit exceeded. Please retry shortly.');

    final torn = FFScouterErrorResponse.fromJson(
      _json('{"code": 88, "error": "Could not validate your key", "source": "torn", "torn_code": 2}'),
    );
    expect(torn.displayMessage, 'Could not validate your key (Torn API error 2)');
  });

  test('check-key reads the data policy flag', () {
    final key = FFScouterCheckKeyResponse.fromJson(
      _json('''{"key": "EXAMPLEKEY000000", "is_registered": true, "registered_at": 1640995200,
        "last_used": 1747333361, "policy_version": 2, "policy_update_required": true, "is_premium": true,
        "premium_expires_at": 1740000000, "faction_id": null, "faction_premium_expires_at": null,
        "premium_entitlement_source": "personal", "elimination_team": "Conspiracy Theorists"}'''),
    );
    expect(key.policyUpdateRequired, isTrue);
    expect(key.isPremium, isTrue);
  });

  test('flights batch keeps players that are not flying', () {
    final flights = ffScouterFlightsBatchFromJson(
      _json('''{"flights": [
        {"player_id": 1844049, "current": {"takeoff_time": 1710000000, "status_description": "Traveling to Japan",
          "earliest_arrival_time": 1710007200, "latest_arrival_time": 1710010800, "travel_method": "Airline",
          "book_likely_being_used": true}},
        {"player_id": 2675763, "current": null}]}'''),
    );
    expect(flights.length, 2);
    expect(flights.first.current!.estimatedArrival, 1710009000);
    expect(flights.last.hasCurrentFlight, isFalse);
  });

  test('stats history drops empty points and sorts by date', () {
    final history = FFScouterStatsHistory.fromJson(
      _json('''{"player_id": 1844049, "bucket_window_seconds": 21600, "history": [
        {"timestamp": 1769292000, "bss_public": 87438, "bs_estimate": 1987805000, "bs_estimate_human": "1.99b",
          "source": "bss"},
        {"timestamp": 1769000000, "bss_public": null, "bs_estimate": null, "bs_estimate_human": null,
          "source": "bss"},
        {"timestamp": 1768000000, "bss_public": 80000, "bs_estimate": 1500000000, "bs_estimate_human": "1.5b",
          "source": "bss"}]}'''),
    );
    expect(history.points.map((p) => p.timestamp), [1768000000, 1769292000]);
  });

  group('notes', () {
    test('list with pagination', () {
      final page = FFScouterNotesPage.fromJson(
        _json('''{"notes": [{"uuid": "4c3f0f6e-8b3a-4f0e-9a4e-2f4b6c8d0e12", "scope": "faction",
          "target_type": "player", "target_id": 1844049, "content": "Watch for war activity on weekends.",
          "created_at": 1769295473, "deleted_at": null, "author_player_id": 2675763, "author_name": "Someone",
          "can_soft_delete": true, "can_purge": false}],
          "pagination": {"page": 1, "limit": 100, "total": 1, "total_pages": 1}}'''),
      );
      final note = page.notes.single;
      expect(page.totalPages, 1);
      expect(note.isFaction, isTrue);
      expect(note.targetId, 1844049);
      expect(note.authorName, 'Someone');
      expect(note.canSoftDelete, isTrue);
    });

    test('info with and without faction', () {
      final withFaction = FFScouterNotesInfo.fromJson(
        _json('''{"personal": {"used": 12, "limit": 200, "is_premium": false},
          "faction": {"faction_id": 41484, "viewer_role": "member", "post_permission": 1, "can_post": false,
            "can_delete": false, "can_purge": false, "used": 5, "limit": 50000}}'''),
      );
      expect(withFaction.personalLimit, 200);
      expect(withFaction.inFaction, isTrue);
      expect(withFaction.canPostFaction, isFalse);

      final alone = FFScouterNotesInfo.fromJson(
        _json('{"personal": {"used": 0, "limit": 10000, "is_premium": true}, "faction": null}'),
      );
      expect(alone.inFaction, isFalse);
    });
  });

  group('hit calling', () {
    test('claims come grouped by target', () {
      final claims = FFScouterHitClaims.fromJson(
        _json('''{"configuration": {"claim_ttl_seconds": 900}, "claims": {"faction": {"555111": [
          {"claim_id": "a0f2e8a3-39f1-4a4f-88d0-7fdf8bde4b37", "created_at": 1770000000, "expires_at": 1770000900,
            "claimer": {"player_id": 100001, "name": "Alpha"},
            "target": {"player_id": 555111, "name": "Target One"}}]}}}'''),
      );
      expect(claims.ttlSeconds, 900);
      expect(claims.claims.single.targetId, 555111);
      expect(claims.claims.single.claimerName, 'Alpha');
    });

    test('no claims come as an empty list', () {
      final claims = FFScouterHitClaims.fromJson(
        _json('{"configuration": {"claim_ttl_seconds": 900}, "claims": {"faction": []}}'),
      );
      expect(claims.claims, isEmpty);
    });

    test('other claims of a new claim get its target', () {
      final result = FFScouterHitClaimResult.fromJson(
        _json('''{"configuration": {"claim_ttl_seconds": 900},
          "claim": {"claim_id": "2f84b4fb", "created_at": 1770000030, "expires_at": 1770000930,
            "claimer": {"player_id": 100003, "name": "Charlie"}, "target": {"player_id": 555111, "name": "Target One"}},
          "position": 2,
          "other_claims_for_target": [{"claim_id": "a0f2e8a3", "position": 1, "created_at": 1770000000,
            "expires_at": 1770000900, "claimer": {"player_id": 100001, "name": "Alpha"}}]}'''),
      );
      expect(result.claim!.claimerId, 100003);
      expect(result.otherClaims.single.targetId, 555111);
    });
  });

  group('bounty board', () {
    test('board with targets, tiers and the seller claims', () {
      final board = FFScouterBountyBoard.fromJson(
        _json('''{"board": {"targets": [{"target_player_id": 267456763, "target_name": "Arcanine",
          "estimate": 2989885521, "estimate_available": true,
          "tiers": [{"price_per_hit": 700000, "quantity_remaining": 3}, {"price_per_hit": 500000, "quantity_remaining": 6}],
          "max_price_per_hit": 700000, "total_remaining": 9, "first_activated_at": 1769997200, "updated_at": 1770001200,
          "disabled": false, "disabled_reason": null}],
          "seller": {"player_id": 3003, "estimate": 1500000000}, "generated_at": 1770001400},
          "claims": {"pending_claims": [{"claim_id": 42, "target_player_id": 267456763, "target_name": "Arcanine",
            "state": "verifying", "successful_checks": 2, "required_checks": 5, "failed_attempts": 0,
            "last_failure_reason": null, "credited_hits": 0, "created_at": 1770001300}],
          "recent_hits": [{"hit_id": 99, "target_player_id": 267456763, "target_name": "Arcanine",
            "reward_amount": 500000, "credited_at": 1770001100, "payout_status": "queued", "payment_reference": null,
            "paid_at": null}],
          "claim_history": []}}'''),
      );
      final target = board.targets.single;
      expect(target.estimate, 2989885521);
      expect(target.tiers.map((t) => t.pricePerHit), [700000, 500000]);
      expect(target.totalRemaining, 9);
      expect(board.claims.pending.single.requiredChecks, 5);
      expect(board.claims.recentHits.single.payoutStatus, 'queued');
    });

    test('quote, new order and order status', () {
      final quote = FFScouterBountyQuote.fromJson(
        _json('''{"quote": {"subtotal": 5000000, "fee_amount": 1250000, "total_payable": 6250000, "fee_percent": 0.25,
          "payment_value_per_xanax": 1200000, "expected_xanax_quantity": 6, "xanax_overage_value": 950000}}'''),
      );
      expect(quote.feePercent, 0.25);
      expect(quote.expectedXanax, 6);

      final order = FFScouterBountyNewOrder.fromJson(
        _json('''{"order": {"reference": "B1234567A", "status_token": "01234567890123",
          "status_url": "https://ffscouter.com/buy-bounties/01234567890123",
          "payment_instructions": {"quantity_remaining": 6, "message": "bounty:B1234567A", "xanax_expected": 6,
            "xanax_received": 0, "total_payable": 6250000, "payment_value_per_xanax": 1200000,
            "payment_deadline_at": 1770007200}}}'''),
      );
      expect(order.statusToken, '01234567890123');
      expect(order.payment.message, 'bounty:B1234567A');

      final status = FFScouterBountyOrderStatus.fromJson(
        _json('''{"order": {"reference": "B1234567A", "state": "active", "target_player_id": 267456763,
          "target_name": "Arcanine", "price_per_hit": 500000, "quantity": 10, "quantity_credited": 4, "hits": []},
          "payment_instructions": {"quantity_remaining": 0, "message": "bounty:B1234567A", "xanax_expected": 6,
            "xanax_received": 6, "payment_deadline_at": 1770007200}}'''),
      );
      expect(status.state, 'active');
      expect(status.quantityCredited, 4);
      expect(status.payment.xanaxReceived, 6);
    });

    test('a disabled target has no estimate when it is not available', () {
      final target = FFScouterBountyTarget.fromJson(
        _json('''{"target_player_id": 1, "target_name": "Me", "estimate": null, "estimate_available": false,
          "tiers": [], "max_price_per_hit": 300000, "total_remaining": 1, "disabled": true,
          "disabled_reason": "target"}'''),
      );
      expect(target.estimate, isNull);
      expect(target.disabled, isTrue);
      expect(target.disabledReason, 'target');
    });
  });
}
