import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_activity_model.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';

class _PatternCacheEntry {
  final FFScouterActivityPattern pattern;
  final int cachedAt;
  _PatternCacheEntry(this.pattern, this.cachedAt);
}

/// Folded typical-day activity patterns (premium), cached a few hours
class FFScouterActivityController extends GetxController {
  final Map<String, _PatternCacheEntry> _cache = {};
  final Set<String> _inFlight = {};
  static const int _ttlSeconds = 6 * 60 * 60;

  int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  FFScouterActivityPattern? getCached(String cacheKey) {
    final e = _cache[cacheKey];
    if (e == null) return null;
    if (_now - e.cachedAt > _ttlSeconds) return null;
    return e.pattern;
  }

  /// Player typical-day pattern over the last [days] (slot value = prob active)
  Future<FFScouterActivityPattern?> playerPattern(int playerId, {int days = 7, int bucket = 900, bool force = false}) {
    return _load(
      "p:$playerId:$bucket:$days",
      days,
      (key, start, end) =>
          FFScouterComm.getActivityPlayer(key: key, target: playerId, start: start, end: end, bucket: bucket),
      (b) => b.activityScore.toDouble(),
      force: force,
    );
  }

  /// Faction typical-day pattern over the last [days] (slot value = active ratio)
  Future<FFScouterActivityPattern?> factionPattern(
    int factionId, {
    int days = 7,
    int bucket = 3600,
    bool force = false,
  }) {
    return _load(
      "f:$factionId:$bucket:$days",
      days,
      (key, start, end) =>
          FFScouterComm.getActivityFaction(key: key, factionId: factionId, start: start, end: end, bucket: bucket),
      (b) => b.activeRatio ?? 0,
      force: force,
    );
  }

  Future<FFScouterActivityPattern?> _load(
    String cacheKey,
    int days,
    Future<FFScouterResult<FFScouterActivityResponse>> Function(String key, int start, int end) call,
    double Function(FFScouterActivityBucket) scoreOf, {
    bool force = false,
  }) async {
    if (!force) {
      final cached = getCached(cacheKey);
      if (cached != null) return cached;
    }
    if (_inFlight.contains(cacheKey)) return getCached(cacheKey);
    if (!Get.find<FFScouterCacheController>().remoteConfigEnabled) return null;

    final key = Get.find<UserController>().alternativeFFScouterKey;
    if (key.isEmpty) return null;

    final end = _now;
    final start = end - days * 86400;

    _inFlight.add(cacheKey);
    final result = await call(key, start, end);
    _inFlight.remove(cacheKey);

    final premiumRegistered = Get.isRegistered<FFScouterPremiumController>();
    if (result.success && result.data != null) {
      if (premiumRegistered) Get.find<FFScouterPremiumController>().markPremiumDetected();
      final pattern = FFScouterActivityPattern.fold(result.data!, scoreOf);
      _cache[cacheKey] = _PatternCacheEntry(pattern, _now);
      update();
      return pattern;
    } else if (result.errorCode == 19 && premiumRegistered) {
      Get.find<FFScouterPremiumController>().markNotPremium();
    }
    return null;
  }
}
