import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_inbox_snapshot.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_typing_report.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

const _bravo = ChatUser(id: 2, name: 'Bravo');
const _dm = ChatRoom(id: 'dm:7', name: 'Charlie', type: ChatRoomType.dm);
const _faction = ChatRoom(id: 'faction', name: 'Faction');
const _calm = ChatRoom(id: 'quiet', name: 'Quiet', reportTyping: false);

List<String> _typingCalls(FakeChatSource source) => [
  for (final c in source.calls)
    if (c.startsWith('typing ')) c,
];

// Ghost line holds the height
Finder _shown(WidgetTester tester, String text) => find.byWidgetPredicate((w) {
  if (w is! RichText || !w.text.toPlainText().contains(text)) return false;
  final element = tester.element(find.byWidget(w));
  var hidden = false;
  element.visitAncestorElements((a) {
    final widget = a.widget;
    if (widget is Opacity && widget.opacity == 0) hidden = true;
    return !hidden;
  });
  return !hidden;
});

void main() {
  useTempPathProvider();

  group('report', () {
    late DateTime clock;
    late List<String> sent;
    late ChatTypingReport report;

    setUp(() {
      clock = DateTime(2026, 10, 29, 12);
      sent = [];
      report = ChatTypingReport((room, on) => sent.add('$room $on'), now: () => clock);
    });

    void type(String text, {String room = 'dm:7', bool allowed = true}) =>
        report.typed(room, text, allowed: allowed);

    test('a burst of keys sends one start per three seconds', () {
      type('h');
      clock = clock.add(const Duration(milliseconds: 900));
      type('he');
      clock = clock.add(const Duration(milliseconds: 1900));
      type('hel');
      expect(sent, ['dm:7 true']);
      clock = clock.add(const Duration(milliseconds: 300));
      type('hell');
      expect(sent, ['dm:7 true', 'dm:7 true']);
    });

    test('emptying the box stops it once, and only after a start', () {
      type('');
      type('h');
      type('');
      type('');
      expect(sent, ['dm:7 true', 'dm:7 false']);
    });

    test('a stop does not reset the throttle of the starts', () {
      type('h');
      clock = clock.add(const Duration(seconds: 1));
      type('');
      type('a');
      expect(sent, ['dm:7 true', 'dm:7 false']);
      clock = clock.add(const Duration(seconds: 2));
      type('ab');
      expect(sent, ['dm:7 true', 'dm:7 false', 'dm:7 true']);
    });

    test('not allowed sends nothing and does not arm the throttle', () {
      type('h', allowed: false);
      type('he');
      expect(sent, ['dm:7 true']);
    });
  });

  group('line', () {
    test('private chats say typing, groups name who', () {
      expect(chatTypingLine(const [], isDm: true), isNull);
      expect(chatTypingLine(['Bravo'], isDm: true), 'typing…');
      expect(chatTypingLine(['Delta'], isDm: false), 'Delta is typing…');
      expect(chatTypingLine(['Delta', 'Echo'], isDm: false), 'Delta and Echo are typing…');
      expect(chatTypingLine(['Delta', 'Echo', 'Foxtrot', 'Golf'], isDm: false), 'Delta, Echo and 2 more are typing…');
    });
  });

  group('controller', () {
    late FakeChatSource source;
    late ChatController chat;

    List<String> typingCalls() => _typingCalls(source);

    void connect({List<ChatRoom> rooms = const [_faction, _calm]}) => source
      ..emit(const ChatReadyEvent(1, myName: 'Me'))
      ..emit(const ChatConnectionEvent(ChatConnection.connected))
      ..emit(ChatRoomsEvent(rooms))
      ..emit(const ChatDmsEvent([_dm]));

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      source = FakeChatSource();
      chat = ChatController(source, ChatPrefs());
    });

    tearDown(() => chat.dispose());

    test('private chats and open rooms report', () {
      connect();
      chat.typed('dm:7', 'h');
      chat.typed('faction', 'h');
      expect(typingCalls(), ['typing dm:7 true', 'typing faction true']);
    });

    test('rooms whose rule says no never report', () {
      connect(rooms: const [_faction, _calm, ChatRoom(id: 'trade', name: 'Trade', reportTyping: false)]);
      chat.typed('quiet', 'hello');
      chat.typed('trade', 'hello');
      chat.typingStopped('trade');
      expect(typingCalls(), isEmpty);
    });

    test('Global and Trade stay silent before Torn answers', () {
      source
        ..emit(const ChatReadyEvent(1))
        ..emit(const ChatConnectionEvent(ChatConnection.connected));
      chat.typed('global', 'hello');
      chat.typed('trade', 'hello');
      expect(typingCalls(), isEmpty);
    });

    test('a room nobody listed never reports', () {
      connect();
      chat.typed('mystery', 'hello');
      expect(typingCalls(), isEmpty);
    });

    test('the rule of the server replaces the default', () {
      connect(rooms: const [ChatRoom(id: 'global', name: 'Global')]);
      chat.typed('global', 'hello');
      expect(typingCalls(), ['typing global true']);
    });

    test('sending clears it', () {
      connect();
      chat.typed('dm:7', 'hi');
      chat.send('hi', to: 'dm:7');
      expect(typingCalls(), ['typing dm:7 true', 'typing dm:7 false']);
    });

    test('no session, no report', () {
      connect();
      source.emit(const ChatConnectionEvent(ChatConnection.twoFactor));
      chat.typed('dm:7', 'h');
      expect(typingCalls(), isEmpty);
    });

    test('a paused app does not report', () {
      connect();
      chat.paused();
      chat.typed('dm:7', 'h');
      expect(typingCalls(), isEmpty);
    });

    test('the saved inbox keeps the rule', () {
      const snapshot = ChatInboxSnapshot(owner: 1, rooms: [_calm, _faction], last: {}, unread: {});
      final back = ChatInboxSnapshot.decode(snapshot.encode(), 1)!;
      expect({for (final r in back.rooms) r.id: r.reportTyping}, {'quiet': false, 'faction': true});
    });

  });

  testWidgets('what others type shows for twelve seconds', (tester) async {
    final source = FakeChatSource();
    final chat = ChatController(source, ChatPrefs());
    source.emit(const ChatTypingEvent('dm:7', [_bravo]));
    expect(chat.typingIn('dm:7'), isNotEmpty);
    await tester.pump(const Duration(seconds: 11));
    expect(chat.typingIn('dm:7'), isNotEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(chat.typingIn('dm:7'), isEmpty);
    chat.dispose();
  });

  group('composer', () {
    late FakeChatSource source;
    late ChatController chat;

    Future<void> mount(WidgetTester tester) async {
      source = FakeChatSource();
      chat = ChatController(source, ChatPrefs());
      source
        ..emit(const ChatReadyEvent(1))
        ..emit(const ChatConnectionEvent(ChatConnection.connected))
        ..emit(const ChatDmsEvent([_dm]));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatComposer(roomName: 'Charlie', roomId: 'dm:7', chat: chat, enabled: true, onSend: (_) {}),
            ),
          ),
        ),
      );
    }

    // The ready event leaves timers behind
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    }

    testWidgets('typing starts it and leaving with text stops it', (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(TextField), 'h');
      expect(_typingCalls(source), ['typing dm:7 true']);
      await tester.pumpWidget(const SizedBox());
      expect(_typingCalls(source), ['typing dm:7 true', 'typing dm:7 false']);
      chat.dispose();
    });

    testWidgets('text set by code is not typing', (tester) async {
      await mount(tester);
      tester.widget<TextField>(find.byType(TextField)).controller!.text = 'a restored draft';
      await tester.pump();
      expect(_typingCalls(source), isEmpty);
      await unmount(tester);
      expect(_typingCalls(source), isEmpty);
    });
  });

  group('row', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      NativeChat.prefs.previewLines = 3;
    });

    const longText = 'a long message that needs several lines of the narrow preview to be read in full by '
        'anyone who looks at the list of chats on a small phone screen right now';

    Widget row({List<ChatUser> typing = const [], ChatRoom room = _dm, String draft = ''}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 260,
            child: ChatConversationTile(
              room: room,
              last: chatMessage('m1', room.id, text: longText),
              unread: 0,
              myUserId: 99,
              draft: draft,
              typing: typing,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    testWidgets('a private chat says typing instead of the last line', (tester) async {
      await tester.pumpWidget(row(typing: const [_bravo]));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('typing…'), findsOneWidget);
      expect(_shown(tester, 'long message'), findsNothing);
    });

    testWidgets('typing wins over a draft and comes back to the last line', (tester) async {
      await tester.pumpWidget(row(typing: const [_bravo], draft: 'my draft'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('typing…'), findsOneWidget);
      expect(_shown(tester, 'my draft'), findsNothing);
      await tester.pumpWidget(row());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('typing…'), findsNothing);
      expect(_shown(tester, 'long message'), findsOneWidget);
    });

    testWidgets('the row keeps its height while someone types', (tester) async {
      await tester.pumpWidget(row());
      await tester.pump(const Duration(seconds: 1));
      final quiet = tester.getSize(find.byType(AnimatedSwitcher)).height;
      await tester.pumpWidget(row(typing: const [_bravo]));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(find.byType(AnimatedSwitcher)).height, quiet);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getSize(find.byType(AnimatedSwitcher)).height, quiet);
      await tester.pumpWidget(row());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getSize(find.byType(AnimatedSwitcher)).height, quiet);
    });
  });
}
