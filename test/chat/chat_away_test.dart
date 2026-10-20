import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_away.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_away_widgets.dart';

import 'chat_fakes.dart';

const _attack = 'https://www.torn.com/loader.php?sid=attack&user2id=99';

void main() {
  useTempPathProvider();

  group('ChatAway', () {
    final since = chatNow.subtract(const Duration(hours: 5, minutes: 20));

    ChatMessage msg(String id, int sender, String text, {int minutesAfter = 10, bool system = false}) => ChatMessage(
      id: id,
      roomId: 'faction',
      sender: ChatUser(id: sender, name: 'Bravo'),
      content: text,
      createdAt: since.add(Duration(minutes: minutesAfter)),
      isSystem: system,
    );

    ChatAway? build(List<ChatMessage> list, {bool older = false, Set<int> leaders = const {}, DateTime? from}) =>
        ChatAway.build(
          messages: list,
          since: from ?? since,
          now: chatNow,
          myUserId: 1,
          hasOlder: older,
          mention: (m) => m.content.contains('@me'),
          word: (m) => m.content.contains('war'),
          leaders: leaders,
        );

    test('span reads like a person would', () {
      expect(ChatAway.span(const Duration(hours: 5, minutes: 20)), '5h 20m');
      expect(ChatAway.span(const Duration(minutes: 45)), '45m');
      expect(ChatAway.span(const Duration(hours: 3)), '3h');
      expect(ChatAway.span(const Duration(days: 1, hours: 3, minutes: 9)), '1d 3h');
    });

    test('no summary when short or empty', () {
      expect(build([msg('a', 2, 'hey @me')], from: chatNow.subtract(const Duration(minutes: 29))), isNull);
      expect(
        build([msg('a', 2, 'hey @me', minutesAfter: 400)], from: chatNow.subtract(const Duration(minutes: 30))),
        isNotNull,
      );
      expect(build([]), isNull);
      expect(build([msg('a', 1, 'mine @me'), msg('b', 2, 'old @me', minutesAfter: -5)]), isNull);
      expect(build([msg('a', 2, 'system @me', system: true)]), isNull);
      expect(build([msg('a', 2, 'hello'), msg('b', 3, 'hi')]), isNull);
    });

    test('counts every group and keeps the oldest of each', () {
      final away = build(
        [
          msg('old', 2, 'before', minutesAfter: -30),
          msg('a', 2, 'hello'),
          msg('b', 3, 'hey @me'),
          msg('c', 4, 'look $_attack'),
          msg('d', 3, 'war soon @me'),
          msg('mine', 1, 'war @me'),
        ],
        leaders: {4},
      )!;
      expect(away.total, 4);
      expect(away.anchorId, 'a');
      expect(away.counts[ChatAwayKind.mentions], 2);
      expect(away.counts[ChatAwayKind.leaders], 1);
      expect(away.counts[ChatAwayKind.attacks], 1);
      expect(away.counts[ChatAwayKind.words], 1);
      expect(away.firsts[ChatAwayKind.mentions], 'b');
      expect(away.firsts[ChatAwayKind.attacks], 'c');
      expect(away.firsts[ChatAwayKind.words], 'd');
      expect(away.away, const Duration(hours: 5, minutes: 20));

      final quiet = build([msg('a', 2, 'hello'), msg('b', 2, 'hey @me')])!;
      expect(quiet.shown, [ChatAwayKind.mentions]);
      expect(quiet.total, 2);
    });

    test('inbox line count and plus', () {
      final away = build([msg('a', 2, 'x @me'), msg('b', 2, _attack)])!;
      expect(away.counts[ChatAwayKind.mentions], 1);
      expect(away.shown, [ChatAwayKind.mentions, ChatAwayKind.attacks]);
      expect(away.inboxLine(38), startsWith('38'));

      final partial = build([msg('a', 2, '@me')], older: true)!;
      expect(partial.more, isTrue);
      expect(partial.inboxLine(1), startsWith('1+'));
      expect(build([msg('old', 2, '@me', minutesAfter: -10), msg('a', 2, '@me')], older: true)!.more, isFalse);
      expect(build([msg('a', 2, '@me')])!.more, isFalse);
    });
  });

  group('ChatController', () {
    late FakeChatSource source;
    late ChatController chat;
    const dm = ChatRoom(id: 'dm:7', name: 'Charlie', type: ChatRoomType.dm);

    ChatMessage msg(String id, String roomId, int sender, String text, DateTime at) =>
        chatMessage(id, roomId, sender: sender, text: text, at: at);

    void load(String roomId, List<ChatMessage> list) =>
        source.emit(ChatHistoryEvent(roomId, list, hasOlder: false, isOlderPage: false));

    setUp(() {
      source = FakeChatSource();
      chat = ChatController(source, ChatPrefs());
      source.emit(const ChatReadyEvent(1, myName: 'Me'));
    });

    tearDown(() => chat.dispose());

    test('summary after 30 minutes away, cleared when dismissed', () {
      final left = DateTime.now().subtract(const Duration(hours: 5));
      load('faction', [
        msg('old', 'faction', 2, 'before', left.subtract(const Duration(minutes: 5))),
        msg('a', 'faction', 2, 'hello', left.add(const Duration(minutes: 5))),
        msg('b', 'faction', 3, 'hey Me', left.add(const Duration(minutes: 9))),
      ]);
      chat.paused(at: left);
      chat.resumed();
      final away = chat.awayFor('faction')!;
      expect(away.total, 2);
      expect(away.counts[ChatAwayKind.mentions], 1);
      expect(away.anchorId, 'a');
      expect(away.away.inHours, 5);
      chat.dismissAway('faction');
      expect(chat.awayFor('faction'), isNull);
    });

    test('time away survives a cold start', () {
      final left = DateTime.now().subtract(const Duration(hours: 3));
      final prefs = ChatPrefs();
      final before = ChatController(source, prefs)..paused(at: left);
      expect(prefs.pausedAt, left);
      before.dispose();

      final cold = ChatController(source, prefs)..restorePaused();
      addTearDown(cold.dispose);
      expect(prefs.pausedAt, isNull);
      source.emit(const ChatReadyEvent(1, myName: 'Me'));
      load('faction', [msg('a', 'faction', 2, 'hey Me', left.add(const Duration(minutes: 5)))]);
      expect(cold.awayFor('faction')!.total, 1);
      source.emit(const ChatDmsEvent([dm]));
      load('dm:7', [msg('d', 'dm:7', 7, 'hey Me', left.add(const Duration(minutes: 9)))]);
      expect(cold.awayFor('dm:7')!.total, 1);
      cold.dismissAway('dm:7');
      source.emit(const ChatDmsEvent([dm]));
      expect(cold.awayFor('dm:7'), isNull);
    });

    test('no summary cases', () {
      expect(['faction', 'company', 'dm:7'].every(ChatAway.appliesTo), isTrue);
      expect(['global', 'trade', 'newplayers'].any(ChatAway.appliesTo), isFalse);

      final recent = DateTime.now().subtract(const Duration(minutes: 10));
      load('faction', [msg('a', 'faction', 2, 'hey Me', recent.add(const Duration(minutes: 1)))]);
      chat.paused(at: recent);
      chat.resumed();
      expect(chat.awayFor('faction'), isNull);

      final left = DateTime.now().subtract(const Duration(hours: 2));
      source
        ..emit(const ChatDmsEvent([dm]))
        ..emit(const ChatUnreadEvent({'dm:7': 1}));
      load('global', [msg('g', 'global', 2, 'hey Me', left.add(const Duration(minutes: 1)))]);
      load('dm:7', [msg('d', 'dm:7', 7, 'hi', left.add(const Duration(minutes: 5)))]);
      chat.paused(at: left);
      chat.resumed();
      expect(chat.awayFor('global'), isNull);
      expect(chat.awayFor('dm:7'), isNull);
    });

    test('marking the conversation as read clears the summary', () {
      final left = DateTime.now().subtract(const Duration(hours: 2));
      source.emit(const ChatDmsEvent([dm]));
      load('dm:7', [msg('a', 'dm:7', 7, 'hey Me', left.add(const Duration(minutes: 5)))]);
      source.emit(const ChatUnreadEvent({'dm:7': 1}));
      chat.paused(at: left);
      chat.resumed();
      expect(chat.awayFor('dm:7')!.counts[ChatAwayKind.mentions], 1);
      chat.markRead('dm:7');
      expect(chat.awayFor('dm:7'), isNull);
    });
  });

  testWidgets('chip jumps to first message', (tester) async {
    const away = ChatAway(
      away: Duration(hours: 5, minutes: 20),
      total: 38,
      more: false,
      counts: {ChatAwayKind.mentions: 2, ChatAwayKind.leaders: 0, ChatAwayKind.attacks: 1, ChatAwayKind.words: 0},
      firsts: {ChatAwayKind.mentions: 'm1', ChatAwayKind.attacks: 'a1'},
      anchorId: 'x',
    );
    final jumped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatAwayCard(away: away, onJump: jumped.add),
        ),
      ),
    );
    expect(find.textContaining('from leaders'), findsNothing);
    await tester.tap(find.text('1 attack link'));
    await tester.tap(find.text('2 mention you'));
    expect(jumped, ['a1', 'm1']);
  });
}
