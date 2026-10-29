import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_inbox_snapshot.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';

import 'chat_fakes.dart';

ChatRoom _room(String id, [String? name]) => ChatRoom(id: id, name: name ?? id);

ChatRoom _dm(int id, String name) => ChatRoom(
  id: ChatRoom.dmId(id),
  name: name,
  type: ChatRoomType.dm,
  peer: ChatUser(id: id, name: name),
);

ChatMessage _msg(String room, int minutesAgo, {String name = 'Bravo'}) =>
    chatMessage('m-$room-$minutesAgo', room, name: name, at: chatNow.subtract(Duration(minutes: minutesAgo)));

ChatInboxSnapshot _saved() => ChatInboxSnapshot(
  owner: 99,
  rooms: [_dm(7, 'Bravo'), _room('global'), _room('faction'), _room('company'), _room('trade')],
  last: {'dm:7': _msg('dm:7', 1), 'global': _msg('global', 5), 'faction': _msg('faction', 60)},
  unread: {'dm:7': 3, 'faction': 2},
);

List<String> _ids(ChatController chat) => [for (final r in chat.conversations) r.id];

void _connect(FakeChatSource source, {List<ChatRoom> dms = const []}) => source
  ..emit(const ChatReadyEvent(99))
  ..emit(const ChatConnectionEvent(ChatConnection.connected))
  ..emit(ChatRoomsEvent([_room('faction'), _room('company'), _room('global'), _room('trade')]))
  ..emit(ChatDmsEvent(dms));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('saved list', () {
    test('round trip, other account ignored', () {
      final raw = _saved().encode();
      final back = ChatInboxSnapshot.decode(raw, 99)!;
      expect(back.order, ['dm:7', 'global', 'faction', 'company', 'trade']);
      expect(back.last['faction']!.createdAt, _saved().last['faction']!.createdAt);
      expect(back.rooms.first.peer!.name, 'Bravo');
      expect(back.unread, {'dm:7': 3, 'faction': 2});
      expect(ChatInboxSnapshot.decode(raw, 5), isNull);
      expect(ChatInboxSnapshot.decode('{broken', 99), isNull);
      expect(ChatInboxSnapshot.decode('', 99), isNull);
    });

    test('holdOrder keeps new rows in place', () {
      final sorted = [_room('c'), _room('new'), _room('a'), _room('b')];
      expect([for (final r in holdOrder(sorted, ['a', 'b', 'c'])) r.id], ['a', 'new', 'b', 'c']);
    });
  });

  group('opening cold', () {
    test('first paint uses the saved order, lines and counts', () {
      final chat = ChatController(FakeChatSource())..restoreInbox(_saved());
      expect(_ids(chat), ['dm:7', 'global', 'faction', 'company', 'trade']);
      expect(chat.lastMessageIn('faction')!.content, 'text m-faction-60');
      expect(chat.listUnreadFor('faction'), 2);
      expect(chat.listUnreadFor('dm:7'), 3);
      expect(chat.unreadFor('faction'), 0);
      expect(chat.unreadQueue, isEmpty);
      expect(chat.unreadGroups(), isEmpty);
      chat.dispose();
    });

    testWidgets('moves once after both batches', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      final seen = <List<String>>[];
      chat.addListener(() => seen.add(_ids(chat)));

      _connect(source, dms: [_dm(7, 'Bravo')]);
      source.emit(const ChatUnreadEvent({'faction': 4, 'dm:7': 3}));
      source.emit(ChatPeekEvent('faction', _msg('faction', 0, name: 'Alpha')));
      source.emit(ChatPeekEvent('global', _msg('global', 5)));
      expect(seen, isNotEmpty);
      expect(seen.every((o) => o.join(',') == 'dm:7,global,faction,company,trade'), isTrue);
      expect(chat.unreadFor('faction'), 4);
      expect(chat.lastMessageIn('faction')!.sender.name, 'Alpha');

      await tester.pump(const Duration(seconds: 1));
      expect(_ids(chat), ['faction', 'dm:7', 'global', 'company', 'trade']);
      final moves = <String>{for (final o in seen) o.join(',')};
      expect(moves.length, 2);
      chat.dispose();
    });

    testWidgets('nothing new means nothing moves', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      final seen = <String>{};
      chat.addListener(() => seen.add(_ids(chat).join(',')));
      _connect(source, dms: [_dm(7, 'Bravo')]);
      source
        ..emit(const ChatUnreadEvent({'faction': 2, 'dm:7': 3}))
        ..emit(ChatPeekEvent('faction', _msg('faction', 60)))
        ..emit(ChatPeekEvent('global', _msg('global', 5)));
      await tester.pump(const Duration(seconds: 1));
      expect(seen, {'dm:7,global,faction,company,trade'});
      chat.dispose();
    });

    test('a saved count is replaced in place by the real one', () {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      _connect(source);
      expect(chat.listUnreadFor('faction'), 2);
      source.emit(const ChatUnreadEvent({'dm:7': 1}));
      expect(chat.listUnreadFor('faction'), 0);
      expect(chat.listUnreadFor('dm:7'), 1);
      chat.dispose();
    });

    test('an older real last line replaces the saved one', () {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      _connect(source);
      source.emit(ChatPeekEvent('faction', _msg('faction', 120, name: 'Alpha')));
      expect(chat.lastMessageIn('faction')!.sender.name, 'Alpha');
      source.emit(ChatPeekEvent('faction', _msg('faction', 200)));
      expect(chat.lastMessageIn('faction')!.sender.name, 'Alpha');
      chat.dispose();
    });

    testWidgets('releases the order without answers', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      source.emit(ChatPeekEvent('faction', _msg('faction', 0)));
      expect(_ids(chat).first, 'dm:7');
      await tester.pump(const Duration(seconds: 9));
      expect(_ids(chat).first, 'faction');
      chat.dispose();
    });

    testWidgets('late answers after opening move the list once', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      final seen = <String>{};
      _connect(source, dms: [_dm(7, 'Bravo')]);
      source.emit(const ChatUnreadEvent({'faction': 2, 'dm:7': 3}));
      await tester.pump(const Duration(seconds: 1));
      expect(_ids(chat).first, 'dm:7');

      chat
        ..addListener(() => seen.add(_ids(chat).join(',')))
        ..attach();
      source.emit(ChatPeekEvent('global', _msg('global', 5)));
      source.emit(ChatPeekEvent('company', _msg('company', 90)));
      await tester.pump(const Duration(milliseconds: 900));
      expect(_ids(chat), ['dm:7', 'global', 'faction', 'company', 'trade']);

      source.emit(ChatPeekEvent('faction', _msg('faction', 0, name: 'Alpha')));
      source.emit(ChatPeekEvent('trade', _msg('trade', 200)));
      expect(_ids(chat).first, 'dm:7');
      await tester.pump(const Duration(seconds: 1));
      expect(_ids(chat), ['faction', 'dm:7', 'global', 'company', 'trade']);
      expect(seen, {'dm:7,global,faction,company,trade', 'faction,dm:7,global,company,trade'});
      chat.dispose();
    });

    testWidgets('an unanswered line does not hold the list for long', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      _connect(source, dms: [_dm(7, 'Bravo')]);
      source.emit(const ChatUnreadEvent({'faction': 2}));
      await tester.pump(const Duration(seconds: 1));
      chat.attach();
      source.emit(ChatPeekEvent('faction', _msg('faction', 0)));
      await tester.pump(const Duration(seconds: 2));
      expect(_ids(chat).first, 'dm:7');
      await tester.pump(const Duration(seconds: 2));
      expect(_ids(chat).first, 'faction');
      chat.dispose();
    });

    testWidgets('a live message does not wait for the late lines', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source)..restoreInbox(_saved());
      _connect(source, dms: [_dm(7, 'Bravo')]);
      source.emit(const ChatUnreadEvent({'faction': 2}));
      await tester.pump(const Duration(seconds: 1));
      chat.attach();
      source.emit(ChatPeekEvent('global', _msg('global', 5)));
      expect(_ids(chat).first, 'dm:7');
      source.emit(ChatMessageEvent(_msg('company', -1, name: 'Alpha')));
      expect(_ids(chat), ['company', 'dm:7', 'global', 'faction', 'trade']);

      source.emit(ChatPeekEvent('faction', _msg('faction', 0)));
      expect(_ids(chat), ['company', 'dm:7', 'global', 'faction', 'trade']);
      await tester.pump(const Duration(seconds: 4));
      expect(_ids(chat), ['company', 'faction', 'dm:7', 'global', 'trade']);
      chat.dispose();
    });

    test('another account on a cold start drops the list', () {
      final source = FakeChatSource();
      final stored = <String>[];
      final chat = ChatController(source)
        ..onInboxChanged = stored.add
        ..restoreUserId(99)
        ..restoreInbox(_saved());
      source.emit(const ChatReadyEvent(100));
      expect(_ids(chat), isNot(contains('dm:7')));
      expect(chat.listUnreadFor('faction'), 0);
      expect(chat.lastMessageIn('faction'), isNull);
      expect(stored, ['']);
      chat.dispose();
    });

    test('the same account on a cold start keeps the list', () {
      final source = FakeChatSource();
      final chat = ChatController(source)
        ..restoreUserId(99)
        ..restoreInbox(_saved());
      source.emit(const ChatReadyEvent(99));
      expect(_ids(chat), contains('dm:7'));
      expect(chat.listUnreadFor('faction'), 2);
      chat.dispose();
    });
  });

  group('storing the list', () {
    testWidgets('writes after a quiet spell and only when it changed', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source);
      final stored = <String>[];
      chat.onInboxChanged = stored.add;
      _connect(source, dms: [_dm(7, 'Bravo')]);
      source.emit(ChatPeekEvent('dm:7', _msg('dm:7', 1)));
      expect(stored, isEmpty);
      source.emit(const ChatUnreadEvent({'faction': 2}));
      source.emit(ChatPeekEvent('faction', _msg('faction', 30)));
      await tester.pump(const Duration(seconds: 4));
      expect(stored, isEmpty);
      await tester.pump(const Duration(seconds: 30));
      expect(stored, hasLength(1));
      final back = ChatInboxSnapshot.decode(stored.single, 99)!;
      expect(back.order.take(2), ['dm:7', 'faction']);
      expect(back.unread, {'faction': 2});

      chat.saveInbox();
      expect(stored, hasLength(1));
      source.emit(ChatPeekEvent('faction', _msg('faction', 0, name: 'Alpha')));
      chat.detach();
      expect(stored, hasLength(2));
      chat.dispose();
    });

    test('keeps only what the row shows', () {
      final long = ChatMessage(
        id: 'x',
        roomId: 'dm:7',
        sender: const ChatUser(id: 7, name: 'Bravo'),
        content: 'a' * 300,
        createdAt: chatNow,
      );
      final saved = ChatInboxSnapshot(owner: 99, rooms: [_dm(7, 'Bravo')], last: {'dm:7': long}, unread: {});
      final back = ChatInboxSnapshot.decode(saved.encode(), 99)!;
      expect(back.last['dm:7']!.content.length, 80);
    });
  });
}
