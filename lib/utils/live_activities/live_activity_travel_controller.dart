import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';

class LiveActivityTravelController extends GetxController {
  final _chainStatusProvider = Get.find<ChainStatusController>();
  final _bridgeController = Get.find<LiveActivityBridgeController>();

  // Ensure that special "initial check" logic (like ignoring stale old arrivals)
  // is applied only once, specifically during the first processing run that has valid API data
  bool _isFirstValidProcessingPending = false;

  int _currentLAArrivalTimestamp = 0;
  bool _isLALogicallyActive = false;
  String _lastProcessedTravelIdentifier = "";
  bool _hasArrivedNotified = false;
  Timer? _autoEndTimer;

  bool _isMonitoring = false;
  Worker? _statusListenerWorker;

  static const int _staleArrivalThresholdSeconds = 15 * 60;
  static const int _arrivedLAAutoEndMinutes = 10;

  Future<void> activate() async {
    if (_isMonitoring) {
      log("TravelLiveActivityHandler: Already active and monitoring.");
      return;
    }

    if (!Platform.isIOS) {
      log("TravelLiveActivityHandler: Not on iOS, activation skipped.");
      return;
    }

    if (kSdkIos < 16.2) {
      log("TravelLiveActivityHandler: iOS SDK < 16.2, LA not supported. Activation skipped.");
      return;
    }

    _isMonitoring = true;

    // Ensure bridge handler is initialized (it has its own internal guard)
    _bridgeController.initializeHandler();

    _statusListenerWorker = ever(_chainStatusProvider.laStatusInputData, _onStatusDataChanged);

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

    _autoEndTimer?.cancel();
    _autoEndTimer = null;

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
      PlayerStatusColor? currentStatusColor, BarsStatusCooldownsModel? model) {
    if (model == null) return false;
    if (currentStatusColor == PlayerStatusColor.hospital) {
      return ((model.status?.until ?? 0) > (DateTime.now().millisecondsSinceEpoch ~/ 1000)) &&
          (model.travel != null && model.travel!.destination == "Torn");
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

  void _processCurrentState({StatusObservable? statusData}) {
    if (!_isMonitoring) {
      return;
    }

    bool isConsideredFirstValidRun = false;

    final Map<String, dynamic>? apiData = _getCurrentTravelDataFromApi(statusData?.barsAndStatusModel);

    if (_isFirstValidProcessingPending) {
      if (apiData != null) {
        isConsideredFirstValidRun = true;
        _isFirstValidProcessingPending = false;
      } else {
        // log("TravelLiveActivityHandler: Awaiting valid API data for initial processing.");
        return;
      }
    }

    final PlayerStatusColor? currentStatusColor = statusData?.statusColor;
    final BarsStatusCooldownsModel? currentModel = statusData?.barsAndStatusModel;
    final bool traveling = currentStatusColor == PlayerStatusColor.travel;
    final bool repatriating = _isPlayerStatusHospitalizedAndPotentiallyReturning(currentStatusColor, currentModel);

    // Log for debugging the input state
    // log("TravelLiveActivityHandler _processCurrentState - Initial: $isInitialCheck, "
    //  "Monitoring: $_isMonitoring, StatusColor: ${statusData?.statusColor}, "
    //  "TravelDest: ${statusData?.barsAndStatusModel?.travel?.destination}, "
    //  "TravelTS: ${statusData?.barsAndStatusModel?.travel?.timestamp}");

    if (apiData == null ||
        apiData['destination'] == null ||
        apiData['arrivalTimestamp'] == null ||
        apiData['departureTimestamp'] == null) {
      // If no travel data, but a LA is logically active, end it.
      if (_isLALogicallyActive) {
        log("TravelLiveActivityHandler: No API travel data in current StatusObservable or not traveling. Ending any logical LA.");
        _bridgeController.endActivity();
        _resetLAState();
      } else {
        log("TravelLiveActivityHandler: No API travel data available in current StatusObservable. Skipping LA processing.");
      }
      return;
    }

    String travelId = "${apiData['destination']}-${apiData['arrivalTimestamp']}-${apiData['departureTimestamp']}";
    if (repatriating) travelId += "-repat";

    // Cancel any existing auto-end timer (e.g., from a previous "arrived" state)
    _autoEndTimer?.cancel();

    bool shouldStartOrUpdateLA = false;
    Map<String, dynamic>? laArgs;

    final int nowSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final int arrivalTimestamp = apiData['arrivalTimestamp']!;
    final bool hasPlayerArrived = nowSeconds >= arrivalTimestamp;

    // --- Determine if action is needed based on travel status
    if (traveling || repatriating) {
      bool isArrivalStale = hasPlayerArrived && (nowSeconds - arrivalTimestamp) > _staleArrivalThresholdSeconds;

      // CASE 0: Initial check, player has ALREADY arrived at the destination,
      // and no LA is logically active for this past trip.
      // We also check if the arrival is "stale" (too old to start a new "Arrived" LA for).
      if (isConsideredFirstValidRun && hasPlayerArrived && isArrivalStale) {
        log("TravelLiveActivityHandler: CASE 0 - Initial valid run, player arrived, arrival is stale. No LA will be started/ended unless one was adopted.");
        if (_isLALogicallyActive) {
          log("TravelLiveActivityHandler: Ending stale LA adopted by native side.");
          _bridgeController.endActivity();
          _resetLAState();
        } else {
          _hasArrivedNotified = true;
          _lastProcessedTravelIdentifier = travelId;
          _currentLAArrivalTimestamp = arrivalTimestamp;
        }
      }
      // CASE 1: Player has arrived at the destination, and we need to start or update an "Arrived" LA
      else if (hasPlayerArrived && !_hasArrivedNotified) {
        log("TravelLiveActivityHandler: CASE 1 - Arrival detected for ${apiData['destination']}. Preparing 'Arrived' LA.");
        laArgs = _buildArgs(apiTravelData: apiData, isRepatriation: repatriating, hasArrived: true);
        shouldStartOrUpdateLA = true;
        _hasArrivedNotified = true;
        _autoEndTimer = Timer(const Duration(minutes: _arrivedLAAutoEndMinutes), () {
          if (_isLALogicallyActive && _currentLAArrivalTimestamp == arrivalTimestamp) {
            log("TravelLiveActivityHandler: Auto-ending 'Arrived' LA.");
            _bridgeController.endActivity();
            _resetLAState();
          }
        });
      }
      // CASE 2: Player is en route (not yet arrived).
      else if (!hasPlayerArrived) {
        // Determine if we need to start a new LA or update an existing one.
        // Conditions to start/update:
        // 1. `noLogicalLA`: Our Dart logic doesn't think an LA is active for the current trip.
        // 2. `arrivalTimeMismatch`: The arrival time of the current API trip
        //    is different from the arrival time of the LA we think is active (implies a new or changed trip).
        // 3. `initialCheckAndNoNativeToken`: It's the first processing after activation, AND
        //    the native side reports no push token for its current LA. This could mean
        //    no LA is active natively, or it's active but without a token.
        //    This encourages starting a new LA to ensure it's set up correctly, especially if tokens are desired.
        // 4. `isNewOrDifferentTrip`: Details of the trip (destination, arrival, departure)
        //    have changed, indicating a completely new trip.

        bool isNewOrDifferentTrip = travelId != _lastProcessedTravelIdentifier;
        bool noLogicalLA = !_isLALogicallyActive;
        bool arrivalTimeMismatch = arrivalTimestamp != _currentLAArrivalTimestamp;

        // This condition helps ensure that on an initial check, if the native side
        // doesn't report a push token (implying no LA or an LA without a token),
        // we attempt to start/update it from Dart to ensure proper setup.
        bool initialCheckAndNoNativeToken =
            isConsideredFirstValidRun && _bridgeController.currentActivityPushToken == null;

        if (noLogicalLA || arrivalTimeMismatch || initialCheckAndNoNativeToken || isNewOrDifferentTrip) {
          // log("TravelLiveActivityHandler: CASE 2 - Conditions met to start/update LA for ongoing travel."); // Log opcional
          laArgs = _buildArgs(apiTravelData: apiData, isRepatriation: repatriating, hasArrived: false);
          shouldStartOrUpdateLA = true;
          _hasArrivedNotified = false;
        }
      }
      // CASE 3: Player has arrived, and we've already processed this "Arrived" state.
      else if (hasPlayerArrived && _hasArrivedNotified) {
        // log("TravelLiveActivityHandler: Already arrived and 'Arrived' state processed. LA remains.");
      }
    } else {
      // CASE 4: NOT traveling or repatriating according to API data.
      if (_isLALogicallyActive) {
        log("TravelLiveActivityHandler: CASE 4 - Not traveling. Ending active LA.");
        _bridgeController.endActivity();
        _resetLAState();
      }
    }

    // --- Perform the necessary LA changes
    if (shouldStartOrUpdateLA && laArgs != null) {
      log("TravelLiveActivityHandler: Calling native startActivity with args: $laArgs");
      // The bridge controller should handle if it's a start or an update internally
      // based on whether an activity is already active natively for this type.
      _bridgeController.startActivity(arguments: laArgs);
      _isLALogicallyActive = true;
      _currentLAArrivalTimestamp = apiData['arrivalTimestamp'];
      _lastProcessedTravelIdentifier = travelId;
    }
  }

  void _resetLAState() {
    _isLALogicallyActive = false;
    _currentLAArrivalTimestamp = 0;
    _lastProcessedTravelIdentifier = "ended_or_reset_${DateTime.now().millisecondsSinceEpoch}";
    _hasArrivedNotified = false;
    _autoEndTimer?.cancel();
    _autoEndTimer = null;
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
}
