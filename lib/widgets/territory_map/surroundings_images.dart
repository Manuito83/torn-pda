import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/surroundings_quality.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_strip_painter.dart';
import 'package:torn_pda/widgets/territory_map/territory_base_painter.dart';

// Pixels per unit on screen
const _nearPhotoFrom = 0.2;
const _dropNearBelow = 0.1;
const _stripUnitsPerPixel = 4.0;
const _lightsShare = 0.5;

typedef StripTile = ({Rect area, ui.Image image, double pixelsPerUnit});

// Landscape photos and far strip tiles
class SurroundingsImages {
  SurroundingsImages(this._read, this._onChange);

  final Future<Uint8List> Function(String name) _read;
  final VoidCallback _onChange;

  ui.Image? far, mid, near, farLights, midLights;
  List<StripTile> strip = const [];

  bool? _lightTheme;
  SurroundingsQuality _quality = SurroundingsQuality.full;
  int _theme = 0;
  bool _nearLoading = false;
  bool _lightsWanted = false;
  bool _lightsAsked = false;
  StripPaints? _stripPaints;
  SurroundingsQuality? _stripQuality;
  bool _disposed = false;
  int _pending = 0;
  Completer<void>? _loaded;

  String get _photo => _lightTheme! ? 'day' : 'dark';

  // Nothing left decoding or drawing
  Future<void> get loaded => _pending == 0 ? Future.value() : (_loaded ??= Completer()).future;

  bool get photosReady => far != null && (mid != null || _quality.midShare == 0);

  // Called while building, before the painters
  void show({required bool lightTheme, required double pixelsPerUnit, required SurroundingsQuality quality}) {
    if (lightTheme != _lightTheme || quality != _quality) {
      _lightTheme = lightTheme;
      _quality = quality;
      final theme = ++_theme;
      for (final image in [far, mid, near]) {
        image?.dispose();
      }
      far = mid = near = null;
      _nearLoading = false;
      unawaited(_load('far-$_photo', 1, (image) => far = image, theme: theme));
      if (quality.midShare > 0) {
        unawaited(_load('mid-$_photo', quality.midShare, (image) => mid = image, theme: theme));
      }
    }
    _loadLights();
    if (quality.near && pixelsPerUnit > _nearPhotoFrom && near == null && !_nearLoading) {
      _nearLoading = true;
      unawaited(
        _load('near-$_photo', 1, (image) {
          near = image;
          _nearLoading = false;
        }, theme: _theme),
      );
    } else if (pixelsPerUnit < _dropNearBelow && near != null) {
      near!.dispose();
      near = null;
    }
  }

  void wantLights() {
    _lightsWanted = true;
    _loadLights();
  }

  // Waits for the quality
  void _loadLights() {
    if (!_lightsWanted || _lightsAsked || _lightTheme == null) return;
    _lightsAsked = true;
    unawaited(_load('far-lights', _lightsShare, (image) => farLights = image));
    if (_quality.midShare > 0) {
      unawaited(_load('mid-lights', _lightsShare * _quality.midShare, (image) => midLights = image));
    }
  }

  Future<void> _load(String name, double share, void Function(ui.Image image) keep, {int? theme}) async {
    _pending++;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(await _read(name));
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      buffer.dispose();
      final codec = await descriptor.instantiateCodec(
        targetWidth: share >= 1 ? null : max(1, (descriptor.width * share).round()),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      descriptor.dispose();
      if (_disposed || (theme != null && theme != _theme)) {
        frame.image.dispose();
        return;
      }
      keep(frame.image);
      _onChange();
    } catch (e) {
      debugPrint('territory map: photo $name unreadable: $e');
    } finally {
      _done();
    }
  }

  void _done() {
    if (--_pending > 0) return;
    _loaded?.complete();
    _loaded = null;
  }

  // Four bands round the city, per theme
  void drawStrip(StripPaints paints, SurroundingsQuality quality) {
    if (identical(paints, _stripPaints) && quality == _stripQuality) return;
    _stripPaints = paints;
    _stripQuality = quality;
    final b = paints.surroundings.bounds, n = paints.surroundings.near;
    const edge = surroundingsEdge + 1;
    final pixelsPerUnit = quality.stripShare / _stripUnitsPerPixel;
    final areas = [
      Rect.fromLTRB(n.left, n.top, n.right, b.top + edge),
      Rect.fromLTRB(n.left, b.bottom - edge, n.right, n.bottom),
      Rect.fromLTRB(n.left, b.top, b.left + edge, b.bottom),
      Rect.fromLTRB(b.right - edge, b.top, n.right, b.bottom),
    ];
    _pending++;
    unawaited(
      Future.wait([for (final area in areas) _drawTile(paints, area, pixelsPerUnit)])
          .then((tiles) {
            if (_disposed || !identical(paints, _stripPaints) || quality != _stripQuality) {
              for (final tile in tiles) {
                tile.image.dispose();
              }
              return;
            }
            final old = strip;
            strip = tiles;
            _onChange();
            // Painted until the next frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (final tile in old) {
                tile.image.dispose();
              }
            });
          })
          .whenComplete(_done),
    );
  }

  Future<StripTile> _drawTile(StripPaints paints, Rect area, double pixelsPerUnit) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(pixelsPerUnit)
      ..translate(-area.left, -area.top);
    paintSurroundingsStrip(canvas, paints, area, farGroundScale);
    final picture = recorder.endRecording();
    final image = await picture.toImage((area.width * pixelsPerUnit).ceil(), (area.height * pixelsPerUnit).ceil());
    picture.dispose();
    return (area: area, image: image, pixelsPerUnit: pixelsPerUnit);
  }

  void dispose() {
    _disposed = true;
    for (final image in [far, mid, near, farLights, midLights]) {
      image?.dispose();
    }
    for (final tile in strip) {
      tile.image.dispose();
    }
    _loaded?.complete();
    _loaded = null;
  }
}
