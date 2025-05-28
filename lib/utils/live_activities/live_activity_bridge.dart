// lib/services/live_activity_bridge_service.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LiveActivityBridgeService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.tornpda.liveactivity');

  String? _currentActivityPushToken;
  String? get currentActivityPushToken => _currentActivityPushToken;

  bool _isInitialized = false;

  void initializeHandler() {
    if (_isInitialized) return;
    _channel.setMethodCallHandler(_handleNativeMethodCalls);
    _isInitialized = true;
    log("LiveActivityBridgeService: Native method call handler initialized.");
    checkExistingActivities();
  }

  Future<void> _handleNativeMethodCalls(MethodCall call) async {
    log("LiveActivityBridgeService: Received call from native: ${call.method}");
    if (call.method == "liveActivityTokenUpdated") {
      _currentActivityPushToken = call.arguments as String?;
      log("LiveActivityBridgeService: Received Push Token: $_currentActivityPushToken");
      notifyListeners();

      if (_currentActivityPushToken != null) {
        // TODO
      }
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
      log("LiveActivityBridgeService: Invoking startTravelActivity with args: $arguments");
      await _channel.invokeMethod('startTravelActivity', arguments);
      log("LiveActivityBridgeService: startTravelActivity method invoked.");
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException during start/update: ${e.message} - Details: ${e.details}");
    } catch (e) {
      log("LiveActivityBridgeService: Generic error during start/update: $e");
    }
  }

  Future<void> endActivity() async {
    if (!_isInitialized) initializeHandler();
    try {
      log("LiveActivityBridgeService: Invoking endTravelActivity.");
      await _channel.invokeMethod('endTravelActivity');
      if (_currentActivityPushToken != null) {
        _currentActivityPushToken = null;
        notifyListeners();
      }
      log("LiveActivityBridgeService: endTravelActivity method invoked.");
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException ending activity: ${e.message} - Details: ${e.details}");
    } catch (e) {
      log("LiveActivityBridgeService: Generic error ending activity: $e");
    }
  }

  Future<void> checkExistingActivities() async {
    if (!_isInitialized) initializeHandler();
    try {
      await _channel.invokeMethod('checkExistingActivities');
    } on PlatformException catch (e) {
      log("LiveActivityBridgeService: PlatformException checking existing: ${e.message} - Details: ${e.details}");
    } catch (e) {
      log("LiveActivityBridgeService: Generic error checking existing: $e");
    }
  }
}
