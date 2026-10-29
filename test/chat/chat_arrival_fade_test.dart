import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_arrival_fade.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

const _me = 99;

void main() {
  useTempPathProvider();

  group('tracker', () {
    late DateTime clock;
    late ChatArrivalTracker tracker;
    final start = DateTime(2026, 10, 29, 12);

    ChatMessage msg(String id, {int minutes = 0}) => chatMessage(id, 'dm:7', at: start.add(Duration(minutes: minutes)));

    setUp(() {
      clock = start;
      tracker = ChatArrivalTracker(clock: () => clock);
    });

    test('what is there at open is not an arrival', () {
      tracker.update('dm:7', [msg('a', minutes: -5), msg('b', minutes: -1)]);
      expect(tracker.take('a'), isFalse);
      expect(tracker.take('b'), isFalse);
    });

    test('a message appended live animates once', () {
      tracker.update('dm:7', [msg('a', minutes: -5)]);
      clock = start.add(const Duration(seconds: 5));
      final list = [msg('a', minutes: -5), msg('b', minutes: 1)];
      tracker.update('dm:7', list);
      tracker.update('dm:7', list);
      expect(tracker.take('b'), isTrue);
      expect(tracker.take('b'), isFalse);
      tracker.update('dm:7', list);
      expect(tracker.take('b'), isFalse);
    });

    test('older history added at the top does not animate', () {
      tracker.update('dm:7', [msg('c', minutes: -1)]);
      tracker.update('dm:7', [msg('a', minutes: -30), msg('b', minutes: -20), msg('c', minutes: -1)]);
      expect(tracker.take('a'), isFalse);
      expect(tracker.take('b'), isFalse);
    });

    test('messages sent while away and fetched after opening do not animate', () {
      tracker.update('dm:7', [msg('a', minutes: -5)]);
      tracker.update('dm:7', [msg('a', minutes: -5), msg('b', minutes: -3)]);
      expect(tracker.take('b'), isFalse);
    });

    test('a sent message confirmed later keeps its single animation', () {
      final a = msg('a', minutes: -5);
      final other = msg('x', minutes: 2);
      final at = start.add(const Duration(minutes: 1));
      final local = chatMessage('local-1', 'dm:7', at: at, reqId: 'r1');
      final confirmed = chatMessage('srv-1', 'dm:7', at: at.add(const Duration(minutes: 2)), reqId: 'r1');

      tracker.update('dm:7', [a]);
      tracker.update('dm:7', [a, local]);
      expect(tracker.take('r1'), isTrue);

      tracker.update('dm:7', [a, local, other]);
      tracker.update('dm:7', [a, other, confirmed]);
      expect(tracker.take('r1'), isFalse);
    });

    test('an arrival nobody built in time is dropped', () {
      tracker.update('dm:7', [msg('a', minutes: -5)]);
      tracker.update('dm:7', [msg('a', minutes: -5), msg('b', minutes: 1)]);
      clock = start.add(const Duration(seconds: 3));
      expect(tracker.take('b'), isFalse);
    });

    test('another room starts clean', () {
      tracker.update('dm:7', [msg('a', minutes: -5)]);
      tracker.update('dm:8', [msg('z', minutes: 1)]);
      expect(tracker.take('z'), isFalse);
    });

    test('the first message of an empty room animates', () {
      tracker.update('dm:7', const []);
      tracker.update('dm:7', [msg('a', minutes: 1)]);
      expect(tracker.take('a'), isTrue);
    });
  });

  group('fade widget', () {
    tearDown(() => NativeChat.prefs.animations = ChatAnimations.verySmooth);

    Widget host({bool still = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: still),
        child: const ChatArrivalFade(animate: true, child: Text('hello')),
      ),
    );

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find.descendant(of: find.byType(ChatArrivalFade), matching: find.byType(FadeTransition)),
        )
        .opacity
        .value;

    testWidgets('an arrival fades in and rises, readable from the first frame', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host());
      expect(opacity(tester), 0);
      expect(find.semantics.byLabel('hello'), findsOneWidget);
      final start = tester.getTopLeft(find.text('hello')).dy;

      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(tester), allOf(greaterThan(0), lessThan(1)));
      final mid = tester.getTopLeft(find.text('hello')).dy;
      expect(mid, lessThan(start));

      await tester.pump(const Duration(milliseconds: 500));
      expect(opacity(tester), 1);
      expect(tester.getTopLeft(find.text('hello')).dy, lessThan(mid));

      await tester.pumpWidget(host());
      expect(opacity(tester), 1);
      expect(find.semantics.byLabel('hello'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the chosen option sets how long the fade lasts', (tester) async {
      NativeChat.prefs.animations = ChatAnimations.quick;
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 250));
      expect(opacity(tester), 1);
      await tester.pumpWidget(const SizedBox());

      NativeChat.prefs.animations = ChatAnimations.verySmooth;
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 250));
      expect(opacity(tester), lessThan(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(tester), 1);
    });

    testWidgets('with reduced motion nothing animates, whatever the option', (tester) async {
      for (final option in ChatAnimations.values) {
        NativeChat.prefs.animations = option;
        await tester.pumpWidget(host(still: true));
        final fades = find.descendant(of: find.byType(ChatArrivalFade), matching: find.byType(FadeTransition));
        expect(fades, findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });

    group('older messages', () {
      Widget feed({required bool arrived, bool animate = true}) => MaterialApp(
        home: ListView(
          reverse: true,
          children: [
            if (arrived)
              ChatArrivalFade(
                key: const ValueKey('new'),
                animate: animate,
                child: const SizedBox(key: Key('new-box'), height: 100),
              ),
            const SizedBox(key: ValueKey('older'), height: 100),
          ],
        ),
      );

      double olderTop(WidgetTester tester) => tester.getTopLeft(find.byKey(const ValueKey('older'))).dy;

      testWidgets('glide up while the arrival makes room', (tester) async {
        await tester.pumpWidget(feed(arrived: false));
        final before = olderTop(tester);
        await tester.pumpWidget(feed(arrived: true));
        expect(olderTop(tester), closeTo(before, 1));

        await tester.pump(const Duration(milliseconds: 150));
        final mid = olderTop(tester);
        expect(mid, lessThan(before));
        expect(mid, greaterThan(before - 100));

        await tester.pump(const Duration(milliseconds: 600));
        expect(olderTop(tester), closeTo(before - 100, 0.5));

        final clip = find.descendant(of: find.byType(ChatArrivalFade), matching: find.byType(ClipRect));
        expect(tester.widget<ClipRect>(clip).clipBehavior, Clip.none);
        expect(tester.getSize(find.byKey(const Key('new-box'))), Size(tester.getSize(find.byType(ListView)).width, 100));
      });

      testWidgets('jump at once when the new row is not an arrival', (tester) async {
        await tester.pumpWidget(feed(arrived: false));
        final before = olderTop(tester);
        await tester.pumpWidget(feed(arrived: true, animate: false));
        expect(olderTop(tester), closeTo(before - 100, 0.5));
      });

      testWidgets('stay put with reduced motion', (tester) async {
        Widget still() => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: feed(arrived: true),
        );
        await tester.pumpWidget(feed(arrived: false));
        final before = olderTop(tester);
        await tester.pumpWidget(still());
        expect(olderTop(tester), closeTo(before - 100, 0.5));
      });
    });
  });

  group('conversations', () {
    final now = DateTime.now();
    late FakeChatSource source;

    ChatController fresh() {
      SharedPreferences.setMockInitialValues({});
      NativeChat.prefs
        ..introSeen = true
        ..drafts = {};
      source = FakeChatSource();
      source.emit(const ChatReadyEvent(_me, myName: 'Me'));
      return ChatController(source, ChatPrefs());
    }

    ChatMessage at(String id, Duration ago, {int sender = 2}) =>
        chatMessage(id, 'dm:7', sender: sender, at: now.subtract(ago));

    final fading = find.descendant(
      of: find.byType(ChatArrivalFade),
      matching: find.byWidgetPredicate((w) => w is FadeTransition && w.opacity.value < 1),
    );

    Future<void> run(WidgetTester tester, Widget page) async {
      source.emit(
        ChatHistoryEvent(
          'dm:7',
          [at('a', const Duration(hours: 2)), at('b', const Duration(hours: 1))],
          hasOlder: true,
          isOlderPage: false,
        ),
      );
      await tester.pumpWidget(page);
      await tester.pump();
      expect(fading, findsNothing);

      source.emit(ChatMessageEvent(chatMessage('c', 'dm:7', at: DateTime.now().add(const Duration(seconds: 2)))));
      await tester.pump();
      expect(fading, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(find.byType(ChatMessageBubble), findsNWidgets(3));

      source.emit(ChatHistoryEvent('dm:7', [at('old', const Duration(days: 1))], hasOlder: false, isOlderPage: true));
      await tester.pump();
      expect(find.text('text old'), findsOneWidget);
      expect(fading, findsNothing);
    }

    testWidgets('live message fades, history does not, in the full chat and the quick window', (tester) async {
      final pages = <Widget Function(ChatController)>[
        (chat) => MaterialApp(
          home: ChangeNotifierProvider<ChatController>.value(
            value: chat,
            child: const ChatConversationPage(roomId: 'dm:7'),
          ),
        ),
        (chat) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: 440,
              child: ChatQuickWindow(chat: chat, roomId: 'dm:7', onClose: () {}),
            ),
          ),
        ),
      ];
      for (final page in pages) {
        await run(tester, page(fresh()));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      }
    });
  });

  group('inbox row', () {
    const dm = ChatRoom(
      id: 'dm:7',
      name: 'Charlie',
      type: ChatRoomType.dm,
      peer: ChatUser(id: 7, name: 'Charlie'),
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget row({required String text, String draft = '', String id = 'm1'}) => MaterialApp(
      home: Scaffold(
        body: ChatConversationTile(
          room: dm,
          last: chatMessage(id, 'dm:7', text: text),
          unread: 0,
          myUserId: _me,
          draft: draft,
          onTap: () {},
        ),
      ),
    );

    testWidgets('a new last line crosses over the old one', (tester) async {
      await tester.pumpWidget(row(text: 'first line'));
      expect(find.textContaining('first line'), findsOneWidget);

      await tester.pumpWidget(row(text: 'second line', id: 'm2'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.textContaining('first line'), findsOneWidget);
      expect(find.textContaining('second line'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('first line'), findsNothing);
      expect(find.textContaining('second line'), findsOneWidget);
    });

    testWidgets('the chosen option sets how long the line crossing lasts', (tester) async {
      addTearDown(() => NativeChat.prefs.animations = ChatAnimations.verySmooth);
      NativeChat.prefs.animations = ChatAnimations.quick;
      await tester.pumpWidget(row(text: 'first line'));
      await tester.pumpWidget(row(text: 'second line', id: 'm2'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('first line'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      NativeChat.prefs.animations = ChatAnimations.verySmooth;
      await tester.pumpWidget(row(text: 'first line'));
      await tester.pumpWidget(row(text: 'second line', id: 'm2'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('first line'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('first line'), findsNothing);
    });

    testWidgets('typing a draft does not fade per key', (tester) async {
      await tester.pumpWidget(row(text: 'first line', draft: 'h'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(row(text: 'first line', draft: 'he'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.textContaining('he'), findsOneWidget);
      expect(find.textContaining('first line'), findsNothing);
    });

    testWidgets('a screen reader hears the row once while it fades', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(row(text: 'first line'));
      await tester.pumpWidget(row(text: 'second line', id: 'm2'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.semantics.byLabel(RegExp('Charlie')), findsOneWidget);
      expect(find.semantics.byLabel(RegExp('second line')), findsOneWidget);
      expect(find.semantics.byLabel(RegExp('first line')), findsNothing);
      handle.dispose();
    });
  });
}
