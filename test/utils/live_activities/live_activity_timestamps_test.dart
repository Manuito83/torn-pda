import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/live_activities/live_activity_travel_controller.dart';

void main() {
  group('computeDeviceRelativeTimestamps', () {
    test('computes device-relative arrival from timeLeft', () {
      final result = LiveActivityTravelController.computeDeviceRelativeTimestamps(
        serverArrivalTimestamp: 1000300,
        serverDepartureTimestamp: 1000000,
        timeLeftSeconds: 300,
        deviceNowSeconds: 999800,
      );
      // deviceNow(999800) + timeLeft(300) = 1000100
      expect(result['arrivalTimestamp'], 1000100);
      // departure = arrival - totalDuration = 1000100 - 300 = 999800
      expect(result['departureTimestamp'], 999800);
    });

    test('compensates for device clock offset behind server', () {
      // Server: now=1000000, arrival=1000300, timeLeft=300
      // Device: now=999970 (30s behind server)
      final result = LiveActivityTravelController.computeDeviceRelativeTimestamps(
        serverArrivalTimestamp: 1000300,
        serverDepartureTimestamp: 1000000,
        timeLeftSeconds: 300,
        deviceNowSeconds: 999970,
      );
      // Expected: 999970 + 300 = 1000270 (NOT server's 1000300)
      // Countdown: 1000270 - 999970 = 300s (matches Torn)
      // Without fix: 1000300 - 999970 = 330s (wrong!)
      expect(result['arrivalTimestamp'], 1000270);
      expect(result['departureTimestamp'], 999970);
    });

    test('compensates for device clock offset ahead of server', () {
      // Server: now=1000000, arrival=1000300, timeLeft=300
      // Device: now=1000030 (30s ahead of server)
      final result = LiveActivityTravelController.computeDeviceRelativeTimestamps(
        serverArrivalTimestamp: 1000300,
        serverDepartureTimestamp: 1000000,
        timeLeftSeconds: 300,
        deviceNowSeconds: 1000030,
      );
      // Expected: 1000030 + 300 = 1000330
      // Countdown: 1000330 - 1000030 = 300s (matches Torn)
      expect(result['arrivalTimestamp'], 1000330);
      expect(result['departureTimestamp'], 1000030);
    });

    test('computes consistent departure for progress bar', () {
      final result = LiveActivityTravelController.computeDeviceRelativeTimestamps(
        serverArrivalTimestamp: 1000600,
        serverDepartureTimestamp: 1000000,
        timeLeftSeconds: 300,
        deviceNowSeconds: 1000100,
      );
      // totalDuration = 1000600 - 1000000 = 600
      // arrival = 1000100 + 300 = 1000400
      // departure = 1000400 - 600 = 999800
      expect(result['arrivalTimestamp'], 1000400);
      expect(result['departureTimestamp'], 999800);
      // Progress bar: (now - departure) / (arrival - departure)
      // = (1000100 - 999800) / (1000400 - 999800) = 300/600 = 50%
      final elapsed = 1000100 - result['departureTimestamp']!;
      final total = result['arrivalTimestamp']! - result['departureTimestamp']!;
      expect(elapsed / total, closeTo(0.5, 0.001));
    });

    test('returns server timestamps when timeLeft is null', () {
      final result = LiveActivityTravelController.computeDeviceRelativeTimestamps(
        serverArrivalTimestamp: 1000300,
        serverDepartureTimestamp: 1000000,
        timeLeftSeconds: null,
        deviceNowSeconds: 999970,
      );
      expect(result['arrivalTimestamp'], 1000300);
      expect(result['departureTimestamp'], 1000000);
    });

    test('returns server timestamps when timeLeft is zero', () {
      final result = LiveActivityTravelController.computeDeviceRelativeTimestamps(
        serverArrivalTimestamp: 1000300,
        serverDepartureTimestamp: 1000000,
        timeLeftSeconds: 0,
        deviceNowSeconds: 1000300,
      );
      expect(result['arrivalTimestamp'], 1000300);
      expect(result['departureTimestamp'], 1000000);
    });
  });
}
