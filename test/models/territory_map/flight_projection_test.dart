import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/flight_projection.dart';
import 'package:torn_pda/models/territory_map/world_land.dart';

const _size = Size(400, 400);

bool _onLand(WorldLand land, LonLat point) {
  for (final polygon in land.polygons) {
    var inside = false;
    for (final ring in polygon) {
      inside ^= _inRing(ring, point);
    }
    if (inside) return true;
  }
  return false;
}

bool _inRing(LandRing ring, LonLat point) {
  var inside = false;
  var lastLon = ring.lonLat[(ring.length - 1) * 2];
  var lastLat = ring.lonLat[(ring.length - 1) * 2 + 1];
  for (var i = 0; i < ring.length; i++) {
    final lon = ring.lonLat[i * 2];
    final lat = ring.lonLat[i * 2 + 1];
    final fromLast = (lastLon - point.lon + 540) % 360 - 180;
    final fromHere = (lon - point.lon + 540) % 360 - 180;
    if ((fromHere >= 0) != (fromLast >= 0) && (fromHere - fromLast).abs() < 180) {
      final latAtPoint = lat + (lastLat - lat) * (0 - fromHere) / (fromLast - fromHere);
      if (latAtPoint > point.lat) inside = !inside;
    }
    lastLon = lon;
    lastLat = lat;
  }
  return inside;
}

void main() {
  final land = worldLandFromGzip(File('assets/territory_map/world-land-110m.json.bin').readAsBytesSync());

  group('globe', () {
    test('puts the center of the view in the middle and east on the right', () {
      final globe = GlobeProjection(lon: -60, lat: 20, size: _size);
      expect(globe.place((lon: -60, lat: 20)), const Offset(200, 200));
      final east = globe.place((lon: -30, lat: 20))!;
      final north = globe.place((lon: -60, lat: 50))!;
      expect(east.dx, greaterThan(200));
      expect(north.dy, lessThan(200));
    });

    test('a point on screen goes back to where it came from, zoomed too', () {
      final globe = GlobeProjection(lon: -60, lat: 20, size: _size, zoom: 2.5);
      for (final point in const [(lon: -70.0, lat: 35.0), (lon: -50.0, lat: 5.0), (lon: -64.0, lat: 22.0)]) {
        final back = globe.lonLatAt(globe.place(point)!)!;
        expect(back.lon, closeTo(point.lon, 1e-6));
        expect(back.lat, closeTo(point.lat, 1e-6));
      }
      expect(globe.lonLatAt(Offset.zero), isNotNull);
      expect(GlobeProjection(lon: -60, lat: 20, size: _size).lonLatAt(Offset.zero), isNull);
    });

    test('the other side of the world is out of sight', () {
      final globe = GlobeProjection(lon: -60, lat: 20, size: _size);
      expect(globe.place((lon: 120, lat: -20)), isNull);
      expect(globe.place((lon: 40, lat: 0)), isNull);
    });

    test('land fills only land, from every side of the world', () {
      final random = Random(7);
      final views = [
        (lon: -60.0, lat: 20.0),
        (lon: 60.0, lat: 20.0),
        (lon: 170.0, lat: -10.0),
        (lon: 20.0, lat: 85.0),
        (lon: 100.0, lat: -85.0),
        (lon: -120.0, lat: 0.0),
      ];
      for (final view in views) {
        final globe = GlobeProjection(lon: view.lon, lat: view.lat, size: _size);
        final path = globe.landPath(land);
        var wrong = 0;
        var checked = 0;
        while (checked < 300) {
          final point = (lon: random.nextDouble() * 360 - 180, lat: asin(random.nextDouble() * 2 - 1) * 180 / pi);
          final at = globe.place(point);
          if (at == null) continue;
          checked++;
          if (path.contains(at) != _onLand(land, point)) wrong++;
        }
        expect(wrong, lessThanOrEqualTo(6));
      }
    });
  });

  group('flat map', () {
    test('keeps Torn in the middle and wraps at the far side', () {
      final flat = FlatProjection(const Size(360, 180));
      expect(flat.place((lon: -90, lat: 0)), const Offset(180, 90));
      expect(flat.place((lon: 89, lat: 0))!.dx, closeTo(359, 0.001));
      expect(flat.place((lon: 91, lat: 0))!.dx, closeTo(1, 0.001));
    });

    test('land fills only land, across the edges too', () {
      final flat = FlatProjection(const Size(720, 360));
      final path = flat.landPath(land);
      final random = Random(11);
      var wrong = 0;
      for (var i = 0; i < 1000; i++) {
        final point = (lon: random.nextDouble() * 360 - 180, lat: random.nextDouble() * 170 - 85);
        if (path.contains(flat.place(point)!) != _onLand(land, point)) wrong++;
      }
      expect(wrong, lessThanOrEqualTo(15));
    });

    test('land fills only land zoomed in over the far side', () {
      const size = Size(720, 360);
      final flat = FlatProjection(size, zoom: 4, center: (lon: 150, lat: -20));
      final path = flat.landPath(land);
      final random = Random(5);
      var wrong = 0;
      for (var i = 0; i < 500; i++) {
        final at = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
        if (path.contains(at) != _onLand(land, flat.lonLatAt(at)!)) wrong++;
      }
      expect(wrong, lessThanOrEqualTo(10));
    });
  });

  test('a route follows the great circle', () {
    const torn = (lon: -90.0, lat: 31.0);
    const japan = (lon: 138.0, lat: 36.0);
    expect(greatCircle(torn, japan, 0).lon, closeTo(-90, 1e-6));
    expect(greatCircle(torn, japan, 1).lon, closeTo(138, 1e-6));
    expect(greatCircle(torn, japan, 0.5).lat, greaterThan(55));
  });

  test('a dashed route draws 3 of every 7 pixels, across its points', () {
    final flat = FlatProjection(const Size(360, 180));
    final dashed = flat
        .line(const [(lon: -90.0, lat: 0.0), (lon: -70.0, lat: 0.0), (lon: -20.0, lat: 0.0)], dashed: true)
        .computeMetrics()
        .where((piece) => piece.length > 0)
        .toList();
    expect(dashed.length, 10);
    for (final piece in dashed) {
      expect(piece.length, closeTo(3, 0.001));
    }
  });
}
