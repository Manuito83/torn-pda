import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

Map<String, dynamic> _state({List<String> voted = const [], bool canWrite = true}) => {
  'canWrite': canWrite,
  'reason': canWrite ? null : 'not_verified',
  'playerId': 7,
  'votedIds': voted,
};

void main() {
  test('failed vote is undone', () async {
    final answer = Completer<int>();
    var on = true;
    final deltas = <int>[];
    final controller = FeedbackAccountController(
      loadState: (_) async => _state(),
      vote: (id, wanted) {
        on = wanted;
        return answer.future;
      },
    );
    await controller.load(['a']);

    final done = controller.toggleVote('a', onDelta: deltas.add);
    expect(controller.isVoted('a'), isTrue);
    expect(on, isTrue);
    expect(deltas, [1]);

    answer.completeError(const FeedbackCallError('rate_limited'));
    await expectLater(done, throwsA(isA<FeedbackCallError>()));
    expect(controller.isVoted('a'), isFalse);
    expect(deltas, [1, -1]);
  });

  test('removing a vote shifts the count down', () async {
    final deltas = <int>[];
    final controller = FeedbackAccountController(
      loadState: (_) async => _state(voted: ['a']),
      vote: (_, _) async => 3,
    );
    await controller.load(['a']);

    expect(await controller.toggleVote('a', onDelta: deltas.add), 3);
    expect(deltas, [-1]);
  });

  test('second tap is ignored', () async {
    final calls = <bool>[];
    final answer = Completer<int>();
    final controller = FeedbackAccountController(
      loadState: (_) async => _state(voted: ['a']),
      vote: (_, wanted) {
        calls.add(wanted);
        return answer.future;
      },
    );
    await controller.load(['a']);

    final first = controller.toggleVote('a');
    expect(await controller.toggleVote('a'), isNull);
    answer.complete(4);
    expect(await first, 4);
    expect(calls, [false]);
    expect(controller.isVoted('a'), isFalse);
  });

  test('a player who cannot write is stopped with the server reason', () async {
    var called = false;
    final controller = FeedbackAccountController(
      loadState: (_) async => _state(canWrite: false),
      vote: (_, _) async {
        called = true;
        return 1;
      },
    );
    await controller.load(['a']);

    await expectLater(
      controller.toggleVote('a'),
      throwsA(isA<FeedbackCallError>().having((e) => e.reason, 'reason', 'not_verified')),
    );
    expect(called, isFalse);
  });

  test('ids that arrive during a load are asked after it', () async {
    final first = Completer<Map<String, dynamic>>();
    final asked = <List<String>>[];
    final controller = FeedbackAccountController(
      loadState: (ids) {
        asked.add(ids);
        return asked.length == 1 ? first.future : Future.value(_state());
      },
    );

    final loading = controller.load(['a']);
    await controller.load(['b']);
    first.complete(_state());
    await loading;
    expect(asked, [
      ['a'],
      ['b'],
    ]);
  });

  test('ids go in batches of fifty', () async {
    final sizes = <int>[];
    final controller = FeedbackAccountController(
      loadState: (ids) async {
        sizes.add(ids.length);
        return _state();
      },
    );

    await controller.load([for (var i = 0; i < 120; i++) 'id$i']);
    expect(sizes, [50, 50, 20]);
  });

  test('state is asked once per id and a failed ask is tried again', () async {
    final asked = <List<String>>[];
    var fail = true;
    final controller = FeedbackAccountController(
      loadState: (ids) async {
        asked.add(ids);
        if (fail) throw const FeedbackCallError('unavailable');
        return _state();
      },
    );

    await controller.load(['a']);
    fail = false;
    await controller.load(['a', 'b']);
    await controller.load(['a', 'b']);
    expect(asked, [
      ['a'],
      ['a', 'b'],
    ]);
  });

  test('unlock and lock', () async {
    final until = DateTime.now().add(const Duration(hours: 1));
    final controller = FeedbackAccountController(
      loadState: (_) async => {..._state(), 'isModerator': true},
      unlock: (_) async => until,
    );
    await controller.load([]);
    expect(controller.unlocked, isFalse);

    await controller.unlock('123456');
    expect(controller.unlocked, isTrue);

    controller.markLocked();
    expect(controller.unlocked, isFalse);
  });

  test('pin calls tell whether there is a pin', () async {
    var answer = 'pin_required';
    final controller = FeedbackAccountController(
      loadState: (_) async => _state(),
      setPin: (_, _) async => throw FeedbackCallError(answer),
      removePin: (_) async {},
    );
    await controller.load([]);
    expect(controller.account.hasPin, isNull);

    await expectLater(controller.setPin('123456'), throwsA(isA<FeedbackCallError>()));
    expect(controller.account.hasPin, isTrue);

    await controller.removePin('123456');
    expect(controller.account.hasPin, isFalse);

    answer = 'too_many';
    await expectLater(controller.setPin('123456'), throwsA(isA<FeedbackCallError>()));
    expect(controller.account.hasPin, isFalse);

    await controller.load(['a']);
    expect(controller.account.hasPin, isFalse);
  });
}
