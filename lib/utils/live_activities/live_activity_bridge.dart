import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/live_activities/live_update_models.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum LiveActivityType {
  travel,
  racing,
}

class LiveActivityBridgeController extends GetxController {
  LiveActivityBridgeController({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.tornpda.liveactivity');

  final MethodChannel _channel;

  // Most recent push token for the current Live Activity instance
  String? _currentActivityPushToken;
  String? get currentActivityPushToken => _currentActivityPushToken;
  final Map<LiveActivityType, String?> _currentActivityPushTokens = {};

  bool _isInitialized = false;

  final _statusEvents = StreamController<LiveUpdateStatusEvent>.broadcast();
  final _capabilitySnapshots = StreamController<LiveUpdateCapabilitySnapshot>.broadcast();
  LiveUpdateCapabilitySnapshot? _latestCapabilitySnapshot;

  Stream<LiveUpdateStatusEvent> get statusEvents => _statusEvents.stream;
  Stream<LiveUpdateCapabilitySnapshot> get capabilitySnapshots => _capabilitySnapshots.stream;
  LiveUpdateCapabilitySnapshot? get latestCapabilitySnapshot => _latestCapabilitySnapshot;

  void initializeHandler() {
    if (_isInitialized) return;
    _channel.setMethodCallHandler(_handleNativeMethodCalls);
    _isInitialized = true;
    log("LiveActivityBridgeService: Native method call handler initialized.");
  }

  Future<void> _handleNativeMethodCalls(MethodCall call) async {
    log("LiveActivityBridgeService: Received call from native: ${call.method}");
    if (call.method == "liveActivityTokenUpdated") {
      final args = (call.arguments as Map?)?.cast<String, dynamic>();
      final String? activityTypeRaw = args?['activityType'] as String?;
      final String? token = args?['token'] as String?;
      _currentActivityPushToken = token;

      if (activityTypeRaw != null) {
        final LiveActivityType? activityType = _activityTypeFromWireValue(activityTypeRaw);
        if (activityType != null) {
          _currentActivityPushTokens[activityType] = token;
          await firebaseFunctions.registerLiveActivityActivityToken(
            token: token,
            activityType: activityType.name,
          );
        }
      }
    } else if (call.method == "liveUpdateStatusChanged") {
      final args = (call.arguments as Map?)?.cast<String, dynamic>();
      if (args != null) {
        final event = LiveUpdateStatusEvent.fromJson(args);
        _statusEvents.add(event);
      }
    } else if (call.method == "liveUpdateCapabilityChanged") {
      final args = (call.arguments as Map?)?.cast<String, dynamic>();
      if (args != null) {
        final snapshot = LiveUpdateCapabilitySnapshot.fromJson(args);
        _emitCapabilitySnapshot(snapshot);
      }
    }
  }

  Future<LiveUpdateStartResult> startActivity({
    required Map<String, dynamic> arguments,
  }) async {
    if (!_isInitialized) {
      log("LiveActivityBridgeService: Handler not initialized. Initializing now...");
      initializeHandler();
    }
    try {
      final dynamic response = await _channel.invokeMethod('startTravelActivity', arguments);
      final result = LiveUpdateStartResult.fromDynamic(response);
      if (result.capabilitySnapshot != null) {
        _emitCapabilitySnapshot(result.capabilitySnapshot!);
      }
      return result;
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException during start/update: ${e.message} - Details: ${e.details}");
      return LiveUpdateStartResult(
        status: LiveUpdateRequestStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      log("LiveActivityBridgeService: Generic error during start/update: $e");
      return const LiveUpdateStartResult(status: LiveUpdateRequestStatus.error);
    }
  }

  Future<LiveUpdateStartResult> startRacingActivity({
    required Map<String, dynamic> arguments,
  }) async {
    if (!_isInitialized) {
      initializeHandler();
    }
    try {
      final dynamic response = await _channel.invokeMethod('startRacingActivity', arguments);
      final result = LiveUpdateStartResult.fromDynamic(response);
      if (result.capabilitySnapshot != null) {
        _emitCapabilitySnapshot(result.capabilitySnapshot!);
      }
      return result;
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException during racing start/update: ${e.message} - Details: ${e.details}");
      return LiveUpdateStartResult(
        status: LiveUpdateRequestStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      log("LiveActivityBridgeService: Generic error during racing start/update: $e");
      return const LiveUpdateStartResult(status: LiveUpdateRequestStatus.error);
    }
  }

  Future<LiveUpdateEndResult> endActivity({String? sessionId}) async {
    if (!_isInitialized) initializeHandler();
    try {
      final dynamic response = await _channel.invokeMethod(
        'endTravelActivity',
        sessionId == null ? null : {'sessionId': sessionId},
      );
      log("LiveActivityBridgeService: endTravelActivity method invoked.");
      return LiveUpdateEndResult.fromDynamic(response);
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException ending activity: ${e.message} - Details: ${e.details}");
      return LiveUpdateEndResult(success: false, errorMessage: e.message);
    } catch (e) {
      log("LiveActivityBridgeService: Generic error ending activity: $e");
      return const LiveUpdateEndResult(success: false);
    }
  }

  Future<bool> isAnyActivityActive() async {
    if (!_isInitialized) initializeHandler();
    try {
      final bool isActive = await _channel.invokeMethod('isAnyTravelActivityActive');
      return isActive;
    } catch (e) {
      log("LiveActivityBridgeService: Error checking if any activity is active: $e");
      return false;
    }
  }

  Future<LiveUpdateEndResult> endRacingActivity() async {
    if (!_isInitialized) initializeHandler();
    try {
      final dynamic response = await _channel.invokeMethod('endRacingActivity');
      log("LiveActivityBridgeService: endRacingActivity method invoked.");
      return LiveUpdateEndResult.fromDynamic(response);
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException ending racing activity: ${e.message} - Details: ${e.details}");
      return LiveUpdateEndResult(success: false, errorMessage: e.message);
    } catch (e) {
      log("LiveActivityBridgeService: Generic error ending racing activity: $e");
      return const LiveUpdateEndResult(success: false);
    }
  }

  Future<bool> isAnyRacingActivityActive() async {
    if (!_isInitialized) initializeHandler();
    try {
      final bool isActive = await _channel.invokeMethod('isAnyRacingActivityActive');
      return isActive;
    } catch (e) {
      log("LiveActivityBridgeService: Error checking if any racing activity is active: $e");
      return false;
    }
  }

  Future<LiveUpdateCapabilitySnapshot?> getLiveUpdateCapabilities() async {
    if (!_isInitialized) initializeHandler();
    try {
      final dynamic response = await _channel.invokeMethod('getLiveUpdateCapabilities');
      if (response is Map) {
        final snapshot = LiveUpdateCapabilitySnapshot.fromJson(response.cast<String, dynamic>());
        _emitCapabilitySnapshot(snapshot);
        return snapshot;
      }
    } catch (e) {
      log("LiveActivityBridgeService: Error getting capability snapshot: $e");
    }
    return _latestCapabilitySnapshot;
  }

  Future<void> getPushToStartTokenAndSendToFirebase({
    required LiveActivityType activityType,
    required bool force,
  }) async {
    final String? tokenToUpdate = await _getUpdatedLiveActivityTokenIfNeeded(
      activityType: activityType,
      force: force,
    );

    if (tokenToUpdate != null) {
      log("Token for '${activityType.name}' needs update. Sending to server...");

      await firebaseFunctions.registerLiveActivityPushToStartToken(
        token: tokenToUpdate,
        activityType: activityType.name,
      );

      await Prefs().setLaPushToken(activityType: activityType, token: tokenToUpdate);
      log("Token for '${activityType.name}' sent and stored.");
    }
  }

  Future<String?> getPushToStartTokenOnly({
    required LiveActivityType activityType,
  }) async {
    return await _getUpdatedLiveActivityTokenIfNeeded(
      activityType: activityType,
      force: false,
    );
  }

  String? currentActivityPushTokenFor(LiveActivityType activityType) {
    return _currentActivityPushTokens[activityType];
  }

  Future<String?> _getUpdatedLiveActivityTokenIfNeeded({
    required LiveActivityType activityType,
    required bool force,
  }) async {
    if (!_isInitialized) initializeHandler();

    try {
      final String? newToken = await _channel.invokeMethod(
        'getPushToStartToken',
        {'activityType': activityType.name},
      );

      if (newToken == null || newToken.isEmpty) {
        log("LiveActivityBridge: Swift returned null for '${activityType.name}'");
        return null;
      }

      if (force) {
        log("LiveActivityBridge: Force update for '${activityType.name}'");
        return newToken;
      }

      final String? storedToken = await Prefs().getLaPushToken(activityType: activityType);
      if (newToken != storedToken) {
        log("LiveActivityBridge: New token for '${activityType.name}' detected");
        return newToken;
      }

      log("LiveActivityBridge: Token for '${activityType.name}' is unchanged");
      return null;
    } catch (e) {
      log("LiveActivityBridge: Error getting token for '${activityType.name}': $e");
      return null;
    }
  }

  LiveActivityType? _activityTypeFromWireValue(String rawValue) {
    switch (rawValue) {
      case 'travel':
        return LiveActivityType.travel;
      case 'racing':
        return LiveActivityType.racing;
      default:
        return null;
    }
  }

  void _emitCapabilitySnapshot(LiveUpdateCapabilitySnapshot snapshot) {
    _latestCapabilitySnapshot = snapshot;
    if (!_capabilitySnapshots.isClosed) {
      _capabilitySnapshots.add(snapshot);
    }
  }

  @visibleForTesting
  Future<void> handleMockMethodCall(String method, Map<String, dynamic> arguments) {
    return _handleNativeMethodCalls(MethodCall(method, arguments));
  }

  @override
  void onClose() {
    _statusEvents.close();
    _capabilitySnapshots.close();
    super.onClose();
  }
}
