import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/city_ground_painter.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_strip_painter.dart';
import 'package:torn_pda/widgets/territory_map/territory_base_painter.dart';

// Moving below this scale draws a snapshot
const _snapshotBelowScale = 2.0;
const _settleAfter = Duration(milliseconds: 200);

// Far image and moving snapshot
class TerritoryMapRaster {
  TerritoryMapRaster(this._controller, this._transform, this._onChange);

  final TerritoryMapController _controller;
  final TransformationController _transform;
  final VoidCallback _onChange;
  bool _disposed = false;

  Size? size;
  TerritoryPaints? paints;
  double pixelRatio = 1;

  ui.Image? farImage;
  int _farImageVersion = -1;
  TerritoryPaints? _farImagePaints;
  int _farImageWidth = 0;
  bool _rendering = false;

  // Kept after moving, reused while still valid
  ui.Image? _snapshot;
  Rect snapshotRect = Rect.zero;
  double _snapshotScale = 0;
  int _snapshotVersion = -1;
  MapState? _snapshotState;
  TerritoryPaints? _snapshotPaints;
  bool _moving = false;
  Timer? _settle;

  bool _still = false;
  bool _holdStill = false;

  set holdStill(bool value) {
    _holdStill = value;
    if (!value) _still = false;
  }

  ui.Image? get snapshot => _moving || _still ? _snapshot : null;

  // Covers the whole view
  bool get still => _still && _snapshot != null;

  void dispose() {
    _disposed = true;
    farImage?.dispose();
    _settle?.cancel();
    _snapshot?.dispose();
  }

  void onMove() {
    _snapshotWhileMoving();
    final outdated =
        _farImageVersion != _controller.dataVersion || _farImagePaints != paints || farImage?.width != _farImageWidth;
    if (outdated && _farImageWidth != 0 && _farImageNeeded) drawFarImage(_farImageWidth);
  }

  void _snapshotWhileMoving() {
    final size = this.size;
    final farImage = this.farImage;
    final paints = this.paints;
    final index = _controller.index;
    if (size == null || farImage == null || paints == null || index == null) return;

    _settle?.cancel();
    _settle = Timer(_settleAfter, () {
      if (_disposed || (!_moving && !_holdStill)) return;
      _moving = false;
      _still = false;
      dropSnapshot();
      keepStill();
      _onChange();
    });
    _still = false;

    final scale = _transform.value.getMaxScaleOnAxis();
    final farImageCovers = scale * pixelRatio <= farImage.width / _controller.territories!.bounds.width;
    if (_moving || farImageCovers || scale >= _snapshotBelowScale) return;

    final visible = visibleScene!;
    final reusable =
        _snapshot != null &&
        !_snapshotOutdated &&
        scale < _snapshotScale * 2 &&
        scale > _snapshotScale / 2 &&
        snapshotRect.contains(visible.center);
    _moving = true;
    if (!reusable) _drawSnapshot(visible, scale);
  }

  // The exact view, under the city life
  void keepStill() {
    final farImage = this.farImage;
    if (!_holdStill || _moving || farImage == null || size == null || paints == null || _controller.index == null) {
      return;
    }
    final visible = visibleScene!;
    if (_still && !_snapshotOutdated && snapshotRect == visible) return;
    final scale = _transform.value.getMaxScaleOnAxis();
    if (scale * pixelRatio <= farImage.width / _controller.territories!.bounds.width) return;
    _drawSnapshot(visible, scale);
    _still = true;
  }

  void _drawSnapshot(Rect visible, double scale) {
    final size = this.size!;
    final paints = this.paints!;
    final recorder = ui.PictureRecorder();
    final bounds = _controller.territories!.bounds;
    // Clear past the strip for the photos
    final canvas = Canvas(recorder)
      ..scale(scale * pixelRatio)
      ..translate(-visible.left, -visible.top);
    if (paints.strip case final strip?) paintSurroundingsStrip(canvas, strip, visible, scale);
    canvas.drawRect(bounds.deflate(surroundingsEdge), paints.backgroundFill);
    if (paints.ground case final ground?) {
      canvas
        ..save()
        ..clipRect(bounds);
      paintCityGround(canvas, ground, visible, scale);
      canvas.restore();
    }
    paintTerritories(
      canvas,
      _controller.index!.visibleIn(visible),
      paths: _controller.paths,
      outlines: _controller.outlines,
      ownership: _controller.displayOwnership,
      colors: _controller.colors,
      paints: paints,
      pixelsPerUnit: scale,
      borders: scale > nearScale,
      wars: _controller.shownWars,
      shades: _controller.shades,
    );
    final picture = recorder.endRecording();
    _snapshot?.dispose();
    _snapshot = picture.toImageSync((size.width * pixelRatio).ceil(), (size.height * pixelRatio).ceil());
    picture.dispose();
    snapshotRect = visible;
    _snapshotScale = scale;
    _snapshotVersion = _controller.dataVersion;
    _snapshotState = _controller.state;
    _snapshotPaints = paints;
  }

  bool get _snapshotOutdated =>
      _snapshotVersion != _controller.dataVersion || _snapshotState != _controller.state || _snapshotPaints != paints;

  // Null before the first layout
  Rect? get visibleScene {
    final size = this.size;
    if (size == null) return null;
    return Rect.fromPoints(_transform.toScene(Offset.zero), _transform.toScene(size.bottomRight(Offset.zero)));
  }

  void dropSnapshot() {
    if (_snapshot == null || _moving || _still) return;
    if (!_snapshotOutdated && _transform.value.getMaxScaleOnAxis() < _snapshotBelowScale) return;
    _snapshot!.dispose();
    _snapshot = null;
  }

  // Unused up close
  bool get _farImageNeeded {
    final image = farImage;
    final file = _controller.territories;
    if (image == null || file == null) return true;
    final scale = _transform.value.getMaxScaleOnAxis();
    return scale < _snapshotBelowScale || scale * pixelRatio <= image.width / file.bounds.width;
  }

  void drawFarImage(int width) {
    _farImageWidth = width;
    final paints = this.paints!;
    final version = _controller.dataVersion;
    if (_rendering ||
        !_farImageNeeded ||
        (version == _farImageVersion && paints == _farImagePaints && farImage?.width == width)) {
      return;
    }
    _rendering = true;
    renderFarImage(
      file: _controller.territories!,
      paths: _controller.paths,
      outlines: _controller.outlines,
      ownership: _controller.displayOwnership,
      colors: _controller.colors,
      paints: paints,
      width: width,
      shades: _controller.shades,
    ).then((image) {
      _rendering = false;
      if (_disposed) {
        image.dispose();
        return;
      }
      farImage?.dispose();
      farImage = image;
      _farImageVersion = version;
      _farImagePaints = paints;
      _onChange();
    });
  }
}
