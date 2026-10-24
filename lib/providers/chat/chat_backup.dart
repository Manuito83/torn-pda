import 'dart:convert';

import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_colors.dart';
import 'package:torn_pda/models/chat/chat_filter.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/chat/chat_person.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

/// What the player customized, not the account
class ChatBackup {
  const ChatBackup({
    this.itemNicknames,
    this.people,
    this.quickReplies,
    this.highlightWords,
    this.alertWords,
    this.tones,
    this.colors,
    this.hiddenRooms,
    this.frozenRooms,
    this.placement,
    this.tickerLevels,
    this.glowLevels,
    this.alertLevels,
    this.playerNotes,
    this.ignored,
    this.chatFriends,
    this.soundForAllType,
    this.roomFilters,
    this.textScale,
    this.previewLines,
    this.listReplyCount,
    this.listTextScale,
    this.bubbleRooms,
    this.waitingHours,
    this.linkPreviews,
    this.translateTo,
    this.switches = const {},
    this.inAppEnabled,
    this.notificationTap,
    this.swipeLeft,
    this.tickerTap,
    this.tickerSeconds,
    this.tickerMax,
    this.tickerLines,
    this.glowMode,
    this.launcher,
    this.profileIcon,
    this.quietFrom,
    this.quietTo,
    this.quickOrder,
    this.quickRows,
    this.quickRowTypes,
    this.quickHidden,
    this.messageActionOrder,
    this.messageActionHidden,
    this.emojiFavorites,
    this.imageHost,
    this.imgbbExpiration,
    this.muted,
  });

  static const int version = 1;

  /// Null fields stay as they are
  final List<ChatItemAlias>? itemNicknames;
  final Map<int, ChatPersonStyle>? people;
  final List<String>? quickReplies;
  final List<String>? highlightWords;
  final Set<String>? alertWords;
  final Map<String, ChatTone>? tones;
  final Map<String, ChatColors>? colors;
  final Set<String>? hiddenRooms;

  /// Until, null for good
  final Map<String, DateTime?>? frozenRooms;

  /// Room or "global" to placement
  final Map<String, ChatGlobalsPlacement>? placement;
  final Map<String, ChatAlertLevel>? tickerLevels;
  final Map<String, ChatAlertLevel>? glowLevels;
  final Map<String, ChatAlertLevel>? alertLevels;
  final Map<int, String>? playerNotes;
  final Map<int, String>? ignored;
  final Map<int, String>? chatFriends;
  final ChatSound? soundForAllType;
  final Map<String, ChatRoomFilter>? roomFilters;
  final double? textScale;
  final int? previewLines;
  final int? listReplyCount;
  final double? listTextScale;
  final Set<String>? bubbleRooms;
  final int? waitingHours;

  /// By ChatPrefs.switches name
  final Map<String, bool> switches;
  final bool? inAppEnabled;
  final ChatNotificationTap? notificationTap;
  final ChatSwipeAction? swipeLeft;
  final ChatTickerTap? tickerTap;
  final int? tickerSeconds;
  final int? tickerMax;
  final int? tickerLines;
  final ChatGlowMode? glowMode;
  final ChatLauncher? launcher;
  final ChatProfileIcon? profileIcon;
  final int? quietFrom;
  final int? quietTo;
  final List<String>? quickOrder;
  final int? quickRows;
  final List<String>? quickRowTypes;
  final Set<String>? quickHidden;
  final List<String>? messageActionOrder;
  final Set<String>? messageActionHidden;
  final List<String>? emojiFavorites;
  final ChatImageHost? imageHost;
  final int? imgbbExpiration;

  /// For good only, timed mutes stay out
  final Set<String>? muted;
  final ChatImageAutoLoad? linkPreviews;
  final String? translateTo;

  static String export(ChatPrefs prefs, DateTime now) => const JsonEncoder.withIndent('  ').convert({
    'version': version,
    'prefs': {
      'itemNicknames': [for (final a in prefs.itemAliases) a.toJson()],
      'people': {for (final e in prefs.people.entries) '${e.key}': e.value.toJson()},
      'quickReplies': prefs.quickReplies,
      'highlightWords': prefs.browserWords,
      'alertWords': prefs.alertWords.toList(),
      'tones': {
        for (final e in prefs.tones.entries)
          if (!e.value.isStandard) e.key: e.value.code,
      },
      'colors': {for (final e in prefs.colors.value.entries) e.key: e.value.toJson()},
      'hiddenRooms': prefs.hiddenRooms.toList(),
      'frozenRooms': {
        for (final e in prefs.frozen.entries)
          if (e.value.activeAt(now)) e.key: e.value.until?.millisecondsSinceEpoch,
      },
      'placement': {
        'global': prefs.globalsPlacement.name,
        for (final e in prefs.roomPlacement.entries) e.key: e.value.name,
      },
      'tickerLevels': {for (final e in prefs.tickerLevels.entries) e.key: e.value.name},
      'glowLevels': {for (final e in prefs.glowLevels.entries) e.key: e.value.name},
      'alertLevels': {for (final e in prefs.alertLevels.entries) e.key: e.value.name},
      'playerNotes': {for (final e in prefs.playerNotes.entries) '${e.key}': e.value},
      'ignored': {for (final e in prefs.ignored.entries) '${e.key}': e.value},
      'chatFriends': {for (final e in prefs.chatFriends.entries) '${e.key}': e.value},
      'soundForAllType': prefs.soundForAllType.name,
      'roomFilters': {
        for (final e in prefs.roomFilters.entries) e.key: {'show': e.value.show, 'hide': e.value.hide},
      },
      'textScale': prefs.textScale,
      'previewLines': prefs.previewLines,
      'listReplyCount': prefs.listReplyCount,
      'listTextScale': prefs.listTextScale,
      'bubbleRooms': prefs.bubbleRooms.toList(),
      'waitingHours': prefs.waitingHours,
      'linkPreviews': prefs.linkPreviews.name,
      'translateTo': prefs.translateTo,
      for (final e in prefs.switches.entries) e.key: e.value.$1,
      'inAppEnabled': prefs.inAppEnabled,
      'notificationTap': prefs.notificationTap.name,
      'swipeLeft': prefs.swipeLeft.name,
      'tickerTap': prefs.tickerTap.name,
      'tickerSeconds': prefs.tickerSeconds,
      'tickerMax': prefs.tickerMax,
      'tickerLines': prefs.tickerLines,
      'glowMode': prefs.glowMode.name,
      'launcher': prefs.launcher.name,
      'profileIcon': prefs.profileIcon.name,
      'quietFrom': prefs.quietFrom,
      'quietTo': prefs.quietTo,
      'quickOrder': prefs.quickOrder,
      'quickRows': prefs.quickRows,
      'quickRowTypes': [for (final t in prefs.quickRowTypes) t.name],
      'quickHidden': prefs.quickHidden.toList(),
      'messageActionOrder': prefs.messageActionOrder,
      'messageActionHidden': prefs.messageActionHidden.toList(),
      'emojiFavorites': prefs.emojiFavorites,
      'imageHost': prefs.imageHost.name,
      'imgbbExpiration': prefs.imgbbExpiration,
      'muted': prefs.muted.toList(),
    },
  });

  /// Throws a FormatException to show
  static ChatBackup parse(String text) {
    Object? json;
    try {
      json = jsonDecode(text.trim());
    } catch (_) {
      throw const FormatException('This is not a chat backup');
    }
    if (json is! Map || json['version'] is! int || json['prefs'] is! Map) {
      throw const FormatException('This is not a chat backup');
    }
    if (json['version'] != version) {
      throw const FormatException('This backup is from a different version of Torn PDA and can\'t be imported');
    }
    final prefs = json['prefs'] as Map;
    List<String>? strings(String key) => prefs[key] is List ? [...(prefs[key] as List).whereType<String>()] : null;
    Map<String, T>? map<T>(String key, T? Function(Object? value) read) => prefs[key] is Map
        ? {
            for (final e in (prefs[key] as Map).entries)
              if ((e.key, read(e.value)) case (final String k, final T v) when k.isNotEmpty) k: v,
          }
        : null;
    Map<int, T>? players<T>(String key, T? Function(Object? value) read) =>
        map(key, read)?.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v))?..removeWhere((id, _) => id <= 0);
    bool? flag(String key) => prefs[key] is bool ? prefs[key] as bool : null;
    int? minutes(String key) =>
        prefs[key] is int && (prefs[key] as int) >= 0 && (prefs[key] as int) < 24 * 60 ? prefs[key] as int : null;
    T? named<T extends Enum>(String key, List<T> values) => values.where((v) => v.name == prefs[key]).firstOrNull;
    int? option(String key, List<int> allowed) => allowed.contains(prefs[key]) ? prefs[key] as int : null;
    ChatAlertLevel? level(Object? v) => ChatAlertLevel.values.where((l) => l.name == v).firstOrNull;
    String? trimmed(Object? v, int max) =>
        v is String && v.trim().isNotEmpty ? v.trim().substring(0, v.trim().length.clamp(0, max)) : null;
    return ChatBackup(
      itemNicknames: prefs['itemNicknames'] is List
          ? ChatItemAliases.parse(jsonEncode(prefs['itemNicknames']))?.$1 ?? const []
          : null,
      people: players('people', ChatPersonStyle.fromJson),
      quickReplies: strings(
        'quickReplies',
      )?.map((r) => r.trim()).where((r) => r.isNotEmpty).toSet().take(ChatPrefs.maxQuickReplies).toList(),
      highlightWords: strings('highlightWords')
          ?.map((w) => w.trim().toLowerCase())
          .where((w) => w.isNotEmpty && w.length <= ChatPrefs.maxWordLength)
          .toSet()
          .toList(),
      alertWords: strings('alertWords')?.map((w) => w.trim().toLowerCase()).where((w) => w.isNotEmpty).toSet(),
      tones: map('tones', (v) => v is String ? ChatTone.decode(v) : null),
      colors: map(
        'colors',
        (v) => switch (ChatColors.fromJson(v)) {
          final c when !c.isEmpty => c,
          _ => null,
        },
      ),
      hiddenRooms: strings('hiddenRooms')?.where((r) => r.isNotEmpty).toSet(),
      frozenRooms: prefs['frozenRooms'] is Map
          ? {
              for (final e in (prefs['frozenRooms'] as Map).entries)
                if (e.key case final String room when room.isNotEmpty && (e.value == null || e.value is int))
                  room: e.value == null ? null : DateTime.fromMillisecondsSinceEpoch(e.value as int),
            }
          : null,
      placement: map('placement', (v) => ChatGlobalsPlacement.values.where((p) => p.name == v).firstOrNull),
      tickerLevels: map('tickerLevels', level),
      glowLevels: map('glowLevels', level),
      alertLevels: map('alertLevels', level),
      playerNotes: players('playerNotes', (v) => trimmed(v, ChatPrefs.playerNoteMax)),
      ignored: players('ignored', (v) => trimmed(v, 100)),
      chatFriends: players('chatFriends', (v) => trimmed(v, 100)),
      soundForAllType: ChatSound.audible.where((s) => s.name == prefs['soundForAllType']).firstOrNull,
      roomFilters: map(
        'roomFilters',
        (v) => v is Map && v['show'] is List && v['hide'] is List
            ? ChatRoomFilter(
                show: [...(v['show'] as List).whereType<String>()],
                hide: [...(v['hide'] as List).whereType<String>()],
              )
            : null,
      ),
      textScale: prefs['textScale'] is num ? (prefs['textScale'] as num).toDouble() : null,
      previewLines: option('previewLines', ChatPrefs.previewLinesOptions),
      listReplyCount: prefs['listReplyCount'] is int ? prefs['listReplyCount'] as int : null,
      listTextScale: prefs['listTextScale'] is num ? (prefs['listTextScale'] as num).toDouble() : null,
      bubbleRooms: strings('bubbleRooms')?.toSet(),
      waitingHours: prefs['waitingHours'] is int && (prefs['waitingHours'] as int) >= 0
          ? prefs['waitingHours'] as int
          : null,
      linkPreviews: named('linkPreviews', ChatImageAutoLoad.values),
      translateTo: prefs['translateTo'] is String ? prefs['translateTo'] as String : null,
      switches: {
        if (named('imageAutoLoad', ChatImageAutoLoad.values) case final old?)
          if (ChatPrefs.imagesFromLegacy(old.name) case (final inPrivate, final inPublic)) ...{
            'imagesPrivate': inPrivate,
            'imagesPublic': inPublic,
          },
        for (final e in prefs.entries)
          if ((e.key, e.value) case (final String name, final bool on)) name: on,
      },
      inAppEnabled: flag('inAppEnabled'),
      notificationTap: named('notificationTap', ChatNotificationTap.values),
      swipeLeft: named('swipeLeft', ChatSwipeAction.values),
      tickerTap: named('tickerTap', ChatTickerTap.values),
      tickerSeconds: option('tickerSeconds', ChatPrefs.tickerSecondsOptions),
      tickerMax: option('tickerMax', ChatPrefs.tickerMaxOptions),
      tickerLines: option('tickerLines', ChatPrefs.tickerLinesOptions),
      glowMode: named('glowMode', ChatGlowMode.values),
      launcher: named('launcher', ChatLauncher.values),
      profileIcon: named('profileIcon', ChatProfileIcon.values),
      quietFrom: minutes('quietFrom'),
      quietTo: minutes('quietTo'),
      quickOrder: strings('quickOrder'),
      quickRows: option('quickRows', ChatPrefs.quickRowsOptions),
      quickRowTypes: strings('quickRowTypes'),
      quickHidden: strings('quickHidden')?.toSet(),
      messageActionOrder: strings('messageActionOrder'),
      messageActionHidden: strings('messageActionHidden')?.toSet(),
      emojiFavorites: strings('emojiFavorites')?.toSet().toList(),
      imageHost: named('imageHost', ChatImageHost.values),
      imgbbExpiration: option('imgbbExpiration', ChatPrefs.imgbbExpirationOptions),
      muted: strings('muted')?.where((r) => r.isNotEmpty).toSet(),
    );
  }
}
