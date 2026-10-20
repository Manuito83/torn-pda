import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart' show ItemMarket;
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/chat/chat_item_price.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/inventory/inventory_v2_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/inventory_provider.dart';
import 'package:torn_pda/widgets/chat/chat_alias_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_price_check_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

void main() {
  final catalog = ItemsModel(
    items: {
      '206': Item(name: 'Xanax', marketValue: 830000, type: ItemType.DRUG),
      '367': Item(name: 'Feathery Hotel Coupon', marketValue: 12500000),
      '1': Item(name: 'Hammer', marketValue: 0),
      '2': Item(name: 'Box of Xanax Lookalikes', marketValue: 100000),
      '3': Item(name: 'Donator Pack', marketValue: 1200000),
      '4': Item(name: 'Erotic DVD', marketValue: 1000000),
      '5': Item(name: 'Small First Aid Kit', marketValue: 60000),
      '6': Item(name: 'Anti Xanax', marketValue: null),
    },
  );
  const aliases = ChatItemAliases.defaults;

  List<String> names(String text, [List<ChatItemAlias> aliases = const []]) =>
      ChatPriceCheck.find(text, catalog, aliases).map((c) => c.name).toList();

  ChatPriceCheck? one(String text) {
    final found = ChatPriceCheck.find(text, catalog);
    return found.isEmpty ? null : found.first;
  }

  group('offers', () {
    test('reads prices with suffixes, dollars and commas', () {
      expect(one('WTS Xanax 800k')!.asked, 800000);
      expect(one(r'WTB Xanax $812,000 pm me')!.asked, 812000);
      expect(one('selling Donator Pack 1.2m')!.asked, 1200000);
      expect(one('WTS Xanax 800k')!.type, 'DRUG');
    });

    test('understands the usual room formats', () {
      expect(one('S: Xanax 830k')!.asked, 830000);
      expect(one('B: Xanax 830k')!.asked, 830000);
      expect(one('Paying 810k ea for Xanax, any amount')!.asked, 810000);
      expect(one('buying Xanax @ 800k pm me')!.asked, 800000);
      expect(one('Selling Xanax 805k 100% MV')!.asked, 805000);
      expect(one('Buying Xanax 100% MV'), isNull);
    });

    test('compares the asked price with the market', () {
      final under = one('WTS Xanax 800k')!;
      expect((under.market, (under.ratio * 100).round()), (830000, -4));
      expect(under.tone, ChatPriceTone.good);
      expect(one('selling Donator Pack 1.2m')!.ratio, 0);
      expect(one(r'WTB Xanax $812,000')!.tone, ChatPriceTone.near);
      expect(one('WTS Xanax 900k')!.tone, ChatPriceTone.near);
      expect(one('WTS Xanax 200k')!.tone, ChatPriceTone.off);
      expect(one('WTS Xanax 1.2m')!.tone, ChatPriceTone.off);
    });

    test('pairs up to three items with their own price', () {
      final found = ChatPriceCheck.find(
        'WTS Xanax 800k, Donator Pack 1.2m, Erotic DVD 1m, Small First Aid Kit 60k',
        catalog,
      );
      expect(found.map((c) => c.name), ['Xanax', 'Donator Pack', 'Erotic DVD']);
      expect(found.map((c) => c.asked), [800000, 1200000, 1000000]);
      expect(names('WTS Box of Xanax Lookalikes 100k'), ['Box of Xanax Lookalikes']);
    });

    test('needs an offer word, a priced item and a price', () {
      for (final text in [
        'Xanax is 800k now',
        'anyone know how much Xanax goes for 800k?',
        'WTS Xanax pm me',
        'WTS Xanax 5',
        'WTS Plushie 800k',
        'WTS Hammer 800k',
        'WTS Xanaxes 800k',
        'WTS 5x Xanax 4m',
      ]) {
        expect(one(text), isNull, reason: text);
      }
      expect(one('WTS 5x Xanax 800k each')!.asked, 800000);
    });

    test('formats short prices', () {
      expect(ChatPriceCheck.short(812000), '812k');
      expect(ChatPriceCheck.short(12500000), '12.5m');
      expect(ChatPriceCheck.short(2000000000), '2b');
    });

    testWidgets('with the price chip off the catalog is not fetched', (tester) async {
      final original = ChatLinkPreviews.fetchItems;
      addTearDown(() {
        ChatLinkPreviews.fetchItems = original;
        NativeChat.prefs.priceCheck = true;
      });
      var calls = 0;
      ChatLinkPreviews.fetchItems = () async {
        calls++;
        return catalog;
      };
      ChatLinkPreviews.resetForTests();
      NativeChat.prefs.priceCheck = false;
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatTradeInsert(roomId: 'trade', text: 'WTS Xanax 800k', userId: null, color: Colors.black),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
    });
  });

  group('market line', () {
    final listings = ItemMarket.fromJson({
      'item': {'id': 206, 'name': 'Xanax', 'type': 'Drug', 'average_price': 847000},
      'listings': [
        {'price': 818500, 'amount': 4},
        {'price': 830000, 'amount': 1},
        {'price': 812000, 'amount': 3},
        {'price': 815000, 'amount': 10},
      ],
      'cache_timestamp': 1,
    }).listings;

    test('shows the three cheapest, cheapest first', () {
      expect(ChatPriceCheck.lowestListed(listings), r'$812,000 x3 - $815,000 x10 - $818,500 x4');
    });

    test('is null without listings', () {
      expect(ChatPriceCheck.lowestListed(const []), isNull);
    });

    Future<void> pumpChips(WidgetTester tester, Future<List<Object>?> Function(int) market, [String? text]) async {
      final fetchItems = ChatLinkPreviews.fetchItems;
      final fetchMarket = ChatLinkPreviews.fetchMarket;
      addTearDown(() {
        ChatLinkPreviews.fetchItems = fetchItems;
        ChatLinkPreviews.fetchMarket = fetchMarket;
      });
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => catalog;
      ChatLinkPreviews.fetchMarket = market;
      NativeChat.prefs.priceCheck = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTradeInsert(
              roomId: 'trade',
              text: text ?? 'WTS 20x Xanax 830k each',
              userId: null,
              color: Colors.black,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a points offer gets its own chip, asked only then', (tester) async {
      final asked = <int>[];
      await pumpChips(tester, (id) async {
        asked.add(id);
        return ChatPriceCheck.pointsListings({
          'pointsmarket': [
            {'cost': 44600, 'quantity': 1200},
          ],
        });
      }, 'selling 500 pts @ 46k');
      expect(find.text(r'3% over market - lowest $44.6k'), findsOneWidget);
      await tester.tap(find.textContaining('lowest'));
      await tester.pumpAndSettle();
      expect(find.textContaining(r'$44,600 x1200'), findsOneWidget);
      expect(asked, [ChatPriceCheck.pointsId]);
    });

    testWidgets('tapping the chip asks once and toggles the line', (tester) async {
      var calls = 0;
      await pumpChips(tester, (id) async {
        calls++;
        return listings;
      });
      expect(calls, 0);
      await tester.tap(find.textContaining('market'));
      await tester.pumpAndSettle();
      expect(find.text(r'Lowest listed: $812,000 x3 - $815,000 x10 - $818,500 x4'), findsOneWidget);
      await tester.tap(find.textContaining('market'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lowest listed'), findsNothing);
      await tester.tap(find.textContaining('market'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lowest listed'), findsOneWidget);
      expect(calls, 1);
    });

    testWidgets('says so when there are no listings', (tester) async {
      await pumpChips(tester, (id) async => <Object>[]);
      await tester.tap(find.textContaining('market'));
      await tester.pumpAndSettle();
      expect(find.text('No listings'), findsOneWidget);
    });

    testWidgets('says so when it fails', (tester) async {
      await pumpChips(tester, (id) async => null);
      await tester.tap(find.textContaining('market'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load listings"), findsOneWidget);
    });
  });

  group('own stock', () {
    Future<List<String>> pumpStock(WidgetTester tester, InventoryCategoryFetcher fetch, List<String> texts) async {
      final fetchItems = ChatLinkPreviews.fetchItems;
      addTearDown(() => ChatLinkPreviews.fetchItems = fetchItems);
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => catalog;
      NativeChat.prefs.priceCheck = true;
      final asked = <String>[];
      final stock = InventoryProvider(
        fetcher: (category, {required withDisplay}) {
          asked.add(category);
          return fetch(category, withDisplay: withDisplay);
        },
        readStore: () async => '',
        writeStore: (_) async {},
      );
      addTearDown(stock.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: stock,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  for (final t in texts) ChatTradeInsert(roomId: 'trade', text: t, userId: null, color: Colors.black),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      return asked;
    }

    InventoryV2Category owned(int amount) => InventoryV2Category(
      items: [InventoryV2Item(id: 206, amount: amount, equipped: false, name: '', factionOwned: false)],
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    testWidgets('shows the stock under the chip and asks once per category', (tester) async {
      final asked = await pumpStock(tester, (c, {required withDisplay}) async => owned(14), [
        'WTS Xanax 800k',
        'WTB Xanax 810k',
      ]);
      expect(find.text('You have 14 - only you see this'), findsNWidgets(2));
      expect(asked, ['Drug']);
    });

    testWidgets('a failed category adds no line and is not asked again', (tester) async {
      final asked = await pumpStock(tester, (c, {required withDisplay}) async => null, [
        'WTS Xanax 800k',
        'WTB Xanax 810k',
      ]);
      expect(find.textContaining('only you see this'), findsNothing);
      expect(asked, ['Drug']);
    });
  });

  group('item search', () {
    test('ranks exact and prefix matches first', () {
      expect(ChatItemPrice.search(catalog, 'xanax').map((i) => i.name), [
        'Xanax',
        'Anti Xanax',
        'Box of Xanax Lookalikes',
      ]);
      expect(ChatItemPrice.search(catalog, 'x'), isEmpty);
    });

    test('shows the market price when there is one', () {
      expect(ChatItemPrice.search(catalog, 'xanax').first.text(), r'Xanax $830,000');
      expect(ChatItemPrice.search(catalog, 'hammer').first.text(), 'Hammer');
      expect(ChatItemPrice.search(catalog, 'anti').first.text(), 'Anti Xanax');
    });

    test('the market link parses back to the item', () {
      final text = ChatItemPrice.search(catalog, 'feathery').first.text(link: true);
      expect(text, startsWith(r'Feathery Hotel Coupon $12,500,000 https://'));
      final link = ChatLink.split(text).whereType<ChatLink>().firstWhere((l) => l.kind == ChatLinkKind.item);
      expect(link.id, 367);
    });
  });

  group('nicknames', () {
    test('offers understand nicknames', () {
      final found = ChatPriceCheck.find('WTS xans 800k', catalog, aliases);
      expect(found.single.name, 'Xanax');
      expect(found.single.asked, 800000);
      expect(names('WTB fhc 12m, edvd 1m', aliases), ['Feathery Hotel Coupon', 'Erotic DVD']);
      expect(names('WTS edvds 1.1m ea and fhcs 12.4m ea', aliases), ['Erotic DVD', 'Feathery Hotel Coupon']);
      expect(names('WTB e-dvd 1m', aliases), ['Erotic DVD']);
    });

    test('nickname rejections', () {
      expect(names('WTS xans 800k'), isEmpty);
      expect(names('WTS xanses 800k', aliases), isEmpty);
      expect(names('WTS munster 50k', aliases), isEmpty);
    });

    test('item search resolves a nickname', () {
      expect(ChatItemPrice.search(catalog, 'xans', aliases).first.name, 'Xanax');
      expect(ChatItemPrice.search(catalog, 'xans'), isEmpty);
    });

    test('cleans and validates a nickname', () {
      expect(ChatItemAliases.cleanAlias('  XANS '), 'xans');
      expect(ChatItemAliases.cleanAlias('x'), isNull);
      expect(ChatItemAliases.cleanAlias('a<b>'), isNull);
    });

    test('stored and exported lists round trip', () {
      expect(ChatItemAliases.decode(''), ChatItemAliases.defaults);
      expect(ChatItemAliases.decode('oops'), ChatItemAliases.defaults);
      expect(ChatItemAliases.decode('[]'), isEmpty);
      const own = [ChatItemAlias('pills', 'Xanax')];
      expect(ChatItemAliases.decode(ChatItemAliases.encode(own)), own);
      final parsed = ChatItemAliases.parse(ChatItemAliases.export(aliases))!;
      expect(parsed.$1, aliases);
      expect(parsed.$2, 0);
    });

    test('import keeps the valid ones and counts the rest', () {
      final parsed = ChatItemAliases.parse(
        '[{"alias":"Zan","item":"Xanax"},{"alias":"x","item":"Xanax"},{"alias":"ok"},5]',
      )!;
      expect(parsed.$1, [const ChatItemAlias('zan', 'Xanax')]);
      expect(parsed.$2, 3);
      for (final text in ['hello', '{"a":1}', '[]', '[{"alias":"x"}]']) {
        expect(ChatItemAliases.parse(text), isNull, reason: text);
      }
    });

    test('merge keeps existing ones and skips duplicates', () {
      const current = [ChatItemAlias('xans', 'Something Else')];
      final merged = ChatItemAliases.merge(current, const [
        ChatItemAlias('xans', 'Xanax'),
        ChatItemAlias('fhc', 'Feathery Hotel Coupon'),
        ChatItemAlias('fhc', 'Feathery Hotel Coupon'),
      ]);
      expect(merged, [current.first, const ChatItemAlias('fhc', 'Feathery Hotel Coupon')]);
    });

    testWidgets('pasted nicknames are merged into the saved list', (tester) async {
      NativeChat.prefs.itemAliases = ChatItemAliases.defaults;
      addTearDown(() => NativeChat.prefs.itemAliases = ChatItemAliases.defaults);
      await tester.pumpWidget(
        MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: Scaffold(body: ChatImportDialog.itemNicknames()),
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        '[{"alias":"pills","item":"Xanax"},{"alias":"xans","item":"Xanax"}]',
      );
      await tester.pump();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      expect(NativeChat.prefs.itemAliases.where((a) => a.alias == 'pills'), hasLength(1));
      expect(NativeChat.prefs.itemAliases.where((a) => a.alias == 'xans'), hasLength(1));
    });
  });

  group('money', () {
    int? amount(String text) {
      final refs = ChatMoneyRef.split(text).whereType<ChatMoneyRef>().toList();
      return refs.length == 1 ? refs.single.amount : null;
    }

    test('reads amounts with units and symbols', () {
      expect(amount('selling for 1.2m'), 1200000);
      expect(amount('850k'), 850000);
      expect(amount('3b'), 3000000000);
      expect(amount('1,200,000 each'), 1200000);
      expect(amount(r'pay $1.5m now'), 1500000);
      expect(amount('2.5 mil'), 2500000);
      expect(amount('1 million'), 1000000);
      expect(amount(r'$5'), 5);
      expect(amount(r'$1500'), 1500);
      expect(amount('1,200'), 1200);
      expect(amount('worth 10K.'), 10000);
      final parts = ChatMoneyRef.split('buy at 850k please');
      expect(parts.first, 'buy at ');
      expect((parts[1] as ChatMoneyRef).raw, '850k');
      expect(parts.last, ' please');
    });

    test('ignores bare numbers and other uses', () {
      for (final text in [
        '1200000',
        '25',
        'level 100',
        'id 3456789',
        '5 minutes',
        '5m ago',
        '12:30',
        '2.5',
        'v1.2m',
        'x5m',
        '5 milk',
        '5mx',
        '1.2.3m',
        '#5k',
        '15/100k',
        '1,200k',
        '1,200.5',
        '0k',
        r'$0',
        '10 m',
      ]) {
        expect(ChatMoneyRef.split(text).whereType<ChatMoneyRef>(), isEmpty, reason: text);
      }
    });

    test('compares an amount with the cash on hand', () {
      expect(ChatMoneyRef.format(1200000), r'$1,200,000');
      const ref = ChatMoneyRef(1000000, '1m');
      expect(ref.coverage(1500000), r'You have $1,500,000 on hand: enough');
      expect(ref.coverage(1000000), r'You have $1,000,000 on hand: enough');
      expect(ref.coverage(400000), r'You have $400,000 on hand: short by $600,000');
    });
  });

  group('item names in the text', () {
    final shop = ItemsModel(
      items: {
        '1': Item(name: 'Goodie Bag', marketValue: 5000),
        '2': Item(name: 'Six-Pack of Energy Drink', marketValue: 2000000),
        '3': Item(name: 'Rose', marketValue: 300),
        '4': Item(name: 'Xanax', marketValue: 830000),
      },
    );

    List<String> marked(String text) => [
      for (final part in ChatItemRef.split(text, shop, aliases))
        if (part is ChatItemRef) part.raw,
    ];

    test('marks multi word names and nicknames', () {
      expect(marked('Just making money Bazaar ___E-Cans, Xanax(182qty), Goodie Bag, Six pack Energy, etc'), [
        'Goodie Bag',
        'Six pack Energy',
      ]);
      expect(marked('goodie bag here, goodie bag there'), ['goodie bag', 'goodie bag']);
      expect(marked('who has a six-pack of energy drink or 2 xans?'), ['six-pack of energy drink', 'xans']);
    });

    test('leaves one word names alone', () {
      expect(marked('I gave her a rose and a Xanax'), isEmpty);
    });

    test('takes a plural but not half a word', () {
      expect(marked('goodie bags and goodie bagged'), ['goodie bags']);
    });

    testWidgets('tapping a name shows its value and cheapest listing', (tester) async {
      final fetchItems = ChatLinkPreviews.fetchItems;
      final fetchMarket = ChatLinkPreviews.fetchMarket;
      addTearDown(() {
        ChatLinkPreviews.fetchItems = fetchItems;
        ChatLinkPreviews.fetchMarket = fetchMarket;
      });
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => shop;
      ChatLinkPreviews.fetchMarket = (id) async => <Object>[
        {'price': 4800, 'amount': 2},
      ];
      NativeChat.prefs.priceCheck = true;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatMessageText(content: 'selling Goodie Bag cheap', color: Colors.black, roomId: 'trade'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('Goodie Bag'));
      await tester.pumpAndSettle();
      expect(find.text(r'Market value: $5k'), findsOneWidget);
      expect(find.text(r'Lowest listed: $4,800 x2'), findsOneWidget);
    });

    Future<void> openSheet(WidgetTester tester, String description) async {
      final fetchItems = ChatLinkPreviews.fetchItems;
      final fetchMarket = ChatLinkPreviews.fetchMarket;
      addTearDown(() {
        ChatLinkPreviews.fetchItems = fetchItems;
        ChatLinkPreviews.fetchMarket = fetchMarket;
      });
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => ItemsModel(
        items: {'1': Item(name: 'Goodie Bag', marketValue: 5000, description: description)},
      );
      ChatLinkPreviews.fetchMarket = (id) async => <Object>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showChatItemSheet(
                context,
                const ChatItemRef(raw: 'Goodie Bag', id: 1, type: null, name: 'Goodie Bag', market: 5000),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('a long description starts folded and More opens it', (tester) async {
      final long = List.filled(30, 'A bag full of goodies.').join(' ');
      await openSheet(tester, long);
      expect(tester.widget<Text>(find.text(long)).maxLines, 3);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text(long)).maxLines, isNull);
      await tester.ensureVisible(find.text('Less'));
      await tester.tap(find.text('Less'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text(long)).maxLines, 3);
    });

    testWidgets('a short description has no More', (tester) async {
      await openSheet(tester, 'A bag full of <b>goodies</b>.');
      expect(find.text('A bag full of goodies.'), findsOneWidget);
      expect(find.text('More'), findsNothing);
    });
  });

  group('points', () {
    final listings = ChatPriceCheck.pointsListings({
      'pointsmarket': [
        {'id': 1, 'quantity': 300, 'cost': 46000, 'total_cost': 13800000},
        {'id': 2, 'quantity': 1200, 'cost': 44600, 'total_cost': 53520000},
        {'id': 3, 'quantity': 50, 'cost': 47000, 'total_cost': 2350000},
      ],
    })!;

    test('compares the price per point with the cheapest listing', () {
      final over = ChatPriceCheck.points('WTB 2k points 45k ea', listings)!;
      expect(over.asked, 45000);
      expect(over.market, 44600);
      expect(over.label, '1% over market - lowest \$44.6k');
      expect(ChatPriceCheck.points('selling 500 pts @ 46k', listings)!.asked, 46000);
      expect(ChatPriceCheck.points('selling 500 pts @ 40k', listings)!.tone, ChatPriceTone.good);
    });

    test('no chip without a clear price per point', () {
      expect(ChatPriceCheck.points('WTB 2k points', listings), isNull);
      expect(ChatPriceCheck.points('selling points 45k and 50k', listings), isNull);
      expect(ChatPriceCheck.points('selling Xanax 800k', listings), isNull);
      expect(ChatPriceCheck.points('selling 500 pts for 100', listings), isNull);
    });

    test('divides a total only when that is the sane reading', () {
      expect(ChatPriceCheck.points('selling 500 pts for 23m', listings)!.asked, 46000);
      expect(ChatPriceCheck.points('selling 500 pts for 46k', listings)!.asked, 46000);
      expect(ChatPriceCheck.points('selling pts for 23m', listings), isNull);
    });

    test('reads listings keyed by id', () {
      final keyed = ChatPriceCheck.pointsListings({
        'pointsmarket': {
          '101': {'cost': 46000, 'quantity': 300},
          '102': {'cost': 44600, 'quantity': 1200},
        },
      })!;
      expect(keyed, hasLength(2));
      expect(ChatPriceCheck.points('selling 500 pts @ 46k', keyed)!.market, 44600);
    });

    test('a price already given to an item is skipped', () {
      expect(ChatPriceCheck.points('WTS Xanax 46k, WTB points', listings, [46000]), isNull);
    });

    test('listings need cost and ignore junk', () {
      expect(ChatPriceCheck.pointsListings({'pointsmarket': []}), isNull);
      expect(ChatPriceCheck.pointsListings({'other': 1}), isNull);
      expect(ChatPriceCheck.pointsListings(null), isNull);
      expect(
        ChatPriceCheck.pointsListings({
          'pointsmarket': [
            {'cost': 0},
            'x',
            {'cost': 45000, 'quantity': 10},
          ],
        }),
        hasLength(1),
      );
    });
  });
}
