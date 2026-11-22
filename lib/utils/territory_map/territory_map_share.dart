import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_share_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

const _maxPixelRatio = 3.0;
const mapPictureFooter = 30.0;
const _folderName = 'territory_map_share';

void shareToast(String text) {
  BotToast.showText(
    text: text,
    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
    contentColor: Colors.grey[700]!,
    duration: const Duration(seconds: 3),
    contentPadding: const EdgeInsets.all(10),
  );
}

Rect shareOrigin(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return Rect.fromLTWH(0, 0, size.width, size.height / 2);
}

Future<void> shareMapView(BuildContext context) async {
  final map = context.read<TerritoryMapController>();
  final view = context.read<TerritoryShareController>().capture(map);
  if (view == null) return shareToast('The map is not ready yet');
  await SharePlus.instance.share(ShareParams(text: mapShareMessage(view), sharePositionOrigin: shareOrigin(context)));
}

// Left in the box, never sent
void sendMapViewToFaction(BuildContext context) {
  final view = context.read<TerritoryShareController>().capture(context.read<TerritoryMapController>());
  if (view == null) return shareToast('The map is not ready yet');
  NativeChat.shareToFaction(buildMapLink(view));
}

Future<void> shareMapPicture(
  BuildContext context,
  GlobalKey mapKey,
  GlobalKey legendKey,
  Future<void> Function(bool ready) readyForPicture,
) async {
  final origin = shareOrigin(context);
  final ratio = math.min(MediaQuery.devicePixelRatioOf(context), _maxPixelRatio);
  final theme = context.read<ThemeProvider>();
  final map = context.read<TerritoryMapController>();
  final caption = mapPictureCaption(now: DateTime.now().toUtc(), pastDay: map.pastDay);
  final boundary = mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return shareToast('The map is not ready yet');
  final legend = legendKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

  try {
    await readyForPicture(true);
    final Uint8List png;
    try {
      png = await _renderMapPicture(
        boundary,
        legend: legend,
        ratio: ratio,
        caption: caption,
        background: theme.canvas,
        text: theme.mainText,
      );
    } finally {
      await readyForPicture(false);
    }
    final file = await _writeTemp(png);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: origin,
      ),
    );
  } catch (e) {
    debugPrint('territory map: share picture failed: $e');
    shareToast('Could not make the picture');
  }
}

Future<Uint8List> _renderMapPicture(
  RenderRepaintBoundary boundary, {
  required RenderRepaintBoundary? legend,
  required double ratio,
  required String caption,
  required Color background,
  required Color text,
}) async {
  final composed = await composeMapPicture(
    boundary,
    legend: legend,
    ratio: ratio,
    caption: caption,
    background: background,
    text: text,
  );
  try {
    final data = await composed.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('png encoding failed');
    return data.buffer.asUint8List();
  } finally {
    composed.dispose();
  }
}

// The caller disposes it
Future<ui.Image> composeMapPicture(
  RenderRepaintBoundary boundary, {
  required RenderRepaintBoundary? legend,
  required double ratio,
  required String caption,
  required Color background,
  required Color text,
}) async {
  if (boundary.debugNeedsPaint) await WidgetsBinding.instance.endOfFrame;
  final map = await boundary.toImage(pixelRatio: ratio);
  ui.Image? legendImage;
  try {
    // Same place as on screen
    Offset? legendAt;
    if (legend != null && legend.attached && legend.hasSize) {
      legendImage = await legend.toImage(pixelRatio: ratio);
      legendAt = (legend.localToGlobal(Offset.zero) - boundary.localToGlobal(Offset.zero)) * ratio;
    }
    final footer = mapPictureFooter * ratio;
    final width = map.width.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, map.height.toDouble()), Paint()..color = background);
    canvas.drawImage(map, Offset.zero, Paint());
    if (legendImage != null && legendAt != null) canvas.drawImage(legendImage, legendAt, Paint());
    canvas.drawRect(Rect.fromLTWH(0, map.height.toDouble(), width, footer), Paint()..color = background);
    final style = TextStyle(color: text.withValues(alpha: 0.8), fontSize: 12 * ratio);
    final margin = 10 * ratio;
    final right = _footerText('Torn PDA', style.copyWith(fontWeight: FontWeight.bold), width / 2);
    final left = _footerText(caption, style, width - right.width - 3 * margin);
    final top = map.height + (footer - left.height) / 2;
    left.paint(canvas, Offset(margin, top));
    right.paint(canvas, Offset(width - margin - right.width, top));

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(map.width, map.height + footer.round());
    } finally {
      picture.dispose();
    }
  } finally {
    map.dispose();
    legendImage?.dispose();
  }
}

TextPainter _footerText(String text, TextStyle style, double maxWidth) {
  return TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '...',
  )..layout(maxWidth: maxWidth);
}

// Empty, files from earlier shares are gone
Future<Directory> freshShareFolder() async {
  final folder = Directory('${(await getTemporaryDirectory()).path}/$_folderName');
  if (await folder.exists()) await folder.delete(recursive: true);
  return folder.create(recursive: true);
}

Future<File> _writeTemp(Uint8List png) async {
  final folder = await freshShareFolder();
  final file = File('${folder.path}/territory_map_${DateTime.now().millisecondsSinceEpoch}.png');
  return file.writeAsBytes(png, flush: true);
}
