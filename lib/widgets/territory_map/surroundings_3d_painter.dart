import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/surroundings_relief.dart';
import 'package:torn_pda/widgets/territory_map/city_3d_painter.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_layer.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_strip_painter.dart';
import 'package:torn_pda/widgets/territory_map/territory_base_painter.dart';

const _skyBand = 0.3;

// Photos with the strip on top
Future<ui.Image> renderSurroundingsAtlas(ui.Image far, ui.Image? mid, StripPaints strip, ReliefMesh mesh) {
  final s = strip.surroundings;
  final ax = mesh.atlasX, ay = mesh.atlasY;
  final paint = Paint()..filterQuality = FilterQuality.medium;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  double farX(double x) => (x - s.far.left) / s.far.width * far.width;
  double farY(double y) => (y - s.far.top) / s.far.height * far.height;
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      canvas.drawImageRect(
        far,
        Rect.fromLTRB(farX(ax.at[i]), farY(ay.at[j]), farX(ax.at[i + 1]), farY(ay.at[j + 1])),
        Rect.fromLTRB(ax.pixel[i], ay.pixel[j], ax.pixel[i + 1], ay.pixel[j + 1]),
        paint,
      );
    }
  }
  final middle = Rect.fromLTRB(ax.pixel[1], ay.pixel[1], ax.pixel[2], ay.pixel[2]);
  if (mid != null) {
    canvas.drawImageRect(mid, Rect.fromLTWH(0, 0, mid.width.toDouble(), mid.height.toDouble()), middle, paint);
  }
  canvas
    ..save()
    ..clipRect(middle)
    ..translate(middle.left, middle.top)
    ..scale(middle.width / (ax.at[2] - ax.at[1]), middle.height / (ay.at[2] - ay.at[1]))
    ..translate(-ax.at[1], -ay.at[1]);
  paintSurroundingsStrip(canvas, strip, s.near, farGroundScale);
  canvas.restore();
  final picture = recorder.endRecording();
  return picture.toImage(ax.pixel.last.ceil(), ay.pixel.last.ceil()).whenComplete(picture.dispose);
}

// Relief round the city, fogged far off
class SurroundingsTerrain {
  SurroundingsTerrain(this.atlas, this.mesh, Color fog)
    : _fog = fog.toARGB32() & 0xFFFFFF,
      _paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..shader = ImageShader(atlas, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage) {
    final points = mesh.xs.length * mesh.ys.length, cells = mesh.cells.length;
    _x = Float32List(points);
    _y = Float32List(points);
    _shade = Int32List(points);
    _order = Int32List(cells);
    _positions = Float32List(cells * 12);
    _texture = Float32List(cells * 12);
    _colors = Int32List(cells * 6);
    _u = [for (final x in mesh.xs) atlasPixel(mesh.atlasX, x)];
    _v = [for (final y in mesh.ys) atlasPixel(mesh.atlasY, y)];
  }

  final ui.Image atlas;
  final ReliefMesh mesh;
  final int _fog;
  final Paint _paint;
  late final Float32List _x, _y, _positions, _texture;
  late final Int32List _shade, _order, _colors;
  late final List<double> _u, _v;
  double? _orderedFor;

  void paint(Canvas canvas, CityProjection p) {
    final columns = mesh.xs.length;
    final camera = p.camera;
    if (_orderedFor != camera.yaw) {
      _orderedFor = camera.yaw;
      reliefFarFirst(mesh, camera.yaw, _order);
      var i = 0;
      for (final cell in _order) {
        final at = mesh.cells[cell], c = at % columns, r = at ~/ columns;
        for (final (dc, dr) in gridCorners) {
          _texture[i++] = _u[c + dc];
          _texture[i++] = _v[r + dr];
        }
      }
    }

    final near = p.near;
    var j = 0;
    for (var r = 0; r < mesh.ys.length; r++) {
      final dy = mesh.ys[r] - camera.y;
      for (var c = 0; c < columns; c++, j++) {
        final dx = mesh.xs[c] - camera.x, z = mesh.z[j];
        final rx = dx * p.cosYaw - dy * p.sinYaw, ry = dx * p.sinYaw + dy * p.cosYaw;
        final beyond = -(ry * p.sinPitch + z * p.cosPitch);
        final k = camera.zoom * p.distance / math.max(p.distance + beyond, near);
        _x[j] = p.centerX + rx * k;
        _y[j] = p.centerY + (ry * p.cosPitch - z * p.sinPitch) * k;
        final fog = math.max(reliefFog(beyond), mesh.fade[j]);
        _shade[j] = (fog * 255).round() << 24 | _fog;
      }
    }

    var i = 0, n = 0;
    for (final cell in _order) {
      final at = mesh.cells[cell];
      for (final (dc, dr) in gridCorners) {
        final point = at + dr * columns + dc;
        _positions[i++] = _x[point];
        _positions[i++] = _y[point];
        _colors[n++] = _shade[point];
      }
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      textureCoordinates: _texture,
      colors: _colors,
    );
    // Fog color over the photo by alpha
    canvas.drawVertices(vertices, BlendMode.dstATop, _paint);
    vertices.dispose();
  }

  void dispose() {
    _paint.shader?.dispose();
    atlas.dispose();
  }
}

Color _skyTop({required bool lightTheme}) => lightTheme ? const Color(0xFFC3D5E6) : const Color(0xFF131925);

// Air, and sky above the horizon
void paintSky(Canvas canvas, Size size, CityProjection p, {required bool lightTheme}) {
  final air = surroundingsAir(lightTheme: lightTheme);
  canvas.drawColor(air, BlendMode.src);
  if (p.sinPitch < 0.01) return;
  final horizon = p.centerY - p.camera.zoom * p.distance * p.cosPitch / p.sinPitch;
  if (horizon <= 0) return;
  final top = horizon - size.height * _skyBand;
  canvas.drawRect(
    Rect.fromLTRB(0, 0, size.width, horizon),
    Paint()..shader = ui.Gradient.linear(Offset(0, top), Offset(0, horizon), [_skyTop(lightTheme: lightTheme), air]),
  );
}
