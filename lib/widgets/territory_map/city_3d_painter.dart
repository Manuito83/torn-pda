import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/city_night.dart';
import 'package:torn_pda/models/territory_map/city_scene.dart';
import 'package:torn_pda/models/territory_map/map_labels.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/providers/territory_map_3d_controller.dart';
import 'package:torn_pda/widgets/territory_map/city_ground_painter.dart';
import 'package:torn_pda/widgets/territory_map/city_night_layer.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_3d_painter.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_layer.dart';
import 'package:torn_pda/widgets/territory_map/territory_overlay_painter.dart';

const _groundColumns = 64;

// Borders only when still and close enough
const _bordersFromZoom = 0.14;

// Pixels per unit on the roof
const _labelsFromScale = 0.22;
const _maxRoofLabels = 60;

// Two triangles per grid cell
const gridCorners = [(0, 0), (1, 0), (1, 1), (0, 0), (1, 1), (0, 1)];

Future<ui.Image> renderCityGround(GroundPaints paints, Rect bounds, Color background, int width) {
  final scale = width / bounds.width;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(background, BlendMode.src)
    ..scale(scale)
    ..translate(-bounds.left, -bounds.top);
  paintCityGround(canvas, paints, bounds, scale);
  final picture = recorder.endRecording();
  return picture.toImage(width, (bounds.height * scale).ceil()).whenComplete(picture.dispose);
}

// Ground image on a grid of triangles
class CityGroundGrid {
  CityGroundGrid(this.image, this.bounds)
    : rows = math.max(1, (_groundColumns * bounds.height / bounds.width).round()),
      _paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..shader = ImageShader(image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage) {
    _points = Float32List((_groundColumns + 1) * (rows + 1) * 2);
    _positions = Float32List(_groundColumns * rows * 12);
    _texture = Float32List(_groundColumns * rows * 12);
    final sx = image.width / _groundColumns, sy = image.height / rows;
    var i = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < _groundColumns; c++) {
        for (final (dc, dr) in gridCorners) {
          _texture[i++] = (c + dc) * sx;
          _texture[i++] = (r + dr) * sy;
        }
      }
    }
  }

  final ui.Image image;
  final Rect bounds;
  final int rows;
  final Paint _paint;
  late final Float32List _points;
  late final Float32List _positions;
  late final Float32List _texture;

  void paint(Canvas canvas, CityProjection p) {
    final camera = p.camera;
    final near = p.near;
    final cellW = bounds.width / _groundColumns, cellH = bounds.height / rows;
    var i = 0;
    for (var r = 0; r <= rows; r++) {
      for (var c = 0; c <= _groundColumns; c++) {
        final dx = bounds.left + c * cellW - camera.x, dy = bounds.top + r * cellH - camera.y;
        final rx = dx * p.cosYaw - dy * p.sinYaw, ry = dx * p.sinYaw + dy * p.cosYaw;
        final k = camera.zoom * p.distance / math.max(p.distance - ry * p.sinPitch, near);
        _points[i++] = p.centerX + rx * k;
        _points[i++] = p.centerY + ry * p.cosPitch * k;
      }
    }
    i = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < _groundColumns; c++) {
        for (final (dc, dr) in gridCorners) {
          final at = ((r + dr) * (_groundColumns + 1) + c + dc) * 2;
          _positions[i++] = _points[at];
          _positions[i++] = _points[at + 1];
        }
      }
    }
    final vertices = ui.Vertices.raw(ui.VertexMode.triangles, _positions, textureCoordinates: _texture);
    // Impeller aborts on dst with a texture
    canvas.drawVertices(vertices, BlendMode.src, _paint);
    vertices.dispose();
  }

  void dispose() {
    _paint.shader?.dispose();
    image.dispose();
  }
}

class City3dGroundPainter extends CustomPainter {
  City3dGroundPainter({
    required this.scene,
    required this.background,
    required this.ground,
    required this.terrain,
    required this.lightTheme,
  }) : super(repaint: scene);

  final TerritoryMap3dController scene;
  final Color background;
  final CityGroundGrid? ground;
  final SurroundingsTerrain? terrain;
  final bool lightTheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final mesh = scene.mesh;
    if (mesh == null || size.isEmpty) return canvas.drawColor(surroundingsAir(lightTheme: lightTheme), BlendMode.src);
    final p = scene.projection;
    paintSky(canvas, size, p, lightTheme: lightTheme);
    terrain?.paint(canvas, p);
    if (ground case final grid?) return grid.paint(canvas, p);
    final b = mesh.bounds;
    final corners = [
      p.project(b.left, b.top, 0),
      p.project(b.right, b.top, 0),
      p.project(b.right, b.bottom, 0),
      p.project(b.left, b.bottom, 0),
    ];
    if (corners.contains(null)) return canvas.drawColor(background, BlendMode.src);
    canvas.drawPath(Path()..addPolygon([for (final c in corners) c!], true), Paint()..color = background);
  }

  @override
  bool shouldRepaint(City3dGroundPainter old) =>
      old.scene != scene ||
      old.background != background ||
      old.ground != ground ||
      old.terrain != terrain ||
      old.lightTheme != lightTheme;
}

class City3dPainter extends CustomPainter {
  City3dPainter({
    required this.scene,
    required this.colors,
    required this.background,
    required this.pixelRatio,
    required this.lightTheme,
    this.night,
    this.ownLines,
  }) : super(repaint: Listenable.merge([scene, night]));

  final TerritoryMap3dController scene;
  final Int32List colors;
  final Color background;
  final double pixelRatio;
  final bool lightTheme;
  final ValueListenable<NightLevel>? night;
  final ({Uint8List full, Uint8List moving})? ownLines;
  final _paint = Paint();

  // Still city as one image
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    if (scene.moving || size.isEmpty) {
      _paintCity(canvas, size);
      return _paintVeil(canvas, size);
    }
    final recorder = ui.PictureRecorder();
    _paintCity(Canvas(recorder)..scale(pixelRatio), size);
    final picture = recorder.endRecording();
    final image = picture.toImageSync((size.width * pixelRatio).ceil(), (size.height * pixelRatio).ceil());
    picture.dispose();
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & Size(image.width / pixelRatio, image.height / pixelRatio),
      _paint,
    );
    image.dispose();
    _paintVeil(canvas, size);
  }

  void _paintCity(Canvas canvas, Size size) {
    final mesh = scene.mesh;
    final order = scene.order;
    final frame = scene.moving ? scene.movingFrame : scene.fullFrame;
    if (mesh == null || order == null || frame == null || colors.length != mesh.length) return;
    final p = scene.projection;

    sortVisible(mesh, p, scene.heights, order);
    final zoom = p.camera.zoom;
    fillCityFrame(
      frame,
      mesh,
      p,
      scene.heights,
      order,
      colors,
      background.toARGB32(),
      borderWidth: scene.moving || zoom < _bordersFromZoom ? 0 : (zoom > 0.5 ? 1 : 0.7),
      wallsFrom: scene.moving && scene.low ? 0.55 : 0,
      lines: scene.moving ? ownLines?.moving : ownLines?.full,
      lineColor: (lightTheme ? Colors.black : Colors.white).toARGB32(),
      lineWidth: zoom < _bordersFromZoom ? 1 : 2,
    );
    if (frame.vertices == 0) return;
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(frame.positions, 0, frame.vertices * 2),
      colors: Int32List.sublistView(frame.colors, 0, frame.vertices),
    );
    canvas.drawVertices(vertices, BlendMode.dst, _paint);
    vertices.dispose();
  }

  void _paintVeil(Canvas canvas, Size size) {
    final dark = night?.value.dark ?? 0;
    if (dark > 0) canvas.drawRect(Offset.zero & size, Paint()..color = nightVeil(dark, lightTheme: lightTheme));
  }

  @override
  bool shouldRepaint(City3dPainter old) =>
      old.scene != scene ||
      old.colors != colors ||
      old.background != background ||
      old.pixelRatio != pixelRatio ||
      old.lightTheme != lightTheme ||
      old.night != night ||
      old.ownLines != ownLines;
}

// War columns and selection, on top
class City3dOverlayPainter extends CustomPainter {
  City3dOverlayPainter({required this.scene, required this.wars, required this.selected, required this.pulse})
    : super(repaint: Listenable.merge([scene, pulse]));

  final TerritoryMap3dController scene;
  final List<int> wars;
  final int selected;
  final ValueNotifier<double> pulse;
  final _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final _dot = Paint()..color = const Color(0xFFFF5A5A);

  Path _top(CityMeshLevel level, int t, CityFrame frame) {
    final path = Path();
    for (var r = level.firstRing[t]; r < level.firstRing[t + 1]; r++) {
      final start = level.ringStart[r], end = level.ringStart[r + 1];
      path.moveTo(frame.topX[start], frame.topY[start]);
      for (var v = start + 1; v < end; v++) {
        path.lineTo(frame.topX[v], frame.topY[v]);
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mesh = scene.mesh;
    final full = scene.fullFrame;
    final drawn = scene.moving ? scene.movingFrame : full;
    if (mesh == null || drawn == null || full == null) return;
    canvas.clipRect(Offset.zero & size);
    final p = scene.projection;
    final glow = pulse.value;
    final zoom = p.camera.zoom;
    final beam = (34 + 22 * (0.2 / zoom).clamp(0.6, 1.2)) / zoom;
    for (final t in wars) {
      final h = scene.heights[t];
      final a = p.project(mesh.centerX[t], mesh.centerY[t], h);
      final b = p.project(mesh.centerX[t], mesh.centerY[t], h + beam);
      if (a == null || b == null || a.dx < -40 || a.dx > size.width + 40 || a.dy < -80 || a.dy > size.height + 80) {
        continue;
      }
      projectTerritory(drawn.level, t, h, p, drawn);
      canvas.drawPath(
        _top(drawn.level, t, drawn),
        _line
          ..color = Color.fromRGBO(255, 61, 61, 0.55 + 0.45 * glow)
          ..strokeWidth = 1.2 + 1.6 * glow,
      );
      canvas
        ..drawLine(
          a,
          b,
          _line
            ..color = Color.fromRGBO(255, 61, 61, 0.13 + 0.14 * glow)
            ..strokeWidth = 9,
        )
        ..drawLine(
          a,
          b,
          _line
            ..color = Color.fromRGBO(255, 190, 190, 0.65 + 0.3 * glow)
            ..strokeWidth = 1.6,
        )
        ..drawCircle(b, 2.2 + 1.6 * glow, _dot);
    }
    if (selected >= 0) {
      projectTerritory(full.level, selected, scene.heights[selected], p, full);
      canvas.drawPath(
        _top(full.level, selected, full),
        _line
          ..color = Colors.white
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(City3dOverlayPainter old) =>
      old.scene != scene || !listEquals(old.wars, wars) || old.selected != selected || old.pulse != pulse;
}

class City3dLabelsPainter extends CustomPainter {
  City3dLabelsPainter({
    required this.scene,
    required this.roofs,
    required this.labels,
    required this.space,
    required this.state,
    required this.ownership,
    required this.names,
    required this.showNames,
    required this.shades,
    required this.dataVersion,
  }) : super(repaint: scene);

  final TerritoryMap3dController scene;
  final CityRoofs roofs;
  final Map<String, ui.Paragraph> labels;
  final LabelSpace space;
  final MapState? state;
  final Map<String, Ownership> ownership;
  final Map<int, MapFaction> names;
  final bool showNames;
  final Map<String, Shade>? shades;
  final int dataVersion;

  @override
  void paint(Canvas canvas, Size size) {
    final mesh = scene.mesh, order = scene.order, frame = scene.fullFrame, current = state;
    if (scene.moving || mesh == null || order == null || frame == null || current == null || size.isEmpty) return;
    final p = scene.projection;
    if (p.camera.zoom < _labelsFromScale / 2) return;
    final count = roofsInSight(
      mesh,
      p,
      scene.heights,
      order: order,
      frame: frame,
      out: roofs,
      minWidth: territoryLabelFromWidth,
      minScale: _labelsFromScale,
    );
    space.clear();
    var drawn = 0;
    for (var i = 0; i < count && drawn < _maxRoofLabels; i++) {
      final code = mesh.codes[roofs.territory[i]];
      if (shades != null && !shades!.containsKey(code)) continue;
      final id = ownership[code]?.factionId ?? 0;
      final label = territoryLabel(
        labels,
        code,
        current.factions[id] ?? names[id],
        roofs.width[i],
        showNames: showNames,
      );
      if (label == null) continue;
      final x = roofs.x[i], y = roofs.y[i];
      if (!space.take(Rect.fromCenter(center: Offset(x, y), width: label.longestLine, height: label.height))) continue;
      canvas.drawParagraph(label, Offset(x - label.width / 2, y - label.height / 2));
      drawn++;
    }
  }

  @override
  bool shouldRepaint(City3dLabelsPainter old) =>
      old.scene != scene ||
      old.state != state ||
      old.ownership != ownership ||
      old.dataVersion != dataVersion ||
      old.showNames != showNames ||
      old.names != names ||
      old.shades != shades;
}
