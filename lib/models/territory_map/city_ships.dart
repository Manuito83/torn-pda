import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/sea_chart.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';

enum ShipRole { berth, ferry, crossing, loop, anchored }

enum ShipMode { sailing, docked, turning, leaving }

// World length, beam over length, speed
typedef ShipSpec = ({double length, double beam, double speed});

const shipSpecs = <ShipKind, ShipSpec>{
  ShipKind.cargo: (length: 124, beam: 0.16, speed: 17),
  ShipKind.tanker: (length: 138, beam: 0.17, speed: 14),
  ShipKind.cruise: (length: 150, beam: 0.15, speed: 15),
  ShipKind.ferry: (length: 64, beam: 0.24, speed: 15),
  ShipKind.yacht: (length: 27, beam: 0.24, speed: 16),
  ShipKind.sailboat: (length: 14, beam: 0.3, speed: 7),
  ShipKind.speedboat: (length: 9, beam: 0.36, speed: 30),
  ShipKind.fishing: (length: 18, beam: 0.34, speed: 6),
};

const _beforeHorizon = 650.0;
const _hazeEatsShips = 1.25;
const _wakeLife = 26.0;
const _wakePoints = 26;
const _turnTime = 9.0;
const _ferryStop = 14.0;
const _sailboatsPerLoop = 3;
const _berthStarts = [1.0, 0.55, 0.3, 1.0];
const _crossingStarts = [0.42, 0.6, 0.3];

// On the map, cut before the horizon
class ShipRoute {
  ShipRoute(this.xs, this.ys, this.sizes, this.distances, this.cumulative, {required this.closed});

  final Float32List xs, ys, sizes, cumulative;

  // World distance to the city, for haze
  final Float32List distances;
  final bool closed;

  double get length => cumulative.last;
}

ShipRoute shipRoute(List<Offset> world, Surroundings s, {bool closed = false, double step = 40}) {
  final xs = <double>[], ys = <double>[], sizes = <double>[], distances = <double>[], cumulative = <double>[];
  final reach = s.horizon.flat + s.horizon.length - _beforeHorizon;
  var total = 0.0;
  for (final point in smoothRoute(world, closed: closed, step: step)) {
    final view = squeezed(point, s.bounds, s.horizon);
    if (horizonDistance(view.distance, s.horizon) > reach) continue;
    final at = view.at;
    if (xs.isNotEmpty) total += (at - Offset(xs.last, ys.last)).distance;
    xs.add(at.dx);
    ys.add(at.dy);
    sizes.add(view.size);
    distances.add(view.distance);
    cumulative.add(total);
  }
  return ShipRoute(
    Float32List.fromList(xs),
    Float32List.fromList(ys),
    Float32List.fromList(sizes),
    Float32List.fromList(distances),
    Float32List.fromList(cumulative),
    closed: closed,
  );
}

typedef RouteSpot = ({double x, double y, double dx, double dy, double size, double distance});

RouteSpot routeAt(ShipRoute r, double along) {
  final length = r.length;
  var s = r.closed ? along % length : along;
  s = s.clamp(0.0, length);
  var lo = 0, hi = r.cumulative.length - 1;
  while (hi - lo > 1) {
    final mid = (lo + hi) >> 1;
    if (r.cumulative[mid] <= s) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  final piece = r.cumulative[hi] - r.cumulative[lo];
  final u = piece == 0 ? 0.0 : (s - r.cumulative[lo]) / piece;
  final mx = r.xs[hi] - r.xs[lo], my = r.ys[hi] - r.ys[lo];
  var drawn = sqrt(mx * mx + my * my);
  if (drawn == 0) drawn = 1;
  return (
    x: r.xs[lo] + mx * u,
    y: r.ys[lo] + my * u,
    dx: mx / drawn,
    dy: my / drawn,
    size: r.sizes[lo] + (r.sizes[hi] - r.sizes[lo]) * u,
    distance: r.distances[lo] + (r.distances[hi] - r.distances[lo]) * u,
  );
}

class Ship {
  Ship(this.kind, this.role, this.route, {required this.speed, required this.hull, required this.seed, this.along = 0});

  final ShipKind kind;
  final ShipRole role;

  // Null while anchored
  final ShipRoute? route;
  final double speed;

  // Hull colors and deck boxes
  int hull, seed;
  double along;
  int direction = 1;
  ShipMode mode = ShipMode.sailing;
  double wait = 0;
  double turn = 0;
  double heading = 0;

  double x = 0, y = 0, dx = 1, dy = 0, size = 1, distance = 0;

  // Newest last
  final wake = <({double x, double y, double at})>[];

  ShipSpec get spec => shipSpecs[kind]!;

  double get alpha => hazeFade(distance, _hazeEatsShips);
}

// Port first, so fewer keeps the busiest
List<Ship> spawnShips(SeaChart sea, Surroundings s, Random random, {int? most}) {
  Ship ship(ShipKind kind, ShipRole role, ShipRoute? route, {double along = 0}) => Ship(
    kind,
    role,
    route,
    speed: shipSpecs[kind]!.speed * (0.85 + random.nextDouble() * 0.3),
    hull: random.nextInt(1 << 16),
    seed: random.nextInt(1 << 20),
    along: along,
  );

  final ships = <Ship>[];
  for (final (i, berth) in sea.berths.indexed) {
    final route = shipRoute([...sea.channel, ...berth.points], s);
    final start = _berthStarts[i % _berthStarts.length];
    final docked = start == 1;
    ships.add(
      ship(berth.kind, ShipRole.berth, route, along: route.length * start)
        ..mode = docked
            ? ShipMode.docked
            : i % 4 == 1
            ? ShipMode.sailing
            : ShipMode.leaving
        ..direction = docked || i % 4 == 1 ? 1 : -1
        ..wait = docked ? 14.0 + i * 16 : 0,
    );
  }
  if (sea.ferry.length > 1) {
    ships.add(ship(ShipKind.ferry, ShipRole.ferry, shipRoute(sea.ferry, s, step: 25), along: 300));
  }
  for (final (i, crossing) in sea.crossings.indexed) {
    final route = shipRoute(crossing.points, s, step: 120);
    ships.add(ship(crossing.kind, ShipRole.crossing, route, along: route.length * _crossingStarts[i % 3]));
  }
  for (final (i, loop) in sea.loops.indexed) {
    final route = shipRoute(loop.points, s, closed: true, step: 25);
    final count = loop.kind == ShipKind.sailboat ? _sailboatsPerLoop : 1;
    for (var k = 0; k < count; k++) {
      ships.add(ship(loop.kind, ShipRole.loop, route, along: route.length * ((k + 0.2 + i * 0.37) % 1 + k) / count));
    }
  }
  for (final anchored in sea.anchored) {
    final view = squeezed(anchored.at, s.bounds, s.horizon);
    ships.add(
      ship(random.nextBool() ? ShipKind.cargo : ShipKind.tanker, ShipRole.anchored, null)
        ..heading = anchored.heading
        ..x = view.at.dx
        ..y = view.at.dy
        ..size = view.size
        ..distance = view.distance,
    );
  }
  for (final ship in ships) {
    stepShip(ship, 0, 0, random);
  }
  return most == null || most >= ships.length ? ships : ships.sublist(0, max(0, most));
}

void stepShip(Ship ship, double dt, double clock, Random random) {
  final route = ship.route;
  if (route == null) {
    final heading = ship.heading + sin(clock * 0.05 + ship.seed) * 0.12;
    ship
      ..dx = cos(heading)
      ..dy = sin(heading);
    return;
  }
  final length = route.length;
  var v = ship.speed;
  switch (ship.role) {
    case ShipRole.berth:
      switch (ship.mode) {
        case ShipMode.docked:
          v = 0;
          ship.wait -= dt;
          if (ship.wait <= 0) {
            ship
              ..mode = ShipMode.turning
              ..turn = 0;
          }
        case ShipMode.turning:
          v = 0;
          ship.turn += dt / _turnTime;
          if (ship.turn >= 1) {
            ship
              ..mode = ShipMode.leaving
              ..direction = -1;
          }
        case ShipMode.leaving:
          v *= min(1.0, 0.25 + (length - ship.along) / 500);
          if (ship.along <= 2) {
            // Back from the horizon as another ship
            ship
              ..mode = ShipMode.sailing
              ..direction = 1
              ..along = 0
              ..hull = random.nextInt(1 << 16)
              ..seed = random.nextInt(1 << 20);
          }
        case ShipMode.sailing:
          v *= min(1.0, 0.12 + (length - ship.along) / 420);
          if (ship.along >= length - 1) {
            ship
              ..mode = ShipMode.docked
              ..wait = 30 + random.nextDouble() * 30;
          }
      }
    case ShipRole.ferry:
      if (ship.wait > 0) {
        v = 0;
        ship.wait -= dt;
      } else if ((ship.direction > 0 && ship.along >= length - 1) || (ship.direction < 0 && ship.along <= 1)) {
        ship
          ..direction = -ship.direction
          ..wait = _ferryStop;
        v = 0;
      } else {
        v *= min(1.0, 0.2 + min(ship.along, length - ship.along) / 160);
      }
    case ShipRole.crossing:
      if (ship.along >= length - 1) ship.along = 0;
    case ShipRole.loop || ShipRole.anchored:
      break;
  }

  // Slower on the map far out
  final before = routeAt(route, ship.along);
  ship.along += v * ship.direction * dt * (0.3 + 0.7 * before.size);
  if (!route.closed) ship.along = ship.along.clamp(0.0, length);
  final spot = routeAt(route, ship.along);
  ship
    ..x = spot.x
    ..y = spot.y
    ..size = spot.size
    ..distance = spot.distance;
  if (ship.mode == ShipMode.turning) {
    final angle = atan2(spot.dy, spot.dx) + pi * ship.turn;
    ship
      ..dx = cos(angle)
      ..dy = sin(angle);
  } else {
    // Double-ended ferries never turn round
    final sign = ship.role == ShipRole.ferry ? 1 : ship.direction;
    ship
      ..dx = spot.dx * sign
      ..dy = spot.dy * sign;
  }

  final wake = ship.wake;
  if (v > 1) {
    final last = wake.isEmpty ? null : wake.last;
    if (last == null ||
        (Offset(last.x, last.y) - Offset(ship.x, ship.y)).distance > ship.spec.length * ship.size * 0.45) {
      wake.add((x: ship.x, y: ship.y, at: clock));
      if (wake.length > _wakePoints) wake.removeAt(0);
    }
  }
  while (wake.isNotEmpty && clock - wake.first.at > _wakeLife) {
    wake.removeAt(0);
  }
}

// 0 fresh, 1 gone
double wakeAge(double at, double clock) => (clock - at) / _wakeLife;
