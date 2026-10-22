import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_telemetry.dart';

void main() {
  final sent = <List<Object>>[];

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    ChatTelemetry.reset();
    sent.clear();
    ChatTelemetry.debugSink = (name, params) => sent.add([name, params]);
  });

  tearDown(() => ChatTelemetry.debugSink = null);

  Future<void> report(ChatPrefs prefs, {bool loaded = false}) =>
      ChatTelemetry.report(prefs, remote: true, loaded: loaded);

  test('background inbox is drained once', () async {
    await ChatTelemetry.reply('timeout', main: false);
    await ChatTelemetry.reply('sent', main: false);
    await ChatTelemetry.push('shown');
    await ChatTelemetry.push('shown');
    await ChatTelemetry.push('suppressed_rules');

    await ChatTelemetry.flush();
    await ChatTelemetry.flush();
    expect(sent.map((e) => (e[1] as Map)['outcome']), ['timeout', 'sent']);

    sent.clear();
    await report(ChatPrefs());
    expect(sent, [
      [
        'chat_usage_daily',
        {'feature': 'notif_reply', 'count': 1},
      ],
      [
        'chat_push_daily',
        {'outcome': 'shown', 'count': 2},
      ],
      [
        'chat_push_daily',
        {'outcome': 'suppressed_rules', 'count': 1},
      ],
    ]);
  });

  test('daily report once a day, settings only when not default', () async {
    final prefs = ChatPrefs()..ticker = false;
    await ChatTelemetry.count('open_bubble');
    await report(prefs, loaded: true);
    await report(prefs, loaded: true);
    expect(sent, [
      [
        'chat_setting_daily',
        {'setting': 'ticker', 'option': 'off'},
      ],
      [
        'chat_usage_daily',
        {'feature': 'open_bubble', 'count': 1},
      ],
    ]);

    sent.clear();
    prefs.inAppEnabled = false;
    await report(prefs, loaded: true);
    expect(sent, [
      [
        'chat_mode_changed',
        {'mode': 'dm_push_only'},
      ],
    ]);

    // A restart the same day sends nothing
    sent.clear();
    ChatTelemetry.reset();
    await ChatTelemetry.count('open_bubble');
    await report(prefs, loaded: true);
    expect(sent, isEmpty);
  });

  test('hidden browser facts', () {
    ChatTelemetry.health({'fact': 'connect', 'outcome': 'connected', 'ms': 7000, 'cold': true});
    ChatTelemetry.health({'fact': 'connect', 'outcome': 'connected', 'ms': 300});
    ChatTelemetry.health({'fact': 'connect', 'outcome': 'offline', 'ms': 90000});
    ChatTelemetry.health({'fact': 'lost', 'reason': 'Bravo [7]', 'autologin': 'ok'});
    expect(sent, [
      [
        'chat_connect',
        {'outcome': 'connected', 'ms_bucket': '<15s', 'cold': '1'},
      ],
      [
        'chat_connect',
        {'outcome': 'offline', 'ms_bucket': '>60s', 'cold': '0'},
      ],
      [
        'chat_session_lost',
        {'reason': 'other', 'autologin': 'ok'},
      ],
    ]);
  });
}
