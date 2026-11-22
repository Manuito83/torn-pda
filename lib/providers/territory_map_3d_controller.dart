import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/city_heights.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/city_scene.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';

// Full detail once still this long
const _stillAfter = 0.11;
const _doubleTapZoom = 2.4;

typedef _HeightRun = ({double start, double duration, double spread, double each, bool back});
typedef _CameraRun = ({CityCamera from, CityCamera to, double start, double duration});

double _easeInOut(double u) => u < 0.5 ? 2 * u * u : 1 - math.pow(-2 * u + 2, 2) / 2;

double _easeOutBack(double u) {
  const c = 1.2;
  final v = u - 1;
  return 1 + (c + 1) * v * v * v + c * v * v;
}

class TerritoryMap3dController extends ChangeNotifier {
  TerritoryMap3dController(this._map);

  final TerritoryMapController _map;
  final _clock = Stopwatch()..start();

  CityMesh? mesh;
  Size size = Size.zero;
  CityCamera camera = (yaw: 0, pitch: 0, zoom: 0.1, x: 0, y: 0);
  Float32List heights = Float32List(0);
  Float32List _from = Float32List(0);
  Float32List _to = Float32List(0);
  _HeightRun? _heightRun;
  _CameraRun? _cameraRun;
  double _flingYaw = 0, _flingPitch = 0;
  double _lastStep = 0;
  double _lastInput = 0;
  bool moving = false;

  // Slow frames drop far walls while moving
  bool low = false;
  int _slow = 0, _fast = 0;
  bool _movedLately = false;
  int _dataSeen = -1;
  CityHeight? _heightSeen;
  bool _loading = false;
  bool failed = false;
  bool _disposed = false;

  // Buffers for painting and taps
  CityOrder? order;
  CityFrame? fullFrame;
  CityFrame? movingFrame;

  double get _now => _clock.elapsedMicroseconds / 1e6;

  CityProjection get projection => CityProjection(camera, size);

  bool get active => _heightRun != null || _cameraRun != null || _flingYaw != 0 || _flingPitch != 0 || moving;

  // After the 2D map saves its camera
  Future<void> load() async {
    final file = _map.territories;
    if (_loading || failed || mesh != null || file == null) return;
    _loading = true;
    final CityMesh loaded;
    try {
      loaded = await _map.cityMesh(file);
      await SchedulerBinding.instance.endOfFrame;
    } catch (_) {
      _loading = false;
      if (_disposed) return;
      failed = true;
      notifyListeners();
      return;
    }
    if (_disposed) return;
    mesh = loaded;
    order = CityOrder(loaded.length);
    fullFrame = CityFrame(loaded.full);
    movingFrame = CityFrame(loaded.moving);
    heights = Float32List(loaded.length);
    _from = Float32List(loaded.length);
    _to = _targetHeights();
    _rise();
    notifyListeners();
  }

  void retry() {
    failed = false;
    notifyListeners();
    unawaited(load());
  }

  void _rise() {
    final m = mesh!;
    final fit = fitCityZoom(m.bounds, size);
    final saved = _map.savedCamera.split(',').map(double.tryParse).toList();
    var start = (yaw: 0.0, pitch: 0.0, zoom: fit, x: m.bounds.center.dx, y: m.bounds.center.dy);
    if (saved.length == 3 && !saved.contains(null)) {
      start = (yaw: 0.0, pitch: 0.0, zoom: saved[2]!, x: saved[0]!, y: saved[1]!);
    }
    start = clampCamera(start, m.bounds, size);
    final centers = [for (var t = 0; t < m.length; t++) Offset(m.centerX[t], m.centerY[t])];
    final to = start.zoom < fit * 1.3
        ? homeCityCamera(m.bounds, size, centers)
        : (yaw: -0.5, pitch: 0.85, zoom: start.zoom, x: start.x, y: start.y);
    camera = start;
    final now = _now;
    _cameraRun = (from: start, to: to, start: now, duration: 1.1);
    _heightRun = (start: now, duration: 1.4, spread: 0.45, each: 0.55, back: true);
    _lastInput = now;
    moving = true;
  }

  Float32List _targetHeights() {
    _dataSeen = _map.dataVersion;
    _heightSeen = _map.cityHeight;
    return cityHeights(
      _map.cityHeight,
      mesh!,
      _map.territories?.territories ?? const {},
      _map.displayOwnership,
      _map.pastDay ?? DateTime.now(),
    );
  }

  // Frames with room for the outline
  void fitOutline(({Uint8List full, Uint8List moving})? lines) {
    fullFrame = CityFrame(mesh!.full, outline: lines?.full);
    movingFrame = CityFrame(mesh!.moving, outline: lines?.moving);
  }

  // True when heights start moving
  bool syncHeights() {
    if (mesh == null || (_dataSeen == _map.dataVersion && _heightSeen == _map.cityHeight)) return false;
    final target = _targetHeights();
    if (listEquals(target, _to)) return false;
    _from.setAll(0, heights);
    _to = target;
    _heightRun = (start: _now, duration: 0.75, spread: 0.3, each: 0.7, back: false);
    return true;
  }

  bool step() {
    final m = mesh;
    if (m == null) return false;
    final now = _now;
    final dt = math.min(now - _lastStep, 0.05);
    _lastStep = now;
    var changed = false;

    if (_heightRun case final run?) {
      final u = (now - run.start) / run.duration;
      for (var t = 0; t < m.length; t++) {
        final local = ((u - m.rise[t] * run.spread) / run.each).clamp(0.0, 1.0);
        final e = run.back ? _easeOutBack(local) : _easeInOut(local);
        heights[t] = _from[t] + (_to[t] - _from[t]) * e;
      }
      if (u >= run.spread + run.each) {
        heights.setAll(0, _to);
        _heightRun = null;
      }
      changed = true;
    }
    if (_cameraRun case final run?) {
      final u = ((now - run.start) / run.duration).clamp(0.0, 1.0);
      camera = lerpCamera(run.from, run.to, _easeInOut(u));
      if (u >= 1) _cameraRun = null;
      changed = true;
    }
    if (_flingYaw != 0 || _flingPitch != 0) {
      camera = clampCamera(
        (
          yaw: camera.yaw + _flingYaw * dt,
          pitch: camera.pitch + _flingPitch * dt,
          zoom: camera.zoom,
          x: camera.x,
          y: camera.y,
        ),
        m.bounds,
        size,
      );
      _flingYaw *= math.pow(0.93, dt * 60);
      _flingPitch *= math.pow(0.9, dt * 60);
      if (_flingYaw.abs() + _flingPitch.abs() < 0.024) _flingYaw = _flingPitch = 0;
      changed = true;
    }

    if (changed) _lastInput = now;
    final wasMoving = moving;
    moving = now - _lastInput < _stillAfter;
    if (moving) _movedLately = true;
    if (wasMoving && !moving) _map.savedCamera = '${camera.x},${camera.y},${camera.zoom}';
    if (changed || wasMoving != moving) notifyListeners();
    return active;
  }

  // Release builds send these once a second
  void timed(List<FrameTiming> timings) {
    if (!_movedLately) return;
    _movedLately = moving;
    for (final timing in timings) {
      final ms = math.max(timing.buildDuration.inMicroseconds, timing.rasterDuration.inMicroseconds) / 1000;
      _slow = ms > 24 ? _slow + 1 : 0;
      _fast = ms < 14 ? _fast + 1 : 0;
      if (_slow > 10) {
        low = true;
        _slow = 0;
      } else if (_fast > 90) {
        low = false;
        _fast = 0;
      }
    }
  }

  void _moved(CityCamera to) {
    final m = mesh;
    if (m == null) return;
    camera = clampCamera(to, m.bounds, size);
    _lastInput = _now;
    moving = true;
    notifyListeners();
  }

  // A finger down stops camera motion
  void hold() {
    _cameraRun = null;
    _flingYaw = _flingPitch = 0;
  }

  void orbit(Offset delta) => _moved((
    yaw: camera.yaw + delta.dx * 0.0075,
    pitch: camera.pitch - delta.dy * 0.0045,
    zoom: camera.zoom,
    x: camera.x,
    y: camera.y,
  ));

  void pinch(Offset from, Offset to, double scale, double rotation) {
    final m = mesh;
    if (m == null) return;
    _moved(pinchCamera(camera, size, from, to, scale, rotation, m.bounds));
  }

  // Pixels per second from the last drag
  void fling(Offset velocity) {
    _flingYaw = velocity.dx * 0.0075 * 0.35;
    _flingPitch = -velocity.dy * 0.0045 * 0.25;
    if (_flingYaw.abs() + _flingPitch.abs() < 0.12) _flingYaw = _flingPitch = 0;
  }

  void _animateTo(CityCamera to, double seconds) {
    final m = mesh;
    if (m == null) return;
    _cameraRun = (from: camera, to: clampCamera(to, m.bounds, size), start: _now, duration: seconds);
  }

  void zoomAt(Offset point) {
    if (mesh == null) return;
    final target = projection.groundAt(point);
    _animateTo((
      yaw: camera.yaw,
      pitch: camera.pitch,
      zoom: camera.zoom * _doubleTapZoom,
      x: target.dx,
      y: target.dy,
    ), 0.42);
  }

  // Room for chips and an open sheet
  void focusOn(Rect area, {required bool sheetOpen}) {
    final m = mesh;
    if (m == null) return;
    final room = Rect.fromLTRB(24, 72, size.width - 24, size.height * (sheetOpen ? 0.55 : 1) - 24);
    final zoom = math.min(3.0, math.min(room.width / area.width, room.height / area.height) * 0.7);
    final turn = _cameraRun?.to ?? camera;
    var to = (yaw: turn.yaw, pitch: turn.pitch, zoom: zoom, x: area.center.dx, y: area.center.dy);
    final p = CityProjection(to, size);
    final shift = p.groundAt(room.center) - p.groundAt(size.center(Offset.zero));
    to = (yaw: to.yaw, pitch: to.pitch, zoom: to.zoom, x: to.x - shift.dx, y: to.y - shift.dy);
    _animateTo(to, 0.9);
  }

  String? territoryAt(Offset point) {
    final m = mesh;
    final order = this.order, frame = fullFrame;
    if (m == null || order == null || frame == null) return null;
    final t = cityTerritoryAt(m, projection, heights, point, order: order, frame: frame);
    return t < 0 ? null : m.codes[t];
  }

  @override
  void dispose() {
    _disposed = true;
    if (mesh != null) _map.saveCamera('${camera.x},${camera.y},${camera.zoom}');
    super.dispose();
  }
}
