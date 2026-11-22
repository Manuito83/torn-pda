import 'dart:convert';

import 'package:flutter/painting.dart';

const _frameSideMargin = 8.0;
const _frameEndMargin = 15.0;

// Null if scrolled away
Rect? cityHoleOnScreen(String? json, Rect webArea) {
  try {
    final hole = jsonDecode(json ?? '') as Map<String, dynamic>;
    double number(String key) => (hole[key] as num).toDouble();
    final scale = webArea.width / number('vw');
    final rect = Rect.fromLTWH(
      webArea.left + number('x') * scale,
      webArea.top + number('y') * scale,
      number('w') * scale,
      number('h') * scale,
    );
    final visible = rect.intersect(webArea);
    if (visible.width <= 0 || visible.height < rect.height / 2) return null;
    return rect;
  } catch (_) {
    return null;
  }
}

// Debug line for each close
String cityCloseLine({required bool hole, required String reason, String? rect}) {
  var box = 'box unknown';
  try {
    final r = jsonDecode(rect ?? '') as Map<String, dynamic>;
    String n(String key) => (r[key] as num).round().toString();
    final page = r['vh'] == null ? n('vw') : '${n('vw')}x${n('vh')}';
    box = 'box ${n('w')}x${n('h')} at ${n('x')},${n('y')}, page $page';
  } catch (_) {}
  return 'City map closed: ${hole ? 'picture in the hole' : "Torn's map back"} ($reason), $box';
}

Rect cityFrameRect(Size screen, EdgeInsets padding) {
  return Rect.fromLTRB(
    padding.left + _frameSideMargin,
    padding.top + _frameEndMargin,
    screen.width - padding.right - _frameSideMargin,
    screen.height - padding.bottom - _frameEndMargin,
  );
}

// Like a covering image
({double scale, Offset offset}) cityFrameCover(Rect rect, Size frame) {
  final widthScale = rect.width / frame.width;
  final heightScale = rect.height / frame.height;
  final scale = widthScale > heightScale ? widthScale : heightScale;
  return (
    scale: scale,
    offset: Offset((rect.width - frame.width * scale) / 2, (rect.height - frame.height * scale) / 2),
  );
}

bool cityBackCloses(DateTime? lastBack, DateTime now) =>
    lastBack != null && now.difference(lastBack) < const Duration(seconds: 2);

// Null unless it points at a territory
String? cityLinkTerritory(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.endsWith('city.php')) return null;
  const prefix = 'terrName=';
  return uri.fragment.startsWith(prefix) ? uri.fragment.substring(prefix.length) : null;
}
