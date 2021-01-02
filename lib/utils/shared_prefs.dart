import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SharedPreferencesModel {
  ///
  /// Instantiation of the SharedPreferences library
  ///
  final String _kAppVersion = "pda_appVersion";
  final String _kOwnDetails = "pda_ownDetails";
  final String _kLastAppUse = "pda_lastAppUse";
  final String _kTargetsList = "pda_targetsList";
  final String _kTargetsSort = "pda_targetsSort";
  final String _kTargetSkipping = "pda_targetSkipping";
  final String _kShowTargetsNotes = "pda_showTargetsNotes";
  final String _kChainWatcherSound = "pda_chainWatcherSound";
  final String _kChainWatcherVibration = "pda_chainWatcherVibration";
  final String _kYataTargetsEnabled = "pda_yataTargetsEnabled";
  final String _kAttacksSort = "pda_attacksSort";
  final String _kFriendsList = "pda_friendsList";
  final String _kFriendsSort = "pda_friendsSort";
  final String _kTheme = "pda_theme";
  final String _kDefaultSection = "pda_defaultSection";
  final String _kDefaultBrowser = "pda_defaultBrowser";
  final String _kOnAppExit = "pda_onAppExit";
  final String _kLoadBarBrowser = "pda_loadBarBrowser";
  final String _kUseQuickBrowser = "pda_useQuickBrowser";
  final String _kTestBrowserActive = "pda_testBrowserActive";
  final String _kDefaultTimeFormat = "pda_defaultTimeFormat";
  final String _kDefaultTimeZone = "pda_defaultTimeZone";
  final String _kAppBarPosition = "pda_AppBarPosition";
  final String _kTravelNotificationTitle = "pda_travelNotificationTitle";
  final String _kTravelNotificationBody = "pda_travelNotificationBody";
  final String _kTravelNotificationAhead = "pda_travelNotificationAhead";
  final String _kTravelAlarmAhead = "pda_travelAlarmAhead";
  final String _kTravelTimerAhead = "pda_travelTimerAhead";
  final String _kTravelAlarmSound = "pda_travelAlarmSound";
  final String _kTravelAlarmVibration = "pda_travelAlarmVibration";
  final String _kStockCountryFilter = "pda_stockCountryFilter";
  final String _kStockTypeFilter = "pda_stockTypeFilter";
  final String _kStockSort = "pda_stockSort";
  final String _kStockCapacity = "pda_stockCapacity";
  final String _kShowForeignInventory = "pda_showForeignInventory";
  final String _kTravelNotificationType = "pda_travelNotificationType";
  final String _kEnergyNotificationType = "pda_energyNotificationType";
  final String _kEnergyNotificationValue = "pda_energyNotificationValue";
  final String _kEnergyCustomOverride = "pda_energyCustomOverride";
  final String _kNerveNotificationValue = "pda_nerveNotificationValue";
  final String _kNerveCustomOverride = "pda_nerveCustomOverride";
  final String _kNerveNotificationType = "pda_nerveNotificationType";
  final String _kLifeNotificationType = "pda_lifeNotificationType";
  final String _kDrugNotificationType = "pda_drugNotificationType";
  final String _kMedicalNotificationType = "pda_medicalNotificationType";
  final String _kBoosterNotificationType = "pda_boosterNotificationType";
  final String _kProfileAlarmVibration = "pda_profileAlarmVibration";
  final String _kProfileAlarmSound = "pda_profileAlarmSound";
  final String _kEnableShortcuts = "pda_enableShortcuts";
  final String _kShortcutTile = "pda_shortcutTile";
  final String _kShortcutMenu = "pda_shortcutMenu";
  final String _kActiveShortcutsList = "pda_activeShortcutsList";
  final String _kUseNukeRevive = "pda_useNukeRevive";
  final String _kWarnAboutChains = "pda_warnAboutChains";
  final String _kExpandEvents = "pda_ExpandEvents";
  final String _kExpandMessages = "pda_ExpandMessages";
  final String _kMessagesShowNumber = "pda_messagesShowNumber";
  final String _kEventsShowNumber = "pda_eventsShowNumber";
  final String _kExpandBasicInfo = "pda_ExpandBasicInfo";
  final String _kExpandNetworth = "pda_ExpandNetworth";
  final String _kActiveCrimesList = "pda_activeCrimesList";
  final String _kQuickItemsList = "pda_quickItemsList";
  final String _kLootYataCache = "pda_lootYataCache";
  final String _kLootTimerType = "pda_lootTimerType";
  final String _kLootNotificationType = "pda_lootNotificationType";
  final String _kLootNotificationAhead = "pda_lootNotificationAhead";
  final String _kLootAlarmAhead = "pda_lootAlarmAhead";
  final String _kLootTimerAhead = "pda_lootTimerAhead";
  final String _kLootAlarmVibration = "pda_lootAlarmVibration";
  final String _kLootAlarmSound = "pda_lootAlarmSound";
  final String _kTradeCalculatorEnabled = "pda_tradeCalculatorActive";
  final String _kTornTraderEnabled = "pda_tornTraderActive";
  final String _kCityFinderEnabled = "pda_cityFinderActive";
  final String _kAwardsSort = "pda_awardsSort";
  final String _kShowAchievedAwards = "pda_showAchievedAwards";
  final String _kHiddenAwardCategories = "pda_hiddenAwardCategories";
  final String _kChatRemovalEnabled = "pda_chatRemovalEnabled";
  final String _kChatRemovalActive = "pda_chatRemovalActive";
  final String _kHighlightChat = "pda_highlightChat";
  final String _kHighlightColor = "pda_highlightColor";


  /// This is use for transitioning from v1.2.0 onwards. After 1.2.0, use
  /// UserDetailsProvider for retrieving the API key and other details!
  @deprecated
  final String _kApiKey = "pda_apiKey";

  /// ----------------------------
  /// Methods for app version
  /// ----------------------------
  Future<String> getAppVersion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAppVersion) ?? "";
  }

  Future<bool> setAppVersion(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAppVersion, value);
  }

  /// ----------------------------
  /// Methods for identification
  /// ----------------------------
  Future<String> getOwnDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kOwnDetails) ?? "";
  }

  Future<bool> setOwnDetails(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kOwnDetails, value);
  }

  /// ----------------------------
  /// Methods for identification
  /// ----------------------------
  Future<int> getLastAppUse() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLastAppUse) ?? 0;
  }

  Future<bool> setLastAppUse(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kLastAppUse, value);
  }

  /// This is use for transitioning from v1.2.0 onwards. After 1.2.0, use
  /// UserDetailsProvider for retrieving the API key and other details!
  @deprecated
  Future<String> getApiKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kApiKey) ?? "";
  }

  /// This is use for transitioning from v1.2.0 onwards. After 1.2.0, use
  /// UserDetailsProvider for retrieving the API key and other details!
  @deprecated
  Future<bool> setApiKey(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kApiKey, value);
  }

  /// ----------------------------
  /// Methods for targets
  /// ----------------------------
  Future<List<String>> getTargetsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kTargetsList) ?? <String>[];
  }

  Future<bool> setTargetsList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kTargetsList, value);
  }

  //**************
  Future<String> getTargetsSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTargetsSort) ?? '';
  }

  Future<bool> setTargetsSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTargetsSort, value);
  }

  Future<bool> getTargetSkipping() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTargetSkipping) ?? true;
  }

  Future<bool> setTargetSkipping(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTargetSkipping, value);
  }

  Future<bool> getShowTargetsNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTargetsNotes) ?? true;
  }

  Future<bool> setShowTargetsNotes(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowTargetsNotes, value);
  }

  Future<bool> getChainWatcherSound() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kChainWatcherSound) ?? true;
  }

  Future<bool> setChainWatcherSound(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kChainWatcherSound, value);
  }

  Future<bool> getChainWatcherVibration() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kChainWatcherVibration) ?? true;
  }

  Future<bool> setChainWatcherVibration(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kChainWatcherVibration, value);
  }

  Future<bool> getYataTargetsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kYataTargetsEnabled) ?? true;
  }

  Future<bool> setYataTargetsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kYataTargetsEnabled, value);
  }

  /// ----------------------------
  /// Methods for attacks
  /// ----------------------------
  Future<String> getAttackSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAttacksSort) ?? '';
  }

  Future<bool> setAttackSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAttacksSort, value);
  }

  /// ----------------------------
  /// Methods for friends
  /// ----------------------------
  Future<List<String>> getFriendsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kFriendsList) ?? <String>[];
  }

  Future<bool> setFriendsList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kFriendsList, value);
  }

  //**************
  Future<String> getFriendsSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFriendsSort) ?? '';
  }

  Future<bool> setFriendsSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kFriendsSort, value);
  }

  /// ----------------------------
  /// Methods for theme
  /// ----------------------------
  Future<String> getAppTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTheme) ?? 'light';
  }

  Future<bool> setAppTheme(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTheme, value);
  }

  /// ----------------------------
  /// Methods for default launch section
  /// ----------------------------
  Future<String> getDefaultSection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultSection) ?? '0';
  }

  Future<bool> setDefaultSection(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultSection, value);
  }

  /// ----------------------------
  /// Methods for on app exit
  /// ----------------------------
  Future<String> getOnAppExit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kOnAppExit) ?? 'ask';
  }

  Future<bool> setOnAppExit(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kOnAppExit, value);
  }

  /// ----------------------------
  /// Methods for default browser
  /// ----------------------------
  Future<String> getDefaultBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultBrowser) ?? 'app';
  }

  Future<bool> setDefaultBrowser(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultBrowser, value);
  }

  Future<bool> getLoadBarBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoadBarBrowser) ?? true;
  }

  Future<bool> setLoadBarBrowser(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kLoadBarBrowser, value);
  }

  Future<bool> getUseQuickBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseQuickBrowser) ?? true;
  }

  Future<bool> setUseQuickBrowser(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseQuickBrowser, value);
  }

  /// ----------------------------
  /// Methods for default browser
  /// ----------------------------
  Future<bool> getTestBrowserActive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTestBrowserActive) ?? false;
  }

  Future<bool> setTestBrowserActive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTestBrowserActive, value);
  }

  /// ----------------------------
  /// Methods for default time format
  /// ----------------------------
  Future<String> getDefaultTimeFormat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultTimeFormat) ?? '24';
  }

  Future<bool> setDefaultTimeFormat(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultTimeFormat, value);
  }

  /// ----------------------------
  /// Methods for default time zone
  /// ----------------------------
  Future<String> getDefaultTimeZone() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultTimeZone) ?? 'local';
  }

  Future<bool> setDefaultTimeZone(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultTimeZone, value);
  }

  /// ----------------------------
  /// Methods for appBar position
  /// ----------------------------
  Future<String> getAppBarPosition() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAppBarPosition) ?? 'top';
  }

  Future<bool> setAppBarPosition(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAppBarPosition, value);
  }

  /// ----------------------------
  /// Methods for travel options
  /// ----------------------------
  Future<String> getTravelNotificationTitle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelNotificationTitle) ?? 'TORN TRAVEL';
  }

  Future<bool> setTravelNotificationTitle(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelNotificationTitle, value);
  }

  Future<String> getTravelNotificationBody() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelNotificationBody) ??
        'Arriving at your destination!';
  }

  Future<bool> setTravelNotificationBody(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelNotificationBody, value);
  }

  Future<String> getTravelNotificationAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelNotificationAhead) ?? '0';
  }

  Future<bool> setTravelNotificationAhead(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelNotificationAhead, value);
  }

  Future<String> getTravelAlarmAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelAlarmAhead) ?? '0';
  }

  Future<bool> setTravelAlarmAhead(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelAlarmAhead, value);
  }

  Future<String> getTravelTimerAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelTimerAhead) ?? '0';
  }

  Future<bool> setTravelTimerAhead(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelTimerAhead, value);
  }

  Future<bool> getTravelAlarmSound() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelAlarmSound) ?? true;
  }

  Future<bool> setTravelAlarmSound(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelAlarmSound, value);
  }

  Future<bool> getTravelAlarmVibration() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelAlarmVibration) ?? true;
  }

  Future<bool> setTravelAlarmVibration(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelAlarmVibration, value);
  }

  /// ----------------------------
  /// Methods for foreign stocks
  /// ----------------------------
  Future<List<String>> getStockCountryFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStockCountryFilter) ??
        List<String>.filled(12, '1', growable: false);
  }

  Future<bool> setStockCountryFilter(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kStockCountryFilter, value);
  }

  Future<List<String>> getStockTypeFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStockTypeFilter) ??
        List<String>.filled(4, '1', growable: false);
  }

  Future<bool> setStockTypeFilter(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kStockTypeFilter, value);
  }

  Future<String> getStockSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kStockSort) ?? 'profit';
  }

  Future<bool> setStockSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kStockSort, value);
  }

  Future<int> getStockCapacity() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStockCapacity) ?? 1;
  }

  Future<bool> setStockCapacity(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kStockCapacity, value);
  }

  Future<bool> getShowForeignInventory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowForeignInventory) ?? true;
  }

  Future<bool> setShowForeignInventory(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowForeignInventory, value);
  }

  /// ----------------------------
  /// Methods for notification types
  /// ----------------------------
  Future<String> getTravelNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelNotificationType) ?? '0';
  }

  Future<bool> setTravelNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelNotificationType, value);
  }

  Future<String> getEnergyNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEnergyNotificationType) ?? '0';
  }

  Future<bool> setEnergyNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kEnergyNotificationType, value);
  }

  Future<int> getEnergyNotificationValue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kEnergyNotificationValue) ?? 0;
  }

  Future<bool> setEnergyNotificationValue(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kEnergyNotificationValue, value);
  }

  Future<bool> setEnergyPercentageOverride(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kEnergyCustomOverride, value);
  }

  Future<bool> getEnergyPercentageOverride() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnergyCustomOverride) ?? false;
  }

  Future<String> getNerveNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNerveNotificationType) ?? '0';
  }

  Future<bool> setNerveNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kNerveNotificationType, value);
  }

  Future<int> getNerveNotificationValue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kNerveNotificationValue) ?? 0;
  }

  Future<bool> setNerveNotificationValue(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kNerveNotificationValue, value);
  }

  Future<bool> setNervePercentageOverride(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kNerveCustomOverride, value);
  }

  Future<bool> getNervePercentageOverride() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNerveCustomOverride) ?? false;
  }

  Future<String> getLifeNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLifeNotificationType) ?? '0';
  }

  Future<bool> setLifeNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLifeNotificationType, value);
  }

  Future<String> getDrugNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDrugNotificationType) ?? '0';
  }

  Future<bool> setDrugNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDrugNotificationType, value);
  }

  Future<String> getMedicalNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMedicalNotificationType) ?? '0';
  }

  Future<bool> setMedicalNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kMedicalNotificationType, value);
  }

  Future<String> getBoosterNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBoosterNotificationType) ?? '0';
  }

  Future<bool> setBoosterNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kBoosterNotificationType, value);
  }

  Future<bool> getProfileAlarmVibration() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kProfileAlarmVibration) ?? true;
  }

  Future<bool> setProfileAlarmVibration(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kProfileAlarmVibration, value);
  }

  Future<bool> getProfileAlarmSound() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kProfileAlarmSound) ?? true;
  }

  Future<bool> setProfileAlarmSound(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kProfileAlarmSound, value);
  }

  Future<bool> getEnableShortcuts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnableShortcuts) ?? true;
  }

  Future<bool> setEnableShortcuts(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kEnableShortcuts, value);
  }

  Future<bool> getUseNukeRevive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseNukeRevive) ?? true;
  }

  Future<bool> setUseNukeRevive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseNukeRevive, value);
  }

  Future<bool> getWarnAboutChains() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWarnAboutChains) ?? true;
  }

  Future<bool> setWarnAboutChains(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kWarnAboutChains, value);
  }

  Future<bool> getExpandEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kExpandEvents) ?? false;
  }

  Future<bool> setExpandEvents(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kExpandEvents, value);
  }

  Future<int> getEventsShowNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kEventsShowNumber) ?? 25;
  }

  Future<bool> setEventsShowNumber(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kEventsShowNumber, value);
  }

  Future<bool> getExpandMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kExpandMessages) ?? false;
  }

  Future<bool> setExpandMessages(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kExpandMessages, value);
  }

  Future<int> getMessagesShowNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kMessagesShowNumber) ?? 25;
  }

  Future<bool> setMessagesShowNumber(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kMessagesShowNumber, value);
  }

  Future<bool> getExpandBasicInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kExpandBasicInfo) ?? false;
  }

  Future<bool> setExpandBasicInfo(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kExpandBasicInfo, value);
  }

  Future<bool> getExpandNetworth() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kExpandNetworth) ?? false;
  }

  Future<bool> setExpandNetworth(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kExpandNetworth, value);
  }

  /// ----------------------------
  /// Methods for shortcuts
  /// ----------------------------
  Future<String> getShortcutTile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShortcutTile) ?? 'both';
  }

  Future<bool> setShortcutTile(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kShortcutTile, value);
  }

  Future<String> getShortcutMenu() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShortcutMenu) ?? 'carousel';
  }

  Future<bool> setShortcutMenu(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kShortcutMenu, value);
  }

  Future<List<String>> getActiveShortcutsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kActiveShortcutsList) ?? <String>[];
  }

  Future<bool> setActiveShortcutsList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kActiveShortcutsList, value);
  }

  /// ----------------------------
  /// Methods for easy crimes
  /// ----------------------------
  Future<List<String>> getActiveCrimesList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kActiveCrimesList) ?? <String>[];
  }

  Future<bool> setActiveCrimesList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kActiveCrimesList, value);
  }

  /// ----------------------------
  /// Methods for quick items
  /// ----------------------------
  Future<List<String>> getQuickItemsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kQuickItemsList) ?? <String>[];
  }

  Future<bool> setQuickItemsList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kQuickItemsList, value);
  }

  /// ----------------------------
  /// Methods for loot
  /// ----------------------------
  Future<String> getLootYataCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLootYataCache) ?? '';
  }

  Future<bool> setLootYataCache(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLootYataCache, value);
  }

  Future<String> getLootTimerType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLootTimerType) ?? 'timer';
  }

  Future<bool> setLootTimerType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLootTimerType, value);
  }

  Future<String> getLootNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLootNotificationType) ?? '0';
  }

  Future<bool> setLootNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLootNotificationType, value);
  }

  Future<String> getLootNotificationAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLootNotificationAhead) ?? '0';
  }

  Future<bool> setLootNotificationAhead(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLootNotificationAhead, value);
  }

  Future<String> getLootAlarmAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLootAlarmAhead) ?? '0';
  }

  Future<bool> setLootAlarmAhead(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLootAlarmAhead, value);
  }

  Future<String> getLootTimerAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLootTimerAhead) ?? '0';
  }

  Future<bool> setLootTimerAhead(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLootTimerAhead, value);
  }

  Future<bool> getLootAlarmVibration() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLootAlarmVibration) ?? true;
  }

  Future<bool> setLootAlarmVibration(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kLootAlarmVibration, value);
  }

  Future<bool> getLootAlarmSound() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLootAlarmSound) ?? true;
  }

  Future<bool> setLootAlarmSound(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kLootAlarmSound, value);
  }

  /// ----------------------------
  /// Methods for Trades Calculator
  /// ----------------------------
  Future<bool> getTradeCalculatorEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTradeCalculatorEnabled) ?? true;
  }

  Future<bool> setTradeCalculatorEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTradeCalculatorEnabled, value);
  }

  Future<bool> getTornTraderEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTornTraderEnabled) ?? false;
  }

  Future<bool> setTornTraderEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTornTraderEnabled, value);
  }

  /// ----------------------------
  /// Methods for City Finder
  /// ----------------------------
  Future<bool> getCityEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCityFinderEnabled) ?? true;
  }

  Future<bool> setCityEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kCityFinderEnabled, value);
  }

  /// ----------------------------
  /// Methods for Awards
  /// ----------------------------
  Future<String> getAwardsSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAwardsSort) ?? '';
  }

  Future<bool> setAwardsSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAwardsSort, value);
  }

  Future<bool> getShowAchievedAwards() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowAchievedAwards) ?? true;
  }

  Future<bool> setShowAchievedAwards(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowAchievedAwards, value);
  }

  Future<List<String>> getHiddenAwardCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHiddenAwardCategories) ?? <String>[];
  }

  Future<bool> setHiddenAwardCategories(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kHiddenAwardCategories, value);
  }

  /// ----------------------------
  /// Methods for Chat Removal
  /// ----------------------------
  Future<bool> getChatRemovalEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kChatRemovalEnabled) ?? true;
  }

  Future<bool> setChatRemovalEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kChatRemovalEnabled, value);
  }

  Future<bool> getChatRemovalActive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kChatRemovalActive) ?? false;
  }

  Future<bool> setChatRemovalActive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kChatRemovalActive, value);
  }

  /// ----------------------------
  /// Methods for Chat Highlight
  /// ----------------------------
  Future<bool> getHighlightChat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHighlightChat) ?? true;
  }

  Future<bool> setHighlightChat(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kHighlightChat, value);
  }

  Future<int> getHighlightColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kHighlightColor) ?? 0x667ca900;
  }

  Future<bool> setHighlightColor(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kHighlightColor, value);
  }


}
