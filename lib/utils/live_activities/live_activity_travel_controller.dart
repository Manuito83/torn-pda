import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/utils/firebase_rtdb.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/live_update_models.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class LiveActivityTravelController extends GetxController {
  final _chainStatusProvider = Get.find<ChainStatusController>();
  final _bridgeController = Get.find<LiveActivityBridgeController>();
  final _prefs = Prefs();

  // Ensure that special "initial check" logic (like ignoring stale old arrivals)
  // is applied only once, specifically during the first processing run that has valid API data
  bool _isFirstValidProcessingPending = false;

  int _currentLAArrivalTimestamp = 0;
  bool _isLALogicallyActive = false;
  String _lastProcessedTravelIdentifier = "";
  String _lastArrivalNotifiedTravelId = "";
  bool _hasArrivedNotified = false;

  bool _isMonitoring = false;
  Worker? _statusListenerWorker;
  StreamSubscription<LiveUpdateStatusEvent>? _statusEventSubscription;

  static const int _staleArrivalThresholdSeconds = 15 * 60;
  static const int _arrivedLAAutoEndMinutes = 10;
  String? _activeSessionId;

  @visibleForTesting
  bool get isLiveActivityActiveForTest => _isLALogicallyActive;

  @visibleForTesting
  String? get activeSessionIdForTest => _activeSessionId;

  Future<void> activate() async {
    if (_isMonitoring) {
      log("TravelLiveActivityHandler: Already active and monitoring.");
      return;
    }

    if (Platform.isIOS && kSdkIos < 16.2) {
      log("TravelLiveActivityHandler: iOS SDK < 16.2, LA not supported. Activation skipped.");
      return;
    }

    _isMonitoring = true;

    // Ensure bridge handler is initialized (it has its own internal guard)
    _bridgeController.initializeHandler();

    _statusListenerWorker = ever(_chainStatusProvider.laStatusInputData, _onStatusDataChanged);
    _statusEventSubscription?.cancel();
    _statusEventSubscription = _bridgeController.statusEvents.listen(handleStatusEvent);

    if (Platform.isAndroid) {
      final storedArrivalId = await _prefs.getAndroidLiveActivityTravelLastArrivalId();
      if (storedArrivalId != null && storedArrivalId.isNotEmpty) {
        _lastArrivalNotifiedTravelId = storedArrivalId;
      }
    }

    // Sync LA State
    _isLALogicallyActive = await _bridgeController.isAnyActivityActive();
    log("TravelLiveActivityHandler: Initial native LA active state: $_isLALogicallyActive");

    if (!_isLALogicallyActive) {
      // If there is no active Live Activity, we reset the internal state
      // If there is, we will let [_processCurrentState] handle it
      _resetLAStateInternal();
    }

    _isFirstValidProcessingPending = true;
    _processCurrentState(statusData: _chainStatusProvider.laStatusInputData.value);
    log("TravelLiveActivityHandler: Activated and monitoring travel status.");
  }

  void deactivate() {
    if (!_isMonitoring) {
      log("TravelLiveActivityHandler: Already inactive.");
      return;
    }

    _statusListenerWorker?.dispose();
    _statusListenerWorker = null;
    _statusEventSubscription?.cancel();
    _statusEventSubscription = null;

    if (_isLALogicallyActive) {
      log("TravelLiveActivityHandler: Deactivating. Ending any active LA via bridge.");
      _bridgeController.endActivity();
    }
    _resetLAState();

    _isMonitoring = false;
    _isFirstValidProcessingPending = false;
    log("TravelLiveActivityHandler: Deactivated. Stopped monitoring.");
  }

  bool _isPlayerStatusHospitalizedAndPotentiallyReturning(
    PlayerStatusColor? currentStatusColor,
    BarsStatusCooldownsModel? model,
  ) {
    if (model == null) return false;
    if (currentStatusColor == PlayerStatusColor.hospital) {
      if ((model.status?.until ?? 0) > (DateTime.now().millisecondsSinceEpoch ~/ 1000) &&
          model.travel != null &&
          model.travel!.destination == "Torn" &&
          (model.travel!.timeLeft ?? 0) > 0) {
        return true;
      }
      return false;
    }
    return false;
  }

  Map<String, dynamic>? _getCurrentTravelDataFromApi(BarsStatusCooldownsModel? model) {
    if (model != null) {
      final travel = model.travel;
      if (travel != null && travel.destination != null && travel.timestamp != null && travel.departed != null) {
        return {
          'destination': travel.destination!,
          'arrivalTimestamp': travel.timestamp!,
          'departureTimestamp': travel.departed!,
        };
      }
    }
    return null;
  }

  void _onStatusDataChanged(StatusObservable? statusData) {
    if (!_isMonitoring) return;
    //log("TravelLiveActivityHandler received new status: ${json.encode(statusData?.barsAndStatusModel?.travel)}");
    _processCurrentState(statusData: statusData);
  }

  void _processCurrentState({StatusObservable? statusData}) async {
    if (!_isMonitoring) {
      return;
    }

    bool isConsideredFirstValidRun = false;
    final apiData = _getCurrentTravelDataFromApi(statusData?.barsAndStatusModel);

    if (_isFirstValidProcessingPending) {
      if (apiData != null) {
        // We have valid API data for the first time this activation cycle
        isConsideredFirstValidRun = true;
        _isFirstValidProcessingPending = false;
        // log("TravelLiveActivityHandler: First valid data processing run.");
      } else {
        // Still waiting for valid data on the first go, do nothing yet.
        return;
      }
    }

    final currentStatusColor = statusData?.statusColor;
    final currentModel = statusData?.barsAndStatusModel;
    final traveling = currentStatusColor == PlayerStatusColor.travel;
    final repatriating = _isPlayerStatusHospitalizedAndPotentiallyReturning(currentStatusColor, currentModel);

    if (apiData == null) {
      // If no travel data from API, end any LA that Dart thinks is active
      if (_isLALogicallyActive) {
        log("TravelLiveActivityHandler: No API travel data. Ending active LA (if any).");
        _bridgeController.endActivity(); // Tell native to end
        _resetLAStateInternal(); // Reset Dart's logical state
      }
      return;
    }

    String travelId = "${apiData['destination']}-${apiData['arrivalTimestamp']}-${apiData['departureTimestamp']}";
    if (repatriating) travelId += "-repat";

    bool shouldStartOrUpdateLA = false;
    Map<String, dynamic>? laArgs;

    final nowSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final arrivalTimestamp = apiData['arrivalTimestamp']!;
    final hasPlayerArrived = nowSeconds >= arrivalTimestamp;

    // --- Main logic to determine LA action ---
    if (traveling || repatriating) {
      // Player is currently traveling or repatriating according to API
      bool isArrivalStale = hasPlayerArrived && (nowSeconds - arrivalTimestamp) > _staleArrivalThresholdSeconds;

      // CASE 0: First valid processing run, player has arrived, and the arrival is "stale"
      if (isConsideredFirstValidRun && hasPlayerArrived && isArrivalStale) {
        log("TravelLiveActivityHandler: CASE 0 - Initial valid run, player arrived, arrival is stale ($travelId).");
        if (_isLALogicallyActive) {
          // If Dart thinks an LA is active (likely adopted by Swift and it's for this stale trip), end it
          log("CASE 0.1: Ending stale LA that was likely adopted by native side.");
          _resetLAState();
        } else {
          // No LA was active, and we won't start one for this stale arrival
          // Mark this stale trip as processed by Dart for this session
          _hasArrivedNotified = true;
          _lastProcessedTravelIdentifier = travelId;
          _currentLAArrivalTimestamp = arrivalTimestamp;
          log("CASE 0.2: No active LA but Dart processed this stale trip already.");
        }
      }
      // CASE 1: Player has arrived (and if it's the first valid run, it's not stale), and arrival not yet notified by LA
      else if (hasPlayerArrived &&
          !_hasArrivedNotified &&
          (!Platform.isAndroid || travelId != _lastArrivalNotifiedTravelId)) {
        log("TravelLiveActivityHandler: CASE 1 - Arrival detected for ${apiData['destination']}. Preparing 'Arrived' LA.");
        laArgs = _buildArgs(apiTravelData: apiData, isRepatriation: repatriating, hasArrived: true);
        shouldStartOrUpdateLA = true;
        _hasArrivedNotified = true;
      }
      // CASE 2: Player is en route (not yet arrived)
      else if (!hasPlayerArrived) {
        // Avoid constant calls to native side BUT also restarting LA if user canceled!
        bool isNewOrDifferentTrip = travelId != _lastProcessedTravelIdentifier;
        // If an LA was adopted (_isLALogicallyActive=true) but Dart's _currentLAArrivalTimestamp is 0 (or different),
        // this mismatch will trigger an update/replacement
        bool arrivalTimeMismatch = _isLALogicallyActive && (arrivalTimestamp != _currentLAArrivalTimestamp);
        bool noLogicalLA = !_isLALogicallyActive;

        // 1. No LA logically active in Dart.
        // 2. Or, an LA is active, but its arrival time doesn't match the current API data.
        // 3. Or, an LA is active, but the trip identifier (dest, arrival, dep) has changed.
        if (noLogicalLA || arrivalTimeMismatch || (_isLALogicallyActive && isNewOrDifferentTrip)) {
          String logReason =
              "Reasons: noLogicalLA=$noLogicalLA, arrivalTimeMismatch=$arrivalTimeMismatch, isNewOrDifferentTripWhileActive=${_isLALogicallyActive && isNewOrDifferentTrip}";
          log("TravelLiveActivityHandler: CASE 2 - Conditions met to start/update LA for ongoing travel. $logReason");
          laArgs = _buildArgs(apiTravelData: apiData, isRepatriation: repatriating, hasArrived: false);
          shouldStartOrUpdateLA = true;
          _hasArrivedNotified = false;
        }
      }
    } else {
      // CASE 3: Player is NOT traveling or repatriating
      if (_isLALogicallyActive) {
        // An LA is active in Dart, but API says player isn't traveling
        if (_hasArrivedNotified && _currentLAArrivalTimestamp > 0) {
          // This was an "Arrived" LA
          // Check if 10 minutes have passed since that arrival
          int elapsedTimeSinceArrival = nowSeconds - _currentLAArrivalTimestamp;
          if (elapsedTimeSinceArrival >= (_arrivedLAAutoEndMinutes * 60)) {
            log("TravelLiveActivityHandler: CASE 3.1 - No longer traveling. 'Arrived' LA was active & 10+ min passed since its arrival. Ending LA.");
            _resetLAState();
          }
        } else {
          // LA was active but it wasn't an "Arrived" state (e.g., was "En Route" and trip ended/cancelled),
          // or we don't have its arrival info.
          log("TravelLiveActivityHandler: CASE 3.2 - No longer traveling. LA was 'En Route' or unknown type. Ending LA immediately.");
          _resetLAState();
        }
      }
    }

    // --- Perform the LA start/update if decided
    if (shouldStartOrUpdateLA && laArgs != null) {
      final bool isArrivalUpdate = laArgs['hasArrived'] == true;
      // log("TravelLiveActivityHandler: Calling bridge to start/update LA with args: $laArgs");
      final LiveUpdateStartResult result = await _bridgeController.startActivity(arguments: laArgs);
      applyStartResult(result);
      if (!result.isSuccess) {
        log("TravelLiveActivityHandler: Native layer reported ${result.status} (${result.reason})");
        return;
      }
      _currentLAArrivalTimestamp = arrivalTimestamp;
      _lastProcessedTravelIdentifier = travelId;
      if (isArrivalUpdate) {
        _lastArrivalNotifiedTravelId = travelId;
        if (Platform.isAndroid) {
          await _prefs.setAndroidLiveActivityTravelLastArrivalId(travelId);
        }
      }

      // Sync with Firebase so that a Cloud Function won't start for this LA
      log("Syncing arrival timestamp $arrivalTimestamp with server...");
      _syncTimestamp(arrivalTimestamp);
    }
  }

  // Does not end the native Live Activity, just resets the internal state
  void _resetLAStateInternal({bool calledFromDeactivate = false}) {
    if (!calledFromDeactivate) {
      log("TravelLiveActivityHandler: Internal state reset (native LA might still exist)");
    }
    _isLALogicallyActive = false;
    _activeSessionId = null;
    _currentLAArrivalTimestamp = 0;
    _hasArrivedNotified = false;
  }

  // Ends the native Live Activity and resets the internal state
  void _resetLAState() {
    _bridgeController.endActivity(sessionId: _activeSessionId);
    _resetLAStateInternal(calledFromDeactivate: true);
    _clearTimestamp();
  }

  Map<String, dynamic> _buildArgs({
    required Map<String, dynamic> apiTravelData,
    required bool isRepatriation,
    required bool hasArrived,
  }) {
    String currentDestinationDisplayName;
    String currentDestinationFlagAsset;
    String originDisplayName;
    String originFlagAsset;
    String vehicleAssetName;
    String activityStateTitle;
    int? earliestReturnTimestamp;
    bool showProgressBar = !hasArrived;

    bool isChristmasTimeValue = _isChristmas();

    if (isRepatriation) {
      currentDestinationDisplayName = "Torn";
      currentDestinationFlagAsset = "ball_torn";
      originDisplayName = "Hospital";
      originFlagAsset = "hospital_origin_icon";
      vehicleAssetName = isChristmasTimeValue ? "sleigh" : "plane_left";
      activityStateTitle = hasArrived ? "Repatriated to" : "Repatriating to";
    } else {
      final String destination = apiTravelData['destination']!;
      if (destination == "Torn") {
        currentDestinationDisplayName = "Torn";
        currentDestinationFlagAsset = "ball_torn";
        originDisplayName = "Abroad";
        originFlagAsset = "world_origin_icon";
        vehicleAssetName = isChristmasTimeValue ? "sleigh" : "plane_left";
        activityStateTitle = hasArrived ? "Returned to" : "Returning to";
      } else {
        currentDestinationDisplayName = destination;
        currentDestinationFlagAsset = "ball_${_normalizeCountryNameForAsset(destination)}";
        originDisplayName = "Torn";
        originFlagAsset = "ball_torn";
        vehicleAssetName = isChristmasTimeValue ? "sleigh" : "plane_right";
        activityStateTitle = hasArrived ? "Arrived in" : "Traveling to";

        if (!hasArrived) {
          int travelDuration = apiTravelData['arrivalTimestamp']! - apiTravelData['departureTimestamp']!;
          if (travelDuration > 0) {
            earliestReturnTimestamp = apiTravelData['arrivalTimestamp']! + travelDuration;
          }
        }
      }
    }

    final int currentDeviceTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    return {
      'currentDestinationDisplayName': currentDestinationDisplayName,
      'currentDestinationFlagAsset': currentDestinationFlagAsset,
      'originDisplayName': originDisplayName,
      'originFlagAsset': originFlagAsset,
      'arrivalTimeTimestamp': apiTravelData['arrivalTimestamp']!,
      'departureTimeTimestamp': apiTravelData['departureTimestamp']!,
      'currentServerTimestamp': currentDeviceTimestamp,
      'vehicleAssetName': vehicleAssetName,
      'earliestReturnTimestamp': earliestReturnTimestamp,
      'activityStateTitle': activityStateTitle,
      'showProgressBar': showProgressBar,
      'hasArrived': hasArrived,
    };
  }

  bool _isChristmas() {
    final now = DateTime.now();
    final christmasStart = DateTime(now.year, 12, 19);
    final christmasEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    return now.isAfter(christmasStart) && now.isBefore(christmasEnd);
  }

  String _normalizeCountryNameForAsset(String countryName) {
    String normalized = countryName.toLowerCase().replaceAll(" ", "-");
    if (normalized == "united-kingdom") return "uk";
    if (normalized == "south-africa") return "south-africa";
    if (normalized == "cayman-islands") return "cayman";
    if (normalized == "united-arab-emirates") return "uae";
    return normalized;
  }

  void _syncTimestamp(int arrivalTimestamp) {
    // This is currently only used for iOS Live Activities sync
    if (!Platform.isIOS) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseRtdbHelper().liveActivityTravelTimestampSync(
        uid: user.uid,
        arrivalTimestamp: arrivalTimestamp,
      );
    }
  }

  void _clearTimestamp() {
    // This is currently only used for iOS Live Activities sync
    if (!Platform.isIOS) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseRtdbHelper().liveActivityClearTimeStamp(uid: user.uid);
    }
  }

  @visibleForTesting
  void applyStartResult(LiveUpdateStartResult result) {
    if (!result.isSuccess) {
      _resetLAStateInternal();
      return;
    }
    if (result.sessionId != null) {
      _activeSessionId = result.sessionId;
    }
    _isLALogicallyActive = true;
  }

  @visibleForTesting
  void handleStatusEvent(LiveUpdateStatusEvent event) {
    // Ignore events for other sessions when we have a known session id.
    if (event.sessionId != null && _activeSessionId != null && event.sessionId != _activeSessionId) {
      return;
    }

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

  @override
  void onClose() {
    _statusEventSubscription?.cancel();
    super.onClose();
  }
}
