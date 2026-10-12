import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';

class FakeApiCaller extends ApiCallerController {
  final calls = <ApiSelection_v1>[];
  Future<dynamic> Function(ApiSelection_v1 selection, String? prefix)? handler;

  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  Future<dynamic> enqueueApiCall<T>({
    ApiSelection_v1? apiSelection,
    String? prefix = '',
    int limit = 100,
    int? from,
    // ignore: non_constant_identifier_names
    ApiSelection_v2? apiSelection_v2,
    dynamic apiCall,
    String? forcedApiKey = '',
  }) async {
    calls.add(apiSelection!);
    return handler?.call(apiSelection, prefix) ?? ApiError(errorId: 100);
  }
}

class FakeChain extends ChainStatusController {
  bool watcher = false;

  @override
  bool get watcherActive => watcher;
}

class FakeSettings extends SettingsProvider {
  @override
  bool pipEnabled = true;
  @override
  bool pipChainButton = true;
  @override
  bool pipPlayerButtons = true;
  @override
  bool pipStakeoutsButton = true;
  @override
  bool pipAutoEnter = false;
  @override
  List<String> showCases = [];

  @override
  set addShowCase(String showCase) => showCases.add(showCase);
}

const pipChannel = MethodChannel('tornpda.pip');

Future<void> fromNative(String method, [dynamic arguments]) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    pipChannel.name,
    pipChannel.codec.encodeMethodCall(MethodCall(method, arguments)),
    (_) {},
  );
}

Map<String, dynamic> profileJson({required String state, String name = 'Target'}) => {
  'signup': '2020-01-01 00:00:00',
  'name': name,
  'life': <String, dynamic>{},
  'status': <String, dynamic>{'state': state, 'description': 'desc $state', 'color': 'green', 'until': 0},
  'job': <String, dynamic>{},
  'faction': <String, dynamic>{},
  'married': <String, dynamic>{},
  'basicicons': <String, dynamic>{},
  'states': <String, dynamic>{},
  'last_action': <String, dynamic>{},
};

Map<String, dynamic> chainJson({int current = 0, int timeout = 0, int cooldown = 0}) => {
  'chain': <String, dynamic>{
    'current': current,
    'max': 10,
    'timeout': timeout,
    'modifier': 1.0,
    'cooldown': cooldown,
    'start': 0,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiCaller api;
  late PipController pip;
  late ChainStatusController chain;

  setUp(() {
    Get.reset();
    api = Get.put<ApiCallerController>(FakeApiCaller()) as FakeApiCaller;
    chain = Get.put(ChainStatusController());
    pip = Get.put(PipController());
  });

  tearDown(() {
    chain.deactivateStatus();
    pip.onClose();
    Get.reset();
  });

  group('player window', () {
    Future<void> watch(List<int> ids) => pip.watchPlayers([for (final id in ids) PipPlayer(id: id, name: 'P$id')]);

    PipPlayer player(int id) => pip.players.firstWhere((p) => p.id == id);

    setUp(() => pip.inPip.value = true);

    test('first response does not highlight', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1]);
      expect(player(1).state, 'Okay');
      expect(player(1).changedAt, isNull);
      expect(player(1).highlighted, isFalse);
    });

    test('state change highlights', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1]);
      api.handler = (_, _) async => profileJson(state: 'Hospital');
      await watch([1]);
      expect(player(1).state, 'Hospital');
      expect(player(1).highlighted, isTrue);
    });

    test('same state does not highlight', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1]);
      await watch([1]);
      expect(player(1).highlighted, isFalse);
    });

    test('highlight expires after 30 seconds', () {
      final p = PipPlayer(id: 1, name: 'A');
      p.changedAt = DateTime.now().subtract(const Duration(seconds: 29));
      expect(p.highlighted, isTrue);
      p.changedAt = DateTime.now().subtract(const Duration(seconds: 31));
      expect(p.highlighted, isFalse);
    });

    test('failed fetch flags error and keeps last state', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1]);
      api.handler = null;
      await watch([1]);
      expect(player(1).error, isTrue);
      expect(player(1).state, 'Okay');
      expect(player(1).highlighted, isFalse);
    });

    test('late response of an unwatched player is discarded', () async {
      final late = Completer<dynamic>();
      api.handler = (_, prefix) => prefix == '1' ? late.future : Future.value(profileJson(state: 'Okay', name: 'Two'));
      final first = watch([1]);
      await watch([2]);
      expect(pip.players.map((p) => p.id), [2]);

      late.complete(profileJson(state: 'Hospital', name: 'One'));
      await first;

      expect(pip.players.map((p) => p.id), [2]);
      expect(player(2).name, 'Two');
      expect(player(2).state, 'Okay');
    });

    test('no more than four players', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1, 2, 3, 4, 5, 6]);
      expect(pip.players.map((p) => p.id), [1, 2, 3, 4]);
    });

    test('four players are fetched every round', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1, 2, 3, 4]);
      expect(api.calls.length, 4);
    });

    test('players already watched keep their state', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1]);
      final kept = player(1);
      api.handler = (_, _) async => profileJson(state: 'Hospital');
      await watch([1, 2]);
      expect(identical(player(1), kept), isTrue);
      expect(player(1).highlighted, isTrue);
      expect(player(2).highlighted, isFalse);
    });

    test('reopening the window does not reuse the old state', () async {
      api.handler = (_, _) async => profileJson(state: 'Hospital');
      await watch([1]);
      pip.inPip.value = false;
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await watch([1]);
      expect(player(1).state, 'Okay');
      expect(player(1).highlighted, isFalse);
    });

    testWidgets('a round is skipped while the previous one runs', (tester) async {
      final pending = Completer<dynamic>();
      api.handler = (_, _) => pending.future;
      final opening = pip.watchPlayers([PipPlayer(id: 1, name: 'A')]);
      await tester.pump(const Duration(seconds: 25));
      expect(api.calls.length, 1);
      pending.complete(profileJson(state: 'Okay'));
      await opening;
      pip.onClose();
    });

    test('only the one that changes is highlighted', () async {
      api.handler = (_, _) async => profileJson(state: 'Hospital');
      await watch([1, 2, 3]);
      api.handler = (_, prefix) async => profileJson(state: prefix == '2' ? 'Okay' : 'Hospital');
      await watch([1, 2, 3]);
      expect(pip.players.where((p) => p.highlighted).map((p) => p.id), [2]);
      expect(pip.profilePlayer?.id, 2);
    });

    test('sorted by who gets out first', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      pip.players = [
        PipPlayer(id: 1, name: 'Long')
          ..state = 'Hospital'
          ..until = now + 3000,
        PipPlayer(id: 2, name: 'Jail')
          ..state = 'Jail'
          ..until = now + 500,
        PipPlayer(id: 3, name: 'Free')..state = 'Okay',
        PipPlayer(id: 4, name: 'Short')
          ..state = 'Hospital'
          ..until = now + 60,
        PipPlayer(id: 5, name: 'Away')..state = 'Traveling',
      ];
      expect(pip.sortedPlayers.map((p) => p.id), [3, 5, 4, 2, 1]);
    });

    test('Profile with one player, or the last one that changed', () {
      pip.players = [PipPlayer(id: 1, name: 'A')];
      expect(pip.profilePlayer?.id, 1);
      pip.players = [PipPlayer(id: 1, name: 'A'), PipPlayer(id: 2, name: 'B'), PipPlayer(id: 3, name: 'C')];
      expect(pip.profilePlayer, isNull);
      pip.players[0].changedAt = DateTime.now().subtract(const Duration(seconds: 5));
      pip.players[2].changedAt = DateTime.now();
      expect(pip.profilePlayer?.id, 3);
    });
  });

  group('failed entry', () {
    test('player entry leaves inPip false', () async {
      api.handler = (_, _) async => profileJson(state: 'Okay');
      await pip.watchPlayers([PipPlayer(id: 1, name: 'A')]);
      expect(pip.inPip.value, isFalse);
    });

    test('chain entry leaves inPip false and releases the chain', () async {
      api.handler = (selection, _) async => selection == ApiSelection_v1.chainStatus ? chainJson() : ApiError();
      await pip.openChain();
      expect(pip.inPip.value, isFalse);
      expect(chain.pipVisible, isFalse);
      expect(chain.statusActive, isFalse);
    });
  });

  group('chain polling client', () {
    setUp(() {
      api.handler = (selection, _) async => selection == ApiSelection_v1.chainStatus ? chainJson() : ApiError();
    });

    test('idle chain switches polling off without pip', () async {
      await chain.activateChainWidgetStatusRequests();
      expect(chain.statusActive, isFalse);
    });

    test('pip window counts as a client', () async {
      chain.pipVisible = true;
      await chain.activateChainWidgetStatusRequests();
      expect(chain.statusActive, isTrue);
      chain.tryToDeactivateStatus();
      expect(chain.statusActive, isTrue);
    });

    test('leaving pip switches polling off when nobody else uses it', () async {
      chain.pipVisible = true;
      await chain.activateChainWidgetStatusRequests();
      chain.pipVisible = false;
      chain.tryToDeactivateStatus();
      expect(chain.statusActive, isFalse);
    });

    test('leaving pip keeps polling while the chain widget is visible', () async {
      chain.pipVisible = true;
      chain.widgetVisible = true;
      await chain.activateChainWidgetStatusRequests();
      chain.pipVisible = false;
      chain.tryToDeactivateStatus();
      expect(chain.statusActive, isTrue);
    });

    test('opening the chain window does not switch polling off', () async {
      chain.pipVisible = true;
      await chain.activateChainWidgetStatusRequests();
      expect(chain.pipVisible, isTrue);
      expect(chain.statusActive, isTrue);
    });
  });

  group('status color in pip', () {
    const laChannel = MethodChannel('test.liveactivity');
    var travelActive = false;
    var racingActive = false;

    int barsCalls() => api.calls.where((c) => c == ApiSelection_v1.barsAndPlayerStatus).length;

    setUp(() {
      travelActive = false;
      racingActive = false;
      Get.put(LiveActivityBridgeController(channel: laChannel));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(laChannel, (
        call,
      ) async {
        if (call.method == 'isAnyTravelActivityActive') return travelActive;
        if (call.method == 'isAnyRacingActivityActive') return racingActive;
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(laChannel, null);
    });

    test('outside pip it always fetches', () async {
      await chain.getOrSetStatus();
      expect(barsCalls(), 1);
    });

    test('in pip without live activities it skips', () async {
      pip.inPip.value = true;
      await chain.getOrSetStatus();
      expect(barsCalls(), 0);
    });

    test('in pip with a travel live activity it fetches', () async {
      pip.inPip.value = true;
      travelActive = true;
      await chain.getOrSetStatus();
      expect(barsCalls(), 1);
    });

    test('in pip with a racing live activity it fetches', () async {
      pip.inPip.value = true;
      racingActive = true;
      await chain.getOrSetStatus();
      expect(barsCalls(), 1);
    });
  });

  group('stakeout alerts', () {
    test('default settings', () {
      final settings = SettingsProvider();
      expect(settings.pipEnabled, isTrue);
      expect(settings.pipChainButton, isTrue);
      expect(settings.pipPlayerButtons, isTrue);
      expect(settings.pipStakeoutsButton, isTrue);
      expect(settings.pipAutoEnter, isFalse);
    });

    test('alert outside pip is kept as last alert without banner', () {
      pip.stakeoutAlert(id: 4, name: 'Test', lines: ['Test is now OK!']);
      expect(pip.stakeoutId, 4);
      expect(pip.stakeoutName, 'Test');
      expect(pip.stakeoutLines, ['Test is now OK!']);
      expect(pip.stakeoutAt, isNotNull);
      expect(pip.stakeoutHighlighted, isTrue);
      expect(pip.stakeoutCount, 1);
      expect(pip.bannerVisible, isFalse);
    });

    test('alerts during the highlight are counted', () {
      pip.stakeoutAlert(id: 4, name: 'A', lines: ['A is online!']);
      pip.stakeoutAlert(id: 5, name: 'B', lines: ['B has landed!']);
      expect(pip.stakeoutCount, 2);
      expect(pip.stakeoutId, 5);
      expect(pip.stakeoutName, 'B');
    });

    test('count restarts after the highlight', () {
      pip.stakeoutAlert(id: 4, name: 'A', lines: ['A is online!']);
      pip.stakeoutChangedAt = DateTime.now().subtract(const Duration(seconds: 31));
      expect(pip.stakeoutHighlighted, isFalse);
      pip.stakeoutAlert(id: 5, name: 'B', lines: ['B has landed!']);
      expect(pip.stakeoutCount, 1);
    });

    test('banner over the chain and player windows', () {
      pip.inPip.value = true;
      for (final mode in [PipMode.chain, PipMode.player]) {
        pip.mode = mode;
        pip.bannerAt = null;
        pip.stakeoutAlert(id: 4, name: 'Test', lines: ['Test is now OK!']);
        expect(pip.bannerVisible, isTrue, reason: mode.name);
      }
    });

    test('no banner in the stakeouts window', () {
      pip.inPip.value = true;
      pip.mode = PipMode.stakeouts;
      pip.stakeoutAlert(id: 4, name: 'Test', lines: ['Test is now OK!']);
      expect(pip.bannerAt, isNull);
      expect(pip.stakeoutHighlighted, isTrue);
    });

    test('banner goes away after 10 seconds', () {
      pip.bannerAt = DateTime.now().subtract(const Duration(seconds: 9));
      expect(pip.bannerVisible, isTrue);
      pip.bannerAt = DateTime.now().subtract(const Duration(seconds: 11));
      expect(pip.bannerVisible, isFalse);
    });

    test('opening stakeouts releases the chain', () async {
      api.handler = (selection, _) async => selection == ApiSelection_v1.chainStatus ? chainJson() : ApiError();
      chain.pipVisible = true;
      await chain.activateChainWidgetStatusRequests();
      await pip.openStakeouts(players: 3);
      expect(pip.mode, PipMode.stakeouts);
      expect(pip.stakeoutPlayers, 3);
      expect(chain.pipVisible, isFalse);
      expect(chain.statusActive, isFalse);
    });
  });

  group('auto entry', () {
    late FakeChain watcherChain;
    late FakeSettings settings;
    final autoCalls = <Map<Object?, Object?>>[];

    setUp(() {
      Get.reset();
      api = Get.put<ApiCallerController>(FakeApiCaller()) as FakeApiCaller;
      api.handler = (selection, _) async => selection == ApiSelection_v1.chainStatus ? chainJson() : ApiError();
      watcherChain = Get.put<ChainStatusController>(FakeChain()) as FakeChain;
      chain = watcherChain;
      pip = Get.put(PipController());
      pip.supported = true;
      settings = FakeSettings();
      autoCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pipChannel, (
        call,
      ) async {
        if (call.method == 'autoEnter') autoCalls.add(call.arguments as Map<Object?, Object?>);
        return null;
      });
    });

    tearDown(() {
      watcherChain.onClose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pipChannel, null);
    });

    Future<void> pumpApp(WidgetTester tester) {
      return tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
        ),
      );
    }

    testWidgets('off by default even with the watcher on', (tester) async {
      await pumpApp(tester);
      watcherChain.watcher = true;
      pip.syncAutoEnter();
      expect(autoCalls.last['enabled'], isFalse);
    });

    testWidgets('setting on without the watcher stays off', (tester) async {
      await pumpApp(tester);
      settings.pipAutoEnter = true;
      pip.syncAutoEnter();
      expect(autoCalls.last['enabled'], isFalse);
    });

    testWidgets('setting and watcher on arm it with the chain buttons', (tester) async {
      await pumpApp(tester);
      settings.pipAutoEnter = true;
      watcherChain.watcher = true;
      pip.syncAutoEnter();
      expect(autoCalls.last['enabled'], isTrue);
      expect(autoCalls.last['actions'], [
        {'id': 'open', 'title': 'Open PDA'},
      ]);
    });

    testWidgets('general switch off disarms it', (tester) async {
      await pumpApp(tester);
      settings.pipAutoEnter = true;
      watcherChain.watcher = true;
      pip.syncAutoEnter();
      settings.pipEnabled = false;
      pip.syncAutoEnter();
      expect(autoCalls.last['enabled'], isFalse);
    });

    testWidgets('follows the watcher through chain updates', (tester) async {
      await pumpApp(tester);
      settings.pipAutoEnter = true;
      watcherChain.watcher = true;
      watcherChain.update();
      expect(autoCalls.last['enabled'], isTrue);
      watcherChain.watcher = false;
      watcherChain.update();
      expect(autoCalls.last['enabled'], isFalse);
    });

    testWidgets('same state is sent once', (tester) async {
      await pumpApp(tester);
      settings.pipAutoEnter = true;
      watcherChain.watcher = true;
      pip.syncAutoEnter();
      pip.syncAutoEnter();
      watcherChain.update();
      expect(autoCalls.length, 1);
    });

    testWidgets('unsupported devices never arm it', (tester) async {
      await pumpApp(tester);
      pip.supported = false;
      settings.pipAutoEnter = true;
      watcherChain.watcher = true;
      pip.syncAutoEnter();
      expect(autoCalls, isEmpty);
    });

    testWidgets('native auto entry opens the chain window', (tester) async {
      await pumpApp(tester);
      pip.mode = PipMode.player;
      await fromNative('autoEntering');
      await tester.pump();
      expect(pip.inPip.value, isTrue);
      expect(pip.mode, PipMode.chain);
      expect(watcherChain.pipVisible, isTrue);
      expect(watcherChain.statusActive, isTrue);
      watcherChain.onClose();
    });

    testWidgets('system entry without the early notice also opens the chain', (tester) async {
      await pumpApp(tester);
      pip.mode = PipMode.stakeouts;
      await fromNative('changed', true);
      await tester.pump();
      expect(pip.inPip.value, isTrue);
      expect(pip.mode, PipMode.chain);
      expect(watcherChain.pipVisible, isTrue);
      watcherChain.onClose();
    });

    testWidgets('leaving the window arms it again', (tester) async {
      await pumpApp(tester);
      settings.pipAutoEnter = true;
      watcherChain.watcher = true;
      pip.syncAutoEnter();
      await fromNative('autoEntering');
      pip.syncAutoEnter();
      expect(autoCalls.length, 1);

      final leaving = fromNative('changed', false);
      await tester.pump(const Duration(milliseconds: 1100));
      await leaving;
      expect(pip.inPip.value, isFalse);
      expect(watcherChain.pipVisible, isFalse);
      expect(autoCalls.length, 2);
      expect(autoCalls.last['enabled'], isTrue);
      watcherChain.onClose();
    });
  });
}
