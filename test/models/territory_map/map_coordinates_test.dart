import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_coordinates.dart';

void main() {
  const city = Rect.fromLTRB(-1, 0, 6256, 3410);
  const phone = Size(400, 800);

  test('BAA first point', () {
    final point = latLngToMap(46.83, -78.02);
    expect(point.dx, closeTo(473.0, 0.5));
    expect(point.dy, closeTo(302.0, 0.5));
  });

  test('city fits phone width', () {
    final scale = fitScale(city, phone);
    expect(scale, closeTo(400 / 6257, 1e-9));

    final camera = cameraToFit(city, phone);
    final cityOnScreen = Rect.fromPoints(
      city.topLeft * camera.scale + camera.translation,
      city.bottomRight * camera.scale + camera.translation,
    );
    expect(cityOnScreen.left, closeTo(0, 1e-6));
    expect(cityOnScreen.right, closeTo(400, 1e-6));
    expect(cityOnScreen.center.dy, closeTo(400, 1e-6));
  });

  test('max scale', () {
    final camera = cameraToFit(const Rect.fromLTWH(470, 290, 10, 10), phone, maxScale: 6);
    expect(camera.scale, 6);
    expect(const Offset(475, 295) * 6 + camera.translation, const Offset(200, 400));
  });

  test('past the city, more room across than down', () {
    final fit = cameraToFit(city, phone);
    expect(clampTranslation(fit.translation, fit.scale, city, phone), fit.translation);

    final left = clampTranslation(const Offset(-5000, 300), fit.scale, city, phone);
    expect(city.left * fit.scale + left.dx, closeTo(-0.42 * 400, 1e-6));

    final street = clampTranslation(const Offset(100000, -100000), 4, city, phone);
    expect(city.left * 4 + street.dx, closeTo(0.42 * 400, 1e-6));
    expect(city.bottom * 4 + street.dy, closeTo(800 - 0.30 * 800, 1e-6));
  });

  test('the view stops at the horizon', () {
    final fit = cameraToFit(city, phone);
    const reach = Rect.fromLTRB(-3900, -7850, 10160, 11260);
    final up = clampTranslation(const Offset(0, -9000), fit.scale, city, phone, reach: reach);
    expect((800 - up.dy) / fit.scale, closeTo(reach.bottom, 1e-6));

    // Reach shorter than the screen: centered
    final tight = clampTranslation(const Offset(0, -9000), fit.scale, city, phone, reach: city.inflate(100));
    expect(city.center.dy * fit.scale + tight.dy, closeTo(400, 1e-6));
  });

  test('a city smaller than the screen stays on it', () {
    final fit = cameraToFit(city, phone);
    final up = clampTranslation(const Offset(0, -9000), fit.scale, city, phone);
    expect(city.top * fit.scale + up.dy, closeTo(0, 1e-6));
    final down = clampTranslation(const Offset(0, 9000), fit.scale, city, phone);
    expect(city.bottom * fit.scale + down.dy, closeTo(800, 1e-6));
  });
}
