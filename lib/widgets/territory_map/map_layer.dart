import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

class MapViewport {
  MapViewport(this.visible, this.scale);

  final Rect visible;
  final double scale;
}

// Drawn and tapped above the territories
abstract class MapLayer {
  void paint(Canvas canvas, MapViewport viewport);

  Object? hitTest(Offset mapPoint, double scale);
}

const _rebuildEvery = Duration(minutes: 1);

// Repaints with its source, rebuilt each minute
abstract class RefreshedMapLayer implements MapLayer, Listenable {
  RefreshedMapLayer(this._source);

  final Listenable _source;
  List<Object?> _inputs = const [];
  DateTime _builtAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void addListener(VoidCallback listener) => _source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _source.removeListener(listener);

  // True when inputs changed or a minute passed
  @protected
  bool outdated(List<Object?> inputs, DateTime now) {
    if (listEquals(inputs, _inputs) && now.difference(_builtAt) < _rebuildEvery) return false;
    _inputs = inputs;
    _builtAt = now;
    return true;
  }
}

class MapLayersPainter extends CustomPainter {
  MapLayersPainter(this.layers, this.viewport) : super(repaint: Listenable.merge(layers.whereType<Listenable>()));

  final List<MapLayer> layers;
  final MapViewport viewport;

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      layer.paint(canvas, viewport);
    }
  }

  @override
  bool shouldRepaint(MapLayersPainter old) => true;
}
