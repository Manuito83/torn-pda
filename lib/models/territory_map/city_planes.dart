import 'dart:math';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/flight_projection.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';

enum PlanePhase { roll, climb, departing, inbound, turn, approach, rollout, taxi, goAround, rejected }

enum PlaneJoke { goAround, plushie, barrelRoll }

const planeJokeTexts = {
  PlaneJoke.goAround: 'Tower: go around, I say again, go around. Plushie on the runway.',
  PlaneJoke.plushie: 'Smuggler spotted. Customs is on its way.',
  PlaneJoke.barrelRoll: 'Captain speaking: the seatbelt sign was a suggestion.',
};

const rejectedTakeoffText = 'Tower: stop immediately, I say again, stop immediately. Plushie on the runway.';

const _barrelRollSeconds = 1.5;
const _plushieLasts = 12.0;

// Until customs gets there
const _smuggledPlushieLasts = 45.0;
const _planeEvery = {LifeDensity.low: (20.0, 32.0), LifeDensity.normal: (11.0, 19.0), LifeDensity.high: (6.0, 10.0)};
const _planesAtOnce = {LifeDensity.low: 3, LifeDensity.normal: 5, LifeDensity.high: 7};
const _hazeEatsPlanes = 1.12;
const _planesGoneAt = 20000.0;

class Plane {
  Plane({
    required this.arriving,
    required this.phase,
    required this.x,
    required this.y,
    required this.z,
    required this.heading,
    required this.speed,
    required this.destination,
    required this.alpha,
    required this.size,
  });

  final bool arriving;
  PlanePhase phase;
  double x, y, z, heading, speed, alpha;
  double bank = 0;

  // Below zero while upside down
  double wing = 1;

  // Map angle towards or from the country
  final double destination;
  final double size;
  double? rollStartedAt;

  // Drawn here, squeezed past the city
  late double mapX = x, mapY = y;
  double shrink = 1;

  // Alpha with the haze
  late double shown = alpha.clamp(0, 1);
}

class Plushie {
  Plushie({
    required this.x,
    required this.y,
    required this.z,
    this.vx = 0,
    this.vy = 0,
    this.landedAt,
    this.customs = false,
  });

  double x, y, z, vx, vy;
  double vz = 0;
  double? landedAt;
  final bool customs;
}

class Airport {
  Airport(CityGround ground, this.city, {this.horizon})
    : arrivals = ground.arrivals,
      departures = ground.departures,
      runwayHeading = atan2(-ground.arrivals.uy, -ground.arrivals.ux),
      center = city.center,
      reach = Size(ground.width / 2 + 900, ground.height / 2 + 900),
      destinations = [
        for (final MapEntry(:key, :value) in flightPlaces.entries)
          if (key != tornPlace) mapAngle(initialBearing(flightPlaces[tornPlace]!, value)),
      ];

  final Runway arrivals, departures;

  // Runway 29, towards the west
  final double runwayHeading;
  final Rect city;
  final Offset center;

  // Without surroundings planes fade past this
  final Size reach;

  // With them, the haze takes them
  final Horizon? horizon;
  final List<double> destinations;
}

double initialBearing(LonLat from, LonLat to) {
  final p1 = from.lat * pi / 180, p2 = to.lat * pi / 180, dl = (to.lon - from.lon) * pi / 180;
  final y = sin(dl) * cos(p2);
  final x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}

// North is up, y grows down
double mapAngle(double bearing) => (bearing - 90) * pi / 180;

double angleTo(double from, double to) {
  var d = to - from;
  while (d > pi) {
    d -= 2 * pi;
  }
  while (d < -pi) {
    d += 2 * pi;
  }
  return d;
}

double nextPlaneIn(LifeDensity density, Random random) {
  final (low, high) = _planeEvery[density]!;
  return low + random.nextDouble() * (high - low);
}

int planesAtOnce(LifeDensity density) => _planesAtOnce[density]!;

Plane departure(Airport airport, Random random, {bool rolling = false}) {
  final r = airport.departures;
  final s = rolling ? r.length * 0.25 : 40;
  return Plane(
    arriving: false,
    phase: PlanePhase.roll,
    x: r.bx - r.ux * s,
    y: r.by - r.uy * s,
    z: 0,
    heading: airport.runwayHeading,
    speed: rolling ? 55 : 0,
    destination: airport.destinations[random.nextInt(airport.destinations.length)],
    alpha: 1,
    size: 36 + random.nextDouble() * 6,
  );
}

Plane arrival(Airport airport, Random random, {bool onFinal = false}) {
  final r = airport.arrivals;
  final destination = airport.destinations[random.nextInt(airport.destinations.length)];
  final size = 36 + random.nextDouble() * 6;
  if (onFinal) {
    const away = 1500.0;
    return Plane(
      arriving: true,
      phase: PlanePhase.approach,
      x: r.bx + r.ux * away,
      y: r.by + r.uy * away,
      z: away * 0.07,
      heading: airport.runwayHeading,
      speed: 115,
      destination: destination,
      alpha: 1,
      size: size,
    );
  }
  final (away, fade) = airport.horizon == null ? (const Size(4600, 3400), 0.0) : (const Size(9500, 8200), 1.0);
  final x = airport.center.dx + cos(destination) * away.width;
  final y = airport.center.dy + sin(destination) * away.height;
  return Plane(
    arriving: true,
    phase: PlanePhase.inbound,
    x: x,
    y: y,
    z: 300,
    heading: atan2(airport.center.dy - y, airport.center.dx - x),
    speed: 190,
    destination: destination,
    alpha: fade,
    size: size,
  );
}

// Takes off by 29L, lands by 29R
void stepPlane(Plane p, double dt, Airport airport) {
  final r = p.arriving ? airport.arrivals : airport.departures;
  final runway = airport.runwayHeading;
  var want = p.heading;
  var turnRate = 0.16;
  switch (p.phase) {
    case PlanePhase.roll:
      p.speed = min(95, p.speed + 9 * dt);
      if (p.speed >= 95) p.phase = PlanePhase.climb;
    case PlanePhase.climb || PlanePhase.goAround:
      want = runway;
      p.speed = min(175, p.speed + 6 * dt);
      p.z += (p.phase == PlanePhase.goAround ? 26 : 20) * dt;
      final passed = (p.x - r.ax) * -r.ux + (p.y - r.ay) * -r.uy;
      if (passed > 300 && p.z > 90) p.phase = PlanePhase.departing;
    case PlanePhase.departing:
      want = p.destination;
      p.speed = min(200, p.speed + 5 * dt);
      p.z = min(320, p.z + 16 * dt);
    case PlanePhase.inbound:
      final fx = r.bx + r.ux * 2600, fy = r.by + r.uy * 2600;
      want = atan2(fy - p.y, fx - p.x);
      p.z += (190 - p.z) * min(1, dt * 0.15);
      if (sqrt(pow(fx - p.x, 2) + pow(fy - p.y, 2)) < 380) p.phase = PlanePhase.turn;
    case PlanePhase.turn:
      want = runway;
      turnRate = 0.3;
      p.speed += (130 - p.speed) * min(1, dt * 0.4);
      if (angleTo(p.heading, runway).abs() < 0.2) p.phase = PlanePhase.approach;
    case PlanePhase.approach:
      final along = (p.x - r.bx) * r.ux + (p.y - r.by) * r.uy;
      final cross = (p.x - r.bx) * -r.uy + (p.y - r.by) * r.ux;
      want = runway + (cross * 0.004).clamp(-0.5, 0.5);
      turnRate = 0.5;
      p.speed += (115 - p.speed) * min(1, dt * 0.5);
      final glide = max(0.0, (along + 160) * 0.07);
      p.z += (glide - p.z) * min(1, dt * 2);
      if (along < -160) {
        p.phase = PlanePhase.rollout;
        p.z = 0;
      }
    case PlanePhase.rollout:
      p.speed = max(18, p.speed - 14 * dt);
      if (p.speed <= 18) p.phase = PlanePhase.taxi;
    case PlanePhase.taxi:
      want = runway - pi / 2;
      turnRate = 0.9;
      p.alpha -= dt * 0.6;
    case PlanePhase.rejected:
      p.speed = max(0, p.speed - 16 * dt);
      if (p.speed == 0) p.alpha -= dt * 0.5;
  }
  final d = angleTo(p.heading, want);
  p.bank = (d * 3).clamp(-1.0, 1.0);
  p.heading += d.clamp(-turnRate * dt, turnRate * dt);
  p.x += cos(p.heading) * p.speed * dt;
  p.y += sin(p.heading) * p.speed * dt;
  if (p.phase == PlanePhase.inbound) p.alpha = min(1, p.alpha + dt * 0.5);

  final horizon = airport.horizon;
  if (horizon == null) {
    final far = max(
      (p.x - airport.center.dx).abs() / airport.reach.width,
      (p.y - airport.center.dy).abs() / airport.reach.height,
    );
    if (p.phase == PlanePhase.departing && far > 1) p.alpha -= dt * 0.8;
    p.mapX = p.x;
    p.mapY = p.y;
    p.shown = p.alpha.clamp(0, 1);
    return;
  }
  final world = Offset(p.x, p.y);
  final view = squeezed(world, airport.city, horizon);
  p.mapX = view.at.dx;
  p.mapY = view.at.dy;
  p.shrink = view.size;
  p.shown = p.alpha.clamp(0, 1) * hazeFade(view.distance, _hazeEatsPlanes);
  if (p.phase == PlanePhase.departing && (p.shown < 0.02 || view.distance > _planesGoneAt)) p.alpha = 0;
}

// Wing span through a barrel roll
double planeWing(Plane plane, double now) {
  final started = plane.rollStartedAt;
  if (started == null) return 1;
  final u = (now - started) / _barrelRollSeconds;
  return u >= 1 ? 1 : cos(u * 2 * pi);
}

// At least 11 pixels, unless far out
double planeLength(Plane plane, double scale) =>
    max(11 / scale * (0.5 + 0.5 * plane.shrink), plane.size * (1 + plane.z / 900) * pow(plane.shrink, 0.8));

Plane? planeAt(Iterable<Plane> planes, Offset point, double scale) {
  Plane? best;
  var bestDistance = double.infinity;
  for (final p in planes) {
    if (p.shown <= 0.2) continue;
    final distance = (Offset(p.mapX, p.mapY) - point).distance * scale;
    if (distance < max(22, planeLength(p, scale) * scale * 0.7) && distance < bestDistance) {
      bestDistance = distance;
      best = p;
    }
  }
  return best;
}

Plane? planeOnScreen(Iterable<Plane> planes, Offset tap, CityProjection p) {
  Plane? best;
  var bestDistance = double.infinity;
  for (final plane in planes) {
    if (plane.alpha <= 0.2 || !p.place(plane.x, plane.y, plane.z)) continue;
    final distance = (Offset(p.sx, p.sy) - tap).distance;
    if (distance < max(22, planeLength(plane, p.k) * p.k * 0.7) && distance < bestDistance) {
      bestDistance = distance;
      best = plane;
    }
  }
  return best;
}

bool jokeFits(PlaneJoke joke, PlanePhase phase) =>
    joke != PlaneJoke.goAround || phase == PlanePhase.approach || phase == PlanePhase.turn || phase == PlanePhase.roll;

// No repeats until the deck runs out
PlaneJoke takeJoke(List<PlaneJoke> deck, PlanePhase phase, Random random) {
  if (deck.isEmpty) deck.addAll(PlaneJoke.values.toList()..shuffle(random));
  final i = deck.indexWhere((joke) => jokeFits(joke, phase));
  return deck.removeAt(i < 0 ? 0 : i);
}

({String text, Plushie? plushie}) playJoke(Plane plane, PlaneJoke joke, Airport airport, double now) {
  if (!jokeFits(joke, plane.phase)) joke = PlaneJoke.barrelRoll;
  switch (joke) {
    case PlaneJoke.goAround:
      final r = plane.arriving ? airport.arrivals : airport.departures;
      final at = plane.phase == PlanePhase.roll ? 0.55 : 0.18;
      final plushie = Plushie(x: r.bx - r.ux * r.length * at, y: r.by - r.uy * r.length * at, z: 0, landedAt: now);
      if (plane.phase == PlanePhase.roll) {
        plane.phase = PlanePhase.rejected;
        return (text: rejectedTakeoffText, plushie: plushie);
      }
      plane.phase = PlanePhase.goAround;
      return (text: planeJokeTexts[joke]!, plushie: plushie);
    case PlaneJoke.plushie:
      final plushie = Plushie(
        x: plane.mapX,
        y: plane.mapY,
        z: max(plane.z, 40),
        vx: cos(plane.heading) * plane.speed * 0.4,
        vy: sin(plane.heading) * plane.speed * 0.4,
        customs: true,
      );
      return (text: planeJokeTexts[joke]!, plushie: plushie);
    case PlaneJoke.barrelRoll:
      plane.rollStartedAt = now;
      return (text: planeJokeTexts[joke]!, plushie: null);
  }
}

// True on the step it lands
bool stepPlushie(Plushie p, double dt, double now) {
  if (p.landedAt != null) return false;
  p.vz -= 60 * dt;
  p.z += p.vz * dt;
  p.x += p.vx * dt;
  p.y += p.vy * dt;
  final drag = pow(0.985, dt * 60);
  p.vx *= drag;
  p.vy *= drag;
  if (p.z > 0) return false;
  p.z = 0;
  p.landedAt = now;
  return true;
}

bool plushieGone(Plushie p, double now) =>
    p.landedAt != null && now - p.landedAt! > (p.customs ? _smuggledPlushieLasts : _plushieLasts);
