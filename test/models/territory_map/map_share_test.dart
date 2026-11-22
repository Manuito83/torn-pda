import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';

void main() {
  test('a link brings back the same view', () {
    const view = SharedMapView(
      camera: Rect.fromLTWH(4000, 3000, 1200, 2400),
      view: MapView.activity,
      span: ActivitySpan.month,
      territory: 'RCD',
      warId: 77,
      layers: {layerLocks, layerNames},
    );
    final back = readMapLink(buildMapLink(view))!;
    expect(back.camera, view.camera);
    expect(back.view, MapView.activity);
    expect(back.span, ActivitySpan.month);
    expect(back.territory, 'RCD');
    expect(back.warId, 77);
    expect(back.layers, {layerLocks, layerNames});
  });

  test('a plain view stays short', () {
    final link = buildMapLink(const SharedMapView(camera: Rect.fromLTWH(0, 0, 100, 100)));
    expect(link, 'https://tornpda.com/map/?x=50&y=50&w=100&h=100');
    final back = readMapLink(link)!;
    expect(back.view, MapView.normal);
    expect(back.territory, isNull);
    expect(back.layers, isEmpty);
  });

  test('reads the old app link and the web link without the slash', () {
    final old = readMapLink('tornpda://map/view?x=10&y=20&w=300&h=400&t=RCD')!;
    final web = readMapLink('https://www.tornpda.com/map?x=10&y=20&w=300&h=400&t=RCD')!;
    expect(web.camera, old.camera);
    expect(web.territory, 'RCD');
  });

  test('the span only travels with the activity view', () {
    final link = buildMapLink(const SharedMapView(camera: Rect.fromLTWH(0, 0, 100, 100), view: MapView.war));
    expect(link, contains('v=war'));
    expect(link, isNot(contains('span')));
  });

  test('drops what cannot be trusted but keeps the camera', () {
    final view = readMapLink('tornpda://map/view?x=10&y=20&w=300&h=400&t=rcd&war=-3&v=disco&l=locks,bomb,city')!;
    expect(view.territory, isNull);
    expect(view.warId, isNull);
    expect(view.view, MapView.normal);
    expect(view.layers, {layerLocks, layerCity});
  });

  test('a view dragged past the north edge still opens', () {
    expect(readMapLink('https://tornpda.com/map/?x=3000&y=-2213&w=6900&h=15000'), isNotNull);
    expect(readMapLink('https://tornpda.com/map/?x=3000&y=-7600&w=6900&h=3000'), isNotNull);
  });

  test('refuses links that are not a usable map view', () {
    expect(readMapLink('tornpda://map/view?x=10&y=20&w=300'), isNull);
    expect(readMapLink('tornpda://map/view?x=a&y=20&w=300&h=400'), isNull);
    expect(readMapLink('tornpda://map/view?x=1e9&y=20&w=300&h=400'), isNull);
    expect(readMapLink('tornpda://map/view?x=10&y=20&w=0&h=400'), isNull);
    expect(readMapLink('tornpda://travel/live?x=10&y=20&w=300&h=400'), isNull);
    expect(readMapLink('https://www.torn.com/city.php'), isNull);
    expect(readMapLink('https://tornpda.com/changelog/?x=10&y=20&w=300&h=400'), isNull);
    expect(readMapLink('http://tornpda.com/map/?x=10&y=20&w=300&h=400'), isNull);
    expect(readMapLink(''), isNull);
  });

  test('the picture caption is in Torn time and names the day in the past', () {
    final now = DateTime.utc(2026, 11, 8, 14, 5);
    expect(mapPictureCaption(now: now), 'Map - 8 Nov 2026 14:05 TCT');
    expect(mapPictureCaption(now: now, pastDay: DateTime.utc(2026, 11, 1)), 'Map - as of 1 Nov 2026');
  });
}
