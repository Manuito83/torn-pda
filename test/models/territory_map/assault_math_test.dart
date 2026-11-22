import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/assault_math.dart';

import 'sample_data.dart';

void main() {
  group('projectedScore', () {
    test('extrapolates with the walls', () {
      final war = liveWar(score: 1000, attackers: 3, defenders: 1);
      expect(projectedScore(war, scoreTime.add(const Duration(minutes: 10))), 1000 + 1200);
    });

    test('floor at zero and ceiling at the target', () {
      final losing = liveWar(score: 100, attackers: 1, defenders: 3);
      expect(projectedScore(losing, scoreTime.add(const Duration(minutes: 5))), 0);
      final winning = liveWar(score: 299000, attackers: 5);
      expect(projectedScore(winning, scoreTime.add(const Duration(minutes: 10))), 300000);
    });

    test('at most 15 minutes', () {
      final war = liveWar(attackers: 2);
      expect(projectedScore(war, scoreTime.add(const Duration(hours: 2))), 1800);
    });
  });

  test('timeToTarget', () {
    expect(timeToTarget(12000, 3, 1), const Duration(minutes: 100));
    expect(timeToTarget(12000, 2, 2), isNull);
    expect(timeToTarget(12000, 0, 5), isNull);
  });

  group('finishesWithin', () {
    const hours72 = Duration(hours: 72);

    test('72 hours', () {
      expect(finishesWithin(259200, 1, 0, hours72, 5), isTrue);
      expect(finishesWithin(259199, 1, 0, hours72, 5), isTrue);
      expect(finishesWithin(259201, 1, 0, hours72, 5), isFalse);
      expect(finishesWithin(1000, 3, 3, hours72, 11), isFalse);
    });

    test('both walls share the slots', () {
      expect(finishesWithin(250000, 4, 1, hours72, 5), isTrue);
      expect(finishesWithin(250000, 5, 1, hours72, 5), isFalse);
    });
  });

  group('attackersNeeded', () {
    test('within 72 hours', () {
      expect(attackersNeeded(550000, 3, const Duration(hours: 72), 11), 6);
    });

    test('under a minute left', () {
      expect(attackersNeeded(300, 0, const Duration(seconds: 30), 10), 10);
    });

    test('a full wall is not enough', () {
      expect(attackersNeeded(300, 0, const Duration(seconds: 30), 9), isNull);
      expect(attackersNeeded(550000, 6, const Duration(hours: 72), 11), isNull);
    });

    test('no time left', () {
      expect(attackersNeeded(550000, 3, Duration.zero, 11), isNull);
      expect(attackersNeeded(550000, 3, const Duration(minutes: -5), 11), isNull);
    });
  });

  group('warEnd', () {
    test('reaches the target before the deadline', () {
      final end = warEnd(liveWar(score: 288000, attackers: 3, defenders: 1));
      expect(end.reachesTarget, isTrue);
      expect(end.at, scoreTime.add(const Duration(minutes: 100)));
    });

    test('slow or negative pace keeps the scheduled end', () {
      final slow = liveWar(attackers: 1, hoursLeft: 2);
      expect(warEnd(slow).at, slow.scheduledEnd);
      expect(warEnd(slow).reachesTarget, isFalse);
      final stalled = liveWar(defenders: 20);
      expect(warEnd(stalled).at, stalled.scheduledEnd);
    });
  });
}
