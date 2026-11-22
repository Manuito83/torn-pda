import 'dart:math';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/map_labels.dart';

const flightNameHeight = 13.0;
const flightMoreHeight = 15.0;
const _belowPlane = 11.0;
const _twoRingsFrom = 12.0;
const _firstRing = 8;
const _secondRing = 8;
const starMostNames = _firstRing + _secondRing;
const _secondRadius = 66.0;
const _farther = 28.0;

String shortPlaneName(String name) => name.length > 7 ? '${name.substring(0, 5)}…' : name;

typedef PlaneName = ({PlaneMark plane, String text, Rect box});

// Chosen one has a bubble
({List<PlaneName> shown, int hidden}) placePlaneNames(
  LabelSpace space,
  List<PlaneMark> planes,
  double Function(String text) width, {
  int? chosen,
}) {
  final shown = <PlaneName>[];
  var hidden = 0;
  for (final plane in planes) {
    final at = plane.at;
    if (plane.flight.id == chosen || !space.area.contains(at)) continue;
    var text = plane.flight.name;
    var box = Rect.fromLTWH(at.dx - width(text) / 2, at.dy + _belowPlane, width(text), flightNameHeight);
    if (!space.take(box)) {
      final short = shortPlaneName(text);
      box = Rect.fromLTWH(at.dx - width(short) / 2, at.dy + _belowPlane, width(short), flightNameHeight);
      if (short == text || !space.take(box)) {
        hidden++;
        continue;
      }
      text = short;
    }
    shown.add((plane: plane, text: text, box: box));
  }
  return (shown: shown, hidden: hidden);
}

typedef StarName = ({int index, Offset end, Rect box});
typedef StarLayout = ({List<StarName> names, Rect? more, Offset? moreEnd, int hidden});

// Text beside the end of its ray
(Offset, Rect) _rayBox(Offset pin, (double, double) ray, double width, double height) {
  final angle = ray.$1 * pi / 180;
  final across = cos(angle);
  final down = sin(angle);
  final end = pin + Offset(across, down) * ray.$2;
  final left = across > 0.25
      ? end.dx + 4
      : across < -0.25
      ? end.dx - 4 - width
      : end.dx - width / 2;
  final top = down < -0.6
      ? end.dy - 14
      : down > 0.6
      ? end.dy + 1
      : end.dy - 6.5;
  return (end, Rect.fromLTWH(left, top, width, height));
}

// Widths of the first starMostNames
StarLayout placeStar(
  LabelSpace space,
  Offset pin,
  List<double> widths, {
  int? count,
  required double perDegree,
  required double moreWidth,
}) {
  count ??= widths.length;
  final wide = perDegree >= _twoRingsFrom;
  final most = wide ? starMostNames : _firstRing;
  final first = min(count, _firstRing);
  final start = first == 1 ? -35.0 : -90 + 180 / first;
  final radius = count > 4 ? 34.0 : 30.0;
  final rays = <(double, double)>[
    for (var i = 0; i < first; i++) (start + 360 * i / first, radius),
    if (wide && count > _firstRing)
      for (var i = 0; i < _secondRing; i++) (-45.0 + 45 * i, _secondRadius),
    for (var i = 0; i < 8; i++) (-67.5 + 45 * i, radius),
    for (var i = 0; i < 8; i++) (-67.5 + 45 * i, radius + _farther),
  ];
  final used = List.filled(rays.length, false);

  Rect? more;
  Offset? moreEnd;
  void placeMore() {
    for (var i = 0; i < rays.length; i++) {
      if (used[i]) continue;
      final (end, box) = _rayBox(pin, rays[i], moreWidth, flightMoreHeight);
      if (space.take(box)) {
        used[i] = true;
        more = box;
        moreEnd = end;
        return;
      }
    }
  }

  if (count > most) placeMore();
  final names = <StarName>[];
  for (var n = 0; n < (count > most ? most - 1 : count); n++) {
    for (var i = 0; i < rays.length; i++) {
      if (used[i]) continue;
      final (end, box) = _rayBox(pin, rays[i], widths[n], flightNameHeight);
      if (space.take(box)) {
        used[i] = true;
        names.add((index: n, end: end, box: box));
        break;
      }
    }
  }
  final hidden = count - names.length;
  if (hidden > 0 && more == null) placeMore();
  return (names: names, more: more, moreEnd: moreEnd, hidden: hidden);
}

// Name: the label, not the plane
typedef FlightTap = ({Rect box, int? member, String? place, bool focus, bool name});

// Smallest box under the finger wins
FlightTap? flightTapAt(List<FlightTap> taps, Offset at, {double slack = 3}) {
  FlightTap? best;
  for (final tap in taps) {
    if (!tap.box.inflate(slack).contains(at)) continue;
    if (best == null || tap.box.width * tap.box.height < best.box.width * best.box.height) best = tap;
  }
  return best;
}
