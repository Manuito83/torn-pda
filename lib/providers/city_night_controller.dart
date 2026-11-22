import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_night.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

const _checkEvery = Duration(seconds: 30);
const _sleepAfter = Duration(seconds: 60);

// Night by TCT
class CityNightController {
  CityNightController(this.ground, this.file, {this.withWindows = true});

  final CityGround ground;
  final TerritoryFile file;
  final bool withWindows;

  final level = ValueNotifier<NightLevel>(daylight);

  // Null until worked out
  final windows = ValueNotifier<CityWindows?>(null);
  late final lamps = streetLamps(ground.roads.edges);
  late final runwayEdges = runwayLights(ground.runways);

  bool on = false;

  // Debug only, null follows TCT
  double? _hour;
  bool _windowsAsked = false;
  bool _disposed = false;
  bool _shown = false;
  Timer? _timer;
  final _sinceTouch = Stopwatch();

  bool get awake => _sinceTouch.isRunning && _sinceTouch.elapsed < _sleepAfter;

  void configure({required bool on, double? hour}) {
    if (on == this.on && hour == _hour) return;
    this.on = on;
    _hour = hour;
    _check();
    _sync();
  }

  // Map on screen, app in front
  void show(bool shown) {
    if (shown == _shown) return;
    _shown = shown;
    shown ? wake() : _sync();
  }

  void wake() {
    _sinceTouch
      ..reset()
      ..start();
    _check();
    _sync();
  }

  void _check() {
    if (!on) {
      level.value = daylight;
      return;
    }
    final now = DateTime.now().toUtc();
    final hour = _hour;
    final time = hour == null
        ? now
        : DateTime.utc(now.year, now.month, now.day).add(Duration(seconds: (hour * 3600).round()));
    final found = nightLevelAt(time);
    if (withWindows && found.dark > 0 && !_windowsAsked) {
      _windowsAsked = true;
      unawaited(
        compute(cityWindows, file.territories.values.toList()).then((found) {
          if (!_disposed) windows.value = found;
        }),
      );
    }
    level.value = found;
  }

  void _sync() {
    if (_shown && awake && on) {
      _timer ??= Timer.periodic(_checkEvery, (_) {
        if (!awake) return _sync();
        _check();
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    level.dispose();
    windows.dispose();
  }
}
