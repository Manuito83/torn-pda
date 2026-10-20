import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  tearDown(() => ChatRooms.remote = const []);

  group('Remote Config rooms', () {
    test('valid entries keep label and color, the rest is dropped', () {
      final rooms = ChatRooms.parse('''[
        {"id": "club", "label": " Book club ", "color": "#1A2b3C"},
        {"id": "events", "label": "Events", "color": "red"},
        {"id": "club", "label": "Twice"},
        {"id": "faction", "label": "Mine"},
        {"id": "dm:4", "label": "Private"},
        {"id": "", "label": "Empty"},
        {"id": 7, "label": "Number"},
        {"id": "nolabel"},
        "loose",
        null
      ]''');
      expect(rooms.map((r) => (r.id, r.label)), [('club', 'Book club'), ('events', 'Events')]);
      expect(rooms.first.color, const Color(0xFF1A2B3C));
      expect(rooms.last.color, isNull);
    });
  });

  test('unknown room reported once', () async {
    final source = FakeChatSource();
    final prefs = ChatPrefs();
    final reported = <String>[];
    prefs.unknownRoomSink = reported.add;
    final chat = ChatController(source, prefs);
    addTearDown(chat.dispose);
    source.emit(const ChatReadyEvent(1));

    const rooms = ChatRoomsEvent([
      ChatRoom(id: 'faction', name: 'Faction'),
      ChatRoom(id: 'club', name: 'Club'),
      ChatRoom(id: 'mystery', name: 'Mystery'),
    ]);
    source.emit(rooms);
    expect(reported, isEmpty);

    prefs.setRemoteRooms('[{"id": "club", "label": "Book club"}]');
    source
      ..emit(rooms)
      ..emit(rooms);
    expect(reported, ['mystery']);

    final again = ChatPrefs();
    await again.load();
    final later = <String>[];
    again
      ..unknownRoomSink = later.add
      ..setRemoteRooms('[]')
      ..noteRooms(['mystery', 'club', 'other']);
    expect(later, ['club', 'other']);
  });

  group('live, frozen and hidden', () {
    test('saved frozen rooms load until unfrozen, hidden wins', () async {
      await Prefs().setNativeChatPausedRooms(['global|1000|', 'trade|1000|']);
      await Prefs().setNativeChatHiddenRooms(['trade']);
      final prefs = ChatPrefs();
      await prefs.load();
      expect(prefs.roomState('global'), ChatRoomState.frozen);
      expect(prefs.frozenUntilOf('global'), isNull);
      expect(prefs.roomState('trade'), ChatRoomState.hidden);
      expect(prefs.roomState('faction'), ChatRoomState.live);

      final saved = ChatFreeze.decode(await Prefs().getNativeChatPausedRooms());
      expect(saved.keys, ['global']);
      expect(saved['global']!.until, isNull);
    });

    test('frozen room behaviour', () async {
      final source = FakeChatSource();
      final prefs = ChatPrefs()
        ..browserWords = ['xanax']
        ..alertWords = {'xanax'}
        ..alertLevels = {'faction': ChatAlertLevel.all};
      final chat = ChatController(source, prefs);
      addTearDown(chat.dispose);
      final alerts = <ChatAlert>[];
      final sub = chat.alertStream.listen(alerts.add);
      addTearDown(sub.cancel);
      source.emit(const ChatReadyEvent(1, myName: 'Me'));

      prefs.setRoomState('faction', ChatRoomState.frozen, until: ChatMuteFor.eightHours.until(DateTime.now()));
      prefs.setRoomState('global', ChatRoomState.hidden);
      expect(source.calls.last, 'pause [faction, global]');
      expect(prefs.bubbleCounts({'faction': 2, 'company': 1, 'dm': 3}), {'company': 1, 'dm': 3});

      source.emit(ChatMessageEvent(chatMessage('1', 'faction', text: 'hey me', at: DateTime.now())));
      await Future<void>.delayed(Duration.zero);
      expect(alerts, isEmpty);

      final since = prefs.frozen['faction']!.since;
      prefs.setRoomState('faction', ChatRoomState.frozen);
      expect(prefs.frozen['faction']!.since, since);
      expect(prefs.frozenUntilOf('faction'), isNull);

      prefs.setRoomState('faction', ChatRoomState.live);
      expect(source.calls.last, 'pause [global]');
      final bar = chat.messagesFor('faction').singleWhere((m) => m.isLocal);
      expect(bar.createdAt, since);
      expect(bar.isSystem, isTrue);
      expect(bar.content, ChatFreeze.thawText(Duration.zero));

      source.emit(ChatMessageEvent(chatMessage('2', 'faction', text: 'hey me', at: DateTime.now())));
      await Future<void>.delayed(Duration.zero);
      expect(alerts.map((a) => a.message.id), ['2']);
    });
  });
}
