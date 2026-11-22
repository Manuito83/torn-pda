import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_sky.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/widgets/territory_map/city_life_shapes.dart';
import 'package:torn_pda/widgets/territory_map/point_buffer.dart';

// Small sprites, stretched; built once
class SkyShapes {
  final _made = <ui.Image>[];
  late final cloudsDay = [_cloud(1, _dayCloud), _cloud(77, _dayCloud)];
  late final cloudsNight = [_cloud(1, _nightCloud), _cloud(77, _nightCloud)];
  late final cloudShadows = [_cloud(1, _shadowCloud), _cloud(77, _shadowCloud)];
  late final veils = [_veil(5), _veil(91)];

  final fill = Paint();
  final sprite = Paint()..filterQuality = FilterQuality.low;
  final glints = ColorMesh();

  ui.Image _sprite(int width, int height, void Function(Canvas canvas) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    _made.add(image);
    return image;
  }

  void _puffs(Canvas canvas, List<(double, double, double)> puffs, Offset shift, Color color, double solid) {
    final paint = Paint();
    for (final (x, y, r) in puffs) {
      final center = Offset(x, y) + shift;
      paint.shader = ui.Gradient.radial(center, r, [color, color, color.withValues(alpha: 0)], [0, solid, 1]);
      canvas.drawCircle(center, r, paint);
    }
  }

  // Cumulus from above, shaded side lower right
  ui.Image _cloud(int seed, void Function(Canvas, List<(double, double, double)>) layers) {
    final puffs = <(double, double, double)>[];
    for (var i = 0; i < 54; i++) {
      final a = groundHash(i * 3 + seed) * 2 * pi, d = pow(groundHash(i * 5 + seed + 1), 0.8) * 0.36;
      puffs.add((
        160 + cos(a) * d * 250,
        108 + sin(a) * d * 130,
        15 + groundHash(i * 7 + seed + 2) * 24 * (1.15 - d * 1.6),
      ));
    }
    return _sprite(320, 220, (canvas) => layers(canvas, puffs));
  }

  void _dayCloud(Canvas canvas, List<(double, double, double)> puffs) {
    _puffs(canvas, puffs, const Offset(6, 8), const Color.fromRGBO(176, 188, 206, 0.9), 0.62);
    _puffs(canvas, puffs, Offset.zero, const Color.fromRGBO(255, 255, 255, 0.96), 0.6);
  }

  void _nightCloud(Canvas canvas, List<(double, double, double)> puffs) {
    _puffs(canvas, puffs, const Offset(5, 7), const Color.fromRGBO(30, 36, 50, 0.8), 0.6);
    _puffs(canvas, puffs, Offset.zero, const Color.fromRGBO(70, 80, 100, 0.75), 0.55);
  }

  void _shadowCloud(Canvas canvas, List<(double, double, double)> puffs) =>
      _puffs(canvas, puffs, Offset.zero, const Color.fromRGBO(12, 22, 40, 0.5), 0.35);

  // High cloud shadow, no hard core
  ui.Image _veil(int seed) {
    final puffs = <(double, double, double)>[];
    for (var i = 0; i < 24; i++) {
      final a = groundHash(i * 3 + seed) * 2 * pi, d = pow(groundHash(i * 5 + seed + 1), 0.9) * 0.3;
      puffs.add((128 + cos(a) * d * 256, 100 + sin(a) * d * 150, 26 + groundHash(i * 7 + seed + 2) * 24));
    }
    return _sprite(256, 200, (canvas) => _puffs(canvas, puffs, Offset.zero, const Color.fromRGBO(14, 24, 44, 0.44), 0));
  }

  void dispose() {
    for (final image in _made) {
      image.dispose();
    }
    _made.clear();
  }
}

void _drawSprite(Canvas canvas, SkyShapes shapes, ui.Image image, Offset at, double turn, Size size, double alpha) {
  shapes.sprite.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
  canvas
    ..save()
    ..translate(at.dx, at.dy)
    ..rotate(turn)
    ..drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height),
      shapes.sprite,
    )
    ..restore();
}

// Below ships and cars
void paintSeaLife(
  Canvas canvas,
  SkyShapes shapes, {
  required CitySky sky,
  required Surroundings surroundings,
  required double clock,
  required Rect area,
  required double scale,
  required double dark,
  required bool lightTheme,
}) {
  final shade = (lightTheme ? 0.3 : 0.5) * (1 - dark);
  if (shade > 0.01) {
    for (final shadow in sky.shadows) {
      final spot = shadowAt(shadow, clock, surroundings);
      if (spot.alpha * shade <= 0.01 || !area.inflate(spot.width).contains(spot.at)) continue;
      final size = Size(spot.width, spot.width * 0.78);
      _drawSprite(canvas, shapes, shapes.veils[shadow.look], spot.at, shadow.turn, size, spot.alpha * shade);
    }
  }
  if (!area.overlaps(sky.sea)) return;

  final glints = sky.glints;
  final color = Color.lerp(const Color(0xFFFFFFFA), const Color(0xFFC8D7F0), dark)!;
  final peak = 0.9 - 0.4 * dark;
  final side = 1.5 / scale;
  for (var i = 0; i < glints.length; i += 4) {
    final x = glints[i], y = glints[i + 1];
    if (!area.contains(Offset(x, y))) continue;
    final k = glintStrength(glints[i + 2], glints[i + 3], clock);
    if (k < 0.05) continue;
    final c = color.withValues(alpha: k * peak).toARGB32();
    final l = x - side / 2, r = x + side / 2, t = y - side * 0.3, b = y + side * 0.3;
    shapes.glints.quad(Offset(l, t), Offset(l, b), Offset(r, t), Offset(r, b), c, c);
  }
  shapes.glints.draw(canvas, shapes.fill..color = Colors.white);

  final paint = shapes.fill;
  final lit = dark > seaLightsFrom;
  final buoy = max(1.3 / scale, 3.4);
  for (final b in sky.buoys) {
    if (!area.contains(b.at)) continue;
    if (!lit) {
      paint.color = b.green ? const Color(0xFF2F9E58) : const Color(0xFFC8402F);
      canvas.drawCircle(b.at, buoy * 0.8, paint);
    } else if (buoyLit(b.green, clock)) {
      paint
        ..blendMode = lifeGlow(lightTheme)
        ..color = (b.green ? starboardGreen : portRed).withValues(alpha: 0.9 * dark);
      canvas.drawCircle(b.at, buoy * 1.3, paint);
      paint.blendMode = BlendMode.srcOver;
    }
  }

  for (final l in sky.lighthouses) {
    final reach = lighthouseBeam * l.size;
    if (!area.inflate(reach).contains(l.at)) continue;
    final r = max(1.5 / scale, 6 * l.size);
    canvas
      ..drawCircle(l.at + Offset(r * 0.5, r * 0.7), r, paint..color = const Color.fromRGBO(0, 0, 0, 0.25))
      ..drawCircle(l.at, r, paint..color = Color.lerp(Colors.white, const Color(0xFFCFD3D8), dark)!)
      ..drawCircle(l.at, r * 0.45, paint..color = const Color(0xFFC8402F));
    if (dark < 0.05) continue;
    paint.blendMode = lifeGlow(lightTheme);
    final angle = beamAngle(l.phase, clock);
    final beam = Rect.fromCircle(center: l.at, radius: reach);
    paint.shader = ui.Gradient.radial(l.at, reach, [
      Color.fromRGBO(255, 244, 200, 0.3 * dark),
      const Color.fromRGBO(255, 244, 200, 0),
    ]);
    for (final turn in const [0.0, pi]) {
      canvas.drawPath(
        Path()
          ..moveTo(l.at.dx, l.at.dy)
          ..arcTo(beam, angle + turn - 0.05, 0.1, false)
          ..close(),
        paint,
      );
    }
    paint
      ..shader = null
      ..color = Color.fromRGBO(255, 246, 210, 0.95 * dark);
    canvas.drawCircle(l.at, r * 1.25, paint);
    paint.blendMode = BlendMode.srcOver;
  }
}

// Above the cars, below the planes
void paintClouds(
  Canvas canvas,
  SkyShapes shapes, {
  required CitySky sky,
  required Surroundings surroundings,
  required double clock,
  required Rect area,
  required double dark,
  required bool lightTheme,
}) {
  final looks = lightTheme && dark < 0.5 ? shapes.cloudsDay : shapes.cloudsNight;
  for (final cloud in sky.clouds) {
    final spot = cloudAt(cloud, clock, surroundings);
    if (spot.alpha <= 0.02 || !area.inflate(spot.width * 1.8).contains(spot.at)) continue;
    final size = Size(spot.width, spot.width * 0.69);
    // High cloud, shadow falls far
    final k = spot.width / cloud.width;
    final below = spot.at + Offset(230 * k, 330 * k);
    final shadow = (0.34 - 0.12 * dark) * spot.alpha;
    _drawSprite(canvas, shapes, shapes.cloudShadows[cloud.look], below, cloud.turn, size, shadow);
    _drawSprite(canvas, shapes, looks[cloud.look], spot.at, cloud.turn, size, 0.86 * spot.alpha);
  }
}
