part of 'feature_diagrams.dart';

const _cityCols = 7;
const _cityRows = 4;
const _unowned = -2;

const _owners = [
  7,
  7,
  _unowned,
  2,
  2,
  0,
  0,
  7,
  7,
  4,
  4,
  2,
  0,
  _unowned,
  9,
  4,
  4,
  -1,
  -1,
  5,
  5,
  9,
  9,
  _unowned,
  -1,
  5,
  5,
  0,
];
const _warSector = 11;
const _warAttacker = 0;

// Sector, new owner and when it flips
const _ownerChanges = [(11, 0, 0.3), (2, 7, 0.4), (16, 9, 0.5), (23, -1, 0.58), (13, 0, 0.66), (9, 7, 0.74)];

const _flightDestination = 'United Kingdom';
const _flights = [
  ('Ana', _flightDestination, 0.2, 1.65),
  ('Kai', 'Argentina', 0.05, 0.85),
  ('Mia', 'Canada', 0.25, 0.95),
];

double _hash(int i, int salt) => (sin(i * 12.9898 + salt * 78.233) * 43758.5453) % 1;

Offset _cityPoint(Rect city, int col, int row) {
  final int i = row * (_cityCols + 1) + col;
  return Offset(
    city.left + (col + (_hash(i, 1) - 0.5) * 0.5) * city.width / _cityCols,
    city.top + (row + (_hash(i, 2) - 0.5) * 0.5) * city.height / _cityRows,
  );
}

List<Offset> _sectorCorners(Rect city, int sector) {
  final int col = sector % _cityCols, row = sector ~/ _cityCols;
  return [
    _cityPoint(city, col, row),
    _cityPoint(city, col + 1, row),
    _cityPoint(city, col + 1, row + 1),
    _cityPoint(city, col, row + 1),
  ];
}

extension on _FeatureDiagramPainter {
  Color _ownerColor(int owner) => owner == _unowned ? unownedFill : fillColor(owner, lightTheme: palette.light);

  Rect _drawMapApp(Canvas canvas) {
    final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
    final rrect = RRect.fromRectAndRadius(full, Radius.circular(u * 1.5));
    canvas.drawRRect(rrect, Paint()..color = palette.panel);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTRB(full.left, full.top + u * 8, full.right, full.bottom),
      Paint()..color = Color.alphaBlend(palette.ink.withValues(alpha: 0.05), palette.panel),
    );
    _drawAppBar(canvas, full);
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.3
        ..color = palette.ink.withValues(alpha: 0.18),
    );
    return Rect.fromLTRB(full.left, full.top + u * 8, full.right, full.bottom);
  }

  void _clipMap(Canvas canvas, Rect map) => canvas.clipRRect(
    RRect.fromRectAndCorners(map, bottomLeft: Radius.circular(u * 1.5), bottomRight: Radius.circular(u * 1.5)),
  );

  void _drawSector(Canvas canvas, List<Offset> corners, Color color) {
    final path = Path()..addPolygon(corners, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.25
        ..strokeJoin = StrokeJoin.round
        ..color = palette.ink.withValues(alpha: 0.3),
    );
  }

  void _paintMapTerritories(Canvas canvas, Size size, double t) {
    final Rect map = _drawMapApp(canvas);
    final Rect city = map.deflate(u * 5);
    final List<Offset> war = _sectorCorners(city, _warSector);
    final Offset warCenter = war.reduce((a, b) => a + b) / 4;
    final double warIn = _seg(t, 0.3, 0.36);
    final double tap = _seg(t, 0.5, 0.55);
    final double sheet = _seg(t, 0.56, 0.66);

    canvas.save();
    _clipMap(canvas, map);
    for (var i = 0; i < _owners.length; i++) {
      final double show = _seg(t, 0.04 + i * 0.007, 0.14 + i * 0.007);
      _drawSector(canvas, _sectorCorners(city, i), Color.lerp(unownedFill, _ownerColor(_owners[i]), show)!);
    }
    if (warIn > 0) {
      final double pulse = 0.5 + 0.5 * sin(t * pi * 16);
      final path = Path()..addPolygon(war, true);
      canvas.drawPath(path, Paint()..color = Colors.red.withValues(alpha: 0.4 * pulse * warIn));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * (0.5 + 0.5 * pulse)
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.red[600]!.withValues(alpha: warIn),
      );
      canvas.drawCircle(warCenter, u * 3.2 * warIn, Paint()..color = Colors.black.withValues(alpha: 0.55 * warIn));
      _drawIcon(canvas, MdiIcons.swordCross, warCenter, u * 4 * warIn, Colors.white.withValues(alpha: warIn));
    }

    if (sheet > 0) {
      final Rect panel = Rect.fromLTWH(map.left, map.bottom - u * 17 * sheet, map.width, u * 17);
      final shape = RRect.fromRectAndCorners(
        panel,
        topLeft: Radius.circular(u * 2.5),
        topRight: Radius.circular(u * 2.5),
      );
      canvas.drawShadow(Path()..addRRect(shape), Colors.black, u * 1.5, false);
      canvas.drawRRect(shape, Paint()..color = palette.panel);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(panel.center.dx, panel.top + u * 1.6), width: u * 8, height: u * 0.8),
          Radius.circular(u),
        ),
        Paint()..color = palette.ink.withValues(alpha: 0.25),
      );
      final double row = panel.top + u * 6;
      final Rect track = Rect.fromLTWH(panel.left + u * 18, row - u * 1.2, panel.width - u * 36, u * 2.4);
      final double progress = 0.25 + 0.5 * _seg(t, 0.66, 0.86);
      for (final (owner, x) in [(_owners[_warSector], panel.left + u * 6), (_warAttacker, panel.right - u * 6)]) {
        canvas.drawCircle(Offset(x, row), u * 2.2, Paint()..color = _ownerColor(owner));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, row + u * 5), width: u * 9, height: u * 1.6),
            Radius.circular(u),
          ),
          Paint()..color = palette.ink.withValues(alpha: 0.2),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(track, Radius.circular(u * 1.2)),
        Paint()..color = _ownerColor(_owners[_warSector]),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(track.right - track.width * progress, track.top, track.width * progress, track.height),
          Radius.circular(u * 1.2),
        ),
        Paint()..color = _ownerColor(_warAttacker),
      );
      _drawIcon(canvas, MdiIcons.swordCross, Offset(track.center.dx, row + u * 5), u * 3.4, palette.ink);
    }
    canvas.restore();

    _drawFinger(
      canvas,
      Offset.lerp(Offset(map.right - u * 10, size.height + u * 4), warCenter, _seg(t, 0.38, 0.5))!,
      alpha: _seg(t, 0.38, 0.44) * (1 - _seg(t, 0.56, 0.62)),
      ring: tap > 0 && tap < 1 ? tap : 0,
    );
  }

  void _paintMap3d(Canvas canvas, Size size, double t) {
    final Rect map = _drawMapApp(canvas);
    final Rect city = map.deflate(u * 5);
    final Rect button = Rect.fromCenter(
      center: Offset(map.right - u * 7, map.top + u * 5),
      width: u * 8,
      height: u * 5,
    );
    final double tap = _seg(t, 0.2, 0.25);
    final double tilt = 0.95 * _seg(t, 0.28, 0.5);
    final double rise = _seg(t, 0.42, 0.68);
    final double turn = 0.35 * _seg(t, 0.5, 0.9);
    final Offset middle = city.center + Offset(0, u * 2 * tilt);
    final double eye = u * 130;

    Offset project(Offset ground, double z) {
      final Offset p = ground - city.center;
      final double x = p.dx * cos(turn) - p.dy * sin(turn);
      final double y = p.dx * sin(turn) + p.dy * cos(turn);
      final double f = eye / (eye - y * sin(tilt) - z * cos(tilt));
      return Offset(middle.dx + x * f, middle.dy + (y * cos(tilt) - z * sin(tilt)) * f);
    }

    double depth(Offset ground) {
      final Offset p = ground - city.center;
      return p.dx * sin(turn) + p.dy * cos(turn);
    }

    canvas.save();
    _clipMap(canvas, map);
    final centers = <int, Offset>{};
    for (var i = 0; i < _owners.length; i++) {
      final List<Offset> corners = _sectorCorners(city, i);
      centers[i] = corners.reduce((a, b) => a + b) / 4;
      _drawSector(canvas, [for (final c in corners) project(c, 0)], _ownerColor(_owners[i]));
    }

    if (rise > 0) {
      final Color base = palette.light ? Colors.grey[200]! : Colors.grey[700]!;
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.15
        ..color = Colors.black.withValues(alpha: 0.3);
      final List<int> order = List.generate(_owners.length, (i) => i)
        ..sort((a, b) => depth(centers[a]!).compareTo(depth(centers[b]!)));
      for (final i in order) {
        final Offset c = centers[i]!;
        final double half = u * (1.6 + 1.2 * _hash(i, 3));
        final double height = u * (3 + 9 * _hash(i, 4)) * rise;
        final Color color = Color.alphaBlend(_ownerColor(_owners[i]).withValues(alpha: 0.45), base);
        final List<Offset> ground = [
          c + Offset(-half, -half),
          c + Offset(half, -half),
          c + Offset(half, half),
          c + Offset(-half, half),
        ];
        final sides = [
          for (var k = 0; k < 4; k++) (ground[k], ground[(k + 1) % 4], const [0.78, 0.62, 0.88, 0.7][k]),
        ]..sort((a, b) => depth((a.$1 + a.$2) / 2).compareTo(depth((b.$1 + b.$2) / 2)));
        for (final (a, b, shade) in sides) {
          final face = Path()..addPolygon([project(a, 0), project(b, 0), project(b, height), project(a, height)], true);
          canvas.drawPath(face, Paint()..color = Color.lerp(Colors.black, color, shade)!);
          canvas.drawPath(face, edge);
        }
        final top = Path()..addPolygon([for (final g in ground) project(g, height)], true);
        canvas.drawPath(top, Paint()..color = color);
        canvas.drawPath(top, edge);
      }
    }
    canvas.restore();

    final shape = RRect.fromRectAndRadius(button, Radius.circular(u * 1.2));
    canvas.drawShadow(Path()..addRRect(shape), Colors.black, u * 0.8, false);
    canvas.drawRRect(shape, Paint()..color = Color.lerp(palette.panel, _FeatureDiagramPainter._blue, tap)!);
    _drawLabel(canvas, "3D", button.center, u * 3.2, Color.lerp(palette.ink, Colors.white, tap)!);

    _drawFinger(
      canvas,
      Offset.lerp(Offset(map.right - u * 4, size.height + u * 4), button.center, _seg(t, 0.06, 0.2))!,
      alpha: _seg(t, 0.06, 0.11) * (1 - _seg(t, 0.28, 0.34)),
      ring: tap > 0 && tap < 1 ? tap : 0,
    );
  }

  void _paintMapFlights(Canvas canvas, double t) {
    final Rect area = _drawMapApp(canvas);
    final double side = area.height;
    final Rect box = Rect.fromCenter(center: area.center, width: side, height: side);
    final projection = GlobeProjection(lon: -105 + 75 * t, lat: 24, size: box.size);
    final Path globe = projection.outline;
    final LonLat torn = flightPlaces[tornPlace]!;
    final double arrived = _seg(t, 0.55, 0.63);

    canvas.save();
    _clipMap(canvas, area);
    canvas.translate(box.left, box.top);
    canvas.drawPath(globe, Paint()..color = flightsSeaColor);
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.15
      ..color = Colors.white.withValues(alpha: 0.08);
    for (final line in graticule) {
      canvas.drawPath(projection.line(line), grid);
    }
    canvas.drawPath(
      globe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.4
        ..color = flightsLimbColor,
    );
    for (final MapEntry(:key, :value) in flightPlaces.entries) {
      final Offset? at = projection.place(value);
      if (at == null) continue;
      final bool home = key == tornPlace;
      canvas.drawCircle(
        at,
        u * (home ? 1 : 0.5),
        Paint()..color = home ? flightsTornColor : Colors.white.withValues(alpha: 0.35),
      );
      if (home) _drawLabel(canvas, "Torn", at + Offset(0, u * 2.6), u * 2.4, flightsTornColor);
    }

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black;
    final route = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.3
      ..color = flightsFlyingColor.withValues(alpha: 0.45);
    for (final (i, (name, place, from, to)) in _flights.indexed) {
      final LonLat end = flightPlaces[place]!;
      final double progress = min(1.0, from + (to - from) * t);
      canvas.drawPath(projection.line(_flightLines[i], dashed: true), route);
      if (progress >= 1) continue;
      final Offset? at = projection.place(greatCircle(torn, end, progress));
      final Offset? ahead = projection.place(greatCircle(torn, end, progress + 0.02));
      if (at == null || ahead == null) continue;
      final double length = u * 5;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate((ahead - at).direction);
      canvas.scale(length);
      canvas.drawPath(_life.whole, Paint()..color = flightsFlyingColor);
      canvas.drawPath(_life.whole, outline..strokeWidth = 0.8 / length);
      canvas.restore();
      _drawLabel(canvas, name, at + Offset(0, u * 3.6), u * 2.6, flightsFlyingColor);
    }

    final Offset? star = projection.place(flightPlaces[_flightDestination]!);
    if (arrived > 0 && star != null) {
      for (final (name, angle) in [('Ana', -0.5), ('Leo', 0.4)]) {
        final Offset end = star + Offset.fromDirection(angle, u * 8 * arrived);
        canvas.drawLine(
          star,
          end,
          Paint()
            ..strokeWidth = u * 0.3
            ..color = flightsAbroadColor.withValues(alpha: 0.6 * arrived),
        );
        canvas.drawCircle(end, u * 0.6, Paint()..color = flightsAbroadColor.withValues(alpha: arrived));
        _drawLabel(canvas, name, end + Offset(u * 4.5, 0), u * 2.6, flightsStarTextColor.withValues(alpha: arrived));
      }
      canvas.drawCircle(star, u * 2.2 * arrived, Paint()..color = flightsAbroadColor);
      canvas.drawCircle(
        star,
        u * 2.2 * arrived,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.4
          ..color = flightsTornColor,
      );
      _drawLabel(canvas, "2", star, u * 2.6 * arrived, flightsAbroadTextColor);
    }
    canvas.restore();
  }

  void _paintMapHistory(Canvas canvas, Size size, double t) {
    final Rect map = _drawMapApp(canvas);
    final Rect bar = Rect.fromLTWH(map.left + u * 3, map.bottom - u * 9, map.width - u * 6, u * 7);
    final Rect city = Rect.fromLTRB(map.left + u * 6, map.top + u * 3, map.right - u * 6, bar.top - u * 2.5);
    final Offset play = Offset(bar.left + u * 4, bar.center.dy);
    final double tap = _seg(t, 0.12, 0.16);
    final double progress = ((t - 0.18) / 0.7).clamp(0, 1);
    final Rect track = Rect.fromLTRB(
      bar.left + u * 8,
      bar.center.dy - u * 0.5,
      bar.right - u * 22,
      bar.center.dy + u * 0.5,
    );

    canvas.save();
    _clipMap(canvas, map);
    for (var i = 0; i < _owners.length; i++) {
      Color color = _ownerColor(_owners[i]);
      double flash = 0;
      for (final (sector, owner, at) in _ownerChanges) {
        if (sector != i) continue;
        final double flip = _seg(t, at, at + 0.04);
        color = Color.lerp(color, _ownerColor(owner), flip)!;
        if (flip > 0 && flip < 1) flash = sin(pi * flip);
      }
      final List<Offset> corners = _sectorCorners(city, i);
      _drawSector(canvas, corners, color);
      if (flash > 0) {
        canvas.drawPath(
          Path()..addPolygon(corners, true),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.8
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white.withValues(alpha: flash),
        );
      }
    }
    canvas.restore();

    final shape = RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2));
    canvas.drawShadow(Path()..addRRect(shape), Colors.black, u, false);
    canvas.drawRRect(shape, Paint()..color = palette.panel);
    final Color blue = _FeatureDiagramPainter._blue;
    _drawIcon(canvas, t < 0.15 ? Icons.play_arrow_rounded : Icons.pause_rounded, play, u * 5, blue);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, Radius.circular(u * 0.5)),
      Paint()..color = palette.ink.withValues(alpha: 0.15),
    );
    for (final (_, _, at) in _ownerChanges) {
      canvas.drawCircle(
        Offset(track.left + track.width * ((at - 0.18) / 0.7), track.center.dy),
        u * 0.45,
        Paint()..color = palette.ink.withValues(alpha: 0.45),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(track.left, track.top, track.width * progress, track.height),
        Radius.circular(u * 0.5),
      ),
      Paint()..color = blue,
    );
    canvas.drawCircle(Offset(track.left + track.width * progress, track.center.dy), u * 1.4, Paint()..color = blue);
    _drawLabel(
      canvas,
      progress >= 1
          ? "Now"
          : DateFormat('EEE d MMM').format(DateTime(2026, 9, 22).add(Duration(days: (progress * 60).floor()))),
      Offset(bar.right - u * 11, bar.center.dy),
      u * 2.7,
      palette.ink.withValues(alpha: 0.85),
    );

    _drawFinger(
      canvas,
      Offset.lerp(Offset(bar.left + u * 14, size.height + u * 4), play, _seg(t, 0.02, 0.12))!,
      alpha: _seg(t, 0.02, 0.07) * (1 - _seg(t, 0.18, 0.24)),
      ring: tap > 0 && tap < 1 ? tap : 0,
    );
  }
}
