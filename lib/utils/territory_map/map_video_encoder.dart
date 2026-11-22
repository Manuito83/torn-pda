import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_story_encoder/flutter_story_encoder.dart';
import 'package:torn_pda/models/territory_map/map_video.dart';

const _busyTries = 100;
const _busyWait = Duration(milliseconds: 30);

// Its finish drains the codec only once
const _drainWait = Duration(milliseconds: 300);

abstract class MapVideoEncoder {
  Future<void> start({required String path, required int width, required int height});

  // Raw RGBA, exactly width x height
  Future<void> addFrame(Uint8List rgba);

  Future<String> finish();

  // Drops the file as well
  Future<void> cancel();
}

class StoryMapVideoEncoder implements MapVideoEncoder {
  String? _path;

  @override
  Future<void> start({required String path, required int width, required int height}) async {
    _path = path;
    final config = EncoderConfig(
      width: width,
      height: height,
      fps: videoFps,
      bitrate: videoBitrate,
      outputPath: path,
      addSilentAudio: false,
    );
    if (!await FlutterStoryEncoder.start(config: config)) throw StateError('encoder did not start');
  }

  // False while the encoder is busy
  @override
  Future<void> addFrame(Uint8List rgba) async {
    for (var i = 0; i < _busyTries; i++) {
      if (await FlutterStoryEncoder.appendFrame(rgba)) return;
      await Future.delayed(_busyWait);
    }
    throw StateError('encoder stayed busy');
  }

  @override
  Future<String> finish() async {
    await Future.delayed(_drainWait);
    final path = await FlutterStoryEncoder.finish();
    if (path == null) throw StateError('encoder gave no file');
    return path;
  }

  @override
  Future<void> cancel() async {
    await FlutterStoryEncoder.cancel();
    final path = _path;
    if (path != null && await File(path).exists()) await File(path).delete();
  }
}
