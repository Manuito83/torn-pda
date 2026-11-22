import 'dart:math' as math;
import 'dart:ui';

// Web Mercator at Torn's zoom 6
Offset latLngToMap(double lat, double lng) {
  final sinLat = math.sin(lat * math.pi / 180);
  final mx = (lng + 180) / 360;
  final my = 0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi);
  return Offset(16383.9 * mx - 4168.2, 16382.3 * my - 5471.2);
}

double fitScale(Rect bounds, Size viewport) => math.min(viewport.width / bounds.width, viewport.height / bounds.height);

({double scale, Offset translation}) cameraToFit(Rect rect, Size viewport, {double maxScale = double.infinity}) {
  final scale = math.min(fitScale(rect, viewport), maxScale);
  final translation = viewport.center(Offset.zero) - rect.center * scale;
  return (scale: scale, translation: translation);
}

const _dragMarginX = 0.42;
const _dragMarginY = 0.30;

// Screen share past the city, then reach
Offset clampTranslation(Offset translation, double scale, Rect bounds, Size viewport, {Rect? reach}) {
  double clampAxis(double value, double start, double end, double screen, double share, double? from, double? to) {
    final margin = screen * share;
    final size = (end - start) * scale;
    // Small city stays fully on screen
    final lowest = math.min(screen - margin - size, 0.0);
    final highest = math.max(margin, screen - size);
    value = value.clamp(lowest - start * scale, highest - start * scale);
    if (from == null || to == null) return value;
    final first = screen - to * scale, last = -from * scale;
    return first > last ? (first + last) / 2 : value.clamp(first, last);
  }

  return Offset(
    clampAxis(translation.dx, bounds.left, bounds.right, viewport.width, _dragMarginX, reach?.left, reach?.right),
    clampAxis(translation.dy, bounds.top, bounds.bottom, viewport.height, _dragMarginY, reach?.top, reach?.bottom),
  );
}
