import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/api_ping_summary.dart';

void main() {
  test('all replies is a success with min, avg and max', () {
    expect(
      apiPingMessage([300, 100, 200, 101], 4, null),
      "SUCCESS\n\nReceived 4/4\nTime: min 100 ms, avg 175 ms, max 300 ms",
    );
  });

  test('a lost reply is a problem and shows the error', () {
    expect(
      apiPingMessage([120, 80, 100], 4, "timeout"),
      "CONNECTION PROBLEM\n\nReceived 3/4\nTime: min 80 ms, avg 100 ms, max 120 ms\n\ntimeout",
    );
  });

  test('no replies shows only the error', () {
    expect(apiPingMessage([], 4, "Failed host lookup"), "CONNECTION PROBLEM\n\nReceived 0/4\n\nFailed host lookup");
  });
}
