import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

import 'chat_fakes.dart';

const _code = 'd51ad4fe6be884b309b142e2d1d4f807';

Map<String, dynamic> _action(String action, int at, {Map? attacker, Map? defender, String text = ''}) => {
  'text': text,
  'timestamp': at,
  'action': action,
  'icon': 'x',
  'attacker': attacker,
  'defender': defender,
};

Map<String, dynamic> _attacker(int id, double total, int hits) => {
  'id': id,
  'respect': {'total': total, 'average': total / hits, 'best': total / hits},
  'attacks': {'total': hits},
};

Map<String, dynamic> _chainReport({int id = 20946793, int end = 1700011520, int me = 7}) => {
  'chainreport': {
    'id': id,
    'faction_id': 10,
    'start': 1700000000,
    'end': end,
    'details': {'chain': 250, 'respect': 1842.4, 'best': 48.2},
    'attackers': [for (var i = 0; i < 32; i++) _attacker(i == 3 ? me : 100 + i, 300.0 - i * 5, 30 - i ~/ 2)],
    'non_attackers': [5],
  },
};

void main() {
  useTempPathProvider();

  ChatLink link(String url) => ChatLink.parse(url)!;

  group('report links', () {
    test('attack logs, chain reports and war reports carry their id', () {
      final log = link('https://www.torn.com/loader.php?sid=attackLog&ID=$_code');
      expect(log.kind, ChatLinkKind.attackLog);
      expect(log.logCode, _code);
      expect(link('torn.com/loader.php?sid=attacklog&id=${_code.toUpperCase()}').logCode, _code);
      expect(link('https://www.torn.com/page.php?sid=attackLog&ID=$_code').logCode, _code);

      final chain = link('https://www.torn.com/factions.php?step=chainreport&chainID=20946793');
      expect((chain.kind, chain.id), (ChatLinkKind.chainReport, 20946793));
      expect(link('https://www.torn.com/factions.php?chainid=7&step=ChainReport').id, 7);
      final real = link('https://www.torn.com/war.php?step=chainreport&chainID=71562373');
      expect((real.kind, real.id), (ChatLinkKind.chainReport, 71562373));

      final war = link('https://www.torn.com/war.php?step=rankreport&rankID=25579');
      expect((war.kind, war.id), (ChatLinkKind.warReport, 25579));
    });

    test('other pages on the same scripts stay generic', () {
      expect(link('https://www.torn.com/loader.php?sid=attackLog&ID=abc').kind, ChatLinkKind.torn);
      expect(link('https://www.torn.com/loader.php?sid=crimes').kind, ChatLinkKind.torn);
      expect(link('https://www.torn.com/war.php?step=rankreport').kind, ChatLinkKind.torn);
      expect(link('https://www.torn.com/factions.php?step=your&type=1').kind, ChatLinkKind.torn);
      expect(link('https://www.torn.com/factions.php?step=profile&ID=12').kind, ChatLinkKind.faction);
    });
  });

  group('report cards', () {
    test('an attack log shows the last action by time, with the totals', () {
      final duke = {'id': 4, 'name': 'Duke'};
      final bob = {'id': 5, 'name': 'Bob'};
      final info = ChatLinkInfo.attackLog({
        'attacklog': {
          'log': [
            _action('hosp', 120, attacker: duke, defender: bob),
            _action('hit', 100, attacker: duke, defender: bob),
            _action('missed', 110, attacker: duke, defender: bob),
          ],
          'summary': [
            {'id': 4, 'name': 'Duke', 'hits': 9, 'misses': 2, 'damage': 48210},
            {'id': 5, 'name': 'Bob', 'hits': 0, 'misses': 0, 'damage': 0},
          ],
        },
      })!;
      expect(info.title, 'Duke [4] hospitalized Bob [5]');
      expect(info.detail, '9 hits, 2 missed - 48,210 dmg');
    });

    test('attack log falls back to its text', () {
      final stealth = ChatLinkInfo.attackLog({
        'attacklog': {
          'log': [
            _action('mug', 5, defender: {'id': 5, 'name': 'Bob'}),
          ],
          'summary': const [],
        },
      })!;
      expect(stealth.title, 'Someone mugged Bob [5]');
      expect(stealth.detail, isNull);

      final ended = ChatLinkInfo.attackLog({
        'attacklog': {
          'log': [_action('stalemate', 5, text: 'Duke and Bob stalemated')],
          'summary': const [],
        },
      })!;
      expect(ended.title, 'Duke and Bob stalemated');
      expect(
        ChatLinkInfo.attackLog({
          'attacklog': {'log': [], 'summary': []},
        }),
        isNull,
      );
    });

    test('a chain report shows hits, respect, length and who took part', () {
      final info = ChatLinkInfo.chainReport(_chainReport(), DateTime.fromMillisecondsSinceEpoch(1700100000 * 1000))!;
      expect(info.title, 'Chain 250 - 1,842 respect - 3h 12m');
      expect(info.detail, '32 attackers - best hit 48.2');
      expect(info.settled, isTrue);
      expect(
        ChatLinkInfo.chainReport(_chainReport(), DateTime.fromMillisecondsSinceEpoch(1700011600 * 1000))!.settled,
        isFalse,
      );
      expect(ChatLinkInfo.chainReport({'chainreport': {}}), isNull);
    });

    test('a war report names the winner and the rank change', () {
      Map<String, dynamic> side(int id, String name, int score, String before, String after) => {
        'id': id,
        'name': name,
        'score': score,
        'rank': {'before': before, 'after': after},
      };
      final report = {
        'rankedwarreport': {
          'id': 25579,
          'end': 1700000000,
          'winner': 111,
          'forfeit': false,
          'factions': [
            side(111, 'Natural Selection', 3120, 'Platinum', 'Diamond'),
            side(222, 'Umbrella', 2980, 'Platinum', 'Gold'),
          ],
        },
      };
      final info = ChatLinkInfo.warReport(report)!;
      expect(info.title, 'Natural Selection 3,120 : 2,980 Umbrella');
      expect(info.detail, 'Natural Selection won - Platinum to Diamond');
      expect(info.settled, isTrue);
    });

    test('a finished report is asked once', () async {
      ChatLinkPreviews.resetForTests();
      final original = ChatLinkPreviews.fetchChainReport;
      addTearDown(() => ChatLinkPreviews.fetchChainReport = original);
      var calls = 0;
      ChatLinkPreviews.fetchChainReport = (id) async {
        calls++;
        return _chainReport(id: id);
      };
      final chain = link('https://www.torn.com/factions.php?step=chainreport&chainID=20946793');
      final first = await ChatLinkPreviews.load(chain, () => true);
      final second = await ChatLinkPreviews.load(chain, () => true);
      expect(first?.title, second?.title);
      expect(calls, 1);
      expect(
        ChatLinkPreviews.keyOf(chain),
        isNot(ChatLinkPreviews.keyOf(link('https://www.torn.com/war.php?step=rankreport&rankID=20946793'))),
      );
    });
  });

  group('chain over line', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700011600 * 1000);
    late ChatPrefs prefs;
    late ChatController chat;
    late ChatFactionOps ops;
    late Future<Map<String, dynamic>?> Function() original;
    var fetched = 0;
    Map<String, dynamic> report = _chainReport();

    List<ChatMessage> locals() => chat.messagesFor('faction').where((m) => m.isLocal).toList();

    Future<void> settle(int calls) async {
      while (fetched < calls) {
        await Future.delayed(Duration.zero);
      }
      for (var i = 0; i < 5; i++) {
        await Future.delayed(Duration.zero);
      }
    }

    Future<void> chainEnds() async {
      ops.apply(chain: const ChatChain(hits: 120, seconds: 90), now: now);
      ops.apply(chain: const ChatChain(hits: 0, seconds: 0), now: now);
      await settle(fetched + 1);
    }

    setUp(() {
      ChatLinkPreviews.resetForTests();
      original = ChatLinkPreviews.fetchOwnChainReport;
      fetched = 0;
      report = _chainReport();
      ChatLinkPreviews.fetchOwnChainReport = () async {
        fetched++;
        return report;
      };
      prefs = ChatPrefs();
      chat = ChatController(FakeChatSource(), prefs)..restoreUserId(7);
      ops = ChatFactionOps(chat, prefs, reportDelay: Duration.zero);
    });

    tearDown(() {
      ChatLinkPreviews.fetchOwnChainReport = original;
      chat.dispose();
    });

    test('says how the chain went and where the player stood', () async {
      await chainEnds();
      expect(
        locals().single.content,
        'Chain over: 250 hits, 1,842 respect - You: 29 hits, 285 respect (4th of 32) - only you see this',
      );
    });

    test('one line per chain, even if the same report comes back', () async {
      await chainEnds();
      await chainEnds();
      expect(fetched, 2);
      expect(locals(), hasLength(1));
      expect(prefs.lastChainReport, 20946793);
    });

    test('a report from an older chain is not announced', () async {
      report = _chainReport(end: 1700011600 - 3600);
      await chainEnds();
      expect(locals(), isEmpty);
    });

    test('short chains and a switched off setting ask for nothing', () async {
      ops.apply(chain: const ChatChain(hits: 6, seconds: 90), now: now);
      ops.apply(chain: const ChatChain(hits: 0, seconds: 0), now: now);
      prefs.setFactionChain(false);
      ops.apply(chain: const ChatChain(hits: 120, seconds: 90), now: now);
      ops.apply(chain: const ChatChain(hits: 0, seconds: 0), now: now);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(fetched, 0);
    });

    test('a local clock at zero does not end a chain the API still has', () async {
      ops.apply(chain: const ChatChain(hits: 120, seconds: 90), now: now);
      ops.apply(chain: const ChatChain(hits: 121, seconds: 0), now: now);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(fetched, 0);
      ops.apply(chain: const ChatChain(hits: 121, seconds: 0, cooldown: true), now: now);
      await settle(1);
      ops.apply(chain: const ChatChain(hits: 121, seconds: 0, cooldown: true), now: now);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(fetched, 1);
      expect(locals(), hasLength(1));
    });

    test('a report still running is not announced', () async {
      report = _chainReport(end: 0);
      await chainEnds();
      expect(locals(), isEmpty);
      expect(prefs.lastChainReport, isNot(20946793));
    });

    test('a chain that ends in cooldown counts too', () async {
      ops.apply(chain: const ChatChain(hits: 120, seconds: 90), now: now);
      ops.apply(chain: const ChatChain(hits: 0, seconds: 300, cooldown: true), now: now);
      await settle(1);
      expect(locals(), hasLength(1));
    });
  });

  group('war over line', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700100000 * 1000);
    final war = ChatWar(ours: 3000, theirs: 2900, enemy: 'Umbrella', start: now);
    late ChatPrefs prefs;
    late ChatController chat;
    late ChatFactionOps ops;
    late Future<Map<String, dynamic>?> Function() ownWars;
    late Future<Map<String, dynamic>?> Function(int) warReport;
    var listed = 0;
    var reports = 0;
    int endedAt = 1700100000 - 120;

    List<ChatMessage> locals() => chat.messagesFor('faction').where((m) => m.isLocal).toList();

    Map<String, dynamic> member(int id, double score, int attacks) => {'id': id, 'score': score, 'attacks': attacks};

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future.delayed(Duration.zero);
      }
    }

    Future<void> warEnds() async {
      ops.watchWar(war, 111, now);
      ops.watchWar(null, 111, now);
      await settle();
    }

    setUp(() {
      ChatLinkPreviews.resetForTests();
      ownWars = ChatLinkPreviews.fetchOwnWars;
      warReport = ChatLinkPreviews.fetchWarReport;
      listed = 0;
      reports = 0;
      endedAt = 1700100000 - 120;
      ChatLinkPreviews.fetchOwnWars = () async {
        listed++;
        return {
          'rankedwars': [
            {'id': 25000, 'start': 1, 'end': 1700000000},
            {'id': 25579, 'start': 2, 'end': endedAt},
          ],
        };
      };
      ChatLinkPreviews.fetchWarReport = (id) async {
        reports++;
        return {
          'rankedwarreport': {
            'id': id,
            'winner': 111,
            'factions': [
              {
                'id': 111,
                'score': 3120,
                'members': [member(1, 90, 20), member(2, 60, 14), member(7, 45.4, 12), member(3, 10, 3)],
              },
              {'id': 222, 'score': 2980, 'members': <Map>[]},
            ],
          },
        };
      };
      prefs = ChatPrefs();
      chat = ChatController(FakeChatSource(), prefs)..restoreUserId(7);
      ops = ChatFactionOps(chat, prefs, reportDelay: Duration.zero);
    });

    tearDown(() {
      ChatLinkPreviews.fetchOwnWars = ownWars;
      ChatLinkPreviews.fetchWarReport = warReport;
      chat.dispose();
    });

    test('says who won and how the player did, once per war', () async {
      await warEnds();
      expect(
        locals().single.content,
        'War over: won 3,120 to 2,980 - You: 45 score, 12 hits (3rd) - only you see this',
      );
      await warEnds();
      expect(locals(), hasLength(1));
      expect((listed, reports), (2, 1));
      expect(prefs.lastWarReport, 25579);
    });

    test('nothing happens if the chat never saw a war', () async {
      ops.watchWar(null, 111, now);
      await settle();
      expect(listed, 0);
    });

    test('a war list without a recent end announces nothing', () async {
      endedAt = 1700100000 - 7200;
      await warEnds();
      expect((listed, reports), (1, 0));
      expect(locals(), isEmpty);
    });

    test('the setting turns it off', () async {
      prefs.setFactionWar(false);
      await warEnds();
      expect(listed, 0);
    });
  });
}
