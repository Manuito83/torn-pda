import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

// Painted in this order
enum GroundKind { field, park, sand, shore, water, airfield, apron, road, trees, structure }

typedef GroundTree = ({double x, double y, double radius});

class Runway {
  Runway(this.ax, this.ay, this.bx, this.by, this.width, this.labels)
    : length = sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay)) {
    ux = (bx - ax) / length;
    uy = (by - ay) / length;
  }

  final double ax, ay, bx, by, width, length;
  late final double ux, uy;

  // Painted at the a and b ends
  final List<String> labels;
}

// Outside: highway 0, road 1, street 2
const cityStreet = 3;
const tunnelRoad = -1;

class RoadEdge {
  RoadEdge(this.a, this.b, this.xs, this.ys, this.cumulative, {this.kind = cityStreet, this.sizes, this.fades});

  // Flat x, y from the file
  factory RoadEdge.fromPoints(int a, int b, List points, {int kind = cityStreet}) {
    final count = points.length ~/ 2;
    final xs = Float32List(count), ys = Float32List(count), cumulative = Float32List(count);
    for (var i = 0; i < count; i++) {
      xs[i] = (points[i * 2] as num).toDouble();
      ys[i] = (points[i * 2 + 1] as num).toDouble();
      if (i > 0) cumulative[i] = cumulative[i - 1] + sqrt(pow(xs[i] - xs[i - 1], 2) + pow(ys[i] - ys[i - 1], 2));
    }
    return RoadEdge(a, b, xs, ys, cumulative, kind: kind);
  }

  final int a, b;
  final Float32List xs, ys, cumulative;
  final int kind;

  // Outside: drawn size and alpha per point
  final Float32List? sizes, fades;

  double get length => cumulative.last;
}

class RoadGraph {
  RoadGraph(this.nodes, this.edges, {this.portals = const [], int? cityEdges})
    : cityEdges = cityEdges ?? edges.length,
      nodeEdges = List.generate(nodes.length ~/ 2, (_) => <int>[]),
      length = edges.fold(0.0, (sum, e) => sum + e.length) {
    for (var i = 0; i < edges.length; i++) {
      nodeEdges[edges[i].a].add(i);
      if (edges[i].b != edges[i].a) nodeEdges[edges[i].b].add(i);
    }
  }

  // Flat x, y
  final Float32List nodes;
  final List<RoadEdge> edges;
  final List<List<int>> nodeEdges;
  final double length;

  // Far ends, cars come back by another
  final List<int> portals;

  // Edges before this are the city's
  final int cityEdges;
  late final double cityLength = edges.take(cityEdges).fold(0.0, (sum, e) => sum + e.length);

  int get nodeCount => nodes.length ~/ 2;
}

class CityGround {
  CityGround({
    required this.width,
    required this.height,
    required this.shapes,
    required this.trees,
    required this.roads,
    required this.runways,
  });

  final double width, height;
  final Map<GroundKind, List<Float32List>> shapes;
  final List<GroundTree> trees;
  final RoadGraph roads;

  // North first: arrivals 29R, departures 29L
  final List<Runway> runways;

  Runway get arrivals => runways[0];
  Runway get departures => runways[1];
}

// Seeded, same trees every time
double groundHash(int n) {
  n = ((n ^ (n >>> 16)) * 0x45d9f3b) & 0xFFFFFFFF;
  n = ((n ^ (n >>> 16)) * 0x45d9f3b) & 0xFFFFFFFF;
  return (n ^ (n >>> 16)) / 4294967296;
}

CityGround cityGroundFromGzip(Uint8List bytes) => parseCityGround(utf8.decode(gzip.decode(bytes)));

CityGround parseCityGround(String text) {
  final json = jsonDecode(text) as Map<String, dynamic>;
  final size = json['size'] as List;
  Float32List ring(List values) => Float32List.fromList([for (final v in values) (v as num).toDouble()]);

  final shapes = <GroundKind, List<Float32List>>{};
  final kinds = GroundKind.values.asNameMap();
  for (final MapEntry(:key, :value) in (json['shapes'] as Map<String, dynamic>).entries) {
    final kind = kinds[key];
    if (kind != null) shapes[kind] = [for (final r in value as List) ring(r as List)];
  }
  shapes[GroundKind.trees] = [for (final r in json['canopy'] as List) ring(r as List)];

  final cells = json['trees'] as Map<String, dynamic>;
  final cell = (cells['cell'] as num).toDouble();
  final columns = cells['w'] as int;
  final bits = base64.decode(cells['bits'] as String);
  final trees = <GroundTree>[];
  for (var i = 0; i < bits.length * 8; i++) {
    if (bits[i >> 3] & (0x80 >> (i & 7)) == 0) continue;
    final x = (i % columns) * cell;
    final y = (i ~/ columns) * cell;
    trees.add((
      x: x + 2 + groundHash(i) * (cell - 4),
      y: y + 2 + groundHash(i + 7) * (cell - 4),
      radius: 4.2 + groundHash(i + 13) * 2.6,
    ));
  }

  final roads = json['roads'] as Map<String, dynamic>;
  final nodes = Float32List.fromList([
    for (final n in roads['nodes'] as List) ...[for (final v in n as List) (v as num).toDouble()],
  ]);
  final edges = [
    for (final e in roads['edges'] as List) RoadEdge.fromPoints((e as List)[0] as int, e[1] as int, e[2] as List),
  ];

  final airport = json['airport'] as Map<String, dynamic>;
  final heading = (airport['heading'] as num).toDouble();
  final raw = [for (final r in airport['runways'] as List) (r as List).map((v) => (v as num).toDouble()).toList()];
  String number(double h) => ((h / 10).round() == 0 ? 36 : (h / 10).round()).toString().padLeft(2, '0');
  // Northern first, the L for 11
  raw.sort((a, b) => (a[1] + a[3]).compareTo(b[1] + b[3]));
  final runways = [
    for (var i = 0; i < raw.length; i++)
      Runway(raw[i][0], raw[i][1], raw[i][2], raw[i][3], max(34, raw[i][4] * 1.7), [
        number(heading) + (i == 0 ? 'L' : 'R'),
        number((heading + 180) % 360) + (i == 0 ? 'R' : 'L'),
      ]),
  ];

  return CityGround(
    width: (size[0] as num).toDouble(),
    height: (size[1] as num).toDouble(),
    shapes: shapes,
    trees: trees,
    roads: RoadGraph(nodes, edges),
    runways: runways,
  );
}

const groundCellSize = 1024.0;

typedef ShapeCell<K> = ({Rect area, Map<K, Path> paths});

typedef GroundCell = ShapeCell<GroundKind>;

List<GroundCell> buildGroundCells(CityGround ground) =>
    buildShapeCells(ground.shapes, Rect.fromLTWH(0, 0, ground.width, ground.height));

// Rings per cell, open ones as lines
List<ShapeCell<K>> buildShapeCells<K>(Map<K, List<Float32List>> shapes, Rect extent, {Set<K> open = const {}}) {
  final columns = (extent.width / groundCellSize).ceil();
  final rows = (extent.height / groundCellSize).ceil();
  final cells = List.generate(columns * rows, (_) => <K, Path>{});
  int cellOf(double at, double start, int count) => ((at - start) / groundCellSize).floor().clamp(0, count - 1);
  for (final MapEntry(:key, :value) in shapes.entries) {
    for (final r in value) {
      var left = r[0], right = r[0], top = r[1], bottom = r[1];
      for (var i = 2; i < r.length; i += 2) {
        left = min(left, r[i]);
        right = max(right, r[i]);
        top = min(top, r[i + 1]);
        bottom = max(bottom, r[i + 1]);
      }
      for (var y = cellOf(top, extent.top, rows); y <= cellOf(bottom, extent.top, rows); y++) {
        for (var x = cellOf(left, extent.left, columns); x <= cellOf(right, extent.left, columns); x++) {
          // Holes need even-odd
          final path = cells[y * columns + x][key] ??= Path()..fillType = PathFillType.evenOdd;
          path.moveTo(r[0], r[1]);
          for (var i = 2; i < r.length; i += 2) {
            path.lineTo(r[i], r[i + 1]);
          }
          if (!open.contains(key)) path.close();
        }
      }
    }
  }
  // Edge cells reach past the shapes
  double line(int i, int count, double start) => i == 0 ? -1e5 : (i == count ? 1e5 : start + i * groundCellSize);
  return [
    for (var i = 0; i < cells.length; i++)
      if (cells[i].isNotEmpty)
        (
          area: Rect.fromLTRB(
            line(i % columns, columns, extent.left),
            line(i ~/ columns, rows, extent.top),
            line(i % columns + 1, columns, extent.left),
            line(i ~/ columns + 1, rows, extent.top),
          ),
          paths: cells[i],
        ),
  ];
}
