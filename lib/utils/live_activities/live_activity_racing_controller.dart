import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/utils/firebase_rtdb.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/racing_live_activity_background.dart';
import 'package:torn_pda/utils/live_activities/live_update_models.dart';
import 'package:torn_pda/utils/live_activities/racing_live_activity_parser.dart';
import 'package:torn_pda/utils/user_helper.dart';

/// Controls Racing Live Activities / Live Updates
///
/// On Android, background refresh is handled via AlarmManager
/// Diagnostics are logged under the tag "RacingLU"
class LiveActivityRacingController extends GetxController {
  final _chainStatusProvider = Get.find<ChainStatusController>();
  final _bridgeController = Get.find<LiveActivityBridgeController>();

  bool _isMonitoring = false;
  bool _isLALogicallyActive = false;
  bool _isFirstValidProcessingPending = false;
  bool _skipNextNullAfterAdopt = false;
  String _lastProcessedStateIdentifier = '';
  Worker? _statusListenerWorker;
  StreamSubscription<LiveUpdateStatusEvent>? _statusEventSubscription;

  Future<void> activate() async {
    if (_isMonitoring) {
      log('RacingLiveActivityHandler: Already active and monitoring.');
      return;
    }

    final bool supportedOnIos = Platform.isIOS && kSdkIos >= 16.2;
    final bool supportedOnAndroid = Platform.isAndroid && kSdkAndroid >= 26;
    if (!supportedOnIos && !supportedOnAndroid) {
      log('RacingLiveActivityHandler: Racing live updates not supported on this platform/version.');
      return;
    }

    _isMonitoring = true;
    _bridgeController.initializeHandler();
    _statusListenerWorker = ever(_chainStatusProvider.laStatusInputData, _onStatusDataChanged);
    _statusEventSubscription?.cancel();
    _statusEventSubscription = _bridgeController.statusEvents.listen(_handleStatusEvent);

    _isLALogicallyActive = await _bridgeController.isAnyRacingActivityActive();
    if (!_isLALogicallyActive) {
      _resetLAStateInternal();
    } else {
      // A background-started LA exists; allow one null-state result before
      // ending it, since the first data after activation may be stale
      _skipNextNullAfterAdopt = true;
    }

    _isFirstValidProcessingPending = true;
    _processCurrentState(statusData: _chainStatusProvider.laStatusInputData.value);
    log('RacingLiveActivityHandler: Activated and monitoring racing status.');
  }

  void deactivate() {
    if (!_isMonitoring) return;

    _statusListenerWorker?.dispose();
    _statusListenerWorker = null;
    _statusEventSubscription?.cancel();
    _statusEventSubscription = null;

    if (_isLALogicallyActive) {
      unawaited(_bridgeController.endRacingActivity());
    }

    _resetLAState();
    _isMonitoring = false;
    _isFirstValidProcessingPending = false;
    _skipNextNullAfterAdopt = false;
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

    // Wait until the first update with a valid model and icons before
    // taking any action
    if (_isFirstValidProcessingPending) {
      if (model != null && icons != null) {
        _isFirstValidProcessingPending = false;
      } else {
        // Still waiting for valid data on the first cycle
        return;
      }
    }

    // If model is null (no API data yet), skip to avoid ending an active LA
    // that was started by a previous valid update or by the background
    if (model == null) {
      return;
    }

    final String? icon17 = icons?.icon17 as String?;
    final String? icon18 = icons?.icon18 as String?;
    final int baseTimestamp = model.serverTime ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    final RacingLiveActivityState? racingState = RacingLiveActivityParser.parse(
      icon17: icon17,
      icon18: icon18,
      baseTimestamp: baseTimestamp,
    );

    if (racingState == null) {
      if (_isLALogicallyActive) {
        // After adopting an existing LA, the first tick may carry stale data
        // that predates the race, skip one null before ending
        if (_skipNextNullAfterAdopt) {
          _skipNextNullAfterAdopt = false;
          log('RacingLiveActivityHandler: Skipping first null racing state after adopt — waiting for fresh data.');
          return;
        }
        await _bridgeController.endRacingActivity();
      }
      _resetLAState();
      return;
    }
    _skipNextNullAfterAdopt = false;

    // Don't create a new LA for a finished state. Finished only makes
    // sense as a transition from an already-active LA
    if (!_isLALogicallyActive && racingState.phase == RacingLivePhase.finished) {
      return;
    }

    final bool shouldStartOrUpdate =
        !_isLALogicallyActive || racingState.stateIdentifier != _lastProcessedStateIdentifier;
    if (!shouldStartOrUpdate) return;

    final LiveUpdateStartResult result = await _bridgeController.startRacingActivity(
      arguments: buildRacingLiveActivityArgs(
        racingState: racingState,
        currentTimestamp: baseTimestamp,
        apiKey: Platform.isAndroid && UserHelper.isApiKeyValid ? UserHelper.apiKey : null,
      ),
    );

    if (!result.isSuccess) {
      log('RacingLiveActivityHandler: Native layer reported ${result.status} (${result.reason}).');
      _resetLAStateInternal();
      return;
    }

    _isLALogicallyActive = true;
    _lastProcessedStateIdentifier = racingState.stateIdentifier;
    await _syncState(racingState);

    // Finished: after a brief delay, reset controller state so it's ready
    // for the next race (Android preserves the notification for demotion)
    if (racingState.phase == RacingLivePhase.finished) {
      final capturedId = racingState.stateIdentifier;
      Future.delayed(const Duration(seconds: 15), () {
        if (_isMonitoring && _isLALogicallyActive && _lastProcessedStateIdentifier == capturedId) {
          unawaited(_bridgeController.endRacingActivity());
          _resetLAState();
        }
      });
    }
  }

  String _phaseToNativeValue(RacingLivePhase phase) {
    return racingLivePhaseToNativeValue(phase);
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

  void _handleStatusEvent(LiveUpdateStatusEvent event) {
    switch (event.status) {
      case LiveUpdateLifecycleStatus.timeout:
      case LiveUpdateLifecycleStatus.dismissed:
      case LiveUpdateLifecycleStatus.ended:
        _resetLAStateInternal();
        break;
      default:
        break;
    }
  }

  void _clearState() {
    if (!Platform.isIOS) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      unawaited(FirebaseRtdbHelper().liveActivityRacingClearState(uid: user.uid));
    }
  }

  @override
  void onClose() {
    _statusEventSubscription?.cancel();
    super.onClose();
  }
}
