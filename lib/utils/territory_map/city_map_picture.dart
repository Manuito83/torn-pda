import 'dart:convert';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';

const _pixelRatio = 1.5;

// Data URL for Torn's map hole
Future<String?> cityMapPictureUrl(GlobalKey mapKey) async {
  final boundary = mapKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary || !boundary.attached) return null;
  final image = await boundary.toImage(pixelRatio: _pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List())}';
  } finally {
    image.dispose();
  }
}
