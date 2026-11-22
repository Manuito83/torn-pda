import 'package:flutter/services.dart';

const landscapeOrientations = [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];

List<DeviceOrientation> appOrientations({required bool allowRotation}) {
  return allowRotation ? DeviceOrientation.values : const [DeviceOrientation.portraitUp];
}
