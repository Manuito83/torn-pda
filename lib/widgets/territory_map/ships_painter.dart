import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/city_ships.dart';
import 'package:torn_pda/models/territory_map/sea_chart.dart';
import 'package:torn_pda/widgets/territory_map/city_life_shapes.dart';
import 'package:torn_pda/widgets/territory_map/point_buffer.dart';

const _hulls = <ShipKind, List<Color>>{
  ShipKind.cargo: [Color(0xFF3A4250), Color(0xFF7A2F2A), Color(0xFF24303F), Color(0xFF2F4A3F)],
  ShipKind.tanker: [Color(0xFF5C2F29), Color(0xFF30343B)],
  ShipKind.cruise: [Color(0xFFF4F5F7)],
  ShipKind.ferry: [Color(0xFFF1F3F5)],
  ShipKind.yacht: [Color(0xFFFBFBFB)],
  ShipKind.sailboat: [Color(0xFFFAFAFA)],
  ShipKind.speedboat: [Color(0xFFFFFFFF)],
  ShipKind.fishing: [Color(0xFF2F6F86), Color(0xFF8A3B2E), Color(0xFF3F7A52)],
};

// Never shorter than this on screen
const _minPixels = <ShipKind, double>{
  ShipKind.cargo: 8,
  ShipKind.tanker: 8,
  ShipKind.cruise: 9,
  ShipKind.ferry: 6,
  ShipKind.yacht: 4.5,
  ShipKind.sailboat: 4,
  ShipKind.speedboat: 3.5,
  ShipKind.fishing: 4,
};

// Color and rect, y in half beams
const _decks = <ShipKind, List<(int, double, double, double, double)>>{
  ShipKind.cargo: [(0xFFB9B3A8, -0.44, -0.82, 0.8, 1.64)],
  ShipKind.tanker: [
    (0xFF8F4A3A, -0.3, -0.8, 0.68, 1.6),
    (0xFFC9C3B6, -0.28, -0.12, 0.64, 0.24),
    (0xFFF2F2EE, -0.45, -0.72, 0.12, 1.44),
  ],
  ShipKind.cruise: [
    (0xFFDFE6EE, -0.4, -0.74, 0.74, 1.48),
    (0xFFFFFFFF, -0.34, -0.5, 0.6, 1),
    (0xFF58B6D6, -0.05, -0.26, 0.1, 0.52),
    (0xFF58B6D6, 0.1, -0.2, 0.06, 0.4),
    (0xFFE0A030, -0.3, -0.3, 0.07, 0.6),
  ],
  ShipKind.ferry: [(0xFFC9D3DE, -0.4, -0.72, 0.8, 1.44), (0xFF2F6FA8, -0.12, -0.72, 0.24, 1.44)],
  ShipKind.yacht: [(0xFF2C3E55, -0.12, -0.5, 0.3, 1)],
  ShipKind.sailboat: [],
  ShipKind.speedboat: [(0xFF2C3E55, -0.12, -0.5, 0.3, 1)],
  ShipKind.fishing: [(0xFFF0EFE9, -0.1, -0.55, 0.26, 1.1)],
};

const _boxes = [Color(0xFFB5493C), Color(0xFF3F6F9E), Color(0xFFD08A3A), Color(0xFFE9E7E1), Color(0xFF4F8A5B)];
const _bridge = Color(0xFFF2F2EE);
const _decksFromPixels = 9.0;
const _shipsMargin = 600.0;

Color _atNight(Color color, double k, double dark) => Color.lerp(
  color,
  Color.from(alpha: color.a, red: color.r * k + 6 / 255, green: color.g * k + 9 / 255, blue: color.b * k + 16 / 255),
  dark,
)!;

// Length one, bow at +x
class ShipShapes {
  late final hulls = {for (final kind in ShipKind.values) kind: _hull(shipSpecs[kind]!.beam / 2)};
  late final sail = Path()..addPolygon(const [Offset(0.3, 0), Offset(-0.34, -1), Offset(-0.3, 0)], true);
  final fill = Paint();
  final wakes = ColorMesh();

  Path _hull(double w) => Path()
    ..moveTo(0.5, 0)
    ..quadraticBezierTo(0.42, -w, 0.26, -w)
    ..lineTo(-0.44, -w)
    ..quadraticBezierTo(-0.5, -w, -0.5, -w * 0.6)
    ..lineTo(-0.5, w * 0.6)
    ..quadraticBezierTo(-0.5, w, -0.44, w)
    ..lineTo(0.26, w)
    ..quadraticBezierTo(0.42, w, 0.5, 0)
    ..close();
}

void paintShips(
  Canvas canvas,
  ShipShapes shapes,
  List<Ship> ships, {
  required double clock,
  required Rect area,
  required double scale,
  required double dark,
  required bool lightTheme,
}) {
  final shown = <(Ship, double, double)>[];
  final around = area.inflate(_shipsMargin);
  final mesh = shapes.wakes;
  final foam = Color.lerp(Colors.white, const Color(0xFFAABED7), dark)!;
  final strength = 0.62 - 0.32 * dark;
  for (final ship in ships) {
    final alpha = ship.alpha;
    if (alpha < 0.03 || !around.contains(Offset(ship.x, ship.y))) continue;
    final spec = ship.spec;
    final length = max(spec.length * pow(ship.size, 0.85), _minPixels[ship.kind]! / scale * (0.45 + 0.55 * ship.size));
    shown.add((ship, length, alpha));
    if (ship.wake.isEmpty) continue;

    // Wider and fainter behind
    final beam = length * spec.beam;
    final trail = [
      (x: ship.x - ship.dx * length * 0.4, y: ship.y - ship.dy * length * 0.4, age: 0.0),
      for (final w in ship.wake.reversed) (x: w.x, y: w.y, age: wakeAge(w.at, clock)),
    ];
    int color(double age) => foam.withValues(alpha: strength * alpha * (1 - age) * (1 - age)).toARGB32();
    for (var i = 0; i + 1 < trail.length; i++) {
      final p = trail[i], q = trail[i + 1];
      if (p.age >= 1) break;
      final along = Offset(q.x - p.x, q.y - p.y);
      final distance = along.distance;
      if (distance == 0) continue;
      final normal = Offset(-along.dy, along.dx) / distance;
      final qAge = min(1.0, q.age);
      final pHalf = beam * (0.55 + 2.4 * p.age) / 2, qHalf = beam * (0.55 + 2.4 * qAge) / 2;
      final pAt = Offset(p.x, p.y), qAt = Offset(q.x, q.y);
      mesh.quad(
        pAt + normal * pHalf,
        pAt - normal * pHalf,
        qAt + normal * qHalf,
        qAt - normal * qHalf,
        color(p.age),
        color(qAge),
      );
    }
  }
  mesh.draw(canvas, shapes.fill..color = Colors.white);

  final paint = shapes.fill;
  final lit = dark > seaLightsFrom;
  for (final (ship, length, alpha) in shown) {
    final heading = atan2(ship.dy, ship.dx);
    final w = ship.spec.beam / 2;
    final hull = shapes.hulls[ship.kind]!;
    final colors = _hulls[ship.kind]!;
    canvas
      ..save()
      ..translate(ship.x, ship.y)
      ..rotate(heading)
      ..scale(length, length)
      ..save()
      ..translate(0.012 * cos(-heading + 0.9), 0.02)
      ..drawPath(hull, paint..color = Color.fromRGBO(0, 10, 25, 0.28 * alpha))
      ..restore()
      ..drawPath(hull, paint..color = _atNight(colors[ship.hull % colors.length], 0.42, dark).withValues(alpha: alpha));
    if (length * scale > _decksFromPixels) {
      Color tint(Color c) => _atNight(c, 0.45, dark).withValues(alpha: alpha);
      for (final (color, left, top, width, height) in _decks[ship.kind]!) {
        canvas.drawRect(Rect.fromLTWH(left, top * w, width, height * w), paint..color = tint(Color(color)));
      }
      if (ship.kind == ShipKind.cargo) {
        for (var i = 0; i < 9; i++) {
          for (var j = 0; j < 3; j++) {
            if (groundHash(ship.seed + i * 7 + j) < 0.18) continue;
            paint.color = tint(_boxes[(groundHash(ship.seed + i * 31 + j * 5) * _boxes.length).floor()]);
            canvas.drawRect(Rect.fromLTWH(-0.3 + i * 0.07, -w * 0.78 + j * w * 0.53, 0.06, w * 0.47), paint);
          }
        }
        canvas.drawRect(Rect.fromLTWH(-0.44, -w * 0.72, 0.1, w * 1.44), paint..color = tint(_bridge));
      } else if (ship.kind == ShipKind.sailboat) {
        canvas
          ..save()
          ..scale(1, w * 2.3)
          ..drawPath(shapes.sail, paint..color = tint(Colors.white))
          ..restore();
      }
    }
    canvas.restore();
    if (lit) _paintShipLights(canvas, paint, ship, heading, length, alpha * dark, scale, lightTheme);
  }
}

void _paintShipLights(
  Canvas canvas,
  Paint paint,
  Ship ship,
  double heading,
  double length,
  double alpha,
  double scale,
  bool lightTheme,
) {
  final r = max(0.8 / scale, length * 0.03);
  final m = ship.spec.beam;
  void light(double x, double y, Color color, [double k = 1]) {
    paint.color = color.withValues(alpha: color.a * alpha);
    canvas.drawCircle(Offset(x * length, y * length), r * k, paint);
  }

  canvas
    ..save()
    ..translate(ship.x, ship.y)
    ..rotate(heading);
  paint.blendMode = lifeGlow(lightTheme);
  light(0.3, 0, const Color.fromRGBO(255, 255, 235, 0.95), 1.2);
  light(-0.46, 0, const Color.fromRGBO(255, 255, 235, 0.8));
  light(0.1, -m / 2, portRed);
  light(0.1, m / 2, starboardGreen);
  if (ship.kind == ShipKind.cruise || ship.kind == ShipKind.ferry) {
    for (var x = -0.34; x < 0.3; x += 0.07) {
      light(x, -m * 0.3, const Color.fromRGBO(255, 214, 150, 0.8), 0.8);
      light(x, m * 0.3, const Color.fromRGBO(255, 214, 150, 0.8), 0.8);
    }
  }
  paint.blendMode = BlendMode.srcOver;
  canvas.restore();
}
