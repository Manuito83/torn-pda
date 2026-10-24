import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_banking.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_bank_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_compose_tools.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

Future<void> _bubble(WidgetTester tester, ChatMessage message, {bool mine = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChatMessageBubble(message: message, isMine: mine, isFirstInGroup: true, isLastInGroup: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ChatMessage _request({String room = 'faction', String text = 'banker can I get 5m'}) =>
    chatMessage('1', room, sender: 7, text: text);

void main() {
  useTempPathProvider();

  late FakeChatSource source;
  late ChatController chat;

  setUp(() {
    source = FakeChatSource();
    chat = ChatController(source, ChatPrefs());
    source.emit(const ChatReadyEvent(1, myName: 'Me'));
    ChatBankInsert.chat = () => chat;
    NativeChat.prefs.factionBanker = true;
  });

  tearDown(() {
    chat.dispose();
    NativeChat.prefs.factionBanker = false;
    NativeChat.prefs.compactMode = false;
    NativeChat.linkWindow.value = null;
  });

  group('give button', () {
    testWidgets('opens the vault page for the sender with the amount', (tester) async {
      await _bubble(tester, _request());
      expect(find.text('Give \$5,000,000'), findsOneWidget);
      await tester.tap(find.byKey(ChatBankInsert.buttonKey));
      expect(
        NativeChat.linkWindow.value?.url,
        'https://www.torn.com/factions.php?step=your#/tab=controls&giveMoneyTo=7&money=5000000',
      );
    });

    testWidgets('a request for everything sends the full balance marker', (tester) async {
      await _bubble(tester, _request(text: 'banker send me all please'));
      await tester.tap(find.byKey(ChatBankInsert.buttonKey));
      expect(NativeChat.linkWindow.value?.url, endsWith('giveMoneyTo=7&money=SEND_FULL'));
    });

    testWidgets('nothing outside the faction room', (tester) async {
      await _bubble(tester, _request(room: 'global'));
      expect(find.byKey(ChatBankInsert.buttonKey), findsNothing);
    });

    testWidgets('nothing on a message that is not a request', (tester) async {
      await _bubble(tester, _request(text: 'war starts at 5'));
      expect(find.byKey(ChatBankInsert.buttonKey), findsNothing);
    });

    testWidgets('nothing on the own message', (tester) async {
      await _bubble(tester, _request(), mine: true);
      expect(find.byKey(ChatBankInsert.buttonKey), findsNothing);
    });
  });

  group('mark as paid', () {
    Future<ChatMessage> inRoom(WidgetTester tester) async {
      final request = _request(text: 'Bank request: \$5m');
      source.emit(ChatHistoryEvent('faction', [request], hasOlder: false, isOlderPage: false));
      await _bubble(tester, request);
      return request;
    }

    Future<void> echo(WidgetTester tester) async {
      final sent = source.sent.single;
      source.emit(ChatMessageEvent(chatMessage('9', 'faction', sender: 1, text: sent.content, reqId: sent.reqId)));
      await tester.pumpAndSettle();
    }

    testWidgets('sends the paid line and the request shows as paid', (tester) async {
      await inRoom(tester);
      await tester.tap(find.byKey(ChatBankInsert.paidKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(source.sent.map((s) => s.content), ['Paid \$5,000,000 to Bravo [7]']);
      await echo(tester);
      expect(find.byKey(ChatBankInsert.paidKey), findsNothing);
      expect(find.textContaining('Paid by'), findsOneWidget);
    });

    testWidgets('giving on a paid request asks first', (tester) async {
      await inRoom(tester);
      await tester.tap(find.byKey(ChatBankInsert.paidKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      await echo(tester);
      await tester.tap(find.byKey(ChatBankInsert.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(NativeChat.linkWindow.value, isNull);
      await tester.tap(find.byKey(ChatBankInsert.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(NativeChat.linkWindow.value?.url, endsWith('giveMoneyTo=7&money=5000000'));
    });

    testWidgets('the banker can change the amount paid', (tester) async {
      await inRoom(tester);
      await tester.tap(find.byKey(ChatBankInsert.paidKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3m');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(source.sent.single.content, 'Paid \$3,000,000 to Bravo [7]');
      await echo(tester);
    });

    testWidgets('cancelling the confirmation sends nothing', (tester) async {
      await inRoom(tester);
      await tester.tap(find.byKey(ChatBankInsert.paidKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(source.sent, isEmpty);
      expect(find.byKey(ChatBankInsert.buttonKey), findsOneWidget);
    });

    testWidgets('a cancelled request loses its buttons', (tester) async {
      final request = await inRoom(tester);
      source.emit(
        ChatMessageEvent(chatMessage('2', 'faction', sender: request.sender.id, text: ChatBanking.cancelText)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ChatBankInsert.buttonKey), findsNothing);
      expect(find.byKey(ChatBankInsert.paidKey), findsNothing);
      expect(find.text('Cancelled'), findsOneWidget);
    });
  });

  group('request money', () {
    Future<List<String>> tools(WidgetTester tester, String room) async {
      final inserted = <String>[];
      NativeChat.prefs.quickHidden = {};
      tester.view.physicalSize = const Size(2400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatComposeTools(onInsert: inserted.add, roomId: room),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return inserted;
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Request money'));
      await tester.pumpAndSettle();
    }

    testWidgets('inserts the request text without sending', (tester) async {
      final inserted = await tools(tester, 'faction');
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '2.5m');
      await tester.tap(find.text('Add to message'));
      await tester.pumpAndSettle();
      expect(inserted, ['Bank request: \$2.5m']);
      expect(source.sent, isEmpty);
    });

    testWidgets('quick actions insert their fixed text', (tester) async {
      final inserted = await tools(tester, 'faction');
      for (final label in ['Request full balance', 'Cancel request', 'Call bankers']) {
        await openDialog(tester);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(inserted, [ChatBanking.fullText, ChatBanking.cancelText, ChatBanking.callText]);
    });

    testWidgets('asks again when the amount is not a figure', (tester) async {
      final inserted = await tools(tester, 'faction');
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), 'lots');
      await tester.tap(find.text('Add to message'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Enter an amount'), findsOneWidget);
      expect(inserted, isEmpty);
    });

    testWidgets('cancel inserts nothing', (tester) async {
      final inserted = await tools(tester, 'faction');
      await openDialog(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(inserted, isEmpty);
    });

    testWidgets('only in the faction room', (tester) async {
      await tools(tester, 'global');
      expect(find.text('Request money'), findsNothing);
    });
  });
}
