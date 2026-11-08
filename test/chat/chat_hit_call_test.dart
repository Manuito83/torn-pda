import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_faction_now.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_faction_cards.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_hit_picker.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

final _sent = DateTime.utc(2026, 10, 14, 12, 41, 2);

ChatHitTarget _target(int id, String name, ChatHitState state, {DateTime? until}) =>
    ChatHitTarget(id: id, name: name, state: state, until: until);

void main() {
  useTempPathProvider();

  group('hit call', () {
    test('call text round trip', () {
      final call = chatHitCallOf(chatHitCallText('Kilo_2', 30, _sent, id: 2), _sent)!;
      expect((call.name, call.seconds, call.at, call.id), ('Kilo_2', 30, DateTime.utc(2026, 10, 14, 12, 41, 32), 2));
      final old = chatHitCallOf(chatHitCallText('Kilo_2', 30, _sent), _sent)!;
      expect((old.name, old.at, old.id), ('Kilo_2', call.at, null));
      final loader = 'Hitting Kilo_2 in 30s - at 12:41:32 TCT - https://www.torn.com/loader.php?sid=attack&user2ID=2';
      expect(chatHitCallOf(loader, _sent)?.id, 2);
      expect(chatHitCallText('Kilo_2', 30, _sent, id: 2), endsWith('https://www.torn.com/page.php?sid=attack&user2ID=2'));
    });

    test('anything else stays a normal message', () {
      for (final text in [
        'Hitting Kilo in 30s',
        'hitting Kilo in 30s - at 12:41:32 TCT',
        'Hitting Kilo in 30s - at 12:41:32 TCT!',
        'ok Hitting Kilo in 30s - at 12:41:32 TCT',
        'Hitting Kilo in 0s - at 12:41:02 TCT',
        'Hitting Kilo in 700s - at 12:52:42 TCT',
        'Hitting Kilo in 30s - at 25:41:32 TCT',
        'Hitting Kilo in 30s - at 15:41:32 TCT',
        'Hitting Kilo in 30s - at 12:41:32 TCT - https://www.torn.com/loader.php?sid=attack&user2ID=x',
        'Hitting Kilo in 30s - at 12:41:32 TCT - https://example.com/loader.php?sid=attack&user2ID=2',
      ]) {
        expect(chatHitCallOf(text, _sent), isNull);
      }
    });

    test('counts from the server time, sender clock off or across midnight', () {
      final server = _sent.add(const Duration(seconds: 4));
      expect(chatHitCallOf(chatHitCallText('Kilo', 30, _sent), server)!.at, DateTime.utc(2026, 10, 14, 12, 41, 36));

      final late = DateTime.utc(2026, 10, 14, 23, 59, 50);
      expect(chatHitCallOf(chatHitCallText('Kilo', 30, late), late)!.at, DateTime.utc(2026, 10, 15, 0, 0, 20));

      final early = DateTime.utc(2026, 10, 15, 0, 0, 1);
      expect(chatHitCallOf('Hitting Kilo in 1s - at 23:59:59 TCT', early)!.at, DateTime.utc(2026, 10, 15, 0, 0, 2));
    });

    test('countdown runs to now, then done', () {
      final call = ChatHitCall(name: 'Kilo', seconds: 30, at: _sent.add(const Duration(seconds: 30)));
      final start = chatHitCountdown(call, _sent);
      expect((start.seconds, start.fill, start.phase), (30, 1.0, ChatHitPhase.counting));

      final mid = chatHitCountdown(call, _sent.add(const Duration(milliseconds: 20500)));
      expect((mid.seconds, mid.phase), (10, ChatHitPhase.counting));
      expect(mid.fill, closeTo(9.5 / 30, 1e-9));

      expect(chatHitCountdown(call, call.at).phase, ChatHitPhase.now);
      expect(chatHitCountdown(call, call.at.add(const Duration(seconds: 2))).phase, ChatHitPhase.now);
      expect(chatHitCountdown(call, call.at.add(const Duration(seconds: 3))).phase, ChatHitPhase.done);
      expect(chatHitCountdown(call, _sent.subtract(const Duration(seconds: 5))).fill, 1.0);
    });
  });

  group('hit targets', () {
    test('first ready in order, hospital over counts as ready', () {
      final now = _sent;
      final list = [
        _target(1, 'Juliet', ChatHitState.hospital, until: now.add(const Duration(minutes: 2))),
        _target(2, 'Mike', ChatHitState.traveling),
        _target(3, 'Papa', ChatHitState.jail, until: now.subtract(const Duration(seconds: 1))),
        _target(4, 'Kilo', ChatHitState.ok),
      ];
      expect(chatFirstReady(list, now), 2);
      expect(chatFirstReady(list.take(2).toList(), now), 0);
      expect(chatFirstReady(const [], now), 0);
    });

    test('mark moves only when someone ahead gets out', () {
      final now = _sent;
      final soon = now.add(const Duration(minutes: 1));
      final list = [
        _target(1, 'Juliet', ChatHitState.hospital, until: now.add(const Duration(minutes: 5))),
        _target(2, 'Mike', ChatHitState.jail, until: soon),
        _target(3, 'Kilo', ChatHitState.ok),
        _target(4, 'Papa', ChatHitState.hospital, until: now.add(const Duration(seconds: 10))),
      ];
      expect(chatNextReadyChange(list, now), soon);
      expect(chatNextReadyChange(list.sublist(2), now), isNull);
      expect(chatNextReadyChange(list.sublist(0, 2), now), soon);
      expect(chatNextReadyChange([_target(5, 'Oscar', ChatHitState.traveling)], now), isNull);
    });

    test('abroad keeps the country', () {
      final t = ChatHitTarget.fromStatus(id: 1, name: 'November', state: 'Abroad', description: 'In Japan');
      expect((t.state, t.place), (ChatHitState.abroad, 'Japan'));
      expect(ChatHitTarget.fromStatus(id: 2, name: 'Oscar', state: 'Federal').state, ChatHitState.other);
    });

    test('seconds until out round up and stay inside the call limit', () {
      int? left(ChatHitState state, {Duration? after}) =>
          chatSecondsUntilOut(_target(1, 'Kilo', state, until: after == null ? null : _sent.add(after)), _sent);
      expect(left(ChatHitState.hospital, after: const Duration(milliseconds: 44200)), 45);
      expect(left(ChatHitState.jail, after: const Duration(milliseconds: 200)), 1);
      expect(left(ChatHitState.hospital, after: Duration.zero), isNull);
      expect(left(ChatHitState.hospital, after: const Duration(seconds: -3)), isNull);
      expect(left(ChatHitState.hospital, after: const Duration(seconds: chatHitCallMax)), chatHitCallMax);
      expect(left(ChatHitState.hospital, after: const Duration(seconds: chatHitCallMax + 1)), isNull);
      expect(left(ChatHitState.hospital), isNull);
      expect(left(ChatHitState.ok, after: const Duration(seconds: 30)), isNull);
    });
  });

  test('chain pill count', () {
    expect(chatChainCount(const ChatChain(hits: 312, seconds: 41, bonus: 500)), '312/500');
    expect(chatChainCount(const ChatChain(hits: 1234, seconds: 41, bonus: 2500)), '1,234/2,500');
    expect(chatChainCount(const ChatChain(hits: 250, seconds: 4990, cooldown: true, bonus: 500)), '250');
    expect(chatChainCount(const ChatChain(hits: 64, seconds: 41)), '64');
    expect(const ChatChain(hits: 250, seconds: 4990, cooldown: true).shown, isTrue);
    expect(const ChatChain(hits: 64, seconds: 0).shown, isFalse);
  });

  testWidgets('screen reader opens each sheet from its pill', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatFactionPills(
            now: ChatFactionNow(
              chain: const ChatChain(hits: 312, seconds: 41, bonus: 500),
              war: ChatWar(ours: 1234, theirs: 980, enemy: 'Bravo', start: DateTime.now()),
            ),
          ),
        ),
      ),
    );

    tester.semantics.tap(find.semantics.byLabel(RegExp('^Chain 312')));
    await tester.pumpAndSettle();
    expect(find.text('Watcher'), findsOneWidget);

    Navigator.of(tester.element(find.text('Watcher'))).pop();
    await tester.pumpAndSettle();
    tester.semantics.tap(find.semantics.byLabel(RegExp('^Ranked war')));
    await tester.pumpAndSettle();
    expect(find.text('Open War page'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets('join arms the card, disarm leaves attack and cancel', (tester) async {
    final chat = ChatController(FakeChatSource(), ChatPrefs());
    var known = <ChatHitTarget>[];
    final launched = <int>[];
    final ops = ChatFactionOps(chat, ChatPrefs(), launch: (id) async => launched.add(id), known: () => known);
    final now = DateTime.now();
    final live = ChatHitCall(name: 'Kilo', seconds: 40, at: now.add(const Duration(seconds: 40)), id: 2);
    Future<void> show(ChatHitCall call, {bool mine = false}) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatHitCard(
            message: chatMessage('m1', 'faction', text: 'call'),
            call: call,
            color: Colors.black,
            isMine: mine,
            ops: ops,
          ),
        ),
      ),
    );

    await show(live, mine: true);
    expect(find.text('Join'), findsNothing);

    await show(live);
    await tester.tap(find.text('Join'));
    await tester.pump();
    expect(ops.joined.value?.messageId, 'm1');
    expect(find.textContaining('Armed - opens at'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.textContaining('Attacking in'), findsOneWidget);

    await tester.tap(find.text('Disarm'));
    await tester.pump();
    expect(find.textContaining('Armed'), findsNothing);
    expect(launched, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(ops.joined.value, isNull);
    expect(find.text('Join'), findsOneWidget);
    expect(find.textContaining('to go'), findsOneWidget);

    final unlinked = ChatHitCall(name: 'Kilo', seconds: 40, at: live.at);
    await show(unlinked);
    expect(find.text('Join'), findsNothing);
    known = [const ChatHitTarget(id: 5, name: 'kilo')];
    await show(unlinked);
    await tester.tap(find.text('Join'));
    await tester.pump();
    expect(ops.joined.value?.id, 5);
    ops.dropJoin();

    known = [const ChatHitTarget(id: 2, name: 'Lima')];
    await show(live);
    expect(find.text('Join'), findsNothing);
    known = [];

    final over = ChatHitCall(name: 'Kilo', seconds: 40, at: now.subtract(const Duration(seconds: 10)), id: 2);
    ops.joined.value = ChatHitJoin(
      messageId: 'm1',
      id: 2,
      name: 'Kilo',
      at: over.at,
      opens: over.at,
      state: ChatHitJoinState.missed,
    );
    await show(over);
    expect(find.text('Join'), findsNothing);
    expect(find.text('missed'), findsOneWidget);

    ops.joined.value = ChatHitJoin(messageId: 'm1', id: 2, name: 'Kilo', at: live.at, opens: live.at, own: true);
    await show(live, mine: true);
    await tester.tap(find.text('Disarm'));
    await tester.pump();
    expect(find.text('Cancel'), findsNothing);
    await tester.tap(find.text('Attack'));
    await tester.pump();
    expect(launched, [2]);

    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });

  testWidgets('the card counts joiners', (tester) async {
    final chat = ChatController(FakeChatSource(), ChatPrefs());
    final ops = ChatFactionOps(chat, ChatPrefs(), launch: (_) async {});
    final sent = DateTime.now().subtract(const Duration(seconds: 5));
    final callMsg = chatMessage(
      'c1',
      'faction',
      sender: 9,
      name: 'Nub',
      text: chatHitCallText('Kilo', 40, sent, id: 2),
      at: sent,
    );
    chat.replaceLocal('faction', (_) => false, [
      callMsg,
      chatMessage('j1', 'faction', sender: 3, name: 'Alpha', text: 'Joining Kilo', at: sent.add(const Duration(seconds: 1))),
      chatMessage('j2', 'faction', sender: 4, name: 'Bravo', text: 'Joining Kilo', at: sent.add(const Duration(seconds: 2))),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatHitCard(
            message: callMsg,
            call: chatHitCallOf(callMsg.content, sent)!,
            color: Colors.black,
            isMine: true,
            ops: ops,
          ),
        ),
      ),
    );
    expect(find.text('2 joined'), findsOneWidget);
    expect(find.text('Join'), findsNothing);

    await tester.tap(find.text('2 joined'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Alpha, Bravo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });

  testWidgets('in cooldown the sheet counts down over the tabs, no watch', (tester) async {
    const chain = ChatChain(hits: 196, seconds: 439, cooldown: true, bonus: 250);
    NativeChat.factionOps.simulated.value = chain;
    addTearDown(() => NativeChat.factionOps.simulated.value = null);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ChatFactionPills(now: ChatFactionNow(chain: chain))),
      ),
    );
    await tester.tap(find.text('196'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('7:19'), findsOneWidget);
    expect(find.textContaining('Bonus 100 reached'), findsOneWidget);
    expect(find.text('Finder'), findsOneWidget);
    expect(find.text('Watcher'), findsOneWidget);
    expect(find.text('Take watch'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('call button needs a target and a live chain', (tester) async {
    final chat = ChatController(FakeChatSource(), ChatPrefs());
    final ops = ChatFactionOps(chat, ChatPrefs());
    Future<void> show(List<ChatHitTarget> targets, {bool canCall = true}) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatHitPicker(
            targets: targets,
            card: (t) => Text('card ${t.id}'),
            ops: ops,
            prefs: ChatPrefs(),
            empty: 'No targets',
            canCall: canCall,
            onAttack: (_) {},
          ),
        ),
      ),
    );
    bool enabled<T extends ButtonStyleButton>() => tester.widget<T>(find.byWidgetPredicate((w) => w is T)).enabled;

    await show([_target(2, 'Kilo', ChatHitState.ok)]);
    expect(enabled<OutlinedButton>(), isTrue);
    await show([_target(2, 'Kilo', ChatHitState.ok)], canCall: false);
    expect(enabled<OutlinedButton>(), isFalse);
    expect(enabled<FilledButton>(), isTrue);
    await show(const []);
    expect(enabled<OutlinedButton>(), isFalse);
    expect(enabled<FilledButton>(), isFalse);

    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });

  testWidgets('call goes to faction armed for the picked target, attack takes any', (tester) async {
    final semantics = tester.ensureSemantics();
    final source = FakeChatSource();
    final chat = ChatController(source, ChatPrefs());
    final ops = ChatFactionOps(chat, ChatPrefs());
    final attacked = <String>[];
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatHitPicker(
            targets: [
              _target(1, 'Juliet', ChatHitState.hospital, until: DateTime.now().add(const Duration(minutes: 2))),
              _target(2, 'Kilo', ChatHitState.ok),
              _target(3, 'Lima', ChatHitState.ok),
            ],
            card: (t) => Text('card ${t.id}'),
            ops: ops,
            prefs: ChatPrefs(),
            empty: 'No targets',
            onAttack: (t) => attacked.add(t.name),
            onCalled: () => closed++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Hitting in 30s'));
    await tester.pump();
    final first = chatHitCallOf(source.sent.single.content, DateTime.now())!;
    expect((source.sent.single.roomId, first.name, first.seconds, first.id), ('faction', 'Kilo', 30, 2));
    expect((closed, ops.joined.value?.own, ops.joined.value?.id), (1, true, 2));

    tester.semantics.tap(find.semantics.byLabel(RegExp('^Juliet')));
    await tester.tap(find.text('10s'));
    await tester.tap(find.text('Link'));
    await tester.pump();
    await tester.tap(find.text('Hitting in 10s'));
    await tester.tap(find.text('Attack Juliet'));
    await tester.pump();
    final second = chatHitCallOf(source.sent.last.content, DateTime.now())!;
    expect((second.name, second.seconds, second.id), ('Juliet', 10, null));
    expect(attacked, ['Juliet']);

    await tester.tap(find.text('...'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('Hitting'));
    expect(source.sent, hasLength(2));

    await tester.pumpWidget(const SizedBox());
    chat.dispose();
    semantics.dispose();
  });
}
