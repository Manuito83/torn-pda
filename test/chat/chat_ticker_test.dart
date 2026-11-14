import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_ticker_queue.dart';
import 'package:torn_pda/widgets/chat/chat_ticker.dart';

import 'chat_fakes.dart';

ChatAlert _alert(String id, {String room = 'dm:7', ChatMatch? match}) => ChatAlert(
  ChatMessage(
    id: id,
    roomId: room,
    sender: const ChatUser(id: 7, name: 'Bravo'),
    content: 'message $id',
    createdAt: DateTime(2026, 10, 16),
  ),
  match,
);

void main() {
  useTempPathProvider();

  group('queue', () {
    test('keeps as many as the setting says, oldest first out', () {
      for (final max in ChatPrefs.tickerMaxOptions) {
        final queue = ChatTickerQueue();
        for (var i = 0; i < 5; i++) {
          queue.add(_alert('$i'), max);
        }
        final staying = queue.entries.where((e) => !e.leaving).map((e) => e.alert.message.id).toList();
        expect(staying, [for (var i = 5 - max; i < 5; i++) '$i']);
        expect(queue.entries.length, lessThanOrEqualTo(max * 2));
      }
    });

    test('an expanded caption stays put and is never pushed out', () {
      final queue = ChatTickerQueue();
      final first = queue.add(_alert('a'), 1);
      queue.add(_alert('b'), 1);
      queue.expand(queue.entries.last);
      final pinned = queue.entries.last;
      expect(queue.arranged(top: true).first, pinned);
      expect(queue.arranged(top: false).last, pinned);
      expect(first.leaving, isTrue);

      for (final id in ['c', 'd', 'e', 'f']) {
        queue.add(_alert(id), 1);
        expect(pinned.leaving, isFalse);
        expect(queue.entries, contains(pinned));
        expect(queue.arranged(top: true).first, pinned);
        expect(queue.arranged(top: false).last, pinned);
      }
      expect(queue.entries.where((e) => !e.leaving && !e.expanded).map((e) => e.alert.message.id), ['f']);
      expect(queue.entries.where((e) => !e.expanded).length, lessThanOrEqualTo(2));
    });
  });

  testWidgets('caption duration and keep', (tester) async {
    final prefs = ChatPrefs();
    final source = FakeChatSource();
    final chat = ChatController(source, prefs);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: ChatTicker(chat: chat, prefs: prefs, onOpen: (_) {}),
            ),
          ),
        ),
      ),
    );
    source.emit(const ChatReadyEvent(99, myName: 'Me'));
    await tester.pump();
    Finder caption(String text) => find.textContaining(text, findRichText: true);
    Future<void> dm(String id, String text) async {
      source.emit(ChatMessageEvent(chatMessage(id, 'dm:7', sender: 7, name: 'Bravo', text: text, at: DateTime.now())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    prefs.tickerSeconds = 4;
    await dm('m4', 'hello 4');
    await tester.pump(const Duration(seconds: 4) - const Duration(milliseconds: 600));
    expect(caption('hello 4'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(caption('hello 4'), findsNothing);

    prefs.tickerSeconds = 0;
    await dm('keep', 'stays');
    await tester.pump(const Duration(minutes: 5));
    expect(caption('stays'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });

  group('glow filter', () {
    test('frozen, hidden and muted rooms never glow', () {
      final prefs = ChatPrefs()
        ..tickerLevels = {'global': ChatAlertLevel.all, 'trade': ChatAlertLevel.all, 'poker': ChatAlertLevel.all}
        ..setRoomState('global', ChatRoomState.frozen)
        ..setRoomState('trade', ChatRoomState.hidden)
        ..muted = {'poker'};
      expect(prefs.glowShows('global', const ChatMatch(mention: true)), isFalse);
      expect(prefs.glowShows('trade', const ChatMatch(mention: true)), isFalse);
      expect(prefs.glowShows('poker', null), isFalse);
      expect(prefs.glowShows('poker', const ChatMatch(mention: true)), isFalse);
    });
  });
}
