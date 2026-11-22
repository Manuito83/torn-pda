import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/territory_index.dart';
import 'package:torn_pda/widgets/territory_map/territory_base_painter.dart';

const territoryLabelFromWidth = 36.0;
const _codeFromWidth = 90.0;
const _maxLabels = 200;
const _labelWidth = 120.0;

// Bounds are wider than the shape
const _nameRoom = 0.8;

// Null when nothing fits that width
ui.Paragraph? territoryLabel(
  Map<String, ui.Paragraph> cache,
  String code,
  MapFaction? faction,
  double width, {
  required bool showNames,
}) {
  if (width < territoryLabelFromWidth) return null;
  final shownCode = width >= _codeFromWidth ? code : null;
  final name = showNames ? faction?.name : null;
  var paragraph = name == null ? null : _label(cache, [name, ?shownCode]);
  if (paragraph != null && paragraph.maxIntrinsicWidth > width * _nameRoom) paragraph = null;
  final lines = [?faction?.tag, ?shownCode];
  if (paragraph == null && lines.isEmpty) return null;
  return paragraph ?? _label(cache, lines);
}

ui.Paragraph _label(Map<String, ui.Paragraph> cache, List<String> lines) =>
    cache.putIfAbsent(lines.join('\n'), () => _buildLabel(lines));

ui.Paragraph _buildLabel(List<String> lines) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 2))
    ..pushStyle(
      ui.TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(offset: Offset(1, 1))],
      ),
    )
    ..addText(lines.join('\n'));
  final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: _labelWidth));
  if (paragraph.maxIntrinsicWidth > _labelWidth) {
    paragraph.layout(ui.ParagraphConstraints(width: paragraph.maxIntrinsicWidth.ceilToDouble()));
  }
  return paragraph;
}

class TerritoryOverlayPainter extends CustomPainter {
  TerritoryOverlayPainter({
    required this.file,
    required this.paths,
    required this.outlines,
    required this.closures,
    required this.index,
    required this.state,
    required this.ownership,
    required this.wars,
    required this.dataVersion,
    required this.selected,
    required this.highlighted,
    required this.lightTheme,
    required this.visible,
    required this.scale,
    required this.labels,
    this.mine = const [],
    this.showNames = false,
    this.names = const {},
    this.shades,
  });

  final TerritoryFile file;
  final Map<String, Path> paths;
  final Map<String, Path> outlines;
  final Map<String, ClosurePath> closures;
  final TerritoryIndex index;
  final MapState? state;
  final Map<String, Ownership> ownership;
  final List<TerritoryWar> wars;
  final int dataVersion;
  final String? selected;
  final List<String>? highlighted;
  final bool lightTheme;
  final Rect visible;
  final double scale;

  // Cache owned by the view
  final Map<String, ui.Paragraph> labels;

  // Own faction territories
  final List<String> mine;
  final bool showNames;

  // Factions gone from the state
  final Map<int, MapFaction> names;

  // Grey territories go unlabeled
  final Map<String, Shade>? shades;

  // The whole sector, with its closure outside
  void _mark(Canvas canvas, String? code, Paint fill, Paint stroke) {
    final path = paths[code];
    if (path == null) return;
    canvas.drawPath(path, fill);
    final closure = closures[code];
    if (closure == null) return canvas.drawPath(path, stroke);
    canvas
      ..drawPath(closure.area, fill)
      ..drawPath(outlines[code] ?? path, stroke)
      ..drawPath(closure.edge, stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mineBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (scale > nearScale ? 2 : 1) / scale
      ..color = lightTheme ? Colors.black : Colors.white;
    for (final code in borderedMine(mine, wars, shades)) {
      final path = outlines[code] ?? paths[code];
      final bounds = file.territories[code]?.bounds;
      if (path == null || bounds == null || !visible.overlaps(bounds)) continue;
      canvas.drawPath(path, mineBorder);
    }

    final veil = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5 / scale
      ..color = lightTheme ? Colors.black : Colors.white;
    for (final code in highlighted ?? const <String>[]) {
      _mark(canvas, code, veil, outline);
    }

    _mark(
      canvas,
      selected,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3 / scale
        ..color = lightTheme ? Colors.black : Colors.white,
    );

    final current = state;
    if (current == null) return;
    _paintLabels(canvas, current);

    final marker = Paint()..color = Colors.red;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / scale
      ..color = Colors.white;
    for (final war in wars) {
      final center = file.territories[war.territory]?.label;
      if (center == null || !visible.contains(center)) continue;
      canvas.drawCircle(center, 5 / scale, marker);
      canvas.drawCircle(center, 5 / scale, ring);
    }
  }

  void _paintLabels(Canvas canvas, MapState current) {
    var drawn = 0;
    for (final t in index.visibleIn(visible)) {
      final width = t.bounds.width * scale;
      if (width < territoryLabelFromWidth || !visible.contains(t.label)) continue;
      if (shades != null && !shades!.containsKey(t.code)) continue;
      final id = ownership[t.code]?.factionId ?? 0;
      final paragraph = territoryLabel(labels, t.code, current.factions[id] ?? names[id], width, showNames: showNames);
      if (paragraph == null) continue;

      canvas.save();
      canvas.translate(t.label.dx, t.label.dy);
      canvas.scale(1 / scale);
      canvas.drawParagraph(paragraph, Offset(-paragraph.width / 2, -paragraph.height / 2));
      canvas.restore();
      if (++drawn >= _maxLabels) return;
    }
  }

  @override
  bool shouldRepaint(TerritoryOverlayPainter old) =>
      old.showNames != showNames ||
      old.mine != mine ||
      old.dataVersion != dataVersion ||
      old.state != state ||
      old.selected != selected ||
      old.highlighted != highlighted ||
      old.closures != closures ||
      old.lightTheme != lightTheme ||
      old.visible != visible ||
      old.scale != scale;
}
