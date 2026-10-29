import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_saved.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_events.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

import 'chat_fakes.dart';

class _OfflineSource extends FakeChatSource {
  @override
  bool get available => false;
}

void main() {
  useTempPathProvider();

  late FakeChatSource source;
  late ChatPrefs prefs;
  late ChatController chat;

  const dm = ChatRoom(id: 'dm:7', name: 'Charlie', type: ChatRoomType.dm);
  const dm8 = ChatRoom(id: 'dm:8', name: 'Delta', type: ChatRoomType.dm);
  const faction = ChatRoom(id: 'faction', name: 'Faction');
  const poker = ChatRoom(id: 'poker', name: 'Poker', icon: 'casino');

  ChatMessage at(String id, String roomId, int minute, {int sender = 2}) => chatMessage(
    id,
    roomId,
    sender: sender,
    at: chatNow.add(Duration(minutes: minute)),
  );

  void page(String roomId, List<int> minutes, {bool hasOlder = true, bool older = false}) => source.emit(
    ChatHistoryEvent(
      roomId,
      [for (final m in minutes) at('$roomId-$m', roomId, m)],
      hasOlder: hasOlder,
      isOlderPage: older,
    ),
  );

  void load(String roomId, List<ChatMessage> list) =>
      source.emit(ChatHistoryEvent(roomId, list, hasOlder: false, isOlderPage: false));

  List<int> minutesIn(String roomId) => [
    for (final m in chat.messagesFor(roomId)) m.createdAt.difference(chatNow).inMinutes,
  ];

  ChatMessage ago(String id, String roomId, int sender, Duration age) =>
      chatMessage(id, roomId, sender: sender, at: DateTime.now().subtract(age));

  setUp(() {
    source = FakeChatSource();
    prefs = ChatPrefs();
    chat = ChatController(source, prefs);
    source.emit(const ChatReadyEvent(1, myName: 'Me'));
  });

  tearDown(() => chat.dispose());

  test('dm title falls back to sender', () {
    expect(chat.roomById('dm:7').name, 'Private chat');
    chat.noteSender('dm:7', 'Charlie');
    expect(chat.roomById('dm:7').name, 'Charlie');
    source.emit(const ChatDmsEvent([ChatRoom(id: 'dm:7', name: 'Charles', type: ChatRoomType.dm)]));
    expect(chat.roomById('dm:7').name, 'Charles');
  });

  group('session', () {
    test('a lost session keeps the chat, another account wipes it', () {
      chat.openConversation('faction');
      page('faction', [1, 2]);
      source.emit(const ChatConnectionEvent(ChatConnection.needsBrowser));
      expect(chat.ready, isFalse);
      expect(chat.myUserId, 1);
      expect(chat.messagesFor('faction'), hasLength(2));
      expect(chat.currentRoomId, 'faction');

      source.emit(const ChatReadyEvent(1));
      expect(chat.ready, isTrue);
      expect(chat.messagesFor('faction'), hasLength(2));

      source.emit(const ChatReadyEvent(9));
      expect(chat.myUserId, isNull);
      expect(chat.messagesFor('faction'), isEmpty);
      expect(chat.currentRoomId, isNull);
      expect(chat.filteredMessagesFor('faction'), isEmpty);
    });

    test('starting lasts until the session is known', () {
      final fresh = FakeChatSource();
      final controllers = <ChatController>[];
      ChatController make([FakeChatSource? s]) {
        final c = ChatController(s ?? fresh, ChatPrefs());
        controllers.add(c);
        return c;
      }

      final connecting = make();
      expect(connecting.starting, isTrue);
      fresh.emit(const ChatConnectionEvent(ChatConnection.connecting));
      expect(connecting.starting, isTrue);
      fresh.emit(const ChatConnectionEvent(ChatConnection.connected));
      expect(connecting.starting, isFalse);

      for (final event in [
        const ChatConnectionEvent(ChatConnection.noSession),
        const ChatConnectionEvent(ChatConnection.error),
        const ChatReadyEvent(1),
      ]) {
        final other = make();
        fresh.emit(event);
        expect(other.starting, isFalse);
      }
      expect(make(_OfflineSource()).starting, isFalse);
      for (final c in controllers) {
        c.dispose();
      }
    });

    test('reconnection asks the unread once', () {
      chat.openConversation('faction');
      page('faction', [1]);
      source.calls.clear();
      source.emit(const ChatConnectionEvent(ChatConnection.connected, reconnected: true));
      expect(source.calls, ['refreshUnread']);
    });

    testWidgets('a room caught by a drop asks again, a failed one each minute', (tester) async {
      final torn = FakeChatSource();
      final c = ChatController(torn, ChatPrefs());
      torn
        ..emit(const ChatConnectionEvent(ChatConnection.connected))
        ..emit(const ChatReadyEvent(1));
      c.openConversation('faction');
      torn
        ..emit(const ChatConnectionEvent(ChatConnection.disconnected))
        ..emit(const ChatConnectionEvent(ChatConnection.connected, reconnected: true));
      expect(torn.count('openRoom'), 2);

      await tester.pump(const Duration(seconds: 21));
      expect(c.openFailed('faction'), isTrue);
      await tester.pump(const Duration(seconds: 40));
      expect(torn.count('openRoom'), 3);
      expect(c.openFailed('faction'), isTrue);

      torn.emit(const ChatHistoryEvent('faction', [], hasOlder: false, isOlderPage: false));
      await tester.pump(const Duration(seconds: 60));
      expect(torn.count('openRoom'), 3);
      expect(c.openFailed('faction'), isFalse);
      c.dispose();
    });

    testWidgets('only the last room opened can fail to load', (tester) async {
      final torn = FakeChatSource();
      final c = ChatController(torn, ChatPrefs());
      torn
        ..emit(const ChatConnectionEvent(ChatConnection.connected))
        ..emit(const ChatReadyEvent(1));
      c.peekRoom('faction');
      c.peekRoom('global');

      await tester.pump(const Duration(seconds: 21));
      expect(c.openFailed('faction'), isFalse);
      expect(c.openFailed('global'), isTrue);
      c.dispose();
    });

    testWidgets('a window left waiting loads again when asked', (tester) async {
      final torn = FakeChatSource();
      final c = ChatController(torn, ChatPrefs());
      torn
        ..emit(const ChatConnectionEvent(ChatConnection.connected))
        ..emit(const ChatReadyEvent(1));
      c.openConversation('faction');
      c.openConversation('global');
      expect((c.opening('faction'), c.opening('global')), (false, true));

      await tester.pump(const Duration(seconds: 21));
      expect(c.openFailed('faction'), isFalse);
      c.openConversation('faction');
      expect(c.opening('faction'), isTrue);
      await tester.pump(const Duration(seconds: 21));
      expect(c.openFailed('faction'), isTrue);
      c.dispose();
    });

    test('forgetAccount clears personal data', () {
      final message = chatMessage('a', 'dm:7');
      prefs
        ..drafts = {'faction': 'half typed'}
        ..savedMessages = [ChatSaved.of(message, 'Bravo')]
        ..playerNotes = {7: 'note'}
        ..pinnedMessages = {'dm:7': ChatSaved.of(message, 'Bravo')}
        ..pinned = ['faction', 'dm:7']
        ..shortcutCache = ['dm:7|Bravo']
        ..windows = ['dm:7']
        ..ignored = {3: 'Echo'};
      prefs.forgetAccount();
      expect(prefs.drafts, isEmpty);
      expect(prefs.savedMessages, isEmpty);
      expect(prefs.playerNotes, isEmpty);
      expect(prefs.pinnedMessages, isEmpty);
      expect(prefs.pinned, ['faction']);
      expect(prefs.shortcutCache, isEmpty);
      expect(prefs.windows, isEmpty);
      expect(prefs.ignored, {3: 'Echo'});
    });

    test('faction news of the last account never come back', () async {
      prefs.factionEvents = true;
      final news = FactionNewsResponse(
        news: [
          FactionNews(id: '1', text: 'A player joined the faction', timestamp: chatNow.millisecondsSinceEpoch ~/ 1000),
        ],
        metadata: const RequestMetadataWithLinks(links: RequestLinks(next: null, prev: null)),
      );
      final events = ChatFactionEvents(chat, prefs, fetch: () async => news, clock: () => chatNow);
      chat.openConversation('faction');
      events.sync();
      await Future<void>.delayed(Duration.zero);
      expect(chat.messagesFor('faction').where(isChatFactionEvent), hasLength(1));

      source
        ..emit(const ChatReadyEvent(9))
        ..emit(const ChatReadyEvent(9));
      chat.openConversation('faction');
      page('faction', [1]);
      events.sync();
      expect(chat.messagesFor('faction').where(isChatFactionEvent), isEmpty);
    });
  });

  group('history', () {
    test('a fresh recent page keeps older history it joins', () {
      chat.openConversation('faction');
      page('faction', [10, 11, 12]);
      page('faction', [7, 8, 9], older: true);
      page('faction', [11, 12, 13], hasOlder: false);
      expect(minutesIn('faction'), [7, 8, 9, 10, 11, 12, 13]);
      expect(chat.hasOlder('faction'), isTrue);

      page('faction', [30, 31]);
      expect(minutesIn('faction'), [30, 31]);
    });

    test('a failed older page lets the next one load', () async {
      chat.openConversation('faction');
      page('faction', [10, 11]);
      source.olderError = Exception('page gone');
      await expectLater(chat.loadOlder(), throwsException);
      expect(chat.loadingOlder, isFalse);
      source.olderError = null;
      await chat.loadOlder();
      expect(source.count('loadOlder'), 2);
    });

    test('live message keeps history', () {
      final start = DateTime.now().subtract(const Duration(hours: 2));
      ChatMessage line(int i) => chatMessage('m$i', 'global', at: start.add(Duration(seconds: i)));
      source.emit(
        ChatHistoryEvent('global', [for (var i = 0; i < 1500; i++) line(i)], hasOlder: true, isOlderPage: false),
      );
      chat.openConversation('global');
      source.emit(ChatMessageEvent(line(1500)));
      expect(chat.messagesFor('global').length, 1501);
      expect(chat.messagesFor('global').first.id, 'm0');

      chat.closeConversation('global');
      source.emit(ChatMessageEvent(line(1501)));
      expect(chat.messagesFor('global').length, 1000);
      expect(chat.messagesFor('global').last.id, 'm1501');
    });

    test('ending a search leaves a newer one alone', () {
      chat.search('alpha');
      chat.search('bravo');
      chat.endSearch('alpha');
      expect(chat.searchQuery, 'bravo');
      source.emit(const ChatSearchEvent('bravo', [ChatUser(id: 5, name: 'Bravo')]));
      expect(chat.searchResults!.single.name, 'Bravo');
      chat.endSearch(' bravo ');
      expect(chat.searchQuery, isNull);
    });
  });

  group('unread', () {
    test('markAllRead per room fallback', () {
      source.emit(const ChatUnreadEvent({'faction': 2, 'dm:7': 1}));
      source.calls.clear();
      expect(chat.markAllRead(), 2);
      expect(source.calls, ['markAllRead']);
      expect(chat.unreadFor('faction'), 0);

      source.emit(const ChatUnreadEvent({'faction': 2, 'dm:7': 1, 'global': 5}));
      source.calls.clear();
      expect(chat.markAllRead(), 2);
      expect(source.calls, ['markRead faction', 'markRead dm:7']);
      expect(chat.unreadFor('global'), 5);

      prefs.hiddenRooms = {'company'};
      source.emit(const ChatUnreadEvent({'faction': 2, 'company': 3}));
      source.calls.clear();
      expect(chat.markAllRead(), 1);
      expect(source.calls, ['markRead faction']);
      expect(chat.unreadFor('company'), 3);
    });

    test('peeked rooms are released one by one', () {
      source.emit(const ChatUnreadEvent({'faction': 2, 'company': 1}));
      source.calls.clear();
      chat.peekRoom('faction');
      chat.peekRoom('company');
      expect(chat.unreadGroups(), isEmpty);

      chat.unpeekRoom('faction');
      expect(source.calls.last, 'openRoom company');
      source.emit(ChatMessageEvent(at('f1', 'faction', 1), unread: 1));
      source.emit(ChatMessageEvent(at('c1', 'company', 1), unread: 1));
      expect(chat.unreadFor('faction'), 1);
      expect(chat.unreadFor('company'), 0);

      chat.unpeekRoom('company');
      expect(source.calls.last, 'closeRoom');
    });

    test('marked unread counts until the chat is opened', () {
      source.emit(const ChatDmsEvent([dm]));
      expect(chat.canMarkUnread('global'), isFalse);
      expect(chat.canMarkUnread('trade'), isFalse);
      expect(chat.canMarkUnread('dm:7'), isTrue);
      chat.markUnread('dm:7');
      expect(chat.unreadFor('dm:7'), 1);
      expect(chat.unreadGroups(), {'dm': 1});
      expect(chat.canMarkUnread('dm:7'), isFalse);
      expect(chat.readable, ['dm:7']);
      chat.openConversation('dm:7');
      expect(chat.unreadFor('dm:7'), 0);
      chat.closeConversation('dm:7');
      expect(chat.unreadFor('dm:7'), 0);
    });

    test('marked unread survives a read event', () {
      source.emit(const ChatDmsEvent([dm]));
      chat.markUnread('dm:7');
      source.emit(const ChatUnreadEvent({'dm:7': 0}));
      expect(chat.unreadFor('dm:7'), 1);
      chat.markRead('dm:7');
      expect(chat.unreadFor('dm:7'), 0);
      expect(chat.canMarkRead('dm:7'), isFalse);
    });

    test('rooms Torn never marks read stay out of the counts', () {
      source.emit(const ChatUnreadEvent({'poker': 40, 'global': 120, 'faction': 2}));
      expect(chat.tornMarksRead('faction'), isTrue);
      for (final id in ['poker', 'global']) {
        expect(chat.tornMarksRead(id), isFalse);
      }
      expect(chat.countsInBadge('poker'), isFalse);
      expect(chat.canMarkRead('poker'), isFalse);
    });

    test('Global counts as new only until visited', () {
      source.emit(const ChatUnreadEvent({'global': 120}));
      page('global', [1, 2]);
      expect(chat.newSinceVisit('global'), isTrue);
      chat.openConversation('global');
      chat.closeConversation('global');
      expect(chat.newSinceVisit('global'), isFalse);
      source.emit(ChatMessageEvent(at('late', 'global', 5), unread: 121));
      expect(chat.newSinceVisit('global'), isTrue);
    });

    test('Global counts messages since the last visit', () {
      chat.openConversation('global');
      page('global', [1, 2, 3]);
      chat.closeConversation('global');
      expect(chat.unreadShown('global'), (0, false));
      source.emit(ChatMessageEvent(at('a', 'global', 5)));
      source.emit(ChatMessageEvent(at('mine', 'global', 6, sender: 1)));
      source.emit(
        ChatMessageEvent(
          ChatMessage(
            id: 'sys',
            roomId: 'global',
            sender: const ChatUser(id: 0, name: 'Torn'),
            content: 'joined',
            createdAt: chatNow.add(const Duration(minutes: 7)),
            isSystem: true,
          ),
        ),
      );
      source.emit(ChatMessageEvent(at('b', 'global', 8)));
      expect(chat.unreadShown('global'), (2, false));
      expect(chat.unreadGroups()['global'], 2);
      chat.openConversation('global');
      expect(chat.unreadShown('global'), (0, false));
    });

    test('Global gets a plus with older history not loaded', () {
      chat.openConversation('global');
      page('global', [1, 2, 3]);
      chat.closeConversation('global');
      source.emit(ChatHistoryEvent('global', [at('n', 'global', 30)], hasOlder: true, isOlderPage: false));
      expect(chat.unreadShown('global'), (1, true));
    });

    test('unread queue order and exclusions', () {
      prefs
        ..pinned = ['company']
        ..muted = {'faction'}
        ..mutedUnread = false;
      source.emit(const ChatUnreadEvent({'faction': 2, 'company': 1, 'trade': 4, 'global': 3}));
      expect([for (final r in chat.unreadQueue) r.id], ['company']);
      prefs.mutedUnread = true;
      expect([for (final r in chat.unreadQueue) r.id], ['company', 'faction']);
      chat.openConversation('company');
      expect([for (final r in chat.unreadQueue) r.id], ['faction']);
      prefs.hiddenRooms = {'faction'};
      expect(chat.unreadQueue, isEmpty);
    });

    test('landing time only while traveling with the flight ahead', () {
      int secs(Duration d) => chatNow.add(d).millisecondsSinceEpoch ~/ 1000;
      BarsStatusCooldownsModel bars(String state, int stamp) => BarsStatusCooldownsModel(
        status: Status(state: state),
        travel: Travel(timestamp: stamp),
      );
      final landing = secs(const Duration(hours: 2));
      expect(chatLandingTime(bars('Traveling', landing), chatNow), DateTime.fromMillisecondsSinceEpoch(landing * 1000));
      expect(chatLandingTime(bars('Traveling', secs(const Duration(minutes: -1))), chatNow), isNull);
      expect(chatLandingTime(bars('Okay', landing), chatNow), isNull);
      expect(chatLandingTime(bars('Hospital', landing), chatNow), isNull);
      expect(chatLandingTime(null, chatNow), isNull);
    });
  });

  group('private chats', () {
    test('waiting lists unanswered private chats past the threshold', () {
      source.emit(const ChatDmsEvent([dm, dm8]));
      load('dm:7', [ago('a', 'dm:7', 7, const Duration(hours: 4))]);
      load('dm:8', [ago('b', 'dm:8', 8, const Duration(hours: 1))]);
      expect(chat.waitingDms().map((w) => w.$1.id), ['dm:7']);
      load('dm:7', [ago('a', 'dm:7', 7, const Duration(hours: 4)), ago('c', 'dm:7', 1, const Duration(hours: 3))]);
      expect(chat.waitingDms(), isEmpty);

      load('dm:8', [ago('b', 'dm:8', 8, const Duration(days: 8))]);
      expect(chat.waitingDms(), isEmpty);
      load('dm:8', [ago('d', 'dm:8', 8, const Duration(hours: 5))]);
      expect(chat.waitingDms(), hasLength(1));
      prefs.setWaitingHours(0);
      expect(chat.waitingDms(), isEmpty);
    });

    test('waiting chat returns on new message', () {
      source.emit(const ChatDmsEvent([dm, dm8]));
      final old = DateTime.now().subtract(const Duration(hours: 4));
      final first = chatMessage('a', 'dm:7', sender: 7, at: old);
      load('dm:7', [first]);
      load('dm:8', [chatMessage('b', 'dm:8', sender: 8, at: old)]);
      chat.openConversation('dm:7');
      chat.closeConversation('dm:7');
      expect(chat.waitingDms().map((w) => w.$1.id), ['dm:8']);
      chat.dismissWaiting('dm:8');
      expect(chat.waitingDms(), isEmpty);

      load('dm:7', [first, chatMessage('c', 'dm:7', sender: 7, at: old.add(const Duration(minutes: 5)))]);
      expect(chat.waitingDms().map((w) => w.$1.id), ['dm:7']);
      chat.dismissWaiting();
      expect(chat.waitingDms(), isEmpty);
    });

    test('dismissal survives a restart', () {
      final old = DateTime.now().subtract(const Duration(hours: 4));
      source.emit(const ChatDmsEvent([dm]));
      load('dm:7', [chatMessage('m1', 'dm:7', sender: 7, at: old)]);
      chat.dismissWaiting('dm:7');

      final next = FakeChatSource();
      final restarted = ChatController(next, prefs);
      next.emit(
        ChatDmsEvent([
          ChatRoom(
            id: 'dm:7',
            name: 'Charlie',
            type: ChatRoomType.dm,
            lastMessage: chatMessage('last-dm:7', 'dm:7', sender: 7, at: old),
          ),
        ]),
      );
      expect(restarted.waitingDms(), isEmpty);

      next.emit(ChatMessageEvent(chatMessage('m2', 'dm:7', sender: 7, at: old.add(const Duration(minutes: 5)))));
      expect(restarted.waitingDms().map((w) => w.$1.id), ['dm:7']);
      restarted.dispose();
    });

    test('own last message never waits', () {
      final next = FakeChatSource();
      final cold = ChatController(next, prefs)..restoreUserId(1);
      final old = DateTime.now().subtract(const Duration(hours: 4));
      next.emit(
        ChatDmsEvent([
          ChatRoom(
            id: 'dm:7',
            name: 'Charlie',
            type: ChatRoomType.dm,
            lastMessage: chatMessage('x', 'dm:7', sender: 1, at: old),
          ),
          ChatRoom(
            id: 'dm:8',
            name: 'Delta',
            type: ChatRoomType.dm,
            lastMessage: chatMessage('y', 'dm:8', sender: 8, at: old),
          ),
        ]),
      );
      expect(cold.ready, isFalse);
      expect(cold.waitingDms().map((w) => w.$1.id), ['dm:8']);
      cold.dispose();
    });

    test('archived dm leaves unread counts', () {
      source
        ..emit(const ChatDmsEvent([dm]))
        ..emit(const ChatUnreadEvent({'dm:7': 2}));
      expect(chat.unreadGroups()['dm'], 2);
      prefs.setPinned('dm:7', true);
      prefs.setArchived('dm:7', true);
      expect(chat.unreadFor('dm:7'), 0);
      expect(chat.unreadGroups(), isEmpty);
      expect(chat.readable, isEmpty);
      expect(chat.unreadQueue, isEmpty);
      expect(chat.archivedDms.map((r) => r.id), ['dm:7']);
      expect(prefs.isPinned('dm:7'), isFalse);
      expect(source.count('closeDm'), 0);

      prefs.setArchived('dm:7', false);
      expect(chat.unreadFor('dm:7'), 2);
      expect(chat.archivedDms, isEmpty);
    });

    test('incoming message unarchives', () {
      source
        ..emit(const ChatDmsEvent([dm]))
        ..emit(const ChatUnreadEvent({'dm:7': 2}));
      prefs.setArchived('dm:7', true);
      source.emit(ChatMessageEvent(chatMessage('m1', 'dm:7', sender: 1)));
      expect(prefs.isArchived('dm:7'), isTrue);

      source.emit(ChatMessageEvent(chatMessage('m2', 'dm:7', sender: 7), unread: 3));
      expect(prefs.isArchived('dm:7'), isFalse);
      expect(chat.archivedDms, isEmpty);
      expect(chat.unreadFor('dm:7'), 3);
    });
  });

  group('rooms that come and go', () {
    test('dropped room announced once', () async {
      final gone = <String>[];
      chat.goneStream.listen((r) => gone.add(r.id));
      expect(chat.isUnlisted('poker'), isFalse);
      source.emit(const ChatRoomsEvent([faction, poker]));
      expect(chat.isUnlisted('poker'), isFalse);
      prefs.alertLevels['poker'] = ChatAlertLevel.all;
      prefs.globalsPlacement = ChatGlobalsPlacement.top;
      source
        ..emit(const ChatRoomsEvent([faction]))
        ..emit(const ChatRoomsEvent([faction]));
      await Future<void>.delayed(Duration.zero);
      expect(gone, ['poker']);
      expect(chat.isUnlisted('poker'), isTrue);
      expect(chat.isUnlisted('dm:5'), isFalse);
      expect(chat.rooms.map((r) => r.id), ['faction']);

      source.emit(const ChatRoomsEvent([faction, poker]));
      expect(chat.isUnlisted('poker'), isFalse);
      expect(prefs.alertLevel('poker'), ChatAlertLevel.all);
      expect(prefs.placementOf('poker'), ChatGlobalsPlacement.top);
    });

    test('rooms absent from the first list are not announced', () async {
      final gone = <String>[];
      chat.goneStream.listen((r) => gone.add(r.id));
      source.emit(const ChatRoomsEvent([faction]));
      await Future<void>.delayed(Duration.zero);
      expect(gone, isEmpty);
      expect(chat.isUnlisted('company'), isTrue);
    });
  });
}
