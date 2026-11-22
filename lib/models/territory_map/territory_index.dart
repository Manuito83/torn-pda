import 'dart:math' as math;
import 'dart:ui';

import 'package:torn_pda/models/territory_map/territory_file.dart';

class TerritoryIndex {
  TerritoryIndex(Iterable<Territory> territories, this._paths, {this.cellSize = 64}) {
    Rect? covered;
    for (final t in territories) {
      covered = covered?.expandToInclude(t.bounds) ?? t.bounds;
    }
    final area = covered ?? Rect.zero;
    _origin = area.topLeft;
    _columns = math.max(1, (area.width / cellSize).ceil());
    _rows = math.max(1, (area.height / cellSize).ceil());
    _cells = List.generate(_columns * _rows, (_) => <Territory>[]);
    for (final t in territories) {
      final (left, top, right, bottom) = _cellRange(t.bounds);
      for (var row = top; row <= bottom; row++) {
        for (var column = left; column <= right; column++) {
          _cells[row * _columns + column].add(t);
        }
      }
    }
  }

  final double cellSize;
  final Map<String, Path> _paths;
  late final Offset _origin;
  late final int _columns;
  late final int _rows;
  late final List<List<Territory>> _cells;

  List<Territory> visibleIn(Rect rect) {
    final found = <Territory>{};
    final (left, top, right, bottom) = _cellRange(rect);
    for (var row = top; row <= bottom; row++) {
      for (var column = left; column <= right; column++) {
        for (final t in _cells[row * _columns + column]) {
          if (t.bounds.overlaps(rect)) found.add(t);
        }
      }
    }
    return found.toList();
  }

  Territory? territoryAt(Offset point) {
    final column = ((point.dx - _origin.dx) / cellSize).floor();
    final row = ((point.dy - _origin.dy) / cellSize).floor();
    if (column < 0 || row < 0 || column >= _columns || row >= _rows) return null;
    for (final t in _cells[row * _columns + column]) {
      if (t.bounds.contains(point) && (_paths[t.code]?.contains(point) ?? false)) return t;
    }
    return null;
  }

  (int, int, int, int) _cellRange(Rect rect) {
    int clampColumn(double x) => ((x - _origin.dx) / cellSize).floor().clamp(0, _columns - 1);
    int clampRow(double y) => ((y - _origin.dy) / cellSize).floor().clamp(0, _rows - 1);
    return (clampColumn(rect.left), clampRow(rect.top), clampColumn(rect.right), clampRow(rect.bottom));
  }
}
