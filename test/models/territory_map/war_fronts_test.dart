import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/war_fronts.dart';

import 'sample_data.dart';

void main() {
  final territories = sectorsOneAndTwo().territories;
  final since = scoreTime.subtract(frontDays);

  Conquest conquest(String code, int hoursAgo, {int faction = 1}) =>
      (code: code, factionId: faction, at: scoreTime.subtract(Duration(hours: hoursAgo)));

  List<(String, String?)> steps(WarFront front) => [for (final s in front.steps) (s.code, s.from)];

  test('chains conquests of neighboring territories', () {
    final fronts = warFronts([conquest('RYD', 20), conquest('UKE', 10), conquest('XOE', 5)], territories);
    expect(fronts, hasLength(1));
    expect(steps(fronts.single), [('RYD', null), ('UKE', 'RYD'), ('XOE', 'RYD')]);
  });

  test('a conquest next to two fronts joins the newer one', () {
    final fronts = warFronts([conquest('UKE', 30), conquest('WZD', 20), conquest('RYD', 10)], territories);
    expect(steps(fronts.single), [('WZD', null), ('RYD', 'WZD')]);
  });

  test('other factions and lone conquests stay out', () {
    final fronts = warFronts([conquest('RYD', 20), conquest('SYD', 15, faction: 2), conquest('AFE', 10)], territories);
    expect(fronts, isEmpty);
  });

  test('newest front first', () {
    final fronts = warFronts([
      conquest('RYD', 30),
      conquest('UKE', 25),
      conquest('ADF', 20, faction: 2),
      conquest('FCF', 2, faction: 2),
    ], territories);
    expect([for (final f in fronts) f.factionId], [2, 1]);
  });

  test('conquests from recent wars and daily changes, each war once', () {
    MapChange owner(String code, int hoursAgo, int? warId) => mapChangeFrom([
      scoreTime.subtract(Duration(hours: hoursAgo)).millisecondsSinceEpoch ~/ 1000,
      'ownership',
      code,
      'owner',
      1,
      2,
      warId,
      null,
    ]);
    RecentWar war(String code, int hoursAgo, int id, {WarResult result = WarResult.successAssault}) => endedWar(
      code: code,
      endedAt: scoreTime.subtract(Duration(hours: hoursAgo)),
      result: result,
      id: id,
    );

    final conquests = conquestsSince(
      since,
      [war('UKE', 10, 7), war('XOE', 8, 8, result: WarResult.failAssault), war('AAD', 500, 9)],
      [owner('RYD', 40, 6), owner('UKE', 10, 7), owner('SYD', 30, null), owner('WZD', 400, 5)],
    );
    expect([for (final c in conquests) c.code], ['RYD', 'UKE']);
  });
}
