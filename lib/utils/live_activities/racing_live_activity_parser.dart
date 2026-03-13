enum RacingLivePhase {
  waiting,
  waitingUnknown,
  racing,
  finished,
}

class RacingLiveActivityState {
  const RacingLiveActivityState({
    required this.phase,
    required this.titleText,
    required this.bodyText,
    required this.stateIdentifier,
    this.targetTimestamp,
  });

  final RacingLivePhase phase;
  final String titleText;
  final String bodyText;
  final String stateIdentifier;
  final int? targetTimestamp;

  bool get hasTimer => targetTimestamp != null && phase != RacingLivePhase.finished;
}

class RacingLiveActivityParser {
  static final RegExp _durationRegex = RegExp(
    r'(\d+)\s+(day|days|hour|hours|minute|minutes|second|seconds)',
    caseSensitive: false,
  );

  static RacingLiveActivityState? parse({
    required String? icon17,
    required String? icon18,
    required int baseTimestamp,
  }) {
    final String? normalizedIcon17 = icon17?.trim();
    final String? normalizedIcon18 = icon18?.trim();

    if (normalizedIcon17 != null && normalizedIcon17.isNotEmpty) {
      if (normalizedIcon17.contains('Currently racing')) {
        final String detail = _stripRacingPrefix(normalizedIcon17);
        final int? remainingSeconds = parseRelativeSeconds(detail);
        final int? targetTimestamp = remainingSeconds == null ? null : baseTimestamp + remainingSeconds;
        return RacingLiveActivityState(
          phase: RacingLivePhase.racing,
          titleText: 'Currently racing',
          bodyText: detail,
          stateIdentifier: targetTimestamp == null ? 'racing-unknown' : 'racing-${_bucketize(targetTimestamp)}',
          targetTimestamp: targetTimestamp,
        );
      }

      if (normalizedIcon17.contains('Waiting for a race to start')) {
        final String detail = _stripRacingPrefix(normalizedIcon17);
        final int? remainingSeconds = parseRelativeSeconds(detail);
        if (remainingSeconds != null) {
          final int targetTimestamp = baseTimestamp + remainingSeconds;
          return RacingLiveActivityState(
            phase: RacingLivePhase.waiting,
            titleText: 'Waiting to race',
            bodyText: detail,
            stateIdentifier: 'waiting-${_bucketize(targetTimestamp)}',
            targetTimestamp: targetTimestamp,
          );
        }

        return const RacingLiveActivityState(
          phase: RacingLivePhase.waitingUnknown,
          titleText: 'Waiting to race',
          bodyText: 'Start time pending',
          stateIdentifier: 'waiting-unknown',
        );
      }
    }

    if (normalizedIcon18 != null && normalizedIcon18.isNotEmpty) {
      final String detail = _stripRacingPrefix(normalizedIcon18);
      return RacingLiveActivityState(
        phase: RacingLivePhase.finished,
        titleText: 'Race finished',
        bodyText: detail,
        stateIdentifier: 'finished-${_sanitizeIdentifier(detail)}',
      );
    }

    return null;
  }

  static int? parseRelativeSeconds(String input) {
    int totalSeconds = 0;
    bool foundAny = false;

    for (final match in _durationRegex.allMatches(input)) {
      final int value = int.tryParse(match.group(1) ?? '') ?? 0;
      final String unit = (match.group(2) ?? '').toLowerCase();
      foundAny = true;

      if (unit.startsWith('day')) {
        totalSeconds += value * 24 * 60 * 60;
      } else if (unit.startsWith('hour')) {
        totalSeconds += value * 60 * 60;
      } else if (unit.startsWith('minute')) {
        totalSeconds += value * 60;
      } else if (unit.startsWith('second')) {
        totalSeconds += value;
      }
    }

    return foundAny ? totalSeconds : null;
  }

  static String _stripRacingPrefix(String input) {
    return input.replaceFirst(RegExp(r'^Racing\s*-\s*', caseSensitive: false), '').trim();
  }

  /// Rounds a timestamp to the nearest 120 s bucket so that small API
  /// time-drift between polls doesn't produce a different
  /// stateIdentifier for the same race
  static int _bucketize(int timestamp) => (timestamp ~/ 120) * 120;

  static String _sanitizeIdentifier(String input) {
    final sanitized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (sanitized.length <= 80) {
      return sanitized;
    }
    return sanitized.substring(0, 80);
  }
}
