import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_faction_now.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_retal.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_events.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/retals_controller.dart';

import 'chat_fakes.dart';

class _SlowRetals extends RetalsController {
  int asked = 0;
  var _reply = Completer<String>();

  void answer(String error) => _reply.complete(error);

  @override
  Future<String> retrieveQuietly() {
    asked++;
    _reply = Completer();
    return _reply.future;
  }
}

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

    test('entities read as plain text', () {
      final lines = chatFactionEvents([_news('1', 'Bonnie &amp; Clyde joined the faction', _ts(5))], now: _now);
      expect(lines.single.content, 'Bonnie & Clyde joined the faction');
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

  group('join lines', () {
    final call = chatMessage(
      'c1',
      'faction',
      sender: 9,
      name: 'Nub',
      text: chatHitCallText('Kilo', 60, _now, id: 2),
      at: _now,
    );
    final hit = chatHitCallOf(call.content, call.createdAt)!;
    ChatMessage line(String id, int sender, String name, String text, int secondsIn) =>
        chatMessage(id, 'faction', sender: sender, name: name, text: text, at: _now.add(Duration(seconds: secondsIn)));

    test('one vote per player', () {
      expect(chatJoinOf(chatJoinText('Kilo')), (name: 'Kilo', joining: true));
      expect(chatJoinOf(chatJoinText('Kilo', joining: false)), (name: 'Kilo', joining: false));
      final lines = [
        call,
        line('j1', 3, 'Alpha', 'Joining Kilo', 5),
        line('j2', 4, 'Bravo', 'Joining Kilo', 10),
        line('j3', 3, 'Alpha', 'Joining Kilo', 12),
        line('j4', 5, 'Charlie', 'Joining Kilo', 15),
        line('j5', 5, 'Charlie', 'Not joining Kilo', 20),
        line('j6', 6, 'Delta', 'Not joining Kilo', 21),
        line('j7', 6, 'Delta', 'Joining Kilo', 25),
      ];
      expect(chatJoinersOf(call, hit, lines).map((u) => u.name), ['Alpha', 'Bravo', 'Delta']);
      expect(chatJoinsFolded(lines), {'j1', 'j2', 'j3', 'j4', 'j5', 'j6', 'j7'});
    });

    test('lines outside the call stay plain', () {
      final pending = chatMessage(
        'own',
        'faction',
        sender: 8,
        name: 'You',
        text: 'Joining Kilo',
        at: _now.add(const Duration(seconds: 8)),
        state: ChatMessageState.pending,
      );
      final lines = [
        line('early', 3, 'Alpha', 'Joining Kilo', -1),
        call,
        line('other', 4, 'Bravo', 'Joining Lima', 5),
        line('chat', 5, 'Charlie', 'Joining Kilo now', 6),
        line('ok', 6, 'Delta', 'Joining KILO', 7),
        pending,
        line('late', 7, 'Echo', 'Joining Kilo', 61),
      ];
      expect(chatJoinersOf(call, hit, lines).map((u) => u.name), ['Delta']);
      expect(chatJoinsFolded(lines), {'ok'});
      expect(chatJoinFolds(lines[4], lines), isTrue);
      expect(chatJoinFolds(pending, lines), isFalse);
      expect(chatJoinsFolded(lines.where((m) => m.id != 'c1').toList()), isEmpty);
    });

    test('join target by link or by name', () {
      final known = [const ChatHitTarget(id: 2, name: 'Kilo'), const ChatHitTarget(id: 3, name: 'Lima')];
      ChatHitCall callOn(String name, {int? id}) => ChatHitCall(name: name, seconds: 30, at: _now, id: id);
      expect(chatJoinTargetOf(callOn('Kilo', id: 2), known), 2);
      expect(chatJoinTargetOf(callOn('kilo', id: 2), known), 2);
      expect(chatJoinTargetOf(callOn('Kilo', id: 3), known), isNull);
      expect(chatJoinTargetOf(callOn('Mike', id: 9), known), 9);
      expect(chatJoinTargetOf(callOn('Lima'), known), 3);
      expect(chatJoinTargetOf(callOn('Mike'), known), isNull);
      expect(chatJoinTargetOf(callOn('Mike'), const []), isNull);
    });
  });

  test('spoken chain for the screen reader', () {
    final now = DateTime(2026, 10, 14, 12);
    const me = ChatUser(id: 7, name: 'Me');
    final watcher = ChatWatcher(user: me, since: now, until: now, said: now, messageId: 'w');
    final watches = {'faction': (state: ChatWatchState(seen: true, watchers: [watcher]), short: true)};
    const bonus = ChatChain(hits: 40, seconds: 270, bonus: 50);
    expect(
      chatChainSpoken(
        bonus,
        ChatFactionNow(chain: bonus, live: true, watcher: true, watches: watches, me: 7),
        'faction',
      ),
      'Chain 40 of 50 hits, 4:30 left, live, watcher on, 1 on watch so far, you are on watch',
    );
    expect(
      chatChainSpoken(_chain(45), const ChatFactionNow(panic: true), 'faction'),
      'Chain 120 hits, 0:45 left, panic mode on',
    );
    const cooling = ChatChain(hits: 250, seconds: 600, cooldown: true, bonus: 500);
    expect(
      chatChainSpoken(cooling, const ChatFactionNow(chain: cooling), 'faction'),
      'Chain cooldown, 250 hits, 10:00 left',
    );
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

    test('chain line under the threshold', () {
      ops.apply(chain: _chain(90), now: now);
      expect(locals(), isEmpty);

      ops.apply(chain: _chain(45), now: now);
      final line = locals().single;
      expect(chatChainLineAt(line.id), now.add(const Duration(seconds: 45)));
      expect((line.isSystem, line.createdAt), (true, now));
      expect(chat.unreadFor('faction'), 0);
      expect(chat.lastMessageIn('faction'), isNull);

      ops.apply(chain: _chain(44), now: now.add(const Duration(seconds: 1)));
      ops.apply(chain: _chain(46), now: now.add(const Duration(seconds: 1)));
      expect(locals().single.id, line.id);

      ops.apply(chain: _chain(55), now: now.add(const Duration(seconds: 2)));
      final moved = locals().single;
      expect(chatChainLineAt(moved.id), now.add(const Duration(seconds: 57)));
      expect(moved.createdAt, now);

      ops.apply(chain: _chain(300), now: now.add(const Duration(seconds: 3)));
      expect(locals(), isEmpty);
      ops.apply(chain: _chain(59), now: now.add(const Duration(seconds: 4)));
      expect(locals(), hasLength(1));
      ops.apply(now: now.add(const Duration(seconds: 66)));
      expect(locals(), hasLength(1));
      ops.apply(now: now.add(const Duration(seconds: 70)));
      expect(locals(), isEmpty);
      expect(chatChainLineAt('local-retal-77'), isNull);
    });

    test('join opens five seconds early', () {
      final launched = <int>[];
      final joining = ChatFactionOps(chat, prefs, launch: (id) async => launched.add(id));
      final call = ChatHitCall(name: 'Kilo', seconds: 30, at: now.add(const Duration(seconds: 30)), id: 2);

      joining.join('m1', call, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 24)));
      expect(joining.joined.value!.state, ChatHitJoinState.armed);
      expect(launched, isEmpty);

      joining.apply(now: now.add(const Duration(seconds: 25)));
      expect(joining.joined.value!.state, ChatHitJoinState.launched);
      expect(launched, [2]);
      joining.apply(now: now.add(const Duration(seconds: 26)));
      expect(launched, hasLength(1));

      joining.join('m2', call, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 26)), inFront: false);
      expect((joining.joined.value!.messageId, joining.joined.value!.state), ('m2', ChatHitJoinState.missed));
      expect(launched, hasLength(1));

      joining.join('m3', call, 2, now: now);
      joining.disarm();
      joining.apply(now: now.add(const Duration(seconds: 26)));
      expect(joining.joined.value!.state, ChatHitJoinState.disarmed);
      expect(launched, hasLength(1));
      joining.attackNow();
      expect(joining.joined.value!.state, ChatHitJoinState.launched);
      expect(launched, [2, 2]);

      joining.join('m4', call, 2, now: now);
      joining.cancelJoin();
      joining.apply(now: now.add(const Duration(minutes: 1)));
      expect(joining.joined.value, isNull);
      expect(launched, hasLength(2));

      joining.join('m5', call, 2, now: now);
      joining.stop();
      expect(joining.joined.value, isNull);
    });

    test('a missed call keeps its mark when the next one is joined', () {
      final joining = ChatFactionOps(chat, prefs, launch: (_) async {});
      final call = ChatHitCall(name: 'Kilo', seconds: 30, at: now.add(const Duration(seconds: 30)), id: 2);
      final first = chatMessage('m1', 'faction', text: 'call');
      joining.join('m1', call, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 26)), inFront: false);
      expect(joining.joinFor(first)?.state, ChatHitJoinState.missed);

      joining.join('m2', call, 2, now: now);
      expect(joining.joined.value?.messageId, 'm2');
      expect(joining.joinFor(first)?.state, ChatHitJoinState.missed);
      expect(joining.joinFor(chatMessage('m3', 'faction', text: 'call')), isNull);
    });

    test('a late first tick misses, a short call opens at once', () {
      final launched = <int>[];
      final joining = ChatFactionOps(chat, prefs, launch: (id) async => launched.add(id));
      final call = ChatHitCall(name: 'Kilo', seconds: 30, at: now.add(const Duration(seconds: 30)), id: 2);
      joining.join('m1', call, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 28)));
      expect(joining.joined.value!.state, ChatHitJoinState.launched);
      expect(launched, [2]);

      joining.join('m2', call, 2, now: now);
      joining.apply(now: now.add(const Duration(minutes: 1, seconds: 30)));
      expect(joining.joined.value!.state, ChatHitJoinState.missed);
      expect(launched, hasLength(1));

      final soon = ChatHitCall(name: 'Kilo', seconds: 2, at: now.add(const Duration(seconds: 2)), id: 2);
      joining.join('m3', soon, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 1)));
      expect(launched, [2, 2]);
    });

    test('own call arms on its server time and replaces a join', () async {
      final source = FakeChatSource();
      final room = ChatController(source, prefs);
      final launched = <int>[];
      final calling = ChatFactionOps(room, prefs, launch: (id) async => launched.add(id));
      final start = DateTime.now();
      final other = ChatHitCall(name: 'Lima', seconds: 60, at: start.add(const Duration(seconds: 60)), id: 3);

      calling.join('c1', other, 3, now: start);
      calling.callHit(const ChatHitTarget(id: 2, name: 'Kilo'), 20, room: 'faction', now: start);
      expect(source.sent.map((s) => s.content).skip(1).take(1), ['[PDA] Not joining Lima']);
      final own = calling.joined.value!;
      expect((own.own, own.id, own.messageId), (true, 2, source.sent.last.reqId));
      expect(own.isFor(room.messagesFor('faction').last), isTrue);

      final echo = room.messagesFor('faction').last;
      source.emit(
        ChatMessageEvent(
          ChatMessage(
            id: 'server-1',
            reqId: echo.reqId,
            roomId: 'faction',
            sender: echo.sender,
            content: echo.content,
            createdAt: echo.createdAt.add(const Duration(seconds: 3)),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      calling.apply(now: start.add(const Duration(seconds: 17)));
      expect(launched, isEmpty);
      calling.apply(now: start.add(const Duration(seconds: 19)));
      expect(launched, [2]);

      calling.callHit(const ChatHitTarget(id: 2, name: 'Kilo'), 20, room: 'faction', now: start);
      calling.cancelJoin();
      expect(source.sent, hasLength(4));

      room.dispose();
    });

    test('a disarmed join ends with its call and says nothing after', () {
      final source = FakeChatSource();
      final room = ChatController(source, prefs);
      final joining = ChatFactionOps(room, prefs, launch: (_) async {});
      final call = ChatHitCall(name: 'Kilo', seconds: 30, at: now.add(const Duration(seconds: 30)), id: 2);
      final next = ChatHitCall(name: 'Lima', seconds: 30, at: now.add(const Duration(minutes: 2)), id: 3);

      joining.join('m1', call, 2, now: now);
      joining.disarm();
      joining.apply(now: now.add(const Duration(seconds: 33)));
      expect(joining.joined.value, isNotNull);
      joining.apply(now: now.add(const Duration(seconds: 34)));
      expect(joining.joined.value, isNull);

      joining.join('m2', call, 2, now: now);
      joining.disarm();
      joining.join('m3', next, 3, now: now.add(const Duration(seconds: 40)));
      expect(source.sent.map((s) => s.content), ['[PDA] Joining Kilo', '[PDA] Joining Kilo', '[PDA] Joining Lima']);

      room.dispose();
    });

    test('away from the room the attack is offered first', () {
      final launched = <int>[];
      final offered = <String>[];
      final joining = ChatFactionOps(
        chat,
        prefs,
        launch: (id) async => launched.add(id),
        offer: (join) => offered.add(join.messageId),
      );
      final call = ChatHitCall(name: 'Kilo', seconds: 30, at: now.add(const Duration(seconds: 30)), id: 2);

      joining.join('m1', call, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 25)), factionShown: false);
      expect(joining.joined.value!.state, ChatHitJoinState.offered);
      expect(offered, ['m1']);
      expect(launched, isEmpty);
      joining.apply(now: now.add(const Duration(seconds: 30)), factionShown: false);
      expect(offered, hasLength(1));
      joining.takeOffer();
      expect(joining.joined.value!.state, ChatHitJoinState.launched);
      expect(launched, [2]);
      joining.takeOffer();
      expect(launched, hasLength(1));

      joining.join('m2', call, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 26)), factionShown: false);
      joining.apply(now: now.add(const Duration(seconds: 37)), factionShown: false);
      expect(joining.joined.value!.state, ChatHitJoinState.missed);
      joining.takeOffer();
      expect(launched, hasLength(1));

      joining.join('m3', call, 2, now: now);
      joining.apply(now: now.add(const Duration(seconds: 25)), factionShown: true);
      expect(joining.joined.value!.state, ChatHitJoinState.launched);
      expect(launched, [2, 2]);
    });

    test('join and cancel lines', () {
      final source = FakeChatSource();
      final room = ChatController(source, prefs);
      final joining = ChatFactionOps(room, prefs, launch: (_) async {});
      final sent = DateTime.now().subtract(const Duration(seconds: 10));
      final callMsg = chatMessage(
        'c1',
        'faction',
        sender: 9,
        name: 'Nub',
        text: chatHitCallText('Kilo', 60, sent, id: 2),
        at: sent,
      );
      final hit = chatHitCallOf(callMsg.content, sent)!;
      final other = ChatHitCall(name: 'Lima', seconds: 60, at: sent.add(const Duration(seconds: 60)), id: 3);
      room.replaceLocal('faction', (_) => false, [
        callMsg,
        chatMessage('j1', 'faction', sender: 3, name: 'Alpha', text: 'Joining Kilo', at: sent.add(const Duration(seconds: 2))),
      ]);

      joining.join('c1', hit, 2);
      expect((source.sent.single.roomId, source.sent.single.content), ('faction', '[PDA] Joining Kilo'));
      expect(joining.joinersOf(callMsg, hit).map((u) => u.name), ['Alpha']);
      expect(room.visibleMessagesFor('faction').map((m) => m.id), ['c1', source.sent.single.reqId]);

      source.emit(ChatSendResultEvent('faction', source.sent.single.reqId, ok: true));
      expect(joining.joinersOf(callMsg, hit).map((u) => u.name), ['Alpha', 'You']);
      expect(room.visibleMessagesFor('faction').map((m) => m.id), ['c1']);

      joining.cancelJoin();
      expect(source.sent.last.content, '[PDA] Not joining Kilo');
      source.emit(ChatSendResultEvent('faction', source.sent.last.reqId, ok: true));
      expect(joining.joinersOf(callMsg, hit).map((u) => u.name), ['Alpha']);
      expect(room.visibleMessagesFor('faction').map((m) => m.id), ['c1']);

      joining.join('c1', hit, 2);
      joining.join('c2', other, 3);
      expect(source.sent.skip(2).map((s) => s.content), [
        '[PDA] Joining Kilo',
        '[PDA] Not joining Kilo',
        '[PDA] Joining Lima',
      ]);

      joining.dropJoin();
      joining.cancelJoin();
      expect(source.sent, hasLength(5));

      room.dispose();
    });

    test('folded lines neither anchor the unread separator nor alert', () async {
      final source = FakeChatSource();
      final room = ChatController(source, prefs);
      final incoming = <String>[];
      final sub = room.incomingStream.listen((a) => incoming.add(a.message.id));
      final sent = DateTime.now().subtract(const Duration(seconds: 30));
      source
        ..emit(const ChatReadyEvent(99))
        ..emit(const ChatUnreadEvent({'faction': 2}));
      room.openConversation('faction');
      source.emit(
        ChatHistoryEvent('faction', [
          chatMessage('c1', 'faction', sender: 9, name: 'Nub', text: chatHitCallText('Kilo', 120, sent, id: 2), at: sent),
          chatMessage('j1', 'faction', sender: 3, name: 'Alpha', text: 'Joining Kilo', at: sent.add(const Duration(seconds: 1))),
          chatMessage('m1', 'faction', sender: 4, name: 'Bravo', text: 'go go', at: sent.add(const Duration(seconds: 2))),
        ], hasOlder: false, isOlderPage: false),
      );
      expect(room.firstUnreadId('faction'), 'm1');

      room.closeConversation('faction');
      source
        ..emit(ChatMessageEvent(chatMessage('j2', 'faction', sender: 5, name: 'Charlie', text: 'Joining Kilo', at: sent.add(const Duration(seconds: 3)))))
        ..emit(ChatMessageEvent(chatMessage('m2', 'faction', sender: 4, name: 'Bravo', text: 'Joining Zulu', at: sent.add(const Duration(seconds: 4)))));
      await pumpEventQueue();
      expect(incoming, ['m2']);

      await sub.cancel();
      room.dispose();
    });

    test('a test room follows the faction room rules', () async {
      final source = FakeChatSource();
      final room = ChatController(source, prefs);
      final joining = ChatFactionOps(room, prefs, launch: (_) async {})..alarm.threshold = 60;
      final incoming = <String>[];
      final sub = room.incomingStream.listen((a) => incoming.add(a.message.id));
      final sent = DateTime.now().subtract(const Duration(seconds: 30));
      ChatMessage line(String id, String text, int second) =>
          chatMessage(id, 'dm:9', sender: 9, name: 'Nub', text: text, at: sent.add(Duration(seconds: second)));
      final call = line('c1', chatHitCallText('Kilo', 120, sent, id: 2), 0);
      source
        ..emit(const ChatReadyEvent(99))
        ..emit(const ChatUnreadEvent({'dm:9': 2}));
      room.openConversation('dm:9');
      source.emit(
        ChatHistoryEvent('dm:9', [
          call,
          line('j1', 'Joining Kilo', 1),
          line('m1', 'go go', 2),
        ], hasOlder: false, isOlderPage: false),
      );
      expect(room.firstUnreadId('dm:9'), 'j1');

      prefs.setTestFactionRoom('dm:9');
      expect(room.visibleMessagesFor('dm:9').map((m) => m.id), ['c1', 'm1']);
      expect(room.firstUnreadId('dm:9'), 'm1');

      joining.join('c1', chatHitCallOf(call.content, sent)!, 2, room: 'dm:9');
      joining.cancelJoin();
      expect(source.sent.map((s) => (s.roomId, s.content)), [
        ('dm:9', '[PDA] Joining Kilo'),
        ('dm:9', '[PDA] Not joining Kilo'),
      ]);

      room.closeConversation('dm:9');
      source
        ..emit(ChatMessageEvent(line('j2', 'Joining Kilo', 3)))
        ..emit(ChatMessageEvent(line('m2', 'Joining Zulu', 4)));
      await pumpEventQueue();
      expect(incoming, ['m2']);

      bool chainLine(ChatMessage m) => m.id.startsWith(chatChainLinePrefix);
      joining.apply(chain: _chain(30), now: now);
      expect([room.messagesFor('faction').where(chainLine).length, room.messagesFor('dm:9').where(chainLine).length], [
        1,
        1,
      ]);
      prefs.setTestFactionRoom(null);
      joining.apply(chain: _chain(30), now: now);
      expect(room.messagesFor('dm:9').where(chainLine), isEmpty);
      expect(room.messagesFor('faction').where(chainLine), hasLength(1));

      await sub.cancel();
      room.dispose();
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

    test('retal lines in each faction room, gone when over or returned', () {
      prefs.setTestFactionRoom('dm:9');
      prefs.watchRetals = true;
      final retal = ChatRetal(id: 77, name: 'Delta', expiry: now.add(const Duration(seconds: 275)));
      ops.apply(retals: [retal], now: now);
      final line = locals().single;
      expect(chatRetalLineOf(line.id), (id: 77, expiry: retal.expiry));
      expect(chat.messagesFor('dm:9').where((m) => m.isLocal).single.id, line.id);

      final again = ChatRetal(id: 77, name: 'Delta', expiry: now.add(const Duration(seconds: 290)));
      ops.apply(retals: [again], now: now.add(const Duration(seconds: 15)));
      expect(locals().map((m) => chatRetalLineOf(m.id)!.expiry), [again.expiry]);

      ops.apply(now: now.add(const Duration(seconds: 291)));
      expect(locals(), isEmpty);

      ops.apply(retals: [retal], now: now);
      ops.apply(retals: const [], now: now.add(const Duration(seconds: 30)));
      expect(locals(), isEmpty);

      prefs.watchRetals = false;
      ops.apply(retals: [retal], now: now);
      expect(locals(), isEmpty);
    });

    test('a swiped retal stays away until a new one', () {
      prefs.watchRetals = true;
      final retal = ChatRetal(id: 77, name: 'Delta', expiry: now.add(const Duration(seconds: 275)));
      final other = ChatRetal(id: 78, name: 'Echo', expiry: now.add(const Duration(seconds: 200)));
      ops.apply(retals: [retal, other], now: now);
      ops.dismissRetal(chatRetalLineId(retal), now: now);
      ops.apply(retals: [retal, other], now: now.add(const Duration(seconds: 30)));
      expect(locals().map((m) => chatRetalLineOf(m.id)!.id), [78]);
      expect(ops.retalsLive.value, 1);

      final later = ChatRetal(id: 77, name: 'Delta', expiry: now.add(const Duration(seconds: 400)));
      ops.apply(retals: [later, other], now: now.add(const Duration(seconds: 120)));
      expect(locals().map((m) => chatRetalLineOf(m.id)!.id), unorderedEquals([77, 78]));
    });

    test('the Retals tab asks one call at a time and leaves the room watch on', () async {
      SharedPreferences.setMockInitialValues({});
      final retals = _SlowRetals();
      Get.put<RetalsController>(retals);
      addTearDown(() => Get.delete<RetalsController>(force: true));
      prefs.watchRetals = true;

      ops.retalTab(true);
      ops.retalTab(true);
      await pumpEventQueue();
      expect(retals.asked, 1);
      expect(ops.retalTabFailed.value, isNull);
      retals.answer('incorrect ID-entity relation');
      await pumpEventQueue();
      expect((ops.retalTabFailed.value, ops.retalDenied.value, prefs.watchRetals), (true, false, true));

      ops.retalTab(false);
      ops.retalTab(false);
      ops.retalTab(true);
      await pumpEventQueue();
      expect(retals.asked, 2);
      retals.answer('');
      await pumpEventQueue();
      expect(ops.retalTabFailed.value, isFalse);

      ops.retalTab(true);
      await pumpEventQueue();
      expect((retals.asked, ops.retalTabFailed.value), (2, false));
    });

    test('a new account sees swiped retals again and can take watch at once', () {
      prefs.watchRetals = true;
      final retal = ChatRetal(id: 77, name: 'Delta', expiry: now.add(const Duration(seconds: 275)));
      ops.apply(retals: [retal], now: now);
      ops.dismissRetal(chatRetalLineId(retal), now: now);
      expect(ops.takeWatch('faction', now.add(const Duration(hours: 1)), now: now), ChatWatchSend.sent);

      ops.forget();
      ops.apply(retals: [retal], now: now);
      expect(locals().map((m) => chatRetalLineOf(m.id)!.id), [77]);
      expect(ops.takeWatch('faction', now.add(const Duration(hours: 2)), now: now), ChatWatchSend.sent);
    });

    test('a retal is shared once and reads back with its link', () {
      final source = FakeChatSource();
      final room = ChatController(source, prefs);
      final sharing = ChatFactionOps(room, prefs);
      final at = DateTime.now();
      final retal = ChatRetal(id: 77, name: 'Delta', expiry: at.add(const Duration(minutes: 4)), stats: '~350M (FFS)');
      sharing.apply(retals: [retal], now: at);
      final id = chatRetalLineId(retal);

      expect(sharing.shareRetal('faction', id, now: at), isTrue);
      expect(sharing.shareRetal('faction', id, now: at), isFalse);
      expect(sharing.shareRetal('faction', 'local-retal-5-1', now: at), isFalse);
      final sent = source.sent.single;
      final read = chatRetalCallOf(sent.content, at)!;
      expect((sent.roomId, read.name, read.id, read.stats), ('faction', 'Delta', 77, '~350M (FFS)'));
      expect(read.until.difference(retal.expiry).inSeconds, 0);
      room.dispose();
    });

    test('the chat list with the faction row counts as the room in view', () {
      final source = FakeChatSource();
      final listed = ChatController(source, prefs);
      final inList = ChatFactionOps(listed, prefs);
      source.emit(const ChatRoomsEvent([ChatRoom(id: 'faction', name: 'Faction')]));
      expect(inList.factionInView, isFalse);

      listed.attach();
      expect(inList.factionInView, isTrue);
      listed.openConversation('global');
      expect(inList.factionInView, isFalse);
      listed.closeConversation('global');
      prefs.hiddenRooms.add('faction');
      expect(inList.factionInView, isFalse);

      listed.dispose();
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
      final active = warOf(war(start: started), 10, now)!;
      expect((active.ours, active.theirs, active.enemy), (900, 1200, 'Bravo'));
      expect(now.difference(active.start), const Duration(hours: 5));

      final later = now.add(const Duration(hours: 3)).millisecondsSinceEpoch ~/ 1000;
      expect(warOf(war(start: later), 10, now), isNull);
      expect(warOf(war(start: started, end: started + 60), 10, now), isNull);
      expect(warOf(war(start: started), 30, now), isNull);
      expect(warOf(null, 10, now), isNull);
    });
  });

  test('a retal notice needs a numeric link and an end within minutes', () {
    final sent = DateTime.utc(2026, 10, 14, 23, 58, 30);
    const link = 'https://www.torn.com/page.php?sid=attack&user2ID=';
    final read = chatRetalCallOf('[PDA] Retal available: Delta - until 00:02:10 TCT - ${link}77', sent)!;
    expect((read.name, read.id, read.stats, read.until), ('Delta', 77, null, DateTime.utc(2026, 10, 15, 0, 2, 10)));
    for (final text in [
      'Retal available: Delta - until 00:02:10 TCT - ${link}77&step=x',
      'Retal available: Delta - until 00:02:10 TCT - https://evil.com/page.php?sid=attack&user2ID=77',
      'Retal available: Delta - until 00:02:10 TCT',
      'Retal available: Delta - until 01:30:00 TCT - ${link}77',
    ]) {
      expect(chatRetalCallOf(text, sent), isNull, reason: text);
    }
  });

  test('retal stats follow the Settings order', () {
    final now = DateTime(2026, 10, 14);
    final oldSpy = now.subtract(const Duration(days: 100));
    expect(chatRetalStats(spy: 1200000000, spyAt: oldSpy, ffs: '350M', now: now), '1.2B (spy)');
    expect(chatRetalStats(spy: 1200000000, spyAt: oldSpy, ffs: '350M', ffsOverSpyMonths: 3, now: now), '~350M (FFS)');
    expect(chatRetalStats(spy: 1200000000, spyAt: oldSpy, ffsOverSpyMonths: 3, now: now), '1.2B (spy)');
    expect(chatRetalStats(ffs: '350M', estimated: '2M - 25M', now: now), '~350M (FFS)');
    expect(chatRetalStats(estimated: '2M - 25M', now: now), '2M-25M (est.)');
    expect(chatRetalStats(now: now), isNull);
  });
}
