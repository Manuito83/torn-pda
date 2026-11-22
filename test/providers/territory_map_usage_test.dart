import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/alert_topics.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/sembast_db.dart';

const _setup = (
  origin: MapOrigin.menu,
  view: MapView.normal,
  names: true,
  strip: false,
  locks: false,
  cityFinder: null,
  citySites: null,
  flightsButton: false,
  flatFlights: false,
  alertsOn: false,
  alertKinds: <AlertKind>{},
  life: null,
  planes: false,
  traffic: false,
  night: false,
  gunfire: false,
  police: false,
  threeD: null,
  quality: null,
);

void main() {
  late Directory dir;
  late Map<String, int> sent;
  late TerritoryMapUsage usage;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dir = Directory.systemTemp.createTempSync('map_usage_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    dir.deleteSync(recursive: true);
  });

  setUp(() async {
    await PrefsDatabase.clearAll();
    sent = {};
    usage = TerritoryMapUsage.withSender((feature, count) async => sent[feature] = (sent[feature] ?? 0) + count);
  });

  test('two counts in a row are both kept', () async {
    usage
      ..count(mapFlightsTapFeature)
      ..count(mapFlightsTapFeature);
    await usage.sync(disabled: false);
    expect(sent, {mapFlightsTapFeature: 2});
  });

  test('open and sync send each count once', () async {
    await usage.opened(_setup);
    expect(sent, {'map_open_menu': 1, 'map_view_normal': 1, 'map_layer_names': 1});

    await Prefs().setTerritoryMapUsageDay(1);
    await usage.sync(disabled: false);
    expect(sent.values, everyElement(1));
  });
}
