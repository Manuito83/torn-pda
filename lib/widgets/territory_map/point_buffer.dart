import 'dart:typed_data';
import 'dart:ui';

// Reused frame after frame, only grows
class PointBuffer {
  var _data = Float32List(512);
  var _length = 0;

  bool get isEmpty => _length == 0;

  Float32List get points => Float32List.sublistView(_data, 0, _length);

  void clear() => _length = 0;

  void add(double x, double y) {
    if (_length + 2 > _data.length) _data = Float32List(_data.length * 2)..setAll(0, _data);
    _data[_length++] = x;
    _data[_length++] = y;
  }
}

// Triangles with a color per corner
class ColorMesh {
  final _positions = <double>[];
  final _colors = <int>[];

  // a, b near end; c, d far
  void quad(Offset a, Offset b, Offset c, Offset d, int near, int far) {
    _positions.addAll([a.dx, a.dy, b.dx, b.dy, c.dx, c.dy, b.dx, b.dy, d.dx, d.dy, c.dx, c.dy]);
    _colors.addAll([near, near, far, near, far, far]);
  }

  void draw(Canvas canvas, Paint paint) {
    if (_positions.isEmpty) return;
    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.fromList(_positions),
      colors: Int32List.fromList(_colors),
    );
    canvas.drawVertices(vertices, BlendMode.dst, paint);
    vertices.dispose();
    _positions.clear();
    _colors.clear();
  }
}
