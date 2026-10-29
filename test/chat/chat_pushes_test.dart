import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_reminder.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_push_rules.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_engine.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_reminder_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  final noon = DateTime(2026, 1, 1, 12);

  group('rules', () {
    test('only DM settings travel, and survive the round trip', () {
      final prefs = ChatPrefs()
        ..ignored = {3: 'Charlie'}
        ..muted = {'dm:4', 'faction'}
        ..mutedUntil = {'dm:5': noon.add(const Duration(hours: 1)), 'global': noon}
        ..alertLevels = {'dm:6': ChatAlertLevel.none, 'trade': ChatAlertLevel.all}
        ..tones = {
          'dm:7': const ChatTone(ChatSound.silent, ChatVibration.short),
          'company': const ChatTone(ChatSound.silent, ChatVibration.short),
        }
        ..quietHours = true
        ..quietFrom = 23 * 60
        ..quietTo = 8 * 60;
      var rules = ChatPushRules.decode(ChatPushRules.of(prefs).encode());
      expect(rules.ignored, {3});
      expect(rules.muted, {'dm:4'});
      expect(rules.mutedUntil.keys, ['dm:5']);
      expect(rules.levels, {'dm:6': ChatAlertLevel.none});
      expect(rules.tones.keys, ['dm:7']);
      expect(rules.quiet, (23 * 60, 8 * 60));
      expect(rules.soundForAll, isNull);
      expect(rules.toneFor(7).vibration, ChatVibration.short);
      expect(rules.toneFor(8).sound, ChatSound.keyboard);

      prefs
        ..soundForAll = true
        ..soundForAllType = ChatSound.swordClash;
      rules = ChatPushRules.decode(ChatPushRules.of(prefs).encode());
      expect(rules.soundForAll, ChatSound.swordClash);
      expect(rules.toneFor(8).sound, ChatSound.swordClash);
      expect(rules.toneFor(7).sound, ChatSound.silent);
    });

    test('push respects ignored players, mutes and quiet hours', () {
      final rules = ChatPushRules(
        ignored: {3},
        muted: {'dm:4'},
        mutedUntil: {'dm:5': noon.add(const Duration(hours: 1)), 'dm:9': noon.subtract(const Duration(minutes: 1))},
        levels: {'dm:6': ChatAlertLevel.none, 'dm:8': ChatAlertLevel.mentions},
      );
      for (final (id, allowed) in [(2, true), (3, false), (4, false), (5, false), (6, false), (8, false), (9, true)]) {
        expect(rules.allows(id, noon), allowed, reason: '$id');
      }
      const quiet = ChatPushRules(quiet: (23 * 60, 8 * 60));
      expect(quiet.allows(2, DateTime(2026, 1, 1, 1)), isFalse);
      expect(quiet.allows(2, noon), isTrue);
    });

    test('quiet hours wrap past midnight', () {
      bool quiet(int from, int to, String at) {
        final [h, m] = at.split(':').map(int.parse).toList();
        return ChatPrefs.inQuietRange(from * 60, to * 60, h * 60 + m);
      }

      expect(quiet(23, 8, '23:00'), isTrue);
      expect(quiet(23, 8, '02:30'), isTrue);
      expect(quiet(23, 8, '07:59'), isTrue);
      expect(quiet(23, 8, '08:00'), isFalse);
      expect(quiet(23, 8, '22:59'), isFalse);
      expect(quiet(13, 15, '14:10'), isTrue);
      expect(quiet(13, 15, '15:00'), isFalse);
      expect(quiet(9, 9, '09:00'), isFalse);

      final prefs = ChatPrefs()
        ..quietFrom = 23 * 60
        ..quietTo = 8 * 60;
      expect(prefs.isQuietAt(DateTime(2026, 1, 1, 1)), isFalse);
      prefs.quietHours = true;
      expect(prefs.isQuietAt(DateTime(2026, 1, 1, 1)), isTrue);
      expect(prefs.isQuietAt(DateTime(2026, 1, 1, 12)), isFalse);
    });

    test('unreadable rules let the push through', () {
      for (final raw in ['', 'nope', '{"ignored":"x"}', '[]']) {
        final rules = ChatPushRules.decode(raw);
        expect(rules.allows(3, noon), isTrue);
        expect(rules.quiet, isNull);
      }
    });
  });

  group('DM notifications', () {
    const plugin = MethodChannel('dexterous.com/flutter/local_notifications');
    final shown = <Map>[];
    final push = {'event': 'tchat', 'kind': 'dm', 'userId': '7', 'sender': 'Bravo', 'message': 'hello'};
    final skip = ChatEngine.enabled ? false : 'Native chat not configured';

    Future<void> own({int id = 5, String key = ''}) =>
        SharedPreferencesAsync().setString('pda_ownDetails', jsonEncode({'player_id': id, 'userApiKey': key}));

    NotificationResponse reply(String text, {int? owner = 5}) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotificationAction,
      id: 677001,
      actionId: 'tchat_reply_action',
      input: text,
      payload: jsonEncode({'tornChatDm': 7, 'name': 'Bravo', 'owner': ?owner}),
    );

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

    setUp(() {
      shown.clear();
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    });

    test('anything but a Torn chat DM is left alone', () async {
      expect(await showTornChatNotification({'event': 'tchat', 'kind': 'room'}), isFalse);
      expect(await showTornChatNotification({'title': 'Energy full'}), isFalse);
      expect(shown, isEmpty);
    });

    test('DM push gating', () async {
      await own();
      await SharedPreferencesAsync().setBool('pda_tornChatDmPush', false);
      expect(await showTornChatNotification(push), isTrue);
      expect(shown, isEmpty);

      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      await own();
      expect(await showTornChatNotification(push, foreground: true), isTrue);
      expect(shown, hasLength(1));
      expect((shown.single['title'], shown.single['body']), ('Bravo', 'hello'));
      expect(shown.single['id'], inInclusiveRange(677000, 677999));
      expect(jsonDecode(shown.single['payload'] as String), {'tornChatDm': 7, 'name': 'Bravo', 'owner': 5});

      for (final rules in [
        const ChatPushRules(ignored: {7}),
        const ChatPushRules(muted: {'dm:7'}),
        const ChatPushRules(quiet: (0, 24 * 60)),
      ]) {
        shown.clear();
        await BackgroundPrefs().setChatPushRules(rules.encode());
        expect(await showTornChatNotification(push), isTrue);
        expect(shown, isEmpty);
      }
    }, skip: skip);

    test('DM push sound and channel', () async {
      await own();
      Map android() => shown.last['platformSpecifics'] as Map;
      await showTornChatNotification(push);
      expect(android()['playSound'], isTrue);
      expect(android()['channelId'], endsWith(' s'));

      await BackgroundPrefs().setChatPushRules(const ChatPushRules(soundForAll: ChatSound.carStart).encode());
      await showTornChatNotification(push);
      expect(android()['playSound'], isTrue);
      expect(android()['channelId'], startsWith('Torn chat carStart'));

      const person = ChatPushRules(tones: {'dm:7': ChatTone(ChatSound.silent)});
      await BackgroundPrefs().setChatPushRules(person.encode());
      await showTornChatNotification(push);
      expect(android()['playSound'], isFalse);
    }, skip: skip);

    test('tap payload parsing', () async {
      final tap = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: jsonEncode({'tornChatDm': 7, 'name': 'Bravo', 'owner': 5}),
      );
      expect(await handleTornChatResponse(tap), (7, 'Bravo'));
      const other = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'energy',
      );
      expect(await handleTornChatResponse(other), isNull);
      expect(shown, isEmpty);
    });

    test('notification reply checks', () async {
      await own();
      await handleTornChatResponse(reply('see you'));
      expect(shown.single['body'], 'Not sent: open the chat to reply');
      shown.clear();
      await Prefs().setNativeChatReplyEnabled(true);

      await own(id: 6, key: 'abcdefghijklmnop');
      expect(await handleTornChatResponse(reply('see you')), (7, 'Bravo'));
      expect(shown.single['body'], 'Not sent: account changed');
      shown.clear();
      await handleTornChatResponse(reply('see you', owner: null));
      expect(shown.single['body'], 'Not sent: account changed');

      shown.clear();
      await own();
      await handleTornChatResponse(reply('see you at the bank'));
      expect((shown.single['title'], shown.single['body']), ('Bravo', 'Reply failed: see you at the bank'));
    });
  });

  group('reminders', () {
    const now = 1000000;

    BarsStatusCooldownsModel bars({
      String state = 'Okay',
      int until = 0,
      int landing = 0,
      int full = 0,
      int age = 10,
    }) => BarsStatusCooldownsModel(
      serverTime: now - age,
      energy: PersonalBars(current: 95, maximum: 150, fulltime: full),
      status: Status(state: state, until: until),
      travel: Travel(destination: 'Japan', timestamp: landing),
    );

    ChatReminder reminder(int id, {String excerpt = 'x', DateTime? at}) => ChatReminder(
      id: id,
      roomId: 'global',
      roomName: 'Global',
      messageId: 'm$id',
      author: 'Alpha',
      excerpt: excerpt,
      at: at ?? DateTime(2030),
      label: 'In 1 h',
    );

    test('only the triggers that apply now, at their real times', () {
      List<String> labels(BarsStatusCooldownsModel b) => [
        for (final o in ChatReminders.triggers(bars: b, now: now)) o.label,
      ];
      expect(labels(bars()), isEmpty);
      expect(labels(bars(state: 'Traveling', landing: now + 600)), ['When I land']);
      expect(labels(bars(state: 'Hospital', until: now + 600)), ['When I leave hospital']);
      expect(labels(bars(full: 3600)), ['When energy is full']);

      expect(labels(bars(state: 'Traveling', landing: now - 5)), isEmpty);
      expect(labels(bars(state: 'Hospital', until: now - 5)), isEmpty);
      expect(labels(bars(full: 3600, age: 3600)), isEmpty);
      expect(labels(bars(full: 5)), isEmpty);

      final landing = ChatReminders.triggers(
        bars: bars(state: 'Traveling', landing: now + 600),
        now: now,
      );
      expect(landing.single.at.millisecondsSinceEpoch, (now + 600) * 1000);
      final energy = ChatReminders.triggers(bars: bars(full: 3600), now: now);
      expect(energy.single.at.millisecondsSinceEpoch, (now - 10 + 3600) * 1000);
    });

    test('chat and reminder taps carry the room in letters only', () {
      for (final room in ['faction', 'dm:7', 'global']) {
        final payload = NativeChat.tapPayload(room);
        expect(payload, matches(RegExp(r'^pdachat:[A-P]+$')));
        expect(NativeChat.roomFromTap(payload), room);
      }
      expect(NativeChat.roomFromTap('tornChat'), isNull);
      expect(NativeChat.roomFromTap('pdachat:AZ'), isNull);

      final payload = ChatReminders.payload('dm:7', 'm-9');
      expect(payload, matches(RegExp(r'^pdachat-remind:[A-P]+$')));
      expect(ChatReminders.fromPayload(payload), ('dm:7', 'm-9'));
      expect(ChatReminders.fromPayload('pdachat:AB'), isNull);
      expect(ChatReminders.fromPayload(null), isNull);
    });

    test('web chat payload peer', () {
      expect(NativeChat.webChatPayload('dm:123'), 'tornChat:123');
      expect(NativeChat.webChatPayload('faction'), 'tornChat');
      expect(NativeChat.webChatPayload('dm:0'), 'tornChat');
      expect(NativeChat.webChatPeer('tornChat:123'), '123');
      expect(NativeChat.webChatPeer('tornChat'), isNull);
      expect(NativeChat.webChatPeer('tornChat:12"});alert(1)'), isNull);
      expect(NativeChat.webChatPeer(null), isNull);
    });

    test('reminder id, excerpt and json', () {
      expect(ChatReminders.nextId(const []), ChatReminders.idBase);
      expect(
        ChatReminders.nextId([reminder(ChatReminders.idBase), reminder(ChatReminders.idBase + 1)]),
        ChatReminders.idBase + 2,
      );

      final message = chatMessage('m1', 'global', sender: 7, name: 'Alpha', text: 'x' * 400);
      final r = ChatReminder.of(message, 'Global', id: 678001, at: DateTime(2031), label: 'In 1 h');
      expect(r.excerpt.length, lessThan(200));
      final back = ChatReminder.fromJson(r.toJson())!;
      expect((back.id, back.roomId, back.messageId, back.author, back.at), (678001, 'global', 'm1', 'Alpha', r.at));
      expect(ChatReminder.fromJson({'n': 'bad'}), isNull);
    });

    testWidgets('the list shows pending reminders only', (tester) async {
      addTearDown(() => NativeChat.prefs.reminders = []);
      NativeChat.prefs.reminders = [
        reminder(678000, excerpt: 'meet at the bank', at: DateTime.now().add(const Duration(hours: 1))),
        reminder(678001, excerpt: 'already gone', at: DateTime.now().subtract(const Duration(hours: 1))),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(onPressed: () => showChatRemindersList(context), child: const Text('go')),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('meet at the bank'), findsOneWidget);
      expect(find.text('already gone'), findsNothing);
      expect(find.byTooltip('Delete reminder'), findsOneWidget);
    });
  });
}
