import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/assault_locks.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

import 'sample_data.dart';

void main() {
  final now = DateTime.utc(2026, 11, 7, 12);
  DateTime hoursAgo(int hours) => now.subtract(Duration(hours: hours));

  group('territoryLock', () {
    test('72 hours after a war', () {
      final ended71 = [endedWar(code: 'QFA', endedAt: hoursAgo(71))];
      final lock = territoryLock('QFA', const [], ended71, now)!;
      expect(lock.reason, LockReason.afterWar);
      expect(lock.until, now.add(const Duration(hours: 1)));
      expect(territoryLock('QFA', const [], [endedWar(code: 'QFA', endedAt: hoursAgo(73))], now), isNull);
      expect(territoryLock('BAA', const [], ended71, now), isNull);
    });

    test('ongoing assault', () {
      final war = liveWar(code: 'RCD', hoursLeft: 10);
      final lock = territoryLock('RCD', [war], const [], now)!;
      expect(lock.reason, LockReason.assault);
      expect(lock.until, war.scheduledEnd.add(const Duration(hours: 72)));
    });
  });

  group('factionLock', () {
    test('loser of a failed assault, not the defender', () {
      final wars = [endedWar(code: 'QFA', endedAt: hoursAgo(10), aggressor: 7, defender: 8)];
      expect(factionLock(7, 'QFA', wars, now), hoursAgo(10).add(const Duration(hours: 72)));
      expect(factionLock(8, 'QFA', wars, now), isNull);
      expect(factionLock(7, 'BAA', wars, now), isNull);
    });

    test('defender loses a conquest', () {
      final wars = [endedWar(code: 'QFA', endedAt: hoursAgo(10), result: WarResult.successAssault, defender: 8)];
      expect(factionLock(8, 'QFA', wars, now), isNotNull);
    });

    test('a truce has no loser', () {
      final wars = [
        endedWar(code: 'QFA', endedAt: hoursAgo(10), result: WarResult.peaceTreaty, aggressor: 7, defender: 8),
      ];
      expect(factionLock(7, 'QFA', wars, now), isNull);
      expect(factionLock(8, 'QFA', wars, now), isNull);
    });
  });

  test('lockedCodes', () {
    final state = MapState(
      generatedAt: now,
      territoriesVersion: 1,
      readAt: const {},
      ownership: const {},
      wars: [liveWar(code: 'RCD')],
      rackets: const {},
      factions: const {},
      bombs: const [],
      recentWars: [
        endedWar(code: 'QFA', endedAt: hoursAgo(71)),
        endedWar(code: 'BAA', endedAt: hoursAgo(73)),
      ],
    );
    expect(lockedCodes(state, now), {'RCD', 'QFA'});
  });
}
