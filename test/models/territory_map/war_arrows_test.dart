import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/war_arrows.dart';

import 'sample_data.dart';

void main() {
  final territories = sectorsOneAndTwo().territories;
  final war = liveWar(code: 'AAD', attackers: 1);

  group('assaultOrigin', () {
    test('nearest neighbor of the aggressor', () {
      final origin = assaultOrigin(war, territories, {'RYD': owned(1), 'NBD': owned(1), 'WZD': owned(2)});
      expect(origin, (code: 'NBD', adjacent: true));
    });

    test('nearest territory when none touches the target', () {
      final origin = assaultOrigin(war, territories, {'UKE': owned(1), 'AFE': owned(1), 'NBD': owned(2)});
      expect(origin, (code: 'UKE', adjacent: false));
    });

    test('none when the aggressor holds nothing', () {
      expect(assaultOrigin(war, territories, {'NBD': owned(2)}), isNull);
    });
  });

  group('assaultMomentum', () {
    test('by walls and time left', () {
      expect(assaultMomentum(liveWar(attackers: 3, defenders: 1), scoreTime), AssaultMomentum.advancing);
      expect(assaultMomentum(liveWar(attackers: 2, defenders: 1), scoreTime), AssaultMomentum.slow);
      expect(assaultMomentum(liveWar(attackers: 2, defenders: 2), scoreTime), AssaultMomentum.blocked);
      expect(assaultMomentum(liveWar(defenders: 2), scoreTime), AssaultMomentum.stalled);
    });

    test('stalled when nobody attacked for an hour', () {
      final idle = WarIdle(
        noAttackersSince: scoreTime.subtract(const Duration(hours: 2)),
        scoreChangedAt: scoreTime.subtract(const Duration(hours: 2)),
      );
      expect(assaultMomentum(liveWar(attackers: 3, idle: idle), scoreTime), AssaultMomentum.stalled);
    });

    test('an empty wall is not idle in the first hour', () {
      final fresh = liveWar(defenders: 2);
      expect(assaultMomentum(fresh, fresh.start.add(const Duration(minutes: 10))), AssaultMomentum.slow);
    });
  });

  group('assaultProgress', () {
    test('score share of the target', () {
      expect(assaultProgress(liveWar(score: 75000, target: 300000), scoreTime), closeTo(0.25, 1e-9));
      expect(assaultProgress(liveWar(target: 300000), scoreTime), 0);
    });

    test('moves on with the wall pace since the last score', () {
      final soon = scoreTime.add(const Duration(minutes: 10));
      final war = liveWar(score: 30000, attackers: 3, defenders: 1, target: 300000);
      expect(assaultProgress(war, soon), closeTo((30000 + 10 * 120) / 300000, 1e-9));
    });

    test('never past the target', () {
      expect(assaultProgress(liveWar(score: 400000, target: 300000), scoreTime), 1);
    });
  });

  group('arrowShape', () {
    test('grows with the arrow and stays within bounds', () {
      final short = arrowShape(30);
      final medium = arrowShape(60);
      final long = arrowShape(2000);
      expect(short.width, 4);
      expect(medium.width, greaterThan(short.width));
      expect(long.width, 11);
      expect(long.headWidth, greaterThan(long.width));
    });
  });

  test('assaults on unknown territories get no arrow', () {
    final state = MapState(
      generatedAt: scoreTime,
      territoriesVersion: 1,
      readAt: const {},
      ownership: {'NBD': owned(1)},
      wars: [
        war,
        liveWar(code: 'ZZZ', attackers: 1),
      ],
      rackets: const {},
      factions: const {},
      bombs: const [],
    );
    final arrows = assaultArrows(state, territories, scoreTime);
    expect([for (final a in arrows) (a.from, a.to)], [('NBD', 'AAD')]);
  });
}
