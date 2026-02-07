import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_cache_model.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

/// Central cache controller for FFScouter battle score estimates.
///
/// Holds an in-memory map of [FFScouterCacheEntry] keyed by player ID,
/// persisted to SharedPrefs. Entries have a 24-hour TTL.
///
/// Call [ensureFresh] with a list of player IDs before displaying stats.
/// It will bulk-fetch only the IDs whose cache is stale or missing,
/// in chunks of 205 (the API limit).
///
/// If another [ensureFresh] is already in progress, callers will wait for
/// it to finish and then re-check for any still-stale IDs.
class FFScouterCacheController extends GetxController {
  final Map<int, FFScouterCacheEntry> _cache = {};

  /// Master kill-switch mirrored from Firebase Remote Config.
  /// When `false`, [get] returns null and [ensureFresh] is a no-op,
  /// effectively disabling all FFScouter functionality.
  bool remoteConfigEnabled = true;

  /// Whether a bulk fetch is currently in progress.
  bool _isFetching = false;
  bool get isFetching => _isFetching;

  /// Completer that concurrent callers can await while a fetch is running.
  Completer<void>? _activeFetch;

  /// Current number of entries in the cache (for diagnostics).
  int get cacheSize => _cache.length;

  /// Max cache entries to keep (prevents unbounded growth).
  static const int _maxEntries = 3000;

  @override
  void onInit() {
    super.onInit();
    _restoreCache();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the cached entry for [playerId], or null if not available.
  /// Returns null when [remoteConfigEnabled] is false (kill-switch).
  FFScouterCacheEntry? get(int playerId) {
    if (!remoteConfigEnabled) return null;
    final entry = _cache[playerId];
    if (entry != null && entry.isFresh) return entry;
    return null;
  }

  /// Returns true if we have a fresh cache entry for [playerId].
  bool hasFresh(int playerId) => get(playerId) != null;

  /// Ensures all [playerIds] have fresh cache entries.
  /// Fetches only the stale/missing ones in bulk (chunks of 205).
  ///
  /// If another fetch is already running, waits for it to complete and then
  /// re-checks — only fetching IDs that are still stale.
  ///
  /// Returns the number of newly fetched entries.
  Future<int> ensureFresh(List<int> playerIds) async {
    // Remote Config kill-switch: skip all API calls when disabled
    if (!remoteConfigEnabled) return 0;

    // If another fetch is in progress, wait for it instead of bailing out
    if (_activeFetch != null) {
      await _activeFetch!.future;
    }

    final staleIds = playerIds.where((id) => !hasFresh(id)).toList();
    if (staleIds.isEmpty) return 0;

    _isFetching = true;
    _activeFetch = Completer<void>();
    update();

    int totalFetched = 0;
    final UserController u = Get.find<UserController>();

    // Wait up to 5 seconds for the FFScouter API key to become available.
    // UserController._setupAlternativeKeys() is async and may not have
    // completed yet when WarController.initialise() fires early.
    if (u.alternativeFFScouterKey.isEmpty) {
      for (int wait = 0; wait < 10; wait++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (u.alternativeFFScouterKey.isNotEmpty) break;
      }
      if (u.alternativeFFScouterKey.isEmpty) {
        _isFetching = false;
        _activeFetch?.complete();
        _activeFetch = null;
        update();
        return 0;
      }
    }

    try {
      // Chunk into groups of 205
      for (int i = 0; i < staleIds.length; i += 205) {
        final chunk = staleIds.sublist(i, (i + 205).clamp(0, staleIds.length));

        final result = await FFScouterComm.getStats(
          key: u.alternativeFFScouterKey,
          targetIds: chunk,
        );

        if (result.success && result.data != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          for (final stat in result.data!) {
            if (stat.playerId == null) continue;
            _cache[stat.playerId!] = FFScouterCacheEntry(
              playerId: stat.playerId!,
              bsEstimate: stat.bsEstimate,
              bsEstimateHuman: stat.bsEstimateHuman,
              fairFight: stat.fairFight,
              lastUpdatedByFFScouter: stat.lastUpdated,
              cachedAt: now,
            );
            totalFetched++;
          }
        }

        // Rate-limit courtesy: small delay between chunks
        if (i + 205 < staleIds.length) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      // Enforce max cache size by evicting oldest entries
      _evictIfNeeded();

      // Persist
      await _saveCache();
    } catch (_) {
    } finally {
      _isFetching = false;
      _activeFetch?.complete();
      _activeFetch = null;
      update();
    }

    return totalFetched;
  }

  /// Clears the entire cache.
  Future<void> clearCache() async {
    _cache.clear();
    await _saveCache();
    update();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _restoreCache() async {
    try {
      final raw = await Prefs().getFFScouterStatsCache();
      if (raw.isEmpty) return;
      final List<dynamic> decoded = json.decode(raw);
      for (final item in decoded) {
        final entry = FFScouterCacheEntry.fromJson(item);
        if (entry.isFresh) {
          _cache[entry.playerId] = entry;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      final entries = _cache.values.where((e) => e.isFresh).toList();
      final encoded = json.encode(entries.map((e) => e.toJson()).toList());
      await Prefs().setFFScouterStatsCache(encoded);
    } catch (_) {}
  }

  void _evictIfNeeded() {
    if (_cache.length <= _maxEntries) return;
    final sorted = _cache.entries.toList()..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final toRemove = sorted.length - _maxEntries;
    for (int i = 0; i < toRemove; i++) {
      _cache.remove(sorted[i].key);
    }
  }
}
