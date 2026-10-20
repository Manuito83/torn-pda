import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_events.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

import 'chat_fakes.dart';

final _now = DateTime.utc(2026, 10, 14, 12);

int _ts(int minutesAgo) => _now.subtract(Duration(minutes: minutesAgo)).millisecondsSinceEpoch ~/ 1000;

FactionNews _news(String id, String text, int ts) => FactionNews(id: id, text: text, timestamp: ts);

ChatChain _chain(int seconds, {int hits = 120}) => ChatChain(hits: hits, seconds: seconds);

void main() {
  useTempPathProvider();

  group('chatFactionEvents', () {
    test('keeps general news, oldest first, without tags', () {
      final lines = chatFactionEvents([
        _news('2', 'Chain bonus <b>reached</b>', _ts(5)),
        _news('1', 'A player joined the faction', _ts(30)),
      ], now: _now);
      expect(lines.map((l) => l.content), ['A player joined the faction', 'Chain bonus reached']);
      expect(lines.every((l) => l.isLocal && l.isSystem && isChatFactionEvent(l)), isTrue);
    });

    test('drops money and armory unless they name the player', () {
      final news = [
        _news('1', 'Alpha deposited \$5,000 into the faction', _ts(9)),
        _news('2', 'Bravo used an item from the armory', _ts(8)),
        _news('3', 'Charlie deposited \$100 into the faction', _ts(7)),
      ];
      expect(chatFactionEvents(news, now: _now), isEmpty);
      expect(chatFactionEvents(news, now: _now, myName: 'Charlie').map((l) => l.id), ['${chatFactionEventPrefix}3']);
    });

    test('news time and id filters', () {
      final lines = chatFactionEvents([
        _news('1', 'No time', 0),
        _news('2', 'From the future', _ts(-60)),
        _news('3', 'Fine', _ts(3)),
        _news('3', 'Fine again', _ts(2)),
      ], now: _now);
      expect(lines.map((l) => l.content), ['Fine']);

      final many = chatFactionEvents([for (var i = 0; i < 80; i++) _news('$i', 'Line $i', _ts(100 - i))], now: _now);
      expect(many.length, chatFactionEventMax);
      expect(many.last.content, 'Line 79');
    });
  });

  group('ChatFactionEvents', () {
    late ChatPrefs prefs;
    late ChatController chat;
    late DateTime clock;
    late int calls;
    late Object? answer;
    late ChatFactionEvents events;

    setUp(() {
      prefs = ChatPrefs()..factionEvents = true;
      chat = ChatController(FakeChatSource(), prefs);
      clock = _now;
      calls = 0;
      answer = FactionNewsResponse(
        news: [_news('1', 'A player joined the faction', _ts(5))],
        metadata: const RequestMetadataWithLinks(links: RequestLinks(next: null, prev: null)),
      );
      events = ChatFactionEvents(
        chat,
        prefs,
        fetch: () async {
          calls++;
          return answer;
        },
        clock: () => clock,
      );
    });

    tearDown(() => chat.dispose());

    Future<void> tick() async {
      events.sync();
      await Future<void>.delayed(Duration.zero);
    }

    int shown() => chat.messagesFor('faction').where(isChatFactionEvent).length;

    test('one call on opening, then one every ten minutes', () async {
      chat.openConversation('faction');
      await tick();
      await tick();
      expect(calls, 1);
      expect(shown(), 1);
      clock = _now.add(const Duration(minutes: 9));
      await tick();
      expect(calls, 1);
      clock = _now.add(const Duration(minutes: 10));
      await tick();
      expect(calls, 2);
    });

    test('events only in faction, off removes them', () async {
      chat.openConversation('global');
      await tick();
      expect(calls, 0);

      chat.openConversation('faction');
      await tick();
      expect(shown(), 1);
      prefs.factionEvents = false;
      clock = _now.add(const Duration(minutes: 10));
      await tick();
      expect(shown(), 0);
      expect(calls, 1);
    });

    test('lines sit by time and never count as unread', () async {
      chat.openConversation('faction');
      chat.replaceLocal('faction', (_) => false, [
        chatMessage('real', 'faction', at: _now.subtract(const Duration(minutes: 20))),
      ]);
      await tick();
      expect(chat.messagesFor('faction').map((m) => m.id), ['real', '${chatFactionEventPrefix}1']);
      expect(chat.unreadFor('faction'), 0);
    });

    test('denied key disables faction events', () async {
      expect(chatFactionEventsDenied(16), isTrue);
      expect(chatFactionEventsDenied(5), isFalse);
      expect(chatFactionEventsDenied(null), isFalse);

      answer = ApiError(errorId: 100);
      chat.openConversation('faction');
      await tick();
      expect(prefs.factionEvents, isTrue);
      expect(prefs.factionEventsDenied, isFalse);

      answer = ApiError(errorId: 16);
      clock = _now.add(const Duration(minutes: 10));
      await tick();
      expect(prefs.factionEvents, isFalse);
      expect(prefs.factionEventsDenied, isTrue);
      expect(shown(), 0);

      prefs.setFactionEvents(true);
      expect(prefs.factionEventsDenied, isFalse);
    });
  });

  group('ChatFactionOps', () {
    late ChatPrefs prefs;
    late ChatController chat;
    late ChatFactionOps ops;
    final now = DateTime(2026, 10, 14, 12);

    setUp(() {
      prefs = ChatPrefs();
      chat = ChatController(FakeChatSource(), prefs);
      ops = ChatFactionOps(chat, prefs)..alarm.threshold = 60;
    });

    tearDown(() => chat.dispose());

    List<ChatMessage> locals() => chat.messagesFor('faction').where((m) => m.isLocal).toList();

    test('clock and span text', () {
      expect(chatClock(const Duration(seconds: 45)), '0:45');
      expect(chatClock(const Duration(seconds: 270)), '4:30');
      expect(chatClock(const Duration(seconds: 3723)), '1:02:03');
      expect(chatSpan(const Duration(minutes: 45)), '45m');
      expect(chatSpan(const Duration(minutes: 312)), '5h 12m');
    });

    test('chain level follows the floating window cut points', () {
      expect(_chain(200).level, ChatChainLevel.ok);
      expect(_chain(120).level, ChatChainLevel.caution);
      expect(_chain(45).level, ChatChainLevel.danger);
      expect(_chain(45, hits: 5).level, ChatChainLevel.ok);
      expect(const ChatChain(hits: 120, seconds: 3000, cooldown: true).level, ChatChainLevel.cooldown);
    });

    test('one chain line per crossing', () {
      ops.apply(chain: _chain(90), now: now);
      expect(locals(), isEmpty);
      ops.apply(chain: _chain(45), now: now);
      ops.apply(chain: _chain(44), now: now.add(const Duration(seconds: 1)));
      expect(locals().map((m) => m.content), [contains('0:45')]);
      expect(locals().single.isSystem, isTrue);
      expect(chat.unreadFor('faction'), 0);
      expect(chat.lastMessageIn('faction'), isNull);

      ops.apply(chain: _chain(300), now: now.add(const Duration(seconds: 2)));
      ops.apply(chain: _chain(59), now: now.add(const Duration(seconds: 3)));
      expect(locals().map((m) => m.content), [contains('0:45'), contains('0:59')]);
    });

    test('chain line suppressed cases', () {
      ops.apply(chain: _chain(30, hits: 9), now: now);
      ops.alarm.threshold = null;
      ops.apply(chain: _chain(30), now: now);
      expect(locals(), isEmpty);
      ops.alarm.threshold = 60;
      prefs.factionChain = false;
      ops.apply(chain: _chain(30), now: now);
      expect(locals(), isEmpty);

      prefs.factionChain = true;
      ops.apply(chain: _chain(45), now: now);
      ops.apply(now: now);
      expect(locals(), hasLength(1));
      ops.apply(chain: const ChatChain(hits: 0, seconds: 0), now: now);
      expect(locals(), isEmpty);
    });

    test('retal line countdown', () {
      final retal = ChatRetal(id: 77, name: 'Delta', expiry: now.add(const Duration(seconds: 275)));
      ops.apply(retals: [retal], now: now);
      final line = locals().single;
      expect(line.content, contains('4:30'));
      expect(line.sender.id, 77);
      expect(line.roomId, 'faction');

      ops.apply(now: now.add(const Duration(seconds: 20)));
      expect(locals().single.content, contains('4:10'));
      expect(locals().single.createdAt, now);

      ops.apply(now: now.add(const Duration(seconds: 276)));
      expect(locals(), isEmpty);

      prefs.factionWar = false;
      ops.apply(
        retals: [ChatRetal(id: 1, name: 'Echo', expiry: now.add(const Duration(minutes: 3)))],
        now: now,
      );
      expect(locals(), isEmpty);
    });

    test('active ranked war only, sides by faction id', () {
      RankedWar war({int end = 0, int start = 0}) => RankedWar(
        factions: {
          '10': WarFaction(name: 'Alpha', score: 900),
          '20': WarFaction(name: 'Bravo', score: 1200),
        },
        war: War(start: start, end: end, target: 3000),
      );
      final started = now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch ~/ 1000;
      final active = ChatFactionOps.warOf(war(start: started), 10, now)!;
      expect((active.ours, active.theirs, active.enemy), (900, 1200, 'Bravo'));
      expect(now.difference(active.start), const Duration(hours: 5));

      final later = now.add(const Duration(hours: 3)).millisecondsSinceEpoch ~/ 1000;
      expect(ChatFactionOps.warOf(war(start: later), 10, now), isNull);
      expect(ChatFactionOps.warOf(war(start: started, end: started + 60), 10, now), isNull);
      expect(ChatFactionOps.warOf(war(start: started), 30, now), isNull);
      expect(ChatFactionOps.warOf(null, 10, now), isNull);
    });
  });
}
