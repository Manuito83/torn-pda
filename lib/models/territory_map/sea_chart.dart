import 'dart:math';
import 'dart:ui';

enum ShipKind { cargo, tanker, cruise, ferry, yacht, sailboat, speedboat, fishing }

typedef ShipPath = ({ShipKind kind, List<Offset> points});

// World units, from the surroundings file
class SeaChart {
  SeaChart({
    required this.channel,
    required this.berths,
    required this.loops,
    required this.ferry,
    required this.anchored,
    required this.crossings,
    required this.lighthouses,
    required this.buoys,
  });

  // From the horizon to the port
  final List<Offset> channel;

  // Each from the channel end
  final List<ShipPath> berths;
  final List<ShipPath> loops;
  final List<Offset> ferry;
  final List<({Offset at, double heading})> anchored;
  final List<ShipPath> crossings;
  final List<Offset> lighthouses;
  final List<({Offset at, bool green})> buoys;
}

SeaChart seaChartFromJson(Map<String, dynamic> json) {
  Offset point(List v) => Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
  List<Offset> line(List values) => [for (final v in values) point(v as List)];
  List<ShipPath> paths(List values, String key) => [
    for (final p in values)
      (kind: ShipKind.values.byName((p as Map<String, dynamic>)['type'] as String), points: line(p[key] as List)),
  ];
  return SeaChart(
    channel: line(json['channel'] as List),
    berths: paths(json['berths'] as List, 'end'),
    loops: paths(json['loops'] as List, 'points'),
    ferry: line(json['ferry'] as List),
    anchored: [for (final a in json['anchored'] as List) (at: point(a as List), heading: (a[2] as num) * pi / 180)],
    crossings: paths(json['crossings'] as List, 'points'),
    lighthouses: line(json['lighthouses'] as List),
    buoys: [for (final b in json['buoys'] as List) (at: point(b as List), green: b[2] == 1)],
  );
}

// Catmull-Rom through the points
List<Offset> smoothRoute(List<Offset> points, {required bool closed, required double step}) {
  final n = points.length;
  Offset at(int i) => closed ? points[(i + n) % n] : points[i.clamp(0, n - 1)];
  final out = <Offset>[];
  for (var i = 0; i < (closed ? n : n - 1); i++) {
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    final steps = ((p2 - p1).distance / step).ceil().clamp(2, 700);
    for (var k = 0; k < steps; k++) {
      final t = k / steps, t2 = t * t, t3 = t2 * t;
      double mix(double a, double b, double c, double d) =>
          0.5 * (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (3 * b - a - 3 * c + d) * t3);
      out.add(Offset(mix(p0.dx, p1.dx, p2.dx, p3.dx), mix(p0.dy, p1.dy, p2.dy, p3.dy)));
    }
  }
  out.add(closed ? out.first : points.last);
  return out;
}
