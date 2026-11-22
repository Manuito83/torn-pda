import 'dart:math' as math;

const videoFps = 2;
const videoBitrate = 4000000;

// Extra frames that hold the last day
const videoFinalHold = 2;

const _rangeChoices = [7, 14, 30];
const _maxWidth = 1080;

// Encoder level 4.1 tops out near 1920
const _maxHeight = 1920;

// Rows stay aligned in the encoder buffers
const _widthStep = 16;
const _minAndroidSdk = 26;

bool canShareVideo({required bool isAndroid, required bool isIos, required int androidSdk}) =>
    isIos || (isAndroid && androidSdk >= _minAndroidSdk);

// Day counts to offer
List<int> videoRangeOptions(int recordedDays) => [
  ..._rangeChoices.where((n) => n <= recordedDays),
  if (recordedDays > 1 && recordedDays < _rangeChoices.last && !_rangeChoices.contains(recordedDays)) recordedDays,
];

// The last days, oldest first
List<String> videoDays(List<String> days, int range) => days.sublist(math.max(0, days.length - range));

typedef VideoSize = ({int width, int height, double ratio});

// Ratio is pixels per map unit
VideoSize videoSize({required double mapWidth, required double mapHeight, required double footer}) {
  final tall = (mapHeight + footer) / mapWidth;
  final fitting = math.min(_maxWidth.toDouble(), _maxHeight / tall);
  final width = fitting ~/ _widthStep * _widthStep;
  final ratio = width / mapWidth;
  final height = math.min(((mapHeight + footer) * ratio / 2).ceil() * 2, _maxHeight);
  return (width: width, height: height, ratio: ratio);
}

String videoFileName(String firstDay, String lastDay) =>
    'territory_map_${firstDay.replaceAll('-', '')}_${lastDay.replaceAll('-', '')}.mp4';
