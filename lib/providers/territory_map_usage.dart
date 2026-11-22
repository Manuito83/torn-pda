import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/main.dart' show analytics;
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

void countMapUse(String feature) => TerritoryMapUsage().count(feature);

void countMapFailure(MapFailure failure) => countMapUse(mapFailureFeature(failure));

Future<void> _logDaily(String feature, int count) async {
  await analytics?.logEvent(name: 'map_usage_daily', parameters: {'feature': feature, 'count': count});
}

// One pref per name, sent daily
class TerritoryMapUsage {
  TerritoryMapUsage._() : _send = _logDaily;

  @visibleForTesting
  TerritoryMapUsage.withSender(this._send);

  static final _shared = TerritoryMapUsage._();

  factory TerritoryMapUsage() => _shared;

  final Future<void> Function(String feature, int count) _send;
  final _prefs = Prefs();
  Future<void> _queue = Future.value();
  Set<MapOrigin>? _origins;

  // Count reads and writes go one at a time
  Future<void> _enqueue(Future<void> Function() job) => _queue = _queue.then((_) => job()).catchError((_) {});

  void count(String feature) {
    if (Platform.isWindows || !territoryMapFeatures.contains(feature)) return;
    unawaited(
      _enqueue(() async => _prefs.setTerritoryMapCount(feature, await _prefs.getTerritoryMapCount(feature) + 1)),
    );
  }

  Future<Set<MapOrigin>> _used() async => _origins ??= readMapOrigins(await _prefs.getTerritoryMapOrigins());

  Future<void> opened(MapSetup setup) async {
    mapOpenFeatures(setup).forEach(count);
    try {
      final used = await _used();
      if (used.add(setup.origin)) await _prefs.setTerritoryMapOrigins([for (final o in used) o.name]);
    } catch (_) {}
    await sync(disabled: false);
  }

  // App start and each open
  Future<void> sync({required bool disabled}) async {
    try {
      await _enqueue(_flush);
      final value = mapUse(await _used(), disabled: disabled);
      await analytics?.setUserProperty(name: 'map_use', value: value);
    } catch (_) {}
  }

  // Counts since the last day sent
  Future<void> _flush() async {
    final today = mapUsageDay(DateTime.now());
    if (await _prefs.getTerritoryMapUsageDay() == today) return;
    await _prefs.setTerritoryMapUsageDay(today);
    for (final feature in territoryMapFeatures) {
      final count = await _prefs.getTerritoryMapCount(feature);
      if (count <= 0) continue;
      await _prefs.setTerritoryMapCount(feature, 0);
      unawaited(_send(feature, count).catchError((_) {}));
    }
  }
}
