import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/faction_colors.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/territory_index.dart';
import 'package:torn_pda/widgets/territory_map/city_ground_painter.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_strip_painter.dart';

const nearScale = 0.5;

// The far image shows below about this
const farGroundScale = 0.15;

// Built once per theme and background
class TerritoryPaints {
  TerritoryPaints({required this.lightTheme, required this.background, this.ground, this.strip})
    : fills = [for (var c = 0; c < paletteSize; c++) Paint()..color = fillColor(c, lightTheme: lightTheme)],
      mine = Paint()..color = fillColor(mineColor, lightTheme: lightTheme),
      dim = Paint()..color = dimFill(lightTheme: lightTheme),
      ramp = [for (final color in valueRamp) Paint()..color = color],
      sectors = [for (final color in sectorColors) Paint()..color = color],
      glow = Paint()..color = irradiatedFill(lightTheme: lightTheme);

  final bool lightTheme;

  // Opaque, so images match the vectors
  final Color background;

  // Null until the ground loads
  final GroundPaints? ground;
  final StripPaints? strip;
  late final backgroundFill = Paint()..color = background;
  final List<Paint> fills;
  final Paint mine;
  final Paint dim;
  final List<Paint> ramp;
  final List<Paint> sectors;
  final Paint glow;
  final unowned = Paint()..color = unownedFill;
  final border = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.black.withValues(alpha: 0.5);
  final war = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.red;
  final irradiated = Paint();
  double _stripesPeriod = 0;

  Paint fillOf(int? color) => color == null
      ? unowned
      : color == mineColor
      ? mine
      : fills[color];

  // Grey unless the view lights it
  Paint shadeOf(Shade? shade, int? color) => switch (shade) {
    null => dim,
    (kind: ShadeKind.faction, step: _) => fillOf(color),
    (kind: ShadeKind.ramp, :final step) => ramp[step],
    (kind: ShadeKind.sector, :final step) => sectors[step],
    (kind: ShadeKind.irradiated, step: _) => glow,
  };

  void scaleTo(double pixelsPerUnit) {
    border.strokeWidth = 1 / pixelsPerUnit;
    war.strokeWidth = 2 / pixelsPerUnit;

    final period = 12 / pixelsPerUnit;
    if (period == _stripesPeriod) return;
    _stripesPeriod = period;
    final stripe = irradiatedFill(lightTheme: lightTheme);
    irradiated.shader?.dispose();
    irradiated.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(period, period),
      [stripe, stripe, Colors.transparent, Colors.transparent],
      [0, 0.4, 0.4, 1],
      TileMode.repeated,
    );
  }
}

// Far image, snapshot and close-up vectors
void paintTerritories(
  Canvas canvas,
  Iterable<Territory> territories, {
  required Map<String, Path> paths,
  required Map<String, Path> outlines,
  required Map<String, Ownership> ownership,
  required Map<int, int> colors,
  required TerritoryPaints paints,
  required double pixelsPerUnit,
  required bool borders,
  List<TerritoryWar> wars = const [],
  Map<String, Shade>? shades,
}) {
  paints.scaleTo(pixelsPerUnit);

  for (final t in territories) {
    final path = paths[t.code];
    if (path == null) continue;
    final owner = ownership[t.code];
    final color = colors[owner?.factionId];
    canvas.drawPath(path, shades == null ? paints.fillOf(color) : paints.shadeOf(shades[t.code], color));
    if (shades == null && (owner?.irradiated ?? false)) canvas.drawPath(path, paints.irradiated);
    if (borders) canvas.drawPath(outlines[t.code] ?? path, paints.border);
  }
  for (final war in wars) {
    final path = paths[war.territory];
    if (path != null) canvas.drawPath(path, paints.war);
  }
}

Future<ui.Image> renderFarImage({
  required TerritoryFile file,
  required Map<String, Path> paths,
  required Map<String, Path> outlines,
  required Map<String, Ownership> ownership,
  required Map<int, int> colors,
  required TerritoryPaints paints,
  required int width,
  Map<String, Shade>? shades,
  List<TerritoryWar> wars = const [],
  // Null draws the whole city
  Rect? area,
  Iterable<Territory>? territories,
}) {
  final bounds = file.bounds;
  final shown = area ?? bounds;
  final pixelsPerUnit = width / shown.width;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(pixelsPerUnit)
    ..translate(-shown.left, -shown.top)
    ..drawRect(bounds.deflate(surroundingsEdge), paints.backgroundFill);
  if (paints.ground case final ground?) {
    canvas
      ..save()
      ..clipRect(bounds);
    paintCityGround(canvas, ground, shown, farGroundScale);
    canvas.restore();
  }
  paintTerritories(
    canvas,
    territories ?? file.territories.values,
    paths: paths,
    outlines: outlines,
    ownership: ownership,
    colors: colors,
    paints: paints,
    pixelsPerUnit: pixelsPerUnit,
    borders: true,
    shades: shades,
    wars: wars,
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, (shown.height * pixelsPerUnit).ceil()).whenComplete(picture.dispose);
}

class TerritoryBasePainter extends CustomPainter {
  TerritoryBasePainter({
    required this.file,
    required this.paths,
    required this.outlines,
    required this.index,
    required this.ownership,
    required this.wars,
    required this.colors,
    required this.paints,
    required this.dataVersion,
    required this.visible,
    required this.scale,
    required this.farImage,
    required this.snapshot,
    required this.snapshotRect,
    this.shades,
  });

  final TerritoryFile file;
  final Map<String, Path> paths;
  final Map<String, Path> outlines;
  final TerritoryIndex index;
  final Map<String, Ownership> ownership;
  final List<TerritoryWar> wars;
  final Map<int, int> colors;
  final TerritoryPaints paints;
  final int dataVersion;
  final Rect visible;
  final double scale;

  // Null while it renders or up close
  final ui.Image? farImage;

  // The view while it moves
  final ui.Image? snapshot;
  final Rect snapshotRect;
  final Map<String, Shade>? shades;

  final _farImagePaint = Paint()..filterQuality = FilterQuality.medium;
  final _snapshotPaint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    void drawImage(ui.Image image, Rect rect, Paint paint) =>
        canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), rect, paint);

    final image = farImage;
    final moving = snapshot;
    if (image != null) {
      canvas.save();
      if (moving != null) canvas.clipRect(snapshotRect, clipOp: ui.ClipOp.difference);
      drawImage(image, file.bounds, _farImagePaint);
      canvas.restore();
    }
    if (moving != null) drawImage(moving, snapshotRect, _snapshotPaint);
    if (image != null || moving != null) return;

    paintTerritories(
      canvas,
      index.visibleIn(visible),
      paths: paths,
      outlines: outlines,
      ownership: ownership,
      colors: colors,
      paints: paints,
      pixelsPerUnit: scale,
      borders: scale > nearScale,
      wars: wars,
      shades: shades,
    );
  }

  @override
  bool shouldRepaint(TerritoryBasePainter old) =>
      old.dataVersion != dataVersion ||
      old.paints != paints ||
      old.farImage != farImage ||
      old.snapshot != snapshot ||
      (farImage == null &&
          snapshot == null &&
          (old.ownership != ownership || old.wars != wars || old.visible != visible || old.scale != scale));
}
