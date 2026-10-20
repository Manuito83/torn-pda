import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_colors.dart';
import 'package:torn_pda/models/chat/chat_emoji.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/chat/chat_person.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/providers/chat/chat_backup.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  ChatPrefs customized() {
    final prefs = ChatPrefs()
      ..itemAliases = const [ChatItemAlias('xans', 'Something Else')]
      ..wordsSink = (words) => Prefs().setHighlightWordList(words);
    prefs
      ..setPerson(1, const ChatPersonStyle(name: 'Alpha', nickname: 'Al'))
      ..addQuickReply('hi')
      ..addKeyword('xanax')
      ..setTone('faction', const ChatTone(ChatSound.swordClash, ChatVibration.none))
      ..setChatColors('dark', const ChatColors({ChatColorSlot.background: Colors.indigo}))
      ..setRoomState('trade', ChatRoomState.hidden)
      ..setRoomPlacement('company', ChatGlobalsPlacement.top)
      ..setTickerLevel('faction', ChatAlertLevel.all)
      ..setAlertLevel('global', ChatAlertLevel.none);
    return prefs;
  }

  String backup({Map<String, Object?> prefs = const {}}) => jsonEncode({'version': 1, 'prefs': prefs});

  test('a backup brings everything back, also after a restart', () async {
    final now = DateTime.now();
    final source = customized()
      ..setRoomState('global', ChatRoomState.frozen, until: now.add(const Duration(hours: 2)))
      ..setRoomState('poker', ChatRoomState.frozen)
      ..setGlobalsPlacement(ChatGlobalsPlacement.top)
      ..setPlayerNote(5, 'owes me 2m')
      ..setIgnored(9, 'Spammer', true)
      ..setChatFriend(4, 'Delta', true)
      ..setSoundForAll(true)
      ..setSoundForAllType(ChatSound.carStart)
      ..setFilter('trade', show: ['xanax'], hide: ['buying'])
      ..setTextScale(0.9)
      ..setCompactMode(true)
      ..setBubbleRoom('global', true)
      ..setBubbleTotal(true)
      ..setLauncher(ChatLauncher.menuBar)
      ..setTicker(false)
      ..setTickerTop(false)
      ..setTickerTap(ChatTickerTap.expand)
      ..setTickerSeconds(0)
      ..setTickerMax(3)
      ..setTickerLines(2)
      ..setGlowMode(ChatGlowMode.custom)
      ..setGlowLevel('faction', ChatAlertLevel.none)
      ..setGlowLevel('global', ChatAlertLevel.all)
      ..setWaitingHours(12)
      ..setImageAutoLoad(ChatImageAutoLoad.never)
      ..setLinkPreviews(ChatImageAutoLoad.always)
      ..setLinkWindow(false)
      ..setLinkNewTab(true)
      ..setTranslateTo('es')
      ..setWarnApiKey(false)
      ..setConfirmPublic(true)
      ..setShowAvatars(false)
      ..setPlayerColors(false)
      ..setShortcuts(false)
      ..setMentions(false)
      ..setAlertNotify(false)
      ..setAlertVibrate(true)
      ..setDmPush(false)
      ..setMutedUnread(false)
      ..setQuietHours(true)
      ..setQuietRange(from: 60, to: 120)
      ..setFactionChain(false)
      ..setFactionWar(false)
      ..setFactionEvents(true)
      ..setItemPrice(false)
      ..setPriceCheck(false)
      ..setBazaarAnalysis(false)
      ..setListReplyCount(14)
      ..setListTextScale(1.2)
      ..setSlangEverywhere(true)
      ..setMoneyOnHand(true)
      ..setNotificationTap(ChatNotificationTap.inbox)
      ..setImageHost(ChatImageHost.catbox)
      ..setQuickRowTypes([ChatQuickRow.replies, ChatQuickRow.emoji, ChatQuickRow.actions])
      ..moveQuickAction(0, 2)
      ..setQuickActionShown('wiki', false)
      ..moveMessageAction(0, 4)
      ..setMessageActionShown('save', false)
      ..setMessageActionShown('share', false)
      ..setSwipeLeft(ChatSwipeAction.trade)
      ..toggleEmojiFavorite(ChatEmoji.defaultFavorites.first)
      ..setMuted('faction', true)
      ..setMuted('company', true, until: now.add(const Duration(hours: 1)));
    addTearDown(source.dispose);
    final exported = ChatBackup.export(source, now);
    await PrefsDatabase.clearAll();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();

    final target = ChatPrefs()..wordsSink = (words) => Prefs().setHighlightWordList(words);
    addTearDown(target.dispose);
    target.applyBackup(ChatBackup.parse(exported), replace: true);
    expect(ChatBackup.export(target, now), exported);
    expect(ChatBackup.export(ChatPrefs(), now), isNot(exported));
    expect(target.roomState('global'), ChatRoomState.frozen);
    expect((target.isMuted('faction'), target.isMuted('company')), (true, false));
    expect(target.frozenUntilOf('poker'), isNull);

    final restarted = ChatPrefs();
    addTearDown(restarted.dispose);
    await restarted.load();
    restarted.syncBrowser(enabled: true, words: await Prefs().getHighlightWordList(), color: 0);
    expect(ChatBackup.export(restarted, now), exported);
  });

  test('message actions keep their order and a new one lands last', () async {
    final prefs = ChatPrefs()
      ..moveMessageAction(0, 8)
      ..setMessageActionShown('pin', false);
    addTearDown(prefs.dispose);
    await Future<void>.delayed(Duration.zero);

    final restarted = ChatPrefs();
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.messageActionOrder.first, 'copy');
    expect(restarted.messageActionOrder.last, 'reply');
    expect(restarted.messageActionHidden, {'pin'});

    await Prefs().setNativeChatMessageActionOrder(['share', 'copy', 'reply', 'gone']);
    final older = ChatPrefs();
    addTearDown(older.dispose);
    await older.load();
    expect(older.messageActionOrder.take(3), ['share', 'copy', 'reply']);
    expect(
      older.messageActionOrder.skip(3),
      ChatPrefs.messageActionIds.where((id) => !['share', 'copy', 'reply'].contains(id)),
    );
    expect(older.messageActionOrder, hasLength(ChatPrefs.messageActionIds.length));
  });

  test('chat friends after a restart and a logout', () async {
    final prefs = ChatPrefs()
      ..setChatFriend(4, 'Delta', true)
      ..setChatFriend(7, 'Golf', true)
      ..setChatFriend(4, 'Delta', false);
    addTearDown(prefs.dispose);
    await Future<void>.delayed(Duration.zero);

    final restarted = ChatPrefs();
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.chatFriends, {7: 'Golf'});
    expect((restarted.isChatFriend(4), restarted.isChatFriend(7)), (false, true));

    restarted.forgetAccount();
    await Future<void>.delayed(Duration.zero);
    final another = ChatPrefs();
    addTearDown(another.dispose);
    await another.load();
    expect(another.chatFriends, isEmpty);
  });

  test('the launcher defaults to the bubble and survives a restart', () async {
    await PrefsDatabase.clearAll();
    final fresh = ChatPrefs();
    addTearDown(fresh.dispose);
    await fresh.load();
    expect(fresh.launcher, ChatLauncher.bubble);

    fresh.setLauncher(ChatLauncher.menuBar);
    await Future<void>.delayed(Duration.zero);
    final restarted = ChatPrefs();
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.launcher, ChatLauncher.menuBar);

    expect(ChatBackup.parse(backup(prefs: {'launcher': 'browser'})).launcher, ChatLauncher.browser);
  });

  test('merge vs replace', () {
    final incoming = ChatBackup.parse(
      backup(
        prefs: {
          'itemNicknames': [
            {'alias': 'xans', 'item': 'Xanax'},
            {'alias': 'pills', 'item': 'Xanax'},
          ],
          'people': {
            '1': {'name': 'Alpha', 'nickname': 'Boss'},
            '2': {'name': 'Bravo', 'highlight': true},
            'nope': {'name': 'Broken', 'nickname': 'X'},
          },
          'quickReplies': ['gl', 'hi'],
          'highlightWords': ['vicodin'],
          'hiddenRooms': ['global'],
          'frozenRooms': {
            'trade': null,
            'company': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          },
          'placement': {'global': 'mixed', 'company': 'tab'},
          'alertLevels': {'global': 'all', 'faction': 'mentions', 'company': 'loud'},
          'playerNotes': {'2': ' friend ', '3': 7},
          'compactMode': true,
          'waitingHours': -1,
        },
      ),
    );

    final merged = customized();
    addTearDown(merged.dispose);
    merged.applyBackup(incoming, replace: false);
    expect(merged.itemAliases, const [ChatItemAlias('xans', 'Something Else'), ChatItemAlias('pills', 'Xanax')]);
    expect(merged.people.map((id, p) => MapEntry(id, p.nickname)), {1: 'Al', 2: ''});
    expect(merged.quickReplies, ['hi', 'gl']);
    expect(merged.browserWords, ['xanax', 'vicodin']);
    expect(merged.roomState('trade'), ChatRoomState.hidden);
    expect(merged.roomState('global'), ChatRoomState.hidden);
    expect(merged.roomState('company'), ChatRoomState.live);
    expect(merged.placementOf('company'), ChatGlobalsPlacement.top);
    expect(merged.globalsPlacement, ChatGlobalsPlacement.tab);
    expect(merged.alertLevels, {'global': ChatAlertLevel.none, 'faction': ChatAlertLevel.mentions});
    expect(merged.toneOf('faction').sound, ChatSound.swordClash);
    expect(merged.playerNotes, {2: 'friend'});
    expect(merged.compactMode, isFalse);

    final replaced = customized();
    addTearDown(replaced.dispose);
    replaced.applyBackup(incoming, replace: true);
    expect(replaced.itemAliases, const [ChatItemAlias('xans', 'Xanax'), ChatItemAlias('pills', 'Xanax')]);
    expect(replaced.people.map((id, p) => MapEntry(id, p.nickname)), {1: 'Boss', 2: ''});
    expect(replaced.quickReplies, ['gl', 'hi']);
    expect(replaced.browserWords, ['vicodin']);
    expect(replaced.roomState('trade'), ChatRoomState.frozen);
    expect(replaced.roomState('global'), ChatRoomState.hidden);
    expect(replaced.placementOf('company'), ChatGlobalsPlacement.tab);
    expect(replaced.globalsPlacement, ChatGlobalsPlacement.mixed);
    expect(replaced.alertLevels, {'global': ChatAlertLevel.all, 'faction': ChatAlertLevel.mentions});
    expect(replaced.toneOf('faction').sound, ChatSound.swordClash);
    expect(replaced.compactMode, isTrue);
    expect(replaced.waitingHours, 3);
  });
}
