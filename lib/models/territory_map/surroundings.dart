import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/city_night.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/sea_chart.dart';

const _mountainTreesFrom = 300.0;
const _dashOn = 14.0;
const _dashOff = 12.0;
const _exitGap = 15.0;
const _exitReach = 30.0;

// Strip shapes, painted in this order
enum StripShape {
  shallows,
  water,
  creek,
  sand,
  fields,
  field,
  airportGrove,
  airportGrass,
  airportApron,
  airportIslands,
  southRunway,
  hangars,
  blocks0,
  blocks1,
  blocks2,
  blocks3,
  blocks4,
  parks,
  closures,
  closureEdges,
  southField,
  southSand,
  southShore,
  southStructure,
  southTrees,
  streets,
  roads,
  highways,
  centerDashes,
  portStructures,
  structure,
  breakwater,
  piers,
  stadium,
  stadiumLawn,
}

// Fading out, nearest first
const blockShapes = [
  StripShape.blocks0,
  StripShape.blocks1,
  StripShape.blocks2,
  StripShape.blocks3,
  StripShape.blocks4,
];

const _southShapes = {
  'field': StripShape.southField,
  'sand': StripShape.southSand,
  'shore': StripShape.southShore,
  'structure': StripShape.southStructure,
  'trees': StripShape.southTrees,
};

const _roadShapes = [StripShape.highways, StripShape.roads, StripShape.streets];

const openStripShapes = {StripShape.closureEdges, StripShape.centerDashes, StripShape.breakwater};

typedef StripCell = ShapeCell<StripShape>;

class Surroundings {
  Surroundings({
    required this.bounds,
    required this.horizon,
    required this.far,
    required this.mid,
    required this.near,
    required this.shapes,
    required this.bridges,
    required this.containers,
    required this.chimneys,
    required this.approachLights,
    required this.cityTrees,
    required this.mountainTrees,
    required this.windows,
    required this.lamps,
    required this.closures,
    required this.roads,
    required this.exits,
    required this.sea,
  });

  final Rect bounds;
  final Horizon horizon;

  // Covered by each photo
  final Rect far, mid, near;
  final Map<StripShape, List<Float32List>> shapes;

  // Starts and ends on the city edge
  final List<({String code, Float32List ring})> closures;

  // In world units, before the squeeze
  final RoadGraph roads;

  // Outside node to city node
  final Map<int, int> exits;
  final SeaChart sea;
  final List<({double width, Float32List line})> bridges;

  // x, y, color
  final Float32List containers;
  final Float32List chimneys;
  final Float32List approachLights;

  // x, y, radius
  final Float32List cityTrees, mountainTrees;
  final Float32List windows;
  final Float32List lamps;
}

List<Float32List> dashLine(Float32List line, double on, double off) {
  final out = <Float32List>[];
  var drawing = true;
  var left = on;
  var piece = <double>[line[0], line[1]];
  for (var i = 0; i + 3 < line.length; i += 2) {
    var x = line[i], y = line[i + 1];
    final x1 = line[i + 2], y1 = line[i + 3];
    var segment = sqrt(pow(x1 - x, 2) + pow(y1 - y, 2));
    while (segment > 1e-6) {
      final step = min(left, segment);
      x += (x1 - x) * step / segment;
      y += (y1 - y) * step / segment;
      segment -= step;
      left -= step;
      if (drawing) piece.addAll([x, y]);
      if (left > 1e-6) continue;
      if (drawing) out.add(Float32List.fromList(piece));
      drawing = !drawing;
      left = drawing ? on : off;
      piece = [x, y];
    }
  }
  if (drawing && piece.length >= 4) out.add(Float32List.fromList(piece));
  return out;
}

Surroundings surroundingsFromGzip(Uint8List bytes) => parseSurroundings(utf8.decode(gzip.decode(bytes)));

Surroundings parseSurroundings(String text) {
  final json = jsonDecode(text) as Map<String, dynamic>;
  Float32List ring(List values) => Float32List.fromList([for (final v in values) (v as num).toDouble()]);
  List<Float32List> rings(List values) => [for (final r in values) ring(r as List)];
  Rect rect(List v) => Rect.fromLTRB(
    (v[0] as num).toDouble(),
    (v[1] as num).toDouble(),
    (v[2] as num).toDouble(),
    (v[3] as num).toDouble(),
  );
  Int16List pairs(String encoded) {
    final data = ByteData.sublistView(base64.decode(encoded));
    return Int16List.fromList([for (var i = 0; i < data.lengthInBytes; i += 2) data.getInt16(i, Endian.little)]);
  }

  final bounds = rect(json['bounds'] as List);
  // Exits start short of the city edge
  Float32List ribbon(List values) {
    final r = ring(values), n = r.length;
    for (final (end, next) in [(0, 2), (n - 2, n - 4)]) {
      final at = Offset(r[end], r[end + 1]);
      final gap = distanceToRect(at, bounds);
      if (gap == 0 || gap > _exitGap) continue;
      final step = at - Offset(r[next], r[next + 1]);
      final reach = at + step / step.distance * _exitReach;
      r
        ..[end] = reach.dx
        ..[end + 1] = reach.dy;
    }
    return r;
  }

  final horizon = json['horizon'] as Map<String, dynamic>;
  final images = json['images'] as Map<String, dynamic>;
  final ground = json['ground'] as Map<String, dynamic>;
  final airport = json['airport'] as Map<String, dynamic>;
  final roads = json['roads'] as Map<String, dynamic>;
  final port = json['port'] as Map<String, dynamic>;
  final closures = [
    for (final c in json['closures'] as List) (code: (c as List)[0] as String, ring: ring(c[1] as List)),
  ];
  final lines = [for (final l in roads['lines'] as List) (kind: (l as List)[0] as int, points: l[1] as List)];

  final shapes = <StripShape, List<Float32List>>{
    StripShape.shallows: rings(json['shallows'] as List),
    StripShape.water: rings(json['water'] as List),
    StripShape.creek: [ring(json['creek'] as List)],
    StripShape.sand: rings(json['sand'] as List),
    StripShape.fields: rings(json['fields'] as List),
    StripShape.field: rings(ground['field'] as List),
    StripShape.airportGrove: [ring(airport['grove'] as List)],
    StripShape.airportGrass: rings(airport['grass'] as List),
    StripShape.airportApron: rings(airport['apron'] as List),
    StripShape.airportIslands: rings(airport['islands'] as List),
    StripShape.southRunway: [ring(airport['southRunway'] as List)],
    StripShape.hangars: rings(airport['hangars'] as List),
    for (final b in json['blocks'] as List) blockShapes[(b as List)[0] as int]: rings(b[1] as List),
    StripShape.parks: rings(json['parks'] as List),
    StripShape.closures: [for (final c in closures) c.ring],
    StripShape.closureEdges: [for (final c in closures) c.ring],
    for (final MapEntry(:key, :value) in (json['south'] as Map<String, dynamic>).entries)
      if (_southShapes[key] case final shape?) shape: rings(value as List),
    for (final (i, shape) in _roadShapes.indexed)
      shape: [
        for (final r in roads['ribbons'] as List)
          if ((r as List)[0] == i) ribbon(r[1] as List),
      ],
    StripShape.centerDashes: [
      for (final l in lines)
        if (l.kind == 0) ...dashLine(ring(l.points), _dashOn, _dashOff),
    ],
    StripShape.portStructures: rings(port['structures'] as List),
    StripShape.structure: rings(ground['structure'] as List),
    StripShape.breakwater: [ring(port['breakwater'] as List)],
    StripShape.piers: rings(port['piers'] as List),
    StripShape.stadium: [ring((port['stadium'] as List)[0] as List)],
    StripShape.stadiumLawn: [ring((port['stadium'] as List)[1] as List)],
  };

  final cityTrees = <double>[], mountainTrees = <double>[];
  final trees = pairs(json['trees'] as String);
  for (var i = 0; i < trees.length; i += 2) {
    final x = trees[i].toDouble(), y = trees[i + 1].toDouble();
    final out = distanceToRect(Offset(x, y), bounds) > _mountainTreesFrom ? mountainTrees : cityTrees;
    out.addAll([x, y, 4.2 + groundHash(i + 13) * 2.6]);
  }

  return Surroundings(
    bounds: bounds,
    horizon: (flat: (horizon['flat'] as num).toDouble(), length: (horizon['length'] as num).toDouble()),
    far: rect(images['far'] as List),
    mid: rect(images['mid'] as List),
    near: rect(images['near'] as List),
    shapes: shapes,
    bridges: [
      for (final b in roads['bridges'] as List) (width: ((b as List)[1] as num).toDouble(), line: ring(b[2] as List)),
    ],
    containers: ring(port['containers'] as List),
    chimneys: ring(port['chimneys'] as List),
    approachLights: ring(airport['approachLights'] as List),
    cityTrees: Float32List.fromList(cityTrees),
    mountainTrees: Float32List.fromList(mountainTrees),
    windows: Float32List.fromList(pairs(json['windows'] as String).map((v) => v.toDouble()).toList()),
    lamps: streetLamps([for (final l in lines) RoadEdge.fromPoints(0, 0, l.points)]),
    closures: closures,
    roads: RoadGraph(
      Float32List.fromList([
        for (final n in roads['nodes'] as List) ...[for (final v in n as List) (v as num).toDouble()],
      ]),
      [
        for (final e in roads['edges'] as List)
          RoadEdge.fromPoints((e as List)[0] as int, e[1] as int, e[3] as List, kind: e[2] as int),
      ],
      portals: (roads['portals'] as List).cast<int>(),
    ),
    exits: {
      for (final MapEntry(:key, :value) in (roads['exits'] as Map<String, dynamic>).entries)
        int.parse(key): value as int,
    },
    sea: seaChartFromJson(json['ships'] as Map<String, dynamic>),
  );
}

// Sector code of the closure there
String? closureAt(Surroundings s, Offset point) {
  for (final c in s.closures) {
    if (insideRing(point.dx, point.dy, c.ring)) return c.code;
  }
  return null;
}

typedef ClosurePath = ({Path area, Path edge});

Map<String, ClosurePath> buildClosurePaths(Surroundings s) {
  final out = <String, ClosurePath>{};
  for (final c in s.closures) {
    final points = [for (var i = 0; i < c.ring.length; i += 2) Offset(c.ring[i], c.ring[i + 1])];
    final path = out[c.code] ??= (area: Path(), edge: Path());
    path.area.addPolygon(points, true);
    path.edge.addPolygon(points, false);
  }
  return out;
}

List<StripCell> buildStripCells(Surroundings s) => buildShapeCells(s.shapes, s.near, open: openStripShapes);
