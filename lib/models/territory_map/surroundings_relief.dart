import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/surroundings.dart';

const _cityLineStep = 150.0;
const _edgeLineStep = 120.0;
const _lineGrowth = 0.06;
const _farUnitsPerPixel = 20.0;
const _midUnitsPerPixel = 8.0;
const _fogFrom = 2200.0;
const _fogReach = 5200.0;
const _edgeFade = 900.0;

// Heights on a grid, in map units
class Relief {
  Relief({
    required this.left,
    required this.top,
    required this.cell,
    required this.columns,
    required this.rows,
    required this.heights,
  });

  final double left, top, cell;
  final int columns, rows;
  final Float32List heights;
}

Relief reliefFromGzip(Uint8List bytes) {
  final data = ByteData.sublistView(Uint8List.fromList(gzip.decode(bytes)));
  final columns = data.getUint16(12, Endian.little), rows = data.getUint16(14, Endian.little);
  final step = data.getFloat32(16, Endian.little);
  final heights = Float32List(columns * rows);
  for (var i = 0; i < heights.length; i++) {
    heights[i] = data.getUint16(20 + i * 2, Endian.little) * step;
  }
  return Relief(
    left: data.getFloat32(0, Endian.little),
    top: data.getFloat32(4, Endian.little),
    cell: data.getFloat32(8, Endian.little),
    columns: columns,
    rows: rows,
    heights: heights,
  );
}

// Bilinear, flat off the grid
double reliefAt(Relief r, double x, double y) {
  final u = (x - r.left) / r.cell, v = (y - r.top) / r.cell;
  if (u < 0 || v < 0 || u > r.columns - 1 || v > r.rows - 1) return 0;
  final c = min(u.floor(), r.columns - 2), w = min(v.floor(), r.rows - 2);
  final fu = u - c, fv = v - w;
  final h = r.heights, i = w * r.columns + c, j = i + r.columns;
  final top = h[i] + (h[i + 1] - h[i]) * fu;
  return top + (h[j] + (h[j + 1] - h[j]) * fu - top) * fv;
}

// Fine by the city, wider outwards
List<double> reliefLines(double from, double cityFrom, double cityTo, double to, Iterable<double> knots) {
  double away(double at) => max(cityFrom - at, max(0.0, at - cityTo));
  // Evenly spaced here gives the growing step
  double u(double d) => log(_edgeLineStep + _lineGrowth * d) / _lineGrowth;
  final fixed = {from, cityFrom, cityTo, to, ...knots.where((k) => k > from && k < to)}.toList()..sort();
  final out = [from];
  for (var i = 0; i + 1 < fixed.length; i++) {
    final a = fixed[i], b = fixed[i + 1];
    if (a >= cityFrom && b <= cityTo) {
      final n = max(1, ((b - a) / _cityLineStep).round());
      for (var k = 1; k < n; k++) {
        out.add(a + (b - a) * k / n);
      }
    } else {
      final ua = u(away(a)), ub = u(away(b));
      final n = max(1, (ub - ua).abs().round());
      for (var k = 1; k < n; k++) {
        final d = (exp(_lineGrowth * (ua + (ub - ua) * k / n)) - _edgeLineStep) / _lineGrowth;
        out.add(b <= cityFrom ? cityFrom - d : cityTo + d);
      }
    }
    out.add(b);
  }
  return out;
}

// Map units to atlas pixels, by piece
typedef AtlasAxis = ({List<double> at, List<double> pixel});

AtlasAxis atlasAxis(double farFrom, double midFrom, double midTo, double farTo, double resolution) {
  final far = resolution / _farUnitsPerPixel, mid = resolution / _midUnitsPerPixel;
  // Whole pixels, or pieces leave a seam
  final a = ((midFrom - farFrom) * far).roundToDouble(), b = a + ((midTo - midFrom) * mid).roundToDouble();
  return (at: [farFrom, midFrom, midTo, farTo], pixel: [0, a, b, b + ((farTo - midTo) * far).roundToDouble()]);
}

double atlasPixel(AtlasAxis axis, double v) {
  final at = axis.at, pixel = axis.pixel;
  var i = 0;
  while (i < at.length - 2 && v > at[i + 1]) {
    i++;
  }
  return pixel[i] + (v - at[i]) / (at[i + 1] - at[i]) * (pixel[i + 1] - pixel[i]);
}

// Past the camera target, in map units
double reliefFog(double beyond) => beyond <= _fogFrom ? 0 : 1 - exp(-pow((beyond - _fogFrom) / _fogReach, 1.5));

// Ground round the city, minus the city
class ReliefMesh {
  ReliefMesh(Relief relief, Surroundings s, {double resolution = 1})
    : xs = reliefLines(s.far.left, s.bounds.left, s.bounds.right, s.far.right, [s.mid.left, s.mid.right]),
      ys = reliefLines(s.far.top, s.bounds.top, s.bounds.bottom, s.far.bottom, [s.mid.top, s.mid.bottom]),
      atlasX = atlasAxis(s.far.left, s.mid.left, s.mid.right, s.far.right, resolution),
      atlasY = atlasAxis(s.far.top, s.mid.top, s.mid.bottom, s.far.bottom, resolution) {
    final columns = xs.length;
    z = Float32List(columns * ys.length);
    fade = Float32List(z.length);
    final cells = <int>[];
    for (var r = 0; r < ys.length; r++) {
      for (var c = 0; c < columns; c++) {
        final x = xs[c], y = ys[r];
        z[r * columns + c] = reliefAt(relief, x, y);
        final inside = min(min(x - s.far.left, s.far.right - x), min(y - s.far.top, s.far.bottom - y));
        final t = (inside / _edgeFade).clamp(0.0, 1.0);
        fade[r * columns + c] = 1 - t * t * (3 - 2 * t);
        if (r + 1 == ys.length || c + 1 == columns) continue;
        final center = Offset((x + xs[c + 1]) / 2, (y + ys[r + 1]) / 2);
        if (!s.bounds.contains(center)) cells.add(r * columns + c);
      }
    }
    this.cells = Int32List.fromList(cells);
  }

  final List<double> xs, ys;
  final AtlasAxis atlasX, atlasY;

  // Height and edge fog, per point
  late final Float32List z, fade;

  // Top left point of each cell
  late final Int32List cells;
}

void reliefFarFirst(ReliefMesh mesh, double yaw, Int32List order) {
  final sinYaw = sin(yaw), cosYaw = cos(yaw);
  final columns = mesh.xs.length;
  final keys = Float64List(mesh.cells.length);
  for (var i = 0; i < keys.length; i++) {
    final at = mesh.cells[i], c = at % columns, r = at ~/ columns;
    keys[i] = (mesh.xs[c] + mesh.xs[c + 1]) * sinYaw + (mesh.ys[r] + mesh.ys[r + 1]) * cosYaw;
  }
  final sorted = List.generate(keys.length, (i) => i)..sort((a, b) => keys[a].compareTo(keys[b]));
  order.setAll(0, sorted);
}
