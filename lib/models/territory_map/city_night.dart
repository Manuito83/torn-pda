import 'dart:math';
import 'dart:typed_data';

import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

// Share of windows lit
typedef NightLevel = ({double dark, double lights});

const daylight = (dark: 0.0, lights: 0.0);

const _windowStep = 11.0;
const _lampEvery = 16.0;
const _runwayLightEvery = 20.0;

double _smooth(double from, double to, double at) {
  final u = ((at - from) / (to - from)).clamp(0.0, 1.0);
  return u * u * (3 - 2 * u);
}

// Torn City Time is UTC
double tctHour(DateTime time) {
  final utc = time.toUtc();
  return utc.hour + utc.minute / 60 + utc.second / 3600;
}

double nightAt(double hour) {
  if (hour >= 7.5 && hour <= 18.5) return 0;
  if (hour > 18.5 && hour < 20.5) return _smooth(18.5, 20.5, hour);
  if (hour >= 5.5 && hour < 7.5) return 1 - _smooth(5.5, 7.5, hour);
  return 1;
}

// Fewer windows late at night
double lightsAt(double hour) {
  final h = hour < 12 ? hour + 24 : hour;
  if (h < 23) return 1;
  if (h < 27) return 1 - 0.6 * _smooth(23, 27, h);
  return 0.4 + 0.4 * _smooth(27, 30, h);
}

// In steps: repaint only on real change
NightLevel nightLevelAt(DateTime time) {
  final hour = tctHour(time);
  final dark = (nightAt(hour) * 50).round() / 50;
  if (dark == 0) return daylight;
  return (dark: dark, lights: (lightsAt(hour) * 25).round() / 25);
}

// Shuffled, so thinning out stays even
class CityWindows {
  CityWindows(this.points, this.thresholds, this.ranges);

  final Float32List points;
  final Float32List thresholds;
  final Map<String, (int, int)> ranges;
}

CityWindows cityWindows(Iterable<Territory> territories) {
  final points = <double>[];
  final thresholds = <double>[];
  final ranges = <String, (int, int)>{};
  for (final t in territories) {
    final rings = flattenRings(t);
    final keep = 0.1 + 0.1 * t.density;
    final found = <(double, double, double, double)>[];
    for (var y = t.bounds.top; y < t.bounds.bottom; y += _windowStep) {
      for (var x = t.bounds.left; x < t.bounds.right; x += _windowStep) {
        final seed = (x * 7919 + y * 104729).round();
        if (groundHash(seed) > keep) continue;
        final px = x + (groundHash(seed + 1) - 0.5) * 7, py = y + (groundHash(seed + 2) - 0.5) * 7;
        if (insideTerritory(rings, px, py)) found.add((px, py, groundHash(seed + 3), groundHash(seed + 4)));
      }
    }
    found.sort((a, b) => a.$4.compareTo(b.$4));
    final start = thresholds.length;
    for (final (x, y, threshold, _) in found) {
      points.addAll([x, y]);
      thresholds.add(threshold);
    }
    ranges[t.code] = (start, thresholds.length);
  }
  return CityWindows(Float32List.fromList(points), Float32List.fromList(thresholds), ranges);
}

Float32List streetLamps(Iterable<RoadEdge> edges) {
  final out = <double>[];
  for (final edge in edges) {
    for (var d = _lampEvery / 2; d < edge.length; d += _lampEvery) {
      var k = 0;
      while (k < edge.xs.length - 2 && edge.cumulative[k + 1] < d) {
        k++;
      }
      final segment = max(edge.cumulative[k + 1] - edge.cumulative[k], 1e-6);
      final u = (d - edge.cumulative[k]) / segment;
      out
        ..add(edge.xs[k] + (edge.xs[k + 1] - edge.xs[k]) * u)
        ..add(edge.ys[k] + (edge.ys[k + 1] - edge.ys[k]) * u);
    }
  }
  return Float32List.fromList(out);
}

// Both edges of every runway
Float32List runwayLights(List<Runway> runways) {
  final out = <double>[];
  for (final r in runways) {
    for (final side in [1, -1]) {
      final nx = -r.uy * r.width / 2 * side, ny = r.ux * r.width / 2 * side;
      for (var d = 0.0; d <= r.length; d += _runwayLightEvery) {
        out
          ..add(r.ax + r.ux * d + nx)
          ..add(r.ay + r.uy * d + ny);
      }
    }
  }
  return Float32List.fromList(out);
}
