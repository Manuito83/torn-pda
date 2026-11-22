import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/faction_colors.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/widgets/territory_map/city_ground_painter.dart';

const _blockFade = [1.0, 0.82, 0.62, 0.44, 0.3];
const _centerDashesFromScale = 0.2;
const _containersFromScale = 0.16;
const _approachLightsFromScale = 0.12;
const _containerColors = [
  Color(0xFFB5493C),
  Color(0xFF3F6F9E),
  Color(0xFFD08A3A),
  Color(0xFFE9E7E1),
  Color(0xFF4F8A5B),
];

// City edge, where its own background stops
const surroundingsEdge = 3.0;

typedef _Step = ({StripShape shape, Paint paint});

Paint _stroke(Color color, {StrokeCap cap = StrokeCap.round}) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = cap
  ..strokeJoin = StrokeJoin.round
  ..color = color;

// Once per theme, city ground colors
class StripPaints {
  StripPaints({required this.ground, required this.surroundings, required this.cells, required bool lightTheme})
    : casing = _stroke(lightTheme ? const Color.fromRGBO(168, 166, 160, 0.9) : const Color.fromRGBO(16, 16, 18, 0.9)),
      centerDashes = _stroke(
        lightTheme ? const Color.fromRGBO(170, 172, 176, 0.9) : const Color.fromRGBO(120, 124, 130, 0.8),
        cap: StrokeCap.butt,
      ),
      containers = [
        for (final color in _containerColors) Paint()..color = color.withValues(alpha: lightTheme ? 0.9 : 0.55),
      ],
      chimney = Paint()..color = lightTheme ? const Color(0xFFD9D4CC) : const Color(0xFF6B6966),
      chimneyTop = Paint()..color = lightTheme ? const Color(0xFF8D2F2A) : const Color(0xFF5A2B28),
      approachLights = Paint()
        ..color = lightTheme ? const Color.fromRGBO(120, 124, 130, 0.9) : const Color.fromRGBO(150, 154, 160, 0.8),
      mountainShadow = Paint()
        ..color = lightTheme ? const Color.fromRGBO(34, 58, 44, 0.5) : const Color.fromRGBO(8, 14, 12, 0.6),
      mountainCrown = Paint()..color = lightTheme ? const Color(0xFF608458) : const Color(0xFF2C4232),
      mountainLight = Paint()..color = lightTheme ? const Color(0xFF84A470) : const Color(0xFF3E5A42) {
    final fills = ground.fills;
    Paint fill(GroundKind kind) => fills[kind]!;
    final structure = fills[GroundKind.structure]!.color;
    breakwater = _stroke(structure)..strokeWidth = 13;
    bridgeSides = _stroke(structure, cap: StrokeCap.butt);
    bridgeDeck = _stroke(fill(GroundKind.road).color, cap: StrokeCap.butt);

    _under = [
      (shape: StripShape.shallows, paint: Paint()..color = fill(GroundKind.shore).color.withValues(alpha: 0.85)),
      (shape: StripShape.water, paint: fill(GroundKind.water)),
      (shape: StripShape.creek, paint: fill(GroundKind.shore)),
      (shape: StripShape.sand, paint: fill(GroundKind.sand)),
      (shape: StripShape.fields, paint: fill(GroundKind.field)),
      (shape: StripShape.field, paint: fill(GroundKind.field)),
      (shape: StripShape.airportGrove, paint: fill(GroundKind.park)),
      (shape: StripShape.airportGrass, paint: fill(GroundKind.airfield)),
      (shape: StripShape.airportApron, paint: fill(GroundKind.apron)),
      (shape: StripShape.airportIslands, paint: fill(GroundKind.airfield)),
      (shape: StripShape.southRunway, paint: fill(GroundKind.road)),
    ];
    _middle = [
      (shape: StripShape.hangars, paint: fill(GroundKind.structure)),
      for (final (i, shape) in blockShapes.indexed) ...[
        (shape: shape, paint: Paint()..color = const Color(0xFF9E9E9E).withValues(alpha: 0.349 * _blockFade[i])),
        (shape: shape, paint: _thin(Colors.black.withValues(alpha: 0.34 * _blockFade[i]))),
      ],
      (shape: StripShape.parks, paint: fill(GroundKind.park)),
      (shape: StripShape.closures, paint: Paint()..color = unownedFill),
      (shape: StripShape.closureEdges, paint: _thin(Colors.black.withValues(alpha: 0.5))),
    ];
    _south = [
      (shape: StripShape.southField, paint: fill(GroundKind.field)),
      (shape: StripShape.southSand, paint: fill(GroundKind.sand)),
      (shape: StripShape.southShore, paint: fill(GroundKind.shore)),
      (shape: StripShape.southTrees, paint: fill(GroundKind.trees)),
      (shape: StripShape.southStructure, paint: fill(GroundKind.structure)),
    ];
    _roads = [
      for (final shape in [StripShape.streets, StripShape.roads, StripShape.highways]) (shape: shape, paint: casing),
      for (final shape in [StripShape.streets, StripShape.roads, StripShape.highways])
        (shape: shape, paint: fill(GroundKind.road)),
    ];
    _over = [
      (shape: StripShape.portStructures, paint: fill(GroundKind.structure)),
      (shape: StripShape.structure, paint: fill(GroundKind.structure)),
      (shape: StripShape.breakwater, paint: breakwater),
      (shape: StripShape.piers, paint: fill(GroundKind.apron)),
      (shape: StripShape.stadium, paint: fill(GroundKind.structure)),
      (shape: StripShape.stadiumLawn, paint: fill(GroundKind.park)),
    ];
  }

  final GroundPaints ground;
  final Surroundings surroundings;
  final List<StripCell> cells;
  final Paint casing;
  final Paint centerDashes;
  final List<Paint> containers;
  final Paint chimney;
  final Paint chimneyTop;
  final Paint approachLights;
  final Paint mountainShadow, mountainCrown, mountainLight;
  late final Paint breakwater, bridgeSides, bridgeDeck;
  final _hairlines = <Paint>[];
  final _chimneyShadow = _stroke(Colors.black.withValues(alpha: 0.22))..strokeWidth = 9;
  late final List<_Step> _under, _middle, _south, _roads, _over;
  late final _dashes = [(shape: StripShape.centerDashes, paint: centerDashes)];
  late final _bridges = [
    for (final b in surroundings.bridges)
      (
        width: b.width,
        path: Path()..addPolygon([for (var i = 0; i < b.line.length; i += 2) Offset(b.line[i], b.line[i + 1])], false),
      ),
  ];

  Paint _thin(Color color) {
    final paint = _stroke(color);
    _hairlines.add(paint);
    return paint;
  }

  void _scaleTo(double scale) {
    for (final paint in _hairlines) {
      paint.strokeWidth = 1 / scale;
    }
    casing.strokeWidth = max(3, 1.6 / scale);
    centerDashes.strokeWidth = max(1.2, 0.7 / scale);
  }
}

void _paintCells(Canvas canvas, StripPaints paints, Rect visible, List<_Step> steps, {Rect? clip}) {
  for (final cell in paints.cells) {
    if (!cell.area.overlaps(visible)) continue;
    canvas
      ..save()
      ..clipRect(cell.area, doAntiAlias: false);
    if (clip != null) canvas.clipRect(clip);
    for (final step in steps) {
      final path = cell.paths[step.shape];
      if (path != null) canvas.drawPath(path, step.paint);
    }
    canvas.restore();
  }
}

void _paintTrees(Canvas canvas, Float32List trees, Rect area, Paint shadow, Paint crown, Paint light) {
  for (var i = 0; i < trees.length; i += 3) {
    final x = trees[i], y = trees[i + 1];
    if (area.contains(Offset(x, y))) drawTree(canvas, x, y, trees[i + 2], shadow, crown, light);
  }
}

// Outside the city and on its edge
void paintSurroundingsStrip(Canvas canvas, StripPaints paints, Rect visible, double scale) {
  final s = paints.surroundings;
  final inner = s.bounds.deflate(surroundingsEdge);
  if (inner.contains(visible.topLeft) && inner.contains(visible.bottomRight)) return;
  paints._scaleTo(scale);
  canvas
    ..save()
    ..clipRect(inner, clipOp: ui.ClipOp.difference);

  _paintCells(canvas, paints, visible, paints._under);
  paintRunways(canvas, paints.ground, visible, scale);
  _paintCells(canvas, paints, visible, paints._middle);
  final south = Rect.fromLTWH(s.bounds.left, s.bounds.bottom - surroundingsEdge, s.bounds.width, 400);
  if (south.overlaps(visible)) _paintCells(canvas, paints, visible, paints._south, clip: south);
  _paintCells(canvas, paints, visible, paints._roads);

  for (final (:width, :path) in paints._bridges) {
    if (!path.getBounds().inflate(width).overlaps(visible)) continue;
    canvas
      ..drawPath(path, paints.bridgeSides..strokeWidth = width + 9)
      ..drawPath(path, paints.bridgeDeck..strokeWidth = width);
  }
  if (scale > _centerDashesFromScale) _paintCells(canvas, paints, visible, paints._dashes);
  _paintCells(canvas, paints, visible, paints._over);

  final area = visible.inflate(20);
  if (scale > _containersFromScale) {
    final boxes = s.containers;
    for (var i = 0; i < boxes.length; i += 3) {
      if (!area.contains(Offset(boxes[i], boxes[i + 1]))) continue;
      canvas.drawRect(Rect.fromLTWH(boxes[i], boxes[i + 1], 11.5, 5.2), paints.containers[boxes[i + 2].toInt()]);
    }
  }
  for (var i = 0; i < s.chimneys.length; i += 2) {
    final at = Offset(s.chimneys[i], s.chimneys[i + 1]);
    if (!area.inflate(100).contains(at)) continue;
    canvas
      ..drawLine(at, at.translate(64, 92), paints._chimneyShadow)
      ..drawCircle(at, 8, paints.chimney)
      ..drawCircle(at, 4.2, paints.chimneyTop);
  }
  if (scale >= treesFromScale) {
    final g = paints.ground;
    _paintTrees(canvas, s.mountainTrees, area, paints.mountainShadow, paints.mountainCrown, paints.mountainLight);
    _paintTrees(canvas, s.cityTrees, area, g.treeShadow, g.treeCrown, g.treeLight);
  }
  if (scale > _approachLightsFromScale) {
    final lights = s.approachLights;
    for (var i = 0; i < lights.length; i += 2) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(lights[i], lights[i + 1]), width: 4, height: 4),
        paints.approachLights,
      );
    }
  }
  canvas.restore();
}
