import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_images.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_strip_painter.dart';

Color surroundingsAir({required bool lightTheme}) => lightTheme ? const Color(0xFFE5EBF0) : const Color(0xFF1F2634);

// Like the city: tiles, snapshot or vectors
enum StripMode { none, tiles, vectors }

// Photos, the strip and the city background
class SurroundingsLayer extends StatelessWidget {
  const SurroundingsLayer({
    super.key,
    required this.images,
    required this.surroundings,
    required this.bounds,
    required this.background,
    required this.strip,
    required this.mode,
    required this.visible,
    required this.scale,
    required this.snapshotRect,
  });

  final SurroundingsImages images;

  // Null until it loads
  final Surroundings? surroundings;
  final Rect bounds;
  final Paint background;

  // Null without the city ground
  final StripPaints? strip;
  final StripMode mode;
  final Rect visible;
  final double scale;

  // Tiles stay out of it
  final Rect? snapshotRect;

  @override
  Widget build(BuildContext context) {
    final strip = this.strip;
    final around = surroundings;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _PhotosPainter(
            photos: [
              if (around != null && images.far != null) (images.far!, around.far),
              if (around != null && images.mid != null) (images.mid!, around.mid),
              if (around != null && images.near != null) (images.near!, around.near),
            ],
            city: bounds.deflate(surroundingsEdge),
            background: background,
          ),
          foregroundPainter: strip == null || mode == StripMode.none
              ? null
              : _StripPainter(
                  paints: strip,
                  tiles: mode == StripMode.tiles ? images.strip : null,
                  snapshotRect: snapshotRect,
                  visible: visible,
                  scale: scale,
                ),
        ),
      ),
    );
  }
}

class _PhotosPainter extends CustomPainter {
  _PhotosPainter({required this.photos, required this.city, required this.background});

  final List<(ui.Image, Rect)> photos;
  final Rect city;
  final Paint background;
  final _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (image, area) in photos) {
      canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), area, _paint);
    }
    canvas.drawRect(city, background);
  }

  @override
  bool shouldRepaint(_PhotosPainter old) {
    if (old.city != city || old.background != background || old.photos.length != photos.length) return true;
    for (var i = 0; i < photos.length; i++) {
      if (old.photos[i].$1 != photos[i].$1) return true;
    }
    return false;
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.paints,
    required this.tiles,
    required this.snapshotRect,
    required this.visible,
    required this.scale,
  });

  final StripPaints paints;

  // Null draws vectors
  final List<StripTile>? tiles;
  final Rect? snapshotRect;
  final Rect visible;
  final double scale;
  final _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final tiles = this.tiles;
    if (tiles == null) return paintSurroundingsStrip(canvas, paints, visible, scale);
    canvas.save();
    if (snapshotRect case final rect?) canvas.clipRect(rect, clipOp: ui.ClipOp.difference);
    for (final (:area, :image, :pixelsPerUnit) in tiles) {
      final source = Rect.fromLTWH(0, 0, area.width * pixelsPerUnit, area.height * pixelsPerUnit);
      canvas.drawImageRect(image, source, area, _paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.paints != paints ||
      old.tiles != tiles ||
      old.snapshotRect != snapshotRect ||
      (tiles == null && (old.visible != visible || old.scale != scale));
}
