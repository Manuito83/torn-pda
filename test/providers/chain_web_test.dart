import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';

class SlowApi extends ApiCallerController {
  var answer = Completer<dynamic>();
  int calls = 0;

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
  }) {
    calls++;
    return answer.future;
  }
}

Map<String, dynamic> apiChain(int current, int timeout, {int cooldown = 0}) => {
  'chain': {'current': current, 'max': 250, 'timeout': timeout, 'modifier': 1.1, 'cooldown': cooldown, 'start': 0},
};

void main() {
  final t = DateTime(2026, 10, 25, 18);
  late SlowApi api;
  late ChainStatusController chain;
  late DateTime now;
  late bool onScreen;
  late bool Function() page;

  void fromPage({required int current, required int timeout, required DateTime at}) {
    chain.applyWebChain(onScreen: page, {
      'current': current,
      'max': 250,
      'timeout': timeout,
      'cooldown': 0,
      'active': true,
      'ts': at.millisecondsSinceEpoch,
      'store': true,
    });
  }

  void fromAttack({required int current, required int timeout, required DateTime at}) {
    chain.applyWebChain(onScreen: page, {
      'current': current,
      'max': null,
      'timeout': timeout,
      'cooldown': null,
      'active': current > 0 && timeout > 0,
      'ts': at.millisecondsSinceEpoch,
      'store': true,
      'attack': true,
    });
  }

  Future<void> fromApi(Map<String, dynamic> answer) async {
    api.answer = Completer()..complete(answer);
    await chain.getChainStatus();
  }

  setUp(() {
    Get.reset();
    api = Get.put<ApiCallerController>(SlowApi()) as SlowApi;
    chain = Get.put(ChainStatusController());
    now = t;
    chain.clock = () => now;
    onScreen = true;
    page = () => onScreen;
  });

  tearDown(() => Get.delete<ChainStatusController>(force: true));

  test('a Torn page sets hits and time left', () {
    fromPage(current: 120, timeout: 200, at: t.subtract(const Duration(milliseconds: 500)));

    expect(chain.modelError, isFalse);
    expect(chain.chainModel!.chain!.current, 120);
    expect(chain.currentSecondsCounter, 200);
    expect(chain.currentChainTimeString, '03:20');
  });

  test('time left counts from the page reading, not from ticks', () {
    fromPage(current: 120, timeout: 200, at: t);
    now = t.add(const Duration(seconds: 13, milliseconds: 400));

    expect(chain.currentSecondsCounter, 187);
  });

  test('an API answer asked before the page reading never overrides it', () async {
    final pending = chain.getChainStatus();
    now = t.add(const Duration(seconds: 2));
    fromPage(current: 120, timeout: 280, at: now);
    now = t.add(const Duration(seconds: 20));
    api.answer.complete(apiChain(100, 290));
    await pending;

    expect(chain.chainModel!.chain!.current, 120);
  });

  test('the API takes over again after 15 s without the page', () async {
    fromPage(current: 120, timeout: 280, at: t);
    now = t.add(const Duration(seconds: 1));
    api.answer.complete(apiChain(119, 290));
    await chain.getChainStatus();
    expect(chain.chainModel!.chain!.current, 120);

    now = t.add(const Duration(seconds: 16));
    api.answer = Completer()..complete(apiChain(125, 270));
    await chain.getChainStatus();
    expect(chain.chainModel!.chain!.current, 125);
    expect(chain.currentSecondsCounter, 270);
  });

  test('a page that does not show the timer leaves the last reading', () {
    fromPage(current: 120, timeout: 280, at: t);
    chain.applyWebChain(onScreen: page, {
      'current': 121,
      'max': 250,
      'timeout': null,
      'cooldown': 0,
      'active': true,
      'ts': t.millisecondsSinceEpoch + 500,
    });

    expect(chain.chainModel!.chain!.current, 120);
    expect(chain.currentSecondsCounter, 280);
  });

  test('cooldown counts down from the page reading', () {
    chain.applyWebChain(onScreen: page, {
      'current': 115,
      'max': 115,
      'timeout': 0,
      'cooldown': 519,
      'active': false,
      'ts': t.millisecondsSinceEpoch,
    });
    expect(chain.currentChainTimeString, '00:08:39');

    now = t.add(const Duration(seconds: 10));
    expect(chain.currentSecondsCounter, 509);
  });

  test('the chat sees a live chain without the chain widget open', () {
    fromPage(current: 120, timeout: 200, at: t);
    now = t.add(const Duration(seconds: 5));
    final live = ChatFactionOps.chainOf(chain)!;
    expect(live.hits, 120);
    expect(live.seconds, 195);

    now = t.add(const Duration(seconds: 16));
    expect(ChatFactionOps.chainOf(chain), isNull);
  });

  test('a page out of sight is ignored', () {
    onScreen = false;
    fromPage(current: 120, timeout: 200, at: t);

    expect(chain.chainModel, isNull);
  });

  testWidgets('losing sight of the page hands over to the API at once', (tester) async {
    fromPage(current: 120, timeout: 200, at: t);
    expect(chain.webLive, isTrue);

    onScreen = false;
    now = t.add(const Duration(seconds: 3));
    expect(chain.webLive, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(api.calls, 1);
    expect(chain.currentSecondsCounter, 197);

    api.answer.complete(apiChain(121, 300));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(chain.chainModel!.chain!.current, 121);
    expect(chain.currentSecondsCounter, 300);
  });

  testWidgets('a cached API answer older than the page does not replace it', (tester) async {
    fromPage(current: 120, timeout: 290, at: t);
    onScreen = false;
    now = t.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    api.answer.complete(apiChain(118, 100));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(chain.chainModel!.chain!.current, 120);
    expect(chain.currentSecondsCounter, 287);
  });

  testWidgets('a fresh API answer arriving late with the same hits is applied', (tester) async {
    fromPage(current: 120, timeout: 290, at: t);
    onScreen = false;
    now = t.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    now = t.add(const Duration(seconds: 15));
    api.answer.complete(apiChain(120, 280));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(chain.chainModel!.chain!.timeout, 280);
    expect(chain.currentSecondsCounter, 275);
  });

  testWidgets('an expired page anchor accepts a dropped chain', (tester) async {
    fromPage(current: 120, timeout: 290, at: t);
    onScreen = false;
    now = t.add(const Duration(seconds: 291));
    await tester.pump(const Duration(seconds: 1));

    api.answer.complete(apiChain(0, 0));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(chain.chainModel!.chain!.current, 0);
  });

  test('a Torn page without the chain bar hands over at once', () {
    fromPage(current: 120, timeout: 200, at: t);
    chain.applyWebChain({'none': true}, onScreen: page);

    expect(chain.webLive, isFalse);
    expect(api.calls, 1);
  });

  test('another page without the chain bar does not stop the live one', () {
    fromPage(current: 120, timeout: 200, at: t);
    chain.applyWebChain({'none': true}, onScreen: () => true);

    expect(chain.webLive, isTrue);
    expect(api.calls, 0);
  });

  test('a late message from another tab is ignored', () {
    fromPage(current: 121, timeout: 300, at: t);
    fromPage(current: 120, timeout: 250, at: t.subtract(const Duration(seconds: 2)));

    expect(chain.chainModel!.chain!.current, 121);
  });

  group('attack page', () {
    test('takes hits and time and keeps the max from the API', () async {
      await fromApi(apiChain(100, 290));
      fromAttack(current: 120, timeout: 200, at: t);

      expect(chain.webLive, isTrue);
      expect(chain.chainModel!.chain!.current, 120);
      expect(chain.chainModel!.chain!.max, 250);
      expect(chain.currentSecondsCounter, 200);
    });

    test('past the API max it moves to the next bonus', () async {
      await fromApi(apiChain(248, 290));
      fromAttack(current: 251, timeout: 300, at: t);

      expect(chain.chainModel!.chain!.max, 500);
    });

    test('waits for the API before showing anything', () {
      fromAttack(current: 120, timeout: 200, at: t);

      expect(chain.chainModel, isNull);
      expect(chain.webLive, isFalse);
    });

    test('a dropped chain hands over to the API once', () async {
      await fromApi(apiChain(100, 290));
      fromAttack(current: 120, timeout: 200, at: t);
      final calls = api.calls;
      chain.applyWebChain({'none': true}, onScreen: page);
      chain.applyWebChain({'none': true}, onScreen: page);

      expect(chain.webLive, isFalse);
      expect(api.calls, calls + 1);
    });

    test('a new chain after a cooldown does not keep the old max', () async {
      await fromApi(apiChain(823, 0, cooldown: 2527));
      fromAttack(current: 5, timeout: 300, at: t);

      expect(chain.chainModel!.chain!.max, 10);
      expect(chain.chainModel!.chain!.cooldown, 0);
    });

    test('no chain on the page leaves the API cooldown alone', () async {
      await fromApi(apiChain(823, 0, cooldown: 4800));
      chain.applyWebChain({'none': true}, onScreen: page);

      expect(chain.webLive, isFalse);
      expect(chain.chainModel!.chain!.cooldown, 4800);
      expect(chain.chainModel!.chain!.current, 823);
    });

    test('a page that disagrees with the API wins while fresh', () async {
      await fromApi(apiChain(100, 290));
      fromAttack(current: 130, timeout: 280, at: t);
      now = t.add(const Duration(seconds: 1));
      await fromApi(apiChain(125, 200));

      expect(chain.chainModel!.chain!.current, 130);
    });
  });

  group('switched off from Remote Config', () {
    test('the page reading is dropped and the API takes over', () {
      fromPage(current: 120, timeout: 200, at: t);
      chain.webLiveAllowed = false;

      expect(chain.webLive, isFalse);
      expect(ChatFactionOps.chainOf(chain), isNull);
      expect(api.calls, 1);
    });

    test('readings that arrive afterwards are ignored', () {
      chain.webLiveAllowed = false;
      fromPage(current: 120, timeout: 200, at: t);

      expect(chain.chainModel, isNull);
      expect(chain.webLive, isFalse);
    });

    test('an API answer is not held back by the dropped reading', () async {
      fromPage(current: 120, timeout: 200, at: t);
      chain.webLiveAllowed = false;
      api.answer.complete(apiChain(100, 290));
      await chain.getChainStatus();

      expect(chain.chainModel!.chain!.current, 100);
    });

    test('switching it back on accepts readings again', () {
      chain.webLiveAllowed = false;
      chain.webLiveAllowed = true;
      fromPage(current: 120, timeout: 200, at: t);

      expect(chain.webLive, isTrue);
    });
  });
}
