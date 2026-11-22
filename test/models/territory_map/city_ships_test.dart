import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/city_ships.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/sea_chart.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';

void main() {
  final around = surroundingsFromGzip(File('assets/territory_map/surroundings-v1.json.bin').readAsBytesSync());
  final sea = around.sea;

  test('a cargo ship sails in, docks, turns round and leaves', () {
    final berth = sea.berths.firstWhere((b) => b.kind == ShipKind.cargo);
    final route = shipRoute([...sea.channel, ...berth.points], around);
    final ship = Ship(ShipKind.cargo, ShipRole.berth, route, speed: 17, hull: 0, seed: 0);
    final random = Random(4);
    var clock = 0.0;
    void runUntil(ShipMode mode) {
      for (var i = 0; i < 100000 && ship.mode != mode; i++) {
        clock += 0.5;
        stepShip(ship, 0.5, clock, random);
      }
      expect(ship.mode, mode);
    }

    stepShip(ship, 0, clock, random);
    expect(ship.alpha, lessThan(0.3));
    runUntil(ShipMode.docked);
    expect(ship.alpha, greaterThan(0.95));
    final quay = towardsHorizon(berth.points.last, around.bounds, around.horizon);
    expect((Offset(ship.x, ship.y) - quay).distance, lessThan(2));
    final inbound = Offset(ship.dx, ship.dy);
    expect(ship.wake, isNotEmpty);

    runUntil(ShipMode.turning);
    runUntil(ShipMode.leaving);
    clock += 1;
    stepShip(ship, 1, clock, random);
    expect(ship.dx * inbound.dx + ship.dy * inbound.dy, closeTo(-1, 0.05));

    runUntil(ShipMode.sailing);
    expect(ship.along, lessThan(route.length * 0.01));
  });

  test('ship routes stay on the water', () {
    final ground = cityGroundFromGzip(File('assets/territory_map/neutral-v1.json.bin').readAsBytesSync());
    final water = ground.shapes[GroundKind.water]!;
    final land = [
      for (final shape in [
        StripShape.southField,
        StripShape.southSand,
        StripShape.southShore,
        StripShape.southStructure,
        StripShape.southTrees,
        StripShape.piers,
        StripShape.portStructures,
        StripShape.fields,
        StripShape.sand,
      ])
        ...around.shapes[shape]!,
    ];
    final routes = [
      for (final berth in sea.berths) ([...sea.channel, ...berth.points], false),
      for (final loop in sea.loops) (loop.points, true),
      (sea.ferry, false),
      for (final crossing in sea.crossings) (crossing.points, false),
    ];
    for (final (points, closed) in routes) {
      for (final p in smoothRoute(points, closed: closed, step: 15)) {
        final ashore = around.bounds.contains(p)
            ? !water.any((ring) => insideRing(p.dx, p.dy, ring))
            : land.any((ring) => insideRing(p.dx, p.dy, ring));
        expect(ashore, isFalse, reason: '$p');
      }
    }
    for (final anchored in sea.anchored) {
      expect(land.any((ring) => insideRing(anchored.at.dx, anchored.at.dy, ring)), isFalse);
    }
  });
}
