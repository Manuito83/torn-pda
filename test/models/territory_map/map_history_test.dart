import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/city_records.dart';
import 'package:torn_pda/models/territory_map/map_biography.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

import 'sample_data.dart';

void main() {
  final history = parseHistory(File('test/models/territory_map/fixtures/history-2026.json').readAsStringSync());

  test('parseHistory', () {
    expect(history.year, 2026);
    expect(history.completeFrom, DateTime.utc(2026, 11, 4));
    expect(history.wars.length, 11);
    expect(history.wars[3].endedAt, isNull);
    expect(history.wars[3].hasReport, isFalse);
    expect(classify(history.owners.first), ChangeKind.conquest);
    expect(classify(history.rackets.first), ChangeKind.racketUp);
    expect(history.bombs.single.territories, ['RFG']);
    expect(history.factions[14821]!.tag, '7DS');
  });

  test('territoryBiography', () {
    final qfa = territoryBiography(history, 'QFA');
    expect(qfa.wars.length, 9);
    expect(qfa.wars.first.id, 46400);
    expect(qfa.conquests, 2);
    expect(qfa.longestWar!.id, 46001);
    expect(qfa.longestWar!.duration, const Duration(hours: 72, minutes: 1));
    expect(qfa.owners.single.kind, 'reacquired');
  });

  test('ownerCount: current owner plus recorded owners', () {
    expect(territoryBiography(history, 'RCD', owner: 26312).ownerCount, 2);
    expect(territoryBiography(history, 'QFA', owner: 36811).ownerCount, 1);
    expect(territoryBiography(history, 'ZHB').ownerCount, 1);
  });

  test('war duration without an end', () {
    expect(history.wars.firstWhere((w) => w.id == 46150).duration, const Duration(hours: 72));
    expect(history.wars.firstWhere((w) => w.id == 46350).duration, isNull);
  });

  test('factionBiography', () {
    final envy = factionBiography(history, 14821);
    expect((envy.won, envy.lost, envy.truces), (2, 3, 1));
    expect(envy.lostOtherwise, 1);
    expect(envy.conquered, 0);

    final gluttony = factionBiography(history, 26312);
    expect((gluttony.won, gluttony.lost, gluttony.truces), (2, 2, 0));
    expect(gluttony.conquered, 1);
    expect(factionBiography(history, 36811).bombs.single.respectLost, 769315);
  });

  test('cityRecords', () {
    final ownership = {
      'QFA': Ownership(factionId: 36811, acquiredAt: DateTime.utc(2025, 3, 1), irradiated: false),
      'BAA': Ownership(factionId: 9032, acquiredAt: DateTime.utc(2024, 7, 9), irradiated: false),
      'XGG': Ownership(factionId: 0, acquiredAt: DateTime.utc(2020), irradiated: false),
    };
    final records = cityRecords(history, ownership);
    expect(records.mostAssaulted, (code: 'QFA', assaults: 9));
    expect(records.longestWar!.id, 46001);
    expect(records.oldestOwner!.code, 'BAA');
    expect(records.topConquerors.map((r) => r.factionId), [14821, 26312, 36811]);
  });

  test('mergeHistory: day files win, wars of the last year', () {
    final day = parseDayChanges(File('test/models/territory_map/fixtures/changes-2026-11-04.json').readAsStringSync());
    final merged = mergeHistory([history], [day], DateTime.utc(2027, 6))!;
    expect(merged.owners, day.changes.where((c) => c.source == 'ownership').toList());
    expect(merged.wars.map((w) => w.id), isNot(contains(46001)));
    expect(merged.wars.length, 14);
    final failed = merged.wars.firstWhere((w) => w.id == 46822);
    expect(failed.duration, warLength);
    expect(merged.wars.firstWhere((w) => w.id == 46838).endedAt, isNull);
    expect(merged.bombs.single.id, 89);
    expect(mergeHistory([], [day], DateTime.utc(2026, 11, 7))!.completeFrom, DateTime.utc(2026, 11, 4));
  });

  test('mergeHistory: a day end completes an open year war', () {
    final day = parseDayChanges(
      '{"format": 1, "day": "2026-11-06", "generated_at": 0, "changes": ['
      '[1783259000, "war", "QFA", "end:fail_assault", 14821, 36811, 46150, null, {"score": 80000, "target": 300000}],'
      '[1787100000, "war", "QFA", "end:success_assault", 26312, 14821, 46350, null, null]]}',
    );
    final merged = mergeHistory([history], [day], DateTime.utc(2026, 11, 7))!;
    final failed = merged.wars.singleWhere((w) => w.id == 46150);
    expect(failed.start, history.wars.firstWhere((w) => w.id == 46150).start);
    expect(failed.endedAt, DateTime.fromMillisecondsSinceEpoch(1783259000 * 1000, isUtc: true));
    final taken = merged.wars.singleWhere((w) => w.id == 46350);
    expect(taken.result, WarResult.successAssault);
    expect(taken.duration, const Duration(seconds: 1787100000 - 1787000000));
  });

  test('territoryTimeline: newest first, diary rows only', () {
    final timeline = territoryTimeline(territoryBiography(history, 'QFA'));
    expect(timeline.length, 10);
    expect(timeline.first.event, isA<MapChange>());
    expect(timeline.last.event, isA<RecentWar>());
    for (var i = 1; i < timeline.length; i++) {
      expect(timeline[i].at.isAfter(timeline[i - 1].at), isFalse);
    }
  });

  test('ownersAt: owners when the day ended', () {
    final present = {'RCD': owned(26312), 'BAA': owned(36811), 'QFA': owned(36811)};
    final before = ownersAt(present, history.owners, '2026-11-03');
    expect([before['RCD']!.factionId, before['BAA']!.factionId, before['QFA']!.factionId], [7835, 9032, 36811]);
    expect(ownersAt(present, history.owners, '2026-11-04')['RCD']!.factionId, 26312);
  });

  test('timelapseDays', () {
    expect(timelapseDays(DateTime.utc(2026, 11, 4, 5), DateTime.utc(2026, 11, 6, 1)), [
      '2026-11-04',
      '2026-11-05',
      '2026-11-06',
    ]);
  });
}
