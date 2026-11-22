import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/faction_targets.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

import 'sample_data.dart';

void main() {
  test('open first, then daily value, then code', () {
    final now = DateTime.utc(2026, 11, 7, 12);
    final territories = {
      for (final t in [
        territory('AAA', ['AAB', 'BBB', 'CCC', 'DDD']),
        territory('AAB', ['AAA', 'EEE']),
        territory('BBB', ['AAA'], respect: 10, slots: 4),
        territory('CCC', ['AAA'], respect: 5),
        territory('DDD', ['AAA'], respect: 50),
        territory('EEE', ['AAB'], respect: 10),
      ])
        t.code: t,
    };
    final state = MapState(
      generatedAt: now,
      territoriesVersion: 1,
      readAt: const {},
      ownership: {'AAA': owned(7), 'AAB': owned(7), 'BBB': owned(8), 'CCC': owned(9), 'DDD': owned(8)},
      wars: const [],
      rackets: {
        'CCC': Racket(
          territory: 'CCC',
          factionId: 9,
          name: 'Bootleg Distillery I',
          level: 1,
          reward: '10x Bottle of Moonshine daily',
          changedAt: now,
          rewardItem: RewardItem(
            type: RewardType.item,
            id: 206,
            name: 'Bottle of Moonshine',
            quantity: 10,
            price: 100000,
          ),
        ),
      },
      factions: const {},
      bombs: const [],
      recentWars: [endedWar(code: 'DDD', endedAt: now.subtract(const Duration(hours: 10)))],
    );

    final targets = factionTargets(7, state, territories, now);
    expect(targets.map((t) => t.code), ['CCC', 'BBB', 'EEE', 'DDD']);
    expect(targets.first.racketValue, 1000000);
    expect(targets[1].target, 200000);
    expect(targets[2].ownerId, 0);
    expect(targets.last.lockedUntil, now.add(const Duration(hours: 62)));
  });
}
