import 'dart:math';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/flight_projection.dart';
import 'package:torn_pda/models/territory_map/world_land.dart';

const globeMaxLat = 85.0;
const _maxPerDegree = 20.0;
const _dragPerPixel = 0.5;
const _destinationsFrom = 3.5;
const _starsFrom = 4.5;
const _starFocus = 6.0;
const _countriesFrom = 7.0;
const _countryZoomRoom = 0.5;

typedef FlightView = ({double lon, double lat, double zoom});

// Starts over the Americas
const FlightView globeHomeView = (lon: -60, lat: 20, zoom: 1);
final FlightView flatHomeView = (lon: flatHome.lon, lat: flatHome.lat, zoom: 1);

FlightProjection flightProjection(FlightView view, Size size, {required bool flat}) => flat
    ? FlatProjection(size, zoom: view.zoom, center: (lon: view.lon, lat: view.lat))
    : GlobeProjection(lon: view.lon, lat: view.lat, size: size, zoom: view.zoom);

double flightMaxZoom(Size size, {required bool flat}) =>
    max(1, _maxPerDegree / flightProjection(flat ? flatHomeView : globeHomeView, size, flat: flat).perDegree);

FlightView _clamped(FlightView view, Size size, {required bool flat}) {
  final zoom = view.zoom.clamp(1.0, flightMaxZoom(size, flat: flat));
  final lon = (view.lon + 540) % 360 - 180;
  if (!flat) return (lon: lon, lat: view.lat.clamp(-globeMaxLat, globeMaxLat), zoom: zoom);
  if (zoom <= 1) return flatHomeView;
  final room = max(0.0, 90 - size.height / 2 / (flatScale(size) * zoom));
  return (lon: lon, lat: view.lat.clamp(-room, room), zoom: zoom);
}

// The point under the fingers stays put
FlightView zoomFlightView(FlightView view, double zoom, Offset focal, Size size, {required bool flat}) {
  var zoomed = _clamped((lon: view.lon, lat: view.lat, zoom: zoom), size, flat: flat);
  final before = flightProjection(view, size, flat: flat).lonLatAt(focal);
  if (before == null) return zoomed;
  // The sphere needs a few steps
  for (var step = 0; step < (flat ? 1 : 3); step++) {
    final after = flightProjection(zoomed, size, flat: flat).lonLatAt(focal);
    if (after == null) break;
    zoomed = _clamped(
      (
        lon: zoomed.lon + shortestLon(after.lon, before.lon),
        lat: zoomed.lat + before.lat - after.lat,
        zoom: zoomed.zoom,
      ),
      size,
      flat: flat,
    );
  }
  return zoomed;
}

// The flat map only moves zoomed in
FlightView panFlightView(FlightView view, Offset delta, Size size, {required bool flat}) {
  if (flat && view.zoom <= 1) return view;
  final perPixel = flat ? 1 / (flatScale(size) * view.zoom) : _dragPerPixel / view.zoom;
  return _clamped(
    (lon: view.lon - delta.dx * perPixel, lat: view.lat + delta.dy * perPixel, zoom: view.zoom),
    size,
    flat: flat,
  );
}

FlightView centerFlightView(FlightView view, LonLat at, Size size, {required bool flat}) =>
    _clamped((lon: at.lon, lat: at.lat, zoom: view.zoom), size, flat: flat);

// Back out from the closest
double doubleTapZoom(double zoom, double maxZoom) => zoom >= maxZoom * 0.99 ? 1 : min(zoom * 2, maxZoom);

bool destinationNamesShow(double perDegree) => perDegree >= _destinationsFrom;

bool starsShow(double perDegree) => perDegree >= _starsFrom;

// Opens the star, never zooms out
double starZoom(FlightView view, Size size, {required bool flat}) {
  final home = flightProjection(flat ? flatHomeView : globeHomeView, size, flat: flat).perDegree;
  return max(view.zoom, min(_starFocus / home, flightMaxZoom(size, flat: flat)));
}

// Web map zoom of a 256 pixel world
bool worldNameShows(WorldName name, double perDegree) =>
    perDegree >= _countriesFrom &&
    log(360 * perDegree / 256) / ln2 >= name.minLabel + _countryZoomRoom &&
    !flightPlaces.containsKey(flightPlaceName(name.name));
