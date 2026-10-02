import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_hit_calling_model.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/user_helper.dart';

class FFScouterHitCallingController extends GetxController {
  static const Duration _pollInterval = Duration(seconds: 30);

  Map<int, List<FFScouterHitClaim>> _byTarget = {};
  int ttlSeconds = 900;

  Timer? _timer;
  bool _fetching = false;
  int _lastFetch = 0;
  int _blockedUntil = 0;
  bool _notInFaction = false;
  final Set<int> _busy = {};

  bool remoteConfigEnabled = true;

  int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;
  String get _key => Get.find<UserController>().alternativeFFScouterKey;

  bool get available {
    if (!remoteConfigEnabled || _notInFaction || UserHelper.factionId == 0) return false;
    if (!Get.find<FFScouterCacheController>().remoteConfigEnabled) return false;
    final premium = Get.find<FFScouterPremiumController>();
    return premium.isPremium && premium.hitCallingEnabled && _key.isNotEmpty;
  }

  bool isBusy(int targetId) => _busy.contains(targetId);

  List<FFScouterHitClaim> claimsFor(int targetId) {
    final now = _now;
    return (_byTarget[targetId] ?? const []).where((c) => c.expiresAt > now).toList();
  }

  List<FFScouterHitClaim> get myClaims {
    final now = _now;
    return _byTarget.values.expand((c) => c).where((c) => c.claimerId == UserHelper.playerId && c.expiresAt > now).toList();
  }

  void setWarVisible(bool visible) {
    if (!visible) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(_pollInterval, (_) => fetchClaims());
    if (_now - _lastFetch > 10) fetchClaims();
  }

  Future<void> fetchClaims() async {
    if (!available || _fetching || _now < _blockedUntil) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;

    _fetching = true;
    final result = await FFScouterComm.getHitClaims(key: _key);
    _fetching = false;
    _lastFetch = _now;

    if (result.success && result.data != null) {
      ttlSeconds = result.data!.ttlSeconds;
      final byTarget = <int, List<FFScouterHitClaim>>{};
      for (final claim in result.data!.claims) {
        byTarget.putIfAbsent(claim.targetId, () => []).add(claim);
      }
      for (final list in byTarget.values) {
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      _byTarget = byTarget;
      update();
    } else {
      _message(result);
    }
  }

  /// Returns an error message, or null when the target was claimed
  Future<String?> claim(int targetId) async {
    _busy.add(targetId);
    update();
    var result = await FFScouterComm.claimHit(key: _key, target: targetId);
    if (result.errorCode == 24) {
      await Future.delayed(const Duration(milliseconds: 1500));
      result = await FFScouterComm.claimHit(key: _key, target: targetId);
    }
    _busy.remove(targetId);

    if (result.success && result.data?.claim != null) {
      ttlSeconds = result.data!.ttlSeconds;
      final claims = [result.data!.claim!, ...result.data!.otherClaims];
      final unique = {for (final c in claims) c.claimId: c}.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _byTarget[targetId] = unique;
      update();
      return null;
    }
    update();
    return _message(result);
  }

  Future<String?> unclaim(int targetId) async {
    _busy.add(targetId);
    update();
    final result = await FFScouterComm.unclaimHit(key: _key, target: targetId);
    _busy.remove(targetId);
    if (result.success) {
      _byTarget[targetId] = claimsFor(targetId).where((c) => c.claimerId != UserHelper.playerId).toList();
    }
    update();
    return result.success ? null : _message(result);
  }

  Future<String?> releaseAll() async {
    final result = await FFScouterComm.wipeHitClaims(key: _key);
    if (result.success) {
      _byTarget = _byTarget.map((t, c) => MapEntry(t, c.where((x) => x.claimerId != UserHelper.playerId).toList()));
      update();
      return null;
    }
    return _message(result);
  }

  String _message(FFScouterResult result) {
    switch (result.errorCode) {
      case 19:
        Get.find<FFScouterPremiumController>().markNotPremium();
        return "Hit calling requires FFScouter premium";
      case 25:
        _notInFaction = true;
        update();
        return "You need to be in a faction to call hits";
      case 20:
      case 21:
        final wait = result.retryAfterSeconds ?? 30;
        _blockedUntil = _now + wait;
        return "Too many requests to FFScouter, try again in $wait seconds";
      case 23:
        return "Your faction has reached its limit of calls";
      case 24:
        return "Your faction's calls are being updated, try again in a moment";
      case 28:
        return "You have too many active calls, release some first";
      case 29:
        return "You cannot call yourself";
    }
    return result.errorMessage ?? "Error contacting FFScouter";
  }
}
