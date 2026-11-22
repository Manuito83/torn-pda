import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';

import 'sample_data.dart';

void main() {
  Racket racket(String code, int? money) => Racket(
    territory: code,
    factionId: 7,
    name: 'Racket',
    level: 1,
    reward: '',
    changedAt: scoreTime,
    rewardItem: money == null ? null : RewardItem(type: RewardType.money, id: 0, name: '', quantity: money, price: 1),
  );

  test('racketScale: rounded quantiles, repeats merged', () {
    final rackets = [for (var i = 1; i <= 10; i++) racket('T$i', i * 1234567)];
    expect(racketScale(rackets), [1200000, 3700000, 6100000, 8600000, 11000000]);
    expect(racketScale([racket('A', 500), racket('B', 500), racket('C', null)]), [500]);
  });

  test('rackets view: value step spread over the ramp', () {
    final rackets = {
      'LOW': racket('LOW', 1000),
      'MID': racket('MID', 50000),
      'TOP': racket('TOP', 4000000),
      'NONE': racket('NONE', null),
    };
    final shades = viewShades(
      MapView.rackets,
      ownership: const {},
      wars: const [],
      rackets: rackets,
      territories: const {},
    )!;
    expect(shades['LOW'], (kind: ShadeKind.ramp, step: 0));
    expect(shades['MID'], (kind: ShadeKind.ramp, step: 2));
    expect(shades['TOP'], (kind: ShadeKind.ramp, step: 4));
    expect(shades['NONE'], (kind: ShadeKind.ramp, step: 0));
  });

  test('war view keeps every territory of the factions at war', () {
    final ownership = {'AAA': owned(1), 'BBB': owned(2), 'CCC': owned(2), 'DDD': owned(9)};
    final shades = viewShades(
      MapView.war,
      ownership: ownership,
      wars: [liveWar()],
      rackets: const {},
      territories: const {},
    )!;
    expect(shades.keys, unorderedEquals(['AAA', 'BBB', 'CCC']));
  });

  test('respect view: every territory on the ramp by daily respect', () {
    final territories = {
      for (final (code, respect) in [('AAA', 15), ('BBB', 15), ('CCC', 45), ('DDD', 66), ('EEE', 140)])
        code: territory(code, const [], respect: respect),
    };
    final shades = viewShades(
      MapView.respect,
      ownership: const {},
      wars: const [],
      rackets: const {},
      territories: territories,
    )!;
    expect([for (final code in territories.keys) shades[code]!.step], [0, 0, 1, 3, 4]);
  });

  test('irradiated view lights only the irradiated', () {
    final ownership = {'AAA': owned(1), 'BBB': Ownership(factionId: 1, acquiredAt: null, irradiated: true)};
    final shades = viewShades(
      MapView.irradiated,
      ownership: ownership,
      wars: const [],
      rackets: const {},
      territories: const {},
    )!;
    expect(shades, {'BBB': (kind: ShadeKind.irradiated, step: 0)});
  });

  test('borderedMine leaves out wars and grey views', () {
    final mine = ['AAA', 'BBB', 'CCC'];
    final wars = [liveWar(code: 'BBB')];
    expect(borderedMine(mine, wars, null), ['AAA', 'CCC']);
    final shades = {'AAA': (kind: ShadeKind.faction, step: 0), 'CCC': (kind: ShadeKind.ramp, step: 2)};
    expect(borderedMine(mine, wars, shades), ['AAA']);
  });

  test('activitySpots: live and ended assaults in the span, by territory', () {
    final now = scoreTime;
    final live = liveWar(code: 'AAA', id: 10);
    final ended = [
      endedWar(code: 'AAA', endedAt: now.subtract(const Duration(days: 1)), id: 11),
      endedWar(code: 'AAA', endedAt: now.subtract(const Duration(days: 2)), id: 12),
      endedWar(code: 'BBB', endedAt: now.subtract(const Duration(days: 12)), id: 13),
      endedWar(code: 'CCC', endedAt: now.subtract(const Duration(days: 40)), id: 14),
      endedWar(code: 'AAA', endedAt: now, id: 10),
    ];

    expect(activitySpots(ActivitySpan.now, now, current: [live], ended: ended), [
      (code: 'AAA', assaults: 1, last: live.start),
    ]);
    expect(activitySpots(ActivitySpan.week, now, current: [live], ended: ended), [
      (code: 'AAA', assaults: 3, last: live.start),
    ]);
    final month = activitySpots(ActivitySpan.month, now, current: [live], ended: ended);
    expect([for (final s in month) (s.code, s.assaults)], [('AAA', 3), ('BBB', 1)]);
  });

  test('spotAlpha: older assaults fade over the span, live ones do not', () {
    final now = scoreTime;
    final halfWeek = now.subtract(const Duration(hours: 84));
    expect(spotAlpha(now, now, ActivitySpan.week), 0.85);
    expect(spotAlpha(halfWeek, now, ActivitySpan.week), closeTo(0.625, 0.001));
    expect(spotAlpha(now.subtract(const Duration(days: 30)), now, ActivitySpan.week), closeTo(0.4, 0.001));
    expect(spotAlpha(halfWeek, now, ActivitySpan.now), 0.85);
  });
}
