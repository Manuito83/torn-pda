import 'dart:math' as math;
import 'dart:ui';

const maxPitch = 1.28;
const maxCityZoom = 6.0;

// Enough to see port, island, hills
const _outsideReach = 2000.0;

// Zoom in pixels per map unit
typedef CityCamera = ({double yaw, double pitch, double zoom, double x, double y});

class CityProjection {
  CityProjection(this.camera, this.size)
    : cosYaw = math.cos(camera.yaw),
      sinYaw = math.sin(camera.yaw),
      cosPitch = math.cos(camera.pitch),
      sinPitch = math.sin(camera.pitch),
      distance = math.max(size.height / camera.zoom * 1.15, 700),
      centerX = size.width / 2,
      centerY = size.height * (0.5 + 0.1 * math.sin(camera.pitch));

  final CityCamera camera;
  final Size size;
  final double cosYaw, sinYaw, cosPitch, sinPitch;
  final double distance;
  final double centerX, centerY;

  double get near => distance * 0.14;

  // Left by place, pixels per unit there
  double sx = 0, sy = 0, k = 0;

  // False behind the camera
  bool place(double x, double y, double z) {
    final dx = x - camera.x, dy = y - camera.y;
    final rx = dx * cosYaw - dy * sinYaw, ry = dx * sinYaw + dy * cosYaw;
    final depth = distance - (ry * sinPitch + z * cosPitch);
    if (depth < near) return false;
    k = camera.zoom * distance / depth;
    sx = centerX + rx * k;
    sy = centerY + (ry * cosPitch - z * sinPitch) * k;
    return true;
  }

  // Null behind the camera
  Offset? project(double x, double y, double z) => place(x, y, z) ? Offset(sx, sy) : null;

  Rect groundInView() {
    var area = Rect.fromPoints(groundAt(Offset.zero), groundAt(Offset(size.width, 0)));
    for (final corner in [Offset(0, size.height), Offset(size.width, size.height)]) {
      area = area.expandToInclude(Rect.fromPoints(groundAt(corner), groundAt(corner)));
    }
    return area;
  }

  // Above the horizon, held below it
  Offset groundAt(Offset screen) {
    final u = (screen.dx - centerX) / camera.zoom;
    var v = (screen.dy - centerY) / camera.zoom;
    if (sinPitch > 0) v = math.max(v, -0.7 * cosPitch * distance / sinPitch);
    final ry = v * distance / (cosPitch * distance + v * sinPitch);
    final rx = u * (distance - ry * sinPitch) / distance;
    return Offset(camera.x + rx * cosYaw + ry * sinYaw, camera.y - rx * sinYaw + ry * cosYaw);
  }
}

double fitCityZoom(Rect bounds, Size size) => math.min(size.width / bounds.width, size.height / bounds.height) * 0.98;

CityCamera clampCamera(CityCamera c, Rect bounds, Size size) => (
  yaw: c.yaw,
  pitch: c.pitch.clamp(0.0, maxPitch),
  zoom: c.zoom.clamp(fitCityZoom(bounds, size) * 0.75, maxCityZoom),
  x: c.x.clamp(bounds.left - _outsideReach, bounds.right + _outsideReach),
  y: c.y.clamp(bounds.top - _outsideReach, bounds.bottom + _outsideReach),
);

// The ground under the fingers stays there
CityCamera pinchCamera(CityCamera c, Size size, Offset from, Offset to, double scale, double rotation, Rect bounds) {
  final held = CityProjection(c, size).groundAt(from);
  final zoom = clampCamera((yaw: c.yaw, pitch: c.pitch, zoom: c.zoom * scale, x: c.x, y: c.y), bounds, size).zoom;
  final moved = (yaw: c.yaw + rotation, pitch: c.pitch, zoom: zoom, x: c.x, y: c.y);
  final under = CityProjection(moved, size).groundAt(to);
  return (yaw: moved.yaw, pitch: c.pitch, zoom: zoom, x: c.x + held.dx - under.dx, y: c.y + held.dy - under.dy);
}

// Log zoom, shortest yaw
CityCamera lerpCamera(CityCamera a, CityCamera b, double t) {
  var turn = (b.yaw - a.yaw) % (2 * math.pi);
  if (turn > math.pi) turn -= 2 * math.pi;
  return (
    yaw: a.yaw + turn * t,
    pitch: a.pitch + (b.pitch - a.pitch) * t,
    zoom: a.zoom * math.pow(b.zoom / a.zoom, t),
    x: a.x + (b.x - a.x) * t,
    y: a.y + (b.y - a.y) * t,
  );
}

// Whole city tilted, room for chips
CityCamera homeCityCamera(Rect bounds, Size size, Iterable<Offset> points) {
  const top = 72.0, bottom = 36.0, side = 4.0;
  var c = (yaw: -0.5, pitch: 0.85, zoom: fitCityZoom(bounds, size), x: bounds.center.dx, y: bounds.center.dy);
  for (var pass = 0; pass < 6; pass++) {
    final projection = CityProjection(c, size);
    var minX = double.infinity, maxX = double.negativeInfinity;
    var minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in points) {
      final s = projection.project(p.dx, p.dy, 90);
      if (s == null) continue;
      minX = math.min(minX, s.dx);
      maxX = math.max(maxX, s.dx);
      minY = math.min(minY, s.dy);
      maxY = math.max(maxY, s.dy);
    }
    if (minX >= maxX || minY >= maxY) break;
    final fit = math.min((size.width - side * 2) / (maxX - minX), (size.height - top - bottom) / (maxY - minY));
    final a = projection.groundAt(Offset((minX + maxX) / 2, (minY + maxY) / 2));
    final b = projection.groundAt(Offset(size.width / 2, top + (size.height - top - bottom) / 2));
    c = (yaw: c.yaw, pitch: c.pitch, zoom: c.zoom * fit, x: c.x + a.dx - b.dx, y: c.y + a.dy - b.dy);
  }
  return c;
}
