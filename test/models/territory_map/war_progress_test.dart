import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/war_progress.dart';

import 'sample_data.dart';

void main() {
  test('ignores the measured rate', () {
    final war = liveWar(score: 1000, attackers: 3, defenders: 1, rate: 999);
    expect(warProgressAt(war, scoreTime.add(const Duration(minutes: 10))).score, 2200);
  });

  test('no time left after the end', () {
    final war = liveWar(hoursLeft: 1);
    expect(warProgressAt(war, scoreTime.add(const Duration(hours: 3))).remaining, Duration.zero);
  });

  test('own faction first, then the soonest end', () {
    final late = liveWar(id: 1, hoursLeft: 40);
    final soon = liveWar(id: 2, hoursLeft: 5);
    final mine = liveWar(id: 3, hoursLeft: 60, aggressorId: 7);
    expect(sortedWars([late, mine, soon], 7).map((w) => w.id), [3, 2, 1]);
    expect(sortedWars([late, mine, soon], 0).map((w) => w.id), [2, 1, 3]);
  });
}
