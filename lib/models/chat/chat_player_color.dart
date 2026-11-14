import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChatPlayerColor {
  static const double minContrast = 4.5;
  static const double _golden = 137.508;
  static const double _saturation = 0.65;

  static double _hueOf(int id) => (id.abs() * _golden) % 360;

  static Color of(int id, Color background) {
    final dark = contrast(Colors.white, background) > contrast(Colors.black, background);
    final hue = _hueOf(id);
    var lightness = dark ? 0.72 : 0.30;
    var color = HSLColor.fromAHSL(1, hue, _saturation, lightness).toColor();
    while (contrast(color, background) < minContrast && lightness > 0.05 && lightness < 0.95) {
      lightness += dark ? 0.02 : -0.02;
      color = HSLColor.fromAHSL(1, hue, _saturation, lightness).toColor();
    }
    return contrast(color, background) < minContrast ? blackOrWhite(background) : color;
  }

  static Color blackOrWhite(Color background) =>
      contrast(Colors.white, background) >= contrast(Colors.black, background) ? Colors.white : Colors.black;

  /// Same hue, lightness nudged until legible
  static Color tinted(Color color, Color background) {
    final dark = contrast(Colors.white, background) > contrast(Colors.black, background);
    var hsl = HSLColor.fromColor(color);
    while (contrast(hsl.toColor(), background) < minContrast && hsl.lightness > 0.05 && hsl.lightness < 0.95) {
      hsl = hsl.withLightness((hsl.lightness + (dark ? 0.02 : -0.02)).clamp(0.0, 1.0));
    }
    final picked = hsl.toColor();
    return contrast(picked, background) < minContrast ? blackOrWhite(background) : picked;
  }

  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}
