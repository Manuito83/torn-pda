import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/models/territory_map/map_video.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_timelapse_controller.dart';
import 'package:torn_pda/providers/territory_video_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/territory_map/territory_map_share.dart';
import 'package:torn_pda/widgets/territory_map/video_dialogs.dart';

Future<void> shareMapVideo(
  BuildContext context,
  GlobalKey mapKey,
  GlobalKey legendKey,
  Future<void> Function(bool ready) readyForPicture,
  TerritoryTimelapseController timelapse,
  TerritoryVideoController video, {
  required int range,
  required Future<void> Function(String chosen) restore,
}) async {
  final boundary = mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return shareToast('The map is not ready yet');

  final legend = legendKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  final theme = context.read<ThemeProvider>();
  final map = context.read<TerritoryMapController>();
  final origin = shareOrigin(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final days = videoDays(timelapse.days, range);
  final chosen = timelapse.days[timelapse.selected];
  final size = videoSize(mapWidth: boundary.size.width, mapHeight: boundary.size.height, footer: mapPictureFooter);

  video.begin(total: days.length);
  showVideoProgressDialog(context, video);
  String? made;
  try {
    final folder = await freshShareFolder();
    await readyForPicture(true);
    made = await video.export(
      path: '${folder.path}/${videoFileName(days.first, days.last)}',
      size: size,
      days: days,
      showDay: (day) => timelapse.showDay(day, cancelled: () => video.cancelled),
      captureFrame: () async {
        final picture = await composeMapPicture(
          boundary,
          legend: legend,
          ratio: size.ratio,
          caption: mapPictureCaption(now: DateTime.now().toUtc(), pastDay: map.pastDay),
          background: theme.canvas,
          text: theme.mainText,
        );
        try {
          return await _rgbaFrame(picture, size);
        } finally {
          picture.dispose();
        }
      },
    );
  } catch (e) {
    debugPrint('territory map: make video failed: $e');
    shareToast('Could not make the video');
  } finally {
    if (navigator.mounted) navigator.pop();
    video.end();
    await readyForPicture(false);
    await restore(chosen);
  }
  if (made == null) return;
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(made, mimeType: 'video/mp4')],
        sharePositionOrigin: origin,
      ),
    );
  } catch (e) {
    debugPrint('territory map: share video failed: $e');
    shareToast('Could not share the video');
  }
}

// Encoder start size
Future<Uint8List> _rgbaFrame(ui.Image picture, VideoSize size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    picture,
    Rect.fromLTWH(0, 0, picture.width.toDouble(), picture.height.toDouble()),
    Rect.fromLTWH(0, 0, size.width.toDouble(), size.height.toDouble()),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final frame = await recorder.endRecording().toImage(size.width, size.height);
  try {
    final data = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) throw StateError('frame encoding failed');
    return data.buffer.asUint8List();
  } finally {
    frame.dispose();
  }
}
