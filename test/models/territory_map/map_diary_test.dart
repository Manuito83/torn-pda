import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

void main() {
  final day = parseDayChanges(File('test/models/territory_map/fixtures/changes-2026-11-04.json').readAsStringSync());
  String tag(int id) => '[${day.factions[id]?.tag}]';
  String text(String territory, String kind) {
    final change = day.changes.firstWhere((c) => c.territory == territory && c.kind == kind);
    return diaryText(change, classify(change)!, tag);
  }

  final now = DateTime.utc(2026, 11, 7, 15, 40);

  group('diaryDays', () {
    test('from the last look to today, newest first', () {
      expect(diaryDays(DateTime.utc(2026, 11, 5, 23), now), ['2026-11-07', '2026-11-06', '2026-11-05']);
    });

    test('never more than 31 files', () {
      final days = diaryDays(DateTime.utc(2026, 8, 1), now);
      expect(days.length, 31);
      expect(days.last, '2026-10-08');
    });
  });

  test('a day not published is gone for good after 22 days', () {
    expect(isMissingForGood('2026-10-05', DateTime.utc(2026, 10, 27)), isFalse);
    expect(isMissingForGood('2026-10-05', DateTime.utc(2026, 10, 27, 0, 1)), isTrue);
  });

  test('a missing late day is asked every 3 hours, others every minute', () {
    final asked = DateTime.utc(2026, 11, 7, 12);
    final soon = asked.add(const Duration(minutes: 2));
    final later = asked.add(const Duration(hours: 3));
    expect(shouldAskDay('2026-11-07', asked, null, missing: true), isTrue);
    expect(shouldAskDay('2026-11-07', asked.add(const Duration(seconds: 30)), asked, missing: false), isFalse);
    expect(shouldAskDay('2026-11-06', soon, asked, missing: true), isTrue);
    expect(shouldAskDay('2026-11-04', soon, asked, missing: false), isTrue);
    expect(shouldAskDay('2026-11-04', soon, asked, missing: true), isFalse);
    expect(shouldAskDay('2026-11-04', later, asked, missing: true), isTrue);
  });

  test('days before the first published one are not missing', () {
    final days = ['2026-11-07', '2026-11-06', '2026-11-05', '2026-11-04', '2026-11-03'];
    expect(hasMissingDays(days, {'2026-11-03'}), isFalse);
    expect(hasMissingDays(days, {'2026-11-05', '2026-11-03'}), isTrue);
    expect(hasMissingDays(days, days.toSet()), isFalse);
  });

  test('diarySummary groups the kinds', () {
    final counts = {
      ChangeKind.conquest: 2,
      ChangeKind.transfer: 31,
      ChangeKind.assaultStarted: 7,
      ChangeKind.assaultFailed: 3,
      ChangeKind.assaultSucceeded: 2,
      ChangeKind.racketUp: 2,
      ChangeKind.racketNew: 1,
      ChangeKind.bomb: 1,
    };
    expect(
      diarySummary(counts),
      '2 conquests - 31 transfers - 7 assaults started - 5 ended (3 failed) - 3 racket changes - 1 bomb',
    );
  });

  group('diaryText', () {
    test('conquest needs the war id', () {
      expect(text('CNF', 'owner'), '[LOC] conquered CNF from [DP]');
      expect(text('QWF', 'owner'), 'QWF transferred [7DS] → [GLU]');
    });

    test('extra columns when published', () {
      expect(text('XGG', 'end:fail_assault'), endsWith('(63,934 / 300,000)'));
      expect(text('IFE', 'level'), 'IFE racket down to level 1');
      final bomb = day.changes.firstWhere((c) => c.source == 'bomb');
      expect(diaryText(bomb, ChangeKind.bomb, tag), 'Dirty bomb on RFG: [UNT] lost 769,315 respect');
    });
  });

  group('periodStats', () {
    test('ranks net gains', () {
      final stats = periodStats(day.changes, DateTime.utc(2026, 11, 4));
      expect(stats.gainers.first.key, 13665);
      expect(stats.gainers.first.value, 2);
      expect(stats.gainers.length, 3);
      expect(stats.losers.map((e) => e.key).toSet(), {8085, 38662, 21234});
    });

    test('ignores changes before the period', () {
      final stats = periodStats(day.changes, unixTime(1793800000));
      expect(stats.gainers.single.key, 26312);
      expect(stats.losers.single.key, 21234);
      expect(stats.counts[ChangeKind.conquest], isNull);
    });
  });

  test('factionRecent counts territories won and lost', () {
    final dead = factionRecent(day.changes, 38662);
    expect(dead.rows.map((r) => r.$2), [ChangeKind.assaultSucceeded, ChangeKind.conquest]);
    expect((dead.won, dead.lost), (0, 1));
    final claimer = factionRecent(day.changes, 13665);
    expect((claimer.won, claimer.lost), (2, 0));
  });

  group('diaryRows', () {
    List<String> search(String query, {int factionId = 0}) => [
      for (final (change, _) in diaryRows(day, query: query, factionId: factionId, faction: (id) => day.factions[id]))
        '${change.territory} ${change.kind}',
    ];

    test('by faction tag or name, both sides of the change', () {
      expect(search('loc'), search('Lords of'));
      expect(search('dp'), contains('CNF owner'));
    });

    test('by code prefix, bomb territories included', () {
      expect(search('cn'), unorderedEquals(['CNF end:success_assault', 'CNF owner']));
      expect(search('rfg'), contains('null new'));
    });

    test('by whole kind words, and every word must hit', () {
      expect(search('bomb'), ['null new']);
      expect(search('assault failed'), unorderedEquals(['XGG end:fail_assault', 'LIC end:fail_assault']));
      expect(search('failed xg'), ['XGG end:fail_assault']);
      expect(search('fail'), search('failed'));
      expect(search('conquer'), contains('CNF owner'));
      expect(search('ed'), isEmpty);
      expect(search('loc bomb'), isEmpty);
    });

    test('my faction narrows the search', () {
      expect(search('', factionId: 38662), unorderedEquals(['CNF end:success_assault', 'CNF owner']));
      expect(search('assault', factionId: 38662), ['CNF end:success_assault']);
    });
  });
}
