import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';

import 'sample_data.dart';

void main() {
  final json = File('test/models/territory_map/fixtures/war-46843.json').readAsStringSync();

  group('parseWarFile', () {
    test('war in progress', () {
      final war = parseWarFile(json);
      expect(war.territory, 'RCD');
      expect(war.result, WarResult.inProgress);
      expect(war.endedAt, isNull);
      expect(war.report, isNull);
      expect(war.samples.length, 10);
      expect(war.samples.last.score, 23400);
      expect(war.samples.last.attackers, 6);
    });

    test('closed war with its report', () {
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['war']['result'] = 'fail_assault';
      data['war']['ended_at'] = 1793859000;
      data['report'] = {
        'winner': 26312,
        'ended_at': 1793859000,
        'aggressor': {'score': 243221, 'joins': 3, 'clears': 0},
        'defender': {'score': 2446864, 'joins': 23, 'clears': 0},
      };
      final war = parseWarFile(jsonEncode(data));
      expect(war.result, WarResult.failAssault);
      expect(war.endedAt, unixTime(1793859000));
      expect(war.report!.winnerId, 26312);
      expect(war.report!.aggressor.score, 243221);
      expect(war.report!.defender.joins, 23);
    });

    test('truce report without a winner', () {
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['war']['result'] = 'end_with_peace_treaty';
      data['report'] = {
        'winner': null,
        'ended_at': 1793859000,
        'aggressor': {'score': 243221, 'joins': 3, 'clears': null},
        'defender': {'score': null, 'joins': 23, 'clears': 0},
      };
      final report = parseWarFile(jsonEncode(data)).report!;
      expect(report.winnerId, isNull);
      expect(report.aggressor.clears, 0);
      expect(report.defender.score, 0);
    });
  });

  group('paceLastHour', () {
    final samples = parseWarFile(json).samples;

    test('uneven samples', () {
      expect(paceLastHour(samples, unixTime(1793702400)), 320);
      expect(paceLastHour(samples, unixTime(1793704200)), 240);
    });

    test('score holds through a long gap', () {
      final start = unixTime(1793691600);
      final gap = [
        WarSample(at: start, score: 0, attackers: 0, defenders: 20),
        WarSample(at: start.add(const Duration(hours: 3, minutes: 10)), score: 3600, attackers: 6, defenders: 0),
      ];
      expect(paceLastHour(gap, gap.last.at), 60);
    });

    test('war younger than an hour', () {
      expect(paceLastHour(samples.take(2).toList(), unixTime(1793692200)), 180);
      expect(paceLastHour(const [], unixTime(1793692200)), isNull);
    });
  });

  group('warChartSamples', () {
    final file = parseWarFile(json);

    test('live point after the last sample', () {
      final samples = warChartSamples(file, liveWar(score: 30000, attackers: 6), null);
      expect(samples.length, 11);
      expect(samples.last.at, scoreTime);
      expect(samples.last.score, 30000);
    });

    test('live point older than the last sample', () {
      final data = jsonDecode(json) as Map<String, dynamic>;
      (data['samples'] as List<dynamic>).add([scoreTime.millisecondsSinceEpoch ~/ 1000 + 600, 31000, 6, 0]);
      final samples = warChartSamples(parseWarFile(jsonEncode(data)), liveWar(score: 30000), null);
      expect(samples.length, 11);
      expect(samples.last.score, 31000);
    });

    test('ended war closes at the final score', () {
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['war']['ended_at'] = 1793859000;
      final samples = warChartSamples(parseWarFile(jsonEncode(data)), null, null);
      expect(samples.last.at, unixTime(1793859000));
      expect(samples.last.score, 23400);
      expect(samples.last.attackers, 0);

      final ended = endedWar(code: 'RCD', endedAt: unixTime(1793860000));
      expect(warChartSamples(file, null, ended).last.at, unixTime(1793860000));
    });
  });

  group('stalledSince', () {
    final since = scoreTime.subtract(const Duration(hours: 2));

    test('score moved after the attackers left', () {
      final war = liveWar(
        idle: WarIdle(noAttackersSince: since, scoreChangedAt: since.add(const Duration(minutes: 30))),
      );
      expect(stalledSince(war), (since: since, scoreUnchanged: false));
    });

    test('score held since then', () {
      final war = liveWar(
        idle: WarIdle(noAttackersSince: since, scoreChangedAt: since.subtract(const Duration(minutes: 10))),
      );
      expect(stalledSince(war), (since: since, scoreUnchanged: true));
    });

    test('older state counts from the start', () {
      final war = liveWar(defenders: 20);
      expect(stalledSince(war), (since: war.start, scoreUnchanged: true));
    });
  });

  group('isStalled', () {
    final now = scoreTime;

    test('from idle', () {
      WarIdle idle(int minutes) => WarIdle(
        noAttackersSince: now.subtract(Duration(minutes: minutes)),
        scoreChangedAt: now,
      );
      expect(isStalled(liveWar(idle: idle(59)), now), isFalse);
      expect(isStalled(liveWar(idle: idle(61)), now), isTrue);
      expect(isStalled(liveWar(idle: WarIdle(noAttackersSince: null, scoreChangedAt: now)), now), isFalse);
    });

    test('older state without idle', () {
      expect(isStalled(liveWar(defenders: 20), now), isTrue);
      expect(isStalled(liveWar(attackers: 1), now), isFalse);
      expect(isStalled(liveWar(score: 500), now), isFalse);
    });
  });

  group('war texts', () {
    test('stalled line says when the score stopped too', () {
      final since = scoreTime.subtract(const Duration(minutes: 90));
      String clock(DateTime at) => '${at.toUtc().hour}:${at.toUtc().minute}';
      final held = liveWar(idle: WarIdle(noAttackersSince: since, scoreChangedAt: since));
      final moved = liveWar(idle: WarIdle(noAttackersSince: since, scoreChangedAt: scoreTime));
      expect(warStalledText(held, scoreTime, clock), 'No attackers since 19:30 (1h 30m), score unchanged');
      expect(warStalledText(moved, scoreTime, clock), 'No attackers since 19:30 (1h 30m)');
    });

    test('report line counts in singular and plural', () {
      final first = WarReportSide(score: 243221, joins: 1, clears: 0);
      expect(warReportText(first), '243,221 wall seconds, 1 join, 0 clears');
      expect(warReportText(WarReportSide(score: 0, joins: 23, clears: 1)), '0 wall seconds, 23 joins, 1 clear');
    });
  });
}
