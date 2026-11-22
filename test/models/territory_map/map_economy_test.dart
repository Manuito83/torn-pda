import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_economy.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

import 'sample_data.dart';

void main() {
  final now = DateTime.utc(2026, 11, 7, 12);

  Racket racket(String code, int factionId, RewardItem? item) => Racket(
    territory: code,
    factionId: factionId,
    name: 'Racket',
    level: 1,
    reward: '',
    changedAt: now,
    rewardItem: item,
  );
  RewardItem item(RewardType type, int quantity, int price) =>
      RewardItem(type: type, id: 0, name: '', quantity: quantity, price: price);

  test('racketDailyValue', () {
    expect(racketDailyValue(racket('IFE', 7, item(RewardType.item, 10, 5500))), 55000);
    expect(racketDailyValue(racket('IFE', 7, item(RewardType.points, 25, 45000))), 1125000);
    expect(racketDailyValue(racket('IFE', 7, null)), isNull);
  });

  test('respectEarned', () {
    final acquired = now.subtract(const Duration(days: 235, hours: 5));
    expect(respectEarned(28, acquired, now), 6580);
    expect(respectEarned(28, now.add(const Duration(days: 1)), now), 0);
  });

  test('income by faction', () {
    final state = MapState(
      generatedAt: now,
      territoriesVersion: 1,
      readAt: const {},
      ownership: {'AAA': owned(7), 'BBB': owned(7), 'CCC': owned(8)},
      wars: const [],
      rackets: {
        'AAA': racket('AAA', 7, item(RewardType.item, 10, 5500)),
        'BBB': racket('BBB', 7, null),
        'CCC': racket('CCC', 8, item(RewardType.money, 100000, 1)),
      },
      factions: const {},
      bombs: const [],
    );
    final territories = {
      for (final t in [territory('AAA', [], respect: 28), territory('BBB', [], respect: 12), territory('CCC', [])])
        t.code: t,
    };

    final income = factionIncome(7, state, territories);
    expect(income.respect, 40);
    expect(income.money, 55000);
    expect(topRackets(state).map((r) => r.territory), ['CCC', 'AAA']);
    expect(topFactionIncome(state), [(factionId: 8, money: 100000), (factionId: 7, money: 55000)]);
  });
}
