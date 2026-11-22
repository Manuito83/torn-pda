import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/territory_view_facts.dart';

import 'sample_data.dart';

void main() {
  final now = scoreTime;
  final tAAA = territory('AAA', const [], respect: 40);
  final territories = {'AAA': tAAA, 'BBB': territory('BBB', const [])};

  MapState state({
    List<TerritoryWar> wars = const [],
    Map<String, Racket> rackets = const {},
    List<DirtyBomb> bombs = const [],
  }) => MapState(
    generatedAt: now,
    territoriesVersion: 1,
    readAt: const {},
    ownership: const {},
    wars: wars,
    rackets: rackets,
    factions: const {},
    bombs: bombs,
  );

  ViewFacts? facts(
    MapView view,
    MapState state, {
    ActivitySpan span = ActivitySpan.week,
    List<RecentWar> ended = const [],
    bool irradiated = false,
    DateTime? pastDay,
  }) => territoryViewFacts(
    view,
    territory: tAAA,
    territories: territories,
    state: state,
    span: span,
    now: now,
    ended: ended,
    irradiated: irradiated,
    pastDay: pastDay,
    date: (at) => '${at.day}/${at.month}',
    faction: (id) => 'F$id',
  );

  test('activity: assaults of the span on this territory, newest first', () {
    final live = liveWar(code: 'AAA', id: 10);
    final ended = [
      endedWar(code: 'AAA', endedAt: now.subtract(const Duration(days: 2)), id: 11, result: WarResult.successAssault),
      endedWar(code: 'AAA', endedAt: now.subtract(const Duration(days: 20)), id: 12),
      endedWar(code: 'BBB', endedAt: now.subtract(const Duration(days: 1)), id: 13),
    ];

    final week = facts(MapView.activity, state(wars: [live]), ended: ended)!;
    expect([for (final l in week.lines.skip(1)) l.warId], [10, 11]);

    final month = facts(
      MapView.activity,
      state(wars: [live]),
      span: ActivitySpan.month,
      ended: ended,
    )!;
    expect([for (final l in month.lines.skip(1)) l.warId], [10, 11, 12]);
  });

  test('activity: nothing in the span gives no assault lines', () {
    final none = facts(MapView.activity, state(), span: ActivitySpan.now)!;
    expect(none.lines.where((l) => l.warId != null), isEmpty);
  });

  test('rackets: the racket here, or none', () {
    final racket = Racket(
      territory: 'AAA',
      factionId: 1,
      name: 'Gambling',
      level: 3,
      reward: '5 Xanax',
      changedAt: now,
      rewardItem: RewardItem(type: RewardType.item, id: 1, name: 'Xanax', quantity: 5, price: 800000),
    );
    final here = facts(MapView.rackets, state(rackets: {'AAA': racket}))!;
    expect(here.lines.map((l) => l.text), ['Gambling (level 3)', '5 Xanax - about \$4,000,000/day at market price']);
    expect(facts(MapView.rackets, state())!.lines, hasLength(1));
  });

  group('irradiated follows what the map shows', () {
    final detonated = DateTime.utc(2026, 11, 3, 12);
    final bomb = DirtyBomb(id: 1, detonatedAt: detonated, factionId: 4, respectLost: 0, territories: const ['AAA']);
    bool hasBomb(ViewFacts facts) => facts.lines.any((l) => l.text.startsWith('Bomb by'));

    test('lit today: the bomb', () {
      expect(hasBomb(facts(MapView.irradiated, state(bombs: [bomb]), irradiated: true)!), isTrue);
    });

    test('over today: no bomb even inside the 7 day window', () {
      expect(hasBomb(facts(MapView.irradiated, state(bombs: [bomb]))!), isFalse);
    });

    test('a day before the bomb: no bomb, though the map had it lit then', () {
      final before = facts(
        MapView.irradiated,
        state(bombs: [bomb]),
        irradiated: true,
        pastDay: DateTime.utc(2026, 11, 2),
      );
      expect(hasBomb(before!), isFalse);
    });

    test('the day of the bomb: the bomb', () {
      final that = facts(
        MapView.irradiated,
        state(bombs: [bomb]),
        irradiated: true,
        pastDay: DateTime.utc(2026, 11, 3),
      );
      expect(hasBomb(that!), isTrue);
    });
  });

  test('sector counts the territories in it', () {
    expect(facts(MapView.sector, state())!.lines.single.text, contains('2 territories'));
  });
}
