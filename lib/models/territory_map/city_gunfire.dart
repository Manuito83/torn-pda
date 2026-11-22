import 'dart:math';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

// Scaled like the traffic density
const _rates = {LifeDensity.low: 0.5, LifeDensity.normal: 1.0, LifeDensity.high: 1.7};

const _spotsPerWar = 40;
const tracerLife = 0.22;

class Shot {
  Shot(this.x, this.y, this.at, this.life, {this.toX, this.toY, this.territory});

  // Flash life in seconds
  final double x, y, at, life;

  // Null for a flash without a tracer
  final double? toX, toY;

  // Code, for the 3D roof
  final String? territory;

  bool overAt(double now) => now - at > (toX == null ? life : max(life, tracerLife));
}

double _between(Random random, double low, double high) => low + random.nextDouble() * (high - low);

double nextWarBurstIn(LifeDensity density, TerritoryWar war, Random random) {
  final fighting = war.aggressor.score + war.defender.score > 0;
  return _between(random, 0.25, 0.9) / (fighting ? 2.2 : 1) / _rates[density]!;
}

double nextShootingIn(LifeDensity density, Random random) => _between(random, 3.5, 9) / _rates[density]!;

// Same spots every time
List<Offset> warSpots(Territory territory) {
  final rings = flattenRings(territory);
  final b = territory.bounds;
  final seed = territory.code.codeUnits.fold(0, (sum, unit) => (sum * 31 + unit) & 0xFFFFFF);
  final spots = <Offset>[];
  for (var i = 0; spots.length < _spotsPerWar && i < 600; i++) {
    final x = b.left + groundHash(seed * 131 + i) * b.width;
    final y = b.top + groundHash(seed * 131 + i + 999) * b.height;
    if (insideTerritory(rings, x, y)) spots.add(Offset(x, y));
  }
  return spots.isEmpty ? [b.center] : spots;
}

// Quick flashes, most with a tracer
List<Shot> burst(List<Offset> spots, double now, int count, double spread, Random random, {String? territory}) {
  Offset near(Offset spot) =>
      Offset(spot.dx + _between(random, -spread, spread), spot.dy + _between(random, -spread, spread));
  final shots = <Shot>[];
  var at = now;
  for (var i = 0; i < count; i++) {
    final from = near(spots[random.nextInt(spots.length)]);
    final to = near(spots[random.nextInt(spots.length)]);
    final tracer = random.nextDouble() < 0.6;
    shots.add(
      Shot(
        from.dx,
        from.dy,
        at,
        _between(random, 0.09, 0.16),
        toX: tracer ? to.dx : null,
        toY: tracer ? to.dy : null,
        territory: territory,
      ),
    );
    at += _between(random, 0.04, 0.14);
  }
  return shots;
}

// Rather away from the wars
Territory quietTerritory(List<Territory> territories, Set<String> atWar, Random random) {
  var t = territories[random.nextInt(territories.length)];
  for (var i = 0; i < 5 && atWar.contains(t.code); i++) {
    t = territories[random.nextInt(territories.length)];
  }
  return t;
}

double nextPatrolIn(LifeDensity density, Random random) => _between(random, 22, 40) / _rates[density]!;

int policeAtOnce(LifeDensity density) => (3 * _rates[density]!).round();
