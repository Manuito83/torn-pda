// ignore: depend_on_referenced_packages
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  final tornFaction = ChatLinkPreviews.fetchFaction;
  ChatLink link(String url) => ChatLink.parse(url)!;

  Widget host(String content) => MaterialApp(
    home: Scaffold(
      body: ChatMessageText(content: content, color: Colors.black),
    ),
  );

  Map<String, dynamic> player({List<dynamic>? bazaar}) => {
    'profile': {
      'id': 42,
      'name': 'Alpha',
      'level': 15,
      'status': {'description': 'Okay', 'state': 'Okay'},
      'last_action': {'status': 'Online'},
    },
    'bazaar': ?bazaar,
  };

  ForumThreadExtended thread({String title = 'Big &amp; small', int posts = 12, String author = 'Bravo'}) =>
      ForumThreadExtended.fromJson({
        'content': '',
        'content_raw': '',
        'poll': null,
        'id': 16000000,
        'title': title,
        'forum_id': 2,
        'posts': posts,
        'rating': 0,
        'views': 1,
        'author': {'id': 1, 'username': author, 'karma': 0},
        'last_poster': null,
        'first_post_time': 1,
        'last_post_time': null,
        'has_poll': false,
        'is_locked': false,
        'is_sticky': false,
      });

  setUp(() {
    ChatLinkPreviews.resetForTests();
    ChatPlayerCards.fetch = (id) async => null;
    ChatLinkPreviews.fetchFaction = (id) async => null;
    ChatLinkPreviews.fetchCompany = (id) async => null;
    ChatLinkPreviews.fetchItems = () async => null;
    ChatLinkPreviews.fetchThread = (id) async => null;
    ChatLinkPreviews.fetchPage = (uri) async => null;
    ChatLinkPreviews.fetchVideo = (id) async => null;
  });

  tearDown(() {
    NativeChat.prefs.linkPreviews = ChatImageAutoLoad.torn;
    NativeChat.prefs.imageAutoLoad = ChatImageAutoLoad.torn;
  });

  group('cards', () {
    test('reads players and bazaars in both API shapes', () {
      final info = ChatLinkInfo.player(ChatLinkKind.player, player())!;
      expect(info.title, 'Alpha [42]');
      expect(info.detail, allOf(contains('15'), contains('Okay')));
      expect(info.presence, ChatPresence.online);
      expect(ChatLinkInfo.player(ChatLinkKind.bazaar, player(bazaar: [{}, {}]))!.detail, '2 items');
      expect(ChatLinkInfo.player(ChatLinkKind.bazaar, player(bazaar: []))!.detail, 'Empty');
      expect(ChatLinkInfo.player(ChatLinkKind.bazaar, player())!.detail, isNull);
      final flat = {
        'player_id': 42,
        'name': 'Alpha',
        'level': 3,
        'status': {'description': 'Okay'},
        'last_action': {'status': 'Offline'},
        'bazaar_is_open': 0,
        'bazaar': [],
      };
      expect(ChatLinkInfo.player(ChatLinkKind.player, flat)!.title, 'Alpha [42]');
      expect(ChatLinkInfo.player(ChatLinkKind.bazaar, flat)!.detail, 'Closed');
      expect(ChatLinkInfo.player(ChatLinkKind.player, {'error': 'x'}), isNull);
      expect(
        ChatLinkInfo.player(ChatLinkKind.player, {
          'profile': {'name': ''},
        }),
        isNull,
      );
    });

    test('finds items by id or name with their market value', () {
      final catalog = ItemsModel.fromJson({
        'items': {
          '206': {'name': 'Xanax', 'market_value': 830000},
          '1': {'name': 'Hammer', 'market_value': 0},
        },
      });
      final byId = ChatLinkInfo.item(link('https://www.torn.com/imarket.php#/p=shop&itemID=206'), catalog)!;
      expect(byId.title, 'Xanax');
      expect(byId.detail, r'Market $830,000');
      final byName = ChatLinkInfo.item(link('https://www.torn.com/imarket.php#/p=shop&itemName=xanax'), catalog);
      expect(byName!.title, 'Xanax');
      expect(ChatLinkInfo.item(link('https://www.torn.com/imarket.php#/p=shop&itemID=999'), catalog), isNull);
    });

    test('forum threads load their title, author and posts', () async {
      final info = ChatLinkInfo.forum(thread())!;
      expect(info.title, 'Big & small');
      expect(info.detail, allOf(contains('Bravo'), contains('12 posts')));
      expect(ChatLinkInfo.forum(thread(posts: 1, author: ''))!.detail, '1 post');
      expect(ChatLinkInfo.forum(thread(title: ' ')), isNull);
      expect(ChatLinkPreviews.keyOf(link('https://www.torn.com/forums.php#/p=forums&f=2')), isNull);
      final asked = <int>[];
      ChatLinkPreviews.fetchThread = (id) async {
        asked.add(id);
        return thread();
      };
      final loaded = await ChatLinkPreviews.load(
        link('https://www.torn.com/forums.php#/p=threads&f=2&t=16000000'),
        () => true,
      );
      expect(loaded?.title, 'Big & small');
      expect(asked, [16000000]);
    });

    test('web pages use the og title and a resolved image', () {
      final base = Uri.parse('https://example.org/a/b');
      final rich = ChatLinkInfo.page(
        '<html><head><title>Plain</title><meta property="og:title" content="Rich title">'
        '<meta property="og:image" content="/img/x.png"></head></html>',
        base,
      )!;
      expect(rich.title, 'Rich title');
      expect(rich.imageUrl, 'https://example.org/img/x.png');
      expect(rich.detail, 'example.org');
      final plain = ChatLinkInfo.page(
        '<head><title> Plain </title><meta property="og:image" content="javascript:x"></head>',
        base,
      )!;
      expect(plain.title, 'Plain');
      expect(plain.imageUrl, isNull);
      expect(ChatLinkInfo.page('<p>hello</p>', base), isNull);
    });
  });

  group('bounty', () {
    Map<String, dynamic> listed(List<int> rewards) => {
      'bounties': [
        for (final reward in rewards)
          {'target_id': 42, 'target_name': 'Alpha', 'reward': reward, 'quantity': 1, 'is_anonymous': false},
      ],
      'bounties_timestamp': 1,
    };

    test('adds up what is listed', () {
      expect(ChatBounty.parse(listed([3000000, 1500000, 500000]))!.text, r'Bounty $5,000,000 (3 listed)');
      expect(ChatBounty.parse(listed([250000]))!.text, r'Bounty $250,000');
      expect(ChatBounty.parse(listed([])), isNull);
      expect(ChatBounty.parse({'error': 'x'}), isNull);
    });

    test('shows on player and attack cards but not on bazaars', () async {
      var asked = 0;
      ChatPlayerCards.fetch = (id) async {
        asked++;
        return {
          ...player(bazaar: []),
          ...listed([4000000, 1000000]),
        };
      };
      final attack = await ChatLinkPreviews.load(
        link('https://www.torn.com/loader.php?sid=attack&user2ID=42'),
        () => true,
      );
      final profile = await ChatLinkPreviews.load(link('https://www.torn.com/profiles.php?XID=42'), () => true);
      final bazaar = await ChatLinkPreviews.load(link('https://www.torn.com/bazaar.php?userId=42'), () => true);
      expect(attack!.extra, [r'Bounty $5,000,000 (2 listed)']);
      expect(profile!.extra, attack.extra);
      expect(bazaar!.extra, isEmpty);
      expect(asked, 1);
    });

    test('a player without bounty still gets a card, asked once', () async {
      var asked = 0;
      ChatPlayerCards.fetch = (id) async {
        asked++;
        return player();
      };
      final first = await ChatLinkPreviews.load(link('https://www.torn.com/profiles.php?XID=42'), () => true);
      expect(first!.title, 'Alpha [42]');
      expect(first.extra, isEmpty);
      expect(await ChatLinkPreviews.bountyOf(42), isNull);
      expect(asked, 1);
    });

    test('profile, bazaar and bounties in one call', () async {
      final api = FakeApiCaller(
        (url) => {
          ...player(),
          ...listed([4000000]),
        },
      );
      Get.put<ApiCallerController>(api);
      addTearDown(Get.reset);
      ChatPlayerCards.resetForTests();
      final card = await ChatLinkPreviews.load(link('https://www.torn.com/profiles.php?XID=42'), () => true);
      expect(card!.extra, [r'Bounty $4,000,000']);
      expect((await ChatLinkPreviews.bountyOf(42))!.total, 4000000);
      expect((await ChatPlayerCards.load(42))!.levelText, 'Lvl 15');
      expect(api.urls.map((u) => u.queryParameters['selections']), ['profile,bazaar,bounties,discord']);
    });
  });

  group('discord selection rejected', () {
    test('the card loads without it and later cards skip it', () async {
      final api = _RejectsDiscord((url) => {'profile': player()['profile']});
      Get.put<ApiCallerController>(api);
      addTearDown(Get.reset);
      ChatPlayerCards.resetForTests();
      final first = await ChatPlayerCards.load(42);
      final second = await ChatPlayerCards.load(43);
      expect(first!.levelText, 'Lvl 15');
      expect(first.discordId, isNull);
      expect(second!.levelText, 'Lvl 15');
      expect(api.asked, ['profile,bazaar,bounties,discord', 'profile,bazaar,bounties', 'profile,bazaar,bounties']);
    });
  });

  group('discord selection fails twice', () {
    test('each load asks at most twice', () async {
      final api = _RejectsDiscord((url) => <String, dynamic>{});
      Get.put<ApiCallerController>(api);
      addTearDown(Get.reset);
      ChatPlayerCards.resetForTests();
      await ChatPlayerCards.load(42);
      final first = api.asked.length;
      await ChatPlayerCards.load(43);
      expect(first, lessThanOrEqualTo(2));
      expect(api.asked.length - first, lessThanOrEqualTo(2));
    });
  });

  group('faction and company', () {
    const now = 2000000;
    final at = DateTime.fromMillisecondsSinceEpoch(now * 1000);

    Map<String, dynamic> faction({Map<String, dynamic>? ranked, int chain = 0}) => {
      'basic': {
        'id': 11,
        'name': 'Natural Selection',
        'tag': 'NS',
        'respect': 2100000,
        'capacity': 100,
        'members': 98,
        'rank': {'level': 11, 'name': 'Platinum', 'division': 3, 'position': 4, 'wins': 12},
      },
      'wars': {'ranked': ranked, 'raids': [], 'territory': []},
      'pacts': [],
      'chain': {'id': 5, 'current': chain, 'max': 100, 'timeout': 90, 'modifier': 1.0, 'cooldown': 0},
    };

    Map<String, dynamic> war({int start = now - 3600, int? end, bool swapped = false}) {
      final ours = {'id': 11, 'name': 'Natural Selection', 'score': 1240, 'chain': 0};
      final theirs = {'id': 12, 'name': 'Umbrella', 'score': 980, 'chain': 0};
      return {
        'war_id': 9,
        'start': start,
        'end': end,
        'target': 5000,
        'winner': null,
        'factions': swapped ? [theirs, ours] : [ours, theirs],
      };
    }

    test('faction without a war', () {
      final info = ChatLinkInfo.faction(faction(), at)!;
      expect(info.title, 'Natural Selection [NS]');
      expect(info.detail, '98/100 members - Respect 2.1m - Platinum');
      expect(info.extra, isEmpty);
    });

    test('faction in a live war puts its own score first', () {
      expect(ChatLinkInfo.faction(faction(ranked: war()), at)!.extra, ['War vs Umbrella: 1,240 - 980']);
      expect(ChatLinkInfo.faction(faction(ranked: war(swapped: true)), at)!.extra, ['War vs Umbrella: 1,240 - 980']);
    });

    test('faction ignores wars that are over or not started', () {
      expect(ChatLinkInfo.faction(faction(ranked: war(end: now - 10)), at)!.extra, isEmpty);
      expect(ChatLinkInfo.faction(faction(ranked: war(start: now + 600)), at)!.extra, isEmpty);
      expect(ChatLinkInfo.faction(faction(ranked: war(end: now + 600)), at)!.extra, hasLength(1));
    });

    test('faction shows the chain only while there is one', () {
      expect(ChatLinkInfo.faction(faction(ranked: war(), chain: 112), at)!.extra, [
        'War vs Umbrella: 1,240 - 980',
        'Chain 112',
      ]);
      expect(ChatLinkInfo.faction(faction(chain: 112), at)!.extra, ['Chain 112']);
    });

    test('faction survives missing pieces', () {
      final bare = ChatLinkInfo.faction({
        'basic': {'name': 'Solo'},
      })!;
      expect(bare.title, 'Solo');
      expect(bare.detail, isNull);
      expect(ChatLinkInfo.faction({'error': 'x'}), isNull);
    });

    test('company', () {
      final info = ChatLinkInfo.company({
        'profile': {
          'id': 12,
          'name': 'Acme Logistics',
          'rating': 10,
          'type': {'id': 23, 'name': 'Logistics'},
          'director': {'id': 123, 'name': 'Bob'},
          'employees': {'hired': 12, 'capacity': 15},
        },
      })!;
      expect(info.title, 'Acme Logistics');
      expect(info.detail, '10* Logistics - 12/15 staff');
      expect(info.extra, ['Director Bob [123]']);
      expect(ChatLinkInfo.company({'profile': {}}), isNull);
    });

    test('faction and company are asked once', () async {
      var factions = 0;
      var companies = 0;
      ChatLinkPreviews.fetchFaction = (id) async {
        factions++;
        return faction();
      };
      ChatLinkPreviews.fetchCompany = (id) async {
        companies++;
        return {
          'profile': {'name': 'Acme'},
        };
      };
      final f = link('https://www.torn.com/factions.php?step=profile&ID=11');
      final c = link('https://www.torn.com/joblist.php#/p=corpinfo&ID=12');
      expect((await ChatLinkPreviews.load(f, () => true))!.title, 'Natural Selection [NS]');
      expect((await ChatLinkPreviews.load(c, () => true))!.title, 'Acme');
      await ChatLinkPreviews.load(f, () => true);
      await ChatLinkPreviews.load(c, () => true);
      expect((factions, companies), (1, 1));
    });

    test('a company link without an id has no key', () {
      expect(ChatLinkPreviews.keyOf(link('https://www.torn.com/joblist.php#/p=corpinfo&userID=13')), isNull);
    });

    test('a faction card is one call', () async {
      final api = FakeApiCaller((url) => faction(chain: 120));
      Get.put<ApiCallerController>(api);
      addTearDown(Get.reset);
      ChatLinkPreviews.fetchFaction = tornFaction;
      final info = await ChatLinkPreviews.load(
        link('https://www.torn.com/factions.php?step=profile&ID=11'),
        () => true,
      );
      expect(info!.title, 'Natural Selection [NS]');
      expect(api.urls.map((u) => '${u.path}?${u.queryParameters['selections']}'), ['/v2/faction/11?basic,wars,chain']);
    });
  });

  group('loading', () {
    test('one API call serves the player and the bazaar card', () async {
      var calls = 0;
      ChatPlayerCards.fetch = (id) async {
        calls++;
        return player(bazaar: [{}]);
      };
      final a = await ChatLinkPreviews.load(link('https://www.torn.com/profiles.php?XID=42'), () => true);
      final b = await ChatLinkPreviews.load(link('https://www.torn.com/bazaar.php?userId=42'), () => true);
      expect(a!.title, 'Alpha [42]');
      expect(b!.detail, '1 item');
      expect(calls, 1);
      expect(ChatLinkPreviews.cached(link('https://www.torn.com/profiles.php?XID=42'))!.$1, isNotNull);
    });

    test('a failed fetch is not asked again right away', () async {
      var pages = 0;
      ChatLinkPreviews.fetchPage = (uri) async {
        pages++;
        throw Exception('down');
      };
      final url = link('https://example.org/x');
      expect(await ChatLinkPreviews.load(url, () => true), isNull);
      expect(await ChatLinkPreviews.load(url, () => true), isNull);
      expect(pages, 1);
      var catalogs = 0;
      ChatLinkPreviews.fetchItems = () async {
        catalogs++;
        throw Exception('down');
      };
      expect(await ChatLinkPreviews.catalogItems(), isNull);
      expect(await ChatLinkPreviews.catalogItems(), isNull);
      expect(catalogs, 1);
    });

    test('cards that went away are not fetched', () async {
      var calls = 0;
      ChatLinkPreviews.fetchPage = (uri) async {
        calls++;
        return '<title>x</title>';
      };
      expect(await ChatLinkPreviews.load(link('https://example.org/gone'), () => false), isNull);
      expect(calls, 0);
      expect(ChatLinkPreviews.cached(link('https://example.org/gone')), isNull);
    });

    test('YouTube asks oEmbed once per video and keeps the thumbnail', () async {
      final asked = <String>[];
      ChatLinkPreviews.fetchVideo = (id) async {
        asked.add(id);
        return {'title': 'A video', 'author_name': 'A channel'};
      };
      final a = await ChatLinkPreviews.load(link('https://youtu.be/dQw4w9WgXcQ'), () => true);
      final b = await ChatLinkPreviews.load(link('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), () => true);
      expect(a?.title, 'A video');
      expect(a?.detail, 'A channel');
      expect(a?.imageUrl, 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
      expect(b?.title, 'A video');
      expect(asked, ['dQw4w9WgXcQ']);

      ChatLinkPreviews.resetForTests();
      ChatLinkPreviews.fetchVideo = (id) async => throw Exception('down');
      final failed = await ChatLinkPreviews.load(link('https://youtu.be/dQw4w9WgXcQ'), () => true);
      expect(failed?.title, 'YouTube video');
      expect(failed?.imageUrl, 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
    });
  });

  group('player card', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1000000 * 1000);
    Map<String, dynamic> profile({String state = 'Okay', int? until}) => {
      'profile': {
        'level': 54,
        'age': 1203,
        'life': {'current': 4500, 'maximum': 5000},
        'status': {'state': state, 'description': 'Traveling to Mexico', 'until': until},
        'faction': {'name': 'Charlie Crew', 'tag': 'CC', 'position': 'Member'},
        'last_action': {'timestamp': 1000000 - 300, 'relative': '5 minutes ago'},
      },
    };

    setUp(ChatPlayerCards.resetForTests);

    test('reads the linked Discord id only when there is one', () {
      expect(
        ChatPlayerCard.fromJson({
          ...profile(),
          'discord': {'discord_id': '1234', 'user_id': 7},
        })!.discordId,
        '1234',
      );
      expect(
        ChatPlayerCard.fromJson({
          ...profile(),
          'discord': {'discord_id': '', 'user_id': 7},
        })!.discordId,
        isNull,
      );
      expect(
        ChatPlayerCard.fromJson({
          ...profile(),
          'discord': {'user_id': 7},
        })!.discordId,
        isNull,
      );
      expect(ChatPlayerCard.fromJson(profile())!.discordId, isNull);
    });

    test('parses the profile into short facts', () {
      final card = ChatPlayerCard.fromJson(profile())!;
      expect(card.levelText, 'Lvl 54');
      expect(card.factionText, allOf(contains('Charlie Crew'), contains('Member')));
      expect(card.lifeText, 'Life 4,500/5,000');
      expect(card.ageText, contains('1,203'));
      expect(card.statusText(now), 'Okay');
      expect(card.lastActionText(now), 'Last action 5m ago');
      expect(
        ChatPlayerCard.fromJson(profile(state: 'Hospital', until: 1000000 + 3900))!.statusText(now),
        'In hospital - out in 1:05:00',
      );
      final travel = ChatPlayerCard.fromJson(profile(state: 'Traveling'))!;
      expect(travel.statusText(now), 'Traveling to Mexico');
      expect(travel.kind, ChatStatusKind.travel);
      expect(ChatPlayerCard.fromJson({'x': 1}), isNull);
    });

    test('counts down hospital, jail and flights from the profile', () {
      String? text(String state, int left) =>
          ChatPlayerCard.fromJson(profile(state: state, until: 1000000 + left))!.statusText(now);
      expect(text('Hospital', 760), 'In hospital - out in 12:40');
      expect(text('Jail', 59), 'In jail - out in 0:59');
      expect(text('Traveling', 3700), 'Traveling to Mexico - lands in 1:01:40');
      expect(text('Hospital', 2 * 86400 + 3 * 3600), 'In hospital - out in 2d 3h');
      expect(text('Hospital', -5), 'Hospital');
      expect(ChatPlayerCard.fromJson(profile(until: 1000000 + 760))!.clock, isNull);
      final card = ChatPlayerCard.fromJson(profile(state: 'Hospital', until: 1000000 + 760))!;
      expect(card.statusText(now.add(const Duration(seconds: 100))), 'In hospital - out in 11:00');
    });

    test('link cards keep the level in front of the countdown', () {
      final json = player();
      (json['profile'] as Map)['status'] = {
        'state': 'Hospital',
        'description': 'In hospital for 13 mins',
        'until': 1000760,
      };
      final info = ChatLinkInfo.player(ChatLinkKind.attack, json)!;
      expect(info.detailAt(now), 'Lvl 15 - In hospital - out in 12:40');
      expect(info.detailAt(now.add(const Duration(minutes: 10))), 'Lvl 15 - In hospital - out in 2:40');
      expect(info.detailAt(now.add(const Duration(minutes: 13))), 'Lvl 15');
      expect(ChatLinkInfo.player(ChatLinkKind.player, player())!.detailAt(now), 'Lvl 15 - Okay');
    });

    test('one call per player within two minutes', () async {
      var calls = 0;
      ChatPlayerCards.fetch = (id) async {
        calls++;
        return profile();
      };
      await Future.wait([ChatPlayerCards.load(1), ChatPlayerCards.load(1)]);
      await ChatPlayerCards.load(1);
      expect(calls, 1);
      await ChatPlayerCards.load(2);
      expect(calls, 2);
      ChatPlayerCards.fetch = (id) async => throw Exception('x');
      expect(await ChatPlayerCards.load(3), isNull);
    });
  });

  group('screens', () {
    testWidgets('a Torn card fills in once it is on screen', (tester) async {
      var calls = 0;
      ChatPlayerCards.fetch = (id) async {
        calls++;
        return player();
      };
      await tester.pumpWidget(host('https://www.torn.com/profiles.php?XID=42'));
      expect(find.text('Player [42]'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(find.text('Alpha [42]'), findsOneWidget);
      expect(calls, 1);
      await tester.pump(const Duration(minutes: 1));
    });

    testWidgets('a busy key waits for a tap or a calmer minute', (tester) async {
      var calls = 0;
      var load = 80;
      ChatLinkPreviews.pdaCalls = () => load;
      ChatPlayerCards.fetch = (id) async {
        calls++;
        return player();
      };
      await tester.pumpWidget(
        host('https://www.torn.com/profiles.php?XID=42 https://www.torn.com/profiles.php?XID=43'),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(calls, 0);
      await tester.tap(find.byTooltip('Show preview').first);
      await tester.pump();
      await tester.pump();
      expect(find.text('Alpha [42]'), findsOneWidget);
      expect(calls, 1);
      load = 20;
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(calls, 2);
      await tester.pump(const Duration(minutes: 1));
    });

    testWidgets('with previews off nothing loads until tapped', (tester) async {
      NativeChat.prefs.linkPreviews = ChatImageAutoLoad.never;
      var calls = 0;
      ChatLinkPreviews.fetchPage = (uri) async {
        calls++;
        return '<title>A page</title>';
      };
      await tester.pumpWidget(host('https://example.org/x'));
      await tester.pump(const Duration(seconds: 2));
      expect(calls, 0);
      await tester.tap(find.byTooltip('Show preview'));
      await tester.pump();
      await tester.pump();
      expect(find.text('A page'), findsOneWidget);
      expect(calls, 1);
      await tester.pump(const Duration(minutes: 1));
    });

    testWidgets('a lookalike link never loads and warns before opening', (tester) async {
      expect(ChatLinkPreviews.keyOf(link('https://t0rn.com/login')), isNull);
      await tester.pumpWidget(host('https://t0rn.com/login'));
      expect(find.byTooltip('Show preview'), findsNothing);
      await tester.tap(find.text('t0rn.com'));
      await tester.pumpAndSettle();
      expect(find.text('Open anyway'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('external images wait for a tap', (tester) async {
      await tester.pumpWidget(host('look https://i.example.org/pics/cat.png'));
      expect(find.byType(ChatImageCard), findsOneWidget);
      expect(find.byType(ChatLinkCard), findsNothing);
      expect(find.text('Show'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final torn = link('https://www.torn.com/images/v2/a.gif');
      expect(ChatImages.autoLoads(torn), isTrue);
      NativeChat.prefs.imageAutoLoad = ChatImageAutoLoad.never;
      expect(ChatImages.autoLoads(torn), isFalse);
    });

    testWidgets('a script from an unknown host carries a warning', (tester) async {
      const warning = 'Scripts can read your account. Only install from people you trust';
      await tester.pumpWidget(host('https://example.org/a/tool.user.js'));
      expect(find.text(warning), findsOneWidget);
      await tester.pumpWidget(host('https://greasyfork.org/en/scripts/12345-torn-tools'));
      expect(find.text(warning), findsNothing);
    });
  });
}

class _RejectsDiscord extends FakeApiCaller {
  _RejectsDiscord(super.answer);

  final List<String> asked = [];

  @override
  Future<dynamic> enqueueApiCall<T>({
    ApiSelection_v1? apiSelection,
    String? prefix = '',
    int limit = 100,
    int? from,
    // ignore: non_constant_identifier_names
    ApiSelection_v2? apiSelection_v2,
    Future<chopper.Response<T>> Function(TornV2 client, String apiKey)? apiCall,
    String? forcedApiKey = '',
  }) async {
    final body = await super.enqueueApiCall<T>(apiSelection_v2: apiSelection_v2, apiCall: apiCall);
    final selections = urls.last.queryParameters['selections']!;
    asked.add(selections);
    return selections.contains('discord') ? ApiError(errorId: 4) : body;
  }
}
