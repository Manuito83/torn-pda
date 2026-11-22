import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';

const stalledAfter = Duration(hours: 1);
final _points = NumberFormat('#,##0', 'en_US');
const sampleInterval = Duration(minutes: 10);

class WarSample {
  WarSample({required this.at, required this.score, required this.attackers, required this.defenders});

  final DateTime at;
  final int score;
  final int attackers;
  final int defenders;
}

class WarReportSide {
  WarReportSide({required this.score, required this.joins, required this.clears});

  // Wall seconds as Torn reports them
  final int score;
  final int joins;
  final int clears;
}

class WarReport {
  WarReport({required this.winnerId, required this.endedAt, required this.aggressor, required this.defender});

  final int? winnerId;
  final DateTime endedAt;
  final WarReportSide aggressor;
  final WarReportSide defender;
}

class WarFile {
  WarFile({
    required this.id,
    required this.territory,
    required this.start,
    required this.scheduledEnd,
    required this.target,
    required this.aggressorId,
    required this.defenderId,
    required this.result,
    required this.endedAt,
    required this.samples,
    required this.report,
  });

  final int id;
  final String territory;
  final DateTime start;
  final DateTime scheduledEnd;
  final int target;
  final int aggressorId;
  final int defenderId;
  final WarResult result;
  final DateTime? endedAt;
  final List<WarSample> samples;
  final WarReport? report;
}

WarFile parseWarFile(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  if (data['format'] != 1) {
    throw FormatException('Unknown war file format: ${data['format']}');
  }

  WarReportSide side(Map<String, dynamic> row) => WarReportSide(
    score: row['score'] as int? ?? 0,
    joins: row['joins'] as int? ?? 0,
    clears: row['clears'] as int? ?? 0,
  );

  final war = data['war'] as Map<String, dynamic>;
  final report = data['report'] as Map<String, dynamic>?;
  return WarFile(
    id: war['id'] as int,
    territory: war['territory'] as String,
    start: unixTime(war['start']),
    scheduledEnd: unixTime(war['scheduled_end']),
    target: war['target'] as int,
    aggressorId: war['aggressor'] as int,
    defenderId: war['defender'] as int,
    result: warResultFrom(war['result'] as String?),
    endedAt: war['ended_at'] == null ? null : unixTime(war['ended_at']),
    samples: [
      for (final row in (data['samples'] as List<dynamic>? ?? const []).cast<List<dynamic>>())
        WarSample(at: unixTime(row[0]), score: row[1] as int, attackers: row[2] as int, defenders: row[3] as int),
    ],
    report: report == null
        ? null
        : WarReport(
            winnerId: report['winner'] as int?,
            endedAt: unixTime(report['ended_at']),
            aggressor: side(report['aggressor'] as Map<String, dynamic>),
            defender: side(report['defender'] as Map<String, dynamic>),
          ),
  );
}

// Samples only exist when something changed
int _scoreAt(List<WarSample> samples, DateTime at) {
  if (!at.isAfter(samples.first.at)) return samples.first.score;
  for (var i = 1; i < samples.length; i++) {
    final after = samples[i];
    if (after.at.isBefore(at)) continue;
    final before = samples[i - 1];
    final rampStart = after.at.subtract(sampleInterval);
    final from = before.at.isAfter(rampStart) ? before.at : rampStart;
    if (!at.isAfter(from)) return before.score;
    final share = at.difference(from).inSeconds / after.at.difference(from).inSeconds;
    return (before.score + (after.score - before.score) * share).round();
  }
  return samples.last.score;
}

// Points a minute, oldest sample first
double? paceLastHour(List<WarSample> samples, DateTime now) {
  if (samples.isEmpty) return null;
  final hourAgo = now.subtract(const Duration(hours: 1));
  final from = hourAgo.isBefore(samples.first.at) ? samples.first.at : hourAgo;
  final minutes = now.difference(from).inSeconds / 60;
  if (minutes <= 0) return null;
  return (_scoreAt(samples, now) - _scoreAt(samples, from)) / minutes;
}

DateTime? warEndedAt(WarFile? file, RecentWar? recent) => recent?.endedAt ?? file?.report?.endedAt ?? file?.endedAt;

// Live point last, final score once ended
List<WarSample> warChartSamples(WarFile? file, TerritoryWar? live, RecentWar? recent) {
  final samples = file?.samples ?? const <WarSample>[];
  if (live != null) {
    if (samples.isNotEmpty && !live.scoreAt.isAfter(samples.last.at)) return samples;
    final point = WarSample(
      at: live.scoreAt,
      score: live.aggressor.score,
      attackers: live.aggressor.wall,
      defenders: live.defender.wall,
    );
    return [...samples, point];
  }
  final endedAt = warEndedAt(file, recent);
  if (endedAt == null || samples.isEmpty) return samples;
  return [...samples, WarSample(at: endedAt, score: recent?.score ?? samples.last.score, attackers: 0, defenders: 0)];
}

({DateTime since, bool scoreUnchanged}) stalledSince(TerritoryWar war) {
  final since = war.idle?.noAttackersSince ?? war.start;
  final changedAt = war.idle?.scoreChangedAt;
  return (since: since, scoreUnchanged: changedAt == null || !changedAt.isAfter(since));
}

bool isStalled(TerritoryWar war, DateTime now) {
  final idle = war.idle;
  if (idle == null) {
    return war.aggressor.wall == 0 && war.aggressor.score == 0 && now.difference(war.start) >= stalledAfter;
  }
  final since = idle.noAttackersSince;
  return since != null && now.difference(since) >= stalledAfter;
}

String warStalledText(TerritoryWar war, DateTime now, String Function(DateTime) clock) {
  final (:since, :scoreUnchanged) = stalledSince(war);
  return 'No attackers since ${clock(since)} (${chatSpan(now.difference(since))})'
      '${scoreUnchanged ? ', score unchanged' : ''}';
}

String warResultText(WarResult result, String code) => switch (result) {
  WarResult.successAssault => 'Attackers took $code',
  WarResult.failAssault => 'Defenders held $code',
  WarResult.peaceTreaty => 'Ended with a peace treaty',
  _ => 'Ended',
};

String warReportText(WarReportSide side) =>
    '${_points.format(side.score)} wall seconds, ${side.joins} ${side.joins == 1 ? 'join' : 'joins'}, '
    '${side.clears} ${side.clears == 1 ? 'clear' : 'clears'}';
