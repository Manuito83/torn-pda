import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

class _NewYork extends ChatClock {
  _NewYork({required super.tornTime, super.h12});

  @override
  Duration localOffset(DateTime at) => const Duration(hours: -4);
}

void main() {
  useTempPathProvider();

  final at = DateTime.utc(2026, 10, 25, 2, 30);
  final now = DateTime.utc(2026, 10, 25, 12);

  test('TCT and local time give their own hour and day', () {
    final tct = _NewYork(tornTime: true);
    expect((tct.clock(at), tct.daysFrom(now, at)), ('02:30', 0));

    final local = _NewYork(tornTime: false);
    expect((local.clock(at), local.daysFrom(now, at)), ('22:30', -1));
    expect(local.daysFrom(at, now), 1);
    expect(_NewYork(tornTime: false, h12: true).clock(at), '10:30 PM');
  });

  test('quiet hours follow the app 12 or 24 h', () {
    expect(ChatClock(tornTime: true).minutesClock(22 * 60 + 5), '22:05');
    final h12 = ChatClock(tornTime: true, h12: true);
    expect(h12.minutesClock(22 * 60 + 5), '10:05 PM');
    expect(h12.minutesClock(30), '12:30 AM');
  });

  test('a reminder picked in TCT keeps the instant', () {
    final clock = _NewYork(tornTime: true);
    final reminder = clock.nextAt(3, 0, now);
    expect(reminder.isAtSameMomentAs(DateTime.utc(2026, 10, 26, 3)), isTrue);
    expect(reminder.isUtc, isFalse);
    expect(clock.nextAt(13, 0, now).isAtSameMomentAs(DateTime.utc(2026, 10, 25, 13)), isTrue);
  });

  group('open lists follow Chat times', () {
    late FakeChatSource source;
    late ChatController chat;
    final sent = DateTime.utc(2026, 10, 24, 22, 8).toLocal();
    final meridiem = find.textContaining(RegExp(r'\d [AP]M'));

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      NativeChat.prefs
        ..introSeen = true
        ..drafts = {}
        ..chatTimes = ChatTimes.app;
      source = FakeChatSource();
      chat = ChatController(source, NativeChat.prefs);
      source
        ..emit(const ChatReadyEvent(99, myName: 'Me'))
        ..emit(ChatHistoryEvent('dm:7', [chatMessage('m1', 'dm:7', at: sent)], hasOlder: false, isOlderPage: false));
    });

    tearDown(() => NativeChat.prefs.chatTimes = ChatTimes.app);

    Future<void> follow(WidgetTester tester, Widget page) async {
      final settings = SettingsProvider();
      await tester.pumpWidget(ChangeNotifierProvider.value(value: settings, child: MaterialApp(home: page)));
      await tester.pump();
      expect(meridiem, findsNothing);

      settings.changeTimeFormat = TimeFormatSetting.h12;
      await tester.pump();
      expect(meridiem, findsOneWidget);

      NativeChat.prefs.setChatTimes(ChatTimes.tct);
      await tester.pump();
      expect(find.text('10:08 PM'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
      chat.dispose();
    }

    testWidgets('in a quick window', (tester) async {
      await follow(
        tester,
        Scaffold(
          body: SizedBox(
            width: 340,
            height: 440,
            child: ChatQuickWindow(chat: chat, roomId: 'dm:7', onClose: () {}),
          ),
        ),
      );
    });

    testWidgets('in a conversation', (tester) async {
      await follow(
        tester,
        ChangeNotifierProvider<ChatController>.value(value: chat, child: const ChatConversationPage(roomId: 'dm:7')),
      );
    });
  });
}
