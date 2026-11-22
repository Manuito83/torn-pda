import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

const moveToVerb = 0;
const lineToVerb = 1;
const cubicToVerb = 2;
const closeVerb = 3;

// Max gap to the city edge
const _onCityEdge = 0.8;

class Territory {
  Territory({
    required this.code,
    required this.sector,
    required this.size,
    required this.density,
    required this.slots,
    required this.respect,
    required this.label,
    required this.neighbors,
    required this.verbs,
    required this.points,
    required this.bounds,
  });

  final String code;
  final int sector;
  final int size;
  final int density;
  final int slots;
  final int respect;
  final Offset label;
  final List<String> neighbors;
  final Uint8List verbs;
  final Float32List points;

  // Includes curve control points
  final Rect bounds;
}

class TerritoryFile {
  TerritoryFile({required this.version, required this.bounds, required this.territories});

  final int version;
  final Rect bounds;
  final Map<String, Territory> territories;
}

TerritoryFile parseTerritoryFile(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  if (data['format'] != 1) {
    throw FormatException('Unknown territory file format: ${data['format']}');
  }

  final territories = <String, Territory>{};
  (data['territories'] as Map<String, dynamic>).forEach((code, value) {
    final row = value as Map<String, dynamic>;
    final path = row['path'] as List<dynamic>;

    var verbCount = 0;
    for (final token in path) {
      if (token is String) verbCount++;
    }
    if (verbCount == 0 || verbCount == path.length) {
      throw FormatException('Territory $code has no path');
    }
    final verbs = Uint8List(verbCount);
    final points = Float32List(path.length - verbCount);

    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    var v = 0, p = 0;
    for (final token in path) {
      if (token is String) {
        verbs[v++] = switch (token) {
          'M' => moveToVerb,
          'L' => lineToVerb,
          'C' => cubicToVerb,
          'Z' => closeVerb,
          _ => throw FormatException('Unknown path command $token in $code'),
        };
        continue;
      }
      final n = (token as num).toDouble();
      points[p] = n;
      if (p.isEven) {
        if (n < minX) minX = n;
        if (n > maxX) maxX = n;
      } else {
        if (n < minY) minY = n;
        if (n > maxY) maxY = n;
      }
      p++;
    }

    final label = row['label'] as List<dynamic>;
    territories[code] = Territory(
      code: code,
      sector: row['sector'] as int,
      size: row['size'] as int,
      density: row['density'] as int,
      slots: row['slots'] as int,
      respect: row['respect'] as int,
      label: Offset((label[0] as num).toDouble(), (label[1] as num).toDouble()),
      neighbors: (row['neighbors'] as List<dynamic>).cast<String>(),
      verbs: verbs,
      points: points,
      bounds: Rect.fromLTRB(minX, minY, maxX, maxY),
    );
  });

  final b = (data['bounds'] as List<dynamic>).cast<num>();
  return TerritoryFile(
    version: data['version'] as int,
    bounds: Rect.fromLTRB(b[0].toDouble(), b[1].toDouble(), b[2].toDouble(), b[3].toDouble()),
    territories: territories,
  );
}

// Points as x, y pairs
bool onCityEdge(List<double> xy, Rect city) {
  if (xy[0] == xy[xy.length - 2] && xy[1] == xy[xy.length - 1]) return false;
  bool all(int from, double edge) {
    for (var i = from; i < xy.length; i += 2) {
      if ((xy[i] - edge).abs() > _onCityEdge) return false;
    }
    return true;
  }

  return all(0, city.left) || all(0, city.right) || all(1, city.top) || all(1, city.bottom);
}

// Border minus the sides on the edge
Path? buildTerritoryOutline(Territory territory, Rect city) {
  final inner = city.deflate(_onCityEdge);
  if (inner.contains(territory.bounds.topLeft) && inner.contains(territory.bounds.bottomRight)) return null;
  final outline = Path();
  final p = territory.points;
  var cut = false, drawing = false;
  var i = 0;
  double x = 0, y = 0, startX = 0, startY = 0;
  void keep(List<double> xy, void Function() draw) {
    if (onCityEdge(xy, city)) {
      cut = true;
      drawing = false;
      return;
    }
    if (!drawing) outline.moveTo(xy[0], xy[1]);
    draw();
    drawing = true;
  }

  for (final verb in territory.verbs) {
    switch (verb) {
      case moveToVerb:
        x = startX = p[i];
        y = startY = p[i + 1];
        drawing = false;
        i += 2;
      case lineToVerb:
        final toX = p[i], toY = p[i + 1];
        keep([x, y, toX, toY], () => outline.lineTo(toX, toY));
        x = toX;
        y = toY;
        i += 2;
      case cubicToVerb:
        final curve = [x, y, for (var k = 0; k < 6; k++) p[i + k]];
        keep(curve, () => outline.cubicTo(curve[2], curve[3], curve[4], curve[5], curve[6], curve[7]));
        x = curve[6];
        y = curve[7];
        i += 6;
      case closeVerb:
        keep([x, y, startX, startY], () => outline.lineTo(startX, startY));
        x = startX;
        y = startY;
    }
  }
  return cut ? outline : null;
}

Path buildTerritoryPath(Territory territory) {
  final path = Path();
  final p = territory.points;
  var i = 0;
  for (final verb in territory.verbs) {
    switch (verb) {
      case moveToVerb:
        path.moveTo(p[i], p[i + 1]);
        i += 2;
      case lineToVerb:
        path.lineTo(p[i], p[i + 1]);
        i += 2;
      case cubicToVerb:
        path.cubicTo(p[i], p[i + 1], p[i + 2], p[i + 3], p[i + 4], p[i + 5]);
        i += 6;
      case closeVerb:
        path.close();
    }
  }
  return path;
}
