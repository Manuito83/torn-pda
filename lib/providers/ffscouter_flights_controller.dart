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
/// Single-target, deduplicated, not persisted. Success/error-19 update premium
class FFScouterFlightsController extends GetxController {
  final Map<int, _FlightCacheEntry> _cache = {};
  final Set<int> _inFlight = {};

  /// Re-fetch window. Short because the target may land or start a new trip
  static const int _ttlSeconds = 120;

  int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Returns fresh cached flights for [target], or null if missing/stale
  FFScouterFlightsResponse? get(int target) {
    final entry = _cache[target];
    if (entry == null) return null;
    if (_now - entry.cachedAt > _ttlSeconds) return null;
    return entry.data;
  }

  /// Fetch flights for [target] (cached when fresh). Null if unavailable
  Future<FFScouterFlightsResponse?> fetch(int target, {bool force = false}) async {
    if (!force) {
      final cached = get(target);
      if (cached != null) return cached;
    }
    if (_inFlight.contains(target)) return get(target);
    if (!Get.find<FFScouterCacheController>().remoteConfigEnabled) return null;

    final key = Get.find<UserController>().alternativeFFScouterKey;
    if (key.isEmpty) return null;

    _inFlight.add(target);
    final result = await FFScouterComm.getPlayerFlights(key: key, target: target);
    _inFlight.remove(target);

    final premiumRegistered = Get.isRegistered<FFScouterPremiumController>();

    if (result.success && result.data != null) {
      if (premiumRegistered) Get.find<FFScouterPremiumController>().markPremiumDetected();
      _cache[target] = _FlightCacheEntry(result.data!, _now);
      update();
      return result.data;
    } else if (result.errorCode == 19 && premiumRegistered) {
      Get.find<FFScouterPremiumController>().markNotPremium();
    }
    return null;
  }
}
