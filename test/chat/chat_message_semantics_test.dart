import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_bank_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

Future<void> _bubble(WidgetTester tester, ChatMessage message) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChatMessageBubble(message: message, isMine: false, isFirstInGroup: true, isLastInGroup: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _act(WidgetTester tester, Finder node, String label) {
  final semantics = tester.getSemantics(node);
  final id = semantics.getSemanticsData().customSemanticsActionIds!.firstWhere(
    (id) => CustomSemanticsAction.getAction(id)?.label == label,
  );
  semantics.owner!.performAction(semantics.id, SemanticsAction.customAction, id);
}

void main() {
  useTempPathProvider();

  group('spoken text', () {
    test('decodes entities Torn leaves in messages', () {
      expect(chatSpokenText('CHEAP&nbsp;&nbsp;CANS &amp; CANDY&#33; &#x1F4B8;'), 'CHEAP CANS & CANDY! 💸');
      expect(chatSpokenText('a &bogus; b'), 'a &bogus; b');
    });

    test('says links by name, not by address', () {
      expect(
        chatSpokenText('💸 [BAZAAR](https://www.torn.com/bazaar.php?userId=4419419#/)!'),
        '💸 BAZAAR link!',
      );
      expect(chatSpokenText('see https://www.example.com/a/b?c=1 now'), 'see link to example.com now');
      expect(chatSpokenText('https://i.imgur.com/abc.png'), 'image from i.imgur.com');
      expect(chatSpokenText('https://www.torn.com/profiles.php?XID=7'), 'link to Player 7');
    });
  });

  group('what sits under a message', () {
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
      NativeChat.linkWindow.value = null;
    });

    testWidgets('a reader can give money from a bank request', (tester) async {
      final semantics = tester.ensureSemantics();
      await _bubble(tester, chatMessage('1', 'faction', sender: 7, name: 'Bravo', text: 'banker can I get 5m'));

      expect(find.bySemanticsLabel(RegExp(r'^Bravo, banker can I get 5m, ')), findsOneWidget);
      final give = find.bySemanticsLabel('Give \$5,000,000');
      expect(give, findsOneWidget);
      tester.getSemantics(give).owner!.performAction(tester.getSemantics(give).id, SemanticsAction.tap);
      expect(NativeChat.linkWindow.value?.url, contains('giveMoneyTo=7&money=5000000'));
      semantics.dispose();
    });

    testWidgets('a time in a message opens its conversion from the reader menu', (tester) async {
      final semantics = tester.ensureSemantics();
      await _bubble(tester, chatMessage('1', 'faction', sender: 7, name: 'Bravo', text: 'raid at 18:00 TCT'));

      _act(tester, find.bySemanticsLabel(RegExp('^Bravo, raid at')), '18:00 TCT in your time');
      await tester.pumpAndSettle();
      expect(find.textContaining('your time'), findsOneWidget);
      semantics.dispose();
    });
  });
}
