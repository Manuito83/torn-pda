import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/city_map_options.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('city_map_options_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await Prefs().setCityMapShowPanel(true);
    await Prefs().setCityMapShowItems(true);
    await Prefs().setCityEnabled(true);
  });

  test('City Finder off in the map hides the items', () async {
    final options = CityMapOptions();
    await options.load();
    options.togglePanel();
    expect(options.panelVisible, isFalse);
    expect(options.itemsVisible, isFalse);
    options.dispose();
  });

  test('the panel choice is saved', () async {
    final first = CityMapOptions();
    await first.load();
    first.togglePanel();
    first.dispose();

    final second = CityMapOptions();
    await second.load();
    expect(second.showPanel, isFalse);
    second.dispose();
  });

  test('City Finder off in the app hides the panel and the items', () async {
    await Prefs().setCityEnabled(false);
    final options = CityMapOptions();
    await options.load();
    expect(options.panelVisible, isFalse);
    expect(options.itemsVisible, isFalse);
    options.dispose();
  });
}
