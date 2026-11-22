import 'package:intl/intl.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

// Null when the reward has no price
int? racketDailyValue(Racket racket) {
  final item = racket.rewardItem;
  return item == null ? null : item.quantity * item.price;
}

String racketRewardText(Racket racket) {
  final value = racketDailyValue(racket);
  if (value == null || racket.rewardItem?.type == RewardType.money) return racket.reward;
  return '${racket.reward} - about \$${NumberFormat('#,##0', 'en_US').format(value)}/day at market price';
}

int respectEarned(int respectPerDay, DateTime acquiredAt, DateTime now) =>
    now.isAfter(acquiredAt) ? now.difference(acquiredAt).inDays * respectPerDay : 0;

({int respect, int money}) factionIncome(int factionId, MapState state, Map<String, Territory> territories) {
  var respect = 0;
  state.ownership.forEach((code, row) {
    if (row.factionId == factionId) respect += territories[code]?.respect ?? 0;
  });
  var money = 0;
  for (final racket in state.rackets.values) {
    if (racket.factionId == factionId) money += racketDailyValue(racket) ?? 0;
  }
  return (respect: respect, money: money);
}

List<Racket> topRackets(MapState state, {int limit = 30}) {
  final priced = state.rackets.values.where((r) => racketDailyValue(r) != null).toList()
    ..sort((a, b) {
      final byValue = racketDailyValue(b)!.compareTo(racketDailyValue(a)!);
      return byValue != 0 ? byValue : a.territory.compareTo(b.territory);
    });
  return priced.take(limit).toList();
}

// Racket money a day by faction
List<({int factionId, int money})> topFactionIncome(MapState state, {int limit = 30}) {
  final money = <int, int>{};
  for (final racket in state.rackets.values) {
    final value = racketDailyValue(racket);
    if (value == null || racket.factionId == 0) continue;
    money.update(racket.factionId, (v) => v + value, ifAbsent: () => value);
  }
  final rows = [for (final e in money.entries) (factionId: e.key, money: e.value)]
    ..sort((a, b) => b.money != a.money ? b.money.compareTo(a.money) : a.factionId.compareTo(b.factionId));
  return rows.take(limit).toList();
}
