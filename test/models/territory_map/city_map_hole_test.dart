import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_map_hole.dart';

void main() {
  const web = Rect.fromLTWH(0, 100, 400, 700);

  String hole(double y) => jsonEncode({'x': 10, 'y': y, 'w': 380, 'h': 300, 'vw': 800});

  test('page pixels to screen, with the page zoomed out', () {
    final rect = cityHoleOnScreen(hole(200), web)!;
    expect(rect.left, 5);
    expect(rect.top, 200);
    expect(rect.width, 190);
    expect(rect.height, 150);
  });

  test('scrolled away falls back', () {
    expect(cityHoleOnScreen(hole(-400), web), isNull);
    expect(cityHoleOnScreen(hole(1500), web), isNull);
    expect(cityHoleOnScreen(hole(-100), web), isNotNull);
    expect(cityHoleOnScreen(null, web), isNull);
    expect(cityHoleOnScreen('null', web), isNull);
  });

  test('the frame fills the rect like a covering image', () {
    const frame = Size(400, 800);
    final tall = cityFrameCover(const Rect.fromLTWH(0, 0, 100, 400), frame);
    expect(tall.scale, 0.5);
    expect(tall.offset, const Offset(-50, 0));
    final wide = cityFrameCover(const Rect.fromLTWH(0, 0, 200, 100), frame);
    expect(wide.scale, 0.5);
    expect(wide.offset, const Offset(0, -150));
  });

  test('second back within two seconds', () {
    final now = DateTime(2026, 11, 8, 12);
    expect(cityBackCloses(null, now), isFalse);
    expect(cityBackCloses(now.subtract(const Duration(seconds: 1)), now), isTrue);
    expect(cityBackCloses(now.subtract(const Duration(seconds: 3)), now), isFalse);
  });

  test('territory links', () {
    expect(cityLinkTerritory('https://www.torn.com/city.php#terrName=QFA'), 'QFA');
    expect(cityLinkTerritory('https://www.torn.com/factions.php?step=profile&ID=7'), isNull);
    expect(cityLinkTerritory('https://www.torn.com/city.php'), isNull);
  });
}
