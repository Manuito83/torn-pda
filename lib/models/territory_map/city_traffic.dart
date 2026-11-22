import 'dart:math';
import 'dart:typed_data';

import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';

const carColorCount = 5;

// Units off the middle, by road kind
const _keepRight = [6.0, 3.6, 2.6, 2.6];

// Lowest speed and spread, by road kind
const _speeds = [(30.0, 9.0), (22.0, 7.0), (14.0, 5.0), (13.0, 9.0)];

const _roadPerCar = {LifeDensity.low: 110.0, LifeDensity.normal: 55.0, LifeDensity.high: 32.0};

// Fewer outside, no gap at the edge
const _outsideRoadPerCar = {LifeDensity.low: 180.0, LifeDensity.normal: 90.0, LifeDensity.high: 52.0};

class Car {
  Car({
    required this.edge,
    required this.forward,
    required this.along,
    required this.speed,
    this.color = 0,
    this.route,
  });

  int edge;
  bool forward;
  double along;
  double speed;
  final int color;

  // Null drives at random
  final List<int>? route;
  bool arrived = false;

  double x = 0, y = 0, dx = 1, dy = 0;

  // Smaller and fainter towards the horizon
  double size = 1, alpha = 1;
}

int carCount(RoadGraph roads, LifeDensity density) => (roads.cityLength / _roadPerCar[density]!).round();

int outsideCarCount(RoadGraph roads, LifeDensity density) =>
    ((roads.length - roads.cityLength) / _outsideRoadPerCar[density]!).round();

double _speedOn(int kind, Random random) {
  final (low, spread) = _speeds[max(0, kind)];
  return low + random.nextDouble() * spread;
}

// On the city's streets or past them
List<Car> spawnCars(RoadGraph roads, int count, Random random, {bool outside = false}) {
  final from = outside ? roads.cityEdges : 0;
  final to = outside ? roads.edges.length : roads.cityEdges;
  final length = outside ? roads.length - roads.cityLength : roads.cityLength;
  final cars = <Car>[];
  for (var i = 0; i < count && to > from; i++) {
    var at = random.nextDouble() * length;
    var edge = from;
    while (at > roads.edges[edge].length && edge < to - 1) {
      at -= roads.edges[edge].length;
      edge++;
    }
    final car = Car(
      edge: edge,
      forward: random.nextBool(),
      along: at,
      speed: _speedOn(roads.edges[edge].kind, random),
      color: random.nextInt(carColorCount),
    );
    advanceCar(roads, car, 0, random);
    cars.add(car);
  }
  return cars;
}

double _between(Float32List? values, int k, double u) =>
    values == null ? 1 : values[k] + (values[k + 1] - values[k]) * u;

// Random turns, U-turns, portals swap
void advanceCar(RoadGraph roads, Car car, double distance, Random random) {
  car.along += distance;
  var edge = roads.edges[car.edge];
  for (var guard = 0; car.along > edge.length && guard < 8; guard++) {
    car.along -= edge.length;
    var node = car.forward ? edge.b : edge.a;
    final route = car.route;
    int next;
    if (route != null && route.isNotEmpty) {
      next = route.removeAt(0);
    } else if (roads.portals.contains(node)) {
      node = roads.portals[random.nextInt(roads.portals.length)];
      next = roads.nodeEdges[node].first;
    } else {
      final ways = [
        for (final e in roads.nodeEdges[node])
          if (e != car.edge) e,
      ];
      next = ways.isEmpty ? car.edge : ways[random.nextInt(ways.length)];
      if (route != null) car.arrived = true;
    }
    final kind = edge.kind;
    car.edge = next;
    edge = roads.edges[next];
    car.forward = edge.a == node;
    if (edge.kind != kind) car.speed = _speedOn(edge.kind, random);
  }

  final d = (car.forward ? car.along : edge.length - car.along).clamp(0.0, edge.length);
  final last = edge.xs.length - 2;
  var k = 0;
  while (k < last && edge.cumulative[k + 1] < d) {
    k++;
  }
  var segment = edge.cumulative[k + 1] - edge.cumulative[k];
  if (segment == 0) segment = 1;
  final u = (d - edge.cumulative[k]) / segment;
  final mx = edge.xs[k + 1] - edge.xs[k], my = edge.ys[k + 1] - edge.ys[k];
  // Outside, drawn length differs from driven
  var drawn = sqrt(mx * mx + my * my);
  if (drawn == 0) drawn = 1;
  var dx = mx / drawn, dy = my / drawn;
  if (!car.forward) {
    dx = -dx;
    dy = -dy;
  }
  car.size = _between(edge.sizes, k, u);
  car.alpha = edge.kind == tunnelRoad ? 0 : _between(edge.fades, k, u);
  final lane = _keepRight[max(0, edge.kind)] * car.size;
  car.x = edge.xs[k] + mx * u - dy * lane;
  car.y = edge.ys[k] + my * u + dx * lane;
  car.dx = dx;
  car.dy = dy;
}

int nearestNode(RoadGraph roads, double x, double y) {
  var best = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < roads.nodeCount; i++) {
    if (roads.nodeEdges[i].isEmpty) continue;
    final dx = roads.nodes[i * 2] - x, dy = roads.nodes[i * 2 + 1] - y;
    final distance = dx * dx + dy * dy;
    if (distance < bestDistance) {
      bestDistance = distance;
      best = i;
    }
  }
  return best;
}

// Fewest crossings, null when cut off
List<int>? routeBetween(RoadGraph roads, int from, int to) {
  final previous = List.filled(roads.nodeCount, -2);
  final via = List.filled(roads.nodeCount, 0);
  previous[from] = -1;
  final queue = [from];
  for (var i = 0; i < queue.length && queue[i] != to; i++) {
    final node = queue[i];
    for (final e in roads.nodeEdges[node]) {
      final edge = roads.edges[e];
      final other = edge.a == node ? edge.b : edge.a;
      if (previous[other] != -2) continue;
      previous[other] = node;
      via[other] = e;
      queue.add(other);
    }
  }
  if (previous[to] == -2) return null;
  final path = <int>[];
  for (var node = to; previous[node] != -1; node = previous[node]) {
    path.insert(0, via[node]);
  }
  return path;
}

// Customs and police
class ServiceCar {
  ServiceCar(this.car, this.born);

  final Car car;
  final double born;
  double? parkedAt;
  double alpha = 0;
}

// False once it has faded out
bool stepServiceCar(RoadGraph roads, ServiceCar service, double dt, double now, Random random) {
  service.alpha = min(1, service.alpha + dt * 2);
  if (service.car.arrived) service.parkedAt ??= now;
  final parkedAt = service.parkedAt;
  if (parkedAt == null) {
    advanceCar(roads, service.car, service.car.speed * dt, random);
  } else if (now - parkedAt > 6) {
    service.alpha -= dt * 3;
  }
  if (now - service.born > 90) service.alpha = 0;
  return service.alpha > 0;
}

Car? _carTo(RoadGraph roads, int goal, Random random, {required double near, required double far, double speed = 60}) {
  final gx = roads.nodes[goal * 2], gy = roads.nodes[goal * 2 + 1];
  for (var tries = 0; tries < 40; tries++) {
    final start = random.nextInt(roads.nodeCount);
    if (roads.nodeEdges[start].isEmpty) continue;
    final distance = sqrt(pow(roads.nodes[start * 2] - gx, 2) + pow(roads.nodes[start * 2 + 1] - gy, 2));
    if (distance < near || distance > far) continue;
    final route = routeBetween(roads, start, goal);
    if (route == null || route.isEmpty) continue;
    final first = route.removeAt(0);
    final car = Car(edge: first, forward: roads.edges[first].a == start, along: 0, speed: speed, route: route);
    advanceCar(roads, car, 0, random);
    return car;
  }
  return null;
}

// From some streets away to the spot
Car? carCalledTo(RoadGraph roads, double x, double y, Random random) =>
    _carTo(roads, nearestNode(roads, x, y), random, near: 250, far: 1100);

// Slow, across town
Car? patrolCar(RoadGraph roads, Random random) {
  final goal = random.nextInt(roads.nodeCount);
  if (roads.nodeEdges[goal].isEmpty) return null;
  return _carTo(roads, goal, random, near: 500, far: 2600, speed: 30);
}
