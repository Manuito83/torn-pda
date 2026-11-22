import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_gunfire.dart';
import 'package:torn_pda/models/territory_map/city_planes.dart';
import 'package:torn_pda/models/territory_map/city_ships.dart';
import 'package:torn_pda/models/territory_map/city_sky.dart';
import 'package:torn_pda/models/territory_map/city_traffic.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/surroundings_roads.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/providers/city_night_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';

// No cars below this
const carsFromScale = 0.085;

// Screen pixels drawn past the view
const lifeMargin = 60.0;

const _frameEvery = Duration(milliseconds: 33);
const _longestStep = 0.06;

// Planes, traffic, night, gunfire and police
class CityLifeController extends ChangeNotifier {
  CityLifeController(
    this.ground,
    this.file, {
    this.surroundings,
    this.budget = fullOutside,
    Random? random,
    bool withWindows = true,
  }) : airport = Airport(ground, file.bounds, horizon: surroundings?.horizon),
       roads = surroundings == null ? ground.roads : joinRoads(ground.roads, surroundings),
       sky = surroundings == null || budget == noOutside ? null : buildSky(surroundings, budget),
       night = CityNightController(ground, file, withWindows: withWindows),
       _random = random ?? Random();

  final CityGround ground;
  final TerritoryFile file;
  final Surroundings? surroundings;
  final OutsideBudget budget;
  final Airport airport;

  // Clouds, shadows and the sea
  final CitySky? sky;

  // City streets and the roads out
  final RoadGraph roads;
  final CityNightController night;
  final Random _random;

  bool planesOn = false;
  bool trafficOn = false;
  bool gunfireOn = false;
  bool policeOn = false;
  LifeDensity density = LifeDensity.normal;
  List<TerritoryWar> _wars = const [];

  List<Car> cars = const [];
  List<Ship> ships = const [];
  final customs = <ServiceCar>[];
  final police = <ServiceCar>[];
  final planes = <Plane>[];
  final plushies = <Plushie>[];
  final shots = <Shot>[];
  late final _territories = file.territories.values.toList();
  final _warSpots = <String, List<Offset>>{};
  final _nextBurst = <String, double>{};
  final _calls = <(double, Offset)>[];

  // Seconds of life shown so far
  double clock = 0;
  double _nextPlane = 0;
  int _planeTurn = 0;
  double _nextShooting = 0;
  double _nextPatrol = 0;
  final _jokes = <PlaneJoke>[];

  bool _shown = false;
  double _scale = 1;
  Rect _area = Rect.largest;
  bool _seenLastTick = true;
  Timer? _timer;
  final _sinceTick = Stopwatch();

  bool get awake => night.awake;

  bool get _carsShown => trafficOn && _scale >= carsFromScale;

  bool get _moving => planesOn || _carsShown || gunfireOn || policeOn || sky != null;

  void follow(TerritoryMapController map) {
    final planes = map.lifePlanes, traffic = map.lifeTraffic, gunfire = map.lifeGunfire, police = map.lifePolice;
    final density = map.lifeDensity;
    _wars = map.shownWars;
    night.configure(on: map.lifeNight, hour: map.debugTctHour);
    if (planes == planesOn &&
        traffic == trafficOn &&
        gunfire == gunfireOn &&
        police == policeOn &&
        density == this.density) {
      return;
    }
    final newDensity = density != this.density;
    this.density = density;
    if (planes && !planesOn) {
      this.planes
        ..add(arrival(airport, _random, onFinal: true))
        ..add(departure(airport, _random));
      _nextPlane = clock + nextPlaneIn(density, _random);
    } else if (!planes) {
      this.planes.clear();
      plushies.clear();
    }
    if (traffic && (!trafficOn || newDensity)) {
      cars = [
        ...spawnCars(roads, carCount(roads, density), _random),
        ...spawnCars(roads, (outsideCarCount(roads, density) * budget.cars).round(), _random, outside: true),
      ];
    } else if (!traffic) {
      cars = const [];
      customs.clear();
    }
    if (traffic && !trafficOn && surroundings != null) {
      ships = spawnShips(surroundings!.sea, surroundings!, _random, most: budget.ships);
    } else if (!traffic) {
      ships = const [];
    }
    if (!gunfire) {
      shots.clear();
      _calls.clear();
    }
    if (police && !policeOn) {
      _nextPatrol = clock + 6;
    } else if (!police) {
      this.police.clear();
      _calls.clear();
    }
    planesOn = planes;
    trafficOn = traffic;
    gunfireOn = gunfire;
    policeOn = police;
    _sync();
    notifyListeners();
  }

  // Map on screen, app in front
  void show(bool shown) {
    if (shown == _shown) return;
    _shown = shown;
    night.show(shown);
    _sync();
  }

  void lookAt(Rect visible, double scale) {
    _area = visible.inflate(lifeMargin / scale);
    if (scale == _scale) return;
    _scale = scale;
    _sync();
  }

  void wake() {
    night.wake();
    _sync();
  }

  String? tap(Offset point, double scale) => tapPlane(planeAt(planes, point, scale));

  // Null without a plane there
  String? tapPlane(Plane? plane) {
    wake();
    if (!planesOn || plane == null) return null;
    final result = playJoke(plane, takeJoke(_jokes, plane.phase, _random), airport, clock);
    if (result.plushie case final plushie?) plushies.add(plushie);
    notifyListeners();
    return result.text;
  }

  void _sync() {
    if (_shown && awake && _moving) {
      if (_timer != null) return;
      _sinceTick
        ..reset()
        ..start();
      _timer = Timer.periodic(_frameEvery, (_) => _tick());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _tick() {
    if (!awake) return _sync();
    final dt = min(_sinceTick.elapsedMicroseconds / 1e6, _longestStep);
    _sinceTick.reset();
    clock += dt;
    if (planesOn) _stepPlanes(dt);
    if (_carsShown) _stepTraffic(dt);
    if (gunfireOn) _stepGunfire();
    if (policeOn || police.isNotEmpty) _stepPolice(dt);
    for (final ship in ships) {
      stepShip(ship, dt, clock, _random);
    }

    final area = _area;
    bool inView(double x, double y) => area.contains(Offset(x, y));
    final seen =
        _skySeen(area) ||
        ships.any((s) => s.alpha > 0.03 && area.inflate(s.spec.length).contains(Offset(s.x, s.y))) ||
        planes.any((p) => inView(p.mapX, p.mapY)) ||
        plushies.any((p) => inView(p.x, p.y)) ||
        shots.any((s) => inView(s.x, s.y)) ||
        police.any((c) => inView(c.car.x, c.car.y)) ||
        (_carsShown && (cars.any((c) => inView(c.x, c.y)) || customs.any((c) => inView(c.car.x, c.car.y))));
    // One more frame clears what just left
    if (seen || _seenLastTick) notifyListeners();
    _seenLastTick = seen;
  }

  bool _skySeen(Rect area) {
    final sky = this.sky, s = surroundings;
    if (sky == null || s == null) return false;
    if (area.overlaps(sky.sea) && (sky.glints.isNotEmpty || night.level.value.dark >= 0.05)) return true;
    bool near(SkySpot spot) => spot.alpha > 0.02 && area.inflate(spot.width).contains(spot.at);
    final day = night.level.value.dark < 1;
    return sky.clouds.any((c) => near(cloudAt(c, clock, s))) ||
        (day && sky.shadows.any((c) => near(shadowAt(c, clock, s))));
  }

  void _stepPlanes(double dt) {
    if (clock > _nextPlane) {
      _nextPlane = clock + nextPlaneIn(density, _random);
      if (planes.length < planesAtOnce(density)) {
        planes.add((_planeTurn++).isOdd ? departure(airport, _random) : arrival(airport, _random));
      }
    }
    for (final plane in planes) {
      stepPlane(plane, dt, airport);
      plane.wing = planeWing(plane, clock);
    }
    planes.removeWhere((plane) => plane.alpha <= 0);
    for (final plushie in plushies) {
      if (!stepPlushie(plushie, dt, clock) || !plushie.customs || !trafficOn) continue;
      if (carCalledTo(ground.roads, plushie.x, plushie.y, _random) case final car?) {
        customs.add(ServiceCar(car, clock));
      }
    }
    plushies.removeWhere((plushie) => plushieGone(plushie, clock));
  }

  void _stepTraffic(double dt) {
    for (final car in cars) {
      advanceCar(roads, car, car.speed * dt, _random);
    }
    customs.removeWhere((c) => !stepServiceCar(ground.roads, c, dt, clock, _random));
  }

  // Only bursts in view are kept
  void _stepGunfire() {
    for (final war in _wars) {
      final code = war.territory;
      if (clock < (_nextBurst[code] ?? 0)) continue;
      _nextBurst[code] = clock + nextWarBurstIn(density, war, _random);
      final territory = file.territories[code];
      if (territory == null || !_area.overlaps(territory.bounds)) continue;
      final spots = _warSpots[code] ??= warSpots(territory);
      shots.addAll(burst(spots, clock, 2 + _random.nextInt(4), 6, _random, territory: code));
    }
    if (clock > _nextShooting) {
      _nextShooting = clock + nextShootingIn(density, _random);
      final atWar = {for (final war in _wars) war.territory};
      final t = quietTerritory(_territories, atWar, _random);
      final center = t.bounds.center;
      if (_area.overlaps(t.bounds)) {
        shots.addAll(
          burst([center], clock, 2 + _random.nextInt(3), t.bounds.longestSide * 0.2, _random, territory: t.code),
        );
      }
      if (policeOn && _random.nextDouble() < 0.55) _calls.add((clock + 1.5 + _random.nextDouble() * 2.5, center));
    }
    shots.removeWhere((s) => s.overAt(clock));
  }

  void _stepPolice(double dt) {
    final most = policeAtOnce(density);
    if (policeOn && clock > _nextPatrol) {
      _nextPatrol = clock + nextPatrolIn(density, _random);
      if (police.length < most) {
        if (patrolCar(ground.roads, _random) case final car?) police.add(ServiceCar(car, clock));
      }
    }
    for (final (_, spot) in _calls.where((call) => call.$1 <= clock)) {
      if (police.length >= most) break;
      if (carCalledTo(ground.roads, spot.dx, spot.dy, _random) case final car?) police.add(ServiceCar(car, clock));
    }
    _calls.removeWhere((call) => call.$1 <= clock);
    police.removeWhere((c) => !stepServiceCar(ground.roads, c, dt, clock, _random));
  }

  @override
  void dispose() {
    _timer?.cancel();
    night.dispose();
    super.dispose();
  }
}
