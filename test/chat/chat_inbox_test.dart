import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_list_reply.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

class _Source extends FakeChatSource {
  final recentOffsets = <int>[];

  @override
  Future<void> loadRecentDms({int offset = 0}) async => recentOffsets.add(offset);
}

class _Friends implements ChatApi {
  _Friends(this.list);

  final List<(ChatUser, ChatLastAction)> list;
  int calls = 0;

  @override
  Future<List<(ChatUser, ChatLastAction)>?> friends() async {
    calls++;
    return [...list];
  }

  @override
  Future<ChatLastAction?> lastAction(int userId) async => null;

  @override
  Future<List<(ChatUser, ChatLastAction)>?> roster(String roomId) async => null;
}

Future<void> _show(WidgetTester tester, ChatController chat) => tester.pumpWidget(
  MaterialApp(
    builder: BotToastInit(),
    navigatorObservers: [BotToastNavigatorObserver()],
    home: ChangeNotifierProvider<ChatController>.value(value: chat, child: const ChatPage()),
  ),
);

void _connect(FakeChatSource source, [List<ChatRoom> dms = const []]) => source
  ..emit(const ChatReadyEvent(99))
  ..emit(const ChatConnectionEvent(ChatConnection.connected))
  ..emit(ChatDmsEvent(dms));

ChatRoom _dm(int id, String name, [DateTime? last]) => ChatRoom(
  id: ChatRoom.dmId(id),
  name: name,
  type: ChatRoomType.dm,
  peer: ChatUser(id: id, name: name),
  lastMessage: last == null ? null : chatMessage('l$id', ChatRoom.dmId(id), sender: id, name: name, at: last),
);

bool _above(WidgetTester tester, String first, String second) {
  final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
  return texts.indexOf(first) < texts.indexOf(second);
}

void main() {
  late _Source source;
  late ChatController chat;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..globalsPlacement = ChatGlobalsPlacement.mixed
      ..roomPlacement = {}
      ..pinned = []
      ..muted = {}
      ..hiddenRooms = {}
      ..savedMessages = [];
  });

  tearDown(() => NativeChat.prefs.listReplyCount = 3);

  void start([ChatPrefs? prefs, ChatApi? api]) {
    source = _Source();
    chat = ChatController(source, prefs, api);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  }

  testWidgets('chats are listed by activity and open on tap', (tester) async {
    start();
    await _show(tester, chat);
    final now = DateTime.now();
    _connect(source, [_dm(7, 'Bravo', now.subtract(const Duration(minutes: 1)))]);
    source
      ..emit(
        ChatPeekEvent(
          'global',
          chatMessage('g1', 'global', name: 'Alpha', at: now.subtract(const Duration(minutes: 5))),
        ),
      )
      ..emit(const ChatUnreadEvent({'global': 4, 'faction': 2, 'dm:7': 3}));
    await tester.pump();

    expect(_above(tester, 'Bravo', 'Global'), isTrue);
    expect(find.text('Alpha: text g1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(chat.unreadGroups(), {'faction': 2, 'dm': 3});

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(source.calls, containsAllInOrder(['openRoom dm:7', 'markRead dm:7']));
    expect(chat.unreadGroups().containsKey('dm'), isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(source.count('closeRoom'), 1);
    expect(chat.currentRoomId, isNull);
    await close(tester);
  });

  testWidgets('quick replies read their rooms', (tester) async {
    start();
    await _show(tester, chat);
    _connect(source);
    source.emit(const ChatUnreadEvent({'faction': 2, 'company': 1}));
    await tester.pump();
    Iterable<String> open() => tester.widgetList<ChatListReply>(find.byType(ChatListReply)).map((r) => r.room.id);
    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tap(find.byTooltip('Quick reply').at(0));
    final first = open().single;
    await tap(find.byTooltip('Quick reply').at(0));
    expect(open(), hasLength(2));
    final second = open().firstWhere((id) => id != first);
    expect(
      source.calls,
      containsAllInOrder(['openRoom $first', 'markRead $first', 'openRoom $second', 'markRead $second']),
    );
    expect(chat.unreadGroups(), isEmpty);

    await tap(find.byTooltip('Close quick reply').first);
    expect(open(), hasLength(1));
    expect(source.calls.last, isNot('closeRoom'));

    await tap(find.byTooltip('Close quick reply'));
    expect(open(), isEmpty);
    expect(source.calls.last, 'closeRoom');
    expect((chat.unreadFor(first), chat.unreadFor(second)), (0, 0));
    await close(tester);
  });

  Future<void> history(WidgetTester tester, int count, {String? long, bool hasOlder = false}) async {
    start();
    await _show(tester, chat);
    _connect(source);
    final now = DateTime.now();
    source
      ..emit(
        ChatPeekEvent('company', chatMessage('c1', 'company', name: 'Carol', at: now.add(const Duration(minutes: 1)))),
      )
      ..emit(
        ChatHistoryEvent(
          'faction',
          [
            for (var i = 1; i <= count; i++)
              chatMessage(
                'f$i',
                'faction',
                name: 'Alpha',
                text: i == count - 1 && long != null ? 'line $i $long' : 'line $i',
                at: now.add(Duration(seconds: i)),
              ),
          ],
          hasOlder: hasOlder,
          isOlderPage: false,
        ),
      );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ChatConversationTile, 'Faction'),
        matching: find.byTooltip('Quick reply'),
      ),
    );
    await tester.pumpAndSettle();
  }

  final block = find.descendant(of: find.byType(ChatListReply), matching: find.byType(CustomScrollView));
  final latest = find.byTooltip('Go to the latest messages').hitTestable();

  void arrive(String id, String text) => source.emit(
    ChatMessageEvent(chatMessage(id, 'faction', text: text, at: DateTime.now().add(const Duration(minutes: 2)))),
  );

  bool shown(WidgetTester tester, String text) {
    final box = tester.getRect(block);
    final line = find.descendant(of: find.byType(ChatListReply), matching: find.textContaining(text));
    if (line.evaluate().isEmpty) return false;
    final rect = tester.getRect(line);
    return rect.top >= box.top - 0.5 && rect.bottom <= box.bottom + 0.5;
  }

  testWidgets('quick reply shows the newest messages and scrolls to older ones', (tester) async {
    NativeChat.prefs.listReplyCount = 5;
    await history(tester, 7);

    expect([for (var i = 1; i <= 7; i++) shown(tester, 'line $i')], [false, false, true, true, true, true, true]);

    await tester.drag(block, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(shown(tester, 'line 1'), isTrue);
    expect(shown(tester, 'line 7'), isFalse);
    await close(tester);
  });

  testWidgets('quick reply shows the last message once', (tester) async {
    await history(tester, 4);

    expect(find.textContaining('line 4'), findsOneWidget);
    final row = find.descendant(of: find.byType(ChatConversationTile), matching: find.textContaining('line 4'));
    expect(row, findsNothing);
    expect([for (var i = 1; i <= 4; i++) shown(tester, 'line $i')], [false, true, true, true]);

    await tester.tap(find.byTooltip('Close quick reply'));
    await tester.pumpAndSettle();
    expect(find.textContaining('line 4'), findsOneWidget);
    expect(find.byType(ChatListReply), findsNothing);
    await close(tester);
  });

  testWidgets('quick reply fits a long message among the newest', (tester) async {
    await history(tester, 5, long: List.filled(12, 'words that wrap').join(' '));

    expect([for (var i = 1; i <= 5; i++) shown(tester, 'line $i')], [false, false, true, true, true]);
    await close(tester);
  });

  testWidgets('quick reply stays open when its room moves up', (tester) async {
    await history(tester, 4);
    final state = tester.state(find.byType(ChatListReply));
    await tester.enterText(find.descendant(of: find.byType(ChatListReply), matching: find.byType(TextField)), 'on it');
    expect(_above(tester, 'Company', 'Faction'), isTrue);

    arrive('f5', 'line 5');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(_above(tester, 'Faction', 'Company'), isTrue);
    expect(tester.state(find.byType(ChatListReply)), same(state));
    expect(find.widgetWithText(TextField, 'on it'), findsOneWidget);
    expect([for (var i = 2; i <= 5; i++) shown(tester, 'line $i')], [false, true, true, true]);
    await close(tester);
  });

  testWidgets('quick reply holds still while scrolled up', (tester) async {
    await history(tester, 7);
    expect(latest, findsNothing);

    await tester.drag(block, const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(latest, findsOneWidget);
    final line = find.descendant(of: find.byType(ChatListReply), matching: find.textContaining('line 5'));
    final y = tester.getTopLeft(line).dy - tester.getTopLeft(block).dy;

    arrive('f8', 'line 8');
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(line).dy - tester.getTopLeft(block).dy, y);
    expect(shown(tester, 'line 8'), isFalse);

    await tester.tap(latest);
    await tester.pumpAndSettle();
    expect([for (var i = 5; i <= 8; i++) shown(tester, 'line $i')], [false, true, true, true]);
    expect(latest, findsNothing);
    await close(tester);
  });

  testWidgets('quick reply asks for older history once', (tester) async {
    await history(tester, 3, hasOlder: true);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    arrive('f4', 'line 4');
    await tester.pumpAndSettle();

    expect(source.count('loadOlder'), 1);
    await close(tester);
  });

  testWidgets('quick reply asks again once older history exists', (tester) async {
    await history(tester, 3);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(source.count('loadOlder'), 0);

    final now = DateTime.now();
    source.emit(
      ChatHistoryEvent(
        'faction',
        [
          for (var i = 1; i <= 3; i++)
            chatMessage('f$i', 'faction', name: 'Alpha', text: 'line $i', at: now.add(Duration(seconds: i))),
        ],
        hasOlder: true,
        isOlderPage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(source.count('loadOlder'), 1);
    await close(tester);
  });

  testWidgets('conversation fades only live messages', (tester) async {
    start();
    final past = DateTime.now().subtract(const Duration(hours: 1));
    ChatHistoryEvent page(int last) => ChatHistoryEvent(
      'faction',
      [
        for (var i = 1; i <= last; i++)
          chatMessage('f$i', 'faction', name: 'Alpha', text: 'line $i', at: past.add(Duration(seconds: i))),
      ],
      hasOlder: false,
      isOlderPage: false,
    );
    double opacity(String text) => tester
        .widgetList<Opacity>(find.ancestor(of: find.textContaining(text), matching: find.byType(Opacity)))
        .map((o) => o.opacity)
        .reduce((a, b) => a < b ? a : b);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatController>.value(
          value: chat,
          child: const ChatConversationPage(roomId: 'faction'),
        ),
      ),
    );
    source
      ..emit(const ChatReadyEvent(99))
      ..emit(const ChatConnectionEvent(ChatConnection.connected))
      ..emit(page(3));
    await tester.pumpAndSettle();

    source.emit(page(5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(opacity('line 5'), 1);

    arrive('live', 'line live');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(opacity('line live'), lessThan(1));
    expect(opacity('line 5'), 1);
    await close(tester);
  });

  testWidgets('quick reply sends to its room', (tester) async {
    start();
    await _show(tester, chat);
    _connect(source);
    source.emit(
      ChatHistoryEvent(
        'faction',
        [chatMessage('f1', 'faction', name: 'Alpha', text: 'chain at 45', at: DateTime.now())],
        hasOlder: false,
        isOlderPage: false,
      ),
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ChatConversationTile, 'Faction'),
        matching: find.byTooltip('Quick reply'),
      ),
    );
    await tester.pumpAndSettle();
    final box = find.descendant(of: find.byType(ChatListReply), matching: find.byType(TextField));
    await tester.enterText(box, 'on it');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(source.sent.map((s) => (s.roomId, s.content)), [('faction', 'on it')]);
    expect(tester.widget<TextField>(box).controller!.text, isEmpty);
    await close(tester);
  });

  testWidgets('pinned first, hidden out, moved rooms in the Social tab', (tester) async {
    NativeChat.prefs
      ..globalsPlacement = ChatGlobalsPlacement.tab
      ..pinned = ['company']
      ..hiddenRooms = {'trade'};
    start();
    await _show(tester, chat);
    _connect(source);
    source.emit(const ChatUnreadEvent({'global': 120, 'trade': 5, 'faction': 2}));
    await tester.pump();

    final socialBadge = find.descendant(of: find.widgetWithText(Tab, 'Social'), matching: find.text('2'));
    expect(_above(tester, 'Company', 'Faction'), isTrue);
    expect(find.text('Global'), findsNothing);
    expect(find.text('99+'), findsNothing);
    expect(socialBadge, findsNothing);

    NativeChat.prefs.setRoomPlacement('faction', ChatGlobalsPlacement.tab);
    await tester.pumpAndSettle();
    expect(find.text('Faction'), findsNothing);
    expect(socialBadge, findsOneWidget);

    await tester.tap(find.text('Social'));
    await tester.pumpAndSettle();
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Faction'), findsOneWidget);
    expect(find.text('Trade'), findsNothing);

    NativeChat.prefs
      ..globalsPlacement = ChatGlobalsPlacement.top
      ..setRoomPlacement('faction', ChatGlobalsPlacement.mixed);
    await tester.pumpAndSettle();
    expect(find.text('Social'), findsNothing);
    expect(_above(tester, 'Global', 'Company'), isTrue);
    await close(tester);
  });

  testWidgets('swipe actions', (tester) async {
    start();
    await _show(tester, chat);
    _connect(source);
    source.emit(const ChatUnreadEvent({'faction': 2}));
    await tester.pump();

    Future<void> swipe(double dx, String action) async {
      await tester.drag(find.text('Faction'), Offset(dx, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
    }

    await swipe(300, 'Pin');
    expect(NativeChat.prefs.isPinned('faction'), isTrue);
    await swipe(300, 'Read');
    expect(chat.unreadFor('faction'), 0);
    await swipe(-300, 'Mute');
    expect(NativeChat.prefs.isMuted('faction'), isTrue);
    await close(tester);
  });

  testWidgets('contextual rooms follow the list from Torn', (tester) async {
    start();
    await _show(tester, chat);
    _connect(source);
    await tester.pump();
    expect(source.count('refreshRooms'), greaterThan(0));

    void rooms(List<String> ids) => source.emit(
      ChatRoomsEvent([for (final id in ids) ChatRoom(id: id, name: id == ChatRoom.travelId ? 'Mexico' : id)]),
    );
    rooms(['global', 'trade', 'faction', 'company', ChatRoom.travelId]);
    await tester.pump();
    expect(find.text('Mexico'), findsOneWidget);
    expect(find.image(const AssetImage('images/flags/ball/ball_mexico.png')), findsOneWidget);

    rooms(['global', 'trade', 'faction', 'company']);
    await tester.pump();
    expect(find.text('Mexico'), findsNothing);

    expect(
      chatTravelFlag(const ChatRoom(id: ChatRoom.travelId, name: 'United Kingdom')),
      'images/flags/ball/ball_uk.png',
    );
    expect(chatTravelFlag(const ChatRoom(id: ChatRoom.travelId, name: 'Travelling')), isNull);
    expect(chatTravelFlag(const ChatRoom(id: 'global', name: 'Mexico')), isNull);
    await close(tester);
  });

  testWidgets('recent private chats load in pages', (tester) async {
    NativeChat.prefs.globalsPlacement = ChatGlobalsPlacement.tab;
    start();
    await _show(tester, chat);
    final now = DateTime.now();
    ChatRoom dm(int id, String name, int minutesAgo) => _dm(id, name, now.subtract(Duration(minutes: minutesAgo)));
    _connect(source, [dm(1, 'Open', 30)]);
    source.emit(ChatRecentDmsEvent([dm(2, 'Newest', 1), dm(1, 'Open', 30)], offset: 0, hasMore: true));
    await tester.pump();
    expect(_above(tester, 'Newest', 'Open'), isTrue);
    expect(find.text('Open'), findsOneWidget);

    await tester.tap(find.text('Older private chats'));
    await tester.pump();
    expect(source.recentOffsets, [2]);
    source.emit(ChatRecentDmsEvent([dm(3, 'Older', 600)], offset: 2, hasMore: false));
    await tester.pump();
    expect(find.text('Older'), findsOneWidget);
    expect(find.text('Older private chats'), findsNothing);

    source.emit(ChatRecentDmsEvent([dm(4, 'Brand new', 0), dm(2, 'Newest', 1)], offset: 0, hasMore: true));
    await tester.pump();
    expect(find.text('Brand new'), findsOneWidget);
    expect(find.text('Older'), findsOneWidget);

    await tester.longPress(find.text('Newest'));
    await tester.pumpAndSettle();
    expect(find.text('Close chat'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Close chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close chat'));
    await tester.pumpAndSettle();
    expect(source.calls, contains('closeDm 1'));
    expect(chat.isDmOpen('dm:1'), isFalse);
    expect(find.text('Open'), findsOneWidget);
    await close(tester);
  });

  test('blocked and ignored players are hidden', () async {
    start(ChatPrefs()..ignored = {8: 'Delta'});
    addTearDown(chat.dispose);
    final alerts = <ChatAlert>[];
    final sub = chat.alertStream.listen(alerts.add);
    addTearDown(sub.cancel);
    source
      ..emit(const ChatReadyEvent(99))
      ..emit(const ChatBlockedEvent({7}));
    for (final (id, room, sender) in [
      ('1', 'dm:6', 6),
      ('2', 'faction', 1),
      ('3', 'faction', 7),
      ('4', 'faction', 8),
      ('5', 'dm:7', 7),
    ]) {
      source.emit(ChatMessageEvent(chatMessage(id, room, sender: sender, at: DateTime.now())));
    }
    await Future<void>.delayed(Duration.zero);

    expect(chat.messagesFor('faction'), hasLength(3));
    expect(chat.visibleMessagesFor('faction').map((m) => m.id), ['2']);
    expect(chat.lastMessageIn('faction')?.id, '2');
    expect(chat.lastMessageIn('dm:7'), isNull);
    expect(alerts.map((a) => a.message.id), ['1']);
    expect(chat.isHidden(const ChatUser(id: 99, name: 'Me')), isFalse);
  });

  testWidgets('the friends list opens a private chat', (tester) async {
    final now = DateTime.now();
    final api = _Friends([
      (
        const ChatUser(id: 3, name: 'Zulu'),
        ChatLastAction(ChatPresence.offline, now.subtract(const Duration(hours: 3))),
      ),
      (const ChatUser(id: 2, name: 'Bravo'), ChatLastAction(ChatPresence.idle, now)),
      (const ChatUser(id: 1, name: 'Alpha'), ChatLastAction(ChatPresence.online, now)),
    ]);
    start(null, api);
    await _show(tester, chat);
    _connect(source);
    await tester.pump();

    await tester.tap(find.byTooltip('Friends'));
    await tester.pumpAndSettle();
    expect(api.calls, 1);
    expect(find.text('Friends - 1 online'), findsOneWidget);
    expect(tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => (t.title as Text).data), [
      'Alpha',
      'Bravo',
      'Zulu',
    ]);
    await tester.pump(const Duration(seconds: 30));
    expect(api.calls, 2);

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(source.sent, isEmpty);
    await tester.pump(const Duration(seconds: 60));
    expect(api.calls, 2);
    await close(tester);
  });

  testWidgets('friends are not asked in the background', (tester) async {
    final api = _Friends([]);
    start(null, api);
    await _show(tester, chat);
    _connect(source);
    await tester.pump();
    await tester.tap(find.byTooltip('Friends'));
    await tester.pumpAndSettle();
    expect(api.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    expect(api.calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 30));
    expect(api.calls, 2);
    await close(tester);
  });

  testWidgets('search splits players from messages', (tester) async {
    start();
    await _show(tester, chat);
    final now = DateTime.now();
    ChatMessage say(String id, int sender, String name, String text, int minutes) => chatMessage(
      id,
      'faction',
      sender: sender,
      name: name,
      text: text,
      at: now.subtract(Duration(minutes: minutes)),
    );
    _connect(source, [_dm(7, 'Hawkeye')]);
    source.emit(
      ChatHistoryEvent(
        'faction',
        [
          say('f1', 3, 'Hawker', 'selling plushies', 9),
          say('f2', 4, 'Bravo', 'ask hawkeye about it', 5),
          say('f3', 7, 'Hawkeye', 'on my way', 2),
          say('f4', 99, 'Hawkme', 'mine', 1),
        ],
        hasOlder: false,
        isOlderPage: false,
      ),
    );
    await tester.pump();
    expect(chat.searchPlayers('hawk').map((p) => (p.$1.id, p.$2.id)), [(7, 'dm:7'), (3, 'faction')]);
    expect(chat.searchMessages('hawk').single.$2.map((m) => m.id), ['f2']);
    expect(chat.searchPlayers('h'), isEmpty);

    Future<void> search(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await search('hawk');
    await tester.tap(find.text('Messages (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Bravo'), findsOneWidget);

    await search('hawker');
    expect(find.byType(TabBar), findsNothing);
    await tester.tap(find.text('Hawker'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(chat.conversations.any((r) => r.id == 'dm:3'), isTrue);
    expect(source.sent, isEmpty);
    await close(tester);
  });

  testWidgets('a missing session shows a notice and retries spaced out', (tester) async {
    final bar = find.bySemanticsLabel('Starting chat');
    start();
    await _show(tester, chat);
    await tester.pump();
    expect(bar, findsOneWidget);
    source.emit(const ChatConnectionEvent(ChatConnection.connecting));
    await tester.pump();
    expect(find.text('Connecting…'), findsOneWidget);

    source.emit(const ChatConnectionEvent(ChatConnection.noSession));
    await tester.pump();
    expect(bar, findsNothing);
    expect(chat.needsLogin, isTrue);
    expect(find.byType(ChatSessionMessage), findsOneWidget);

    chat.attach();
    expect(source.count('reconnect'), 1);
    chat.attach();
    chat.retrySession();
    expect(source.count('reconnect'), 1);
    await tester.pump(const Duration(seconds: 10));
    expect(source.count('reconnect'), 2);

    source
      ..emit(const ChatConnectionEvent(ChatConnection.connecting))
      ..emit(const ChatConnectionEvent(ChatConnection.needsBrowser));
    await tester.pump();
    await tester.pump();
    expect(find.text('Finish logging in to Torn'), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    expect(chat.stalled, isTrue);

    _connect(source);
    await tester.pump();
    await tester.pump();
    expect(chat.stalled, isFalse);
    expect(find.text('Finish logging in to Torn'), findsNothing);

    source.emit(const ChatConnectionEvent(ChatConnection.needsBrowser));
    await tester.pump();
    await tester.pump(const Duration(seconds: 29));
    expect(chat.stalled, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(chat.stalled, isTrue);

    final before = source.count('reconnect');
    source.emit(const ChatReadyEvent(99));
    expect(source.count('reconnect'), before);
    source.emit(const ChatReadyEvent(100));
    expect(source.count('reconnect'), before + 1);
    expect(chat.myUserId, isNull);
    await close(tester);
  });
}
