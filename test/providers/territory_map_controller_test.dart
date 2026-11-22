import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/providers/city_item_prices.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_share_controller.dart';
import 'package:torn_pda/providers/territory_timelapse_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/territory_map/territory_map_files.dart';
import 'package:torn_pda/widgets/territory_map/city_map_layer.dart';

import '../models/territory_map/sample_data.dart';

final _shapes = readGzip('test/models/territory_map/fixtures/territories-sectors-1-2.json.gz');

Uint8List _state(int owner, {int shapesVersion = 1, String rackets = '{}'}) => utf8.encode(
  '{"format": 1, "generated_at": 1000, "territories_version": $shapesVersion, "read_at": {},'
  ' "ownership": {"AAA": [$owner, 0, 0]}, "wars": [], "rackets": $rackets, "factions": {}, "bombs": []}',
);

// Time bar paints every 250 ms
Future<void> _paintWait() => Future<void>.delayed(const Duration(milliseconds: 300));

class _History extends TerritoryHistoryController {
  _History(TerritoryMapFiles files) : super(files: files);

  final _record = MapHistory(
    year: DateTime.now().year,
    generatedAt: DateTime.now().toUtc(),
    completeFrom: DateTime.now().toUtc().subtract(const Duration(days: 5)),
    wars: const [],
    owners: const [],
    rackets: const [],
    bombs: const [],
    factions: const {},
  );

  @override
  MapHistory? get record => _record;

  @override
  Future<void> loadYears() async {}
}

class _Files extends TerritoryMapFiles {
  final disk = <String, Uint8List>{};
  final shapes = <int, Uint8List>{};
  Uint8List? next;
  bool brokenShapes = false;
  Completer<void>? holdState;

  @override
  Future<Uint8List?> readCached(String name) async => disk[name];

  @override
  Future<void> writeCached(String name, Uint8List bytes) async => disk[name] = bytes;

  @override
  Future<Uint8List> readBundledTerritories() async {
    if (brokenShapes) throw StateError('shapes unreadable');
    return utf8.encode(_shapes);
  }

  @override
  Future<TerritoryFile> decodeTerritories(Uint8List bytes) async => parseTerritoryFile(utf8.decode(bytes));

  @override
  Future<MapState> decodeState(Uint8List bytes) async => parseMapState(utf8.decode(bytes));

  @override
  Future<({Uint8List? bytes, String etag})> fetchState(String etag) async {
    await holdState?.future;
    return (bytes: next, etag: 'etag');
  }

  @override
  Future<Uint8List> fetchTerritories(int version) async => shapes[version]!;

  @override
  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchHistory(int year, String etag) async => null;

  @override
  Future<({Uint8List? bytes, String etag, bool immutable})?> fetchChanges(String day, String etag) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late _Files files;
  late TerritoryMapController controller;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('territory_map_test');
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
    await Prefs().setTerritoryMapVersion(0);
    await Prefs().setTerritoryMapStateEtag('');
    await Prefs().setTerritoryMapView('');
    await Prefs().setTerritoryMapStateSavedAt(DateTime.now().millisecondsSinceEpoch);
    files = _Files();
    controller = TerritoryMapController(files: files);
    await controller.open(files, myFactionId: 0);
    controller.close(files);
    files.next = _state(12);
    await controller.refresh();
  });

  test('304 keeps the state', () async {
    final before = controller.state;
    files.next = null;
    await controller.refresh();
    expect(controller.state, same(before));
    expect(controller.state!.ownership['AAA']!.factionId, 12);
    expect(controller.lastError, isNull);
  });

  test('a broken download keeps the previous state', () async {
    files.next = utf8.encode('broken');
    await controller.refresh();
    expect(controller.state!.ownership['AAA']!.factionId, 12);
    expect(controller.lastError, isNotNull);
    expect(files.disk[stateFileName], _state(12));
  });

  test('shapes that fail to load can be retried', () async {
    final broken = _Files()..brokenShapes = true;
    final map = TerritoryMapController(files: broken);
    await map.open(broken, myFactionId: 0);
    map.close(broken);
    expect(map.ready, isFalse);
    expect(map.lastError, isNotNull);

    broken
      ..brokenShapes = false
      ..next = _state(12);
    await map.retry();
    expect(map.ready, isTrue);
    expect(map.lastError, isNull);
    expect(map.state!.ownership['AAA']!.factionId, 12);
  });

  test('the first download is visible while it runs', () async {
    final slow = _Files()..next = _state(12);
    final map = TerritoryMapController(files: slow);
    await map.open(slow, myFactionId: 0);
    map.close(slow);
    slow.holdState = Completer();
    var told = false;
    map.addListener(() => told = told || map.refreshing);
    final refreshing = map.refresh();
    expect(map.refreshing, isTrue);
    expect(told, isTrue);

    slow.holdState!.complete();
    await refreshing;
    expect(map.refreshing, isFalse);
  });

  test('a routine refresh does not rebuild before it has news', () async {
    files
      ..next = null
      ..holdState = Completer();
    var notified = 0;
    controller.addListener(() => notified++);
    final refreshing = controller.refresh();
    expect(notified, 0);
    files.holdState!.complete();
    await refreshing;
  });

  test('a new shapes version is saved and shown', () async {
    final newer = jsonDecode(_shapes) as Map<String, dynamic>..['version'] = 2;
    files.shapes[2] = utf8.encode(jsonEncode(newer));
    files.next = _state(12, shapesVersion: 2);
    await controller.refresh();
    expect(controller.territories!.version, 2);
    expect(files.disk[territoriesFileName(2)], files.shapes[2]);
    expect(await Prefs().getTerritoryMapVersion(), 2);
  });

  test('a city page stops the timelapse and keeps the present', () async {
    final day = DateTime.utc(2026, 11, 1);
    final timelapse = TerritoryTimelapseController(controller, TerritoryHistoryController(files: files))..start();
    controller.showPast(day, {'AAA': owned(99)});
    expect(controller.displayOwnership['AAA']!.factionId, 99);

    controller.openCity(files);
    expect(timelapse.open, isFalse);
    expect(controller.displayOwnership['AAA']!.factionId, 12);
    controller.showPast(day, {'AAA': owned(99)});
    expect(controller.displayOwnership['AAA']!.factionId, 12);

    controller.closeCity(files);
    controller.showPast(day, {'AAA': owned(99)});
    expect(controller.displayOwnership['AAA']!.factionId, 99);
  });

  group('city frame', () {
    late _History history;
    late TerritoryTimelapseController page;
    late TerritoryTimelapseController frame;
    final frameKey = Object();

    setUp(() {
      history = _History(files);
      page = TerritoryTimelapseController(controller, history);
      frame = TerritoryTimelapseController(controller, history, inCity: true);
    });

    tearDown(() {
      frame.dispose();
      page.dispose();
    });

    test('opening closes the page time bar', () async {
      page.start();
      page.select(0);
      await _paintWait();
      expect(controller.pastDay, isNotNull);

      controller.openCity(frameKey);
      expect(page.open, isFalse);
      expect(controller.pastDay, isNull);
    });

    test('page cannot paint over the frame', () async {
      controller.openCity(frameKey);
      frame.start();
      frame.select(0);
      await _paintWait();
      final day = controller.pastDay;
      expect(day, isNotNull);

      controller.showPast(DateTime.utc(2026, 11, 1), {'AAA': owned(77)});
      expect(controller.pastDay, day);

      frame.select(frame.days.length - 1);
      await _paintWait();
      expect(controller.pastDay, isNull);
    });

    test('closing returns to the present', () async {
      final closing = TerritoryTimelapseController(controller, history, inCity: true);
      controller.openCity(frameKey);
      closing.start();
      closing.select(0);
      await _paintWait();
      expect(controller.pastDay, isNotNull);
      var told = 0;
      controller.addListener(() => told++);

      closing.dispose();
      controller.closeCity(frameKey);
      expect(controller.pastDay, isNull);
      expect(controller.overCity, isFalse);

      WidgetsBinding.instance.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance.handleDrawFrame();
      expect(told, 1);
    });

    test('prices arriving late do not lose the item being picked up', () async {
      final tapped = CityItem(id: 1, lat: 10, lng: 10);
      final page = CityPageData(
        time: DateTime.utc(2026, 11, 8),
        owners: {},
        irradiated: {},
        rackets: {},
        sites: [],
        items: [tapped],
      );
      final prices = CityItemPrices(() async => [Item(name: 'Knife', marketValue: 500)..id = '1']);
      addTearDown(prices.dispose);
      final layer = CityMapLayer(page, controller, prices: prices);
      addTearDown(layer.dispose);
      expect(layer.items.single.price, isNull);

      await prices.load(['1']);
      expect(layer.items.single.price?.value, 500);
      expect(layer.hitTest(tapped.point, 1), isNotNull);

      layer.removeItem(tapped);
      expect(layer.items, isEmpty);
    });

    test('items hide on a past day and return at Now', () async {
      final item = CityItem(id: 1, lat: 10, lng: 10);
      final page = CityPageData(
        time: DateTime.utc(2026, 11, 8),
        owners: {},
        irradiated: {},
        rackets: {},
        sites: [],
        items: [item],
      );
      final layer = CityMapLayer(page, controller);
      addTearDown(layer.dispose);
      expect(layer.hitTest(item.point, 1), same(item));

      controller.openCity(frameKey);
      frame.start();
      frame.select(0);
      await _paintWait();
      expect(layer.hitTest(item.point, 1), isNull);

      frame.select(frame.days.length - 1);
      await _paintWait();
      expect(layer.hitTest(item.point, 1), same(item));
    });
  });

  test('a new racket with the same owners repaints only where it shows', () async {
    const racket = '{"AAA": {"faction_id": 12, "name": "R", "level": 1, "reward": "", "changed_at": 1000}}';
    final normal = controller.dataVersion;
    files.next = _state(12, rackets: racket);
    await controller.refresh();
    expect(controller.dataVersion, normal);

    controller.setView(MapView.rackets);
    final rackets = controller.dataVersion;
    files.next = _state(12);
    await controller.refresh();
    expect(controller.dataVersion, rackets + 1);
    expect(controller.shades, isEmpty);
  });

  test('a past day shows no rackets of today', () {
    controller.setView(MapView.rackets);
    controller.showPast(DateTime.utc(2026, 11, 1), {'AAA': owned(99)});
    expect(controller.shownView, MapView.normal);
    expect(controller.shades, isNull);
  });

  test('a shared view is not saved and goes away with the map', () async {
    controller.setView(MapView.rackets);
    controller.showTemporarily(view: MapView.war, span: ActivitySpan.month, locks: false, names: true);
    expect(controller.view, MapView.war);
    expect(controller.showLocks, isFalse);
    expect(await Prefs().getTerritoryMapView(), MapView.rackets.name);
    expect(await Prefs().getTerritoryMapShowLocks(), isTrue);

    controller.restoreSwitches();
    expect(controller.view, MapView.rackets);
    expect(controller.showLocks, isTrue);
    expect(controller.factionNames, isFalse);
    expect(controller.activitySpan, ActivitySpan.week);
  });

  test('a shared view moves the span only in the activity view and skips unknown territories', () {
    final share = TerritoryShareController();
    final span = controller.activitySpan;
    const area = Rect.fromLTWH(0, 0, 100, 100);

    share.show(
      const SharedMapView(camera: area, view: MapView.war, span: ActivitySpan.month, territory: 'ZZZ'),
      controller,
    );
    expect(controller.activitySpan, span);
    expect(controller.selected, isNull);

    final code = controller.territories!.territories.keys.first;
    share.show(SharedMapView(camera: area, view: MapView.activity, span: ActivitySpan.month, territory: code), controller);
    expect(controller.activitySpan, ActivitySpan.month);
    expect(controller.selected, code);
    expect(share.cameraRequest, 2);
  });

  test('the map on top answers the share, a missing one means not ready', () {
    final share = TerritoryShareController();
    Rect? top = const Rect.fromLTWH(0, 0, 200, 300);
    Rect? under() => const Rect.fromLTWH(0, 0, 50, 50);
    Rect? above() => top;

    expect(share.capture(controller), isNull);
    share.addReader(under);
    share.addReader(above);
    expect(share.capture(controller)!.camera, const Rect.fromLTWH(0, 0, 200, 300));

    top = null;
    expect(share.capture(controller), isNull);
    share.removeReader(above);
    expect(share.capture(controller)!.camera, const Rect.fromLTWH(0, 0, 50, 50));
  });

  test('a choice made over a shared view is the one that stays', () async {
    controller.showTemporarily(view: MapView.war, span: ActivitySpan.week, locks: false, names: true);
    controller.setView(MapView.irradiated);
    controller.toggleFactionNames();
    expect(await Prefs().getTerritoryMapView(), MapView.irradiated.name);

    controller.restoreSwitches();
    expect(controller.view, MapView.irradiated);
    expect(controller.factionNames, isFalse);
    expect(controller.showLocks, isTrue);
  });
}
