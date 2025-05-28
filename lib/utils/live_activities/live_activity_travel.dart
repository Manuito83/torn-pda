// lib/features/live_activity/travel_live_activity_handler.dart
import 'dart:async';
import 'dart:developer';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';

class TravelLiveActivityHandler {
  final ChainStatusProvider _chainStatusProvider;
  final LiveActivityBridgeService _bridgeService;

  int _currentLAArrivalTimestamp = 0;
  bool _isLALogicallyActive = false;
  String _lastProcessedTravelIdentifier = "";
  bool _hasArrivedNotified = false;

  Timer? _autoEndTimer;

  TravelLiveActivityHandler({
    required ChainStatusProvider chainStatusProvider,
    required LiveActivityBridgeService bridgeService,
  })  : _chainStatusProvider = chainStatusProvider,
        _bridgeService = bridgeService {
    _initialize();
  }

  bool get _isPlayerStatusHospitalizedAndPotentiallyReturning {
    if (_chainStatusProvider.statusColorCurrent == PlayerStatusColor.hospital &&
        _chainStatusProvider.barsAndStatusModel != null) {
      final data = _chainStatusProvider.barsAndStatusModel!;
      return ((data.status?.until ?? 0) > (DateTime.now().millisecondsSinceEpoch ~/ 1000)) &&
          (data.travel != null && data.travel!.destination == "Torn");
    }
    return false;
  }

  Map<String, dynamic>? get _currentTravelDataFromApi {
    if (_chainStatusProvider.barsAndStatusModel != null) {
      final travel = _chainStatusProvider.barsAndStatusModel!.travel;
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

  void _initialize() {
    _chainStatusProvider.addListener(_onProviderChanged);
    _bridgeService.checkExistingActivities();
    _processCurrentState(isInitialCheck: true);
    log("TravelLiveActivityHandler: Initialized.");
  }

  void _onProviderChanged() {
    _processCurrentState();
  }

  void _processCurrentState({bool isInitialCheck = false}) {
    final bool isPlayerTraveling = _chainStatusProvider.statusColorCurrent == PlayerStatusColor.travel;
    final bool isPlayerRepatriating = _isPlayerStatusHospitalizedAndPotentiallyReturning;
    final Map<String, dynamic>? apiTravelDataMap = _currentTravelDataFromApi;
    final int nowSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    String currentTravelIdentifier = apiTravelDataMap != null
        ? "${apiTravelDataMap['destination']}-${apiTravelDataMap['arrivalTimestamp']}-${apiTravelDataMap['departureTimestamp']}"
        : "no_travel_data";

    if (isPlayerRepatriating) currentTravelIdentifier += "-repat";

    //log("TravelLiveActivityHandler: Processing. Traveling: $isPlayerTraveling, Repatriating: $isPlayerRepatriating, TravelData: ${apiTravelDataMap?.toString()}, IsActiveLA: $_isLALogicallyActive, ArrivalTS: $_currentLAArrivalTimestamp, HasArrivedNotified: $_hasArrivedNotified");

    _autoEndTimer?.cancel();

    bool shouldStartOrUpdateLA = false;
    Map<String, dynamic>? activityArgs;
    bool currentTripHasArrived = false;

    if (apiTravelDataMap != null && (isPlayerTraveling || isPlayerRepatriating)) {
      currentTripHasArrived = nowSeconds >= apiTravelDataMap['arrivalTimestamp']!;

      if (currentTripHasArrived && !_hasArrivedNotified) {
        log("TravelLiveActivityHandler: Arrival detected for ${apiTravelDataMap['destination']}. Preparing 'Arrived' LA state.");
        activityArgs = _prepareTravelArguments(
            apiTravelData: apiTravelDataMap, isRepatriation: isPlayerRepatriating, hasArrived: true);
        shouldStartOrUpdateLA = true;
        _hasArrivedNotified = true;

        _autoEndTimer = Timer(const Duration(minutes: 30), () {
          if (_isLALogicallyActive && _currentLAArrivalTimestamp == apiTravelDataMap['arrivalTimestamp']!) {
            log("TravelLiveActivityHandler: Auto-ending LA after 30 minutes of arrival.");
            _bridgeService.endActivity();
            _resetLAState();
          }
        });
      } else if (!currentTripHasArrived) {
        if (!_isLALogicallyActive ||
            apiTravelDataMap['arrivalTimestamp']! != _currentLAArrivalTimestamp ||
            (isInitialCheck && _bridgeService.currentActivityPushToken == null) ||
            currentTravelIdentifier != _lastProcessedTravelIdentifier) {
          String logMsg = isPlayerRepatriating
              ? "User is being repatriated. Preparing LA."
              : "User is on normal travel to ${apiTravelDataMap['destination']}. Preparing LA.";
          log("TravelLiveActivityHandler: $logMsg");

          activityArgs = _prepareTravelArguments(
              apiTravelData: apiTravelDataMap, isRepatriation: isPlayerRepatriating, hasArrived: false);
          shouldStartOrUpdateLA = true;
          _hasArrivedNotified = false;
        }
      } else if (currentTripHasArrived && _hasArrivedNotified) {
        //log("TravelLiveActivityHandler: Already arrived and 'Arrived' state sent. LA remains until auto-end or new trip.");
      }
    } else {
      if (_isLALogicallyActive) {
        log("TravelLiveActivityHandler: No relevant travel/repatriation conditions met. Ending LA.");
        _bridgeService.endActivity();
        _resetLAState();
      }
    }

    if (shouldStartOrUpdateLA && activityArgs != null) {
      _bridgeService.startActivity(arguments: activityArgs);
      _isLALogicallyActive = true;
      _currentLAArrivalTimestamp = apiTravelDataMap!['arrivalTimestamp']!;
      _lastProcessedTravelIdentifier = currentTravelIdentifier;
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

  Map<String, dynamic> _prepareTravelArguments({
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

    bool isChristmasTime = _isChristmas();

    if (isRepatriation) {
      currentDestinationDisplayName = "Torn";
      currentDestinationFlagAsset = "ball_torn";
      originDisplayName = "Hospital";
      originFlagAsset = "hospital_origin_icon";
      vehicleAssetName = isChristmasTime ? "sleigh" : "plane_left";
      activityStateTitle = hasArrived ? "Repatriated to" : "Repatriating to";
    } else {
      final String destination = apiTravelData['destination']!;
      if (destination == "Torn") {
        currentDestinationDisplayName = "Torn";
        currentDestinationFlagAsset = "ball_torn";
        originDisplayName = "Abroad";
        originFlagAsset = "world_origin_icon";
        vehicleAssetName = isChristmasTime ? "sleigh" : "plane_left";
        activityStateTitle = hasArrived ? "Returned to" : "Returning to";
      } else {
        currentDestinationDisplayName = destination;
        currentDestinationFlagAsset = "ball_${_normalizeCountryNameForAsset(destination)}";
        originDisplayName = "Torn";
        originFlagAsset = "ball_torn";
        vehicleAssetName = isChristmasTime ? "sleigh" : "plane_right";
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

  void dispose() {
    _autoEndTimer?.cancel();
    _chainStatusProvider.removeListener(_onProviderChanged);
    log("TravelLiveActivityHandler: Disposed.");
  }
}
