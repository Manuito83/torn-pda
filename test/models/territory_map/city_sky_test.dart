import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_sky.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';

void main() {
  test('a cloud fades out before it wraps round', () {
    final around = surroundingsFromGzip(File('assets/territory_map/surroundings-v1.json.bin').readAsBytesSync());
    final cloud = buildSky(around, fullOutside).clouds.first;
    // World x reaches the far end here
    final wrap = (10800 - cloud.x) / cloud.speed;
    expect(cloudAt(cloud, wrap - 0.5, around).alpha, lessThan(0.01));
    expect(cloudAt(cloud, wrap + 0.5, around).alpha, lessThan(0.01));
    expect(cloudAt(cloud, wrap - 1600 / cloud.speed, around).alpha, greaterThan(0.1));
  });
}
