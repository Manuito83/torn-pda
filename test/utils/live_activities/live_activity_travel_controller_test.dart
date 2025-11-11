import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/live_activity_travel_controller.dart';
import 'package:torn_pda/utils/live_activities/live_update_models.dart';

class _StubBridgeController extends LiveActivityBridgeController {
  _StubBridgeController() : super(channel: const MethodChannel('test.live.activity')); // Never invoked in tests.
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<ChainStatusController>(ChainStatusController());
    Get.put<LiveActivityBridgeController>(_StubBridgeController());
  });

  tearDown(() {
    Get.reset();
  });

  LiveActivityTravelController buildController() {
    final controller = LiveActivityTravelController();
    return controller;
  }

  test('applyStartResult marks session active on success', () {
    final controller = buildController();

    controller.applyStartResult(const LiveUpdateStartResult(
      status: LiveUpdateRequestStatus.started,
      sessionId: 'session-a',
    ));

    expect(controller.isLiveActivityActiveForTest, isTrue);
    expect(controller.activeSessionIdForTest, 'session-a');
  });

  test('applyStartResult resets when unsupported', () {
    final controller = buildController();
    controller.applyStartResult(const LiveUpdateStartResult(
      status: LiveUpdateRequestStatus.started,
      sessionId: 'session-a',
    ));

    controller.applyStartResult(const LiveUpdateStartResult(
      status: LiveUpdateRequestStatus.unsupported,
      reason: LiveUpdateUnsupportedReason.permissionDenied,
    ));

    expect(controller.isLiveActivityActiveForTest, isFalse);
    expect(controller.activeSessionIdForTest, isNull);
  });

  test('handleStatusEvent clears logical state on timeout for matching session', () {
    final controller = buildController();
    controller.applyStartResult(const LiveUpdateStartResult(
      status: LiveUpdateRequestStatus.started,
      sessionId: 'session-a',
    ));

    controller.handleStatusEvent(const LiveUpdateStatusEvent(
      sessionId: 'session-a',
      status: LiveUpdateLifecycleStatus.timeout,
      surface: LiveUpdateSurface.lockscreen,
    ));

    expect(controller.isLiveActivityActiveForTest, isFalse);
  });
  
  test('handleStatusEvent ignores mismatched sessions', () {
    final controller = buildController();
    controller.applyStartResult(const LiveUpdateStartResult(
      status: LiveUpdateRequestStatus.started,
      sessionId: 'session-a',
    ));

    controller.handleStatusEvent(const LiveUpdateStatusEvent(
      sessionId: 'different',
      status: LiveUpdateLifecycleStatus.timeout,
      surface: LiveUpdateSurface.lockscreen,
    ));

    expect(controller.isLiveActivityActiveForTest, isTrue);
    expect(controller.activeSessionIdForTest, 'session-a');
  });

  test('handleStatusEvent clears state on dismissed when session unknown', () {
    final controller = buildController();
    controller.applyStartResult(const LiveUpdateStartResult(
      status: LiveUpdateRequestStatus.started,
      sessionId: 'session-a',
    ));

    controller.handleStatusEvent(const LiveUpdateStatusEvent(
      sessionId: null,
      status: LiveUpdateLifecycleStatus.dismissed,
      surface: LiveUpdateSurface.notification,
    ));

    expect(controller.isLiveActivityActiveForTest, isFalse);
  });

  test('handleStatusEvent does nothing when event not terminal', () {
    final controller = buildController();
    controller.applyStartResult(const LiveUpdateStartResult(
      status: LiveUpdateRequestStatus.started,
      sessionId: 'session-a',
    ));

    controller.handleStatusEvent(const LiveUpdateStatusEvent(
      sessionId: 'session-a',
      status: LiveUpdateLifecycleStatus.updated,
      surface: LiveUpdateSurface.lockscreen,
    ));

    expect(controller.isLiveActivityActiveForTest, isTrue);
  });
}
