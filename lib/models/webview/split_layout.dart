import 'dart:convert';

const double kSplitScreenMinWidth = 800;
const double kSplitDividerWidth = 12;
const double kSplitSlotMinWidth = 320;

enum WebViewSplitPosition { right, left, off }

enum SplitSide {
  left,
  right;

  SplitSide get other => this == left ? right : left;
}

enum SplitGroup {
  main,
  apart;

  SplitGroup get other => this == main ? apart : main;
}

enum SplitSlotContent { app, browser, mainBrowser, apartBrowser, devTools }

double splitLeftSlotWidth(double width, double ratio, {double leftInset = 0, double rightInset = 0}) {
  final double available = width - kSplitDividerWidth;
  final double minLeft = kSplitSlotMinWidth + leftInset;
  final double minRight = kSplitSlotMinWidth + rightInset;
  if (available <= minLeft + minRight) return leftInset + (available - leftInset - rightInset) / 2;
  return (available * ratio).clamp(minLeft, available - minRight);
}

String encodeSplitLayout({
  required bool apartOpen,
  required SplitSide? appSlot,
  required SplitSide mainSlot,
  required String? mainVisible,
  required String? apartVisible,
}) {
  return jsonEncode({
    "apartOpen": apartOpen,
    "appSlot": appSlot?.name,
    "mainSlot": mainSlot.name,
    "mainVisible": mainVisible,
    "apartVisible": apartVisible,
  });
}

Map<String, dynamic> decodeSplitLayout(String saved) {
  try {
    final dynamic decoded = jsonDecode(saved);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return <String, dynamic>{};
}
