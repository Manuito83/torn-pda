import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_emoji.dart';
import 'package:torn_pda/models/chat/chat_filter.dart';
import 'package:torn_pda/models/chat/chat_item_price.dart';
import 'package:torn_pda/models/chat/chat_mentions.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_saved.dart';
import 'package:torn_pda/models/chat/chat_send_check.dart';
import 'package:torn_pda/models/chat/chat_shortcuts.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/models/chat/chat_template.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/pages/chat/chat_search_page.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/widgets/chat/chat_slot_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_status_sheet.dart';

import 'chat_fakes.dart';

const _now = 1000000;

BarsStatusCooldownsModel _bars({
  String state = 'Okay',
  int until = 0,
  String? destination,
  int arrival = 0,
  int age = 10,
  int at = _now,
  Cooldowns? cooldowns,
}) => BarsStatusCooldownsModel(
  serverTime: at - age,
  energy: PersonalBars(current: 95, maximum: 150),
  nerve: PersonalBars(current: 40, maximum: 55),
  happy: PersonalBars(current: 4500, maximum: 5025),
  life: PersonalBars(current: 900, maximum: 1200),
  status: Status(state: state, until: until),
  travel: Travel(destination: destination, timestamp: arrival),
  cooldowns: cooldowns ?? Cooldowns(drug: 0, medical: 0, booster: 0),
);

Map<String, String> _status(BarsStatusCooldownsModel bars, {int chainCurrent = 0, int chainSeconds = 0}) => {
  for (final p in ChatStatus.pieces(bars: bars, now: _now, chainCurrent: chainCurrent, chainSeconds: chainSeconds))
    p.key: p.text,
};

void main() {
  useTempPathProvider();

  group('mentions', () {
    TextEditingValue at(String text, [int? cursor]) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor ?? text.length),
    );

    test('the query is the @name that ends at the cursor', () {
      expect(ChatMentions.queryAt(at('hi @Al')), 'Al');
      expect(ChatMentions.queryAt(at('@a')), 'a');
      expect(ChatMentions.queryAt(at('hi @Al there', 6)), 'Al');
      for (final text in ['hi @', 'mail@host', 'hi @Al ']) {
        expect(ChatMentions.queryAt(at(text)), isNull, reason: text);
      }
      final selected = const TextEditingValue(text: 'hi @Al', selection: TextSelection(baseOffset: 3, extentOffset: 6));
      expect(ChatMentions.queryAt(selected), isNull);
    });

    test('picking a name replaces the query', () {
      final end = ChatMentions.insert(at('hi @al'), 'Alpha');
      expect(end.text, 'hi @Alpha ');
      expect(end.selection.baseOffset, end.text.length);
      final middle = ChatMentions.insert(at('hi @al there', 6), 'Alpha');
      expect(middle.text, 'hi @Alpha there');
      expect(middle.selection.baseOffset, 'hi @Alpha '.length);
      expect(ChatMentions.insert(at('no mention'), 'Alpha').text, 'no mention');
    });

    test('candidates are recent senders then the roster, ranked by prefix', () {
      final messages = [
        chatMessage('1', 'faction', sender: 1, name: 'Alpha'),
        chatMessage('2', 'faction', sender: 2, name: 'Bravo'),
        chatMessage('3', 'faction', sender: 99, name: 'Me'),
        chatMessage('4', 'faction', sender: 1, name: 'Alpha'),
        ChatMessage(
          id: '5',
          roomId: 'faction',
          sender: const ChatUser(id: 0, name: 'Torn'),
          content: 'x',
          createdAt: chatNow,
          isSystem: true,
        ),
      ];
      expect(ChatMentions.recentSenders(messages, 99).map((u) => u.name), ['Alpha', 'Bravo']);

      const roster = [ChatUser(id: 1, name: 'Alpha'), ChatUser(id: 2, name: 'Bravo'), ChatUser(id: 99, name: 'Me')];
      final users = ChatMentions.candidates(messages.sublist(1, 2), 99, roster);
      expect(users.map((u) => u.name), ['Bravo', 'Alpha', 'Bravo']);
      expect(ChatMentions.rank(users, 'a').map((u) => u.name), ['Alpha', 'Bravo']);

      const names = [
        ChatUser(id: 1, name: 'Malpha'),
        ChatUser(id: 2, name: 'Alpha'),
        ChatUser(id: 3, name: 'Bravo'),
        ChatUser(id: 2, name: 'Alpha'),
        ChatUser(id: 4, name: 'alps'),
      ];
      expect(ChatMentions.rank(names, 'AL').map((u) => u.id), [2, 4, 1]);
      expect(ChatMentions.rank(names, 'al', limit: 2).map((u) => u.id), [2, 4]);
    });

    test('last seen reads in short units', () {
      final now = DateTime(2026, 10, 12, 12);
      expect(ChatLastAction.ago(now.subtract(const Duration(seconds: 40)), now), isNull);
      for (final (ago, text) in [
        (const Duration(minutes: 5), '5m'),
        (const Duration(minutes: 59), '59m'),
        (const Duration(hours: 2, minutes: 50), '2h'),
        (const Duration(hours: 47), '47h'),
        (const Duration(days: 3), '3d'),
      ]) {
        expect(ChatLastAction.ago(now.subtract(ago), now), text);
      }
    });
  });

  group('templates', () {
    test('fills what it has and lists what is missing', () {
      final travel = ChatTemplate.values(
        now: _now,
        name: 'Bravo',
        bars: _bars(state: 'Traveling', destination: 'Japan', arrival: _now + 400),
      );
      final out = ChatTemplate.fill('Hi {name}, landing in {landing} at {destination}, WTS {item}', travel);
      expect(out.text, 'Hi Bravo, landing in 6m 40s at Japan, WTS {item}');
      expect(out.missing, ['item']);

      final bare = ChatTemplate.values(now: _now, me: 'Alpha');
      expect(bare.keys.toSet(), {'me', 'time'});
      final empty = ChatTemplate.fill('{me} {energy} {energy} {hospital}', bare);
      expect(empty.text, 'Alpha {energy} {energy} {hospital}');
      expect(empty.missing, ['energy', 'hospital']);

      final unknown = ChatTemplate.fill('{foo} {name}', {'name': 'Bravo'});
      expect(unknown.text, '{foo} Bravo');
      expect(unknown.missing, isEmpty);
      expect(ChatTemplate.used('{foo} {name} {name}'), ['name', 'name']);
      expect(ChatTemplate.needsBars('hi {name}'), isFalse);
      expect(ChatTemplate.needsBars('{energy}'), isTrue);
    });

    test('jail, life, faction and links fill from the profile and status', () {
      final bars = _bars(state: 'Jail', until: _now + 125)..faction = Faction(factionName: 'Fish Hooks');
      final values = ChatTemplate.values(
        now: _now,
        bars: bars,
        bazaar: 'https://www.torn.com/bazaar.php?userId=7',
        trade: 'https://www.torn.com/trade.php#step=start&userID=7',
        profile: 'https://www.torn.com/profiles.php?XID=7',
      );
      final out = ChatTemplate.fill('{jail} {life} {faction} {bazaar} {trade} {profile}', values);
      expect(
        out.text,
        '2m 5s 900/1200 Fish Hooks https://www.torn.com/bazaar.php?userId=7 '
        'https://www.torn.com/trade.php#step=start&userID=7 https://www.torn.com/profiles.php?XID=7',
      );
      expect(out.missing, isEmpty);
      expect(ChatTemplate.needsBars('{jail}'), isTrue);
      expect(ChatTemplate.needsBars('{life}'), isTrue);
    });

    test('jail, life, faction and links stay empty when they do not apply', () {
      final free = ChatTemplate.values(now: _now, bars: _bars(), faction: ' ');
      expect(free.keys, isNot(contains('jail')));
      expect(free.keys, isNot(contains('faction')));
      expect(free.keys, contains('life'));
      final stale = ChatTemplate.values(now: _now, bars: _bars(state: 'Jail', until: _now + 60, age: 3600));
      expect(stale.keys, isNot(contains('life')));
      expect(ChatTemplate.toAsk('{jail} {life} {bazaar} {trade} {profile} {faction}', stale), [
        'life',
        'bazaar',
        'trade',
        'profile',
        'faction',
      ]);
    });

    test('my links use my id', () async {
      Get.put(UserController()..playerId = 42);
      addTearDown(() => Get.delete<UserController>(force: true));
      final values = await chatSlotValues();
      expect(values['bazaar'], 'https://www.torn.com/bazaar.php?userId=42');
      expect(values['trade'], 'https://www.torn.com/trade.php#step=start&userID=42');
      expect(values['profile'], 'https://www.torn.com/profiles.php?XID=42');
    });

    test('values come from fresh bars, chain, item and time', () {
      final values = ChatTemplate.values(
        now: 1760000000,
        bars: _bars(state: 'Hospital', until: 1760000480, at: 1760000000),
        chainCurrent: 25,
        chainSeconds: 95,
      );
      expect(values['energy'], '95/150');
      expect(values['nerve'], '40/55');
      expect(values['hospital'], '8m');
      expect(values['chain'], '25 hits, 1m 35s');
      expect(values['time'], '08:53 TCT');

      final stale = ChatTemplate.values(now: _now, bars: _bars(age: 3600));
      expect(stale.keys, isNot(contains('energy')));
      expect(stale.keys, isNot(contains('nerve')));

      final priced = ChatTemplate.values(now: _now, item: const ChatItemPrice('1', 'Xanax', 850000));
      expect(ChatTemplate.fill('WTS {item} {price}', priced).text, r'WTS Xanax $850,000');
      final unpriced = ChatTemplate.values(now: _now, item: const ChatItemPrice('2', 'Box', null));
      final out = ChatTemplate.fill('WTS {item} {price}', unpriced);
      expect(out.text, 'WTS Box {price}');
      expect(out.missing, ['price']);
    });
  });

  group('slot sheet', () {
    test('asks only what has no value', () {
      final bare = ChatTemplate.values(now: _now, me: 'Alpha');
      expect(ChatTemplate.toAsk('{me} at {time}', bare), isEmpty);
      expect(ChatTemplate.toAsk('{price} for {item}, ask {name} {energy} {foo}', bare), [
        'name',
        'item',
        'price',
        'energy',
      ]);
      final priced = ChatTemplate.values(now: _now, item: const ChatItemPrice('1', 'Xanax', 850000));
      expect(ChatTemplate.toAsk('WTS {item} for {price}', priced), isEmpty);
      final unpriced = ChatTemplate.values(now: _now, item: const ChatItemPrice('2', 'Box', null));
      expect(ChatTemplate.toAsk('WTS {item} for {price}', unpriced), ['item', 'price']);
      expect(ChatTemplate.toAsk('Yours for {price}', unpriced), ['price']);
    });

    testWidgets('inserts what was typed', (tester) async {
      final fetchItems = ChatLinkPreviews.fetchItems;
      addTearDown(() {
        ChatLinkPreviews.fetchItems = fetchItems;
        ChatLinkPreviews.resetForTests();
      });
      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchItems = () async => ItemsModel(items: {'206': Item(name: 'Xanax', marketValue: 830000)});
      String? inserted;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => inserted = await showChatSlotSheet(
                context,
                'WTS {item} for {price}, {name}',
                const {'me': 'Alpha'},
                const ['name', 'item', 'price'],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      Future<void> fill(String name, String item, {String? pick, String? price}) async {
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).at(0), name);
        await tester.enterText(find.byType(TextField).at(1), item);
        await tester.pumpAndSettle();
        if (pick != null) await tester.tap(find.text(pick));
        if (price != null) await tester.enterText(find.byType(TextField).at(2), price);
        await tester.pump();
        await tester.tap(find.text('Insert'));
        await tester.pumpAndSettle();
      }

      await fill('Bravo', 'xan', pick: 'Xanax (alias: xan)');
      expect(inserted, r'WTS Xanax for $830,000, Bravo');
      await fill('Charlie', 'Old box', price: '1500000 ok');
      expect(inserted, r'WTS Old box for $1,500,000, Charlie');
    });
  });

  group('send check', () {
    const key = 'AbCd1234EfGh5678';

    test('keyRisk own vs similar', () {
      expect(ChatSendCheck.keyRisk('here $key ok', ownKey: key), ChatKeyRisk.own);
      expect(ChatSendCheck.keyRisk('x${key}x', ownKey: key), ChatKeyRisk.own);
      expect(ChatSendCheck.keyRisk('try $key now'), ChatKeyRisk.similar);
      expect(ChatSendCheck.keyRisk('try $key now', ownKey: 'zzzzzzzzzzzzzzzz'), ChatKeyRisk.similar);
    });

    test('ids, links, plain words and short keys never warn', () {
      for (final text in [
        '1234567890123456',
        'https://www.torn.com/profiles.php?XID=123',
        'abcdefghijklmnop',
        'ABCDEFGHIJKLMNOP is long',
        'abcd1234efgh56789',
        'abcd1234efgh567',
        'hello world',
      ]) {
        expect(ChatSendCheck.keyRisk(text, ownKey: key), ChatKeyRisk.none, reason: text);
      }
      expect(ChatSendCheck.keyRisk('abc', ownKey: ''), ChatKeyRisk.none);
      expect(ChatSendCheck.keyRisk('abc', ownKey: 'abc'), ChatKeyRisk.none);
    });
  });

  group('status', () {
    test('durations are short', () {
      expect(ChatStatus.duration(45), '45s');
      expect(ChatStatus.duration(220), '3m 40s');
      expect(ChatStatus.duration(480), '8m');
      expect(ChatStatus.duration(7500), '2h 5m');
      expect(ChatStatus.duration(90000), '1d 1h');
    });

    test('bars and running chain', () {
      final text = _status(_bars());
      expect(text.keys, ['energy', 'nerve', 'happy', 'life']);
      expect(text['energy'], 'E 95/150');
      expect(text['nerve'], 'N 40/55');
      expect(_status(_bars(), chainCurrent: 45, chainSeconds: 130)['chain'], 'Chain 45 (2m 10s left)');
    });

    test('travel, hospital and jail say where and for how long', () {
      final flying = _status(_bars(state: 'Traveling', destination: 'Mexico', arrival: _now + 480));
      expect(flying['travel'], 'landing in Mexico in 8m');
      expect(flying.keys, isNot(contains('hospital')));
      expect(_status(_bars(state: 'Abroad', destination: 'Mexico'))['travel'], 'In Mexico');
      expect(_status(_bars(state: 'Hospital', until: _now + 220))['hospital'], 'Hosp 3m 40s');
      expect(_status(_bars(state: 'Jail', until: _now + 3600))['jail'], 'Jail 1h');
      expect(_status(_bars(state: 'Hospital', until: _now - 5)).keys, isNot(contains('hospital')));
    });

    test('cooldown aging and stale bars', () {
      final text = _status(_bars(age: 60, cooldowns: Cooldowns(drug: 600, medical: 30, booster: 7200)));
      expect(text['drug'], 'Drug cd 9m');
      expect(text['booster'], 'Booster cd 1h 59m');
      expect(text.keys, isNot(contains('medical')));
      expect(_status(_bars(age: 900, state: 'Hospital', until: _now + 120)).keys, ['hospital']);
    });

    test('compose joins the checked pieces in order', () {
      final pieces = ChatStatus.pieces(
        bars: _bars(state: 'Traveling', destination: 'Mexico', arrival: _now + 480),
        now: _now,
      );
      final text = ChatStatus.compose(pieces, {'travel', 'energy', 'nerve'});
      expect(text, allOf(contains('95/150'), contains('40/55'), contains('Mexico')));
      expect(text.indexOf('95/150'), lessThan(text.indexOf('Mexico')));
      expect(ChatStatus.compose(pieces, {}), '');
    });
  });

  test('emoji uses are counted, stored and capped to the top', () {
    expect(ChatEmoji.found('hi 👍👍 and 🔥 ok'), unorderedEquals(['👍', '👍', '🔥']));
    expect(ChatEmoji.found('plain text'), isEmpty);
    final counts = {'👍': 3, '🔥': 1};
    expect(ChatEmoji.decodeCounts(ChatEmoji.encodeCounts(counts)), counts);
    expect(ChatEmoji.decodeCounts(['bad', '👍|x', '👍|0']), isEmpty);
    var all = <String, int>{for (final (i, e) in ChatEmoji.all.indexed) e: i + 1};
    all = ChatEmoji.addUses(all, ['😀']);
    expect(all.length, lessThanOrEqualTo(ChatEmoji.maxTracked));
    expect(all, contains(ChatEmoji.all.last));
  });

  test('the emoji row shows favorites, or the most used without any', () {
    const counts = {'👍': 9, '😂': 5, '🔥': 7, '💰': 1};
    expect(ChatEmoji.row(['💰'], counts), ['💰']);
    expect(ChatEmoji.row([], counts), ['👍', '🔥', '😂', '💰']);
    expect(ChatEmoji.row([], {}), isEmpty);
  });

  test('quick action order and emoji favorites', () {
    final prefs = ChatPrefs()..quickOrder = ['price', 'player', 'tab', 'script'];
    prefs.moveQuickAction(0, 3);
    expect(prefs.quickOrder, ['player', 'tab', 'script', 'price']);
    prefs.setQuickActionShown('wiki', false);
    expect(prefs.quickHidden, {'wiki'});
    prefs.setQuickActionShown('wiki', true);
    expect(prefs.quickHidden, isEmpty);

    prefs.emojiFavorites = ['👍'];
    prefs.toggleEmojiFavorite('😀');
    expect(prefs.emojiFavorites, ['👍', '😀']);
    prefs.toggleEmojiFavorite('👍');
    expect(prefs.emojiFavorites, ['😀']);
    prefs.emojiFavorites = List.filled(ChatEmoji.maxFavorites, '🔥');
    prefs.toggleEmojiFavorite('😀');
    expect(prefs.emojiFavorites, isNot(contains('😀')));
  });

  test('room shortcuts are the top three opened this week', () {
    int ms(Duration ago) => chatNow.subtract(ago).millisecondsSinceEpoch;
    expect(
      ChatShortcuts.top([
        'old|${ms(const Duration(days: 8))}',
        'old|${ms(const Duration(days: 9))}',
        'old|${ms(const Duration(days: 10))}',
        'faction|${ms(const Duration(days: 2))}',
        'faction|${ms(const Duration(days: 1))}',
        'dm:5|${ms(const Duration(hours: 3))}',
      ], chatNow),
      ['faction', 'dm:5'],
    );
    expect(
      ChatShortcuts.top([
        'a|${ms(const Duration(hours: 5))}',
        'b|${ms(const Duration(hours: 1))}',
        'c|${ms(const Duration(hours: 3))}',
        'd|${ms(const Duration(hours: 9))}',
      ], chatNow),
      ['b', 'c', 'a'],
    );
  });

  test('recording an opening skips quick repeats and prunes the list', () {
    var opens = ChatShortcuts.record([], 'faction', chatNow);
    expect(opens, hasLength(1));
    expect(ChatShortcuts.record(opens, 'faction', chatNow.add(const Duration(minutes: 2))), same(opens));
    opens = ChatShortcuts.record(opens, 'faction', chatNow.add(const Duration(minutes: 6)));
    expect(opens, hasLength(2));

    final old = chatNow.subtract(const Duration(days: 8)).millisecondsSinceEpoch;
    final recent = chatNow.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final next = ChatShortcuts.record(['x|$old', 'broken', 'y|$recent'], 'z', chatNow);
    expect(next.map((e) => e.split('|').first), ['y', 'z']);
    expect(ChatShortcuts.top(ChatShortcuts.record([], 'a|b', chatNow), chatNow), ['a|b']);
  });

  test('a saved message keeps only the excerpt', () {
    final m = ChatMessage(
      id: 'm1',
      roomId: 'faction',
      sender: const ChatUser(id: 1, name: 'Alpha'),
      content: '> Bravo: earlier\n${'word ' * 40}',
      createdAt: DateTime(2026, 10, 12, 9, 30),
    );
    final saved = ChatSaved.of(m, 'Faction');
    expect(saved.excerpt, startsWith('word word'));
    expect(saved.excerpt.length, lessThanOrEqualTo(80));
    final back = ChatSaved.fromJson(saved.toJson())!;
    expect(
      [back.messageId, back.roomId, back.roomName, back.author, back.excerpt, back.createdAt],
      ['m1', 'faction', 'Faction', 'Alpha', saved.excerpt, m.createdAt],
    );
    expect(ChatSaved.fromJson({'id': 'x'}), isNull);
    expect(ChatSaved.fromJson('junk'), isNull);
  });

  test('chatSnippet', () {
    final parts = chatSnippet('${'a' * 50} Raid now, raid later', 'raid');
    expect(parts.first, ('…', false));
    expect(parts.where((p) => p.$2).map((p) => p.$1), ['Raid', 'raid']);
    expect(chatSnippet('no hit here', 'raid'), [('no hit here', false)]);
    expect(chatSnippet('plain', null), [('plain', false)]);
  });

  test('room filter whole words', () {
    expect(ChatRoomFilter.none.isActive, isFalse);
    expect(ChatRoomFilter.none.hides('anything'), isFalse);
    final show = ChatRoomFilter(show: ['xanax', 'big deal']);
    expect(show.hides('Selling XANAX cheap'), isFalse);
    expect(show.hides('a big deal today'), isFalse);
    expect(show.hides('xanaxes for sale'), isTrue);
    expect(show.hides('hello there'), isTrue);
    final both = ChatRoomFilter(show: ['xanax'], hide: ['scam']);
    expect(both.hides('xanax scam'), isTrue);
    expect(both.hides('xanax'), isFalse);
    expect(ChatRoomFilter(hide: ['spam']).hides('some Spam here'), isTrue);
    expect(ChatRoomFilter(hide: ['spam']).hides('spammer'), isFalse);
  });
}
