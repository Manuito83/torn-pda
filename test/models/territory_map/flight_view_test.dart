import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/flight_view.dart';
import 'package:torn_pda/models/territory_map/map_labels.dart';
import 'package:torn_pda/models/territory_map/world_land.dart';

const _globeSize = Size(400, 330);
const _flatSize = Size(400, 210);

void main() {
  test('the flat map zooms around the fingers', () {
    const focal = Offset(300, 60);
    final before = flightProjection(flatHomeView, _flatSize, flat: true).lonLatAt(focal)!;
    final zoomed = zoomFlightView(flatHomeView, 3, focal, _flatSize, flat: true);
    final after = flightProjection(zoomed, _flatSize, flat: true).lonLatAt(focal)!;
    expect(zoomed.zoom, 3);
    expect(after.lon, closeTo(before.lon, 1e-6));
    expect(after.lat, closeTo(before.lat, 1e-6));
  });

  test('the globe zooms around the fingers', () {
    const focal = Offset(260, 120);
    var view = globeHomeView;
    final start = flightProjection(view, _globeSize, flat: false).lonLatAt(focal)!;
    for (var zoom = 1.1; zoom <= 3; zoom += 0.1) {
      view = zoomFlightView(view, zoom, focal, _globeSize, flat: false);
    }
    final under = flightProjection(view, _globeSize, flat: false).place(start)!;
    expect((under - focal).distance, lessThan(1));
  });

  test('zoom stays between the whole world and the closest', () {
    final most = flightMaxZoom(_globeSize, flat: false);
    expect(zoomFlightView(globeHomeView, 0.3, Offset.zero, _globeSize, flat: false).zoom, 1);
    expect(zoomFlightView(globeHomeView, 99, const Offset(200, 165), _globeSize, flat: false).zoom, most);
    expect(flightMaxZoom(_flatSize, flat: true), greaterThan(most));
  });

  test('the flat map goes back to Torn in the middle when zoomed out', () {
    final zoomed = zoomFlightView(flatHomeView, 4, const Offset(30, 30), _flatSize, flat: true);
    expect(zoomed.lon, isNot(flatHomeView.lon));
    expect(zoomFlightView(zoomed, 1, const Offset(30, 30), _flatSize, flat: true), flatHomeView);
  });

  test('the flat map only pans zoomed in, and never past the poles', () {
    expect(panFlightView(flatHomeView, const Offset(50, 50), _flatSize, flat: true), flatHomeView);
    var view = zoomFlightView(flatHomeView, 3, const Offset(200, 105), _flatSize, flat: true);
    view = panFlightView(view, const Offset(0, 5000), _flatSize, flat: true);
    final projection = flightProjection(view, _flatSize, flat: true);
    expect(projection.lonLatAt(const Offset(200, 0)), isNotNull);
    expect(projection.lonLatAt(const Offset(200, 0))!.lat, closeTo(90, 1e-6));
  });

  test('going to a country zooms in enough for its star, never out', () {
    for (final (size, flat) in [(_globeSize, false), (_flatSize, true)]) {
      final home = flat ? flatHomeView : globeHomeView;
      final zoom = starZoom(home, size, flat: flat);
      final view = (lon: home.lon, lat: home.lat, zoom: zoom);
      expect(starsShow(flightProjection(home, size, flat: flat).perDegree), isFalse);
      expect(starsShow(flightProjection(view, size, flat: flat).perDegree), isTrue);
      final most = flightMaxZoom(size, flat: flat);
      expect(starZoom((lon: home.lon, lat: home.lat, zoom: most), size, flat: flat), most);
    }
  });

  test('a double tap doubles the zoom and backs out from the closest', () {
    expect(doubleTapZoom(1, 7), 2);
    expect(doubleTapZoom(4, 7), 7);
    expect(doubleTapZoom(7, 7), 1);
  });

  group('names', () {
    final land = worldLandFromGzip(
      File('assets/territory_map/world-land-110m.json.bin').readAsBytesSync(),
      names: File('assets/territory_map/world-names.json.bin').readAsBytesSync(),
    );

    test('destinations show once zoomed in a bit', () {
      final whole = flightProjection(globeHomeView, _globeSize, flat: false).perDegree;
      expect(destinationNamesShow(whole), isFalse);
      expect(destinationNamesShow(whole * 1.5), isTrue);
    });

    test('big countries show before small ones, and destinations never twice', () {
      WorldName named(String name) => land.names.firstWhere((n) => n.name == name);
      final most =
          flightProjection(globeHomeView, _globeSize, flat: false).perDegree * flightMaxZoom(_globeSize, flat: false);
      expect(worldNameShows(named('Brazil'), most / 2), isTrue);
      expect(worldNameShows(named('Belgium'), most / 2), isFalse);
      expect(worldNameShows(named('Belgium'), most), isTrue);
      expect(worldNameShows(named('Mexico'), most), isFalse);
      expect(worldNameShows(named('United Arab Emirates'), most), isFalse);
    });

    test('a name overlapping an earlier one or a plane is left out', () {
      final space = LabelSpace()..block(const Rect.fromLTWH(0, 0, 24, 24));
      expect(space.take(const Rect.fromLTWH(10, 10, 40, 12)), isFalse);
      expect(space.take(const Rect.fromLTWH(30, 10, 40, 12)), isTrue);
      expect(space.take(const Rect.fromLTWH(60, 15, 40, 12)), isFalse);
      expect(space.take(const Rect.fromLTWH(30, 30, 40, 12)), isTrue);
    });
  });
}
