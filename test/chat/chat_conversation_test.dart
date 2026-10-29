import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_filter.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/widgets/chat/chat_player_actions_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_status_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_message_actions.dart';
import 'package:torn_pda/widgets/chat/chat_next_unread.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

class _Api implements ChatApi {
  ChatLastAction? seen;
  List<(ChatUser, ChatLastAction)>? members;
  final List<int> asked = [];
  final List<String> rosters = [];

  @override
  Future<ChatLastAction?> lastAction(int userId) async {
    asked.add(userId);
    return seen;
  }

  @override
  Future<List<(ChatUser, ChatLastAction)>?> roster(String roomId) async {
    rosters.add(roomId);
    return roomId == 'faction' && members != null ? [...members!] : null;
  }

  @override
  Future<List<(ChatUser, ChatLastAction)>?> friends() async => null;
}

class _Host implements HttpClientAdapter {
  _Host(this.status, this.body);

  final int status;
  final Object body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await requestStream?.drain<void>();
    if (status == 0) throw const SocketException('offline');
    final text = body is String;
    return ResponseBody.fromString(
      text ? body as String : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [text ? Headers.textPlainContentType : Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Stakeouts extends StakeoutsController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<AddStakeoutResult> addStakeout({required String inputId}) async {
    stakeouts.add(Stakeout(id: inputId, name: 'x', status: null, lastAction: null));
    update();
    return AddStakeoutResult(success: true, id: inputId);
  }

  @override
  void removeStakeout({required String? removeId}) {
    stakeouts.removeWhere((s) => s.id == removeId);
    update();
  }

  @override
  void savePreferences() {}

  @override
  Future<void> setOnline({required Stakeout? stakeout, required bool onlineEnabled}) async {
    stakeout!.onlineEnabled = onlineEnabled;
  }
}

const _bravo = ChatRoom(
  id: 'dm:7',
  name: 'Bravo',
  type: ChatRoomType.dm,
  peer: ChatUser(id: 7, name: 'Bravo'),
);

Future<void> _show(WidgetTester tester, ChatController chat, Widget page) => tester.pumpWidget(
  MaterialApp(
    builder: BotToastInit(),
    navigatorObservers: [BotToastNavigatorObserver()],
    home: ChangeNotifierProvider<ChatController>.value(value: chat, child: page),
  ),
);

void _connect(FakeChatSource source, [List<ChatRoom> dms = const [_bravo]]) => source
  ..emit(const ChatReadyEvent(99, myName: 'Me'))
  ..emit(const ChatConnectionEvent(ChatConnection.connected))
  ..emit(ChatDmsEvent(dms));

void _history(FakeChatSource source, String roomId, List<ChatMessage> messages) =>
    source.emit(ChatHistoryEvent(roomId, messages, hasOlder: false, isOlderPage: false));

ChatMessage _ago(String id, String roomId, int sender, String name, int minutes, {String? text}) => chatMessage(
  id,
  roomId,
  sender: sender,
  name: name,
  text: text,
  at: DateTime.now().subtract(Duration(minutes: minutes)),
);

String _box(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField).last).controller!.text;

Iterable<String> _focused(WidgetTester tester) => tester
    .widgetList<ChatMessageBubble>(find.byType(ChatMessageBubble))
    .where((b) => b.searchCurrent)
    .map((b) => b.message.id);

void main() {
  useTempPathProvider();

  late FakeChatSource source;
  late ChatController chat;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..globalsPlacement = ChatGlobalsPlacement.mixed
      ..pinned = []
      ..muted = {}
      ..hiddenRooms = {}
      ..drafts = {}
      ..savedMessages = []
      ..pinnedMessages = {}
      ..confirmPublic = false
      ..warnApiKey = true;
  });

  void start([ChatApi? api]) {
    source = FakeChatSource();
    chat = ChatController(source, ChatPrefs(), api);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
    chat.dispose();
  }

  testWidgets('dm send, delete and timeout', (tester) async {
    start();
    final bar = find.bySemanticsLabel('Starting chat');
    await _show(tester, chat, const ChatConversationPage(roomId: 'dm:7'));
    await tester.pump();
    expect(bar, findsOneWidget);
    _connect(source);
    _history(source, 'dm:7', [_ago('a', 'dm:7', 7, 'Bravo', 1)]);
    await tester.pump();
    expect(bar, findsNothing);
    expect(find.text('text a'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(source.sent.single.roomId, 'dm:7');
    expect(source.sent.single.content, 'hello');
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

    final reqId = source.sent.single.reqId;
    source
      ..emit(ChatSendResultEvent('dm:7', reqId, ok: true))
      ..emit(
        ChatMessageEvent(
          chatMessage('real', 'dm:7', sender: 99, name: 'Me', text: 'hello', reqId: reqId, at: DateTime.now()),
        ),
      );
    await tester.pump();
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    expect(chat.messagesFor('dm:7').map((m) => m.id), ['a', 'real']);

    source.emit(const ChatMessageDeletedEvent('dm:7', 'real'));
    await tester.pump();
    expect(find.text('hello'), findsNothing);
    expect(chat.messagesFor('dm:7').map((m) => m.id), ['a']);

    await tester.enterText(find.byType(TextField), 'again');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(seconds: 31));
    expect(chat.messagesFor('dm:7').last.state, ChatMessageState.failed);
    await close(tester);
  });

  testWidgets('a room that never answers offers a retry and reloads when Torn is back', (tester) async {
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'dm:7'));
    _connect(source);
    await tester.pump();
    expect(source.count('openRoom'), 1);
    expect(find.text('Fetching recent messages'), findsOneWidget);

    await tester.pump(const Duration(seconds: 21));
    expect(find.text('Fetching recent messages'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(source.count('openRoom'), 2);
    expect(find.text('Fetching recent messages'), findsOneWidget);

    source
      ..emit(const ChatConnectionEvent(ChatConnection.disconnected))
      ..emit(const ChatConnectionEvent(ChatConnection.connected, reconnected: true));
    await tester.pump();
    expect(source.count('openRoom'), 3);

    source
      ..emit(const ChatConnectionEvent(ChatConnection.tornDown))
      ..emit(const ChatConnectionEvent(ChatConnection.connected))
      ..emit(const ChatReadyEvent(99, myName: 'Me'));
    await tester.pump();
    expect(source.count('openRoom'), 4);

    _history(source, 'dm:7', [_ago('a', 'dm:7', 7, 'Bravo', 1)]);
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('text a'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    await close(tester);
  });

  testWidgets('asks before sending to a public room or a key', (tester) async {
    Future<List<String>> send(String draft, {String? roomId, String? asks, String answer = 'Send'}) async {
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatComposer(
                key: UniqueKey(),
                roomName: 'Global',
                roomId: roomId,
                enabled: true,
                onSend: sent.add,
                draft: draft,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      if (asks == null) {
        expect(find.byType(AlertDialog), findsNothing);
      } else {
        expect(find.textContaining(asks), findsOneWidget);
        await tester.tap(find.text(answer));
        await tester.pumpAndSettle();
      }
      return sent;
    }

    expect(await send('hello', roomId: 'global'), ['hello']);
    NativeChat.prefs.confirmPublic = true;
    expect(await send('hello', roomId: 'global', asks: 'Send to Global?', answer: 'Cancel'), isEmpty);
    expect(await send('hello', roomId: 'global', asks: 'Send to Global?'), ['hello']);
    expect(await send('hello', roomId: 'faction'), ['hello']);

    const key = 'my key AbCd1234EfGh5678';
    expect(await send(key, asks: 'looks like an API key', answer: 'Cancel'), isEmpty);
    expect(await send(key, asks: 'looks like an API key'), [key]);
    expect(await send('profiles.php?XID=1234567890123456'), hasLength(1));
    NativeChat.prefs.warnApiKey = false;
    expect(await send('AbCd1234EfGh5678'), hasLength(1));
  });

  testWidgets('unread separator and markRead', (tester) async {
    start();
    List<String> reads() => [
      for (final c in source.calls)
        if (c.startsWith('markRead ')) c.substring(9),
    ];
    final now = DateTime.now();
    source
      ..emit(const ChatReadyEvent(99))
      ..emit(const ChatUnreadEvent({'faction': 2, 'company': 1, 'global': 40, 'dm:7': 3}));

    chat.openConversation('faction');
    expect(reads(), ['faction']);
    expect(chat.firstUnreadId('faction'), isNull);
    _history(source, 'faction', [
      for (var i = 0; i < 5; i++)
        chatMessage(
          'f$i',
          'faction',
          sender: i == 3 ? 99 : 1,
          at: now.add(Duration(seconds: i)),
        ),
    ]);
    expect(chat.firstUnreadId('faction'), 'f2');
    source.emit(ChatMessageEvent(chatMessage('f5', 'faction', sender: 1, at: now.add(const Duration(seconds: 9)))));
    expect(chat.firstUnreadId('faction'), 'f2');
    chat.closeConversation('faction');
    expect(chat.firstUnreadId('faction'), isNull);

    expect(chat.readable.toSet(), {'company', 'dm:7'});
    expect(chat.markAllRead(), 2);
    expect(chat.unreadFor('company'), 0);
    expect(chat.unreadFor('global'), 40);

    chat.openConversation('global');
    _history(source, 'global', [chatMessage('g1', 'global', sender: 1, at: now)]);
    expect(chat.firstUnreadId('global'), isNull);
    chat.closeConversation('global');
    source.emit(ChatMessageEvent(chatMessage('g2', 'global', sender: 2, at: now.add(const Duration(minutes: 1)))));
    chat.openConversation('global');
    expect(chat.firstUnreadId('global'), 'g2');
    chat.closeConversation('global');

    chat
      ..openConversation('faction')
      ..openConversation('dm:7');
    source.calls.clear();
    source.emit(ChatMessageEvent(chatMessage('f6', 'faction', sender: 5, at: now), unread: 1));
    await tester.pump(const Duration(seconds: 3));
    expect(reads(), isEmpty);
    source.emit(ChatMessageEvent(chatMessage('d1', 'dm:7', sender: 7, at: now), unread: 1));
    await tester.pump(const Duration(seconds: 3));
    expect(reads(), ['dm:7']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    source.emit(ChatMessageEvent(chatMessage('d2', 'dm:7', sender: 7, at: now), unread: 1));
    await tester.pump(const Duration(seconds: 3));
    expect(reads(), ['dm:7']);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    chat.resumed();
    expect(reads(), ['dm:7', 'dm:7']);

    chat.closeConversation('dm:7');
    expect(reads(), ['dm:7', 'dm:7', 'faction']);
    chat.dispose();
  });

  testWidgets('the cross on the unread notice marks the room read', (tester) async {
    start();
    source
      ..emit(const ChatReadyEvent(99))
      ..emit(const ChatUnreadEvent({'faction': 35}));
    await _show(tester, chat, const ChatConversationPage(roomId: 'faction'));
    await tester.pump();
    final now = DateTime.now();
    _history(source, 'faction', [
      for (var i = 0; i < 40; i++) chatMessage('m$i', 'faction', sender: 1, at: now.add(Duration(seconds: i))),
    ]);
    await tester.pump();
    source.emit(const ChatUnreadEvent({'faction': 35}));
    await tester.pump();
    source.calls.clear();

    final notice = find.byType(ChatUnreadAbove);
    expect(notice, findsOneWidget);
    expect(chat.canMarkRead('faction'), isTrue);

    await tester.tap(find.byTooltip('Mark as read'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(source.calls, ['markRead faction']);
    expect(chat.canMarkRead('faction'), isFalse);
    expect(tester.widget<ChatPopIn>(find.ancestor(of: notice, matching: find.byType(ChatPopIn))).visible, isFalse);
    await close(tester);
  });

  testWidgets('the unread notice itself scrolls to the first unread without reading', (tester) async {
    start();
    source
      ..emit(const ChatReadyEvent(99))
      ..emit(const ChatUnreadEvent({'faction': 35}));
    await _show(tester, chat, const ChatConversationPage(roomId: 'faction'));
    await tester.pump();
    final now = DateTime.now();
    _history(source, 'faction', [
      for (var i = 0; i < 40; i++) chatMessage('m$i', 'faction', sender: 1, at: now.add(Duration(seconds: i))),
    ]);
    await tester.pump();
    source.emit(const ChatUnreadEvent({'faction': 35}));
    await tester.pump();
    source.calls.clear();
    expect(find.byType(ChatUnreadSeparator), findsNothing);

    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_up_rounded));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ChatUnreadSeparator), findsOneWidget);
    expect(source.calls, isEmpty);
    expect(chat.canMarkRead('faction'), isTrue);
    await close(tester);
  });

  testWidgets('search in a chat marks and walks the matches', (tester) async {
    start();
    source
      ..emit(const ChatReadyEvent(99))
      ..emit(const ChatUnreadEvent({'faction': 1}));
    NativeChat.prefs.drafts = {'faction': 'half written'};
    await _show(tester, chat, const ChatConversationPage(roomId: 'faction'));
    await tester.pump();
    final now = DateTime.now();
    _history(source, 'faction', [
      for (var i = 0; i < 6; i++) chatMessage('m$i', 'faction', sender: 1, at: now.add(Duration(seconds: i))),
    ]);
    await tester.pump();
    expect(find.byType(ChatUnreadSeparator), findsOneWidget);
    expect(find.text('half written'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Search in this chat'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.descendant(of: find.byType(AppBar), matching: find.byType(TextField)), 'text m');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1/6'), findsOneWidget);
    await tester.tap(find.byTooltip('Older match'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2/6'), findsOneWidget);
    await tester.tap(find.byTooltip('Newer match'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1/6'), findsOneWidget);
    await close(tester);
  });

  testWidgets('a filtered list stays still when messages arrive', (tester) async {
    source = FakeChatSource();
    chat = ChatController(
      source,
      ChatPrefs()
        ..roomFilters = {
          'global': ChatRoomFilter(hide: ['spam']),
        },
    );
    source.emit(const ChatReadyEvent(99));
    await _show(tester, chat, const ChatConversationPage(roomId: 'global'));
    await tester.pump();
    final start = DateTime.now().subtract(const Duration(hours: 1));
    _history(source, 'global', [
      for (var i = 0; i < 40; i++)
        chatMessage(
          'm$i',
          'global',
          sender: 3,
          text: i == 39 ? 'spam spam' : 'line $i',
          at: start.add(Duration(seconds: i)),
        ),
    ]);
    await tester.pump();
    final list = find.byType(ListView).first;
    int rows() => tester.widget<ListView>(list).childrenDelegate.estimatedChildCount!;
    await tester.drag(list, const Offset(0, 600));
    await tester.pump();
    final before = rows();
    source.emit(ChatMessageEvent(chatMessage('fresh', 'global', sender: 3, text: 'fresh news', at: DateTime.now())));
    await tester.pump();
    expect(rows(), before);
    await close(tester);
  });

  testWidgets('with fewer animations the jump to the latest is instant', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    start();
    source.emit(const ChatReadyEvent(99));
    await _show(tester, chat, const ChatConversationPage(roomId: 'global'));
    await tester.pump();
    final begin = DateTime.now().subtract(const Duration(hours: 1));
    _history(source, 'global', [
      for (var i = 0; i < 40; i++)
        chatMessage('m$i', 'global', sender: 3, text: 'line $i', at: begin.add(Duration(seconds: i))),
    ]);
    await tester.pump();
    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, 600));
    await tester.pump();
    await tester.tap(find.byTooltip('Go to the latest messages'));
    await tester.pump();
    expect(tester.widget<ListView>(list).controller!.offset, 0);
    await close(tester);
  });

  testWidgets('search opens a message and jumps to its quote', (tester) async {
    start();
    await _show(tester, chat, const ChatPage());
    await tester.pump();
    ChatMessage say(String id, String room, String name, String text, int minutes) =>
        _ago(id, room, name.length, name, minutes, text: text);
    final original = say('f1', 'faction', 'Alpha', 'raid at noon', 50);
    _connect(source, const []);
    _history(source, 'faction', [
      original,
      for (var i = 0; i < 40; i++) say('pad$i', 'faction', 'Bravo', 'filler $i', 45 - i),
      say('f2', 'faction', 'Bravo', 'Raid moved', 4),
      say('f3', 'faction', 'Charlie', ChatQuote.reply(original, 'ok'), 3),
      say('f4', 'faction', 'Charlie', ChatQuote.reply(say('gone', 'faction', 'Zed', 'lost', 99), 'hm'), 2),
    ]);
    source.emit(ChatPeekEvent('global', say('g1', 'global', 'Delta', 'anyone up for a raid?', 1)));
    await tester.pump();

    final groups = chat.searchMessages('RAID');
    expect(groups.map((g) => g.$1.id), ['global', 'faction']);
    expect(groups.last.$2.map((m) => m.id), ['f3', 'f2', 'f1']);
    expect(chat.searchMessages('r'), isEmpty);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'raid');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Faction'), findsOneWidget);
    expect(find.text('Global'), findsOneWidget);

    await tester.tap(find.text('Alpha'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(source.calls, contains('openRoom faction'));
    expect(_focused(tester), ['f1']);
    await tester.pump(const Duration(seconds: 3));

    await tester.longPress(find.text('raid at noon'));
    await tester.pump();
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(NativeChat.prefs.savedMessages.single.excerpt, 'raid at noon');

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zed\nlost'));
    await tester.pumpAndSettle();
    expect(find.text('Message not loaded'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Alpha\nraid at noon'));
    await tester.pumpAndSettle();
    expect(_focused(tester), ['f1']);
    await tester.pump(const Duration(seconds: 3));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Saved messages'), findsOneWidget);
    expect(find.text('raid at noon'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from saved'));
    await tester.pump();
    expect(NativeChat.prefs.savedMessages, isEmpty);
    await close(tester);
  });

  testWidgets('swipe to quote, select to forward', (tester) async {
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'global'));
    await tester.pump();
    _connect(source);
    _history(source, 'global', [
      _ago('a', 'global', 1, 'Alpha', 3),
      _ago('b', 'global', 2, 'Charlie', 2),
      _ago('k', 'global', 3, 'Delta', 1, text: 'AbCd1234EfGh5678'),
    ]);
    await tester.pump();

    await tester.drag(find.text('text a'), const Offset(90, 0));
    await tester.pumpAndSettle();
    expect(find.text('Replying to Alpha'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'yes');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(source.sent.last.content, '▎ Alpha: text a\nyes');
    expect(find.text('Replying to Alpha'), findsNothing);

    final selected = find.descendant(of: find.byType(AppBar), matching: find.text('2 selected'));
    await tester.longPress(find.text('text a'));
    await tester.pump();
    await tester.tap(find.text('text b'), warnIfMissed: false);
    await tester.pump();
    expect(selected, findsOneWidget);
    await tester.tap(find.text('yes'), warnIfMissed: false);
    await tester.pump();
    expect(selected, findsOneWidget);

    await tester.tap(find.byTooltip('Forward'));
    await tester.pumpAndSettle();
    expect(find.text('Forward 2 messages to'), findsOneWidget);
    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(source.sent.last.roomId, 'dm:7');
    expect(source.sent.last.content, 'Forwarded from Global\nAlpha: text a\nCharlie: text b');
    expect(find.byTooltip('Cancel selection'), findsNothing);

    Future<void> forward(String text, String to) async {
      await tester.longPress(find.text(text));
      await tester.pump();
      await tester.tap(find.byTooltip('Forward'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(to).last);
      await tester.pumpAndSettle();
    }

    NativeChat.prefs.confirmPublic = true;
    final count = source.sent.length;
    await forward('text a', 'Trade');
    expect(find.text('Send to Trade?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(source.sent, hasLength(count));
    await tester.tap(find.byTooltip('Cancel selection'));
    await tester.pump();

    await forward('text a', 'Trade');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(source.sent.last.roomId, 'trade');

    await forward('AbCd1234EfGh5678', 'Faction');
    expect(find.textContaining('looks like an API key'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(source.sent, hasLength(count + 1));
    await close(tester);
  });

  testWidgets('an emoji from the strip replies to that message', (tester) async {
    NativeChat.prefs.emojiFavorites = ['👍', '🔥'];
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'faction'));
    await tester.pump();
    _connect(source);
    _history(source, 'faction', [_ago('a', 'faction', 1, 'Alpha', 3), _ago('b', 'faction', 2, 'Charlie', 2)]);
    await tester.pump();

    await tester.longPress(find.text('text a'));
    await tester.pump();
    await tester.tap(find.byTooltip('Reply with an emoji'));
    await tester.pump();
    await tester.tap(find.byTooltip('Reply with 🔥'));
    await tester.pumpAndSettle();
    expect(source.sent.last.roomId, 'faction');
    expect(source.sent.last.content, '▎ Alpha: text a\n🔥');
    expect(find.byTooltip('Cancel selection'), findsNothing);
    await close(tester);
  });

  testWidgets('the message bar follows the chosen actions and order', (tester) async {
    addTearDown(() {
      NativeChat.prefs.messageActionOrder = [...ChatPrefs.messageActionIds];
      NativeChat.prefs.messageActionHidden = {};
    });
    NativeChat.prefs
      ..messageActionOrder = [
        'share',
        'copy',
        ...ChatPrefs.messageActionIds.where((id) => id != 'share' && id != 'copy'),
      ]
      ..messageActionHidden = {'forward', 'smiley', 'pin', 'save', 'translate', 'remind'};
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'faction'));
    await tester.pump();
    _connect(source);
    _history(source, 'faction', [_ago('a', 'faction', 1, 'Alpha', 3)]);
    await tester.pump();

    await tester.longPress(find.text('text a'));
    await tester.pump();
    final bar = tester.widget<ChatMessageActions>(find.byType(ChatMessageActions));
    expect([for (final a in bar.actions) a.$3], ['Share', 'Copy', 'Reply']);
    await close(tester);
  });

  testWidgets('@ suggests recent senders first', (tester) async {
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'global'));
    await tester.pump();
    _connect(source);
    _history(source, 'global', [
      _ago('a', 'global', 1, 'Alpha', 3),
      _ago('b', 'global', 2, 'Bravo', 2),
      _ago('c', 'global', 3, 'Malfoy', 1),
      _ago('d', 'global', 99, 'Alice', 0),
    ]);
    await tester.pump();
    Iterable<String?> chips() =>
        tester.widgetList<ActionChip>(find.byType(ActionChip)).map((c) => (c.label as Text).data);

    await tester.enterText(find.byType(TextField), 'hi @a');
    await tester.pump();
    expect(chips(), unorderedEquals(['Alpha', 'Bravo', 'Malfoy']));
    await tester.pump(const Duration(milliseconds: 500));
    expect(source.count('search'), 0);

    await tester.enterText(find.byType(TextField), 'hi @al');
    await tester.pump(const Duration(milliseconds: 500));
    expect(source.calls, contains('search al'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    source.emit(const ChatSearchEvent('al', [ChatUser(id: 5, name: 'Alvaro'), ChatUser(id: 99, name: 'Alice')]));
    await tester.pump();
    expect(chips(), ['Alpha', 'Alvaro', 'Malfoy']);

    await tester.tap(find.widgetWithText(ActionChip, 'Alvaro'));
    await tester.pump();
    expect(_box(tester), 'hi @Alvaro ');
    expect(find.byType(ActionChip), findsNothing);
    expect(chat.searchQuery, isNull);
    await tester.enterText(find.byType(TextField), '');
    await close(tester);
  });

  testWidgets('presence polled only while open', (tester) async {
    final now = DateTime.now();
    final api = _Api()
      ..seen = ChatLastAction(ChatPresence.offline, now.subtract(const Duration(hours: 2, minutes: 5)))
      ..members = [
        (const ChatUser(id: 3, name: 'Zulu'), const ChatLastAction(ChatPresence.offline)),
        (const ChatUser(id: 1, name: 'Alpha'), ChatLastAction(ChatPresence.online, now)),
        (const ChatUser(id: 2, name: 'Bravo'), ChatLastAction(ChatPresence.idle, now)),
        (const ChatUser(id: 4, name: 'Zed'), ChatLastAction(ChatPresence.online, now)),
        (const ChatUser(id: 99, name: 'Me'), ChatLastAction(ChatPresence.online, now)),
      ];
    start(api);
    await _show(tester, chat, const ChatConversationPage(roomId: 'dm:7'));
    _connect(source);
    await tester.pump();
    expect(source.calls, contains('online [7]'));
    expect(api.asked, [7]);
    expect(find.text('2h ago'), findsOneWidget);

    source.emit(const ChatPresenceEvent({7: ChatPresence.idle, 8: ChatPresence.online}));
    await tester.pump();
    expect(find.text('Idle, 2h ago'), findsOneWidget);

    api.seen = ChatLastAction(ChatPresence.online, now);
    source.emit(const ChatPresenceEvent({7: ChatPresence.online}));
    await tester.pump(const Duration(seconds: 30));
    expect(api.asked, [7, 7]);
    expect(find.text('Online'), findsOneWidget);

    source.emit(const ChatConnectionEvent(ChatConnection.disconnected));
    await tester.pump();
    expect(find.text('Offline, reconnecting…'), findsOneWidget);

    chat.closeConversation('dm:7');
    await tester.pump(const Duration(seconds: 90));
    expect(api.asked, [7, 7]);
    expect(api.rosters, isEmpty);

    await _show(tester, chat, const ChatConversationPage(key: ValueKey('faction'), roomId: 'faction'));
    source.emit(const ChatConnectionEvent(ChatConnection.connected));
    _history(source, 'faction', [_ago('a', 'faction', 1, 'Alpha', 2), _ago('b', 'faction', 2, 'Bravo', 1)]);
    await tester.pump();
    expect(api.rosters, ['faction']);
    expect(chat.rosterOf('faction').map((u) => u.name), ['Alpha', 'Me', 'Zed', 'Bravo', 'Zulu']);
    expect(
      {
        for (final b in tester.widgetList<ChatMessageBubble>(find.byType(ChatMessageBubble)))
          b.message.sender.name: b.presence,
      },
      {'Alpha': ChatPresence.online, 'Bravo': ChatPresence.idle},
    );

    await tester.enterText(find.byType(TextField), 'hi @z');
    await tester.pump();
    expect(tester.widgetList<ActionChip>(find.byType(ActionChip)).map((c) => (c.label as Text).data), ['Zed', 'Zulu']);
    await tester.enterText(find.byType(TextField), 'hi @m');
    await tester.pump();
    expect(find.widgetWithText(ActionChip, 'Me'), findsNothing);
    await tester.enterText(find.byType(TextField), '');

    await tester.pump(const Duration(seconds: 30));
    expect(api.rosters, ['faction', 'faction']);
    chat.closeConversation('faction');
    await tester.pump(const Duration(seconds: 60));
    expect(api.rosters, ['faction', 'faction']);
    await close(tester);
  });

  testWidgets('a covered room is not polled', (tester) async {
    final api = _Api()..seen = ChatLastAction(ChatPresence.online, DateTime.now());
    start(api);
    await _show(tester, chat, const ChatConversationPage(roomId: 'dm:7'));
    _connect(source);
    await tester.pump();
    expect(api.asked, [7]);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('browser'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(minutes: 2));
    expect(api.asked, [7]);
    nav.pop();
    await tester.pump();
    expect(api.asked, [7, 7]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 30));
    expect(api.asked, [7, 7, 7]);
    await close(tester);
  });

  testWidgets('the full screen chat minimizes only where a bubble takes it', (tester) async {
    start();
    final enabled = NativeChat.prefs.inAppEnabled;
    addTearDown(
      () => NativeChat.prefs
        ..inAppEnabled = enabled
        ..launcher = ChatLauncher.bubble
        ..miniBubbles = true,
    );
    Future<Finder> minimize(ChatLauncher launcher, {required bool miniBubbles}) async {
      NativeChat.prefs
        ..inAppEnabled = true
        ..launcher = launcher
        ..miniBubbles = miniBubbles;
      await _show(tester, chat, ChatConversationPage(key: UniqueKey(), roomId: 'global'));
      return find.byTooltip('Minimize to the bubble');
    }

    expect(await minimize(ChatLauncher.browser, miniBubbles: false), findsNothing);
    expect(await minimize(ChatLauncher.menuBar, miniBubbles: true), findsOneWidget);
    expect(await minimize(ChatLauncher.bubble, miniBubbles: false), findsOneWidget);
    await close(tester);
  });

  testWidgets('an embedded conversation leaves navigation and covering to its host', (tester) async {
    final api = _Api()..seen = ChatLastAction(ChatPresence.online, DateTime.now());
    start(api);
    final live = ValueNotifier(true);
    var back = 0;
    await _show(
      tester,
      chat,
      ValueListenableBuilder(
        valueListenable: live,
        builder: (_, on, _) => TickerMode(
          enabled: on,
          child: ChatConversationPage(roomId: 'dm:7', embedded: true, onBack: () => back++),
        ),
      ),
    );
    _connect(source);
    await tester.pump();
    expect(api.asked, [7]);
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    expect(back, 1);
    expect(find.byType(ChatConversationPage), findsOneWidget);
    live.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(minutes: 2));
    expect(api.asked, [7]);
    await close(tester);
  });

  testWidgets('an embedded conversation reports a gone room to its host', (tester) async {
    start();
    var gone = 0;
    await _show(tester, chat, ChatConversationPage(roomId: 'poker', embedded: true, onGone: () => gone++));
    const faction = ChatRoom(id: 'faction', name: 'Faction');
    const poker = ChatRoom(id: 'poker', name: 'Poker', icon: 'casino');
    source
      ..emit(const ChatRoomsEvent([faction, poker]))
      ..emit(const ChatRoomsEvent([faction]));
    await tester.pump();
    await tester.pump();
    expect(gone, 1);
    expect(find.byType(ChatConversationPage), findsOneWidget);
    await close(tester);
  });

  testWidgets('compose extras fill the box and never send', (tester) async {
    NativeChat.prefs
      ..quickReplies = ['Price?']
      ..itemPrice = true;
    final fetchItems = ChatLinkPreviews.fetchItems;
    final fetchStatus = chatStatusFetch;
    addTearDown(() {
      ChatLinkPreviews.fetchItems = fetchItems;
      ChatLinkPreviews.resetForTests();
      chatStatusFetch = fetchStatus;
    });
    ChatLinkPreviews.resetForTests();
    ChatLinkPreviews.fetchItems = () async => ItemsModel(items: {'206': Item(name: 'Xanax', marketValue: 830000)});
    ChatPlayerCards.fetch = (id) async => {
      'profile': {
        'id': id,
        'name': 'Bravo',
        'level': 12,
        'status': {'description': 'Okay'},
        'last_action': {'status': 'Online'},
      },
    };
    var statusCalls = 0;
    chatStatusFetch = () async {
      statusCalls++;
      return BarsStatusCooldownsModel(
        serverTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        energy: PersonalBars(current: 95, maximum: 150),
        status: Status(state: 'Okay', until: 0),
        travel: Travel(destination: 'Torn', timestamp: 0),
        cooldowns: Cooldowns(drug: 0, medical: 0, booster: 0),
      );
    };
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'faction'));
    _connect(source, const []);
    _history(source, 'faction', [_ago('f1', 'faction', 1, 'Alpha', 9), _ago('f2', 'faction', 2, 'Bravo', 1)]);
    await tester.pump();

    await tester.longPress(find.text('text f1'));
    await tester.pump();
    await tester.tap(find.byTooltip('Pin'));
    await tester.pumpAndSettle();
    expect(NativeChat.prefs.pinnedIn('faction')?.messageId, 'f1');
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byType(ChatPinnedBar));
    await tester.pumpAndSettle();
    expect(_focused(tester), ['f1']);
    await tester.pump(const Duration(seconds: 3));
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).removeCurrentSnackBar();
    await tester.pump();

    Future<void> tool(String chip) async {
      if (find.byType(ActionChip).evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Quick actions'));
        await tester.pump();
      }
      final row = find.ancestor(of: find.byType(ActionChip).first, matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(
        find.widgetWithText(ActionChip, chip),
        200,
        scrollable: find.byWidget(tester.widget<Scrollable>(row)),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ActionChip, chip));
      await tester.pumpAndSettle();
    }

    await tool('Price?');
    expect(_box(tester), 'Price? ');

    await tool('Item price');
    await tester.enterText(find.widgetWithText(TextField, 'Item name'), 'xan');
    await tester.pump();
    await tester.tap(find.text(r'Xanax $830,000'));
    await tester.pump();
    expect(_box(tester), r'Price? Xanax $830,000 ');

    await tool('Player');
    await tester.enterText(find.widgetWithText(TextField, 'Player name or ID'), 'char');
    await tester.pump(const Duration(milliseconds: 500));
    expect(source.calls.last, 'search char');
    source.emit(const ChatSearchEvent('char', [ChatUser(id: 7, name: 'Charlie')]));
    await tester.pump();
    expect(find.widgetWithText(ActionChip, 'Charlie'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Player name or ID'), 'bra');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'Bravo'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('Add to the message'));
    await tester.pump();
    expect(_box(tester), endsWith('Bravo [2] '));

    await tool('Status');
    expect(statusCalls, 1);
    expect(find.text('E 95/150'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tool('Wiki');
    await tester.enterText(find.widgetWithText(TextField, 'Search the wiki'), 'xan');
    await tester.pump();
    await tester.tap(find.text('Xanax'));
    await tester.pumpAndSettle();
    expect(_box(tester), endsWith('https://wiki.torn.com/wiki/Xanax '));

    await tester.tap(find.byTooltip('Unpin'));
    await tester.pump();
    expect(NativeChat.prefs.pinnedIn('faction'), isNull);
    expect(source.sent, isEmpty);
    await close(tester);
  });

  testWidgets('an imgur upload lands in the box', (tester) async {
    NativeChat.prefs
      ..imageHost = ChatImageHost.imgur
      ..imgurClientId = '';
    final pick = ChatImageUpload.pick;
    final adapter = ChatImageUpload.dio.httpClientAdapter;
    addTearDown(() {
      ChatImageUpload.pick = pick;
      ChatImageUpload.dio.httpClientAdapter = adapter;
      NativeChat.prefs.imgurClientId = '';
    });
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'global'));
    _connect(source);
    await tester.pump();

    await tester.tap(find.byTooltip('Attach an image'));
    await tester.pump();
    expect(find.text('Register at imgur'), findsOneWidget);
    expect(find.text('Gallery'), findsNothing);

    NativeChat.prefs.imgurClientId = 'fake-client-id';
    ChatImageUpload.pick = ({required bool fromFiles}) async =>
        PlatformFile(name: 'a.png', size: 3, bytes: Uint8List.fromList([1, 2, 3]));
    final imgur = _Host(200, {
      'data': {'link': 'https://i.imgur.com/abc.png'},
      'success': true,
      'status': 200,
    });
    ChatImageUpload.dio.httpClientAdapter = imgur;
    await tester.tap(find.byTooltip('Attach an image'));
    await tester.pump();
    await tester.tap(find.byTooltip('Attach an image'));
    await tester.pump();
    expect(find.textContaining('anyone with the link'), findsOneWidget);

    await tester.tap(find.text('Gallery'));
    for (var i = 0; i < 50 && _box(tester).isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(imgur.requests.single.headers['Authorization'], 'Client-ID fake-client-id');
    expect(_box(tester), 'https://i.imgur.com/abc.png ');
    expect(source.sent, isEmpty);

    const limited = 'imgur is limiting uploads right now, try again later';
    ChatImageUpload.dio.httpClientAdapter = _Host(429, {'success': false, 'status': 429});
    await tester.tap(find.byTooltip('Attach an image'));
    await tester.pump();
    await tester.tap(find.text('Files'));
    for (var i = 0; i < 50 && find.text(limited).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text(limited), findsOneWidget);
    expect(_box(tester), 'https://i.imgur.com/abc.png ');

    for (final (bytes, id) in [(Uint8List(ChatImageHost.imgur.maxBytes + 1), 'fake-client-id'), (Uint8List(1), ' ')]) {
      await expectLater(
        ChatImageUpload.upload(ChatImageHost.imgur, bytes, 'a.png', id),
        throwsA(isA<ChatUploadError>()),
      );
    }
    await tester.enterText(find.byType(TextField), '');
    await close(tester);
  });

  testWidgets('picking Catbox in the upload notice shows the pickers', (tester) async {
    NativeChat.prefs
      ..imageHost = ChatImageHost.imgur
      ..imgurClientId = '';
    addTearDown(() => NativeChat.prefs.imageHost = ChatImageHost.imgur);
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'global'));
    _connect(source);
    await tester.pump();

    await tester.tap(find.byTooltip('Attach an image'));
    await tester.pump();
    expect(find.text('Gallery'), findsNothing);
    await tester.tap(find.text('Catbox'));
    await tester.pump();
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    await close(tester);
  });

  testWidgets('picking another service after a blocked upload clears the notice', (tester) async {
    NativeChat.prefs
      ..imageHost = ChatImageHost.imgur
      ..imgurClientId = 'fake-client-id';
    final pick = ChatImageUpload.pick;
    final adapter = ChatImageUpload.dio.httpClientAdapter;
    addTearDown(() {
      ChatImageUpload.pick = pick;
      ChatImageUpload.dio.httpClientAdapter = adapter;
      NativeChat.prefs
        ..imageHost = ChatImageHost.imgur
        ..imgurClientId = '';
    });
    ChatImageUpload.pick = ({required bool fromFiles}) async =>
        PlatformFile(name: 'a.png', size: 3, bytes: Uint8List.fromList([1, 2, 3]));
    ChatImageUpload.dio.httpClientAdapter = _Host(451, {});
    start();
    await _show(tester, chat, const ChatConversationPage(roomId: 'global'));
    _connect(source);
    await tester.pump();

    await tester.tap(find.byTooltip('Attach an image'));
    await tester.pump();
    await tester.tap(find.text('Gallery'));
    for (var i = 0; i < 50 && find.text('Could not upload the image').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Could not upload the image'), findsOneWidget);
    expect(find.text('imgur'), findsNothing);

    await tester.tap(find.text('ImgBB'));
    await tester.pump();
    expect(find.text('Could not upload the image'), findsNothing);
    expect(find.text('imgur'), findsNothing);
    await close(tester);
  });

  test('ImgBB and Catbox uploads and their errors', () async {
    final adapter = ChatImageUpload.dio.httpClientAdapter;
    addTearDown(() => ChatImageUpload.dio.httpClientAdapter = adapter);
    final bytes = Uint8List.fromList([1, 2, 3]);
    Future<String> up(ChatImageHost host, _Host fake, [String credential = '']) {
      ChatImageUpload.dio.httpClientAdapter = fake;
      return ChatImageUpload.upload(host, bytes, 'a.png', credential);
    }

    Future<void> fails(ChatImageHost host, _Host fake, String message, [String credential = 'k']) => expectLater(
      up(host, fake, credential),
      throwsA(isA<ChatUploadError>().having((e) => e.message, 'message', message)),
    );

    final imgbb = _Host(200, {
      'data': {'url': 'https://i.ibb.co/x/a.png', 'display_url': 'https://ibb.co/x'},
      'success': true,
      'status': 200,
    });
    expect(await up(ChatImageHost.imgbb, imgbb, ' fake-key '), 'https://i.ibb.co/x/a.png');
    final sent = imgbb.requests.single;
    expect(sent.uri.toString(), startsWith('https://api.imgbb.com/1/upload'));
    expect(sent.uri.queryParameters['key'], 'fake-key');
    expect(sent.headers['Authorization'], isNull);
    expect((sent.data as FormData).files.map((f) => f.key), ['image']);

    await fails(
      ChatImageHost.imgbb,
      _Host(400, {
        'status_code': 400,
        'error': {'message': 'Invalid API v1 key.', 'code': 100},
      }),
      'ImgBB refused the API key, check it in the chat settings',
    );
    await fails(
      ChatImageHost.imgbb,
      _Host(400, {
        'status_code': 400,
        'error': {'message': 'Invalid image source', 'code': 310},
      }),
      'ImgBB could not read that image',
    );
    await fails(ChatImageHost.imgbb, _Host(429, {}), 'ImgBB is limiting uploads right now, try again later');
    await fails(
      ChatImageHost.imgbb,
      _Host(0, {}),
      'Could not reach ImgBB, check the connection. If it is fine, ImgBB may be blocked in your country',
    );
    for (final blocked in [_Host(451, {}), _Host(403, '<html>denied</html>')]) {
      await expectLater(
        up(ChatImageHost.imgbb, blocked, 'k'),
        throwsA(isA<ChatUploadError>().having((e) => e.blocked, 'blocked', isTrue)),
      );
    }
    await fails(ChatImageHost.imgbb, _Host(200, {}), 'Add the ImgBB API key in the chat settings first', ' ');
    await expectLater(
      ChatImageUpload.upload(ChatImageHost.imgbb, Uint8List(ChatImageHost.imgbb.maxBytes + 1), 'big.png', 'k'),
      throwsA(
        isA<ChatUploadError>().having((e) => e.message, 'message', 'The image is too big, ImgBB takes up to 32 MB'),
      ),
    );

    final catbox = _Host(200, 'https://files.catbox.moe/abc123.png\n');
    expect(await up(ChatImageHost.catbox, catbox), 'https://files.catbox.moe/abc123.png');
    final anonymous = catbox.requests.single.data as FormData;
    expect(catbox.requests.single.uri.toString(), 'https://catbox.moe/user/api.php');
    expect(Map.fromEntries(anonymous.fields), {'reqtype': 'fileupload'});
    expect(anonymous.files.map((f) => f.key), ['fileToUpload']);

    final withHash = _Host(200, 'https://files.catbox.moe/def456.png');
    expect(await up(ChatImageHost.catbox, withHash, 'fake-hash'), 'https://files.catbox.moe/def456.png');
    expect(Map.fromEntries((withHash.requests.single.data as FormData).fields)['userhash'], 'fake-hash');

    await fails(
      ChatImageHost.catbox,
      _Host(400, 'Invalid UserHash'),
      'Catbox refused the Userhash, check it in the chat settings',
    );
    await fails(ChatImageHost.catbox, _Host(200, 'Something went wrong'), 'Catbox could not take the image');
    await fails(ChatImageHost.catbox, _Host(413, 'too big'), 'The image is too big for Catbox');
  });

  testWidgets('watch button adds a stakeout with undo', (tester) async {
    expect(ChatWatchCondition.forKind(ChatStatusKind.hospital), ChatWatchCondition.okay);
    expect(ChatWatchCondition.forKind(ChatStatusKind.jail), ChatWatchCondition.freed);
    expect(ChatWatchCondition.forKind(ChatStatusKind.travel), ChatWatchCondition.landed);
    expect(ChatWatchCondition.forKind(ChatStatusKind.okay), ChatWatchCondition.online);
    expect(ChatWatchCondition.forKind(null), ChatWatchCondition.online);

    Get.reset();
    addTearDown(Get.reset);
    ChatPlayerCards.resetForTests();
    addTearDown(ChatPlayerCards.resetForTests);
    ChatPlayerCards.fetch = (id) async => {
      'profile': {
        'status': {'state': 'Okay'},
      },
    };
    final stakeouts = Get.put<StakeoutsController>(_Stakeouts());
    await tester.pumpWidget(
      MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: const Scaffold(body: ChatWatchButton(id: 7)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notify me when online'));
    await tester.pumpAndSettle();
    expect(stakeouts.stakeouts.single.onlineEnabled, isTrue);
    expect(find.text('Watching'), findsWidgets);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(stakeouts.stakeouts, isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(stakeouts.stakeouts.single.onlineEnabled, isTrue);
  });
}
