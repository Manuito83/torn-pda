import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';

// cars: share of the outside traffic
typedef OutsideBudget = ({int ships, int clouds, int shadows, int glints, double cars});

const OutsideBudget fullOutside = (ships: 22, clouds: 8, shadows: 6, glints: 300, cars: 1);
const OutsideBudget noOutside = (ships: 0, clouds: 0, shadows: 0, glints: 0, cars: 0);

// World x, y, width, speed, turn, look
typedef Drifter = ({double x, double y, double width, double speed, double turn, int look});

typedef SkySpot = ({Offset at, double width, double alpha});

const _shadows = [
  (900.0, -150.0, 3300.0, 13.0, 0.3),
  (5300.0, 2100.0, 2900.0, 15.0, -0.4),
  (2300.0, 4400.0, 3700.0, 12.0, 0.15),
  (-3600.0, 900.0, 3100.0, 16.0, 0.5),
  (8300.0, -2600.0, 3500.0, 11.0, -0.2),
  (-1300.0, 6100.0, 2700.0, 14.0, 0.4),
];

const _glintsCenter = Offset(2700, 6900);
const _beamTurn = 0.7;
const lighthouseBeam = 1700.0;

class CitySky {
  CitySky({
    required this.clouds,
    required this.shadows,
    required this.glints,
    required this.lighthouses,
    required this.buoys,
    required this.sea,
  });

  final List<Drifter> clouds, shadows;

  // Map x, y, phase, rate
  final Float32List glints;
  final List<({Offset at, double size, double phase})> lighthouses;
  final List<({Offset at, bool green})> buoys;

  // Around glints, buoys and lighthouses
  final Rect sea;
}

CitySky buildSky(Surroundings s, OutsideBudget budget) {
  Offset onMap(Offset world) => towardsHorizon(world, s.bounds, s.horizon);
  final glints = Float32List(budget.glints * 4);
  for (var i = 0; i < budget.glints; i++) {
    final angle = groundHash(i * 3 + 9) * 2 * pi, r = sqrt(groundHash(i * 7 + 5));
    final at = onMap(_glintsCenter + Offset(cos(angle) * r * 2300, sin(angle) * r * 1700));
    glints
      ..[i * 4] = at.dx
      ..[i * 4 + 1] = at.dy
      ..[i * 4 + 2] = groundHash(i * 13) * 2 * pi
      ..[i * 4 + 3] = 1.2 + groundHash(i * 17) * 2.4;
  }
  final lighthouses = [
    for (final (i, world) in s.sea.lighthouses.indexed)
      (at: onMap(world), size: squeezed(world, s.bounds, s.horizon).size, phase: i * 2.1),
  ];
  final buoys = [for (final b in s.sea.buoys) (at: onMap(b.at), green: b.green)];
  final points = [
    for (var i = 0; i < glints.length; i += 4) Offset(glints[i], glints[i + 1]),
    for (final l in lighthouses) l.at,
    for (final b in buoys) b.at,
  ];
  var sea = Rect.zero;
  if (points.isNotEmpty) {
    sea = Rect.fromPoints(points.first, points.first);
    for (final p in points) {
      sea = sea.expandToInclude(Rect.fromPoints(p, p));
    }
  }

  return CitySky(
    clouds: [
      for (var i = 0; i < budget.clouds; i++)
        (
          x: -4200 + groundHash(i * 11 + 3) * 14600,
          // Half north, half south over the sea
          y: i.isEven ? -9500 + groundHash(i * 13) * 5000 : 5600 + groundHash(i * 17) * 4400,
          width: 900 + groundHash(i * 19) * 900,
          speed: 7 + groundHash(i * 23) * 7,
          turn: (groundHash(i * 29) - 0.5) * 0.9,
          look: i % 2,
        ),
    ],
    shadows: [
      for (final (i, (x, y, width, speed, turn)) in _shadows.take(budget.shadows).indexed)
        (x: x, y: y, width: width, speed: speed, turn: turn, look: i % 2),
    ],
    glints: glints,
    lighthouses: lighthouses,
    buoys: buoys,
    sea: sea.inflate(lighthouseBeam),
  );
}

// Drifts east and wraps round
SkySpot _drift(
  Drifter d,
  double clock,
  Surroundings s, {
  required double from,
  required double span,
  required double fade,
  required double hazeBite,
}) {
  final x = (d.x + d.speed * clock - from) % span + from;
  final world = Offset(x, d.y);
  final view = squeezed(world, s.bounds, s.horizon);
  final edge = min(1.0, min((x - from) / fade, (from + span - x) / fade));
  return (
    at: view.at,
    width: d.width * (0.5 + 0.5 * view.size),
    alpha: max(0.0, edge) * hazeFade(view.distance, hazeBite),
  );
}

SkySpot cloudAt(Drifter cloud, double clock, Surroundings s) =>
    _drift(cloud, clock, s, from: -4600, span: 15400, fade: 900, hazeBite: 0.5);

SkySpot shadowAt(Drifter shadow, double clock, Surroundings s) =>
    _drift(shadow, clock, s, from: -5200, span: 16800, fade: 1200, hazeBite: 0.6);

// Sharp flashes, mostly dark
double glintStrength(double phase, double rate, double clock) => pow(max(0.0, sin(clock * rate + phase)), 8).toDouble();

double beamAngle(double phase, double clock) => clock * _beamTurn + phase;

bool buoyLit(bool green, double clock) => (clock * 1.2 + (green ? 0.5 : 0)).floor().isOdd;
