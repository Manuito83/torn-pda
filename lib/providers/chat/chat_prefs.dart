import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_colors.dart';
import 'package:torn_pda/models/chat/chat_emoji.dart';
import 'package:torn_pda/models/chat/chat_filter.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_person.dart';
import 'package:torn_pda/models/chat/chat_reminder.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/models/chat/chat_saved.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/pages/settings/app_icon_menu_page.dart';
import 'package:torn_pda/providers/chat/chat_backup.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum ChatGlobalsPlacement { top, mixed, tab }

enum ChatNotificationTap { window, inbox }

enum ChatTickerTap { window, expand }

enum ChatSwipeAction {
  off,
  message,
  profile,
  attack,
  trade,
  bazaar,
  mail;

  static ChatSwipeAction of(String name) => values.firstWhere((a) => a.name == name, orElse: () => message);
}

enum ChatGlowMode { ticker, custom, off }

enum ChatImageAutoLoad { never, torn, always }

enum ChatLauncher { bubble, browser, menuHeader, menuBar }

enum ChatLauncherTap { full, window }

enum ChatTimes { app, tct, local }

enum ChatAnimations { quick, smooth, verySmooth }

enum ChatProfileIcon { pda, torn }

enum ChatQuickRow {
  actions('Actions'),
  emoji('Emoji'),
  replies('Replies');

  const ChatQuickRow(this.title);

  final String title;

  static List<ChatQuickRow>? read(List<String> names) {
    final rows = [for (final name in names) ?values.asNameMap()[name]];
    return rows.length == 3 && names.length == 3 ? rows : null;
  }
}

class ChatPrefs extends ChangeNotifier {
  static List<String> get bubbleOptions => ChatRooms.groups;
  static const Set<String> globalRooms = {'global', 'trade', 'poker'};
  static List<String> get placedRooms => [
    'faction',
    'company',
    ChatRooms.travel,
    for (final r in ChatRooms.remote) r.id,
  ];
  static const int _maxSaved = 300;
  static const int maxQuickReplies = 20;
  static List<String> get tickerOptions => [...bubbleOptions, ChatRooms.other];

  /// Zero is until dismissed
  static const List<int> tickerSecondsOptions = [4, 6, 10, 0];
  static const List<int> tickerMaxOptions = [1, 2, 3];
  static const List<int> tickerLinesOptions = [1, 2];
  static const List<int> previewLinesOptions = [1, 2, 3];

  /// Seconds, 0 keeps images forever
  static const List<int> imgbbExpirationOptions = [0, 86400, 604800, 2592000, 15552000];
  static const int minListReplyCount = 1;
  static const int maxListReplyCount = 20;

  bool inAppEnabled = true;
  Set<String> bubbleRooms = {'faction', 'company', 'dm'};
  bool bubbleTotal = false;
  List<String> pinned = [];
  Set<String> hiddenRooms = {};

  /// DMs hidden from inbox, this device only
  Set<String> archived = {};
  ChatGlobalsPlacement globalsPlacement = ChatGlobalsPlacement.tab;
  Map<String, ChatGlobalsPlacement> roomPlacement = {};
  bool mentions = true;

  bool browserHighlight = false;
  Color? browserColor;

  /// Shared with the browser chat, lowercase
  List<String> browserWords = [];
  ChatAlertMatcher browserMatcher = ChatAlertMatcher();

  /// Subset of the shared list that alerts
  Set<String> alertWords = {};

  void Function(List<String> words)? wordsSink;
  static const int maxWordLength = 30;
  Set<String> muted = {};

  /// Timed mutes, [muted] is for good
  Map<String, DateTime> mutedUntil = {};

  /// Chip picked for each timed mute
  Map<String, ChatMuteFor> muteChoice = {};
  Timer? _unmuteTimer;
  bool mutedUnread = true;

  /// Rooms marked unread until opened
  Set<String> markedUnread = {};

  /// In hours, 0 is off
  int waitingHours = 3;

  /// Last message attended per DM
  Map<String, DateTime> waitingDismissed = {};
  Map<String, ChatAlertLevel> alertLevels = {};
  Map<String, ChatRoomFilter> roomFilters = {};
  Map<String, ChatFreeze> frozen = {};
  Timer? _thawTimer;
  final List<(String, DateTime, DateTime)> _thaws = [];

  /// Reported once per install
  Set<String> unknownRooms = {};
  void Function(String roomId)? unknownRoomSink;
  final Set<String> _seenRooms = {};
  bool _remoteReady = false;
  bool alertNotify = true;
  bool alertVibrate = false;
  Map<String, ChatTone> tones = {};
  bool soundForAll = false;
  ChatSound soundForAllType = ChatSound.keyboard;

  /// Torn's DM pushes, read in the background
  bool dmPush = true;
  bool quietHours = false;

  /// Minutes since midnight
  int quietFrom = 23 * 60;
  int quietTo = 8 * 60;

  /// Empty follows the device
  String translateTo = '';
  ChatNotificationTap notificationTap = ChatNotificationTap.window;
  ChatSwipeAction swipeLeft = ChatSwipeAction.message;
  bool ticker = true;
  ChatLauncher launcher = ChatLauncher.bubble;
  ChatLauncherTap launcherTap = ChatLauncherTap.full;
  bool miniBubbles = true;
  bool reopenChats = false;
  ChatTimes chatTimes = ChatTimes.app;
  ChatAnimations animations = ChatAnimations.verySmooth;

  /// From the app settings, not stored
  bool appTornTime = false;
  bool app12h = false;

  /// "roomId|title" as last published
  List<String> shortcutCache = [];

  /// Survives the system killing the app
  DateTime? pausedAt;
  bool tickerTop = true;
  Map<String, ChatAlertLevel> tickerLevels = {};
  ChatTickerTap tickerTap = ChatTickerTap.window;
  int tickerSeconds = 6;
  int tickerMax = 2;
  int tickerLines = 1;
  ChatGlowMode glowMode = ChatGlowMode.ticker;
  Map<String, ChatAlertLevel> glowLevels = {};

  /// Left, top, width, height and size preset
  List<String> windowFrame = [];

  /// Encoded by ChatWindowFrame
  List<String> windows = [];

  /// Encoded by ChatBigWindow
  List<String> bigWindow = [];

  /// Encoded by ChatOnScreen
  List<String> onScreen = [];

  /// x and y fractions, then dock side
  List<String> bubbleSpot = [];
  bool imagesPrivate = true;
  bool imagesPublic = false;
  ChatImageAutoLoad linkPreviews = ChatImageAutoLoad.always;

  /// Groups where web previews wait
  Set<String> linkPreviewsOff = {...globalRooms};
  bool linkWindow = true;
  bool linkNewTab = false;
  ChatImageHost imageHost = ChatImageHost.imgbb;
  String imgurClientId = '';
  String imgbbKey = '';
  int imgbbExpiration = 0;
  String catboxUserhash = '';

  /// Only in Torn PDA, id to name
  Map<int, String> ignored = {};

  /// Friends only in chat, id to name
  Map<int, String> chatFriends = {};
  String friendsTab = '';

  /// Faction and company lists: status, online or name
  String friendsSort = 'status';

  /// Only in chat, by player id
  Map<int, String> playerNotes = {};
  static const int playerNoteMax = 500;

  /// Look per player id
  Map<int, ChatPersonStyle> people = {};
  Map<String, String> drafts = {};

  /// Newest first
  List<ChatSaved> savedMessages = [];
  List<String> quickReplies = [];
  bool itemPrice = true;
  List<ChatItemAlias> itemAliases = ChatItemAliases.defaults;
  static const List<String> _quickActionIds = [
    'price',
    'player',
    'tab',
    'script',
    'status',
    'wiki',
    'time',
    'bank',
    'emoji',
    'replies',
  ];
  static const String rowBreak2 = 'row2';
  static const String rowBreak3 = 'row3';
  static const List<String> rowBreaks = [rowBreak2, rowBreak3];
  static const String offBreak = 'off';
  ChatProfileIcon profileIcon = ChatProfileIcon.pda;
  static const List<int> quickRowsOptions = [1, 2, 3];
  List<String> quickOrder = [..._quickActionIds];
  Set<String> quickHidden = {};
  int quickRows = 3;
  List<ChatQuickRow> quickRowTypes = [...ChatQuickRow.values];
  static const List<String> messageActionIds = [
    'reply',
    'copy',
    'forward',
    'smiley',
    'pin',
    'save',
    'translate',
    'share',
    'remind',
  ];
  List<String> messageActionOrder = [...messageActionIds];
  Set<String> messageActionHidden = {};
  List<String> emojiFavorites = [...ChatEmoji.defaultFavorites];
  Map<String, int> emojiCounts = {};
  bool priceCheck = true;
  bool bazaarAnalysis = true;
  bool slangEverywhere = false;
  bool moneyOnHand = false;
  bool warnApiKey = true;
  bool confirmPublic = false;
  bool enterSendsHardware = true;
  bool enterSendsSoft = false;
  bool playerColors = true;
  bool compactMode = false;
  bool showAvatars = true;
  double textScale = 1;
  double listTextScale = 1;
  int previewLines = 1;
  bool listReply = true;
  int listReplyCount = 3;

  /// By theme name, own notifier
  final ValueNotifier<Map<String, ChatColors>> colors = ValueNotifier(const {});
  bool factionChain = true;
  int lastChainReport = 0;
  int lastWarReport = 0;
  bool factionEvents = false;

  bool factionEventsDenied = false;
  bool factionWar = true;
  bool factionEnemyChain = true;
  bool factionRoster = true;
  bool factionBanker = false;
  Set<String> statusPieces = {};

  /// One per conversation
  Map<String, ChatSaved> pinnedMessages = {};
  bool introSeen = false;
  List<ChatReminder> reminders = [];

  void syncBrowser({required bool enabled, required List<String> words, required int color}) {
    // Over 32 bits is the broken default
    final usable = color <= 0xFFFFFFFF ? Color(color).withAlpha(255) : null;
    if (enabled == browserHighlight && usable == browserColor && listEquals(words, browserWords)) return;
    browserHighlight = enabled;
    browserColor = usable;
    browserWords = List.of(words);
    browserMatcher = ChatAlertMatcher(keywords: browserWords);
    notifyListeners();
  }

  Future<void> load() async {
    inAppEnabled = await Prefs().getNativeChatEnabled();
    bubbleRooms = (await Prefs().getNativeChatBubbleRooms()).toSet();
    bubbleTotal = await Prefs().getNativeChatBubbleTotal();
    pinned = await Prefs().getNativeChatPinned();
    hiddenRooms = (await Prefs().getNativeChatHiddenRooms()).toSet();
    archived = (await Prefs().getNativeChatArchived()).toSet();
    final placement = await Prefs().getNativeChatGlobalsPlacement();
    globalsPlacement = ChatGlobalsPlacement.values.firstWhere(
      (p) => p.name == placement,
      orElse: () => ChatGlobalsPlacement.tab,
    );
    roomPlacement = {
      for (final pair in await Prefs().getNativeChatRoomPlacement())
        if (pair.split('|') case [final room, final value])
          room: ChatGlobalsPlacement.values.firstWhere(
            (p) => p.name == value,
            orElse: () => ChatGlobalsPlacement.mixed,
          ),
    };
    mentions = await Prefs().getNativeChatMentions();
    alertWords = (await Prefs().getNativeChatAlertWords()).toSet();
    muted = (await Prefs().getNativeChatMuted()).toSet();
    mutedUntil = {};
    muteChoice = {};
    for (final pair in await Prefs().getNativeChatMutedUntil()) {
      final parts = pair.split('|');
      final choice = parts.length >= 3 ? ChatMuteFor.values.asNameMap()[parts.last] : null;
      if (choice != null) parts.removeLast();
      final ms = parts.length >= 2 ? int.tryParse(parts.removeLast()) : null;
      if (ms == null) continue;
      final id = parts.join('|');
      mutedUntil[id] = DateTime.fromMillisecondsSinceEpoch(ms);
      if (choice != null) muteChoice[id] = choice;
    }
    _scheduleUnmute();
    mutedUnread = await Prefs().getNativeChatMutedUnread();
    markedUnread = (await Prefs().getNativeChatMarkedUnread()).toSet();
    waitingHours = await Prefs().getNativeChatWaitingHours();
    waitingDismissed = _decodeWaiting(await Prefs().getNativeChatWaitingDismissed());
    alertLevels = {
      for (final pair in await Prefs().getNativeChatAlertLevels())
        if (pair.contains('|'))
          pair.substring(0, pair.lastIndexOf('|')): ChatAlertLevel.values.firstWhere(
            (l) => l.name == pair.substring(pair.lastIndexOf('|') + 1),
            orElse: () => ChatAlertLevel.mentions,
          ),
    };
    final pausedRooms = await Prefs().getNativeChatPausedRooms();
    frozen = ChatFreeze.decode(pausedRooms)..removeWhere((id, _) => hiddenRooms.contains(id));
    if (!listEquals(ChatFreeze.encode(frozen), pausedRooms)) {
      await Prefs().setNativeChatPausedRooms(ChatFreeze.encode(frozen));
    }
    _scheduleThaw();
    unknownRooms = (await Prefs().getNativeChatUnknownRooms()).toSet();
    alertNotify = await Prefs().getNativeChatAlertNotify();
    alertVibrate = await Prefs().getNativeChatAlertVibrate();
    tones = decodeChatTones(await Prefs().getNativeChatTones());
    soundForAll = await Prefs().getNativeChatSoundForAll();
    final allType = await Prefs().getNativeChatSoundForAllType();
    soundForAllType = ChatSound.audible.firstWhere((s) => s.name == allType, orElse: () => ChatSound.keyboard);
    dmPush = await Prefs().getTornChatDmPush();
    quietHours = await Prefs().getNativeChatQuietHours();
    quietFrom = await Prefs().getNativeChatQuietFrom();
    quietTo = await Prefs().getNativeChatQuietTo();
    translateTo = await Prefs().getNativeChatTranslateTo();
    final tap = await Prefs().getNativeChatNotificationTap();
    notificationTap = ChatNotificationTap.values.firstWhere(
      (t) => t.name == tap,
      orElse: () => ChatNotificationTap.window,
    );
    swipeLeft = ChatSwipeAction.of(await Prefs().getNativeChatSwipeLeft());
    ticker = await Prefs().getNativeChatTicker();
    final launcherName = await Prefs().getNativeChatLauncher();
    launcher = ChatLauncher.values.where((l) => l.name == launcherName).firstOrNull ?? ChatLauncher.bubble;
    final tapName = await Prefs().getNativeChatLauncherTap();
    launcherTap = ChatLauncherTap.values.where((t) => t.name == tapName).firstOrNull ?? ChatLauncherTap.full;
    miniBubbles = await Prefs().getNativeChatMiniBubbles();
    reopenChats = await Prefs().getNativeChatReopen();
    final timesName = await Prefs().getNativeChatTimes();
    chatTimes = ChatTimes.values.where((t) => t.name == timesName).firstOrNull ?? ChatTimes.app;
    final animationsName = await Prefs().getNativeChatAnimations();
    animations =
        ChatAnimations.values.where((a) => a.name == animationsName).firstOrNull ?? ChatAnimations.verySmooth;
    shortcutCache = await Prefs().getNativeChatShortcutCache();
    final paused = await Prefs().getNativeChatPausedAt();
    pausedAt = paused > 0 ? DateTime.fromMillisecondsSinceEpoch(paused) : null;
    tickerTop = await Prefs().getNativeChatTickerTop();
    tickerLevels = {
      for (final pair in await Prefs().getNativeChatTickerLevels())
        if (pair.split('|') case [final group, final level])
          group: ChatAlertLevel.values.firstWhere((l) => l.name == level, orElse: () => ChatAlertLevel.mentions),
    };
    final tickerTapName = await Prefs().getNativeChatTickerTap();
    tickerTap = ChatTickerTap.values.firstWhere((t) => t.name == tickerTapName, orElse: () => ChatTickerTap.window);
    final seconds = await Prefs().getNativeChatTickerSeconds();
    tickerSeconds = tickerSecondsOptions.contains(seconds) ? seconds : 6;
    final shownAtOnce = await Prefs().getNativeChatTickerMax();
    tickerMax = tickerMaxOptions.contains(shownAtOnce) ? shownAtOnce : 2;
    final lines = await Prefs().getNativeChatTickerLines();
    tickerLines = tickerLinesOptions.contains(lines) ? lines : 1;
    final glowName = await Prefs().getNativeChatGlowMode();
    glowMode = ChatGlowMode.values.firstWhere((m) => m.name == glowName, orElse: () => ChatGlowMode.ticker);
    glowLevels = {
      for (final pair in await Prefs().getNativeChatGlowLevels())
        if (pair.split('|') case [final group, final level])
          group: ChatAlertLevel.values.firstWhere((l) => l.name == level, orElse: () => ChatAlertLevel.mentions),
    };
    windowFrame = await Prefs().getNativeChatWindowFrame();
    windows = await Prefs().getNativeChatWindows();
    bigWindow = await Prefs().getNativeChatBigWindow();
    onScreen = await Prefs().getNativeChatOnScreen();
    bubbleSpot = await Prefs().getNativeChatBubbleSpot();
    final (legacyPrivate, legacyPublic) = imagesFromLegacy(await Prefs().getNativeChatImageAutoLoad());
    imagesPrivate = await Prefs().getNativeChatImagesPrivate(legacyPrivate);
    imagesPublic = await Prefs().getNativeChatImagesPublic(legacyPublic);
    final previews = await Prefs().getNativeChatLinkPreviews();
    linkPreviews = ChatImageAutoLoad.values.firstWhere((v) => v.name == previews, orElse: () => ChatImageAutoLoad.always);
    linkPreviewsOff = (await Prefs().getNativeChatLinkPreviewsOff()).toSet();
    linkWindow = await Prefs().getNativeChatLinkWindow();
    linkNewTab = await Prefs().getNativeChatLinkNewTab();
    imgurClientId = await Prefs().getChatImgurClientId();
    final host = await Prefs().getChatImageHost();
    imageHost = ChatImageHost.values.firstWhere(
      (h) => h.name == host,
      orElse: () => imgurClientId.isNotEmpty ? ChatImageHost.imgur : ChatImageHost.imgbb,
    );
    imgbbKey = await Prefs().getChatImgbbKey();
    final expiration = await Prefs().getChatImgbbExpiration();
    imgbbExpiration = imgbbExpirationOptions.contains(expiration) ? expiration : 0;
    catboxUserhash = await Prefs().getChatCatboxUserhash();
    ignored = {
      for (final pair in await Prefs().getNativeChatIgnored())
        if (int.tryParse(pair.split('|').first) case final int id) id: pair.substring(pair.indexOf('|') + 1),
    };
    chatFriends = {
      for (final pair in await Prefs().getNativeChatFriends())
        if (int.tryParse(pair.split('|').first) case final int id) id: pair.substring(pair.indexOf('|') + 1),
    };
    friendsTab = await Prefs().getNativeChatFriendsTab();
    friendsSort = await Prefs().getNativeChatFriendsSort();
    try {
      roomFilters = {
        for (final e in (jsonDecode(await Prefs().getNativeChatRoomFilters()) as Map).entries)
          e.key as String: ChatRoomFilter(
            show: List<String>.from(e.value['show'] as List),
            hide: List<String>.from(e.value['hide'] as List),
          ),
      };
    } catch (_) {
      roomFilters = {};
    }
    try {
      drafts = Map<String, String>.from(jsonDecode(await Prefs().getNativeChatDrafts()) as Map);
    } catch (_) {
      drafts = {};
    }
    try {
      savedMessages = (jsonDecode(await Prefs().getNativeChatSaved()) as List)
          .map(ChatSaved.fromJson)
          .nonNulls
          .toList();
    } catch (_) {
      savedMessages = [];
    }
    quickReplies = await Prefs().getNativeChatQuickReplies();
    itemPrice = await Prefs().getNativeChatItemPrice();
    itemAliases = ChatItemAliases.decode(await Prefs().getNativeChatItemAliases());
    quickOrder = _withAllQuick(await Prefs().getNativeChatQuickOrder());
    final rows = await Prefs().getNativeChatQuickRows();
    final hidden = (await Prefs().getNativeChatQuickHidden()).where(_quickActionIds.contains).toSet();
    final types = ChatQuickRow.read(await Prefs().getNativeChatQuickRowTypes());
    quickRowTypes = types ?? [...ChatQuickRow.values];
    quickRows = quickRowsOptions.contains(rows) ? rows : 3;
    quickHidden = types != null ? hidden : {'emoji', 'replies'};
    quickOrder = _withActiveBreaks(quickOrder);
    if (types == null) {
      await Prefs().setNativeChatQuickRowTypes([for (final t in quickRowTypes) t.name]);
      await Prefs().setNativeChatQuickRows(quickRows);
      await Prefs().setNativeChatQuickHidden(quickHidden.toList());
    }
    messageActionOrder = _withAllActions(await Prefs().getNativeChatMessageActionOrder());
    messageActionHidden = (await Prefs().getNativeChatMessageActionHidden())
        .where(messageActionIds.contains)
        .toSet();
    emojiFavorites = await Prefs().getNativeChatEmojiFavorites(ChatEmoji.defaultFavorites);
    emojiCounts = ChatEmoji.decodeCounts(await Prefs().getNativeChatEmojiCounts());
    priceCheck = await Prefs().getNativeChatPriceCheck();
    bazaarAnalysis = await Prefs().getNativeChatBazaarAnalysis();
    slangEverywhere = await Prefs().getNativeChatSlangEverywhere();
    moneyOnHand = await Prefs().getNativeChatMoneyOnHand();
    warnApiKey = await Prefs().getNativeChatWarnApiKey();
    confirmPublic = await Prefs().getNativeChatConfirmPublic();
    enterSendsHardware = await Prefs().getNativeChatEnterSendsHardware();
    enterSendsSoft = await Prefs().getNativeChatEnterSendsSoft();
    playerColors = await Prefs().getNativeChatPlayerColors();
    compactMode = await Prefs().getNativeChatCompactMode();
    showAvatars = await Prefs().getNativeChatShowAvatars();
    textScale = (await Prefs().getNativeChatTextScale()).clamp(minTextScale, maxTextScale);
    final preview = await Prefs().getNativeChatPreviewLines();
    previewLines = previewLinesOptions.contains(preview) ? preview : 1;
    listReply = await Prefs().getNativeChatListReply();
    listReplyCount = (await Prefs().getNativeChatListReplyCount()).clamp(minListReplyCount, maxListReplyCount);
    listTextScale = (await Prefs().getNativeChatListTextScale()).clamp(minTextScale, maxTextScale);
    try {
      colors.value = {
        for (final e in (jsonDecode(await Prefs().getNativeChatColors()) as Map).entries)
          e.key as String: ChatColors.fromJson(e.value),
      }..removeWhere((_, c) => c.isEmpty);
    } catch (_) {
      colors.value = const {};
    }
    factionChain = await Prefs().getNativeChatFactionChain();
    lastChainReport = await Prefs().getNativeChatLastChainReport();
    lastWarReport = await Prefs().getNativeChatLastWarReport();
    factionWar = await Prefs().getNativeChatFactionWar();
    factionEnemyChain = await Prefs().getNativeChatFactionEnemyChain();
    factionRoster = await Prefs().getNativeChatFactionRoster();
    factionBanker = await Prefs().getNativeChatFactionBanker();
    final profileIconName = await Prefs().getNativeChatProfileIcon();
    profileIcon = ChatProfileIcon.values.where((v) => v.name == profileIconName).firstOrNull ?? ChatProfileIcon.pda;
    factionEvents = await Prefs().getNativeChatFactionEvents();
    factionEventsDenied = await Prefs().getNativeChatFactionEventsDenied();
    try {
      playerNotes = {
        for (final e in (jsonDecode(await Prefs().getNativeChatPlayerNotes()) as Map).entries)
          if (int.tryParse('${e.key}') case final int id when e.value is String) id: e.value as String,
      };
    } catch (_) {
      playerNotes = {};
    }
    try {
      people = {
        for (final e in (jsonDecode(await Prefs().getNativeChatPeople()) as Map).entries)
          if ((int.tryParse('${e.key}'), ChatPersonStyle.fromJson(e.value)) case (final int id, final style?))
            id: style,
      };
    } catch (_) {
      people = {};
    }
    statusPieces = (await Prefs().getNativeChatStatusPieces()).toSet();
    introSeen = await Prefs().getNativeChatIntroSeen();
    try {
      reminders = [
        for (final e in jsonDecode(await Prefs().getNativeChatReminders()) as List)
          if (ChatReminder.fromJson(e) case final ChatReminder r) r,
      ];
    } catch (_) {
      reminders = [];
    }
    try {
      pinnedMessages = {
        for (final e in (jsonDecode(await Prefs().getNativeChatPinnedMessages()) as Map).entries)
          if (ChatSaved.fromJson(e.value) case final ChatSaved pin) '${e.key}': pin,
      };
    } catch (_) {
      pinnedMessages = {};
    }
    notifyListeners();
  }

  void setIntroSeen(bool value) {
    introSeen = value;
    Prefs().setNativeChatIntroSeen(value);
    notifyListeners();
  }

  void setStatusPieces(Set<String> value) {
    statusPieces = value;
    Prefs().setNativeChatStatusPieces(value.toList());
  }

  List<ChatQuickRow> get quickRowsShown => quickRowTypes.take(quickRows).toList();

  int get actionRows => quickRowsShown.where((t) => t == ChatQuickRow.actions).length;

  List<String> get _activeBreaks => rowBreaks.take((actionRows - 1).clamp(0, rowBreaks.length)).toList();

  bool _quickShown(String id) => rowBreaks.contains(id) ? _activeBreaks.contains(id) : !quickOff(id);

  List<String> get quickEditor => [
    for (final id in quickOrder)
      if (_quickShown(id)) id,
    offBreak,
    for (final id in quickOrder)
      if (!rowBreaks.contains(id) && quickOff(id)) id,
  ];

  void moveQuickAction(int from, int to) {
    final list = quickEditor;
    final id = list.removeAt(from);
    list.insert(to, id);
    var at = list.indexOf(offBreak);
    final isBreak = rowBreaks.contains(id);
    if (isBreak && to > at) {
      list
        ..remove(id)
        ..insert(at, id);
      at = list.indexOf(offBreak);
    } else if (!isBreak) {
      _setQuickOff(id, to > at);
    }
    list.removeAt(at);
    for (final parked in rowBreaks.where((b) => !_activeBreaks.contains(b))) {
      final was = quickOrder.indexOf(parked);
      if (was >= 0) list.insert(was.clamp(0, at), parked);
    }
    final first = list.indexOf(rowBreak2);
    final second = list.indexOf(rowBreak3);
    if (first > second && second >= 0) {
      list[first] = rowBreak3;
      list[second] = rowBreak2;
    }
    quickOrder = list;
    Prefs().setNativeChatQuickOrder(list);
    notifyListeners();
  }

  static List<String> _withAllQuick(List<String> saved) {
    final ids = [...saved.where((id) => _quickActionIds.contains(id) || rowBreaks.contains(id)).toSet()];
    return [...ids, ..._quickActionIds.where((id) => !saved.contains(id))];
  }

  List<String> _withActiveBreaks(List<String> saved) {
    final order = [...saved];
    for (final id in _activeBreaks.where((b) => !order.contains(b))) {
      final start = order.lastIndexWhere((e) => rowBreaks.contains(e) && _quickShown(e)) + 1;
      final end = order.lastIndexWhere(_quickShown) + 1;
      order.insert(start + (end - start + 1) ~/ 2, id);
    }
    return order;
  }

  void setQuickRows(int value) {
    if (!quickRowsOptions.contains(value)) return;
    quickRows = value;
    quickOrder = _withActiveBreaks(quickOrder);
    Prefs().setNativeChatQuickOrder(quickOrder);
    Prefs().setNativeChatQuickRows(value);
    notifyListeners();
  }

  void setQuickRowTypes(List<ChatQuickRow> types) {
    quickRowTypes = types;
    for (final t in types) {
      if (t != ChatQuickRow.actions) _setQuickOff(t.name, true);
    }
    quickOrder = _withActiveBreaks(quickOrder);
    Prefs().setNativeChatQuickOrder(quickOrder);
    Prefs().setNativeChatQuickRowTypes([for (final t in types) t.name]);
    notifyListeners();
  }

  static List<List<String>> splitQuickRows(List<String> order, {required int rows}) {
    final split = [<String>[]];
    for (final id in order) {
      if (_quickActionIds.contains(id)) {
        split.last.add(id);
      } else if (rowBreaks.contains(id) && split.length < rows) {
        split.add([]);
      }
    }
    while (split.length < rows) {
      split.add([]);
    }
    return split;
  }

  bool quickOff(String id) => quickHidden.contains(id) || (id == 'price' && !itemPrice);

  void _setQuickOff(String id, bool off) {
    if (id == 'price') {
      itemPrice = !off;
      Prefs().setNativeChatItemPrice(itemPrice);
    }
    quickHidden = off && id != 'price' ? {...quickHidden, id} : (quickHidden.toSet()..remove(id));
    Prefs().setNativeChatQuickHidden(quickHidden.toList());
  }

  void setQuickActionShown(String id, bool shown) {
    _setQuickOff(id, !shown);
    if (shown) {
      final rest = quickOrder.where((e) => e != id).toList();
      rest.insert(rest.lastIndexWhere(_quickShown) + 1, id);
      quickOrder = rest;
      Prefs().setNativeChatQuickOrder(rest);
    }
    notifyListeners();
  }

  static List<String> _withAllActions(List<String> saved) => [
    ...saved.where(messageActionIds.contains).toSet(),
    ...messageActionIds.where((id) => !saved.contains(id)),
  ];

  void moveMessageAction(int from, int to) {
    final order = [...messageActionOrder];
    order.insert(to, order.removeAt(from));
    messageActionOrder = order;
    Prefs().setNativeChatMessageActionOrder(order);
    notifyListeners();
  }

  void setMessageActionShown(String id, bool shown) {
    messageActionHidden = shown ? (messageActionHidden.toSet()..remove(id)) : {...messageActionHidden, id};
    Prefs().setNativeChatMessageActionHidden(messageActionHidden.toList());
    notifyListeners();
  }

  void toggleEmojiFavorite(String emoji) {
    if (emojiFavorites.contains(emoji)) {
      emojiFavorites = emojiFavorites.where((e) => e != emoji).toList();
    } else if (emojiFavorites.length < ChatEmoji.maxFavorites) {
      emojiFavorites = [...emojiFavorites, emoji];
    } else {
      return;
    }
    Prefs().setNativeChatEmojiFavorites(emojiFavorites);
    notifyListeners();
  }

  void moveEmojiFavorite(int from, int to) {
    final next = [...emojiFavorites];
    next.insert(to, next.removeAt(from));
    emojiFavorites = next;
    Prefs().setNativeChatEmojiFavorites(next);
    notifyListeners();
  }

  void countEmojis(Iterable<String> emojis) {
    if (emojis.isEmpty) return;
    emojiCounts = ChatEmoji.addUses(emojiCounts, emojis);
    Prefs().setNativeChatEmojiCounts(ChatEmoji.encodeCounts(emojiCounts));
    notifyListeners();
  }

  void setItemPrice(bool value) {
    itemPrice = value;
    Prefs().setNativeChatItemPrice(value);
    notifyListeners();
  }

  void setPriceCheck(bool value) {
    priceCheck = value;
    Prefs().setNativeChatPriceCheck(value);
    notifyListeners();
  }

  void setBazaarAnalysis(bool value) {
    bazaarAnalysis = value;
    Prefs().setNativeChatBazaarAnalysis(value);
    notifyListeners();
  }

  void setSlangEverywhere(bool value) {
    slangEverywhere = value;
    Prefs().setNativeChatSlangEverywhere(value);
    notifyListeners();
  }

  void setMoneyOnHand(bool value) {
    moneyOnHand = value;
    Prefs().setNativeChatMoneyOnHand(value);
    notifyListeners();
  }

  void setWarnApiKey(bool value) {
    warnApiKey = value;
    Prefs().setNativeChatWarnApiKey(value);
    notifyListeners();
  }

  void setConfirmPublic(bool value) {
    confirmPublic = value;
    Prefs().setNativeChatConfirmPublic(value);
    notifyListeners();
  }

  bool hardwareEnterSends({required bool shift}) => enterSendsHardware && !shift;

  TextInputAction get softAction => enterSendsSoft ? TextInputAction.send : TextInputAction.newline;

  void setEnterSendsHardware(bool value) {
    enterSendsHardware = value;
    Prefs().setNativeChatEnterSendsHardware(value);
    notifyListeners();
  }

  void setEnterSendsSoft(bool value) {
    enterSendsSoft = value;
    Prefs().setNativeChatEnterSendsSoft(value);
    notifyListeners();
  }

  void setPlayerColors(bool value) {
    playerColors = value;
    Prefs().setNativeChatPlayerColors(value);
    notifyListeners();
  }

  static const double minTextScale = 0.8;
  static const double maxTextScale = 1.6;

  void setCompactMode(bool value) {
    compactMode = value;
    Prefs().setNativeChatCompactMode(value);
    notifyListeners();
  }

  void setShowAvatars(bool value) {
    showAvatars = value;
    Prefs().setNativeChatShowAvatars(value);
    notifyListeners();
  }

  void setPreviewLines(int value) {
    if (!previewLinesOptions.contains(value)) return;
    previewLines = value;
    Prefs().setNativeChatPreviewLines(value);
    notifyListeners();
  }

  void setListReplyCount(int value) {
    listReplyCount = value.clamp(minListReplyCount, maxListReplyCount);
    Prefs().setNativeChatListReplyCount(listReplyCount);
    notifyListeners();
  }

  void setListTextScale(double value) {
    listTextScale = ((value * 10).round() / 10).clamp(minTextScale, maxTextScale);
    Prefs().setNativeChatListTextScale(listTextScale);
    notifyListeners();
  }

  void setListReply(bool value) {
    listReply = value;
    Prefs().setNativeChatListReply(value);
    notifyListeners();
  }

  void setTextScale(double value) {
    textScale = ((value * 10).round() / 10).clamp(minTextScale, maxTextScale);
    Prefs().setNativeChatTextScale(textScale);
    notifyListeners();
  }

  ChatColors colorsFor(String theme) => colors.value[theme] ?? const ChatColors();

  void setChatColors(String theme, ChatColors value) {
    colors.value = {...colors.value, theme: value}..removeWhere((_, c) => c.isEmpty);
    Prefs().setNativeChatColors(jsonEncode({for (final e in colors.value.entries) e.key: e.value.toJson()}));
  }

  void setFactionChain(bool value) {
    factionChain = value;
    Prefs().setNativeChatFactionChain(value);
    notifyListeners();
  }

  void setLastChainReport(int id) {
    lastChainReport = id;
    Prefs().setNativeChatLastChainReport(id);
  }

  void setLastWarReport(int id) {
    lastWarReport = id;
    Prefs().setNativeChatLastWarReport(id);
  }

  void setFactionWar(bool value) {
    factionWar = value;
    Prefs().setNativeChatFactionWar(value);
    notifyListeners();
  }

  void setFactionEnemyChain(bool value) {
    factionEnemyChain = value;
    Prefs().setNativeChatFactionEnemyChain(value);
    notifyListeners();
  }

  void setProfileIcon(ChatProfileIcon value) {
    profileIcon = value;
    Prefs().setNativeChatProfileIcon(value.name);
    notifyListeners();
  }

  void setFactionBanker(bool value) {
    factionBanker = value;
    Prefs().setNativeChatFactionBanker(value);
    notifyListeners();
  }

  void setFactionRoster(bool value) {
    factionRoster = value;
    Prefs().setNativeChatFactionRoster(value);
    notifyListeners();
  }

  void setFactionEvents(bool value) {
    factionEvents = value;
    factionEventsDenied = false;
    Prefs().setNativeChatFactionEvents(value);
    Prefs().setNativeChatFactionEventsDenied(false);
    notifyListeners();
  }

  void denyFactionEvents() {
    factionEvents = false;
    factionEventsDenied = true;
    Prefs().setNativeChatFactionEvents(false);
    Prefs().setNativeChatFactionEventsDenied(true);
    notifyListeners();
  }

  void setInAppEnabled(bool value) {
    inAppEnabled = value;
    Prefs().setNativeChatEnabled(value);
    notifyListeners();
  }

  void setBubbleRoom(String room, bool counted) {
    counted ? bubbleRooms.add(room) : bubbleRooms.remove(room);
    Prefs().setNativeChatBubbleRooms(bubbleRooms.toList());
    notifyListeners();
  }

  void setBubbleTotal(bool value) {
    bubbleTotal = value;
    Prefs().setNativeChatBubbleTotal(value);
    notifyListeners();
  }

  bool isPinned(String roomId) => pinned.contains(roomId);

  void setPinned(String roomId, bool value) {
    pinned.remove(roomId);
    if (value) pinned.add(roomId);
    Prefs().setNativeChatPinned(pinned);
    notifyListeners();
  }

  bool isArchived(String roomId) => archived.contains(roomId);

  void setArchived(String roomId, bool value) {
    if (value) {
      archived.add(roomId);
      pinned.remove(roomId);
      Prefs().setNativeChatPinned(pinned);
    } else if (!archived.remove(roomId)) {
      return;
    }
    Prefs().setNativeChatArchived(archived.toList());
    notifyListeners();
  }

  ChatRoomState roomState(String roomId) => hiddenRooms.contains(roomId)
      ? ChatRoomState.hidden
      : (isFrozen(roomId) ? ChatRoomState.frozen : ChatRoomState.live);

  bool isFrozen(String roomId) => frozen[roomId]?.activeAt(DateTime.now()) ?? false;

  DateTime? frozenUntilOf(String roomId) => frozen[roomId]?.until;

  /// Retiming keeps a frozen start
  void setRoomState(String roomId, ChatRoomState state, {DateTime? until, ChatMuteFor? choice}) {
    final now = DateTime.now();
    final was = frozen.remove(roomId);
    if (state == ChatRoomState.frozen) frozen[roomId] = ChatFreeze(was?.since ?? now, until, choice);
    if (was != null && state == ChatRoomState.live) _thaws.add((roomId, was.since, now));
    state == ChatRoomState.hidden ? hiddenRooms.add(roomId) : hiddenRooms.remove(roomId);
    Prefs().setNativeChatHiddenRooms(hiddenRooms.toList());
    Prefs().setNativeChatPausedRooms(ChatFreeze.encode(frozen));
    _scheduleThaw();
    notifyListeners();
  }

  /// Room, frozen at, thawed at
  List<(String, DateTime, DateTime)> takeThaws() {
    final thaws = List.of(_thaws);
    _thaws.clear();
    return thaws;
  }

  void _scheduleThaw() {
    _thawTimer?.cancel();
    final now = DateTime.now();
    final over = [
      for (final e in frozen.entries)
        if (!e.value.activeAt(now)) e.key,
    ];
    for (final id in over) {
      final freeze = frozen.remove(id)!;
      _thaws.add((id, freeze.since, freeze.until!));
    }
    if (over.isNotEmpty) {
      Prefs().setNativeChatPausedRooms(ChatFreeze.encode(frozen));
      notifyListeners();
    }
    final ends = [for (final f in frozen.values) ?f.until];
    if (ends.isEmpty) return;
    final next = ends.reduce((a, b) => a.isBefore(b) ? a : b);
    _thawTimer = Timer(next.difference(now) + const Duration(seconds: 1), _scheduleThaw);
  }

  /// Counts the bubble shows, by group
  Map<String, int> bubbleCounts(Map<String, int> groups) => {
    for (final e in groups.entries)
      if (bubbleRooms.contains(e.key) && roomState(e.key) == ChatRoomState.live) e.key: e.value,
  };

  void setRemoteRooms(String raw) {
    ChatRooms.remote = ChatRooms.parse(raw);
    _remoteReady = true;
    noteRooms(const []);
    notifyListeners();
  }

  /// Waits for Remote Config before reporting
  void noteRooms(Iterable<String> roomIds) {
    _seenRooms.addAll(roomIds);
    if (!_remoteReady) return;
    final fresh = [
      for (final id in _seenRooms)
        if (!ChatRooms.isKnown(id) && unknownRooms.add(id)) id,
    ];
    _seenRooms.clear();
    if (fresh.isEmpty) return;
    Prefs().setNativeChatUnknownRooms(unknownRooms.toList());
    for (final id in fresh) {
      unknownRoomSink?.call(id);
    }
  }

  void setGlobalsPlacement(ChatGlobalsPlacement value) {
    globalsPlacement = value;
    Prefs().setNativeChatGlobalsPlacement(value.name);
    notifyListeners();
  }

  ChatGlobalsPlacement placementOf(String roomId) => globalRooms.contains(roomId)
      ? globalsPlacement
      : roomPlacement[roomId] ?? (roomId == ChatRooms.travel ? ChatGlobalsPlacement.top : ChatGlobalsPlacement.mixed);

  bool get usesSocialTab => [...globalRooms, ...placedRooms].any((r) => placementOf(r) == ChatGlobalsPlacement.tab);

  void setRoomPlacement(String roomId, ChatGlobalsPlacement value) {
    if (globalRooms.contains(roomId)) return setGlobalsPlacement(value);
    roomPlacement[roomId] = value;
    Prefs().setNativeChatRoomPlacement([for (final e in roomPlacement.entries) '${e.key}|${e.value.name}']);
    notifyListeners();
  }

  void setMentions(bool value) {
    mentions = value;
    Prefs().setNativeChatMentions(value);
    notifyListeners();
  }

  /// Words typed here start alerting
  void addKeyword(String word) {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty || clean.length > maxWordLength || browserWords.contains(clean)) return;
    browserWords = [...browserWords, clean];
    browserMatcher = ChatAlertMatcher(keywords: browserWords);
    wordsSink?.call(browserWords);
    setWordAlert(clean, true);
  }

  void removeKeyword(String word) {
    browserWords = browserWords.where((k) => k != word).toList();
    browserMatcher = ChatAlertMatcher(keywords: browserWords);
    wordsSink?.call(browserWords);
    setWordAlert(word, false);
  }

  void setWordAlert(String word, bool on) {
    on ? alertWords.add(word) : alertWords.remove(word);
    Prefs().setNativeChatAlertWords(alertWords.toList());
    notifyListeners();
  }

  bool isMuted(String roomId) => muted.contains(roomId) || mutedUntilOf(roomId) != null;

  /// Null unless muted for a while
  DateTime? mutedUntilOf(String roomId) {
    final until = mutedUntil[roomId];
    return until != null && until.isAfter(DateTime.now()) ? until : null;
  }

  ChatMuteFor? muteChoiceOf(String roomId) => mutedUntilOf(roomId) == null ? null : muteChoice[roomId];

  ChatMuteFor? freezeChoiceOf(String roomId) => isFrozen(roomId) ? frozen[roomId]?.choice : null;

  /// Without until it stays muted for good
  void setMuted(String roomId, bool value, {DateTime? until, ChatMuteFor? choice}) {
    muted.remove(roomId);
    mutedUntil.remove(roomId);
    muteChoice.remove(roomId);
    if (value && until == null) muted.add(roomId);
    if (value && until != null) mutedUntil[roomId] = until;
    if (value && until != null && choice != null) muteChoice[roomId] = choice;
    Prefs().setNativeChatMuted(muted.toList());
    _saveMutedUntil();
    _scheduleUnmute();
    notifyListeners();
  }

  void _saveMutedUntil() => Prefs().setNativeChatMutedUntil([
    for (final e in mutedUntil.entries)
      '${e.key}|${e.value.millisecondsSinceEpoch}${muteChoice[e.key] == null ? '' : '|${muteChoice[e.key]!.name}'}',
  ]);

  void _scheduleUnmute() {
    _unmuteTimer?.cancel();
    final now = DateTime.now();
    final before = mutedUntil.length;
    mutedUntil.removeWhere((_, until) => !until.isAfter(now));
    if (mutedUntil.length != before) {
      _saveMutedUntil();
      notifyListeners();
    }
    if (mutedUntil.isEmpty) return;
    final next = mutedUntil.values.reduce((a, b) => a.isBefore(b) ? a : b);
    _unmuteTimer = Timer(next.difference(now) + const Duration(seconds: 1), _scheduleUnmute);
  }

  @override
  void dispose() {
    _unmuteTimer?.cancel();
    _thawTimer?.cancel();
    colors.dispose();
    super.dispose();
  }

  void setMutedUnread(bool value) {
    mutedUnread = value;
    Prefs().setNativeChatMutedUnread(value);
    notifyListeners();
  }

  void setMarkedUnread(String roomId, bool value) {
    if (!(value ? markedUnread.add(roomId) : markedUnread.remove(roomId))) return;
    Prefs().setNativeChatMarkedUnread(markedUnread.toList());
    notifyListeners();
  }

  void setWaitingHours(int value) {
    waitingHours = value;
    Prefs().setNativeChatWaitingHours(value);
    notifyListeners();
  }

  void dismissWaiting(Map<String, DateTime> lastAt) {
    if (!lastAt.entries.any((e) => waitingDismissed[e.key] != e.value)) return;
    waitingDismissed = {...waitingDismissed, ...lastAt};
    Prefs().setNativeChatWaitingDismissed(_encodeWaiting(waitingDismissed));
    notifyListeners();
  }

  static Map<String, DateTime> _decodeWaiting(Iterable<String> entries) => {
    for (final e in entries)
      if (e.indexOf('\t') case final cut when cut > 0)
        if (e.substring(cut + 1) case final v when v.startsWith('@'))
          if (int.tryParse(v.substring(1)) case final us?) e.substring(0, cut): DateTime.fromMicrosecondsSinceEpoch(us),
  };

  static List<String> _encodeWaiting(Map<String, DateTime> dismissed) => [
    for (final e in dismissed.entries) '${e.key}\t@${e.value.microsecondsSinceEpoch}',
  ];

  ChatAlertLevel alertLevel(String roomId) =>
      alertLevels[roomId] ?? (roomId.startsWith('dm:') ? ChatAlertLevel.all : ChatAlertLevel.mentions);

  void setAlertLevel(String roomId, ChatAlertLevel level) {
    alertLevels[roomId] = level;
    Prefs().setNativeChatAlertLevels([for (final e in alertLevels.entries) '${e.key}|${e.value.name}']);
    notifyListeners();
  }

  void setSwipeLeft(ChatSwipeAction value) {
    swipeLeft = value;
    Prefs().setNativeChatSwipeLeft(value.name);
    notifyListeners();
  }

  void setNotificationTap(ChatNotificationTap value) {
    notificationTap = value;
    Prefs().setNativeChatNotificationTap(value.name);
    notifyListeners();
  }

  ChatTone toneOf(String roomId) => tones[roomId] ?? ChatTone.standard;

  ChatSound? get allSound => soundForAll ? soundForAllType : null;

  /// Own tone also covers their room mentions
  ChatTone toneForAlert(ChatAlert alert) {
    final m = alert.message;
    final person = toneOf(ChatRoom.dmId(m.sender.id));
    final tone = alert.match != null && !person.isStandard ? person : toneOf(m.roomId);
    return tone.resolve(allSound, m.roomId);
  }

  void setSoundForAll(bool value) {
    soundForAll = value;
    Prefs().setNativeChatSoundForAll(value);
    notifyListeners();
  }

  void setSoundForAllType(ChatSound value) {
    soundForAllType = value;
    Prefs().setNativeChatSoundForAllType(value.name);
    notifyListeners();
  }

  void setDmPush(bool value) {
    dmPush = value;
    Prefs().setTornChatDmPush(value);
    notifyListeners();
  }

  void setTone(String roomId, ChatTone tone) {
    tone.isStandard ? tones.remove(roomId) : tones[roomId] = tone;
    Prefs().setNativeChatTones(encodeChatTones(tones));
    notifyListeners();
  }

  void setAlertVibrate(bool value) {
    alertVibrate = value;
    Prefs().setNativeChatAlertVibrate(value);
    notifyListeners();
  }

  void setAlertNotify(bool value) {
    alertNotify = value;
    Prefs().setNativeChatAlertNotify(value);
    notifyListeners();
  }

  bool isQuietAt(DateTime time) => quietHours && inQuietRange(quietFrom, quietTo, time.hour * 60 + time.minute);

  /// Wraps midnight, empty when ends match
  static bool inQuietRange(int from, int to, int minute) =>
      from <= to ? minute >= from && minute < to : minute >= from || minute < to;

  void setQuietHours(bool value) {
    quietHours = value;
    Prefs().setNativeChatQuietHours(value);
    notifyListeners();
  }

  void setQuietRange({int? from, int? to}) {
    quietFrom = from ?? quietFrom;
    quietTo = to ?? quietTo;
    Prefs().setNativeChatQuietFrom(quietFrom);
    Prefs().setNativeChatQuietTo(quietTo);
    notifyListeners();
  }

  void setTranslateTo(String value) {
    translateTo = value;
    Prefs().setNativeChatTranslateTo(value);
    notifyListeners();
  }

  void setLauncher(ChatLauncher value) {
    launcher = value;
    Prefs().setNativeChatLauncher(value.name);
    notifyListeners();
  }

  void setLauncherTap(ChatLauncherTap value) {
    launcherTap = value;
    Prefs().setNativeChatLauncherTap(value.name);
    notifyListeners();
  }

  void setMiniBubbles(bool value) {
    miniBubbles = value;
    Prefs().setNativeChatMiniBubbles(value);
    notifyListeners();
  }

  void setReopenChats(bool value) {
    reopenChats = value;
    Prefs().setNativeChatReopen(value);
    notifyListeners();
  }

  /// The bubble launcher always minimizes
  bool get canMinimize => launcher == ChatLauncher.bubble || miniBubbles;

  void setChatTimes(ChatTimes value) {
    chatTimes = value;
    Prefs().setNativeChatTimes(value.name);
    notifyListeners();
  }

  void setAnimations(ChatAnimations value) {
    animations = value;
    Prefs().setNativeChatAnimations(value.name);
    notifyListeners();
  }

  void followAppTime({required bool tornTime, required bool h12}) {
    if (appTornTime == tornTime && app12h == h12) return;
    appTornTime = tornTime;
    app12h = h12;
    notifyListeners();
  }

  bool get tornTime => switch (chatTimes) {
    ChatTimes.app => appTornTime,
    ChatTimes.tct => true,
    ChatTimes.local => false,
  };

  @visibleForTesting
  Duration localOffset(DateTime at) => at.toLocal().timeZoneOffset;

  /// Chat zone time, as UTC
  DateTime wallClock(DateTime at) => at.toUtc().add(tornTime ? Duration.zero : localOffset(at));

  String clock(DateTime at) => clockOf(wallClock(at));

  /// [wall] already in the zone shown
  String clockOf(DateTime wall) => DateFormat(app12h ? 'h:mm a' : 'HH:mm').format(wall);

  String minutesClock(int minutes) => clockOf(DateTime.utc(2000, 1, 1, minutes ~/ 60, minutes % 60));

  /// Time, with the date if not today
  String stamp(DateTime at) {
    final time = clock(at);
    return switch (daysFrom(DateTime.now(), at)) {
      0 => time,
      1 => 'tomorrow $time',
      _ => '${DateFormat.MMMd().format(wallClock(at))}, $time',
    };
  }

  /// Device time, "tomorrow" if another day
  String localClock(DateTime at, DateTime now) {
    final here = at.toLocal();
    final today = now.toLocal();
    final days = DateTime(
      here.year,
      here.month,
      here.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    final day = switch (days) {
      0 => '',
      1 => ' tomorrow',
      -1 => ' yesterday',
      _ => ' (${DateFormat.MMMd().format(here)})',
    };
    return '${clockOf(here)}$day';
  }

  /// Next [hour]:[minute] in chat time
  DateTime nextAt(int hour, int minute, DateTime now) {
    final (wall, here) = (wallClock(now), now.toLocal());
    var at = tornTime
        ? DateTime.utc(wall.year, wall.month, wall.day, hour, minute).toLocal()
        : DateTime(here.year, here.month, here.day, hour, minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  /// Calendar days, negative if earlier
  int daysFrom(DateTime now, DateTime at) {
    final (x, y) = (wallClock(now), wallClock(at));
    return DateTime.utc(y.year, y.month, y.day).difference(DateTime.utc(x.year, x.month, x.day)).inDays;
  }

  void setTicker(bool value) {
    ticker = value;
    Prefs().setNativeChatTicker(value);
    notifyListeners();
  }

  void setShortcutCache(List<String> value) {
    shortcutCache = value;
    Prefs().setNativeChatShortcutCache(value);
  }

  void setPausedAt(DateTime? value) {
    if (value == pausedAt) return;
    pausedAt = value;
    Prefs().setNativeChatPausedAt(value?.millisecondsSinceEpoch ?? 0);
  }

  void setTickerTop(bool value) {
    tickerTop = value;
    Prefs().setNativeChatTickerTop(value);
    notifyListeners();
  }

  void setWindowFrame(List<String> value) {
    windowFrame = value;
    Prefs().setNativeChatWindowFrame(value);
  }

  void setWindows(List<String> value) {
    windows = value;
    Prefs().setNativeChatWindows(value);
  }

  void setBigWindow(List<String> value) {
    bigWindow = value;
    Prefs().setNativeChatBigWindow(value);
  }

  void setOnScreen(List<String> value) {
    onScreen = value;
    Prefs().setNativeChatOnScreen(value);
  }

  void setBubbleSpot(List<String> value) {
    bubbleSpot = value;
    Prefs().setNativeChatBubbleSpot(value);
  }

  /// Old setting to private, public
  static (bool, bool) imagesFromLegacy(String? value) => switch (value) {
    'never' => (false, false),
    'always' => (true, true),
    _ => (true, false),
  };

  void setImagesPrivate(bool value) {
    imagesPrivate = value;
    Prefs().setNativeChatImagesPrivate(value);
    notifyListeners();
  }

  void setImagesPublic(bool value) {
    imagesPublic = value;
    Prefs().setNativeChatImagesPublic(value);
    notifyListeners();
  }

  void setLinkPreviews(ChatImageAutoLoad value) {
    linkPreviews = value;
    Prefs().setNativeChatLinkPreviews(value.name);
    notifyListeners();
  }

  void setLinkPreviewsIn(String group, bool on) {
    on ? linkPreviewsOff.remove(group) : linkPreviewsOff.add(group);
    Prefs().setNativeChatLinkPreviewsOff(linkPreviewsOff.toList());
    notifyListeners();
  }

  bool previewsAlone(String? roomId, {required bool torn}) => switch (linkPreviews) {
    ChatImageAutoLoad.never => false,
    _ when torn => true,
    ChatImageAutoLoad.torn => false,
    ChatImageAutoLoad.always => roomId != null && !linkPreviewsOff.contains(ChatRooms.group(roomId)),
  };

  void setLinkWindow(bool value) {
    linkWindow = value;
    Prefs().setNativeChatLinkWindow(value);
    notifyListeners();
  }

  void setLinkNewTab(bool value) {
    linkNewTab = value;
    Prefs().setNativeChatLinkNewTab(value);
    notifyListeners();
  }

  void setImageHost(ChatImageHost value) {
    imageHost = value;
    Prefs().setChatImageHost(value.name);
    notifyListeners();
  }

  void setImgbbExpiration(int seconds) {
    if (!imgbbExpirationOptions.contains(seconds)) return;
    imgbbExpiration = seconds;
    Prefs().setChatImgbbExpiration(seconds);
    notifyListeners();
  }

  String credentialFor(ChatImageHost host) => switch (host) {
    ChatImageHost.imgur => imgurClientId,
    ChatImageHost.imgbb => imgbbKey,
    ChatImageHost.catbox => catboxUserhash,
  };

  void setCredential(ChatImageHost host, String value) {
    final clean = value.trim();
    switch (host) {
      case ChatImageHost.imgur:
        imgurClientId = clean;
        Prefs().setChatImgurClientId(clean);
      case ChatImageHost.imgbb:
        imgbbKey = clean;
        Prefs().setChatImgbbKey(clean);
      case ChatImageHost.catbox:
        catboxUserhash = clean;
        Prefs().setChatCatboxUserhash(clean);
    }
    notifyListeners();
  }

  ChatAlertLevel tickerLevel(String group) =>
      tickerLevels[group] ?? (group == 'dm' ? ChatAlertLevel.all : ChatAlertLevel.mentions);

  void setTickerLevel(String group, ChatAlertLevel level) {
    tickerLevels[group] = level;
    Prefs().setNativeChatTickerLevels([for (final e in tickerLevels.entries) '${e.key}|${e.value.name}']);
    notifyListeners();
  }

  bool tickerShows(String roomId, ChatMatch? match) =>
      ticker &&
      !hiddenRooms.contains(roomId) &&
      ChatAlertMatcher.shouldAlert(tickerLevel(ChatRooms.group(roomId)), muted: isMuted(roomId), match: match);

  void setTickerTap(ChatTickerTap value) {
    tickerTap = value;
    Prefs().setNativeChatTickerTap(value.name);
    notifyListeners();
  }

  void setTickerSeconds(int value) {
    if (!tickerSecondsOptions.contains(value)) return;
    tickerSeconds = value;
    Prefs().setNativeChatTickerSeconds(value);
    notifyListeners();
  }

  void setTickerMax(int value) {
    if (!tickerMaxOptions.contains(value)) return;
    tickerMax = value;
    Prefs().setNativeChatTickerMax(value);
    notifyListeners();
  }

  void setTickerLines(int value) {
    if (!tickerLinesOptions.contains(value)) return;
    tickerLines = value;
    Prefs().setNativeChatTickerLines(value);
    notifyListeners();
  }

  void setGlowMode(ChatGlowMode value) {
    glowMode = value;
    Prefs().setNativeChatGlowMode(value.name);
    notifyListeners();
  }

  ChatAlertLevel glowLevel(String group) =>
      glowLevels[group] ?? (group == 'dm' ? ChatAlertLevel.all : ChatAlertLevel.mentions);

  void setGlowLevel(String group, ChatAlertLevel level) {
    glowLevels[group] = level;
    Prefs().setNativeChatGlowLevels([for (final e in glowLevels.entries) '${e.key}|${e.value.name}']);
    notifyListeners();
  }

  /// Levels apply with ticker off
  bool glowShows(String roomId, ChatMatch? match) {
    if (glowMode == ChatGlowMode.off || hiddenRooms.contains(roomId) || isFrozen(roomId)) return false;
    final group = ChatRooms.group(roomId);
    final level = glowMode == ChatGlowMode.ticker ? tickerLevel(group) : glowLevel(group);
    return ChatAlertMatcher.shouldAlert(level, muted: isMuted(roomId), match: match);
  }

  ChatRoomFilter filterOf(String roomId) => roomFilters[roomId] ?? ChatRoomFilter.none;

  void setFilter(String roomId, {required List<String> show, required List<String> hide}) {
    final filter = ChatRoomFilter(show: show, hide: hide);
    filter.isActive ? roomFilters[roomId] = filter : roomFilters.remove(roomId);
    _storeFilters();
    notifyListeners();
  }

  void _storeFilters() => Prefs().setNativeChatRoomFilters(
    jsonEncode({
      for (final e in roomFilters.entries) e.key: {'show': e.value.show, 'hide': e.value.hide},
    }),
  );

  bool isIgnored(int userId) => ignored.containsKey(userId);

  void setIgnored(int userId, String name, bool value) {
    value ? ignored[userId] = name : ignored.remove(userId);
    Prefs().setNativeChatIgnored([for (final e in ignored.entries) '${e.key}|${e.value}']);
    notifyListeners();
  }

  bool isChatFriend(int userId) => chatFriends.containsKey(userId);

  void setChatFriend(int userId, String name, bool value) {
    value ? chatFriends[userId] = name : chatFriends.remove(userId);
    Prefs().setNativeChatFriends([for (final e in chatFriends.entries) '${e.key}|${e.value}']);
    notifyListeners();
  }

  void setFriendsTab(String value) {
    friendsTab = value;
    Prefs().setNativeChatFriendsTab(value);
  }

  void setFriendsSort(String value) {
    friendsSort = value;
    Prefs().setNativeChatFriendsSort(value);
  }

  String playerNoteFor(int userId) => playerNotes[userId] ?? '';

  void setPlayerNote(int userId, String text) {
    final clean = text.trim();
    clean.isEmpty
        ? playerNotes.remove(userId)
        : playerNotes[userId] = clean.substring(0, clean.length.clamp(0, playerNoteMax));
    Prefs().setNativeChatPlayerNotes(jsonEncode({for (final e in playerNotes.entries) '${e.key}': e.value}));
    notifyListeners();
  }

  ChatPersonStyle personOf(int userId) => people[userId] ?? ChatPersonStyle.none;

  String displayName(int userId, String name) {
    final nickname = people[userId]?.nickname ?? '';
    return nickname.isEmpty ? name : nickname;
  }

  /// New map each time, pages compare identity
  void setPerson(int userId, ChatPersonStyle style) {
    people = {...people};
    style.isEmpty ? people.remove(userId) : people[userId] = style;
    Prefs().setNativeChatPeople(jsonEncode({for (final e in people.entries) '${e.key}': e.value.toJson()}));
    notifyListeners();
  }

  String draftFor(String roomId) => drafts[roomId] ?? '';

  void setDraft(String roomId, String text) {
    if (text.trim().isEmpty) {
      if (drafts.remove(roomId) == null) return;
    } else {
      if (drafts[roomId] == text) return;
      drafts[roomId] = text;
    }
    // Typing must not rebuild the chat
    Prefs().setNativeChatDrafts(jsonEncode(drafts));
  }

  bool isSaved(String messageId) => savedMessages.any((s) => s.messageId == messageId);

  void setSaved(ChatMessage message, String roomName, bool value) {
    savedMessages.removeWhere((s) => s.messageId == message.id);
    if (value) savedMessages.insert(0, ChatSaved.of(message, roomName));
    if (savedMessages.length > _maxSaved) savedMessages.removeRange(_maxSaved, savedMessages.length);
    _storeSaved();
  }

  void removeSaved(String messageId) {
    savedMessages.removeWhere((s) => s.messageId == messageId);
    _storeSaved();
  }

  void _storeSaved() {
    Prefs().setNativeChatSaved(jsonEncode([for (final s in savedMessages) s.toJson()]));
    notifyListeners();
  }

  void addQuickReply(String text) {
    final clean = text.trim();
    if (clean.isEmpty || quickReplies.contains(clean) || quickReplies.length >= maxQuickReplies) return;
    quickReplies = [...quickReplies, clean];
    Prefs().setNativeChatQuickReplies(quickReplies);
    notifyListeners();
  }

  void removeQuickReply(String text) {
    quickReplies = quickReplies.where((r) => r != text).toList();
    Prefs().setNativeChatQuickReplies(quickReplies);
    notifyListeners();
  }

  void _storeAliases() {
    Prefs().setNativeChatItemAliases(ChatItemAliases.encode(itemAliases));
    notifyListeners();
  }

  /// False if invalid or already used
  bool addItemAlias(String alias, String item, {ChatItemAlias? replacing}) {
    final clean = ChatItemAliases.cleanAlias(alias);
    final at = replacing == null ? -1 : itemAliases.indexOf(replacing);
    if (clean == null ||
        itemAliases.any((a) => a.alias == clean && a != replacing) ||
        (at < 0 && itemAliases.length >= ChatItemAliases.max)) {
      return false;
    }
    final entry = ChatItemAlias(clean, item);
    itemAliases = at < 0 ? [...itemAliases, entry] : ([...itemAliases]..[at] = entry);
    _storeAliases();
    return true;
  }

  void removeItemAlias(ChatItemAlias alias) {
    itemAliases = itemAliases.where((a) => a != alias).toList();
    _storeAliases();
  }

  /// How many were new
  int importItemAliases(List<ChatItemAlias> incoming) {
    final merged = ChatItemAliases.merge(itemAliases, incoming);
    final added = merged.length - itemAliases.length;
    itemAliases = merged;
    if (added > 0) _storeAliases();
    return added;
  }

  /// Backed up as they are, by name
  Map<String, (bool, void Function(bool))> get switches => {
    'soundForAll': (soundForAll, setSoundForAll),
    'compactMode': (compactMode, setCompactMode),
    'showAvatars': (showAvatars, setShowAvatars),
    'listReply': (listReply, setListReply),
    'playerColors': (playerColors, setPlayerColors),
    'bubbleTotal': (bubbleTotal, setBubbleTotal),
    'ticker': (ticker, setTicker),
    'tickerTop': (tickerTop, setTickerTop),
    'imagesPrivate': (imagesPrivate, setImagesPrivate),
    'imagesPublic': (imagesPublic, setImagesPublic),
    'linkWindow': (linkWindow, setLinkWindow),
    'linkNewTab': (linkNewTab, setLinkNewTab),
    'warnApiKey': (warnApiKey, setWarnApiKey),
    'confirmPublic': (confirmPublic, setConfirmPublic),
    'enterSendsHardware': (enterSendsHardware, setEnterSendsHardware),
    'enterSendsSoft': (enterSendsSoft, setEnterSendsSoft),
    'miniBubbles': (miniBubbles, setMiniBubbles),
    'reopenChats': (reopenChats, setReopenChats),
    'mentions': (mentions, setMentions),
    'alertNotify': (alertNotify, setAlertNotify),
    'alertVibrate': (alertVibrate, setAlertVibrate),
    'dmPush': (dmPush, setDmPush),
    'mutedUnread': (mutedUnread, setMutedUnread),
    'quietHours': (quietHours, setQuietHours),
    'factionChain': (factionChain, setFactionChain),
    'factionWar': (factionWar, setFactionWar),
    'factionEnemyChain': (factionEnemyChain, setFactionEnemyChain),
    'factionRoster': (factionRoster, setFactionRoster),
    'factionBanker': (factionBanker, setFactionBanker),
    'factionEvents': (factionEvents, setFactionEvents),
    'itemPrice': (itemPrice, setItemPrice),
    'priceCheck': (priceCheck, setPriceCheck),
    'bazaarAnalysis': (bazaarAnalysis, setBazaarAnalysis),
    'slangEverywhere': (slangEverywhere, setSlangEverywhere),
    'moneyOnHand': (moneyOnHand, setMoneyOnHand),
  };

  /// Merge keeps what is already set
  void applyBackup(ChatBackup backup, {required bool replace}) {
    final now = DateTime.now();
    Map<K, V> pick<K, V>(Map<K, V> current, Map<K, V> incoming) => replace ? {...incoming} : {...incoming, ...current};
    if (backup.itemNicknames case final list?) {
      itemAliases = replace ? list.take(ChatItemAliases.max).toList() : ChatItemAliases.merge(itemAliases, list);
      Prefs().setNativeChatItemAliases(ChatItemAliases.encode(itemAliases));
    }
    if (backup.people case final map?) {
      people = pick(people, map);
      Prefs().setNativeChatPeople(jsonEncode({for (final e in people.entries) '${e.key}': e.value.toJson()}));
    }
    if (backup.quickReplies case final list?) {
      quickReplies = (replace ? list : {...quickReplies, ...list}).take(maxQuickReplies).toList();
      Prefs().setNativeChatQuickReplies(quickReplies);
    }
    if (backup.highlightWords case final list?) {
      browserWords = replace ? List.of(list) : {...browserWords, ...list}.toList();
      browserMatcher = ChatAlertMatcher(keywords: browserWords);
      wordsSink?.call(browserWords);
    }
    if (backup.alertWords case final set?) {
      alertWords = replace ? {...set} : {...alertWords, ...set};
      Prefs().setNativeChatAlertWords(alertWords.toList());
    }
    if (backup.tones case final map?) {
      tones = pick(tones, map);
      Prefs().setNativeChatTones(encodeChatTones(tones));
    }
    if (backup.colors case final map?) {
      colors.value = pick(colors.value, map);
      Prefs().setNativeChatColors(jsonEncode({for (final e in colors.value.entries) e.key: e.value.toJson()}));
    }
    if (backup.hiddenRooms != null || backup.frozenRooms != null) {
      final ice = {
        for (final e in (backup.frozenRooms ?? const <String, DateTime?>{}).entries)
          if (e.value?.isAfter(now) ?? true) e.key: ChatFreeze(now, e.value),
      };
      if (replace) {
        if (backup.hiddenRooms case final hidden?) hiddenRooms = {...hidden};
        if (backup.frozenRooms != null) frozen = ice;
      } else {
        final set = {...hiddenRooms, ...frozen.keys};
        hiddenRooms = {...hiddenRooms, ...?backup.hiddenRooms?.where((r) => !set.contains(r))};
        frozen = {
          ...frozen,
          for (final e in ice.entries)
            if (!set.contains(e.key)) e.key: e.value,
        };
      }
      frozen.removeWhere((id, _) => hiddenRooms.contains(id));
      Prefs().setNativeChatHiddenRooms(hiddenRooms.toList());
      Prefs().setNativeChatPausedRooms(ChatFreeze.encode(frozen));
      _scheduleThaw();
    }
    if (backup.placement case final map?) {
      if (replace && map['global'] != null) globalsPlacement = map['global']!;
      roomPlacement = pick(roomPlacement, {...map}..remove('global'));
      Prefs().setNativeChatGlobalsPlacement(globalsPlacement.name);
      Prefs().setNativeChatRoomPlacement([for (final e in roomPlacement.entries) '${e.key}|${e.value.name}']);
    }
    if (backup.tickerLevels case final map?) {
      tickerLevels = pick(tickerLevels, map);
      Prefs().setNativeChatTickerLevels([for (final e in tickerLevels.entries) '${e.key}|${e.value.name}']);
    }
    if (backup.glowLevels case final map?) {
      glowLevels = pick(glowLevels, map);
      Prefs().setNativeChatGlowLevels([for (final e in glowLevels.entries) '${e.key}|${e.value.name}']);
    }
    if (backup.alertLevels case final map?) {
      alertLevels = pick(alertLevels, map);
      Prefs().setNativeChatAlertLevels([for (final e in alertLevels.entries) '${e.key}|${e.value.name}']);
    }
    if (backup.playerNotes case final map?) {
      playerNotes = pick(playerNotes, map);
      Prefs().setNativeChatPlayerNotes(jsonEncode({for (final e in playerNotes.entries) '${e.key}': e.value}));
    }
    if (backup.ignored case final map?) {
      ignored = pick(ignored, map);
      Prefs().setNativeChatIgnored([for (final e in ignored.entries) '${e.key}|${e.value}']);
    }
    if (backup.chatFriends case final map?) {
      chatFriends = pick(chatFriends, map);
      Prefs().setNativeChatFriends([for (final e in chatFriends.entries) '${e.key}|${e.value}']);
    }
    if (backup.roomFilters case final map?) {
      roomFilters = pick(roomFilters, map)..removeWhere((_, f) => !f.isActive);
      _storeFilters();
    }
    if (backup.quickHidden case final set?) {
      quickHidden = {...?(replace ? null : quickHidden), ...set.where(_quickActionIds.contains)};
      Prefs().setNativeChatQuickHidden(quickHidden.toList());
    }
    if (backup.messageActionHidden case final set?) {
      messageActionHidden = {
        ...?(replace ? null : messageActionHidden),
        ...set.where(messageActionIds.contains),
      };
      Prefs().setNativeChatMessageActionHidden(messageActionHidden.toList());
    }
    if (backup.emojiFavorites case final list?) {
      emojiFavorites = {...?(replace ? null : emojiFavorites), ...list}.take(ChatEmoji.maxFavorites).toList();
      Prefs().setNativeChatEmojiFavorites(emojiFavorites);
    }
    if (backup.muted case final set?) {
      muted = {...?(replace ? null : muted), ...set};
      Prefs().setNativeChatMuted(muted.toList());
    }
    if (backup.bubbleRooms case final set?) {
      bubbleRooms = replace ? {...set} : {...bubbleRooms, ...set};
      Prefs().setNativeChatBubbleRooms(bubbleRooms.toList());
    }
    if (backup.linkPreviewsOff case final set?) {
      linkPreviewsOff = replace ? {...set} : {...linkPreviewsOff, ...set};
      Prefs().setNativeChatLinkPreviewsOff(linkPreviewsOff.toList());
    }
    if (replace) {
      if (backup.soundForAllType case final v?) setSoundForAllType(v);
      if (backup.textScale case final v?) setTextScale(v);
      if (backup.previewLines case final v?) setPreviewLines(v);
      if (backup.listReplyCount case final v?) setListReplyCount(v);
      if (backup.listTextScale case final v?) setListTextScale(v);
      if (backup.waitingHours case final v?) setWaitingHours(v);
      if (backup.linkPreviews case final v?) setLinkPreviews(v);
      if (backup.translateTo case final v?) setTranslateTo(v);
      for (final e in backup.switches.entries) {
        if (switches[e.key] case (final current, final apply) when current != e.value) apply(e.value);
      }
      if (backup.notificationTap case final v?) setNotificationTap(v);
      if (backup.swipeLeft case final v?) setSwipeLeft(v);
      if (backup.tickerTap case final v?) setTickerTap(v);
      if (backup.tickerSeconds case final v?) setTickerSeconds(v);
      if (backup.tickerMax case final v?) setTickerMax(v);
      if (backup.tickerLines case final v?) setTickerLines(v);
      if (backup.glowMode case final v?) setGlowMode(v);
      if (backup.launcher case final v?) setLauncher(v);
      if (backup.launcherTap case final v?) setLauncherTap(v);
      if (backup.chatTimes case final v?) setChatTimes(v);
      if (backup.animations case final v?) setAnimations(v);
      if (backup.profileIcon case final v?) setProfileIcon(v);
      if (backup.imageHost case final v?) setImageHost(v);
      if (backup.imgbbExpiration case final v?) setImgbbExpiration(v);
      setQuietRange(from: backup.quietFrom, to: backup.quietTo);
      if (backup.quickOrder case final order?) {
        quickOrder = _withAllQuick(order);
        Prefs().setNativeChatQuickOrder(quickOrder);
      }
      final types = ChatQuickRow.read(backup.quickRowTypes ?? const []);
      if (types != null || backup.quickRows != null) {
        setQuickRowTypes(types ?? List.filled(3, ChatQuickRow.actions));
      }
      if (backup.quickRows case final v?) setQuickRows(v);
      if (backup.appIconMenu case final slots?) AppIconMenu.setSlots(slots);
      if (backup.messageActionOrder case final order?) {
        messageActionOrder = _withAllActions(order);
        Prefs().setNativeChatMessageActionOrder(messageActionOrder);
      }
    }
    notifyListeners();
  }

  ChatSaved? pinnedIn(String roomId) => pinnedMessages[roomId];

  bool isPinnedMessage(String roomId, String messageId) => pinnedMessages[roomId]?.messageId == messageId;

  void setPinnedMessage(String roomId, ChatMessage? message, String roomName) {
    message == null ? pinnedMessages.remove(roomId) : pinnedMessages[roomId] = ChatSaved.of(message, roomName);
    Prefs().setNativeChatPinnedMessages(jsonEncode({for (final e in pinnedMessages.entries) e.key: e.value.toJson()}));
    notifyListeners();
  }

  List<ChatReminder> get pendingReminders {
    final now = DateTime.now();
    return [...reminders.where((r) => r.at.isAfter(now))]..sort((a, b) => a.at.compareTo(b.at));
  }

  void setReminders(List<ChatReminder> value) {
    reminders = value;
    Prefs().setNativeChatReminders(jsonEncode([for (final r in value) r.toJson()]));
    notifyListeners();
  }

  /// Logged out or another account
  void forgetAccount() {
    drafts = {};
    markedUnread = {};
    Prefs().setNativeChatMarkedUnread([]);
    waitingDismissed = {};
    Prefs().setNativeChatWaitingDismissed([]);
    savedMessages = [];
    playerNotes = {};
    chatFriends = {};
    pinnedMessages = {};
    pinned = [
      for (final id in pinned)
        if (!id.startsWith('dm:')) id,
    ];
    reminders = [];
    shortcutCache = [];
    windows = [];
    bigWindow = [];
    onScreen = [];
    Prefs().setNativeChatDrafts('{}');
    Prefs().setNativeChatSaved('[]');
    Prefs().setNativeChatPlayerNotes('{}');
    Prefs().setNativeChatFriends([]);
    Prefs().setNativeChatPinnedMessages('{}');
    Prefs().setNativeChatPinned(pinned);
    Prefs().setNativeChatReminders('[]');
    Prefs().setNativeChatShortcutCache(shortcutCache);
    Prefs().setNativeChatWindows(windows);
    Prefs().setNativeChatBigWindow(bigWindow);
    Prefs().setNativeChatOnScreen(onScreen);
    notifyListeners();
  }
}
