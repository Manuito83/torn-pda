import 'dart:async';

import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_flights_model.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';

class _FlightCacheEntry {
  final FFScouterFlightsResponse data;
  final int cachedAt; // epoch seconds
  _FlightCacheEntry(this.data, this.cachedAt);
}

/// Short-lived in-memory cache for player-flights
/// Batched, deduplicated, not persisted. Success/error-19 update premium
class FFScouterFlightsController extends GetxController {
  final Map<int, _FlightCacheEntry> _cache = {};
  final Map<int, List<Completer<FFScouterFlightsResponse?>>> _waiting = {};
  Timer? _batchTimer;

  /// Re-fetch window. Short because the target may land or start a new trip
  static const int _ttlSeconds = 120;
  static const int _batchSize = 100;

  int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Returns fresh cached flights for [target], or null if missing/stale
  FFScouterFlightsResponse? get(int target) {
    final entry = _cache[target];
    if (entry == null) return null;
    if (_now - entry.cachedAt > _ttlSeconds) return null;
    return entry.data;
  }

  /// Fetch flights for [target] (cached when fresh). Null if unavailable
  Future<FFScouterFlightsResponse?> fetch(int target, {bool force = false}) {
    if (!force) {
      final cached = get(target);
      if (cached != null) return Future.value(cached);
    }
    if (!Get.find<FFScouterCacheController>().remoteConfigEnabled) return Future.value(null);
    if (Get.find<UserController>().alternativeFFScouterKey.isEmpty) return Future.value(null);

    final completer = Completer<FFScouterFlightsResponse?>();
    _waiting.putIfAbsent(target, () => []).add(completer);
    _batchTimer ??= Timer(const Duration(milliseconds: 300), _fetchWaiting);
    return completer.future;
  }

  Future<void> _fetchWaiting() async {
    _batchTimer = null;
    final waiting = Map.of(_waiting);
    _waiting.clear();
    final ids = waiting.keys.toList();
    final key = Get.find<UserController>().alternativeFFScouterKey;
    final premiumRegistered = Get.isRegistered<FFScouterPremiumController>();

    for (int i = 0; i < ids.length; i += _batchSize) {
      final chunk = ids.sublist(i, (i + _batchSize).clamp(0, ids.length));
      final result = await FFScouterComm.getPlayerFlightsBatch(key: key, targets: chunk);

      if (result.success && result.data != null) {
        if (premiumRegistered) Get.find<FFScouterPremiumController>().markPremiumDetected();
        final now = _now;
        for (final id in chunk) {
          final data = result.data!.firstWhereOrNull((f) => f.playerId == id) ?? FFScouterFlightsResponse(playerId: id);
          _cache[id] = _FlightCacheEntry(data, now);
        }
      } else if (result.errorCode == 19 && premiumRegistered) {
        Get.find<FFScouterPremiumController>().markNotPremium();
      }

      for (final id in chunk) {
        final data = result.success ? _cache[id]?.data : null;
        for (final completer in waiting[id]!) {
          completer.complete(data);
        }
      }
    }
    update();
  }
}
