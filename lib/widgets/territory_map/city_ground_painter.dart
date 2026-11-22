import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';

// Trees one by one, inside and out
const treesFromScale = 0.22;
const _centerLineFromScale = 0.12;
const _runwayNumbersFromScale = 0.35;

// Shifts over the app background
const _darkShift = {
  GroundKind.field: (13, 14, 9),
  GroundKind.park: (10, 19, 9),
  GroundKind.sand: (35, 30, 19),
  GroundKind.shore: (6, 18, 27),
  GroundKind.water: (-4, 6, 15),
  GroundKind.airfield: (11, 18, 9),
  GroundKind.apron: (20, 20, 21),
  GroundKind.road: (24, 25, 27),
  GroundKind.trees: (13, 31, 15),
  GroundKind.structure: (47, 48, 50),
};

const _lightShift = {
  GroundKind.field: (-10, -6, -12),
  GroundKind.park: (-24, -12, -24),
  GroundKind.sand: (-6, -12, -30),
  GroundKind.shore: (-34, -18, -6),
  GroundKind.water: (-50, -28, -10),
  GroundKind.airfield: (-20, -10, -20),
  GroundKind.apron: (-22, -22, -20),
  GroundKind.road: (5, 5, 5),
  GroundKind.trees: (-50, -26, -46),
  GroundKind.structure: (-36, -36, -32),
};

Color _shifted(Color base, (int, int, int) shift) {
  final (r, g, b) = shift;
  int channel(double value, int by) => ((value * 255).round() + by).clamp(0, 255);
  return Color.fromARGB(255, channel(base.r, r), channel(base.g, g), channel(base.b, b));
}

// Built once per theme
class GroundPaints {
  GroundPaints({required this.ground, required this.cells, required bool lightTheme, required Color background})
    : fills = {
        for (final kind in GroundKind.values)
          kind: Paint()..color = _shifted(background, (lightTheme ? _lightShift : _darkShift)[kind]!),
      },
      runway = Paint()..color = _shifted(background, lightTheme ? (-78, -76, -72) : (16, 16, 17)),
      centerLine = Paint()
        ..style = PaintingStyle.stroke
        ..color = lightTheme ? Colors.white : const Color(0xFF787C82),
      marks = Paint()..color = lightTheme ? Colors.white : const Color(0xFF969AA0),
      treeShadow = Paint()..color = _shifted(background, lightTheme ? (-60, -50, -60) : (-5, 1, -7)),
      treeCrown = Paint()..color = _shifted(background, lightTheme ? (-90, -50, -80) : (23, 53, 28)),
      treeLight = Paint()..color = _shifted(background, lightTheme ? (-60, -25, -55) : (45, 79, 48)) {
    for (final r in ground.runways) {
      for (var d = 60.0; d < r.length - 60; d += 40) {
        final end = min(d + 22, r.length - 60);
        _dashes
          ..moveTo(r.ax + r.ux * d, r.ay + r.uy * d)
          ..lineTo(r.ax + r.ux * end, r.ay + r.uy * end);
      }
      _runwayShapes.addPolygon([
        for (final (side, along) in [(1, 0.0), (1, 1.0), (-1, 1.0), (-1, 0.0)])
          Offset(
            r.ax + r.ux * r.length * along - r.uy * r.width / 2 * side,
            r.ay + r.uy * r.length * along + r.ux * r.width / 2 * side,
          ),
      ], true);
      for (final label in r.labels) {
        final builder =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 24, fontWeight: FontWeight.w600),
              )
              ..pushStyle(ui.TextStyle(color: marks.color))
              ..addText(label);
        _labels.add(builder.build()..layout(const ui.ParagraphConstraints(width: 60)));
      }
    }
  }

  final CityGround ground;
  final List<GroundCell> cells;
  final Map<GroundKind, Paint> fills;
  final Paint runway;
  final Paint centerLine;
  final Paint marks;
  final Paint treeShadow;
  final Paint treeCrown;
  final Paint treeLight;
  final _dashes = Path();
  final _runwayShapes = Path();
  final _labels = <ui.Paragraph>[];
}

// Under the territories, in map units
void paintCityGround(Canvas canvas, GroundPaints paints, Rect visible, double scale) {
  final trees = scale >= treesFromScale;
  for (final cell in paints.cells) {
    if (!cell.area.overlaps(visible)) continue;
    canvas
      ..save()
      ..clipRect(cell.area, doAntiAlias: false);
    for (final kind in GroundKind.values) {
      final path = cell.paths[kind];
      if (path == null || (kind == GroundKind.trees && trees)) continue;
      canvas.drawPath(path, paints.fills[kind]!);
    }
    canvas.restore();
  }

  paintRunways(canvas, paints, visible, scale);

  if (!trees) return;
  final area = visible.inflate(10);
  for (final t in paints.ground.trees) {
    if (area.contains(Offset(t.x, t.y))) {
      drawTree(canvas, t.x, t.y, t.radius, paints.treeShadow, paints.treeCrown, paints.treeLight);
    }
  }
}

void drawTree(Canvas canvas, double x, double y, double radius, Paint shadow, Paint crown, Paint light) => canvas
  ..drawCircle(Offset(x + 2.5, y + 2.5), radius, shadow)
  ..drawCircle(Offset(x, y), radius, crown)
  ..drawCircle(Offset(x - radius * 0.3, y - radius * 0.3), radius * 0.45, light);

// The north runway goes past the city
void paintRunways(Canvas canvas, GroundPaints paints, Rect visible, double scale) {
  canvas.drawPath(paints._runwayShapes, paints.runway);
  if (scale >= _centerLineFromScale) {
    paints.centerLine.strokeWidth = max(0.6 / scale, 1.4);
    canvas.drawPath(paints._dashes, paints.centerLine);
  }
  if (scale >= _runwayNumbersFromScale) {
    var label = 0;
    for (final r in paints.ground.runways) {
      for (final atB in [false, true]) {
        final paragraph = paints._labels[label++];
        final dx = atB ? -r.ux : r.ux, dy = atB ? -r.uy : r.uy;
        final ox = (atB ? r.bx : r.ax) + dx * 82, oy = (atB ? r.by : r.ay) + dy * 82;
        if (!visible.inflate(120).contains(Offset(ox, oy))) continue;
        canvas
          ..save()
          ..translate(ox, oy)
          ..rotate(atan2(dx, -dy));
        for (var i = 0; i < 4; i++) {
          for (final side in [-1, 1]) {
            canvas.drawRect(Rect.fromLTWH(side * (4 + i * 4.6) - (side < 0 ? 3 : 0), 40, 3, 34), paints.marks);
          }
        }
        canvas
          ..drawParagraph(paragraph, Offset(-paragraph.width / 2, -paragraph.height / 2))
          ..restore();
      }
    }
  }
}

// Up close, when neither image covers it
class CityGroundPainter extends CustomPainter {
  CityGroundPainter({required this.paints, required this.bounds, required this.visible, required this.scale});

  final GroundPaints paints;
  final Rect bounds;
  final Rect visible;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(bounds);
    paintCityGround(canvas, paints, visible, scale);
  }

  @override
  bool shouldRepaint(CityGroundPainter old) =>
      old.paints != paints || old.visible != visible || old.scale != scale || old.bounds != bounds;
}
