import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/sembast_db.dart';

mixin ChatPrefsStorage {
  final String _kNativeChatEnabled = "pda_nativeChatEnabled";
  final String _kNativeChatBubbleRooms = "pda_nativeChatBubbleRooms";
  final String _kNativeChatBubbleTotal = "pda_nativeChatBubbleTotal";
  final String _kNativeChatEnterSendsHardware = "pda_nativeChatEnterSendsHardware";
  final String _kNativeChatEnterSendsSoft = "pda_nativeChatEnterSendsSoft";
  final String _kNativeChatFactionBanker = "pda_nativeChatFactionBanker";
  final String _kNativeChatProfileIcon = "pda_nativeChatProfileIcon";
  final String _kNativeChatPinned = "pda_nativeChatPinned";
  final String _kNativeChatHiddenRooms = "pda_nativeChatHiddenRooms";
  final String _kNativeChatArchived = "pda_nativeChatArchived";
  final String _kNativeChatGlobalsPlacement = "pda_nativeChatGlobalsPlacement";
  final String _kNativeChatRoomPlacement = "pda_nativeChatRoomPlacement";
  final String _kNativeChatMentions = "pda_nativeChatMentions";
  final String _kNativeChatAlertWords = "pda_nativeChatAlertWords";
  final String _kNativeChatMuted = "pda_nativeChatMuted";
  final String _kNativeChatMutedUntil = "pda_nativeChatMutedUntil";
  final String _kNativeChatMutedUnread = "pda_nativeChatMutedUnread";
  final String _kNativeChatMarkedUnread = "pda_nativeChatMarkedUnread";
  final String _kNativeChatWaitingHours = "pda_nativeChatWaitingHours";
  final String _kNativeChatWaitingDismissed = "pda_nativeChatWaitingDismissed";
  final String _kNativeChatAlertLevels = "pda_nativeChatAlertLevels";
  final String _kNativeChatPausedRooms = "pda_nativeChatPausedRooms";
  final String _kNativeChatUnknownRooms = "pda_nativeChatUnknownRooms";
  final String _kNativeChatNotificationTap = "pda_nativeChatNotificationTap";
  final String _kNativeChatAlertNotify = "pda_nativeChatAlertNotify";
  final String _kNativeChatTones = "pda_nativeChatTones";
  final String _kNativeChatSoundForAll = "pda_nativeChatSoundForAll";
  final String _kNativeChatSoundForAllType = "pda_nativeChatSoundForAllType";
  final String _kNativeChatAlertVibrate = "pda_nativeChatAlertVibrate";
  final String _kNativeChatQuietHours = "pda_nativeChatQuietHours";
  final String _kNativeChatQuietFrom = "pda_nativeChatQuietFrom";
  final String _kNativeChatQuietTo = "pda_nativeChatQuietTo";
  final String _kNativeChatTranslateTo = "pda_nativeChatTranslateTo";
  final String _kNativeChatIgnored = "pda_nativeChatIgnored";
  final String _kNativeChatFriends = "pda_nativeChatFriends";
  final String _kNativeChatFriendsTab = "pda_nativeChatFriendsTab";
  final String _kNativeChatFriendsSort = "pda_nativeChatFriendsSort";
  final String _kNativeChatRosterSort = "pda_nativeChatRosterSort";
  final String _kNativeChatRosterReversed = "pda_nativeChatRosterReversed";
  final String _kNativeChatRosterFilters = "pda_nativeChatRosterFilters";
  final String _kNativeChatPlayerNotes = "pda_nativeChatPlayerNotes";
  final String _kNativeChatPeople = "pda_nativeChatPeople";
  final String _kNativeChatRoomFilters = "pda_nativeChatRoomFilters";
  final String _kNativeChatDrafts = "pda_nativeChatDrafts";
  final String _kNativeChatSaved = "pda_nativeChatSaved";
  final String _kNativeChatShortcutCache = "pda_nativeChatShortcutCache";
  final String _kNativeChatPausedAt = "pda_nativeChatPausedAt";
  final String _kNativeChatQuickReplies = "pda_nativeChatQuickReplies";
  final String _kNativeChatItemPrice = "pda_nativeChatItemPrice";
  final String _kNativeChatItemAliases = "pda_nativeChatItemAliases";
  final String _kNativeChatQuickOrder = "pda_nativeChatQuickOrder";
  final String _kNativeChatQuickHidden = "pda_nativeChatQuickHidden";
  final String _kNativeChatQuickRows = "pda_nativeChatQuickRows";
  final String _kNativeChatQuickRowTypes = "pda_nativeChatQuickRowTypes";
  final String _kNativeChatMessageActionOrder = "pda_nativeChatMessageActionOrder";
  final String _kNativeChatMessageActionHidden = "pda_nativeChatMessageActionHidden";
  final String _kNativeChatEmojiFavorites = "pda_nativeChatEmojiFavorites";
  final String _kNativeChatEmojiCounts = "pda_nativeChatEmojiCounts";
  final String _kNativeChatPriceCheck = "pda_nativeChatPriceCheck";
  final String _kNativeChatBazaarAnalysis = "pda_nativeChatBazaarAnalysis";
  final String _kNativeChatSlangEverywhere = "pda_nativeChatSlangEverywhere";
  final String _kNativeChatMoneyOnHand = "pda_nativeChatMoneyOnHand";
  final String _kNativeChatWarnApiKey = "pda_nativeChatWarnApiKey";
  final String _kNativeChatConfirmPublic = "pda_nativeChatConfirmPublic";
  final String _kNativeChatPlayerColors = "pda_nativeChatPlayerColors";
  final String _kNativeChatCompactMode = "pda_nativeChatCompactMode";
  final String _kNativeChatShowAvatars = "pda_nativeChatShowAvatars";
  final String _kNativeChatTextScale = "pda_nativeChatTextScale";
  final String _kNativeChatPreviewLines = "pda_nativeChatPreviewLines";
  final String _kNativeChatListReply = "pda_nativeChatListReply";
  final String _kNativeChatListReplyCount = "pda_nativeChatListReplyCount";
  final String _kNativeChatListTextScale = "pda_nativeChatListTextScale";
  final String _kNativeChatColors = "pda_nativeChatColors";
  final String _kNativeChatFactionChain = "pda_nativeChatFactionChain";
  final String _kNativeChatFactionWar = "pda_nativeChatFactionWar";
  final String _kNativeChatChainSheetWar = "pda_nativeChatChainSheetWar";
  final String _kNativeChatChainSheetTab = "pda_nativeChatChainSheetTab";
  final String _kNativeChatHitCallLink = "pda_nativeChatHitCallLink";
  final String _kNativeChatWatchTurnsOnWatcher = "pda_nativeChatWatchTurnsOnWatcher";
  final String _kNativeChatWatchRetals = "pda_nativeChatWatchRetals";
  final String _kNativeChatWatchHours = "pda_nativeChatWatchHours";
  final String _kNativeChatLastChainReport = "pda_nativeChatLastChainReport";
  final String _kNativeChatLastWarReport = "pda_nativeChatLastWarReport";
  final String _kNativeChatFactionEnemyChain = "pda_nativeChatFactionEnemyChain";
  final String _kNativeChatFactionEvents = "pda_nativeChatFactionEvents";
  final String _kNativeChatFactionEventsDenied = "pda_nativeChatFactionEventsDenied";
  final String _kNativeChatStatusPieces = "pda_nativeChatStatusPieces";
  final String _kNativeChatPinnedMessages = "pda_nativeChatPinnedMessages";
  final String _kNativeChatIntroSeen = "pda_nativeChatIntroSeen";
  final String _kNativeChatReminders = "pda_nativeChatReminders";
  final String _kNativeChatOwner = "pda_nativeChatOwner";
  final String _kNativeChatInbox = "pda_nativeChatInbox";
  final String _kNativeChatRemoteEnabled = "pda_nativeChatRemoteEnabled";
  // Mirrored for background isolates
  final String _kTornChatDmPush = "pda_tornChatDmPush";
  final String _kNativeChatTicker = "pda_nativeChatTicker";
  final String _kNativeChatLauncher = "pda_nativeChatLauncher";
  final String _kNativeChatLauncherTap = "pda_nativeChatLauncherTap";
  final String _kNativeChatMiniBubbles = "pda_nativeChatMiniBubbles";
  final String _kNativeChatReopen = "pda_nativeChatReopen";
  final String _kNativeChatTimes = "pda_nativeChatTimes";
  final String _kNativeChatAnimations = "pda_nativeChatAnimations";
  final String _kNativeChatTickerTop = "pda_nativeChatTickerTop";
  final String _kNativeChatTickerLevels = "pda_nativeChatTickerLevels";
  final String _kNativeChatTickerTap = "pda_nativeChatTickerTap";
  final String _kNativeChatTickerSeconds = "pda_nativeChatTickerSeconds";
  final String _kNativeChatTickerMax = "pda_nativeChatTickerMax";
  final String _kNativeChatTickerLines = "pda_nativeChatTickerLines";
  final String _kNativeChatGlowMode = "pda_nativeChatGlowMode";
  final String _kNativeChatGlowLevels = "pda_nativeChatGlowLevels";
  final String _kNativeChatWindowFrame = "pda_nativeChatWindowFrame";
  final String _kNativeChatWindows = "pda_nativeChatWindows";
  final String _kNativeChatBigWindow = "pda_nativeChatBigWindow";
  final String _kNativeChatOnScreen = "pda_nativeChatOnScreen";
  final String _kNativeChatBubbleSpot = "pda_nativeChatBubbleSpot";
  final String _kNativeChatImageAutoLoad = "pda_nativeChatImageAutoLoad";
  final String _kNativeChatImagesPrivate = "pda_nativeChatImagesPrivate";
  final String _kNativeChatImagesPublic = "pda_nativeChatImagesPublic";
  final String _kNativeChatLinkPreviews = "pda_nativeChatLinkPreviews";
  final String _kNativeChatLinkPreviewsOff = "pda_nativeChatLinkPreviewsOff";
  final String _kNativeChatLinkWindow = "pda_nativeChatLinkWindow";
  final String _kNativeChatLinkNewTab = "pda_nativeChatLinkNewTab";
  final String _kNativeChatSwipeLeft = "pda_nativeChatSwipeLeft";
  final String _kChatImageHost = "pda_chatImageHost";
  final String _kChatImgbbExpiration = "pda_chatImgbbExpiration";
  final String _kChatImgurClientId = "pda_chatImgurClientId";
  final String _kChatImgbbKey = "pda_chatImgbbKey";
  final String _kChatCatboxUserhash = "pda_chatCatboxUserhash";

  Future<bool> getNativeChatEnabled() async {
    return await PrefsDatabase.getBool(_kNativeChatEnabled, true);
  }

  Future setNativeChatEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatEnabled, value);
  }

  Future<List<String>> getNativeChatBubbleRooms() async {
    return await PrefsDatabase.getStringList(_kNativeChatBubbleRooms, <String>['faction', 'company', 'dm']);
  }

  Future setNativeChatBubbleRooms(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatBubbleRooms, value);
  }

  Future<bool> getNativeChatBubbleTotal() async {
    return await PrefsDatabase.getBool(_kNativeChatBubbleTotal, false);
  }

  Future setNativeChatBubbleTotal(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatBubbleTotal, value);
  }

  Future<bool> getNativeChatEnterSendsHardware() async {
    return await PrefsDatabase.getBool(_kNativeChatEnterSendsHardware, true);
  }

  Future setNativeChatEnterSendsHardware(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatEnterSendsHardware, value);
  }

  Future<bool> getNativeChatEnterSendsSoft() async {
    return await PrefsDatabase.getBool(_kNativeChatEnterSendsSoft, false);
  }

  Future setNativeChatEnterSendsSoft(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatEnterSendsSoft, value);
  }

  Future<bool> getNativeChatFactionBanker() async {
    return await PrefsDatabase.getBool(_kNativeChatFactionBanker, false);
  }

  Future setNativeChatFactionBanker(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatFactionBanker, value);
  }

  Future<String> getNativeChatProfileIcon() async {
    return await PrefsDatabase.getString(_kNativeChatProfileIcon, '');
  }

  Future setNativeChatProfileIcon(String value) async {
    return await PrefsDatabase.setString(_kNativeChatProfileIcon, value);
  }

  Future<List<String>> getNativeChatPinned() async {
    return await PrefsDatabase.getStringList(_kNativeChatPinned, <String>[]);
  }

  Future setNativeChatPinned(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatPinned, value);
  }

  Future<List<String>> getNativeChatArchived() async {
    return await PrefsDatabase.getStringList(_kNativeChatArchived, <String>[]);
  }

  Future setNativeChatArchived(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatArchived, value);
  }

  Future<List<String>> getNativeChatHiddenRooms() async {
    return await PrefsDatabase.getStringList(_kNativeChatHiddenRooms, <String>[]);
  }

  Future setNativeChatHiddenRooms(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatHiddenRooms, value);
  }

  Future<String> getNativeChatGlobalsPlacement() async {
    return await PrefsDatabase.getString(_kNativeChatGlobalsPlacement, "tab");
  }

  Future setNativeChatGlobalsPlacement(String value) async {
    return await PrefsDatabase.setString(_kNativeChatGlobalsPlacement, value);
  }

  Future<List<String>> getNativeChatRoomPlacement() async {
    return await PrefsDatabase.getStringList(_kNativeChatRoomPlacement, <String>[]);
  }

  Future setNativeChatRoomPlacement(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatRoomPlacement, value);
  }

  Future<bool> getNativeChatMentions() async {
    return await PrefsDatabase.getBool(_kNativeChatMentions, true);
  }

  Future setNativeChatMentions(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatMentions, value);
  }

  Future<List<String>> getNativeChatAlertWords() async {
    return await PrefsDatabase.getStringList(_kNativeChatAlertWords, <String>[]);
  }

  Future setNativeChatAlertWords(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatAlertWords, value);
  }

  Future<List<String>> getNativeChatMuted() async {
    return await PrefsDatabase.getStringList(_kNativeChatMuted, <String>[]);
  }

  Future setNativeChatMuted(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatMuted, value);
  }

  Future<List<String>> getNativeChatMutedUntil() async {
    return await PrefsDatabase.getStringList(_kNativeChatMutedUntil, <String>[]);
  }

  Future setNativeChatMutedUntil(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatMutedUntil, value);
  }

  Future<bool> getNativeChatMutedUnread() async {
    return await PrefsDatabase.getBool(_kNativeChatMutedUnread, true);
  }

  Future setNativeChatMutedUnread(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatMutedUnread, value);
  }

  Future<List<String>> getNativeChatMarkedUnread() async {
    return await PrefsDatabase.getStringList(_kNativeChatMarkedUnread, <String>[]);
  }

  Future setNativeChatMarkedUnread(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatMarkedUnread, value);
  }

  Future<List<String>> getNativeChatWaitingDismissed() async {
    return await PrefsDatabase.getStringList(_kNativeChatWaitingDismissed, <String>[]);
  }

  Future setNativeChatWaitingDismissed(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatWaitingDismissed, value);
  }

  // 0 turns the waiting strip off
  Future<int> getNativeChatWaitingHours() async {
    return await PrefsDatabase.getInt(_kNativeChatWaitingHours, 3);
  }

  Future setNativeChatWaitingHours(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatWaitingHours, value);
  }

  // "roomId|level" pairs
  Future<List<String>> getNativeChatAlertLevels() async {
    return await PrefsDatabase.getStringList(_kNativeChatAlertLevels, <String>[]);
  }

  Future setNativeChatAlertLevels(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatAlertLevels, value);
  }

  Future<List<String>> getNativeChatPausedRooms() async {
    return await PrefsDatabase.getStringList(_kNativeChatPausedRooms, <String>[]);
  }

  Future setNativeChatPausedRooms(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatPausedRooms, value);
  }

  Future<List<String>> getNativeChatUnknownRooms() async {
    return await PrefsDatabase.getStringList(_kNativeChatUnknownRooms, <String>[]);
  }

  Future setNativeChatUnknownRooms(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatUnknownRooms, value);
  }

  Future<String> getNativeChatNotificationTap() async {
    return await PrefsDatabase.getString(_kNativeChatNotificationTap, "window");
  }

  Future setNativeChatNotificationTap(String value) async {
    return await PrefsDatabase.setString(_kNativeChatNotificationTap, value);
  }

  Future<bool> getNativeChatAlertNotify() async {
    return await PrefsDatabase.getBool(_kNativeChatAlertNotify, true);
  }

  Future setNativeChatAlertNotify(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatAlertNotify, value);
  }

  Future<List<String>> getNativeChatTones() async {
    return await PrefsDatabase.getStringList(_kNativeChatTones, <String>[]);
  }

  Future setNativeChatTones(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatTones, value);
  }

  Future<bool> getNativeChatSoundForAll() async {
    return await PrefsDatabase.getBool(_kNativeChatSoundForAll, false);
  }

  Future setNativeChatSoundForAll(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatSoundForAll, value);
  }

  Future<String> getNativeChatSoundForAllType() async {
    return await PrefsDatabase.getString(_kNativeChatSoundForAllType, 'keyboard');
  }

  Future setNativeChatSoundForAllType(String value) async {
    return await PrefsDatabase.setString(_kNativeChatSoundForAllType, value);
  }

  Future<bool> getNativeChatAlertVibrate() async {
    return await PrefsDatabase.getBool(_kNativeChatAlertVibrate, false);
  }

  Future setNativeChatAlertVibrate(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatAlertVibrate, value);
  }

  Future<bool> getNativeChatQuietHours() async {
    return await PrefsDatabase.getBool(_kNativeChatQuietHours, false);
  }

  Future setNativeChatQuietHours(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatQuietHours, value);
  }

  Future<int> getNativeChatQuietFrom() async {
    return await PrefsDatabase.getInt(_kNativeChatQuietFrom, 23 * 60);
  }

  Future setNativeChatQuietFrom(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatQuietFrom, value);
  }

  Future<int> getNativeChatQuietTo() async {
    return await PrefsDatabase.getInt(_kNativeChatQuietTo, 8 * 60);
  }

  Future setNativeChatQuietTo(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatQuietTo, value);
  }

  Future<String> getNativeChatTranslateTo() async {
    return await PrefsDatabase.getString(_kNativeChatTranslateTo, "");
  }

  Future setNativeChatTranslateTo(String value) async {
    return await PrefsDatabase.setString(_kNativeChatTranslateTo, value);
  }

  Future<bool> getNativeChatTicker() async {
    return await PrefsDatabase.getBool(_kNativeChatTicker, true);
  }

  Future setNativeChatTicker(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatTicker, value);
  }

  Future<String> getNativeChatLauncher() async {
    return await PrefsDatabase.getString(_kNativeChatLauncher, '');
  }

  Future setNativeChatLauncher(String value) async {
    return await PrefsDatabase.setString(_kNativeChatLauncher, value);
  }

  Future<String> getNativeChatLauncherTap() async {
    return await PrefsDatabase.getString(_kNativeChatLauncherTap, 'full');
  }

  Future setNativeChatLauncherTap(String value) async {
    return await PrefsDatabase.setString(_kNativeChatLauncherTap, value);
  }

  Future<bool> getNativeChatMiniBubbles() async {
    return await PrefsDatabase.getBool(_kNativeChatMiniBubbles, true);
  }

  Future setNativeChatMiniBubbles(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatMiniBubbles, value);
  }

  Future<bool> getNativeChatReopen() async {
    return await PrefsDatabase.getBool(_kNativeChatReopen, false);
  }

  Future setNativeChatReopen(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatReopen, value);
  }

  Future<String> getNativeChatTimes() async {
    return await PrefsDatabase.getString(_kNativeChatTimes, '');
  }

  Future setNativeChatTimes(String value) async {
    return await PrefsDatabase.setString(_kNativeChatTimes, value);
  }

  Future<String> getNativeChatAnimations() async {
    return await PrefsDatabase.getString(_kNativeChatAnimations, '');
  }

  Future setNativeChatAnimations(String value) async {
    return await PrefsDatabase.setString(_kNativeChatAnimations, value);
  }

  Future<bool> getNativeChatTickerTop() async {
    return await PrefsDatabase.getBool(_kNativeChatTickerTop, true);
  }

  Future setNativeChatTickerTop(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatTickerTop, value);
  }

  // Old setting, only read to migrate
  Future<String> getNativeChatImageAutoLoad() async {
    return await PrefsDatabase.getString(_kNativeChatImageAutoLoad, "torn");
  }

  Future<bool> getNativeChatImagesPrivate(bool defaultValue) async {
    return await PrefsDatabase.getBool(_kNativeChatImagesPrivate, defaultValue);
  }

  Future setNativeChatImagesPrivate(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatImagesPrivate, value);
  }

  Future<bool> getNativeChatImagesPublic(bool defaultValue) async {
    return await PrefsDatabase.getBool(_kNativeChatImagesPublic, defaultValue);
  }

  Future setNativeChatImagesPublic(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatImagesPublic, value);
  }

  Future<String> getNativeChatLinkPreviews() async {
    return await PrefsDatabase.getString(_kNativeChatLinkPreviews, "always");
  }

  Future setNativeChatLinkPreviews(String value) async {
    return await PrefsDatabase.setString(_kNativeChatLinkPreviews, value);
  }

  Future<List<String>> getNativeChatLinkPreviewsOff(List<String> fallback) async {
    return await PrefsDatabase.getStringList(_kNativeChatLinkPreviewsOff, fallback);
  }

  Future setNativeChatLinkPreviewsOff(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatLinkPreviewsOff, value);
  }

  Future<bool> getNativeChatLinkWindow() async {
    return await PrefsDatabase.getBool(_kNativeChatLinkWindow, true);
  }

  Future setNativeChatLinkWindow(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatLinkWindow, value);
  }

  Future<bool> getNativeChatLinkNewTab() async {
    return await PrefsDatabase.getBool(_kNativeChatLinkNewTab, false);
  }

  Future setNativeChatLinkNewTab(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatLinkNewTab, value);
  }

  Future<String> getNativeChatSwipeLeft() async {
    return await PrefsDatabase.getString(_kNativeChatSwipeLeft, "message");
  }

  Future setNativeChatSwipeLeft(String value) async {
    return await PrefsDatabase.setString(_kNativeChatSwipeLeft, value);
  }

  Future<String> getChatImgurClientId() async {
    return await PrefsDatabase.getString(_kChatImgurClientId, "");
  }

  Future setChatImgurClientId(String value) async {
    return await PrefsDatabase.setString(_kChatImgurClientId, value);
  }

  Future<String> getChatImageHost() async {
    return await PrefsDatabase.getString(_kChatImageHost, "");
  }

  Future setChatImageHost(String value) async {
    return await PrefsDatabase.setString(_kChatImageHost, value);
  }

  Future<int> getChatImgbbExpiration() async {
    return await PrefsDatabase.getInt(_kChatImgbbExpiration, 0);
  }

  Future setChatImgbbExpiration(int value) async {
    return await PrefsDatabase.setInt(_kChatImgbbExpiration, value);
  }

  Future<String> getChatImgbbKey() async {
    return await PrefsDatabase.getString(_kChatImgbbKey, "");
  }

  Future setChatImgbbKey(String value) async {
    return await PrefsDatabase.setString(_kChatImgbbKey, value);
  }

  Future<String> getChatCatboxUserhash() async {
    return await PrefsDatabase.getString(_kChatCatboxUserhash, "");
  }

  Future setChatCatboxUserhash(String value) async {
    return await PrefsDatabase.setString(_kChatCatboxUserhash, value);
  }

  Future<List<String>> getNativeChatTickerLevels() async {
    return await PrefsDatabase.getStringList(_kNativeChatTickerLevels, <String>[]);
  }

  Future setNativeChatTickerLevels(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatTickerLevels, value);
  }

  Future<String> getNativeChatTickerTap() async {
    return await PrefsDatabase.getString(_kNativeChatTickerTap, "window");
  }

  Future setNativeChatTickerTap(String value) async {
    return await PrefsDatabase.setString(_kNativeChatTickerTap, value);
  }

  Future<int> getNativeChatTickerSeconds() async {
    return await PrefsDatabase.getInt(_kNativeChatTickerSeconds, 6);
  }

  Future setNativeChatTickerSeconds(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatTickerSeconds, value);
  }

  Future<int> getNativeChatTickerMax() async {
    return await PrefsDatabase.getInt(_kNativeChatTickerMax, 2);
  }

  Future setNativeChatTickerMax(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatTickerMax, value);
  }

  Future<int> getNativeChatTickerLines() async {
    return await PrefsDatabase.getInt(_kNativeChatTickerLines, 1);
  }

  Future setNativeChatTickerLines(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatTickerLines, value);
  }

  Future<String> getNativeChatGlowMode() async {
    return await PrefsDatabase.getString(_kNativeChatGlowMode, "ticker");
  }

  Future setNativeChatGlowMode(String value) async {
    return await PrefsDatabase.setString(_kNativeChatGlowMode, value);
  }

  Future<List<String>> getNativeChatGlowLevels() async {
    return await PrefsDatabase.getStringList(_kNativeChatGlowLevels, <String>[]);
  }

  Future setNativeChatGlowLevels(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatGlowLevels, value);
  }

  Future<List<String>> getNativeChatWindowFrame() async {
    return await PrefsDatabase.getStringList(_kNativeChatWindowFrame, <String>[]);
  }

  Future setNativeChatWindowFrame(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatWindowFrame, value);
  }

  Future<List<String>> getNativeChatWindows() async {
    return await PrefsDatabase.getStringList(_kNativeChatWindows, <String>[]);
  }

  Future setNativeChatWindows(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatWindows, value);
  }

  Future<List<String>> getNativeChatBigWindow() async {
    return await PrefsDatabase.getStringList(_kNativeChatBigWindow, <String>[]);
  }

  Future setNativeChatBigWindow(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatBigWindow, value);
  }

  Future<List<String>> getNativeChatOnScreen() async {
    return await PrefsDatabase.getStringList(_kNativeChatOnScreen, <String>[]);
  }

  Future setNativeChatOnScreen(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatOnScreen, value);
  }

  Future<List<String>> getNativeChatBubbleSpot() async {
    return await PrefsDatabase.getStringList(_kNativeChatBubbleSpot, <String>[]);
  }

  Future setNativeChatBubbleSpot(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatBubbleSpot, value);
  }

  Future<List<String>> getNativeChatIgnored() async {
    return await PrefsDatabase.getStringList(_kNativeChatIgnored, <String>[]);
  }

  Future setNativeChatIgnored(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatIgnored, value);
  }

  Future<List<String>> getNativeChatFriends() async {
    return await PrefsDatabase.getStringList(_kNativeChatFriends, <String>[]);
  }

  Future setNativeChatFriends(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatFriends, value);
  }

  Future<String> getNativeChatFriendsTab() async {
    return await PrefsDatabase.getString(_kNativeChatFriendsTab, "");
  }

  Future setNativeChatFriendsTab(String value) async {
    return await PrefsDatabase.setString(_kNativeChatFriendsTab, value);
  }

  Future<String> getNativeChatFriendsSort() async {
    return await PrefsDatabase.getString(_kNativeChatFriendsSort, "status");
  }

  Future setNativeChatFriendsSort(String value) async {
    return await PrefsDatabase.setString(_kNativeChatFriendsSort, value);
  }

  Future<String> getNativeChatRosterSort() async {
    return await PrefsDatabase.getString(_kNativeChatRosterSort, "status");
  }

  Future setNativeChatRosterSort(String value) async {
    return await PrefsDatabase.setString(_kNativeChatRosterSort, value);
  }

  Future<bool> getNativeChatRosterReversed() async {
    return await PrefsDatabase.getBool(_kNativeChatRosterReversed, false);
  }

  Future setNativeChatRosterReversed(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatRosterReversed, value);
  }

  Future<List<String>> getNativeChatRosterFilters() async {
    return await PrefsDatabase.getStringList(_kNativeChatRosterFilters, <String>[]);
  }

  Future setNativeChatRosterFilters(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatRosterFilters, value);
  }

  Future<String> getNativeChatPlayerNotes() async {
    return await PrefsDatabase.getString(_kNativeChatPlayerNotes, "{}");
  }

  Future setNativeChatPlayerNotes(String value) async {
    return await PrefsDatabase.setString(_kNativeChatPlayerNotes, value);
  }

  Future<String> getNativeChatPeople() async {
    return await PrefsDatabase.getString(_kNativeChatPeople, "{}");
  }

  Future setNativeChatPeople(String value) async {
    return await PrefsDatabase.setString(_kNativeChatPeople, value);
  }

  Future<String> getNativeChatRoomFilters() async {
    return await PrefsDatabase.getString(_kNativeChatRoomFilters, "{}");
  }

  Future setNativeChatRoomFilters(String value) async {
    return await PrefsDatabase.setString(_kNativeChatRoomFilters, value);
  }

  Future<String> getNativeChatDrafts() async {
    return await PrefsDatabase.getString(_kNativeChatDrafts, "{}");
  }

  Future setNativeChatDrafts(String value) async {
    return await PrefsDatabase.setString(_kNativeChatDrafts, value);
  }

  Future<String> getNativeChatSaved() async {
    return await PrefsDatabase.getString(_kNativeChatSaved, "[]");
  }

  Future setNativeChatSaved(String value) async {
    return await PrefsDatabase.setString(_kNativeChatSaved, value);
  }

  Future<List<String>> getNativeChatShortcutCache() async {
    return await PrefsDatabase.getStringList(_kNativeChatShortcutCache, <String>[]);
  }

  Future setNativeChatShortcutCache(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatShortcutCache, value);
  }

  Future<int> getNativeChatPausedAt() async {
    return await PrefsDatabase.getInt(_kNativeChatPausedAt, 0);
  }

  Future setNativeChatPausedAt(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatPausedAt, value);
  }

  Future<List<String>> getNativeChatQuickReplies() async {
    return await PrefsDatabase.getStringList(_kNativeChatQuickReplies, <String>[
      'Price?',
      'Still available?',
      'Sold, sorry',
      'Sending now',
      'Trade sent',
      'Thanks!',
      'Hi {name}, landing in {landing}',
      'WTS {item} {price}',
    ]);
  }

  Future setNativeChatQuickReplies(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatQuickReplies, value);
  }

  Future<List<String>> getNativeChatStatusPieces() async {
    return await PrefsDatabase.getStringList(_kNativeChatStatusPieces, <String>[
      'energy',
      'nerve',
      'travel',
      'hospital',
    ]);
  }

  Future setNativeChatStatusPieces(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatStatusPieces, value);
  }

  Future<List<String>> getNativeChatQuickOrder() async {
    return await PrefsDatabase.getStringList(_kNativeChatQuickOrder, <String>[]);
  }

  Future setNativeChatQuickOrder(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatQuickOrder, value);
  }

  Future<List<String>> getNativeChatQuickHidden() async {
    return await PrefsDatabase.getStringList(_kNativeChatQuickHidden, <String>[]);
  }

  Future setNativeChatQuickHidden(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatQuickHidden, value);
  }

  Future<int> getNativeChatQuickRows() async {
    return await PrefsDatabase.getInt(_kNativeChatQuickRows, 0);
  }

  Future<List<String>> getNativeChatQuickRowTypes() async {
    return await PrefsDatabase.getStringList(_kNativeChatQuickRowTypes, <String>[]);
  }

  Future setNativeChatQuickRowTypes(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatQuickRowTypes, value);
  }

  Future setNativeChatQuickRows(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatQuickRows, value);
  }

  Future<List<String>> getNativeChatMessageActionOrder() async {
    return await PrefsDatabase.getStringList(_kNativeChatMessageActionOrder, <String>[]);
  }

  Future setNativeChatMessageActionOrder(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatMessageActionOrder, value);
  }

  Future<List<String>> getNativeChatMessageActionHidden() async {
    return await PrefsDatabase.getStringList(_kNativeChatMessageActionHidden, <String>[]);
  }

  Future setNativeChatMessageActionHidden(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatMessageActionHidden, value);
  }

  Future<List<String>> getNativeChatEmojiFavorites(List<String> fallback) async {
    return await PrefsDatabase.getStringList(_kNativeChatEmojiFavorites, fallback);
  }

  Future setNativeChatEmojiFavorites(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatEmojiFavorites, value);
  }

  Future<List<String>> getNativeChatEmojiCounts() async {
    return await PrefsDatabase.getStringList(_kNativeChatEmojiCounts, <String>[]);
  }

  Future setNativeChatEmojiCounts(List<String> value) async {
    return await PrefsDatabase.setStringList(_kNativeChatEmojiCounts, value);
  }

  Future<bool> getNativeChatItemPrice() async {
    return await PrefsDatabase.getBool(_kNativeChatItemPrice, true);
  }

  Future setNativeChatItemPrice(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatItemPrice, value);
  }

  Future<String> getNativeChatItemAliases() async {
    return await PrefsDatabase.getString(_kNativeChatItemAliases, '');
  }

  Future setNativeChatItemAliases(String value) async {
    return await PrefsDatabase.setString(_kNativeChatItemAliases, value);
  }

  Future<bool> getNativeChatPriceCheck() async {
    return await PrefsDatabase.getBool(_kNativeChatPriceCheck, true);
  }

  Future setNativeChatPriceCheck(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatPriceCheck, value);
  }

  Future<bool> getNativeChatBazaarAnalysis() async {
    return await PrefsDatabase.getBool(_kNativeChatBazaarAnalysis, true);
  }

  Future setNativeChatBazaarAnalysis(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatBazaarAnalysis, value);
  }

  Future<bool> getNativeChatSlangEverywhere() async {
    return await PrefsDatabase.getBool(_kNativeChatSlangEverywhere, false);
  }

  Future setNativeChatSlangEverywhere(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatSlangEverywhere, value);
  }

  Future<bool> getNativeChatMoneyOnHand() async {
    return await PrefsDatabase.getBool(_kNativeChatMoneyOnHand, false);
  }

  Future setNativeChatMoneyOnHand(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatMoneyOnHand, value);
  }

  Future<bool> getNativeChatWarnApiKey() async {
    return await PrefsDatabase.getBool(_kNativeChatWarnApiKey, true);
  }

  Future setNativeChatWarnApiKey(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatWarnApiKey, value);
  }

  Future<bool> getNativeChatConfirmPublic() async {
    return await PrefsDatabase.getBool(_kNativeChatConfirmPublic, false);
  }

  Future setNativeChatConfirmPublic(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatConfirmPublic, value);
  }

  Future<bool> getNativeChatPlayerColors() async {
    return await PrefsDatabase.getBool(_kNativeChatPlayerColors, true);
  }

  Future setNativeChatPlayerColors(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatPlayerColors, value);
  }

  Future<bool> getNativeChatCompactMode() async {
    return await PrefsDatabase.getBool(_kNativeChatCompactMode, false);
  }

  Future setNativeChatCompactMode(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatCompactMode, value);
  }

  Future<bool> getNativeChatShowAvatars() async {
    return await PrefsDatabase.getBool(_kNativeChatShowAvatars, true);
  }

  Future setNativeChatShowAvatars(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatShowAvatars, value);
  }

  Future<double> getNativeChatTextScale() async {
    return await PrefsDatabase.getDouble(_kNativeChatTextScale, 1);
  }

  Future setNativeChatTextScale(double value) async {
    return await PrefsDatabase.setDouble(_kNativeChatTextScale, value);
  }

  Future<int> getNativeChatPreviewLines() async {
    return await PrefsDatabase.getInt(_kNativeChatPreviewLines, 1);
  }

  Future setNativeChatPreviewLines(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatPreviewLines, value);
  }

  Future<double> getNativeChatListTextScale() async {
    return await PrefsDatabase.getDouble(_kNativeChatListTextScale, 1);
  }

  Future setNativeChatListTextScale(double value) async {
    return await PrefsDatabase.setDouble(_kNativeChatListTextScale, value);
  }

  Future<int> getNativeChatListReplyCount() async {
    return await PrefsDatabase.getInt(_kNativeChatListReplyCount, 3);
  }

  Future setNativeChatListReplyCount(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatListReplyCount, value);
  }

  Future<bool> getNativeChatListReply() async {
    return await PrefsDatabase.getBool(_kNativeChatListReply, true);
  }

  Future setNativeChatListReply(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatListReply, value);
  }

  Future<String> getNativeChatColors() async {
    return await PrefsDatabase.getString(_kNativeChatColors, "{}");
  }

  Future setNativeChatColors(String value) async {
    return await PrefsDatabase.setString(_kNativeChatColors, value);
  }

  Future<bool> getNativeChatFactionChain() async {
    return await PrefsDatabase.getBool(_kNativeChatFactionChain, true);
  }

  Future setNativeChatFactionChain(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatFactionChain, value);
  }

  Future<int> getNativeChatLastChainReport() async {
    return await PrefsDatabase.getInt(_kNativeChatLastChainReport, 0);
  }

  Future setNativeChatLastChainReport(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatLastChainReport, value);
  }

  Future<int> getNativeChatLastWarReport() async {
    return await PrefsDatabase.getInt(_kNativeChatLastWarReport, 0);
  }

  Future setNativeChatLastWarReport(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatLastWarReport, value);
  }

  Future<bool> getNativeChatFactionWar() async {
    return await PrefsDatabase.getBool(_kNativeChatFactionWar, true);
  }

  Future setNativeChatFactionWar(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatFactionWar, value);
  }

  Future<bool> getNativeChatChainSheetWar() async {
    return await PrefsDatabase.getBool(_kNativeChatChainSheetWar, false);
  }

  Future<int> getNativeChatChainSheetTab() async {
    return await PrefsDatabase.getInt(_kNativeChatChainSheetTab, -1);
  }

  Future setNativeChatChainSheetTab(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatChainSheetTab, value);
  }

  Future<bool> getNativeChatHitCallLink() async {
    return await PrefsDatabase.getBool(_kNativeChatHitCallLink, true);
  }

  Future setNativeChatHitCallLink(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatHitCallLink, value);
  }

  Future<bool> getNativeChatWatchTurnsOnWatcher() async {
    return await PrefsDatabase.getBool(_kNativeChatWatchTurnsOnWatcher, true);
  }

  Future setNativeChatWatchTurnsOnWatcher(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatWatchTurnsOnWatcher, value);
  }

  Future<bool> getNativeChatWatchRetals() async {
    return await PrefsDatabase.getBool(_kNativeChatWatchRetals, false);
  }

  Future setNativeChatWatchRetals(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatWatchRetals, value);
  }

  Future<int> getNativeChatWatchHours() async {
    return await PrefsDatabase.getInt(_kNativeChatWatchHours, 1);
  }

  Future setNativeChatWatchHours(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatWatchHours, value);
  }

  Future<bool> getNativeChatFactionEnemyChain() async {
    return await PrefsDatabase.getBool(_kNativeChatFactionEnemyChain, true);
  }

  Future setNativeChatFactionEnemyChain(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatFactionEnemyChain, value);
  }

  Future<bool> getNativeChatFactionEvents() async {
    return await PrefsDatabase.getBool(_kNativeChatFactionEvents, false);
  }

  Future setNativeChatFactionEvents(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatFactionEvents, value);
  }

  Future<bool> getNativeChatFactionEventsDenied() async {
    return await PrefsDatabase.getBool(_kNativeChatFactionEventsDenied, false);
  }

  Future setNativeChatFactionEventsDenied(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatFactionEventsDenied, value);
  }

  Future<String> getNativeChatPinnedMessages() async {
    return await PrefsDatabase.getString(_kNativeChatPinnedMessages, "{}");
  }

  Future setNativeChatPinnedMessages(String value) async {
    return await PrefsDatabase.setString(_kNativeChatPinnedMessages, value);
  }

  Future<bool> getNativeChatIntroSeen() async {
    return await PrefsDatabase.getBool(_kNativeChatIntroSeen, false);
  }

  Future setNativeChatIntroSeen(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatIntroSeen, value);
  }

  Future<String> getNativeChatReminders() async {
    return await PrefsDatabase.getString(_kNativeChatReminders, "[]");
  }

  Future setNativeChatReminders(String value) async {
    return await PrefsDatabase.setString(_kNativeChatReminders, value);
  }

  Future<String> getNativeChatInbox() async {
    return await PrefsDatabase.getString(_kNativeChatInbox, "");
  }

  Future setNativeChatInbox(String value) async {
    return await PrefsDatabase.setString(_kNativeChatInbox, value);
  }

  Future<int> getNativeChatOwner() async {
    return await PrefsDatabase.getInt(_kNativeChatOwner, 0);
  }

  Future setNativeChatOwner(int value) async {
    return await PrefsDatabase.setInt(_kNativeChatOwner, value);
  }

  Future<bool> getNativeChatRemoteEnabled() async {
    return await PrefsDatabase.getBool(_kNativeChatRemoteEnabled, true);
  }

  Future setNativeChatRemoteEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kNativeChatRemoteEnabled, value);
  }

  Future<bool> getTornChatDmPush() async {
    return await PrefsDatabase.getBool(_kTornChatDmPush, true);
  }

  Future setTornChatDmPush(bool value) async {
    await PrefsDatabase.setBool(_kTornChatDmPush, value);
    await BackgroundPrefs().setTornChatDmPush(value);
  }
}
