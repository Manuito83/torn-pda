import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/faction_colors.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/war_arrows.dart';
import 'package:torn_pda/models/territory_map/war_fronts.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/map_layer.dart';

const _bend = 0.2;
const _frontWeight = 0.6;
// Clears the territory code
const _targetGap = 14.0;

// Screen pixels
const _minLength = 28.0;
const _spineSteps = 14;

const momentumStyle = {
  AssaultMomentum.advancing: (color: Color(0xFFE53935), label: 'Assault on pace'),
  AssaultMomentum.slow: (color: Color(0xFFFB8C00), label: 'Assault too slow'),
  AssaultMomentum.blocked: (color: Color(0xFF8E24AA), label: 'Assault held off'),
  AssaultMomentum.stalled: (color: Color(0xFF9E9E9E), label: 'Assault idle'),
};

// Repaints when history days arrive
class WarArrowsLayer extends RefreshedMapLayer {
  WarArrowsLayer(this.controller, this.history, {required this.lightTheme}) : super(history);

  final TerritoryMapController controller;
  final TerritoryHistoryController history;
  final bool lightTheme;

  List<AssaultArrow> _arrows = const [];
  List<WarFront> _fronts = const [];

  final _fill = Paint();
  final _progress = Paint()..style = PaintingStyle.stroke;
  final _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  void _refresh(MapState state, DateTime now) {
    if (!outdated([state, history.days.length], now)) return;
    final territories = controller.territories!.territories;
    final since = now.subtract(frontDays);
    _arrows = assaultArrows(state, territories, now);
    _fronts = warFronts(conquestsSince(since, state.recentWars, history.changesSince(since)), territories);
  }

  @override
  void paint(Canvas canvas, MapViewport viewport) {
    final state = controller.state;
    final territories = controller.territories?.territories;
    if (state == null || territories == null) return;
    final now = DateTime.now().toUtc();
    _refresh(state, now);
    for (final front in _fronts) {
      final age = now.difference(front.lastAt).inMinutes / frontDays.inMinutes;
      final color = fillColor(
        controller.colors[front.factionId] ?? preferredColor(front.factionId),
        lightTheme: lightTheme,
      );
      final faded = color.withValues(alpha: (1 - 0.6 * age).clamp(0.3, 1));
      for (final step in front.steps) {
        final to = territories[step.code]?.label;
        final from = territories[step.from]?.label;
        if (to == null || from == null) continue;
        _arrow(canvas, from, to, viewport, faded, bend: 0, weight: _frontWeight);
      }
    }

    for (final arrow in _arrows) {
      final to = territories[arrow.to]?.label;
      final from = territories[arrow.from]?.label;
      if (to == null || from == null) continue;
      final style = momentumStyle[arrow.momentum]!;
      final color = arrow.adjacent ? style.color : style.color.withValues(alpha: 0.5);
      _arrow(canvas, from, to, viewport, color, bend: _bend, gap: _targetGap, progress: arrow.progress);
    }
  }

  void _arrow(
    Canvas canvas,
    Offset from,
    Offset to,
    MapViewport viewport,
    Color color, {
    required double bend,
    double gap = 0,
    double weight = 1,
    double progress = 1,
  }) {
    final unit = 1 / viewport.scale;
    var span = to - from;
    if (span.distance == 0) return;
    final shortest = (gap + _minLength) * unit;
    if (span.distance < shortest) span = span / span.distance * shortest;
    from = to - span;
    if (!viewport.visible.overlaps(Rect.fromPoints(from, to))) return;
    final control = from + span / 2 + Offset(-span.dy, span.dx) * bend;
    final direction = to - control;
    final tip = to - direction / direction.distance * gap * unit;
    final shape = arrowShape((tip - from).distance * viewport.scale, weight: weight);
    final base = tip - direction / direction.distance * shape.headLength * unit;
    final spine = _spine(from, control, base, tip);
    final outline = _outline(spine, shape, unit);

    if (progress >= 1) {
      canvas.drawPath(outline, _fill..color = color);
    } else {
      final empty = lightTheme ? Colors.white : Colors.black;
      canvas.drawPath(outline, _fill..color = empty.withValues(alpha: 0.6 * color.a));
      if (progress > 0) {
        canvas
          ..save()
          ..clipPath(outline)
          ..drawPath(
            _partial(spine, progress),
            _progress
              ..color = color
              ..strokeWidth = (shape.headWidth + 4) * unit,
          )
          ..restore();
      }
    }
    canvas.drawPath(
      outline,
      _edge
        ..color = color
        ..strokeWidth = 1.5 * unit,
    );
  }

  List<Offset> _spine(Offset from, Offset control, Offset base, Offset tip) {
    final points = <Offset>[];
    for (var i = 0; i <= _spineSteps; i++) {
      final t = i / _spineSteps;
      final a = Offset.lerp(from, control, t)!;
      final b = Offset.lerp(control, base, t)!;
      points.add(Offset.lerp(a, b, t)!);
    }
    return points..add(tip);
  }

  Path _outline(List<Offset> spine, ({double width, double headLength, double headWidth}) shape, double unit) {
    final half = shape.width / 2 * unit;
    final last = spine.length - 2;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= last; i++) {
      final along = spine[math.min(i + 1, last + 1)] - spine[math.max(i - 1, 0)];
      final normal = Offset(-along.dy, along.dx) / along.distance;
      left.add(spine[i] + normal * half);
      right.add(spine[i] - normal * half);
    }
    final heading = spine.last - spine[last];
    final wing = Offset(-heading.dy, heading.dx) / heading.distance * (shape.headWidth / 2 * unit);
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in [spine[last] + wing, spine.last, spine[last] - wing, ...right.reversed]) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  Path _partial(List<Offset> spine, double share) {
    var total = 0.0;
    for (var i = 1; i < spine.length; i++) {
      total += (spine[i] - spine[i - 1]).distance;
    }
    var left = total * share;
    final path = Path()..moveTo(spine.first.dx, spine.first.dy);
    for (var i = 1; i < spine.length && left > 0; i++) {
      final step = (spine[i] - spine[i - 1]).distance;
      final end = left >= step ? spine[i] : Offset.lerp(spine[i - 1], spine[i], left / step)!;
      path.lineTo(end.dx, end.dy);
      left -= step;
    }
    return path;
  }

  @override
  Object? hitTest(Offset mapPoint, double scale) => null;
}
