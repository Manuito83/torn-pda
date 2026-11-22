import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/map_layer.dart';

const _spacing = 6.0;

// Opposite diagonal to the irradiated stripes
Shader lockHatchShader(double unit) {
  final period = _spacing * unit / sqrt2;
  final color = Colors.grey.withValues(alpha: 0.35);
  const line = 1 / _spacing;
  return ui.Gradient.linear(
    Offset.zero,
    Offset(period, -period),
    [color, color, Colors.transparent, Colors.transparent],
    [0, line, line, 1],
    TileMode.repeated,
  );
}

class AssaultLocksLayer implements MapLayer {
  AssaultLocksLayer(this.controller);

  final TerritoryMapController controller;
  final _paint = Paint();
  double _unit = 0;

  @override
  void paint(Canvas canvas, MapViewport viewport) {
    final territories = controller.territories?.territories;
    if (territories == null || controller.locked.isEmpty) return;
    final unit = 1 / viewport.scale;
    if (unit != _unit) {
      _unit = unit;
      _paint.shader?.dispose();
      _paint.shader = lockHatchShader(unit);
    }
    for (final code in controller.locked) {
      final path = controller.paths[code];
      final bounds = territories[code]?.bounds;
      if (path != null && bounds != null && bounds.overlaps(viewport.visible)) canvas.drawPath(path, _paint);
    }
  }

  @override
  Object? hitTest(Offset mapPoint, double scale) => null;
}

class LockHatchSwatch extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shader = lockHatchShader(1);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    shader.dispose();
  }

  @override
  bool shouldRepaint(LockHatchSwatch old) => false;
}
