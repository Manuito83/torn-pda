import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/territory_index.dart';
import 'package:torn_pda/providers/city_night_controller.dart';
import 'package:torn_pda/widgets/territory_map/point_buffer.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_images.dart';

const _veil = Color(0xFF080C19);
const _lampsFromScale = 0.07;

// Darker without losing the faction color
Color nightVeil(double dark, {required bool lightTheme}) => _veil.withValues(alpha: (lightTheme ? 0.55 : 0.5) * dark);

int _windowStride(double scale) => scale < 0.09
    ? 16
    : scale < 0.16
    ? 7
    : scale < 0.3
    ? 3
    : scale < 0.6
    ? 2
    : 1;

// Between the territories and the life
class CityNightLayer extends StatefulWidget {
  const CityNightLayer({
    super.key,
    required this.night,
    required this.index,
    required this.visible,
    required this.scale,
    required this.lightTheme,
    required this.surroundings,
    required this.photos,
  });

  final CityNightController night;
  final TerritoryIndex index;
  final Rect visible;
  final double scale;
  final bool lightTheme;

  // Null until it loads
  final Surroundings? surroundings;
  final SurroundingsImages photos;

  @override
  State<CityNightLayer> createState() => _CityNightLayerState();
}

class _CityNightLayerState extends State<CityNightLayer> {
  final _kept = PointBuffer();

  @override
  void initState() {
    super.initState();
    widget.night.level.addListener(_askLights);
    _askLights();
  }

  @override
  void didUpdateWidget(CityNightLayer old) {
    super.didUpdateWidget(old);
    if (old.night == widget.night) return;
    old.night.level.removeListener(_askLights);
    widget.night.level.addListener(_askLights);
    _askLights();
  }

  @override
  void dispose() {
    widget.night.level.removeListener(_askLights);
    super.dispose();
  }

  // Only once it gets dark
  void _askLights() {
    if (widget.night.level.value.dark > 0) widget.photos.wantLights();
  }

  @override
  Widget build(BuildContext context) {
    final around = widget.surroundings;
    final photos = widget.photos;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CityNightPainter(
            widget.night,
            widget.index,
            widget.visible,
            widget.scale,
            widget.lightTheme,
            _kept,
            around,
            [
              if (around != null && photos.farLights != null) (photos.farLights!, around.far),
              if (around != null && photos.midLights != null) (photos.midLights!, around.mid),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityNightPainter extends CustomPainter {
  _CityNightPainter(
    this.night,
    this.index,
    this.visible,
    this.scale,
    this.lightTheme,
    this.kept,
    this.surroundings,
    this.lights,
  ) : super(repaint: Listenable.merge([night.level, night.windows]));

  final CityNightController night;
  final TerritoryIndex index;
  final Rect visible;
  final double scale;
  final bool lightTheme;
  final PointBuffer kept;
  final Surroundings? surroundings;
  final List<(ui.Image, Rect)> lights;
  final _paint = Paint();
  final _lightsPaint = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.medium;

  void _draw(Canvas canvas, double width, Color color, StrokeCap cap) {
    if (kept.isEmpty) return;
    _paint
      ..strokeWidth = width
      ..strokeCap = cap
      ..color = color;
    canvas.drawRawPoints(ui.PointMode.points, kept.points, _paint);
  }

  void _keepInside(Float32List all, Rect area) {
    for (var i = 0; i < all.length; i += 2) {
      final x = all[i], y = all[i + 1];
      if (x >= area.left && x < area.right && y >= area.top && y < area.bottom) kept.add(x, y);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final level = night.level.value;
    final dark = level.dark;
    if (dark == 0) return;
    final area = visible.inflate(20 / scale);
    _paint
      ..blendMode = BlendMode.srcOver
      ..color = nightVeil(dark, lightTheme: lightTheme);
    canvas.drawRect(area, _paint);
    _lightsPaint.color = Colors.white.withValues(alpha: (lightTheme ? 0.6 : 1) * dark);
    for (final (image, rect) in lights) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        _lightsPaint,
      );
    }
    _paint.blendMode = lightTheme ? BlendMode.srcOver : BlendMode.plus;
    final around = surroundings;

    if (scale >= _lampsFromScale) {
      kept.clear();
      _keepInside(night.lamps, area);
      if (around != null) _keepInside(around.lamps, area);
      _draw(canvas, max(1.6 / scale, 3), Color.fromRGBO(255, 186, 110, 0.55 * dark), StrokeCap.round);
    }
    kept.clear();
    _keepInside(night.runwayEdges, area);
    if (around != null) _keepInside(around.approachLights, area);
    _draw(canvas, max(1.3 / scale, 2.5), Color.fromRGBO(255, 255, 235, 0.8 * dark), StrokeCap.round);

    final lit = level.lights * dark;
    final windows = night.windows.value;
    if (lit <= 0 || windows == null) return;
    final stride = _windowStride(scale);
    kept.clear();
    if (around != null) {
      final outside = around.windows;
      for (var i = 0; i < outside.length; i += stride * 2) {
        final x = outside[i], y = outside[i + 1];
        if (groundHash(i) <= lit && area.contains(Offset(x, y))) kept.add(x, y);
      }
    }
    for (final t in index.visibleIn(area)) {
      final (start, end) = windows.ranges[t.code] ?? (0, 0);
      for (var i = start; i < end; i += stride) {
        if (windows.thresholds[i] > lit) continue;
        kept.add(windows.points[i * 2], windows.points[i * 2 + 1]);
      }
    }
    _draw(
      canvas,
      (scale * 2.4).clamp(0.9, 2.2) / scale,
      Color.fromRGBO(255, 214, 140, (scale < 0.16 ? 0.6 : 0.85) * dark),
      StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(_CityNightPainter old) =>
      old.night != night ||
      old.visible != visible ||
      old.scale != scale ||
      old.lightTheme != lightTheme ||
      old.surroundings != surroundings ||
      old.lights.length != lights.length;
}
