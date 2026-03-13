import 'package:torn_pda/utils/live_activities/racing_live_activity_parser.dart';

Map<String, dynamic> buildRacingLiveActivityArgs({
  required RacingLiveActivityState racingState,
  required int currentTimestamp,
  String? apiKey,
}) {
  final Map<String, dynamic> args = {
    'stateIdentifier': racingState.stateIdentifier,
    'phase': racingLivePhaseToNativeValue(racingState.phase),
    'titleText': racingState.titleText,
    'bodyText': racingState.bodyText,
    'targetTimeTimestamp': racingState.targetTimestamp,
    'currentServerTimestamp': currentTimestamp,
    'showTimer': racingState.hasTimer,
  };

  if (apiKey != null && apiKey.isNotEmpty) {
    args['apiKey'] = apiKey;
  }

  return args;
}

String racingLivePhaseToNativeValue(RacingLivePhase phase) {
  switch (phase) {
    case RacingLivePhase.waiting:
      return 'waiting';
    case RacingLivePhase.waitingUnknown:
      return 'waitingUnknown';
    case RacingLivePhase.racing:
      return 'racing';
    case RacingLivePhase.finished:
      return 'finished';
  }
}
