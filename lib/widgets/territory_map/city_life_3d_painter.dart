import 'dart:math';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/city_gunfire.dart';
import 'package:torn_pda/models/territory_map/city_planes.dart';
import 'package:torn_pda/providers/city_life_controller.dart';
import 'package:torn_pda/providers/territory_map_3d_controller.dart';
import 'package:torn_pda/widgets/territory_map/city_life_shapes.dart';

const _carShapesFromZoom = 0.6;
const _screenMargin = 40.0;

// The veil above dims them by half
const _nightLightBoost = 1.6;

// Canvas on a shape level at height z
bool _placeFlat(
  Canvas canvas,
  CityProjection p,
  Float64List matrix,
  double x,
  double y,
  double z,
  double heading,
  double length,
  double width,
) {
  final c = cos(heading), s = sin(heading);
  if (!p.place(x + c * length, y + s * length, z)) return false;
  final fx = p.sx, fy = p.sy;
  if (!p.place(x - s * width, y + c * width, z)) return false;
  final wx = p.sx, wy = p.sy;
  if (!p.place(x, y, z)) return false;
  matrix
    ..[0] = fx - p.sx
    ..[1] = fy - p.sy
    ..[4] = wx - p.sx
    ..[5] = wy - p.sy
    ..[12] = p.sx
    ..[13] = p.sy;
  canvas
    ..save()
    ..transform(matrix);
  return true;
}

bool _onScreen(CityProjection p, Size size, double margin) =>
    p.sx > -margin && p.sy > -margin && p.sx < size.width + margin && p.sy < size.height + margin;

class CityLife3dGroundPainter extends CustomPainter {
  CityLife3dGroundPainter({required this.life, required this.scene, required this.shapes, required this.lightTheme})
    : super(repaint: Listenable.merge([life, scene, life.night.level]));

  final CityLifeController life;
  final TerritoryMap3dController scene;
  final CityLifeShapes shapes;
  final bool lightTheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (scene.mesh == null || size.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    final p = scene.projection;
    final dark = life.night.level.value.dark;
    shapes.lights.blendMode = lifeGlow(lightTheme);
    if (life.planesOn) _paintShadows(canvas, p, size, dark);
    if (life.trafficOn && p.camera.zoom >= carsFromScale) _paintCars(canvas, p, size, dark);
    if (life.police.isNotEmpty) _paintPolice(canvas, p, size, dark);
  }

  void _paintCars(Canvas canvas, CityProjection p, Size size, double dark) {
    final zoom = p.camera.zoom;
    final colors = shapes.carColors(lightTheme, 0);
    final rotated = zoom > _carShapesFromZoom;
    final points = shapes.carPoints;
    final paths = shapes.carPaths;
    for (var i = 0; i < colors.length; i++) {
      points[i].clear();
      paths[i].reset();
    }
    final lights = dark > 0.05;
    final ahead = max(1.6 / zoom, 4.5);
    final heads = shapes.heads..clear();
    final tails = shapes.tails..clear();
    for (final car in life.cars) {
      if (!p.place(car.x, car.y, 0) || !_onScreen(p, size, 10)) continue;
      final x = p.sx, y = p.sy;
      if (lights) {
        if (p.place(car.x + car.dx * ahead, car.y + car.dy * ahead, 0)) heads.add(p.sx, p.sy);
        if (p.place(car.x - car.dx * ahead * 0.6, car.y - car.dy * ahead * 0.6, 0)) tails.add(p.sx, p.sy);
      }
      final c = car.color;
      if (!rotated) {
        points[c].add(x, y);
        continue;
      }
      final ax = car.dx * 2.3, ay = car.dy * 2.3, nx = -car.dy * 1.05, ny = car.dx * 1.05;
      if (!p.place(car.x + ax + nx, car.y + ay + ny, 0)) continue;
      final x1 = p.sx, y1 = p.sy;
      if (!p.place(car.x + ax - nx, car.y + ay - ny, 0)) continue;
      final x2 = p.sx, y2 = p.sy;
      if (!p.place(car.x - ax - nx, car.y - ay - ny, 0)) continue;
      final x3 = p.sx, y3 = p.sy;
      if (!p.place(car.x - ax + nx, car.y - ay + ny, 0)) continue;
      paths[c]
        ..moveTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x3, y3)
        ..lineTo(p.sx, p.sy)
        ..close();
    }
    paintCars(
      canvas,
      shapes,
      colors,
      rotated: rotated,
      dot: max(1.3, 5 * zoom),
      head: max(2.4, 4.2 * zoom),
      tail: max(1.4, 2.6 * zoom),
      glow: dark * _nightLightBoost,
      lightTheme: lightTheme,
    );

    for (final customs in life.customs) {
      final car = customs.car;
      if (!p.place(car.x, car.y, 0) || !_onScreen(p, size, 10)) continue;
      final side = max(3.2, 6.5 * p.k);
      shapes.fill.color = customsColor(lightTheme).withValues(alpha: customs.alpha.clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromCenter(center: Offset(p.sx, p.sy), width: side, height: side), shapes.fill);
    }
  }

  void _paintPolice(Canvas canvas, CityProjection p, Size size, double dark) {
    final flick = (life.clock / 0.14).floor().isOdd;
    final body = policeBody(dark);
    for (final police in life.police) {
      final car = police.car;
      final alpha = police.alpha.clamp(0.0, 1.0);
      if (alpha == 0 || !p.place(car.x, car.y, 0) || !_onScreen(p, size, _screenMargin)) continue;
      final x = p.sx, y = p.sy;
      final side = max(2.4, 5.2 * p.k);
      shapes.fill.color = body.withValues(alpha: alpha);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: side, height: side), shapes.fill);
      final glow = max(7, 16 * p.k) * (1 + dark * 0.5);
      paintBeacons(canvas, shapes, x, y, glow, flick, min(1, alpha * (1 + dark * (_nightLightBoost - 1))));
    }
  }

  // Afternoon sun, fades with height
  void _paintShadows(Canvas canvas, CityProjection p, Size size, double dark) {
    for (final plane in life.planes) {
      final fade = max(0.0, 1 - plane.z / 420) * plane.alpha * (dark > 0.25 ? 0.3 : 1);
      if (fade <= 0.02) continue;
      final x = plane.x + plane.z * 0.35, y = plane.y + plane.z * 0.5;
      if (!p.place(x, y, 0) || !_onScreen(p, size, _screenMargin)) continue;
      final length = planeLength(plane, p.k);
      if (!_placeFlat(canvas, p, shapes.matrix, x, y, 0, plane.heading, length, length * plane.wing)) continue;
      canvas
        ..drawPath(shapes.whole, shapes.fill..color = Colors.black.withValues(alpha: 0.32 * fade))
        ..restore();
    }
  }

  @override
  bool shouldRepaint(CityLife3dGroundPainter old) =>
      old.life != life || old.scene != scene || old.shapes != shapes || old.lightTheme != lightTheme;
}

class CityLife3dSkyPainter extends CustomPainter {
  CityLife3dSkyPainter({required this.life, required this.scene, required this.shapes, required this.lightTheme})
    : super(repaint: Listenable.merge([life, scene, life.night.level]));

  final CityLifeController life;
  final TerritoryMap3dController scene;
  final CityLifeShapes shapes;
  final bool lightTheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (scene.mesh == null || size.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    final p = scene.projection;
    final dark = life.night.level.value.dark;
    shapes.lights.blendMode = lifeGlow(lightTheme);
    if (life.shots.isNotEmpty) _paintShots(canvas, p, size, dark);
    if (!life.planesOn) return;
    for (final plushie in life.plushies) {
      if (!p.place(plushie.x, plushie.y, plushie.z) || !_onScreen(p, size, _screenMargin)) continue;
      canvas
        ..save()
        ..translate(p.sx, p.sy)
        ..rotate(plushie.landedAt == null ? life.clock / 0.16 : 0);
      paintPlushie(canvas, shapes, max(3, 4.5 * p.k) * (1 + plushie.z / 900));
      canvas.restore();
    }
    final lit = dark > 0.25;
    for (final plane in life.planes) {
      if (plane.alpha <= 0 || !p.place(plane.x, plane.y, plane.z) || !_onScreen(p, size, _screenMargin)) continue;
      final k = p.k;
      final length = planeLength(plane, k);
      final matrix = shapes.matrix;
      if (!_placeFlat(canvas, p, matrix, plane.x, plane.y, plane.z, plane.heading, length, length * plane.wing)) {
        continue;
      }
      paintPlane(canvas, plane, shapes, pixels: length * k, lit: lit, lightTheme: lightTheme, clock: life.clock);
      canvas.restore();
    }
  }

  double _roof(String? territory) {
    final mesh = scene.mesh;
    final t = territory == null ? null : mesh?.indexOf[territory];
    return t == null ? 0 : scene.heights[t] + 2;
  }

  void _paintShots(Canvas canvas, CityProjection p, Size size, double dark) {
    final now = life.clock;
    final flash = (4 * p.camera.zoom).clamp(1.1, 3.2) * (1 + dark * 0.5);
    final flashes = shapes.flashes..reset();
    final halos = shapes.halos..reset();
    final tracers = shapes.tracers..reset();
    for (final shot in life.shots) {
      final age = now - shot.at;
      if (age < 0) continue;
      final z = _roof(shot.territory);
      if (age <= shot.life && p.place(shot.x, shot.y, z) && _onScreen(p, size, _screenMargin)) {
        final at = Offset(p.sx, p.sy);
        flashes.addOval(Rect.fromCircle(center: at, radius: flash * (1 - age / shot.life * 0.5)));
        if (dark > 0.2) halos.addOval(Rect.fromCircle(center: at, radius: flash * 3.2));
      }
      final toX = shot.toX, toY = shot.toY;
      if (toX == null || toY == null || age > tracerLife) continue;
      final u = age / tracerLife, v = min(1.0, u + 0.25);
      if (!p.place(shot.x + (toX - shot.x) * u, shot.y + (toY - shot.y) * u, z + 1)) continue;
      final ax = p.sx, ay = p.sy;
      if (!p.place(shot.x + (toX - shot.x) * v, shot.y + (toY - shot.y) * v, z + 1)) continue;
      tracers
        ..moveTo(ax, ay)
        ..lineTo(p.sx, p.sy);
    }
    paintShots(canvas, shapes, dark: dark, tracerWidth: (2 * p.camera.zoom).clamp(0.8, 1.6), lightTheme: lightTheme);
  }

  @override
  bool shouldRepaint(CityLife3dSkyPainter old) =>
      old.life != life || old.scene != scene || old.shapes != shapes || old.lightTheme != lightTheme;
}
