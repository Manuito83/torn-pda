import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_faction_now.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';

import 'chat_fakes.dart';

class _Bar extends ChainStatusController {
  bool on = false;

  @override
  bool get watcherActive => on;

  @override
  void activateWatcher({bool fromChat = false}) => on = true;

  @override
  void deactivateWatcher() => on = false;
}

const _me = 99;

void main() {
  useTempPathProvider();

  late FakeChatSource source;
  late ChatPrefs prefs;
  late ChatController chat;
  late ChatFactionOps ops;
  late List<DateTime?> alarms;
  const live = ChatChain(hits: 40, seconds: 200);

  setUp(() {
    source = FakeChatSource();
    prefs = ChatPrefs();
    chat = ChatController(source, prefs);
    alarms = [];
    ops = ChatFactionOps(chat, prefs, watchAlarm: (mine, _, _) async => alarms.add(mine?.until));
    source.emit(const ChatReadyEvent(_me));
  });

  tearDown(() => chat.dispose());

  void tick([ChatChain? chain, DateTime? at]) => ops.apply(chain: chain ?? live, now: at ?? DateTime.now());

  void confirmLast() => source.emit(ChatSendResultEvent('faction', source.sent.last.reqId, ok: true));

  DateTime minute(DateTime at) {
    final t = at.toUtc();
    return DateTime.utc(t.year, t.month, t.day, t.hour, t.minute);
  }

  List<ChatWatchLine?> lines() => [
    for (final m in chat.messagesFor('faction'))
      if (m.isLocal) chatWatchLineOf(m.id),
  ];

  test('take watch sends the time from now, nothing twice, one a minute', () {
    final now = DateTime.now();
    final until = now.add(const Duration(hours: 2));
    tick();
    expect(ops.takeWatch('faction', until, now: now), ChatWatchSend.sent);
    expect(chatWatchOf(source.sent.single.content, now)?.at, minute(until));
    confirmLast();
    tick();
    expect(ops.myWatch('faction')?.until, minute(until));
    expect(alarms, [minute(until)]);

    expect(ops.takeWatch('faction', until, now: now.add(const Duration(minutes: 5))), ChatWatchSend.nothing);
    final later = until.add(const Duration(hours: 1));
    expect(ops.takeWatch('faction', later, now: now.add(const Duration(seconds: 30))), ChatWatchSend.tooSoon);
    expect(ops.takeWatch('faction', later, now: now.add(const Duration(seconds: 61))), ChatWatchSend.sent);
    expect(source.sent, hasLength(2));
  });

  test('leaving or asking for relief goes through right after taking watch', () {
    final now = DateTime.now();
    final until = now.add(const Duration(hours: 1));
    tick();
    expect(ops.takeWatch('faction', until, now: now), ChatWatchSend.sent);
    confirmLast();
    tick();
    final soon = now.add(const Duration(seconds: 5));
    expect(ops.askRelief('faction', const Duration(minutes: 15), now: soon), ChatWatchSend.sent);
    expect(ops.askRelief('faction', const Duration(minutes: 30), now: soon), ChatWatchSend.tooSoon);
    expect(ops.leaveWatch('faction', now: soon), ChatWatchSend.sent);
    expect(source.sent.map((m) => m.content).toList(), [
      chatWatchText(until),
      chatReliefText(soon.add(const Duration(minutes: 15))),
      chatWatchLeaveText,
    ]);
  });

  test('leaving turns the Watcher off only if the watch turned it on', () {
    final bar = Get.put<ChainStatusController>(_Bar()) as _Bar;
    addTearDown(() => Get.delete<ChainStatusController>(force: true));
    var at = DateTime.now();
    ChatWatchSend step(ChatWatchSend Function(DateTime at) action) {
      at = at.add(const Duration(seconds: 61));
      final result = action(at);
      confirmLast();
      tick();
      return result;
    }

    tick();
    expect(step((at) => ops.takeWatch('faction', at.add(const Duration(hours: 1)), now: at)), ChatWatchSend.watcherOn);
    expect(step((at) => ops.leaveWatch('faction', now: at)), ChatWatchSend.watcherOff);
    expect(bar.on, isFalse);

    bar.on = true;
    expect(step((at) => ops.takeWatch('faction', at.add(const Duration(hours: 1)), now: at)), ChatWatchSend.sent);
    expect(step((at) => ops.leaveWatch('faction', now: at)), ChatWatchSend.sent);
    expect(bar.on, isTrue);

    bar.on = false;
    prefs.watchTurnsOnWatcher = false;
    expect(step((at) => ops.takeWatch('faction', at.add(const Duration(hours: 1)), now: at)), ChatWatchSend.sent);
    expect(bar.on, isFalse);
  });

  test('cooldown closes the watch, offers leaving and sends nothing', () {
    tick();
    ops.takeWatch('faction', DateTime.now().add(const Duration(hours: 1)));
    confirmLast();
    tick(const ChatChain(hits: 40, seconds: 0, cooldown: true));
    expect(ops.myWatch('faction'), isNull);
    expect(lines(), [ChatWatchLine.cooldown]);
    expect(source.sent, hasLength(1));

    expect(ops.leaveWatch('faction', now: DateTime.now().add(const Duration(minutes: 2))), ChatWatchSend.sent);
    expect(source.sent.last.content, chatWatchLeaveText);
    confirmLast();
    tick(const ChatChain(hits: 40, seconds: 0, cooldown: true));
    expect(lines(), isEmpty);
  });

  test('a watch counts from the end of the last cooldown, also into the next chain', () {
    const none = ChatChain(hits: 0, seconds: 0);
    tick();
    ops.takeWatch('faction', DateTime.now().add(const Duration(hours: 1)));
    confirmLast();
    tick(const ChatChain(hits: 40, seconds: 0, cooldown: true));
    tick(none);
    expect(ops.myWatch('faction'), isNull);

    final later = DateTime.now().add(const Duration(minutes: 2));
    ops.takeWatch('faction', later.add(const Duration(hours: 2)), now: later);
    confirmLast();
    tick(none);
    expect(ops.myWatch('faction'), isNotNull);
    tick(const ChatChain(hits: 3, seconds: 290));
    expect(ops.myWatch('faction'), isNotNull);
  });

  test('stopping cancels the alarm, coming back sets it again', () {
    tick();
    final until = DateTime.now().add(const Duration(hours: 1));
    ops.takeWatch('faction', until);
    confirmLast();
    tick();
    ops.stop();
    tick();
    expect(alarms, [minute(until), null, minute(until)]);
  });

  test('a simulated cooldown closes only the test room', () {
    addTearDown(() => ops.simulate(null));
    prefs.setTestFactionRoom('dm:9');
    tick();
    final until = DateTime.now().add(const Duration(hours: 1));
    ops.takeWatch('faction', until);
    confirmLast();
    ops.takeWatch('dm:9', until, now: DateTime.now().add(const Duration(minutes: 2)));
    source.emit(ChatSendResultEvent('dm:9', source.sent.last.reqId, ok: true));
    const cooldown = ChatChain(hits: 40, seconds: 0, cooldown: true);
    ops.simulate(cooldown);
    ops.apply(chain: cooldown, realChain: live, now: DateTime.now());
    expect(ops.myWatch('faction'), isNotNull);
    expect(ops.myWatch('dm:9'), isNull);
  });

  test('a Done sent from another client takes me off', () {
    tick();
    ops.takeWatch('faction', DateTime.now().add(const Duration(hours: 1)));
    confirmLast();
    tick();
    expect(ops.myWatch('faction'), isNotNull);
    source.emit(
      ChatMessageEvent(
        chatMessage('web', 'faction', sender: _me, name: 'Me', text: chatWatchLeaveText, at: DateTime.now()),
      ),
    );
    tick();
    expect(ops.myWatch('faction'), isNull);
    expect(alarms.last, isNull);
  });

  test('a folded watch line passes the unread separator to the next shown', () {
    final at = DateTime.now().subtract(const Duration(minutes: 30));
    ChatMessage line(String id, int sender, String text, int minutes) => chatMessage(
      id,
      'faction',
      sender: sender,
      name: 'P$sender',
      text: text,
      at: at.add(Duration(minutes: minutes)),
    );
    source.emit(const ChatUnreadEvent({'faction': 3}));
    chat.openConversation('faction');
    source.emit(
      ChatHistoryEvent('faction', [
        line('w1', 3, chatWatchText(at.add(const Duration(hours: 2))), 0),
        line('w2', 4, chatWatchText(at.add(const Duration(hours: 2))), 1),
        line('m1', 5, 'hi', 2),
      ], hasOlder: false, isOlderPage: false),
    );
    expect(chat.visibleMessagesFor('faction').map((m) => m.id), ['w2', 'm1']);
    expect(chat.firstUnreadId('faction'), 'w2');
    expect(chat.shownIdOf('faction', 'w1'), 'w2');
  });

  test('opening the faction room loads back to the window, at most four pages', () async {
    final now = DateTime.now();
    ChatHistoryEvent page(int hoursAgo, {bool older = true}) => ChatHistoryEvent(
      'faction',
      [chatMessage('h$hoursAgo', 'faction', at: now.subtract(Duration(hours: hoursAgo)))],
      hasOlder: true,
      isOlderPage: older,
    );

    Future<void> arrive(ChatHistoryEvent event) async {
      source.emit(event);
      await pumpEventQueue();
    }

    chat.openConversation('faction');
    await arrive(page(1, older: false));
    expect(chat.watchHistoryShort('faction'), isTrue);
    for (final hours in [2, 3, 4]) {
      await arrive(page(hours));
    }
    expect(source.count('loadOlder'), 4);
    await arrive(page(5));
    expect(source.count('loadOlder'), 4);

    chat.openConversation('faction');
    expect(source.count('loadOlder'), 5);
    await arrive(page(13));
    expect(chat.watchHistoryShort('faction'), isFalse);
    expect(source.count('loadOlder'), 5);
  });

  testWidgets('the pill counts watchers, nothing without watch lines', (tester) async {
    final state = chatWatchStateOf([
      chatMessage('w1', 'faction', sender: _me, text: chatWatchText(chatNow.add(const Duration(hours: 1)))),
    ], chatNow.add(const Duration(minutes: 1)));
    Future<void> pump(Map<String, ChatWatchRoom> watches) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatFactionPills(
            now: ChatFactionNow(chain: live, watches: watches, me: _me),
          ),
        ),
      ),
    );

    await pump({'faction': (state: state, short: true)});
    expect(find.text('~1'), findsOneWidget);
    await pump({'faction': (state: const ChatWatchState(), short: false)});
    expect(find.textContaining(RegExp(r'^~?\d$')), findsNothing);
  });
}
