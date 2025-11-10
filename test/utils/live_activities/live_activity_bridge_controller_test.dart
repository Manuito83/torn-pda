import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/live_update_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.tornpda.liveactivity');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('startActivity treats null native responses as started results', () async {
    final controller = LiveActivityBridgeController();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'startTravelActivity');
      return null;
    });

    final result = await controller.startActivity(arguments: {'foo': 'bar'});
    expect(result.status, LiveUpdateRequestStatus.started);
    expect(result.sessionId, isNull);
  });

  test('startActivity parses structured responses and stores capability snapshot', () async {
    final controller = LiveActivityBridgeController();
    final snapshotPayload = {
      'supportedApi': true,
      'oemCapsule': true,
      'notificationsEnabled': false,
      'batteryOptimized': false,
      'vendor': 'oneplus',
      'timestamp': 12345,
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'startTravelActivity') {
        return {
          'status': 'updated',
          'sessionId': 'session-1',
          'capabilitySnapshot': snapshotPayload,
        };
      }
      return null;
    });

    final result = await controller.startActivity(arguments: {'foo': 'bar'});
    expect(result.status, LiveUpdateRequestStatus.updated);
    expect(result.sessionId, 'session-1');
    expect(result.capabilitySnapshot?.vendor, 'oneplus');
    expect(controller.latestCapabilitySnapshot?.oemCapsule, isTrue);
  });

  test('status event stream surfaces native callbacks', () async {
    final controller = LiveActivityBridgeController();
    final eventFuture = controller.statusEvents.first;

    await controller.handleMockMethodCall('liveUpdateStatusChanged', {
      'sessionId': 'abc',
      'status': 'timeout',
      'surface': 'lockscreen',
    });

    final event = await eventFuture;
    expect(event.sessionId, 'abc');
    expect(event.status, LiveUpdateLifecycleStatus.timeout);
  });

  test('capability stream updates when native capability change arrives', () async {
    final controller = LiveActivityBridgeController();
    final streamFuture = controller.capabilitySnapshots.first;

    await controller.handleMockMethodCall('liveUpdateCapabilityChanged', {
      'supportedApi': false,
      'oemCapsule': false,
      'notificationsEnabled': true,
      'batteryOptimized': true,
      'vendor': 'pixel',
      'timestamp': 6789,
    });

    final snapshot = await streamFuture;
    expect(snapshot.vendor, 'pixel');
    expect(controller.latestCapabilitySnapshot?.supportedApi, isFalse);
  });
}
