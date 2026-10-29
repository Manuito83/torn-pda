import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

class _NewYork extends ChatPrefs {
  @override
  Duration localOffset(DateTime at) => const Duration(hours: -4);
}

void main() {
  useTempPathProvider();

  final at = DateTime.utc(2026, 10, 25, 2, 30);
  final now = DateTime.utc(2026, 10, 25, 12);

  test('TCT and local time give their own hour and day', () {
    final prefs = _NewYork()..chatTimes = ChatTimes.tct;
    addTearDown(prefs.dispose);
    expect((prefs.clock(at), prefs.daysFrom(now, at)), ('02:30', 0));

    prefs.chatTimes = ChatTimes.local;
    expect((prefs.clock(at), prefs.daysFrom(now, at)), ('22:30', -1));
    expect(prefs.daysFrom(at, now), 1);
  });

  test('as in app settings follows the app zone, the format always', () {
    final prefs = _NewYork();
    addTearDown(prefs.dispose);
    prefs.followAppTime(tornTime: true, h12: true);
    expect((prefs.clock(at), prefs.daysFrom(now, at)), ('2:30 AM', 0));

    prefs.followAppTime(tornTime: false, h12: true);
    expect((prefs.clock(at), prefs.daysFrom(now, at)), ('10:30 PM', -1));

    prefs.chatTimes = ChatTimes.tct;
    expect(prefs.clock(at), '2:30 AM');
  });

  test('quiet hours follow the app 12 or 24 h', () {
    final prefs = ChatPrefs();
    addTearDown(prefs.dispose);
    expect(prefs.minutesClock(22 * 60 + 5), '22:05');
    prefs.followAppTime(tornTime: true, h12: true);
    expect(prefs.minutesClock(22 * 60 + 5), '10:05 PM');
    expect(prefs.minutesClock(30), '12:30 AM');
  });

  test('a reminder picked in TCT keeps the instant', () {
    final prefs = _NewYork()..chatTimes = ChatTimes.tct;
    addTearDown(prefs.dispose);
    final reminder = prefs.nextAt(3, 0, now);
    expect(reminder.isAtSameMomentAs(DateTime.utc(2026, 10, 26, 3)), isTrue);
    expect(reminder.isUtc, isFalse);
    expect(prefs.nextAt(13, 0, now).isAtSameMomentAs(DateTime.utc(2026, 10, 25, 13)), isTrue);
  });

  group('open lists follow Chat times', () {
    late FakeChatSource source;
    late ChatController chat;
    final sent = DateTime.utc(2026, 10, 24, 22, 8).toLocal();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      NativeChat.prefs
        ..introSeen = true
        ..drafts = {}
        ..chatTimes = ChatTimes.app
        ..appTornTime = false
        ..app12h = false;
      source = FakeChatSource();
      chat = ChatController(source, NativeChat.prefs);
      source
        ..emit(const ChatReadyEvent(99, myName: 'Me'))
        ..emit(ChatHistoryEvent('dm:7', [chatMessage('m1', 'dm:7', at: sent)], hasOlder: false, isOlderPage: false));
    });

    tearDown(() {
      NativeChat.prefs
        ..chatTimes = ChatTimes.app
        ..app12h = false;
    });

    Future<void> switchToTct(WidgetTester tester) async {
      expect(find.textContaining(' PM'), findsNothing);
      NativeChat.prefs
        ..app12h = true
        ..setChatTimes(ChatTimes.tct);
      await tester.pump();
      expect(find.text('10:08 PM'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
      chat.dispose();
    }

    testWidgets('in a quick window', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: 440,
              child: ChatQuickWindow(chat: chat, roomId: 'dm:7', onClose: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await switchToTct(tester);
    });

    testWidgets('in a conversation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ChatController>.value(
            value: chat,
            child: const ChatConversationPage(roomId: 'dm:7'),
          ),
        ),
      );
      await tester.pump();
      await switchToTct(tester);
    });
  });

  testWidgets('a message shows its time in TCT', (tester) async {
    NativeChat.prefs.chatTimes = ChatTimes.tct;
    addTearDown(() => NativeChat.prefs.chatTimes = ChatTimes.app);
    final message = chatMessage(
      'm1',
      'global',
      text: 'Chain at 22:00',
      at: DateTime.utc(2026, 10, 24, 22, 8).toLocal(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(message: message, isMine: false, isFirstInGroup: true, isLastInGroup: true),
        ),
      ),
    );
    expect(find.text('22:08'), findsOneWidget);
  });
}
