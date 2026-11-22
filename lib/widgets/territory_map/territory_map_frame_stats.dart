import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

const _frameBudgetMs = 16.6;

// Only with TERRITORY_MAP_FRAME_STATS=true
class TerritoryMapFrameStats {
  final _timings = <FrameTiming>[];
  Timer? _timer;
  String mode = '';

  void start() {
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _report());
  }

  void stop() {
    SchedulerBinding.instance.removeTimingsCallback(_timings.addAll);
    _timer?.cancel();
  }

  void _report() {
    if (_timings.isEmpty) return;
    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = [for (final t in _timings) ms(t.buildDuration)]..sort();
    final raster = [for (final t in _timings) ms(t.rasterDuration)]..sort();
    double at(List<double> sorted, double p) => sorted[((sorted.length - 1) * p).round()];
    final slow = _timings.where((t) => ms(t.buildDuration) > _frameBudgetMs || ms(t.rasterDuration) > _frameBudgetMs);

    debugPrint(
      'territory map frames [$mode]: n=${_timings.length}'
      ' build p50=${at(build, .5).toStringAsFixed(1)} p95=${at(build, .95).toStringAsFixed(1)}'
      ' raster p50=${at(raster, .5).toStringAsFixed(1)} p95=${at(raster, .95).toStringAsFixed(1)}'
      ' over16ms=${slow.length}',
    );
    _timings.clear();
  }
}
