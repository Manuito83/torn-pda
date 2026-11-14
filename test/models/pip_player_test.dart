import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chaining/watch_defcon.dart';
import 'package:torn_pda/models/pip/pip_player.dart';

void main() {
  test('panic mode shows when the alert fires', () {
    expect(pipWatchLabel(WatchDefcon.green2, panicMode: true, panicValue: 125), 'PANIC AT 02:05');
    expect(pipWatchLabel(WatchDefcon.green2, panicMode: false, panicValue: 125), '');
  });

  test('a failed API says so even in panic mode', () {
    expect(pipWatchLabel(WatchDefcon.apiFail, panicMode: true, panicValue: 125), 'API FAILED');
  });
}
