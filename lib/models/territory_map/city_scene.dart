import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

const _wallShades = [0.34, 0.47, 0.62, 0.78];

// Below this a territory has no walls
const _flatBelow = 0.3;

// Visible territories, farthest first
class CityOrder {
  CityOrder(int territories)
    : all = Int32List.fromList([for (var t = 0; t < territories; t++) t]),
      order = Int32List(territories),
      key = Float32List(territories),
      fog = Float32List(territories),
      _visible = Uint8List(territories);

  // Last frame's order, nearly sorted
  final Int32List all;
  final Int32List order;
  final Float32List key;
  final Float32List fog;
  final Uint8List _visible;
  bool _sorted = false;
  int count = 0;
}

void sortVisible(CityMesh mesh, CityProjection p, Float32List heights, CityOrder out) {
  final camera = p.camera;
  final foot = p.distance * p.sinPitch;
  final near = p.near;
  final width = p.size.width, height = p.size.height;
  final key = out.key, visible = out._visible;
  var minKey = double.infinity, maxKey = double.negativeInfinity;
  for (var t = 0; t < mesh.length; t++) {
    final dx = mesh.centerX[t] - camera.x, dy = mesh.centerY[t] - camera.y;
    final rx = dx * p.cosYaw - dy * p.sinYaw, ry = dx * p.sinYaw + dy * p.cosYaw;
    final d = rx * rx + (ry - foot) * (ry - foot);
    key[t] = d;
    visible[t] = 0;
    final depth = p.distance - ry * p.sinPitch;
    if (depth - mesh.radius[t] < near) continue;
    final k = camera.zoom * p.distance / depth, r = (mesh.radius[t] + 4) * k;
    final sx = p.centerX + rx * k, sy = p.centerY + ry * p.cosPitch * k;
    final rise = heights[t] * p.sinPitch * k * 1.3;
    if (sx + r < 0 || sx - r > width || sy - r - rise > height || sy + r < 0) continue;
    visible[t] = 1;
    minKey = math.min(minKey, d);
    maxKey = math.max(maxKey, d);
  }

  final all = out.all;
  if (!out._sorted) {
    all.sort((a, b) => key[b].compareTo(key[a]));
    out._sorted = true;
  }
  for (var i = 1; i < all.length; i++) {
    final t = all[i];
    final d = key[t];
    var j = i - 1;
    while (j >= 0 && key[all[j]] < d) {
      all[j + 1] = all[j];
      j--;
    }
    all[j + 1] = t;
  }
  var count = 0;
  for (final t in all) {
    if (visible[t] == 1) out.order[count++] = t;
  }
  out.count = count;
  final span = math.max(1.0, maxKey - minKey);
  for (var i = 0; i < count; i++) {
    final t = out.order[i];
    final far = (key[t] - minKey) / span * p.sinPitch * 1.15;
    out.fog[t] = ((far - 0.2) * 0.62).clamp(0.0, 0.5);
  }
}

int shadeColor(int color, double light, double fog, int background) {
  final keep = light * (1 - fog);
  final r = (((color >> 16) & 0xFF) * keep + ((background >> 16) & 0xFF) * fog).round().clamp(0, 255);
  final g = (((color >> 8) & 0xFF) * keep + ((background >> 8) & 0xFF) * fog).round().clamp(0, 255);
  final b = ((color & 0xFF) * keep + (background & 0xFF) * fog).round().clamp(0, 255);
  return (0xFF000000 | r << 16 | g << 8 | b).toSigned(32);
}

// Two triangles, corners in order
void _quad(
  Float32List pos,
  Int32List col,
  int n,
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
  double dx,
  double dy,
  int color,
) {
  final i = n * 2;
  pos[i] = ax;
  pos[i + 1] = ay;
  pos[i + 2] = bx;
  pos[i + 3] = by;
  pos[i + 4] = cx;
  pos[i + 5] = cy;
  pos[i + 6] = ax;
  pos[i + 7] = ay;
  pos[i + 8] = cx;
  pos[i + 9] = cy;
  pos[i + 10] = dx;
  pos[i + 11] = dy;
  col.fillRange(n, n + 6, color);
}

// False when too short to draw
bool _line(Float32List pos, Int32List col, int n, double x0, double y0, double x1, double y1, double half, int color) {
  final ex = x1 - x0, ey = y1 - y0;
  final length = math.sqrt(ex * ex + ey * ey);
  if (length < 0.01) return false;
  final nx = -ey / length * half, ny = ex / length * half;
  _quad(pos, col, n, x0 + nx, y0 + ny, x1 + nx, y1 + ny, x1 - nx, y1 - ny, x0 - nx, y0 - ny, color);
  return true;
}

// Roof edges, city border left out
Uint8List outlineEdges(CityMeshLevel level, Iterable<int> territories, Rect city) {
  final out = Uint8List(level.vertexCount);
  for (final t in territories) {
    for (var r = level.firstRing[t]; r < level.firstRing[t + 1]; r++) {
      final start = level.ringStart[r], end = level.ringStart[r + 1];
      for (var v = start; v < end; v++) {
        final w = v + 1 == end ? start : v + 1;
        if (!onCityEdge([level.x[v], level.y[v], level.x[w], level.y[w]], city)) out[v] = 1;
      }
    }
  }
  return out;
}

class CityFrame {
  // Outline edges from outlineEdges, 6 each
  CityFrame(this.level, {Uint8List? outline})
    : colors = Int32List(level.maxDrawnVertices + (outline?.where((e) => e == 1).length ?? 0) * 6),
      groundX = Float32List(level.vertexCount),
      groundY = Float32List(level.vertexCount),
      topX = Float32List(level.vertexCount),
      topY = Float32List(level.vertexCount);

  final CityMeshLevel level;
  final Int32List colors;
  late final positions = Float32List(colors.length * 2);
  final Float32List groundX, groundY, topX, topY;
  final wallColors = Int32List(_wallShades.length);
  int vertices = 0;
  int walls = 0;
}

void projectTerritory(CityMeshLevel level, int t, double h, CityProjection p, CityFrame frame) {
  final camera = p.camera;
  final near = p.near;
  final from = level.ringStart[level.firstRing[t]], to = level.ringStart[level.firstRing[t + 1]];
  for (var v = from; v < to; v++) {
    final dx = level.x[v] - camera.x, dy = level.y[v] - camera.y;
    final rx = dx * p.cosYaw - dy * p.sinYaw, ry = dx * p.sinYaw + dy * p.cosYaw;
    final lift = ry * p.sinPitch;
    final k0 = camera.zoom * p.distance / math.max(p.distance - lift, near);
    frame.groundX[v] = p.centerX + rx * k0;
    frame.groundY[v] = p.centerY + ry * p.cosPitch * k0;
    if (h > 0) {
      final k1 = camera.zoom * p.distance / math.max(p.distance - lift - h * p.cosPitch, near);
      frame.topX[v] = p.centerX + rx * k1;
      frame.topY[v] = p.centerY + (ry * p.cosPitch - h * p.sinPitch) * k1;
    } else {
      frame.topX[v] = frame.groundX[v];
      frame.topY[v] = frame.groundY[v];
    }
  }
}

// Back to front, walls then top
void fillCityFrame(
  CityFrame frame,
  CityMesh mesh,
  CityProjection p,
  Float32List heights,
  CityOrder order,
  Int32List colors,
  int background, {
  double borderWidth = 0,
  // Far walls dropped when frames run slow
  double wallsFrom = 0,
  // Roof lines, from outlineEdges
  Uint8List? lines,
  int lineColor = 0,
  double lineWidth = 0,
}) {
  final level = frame.level;
  final pos = frame.positions, col = frame.colors;
  final gx = frame.groundX, gy = frame.groundY, hx = frame.topX, hy = frame.topY;
  final firstWalls = order.count * wallsFrom;
  var n = 0, walls = 0;

  for (var i = 0; i < order.count; i++) {
    final t = order.order[i];
    final h = heights[t];
    final fog = order.fog[t];
    final base = colors[t];
    projectTerritory(level, t, h, p, frame);
    final firstRing = level.firstRing[t], lastRing = level.firstRing[t + 1];

    if (h > _flatBelow && i >= firstWalls) {
      final shades = frame.wallColors;
      for (var s = 0; s < shades.length; s++) {
        shades[s] = shadeColor(base, _wallShades[s], fog, background);
      }
      for (var r = firstRing; r < lastRing; r++) {
        final start = level.ringStart[r], end = level.ringStart[r + 1];
        for (var v = start; v < end; v++) {
          final w = v + 1 == end ? start : v + 1;
          final ex = gx[w] - gx[v], ey = gy[w] - gy[v];
          if (ex * (hy[v] - gy[v]) - ey * (hx[v] - gx[v]) <= 0) continue;
          _quad(pos, col, n, gx[v], gy[v], gx[w], gy[w], hx[w], hy[w], hx[v], hy[v], shades[level.light[v]]);
          n += 6;
          walls++;
        }
      }
    }

    final top = shadeColor(base, 1, fog, background);
    final last = level.firstTriangle[t + 1];
    for (var k = level.firstTriangle[t]; k < last; k++) {
      final v = level.triangles[k];
      pos[n * 2] = hx[v];
      pos[n * 2 + 1] = hy[v];
      col[n++] = top;
    }

    if (borderWidth > 0) {
      final line = shadeColor(base, 0.5, fog, background);
      final half = borderWidth / 2;
      for (var r = firstRing; r < lastRing; r++) {
        final start = level.ringStart[r], end = level.ringStart[r + 1];
        for (var v = start; v < end; v++) {
          final w = v + 1 == end ? start : v + 1;
          if (_line(pos, col, n, hx[v], hy[v], hx[w], hy[w], half, line)) n += 6;
        }
      }
    }
    if (lines != null) {
      for (var r = firstRing; r < lastRing; r++) {
        final start = level.ringStart[r], end = level.ringStart[r + 1];
        for (var v = start; v < end; v++) {
          final w = v + 1 == end ? start : v + 1;
          if (lines[v] == 1 && _line(pos, col, n, hx[v], hy[v], hx[w], hy[w], lineWidth / 2, lineColor)) n += 6;
        }
      }
    }
  }
  frame
    ..vertices = n
    ..walls = walls;
}

// Nearest first, -1 for none
int cityTerritoryAt(
  CityMesh mesh,
  CityProjection p,
  Float32List heights,
  Offset point, {
  required CityOrder order,
  required CityFrame frame,
}) {
  sortVisible(mesh, p, heights, order);
  final level = frame.level;
  final ring = <double>[];
  for (var i = order.count - 1; i >= 0; i--) {
    final t = order.order[i];
    projectTerritory(level, t, heights[t], p, frame);
    if (_covers(level, frame, t, heights[t], point.dx, point.dy, ring)) return t;
  }
  return -1;
}

// Top or a wall, already projected
bool _covers(CityMeshLevel level, CityFrame frame, int t, double h, double x, double y, List<double> ring) {
  final gx = frame.groundX, gy = frame.groundY, hx = frame.topX, hy = frame.topY;
  final firstRing = level.firstRing[t], lastRing = level.firstRing[t + 1];
  var onTop = false;
  for (var r = firstRing; r < lastRing; r++) {
    ring.clear();
    for (var v = level.ringStart[r]; v < level.ringStart[r + 1]; v++) {
      ring
        ..add(hx[v])
        ..add(hy[v]);
    }
    if (insideRing(x, y, ring)) onTop = !onTop;
  }
  if (onTop) return true;
  if (h <= _flatBelow) return false;
  for (var r = firstRing; r < lastRing; r++) {
    final start = level.ringStart[r], end = level.ringStart[r + 1];
    for (var v = start; v < end; v++) {
      final w = v + 1 == end ? start : v + 1;
      final ex = gx[w] - gx[v], ey = gy[w] - gy[v];
      if (ex * (hy[v] - gy[v]) - ey * (hx[v] - gx[v]) <= 0) continue;
      ring
        ..clear()
        ..add(gx[v])
        ..add(gy[v])
        ..add(gx[w])
        ..add(gy[w])
        ..add(hx[w])
        ..add(hy[w])
        ..add(hx[v])
        ..add(hy[v]);
      if (insideRing(x, y, ring)) return true;
    }
  }
  return false;
}

class CityRoofs {
  CityRoofs(int territories)
    : territory = Int32List(territories),
      x = Float32List(territories),
      y = Float32List(territories),
      width = Float32List(territories),
      _boxes = Float32List(territories * 4);

  final Int32List territory;
  final Float32List x, y, width;
  final Float32List _boxes;
  final _ring = <double>[];
}

// Roof middles in sight, nearest first
int roofsInSight(
  CityMesh mesh,
  CityProjection p,
  Float32List heights, {
  required CityOrder order,
  required CityFrame frame,
  required CityRoofs out,
  required double minWidth,
  double minScale = 0,
}) {
  sortVisible(mesh, p, heights, order);
  final level = frame.level;
  final gx = frame.groundX, gy = frame.groundY, hx = frame.topX, hy = frame.topY;
  final boxes = out._boxes;
  var count = 0;
  for (var i = order.count - 1; i >= 0; i--) {
    final t = order.order[i];
    final h = heights[t];
    projectTerritory(level, t, h, p, frame);
    var left = double.infinity, top = double.infinity;
    var right = double.negativeInfinity, bottom = double.negativeInfinity;
    var roofLeft = double.infinity, roofRight = double.negativeInfinity;
    for (var v = level.ringStart[level.firstRing[t]]; v < level.ringStart[level.firstRing[t + 1]]; v++) {
      left = math.min(left, math.min(gx[v], hx[v]));
      right = math.max(right, math.max(gx[v], hx[v]));
      top = math.min(top, math.min(gy[v], hy[v]));
      bottom = math.max(bottom, math.max(gy[v], hy[v]));
      roofLeft = math.min(roofLeft, hx[v]);
      roofRight = math.max(roofRight, hx[v]);
    }
    boxes
      ..[i * 4] = left
      ..[i * 4 + 1] = top
      ..[i * 4 + 2] = right
      ..[i * 4 + 3] = bottom;
    final width = roofRight - roofLeft;
    if (width < minWidth || !p.place(mesh.centerX[t], mesh.centerY[t], h) || p.k < minScale) continue;
    final x = p.sx, y = p.sy;
    if (x < 0 || y < 0 || x > p.size.width || y > p.size.height) continue;
    var hidden = false;
    for (var j = i + 1; j < order.count && !hidden; j++) {
      if (x < boxes[j * 4] || y < boxes[j * 4 + 1] || x > boxes[j * 4 + 2] || y > boxes[j * 4 + 3]) continue;
      final u = order.order[j];
      hidden = _covers(level, frame, u, heights[u], x, y, out._ring);
    }
    if (hidden) continue;
    out.territory[count] = t;
    out.x[count] = x;
    out.y[count] = y;
    out.width[count] = width;
    count++;
  }
  return count;
}
