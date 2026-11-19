import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_bazaar_sources.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chat/chat_bazaar_controller.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';

Map<String, dynamic> reply({bool exists = true, bool open = true}) => {
  'bazaar_timestamp': 1795110047,
  'bazaar_delay': 99999,
  'bazaar_is_open': open,
  'bazaar_exists': exists,
  'bazaar': [],
};

void main() {
  var clock = DateTime(2026, 11, 19, 12);
  late List<int> asked;
  late List<String> reports;
  late Future<dynamic> Function(int id) answer;
  var busy = false;

  ChatBazaarController make({Duration timeout = const Duration(seconds: 8)}) => ChatBazaarController(
    fetch: (id) {
      asked.add(id);
      return answer(id);
    },
    report: (source, reason) => reports.add('$source: $reason'),
    now: () => clock,
    busy: () => busy,
    timeout: timeout,
  );

  void wait(Duration d) => clock = clock.add(d);

  setUp(() {
    clock = DateTime(2026, 11, 19, 12);
    asked = [];
    reports = [];
    busy = false;
    answer = (id) async => reply();
  });

  tearDown(() {
    Get.reset();
    ChatLinkPreviews.resetForTests();
  });

  test('reads open, closed and none', () async {
    final controller = make();
    expect(await controller.state(1), ChatBazaarState.open);
    answer = (id) async => reply(open: false);
    expect(await controller.state(2), ChatBazaarState.closed);
    answer = (id) async => reply(exists: false, open: false);
    expect(await controller.state(3), ChatBazaarState.none);
  });

  group('cache', () {
    test('caches five minutes', () async {
      final controller = make();
      await controller.state(7);
      await controller.state(7);
      expect(asked, [7]);
      wait(const Duration(minutes: 5, seconds: 1));
      await controller.state(7);
      expect(asked, [7, 7]);
    });

    test('keeps at most 400 sellers', () async {
      final controller = make();
      for (var id = 1; id <= 401; id++) {
        await controller.state(id);
      }
      await controller.state(401);
      await controller.state(1);
      expect(asked.length, 402);
      expect(asked.last, 1);
    });

    test('parallel taps share the call', () async {
      final controller = make();
      final both = await Future.wait([controller.state(7), controller.state(7)]);
      expect(both, [ChatBazaarState.open, ChatBazaarState.open]);
      expect(asked, [7]);
    });

    test('remembers a failure two minutes', () async {
      answer = (id) async => ApiError(errorId: 100);
      final controller = make();
      expect(await controller.state(7), isNull);
      wait(const Duration(seconds: 110));
      expect(await controller.state(7), isNull);
      expect(asked, [7]);
      wait(const Duration(seconds: 20));
      await controller.state(7);
      expect(asked, [7, 7]);
    });

    test('forget clears and drops late answers', () async {
      final controller = make();
      await controller.state(7);
      controller.forget();
      await controller.state(7);
      expect(asked, [7, 7]);

      final slow = Completer<dynamic>();
      answer = (id) => slow.future;
      final late = controller.state(8);
      controller.forget();
      slow.complete(reply());
      expect(await late, ChatBazaarState.open);
      answer = (id) async => reply(open: false);
      expect(await controller.state(8), ChatBazaarState.closed);
    });
  });

  group('brake', () {
    test('blocks, comes back and resets', () async {
      answer = (id) async => ApiError(errorId: 17);
      final controller = make();
      await controller.state(1);
      answer = (id) async => reply();
      wait(const Duration(seconds: 30));
      expect(await controller.state(2), isNull);
      expect(asked, [1]);
      wait(const Duration(seconds: 31));
      expect(await controller.state(2), ChatBazaarState.open);
      expect(asked, [1, 2]);

      // Reset: waits one minute again
      answer = (id) async => ApiError(errorId: 17);
      await controller.state(3);
      wait(const Duration(seconds: 61));
      answer = (id) async => reply();
      expect(await controller.state(4), ChatBazaarState.open);
    });

    test('warns once per episode, on the third failure in a row', () async {
      answer = (id) async => ApiError(errorId: 17);
      final controller = make();
      await controller.state(1);
      wait(const Duration(minutes: 2));
      await controller.state(2);
      expect(reports, isEmpty);
      wait(const Duration(minutes: 6));
      await controller.state(3);
      expect(reports, ['torn_v1: torn error 17']);
      wait(const Duration(minutes: 31));
      await controller.state(4);
      expect(asked, [1, 2, 3, 4]);
      expect(reports, hasLength(1));

      // A success ends the episode
      answer = (id) async => reply();
      wait(const Duration(hours: 1));
      await controller.state(5);
      answer = (id) async => ApiError(errorId: 100);
      for (final id in [6, 7, 8]) {
        wait(const Duration(hours: 1));
        await controller.state(id);
      }
      expect(reports, ['torn_v1: torn error 17', 'torn_v1: timeout']);
    });

    test('failures at the same time count once', () async {
      final slow = Completer<dynamic>();
      answer = (id) => slow.future;
      final controller = make();
      final both = Future.wait([controller.state(1), controller.state(2)]);
      slow.complete(ApiError(errorId: 17));
      await both;
      // Twice would wait five minutes
      wait(const Duration(seconds: 61));
      answer = (id) async => reply();
      expect(await controller.state(3), ChatBazaarState.open);
    });

    test('errors of the key, the limits or the seller do not brake', () async {
      final controller = make();
      for (final code in [2, 5, 6, 14, 16, 999]) {
        answer = (id) async => ApiError(errorId: code);
        expect(await controller.state(code), isNull);
      }
      answer = (id) async => reply();
      expect(await controller.state(100), ChatBazaarState.open);
      expect(reports, isEmpty);
    });

    test('a busy app asks nothing and does not brake', () async {
      busy = true;
      final controller = make();
      expect(await controller.state(1), isNull);
      expect(asked, isEmpty);
      busy = false;
      expect(await controller.state(1), ChatBazaarState.open);
    });
  });

  group('odd answers end as unknown', () {
    // Reported on the third failure
    Future<void> expectUnknown(ChatBazaarController controller, String reason) async {
      for (final id in [1, 2, 3]) {
        wait(const Duration(hours: 1));
        expect(await controller.state(id), isNull);
      }
      expect(reports, ['torn_v1: $reason']);
    }

    for (final odd in <Object?>[
      null,
      'text',
      [1],
      <String, dynamic>{},
      {'bazaar_exists': 'yes', 'bazaar_is_open': true},
    ]) {
      test('$odd', () async {
        answer = (id) async => odd;
        final controller = make();
        await expectUnknown(controller, 'unexpected reply');
      });
    }

    test('no connection', () async {
      answer = (id) async => ApiError(errorId: 0);
      await expectUnknown(make(), 'no connection');
    });

    test('an exception', () async {
      answer = (id) async => throw StateError('down');
      final controller = make();
      await expectUnknown(controller, 'exception StateError');
    });

    test('a call that does not answer', () async {
      answer = (id) => Completer<dynamic>().future;
      final controller = make(timeout: const Duration(milliseconds: 20));
      await expectUnknown(controller, 'timeout');
    });
  });

  test('the bazaar link of another player shows the state', () async {
    ChatPlayerCards.fetch = (id) async => {
      'profile': {'id': id, 'name': 'Alpha', 'level': 5},
    };
    Get.put(make());
    final info = await ChatLinkPreviews.load(ChatLink.parse('https://www.torn.com/bazaar.php?userId=42')!, () => true);
    expect(info!.title, 'Bazaar of Alpha [42]');
    expect(info.detail, 'Open');
    expect(asked, [42]);
  });
}
