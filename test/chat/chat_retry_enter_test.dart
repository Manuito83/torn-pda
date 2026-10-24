import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  group('retry', () {
    late FakeChatSource source;
    late ChatController chat;

    setUp(() {
      source = FakeChatSource();
      chat = ChatController(source, ChatPrefs(), null);
    });

    tearDown(() => chat.dispose());

    ChatMessage failedSend(String text) {
      chat.send(text, to: 'faction');
      final reqId = source.sent.last.reqId;
      source.emit(ChatSendResultEvent('faction', reqId, ok: false));
      return chat.messagesFor('faction').single;
    }

    test('a failed message is sent again once, with a new request id', () {
      final failed = failedSend('hello there');
      expect(failed.state, ChatMessageState.failed);

      chat.resend(failed);
      chat.resend(failed);

      final shown = chat.messagesFor('faction');
      expect(shown, hasLength(1));
      expect(shown.single.state, ChatMessageState.pending);
      expect(shown.single.content, 'hello there');
      expect(source.sent, hasLength(2));
      expect(source.sent.last.content, 'hello there');
      expect(source.sent.last.reqId, isNot(source.sent.first.reqId));
      expect(shown.single.reqId, source.sent.last.reqId);
    });

    test('a message that is not failed is left alone', () {
      chat.send('still going', to: 'faction');
      final pending = chat.messagesFor('faction').single;

      chat.resend(pending);

      expect(source.sent, hasLength(1));
      expect(chat.messagesFor('faction').single.reqId, pending.reqId);
    });

    test('keeps the text when the retry fails again', () {
      final failed = failedSend('one more time');
      chat.resend(failed);
      source.emit(ChatSendResultEvent('faction', source.sent.last.reqId, ok: false));

      final shown = chat.messagesFor('faction').single;
      expect(shown.state, ChatMessageState.failed);
      expect(shown.content, 'one more time');
    });
  });

  group('failed bubble', () {
    tearDown(() => NativeChat.prefs.compactMode = false);

    for (final compact in [false, true]) {
      testWidgets(compact ? 'tap retries in compact mode' : 'tap retries', (tester) async {
        NativeChat.prefs.compactMode = compact;
        var retried = 0;
        final failed = ChatMessage(
          id: 'm',
          reqId: 'm',
          roomId: 'faction',
          sender: const ChatUser(id: 99, name: 'Me'),
          content: 'not delivered',
          createdAt: chatNow,
          state: ChatMessageState.failed,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatMessageBubble(
                message: failed,
                isMine: true,
                isFirstInGroup: true,
                isLastInGroup: true,
                onRetry: () => retried++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('not delivered', findRichText: true));
        expect(retried, 1);
      });
    }
  });

  group('enter key', () {
    late List<String> sent;

    Future<void> composer(WidgetTester tester) async {
      sent = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatComposer(roomName: 'Faction', roomId: 'faction', enabled: true, onSend: sent.add),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'hello');
      await tester.pump();
    }

    Future<void> shiftEnter(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
    }

    setUp(() {
      NativeChat.prefs
        ..enterSendsHardware = true
        ..enterSendsSoft = false;
    });

    testWidgets('physical enter sends and shift enter does not', (tester) async {
      await composer(tester);

      await shiftEnter(tester);
      expect(sent, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, ['hello']);
    });

    testWidgets('physical enter does nothing when the option is off', (tester) async {
      NativeChat.prefs.enterSendsHardware = false;
      await composer(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('enter from a phone keyboard on screen does not send', (tester) async {
      await composer(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('enter while composing does not send', (tester) async {
      await composer(tester);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'hello', composing: TextRange(start: 0, end: 5)),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('replying with the field focused shows the keyboard again', (tester) async {
      final reply = ValueNotifier<ChatMessage?>(null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<ChatMessage?>(
              valueListenable: reply,
              builder: (_, message, _) => Align(
                alignment: Alignment.bottomCenter,
                child: ChatComposer(roomName: 'Faction', roomId: 'faction', enabled: true, onSend: (_) {}, replyTo: message),
              ),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(TextField).first);
      tester.testTextInput.log.clear();

      reply.value = ChatMessage(
        id: 'm',
        reqId: 'm',
        roomId: 'faction',
        sender: const ChatUser(id: 5, name: 'Other'),
        content: 'hi',
        createdAt: chatNow,
      );
      await tester.pump();

      expect(tester.testTextInput.log.map((c) => c.method), contains('TextInput.show'));
    });

    testWidgets('the on-screen action key sends only when the option is on', (tester) async {
      await composer(tester);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(sent, isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField).first).textInputAction, TextInputAction.newline);

      NativeChat.prefs.enterSendsSoft = true;
      await composer(tester);
      expect(tester.widget<TextField>(find.byType(TextField).first).textInputAction, TextInputAction.send);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(sent, ['hello']);
    });
  });
}
