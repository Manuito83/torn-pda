import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/world_land.dart';

typedef LonLat = ({double lon, double lat});

const _toRadians = pi / 180;
const _toDegrees = 180 / pi;
const _limbStep = 3 * _toRadians;

// Flat map keeps Torn in the middle
const LonLat flatHome = (lon: -90, lat: 0);
const _globeMargin = 8.0;
const _dashLength = 3.0;
const _dashEvery = 7.0;

abstract class FlightProjection {
  // Null when out of sight
  Offset? place(LonLat point);

  Path landPath(WorldLand land);

  // Pieces out of sight are left out
  Path line(List<LonLat> points, {bool dashed = false});

  // World outline, to fill and clip
  Path get outline;

  bool get canTurn;

  // Null off the world
  LonLat? lonLatAt(Offset at);

  // Along the equator
  double get perDegree;
}

LonLat greatCircle(LonLat a, LonLat b, double t) {
  final (ax, ay, az) = _unit(a);
  final (bx, by, bz) = _unit(b);
  final angle = acos((ax * bx + ay * by + az * bz).clamp(-1.0, 1.0));
  if (angle < 1e-9) return a;
  final wa = sin((1 - t) * angle) / sin(angle);
  final wb = sin(t * angle) / sin(angle);
  final x = wa * ax + wb * bx;
  final y = wa * ay + wb * by;
  final z = wa * az + wb * bz;
  return (lon: atan2(y, x) * _toDegrees, lat: atan2(z, sqrt(x * x + y * y)) * _toDegrees);
}

List<LonLat> greatCircleLine(LonLat a, LonLat b, {int steps = 48}) => [
  for (var i = 0; i <= steps; i++) greatCircle(a, b, i / steps),
];

(double, double, double) _unit(LonLat point) {
  final lambda = point.lon * _toRadians;
  final phi = point.lat * _toRadians;
  return (cos(phi) * cos(lambda), cos(phi) * sin(lambda), sin(phi));
}

double shortestLon(double from, double to) => (to - from + 540) % 360 - 180;

class _LineBuilder {
  _LineBuilder(this.dashed);

  final bool dashed;
  final path = Path();
  Offset _last = Offset.zero;
  double _walked = 0;

  void start(Offset at) {
    path.moveTo(at.dx, at.dy);
    _last = at;
    _walked = 0;
  }

  void to(Offset at) {
    if (!dashed) {
      path.lineTo(at.dx, at.dy);
      return;
    }
    final length = (at - _last).distance;
    var done = 0.0;
    while (done < length) {
      final phase = _walked % _dashEvery;
      final drawing = phase < _dashLength;
      final step = min(length - done, (drawing ? _dashLength : _dashEvery) - phase);
      done += step;
      _walked += step;
      final end = Offset.lerp(_last, at, done / length)!;
      drawing ? path.lineTo(end.dx, end.dy) : path.moveTo(end.dx, end.dy);
    }
    _last = at;
  }
}

final List<List<LonLat>> graticule = [
  for (var lon = -180.0; lon < 180; lon += 10) [for (var lat = -80.0; lat <= 80; lat += 5) (lon: lon, lat: lat)],
  for (var lat = -80.0; lat <= 80; lat += 10) [for (var lon = -180.0; lon <= 180; lon += 5) (lon: lon, lat: lat)],
];

class GlobeProjection implements FlightProjection {
  GlobeProjection({required double lon, required double lat, required Size size, double zoom = 1})
    : _sinLon = sin(lon * _toRadians),
      _cosLon = cos(lon * _toRadians),
      _sinLat = sin(lat * _toRadians),
      _cosLat = cos(lat * _toRadians),
      center = size.center(Offset.zero),
      radius = max(1.0, size.shortestSide / 2 - _globeMargin) * zoom;

  final double _sinLon, _cosLon, _sinLat, _cosLat;
  final Offset center;
  final double radius;

  @override
  bool get canTurn => true;

  @override
  double get perDegree => radius * _toRadians;

  @override
  LonLat? lonLatAt(Offset at) {
    final x = (at.dx - center.dx) / radius;
    final y = (center.dy - at.dy) / radius;
    final away = x * x + y * y;
    if (away > 1) return null;
    final z = sqrt(1 - away);
    final wx = -_sinLon * x - _sinLat * _cosLon * y + _cosLat * _cosLon * z;
    final wy = _cosLon * x - _sinLat * _sinLon * y + _cosLat * _sinLon * z;
    final wz = _cosLat * y + _sinLat * z;
    return (lon: atan2(wy, wx) * _toDegrees, lat: asin(wz.clamp(-1.0, 1.0)) * _toDegrees);
  }

  @override
  Path get outline => Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  (double, double, double) _rotate(double x, double y, double z) => (
    -_sinLon * x + _cosLon * y,
    -_sinLat * _cosLon * x - _sinLat * _sinLon * y + _cosLat * z,
    _cosLat * _cosLon * x + _cosLat * _sinLon * y + _sinLat * z,
  );

  Offset _screen(double x, double y) => Offset(center.dx + radius * x, center.dy - radius * y);

  @override
  Offset? place(LonLat point) {
    final (ux, uy, uz) = _unit(point);
    final (x, y, z) = _rotate(ux, uy, uz);
    return z < 0.02 ? null : _screen(x, y);
  }

  @override
  Path line(List<LonLat> points, {bool dashed = false}) {
    final builder = _LineBuilder(dashed);
    var drawing = false;
    for (final point in points) {
      final at = place(point);
      if (at == null) {
        drawing = false;
      } else if (drawing) {
        builder.to(at);
      } else {
        builder.start(at);
        drawing = true;
      }
    }
    return builder.path;
  }

  // Cut rings rejoin along the horizon
  @override
  Path landPath(WorldLand land) {
    final path = Path()..fillType = PathFillType.evenOdd;
    var longest = 0;
    for (final polygon in land.polygons) {
      for (final ring in polygon) {
        longest = max(longest, ring.length);
      }
    }
    final view = Float64List(longest * 3);
    for (final polygon in land.polygons) {
      final arcs = <_HorizonArc>[];
      for (final ring in polygon) {
        _addRing(ring, view, path, arcs);
      }
      _rejoin(arcs, path);
    }
    return path;
  }

  void _addRing(LandRing ring, Float64List view, Path path, List<_HorizonArc> arcs) {
    final count = ring.length;
    final unit = ring.unit;
    for (var i = 0; i < count * 3; i += 3) {
      final (x, y, z) = _rotate(unit[i], unit[i + 1], unit[i + 2]);
      view[i] = x;
      view[i + 1] = y;
      view[i + 2] = z;
    }

    // Starts where the ring comes into sight
    var start = -1;
    for (var i = 0; i < count; i++) {
      if (view[i * 3 + 2] >= 0 && view[(i + count - 1) % count * 3 + 2] < 0) {
        start = i;
        break;
      }
    }
    if (start < 0) {
      if (view[2] < 0) return;
      for (var i = 0; i < count; i++) {
        final at = _screen(view[i * 3], view[i * 3 + 1]);
        i == 0 ? path.moveTo(at.dx, at.dy) : path.lineTo(at.dx, at.dy);
      }
      path.close();
      return;
    }

    _HorizonArc? open;
    for (var step = 0; step < count; step++) {
      final i = (start + step) % count;
      final previous = (i + count - 1) % count;
      if (view[i * 3 + 2] >= 0) {
        if (open == null) {
          final (x, y) = _horizonPoint(view, previous, i);
          open = _HorizonArc(atan2(y, x))..points.add(_screen(x, y));
        }
        open.points.add(_screen(view[i * 3], view[i * 3 + 1]));
      } else if (open != null) {
        final (x, y) = _horizonPoint(view, i, previous);
        open.points.add(_screen(x, y));
        open.endAngle = atan2(y, x);
        arcs.add(open);
        open = null;
      }
    }
  }

  (double, double) _horizonPoint(Float64List view, int hidden, int shown) {
    final shownZ = view[shown * 3 + 2];
    final t = shownZ / (shownZ - view[hidden * 3 + 2]);
    final x = view[shown * 3] + (view[hidden * 3] - view[shown * 3]) * t;
    final y = view[shown * 3 + 1] + (view[hidden * 3 + 1] - view[shown * 3 + 1]) * t;
    final length = sqrt(x * x + y * y);
    return length == 0 ? (1.0, 0.0) : (x / length, y / length);
  }

  // Land on the right, so clockwise
  void _rejoin(List<_HorizonArc> arcs, Path path) {
    final left = arcs.toSet();
    while (left.isNotEmpty) {
      final first = left.first;
      var arc = first;
      path.moveTo(arc.points.first.dx, arc.points.first.dy);
      while (true) {
        left.remove(arc);
        for (final point in arc.points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        final end = arc.endAngle;
        final next = arcs.reduce((a, b) => _clockwise(end, a.startAngle) <= _clockwise(end, b.startAngle) ? a : b);
        final gap = _clockwise(end, next.startAngle);
        for (var walked = _limbStep; walked < gap; walked += _limbStep) {
          final at = _screen(cos(end - walked), sin(end - walked));
          path.lineTo(at.dx, at.dy);
        }
        if (identical(next, first) || !left.contains(next)) break;
        arc = next;
      }
      path.close();
    }
  }

  double _clockwise(double from, double to) {
    final gap = (from - to) % (2 * pi);
    return gap < 0 ? gap + 2 * pi : gap;
  }
}

class _HorizonArc {
  _HorizonArc(this.startAngle);

  final double startAngle;
  double endAngle = 0;
  final points = <Offset>[];
}

double flatScale(Size size) => min(size.width / 360, size.height / 180);

class FlatProjection implements FlightProjection {
  FlatProjection(Size size, {double zoom = 1, LonLat center = flatHome})
    : _size = size,
      _scale = flatScale(size) * zoom,
      _center = center;

  final Size _size;
  final double _scale;
  final LonLat _center;

  @override
  bool get canTurn => false;

  @override
  double get perDegree => _scale;

  @override
  Path get outline {
    final top = _screen(0, 90).dy;
    final bottom = _screen(0, -90).dy;
    final half = min(180 * _scale, _size.width / 2);
    return Path()..addRect(Rect.fromLTRB(_size.width / 2 - half, top, _size.width / 2 + half, bottom));
  }

  Offset _screen(double degreesFromCenter, double lat) =>
      Offset(_size.width / 2 + degreesFromCenter * _scale, _size.height / 2 - (lat - _center.lat) * _scale);

  @override
  Offset? place(LonLat point) => _screen(shortestLon(_center.lon, point.lon), point.lat);

  @override
  LonLat? lonLatAt(Offset at) {
    final lat = _center.lat - (at.dy - _size.height / 2) / _scale;
    if (lat.abs() > 90) return null;
    final lon = _center.lon + (at.dx - _size.width / 2) / _scale;
    return (lon: (lon + 540) % 360 - 180, lat: lat);
  }

  @override
  Path line(List<LonLat> points, {bool dashed = false}) {
    final builder = _LineBuilder(dashed);
    double? last;
    for (final point in points) {
      final x = shortestLon(_center.lon, point.lon);
      final at = _screen(x, point.lat);
      if (last == null || (x - last).abs() > 180) {
        builder.start(at);
      } else {
        builder.to(at);
      }
      last = x;
    }
    return builder.path;
  }

  // Rings cross the edges, copies each side
  @override
  Path landPath(WorldLand land) {
    final base = Path();
    for (final polygon in land.polygons) {
      for (final ring in polygon) {
        var x = shortestLon(_center.lon, ring.lonLat[0]);
        final start = x;
        var at = _screen(x, ring.lonLat[1]);
        base.moveTo(at.dx, at.dy);
        for (var i = 1; i < ring.length; i++) {
          x += shortestLon(ring.lonLat[(i - 1) * 2], ring.lonLat[i * 2]);
          at = _screen(x, ring.lonLat[i * 2 + 1]);
          base.lineTo(at.dx, at.dy);
        }
        // Antarctica circles the pole, close there
        if ((x - start).abs() > 180) {
          final bottom = _screen(x, -90);
          base.lineTo(bottom.dx, bottom.dy);
          final back = _screen(start, -90);
          base.lineTo(back.dx, back.dy);
        }
        base.close();
      }
    }
    final width = 360 * _scale;
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(base, Offset.zero)
      ..addPath(base, Offset(-width, 0))
      ..addPath(base, Offset(width, 0));
  }
}
