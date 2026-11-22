import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/territory_video_controller.dart';
import 'package:torn_pda/utils/territory_map/map_video_encoder.dart';

class _FakeEncoder implements MapVideoEncoder {
  final frames = <int>[];
  var cancelled = false;
  var finished = false;

  @override
  Future<void> start({required String path, required int width, required int height}) async {}

  @override
  Future<void> addFrame(Uint8List rgba) async => frames.add(rgba.first);

  @override
  Future<String> finish() async {
    finished = true;
    return '/tmp/out.mp4';
  }

  @override
  Future<void> cancel() async => cancelled = true;
}

const _size = (width: 16, height: 16, ratio: 1.0);
const _days = ['2026-11-06', '2026-11-07', '2026-11-08'];

void main() {
  late _FakeEncoder encoder;
  late TerritoryVideoController video;
  late int shown;

  setUp(() {
    encoder = _FakeEncoder();
    video = TerritoryVideoController(encoder);
    shown = -1;
  });

  Future<String?> run({Future<bool> Function(String)? showDay, Future<Uint8List> Function()? capture}) {
    return video.export(
      path: '/tmp/out.mp4',
      size: _size,
      days: _days,
      showDay: showDay ?? (day) async => (shown = _days.indexOf(day)) >= 0,
      captureFrame: capture ?? () async => Uint8List.fromList([shown]),
    );
  }

  test('every day is a frame and the last one is held', () async {
    final path = await run();
    expect(path, '/tmp/out.mp4');
    expect(encoder.frames, [0, 1, 2, 2, 2]);
    expect(video.progress, 1);
    expect(video.exporting, isFalse);
  });

  test('cancelling stops between days and drops the file', () async {
    video.begin();
    final path = await run(
      showDay: (day) async {
        shown = _days.indexOf(day);
        if (shown == 1) video.cancel();
        return true;
      },
    );
    expect(path, isNull);
    expect(encoder.cancelled, isTrue);
    expect(encoder.finished, isFalse);
    expect(encoder.frames, [0]);
  });

  test('a cancel while the last frames go in still stops it', () async {
    final path = await run(
      capture: () async {
        if (shown == 2) video.cancel();
        return Uint8List.fromList([shown]);
      },
    );
    expect(path, isNull);
    expect(encoder.finished, isFalse);
  });

  test('a cancel before the export starts is not lost', () async {
    video.begin();
    video.cancel();
    expect(await run(), isNull);
    expect(encoder.frames, isEmpty);
  });

  test('a cancel with nothing running does not hit the next export', () async {
    video.cancel();
    expect(await run(), '/tmp/out.mp4');
  });

  test('a map that cannot show the day cancels', () async {
    expect(await run(showDay: (day) async => day == _days.first), isNull);
    expect(encoder.cancelled, isTrue);
  });

  test('a failure cleans up and is reported', () async {
    await expectLater(run(capture: () async => throw StateError('no frame')), throwsStateError);
    expect(encoder.cancelled, isTrue);
    expect(video.exporting, isFalse);
  });
}
