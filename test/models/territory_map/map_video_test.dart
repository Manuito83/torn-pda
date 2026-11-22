import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_video.dart';

void main() {
  test('video needs Android 8 or iOS', () {
    expect(canShareVideo(isAndroid: true, isIos: false, androidSdk: 25), isFalse);
    expect(canShareVideo(isAndroid: true, isIos: false, androidSdk: 26), isTrue);
    expect(canShareVideo(isAndroid: false, isIos: true, androidSdk: 0), isTrue);
    expect(canShareVideo(isAndroid: false, isIos: false, androidSdk: 0), isFalse);
  });

  test('ranges only offer what is recorded', () {
    expect(videoRangeOptions(1), isEmpty);
    expect(videoRangeOptions(5), [5]);
    expect(videoRangeOptions(7), [7]);
    expect(videoRangeOptions(10), [7, 10]);
    expect(videoRangeOptions(14), [7, 14]);
    expect(videoRangeOptions(30), [7, 14, 30]);
    expect(videoRangeOptions(400), [7, 14, 30]);
  });

  test('the video ends on the last day', () {
    final days = ['2026-11-04', '2026-11-05', '2026-11-06', '2026-11-07', '2026-11-08'];
    expect(videoDays(days, 3), ['2026-11-06', '2026-11-07', '2026-11-08']);
    expect(videoDays(days, 30), days);
  });

  test('size is even, aligned and never too tall', () {
    for (final mapHeight in [400.0, 700.3, 900.0, 1100.0, 1500.0]) {
      final size = videoSize(mapWidth: 411.4, mapHeight: mapHeight, footer: 30);
      expect(size.width % 16, 0);
      expect(size.height.isEven, isTrue);
      expect(size.width, lessThanOrEqualTo(1080));
      expect(size.height, lessThanOrEqualTo(1920));
      expect(size.height, greaterThanOrEqualTo(((mapHeight + 30) * size.ratio).floor()));
    }
  });

  test('file name carries both days', () {
    expect(videoFileName('2026-11-01', '2026-11-08'), 'territory_map_20261101_20261108.mp4');
  });
}
