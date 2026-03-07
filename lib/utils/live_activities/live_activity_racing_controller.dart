import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/utils/firebase_rtdb.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/live_update_models.dart';
import 'package:torn_pda/utils/live_activities/racing_live_activity_parser.dart';

class LiveActivityRacingController extends GetxController {
  final _chainStatusProvider = Get.find<ChainStatusController>();
  final _bridgeController = Get.find<LiveActivityBridgeController>();

  bool _isMonitoring = false;
  bool _isLALogicallyActive = false;
  String _lastProcessedStateIdentifier = '';
  Worker? _statusListenerWorker;

  Future<void> activate() async {
    if (_isMonitoring) {
      log('RacingLiveActivityHandler: Already active and monitoring.');
      return;
    }

    if (!Platform.isIOS || kSdkIos < 16.2) {
      log('RacingLiveActivityHandler: Racing Live Activities only supported on iOS 16.2+.');
      return;
    }

    _isMonitoring = true;
    _bridgeController.initializeHandler();
    _statusListenerWorker = ever(_chainStatusProvider.laStatusInputData, _onStatusDataChanged);

    _isLALogicallyActive = await _bridgeController.isAnyRacingActivityActive();
    if (!_isLALogicallyActive) {
      _resetLAStateInternal();
    }

    _processCurrentState(statusData: _chainStatusProvider.laStatusInputData.value);
    log('RacingLiveActivityHandler: Activated and monitoring racing status.');
  }

  void deactivate() {
    if (!_isMonitoring) return;

    _statusListenerWorker?.dispose();
    _statusListenerWorker = null;

    if (_isLALogicallyActive) {
      unawaited(_bridgeController.endRacingActivity());
    }

    _resetLAState();
    _isMonitoring = false;
    log('RacingLiveActivityHandler: Deactivated.');
  }

  void _onStatusDataChanged(StatusObservable? statusData) {
    if (!_isMonitoring) return;
    _processCurrentState(statusData: statusData);
  }

  Future<void> _processCurrentState({StatusObservable? statusData}) async {
    if (!_isMonitoring) return;

    final model = statusData?.barsAndStatusModel;
    final dynamic icons = model?.basicicons;

    if (model != null && icons == null) {
      log('RacingLiveActivityHandler: Ignoring status update without icons payload.');
      return;
    }

    final String? icon17 = icons?.icon17 as String?;
    final String? icon18 = icons?.icon18 as String?;
    final int baseTimestamp = model?.serverTime ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    final RacingLiveActivityState? racingState = RacingLiveActivityParser.parse(
      icon17: icon17,
      icon18: icon18,
      baseTimestamp: baseTimestamp,
    );

    if (racingState == null) {
      if (_isLALogicallyActive) {
        await _bridgeController.endRacingActivity();
      }
      _resetLAState();
      return;
    }

    final bool shouldStartOrUpdate =
        !_isLALogicallyActive || racingState.stateIdentifier != _lastProcessedStateIdentifier;
    if (!shouldStartOrUpdate) {
      return;
    }

    final LiveUpdateStartResult result = await _bridgeController.startRacingActivity(
      arguments: _buildArgs(racingState: racingState, currentTimestamp: baseTimestamp),
    );

    if (!result.isSuccess) {
      log('RacingLiveActivityHandler: Native layer reported ${result.status} (${result.reason}).');
      _resetLAStateInternal();
      return;
    }

    _isLALogicallyActive = true;
    _lastProcessedStateIdentifier = racingState.stateIdentifier;
    await _syncState(racingState);
  }

  Map<String, dynamic> _buildArgs({
    required RacingLiveActivityState racingState,
    required int currentTimestamp,
  }) {
    return {
      'stateIdentifier': racingState.stateIdentifier,
      'phase': _phaseToNativeValue(racingState.phase),
      'titleText': racingState.titleText,
      'bodyText': racingState.bodyText,
      'targetTimeTimestamp': racingState.targetTimestamp,
      'currentServerTimestamp': currentTimestamp,
      'showTimer': racingState.hasTimer,
    };
  }

  String _phaseToNativeValue(RacingLivePhase phase) {
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

  Future<void> _syncState(RacingLiveActivityState state) async {
    if (!Platform.isIOS) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseRtdbHelper().liveActivityRacingStateSync(
      uid: user.uid,
      stateIdentifier: state.stateIdentifier,
      targetTimestamp: state.targetTimestamp,
      phase: _phaseToNativeValue(state.phase),
    );
  }

  void _resetLAStateInternal() {
    _isLALogicallyActive = false;
    _lastProcessedStateIdentifier = '';
  }

  void _resetLAState() {
    _resetLAStateInternal();
    _clearState();
  }

  void _clearState() {
    if (!Platform.isIOS) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      unawaited(FirebaseRtdbHelper().liveActivityRacingClearState(uid: user.uid));
    }
  }
}
