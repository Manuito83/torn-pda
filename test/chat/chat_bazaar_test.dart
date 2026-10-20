import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_bazaar.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_bazaar_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_price_check_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

Map<String, dynamic> row(int id, String name, int price, int market, [int quantity = 1]) => {
  'ID': id,
  'name': name,
  'type': 'Drug',
  'quantity': quantity,
  'price': price,
  'market_price': market,
};

Map<String, dynamic> profile(List<Map<String, dynamic>> rows, {Object? open = 1}) => {
  'bazaar_is_open': open,
  'bazaar': rows,
};

void main() {
  group('median', () {
    test('ignores outliers and missing market values', () {
      final bazaar = ChatBazaar.parse(
        profile([
          row(1, 'A', 960, 1000),
          row(2, 'B', 1040, 1000),
          row(3, 'C', 1100, 1000),
          row(4, 'D', 1200, 1000),
          row(5, 'E', 999999999, 1000),
          row(6, 'No value', 5, 0),
        ]),
      )!;
      expect(bazaar.median, closeTo(0.10, 1e-9));
    });

    test('averages the two middle ones', () {
      final bazaar = ChatBazaar.parse(profile([row(1, 'A', 1040, 1000), row(2, 'B', 1100, 1000)]))!;
      expect(bazaar.median, closeTo(0.07, 1e-9));
    });

    test('is null when nothing has a market value', () {
      expect(ChatBazaar.parse(profile([row(1, 'A', 50, 0)]))!.median, isNull);
    });

    test('reads prices that come as doubles', () {
      final bazaar = ChatBazaar.parse(
        profile([
          {...row(1, 'A', 0, 0), 'price': 1040.0, 'market_price': 1000.0},
        ]),
      )!;
      expect(bazaar.median, closeTo(0.04, 1e-9));
    });
  });

  group('parse', () {
    test('a closed bazaar has no items', () {
      final bazaar = ChatBazaar.parse(profile([row(1, 'A', 1040, 1000)], open: 0))!;
      expect(bazaar.open, isFalse);
      expect(bazaar.items, isEmpty);
    });

    test('no bazaar in the profile is null', () {
      expect(ChatBazaar.parse({'profile': {}}), isNull);
    });
  });

  group('tone', () {
    test('very cheap is good, only dear is off', () {
      ChatPriceTone? tone(int price) =>
          ChatBazaar.tone(ChatBazaar.parse(profile([row(1, 'A', price, 1000)]))!.items.single);
      expect(tone(500), ChatPriceTone.good);
      expect(tone(960), ChatPriceTone.good);
      expect(tone(1050), ChatPriceTone.near);
      expect(tone(1400), ChatPriceTone.off);
    });
  });

  group('named items', () {
    final bazaar = ChatBazaar.parse(profile([for (var id = 1; id <= 6; id++) row(id, 'Item $id', 1000, 1000)]))!;

    test('at most three, in bazaar order', () {
      expect(bazaar.named({6, 5, 4, 3, 2}).map((i) => i.id), [2, 3, 4]);
    });

    test('come first in the full list, the rest keep their order', () {
      expect(bazaar.ordered({5, 2}).map((i) => i.id), [2, 5, 1, 3, 4, 6]);
    });

    test('names that are not in the bazaar are ignored', () {
      expect(bazaar.named({99}), isEmpty);
      expect(bazaar.ordered({99}).length, 6);
    });
  });

  group('page filler', () {
    test('a name with quotes and slashes stays one string', () {
      const name = 'Bob\'s "Plush" \\ line\nbreak';
      final script = ChatBazaar.fillScript(name);
      final start = script.indexOf('var n=') + 6;
      final literal = script.substring(start, script.indexOf(',t=0'));
      expect(jsonDecode(literal), name);
    });
  });

  group('check bazaar', () {
    final catalog = ItemsModel(items: {'206': Item(name: 'Xanax', marketValue: 830000)});
    late int calls;

    setUp(() {
      calls = 0;
      ChatPlayerCards.resetForTests();
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => catalog;
      ChatPlayerCards.fetch = (id) async {
        calls++;
        return profile([row(206, 'Xanax', 812000, 830000, 182)]);
      };
      NativeChat.prefs.priceCheck = true;
    });

    tearDown(() {
      ChatPlayerCards.resetForTests();
      ChatLinkPreviews.resetForTests();
    });

    Future<void> pump(WidgetTester tester, {String text = 'WTS Xanax 800k', int? userId = 7}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTradeInsert(roomId: 'trade', text: text, userId: userId, color: Colors.black),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final tapRow = find.byKey(ChatTradeInsert.checkKey);

    testWidgets('asks nothing until the row is pressed', (tester) async {
      await pump(tester);
      expect(calls, 0);
      expect(find.byType(ChatBazaarSummary), findsNothing);

      await tester.tap(tapRow);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(ChatBazaarSummary), findsOneWidget);
    });

    testWidgets('a cached profile shows the line without asking', (tester) async {
      await ChatPlayerCards.json(7);
      expect(calls, 1);
      await pump(tester);
      expect(calls, 1);
      expect(find.byType(ChatBazaarSummary), findsOneWidget);
    });

    testWidgets('nothing without named items, own messages or with a bazaar link', (tester) async {
      for (final (text, userId) in [
        ('hello there', 7),
        ('WTS Xanax 800k', null),
        ('WTS Xanax https://www.torn.com/bazaar.php?userId=7', 7),
      ]) {
        await pump(tester, text: text, userId: userId);
        expect(tapRow, findsNothing, reason: text);
        expect(find.byType(ChatBazaarSummary), findsNothing, reason: text);
      }
      expect(calls, 0);
    });

    testWidgets('a failed load keeps the row and a quick retry asks nothing', (tester) async {
      ChatPlayerCards.fetch = (id) async {
        calls++;
        return null;
      };
      await pump(tester);
      await tester.tap(tapRow);
      await tester.pumpAndSettle();
      expect(find.byType(ChatBazaarSummary), findsNothing);
      expect(tapRow, findsOneWidget);
      expect(calls, 1);

      await tester.tap(tapRow);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(tapRow, findsOneWidget);
    });

    testWidgets('with bazaar analysis off the price stays and the bazaar goes', (tester) async {
      await ChatPlayerCards.json(7);
      NativeChat.prefs.bazaarAnalysis = false;
      addTearDown(() => NativeChat.prefs.bazaarAnalysis = true);
      await pump(tester);
      expect(find.byType(ChatBazaarSummary), findsNothing);
      expect(tapRow, findsNothing);
      expect(calls, 1);
    });

    testWidgets('a points offer with a cached profile shows no bazaar line', (tester) async {
      await ChatPlayerCards.json(7);
      await pump(tester, text: 'WTS 500 points 45k');
      expect(find.byType(ChatBazaarSummary), findsNothing);
    });
  });

  group('card', () {
    const url = 'https://www.torn.com/bazaar.php?userId=42';

    setUp(() {
      ChatPlayerCards.resetForTests();
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => ItemsModel(items: {'206': Item(name: 'Xanax', marketValue: 830000)});
      ChatPlayerCards.fetch = (id) async => {
        'profile': {'id': 42, 'name': 'Alpha'},
        ...profile([row(206, 'Xanax', 812000, 830000, 182), row(3, 'Other', 1000, 1000)]),
      };
      NativeChat.prefs
        ..priceCheck = true
        ..linkPreviews = ChatImageAutoLoad.always;
    });

    tearDown(() {
      ChatPlayerCards.resetForTests();
      ChatLinkPreviews.resetForTests();
    });

    Future<void> pump(WidgetTester tester, String room) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageText(content: 'WTS Xanax 800k $url', color: Colors.black, roomId: room),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the summary and the named item in trade', (tester) async {
      await pump(tester, 'trade');
      expect(find.byType(ChatBazaarSummary), findsOneWidget);
      expect(find.textContaining('Xanax x182'), findsOneWidget);
    });
  });

  group('sheet', () {
    final bazaar = ChatBazaar.parse(
      profile([row(3, 'Donator Pack', 1000, 1000), row(206, 'Xanax', 812000, 830000, 182)]),
    )!;

    Future<void> open(WidgetTester tester) async {
      NativeChat.linkWindow.value = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showChatBazaarSheet(context, userId: 42, bazaar: bazaar, named: {206}),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the named items first and filters locally', (tester) async {
      await open(tester);
      final first = tester.getTopLeft(find.text('Xanax')).dy;
      expect(first, lessThan(tester.getTopLeft(find.text('Donator Pack')).dy));

      await tester.enterText(find.byType(TextField), 'dona');
      await tester.pumpAndSettle();
      expect(find.text('Xanax'), findsNothing);
      expect(find.text('Donator Pack'), findsOneWidget);
    });

    testWidgets('a row opens the bazaar with its name to fill in', (tester) async {
      await open(tester);
      await tester.tap(find.text('Xanax'));
      expect(NativeChat.linkWindow.value?.url, 'https://www.torn.com/bazaar.php?userId=42');
      expect(NativeChat.linkWindow.value?.fill, 'Xanax');
      NativeChat.linkWindow.value = null;
    });

    testWidgets('the top button opens it without filling', (tester) async {
      await open(tester);
      await tester.tap(find.bySubtype<FilledButton>());
      expect(NativeChat.linkWindow.value?.url, 'https://www.torn.com/bazaar.php?userId=42');
      expect(NativeChat.linkWindow.value?.fill, isNull);
      NativeChat.linkWindow.value = null;
    });
  });

  group('own bubble', () {
    setUp(() {
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => ItemsModel(items: {'206': Item(name: 'Xanax', marketValue: 830000)});
      NativeChat.prefs.priceCheck = true;
    });

    tearDown(() {
      NativeChat.prefs.compactMode = false;
      ChatLinkPreviews.resetForTests();
    });

    for (final compact in [false, true]) {
      testWidgets(compact ? 'hangs below the compact row' : 'hangs below the message bubble', (tester) async {
        NativeChat.prefs.compactMode = compact;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatMessageBubble(
                message: chatMessage('1', 'trade', sender: 7, text: 'WTS Xanax 800k'),
                isMine: false,
                isFirstInGroup: true,
                isLastInGroup: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final chip = find.textContaining('market');
        expect(chip, findsOneWidget);
        final bubble = find.ancestor(of: find.byType(ChatMessageText), matching: find.byType(Container)).first;
        expect(find.descendant(of: bubble, matching: chip), findsNothing);
        expect(tester.getTopLeft(chip).dy, greaterThanOrEqualTo(tester.getBottomLeft(bubble).dy));
      });
    }
  });
}
