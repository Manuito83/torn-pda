import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_retal.dart';
import 'package:torn_pda/models/chat/chat_short_text.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';

import 'chat_fakes.dart';

final _t0 = DateTime.utc(2026, 10, 14, 13, 40);

DateTime _at(int minutes) => _t0.add(Duration(minutes: minutes));

ChatMessage _say(String id, int sender, String text, int minutes, {ChatMessageState state = ChatMessageState.sent}) =>
    chatMessage(id, 'faction', sender: sender, name: 'P$sender', text: text, at: _at(minutes), state: state);

List<String> _on(ChatWatchState s) => [for (final w in s.watchers) w.user.name];

void main() {
  group('watch lines', () {
    test('the three lines round trip, typed by hand too', () {
      final until = DateTime.utc(2026, 10, 14, 15, 30);
      expect(chatWatchOf(chatWatchText(until), _t0), (kind: ChatWatchKind.watching, at: until));
      expect(chatWatchOf(chatWatchLeaveText, _t0), (kind: ChatWatchKind.done, at: null));
      expect(chatWatchOf(chatReliefText(null), _t0), (kind: ChatWatchKind.relief, at: null));
      expect(chatWatchOf(chatReliefText(until), _t0), (kind: ChatWatchKind.relief, at: until));
      expect(chatWatchOf('[pda] watching THE chain until 15:30 tct', _t0)?.at, until);
    });

    test('until crosses midnight, more than 12 hours does not count', () {
      final late = DateTime.utc(2026, 10, 14, 23, 10);
      expect(chatWatchOf('[PDA] Watching the chain until 01:00 TCT', late)?.at, DateTime.utc(2026, 10, 15, 1));
      expect(chatWatchOf('[PDA] Watching the chain until 13:39 TCT', _t0), isNull);
      expect(chatWatchOf('[PDA] Need a chain watcher from 13:39 TCT', _t0), (kind: ChatWatchKind.relief, at: null));
    });

    test('anything close stays a normal message', () {
      for (final text in [
        'Watching the chain until 15:30 TCT',
        '[PDA] watching the chain till 15:30 TCT',
        '[PDA] Watching the chain until 15:30 TCT!',
        'ok [PDA] Done watching the chain',
        '[PDA] Watching the chain until 25:30 TCT',
        '[PDA] Need a chain watcher now',
      ]) {
        expect(chatWatchOf(text, _t0), isNull, reason: text);
      }
    });
  });

  test('short text drops the link and the mark, other text stays', () {
    final sent = DateTime.utc(2026, 10, 14, 13, 40, 2);
    final until = DateTime.utc(2026, 10, 14, 15, 30);
    String short(String text) => chatShortText(text, sent, clock: (at) => 'at ${at.hour}');
    expect(short(chatHitCallText('Chedburn', 60, sent, id: 1)), 'Hitting Chedburn in 60s');
    expect(
      short('Hitting Chedburn in 60s - at 13:41:02 TCT - https://www.torn.com/loader.php?sid=attack&user2ID=1'),
      'Hitting Chedburn in 60s',
    );
    expect(short(chatJoinText('Chedburn', joining: false)), 'Not joining Chedburn');
    expect(short('Joining Chedburn'), 'Joining Chedburn');
    expect(short(chatWatchText(until)), 'On watch from at 13 to at 15');
    expect(short(chatWatchLeaveText), 'Done watching');
    expect(short(chatReliefText(until)), 'Chain watcher needed from at 15');
    expect(short(chatReliefText(null)), 'Chain watcher needed');
    final retal = ChatRetal(id: 1, name: 'Chedburn', expiry: sent.add(const Duration(minutes: 4)), stats: '1.2B (spy)');
    expect(short(chatRetalCallText(retal)), 'Retal available: Chedburn - 1.2B (spy) - until at 13');
    expect(chatShortText(chatWatchText(until), sent), 'On watch from 13:40 to 15:30 TCT');
    for (final text in ['[b]hi[/b]', 'Joining the raid later', 'Hitting the gym']) {
      expect(short(text), text);
    }
  });

  group('watch state', () {
    test('the last word counts, renewing keeps since until it runs out', () {
      final s = chatWatchStateOf([
        _say('a1', 1, chatWatchText(_at(60)), 0),
        _say('b1', 2, chatWatchText(_at(30)), 1),
        _say('a2', 1, chatWatchLeaveText, 5),
        _say('a3', 1, chatWatchText(_at(120)), 6),
        _say('b2', 2, chatWatchText(_at(90)), 40),
        _say('c1', 3, chatWatchLeaveText, 41),
      ], _at(45));
      expect(_on(s), ['P1', 'P2']);
      expect((s.of(1)!.since, s.of(1)!.until), (_at(6), _at(120)));
      expect(s.of(2)!.since, _at(40));
      expect(s.lapsed, isEmpty);
      expect(s.next, _at(90));
    });

    test('a watch runs out on its own at its time', () {
      final lines = [_say('a1', 1, chatWatchText(_at(60)), 0)];
      expect(_on(chatWatchStateOf(lines, _at(59))), ['P1']);
      final after = chatWatchStateOf(lines, _at(60));
      expect(after.watchers, isEmpty);
      expect(after.lapsed, {1: _at(60)});
    });

    test('relief trims its asker, any later watch answers it, else forgotten', () {
      final asked = [
        _say('a1', 1, chatWatchText(_at(180)), 0),
        _say('a2', 1, chatReliefText(_at(15)), 1),
        _say('b1', 2, chatReliefText(null), 2),
      ];
      final open = chatWatchStateOf(asked, _at(3));
      expect(open.of(1)!.until, _at(15));
      expect([for (final r in open.reliefs) r.user.name], ['P1', 'P2']);

      final taken = chatWatchStateOf([...asked, _say('c1', 3, chatWatchText(_at(120)), 4)], _at(5));
      expect(taken.reliefs, isEmpty);
      expect([for (final t in taken.takeovers) (t.asker.name, t.taker.name)], [('P1', 'P3'), ('P2', 'P3')]);

      expect(chatWatchStateOf(asked, _at(44)).reliefs.map((r) => r.user.name), ['P1']);
      expect(chatWatchStateOf(asked, _at(45)).reliefs, isEmpty);
      final plain = [...asked.take(1), _say('a2', 1, chatReliefText(null), 1)];
      expect(chatWatchStateOf(plain, _at(3)).of(1)!.until, _at(180));
    });

    test('Done drops the relief asked before it, a plea from outside stays', () {
      final lines = [
        _say('a1', 1, chatWatchText(_at(180)), 0),
        _say('a2', 1, chatReliefText(_at(15)), 1),
        _say('a3', 1, chatWatchLeaveText, 2),
        _say('b1', 2, chatReliefText(_at(30)), 3),
      ];
      final s = chatWatchStateOf(lines, _at(4));
      expect(s.watchers, isEmpty);
      expect([for (final r in s.reliefs) r.user.name], ['P2']);
      final taken = chatWatchStateOf([...lines, _say('c1', 3, chatWatchText(_at(120)), 5)], _at(6));
      expect([for (final t in taken.takeovers) t.asker.name], ['P2']);
    });

    test('only sent lines of the window and after the last cooldown count', () {
      final s = chatWatchStateOf([
        _say('old', 1, chatWatchText(_at(60)), -721),
        _say('pending', 2, chatWatchText(_at(60)), 0, state: ChatMessageState.pending),
        _say('failed', 3, chatWatchText(_at(60)), 0, state: ChatMessageState.failed),
        ChatMessage(
          id: 'local',
          roomId: 'faction',
          sender: const ChatUser(id: 4, name: 'P4'),
          content: chatWatchText(_at(60)),
          createdAt: _at(0),
          isSystem: true,
          isLocal: true,
        ),
        _say('before', 5, chatWatchText(_at(60)), 1),
        _say('ok', 6, chatWatchText(_at(60)), 3),
      ], _at(5), since: _at(2));
      expect(_on(s), ['P6']);
    });

    test('cooldown closes every watch', () {
      final lines = [_say('a1', 1, chatWatchText(_at(60)), 0), _say('b1', 2, chatReliefText(null), 1)];
      final s = chatWatchStateOf(lines, _at(5), cooldown: true);
      expect([s.watchers, s.reliefs], [isEmpty, isEmpty]);
      expect(s.seen, isTrue);
      expect(s.closed.map((w) => w.user.name), ['P1']);
    });

    test('all watch lines fold but the last, even a Done', () {
      final lines = [
        _say('old', 1, chatWatchText(_at(60)), -721),
        _say('a1', 1, chatWatchText(_at(60)), 0),
        _say('m1', 2, 'hello', 1),
        _say('a2', 1, chatWatchLeaveText, 2),
      ];
      expect(chatWatchFolded(lines, _at(3)), {'a1'});
      expect(chatWatchFolded(lines.take(3).toList(), _at(3)), isEmpty);
    });
  });

  group('watch notes', () {
    List<ChatWatchLine> kinds(ChatWatchState s, int me, int minutes, {bool atRisk = false}) => [
      for (final n in chatWatchNotes(s, me, _at(minutes), atRisk: atRisk)) n.kind,
    ];

    test('relief for others, a takeover for the asker until they renew', () {
      final asked = [_say('a1', 1, chatWatchText(_at(180)), 0), _say('a2', 1, chatReliefText(_at(15)), 1)];
      expect(kinds(chatWatchStateOf(asked, _at(2)), 2, 2), [ChatWatchLine.relief]);
      expect(kinds(chatWatchStateOf(asked, _at(2)), 1, 2), isEmpty);

      final taken = [...asked, _say('b1', 2, chatWatchText(_at(120)), 3)];
      expect(kinds(chatWatchStateOf(taken, _at(4)), 1, 4), [ChatWatchLine.over]);
      final renewed = [...taken, _say('a3', 1, chatWatchText(_at(60)), 5)];
      expect(kinds(chatWatchStateOf(renewed, _at(6)), 1, 6), isEmpty);
    });

    test('a plea from someone not on watch is not a relief', () {
      final lines = [_say('a1', 1, chatWatchText(_at(180)), 0), _say('a2', 1, chatReliefText(_at(15)), 1)];
      final plea = [...lines, _say('b1', 2, chatReliefText(_at(30)), 3)];
      List<bool> reliefs(List<ChatMessage> l, int minutes) {
        final s = chatWatchStateOf(l, _at(minutes));
        return [for (final r in s.reliefs) s.isRelief(r)];
      }

      expect(reliefs(plea, 4), [true, false]);
      expect(reliefs(lines, 16), [false]);
      final notes = chatWatchNotes(chatWatchStateOf(plea, _at(4)), 3, _at(4), atRisk: false);
      expect(notes.map((n) => n.text), ['P1 needs relief from 13:55 TCT', 'P2 needs a chain watcher from 14:10 TCT']);
    });

    test('ending soon, then ended, nobody while the chain can break', () {
      final lines = [_say('a1', 1, chatWatchText(_at(60)), 0)];
      expect(kinds(chatWatchStateOf(lines, _at(54)), 1, 54), isEmpty);
      expect(kinds(chatWatchStateOf(lines, _at(55)), 1, 55), [ChatWatchLine.soon]);
      expect(kinds(chatWatchStateOf(lines, _at(61)), 1, 61, atRisk: true), [ChatWatchLine.nobody, ChatWatchLine.ended]);
      expect(kinds(chatWatchStateOf(lines, _at(61)), 2, 61), isEmpty);
    });
  });

  group('card of a message', () {
    final watch = chatWatchText(_at(60));

    test('a watch line shows its card only sent and within 12 hours', () {
      final line = _say('1', 1, watch, 0);
      expect(chatSpecialOf(line, factionRoom: true, now: _at(1)).watch, isTrue);
      expect(chatSpecialOf(line, factionRoom: true, now: _at(12 * 60)).watch, isFalse);
      for (final state in [ChatMessageState.pending, ChatMessageState.failed]) {
        final unsent = _say('2', 1, watch, 0, state: state);
        expect(chatSpecialOf(unsent, factionRoom: true, now: _at(1)).watch, isFalse, reason: '$state');
      }
    });

    test('outside a faction room no line is a card', () {
      final hit = _say('1', 1, chatHitCallText('Chedburn', 60, _t0, id: 1), 0);
      expect(chatSpecialOf(hit, factionRoom: true, now: _t0).hit, isNotNull);
      for (final m in [hit, _say('2', 1, watch, 0)]) {
        expect(chatSpecialOf(m, factionRoom: false, now: _at(1)), (hit: null, retal: null, watch: false));
      }
    });
  });
}
