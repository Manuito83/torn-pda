import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/territory_file.dart';

const fullDetail = 0.5;
const movingDetail = 3.5;

const wallLights = 4;

// Rings of one detail level, triangulated tops
class CityMeshLevel {
  CityMeshLevel({
    required this.x,
    required this.y,
    required this.light,
    required this.ringStart,
    required this.firstRing,
    required this.triangles,
    required this.firstTriangle,
  });

  final Float32List x;
  final Float32List y;

  // Edge from each vertex to the next
  final Uint8List light;
  final Int32List ringStart;
  final Int32List firstRing;
  final Int32List triangles;
  final Int32List firstTriangle;

  int get vertexCount => x.length;

  // Walls and borders, 6 per edge
  int get maxDrawnVertices => triangles.length + vertexCount * 12;
}

class CityMesh {
  CityMesh({
    required this.codes,
    required this.bounds,
    required this.full,
    required this.moving,
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.rise,
  });

  final List<String> codes;
  final Rect bounds;
  final CityMeshLevel full;
  final CityMeshLevel moving;
  final Float32List centerX;
  final Float32List centerY;
  final Float32List radius;

  // 0 at the center, 1 farthest
  final Float32List rise;

  int get length => codes.length;

  late final Map<String, int> indexOf = {for (var i = 0; i < codes.length; i++) codes[i]: i};
}

// Curves become lines, closing point dropped
List<List<double>> flattenRings(Territory territory) {
  final rings = <List<double>>[];
  final p = territory.points;
  List<double>? ring;
  var i = 0;
  for (final verb in territory.verbs) {
    switch (verb) {
      case moveToVerb:
        ring = [p[i], p[i + 1]];
        rings.add(ring);
        i += 2;
      case lineToVerb:
        ring!.addAll([p[i], p[i + 1]]);
        i += 2;
      case cubicToVerb:
        final x0 = ring![ring.length - 2], y0 = ring.last;
        final length =
            _distance(x0, y0, p[i], p[i + 1]) +
            _distance(p[i], p[i + 1], p[i + 2], p[i + 3]) +
            _distance(p[i + 2], p[i + 3], p[i + 4], p[i + 5]);
        final steps = (length / 8).ceil().clamp(2, 8);
        for (var k = 1; k <= steps; k++) {
          final t = k / steps, u = 1 - t;
          final a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t;
          ring.add(a * x0 + b * p[i] + c * p[i + 2] + d * p[i + 4]);
          ring.add(a * y0 + b * p[i + 1] + c * p[i + 3] + d * p[i + 5]);
        }
        i += 6;
    }
  }
  for (final r in rings) {
    final n = r.length;
    if (n >= 4 && r[0] == r[n - 2] && r[1] == r[n - 1]) r.removeRange(n - 2, n);
  }
  return [
    for (final r in rings)
      if (r.length >= 6) r,
  ];
}

double _distance(double ax, double ay, double bx, double by) =>
    math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));

double ringArea(List<double> ring) {
  var sum = 0.0;
  final n = ring.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    sum += ring[j * 2] * ring[i * 2 + 1] - ring[i * 2] * ring[j * 2 + 1];
  }
  return sum / 2;
}

bool insideRing(double x, double y, List<double> ring) {
  var inside = false;
  final n = ring.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = ring[i * 2], yi = ring[i * 2 + 1], xj = ring[j * 2], yj = ring[j * 2 + 1];
    if ((yi > y) != (yj > y) && x < xi + (y - yi) * (xj - xi) / (yj - yi)) inside = !inside;
  }
  return inside;
}

bool insideTerritory(List<List<double>> rings, double x, double y) {
  var inside = false;
  for (final ring in rings) {
    if (insideRing(x, y, ring)) inside = !inside;
  }
  return inside;
}

// Douglas-Peucker on a closed ring
List<double> simplifyRing(List<double> ring, double tolerance) {
  final n = ring.length ~/ 2;
  var far = 0;
  var best = -1.0;
  for (var i = 1; i < n; i++) {
    final d = _distance(ring[0], ring[1], ring[i * 2], ring[i * 2 + 1]);
    if (d > best) {
      best = d;
      far = i;
    }
  }
  if (far == 0) return ring;

  final keep = List.filled(n + 1, false);
  double px(int i) => ring[(i % n) * 2];
  double py(int i) => ring[(i % n) * 2 + 1];
  final stack = [0, far, far, n];
  while (stack.isNotEmpty) {
    final b = stack.removeLast(), a = stack.removeLast();
    keep[a] = keep[b] = true;
    final ax = px(a), ay = py(a), dx = px(b) - ax, dy = py(b) - ay;
    final length = math.sqrt(dx * dx + dy * dy);
    var worst = -1.0;
    var at = -1;
    for (var i = a + 1; i < b; i++) {
      final d = length == 0 ? _distance(ax, ay, px(i), py(i)) : ((px(i) - ax) * dy - (py(i) - ay) * dx).abs() / length;
      if (d > worst) {
        worst = d;
        at = i;
      }
    }
    if (worst > tolerance) stack.addAll([a, at, at, b]);
  }
  final out = <double>[
    for (var i = 0; i < n; i++)
      if (keep[i]) ...[ring[i * 2], ring[i * 2 + 1]],
  ];
  return out.length >= 6 ? out : ring;
}

// Ear clipping, holes bridged to outside
List<int> triangulate(List<double> coords, int outerCount, List<int> holeStarts) {
  final n = coords.length ~/ 2;
  double x(int v) => coords[v * 2];
  double y(int v) => coords[v * 2 + 1];
  double cross(int a, int b, int c) => (x(b) - x(a)) * (y(c) - y(b)) - (y(b) - y(a)) * (x(c) - x(b));

  var polygon = [for (var v = 0; v < outerCount; v++) v];
  final sign = ringArea(coords.sublist(0, outerCount * 2)) >= 0 ? 1.0 : -1.0;

  final holes = <List<int>>[
    for (var h = 0; h < holeStarts.length; h++)
      [for (var v = holeStarts[h]; v < (h + 1 < holeStarts.length ? holeStarts[h + 1] : n); v++) v],
  ];
  int rightmost(List<int> ring) => ring.reduce((a, b) => x(b) > x(a) ? b : a);
  holes.sort((a, b) => x(rightmost(b)).compareTo(x(rightmost(a))));

  for (final hole in holes) {
    final m = rightmost(hole);
    final mx = x(m), my = y(m);
    var bridge = -1;
    var nearest = double.infinity;
    for (var i = 0; i < polygon.length; i++) {
      final a = polygon[i], b = polygon[(i + 1) % polygon.length];
      if ((y(a) > my) == (y(b) > my) || y(a) == y(b)) continue;
      final hit = x(a) + (my - y(a)) * (x(b) - x(a)) / (y(b) - y(a));
      if (hit < mx || hit - mx >= nearest) continue;
      nearest = hit - mx;
      bridge = x(a) > x(b) ? i : (i + 1) % polygon.length;
    }
    if (bridge < 0) continue;
    final at = hole.indexOf(m);
    final p = polygon[bridge];
    polygon = [
      ...polygon.sublist(0, bridge + 1),
      for (var k = 0; k <= hole.length; k++) hole[(at + k) % hole.length],
      p,
      ...polygon.sublist(bridge + 1),
    ];
  }

  bool sameSpot(int a, int b) => x(a) == x(b) && y(a) == y(b);
  bool inTriangle(int p, int a, int b, int c) =>
      cross(a, b, p) * sign >= 0 && cross(b, c, p) * sign >= 0 && cross(c, a, p) * sign >= 0;

  final out = <int>[];
  var guard = 0;
  var i = 0;
  while (polygon.length > 3 && guard < polygon.length * 2) {
    final count = polygon.length;
    final a = polygon[(i + count - 1) % count], b = polygon[i % count], c = polygon[(i + 1) % count];
    var ear = cross(a, b, c) * sign > 0;
    if (ear) {
      for (final p in polygon) {
        if (sameSpot(p, a) || sameSpot(p, b) || sameSpot(p, c)) continue;
        if (inTriangle(p, a, b, c)) {
          ear = false;
          break;
        }
      }
    }
    if (ear) {
      out.addAll([a, b, c]);
      polygon.removeAt(i % count);
      guard = 0;
      i = i % polygon.length;
      continue;
    }
    i = (i + 1) % count;
    guard++;
  }
  // Leftovers from self-touching rings, as a fan
  for (var k = 1; k + 1 < polygon.length; k++) {
    if (cross(polygon[0], polygon[k], polygon[k + 1]) * sign > 0) out.addAll([polygon[0], polygon[k], polygon[k + 1]]);
  }
  return out;
}

// Light from the top left
int edgeLight(double ax, double ay, double bx, double by) {
  final ex = bx - ax, ey = by - ay;
  final length = math.sqrt(ex * ex + ey * ey);
  if (length == 0) return 0;
  final lit = (ey / length * -0.62 + ex / length * 0.78 + 1) / 2;
  return math.min(wallLights - 1, (lit * wallLights).floor());
}

// Outer rings positive, holes negative
List<List<double>> orientedRings(Territory territory) {
  final rings = flattenRings(territory);
  if (rings.isEmpty) return rings;
  final outer = rings.reduce((a, b) => ringArea(b).abs() > ringArea(a).abs() ? b : a);
  return [
    for (final r in rings)
      if ((ringArea(r) > 0) == (!identical(r, outer) && insideRing(r[0], r[1], outer)))
        [
          for (var i = r.length ~/ 2 - 1; i >= 0; i--) ...[r[i * 2], r[i * 2 + 1]],
        ]
      else
        r,
  ];
}

CityMeshLevel _buildLevel(List<List<List<double>>> shapes, double tolerance) {
  final xs = <double>[], ys = <double>[], light = <int>[], ringStart = <int>[], firstRing = <int>[];
  final triangles = <int>[], firstTriangle = <int>[];
  for (final rings in shapes) {
    firstRing.add(ringStart.length);
    firstTriangle.add(triangles.length);
    final simple = [for (final r in rings) simplifyRing(r, tolerance)];
    for (final r in simple) {
      ringStart.add(xs.length);
      final n = r.length ~/ 2;
      for (var k = 0; k < n; k++) {
        final next = (k + 1) % n;
        xs.add(r[k * 2]);
        ys.add(r[k * 2 + 1]);
        light.add(edgeLight(r[k * 2], r[k * 2 + 1], r[next * 2], r[next * 2 + 1]));
      }
    }
    for (var o = 0; o < simple.length; o++) {
      if (ringArea(simple[o]) <= 0) continue;
      final coords = [...simple[o]];
      final starts = <int>[];
      final ids = [for (var k = 0; k < simple[o].length ~/ 2; k++) ringStart[firstRing.last + o] + k];
      for (var h = 0; h < simple.length; h++) {
        final hole = simple[h];
        if (ringArea(hole) >= 0 || !insideRing(hole[0], hole[1], simple[o])) continue;
        starts.add(coords.length ~/ 2);
        coords.addAll(hole);
        ids.addAll([for (var k = 0; k < hole.length ~/ 2; k++) ringStart[firstRing.last + h] + k]);
      }
      for (final v in triangulate(coords, simple[o].length ~/ 2, starts)) {
        triangles.add(ids[v]);
      }
    }
  }
  firstRing.add(ringStart.length);
  ringStart.add(xs.length);
  firstTriangle.add(triangles.length);
  return CityMeshLevel(
    x: Float32List.fromList(xs),
    y: Float32List.fromList(ys),
    light: Uint8List.fromList(light),
    ringStart: Int32List.fromList(ringStart),
    firstRing: Int32List.fromList(firstRing),
    triangles: Int32List.fromList(triangles),
    firstTriangle: Int32List.fromList(firstTriangle),
  );
}

CityMesh buildCityMesh(TerritoryFile file) {
  final codes = file.territories.keys.toList()..sort();
  final shapes = [for (final code in codes) orientedRings(file.territories[code]!)];
  final count = codes.length;
  final centerX = Float32List(count), centerY = Float32List(count), radius = Float32List(count);
  final rise = Float32List(count);
  final cityX = file.bounds.center.dx, cityY = file.bounds.center.dy;
  var farthest = 1.0;
  for (var t = 0; t < count; t++) {
    final b = file.territories[codes[t]]!.bounds;
    centerX[t] = b.center.dx;
    centerY[t] = b.center.dy;
    radius[t] = math.sqrt(b.width * b.width + b.height * b.height) / 2;
    rise[t] = _distance(centerX[t], centerY[t], cityX, cityY);
    farthest = math.max(farthest, rise[t]);
  }
  for (var t = 0; t < count; t++) {
    rise[t] /= farthest;
  }
  return CityMesh(
    codes: codes,
    bounds: file.bounds,
    full: _buildLevel(shapes, fullDetail),
    moving: _buildLevel(shapes, movingDetail),
    centerX: centerX,
    centerY: centerY,
    radius: radius,
    rise: rise,
  );
}
