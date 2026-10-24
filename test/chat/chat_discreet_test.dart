import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/discreet_schedule.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  const plugin = MethodChannel('dexterous.com/flutter/local_notifications');
  final shown = <Map>[];
  final push = {'event': 'tchat', 'kind': 'dm', 'userId': '7', 'sender': 'Bravo', 'message': 'hello'};
  final skip = NativeChat.compiled ? false : 'Native chat not configured';

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(plugin, (call) async {
      if (call.method == 'show') shown.add(call.arguments as Map);
      return null;
    });
    FlutterLocalNotificationsPlatform.instance = AndroidFlutterLocalNotificationsPlugin();
  });

  tearDownAll(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(plugin, null),
  );

  setUp(() async {
    shown.clear();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await SharedPreferencesAsync().setString('pda_ownDetails', jsonEncode({'player_id': 5, 'userApiKey': ''}));
  });

  void expectHidden() {
    expect(shown, hasLength(1));
    final all = '${jsonEncode(shown.single['platformSpecifics'])}${shown.single['title']}${shown.single['body']}';
    expect(all, isNot(contains('Bravo')));
    expect(all, isNot(contains('hello')));
    expect(shown.single['title'], isNot(isEmpty));
  }

  test('a DM push shows the sender and text by default', () async {
    await showTornChatNotification(push);
    expect((shown.single['title'], shown.single['body']), ('Bravo', 'hello'));
  }, skip: skip);

  test('a DM push hides sender and text with the option on', () async {
    await Prefs().setDiscreetNotifications(true);
    await showTornChatNotification(push);
    expectHidden();
  }, skip: skip);

  test('a DM push hides sender and text inside the schedule', () async {
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    await Prefs().setDiscreetSchedule(
      DiscreetSchedule(enabled: true, from: (minute - 5) % 1440, to: (minute + 5) % 1440),
    );
    await showTornChatNotification(push);
    expectHidden();
  }, skip: skip);

  test('a DM push is normal outside the schedule', () async {
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    await Prefs().setDiscreetSchedule(
      DiscreetSchedule(enabled: true, from: (minute + 60) % 1440, to: (minute + 120) % 1440),
    );
    await showTornChatNotification(push);
    expect(shown.single['title'], 'Bravo');
  }, skip: skip);

  test('the schedule is read in the background from the mirror', () async {
    await Prefs().setDiscreetSchedule(const DiscreetSchedule(enabled: true, from: 22 * 60, to: 6 * 60));
    expect(await BackgroundPrefs().getDiscreetAt(DateTime(2026, 1, 1, 23)), isTrue);
    expect(await BackgroundPrefs().getDiscreetAt(DateTime(2026, 1, 1, 6)), isFalse);
  });
}
