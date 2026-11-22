import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_gunfire.dart';
import 'package:torn_pda/models/territory_map/city_planes.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/providers/city_life_controller.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/widgets/territory_map/city_life_shapes.dart';
import 'package:torn_pda/widgets/territory_map/ships_painter.dart';
import 'package:torn_pda/widgets/territory_map/short_animation.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_life_painter.dart';

// Rotated cars from here, dots below
const _carShapesFromScale = 0.6;

void showPlaneJoke(String joke) {
  countMapUse(mapPlaneJokeFeature);
  BotToast.showText(text: joke, contentColor: Colors.grey[700]!, duration: const Duration(seconds: 3));
}

// Runs only while seen, own layer
class CityLifeLayer extends StatefulWidget {
  const CityLifeLayer({
    super.key,
    required this.life,
    required this.visible,
    required this.scale,
    required this.lightTheme,
  });

  final CityLifeController life;
  final Rect visible;
  final double scale;
  final bool lightTheme;

  @override
  State<CityLifeLayer> createState() => _CityLifeLayerState();
}

class _CityLifeLayerState extends State<CityLifeLayer> {
  late final AppLifecycleListener _lifecycle;
  bool _shown = false;
  final _shapes = CityLifeShapes();
  final _sky = SkyShapes();
  final _ships = ShipShapes();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _sync());
    widget.life.lookAt(widget.visible, widget.scale);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shown = animationsShown(context);
    _sync();
  }

  @override
  void didUpdateWidget(CityLifeLayer old) {
    super.didUpdateWidget(old);
    if (old.life != widget.life) old.life.show(false);
    widget.life.lookAt(widget.visible, widget.scale);
    _sync();
  }

  void _sync() => widget.life.show(_shown && appResumed);

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.life.show(false);
    _sky.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CityLifePainter(
            widget.life,
            widget.visible,
            widget.scale,
            widget.lightTheme,
            _shapes,
            _sky,
            _ships,
          ),
        ),
      ),
    );
  }
}

class _CityLifePainter extends CustomPainter {
  _CityLifePainter(this.life, this.visible, this.scale, this.lightTheme, this.shapes, this.sky, this.ships)
    : super(repaint: Listenable.merge([life, life.night.level]));

  final CityLifeController life;
  final Rect visible;
  final double scale;
  final bool lightTheme;
  final CityLifeShapes shapes;
  final SkyShapes sky;
  final ShipShapes ships;

  @override
  void paint(Canvas canvas, Size size) {
    final area = visible.inflate(lifeMargin / scale);
    final dark = life.night.level.value.dark;
    final around = life.surroundings, citySky = life.sky;
    if (citySky != null && around != null) {
      paintSeaLife(
        canvas,
        sky,
        sky: citySky,
        surroundings: around,
        clock: life.clock,
        area: area,
        scale: scale,
        dark: dark,
        lightTheme: lightTheme,
      );
    }
    if (life.ships.isNotEmpty) {
      paintShips(
        canvas,
        ships,
        life.ships,
        clock: life.clock,
        area: area,
        scale: scale,
        dark: dark,
        lightTheme: lightTheme,
      );
    }
    shapes.lights.blendMode = lifeGlow(lightTheme);
    if (life.trafficOn && scale >= carsFromScale) _paintCars(canvas, area, dark);
    if (life.police.isNotEmpty) _paintPolice(canvas, area, dark);
    if (life.shots.isNotEmpty) _paintShots(canvas, area, dark);
    if (citySky != null && around != null) {
      paintClouds(
        canvas,
        sky,
        sky: citySky,
        surroundings: around,
        clock: life.clock,
        area: area,
        dark: dark,
        lightTheme: lightTheme,
      );
    }
    if (life.planesOn) {
      for (final plushie in life.plushies) {
        _paintPlushie(canvas, plushie);
      }
      for (final plane in life.planes) {
        _paintPlane(canvas, plane, area, dark);
      }
    }
  }

  void _paintCars(Canvas canvas, Rect area, double dark) {
    final colors = shapes.carColors(lightTheme, dark);
    final rotated = scale > _carShapesFromScale;
    final points = shapes.carPoints;
    final paths = shapes.carPaths;
    for (var i = 0; i < colors.length; i++) {
      points[i].clear();
      paths[i].reset();
    }
    final lights = dark > 0.05;
    final ahead = max(1.6 / scale, 4.5);
    final dot = max(1.3 / scale, 5.0), head = max(3.6 / scale, 6.8), tail = max(1.4 / scale, 2.6);
    final heads = shapes.heads..clear();
    final tails = shapes.tails..clear();
    final farHeads = shapes.farHeads..reset();
    final farTails = shapes.farTails..reset();
    for (final car in life.cars) {
      if (car.alpha < 0.05 || !area.contains(Offset(car.x, car.y))) continue;
      final away = car.size < 1 || car.alpha < 1;
      // Towards the horizon, smaller and thinner
      final shrink = 0.45 + 0.55 * car.size;
      if (lights) {
        final hx = car.x + car.dx * ahead, hy = car.y + car.dy * ahead;
        final tx = car.x - car.dx * ahead * 0.6, ty = car.y - car.dy * ahead * 0.6;
        if (away) {
          farHeads.addRect(Rect.fromCenter(center: Offset(hx, hy), width: head * shrink, height: head * shrink));
          farTails.addRect(Rect.fromCenter(center: Offset(tx, ty), width: tail * shrink, height: tail * shrink));
        } else {
          heads.add(hx, hy);
          tails.add(tx, ty);
        }
      }
      final c = car.color;
      if (!rotated && !away) {
        points[c].add(car.x, car.y);
        continue;
      }
      if (!rotated) {
        final side = dot * shrink * (0.4 + 0.6 * car.alpha);
        paths[c].addRect(Rect.fromCenter(center: Offset(car.x, car.y), width: side, height: side));
        continue;
      }
      final ax = car.dx * 2.3 * car.size, ay = car.dy * 2.3 * car.size;
      final nx = -car.dy * 1.05 * car.size, ny = car.dx * 1.05 * car.size;
      paths[c]
        ..moveTo(car.x + ax + nx, car.y + ay + ny)
        ..lineTo(car.x + ax - nx, car.y + ay - ny)
        ..lineTo(car.x - ax - nx, car.y - ay - ny)
        ..lineTo(car.x - ax + nx, car.y - ay + ny)
        ..close();
    }
    paintCars(
      canvas,
      shapes,
      colors,
      rotated: rotated,
      dot: dot,
      head: head,
      tail: tail,
      glow: dark,
      lightTheme: lightTheme,
    );

    final side = max(3.2 / scale, 6.5);
    for (final customs in life.customs) {
      final car = customs.car;
      if (!area.contains(Offset(car.x, car.y))) continue;
      shapes.fill.color = customsColor(lightTheme).withValues(alpha: customs.alpha.clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromCenter(center: Offset(car.x, car.y), width: side, height: side), shapes.fill);
    }
  }

  void _paintPolice(Canvas canvas, Rect area, double dark) {
    final side = max(2.4 / scale, 5.2);
    final glow = max(7 / scale, 16.0) * (1 + dark * 0.5);
    final flick = (life.clock / 0.14).floor().isOdd;
    final body = policeBody(dark);
    for (final police in life.police) {
      final car = police.car;
      final alpha = police.alpha.clamp(0.0, 1.0);
      if (alpha == 0 || !area.contains(Offset(car.x, car.y))) continue;
      shapes.fill.color = body.withValues(alpha: alpha);
      canvas.drawRect(Rect.fromCenter(center: Offset(car.x, car.y), width: side, height: side), shapes.fill);
      paintBeacons(canvas, shapes, car.x, car.y, glow, flick, alpha);
    }
  }

  void _paintShots(Canvas canvas, Rect area, double dark) {
    final now = life.clock;
    final flash = (4 * scale).clamp(1.1, 3.2) * (1 + dark * 0.5) / scale;
    final flashes = shapes.flashes..reset();
    final halos = shapes.halos..reset();
    final tracers = shapes.tracers..reset();
    for (final shot in life.shots) {
      final age = now - shot.at;
      if (age < 0 || !area.contains(Offset(shot.x, shot.y))) continue;
      if (age <= shot.life) {
        final at = Offset(shot.x, shot.y);
        flashes.addOval(Rect.fromCircle(center: at, radius: flash * (1 - age / shot.life * 0.5)));
        if (dark > 0.2) halos.addOval(Rect.fromCircle(center: at, radius: flash * 3.2));
      }
      final toX = shot.toX, toY = shot.toY;
      if (toX == null || toY == null || age > tracerLife) continue;
      final u = age / tracerLife, v = min(1.0, u + 0.25);
      tracers
        ..moveTo(shot.x + (toX - shot.x) * u, shot.y + (toY - shot.y) * u)
        ..lineTo(shot.x + (toX - shot.x) * v, shot.y + (toY - shot.y) * v);
    }
    paintShots(canvas, shapes, dark: dark, tracerWidth: (2 * scale).clamp(0.8, 1.6) / scale, lightTheme: lightTheme);
  }

  void _paintPlane(Canvas canvas, Plane p, Rect area, double dark) {
    if (p.shown <= 0.02 || !area.contains(Offset(p.mapX, p.mapY))) return;
    final length = planeLength(p, scale);
    final lit = dark > 0.25;

    // Afternoon sun, fades with height
    final fade = max(0.0, 1 - p.z / 420) * p.shown * (lit ? 0.3 : 1);
    if (fade > 0.02) {
      final shadow = length / (1 + p.z / 900);
      canvas
        ..save()
        ..translate(p.mapX + p.z * 0.35 * p.shrink, p.mapY + p.z * 0.5 * p.shrink)
        ..rotate(p.heading)
        ..scale(shadow, shadow * p.wing)
        ..drawPath(shapes.whole, shapes.fill..color = Colors.black.withValues(alpha: 0.32 * fade))
        ..restore();
    }

    canvas
      ..save()
      ..translate(p.mapX, p.mapY)
      ..rotate(p.heading)
      ..scale(length, length * p.wing);
    paintPlane(canvas, p, shapes, pixels: scale * length, lit: lit, lightTheme: lightTheme, clock: life.clock);
    canvas.restore();
  }

  void _paintPlushie(Canvas canvas, Plushie plushie) {
    canvas
      ..save()
      ..translate(plushie.x, plushie.y)
      ..rotate(plushie.landedAt == null ? life.clock / 0.16 : 0);
    paintPlushie(canvas, shapes, max(3 / scale, 4.5) * (1 + plushie.z / 900));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CityLifePainter old) =>
      old.life != life || old.visible != visible || old.scale != scale || old.lightTheme != lightTheme;
}
