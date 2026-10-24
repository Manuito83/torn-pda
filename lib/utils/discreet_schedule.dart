class DiscreetSchedule {
  const DiscreetSchedule({this.enabled = false, this.from = 23 * 60, this.to = 7 * 60});

  final bool enabled;

  /// Minutes since midnight
  final int from;
  final int to;

  /// Wraps midnight, empty when both ends match
  bool contains(DateTime time) {
    if (!enabled) return false;
    final minute = time.hour * 60 + time.minute;
    return from <= to ? minute >= from && minute < to : minute >= from || minute < to;
  }

  Map<String, Object> toFirestore(int offset) => {"enabled": enabled, "from": from, "to": to, "offset": offset};
}

bool discreetScheduleNeedsSync(
  DiscreetSchedule schedule, {
  required int offset,
  required int? uploadedOffset,
  required bool pending,
}) => pending || (schedule.enabled && offset != uploadedOffset);

bool isDiscreetAt({required bool always, required DiscreetSchedule schedule, required DateTime time}) =>
    always || schedule.contains(time);
