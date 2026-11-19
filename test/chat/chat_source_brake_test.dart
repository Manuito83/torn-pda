import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_source_brake.dart';

void main() {
  final t0 = DateTime(2026, 11, 19, 12);

  test('waits follow the ladder up to the cap', () {
    var brake = const ChatBrake();
    final waits = <Duration>[];
    for (var i = 0; i < 9; i++) {
      brake = brake.failed(t0);
      waits.add(brake.retryAt!.difference(t0));
    }
    expect(waits, [...chatBrakeSteps, chatBrakeCap, chatBrakeCap, chatBrakeCap]);
  });

  test('blocks until the retry time', () {
    final brake = const ChatBrake().failed(t0);
    expect(brake.blocks(t0.add(const Duration(seconds: 59))), isTrue);
    expect(brake.blocks(t0.add(const Duration(minutes: 1))), isFalse);
    expect(const ChatBrake().blocks(t0), isFalse);
  });

  test('a longer retry after wins, a shorter one does not', () {
    final longer = const ChatBrake().failed(t0, retryAfter: const Duration(hours: 2));
    expect(longer.retryAt, t0.add(const Duration(hours: 2)));
    final shorter = const ChatBrake().failed(t0, retryAfter: const Duration(seconds: 5));
    expect(shorter.retryAt, t0.add(const Duration(minutes: 1)));
  });

  test('a huge retry after is capped', () {
    final brake = const ChatBrake().failed(t0, retryAfter: const Duration(days: 30));
    expect(brake.retryAt, t0.add(chatBrakeCap));
  });

  test('persistent is true only on the third failure in a row', () {
    var brake = const ChatBrake();
    final flags = <bool>[];
    for (var i = 0; i < 5; i++) {
      brake = brake.failed(t0);
      flags.add(brake.persistent);
    }
    expect(flags, [false, false, true, false, false]);
  });
}
