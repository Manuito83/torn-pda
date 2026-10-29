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

const _me = 99;

ChatMessage _mine(String id, DateTime at) => chatMessage(id, 'dm:7', sender: _me, name: 'Me', at: at);

Iterable<DateTime> _separators(WidgetTester tester) =>
    tester.widgetList<ChatDaySeparator>(find.byType(ChatDaySeparator)).map((s) => s.day);

void main() {
  useTempPathProvider();

  final now = DateTime.now();
  final noon = DateTime(now.year, now.month, now.day, 12);
  final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day, 16, 36);

  late FakeChatSource source;
  late ChatController chat;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..drafts = {};
    source = FakeChatSource();
    chat = ChatController(source, ChatPrefs());
    source.emit(const ChatReadyEvent(_me, myName: 'Me'));
  });

  void history(List<ChatMessage> messages) =>
      source.emit(ChatHistoryEvent('dm:7', messages, hasOlder: false, isOlderPage: false));

  group('quick window', () {
    Future<void> openQuick(WidgetTester tester) async {
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
    }

    testWidgets('a message from two months ago gets its own date', (tester) async {
      await openQuick(tester);
      history([_mine('old', twoMonthsAgo), _mine('new', noon)]);
      await tester.pump();

      expect(_separators(tester), [noon, twoMonthsAgo]);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('two messages from the same day share one separator', (tester) async {
      await openQuick(tester);
      history([_mine('a', noon), _mine('b', noon.add(const Duration(minutes: 5)))]);
      await tester.pump();

      expect(_separators(tester), [noon]);
    });

    testWidgets('the same sender on another day starts a new group', (tester) async {
      await openQuick(tester);
      history([_mine('old', twoMonthsAgo), _mine('new', noon)]);
      await tester.pump();

      final bubbles = tester.widgetList<ChatMessageBubble>(find.byType(ChatMessageBubble)).toList();
      expect(bubbles.map((b) => (b.message.id, b.isFirstInGroup, b.isLastInGroup)), [
        ('new', true, true),
        ('old', true, true),
      ]);
    });
  });

  testWidgets('the window and the full chat group alike', (tester) async {
    Iterable<(String, bool, bool)> groups() => tester
        .widgetList<ChatMessageBubble>(find.byType(ChatMessageBubble))
        .map((b) => (b.message.id, b.isFirstInGroup, b.isLastInGroup))
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    const expected = [('a', true, false), ('b', false, true), ('c', true, true)];
    history([
      _mine('a', noon),
      _mine('b', noon.add(const Duration(minutes: 2))),
      _mine('c', noon.add(const Duration(hours: 1))),
    ]);

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
    expect(groups(), expected);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatController>.value(
          value: chat,
          child: const ChatConversationPage(roomId: 'dm:7'),
        ),
      ),
    );
    await tester.pump();
    expect(groups(), expected);
  });
}
