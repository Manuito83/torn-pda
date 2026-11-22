import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

import 'sample_data.dart';

void main() {
  group('parseMapState', () {
    test('sample state', () {
      final state = sampleState();
      expect(state.territoriesVersion, 1);
      expect(state.ownership.length, 4108);
      expect(state.wars.length, 19);
      expect(state.factions.length, 377);
      expect(state.rackets.length, 187);
      expect(state.ownership.values.where((o) => o.irradiated).length, 14);

      final rcd = state.wars.firstWhere((w) => w.territory == 'RCD');
      expect(rcd.aggressor.factionId, 51387);
      expect(rcd.aggressor.ratePerMinute, 160);
      expect(rcd.target, 300000);
      expect(state.wars.firstWhere((w) => w.territory == 'TPE').aggressor.ratePerMinute, -14);

      final ife = state.rackets['IFE']!;
      expect(ife.factionId, 7835);
      expect(ife.name, 'Bootleg Distillery I');
      expect(state.factions[8062]!.tag, isNull);
    });

    test('null values', () {
      const json = '''
      {"format": 1, "generated_at": 1000, "territories_version": 3, "read_at": {},
       "ownership": {"AAA": [12, 0, 1]}, "wars": [], "rackets": {},
       "factions": {"12": {"name": null, "tag": null, "tag_image": null, "respect": null, "rank": null, "members": null}},
       "bombs": [{"id": 89, "detonated_at": 900, "faction_id": 12, "respect_lost": 50, "territories": ["AAA"]}]}''';
      final state = parseMapState(json);
      final aaa = state.ownership['AAA']!;
      expect(aaa.acquiredAt, isNull);
      expect(aaa.irradiated, isTrue);
      expect(state.factions[12]!.name, isNull);
      expect(state.bombs.single.territories, ['AAA']);
      expect(dataTime(state), unixTime(1000));
    });

    test('revision 2', () {
      const json = '''
      {"format": 1, "revision": 2, "generated_at": 1000, "territories_version": 1, "read_at": {}, "ownership": {},
       "wars": [
         {"id": 46843, "territory": "RCD", "start": 100, "scheduled_end": 259300, "target": 300000,
          "aggressor": {"id": 14821, "score": 0, "chain": 0, "wall": 0},
          "defender": {"id": 26312, "score": 0, "chain": 0, "wall": 20},
          "score_at": 900, "rate": {"aggressor": 0, "defender": 0},
          "idle": {"no_attackers_since": 100, "score_changed_at": 100}},
         {"id": 46844, "territory": "QFA", "start": 100, "scheduled_end": 259300, "target": 300000,
          "aggressor": {"id": 1, "score": 600, "chain": 0, "wall": 1},
          "defender": {"id": 2, "score": 0, "chain": 0, "wall": 0},
          "score_at": 900, "rate": {"aggressor": 60, "defender": 0},
          "idle": {"no_attackers_since": null, "score_changed_at": 900}}],
       "recent_wars": [
         {"id": 46801, "territory": "QFA", "start": 50, "ended_at": 800, "result": "success_assault",
          "aggressor": 36811, "defender": 9032, "score": 300000, "target": 300000},
         {"id": 46802, "territory": "BAA", "start": 50, "ended_at": 700, "result": "something_new",
          "aggressor": 1, "defender": 2, "score": 0, "target": 50000}],
       "rackets": {
         "IFE": {"faction_id": 7835, "name": "Bootleg Distillery I", "level": 1, "reward": "10x Bottle of Moonshine daily",
                 "changed_at": 500, "reward_item": {"type": "item", "id": 206, "name": "Bottle of Moonshine",
                 "quantity": 10, "price": 5500, "priced_at": "2026-11-07"}},
         "FWG": {"faction_id": 44817, "name": "Unknown", "level": 2, "reward": "???", "changed_at": 500,
                 "reward_item": null}},
       "factions": {}, "bombs": []}''';
      final state = parseMapState(json);
      expect(state.revision, 2);

      final stalled = state.wars.first.idle!;
      expect(stalled.noAttackersSince, unixTime(100));
      expect(state.wars.last.idle!.noAttackersSince, isNull);
      expect(state.wars.last.idle!.scoreChangedAt, unixTime(900));

      final conquest = state.recentWars.first;
      expect(conquest.result, WarResult.successAssault);
      expect(conquest.endedAt, unixTime(800));
      expect(conquest.aggressorId, 36811);
      expect(state.recentWars.last.result, WarResult.unknown);

      final moonshine = state.rackets['IFE']!.rewardItem!;
      expect(moonshine.type, RewardType.item);
      expect(moonshine.quantity * moonshine.price, 55000);
      expect(state.rackets['FWG']!.rewardItem, isNull);
    });

    test('revision 1 has no new keys', () {
      final state = sampleState();
      expect(state.revision, 1);
      expect(state.recentWars, isEmpty);
      expect(state.wars.every((w) => w.idle == null), isTrue);
      expect(state.rackets.values.every((r) => r.rewardItem == null), isTrue);
    });
  });

  test('sameOwners', () {
    final today = sampleState().ownership;
    final baa = today['BAA']!;
    Ownership changed({int? factionId, bool? irradiated, DateTime? acquiredAt}) => Ownership(
      factionId: factionId ?? baa.factionId,
      acquiredAt: acquiredAt ?? baa.acquiredAt,
      irradiated: irradiated ?? baa.irradiated,
    );
    expect(sameOwners(today, sampleState().ownership), isTrue);
    expect(sameOwners(today, {...today, 'BAA': changed(acquiredAt: unixTime(1))}), isTrue);
    expect(sameOwners(today, {...today, 'BAA': changed(factionId: baa.factionId + 1)}), isFalse);
    expect(sameOwners(today, {...today, 'BAA': changed(irradiated: !baa.irradiated)}), isFalse);
    expect(sameOwners(today, {...today}..remove('BAA')), isFalse);
  });

  test('a faction without territories is named from the day files', () {
    final state = sampleState();
    const gone = 999999999;
    final names = {
      gone: MapFaction(id: gone, name: 'Gone', tag: 'GON', tagImage: null, respect: null, rank: null, members: null),
    };
    expect(factionLabel(state, gone), 'Faction $gone');
    expect(factionLabel(state, gone, names: names), '[GON] Gone');
    expect(factionTag(state, gone, names: names), '[GON]');
  });

  test('dataTime and isStale', () {
    final state = sampleState();
    expect(dataTime(state), unixTime(1793826909));
    expect(isStale(state, dataTime(state).add(const Duration(minutes: 14))), isFalse);
    expect(isStale(state, dataTime(state).add(const Duration(minutes: 16))), isTrue);
  });
}
