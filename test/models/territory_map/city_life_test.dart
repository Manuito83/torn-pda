import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_gunfire.dart';
import 'package:torn_pda/models/territory_map/city_planes.dart';
import 'package:torn_pda/models/territory_map/city_traffic.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/surroundings_roads.dart';

import 'sample_data.dart';

// A crossing at 1, a dead end at 3
//   0 ---- 1 ---- 2
//          |
//          3
CityGround _ground({List<List<num>>? runways}) => parseCityGround(
  jsonEncode({
    'size': [6256, 3648],
    'shapes': {
      'water': [
        [0, 0, 10, 0, 10, 10],
      ],
    },
    'canopy': [],
    'trees': {
      'cell': 12,
      'w': 4,
      'h': 2,
      'bits': base64.encode([0x81]),
    },
    'roads': {
      'nodes': [
        [0, 0],
        [100, 0],
        [200, 0],
        [100, 100],
      ],
      'edges': [
        [
          0,
          1,
          [0, 0, 50, 0, 100, 0],
        ],
        [
          1,
          2,
          [100, 0, 200, 0],
        ],
        [
          1,
          3,
          [100, 0, 100, 100],
        ],
      ],
    },
    'airport': {
      'heading': 112.8,
      'runways':
          runways ??
          [
            [556.6, 80.1, 1725.0, 571.2, 24],
            [684.3, 6.0, 1760.8, 444.7, 23],
          ],
      'hangars': [],
    },
  }),
);

const _city = Rect.fromLTRB(-1, 0, 6256, 3410);

void main() {
  group('ground file', () {
    test('landings on 29R, departures from 29L', () {
      final ground = _ground();
      expect(ground.arrivals.ay, 6.0);
      expect(ground.arrivals.labels, ['11L', '29R']);
      expect(ground.departures.labels, ['11R', '29L']);
    });

    test('one tree per set bit, inside its cell', () {
      final trees = _ground().trees;
      expect(trees, hasLength(2));
      expect(trees[0].x, inInclusiveRange(2, 10));
      expect(trees[0].y, inInclusiveRange(2, 10));
      expect(trees[1].x, inInclusiveRange(38, 46));
      expect(trees[1].y, inInclusiveRange(14, 22));
    });

    test('a ring goes in every cell it touches', () {
      final ground = _ground();
      ground.shapes[GroundKind.field] = [
        Float32List.fromList([1000, 10, 1100, 10, 1100, 50]),
      ];
      final cells = buildGroundCells(ground);
      expect(cells, hasLength(2));
      expect(cells[0].paths.keys, unorderedEquals([GroundKind.water, GroundKind.field]));
      expect(cells[1].paths.keys, [GroundKind.field]);
      expect(cells[1].area.left, groundCellSize);
    });
  });

  group('traffic', () {
    test('a car runs on into the next street and keeps right', () {
      final roads = _ground().roads;
      final car = Car(edge: 0, forward: true, along: 90, speed: 10);
      advanceCar(roads, car, 30, Random(1));
      expect(car.edge, anyOf(1, 2));
      expect(car.along, closeTo(20, 1e-6));
      final (x, y) = car.edge == 1 ? (120.0, 2.6) : (97.4, 20.0);
      expect(car.x, closeTo(x, 1e-4));
      expect(car.y, closeTo(y, 1e-4));
    });

    test('a dead end turns the car back', () {
      final roads = _ground().roads;
      final car = Car(edge: 2, forward: true, along: 95, speed: 10);
      advanceCar(roads, car, 10, Random(1));
      expect(car.edge, 2);
      expect(car.forward, isFalse);
      expect(car.y, closeTo(95, 1e-6));
    });

    test('a route takes the fewest crossings and the car stops at the end', () {
      final roads = _ground().roads;
      expect(routeBetween(roads, 0, 3), [0, 2]);
      expect(nearestNode(roads, 190, 10), 2);

      final car = Car(edge: 0, forward: true, along: 0, speed: 60, route: [2]);
      advanceCar(roads, car, 150, Random(1));
      expect(car.edge, 2);
      expect(car.arrived, isFalse);
      advanceCar(roads, car, 60, Random(1));
      expect(car.arrived, isTrue);
    });
  });

  group('past the city edge', () {
    final ground = cityGroundFromGzip(File('assets/territory_map/neutral-v1.json.bin').readAsBytesSync());
    final around = surroundingsFromGzip(File('assets/territory_map/surroundings-v1.json.bin').readAsBytesSync());
    final roads = joinRoads(ground.roads, around);

    test('a car at a city exit drives on outside', () {
      final exit = around.exits[0]!;
      final street = ground.roads.nodeEdges[exit].single;
      final edge = ground.roads.edges[street];
      final car = Car(edge: street, forward: edge.b == exit, along: edge.length - 1, speed: 20);
      advanceCar(roads, car, 5, Random(1));
      expect(car.edge, greaterThanOrEqualTo(roads.cityEdges));
      final node = Offset(roads.nodes[exit * 2], roads.nodes[exit * 2 + 1]);
      expect((Offset(car.x, car.y) - node).distance, lessThan(10));
    });

    test('a car at a far end comes back by another', () {
      final portal = roads.portals.first;
      final road = roads.nodeEdges[portal].single;
      final edge = roads.edges[road];
      final car = Car(edge: road, forward: edge.b == portal, along: edge.length - 1, speed: 20);
      advanceCar(roads, car, 5, Random(3));
      final now = roads.edges[car.edge];
      expect(roads.portals, contains(car.forward ? now.a : now.b));
      expect(car.along, closeTo(4, 1e-3));
      expect(car.size, lessThan(0.7));
    });

    test('a departure flies on outside until the haze takes it', () {
      final airport = Airport(_ground(), _city, horizon: around.horizon);
      final plane = departure(airport, Random(2));
      var checked = false;
      for (var i = 0; i < 20000 && plane.alpha > 0; i++) {
        stepPlane(plane, 1 / 30, airport);
        if (checked || distanceToRect(Offset(plane.x, plane.y), _city) < 3000) continue;
        checked = true;
        expect(plane.alpha, 1);
        expect(plane.shown, inExclusiveRange(0.2, 1));
        final drawn = Offset(plane.mapX, plane.mapY);
        expect(distanceToRect(drawn, _city), lessThan(3000));
        expect(planeAt([plane], drawn, 0.2), plane);
      }
      expect(checked, isTrue);
      expect(plane.alpha, lessThanOrEqualTo(0));
    });
  });

  test('war gunfire stays inside the territory', () {
    final spots = warSpots(courtyard());
    expect(spots.any((s) => inCourtyardHole(s.dx, s.dy)), isFalse);
    final shots = burst(spots, 10, 5, 0, Random(3));
    for (final shot in shots) {
      expect(spots, contains(Offset(shot.x, shot.y)));
      if (shot.toX != null) expect(spots, contains(Offset(shot.toX!, shot.toY!)));
    }
    expect([for (final s in shots) s.at], orderedEquals([for (final s in shots) s.at]..sort()));
    expect(shots.last.overAt(shots.last.at + 0.05), isFalse);
    expect(shots.last.overAt(shots.last.at + 0.3), isTrue);
  });

  group('planes', () {
    test('a departure turns to its country', () {
      final airport = Airport(_ground(), _city);
      final plane = departure(airport, Random(2));
      final seen = <PlanePhase>{};
      double? gapAtStart;
      for (var i = 0; i < 6000 && plane.alpha > 0; i++) {
        stepPlane(plane, 1 / 30, airport);
        seen.add(plane.phase);
        if (plane.phase == PlanePhase.departing) gapAtStart ??= angleTo(plane.heading, plane.destination).abs();
      }
      expect(seen, containsAll([PlanePhase.roll, PlanePhase.climb, PlanePhase.departing]));
      expect(plane.alpha, lessThanOrEqualTo(0));
      expect(angleTo(plane.heading, plane.destination).abs(), lessThan(gapAtStart! - 1));
    });

    test('an arrival lands past the threshold', () {
      final airport = Airport(_ground(), _city);
      final plane = arrival(airport, Random(2), onFinal: true);
      final seen = <PlanePhase>[];
      for (var i = 0; i < 3000 && plane.alpha > 0; i++) {
        stepPlane(plane, 1 / 30, airport);
        if (seen.isEmpty || seen.last != plane.phase) seen.add(plane.phase);
      }
      expect(seen, [PlanePhase.approach, PlanePhase.rollout, PlanePhase.taxi]);
      final r = airport.arrivals;
      final along = (plane.x - r.bx) * r.ux + (plane.y - r.by) * r.uy;
      expect(along, inInclusiveRange(-r.length, -160));
    });

    test('in 3D a tap hits the plane where it is drawn, up in the air', () {
      final airport = Airport(_ground(), _city);
      final high = departure(airport, Random(2))
        ..x = 3000
        ..y = 1700
        ..z = 400;
      final p = CityProjection((yaw: 0.4, pitch: 0.9, zoom: 0.3, x: 3000, y: 1700), const Size(400, 800));
      final drawn = p.project(high.x, high.y, high.z)!;
      final underneath = p.project(high.x, high.y, 0)!;
      expect((drawn - underneath).distance, greaterThan(40));
      expect(planeOnScreen([high], drawn + const Offset(6, 4), p), high);
      expect(planeOnScreen([high], underneath, p), isNull);
    });

    test('Japan is north-west of Torn, South Africa east', () {
      expect(
        angleTo(mapAngle(initialBearing((lon: -90, lat: 31), (lon: 138, lat: 36))), -3 * pi / 4).abs(),
        lessThan(0.4),
      );
      expect(mapAngle(initialBearing((lon: -90, lat: 31), (lon: 24, lat: -29))).abs(), lessThan(0.5));
    });
  });

  group('jokes', () {
    test('go-around only while landing or rolling', () {
      expect(jokeFits(PlaneJoke.goAround, PlanePhase.approach), isTrue);
      expect(jokeFits(PlaneJoke.goAround, PlanePhase.roll), isTrue);
      expect(jokeFits(PlaneJoke.goAround, PlanePhase.departing), isFalse);
      expect(jokeFits(PlaneJoke.plushie, PlanePhase.departing), isTrue);
    });

    test('the deck plays every joke before repeating one', () {
      final deck = <PlaneJoke>[];
      final random = Random(5);
      final played = [for (var i = 0; i < 3; i++) takeJoke(deck, PlanePhase.approach, random)];
      expect(played.toSet(), PlaneJoke.values.toSet());
    });

    test('a joke that does not fit becomes a barrel roll', () {
      final airport = Airport(_ground(), _city);
      final plane = departure(airport, Random(1))..phase = PlanePhase.departing;
      final result = playJoke(plane, PlaneJoke.goAround, airport, 10);
      expect(result.text, planeJokeTexts[PlaneJoke.barrelRoll]);
      expect(plane.rollStartedAt, 10);
      expect(planeWing(plane, 10.75), closeTo(-1, 1e-9));
      expect(planeWing(plane, 11.6), 1);
    });

    test('a plushie on the runway stops a takeoff roll', () {
      final airport = Airport(_ground(), _city);
      final plane = departure(airport, Random(1), rolling: true);
      final result = playJoke(plane, PlaneJoke.goAround, airport, 0);
      expect(result.text, rejectedTakeoffText);
      expect(plane.phase, PlanePhase.rejected);
      for (var i = 0; i < 600; i++) {
        stepPlane(plane, 1 / 30, airport);
      }
      expect(plane.speed, 0);
      expect(plane.alpha, lessThanOrEqualTo(0));
    });

    test('a landing plane goes around and climbs away', () {
      final airport = Airport(_ground(), _city);
      final plane = arrival(airport, Random(1), onFinal: true);
      playJoke(plane, PlaneJoke.goAround, airport, 0);
      expect(plane.phase, PlanePhase.goAround);
      final start = plane.z;
      for (var i = 0; i < 300; i++) {
        stepPlane(plane, 1 / 30, airport);
      }
      expect(plane.z, greaterThan(start + 100));
    });

    test('a go-around in the base turn still leaves the map', () {
      final airport = Airport(_ground(), _city);
      for (var seed = 0; seed < 12; seed++) {
        final plane = arrival(airport, Random(seed));
        while (plane.phase == PlanePhase.inbound) {
          stepPlane(plane, 1 / 30, airport);
        }
        playJoke(plane, PlaneJoke.goAround, airport, 0);
        for (var i = 0; i < 18000 && plane.alpha > 0; i++) {
          stepPlane(plane, 1 / 30, airport);
        }
        expect(plane.alpha, lessThanOrEqualTo(0));
      }
    });

    test('a dropped plushie waits for customs', () {
      final airport = Airport(_ground(), _city);
      final plane = departure(airport, Random(1))
        ..phase = PlanePhase.departing
        ..z = 200
        ..speed = 180;
      final plushie = playJoke(plane, PlaneJoke.plushie, airport, 0).plushie!;
      expect(plushie.customs, isTrue);
      var landings = 0;
      for (var i = 0; i < 600; i++) {
        if (stepPlushie(plushie, 1 / 30, i / 30)) landings++;
      }
      expect(landings, 1);
      expect(plushie.z, 0);
      expect(plushieGone(plushie, plushie.landedAt! + 13), isFalse);
      expect(plushieGone(plushie, plushie.landedAt! + 46), isTrue);
    });
  });
}
