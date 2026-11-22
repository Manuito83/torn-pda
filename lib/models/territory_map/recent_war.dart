const warLength = Duration(hours: 72);

enum WarResult { inProgress, successAssault, failAssault, peaceTreaty, unknown }

WarResult warResultFrom(String? value) => switch (value) {
  'in_progress' => WarResult.inProgress,
  'success_assault' => WarResult.successAssault,
  'fail_assault' => WarResult.failAssault,
  'end_with_peace_treaty' => WarResult.peaceTreaty,
  _ => WarResult.unknown,
};

class RecentWar {
  RecentWar({
    required this.id,
    required this.territory,
    required this.start,
    required this.endedAt,
    required this.result,
    required this.aggressorId,
    required this.defenderId,
    required this.score,
    required this.target,
    this.hasReport = false,
  });

  final int id;
  final String territory;
  final DateTime start;

  // Null for backfilled wars without report
  final DateTime? endedAt;
  final WarResult result;
  final int aggressorId;
  final int defenderId;
  final int score;
  final int target;
  final bool hasReport;

  // Unended failed assaults ran 72 h
  Duration? get duration => endedAt?.difference(start) ?? (result == WarResult.failAssault ? warLength : null);
}

int? warLoser(RecentWar war) => switch (war.result) {
  WarResult.failAssault => war.aggressorId,
  WarResult.successAssault => war.defenderId,
  _ => null,
};
