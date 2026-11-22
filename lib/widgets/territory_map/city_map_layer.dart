import 'dart:collection';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/providers/city_item_prices.dart';
import 'package:torn_pda/providers/city_map_options.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/map_layer.dart';

const _siteSize = 24.0;
const _itemSize = 22.0;
const _racketSize = 7.0;
const _racketsFromScale = 0.2;
const _tapSlop = 6.0;
const _racketColor = Color(0xFFFFC107);

// One per value tier, cheapest first
const _valueColors = [Color(0xFF9E9E9E), Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFFAB47BC), Color(0xFFFF8F00)];

String _itemImage(int id) => 'images/torn_items/small/${id}_small.png';

// Sites, rackets and dropped items from city.php
class CityMapLayer extends ChangeNotifier implements MapLayer {
  CityMapLayer(this.page, this.controller, {this.prices}) {
    options
      ..addListener(_optionsChanged)
      ..load();
    prices?.addListener(_pricesChanged);
  }

  final CityPageData page;
  final CityItemPrices? prices;
  late final _items = [...page.items];
  late final items = UnmodifiableListView(_items);
  final options = CityMapOptions();
  final TerritoryMapController controller;
  final _images = <String, ui.Image>{};
  bool _sitesLoaded = false;
  bool _disposed = false;

  final _back = Paint()..color = Colors.white.withValues(alpha: 0.85);
  final _ring = Paint()..style = PaintingStyle.stroke;
  final _racket = Paint()..color = _racketColor;
  final _edge = Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.stroke;
  final _image = Paint()..filterQuality = FilterQuality.medium;

  // Items and rackets are of now
  bool get _present => controller.pastDay == null;

  void _optionsChanged() {
    if (options.showSites && !_sitesLoaded) {
      _sitesLoaded = true;
      _loadImages({
        for (final site in page.sites)
          if (siteIcon(site.link) case final asset?) asset,
      });
    }
    notifyListeners();
  }

  void _pricesChanged() {
    final known = prices!.byItem;
    for (final (i, item) in _items.indexed) {
      _items[i] = CityItem(id: item.id, lat: item.lat, lng: item.lng, price: known[item.id] ?? item.price);
    }
    notifyListeners();
  }

  void loadImages() => _loadImages({for (final item in page.items) _itemImage(item.id)});

  void _loadImages(Set<String> assets) {
    for (final key in assets) {
      final stream = AssetImage(key).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        stream.removeListener(listener);
        if (_disposed) {
          info.dispose();
          return;
        }
        _images[key] = info.image.clone();
        info.dispose();
        notifyListeners();
      }, onError: (_, _) => stream.removeListener(listener));
      stream.addListener(listener);
    }
  }

  // Prices may have replaced the object
  void removeItem(CityItem item) {
    _items.removeWhere((i) => i.id == item.id && i.lat == item.lat && i.lng == item.lng);
    notifyListeners();
  }

  Color itemColor(CityItem item) => _valueColors[cityValueTier(item)];

  @override
  void dispose() {
    _disposed = true;
    prices?.removeListener(_pricesChanged);
    options.dispose();
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  void paint(Canvas canvas, MapViewport viewport) {
    final unit = 1 / viewport.scale;
    final visible = viewport.visible.inflate(_siteSize * unit);
    _edge.strokeWidth = unit;

    final territories = controller.territories?.territories;
    if (_present && viewport.scale >= _racketsFromScale && territories != null) {
      final r = _racketSize / 2 * unit;
      for (final code in page.rackets.keys) {
        final point = territories[code]?.label;
        if (point == null || !visible.contains(point)) continue;
        final diamond = Path()
          ..moveTo(point.dx, point.dy - r)
          ..lineTo(point.dx + r, point.dy)
          ..lineTo(point.dx, point.dy + r)
          ..lineTo(point.dx - r, point.dy)
          ..close();
        canvas
          ..drawPath(diamond, _racket)
          ..drawPath(diamond, _edge);
      }
    }

    if (options.showSites) {
      for (final site in page.sites) {
        if (!visible.contains(site.point)) continue;
        final rect = Rect.fromCenter(center: site.point, width: _siteSize * unit, height: _siteSize * unit);
        canvas
          ..drawOval(rect.inflate(unit), _back)
          ..drawOval(rect.inflate(unit), _edge);
        _drawImage(canvas, siteIcon(site.link), rect.deflate(2 * unit));
      }
    }

    if (!options.itemsVisible || !_present) return;
    _ring.strokeWidth = 2 * unit;
    for (final item in _items) {
      if (!visible.contains(item.point)) continue;
      final rect = Rect.fromCenter(center: item.point, width: _itemSize * unit, height: _itemSize * unit);
      _ring.color = itemColor(item);
      canvas
        ..drawOval(rect, _back)
        ..drawOval(rect, _ring);
      _drawImage(canvas, _itemImage(item.id), rect.deflate(4 * unit));
    }
  }

  void _drawImage(Canvas canvas, String? key, Rect rect) {
    final image = _images[key];
    if (image == null) return;
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final fit = applyBoxFit(BoxFit.contain, Size(width, height), rect.size);
    final src = Alignment.center.inscribe(fit.source, Rect.fromLTWH(0, 0, width, height));
    canvas.drawImageRect(image, src, Alignment.center.inscribe(fit.destination, rect), _image);
  }

  @override
  Object? hitTest(Offset mapPoint, double scale) {
    Object? nearest;
    var best = double.infinity;
    void check(Object hit, Offset point, double size) {
      final distance = (point - mapPoint).distance;
      if (distance < (size / 2 + _tapSlop) / scale && distance < best) {
        best = distance;
        nearest = hit;
      }
    }

    if (options.itemsVisible && _present) {
      for (final item in _items) {
        check(item, item.point, _itemSize);
      }
    }
    if (nearest != null) return nearest;
    if (options.showSites) {
      for (final site in page.sites) {
        check(site, site.point, _siteSize);
      }
    }
    return nearest;
  }
}
