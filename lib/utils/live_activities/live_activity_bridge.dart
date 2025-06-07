import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class LiveActivityBridgeController extends GetxController {
  static const MethodChannel _channel = MethodChannel('com.tornpda.liveactivity');

  // Stores the most recent push token received from the native side for the current Live Activity
  // This token is specific to an active Live Activity instance and would be used if sending
  // remote push notifications (e.g., for 'end' or 'update' events) directly to APNs for this LA
  // Currently, this token is stored locally in the bridge service but not actively sent to a backend
  String? _currentActivityPushToken;
  String? get currentActivityPushToken => _currentActivityPushToken;

  bool _isInitialized = false;

  void initializeHandler() {
    if (_isInitialized) return;
    _channel.setMethodCallHandler(_handleNativeMethodCalls);
    _isInitialized = true;
    log("LiveActivityBridgeService: Native method call handler initialized.");
  }

  Future<void> _handleNativeMethodCalls(MethodCall call) async {
    log("LiveActivityBridgeService: Received call from native: ${call.method}");
    if (call.method == "liveActivityTokenUpdated") {
      _currentActivityPushToken = call.arguments as String?;
    }
  }

  Future<void> startActivity({
    required Map<String, dynamic> arguments,
  }) async {
    if (!_isInitialized) {
      log("LiveActivityBridgeService: Handler not initialized. Initializing now...");
      initializeHandler();
    }
    try {
      await _channel.invokeMethod('startTravelActivity', arguments);
      //log("LiveActivityBridgeService: Invoking startTravelActivity with args: $arguments");
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException during start/update: ${e.message} - Details: ${e.details}");
    } catch (e) {
      log("LiveActivityBridgeService: Generic error during start/update: $e");
    }
  }

  Future<void> endActivity() async {
    if (!_isInitialized) initializeHandler();
    try {
      await _channel.invokeMethod('endTravelActivity');
      log("LiveActivityBridgeService: endTravelActivity method invoked.");
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException ending activity: ${e.message} - Details: ${e.details}");
    } catch (e) {
      log("LiveActivityBridgeService: Generic error ending activity: $e");
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
}
