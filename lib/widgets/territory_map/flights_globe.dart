import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/chat/chat_player_card.dart';
import 'package:torn_pda/models/territory_map/faction_flights.dart';
import 'package:torn_pda/models/territory_map/flight_labels.dart';
import 'package:torn_pda/models/territory_map/flight_projection.dart';
import 'package:torn_pda/models/territory_map/flight_view.dart';
import 'package:torn_pda/models/territory_map/map_labels.dart';
import 'package:torn_pda/models/territory_map/world_land.dart';
import 'package:torn_pda/providers/faction_flights_controller.dart';

const _frameEvery = Duration(milliseconds: 33);
const _spinPerFrame = 0.12;
const _focusTime = Duration(milliseconds: 500);
const _doubleTapTime = Duration(milliseconds: 300);
const _doubleTapReach = 40.0;
const _maxCountryNames = 40;

// Clear of the abroad circle
const _nameGap = 12.0;

const flightsSeaColor = Color(0xFF0D2233);
const flightsLimbColor = Color(0xFF39404B);
const _gridLine = Color(0x0DFFFFFF);
const _landFill = Color(0xFF3C5A4A);
const _landLine = Color(0xFF22352B);
const flightsFlyingColor = Color(0xFF5CC8FF);
const flightsNoTimeColor = Color(0xFFAAB2BD);
const flightsAbroadColor = Color(0xFF7DDC8A);
const flightsAbroadTextColor = Color(0xFF06210C);
const flightsStarTextColor = Color(0xFFD7F5DC);
const flightsTornColor = Color(0xFFF0A020);

const _ray = Color(0x997DDC8A);

const _tornStyle = TextStyle(color: flightsTornColor, fontSize: 11);
const _bubbleStyle = TextStyle(color: Colors.white, fontSize: 12);
const _unknownStyle = TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold);
const _countStyle = TextStyle(color: flightsAbroadTextColor, fontSize: 11, fontWeight: FontWeight.bold);
const _hiddenStyle = TextStyle(color: Color(0xFFCFD6DE), fontSize: 11);
const _nameShadows = [Shadow(blurRadius: 3), Shadow(blurRadius: 1.5)];
const _flyingName = TextStyle(
  color: flightsFlyingColor,
  fontSize: 10.5,
  fontWeight: FontWeight.w500,
  shadows: _nameShadows,
);
const _noTimeName = TextStyle(
  color: flightsNoTimeColor,
  fontSize: 10.5,
  fontWeight: FontWeight.w500,
  shadows: _nameShadows,
);
const _starName = TextStyle(
  color: flightsStarTextColor,
  fontSize: 10.5,
  fontWeight: FontWeight.w500,
  shadows: _nameShadows,
);
const _starChosen = TextStyle(
  color: flightsTornColor,
  fontSize: 10.5,
  fontWeight: FontWeight.bold,
  shadows: _nameShadows,
);
const _destinationStyle = TextStyle(color: Color(0xE6FFFFFF), fontSize: 11, shadows: [Shadow(blurRadius: 3)]);
const _countryStyle = TextStyle(color: Color(0x8CFFFFFF), fontSize: 10, letterSpacing: 0.4);

class FlightsGlobe extends StatefulWidget {
  const FlightsGlobe({
    super.key,
    required this.flights,
    required this.flat,
    required this.now,
    required this.running,
    required this.spin,
    required this.flags,
    required this.onMember,
    required this.onName,
    required this.onPlace,
  });

  final FactionFlightsController flights;
  final bool flat;
  final ValueNotifier<DateTime> now;

  // Shown and with the app in front
  final bool running;

  // False with animations disabled
  final bool spin;
  final Map<String, ui.Image> flags;
  final ValueChanged<int> onMember;
  final ValueChanged<int> onName;
  final void Function(String? place, {bool focus}) onPlace;

  @override
  State<FlightsGlobe> createState() => _FlightsGlobeState();
}

class _FlightsGlobeState extends State<FlightsGlobe> {
  final _frame = ValueNotifier(0);
  final _scene = _Scene();
  Timer? _timer;

  FlightView _globe = globeHomeView;
  FlightView _flat = flatHomeView;
  double _zoomAtStart = 1;
  bool _turning = true;

  FlightView? _goalFrom;
  FlightView? _goal;
  DateTime _goalStart = DateTime.now();

  DateTime? _lastTap;
  Offset _lastTapAt = Offset.zero;

  int _focusSeen = 0;
  int _placeFocusSeen = 0;

  FlightView get _view => widget.flat ? _flat : _globe;

  set _view(FlightView view) {
    if (widget.flat) {
      _flat = view;
    } else {
      _globe = view;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusSeen = widget.flights.focusRequest;
    _placeFocusSeen = widget.flights.placeFocus;
    _sync();
  }

  @override
  void didUpdateWidget(FlightsGlobe old) {
    super.didUpdateWidget(old);
    if (widget.flights.focusRequest != _focusSeen) {
      _focusSeen = widget.flights.focusRequest;
      _focusSelected();
    }
    if (widget.flights.placeFocus != _placeFocusSeen) {
      _placeFocusSeen = widget.flights.placeFocus;
      final point = flightPlaces[widget.flights.place];
      if (point != null) _focusOn(point, star: true);
    }
    _sync();
    _frame.value++;
  }

  void _sync() {
    final moving = widget.running && !widget.flat && ((_turning && widget.spin) || _goal != null);
    if (moving) {
      _timer ??= Timer.periodic(_frameEvery, (_) => _tick());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _tick() {
    final goal = _goal;
    final zoom = _globe.zoom;
    if (goal != null) {
      final from = _goalFrom!;
      final done = DateTime.now().difference(_goalStart).inMilliseconds / _focusTime.inMilliseconds;
      if (done >= 1) {
        _globe = goal;
        _goal = null;
        _sync();
      } else {
        _globe = (
          lon: from.lon + shortestLon(from.lon, goal.lon) * done,
          lat: from.lat + (goal.lat - from.lat) * done,
          zoom: from.zoom + (goal.zoom - from.zoom) * done,
        );
      }
    } else {
      _globe = (lon: _globe.lon - _spinPerFrame / zoom, lat: _globe.lat, zoom: zoom);
    }
    _frame.value++;
  }

  void _focusSelected() {
    final id = widget.flights.selected;
    final flights = widget.flights.flights;
    if (id == null || flights == null) return;
    final nowSeconds = widget.now.value.millisecondsSinceEpoch ~/ 1000;
    final target = flightFocus(flights, id, nowSeconds);
    if (target == null) return;
    _focusOn(target, star: flightsAt(flights, nowSeconds).abroad.any((m) => m.id == id));
  }

  // With star, close enough to open it
  void _focusOn(LonLat target, {required bool star}) {
    _turning = false;
    final size = _scene.size;
    final view = _view;
    final zoom = star && size != null ? starZoom(view, size, flat: widget.flat) : view.zoom;
    if (widget.flat) {
      if (zoom > 1 && size != null) {
        _flat = centerFlightView((lon: view.lon, lat: view.lat, zoom: zoom), target, size, flat: true);
      }
      return;
    }
    final goal = (lon: target.lon, lat: target.lat.clamp(-globeMaxLat, globeMaxLat), zoom: zoom);
    if (widget.spin && widget.running) {
      _goalFrom = _globe;
      _goal = goal;
      _goalStart = DateTime.now();
    } else {
      _globe = goal;
    }
  }

  void _onScaleStart(ScaleStartDetails _) {
    _turning = false;
    _goal = null;
    _zoomAtStart = _view.zoom;
    _sync();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final size = _scene.size;
    if (size == null) return;
    var view = panFlightView(_view, details.focalPointDelta, size, flat: widget.flat);
    if (details.pointerCount > 1) {
      view = zoomFlightView(view, _zoomAtStart * details.scale, details.localFocalPoint, size, flat: widget.flat);
    }
    _view = view;
    _frame.value++;
  }

  void _onTap(Offset at) {
    _turning = false;
    _goal = null;
    _sync();
    final now = DateTime.now();
    final last = _lastTap;
    final size = _scene.size;
    if (last != null && now.difference(last) < _doubleTapTime && (at - _lastTapAt).distance < _doubleTapReach) {
      _lastTap = null;
      if (size != null) {
        final view = _view;
        final zoom = doubleTapZoom(view.zoom, flightMaxZoom(size, flat: widget.flat));
        _view = zoomFlightView(view, zoom, at, size, flat: widget.flat);
        _frame.value++;
      }
      return;
    }
    _lastTap = now;
    _lastTapAt = at;
    final hit = flightTapAt(_scene.taps, at);
    if (hit == null) return;
    if (hit.member case final id?) {
      hit.name && widget.flights.selected == id ? widget.onName(id) : widget.onMember(id);
    } else if (hit.place case final place?) {
      widget.onPlace(hit.focus || widget.flights.place != place ? place : null, focus: hit.focus);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _frame.dispose();
    _scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _onTap(details.localPosition),
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FlightsPainter(
            scene: _scene,
            frame: Listenable.merge([_frame, widget.now]),
            flights: widget.flights.flights ?? const FactionFlights(),
            land: widget.flights.land,
            selected: widget.flights.selected,
            place: widget.flights.place,
            flags: widget.flags,
            flat: widget.flat,
            view: () => _view,
            now: () => widget.now.value.millisecondsSinceEpoch ~/ 1000,
          ),
        ),
      ),
    );
  }
}

// Left by the last paint, for taps
class _Scene {
  Path? land;
  Object? landKey;
  Size? size;
  final routes = <(String, String), List<LonLat>>{};
  final space = LabelSpace();
  final taps = <FlightTap>[];
  final _names = <(TextStyle, String), TextPainter>{};
  (String, double)? _bubbleKey;
  TextPainter? _bubble;

  TextPainter name(String text, TextStyle style) => _names.putIfAbsent(
    (style, text),
    () => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(),
  );

  // Its text changes every second
  TextPainter bubble(String text, double maxWidth) {
    if (_bubbleKey != (text, maxWidth)) {
      _bubble?.dispose();
      _bubble = TextPainter(
        text: TextSpan(text: text, style: _bubbleStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: maxWidth);
      _bubbleKey = (text, maxWidth);
    }
    return _bubble!;
  }

  void dispose() {
    for (final painter in _names.values) {
      painter.dispose();
    }
    _bubble?.dispose();
  }
}

class _FlightsPainter extends CustomPainter {
  _FlightsPainter({
    required this.scene,
    required Listenable frame,
    required this.flights,
    required this.land,
    required this.selected,
    required this.place,
    required this.flags,
    required this.flat,
    required this.view,
    required this.now,
  }) : super(repaint: frame);

  final _Scene scene;
  final FactionFlights flights;
  final WorldLand? land;
  final int? selected;
  final String? place;
  final Map<String, ui.Image> flags;
  final bool flat;
  final FlightView Function() view;
  final int Function() now;

  static final _plane = Path()
    ..moveTo(9, 0)
    ..lineTo(-3, -2)
    ..lineTo(-6, -8)
    ..lineTo(-8, -8)
    ..lineTo(-7, -2)
    ..lineTo(-9, -2)
    ..lineTo(-11, -4)
    ..lineTo(-12, -4)
    ..lineTo(-11, 0)
    ..lineTo(-12, 4)
    ..lineTo(-11, 4)
    ..lineTo(-9, 2)
    ..lineTo(-7, 2)
    ..lineTo(-8, 8)
    ..lineTo(-6, 8)
    ..lineTo(-3, 2)
    ..close();

  (TextPainter, Rect) _bubble(Size size, Offset at, String text) {
    final painter = scene.bubble(text, max(0, size.width - 20));
    final width = painter.width + 12;
    final x = (at.dx - width / 2).clamp(4.0, max(4.0, size.width - width - 4)).toDouble();
    final y = max(4.0, at.dy - 30);
    return (painter, Rect.fromLTWH(x, y, width, 20));
  }

  void _drawBubble(Canvas canvas, (TextPainter, Rect) bubble) {
    final (painter, box) = bubble;
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(6)), Paint()..color = const Color(0xCC000000));
    painter.paint(canvas, Offset(box.left + 6, box.top + (20 - painter.height) / 2));
  }

  bool _name(Canvas canvas, TextPainter text, Offset topLeft) {
    if (!scene.space.take(topLeft & text.size)) return false;
    text.paint(canvas, topLeft);
    return true;
  }

  // Text centered in its box
  void _boxed(Canvas canvas, TextPainter text, Rect box) =>
      text.paint(canvas, box.center - Offset(text.width / 2, text.height / 2));

  void _rayTo(Canvas canvas, Offset pin, Offset end) {
    final away = end - pin;
    canvas.drawLine(pin + away / away.distance * 10, end, Paint()..color = _ray);
    canvas.drawCircle(end, 2, Paint()..color = flightsAbroadColor);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    scene.size = size;
    canvas.clipRect(Offset.zero & size);
    final nowSeconds = now();
    final current = flightsAt(flights, nowSeconds);
    final shownView = view();
    final projection = flightProjection(shownView, size, flat: flat);

    final outline = projection.outline;
    canvas.drawPath(outline, Paint()..color = flightsSeaColor);
    canvas.save();
    canvas.clipPath(outline);

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _gridLine;
    for (final line in graticule) {
      canvas.drawPath(projection.line(line), gridPaint);
    }

    final world = land;
    if (world != null) {
      final key = (world, size, flat, shownView);
      if (scene.landKey != key) {
        scene.land = projection.landPath(world);
        scene.landKey = key;
      }
      // Fill on top hides flat map seams
      canvas.drawPath(
        scene.land!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _landLine,
      );
      canvas.drawPath(scene.land!, Paint()..color = _landFill);
    }

    for (final flight in current.flying) {
      final from = flightPlaces[flight.from];
      final to = flightPlaces[flight.to];
      if (from == null || to == null) continue;
      final route = scene.routes.putIfAbsent((flight.from, flight.to), () => greatCircleLine(from, to));
      final chosen = selected == flight.id;
      canvas.drawPath(
        projection.line(route, dashed: !flight.hasTime),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = chosen ? 2 : 1
          ..color = (flight.hasTime ? flightsFlyingColor : flightsNoTimeColor).withValues(alpha: chosen ? 1 : 0.53),
      );
    }
    canvas.restore();

    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = flightsLimbColor,
    );

    final space = scene.space..clear(Rect.fromLTRB(2, 2, size.width - 2, size.height - 2));
    final taps = scene.taps..clear();
    final flagPaint = Paint()..filterQuality = FilterQuality.medium;
    for (final place in flightFlagPlaces(current)) {
      final image = flags[place];
      final point = flightPlaces[place];
      final at = point == null ? null : projection.place(point);
      if (image == null || at == null) continue;
      final box = Rect.fromCenter(center: at, width: 14, height: 14);
      space.block(box);
      canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), box, flagPaint);
    }

    final marks = flightMarks(current, projection, nowSeconds);
    (TextPainter, Rect)? bubble;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.black;
    for (final mark in marks.planes) {
      space.block(Rect.fromCenter(center: mark.at, width: 24, height: 20));
      taps.add((
        box: Rect.fromCircle(center: mark.at, radius: 19),
        member: mark.flight.id,
        place: null,
        focus: false,
        name: false,
      ));
      final color = mark.flight.hasTime ? flightsFlyingColor : flightsNoTimeColor;
      canvas.save();
      canvas.translate(mark.at.dx, mark.at.dy);
      canvas.rotate(mark.heading);
      canvas.drawPath(_plane, Paint()..color = color);
      canvas.drawPath(_plane, outlinePaint);
      canvas.restore();
      if (!mark.flight.hasTime) {
        final text = scene.name('?', _unknownStyle);
        final at = mark.at + const Offset(9, -18);
        text.paint(canvas, at);
        space.block(at & text.size);
      }
      if (selected == mark.flight.id) {
        bubble = _bubble(
          size,
          mark.at,
          mark.flight.hasTime
              ? '${mark.flight.name} - in ${ChatPlayerCard.span(Duration(seconds: mark.flight.arrival! - nowSeconds))}'
              : '${mark.flight.name} - no time',
        );
      }
    }

    AbroadMark? chosenGroup;
    for (final group in marks.abroad) {
      final placeChosen = group.place == place;
      if (placeChosen || group.members.any((m) => m.id == selected)) chosenGroup = group;
      space.block(Rect.fromCircle(center: group.at, radius: 10));
      canvas.drawCircle(group.at, 9, Paint()..color = flightsAbroadColor);
      canvas.drawCircle(
        group.at,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = placeChosen ? 2.5 : 1
          ..color = placeChosen ? flightsTornColor : Colors.black,
      );
      _boxed(canvas, scene.name('${group.members.length}', _countStyle), Rect.fromCircle(center: group.at, radius: 9));
    }

    if (bubble != null) space.block(bubble.$2);

    final torn = projection.place(flightPlaces[tornPlace]!);
    if (torn != null) {
      canvas.drawCircle(torn, 4, Paint()..color = flightsTornColor);
      final text = scene.name(tornPlace, _tornStyle);
      final at = torn + const Offset(7, -8);
      text.paint(canvas, at);
      space
        ..block(Rect.fromCircle(center: torn, radius: 4))
        ..block(at & text.size);
    }

    final perDegree = projection.perDegree;
    if (destinationNamesShow(perDegree)) {
      for (final MapEntry(key: place, value: point) in flightPlaces.entries) {
        if (place == tornPlace) continue;
        final at = projection.place(point);
        if (at == null) continue;
        final text = scene.name(place, _destinationStyle);
        final top = at.dy - text.height / 2;
        if (!_name(canvas, text, Offset(at.dx + _nameGap, top))) {
          _name(canvas, text, Offset(at.dx - _nameGap - text.width, top));
        }
      }
    }

    final chosenOpen = chosenGroup != null && _star(canvas, chosenGroup, perDegree);
    for (final group in marks.abroad) {
      final open = group == chosenGroup ? chosenOpen : starsShow(perDegree) && _star(canvas, group, perDegree);
      taps.add((
        box: Rect.fromCircle(center: group.at, radius: 11),
        member: null,
        place: group.place,
        focus: !open,
        name: false,
      ));
    }

    final planeNames = placePlaneNames(
      space,
      marks.planes,
      (text) => scene.name(text, _flyingName).width + 2,
      chosen: selected,
    );
    for (final name in planeNames.shown) {
      _boxed(canvas, scene.name(name.text, name.plane.flight.hasTime ? _flyingName : _noTimeName), name.box);
      taps.add((box: name.box, member: name.plane.flight.id, place: null, focus: false, name: true));
    }

    var countries = 0;
    for (final name in world?.names ?? const <WorldName>[]) {
      if (countries >= _maxCountryNames) break;
      if (!worldNameShows(name, perDegree)) continue;
      final at = projection.place((lon: name.lon, lat: name.lat));
      if (at == null) continue;
      final text = scene.name(name.name, _countryStyle);
      if (_name(canvas, text, at - Offset(text.width / 2, text.height / 2))) countries++;
    }

    if (bubble != null) {
      _drawBubble(canvas, bubble);
    } else if (chosenGroup != null && !chosenOpen) {
      final member = chosenGroup.members.where((m) => m.id == selected).firstOrNull;
      final text = member == null
          ? '${chosenGroup.place}: ${chosenGroup.members.length} abroad'
          : '${member.name} - ${chosenGroup.place}';
      _drawBubble(canvas, _bubble(size, chosenGroup.at - const Offset(0, 4), text));
    }

    final hidden = planeNames.hidden;
    if (hidden > 0) {
      final text = scene.name('$hidden plane ${hidden == 1 ? 'name' : 'names'} hidden, zoom in', _hiddenStyle);
      final box = Rect.fromLTWH(8, size.height - 26, text.width + 14, 18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(9)),
        Paint()..color = const Color(0xBB000000),
      );
      _boxed(canvas, text, box);
    }
  }

  // False when no name fits
  bool _star(Canvas canvas, AbroadMark group, double perDegree) {
    final members = [
      for (final member in group.members)
        if (member.id == selected) member,
      for (final member in group.members)
        if (member.id != selected) member,
    ];
    final names = [
      for (final m in members.take(starMostNames)) scene.name(m.name, m.id == selected ? _starChosen : _starName),
    ];
    final star = placeStar(
      scene.space,
      group.at,
      [for (final name in names) name.width + 2],
      count: members.length,
      perDegree: perDegree,
      moreWidth: scene.name('+${members.length}', _countStyle).width + 12,
    );
    for (final name in star.names) {
      _rayTo(canvas, group.at, name.end);
      _boxed(canvas, names[name.index], name.box);
      scene.taps.add((box: name.box, member: members[name.index].id, place: null, focus: false, name: true));
    }
    final more = star.more;
    final end = star.moreEnd;
    if (more != null && end != null) {
      _rayTo(canvas, group.at, end);
      canvas.drawRRect(RRect.fromRectAndRadius(more, const Radius.circular(7.5)), Paint()..color = flightsAbroadColor);
      _boxed(canvas, scene.name('+${star.hidden}', _countStyle), more);
      scene.taps.add((box: more, member: null, place: group.place, focus: true, name: false));
    }
    return star.names.isNotEmpty;
  }

  @override
  bool shouldRepaint(_FlightsPainter old) =>
      old.flights != flights || old.land != land || old.selected != selected || old.place != place || old.flat != flat;
}
