import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/app_orientations.dart';

void main() {
  test('portrait only unless rotation is allowed', () {
    expect(appOrientations(allowRotation: false), [DeviceOrientation.portraitUp]);
    expect(
      appOrientations(allowRotation: true),
      unorderedEquals([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  });
}
