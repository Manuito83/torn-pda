import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  late FakeChatSource source;
  late ChatController chat;

  setUp(() {
    source = FakeChatSource();
    chat = ChatController(source, ChatPrefs());
    source.emit(const ChatReadyEvent(1, myName: 'Me'));
  });

  tearDown(() => chat.dispose());

  test('counts and messages hold still, then catch up', () {
    source.emit(const ChatUnreadEvent({'dm:7': 2}));
    source.emit(ChatMessageEvent(chatMessage('a', 'dm:7', sender: 7), unread: 2));
    chat.setFrozen(true);

    source.emit(ChatMessageEvent(chatMessage('b', 'dm:7', sender: 7), unread: 3));
    source.emit(const ChatUnreadEvent({'dm:7': 3, 'faction': 4}));
    expect(chat.unreadFor('dm:7'), 2);
    expect(chat.unreadFor('faction'), 0);
    expect(chat.unreadGroups(), {'dm': 2});
    expect(chat.messagesFor('dm:7').map((m) => m.id), ['a']);

    chat.setFrozen(false);
    expect(chat.unreadFor('dm:7'), 3);
    expect(chat.unreadFor('faction'), 4);
    expect(chat.messagesFor('dm:7').map((m) => m.id), ['a', 'b']);
  });

  test('past the cap counters stay still and the room reloads on release', () {
    source.emit(const ChatUnreadEvent({'dm:7': 1}));
    source.emit(ChatHistoryEvent('dm:7', [chatMessage('a', 'dm:7', sender: 7)], hasOlder: false, isOlderPage: false));
    chat.setFrozen(true);
    for (var i = 0; i < 3001; i++) {
      source.emit(ChatMessageEvent(chatMessage('m$i', 'dm:7', sender: 7), unread: 2));
    }
    source.emit(const ChatUnreadEvent({'dm:7': 9}));
    expect(chat.unreadFor('dm:7'), 1);
    expect(chat.messagesFor('dm:7').map((m) => m.id), ['a']);

    source.calls.clear();
    chat.setFrozen(false);
    expect(chat.isLoaded('dm:7'), isFalse);
    expect(source.count('refreshUnread'), 1);
    chat.setFrozen(true);
    source.emit(const ChatUnreadEvent({'dm:7': 5}));
    expect(chat.unreadFor('dm:7'), 1);
  });

  test('held events keep their order', () {
    chat.setFrozen(true);
    source.emit(ChatMessageEvent(chatMessage('a', 'faction')));
    source.emit(const ChatMessageDeletedEvent('faction', 'a'));
    source.emit(ChatMessageEvent(chatMessage('b', 'faction')));
    chat.setFrozen(false);
    expect(chat.messagesFor('faction').map((m) => m.id), ['b']);
  });

  test('connection changes still show while frozen', () {
    chat.setFrozen(true);
    source.emit(const ChatConnectionEvent(ChatConnection.noSession));
    expect(chat.connection, ChatConnection.noSession);
  });

  test('alerts for held messages stay silent on release', () async {
    final alerts = <String>[];
    final sub = chat.alertStream.listen((a) => alerts.add(a.message.id));
    addTearDown(sub.cancel);

    source.emit(ChatMessageEvent(chatMessage('live', 'dm:7', sender: 7)));
    chat.setFrozen(true);
    source.emit(ChatMessageEvent(chatMessage('held', 'dm:7', sender: 7)));
    chat.setFrozen(false);
    await Future<void>.delayed(Duration.zero);
    expect(alerts, ['live']);
    expect(chat.messagesFor('dm:7').map((m) => m.id), ['live', 'held']);
  });

  test('another account drops what was held', () {
    chat.setFrozen(true);
    source.emit(ChatMessageEvent(chatMessage('old', 'faction')));
    source.emit(const ChatReadyEvent(2, myName: 'Other'));
    chat.setFrozen(false);
    expect(chat.messagesFor('faction'), isEmpty);
  });
}
