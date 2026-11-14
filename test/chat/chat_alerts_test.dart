import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_person.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  late FakeChatSource source;
  late ChatPrefs prefs;
  late ChatController chat;

  setUp(() {
    source = FakeChatSource();
    prefs = ChatPrefs();
    chat = ChatController(source, prefs);
    source.emit(const ChatReadyEvent(1, myName: 'Me'));
  });

  tearDown(() => chat.dispose());

  group('matching', () {
    test('name matches as a whole word, with or without @', () {
      final matcher = ChatAlertMatcher(name: 'Bravo');
      for (final text in ['hey @bravo look', 'BRAVO, there?', 'ask bravo.', '**Bravo**', '(@bravo)', 'gg\n@bravo']) {
        expect(matcher.match(text)?.mention, isTrue, reason: text);
      }
      for (final text in ['bravos are here', 'xbravo', '@xbravo', 'bravo_2 said', 'Bravo2', 'nothing here']) {
        expect(matcher.match(text), isNull, reason: text);
      }
      expect(ChatAlertMatcher(name: 'Echo-Bay').match('hi echo-bay!')?.mention, isTrue);
      expect(ChatAlertMatcher(name: 'Echo-Bay').match('hi echo-bayside'), isNull);
      expect(ChatAlertMatcher(name: 'Zoé').match('zoé ven')?.mention, isTrue);
      expect(ChatAlertMatcher(name: 'Zoé').match('zoéa ven'), isNull);
    });

    test('highlight words match whole words, first one wins', () {
      final matcher = ChatAlertMatcher(keywords: ['Xanax', ' RW ', '[TAG]', '']);
      expect(matcher.match('selling xanax cheap')?.keyword, 'Xanax');
      expect(matcher.match('selling xanaxes'), isNull);
      expect(matcher.match('rw starts soon')?.keyword, 'RW');
      expect(matcher.match('brw'), isNull);
      expect(matcher.match('join [tag] now')?.keyword, '[TAG]');
      final both = ChatAlertMatcher(name: 'Bravo', keywords: ['rw']).match('Bravo, RW now');
      expect(both?.mention, isTrue);
      expect(both?.keyword, 'rw');
      expect(ChatAlertMatcher().isEmpty, isTrue);
      expect(ChatAlertMatcher(name: '  ').isEmpty, isTrue);
    });

    test('alert levels and mute', () {
      const mention = ChatMatch(mention: true);
      const word = ChatMatch(keyword: 'rw');
      for (final (level, muted, match, expected) in [
        (ChatAlertLevel.all, false, null, true),
        (ChatAlertLevel.all, false, mention, true),
        (ChatAlertLevel.all, false, word, true),
        (ChatAlertLevel.all, true, mention, false),
        (ChatAlertLevel.all, true, null, false),
        (ChatAlertLevel.mentions, false, null, false),
        (ChatAlertLevel.mentions, false, mention, true),
        (ChatAlertLevel.mentions, false, word, false),
        (ChatAlertLevel.mentions, true, mention, true),
        (ChatAlertLevel.mentions, true, null, false),
        (ChatAlertLevel.mentions, true, word, false),
        (ChatAlertLevel.none, false, mention, false),
        (ChatAlertLevel.none, true, mention, false),
      ]) {
        expect(
          ChatAlertMatcher.shouldAlert(level, muted: muted, match: match),
          expected,
          reason: '$level $muted $match',
        );
      }
    });

    test('the controller keeps alerts by room level, mute and pause', () async {
      final source = FakeChatSource();
      final prefs = ChatPrefs()
        ..browserWords = ['xanax']
        ..alertWords = {'xanax'}
        ..frozen = {'global': ChatFreeze(chatNow)}
        ..hiddenRooms = {'trade'}
        ..muted = {'company', 'global'}
        ..alertLevels = {'global': ChatAlertLevel.all, 'trade': ChatAlertLevel.all, 'dm:8': ChatAlertLevel.none}
        ..mutedUnread = false;
      final chat = ChatController(source, prefs);
      addTearDown(chat.dispose);
      final streamed = <ChatAlert>[];
      final sub = chat.alertStream.listen(streamed.add);
      addTearDown(sub.cancel);
      source.emit(const ChatReadyEvent(99, myName: 'Bravo'));
      expect(source.calls, contains('pause [global, trade]'));

      chat.openConversation('trade');
      for (final (id, room, sender, text) in [
        ('1', 'faction', 1, 'hi @bravo'),
        ('2', 'faction', 1, 'hi there'),
        ('3', 'faction', 99, 'bravo is me'),
        ('4', 'company', 2, 'bravo, muted but mentions only'),
        ('5', 'global', 3, 'bravo, muted with everything'),
        ('6', 'trade', 4, 'cheap Xanax'),
        ('7', 'dm:7', 7, 'any private message'),
        ('8', 'dm:8', 8, 'bravo, private set to nothing'),
        ('9', 'faction', 5, 'xanax but mentions only'),
      ]) {
        source.emit(ChatMessageEvent(chatMessage(id, room, sender: sender, text: text, at: DateTime.now())));
      }
      source.emit(const ChatUnreadEvent({'company': 3, 'faction': 1}));
      await Future<void>.delayed(Duration.zero);

      expect(chat.alerts.map((a) => a.message.id), ['6', '4', '1']);
      expect(streamed.map((a) => a.message.id), ['1', '4', '7']);
      expect(streamed.last.match, isNull);
      expect(chat.alerts.first.seen, isTrue);
      expect(chat.unseenAlerts, 2);
      expect(chat.hasUnseenAlert('faction'), isTrue);
      expect(chat.matchOf(chat.messagesFor('trade').single)?.keyword, 'xanax');
      expect(chat.unreadGroups(), {'faction': 1});

      chat.openConversation('faction');
      expect(chat.hasUnseenAlert('faction'), isFalse);
      chat.markAlertsSeen();
      expect(chat.unseenAlerts, 0);
    });

    test('mutes last their time and end by themselves', () {
      final evening = DateTime(2026, 10, 12, 21, 30);
      expect(ChatMuteFor.hour.until(evening), DateTime(2026, 10, 12, 22, 30));
      expect(ChatMuteFor.eightHours.until(evening), DateTime(2026, 10, 13, 5, 30));
      expect(ChatMuteFor.tomorrow.until(evening), DateTime(2026, 10, 13, 8));
      expect(ChatMuteFor.tomorrow.until(DateTime(2026, 10, 31, 2)), DateTime(2026, 10, 31, 8));
      expect(ChatMuteFor.tomorrow.until(DateTime(2026, 10, 31, 12)), DateTime(2026, 11, 1, 8));
      expect(ChatMuteFor.always.until(evening), isNull);

      final now = DateTime.now();
      prefs
        ..muted = {'global'}
        ..mutedUntil = {
          'faction': now.add(const Duration(hours: 1)),
          'company': now.subtract(const Duration(minutes: 1)),
        };
      expect(prefs.isMuted('global'), isTrue);
      expect(prefs.mutedUntilOf('global'), isNull);
      expect(prefs.isMuted('faction'), isTrue);
      expect(prefs.mutedUntilOf('faction'), isNotNull);
      expect(prefs.isMuted('company'), isFalse);
      expect(prefs.isMuted('trade'), isFalse);
    });

    test('picked duration survives reload', () async {
      final now = DateTime.now();
      prefs.setMuted('faction', true, until: ChatMuteFor.eightHours.until(now), choice: ChatMuteFor.eightHours);
      prefs.setRoomState('trade', ChatRoomState.frozen, until: ChatMuteFor.hour.until(now), choice: ChatMuteFor.hour);
      final loaded = ChatPrefs();
      await loaded.load();
      expect(loaded.muteChoiceOf('faction'), ChatMuteFor.eightHours);
      expect(loaded.freezeChoiceOf('trade'), ChatMuteFor.hour);

      loaded.mutedUntil['faction'] = now.subtract(const Duration(minutes: 1));
      expect(loaded.muteChoiceOf('faction'), isNull);
      loaded.setMuted('faction', false);
      loaded.setRoomState('trade', ChatRoomState.live);
      expect(loaded.muteChoiceOf('faction'), isNull);
      expect(loaded.freezeChoiceOf('trade'), isNull);
    });

    test('api presence keeps online and idle', () {
      expect(ChatPresence.parse('Online'), ChatPresence.online);
      expect(ChatPresence.parse('idle'), ChatPresence.idle);
      expect(ChatPresence.parse('Okay'), isNull);
      expect(ChatPresence.parse(null), isNull);
    });
  });

  group('people', () {
    test('a person style round trips and cleans its nickname', () {
      const style = ChatPersonStyle(
        name: 'Alpha',
        nameColor: Color(0xFFE53935),
        highlight: true,
        highlightColor: Color(0xFFBBDEFB),
        nickname: 'Boss',
      );
      final back = ChatPersonStyle.fromJson(style.toJson())!;
      expect(
        (back.name, back.nameColor, back.highlight, back.highlightColor, back.nickname),
        ('Alpha', const Color(0xFFE53935), true, const Color(0xFFBBDEFB), 'Boss'),
      );
      expect(ChatPersonStyle.fromJson({'name': 'Alpha'}), isNull);
      expect(ChatPersonStyle.fromJson('junk'), isNull);

      expect(ChatPersonStyle.none.copyWith(nickname: '  Boss  ').nickname, 'Boss');
      expect(ChatPersonStyle.none.copyWith(nickname: 'x' * 50).nickname.length, ChatPersonStyle.nicknameMax);
      expect(ChatPersonStyle.none.copyWith(nickname: '   ').isEmpty, isTrue);
      expect(style.copyWith(nameColor: () => null).nameColor, isNull);
      expect(style.copyWith(nickname: 'B').nameColor, const Color(0xFFE53935));
    });

    test('people are set, listed and reset', () {
      final before = prefs.people;
      prefs.setPerson(7, const ChatPersonStyle(name: 'zulu', highlight: true));
      prefs.setPerson(5, const ChatPersonStyle(name: 'Alpha', highlight: true, nickname: 'Boss'));
      prefs.setPerson(9, const ChatPersonStyle(name: 'Bravo', nameColor: Color(0xFF43A047)));
      expect(identical(before, prefs.people), isFalse);
      expect(prefs.displayName(5, 'Alpha'), 'Boss');
      expect(prefs.displayName(7, 'zulu'), 'zulu');
      expect(prefs.displayName(1, 'Other'), 'Other');
      prefs.setPerson(5, ChatPersonStyle.none);
      expect(prefs.people.containsKey(5), isFalse);
      expect(prefs.personOf(5).isEmpty, isTrue);
    });

    test('player highlight vs mention', () {
      prefs.people = {5: const ChatPersonStyle(name: 'Alpha', highlight: true, highlightColor: Color(0xFFBBDEFB))};
      final plain = chat.highlightOf(chatMessage('a', 'faction', sender: 5, text: 'hello'));
      expect((plain.on, plain.color), (true, const Color(0xFFBBDEFB)));
      final mention = chat.highlightOf(chatMessage('b', 'faction', sender: 5, text: 'hello Me'));
      expect((mention.on, mention.color), (true, null));
      expect(chat.highlightOf(chatMessage('c', 'faction', sender: 6, text: 'hello')).on, isFalse);
      expect(chat.matchOf(chatMessage('d', 'faction', sender: 5, text: 'hello')), isNull);
    });

    test('a muted person stays quiet in rooms too', () async {
      prefs.alertLevels = {'faction': ChatAlertLevel.all};
      final alerts = <String>[];
      final incoming = <String>[];
      final subs = [
        chat.alertStream.listen((a) => alerts.add(a.message.id)),
        chat.incomingStream.listen((a) => incoming.add(a.message.id)),
      ];
      prefs.setMuted(ChatRoom.dmId(5), true);
      source
        ..emit(ChatMessageEvent(chatMessage('a', 'faction', sender: 5, text: 'hello Me')))
        ..emit(ChatMessageEvent(chatMessage('b', 'faction', sender: 6, text: 'hello Me')));
      await pumpEventQueue();
      expect(alerts, ['b']);
      expect(incoming, ['b']);
      prefs.setMuted(ChatRoom.dmId(5), false);
      source.emit(ChatMessageEvent(chatMessage('c', 'faction', sender: 5, text: 'hello Me')));
      await pumpEventQueue();
      expect(alerts, ['b', 'c']);
      for (final s in subs) {
        await s.cancel();
      }
    });

    test('player notes are trimmed, capped and cleared', () {
      prefs.setPlayerNote(7, '  hi  ');
      expect(prefs.playerNoteFor(7), 'hi');
      prefs.setPlayerNote(7, 'a' * 900);
      expect(prefs.playerNoteFor(7).length, 500);
      prefs.setPlayerNote(7, '   ');
      expect(prefs.playerNotes.containsKey(7), isFalse);
    });
  });

  group('browser highlight', () {
    test('shared words highlight whole words with their color', () {
      prefs.syncBrowser(enabled: true, words: ['xanax'], color: 0xFF336699);
      final hit = chat.highlightOf(chatMessage('a', 'faction', text: 'selling Xanax now'));
      expect((hit.on, hit.color), (true, const Color(0xFF336699)));
      expect(chat.highlightOf(chatMessage('b', 'faction', text: 'xanaxes here')).on, isFalse);

      prefs.syncBrowser(enabled: true, words: ['xanax'], color: 0x701397248);
      final broken = chat.highlightOf(chatMessage('c', 'faction', text: 'xanax'));
      expect((broken.on, broken.color), (true, null));
    });

    test('highlights and alerts are switched apart', () {
      prefs.alertWords = {'rw'};
      prefs.syncBrowser(enabled: false, words: ['xanax', 'rw'], color: 0xFF336699);
      expect(chat.highlightOf(chatMessage('a', 'faction', text: 'xanax')).on, isFalse);
      expect(chat.highlightOf(chatMessage('b', 'faction', text: 'rw starts')).on, isFalse);
      expect(chat.matchOf(chatMessage('c', 'faction', text: 'rw starts'))?.keyword, 'rw');

      prefs.syncBrowser(enabled: true, words: ['xanax'], color: 0xFF336699);
      expect(chat.matchOf(chatMessage('d', 'faction', text: 'xanax')), isNull);
      prefs.setWordAlert('xanax', true);
      expect(chat.matchOf(chatMessage('e', 'faction', text: 'xanax'))?.keyword, 'xanax');
    });

    test('adding from the chat writes the shared list', () {
      List<String>? sent;
      prefs.wordsSink = (w) => sent = w;
      prefs.syncBrowser(enabled: true, words: ['rw'], color: 0xFF336699);
      prefs.addKeyword('  Xanax ');
      expect(prefs.browserWords, ['rw', 'xanax']);
      expect(sent, ['rw', 'xanax']);
      expect(prefs.alertWords, {'xanax'});
      prefs.addKeyword('XANAX');
      prefs.addKeyword('x' * 31);
      expect(prefs.browserWords, ['rw', 'xanax']);
      prefs.removeKeyword('xanax');
      expect(sent, ['rw']);
      expect(prefs.alertWords, isEmpty);
    });
  });

  group('tones', () {
    test('tones round trip', () {
      const tone = ChatTone(ChatSound.swordClash, ChatVibration.double);
      expect(ChatTone.decode(tone.code)?.code, tone.code);
      expect(ChatTone.decode('nope'), isNull);
      expect(ChatTone.decode('keyboard/zzz'), isNull);

      final stored = encodeChatTones({'dm:5': const ChatTone(ChatSound.silent), 'faction': ChatTone.standard});
      expect(stored, ['dm:5|silent/standard']);
      expect(decodeChatTones(stored)['dm:5']?.sound, ChatSound.silent);
    });

    test('alert tone precedence', () {
      ChatAlert alert(String roomId, [ChatMatch? match]) =>
          ChatAlert(chatMessage('1', roomId, sender: 7, text: 'hi'), match);
      prefs.tones = {
        'dm:7': const ChatTone(ChatSound.silent, ChatVibration.none),
        'faction': const ChatTone(ChatSound.keyboard),
      };
      expect(prefs.toneForAlert(alert('faction')).sound, ChatSound.keyboard);
      expect(prefs.toneForAlert(alert('faction', const ChatMatch(mention: true))).sound, ChatSound.silent);

      prefs.tones = {'faction': const ChatTone(ChatSound.carStart)};
      expect(prefs.toneForAlert(alert('global')).sound, ChatSound.silent);
      expect(prefs.toneForAlert(alert('company')).sound, ChatSound.keyboard);
      prefs
        ..soundForAll = true
        ..soundForAllType = ChatSound.swordClash;
      expect(prefs.toneForAlert(alert('global')).sound, ChatSound.swordClash);
      expect(prefs.toneForAlert(alert('faction')).sound, ChatSound.carStart);
      expect(prefs.toneForAlert(alert('company')).sound, ChatSound.swordClash);
    });
  });
}
