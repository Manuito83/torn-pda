import 'package:flutter/material.dart';

Color? getColorFromJson(dynamic colorData) {
  if (colorData is int) {
    // Newer format: Integer value
    return Color(colorData);
  }

  if (colorData is String) {
    // Check for old format: "Color(0xff757575)"
    if (colorData.startsWith("Color(") && colorData.endsWith(")")) {
      String hexValue = colorData.substring(6, colorData.length - 1);
      // Remove the '0x' prefix if present
      hexValue = hexValue.startsWith('0x') ? hexValue.substring(2) : hexValue;
      return Color(int.parse(hexValue, radix: 16));
    }
    // Check for direct hexadecimal string: "ff757575"
    else if (!colorData.startsWith("#") && colorData.length == 6) {
      return Color(int.parse("FF$colorData", radix: 16)); // Prepend FF for alpha channel
    }
    // Check for standard web color format: "#AABBCC"
    else if (colorData.startsWith("#") && colorData.length == 7) {
      return Color(int.parse(colorData.substring(1), radix: 16));
    }
  }

  return null;
}
