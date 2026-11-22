import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

String readGzip(String path) => utf8.decode(gzip.decode(File(path).readAsBytesSync()));

TerritoryFile wholeCity() => parseTerritoryFile(readGzip('assets/territory_map/territories-v1.json.bin'));

TerritoryFile sectorsOneAndTwo() =>
    parseTerritoryFile(readGzip('test/models/territory_map/fixtures/territories-sectors-1-2.json.gz'));

MapState sampleState() => parseMapState(readGzip('test/models/territory_map/fixtures/state.json.gz'));

Territory territory(String code, List<String> neighbors, {int slots = 1, int respect = 1, Rect bounds = Rect.zero}) =>
    Territory(
      code: code,
      sector: 1,
      size: 1,
      density: 1,
      slots: slots,
      respect: respect,
      label: Offset.zero,
      neighbors: neighbors,
      verbs: Uint8List(0),
      points: Float32List(0),
      bounds: bounds,
    );

Ownership owned(int factionId) => Ownership(factionId: factionId, acquiredAt: null, irradiated: false);

final scoreTime = DateTime.utc(2026, 11, 4, 21);

TerritoryWar liveWar({
  int score = 0,
  int attackers = 0,
  int defenders = 0,
  double rate = 0,
  int target = 300000,
  int hoursLeft = 48,
  String code = 'RCD',
  WarIdle? idle,
  int id = 1,
  int aggressorId = 1,
}) {
  WarSide side(int id, int score, int wall, double rate) =>
      WarSide(factionId: id, score: score, chain: 0, wall: wall, ratePerMinute: rate);
  return TerritoryWar(
    id: id,
    territory: code,
    start: scoreTime.subtract(const Duration(hours: 24)),
    scheduledEnd: scoreTime.add(Duration(hours: hoursLeft)),
    target: target,
    aggressor: side(aggressorId, score, attackers, rate),
    defender: side(2, 0, defenders, 0),
    scoreAt: scoreTime,
    idle: idle,
  );
}

RecentWar endedWar({
  required String code,
  required DateTime endedAt,
  WarResult result = WarResult.failAssault,
  int aggressor = 1,
  int defender = 2,
  int id = 2,
}) => RecentWar(
  id: id,
  territory: code,
  start: endedAt.subtract(const Duration(hours: 72)),
  endedAt: endedAt,
  result: result,
  aggressorId: aggressor,
  defenderId: defender,
  score: 0,
  target: 300000,
);

// Square with a square hole
Territory courtyard({int density = 1}) => Territory(
  code: 'AAA',
  sector: 1,
  size: 1,
  density: density,
  slots: 1,
  respect: 1,
  label: Offset.zero,
  neighbors: const [],
  verbs: Uint8List.fromList([
    moveToVerb,
    lineToVerb,
    lineToVerb,
    lineToVerb,
    closeVerb,
    moveToVerb,
    lineToVerb,
    lineToVerb,
    lineToVerb,
    closeVerb,
  ]),
  points: Float32List.fromList([0, 0, 200, 0, 200, 200, 0, 200, 50, 50, 50, 150, 150, 150, 150, 50]),
  bounds: const Rect.fromLTWH(0, 0, 200, 200),
);

bool inCourtyardHole(double x, double y) => x > 50 && x < 150 && y > 50 && y < 150;
