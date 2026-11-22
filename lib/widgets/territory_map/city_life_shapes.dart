import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_planes.dart';
import 'package:torn_pda/widgets/territory_map/point_buffer.dart';

const _darkCars = [Color(0xFF9AA3AD), Color(0xFFC4C8CC), Color(0xFF6E7782), Color(0xFFA8826A), Color(0xFF7D8EA3)];
const _lightCars = [Color(0xFF6E7782), Color(0xFF8A9096), Color(0xFF4E5660), Color(0xFF8A6450), Color(0xFF5A6B80)];

// Nose towards +x, left wing towards -y
const _body = [(0.5, 0.0), (0.44, -0.04), (-0.42, -0.045), (-0.5, -0.02), (-0.5, 0.02), (-0.42, 0.045), (0.44, 0.04)];
const _wings = [
  (0.1, -0.05),
  (-0.12, -0.5),
  (-0.2, -0.5),
  (-0.08, -0.05),
  (-0.08, 0.05),
  (-0.2, 0.5),
  (-0.12, 0.5),
  (0.1, 0.05),
];
const _tail = [(-0.36, -0.03), (-0.47, -0.18), (-0.5, -0.18), (-0.46, 0.0), (-0.5, 0.18), (-0.47, 0.18), (-0.36, 0.03)];
const _plushieParts = [(-0.75, -0.75, 0.5), (0.75, -0.75, 0.5), (0.0, 0.0, 1.0), (0.0, 1.25, 0.8)];

const _flashColor = Color.fromRGBO(255, 236, 170, 0.95);
const _tracerColor = Color.fromRGBO(255, 190, 110, 0.85);

Color customsColor(bool lightTheme) => lightTheme ? const Color(0xFF00897B) : const Color(0xFF4DD0B5);

Color policeBody(double dark) => dark > 0.3 ? const Color(0xFF3B4048) : const Color(0xFFE6E8EA);

// Plus washes out the light map
BlendMode lifeGlow(bool lightTheme) => lightTheme ? BlendMode.srcOver : BlendMode.plus;

// Ships and buoys light up from here
const seaLightsFrom = 0.25;
const portRed = Color.fromRGBO(255, 60, 50, 0.9);
const starboardGreen = Color.fromRGBO(60, 255, 120, 0.9);

class CityLifeShapes {
  Path _polygon(List<(double, double)> points) => Path()..addPolygon([for (final (x, y) in points) Offset(x, y)], true);

  late final body = _polygon(_body);
  late final wingsAndTail = _polygon(_wings)..addPath(_polygon(_tail), Offset.zero);
  late final whole = Path()
    ..addPath(wingsAndTail, Offset.zero)
    ..addPath(body, Offset.zero);

  final carPoints = List.generate(_darkCars.length, (_) => PointBuffer());
  final carPaths = List.generate(_darkCars.length, (_) => Path());
  final heads = PointBuffer();
  final tails = PointBuffer();

  // Cars past the city, each its size
  final farHeads = Path();
  final farTails = Path();
  final flashes = Path();
  final halos = Path();
  final tracers = Path();

  final fill = Paint();
  final outline = Paint()..style = PaintingStyle.stroke;
  final lights = Paint();

  // 3D planes and shadows
  final matrix = Float64List(16)
    ..[10] = 1
    ..[15] = 1;

  late final landingLight = Path()..addPolygon(const [Offset(0.5, 0), Offset(2.6, -0.4), Offset(2.6, 0.4)], true);
  late final landingGlow = ui.Gradient.linear(const Offset(0.5, 0), const Offset(2.6, 0), const [
    Color(0x80FFFAE1),
    Color(0x00FFFAE1),
  ]);
  late final redLight = ui.Gradient.radial(Offset.zero, 1, const [Color(0xFFFF2828), Color(0x00FF2828)]);
  late final blueLight = ui.Gradient.radial(Offset.zero, 1, const [Color(0xFF3C78FF), Color(0x003C78FF)]);

  var _carColors = const <Color>[];
  bool? _colorsLight;
  var _colorsDark = -1.0;

  List<Color> carColors(bool lightTheme, double dark) {
    if (lightTheme != _colorsLight || dark != _colorsDark) {
      _colorsLight = lightTheme;
      _colorsDark = dark;
      _carColors = [for (final color in lightTheme ? _lightCars : _darkCars) _dimmed(color, 1 - 0.65 * dark)];
    }
    return _carColors;
  }
}

Color _dimmed(Color color, double by) =>
    Color.from(alpha: color.a, red: color.r * by, green: color.g * by, blue: color.b * by);

// Car buffers already filled
void paintCars(
  Canvas canvas,
  CityLifeShapes shapes,
  List<Color> colors, {
  required bool rotated,
  required double dot,
  required double head,
  required double tail,
  required double glow,
  required bool lightTheme,
}) {
  final paint = shapes.fill
    ..style = PaintingStyle.fill
    ..strokeWidth = dot
    ..strokeCap = StrokeCap.square;
  for (var i = 0; i < colors.length; i++) {
    paint.color = colors[i];
    canvas.drawPath(shapes.carPaths[i], paint);
    if (!rotated && !shapes.carPoints[i].isEmpty) {
      canvas.drawRawPoints(ui.PointMode.points, shapes.carPoints[i].points, paint);
    }
  }
  if (glow <= 0) return;
  paint
    ..blendMode = lifeGlow(lightTheme)
    ..strokeCap = StrokeCap.round
    ..strokeWidth = head
    ..color = Color.fromRGBO(255, 236, 190, min(1, 0.55 * glow));
  if (!shapes.heads.isEmpty) canvas.drawRawPoints(ui.PointMode.points, shapes.heads.points, paint);
  canvas.drawPath(shapes.farHeads, paint);
  paint
    ..strokeCap = StrokeCap.square
    ..strokeWidth = tail
    ..color = Color.fromRGBO(255, 40, 30, min(1, 0.7 * glow));
  if (!shapes.tails.isEmpty) canvas.drawRawPoints(ui.PointMode.points, shapes.tails.points, paint);
  canvas.drawPath(shapes.farTails, paint);
  paint.blendMode = BlendMode.srcOver;
}

// Shot paths already filled
void paintShots(
  Canvas canvas,
  CityLifeShapes shapes, {
  required double dark,
  required double tracerWidth,
  required bool lightTheme,
}) {
  final paint = shapes.fill
    ..blendMode = lifeGlow(lightTheme)
    ..color = _flashColor;
  canvas.drawPath(shapes.flashes, paint);
  if (dark > 0.2) canvas.drawPath(shapes.halos, paint..color = Color.fromRGBO(255, 170, 80, 0.22 * dark));
  final outline = shapes.outline
    ..blendMode = lifeGlow(lightTheme)
    ..strokeWidth = tracerWidth
    ..color = _tracerColor;
  canvas.drawPath(shapes.tracers, outline);
  paint.blendMode = BlendMode.srcOver;
  outline.blendMode = BlendMode.srcOver;
}

// Canvas on the plane, one unit long
void paintPlane(
  Canvas canvas,
  Plane p,
  CityLifeShapes shapes, {
  required double pixels,
  required bool lit,
  required bool lightTheme,
  required double clock,
}) {
  final upsideDown = p.wing < 0;
  final wings = lit
      ? (upsideDown ? const Color(0xFF3A3F46) : const Color(0xFF5C636C))
      : (upsideDown ? const Color(0xFF9AA1A8) : const Color(0xFFC9CED4));
  final body = lit ? const Color(0xFF7A828C) : (upsideDown ? const Color(0xFFB9BEC4) : const Color(0xFFF1F3F5));
  canvas.drawPath(shapes.wingsAndTail, shapes.fill..color = wings.withValues(alpha: p.shown));
  canvas.drawPath(shapes.body, shapes.fill..color = body.withValues(alpha: p.shown));
  if (lightTheme) {
    shapes.outline
      ..strokeWidth = 1 / pixels
      ..color = const Color(0xFF55606B).withValues(alpha: p.shown);
    canvas.drawPath(shapes.whole, shapes.outline);
  }
  if (!lit) return;

  final lights = shapes.lights;
  final r = max(1.1 / pixels, 0.05);
  final ms = clock * 1000;
  final strobe = ms % 1300;
  void dot(double x, double y, double radius, Color color) =>
      canvas.drawCircle(Offset(x, y), radius, lights..color = color.withValues(alpha: color.a * p.shown));

  if (p.phase == PlanePhase.approach ||
      p.phase == PlanePhase.rollout ||
      p.phase == PlanePhase.roll ||
      (p.phase == PlanePhase.climb && p.z < 200)) {
    lights
      ..shader = shapes.landingGlow
      ..color = Colors.white.withValues(alpha: p.shown);
    canvas.drawPath(shapes.landingLight, lights);
    lights.shader = null;
  }
  dot(-0.16, -0.5, r * 1.4, const Color.fromRGBO(255, 40, 40, 0.95));
  dot(-0.16, 0.5, r * 1.4, const Color.fromRGBO(40, 255, 90, 0.95));
  dot(-0.5, 0, r, const Color.fromRGBO(255, 255, 255, 0.8));
  if (ms % 1000 < 120) dot(0.05, 0, r * 2.2, const Color.fromRGBO(255, 50, 40, 0.9));
  if (strobe < 60 || (strobe > 160 && strobe < 220)) {
    dot(-0.16, -0.5, r * 2.4, const Color.fromRGBO(255, 255, 255, 0.95));
    dot(-0.16, 0.5, r * 2.4, const Color.fromRGBO(255, 255, 255, 0.95));
  }
}

void paintPlushie(Canvas canvas, CityLifeShapes shapes, double r) {
  final paint = shapes.fill..color = const Color(0xFFC98A4B);
  for (final (x, y, part) in _plushieParts) {
    canvas.drawCircle(Offset(x * r, y * r), part * r, paint);
  }
  paint.color = const Color(0xFF3A2615);
  canvas
    ..drawCircle(Offset(-0.35 * r, -0.15 * r), 0.14 * r, paint)
    ..drawCircle(Offset(0.35 * r, -0.15 * r), 0.14 * r, paint);
}

void paintBeacons(Canvas canvas, CityLifeShapes shapes, double x, double y, double glow, bool flick, double alpha) {
  void light(double x, Shader shader, double alpha) {
    shapes.lights
      ..shader = shader
      ..color = Color.fromRGBO(255, 255, 255, alpha);
    canvas
      ..save()
      ..translate(x, y)
      ..scale(glow)
      ..drawCircle(Offset.zero, 1, shapes.lights)
      ..restore();
  }

  light(x - glow * 0.25, shapes.redLight, alpha * (flick ? 0.95 : 0.35));
  light(x + glow * 0.25, shapes.blueLight, alpha * (flick ? 0.35 : 0.95));
  shapes.lights.shader = null;
}
