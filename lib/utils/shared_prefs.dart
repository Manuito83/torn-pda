// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/widgets/webviews/webview_fab.dart';

class Prefs {
  final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  // General
  final String _kAppVersion = "pda_appVersion";
  final String _kAppAnnouncementDialogVersion = "pda_appAnnouncementDialogVersion";
  final String _kBugsAnnouncementDialogVersion = "pda_bugsAnnouncementDialogVersion";
  final String _kPdaUpdateDialogVersion = "pda_updateDialogVersion";
  final String _kOwnDetails = "pda_ownDetails";
  final String _kLastAppUse = "pda_lastAppUse";
  final String _kPdaConnectivityCheckRC = "pda_connectivityCheckRC";

  final String _kLastKnownFaction = "pfa_lastKnownFaction";
  final String _kLastKnownCompany = "pfa_lastKnownCompany";

  // Native login
  final String _kNativePlayerEmail = "pda_nativePlayerEmail";
  final String _kLastAuthRedirect = "pda_lastAuthRedirect";
  final String _kTryAutomaticLogins = "pda_tryAutomaticLogins";
  final String _kPlayerLastLoginMethod = "pda_playerLastLoginMethod";

  // Targets
  final String _kTargetsList = "pda_targetsList";
  final String _kTargetsSort = "pda_targetsSort";
  final String _kTargetsColorFilter = "pda_targetsColorFilter";

  // War targets
  final String _kWarFactions = "pda_warFactions";
  final String _kFilterListInWars = "pda_filterListInWars";
  final String _kOnlineFilterInWars = "pda_onlineFilterInWars";
  final String _kOkayRedFilterInWars = "pda_okayRedFilterInWars";
  final String _kCountryFilterInWars = "pda_countryFilterInWars";
  final String _kTravelingFilterInWars = "pda_travelingFilterStatusInWars";
  final String _kShowChainWidgetInWars = "pda_showChainWidgetInWars";
  final String _kWarMembersSort = "pda_warMembersSort";
  final String _kRankedWarSortPerTab = "pda_rankedWarSortPerTab";
  final String _kYataSpies = "pda_yataSpies";
  final String _kYataSpiesTime = "pda_yataSpiesTime";
  final String _kTornStatsSpies = "pda_tornStatsSpies";
  final String _kTornStatsSpiesTime = "pda_tornStatsSpiesTime";
  final String _kWarIntegrityCheckTime = "pda_warIntegrityCheckTime";

  // Ranked war extra access
  final String _kRankedWarsInMenu = "pda_rankedWarsInMenu";
  final String _kRankedWarsInProfile = "pda_rankedWarsInProfile";
  final String _kRankedWarsInProfileShowTotalHours = "pda_rankedWarsInProfileShowTotalHours";

  // Retaliation
  final String _kRetaliationSectionEnabled = "pda_retaliationSectionEnabled";
  final String _kSingleRetaliationOpensBrowser = "pda_singleRetaliationOpensBrowser";

  // Other
  final String _kChainingCurrentPage = "pda_chainingCurrentPage";
  final String _kTargetSkipping = "pda_targetSkipping";
  final String _kTargetSkippingFirst = "pda_targetSkippingFirst";
  final String _kShowTargetsNotes = "pda_showTargetsNotes";
  final String _kShowBlankTargetsNotes = "pda_showBlankTargetsNotes";
  final String _kShowOnlineFactionWarning = "pda_showOnlineFactionWarning";
  final String _kChainWatcherSettings = "pda_chainWatcherSettings";
  final String _kChainWatcherPanicTargets = "pda_chainWatcherPanicTargets";
  final String _kChainWatcherSound = "pda_chainWatcherSound";
  final String _kChainWatcherVibration = "pda_chainWatcherVibration";
  final String _kChainWatcherNotifications = "pda_chainWatcherNotifications";
  final String _kYataTargetsEnabled = "pda_yataTargetsEnabled";
  final String _kStatusColorWidgetEnabled = "pda_statusColorWidgetEnabled";
  final String _kAttacksSort = "pda_attacksSort";
  final String _kFriendsList = "pda_friendsList";
  final String _kFriendsSort = "pda_friendsSort";
  final String _kTheme = "pda_theme";
  final String _kUseMaterial3Theme = "pda_useMaterial3Theme";
  final String _kAccesibilityNoTextColors = "pda_accesibilityNoTextColors";
  final String _kSyncTornWebTheme = "tornLite_syncTheme";
  final String _kSyncDeviceTheme = "tornLite_syncDeviceTheme";
  final String _kDarkThemeToSync = "tornLite_themeToSync";
  final String _kDynamicAppIcons = "pda_dynamicAppIcons";
  final String _kDynamicAppIconsManual = "pda_dynamicAppIconsManual";
  final String _kVibrationPattern = "pda_vibrationPattern";
  final String _kDiscreetNotifications = "pda_discreteNotifications"; // We need to accept this typo
  final String _kDefaultSection = "pda_defaultSection";
  final String _kDefaultBrowser = "pda_defaultBrowser";
  final String _kAllowScreenRotation = "pda_allowScreenRotation";
  final String _kIosAllowLinkPreview = "pda_allowIosLinkPreview";
  final String _kExcessTabsAlerted = "pda_excessTabsAlerted";
  final String _kFirstTabLockAlerted = "pda_firstTabLockAlerted";
  final String _kOnBackButtonAppExit = "pda_onBackButtonAppExit";
  final String _kDebugMessages = "pda_debugMessages";
  final String _kLoadBarBrowser = "pda_loadBarBrowser";
  final String _kBrowserStyleBottomBarEnabled = "pda_browserStyleAlternativeEnabled";
  final String _kBrowserStyleBottomBarType = "pda_browserStyleAlternativeType";
  final String _kBrowserBottomBarStylePlaceTabsAtBottom = "pda_browserBottomBarStylePlaceTabsAtBottom";
  final String _kBrowserRefreshMethod2 = "pda_browserRefreshMethod"; // second try to make it icon default
  final String _kBrowserShowNavArrowsAppbar = "pda_browserShowNavArrowsAppbar";
  final String _kUseQuickBrowser = "pda_useQuickBrowser";
  //final String _kClearBrowserCacheNextOpportunity = "pda_clearBrowserCacheNextOpportunity";
  final String _kRestoreSessionCookie = "pda_restoreSessionCookie";
  final String _kWebviewCacheEnabled = "pda_webviewCacheEnabled";
  final String _kAndroidBrowserScale = "pda_androidBrowserScale";
  final String _kAndroidBrowserTextScale = "pda_androidBrowserTextScale";

  // Webview FAB
  final String _kWebviewFabEnabled = "pda_webviewFabEnabled";
  final String _kWebviewFabShownNow = "pda_webviewFabShownNow";
  final String _kWebviewFabDirection = "pda_webviewFabDirection";
  final String _kWebviewFabPositionXY = "pda_webviewFabPositionXY";
  final String _kWebviewFabOnlyFullScreen = "pda_webviewFabOnlyFullScreen";
  final String _kFabButtonCount = "pda_fabButtonCount";
  final String _kFabButtonActions = "pda_fabButtonActions";
  final String _kFabDoubleTapAction = "pda_fabDoubleTapAction";
  final String _kFabTripleTapAction = "pda_fabTripleTapAction";

  final String _kBrowserDoNotPauseWebviews = "pda_browserDoNotPauseWebviews";

  // Browser gestures
  final String _kIosBrowserPinch = "pda_iosBrowserPinch";
  final String _kIosDisallowOverscroll = "pda_iosDisallowOverscroll";
  final String _kBrowserReverseNavigationSwipe = "pda_browserReverseNavigationSwipe";
  final String _kBrowserCenterEditingTextField = "pda_browserCenterEditingTextField";

  final String _kRemoveNotificationsOnLaunch = "pda_removeNotificationsOnLaunch";
  final String _kTestBrowserActive = "pda_testBrowserActive";
  final String _kDefaultTimeFormat = "pda_defaultTimeFormat";
  final String _kDefaultTimeZone = "pda_defaultTimeZone";
  final String _kShowDateInClockString = "pda_showDateInClockString"; // changed from bool to string
  final String _kShowSecondsInClock = "pda_showSecondsInClock";
  final String _kAppBarPosition = "pda_AppBarPosition";
  final String _kSpiesSource = "pda_SpiesSource";
  final String _kAllowMixedSpiesSources = "pda_allowMixedSpiesSources";
  final String _kProfileSectionOrder = "pda_ProfileSectionOrder";
  final String _kColorCodedStatusCard = "pda_colorCodedStatusCard";
  final String _kLifeBarOption = "pda_LifeBarOption";
  final String _kTravelNotificationTitle = "pda_travelNotificationTitle";
  final String _kTravelNotificationBody = "pda_travelNotificationBody";
  final String _kTravelNotificationAhead = "pda_travelNotificationAhead";
  final String _kTravelAlarmAhead = "pda_travelAlarmAhead";
  final String _kTravelTimerAhead = "pda_travelTimerAhead";
  final String _kRemoveAirplane = "pda_removeAirplane";
  final String _kRemoveForeignItemsDetails = "pda_removeForeignItemsDetails";
  final String _kRemoveTravelQuickReturnButton = "pda_removeTravelQuickReturnButton";
  final String _kExtraPlayerInformation = "pda_extraPlayerInformation";
  final String _kFriendlyFactions = "pda_kFriendlyFactions";
  final String _kExtraPlayerNetworth = "pda_extraPlayerNetworth";
  final String _kHitInMiniProfileOpensNewTab = "pda__hitInMiniProfileOpensNewTab";
  final String _kHitInMiniProfileOpensNewTabAndChangeTab = "pda__hitInMiniProfileOpensNewTabAndChangeTab";
  final String _kStockCountryFilter = "pda_stockCountryFilter";
  final String _kStockTypeFilter = "pda_stockTypeFilter";
  final String _kStockSort = "pda_stockSort";
  final String _kStockCapacity = "pda_stockCapacity";
  final String _kShowForeignInventory = "pda_showForeignInventory";
  final String _kShowArrivalTime = "pda_showArrivalTime";
  final String _kShowBarsCooldownAnalysis = "pda_showBarsCooldownAnalysis";
  final String _kTravelTicket = "pda_travelTicket";
  final String _kForeignStocksDataProvider = "pda_foreignStocksDataProvider";
  final String _kActiveRestocks = "pda_activeRestocks";
  final String _kHiddenForeignStocks = "pda_hiddenForeignStocks";
  final String _kCountriesAlphabeticalFilter = "pda_countriesAlphabeticalFilter";
  final String _kRestocksEnabled = "pda_restocksEnabled";

  // Profile notifications
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
  final String _kHospitalNotificationType = "pda_hospitalNotificationType";
  final String _kHospitalNotificationAhead = "pda_hospitalNotificationAhead";
  final String _kHospitalAlarmAhead = "pda_hospitalAlarmAhead";
  final String _kHospitalTimerAhead = "pda_hospitalTimesAhead";
  final String _kJailNotificationType = "pda_jailNotificationType";
  final String _kJailNotificationAhead = "pda_jailNotificationAhead";
  final String _kJailAlarmAhead = "pda_jailAlarmAhead";
  final String _kJailTimerAhead = "pda_jailTimesAhead";
  final String _kRankedWarNotificationType = "pda_rankedWarNotificationType";
  final String _kRankedWarNotificationAhead = "pda_rankedWarNotificationAhead";
  final String _kRankedWarAlarmAhead = "pda_rankedWarAlarmAhead";
  final String _kRankedWarTimerAhead = "pda_rankedWarTimesAhead";
  final String _kRaceStartNotificationType = "pda_raceStartNotificationType";
  final String _kRaceStartNotificationAhead = "pda_raceStartNotificationAhead";
  final String _kRaceStartAlarmAhead = "pda_raceStartAlarmAhead";
  final String _kRaceStartTimerAhead = "pda_raceStartTimesAhead";

  // Profile options
  final String _kShowHeaderWallet = "pda_showHeaderWallet";
  final String _kShowHeaderIcons = "pda_showHeaderIcons";
  final String _kIconsFiltered = "pda_iconsFiltered";
  final String _kDedicatedTravelCard = "pda_dedicatedTravelCard";
  final String _kDisableTravelSection = "pda_disableTravelSection";
  final String _kWarnAboutChains = "pda_warnAboutChains";
  final String _kWarnAboutExcessEnergy = "pda_warnAboutExcessEnergy";
  final String _kWarnAboutExcessEnergyThreshold = "pda_warnAboutExcessEnergyThreshold";

  // Travel Agency warnings
  final String _kTravelEnergyExcessWarning = "pda_travelEnergyExcessWarning";
  final String _kTravelEnergyRangeWarningThresholdMin = 'travelEnergyRangeWarningThresholdMin';
  final String _kTravelEnergyRangeWarningThresholdMax = 'travelEnergyRangeWarningThresholdMax';
  final String _kTravelNerveExcessWarning = "pda_travelNerveExcessWarning";
  final String _kTravelNerveExcessWarningThreshold = "pda_travelNerveExcessWarningThreshold";
  final String _kTravelLifeExcessWarning = "pda_travelLifeExcessWarning";
  final String _kTravelLifeExcessWarningThreshold = "pda_travelLifeExcessWarningThreshold";
  final String _kTravelDrugCooldownWarning = "pda_travelDrugCooldownWarning";
  final String _kTravelBoosterCooldownWarning = "pda_travelBoosterCooldownWarning";
  final String _kTravelWalletMoneyWarning = "pda_travelWalletMoneyWarning";
  final String _kTravelWalletMoneyWarningThreshold = "pda_travelWalletMoneyWarningThreshold";
  final String _kExpandEvents = "pda_ExpandEvents";
  final String _kExpandMessages = "pda_ExpandMessages";
  final String _kMessagesShowNumber = "pda_messagesShowNumber";
  final String _kEventsShowNumber = "pda_eventsShowNumber";
  final String _kEventsLastRetrieved = "pda_eventsLastRetrieved";
  final String _kEventsSave = "pda_eventsSave";
  final String _kExpandBasicInfo = "pda_ExpandBasicInfo";
  final String _kExpandNetworth = "pda_ExpandNetworth";
  final String _kJobAddictionValue = "pda_jobAddiction";
  final String _kJobAddictionNextCallTime = "pda_jobAddictionLastRetrieved";
  final String _kProfileStatsEnabled = "pda_profileStatsEnabled";
  final String _kShareAttackOptions = "pda_shareAttackOptions";
  final String _kTSCEnabledStatus = "pda_tscEnabledStatus";
  final String _kYataStatsEnabledStatus = "pda_yataStatsEnabledStatus";

  // Notes
  final String _kPlayerNotes = "pda_playerNotes";
  final String _kPlayerNotesSort = "pda_playerNotesSort";
  final String _kPlayerNotesSortAscending = "pda_playerNotesSortAscending";
  final String _kNotesWidgetEnabledProfile = "pda_notesWidgetEnabledProfile";
  final String _kNotesWidgetEnabledProfileWhenEmpty = "pda_notesWidgetEnabledProfileWhenEmpty";
  final String _kPlayerNotesMigrationCompleted = "pda_playerNotesMigrationCompleted";

  // OC v2
  final String _kPlayerAlreadyInOCv2 = "pda_PlayerAlreadyInOCv2";

  // OC v1
  final String _kOCrimesEnabled = "pda_OCrimesEnabled";
  final String _kOCrimeDisregarded = "pda_OCrimeDisregarded";
  final String _kOCrimeLastKnown = "pda_OCrimeLastKnown";

  // Loot
  final String _kLootTimerType = "pda_lootTimerType";
  final String _kLootNotificationType = "pda_lootNotificationType";
  final String _kLootNotificationAhead = "pda_lootNotificationAhead";
  final String _kLootAlarmAhead = "pda_lootAlarmAhead";
  final String _kLootTimerAhead = "pda_lootTimerAhead";
  final String _kLootFiltered = "pda_lootFiltered";

  // Browser scripts and widgets
  final String _kManualAlarmVibration = "pda_manualAlarmVibration";
  final String _kManualAlarmSound = "pda_manualAlarmSound";
  final String _kTerminalEnabled = "pda_terminalEnabled";
  final String _kActiveCrimesList = "pda_activeCrimesList";
  final String _kQuickItemsList = "pda_quickItemsList";
  final String _kQuickItemsListFaction = "pda_quickItemsListFaction";
  final String _kQuickItemsLoadoutsNumber = "pda_quickItemsLoadoutsNumber";
  final String _kTradeCalculatorEnabled = "pda_tradeCalculatorActive";
  final String _kAWHEnabled = "pda_awhActive";
  final String _kTornExchangeEnabled = "pda_tornExchangeActive";
  final String _kTornExchangeProfitEnabled = "pda_tornExchangeProfitActive";
  final String _kCityFinderEnabled = "pda_cityFinderActive";
  final String _kAwardsSort = "pda_awardsSort";
  final String _kShowAchievedAwards = "pda_showAchievedAwards";
  final String _kHiddenAwardCategories = "pda_hiddenAwardCategories";
  final String _kHighlightChat = "pda_highlightChat";
  final String _kHighlightChatWordsList = "pda_highlightChatWordsList";
  final String _kHighlightColor = "pda_highlightColor";
  final String _kUserScriptsEnabled = "pda_userScriptsEnabled";
  final String _kUserScriptsNotifyUpdates = "pda_userScriptsNotifyUpdates";
  final String _kUserScriptsList = "pda_userScriptsList";
  final String _kUserScriptsV2FirstTime = "pda_userScriptsV2FirstTime"; // Use new key to force a new dialog
  final String _kUserScriptsFeatInjectionTimeShown = "pda_userScriptsFeatInjectionTimeShown";
  final String _kUserScriptsForcedVersions = "pda_userScriptsForcedVersions";

  // Shortcuts
  final String _kEnableShortcuts = "pda_enableShortcuts";
  final String _kShortcutTile = "pda_shortcutTile"; // Firebase User Pref
  final String _kShortcutMenu = "pda_shortcutMenu"; // Firebase User Pref
  final String _kActiveShortcutsList = "pda_activeShortcutsList"; // Firebase User Pref

  // Reviving
  final String _kUseNukeRevive = "pda_useNukeRevive";
  final String _kUseUhcRevive = "pda_useUhcRevive";
  final String _kUseHelaRevive = "pda_useHelaRevive";
  final String _kUseWtfRevive = "pda_useWtfRevive";
  final String _kUseMidnightXRevive = "pda_useMidnightXRevive";

  // Chaining stats sharing
  final String _kStatsShareIncludeHiddenTargets = "pda_statsShareIncludeHiddenTargets";
  final String _kStatsShareShowOnlyTotals = "pda_statsShareShowOnlyTotals";
  final String _kStatsShareShowEstimatesIfNoSpyAvailable = "pda_statsShareShowEstimatesIfNoSpyAvailable";
  final String _kStatsShareIncludeTargetsWithNoStatsAvailable = "pda_statsShareIncludeTargetsWithNoStatsAvailable";

  // Vault sharing
  final String _kVaultShareEnabled = "pda_vaultShareEnabled";
  final String _kVaultShareCurrent = "pda_vaultShareCurrent";

  // Jail
  final String _kJailModel = "pda_jailOptions";

  // Bounties
  final String _kBountiesModel = "pda_bountiesOptions";

  // Data notification received for stock market
  final String _kDataStockMarket = "pda_dataStockMarket";
  final String _kStockExchangeInMenu = "pda_stockExchangeInMenu";

  // WebView Tabs
  final String _kChatRemovalEnabled = "pda_chatRemovalEnabled";
  final String _kChatRemovalActive = "pda_chatRemovalActive";
  final String _kWebViewLastActiveTab = "pda_webViewLastActiveTab";
  final String _kWebViewSessionCookie = "pda_webViewSessionCookie";
  final String _kWebViewMainTab = "pda_webViewMainTab";
  final String _kWebViewSecondaryTabs = "pda_webViewTabs";
  final String _kUseTabsInFullBrowser = "pda_useTabsInFullBrowser";
  final String _kUseTabsInBrowserDialog = "pda_useTabsInBrowserDialog";

  final String _kRemoveUnusedTabs = "pda_removeUnusedTabs";
  final String _kRemoveUnusedTabsIncludesLocked = "pda_removeUnusedTabsIncludesLocked";
  final String _kRemoveUnusedTabsRangeDays = "pda_removeUnusedTabsRangeDays";

  final String _kOnlyLoadTabsWhenUsed = "pda_onlyLoadTabsWhenUsed";
  final String _kAutomaticChangeToNewTabFromURL = "pda_automaticChangeToNewTabFromURL";
  final String _kUseTabsHideFeature = "pda_useTabsHideFeature";
  final String _kUseTabsIcons = "pda_useTabsIcons";
  final String _kTabsHideBarColor = "pda_tabsHideBarColor";
  final String _kShowTabLockWarnings = "pda_showTabLockWarnings";
  final String _kFullLockNavigationAttemptOpensNewTab = "pda_fullLockNavigationAttemptOpensNewTab";
  final String _kFullLockedTabsNavigationExceptions = "pda_fullLockedTabsNavigationExceptions";
  final String _kHideTabs = "pda_hideTabs";
  final String _kReminderAboutHideTabFeature = "pda_reminderAboutHideTabFeature";
  final String _kFullScreenExplanationShown = "pda_fullScreenExplanationShown";
  final String _kFullScreenRemovesWidgets = "pda_fullScreenRemovesWidgets";
  final String _kFullScreenRemovesChat = "pda_fullScreenRemovesChat";
  final String _kFullScreenExtraCloseButton = "pda_fullScreenExtraCloseButton";
  final String _kFullScreenExtraReloadButton = "pda_fullScreenExtraReloadButton";
  final String _kFullScreenOverNotch = "pda_fullScreenOverNotch";
  final String _kFullScreenOverBottom = "pda_fullScreenOverBottom";
  final String _kFullScreenOverSides = "pda_fullScreenOverSides";
  final String _kFullScreenByShortTap = "pda_fullScreenByShortTap";
  final String _kFullScreenByLongTap = "pda_fullScreenByLongTap";
  final String _kFullScreenByNotificationTap = "pda_fullScreenByNotificationTap";
  final String _kFullScreenByShortChainingTap = "pda_fullScreenByShortChainingTap";
  final String _kFullScreenByLongChainingTap = "pda_fullScreenByLongChainingTap";
  final String _kFullScreenByDeepLinkTap = "pda_fullScreenByDeepLinkTap";
  final String _kFullScreenByQuickItemTap = "pda_fullScreenByQuickItemTap";
  final String _kFullScreenIncludesPDAButtonTap = "pda_fullScreenIncludesPDAButtonTap";

  // Notification actions
  final String _kLifeNotificationTapAction = "pda_lifeNotificationTapAction";
  final String _kDrugsNotificationTapAction = "pda_drugsNotificationTapAction";
  final String _kMedicalNotificationTapAction = "pda_medicalNotificationTapAction";
  final String _kBoosterNotificationTapAction = "pda_BoosterNotificationTapAction";

  // Items
  final String _kItemsSort = "pda_itemssSort";
  final String _kOnlyOwnedItemsFilter = "pda_onlyOwnedItemsFilter";
  final String _kHiddenItemsCategories = "pda_hiddenItemsCategories";
  final String _kPinnedItems = "pda_pinnedItems";

  // NNB
  final String _kNaturalNerveBarSource = "pda_naturalNerveBarSource";
  final String _kNaturalNerveYataTime = "pda_naturalNerveYataTime";
  final String _kNaturalNerveYataModel = "pda_naturalNerveYataModel";
  final String _kNaturalNerveTornStatsTime = "pda_naturalNerveTornStatsTime";
  final String _kNaturalNerveTornStatsModel = "pda_naturalNerveTornStatsModel";

  // Stakeouts
  final String _kStakeoutsEnabled = "pda_stakeoutsEnabled";
  final String _kStakeouts = "pda_stakeouts";
  final String _kStakeoutsSleepTime = "pda_stakeoutsSleepTime";
  final String _kStakeoutsFetchDelayLimit = "pda_stakeoutsFetchDelayLimit";

  // ShowCases (with flutter_showcaseview)
  final String _kShowCases = "pda_showCases";

  // Stats
  final String _kStatsFirstLoginTimestamp = "pda_statsFirstLoginTimestamp";
  final String _kStatsCumulatedAppUseSeconds = "pda_statsCumulatedAppUseSeconds";
  final String _kStatsEventsAchieved = "pda_statsEventsAchieved";

  // Alternative keys
  // YATA
  final String _kAlternativeYataKeyEnabled = "pda_alternativeYataKeyEnabled";
  final String _kAlternativeYataKey = "pda_alternativeYataKey";
  // TS
  final String _kAlternativeTornStatsKeyEnabled = "pda_alternativeTornStatsKeyEnabled";
  final String _kAlternativeTornStatsKey = "pda_alternativeTornStatsKey";
  // TSC
  final String _kAlternativeTSCKeyEnabled = "pda_alternativeTSCKeyEnabled";
  final String _kAlternativeTSCKey = "pda_alternativeTSCKey";

  // TornStats stats chart configuration
  final String _kTornStatsChartSave = "pda_tornStatsChartSave";
  final String _kTornStatsChartDateTime = "pda_tornStatsChartDateTime";
  final String _kTornStatsChartEnabled = "pda_tornStatsChartEnabled";
  final String _kTornStatsChartType = "pda_tornStatsChartType";
  final String _kTornStatsChartInCollapsedMiscCard = "pda_tornStatsChartInCollapsedMiscCard";

  // Torn Attack Central
  // NOTE: [_kTACEnabled] adds an extra tab in Chaining
  final String _kTACEnabled = "pda_tacEnabled";
  final String _kTACFilters = "pda_tacFilters";
  final String _kTACTargets = "pda_tacTargets";

  // Appwidget
  final String _kAppwidgetDarkMode = "pda_appwidgetDarkMode";
  final String _kAppwidgetRemoveShortcutsOneRowLayout = "pda_appwidgetRemoveShortcutsOneRowLayout";
  final String _kAppwidgetMoneyEnabled = "pda_appwidgetMoneyEnabled";
  // V2 after battery checks implemented
  final String _kAppwidgetExplanationShown = "pda_appwidgetExplanationShown_v2";
  final String _kAppwidgetCooldownTapOpensBrowser = "pda__appwidgetCooldownTapOpensBrowser";
  final String _kAppwidgetCooldownTapOpensBrowserDestination = "pda__appwidgetCooldownTapOpensBrowserDestination";

  // Permissions
  final String _kExactPermissionDialogShownAndroid = "pda_exactPermissionDialogShownAndroid";

  // Downloads
  final String _downloadActionShare = "pda_downloadActionShare";

  // Api Rate
  final String _kShowApiRateInDrawer = "pda_showApiRateInDrawer";
  final String _kDelayApiCalls = "pda_delayApiCalls";
  final String _kShowApiMaxCallWarning = "pda_showMaxCallWarning";

  // Memory
  final String _kShowMemoryInDrawer = "pda_showMemoryInDrawer";
  final String _kShowMemoryInWebview = "pda_showMemoryInWebview";

  // Refresh Rate
  final String _kHighRefreshRateEnabled = "pda_highRefreshRateEnabled";

  // Split screen configuration
  final String _kSplitScreenWebview = "pda_splitScreenWebview";
  final String _kSplitScreenRevertsToApp = "pda_splitScreenRevertsToApp";

  // FCM token
  final String _kFCMToken = "pda_fcmToken";

  // Sendbird notifications
  final String _kSendbirdnotificationsEnabled = "pda_sendbirdNotificationsEnabled";
  final String _kSendbirdSessionToken = "pda_sendbirdSessionToken";
  final String _kSendbirdTokenTimestamp = "pda_sendbirdTimestamp";
  final String _kSendbirdExcludeFactionMessages = "pda_sendbirdExcludeFactionMessages";
  final String _kSendbirdExcludeCompanyMessages = "pda_sendbirdExcludeCompanyMessages";

  final String _kBringBrowserForwardOnStart = "pda_bringBrowserForwardOnStart";

  // Periodic tasks
  final String _taskPrefix = "pda_periodic_";

  // Torn Calendar
  final String _kTornCalendarModel = "pda_tornCalendarModel";
  final String _kTornCalendarLastUpdate = "pda_tornCalendarLastUpdate";
  final String _kTctClockHighlightsEvents = "pda_tctClockHighlightsEvents";

  // Drawer menu
  final String _kShowWikiInDrawer = "pda_showWikiInDrawer";

  // Live Activities
  final String _kIosLiveActivityTravelEnabled = "pda_iosLiveActivityTravelEnabled";
  final String _kIosLiveActivityTravelPushToken = "pda_iosLiveActivityTravelPushToken";

  /// ----------------------------
  /// Methods for app version
  /// ----------------------------
  Future<String> getAppCompilation() async {
    return await _asyncPrefs.getString(_kAppVersion) ?? "";
  }

  Future setAppCompilation(String value) async {
    return await _asyncPrefs.setString(_kAppVersion, value);
  }

  /// -------------------------------
  /// Methods for announcement dialog
  /// -------------------------------

  Future<int> getAppStatsAnnouncementDialogVersion() async {
    return await _asyncPrefs.getInt(_kAppAnnouncementDialogVersion) ?? 0;
  }

  Future setAppStatsAnnouncementDialogVersion(int value) async {
    await _asyncPrefs.setInt(_kAppAnnouncementDialogVersion, value);
  }

  Future<int> getBugsAnnouncementDialogVersion() async {
    return await _asyncPrefs.getInt(_kBugsAnnouncementDialogVersion) ?? 0;
  }

  Future setBugsAnnouncementDialogVersion(int value) async {
    await _asyncPrefs.setInt(_kBugsAnnouncementDialogVersion, value);
  }

  Future<int> getPdaUpdateDialogVersion() async {
    return await _asyncPrefs.getInt(_kPdaUpdateDialogVersion) ?? 0;
  }

  Future setPdaUpdateDialogVersion(int value) async {
    await _asyncPrefs.setInt(_kPdaUpdateDialogVersion, value);
  }

  /// ----------------------------
  /// Methods for identification
  /// ----------------------------
  Future<String> getOwnDetails() async {
    return await _asyncPrefs.getString(_kOwnDetails) ?? "";
  }

  Future setOwnDetails(String value) async {
    return await _asyncPrefs.setString(_kOwnDetails, value);
  }

  /// ----------------------------
  /// Methods for identification
  /// ----------------------------
  Future<int> getLastAppUse() async {
    return await _asyncPrefs.getInt(_kLastAppUse) ?? 0;
  }

  Future setLastAppUse(int value) async {
    return await _asyncPrefs.setInt(_kLastAppUse, value);
  }

  /// ----------------------------
  /// Methods for connectivity check in Drawer (RC)
  /// ----------------------------
  Future<bool> getPdaConnectivityCheckRC() async {
    return await _asyncPrefs.getBool(_kPdaConnectivityCheckRC) ?? false;
  }

  Future setPdaConnectivityCheck(bool value) async {
    return await _asyncPrefs.setBool(_kPdaConnectivityCheckRC, value);
  }

  /// ----------------------------
  /// Methods for faction and company tracking
  /// ----------------------------
  Future<int> getLastKnownFaction() async {
    return await _asyncPrefs.getInt(_kLastKnownFaction) ?? 0;
  }

  Future setLastKnownFaction(int value) async {
    return await _asyncPrefs.setInt(_kLastKnownFaction, value);
  }

  Future<int> getLastKnownCompany() async {
    return await _asyncPrefs.getInt(_kLastKnownCompany) ?? 0;
  }

  Future setLastKnownCompany(int value) async {
    return await _asyncPrefs.setInt(_kLastKnownCompany, value);
  }

  /// ----------------------------
  /// Methods for native login
  /// ----------------------------
  Future<String> getNativePlayerEmail() async {
    return await _asyncPrefs.getString(_kNativePlayerEmail) ?? '';
  }

  Future setNativePlayerEmail(String value) async {
    return await _asyncPrefs.setString(_kNativePlayerEmail, value);
  }

  Future<int> getLastAuthRedirect() async {
    return await _asyncPrefs.getInt(_kLastAuthRedirect) ?? 0;
  }

  Future setLastAuthRedirect(int value) async {
    return await _asyncPrefs.setInt(_kLastAuthRedirect, value);
  }

  Future<bool> getTryAutomaticLogins() async {
    return await _asyncPrefs.getBool(_kTryAutomaticLogins) ?? true;
  }

  Future setTryAutomaticLogins(bool value) async {
    return await _asyncPrefs.setBool(_kTryAutomaticLogins, value);
  }

  Future<String> getPlayerLastLoginMethod() async {
    return await _asyncPrefs.getString(_kPlayerLastLoginMethod) ?? '';
  }

  Future setPlayerLastLoginMethod(String value) async {
    return await _asyncPrefs.setString(_kPlayerLastLoginMethod, value);
  }

  /// ----------------------------
  /// Methods for profile section order
  /// ----------------------------
  Future<List<String>> getProfileSectionOrder() async {
    return await _asyncPrefs.getStringList(_kProfileSectionOrder) ?? <String>[];
  }

  Future setProfileSectionOrder(List<String> value) async {
    return await _asyncPrefs.setStringList(_kProfileSectionOrder, value);
  }

  /// ------------------------------
  /// Methods for colored status card
  /// --------------------------------
  Future<bool> getColorCodedStatusCard() async {
    return await _asyncPrefs.getBool(_kColorCodedStatusCard) ?? true;
  }

  Future setColorCodedStatusCard(bool value) async {
    return await _asyncPrefs.setBool(_kColorCodedStatusCard, value);
  }

  /// ----------------------------
  /// Methods for targets
  /// ----------------------------
  Future<List<String>> getTargetsList() async {
    return await _asyncPrefs.getStringList(_kTargetsList) ?? <String>[];
  }

  Future setTargetsList(List<String> value) async {
    return await _asyncPrefs.setStringList(_kTargetsList, value);
  }

  //**************
  Future<String> getTargetsSort() async {
    return await _asyncPrefs.getString(_kTargetsSort) ?? '';
  }

  Future setTargetsSort(String value) async {
    return await _asyncPrefs.setString(_kTargetsSort, value);
  }

  //**************
  Future<List<String>> getTargetsColorFilter() async {
    return await _asyncPrefs.getStringList(_kTargetsColorFilter) ?? [];
  }

  Future setTargetsColorFilter(List<String> value) async {
    return await _asyncPrefs.setStringList(_kTargetsColorFilter, value);
  }

  //**************
  Future<List<String>> getWarFactions() async {
    return await _asyncPrefs.getStringList(_kWarFactions) ?? <String>[];
  }

  Future setWarFactions(List<String> value) async {
    return await _asyncPrefs.setStringList(_kWarFactions, value);
  }

  Future<List<String>> getFilterListInWars() async {
    return await _asyncPrefs.getStringList(_kFilterListInWars) ?? [];
  }

  Future setFilterListInWars(List<String> value) async {
    return await _asyncPrefs.setStringList(_kFilterListInWars, value);
  }

  Future<int> getOnlineFilterInWars() async {
    return await _asyncPrefs.getInt(_kOnlineFilterInWars) ?? 0;
  }

  Future setOnlineFilterInWars(int value) async {
    return await _asyncPrefs.setInt(_kOnlineFilterInWars, value);
  }

  Future<int> getOkayRedFilterInWars() async {
    return await _asyncPrefs.getInt(_kOkayRedFilterInWars) ?? 0;
  }

  Future setOkayRedFilterInWars(int value) async {
    return await _asyncPrefs.setInt(_kOkayRedFilterInWars, value);
  }

  Future<bool> getCountryFilterInWars() async {
    return await _asyncPrefs.getBool(_kCountryFilterInWars) ?? false;
  }

  Future setCountryFilterInWars(bool value) async {
    return await _asyncPrefs.setBool(_kCountryFilterInWars, value);
  }

  Future<int> getTravelingFilterInWars() async {
    return await _asyncPrefs.getInt(_kTravelingFilterInWars) ?? 0;
  }

  Future setTravelingFilterInWars(int value) async {
    return await _asyncPrefs.setInt(_kTravelingFilterInWars, value);
  }

  Future<bool> getShowChainWidgetInWars() async {
    return await _asyncPrefs.getBool(_kShowChainWidgetInWars) ?? true;
  }

  Future setShowChainWidgetInWars(bool value) async {
    return await _asyncPrefs.setBool(_kShowChainWidgetInWars, value);
  }

  Future<String> getWarMembersSort() async {
    return await _asyncPrefs.getString(_kWarMembersSort) ?? '';
  }

  Future setWarMembersSort(String value) async {
    return await _asyncPrefs.setString(_kWarMembersSort, value);
  }

  Future<String> getRankerWarSortPerTab() async {
    return await _asyncPrefs.getString(_kRankedWarSortPerTab) ?? 'active#progressDes-upcoming#timeAsc-finished#timeAsc';
  }

  Future setRankerWarSortPerTab(String value) async {
    return await _asyncPrefs.setString(_kRankedWarSortPerTab, value);
  }

  Future<List<String>> getYataSpies() async {
    return await _asyncPrefs.getStringList(_kYataSpies) ?? [];
  }

  Future setYataSpies(List<String> value) async {
    return await _asyncPrefs.setStringList(_kYataSpies, value);
  }

  Future<int> getYataSpiesTime() async {
    return await _asyncPrefs.getInt(_kYataSpiesTime) ?? 0;
  }

  Future setYataSpiesTime(int value) async {
    return await _asyncPrefs.setInt(_kYataSpiesTime, value);
  }

  Future<String> getTornStatsSpies() async {
    return await _asyncPrefs.getString(_kTornStatsSpies) ?? "";
  }

  Future setTornStatsSpies(String value) async {
    return await _asyncPrefs.setString(_kTornStatsSpies, value);
  }

  Future<int> getTornStatsSpiesTime() async {
    return await _asyncPrefs.getInt(_kTornStatsSpiesTime) ?? 0;
  }

  Future setTornStatsSpiesTime(int value) async {
    return await _asyncPrefs.setInt(_kTornStatsSpiesTime, value);
  }

  Future<int> getWarIntegrityCheckTime() async {
    return await _asyncPrefs.getInt(_kWarIntegrityCheckTime) ?? 0;
  }

  Future setWarIntegrityCheckTime(int value) async {
    return await _asyncPrefs.setInt(_kWarIntegrityCheckTime, value);
  }

  //**************
  Future<int> getChainingCurrentPage() async {
    return await _asyncPrefs.getInt(_kChainingCurrentPage) ?? 0;
  }

  Future setChainingCurrentPage(int value) async {
    return await _asyncPrefs.setInt(_kChainingCurrentPage, value);
  }

  Future<bool> getTargetSkippingAll() async {
    return await _asyncPrefs.getBool(_kTargetSkipping) ?? true;
  }

  Future setTargetSkipping(bool value) async {
    return await _asyncPrefs.setBool(_kTargetSkipping, value);
  }

  Future<bool> getTargetSkippingFirst() async {
    return await _asyncPrefs.getBool(_kTargetSkippingFirst) ?? false;
  }

  Future setTargetSkippingFirst(bool value) async {
    return await _asyncPrefs.setBool(_kTargetSkippingFirst, value);
  }

  Future<bool> getShowTargetsNotes() async {
    return await _asyncPrefs.getBool(_kShowTargetsNotes) ?? true;
  }

  Future setShowTargetsNotes(bool value) async {
    return await _asyncPrefs.setBool(_kShowTargetsNotes, value);
  }

  Future<bool> getShowBlankTargetsNotes() async {
    return await _asyncPrefs.getBool(_kShowBlankTargetsNotes) ?? false;
  }

  Future setShowBlankTargetsNotes(bool value) async {
    return await _asyncPrefs.setBool(_kShowBlankTargetsNotes, value);
  }

  Future<bool> getShowOnlineFactionWarning() async {
    return await _asyncPrefs.getBool(_kShowOnlineFactionWarning) ?? true;
  }

  Future setShowOnlineFactionWarning(bool value) async {
    return await _asyncPrefs.setBool(_kShowOnlineFactionWarning, value);
  }

  Future<String> getChainWatcherSettings() async {
    return await _asyncPrefs.getString(_kChainWatcherSettings) ?? '';
  }

  Future setChainWatcherSettings(String value) async {
    return await _asyncPrefs.setString(_kChainWatcherSettings, value);
  }

  Future<List<String>> getChainWatcherPanicTargets() async {
    return await _asyncPrefs.getStringList(_kChainWatcherPanicTargets) ?? <String>[];
  }

  Future setChainWatcherPanicTargets(List<String> value) async {
    return await _asyncPrefs.setStringList(_kChainWatcherPanicTargets, value);
  }

  Future<bool> getChainWatcherSound() async {
    return await _asyncPrefs.getBool(_kChainWatcherSound) ?? true;
  }

  Future setChainWatcherSound(bool value) async {
    return await _asyncPrefs.setBool(_kChainWatcherSound, value);
  }

  Future<bool> getChainWatcherVibration() async {
    return await _asyncPrefs.getBool(_kChainWatcherVibration) ?? true;
  }

  Future setChainWatcherVibration(bool value) async {
    return await _asyncPrefs.setBool(_kChainWatcherVibration, value);
  }

  Future<bool> getChainWatcherNotificationsEnabled() async {
    return await _asyncPrefs.getBool(_kChainWatcherNotifications) ?? true;
  }

  Future setChainWatcherNotificationsEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kChainWatcherNotifications, value);
  }

  Future<bool> getYataTargetsEnabled() async {
    return await _asyncPrefs.getBool(_kYataTargetsEnabled) ?? true;
  }

  Future setYataTargetsEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kYataTargetsEnabled, value);
  }

  Future<bool> getStatusColorWidgetEnabled() async {
    return await _asyncPrefs.getBool(_kStatusColorWidgetEnabled) ?? true;
  }

  Future setStatusColorWidgetEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kStatusColorWidgetEnabled, value);
  }

  /// ----------------------------
  /// Methods for attacks
  /// ----------------------------
  Future<String> getAttackSort() async {
    return await _asyncPrefs.getString(_kAttacksSort) ?? '';
  }

  Future setAttackSort(String value) async {
    return await _asyncPrefs.setString(_kAttacksSort, value);
  }

  /// ----------------------------
  /// Methods for friends
  /// ----------------------------
  Future<List<String>> getFriendsList() async {
    return await _asyncPrefs.getStringList(_kFriendsList) ?? <String>[];
  }

  Future setFriendsList(List<String> value) async {
    return await _asyncPrefs.setStringList(_kFriendsList, value);
  }

  //**************
  Future<String> getFriendsSort() async {
    return await _asyncPrefs.getString(_kFriendsSort) ?? '';
  }

  Future setFriendsSort(String value) async {
    return await _asyncPrefs.setString(_kFriendsSort, value);
  }

  /// ----------------------------
  /// Methods for theme
  /// ----------------------------
  Future<String> getAppTheme() async {
    return await _asyncPrefs.getString(_kTheme) ?? 'light';
  }

  Future setAppTheme(String value) async {
    return await _asyncPrefs.setString(_kTheme, value);
  }

  Future<bool> getUseMaterial3() async {
    return await _asyncPrefs.getBool(_kUseMaterial3Theme) ?? false;
  }

  Future setUseMaterial3(bool value) async {
    return await _asyncPrefs.setBool(_kUseMaterial3Theme, value);
  }

  Future<bool> getAccesibilityNoTextColors() async {
    return await _asyncPrefs.getBool(_kAccesibilityNoTextColors) ?? false;
  }

  Future setAccesibilityNoTextColors(bool value) async {
    return await _asyncPrefs.setBool(_kAccesibilityNoTextColors, value);
  }

  /// ----------------------------
  /// Methods for theme sync with web and device
  /// ----------------------------
  Future<bool> getSyncTornWebTheme() async {
    return await _asyncPrefs.getBool(_kSyncTornWebTheme) ?? true;
  }

  Future setSyncTornWebTheme(bool value) async {
    return await _asyncPrefs.setBool(_kSyncTornWebTheme, value);
  }

  Future<bool> getSyncDeviceTheme() async {
    return await _asyncPrefs.getBool(_kSyncDeviceTheme) ?? false;
  }

  Future setSyncDeviceTheme(bool value) async {
    return await _asyncPrefs.setBool(_kSyncDeviceTheme, value);
  }

  Future<String> getDarkThemeToSync() async {
    return await _asyncPrefs.getString(_kDarkThemeToSync) ?? 'dark';
  }

  Future setDarkThemeToSync(String value) async {
    return await _asyncPrefs.setString(_kDarkThemeToSync, value);
  }

  /// ----------------------------
  /// Methods for dynamic app icons
  /// ----------------------------
  Future<bool> getDynamicAppIcons() async {
    return await _asyncPrefs.getBool(_kDynamicAppIcons) ?? true;
  }

  Future setDynamicAppIcons(bool value) async {
    return await _asyncPrefs.setBool(_kDynamicAppIcons, value);
  }

  //--

  Future<String> getDynamicAppIconsManual() async {
    return await _asyncPrefs.getString(_kDynamicAppIconsManual) ?? "off";
  }

  Future setDynamicAppIconsManual(String value) async {
    return await _asyncPrefs.setString(_kDynamicAppIconsManual, value);
  }

  /// ----------------------------
  /// Methods for vibration pattern
  /// ----------------------------
  Future<String> getVibrationPattern() async {
    return await _asyncPrefs.getString(_kVibrationPattern) ?? 'medium';
  }

  Future setVibrationPattern(String value) async {
    return await _asyncPrefs.setString(_kVibrationPattern, value);
  }

  /// ----------------------------
  /// Methods for discreet notifications
  /// ----------------------------
  Future<bool> getDiscreetNotifications() async {
    return await _asyncPrefs.getBool(_kDiscreetNotifications) ?? false;
  }

  Future setDiscreetNotifications(bool value) async {
    return await _asyncPrefs.setBool(_kDiscreetNotifications, value);
  }

  /// ----------------------------
  /// Methods for default launch section
  /// ----------------------------
  Future<String> getDefaultSection() async {
    return await _asyncPrefs.getString(_kDefaultSection) ?? '0';
  }

  Future setDefaultSection(String value) async {
    return await _asyncPrefs.setString(_kDefaultSection, value);
  }

  /// ----------------------------
  /// Methods for on app exit
  /// ----------------------------
  Future<String> getOnBackButtonAppExit() async {
    return await _asyncPrefs.getString(_kOnBackButtonAppExit) ?? 'stay';
  }

  Future setOnAppExit(String value) async {
    return await _asyncPrefs.setString(_kOnBackButtonAppExit, value);
  }

  /// ----------------------------
  /// Methods for debug messages
  /// ----------------------------
  Future<bool> getDebugMessages() async {
    return await _asyncPrefs.getBool(_kDebugMessages) ?? false;
  }

  Future setDebugMessages(bool value) async {
    return await _asyncPrefs.setBool(_kDebugMessages, value);
  }

  /// ----------------------------
  /// Methods for default browser
  /// ----------------------------
  Future<String> getDefaultBrowser() async {
    return await _asyncPrefs.getString(_kDefaultBrowser) ?? 'app';
  }

  Future setDefaultBrowser(String value) async {
    return await _asyncPrefs.setString(_kDefaultBrowser, value);
  }

  Future<bool> getLoadBarBrowser() async {
    return await _asyncPrefs.getBool(_kLoadBarBrowser) ?? true;
  }

  Future setLoadBarBrowser(bool value) async {
    return await _asyncPrefs.setBool(_kLoadBarBrowser, value);
  }

  Future<String> getBrowserRefreshMethod() async {
    return await _asyncPrefs.getString(_kBrowserRefreshMethod2) ?? "both";
  }

  Future setBrowserRefreshMethod(String value) async {
    return await _asyncPrefs.setString(_kBrowserRefreshMethod2, value);
  }

  Future<String> getBrowserShowNavArrowsAppbar() async {
    return await _asyncPrefs.getString(_kBrowserShowNavArrowsAppbar) ?? "wide";
  }

  Future setBrowserShowNavArrowsAppbar(String value) async {
    return await _asyncPrefs.setString(_kBrowserShowNavArrowsAppbar, value);
  }

  Future<bool> getBrowserBottomBarStyleEnabled() async {
    return await _asyncPrefs.getBool(_kBrowserStyleBottomBarEnabled) ?? false;
  }

  Future setBrowserBottomBarStyleEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kBrowserStyleBottomBarEnabled, value);
  }

  Future<int> getBrowserBottomBarStyleType() async {
    return await _asyncPrefs.getInt(_kBrowserStyleBottomBarType) ?? 1;
  }

  Future setBrowserBottomBarStyleType(int value) async {
    return await _asyncPrefs.setInt(_kBrowserStyleBottomBarType, value);
  }

  Future<bool> getBrowserBottomBarStylePlaceTabsAtBottom() async {
    return await _asyncPrefs.getBool(_kBrowserBottomBarStylePlaceTabsAtBottom) ?? false;
  }

  Future setBrowserBottomBarStylePlaceTabsAtBottom(bool value) async {
    return await _asyncPrefs.setBool(_kBrowserBottomBarStylePlaceTabsAtBottom, value);
  }

  Future<String> getTMenuButtonLongPressBrowser() async {
    return await _asyncPrefs.getString(_kUseQuickBrowser) ?? "quick";
  }

  Future setTMenuButtonLongPressBrowser(String value) async {
    return await _asyncPrefs.setString(_kUseQuickBrowser, value);
  }

  Future<bool> getRestoreSessionCookie() async {
    return await _asyncPrefs.getBool(_kRestoreSessionCookie) ?? false;
  }

  Future setRestoreSessionCookie(bool value) async {
    return await _asyncPrefs.setBool(_kRestoreSessionCookie, value);
  }

  Future<bool> getWebviewCacheEnabled() async {
    return await _asyncPrefs.getBool(_kWebviewCacheEnabled) ?? true;
  }

  Future setWebviewCacheEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kWebviewCacheEnabled, value);
  }

  /*
  Future<bool> getClearBrowserCacheNextOpportunity() async {
    
    return await _asyncPrefs.getBool(_kClearBrowserCacheNextOpportunity) ?? false;
  }
  
  Future setClearBrowserCacheNextOpportunity(bool value) async {
    
    return await _asyncPrefs.setBool(_kClearBrowserCacheNextOpportunity, value);
  }
  */

  Future<int> getAndroidBrowserScale() async {
    return await _asyncPrefs.getInt(_kAndroidBrowserScale) ?? 0;
  }

  Future setAndroidBrowserScale(int value) async {
    return await _asyncPrefs.setInt(_kAndroidBrowserScale, value);
  }

  Future<int> getAndroidBrowserTextScale() async {
    return await _asyncPrefs.getInt(_kAndroidBrowserTextScale) ?? 8;
  }

  Future setAndroidBrowserTextScale(int value) async {
    return await _asyncPrefs.setInt(_kAndroidBrowserTextScale, value);
  }

  // Settings - Browser FAB

  Future<bool> getWebviewFabEnabled() async {
    return await _asyncPrefs.getBool(_kWebviewFabEnabled) ?? false;
  }

  Future setWebviewFabEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kWebviewFabEnabled, value);
  }

  // --

  Future<bool> getWebviewFabShownNow() async {
    return await _asyncPrefs.getBool(_kWebviewFabShownNow) ?? true;
  }

  Future setWebviewFabShownNow(bool value) async {
    return await _asyncPrefs.setBool(_kWebviewFabShownNow, value);
  }

  // --

  Future<String> getWebviewFabDirection() async {
    return await _asyncPrefs.getString(_kWebviewFabDirection) ?? "center";
  }

  Future setWebviewFabDirection(String value) async {
    return await _asyncPrefs.setString(_kWebviewFabDirection, value);
  }

  // --

  Future setWebviewFabPositionXY(List<int> value) async {
    // Convert list to JSON string for storage
    return await _asyncPrefs.setString(_kWebviewFabPositionXY, jsonEncode(value));
  }

  // Retrieve FAB position and decode JSON string to List<int>
  Future<List<int>> getWebviewFabPositionXY() async {
    final jsonString = await _asyncPrefs.getString(_kWebviewFabPositionXY);
    if (jsonString != null) {
      try {
        // Decode JSON string back to List<int>
        return List<int>.from(jsonDecode(jsonString));
      } catch (e) {
        return [100, 100];
      }
    }
    return [100, 100]; // Default
  }

  // --

  Future<bool> getWebviewFabOnlyFullScreen() async {
    return await _asyncPrefs.getBool(_kWebviewFabOnlyFullScreen) ?? false;
  }

  Future setWebviewFabOnlyFullScreen(bool value) async {
    return await _asyncPrefs.setBool(_kWebviewFabOnlyFullScreen, value);
  }

  // --

  Future setFabButtonCount(int value) async {
    return await _asyncPrefs.setInt(_kFabButtonCount, value);
  }

  Future<int> getFabButtonCount() async {
    return await _asyncPrefs.getInt(_kFabButtonCount) ?? 4; // Default to 4 buttons
  }

// --

  Future setFabButtonActions(List<WebviewFabAction> actions) async {
    final actionIndices = actions.map((action) => action.index).toList();
    return await _asyncPrefs.setStringList(
      _kFabButtonActions,
      actionIndices.map((e) => e.toString()).toList(),
    );
  }

  Future<List<WebviewFabAction>> getFabButtonActions() async {
    final actionStrings = await _asyncPrefs.getStringList(_kFabButtonActions);

    if (actionStrings != null) {
      return actionStrings
          .map((actionIndex) => int.tryParse(actionIndex))
          .whereType<int>() // Eliminate null values
          .map((index) => FabActionExtension.fromIndex(index))
          .toList();
    }

    // Default actions
    return [
      WebviewFabAction.home,
      WebviewFabAction.back,
      WebviewFabAction.forward,
      WebviewFabAction.reload,
      WebviewFabAction.openTabsMenu,
      WebviewFabAction.closeCurrentTab,
    ];
  }

// --

  Future setFabDoubleTapAction(WebviewFabAction action) async {
    return await _asyncPrefs.setInt(_kFabDoubleTapAction, action.index);
  }

  Future<WebviewFabAction> getFabDoubleTapAction() async {
    final actionIndex = await _asyncPrefs.getInt(_kFabDoubleTapAction);
    return actionIndex != null
        ? FabActionExtension.fromIndex(actionIndex)
        : WebviewFabAction.openTabsMenu; // Default to Open Tabs Menu
  }

// --

  Future setFabTripleTapAction(WebviewFabAction action) async {
    return await _asyncPrefs.setInt(_kFabTripleTapAction, action.index);
  }

  Future<WebviewFabAction> getFabTripleTapAction() async {
    final actionIndex = await _asyncPrefs.getInt(_kFabTripleTapAction);
    return actionIndex != null
        ? FabActionExtension.fromIndex(actionIndex)
        : WebviewFabAction.closeCurrentTab; // Default to Close Current Tab
  }

  // FAB ENDS ###

  Future<bool> getBrowserDoNotPauseWebviews() async {
    return await _asyncPrefs.getBool(_kBrowserDoNotPauseWebviews) ?? false;
  }

  Future setBrowserDoNotPauseWebviews(bool value) async {
    return await _asyncPrefs.setBool(_kBrowserDoNotPauseWebviews, value);
  }

  // Settings - Browser Gestures

  Future<bool> getIosBrowserPinch() async {
    return await _asyncPrefs.getBool(_kIosBrowserPinch) ?? false;
  }

  Future setIosBrowserPinch(bool value) async {
    return await _asyncPrefs.setBool(_kIosBrowserPinch, value);
  }

  Future<bool> getIosDisallowOverscroll() async {
    return await _asyncPrefs.getBool(_kIosDisallowOverscroll) ?? false;
  }

  Future setIosDisallowOverscroll(bool value) async {
    return await _asyncPrefs.setBool(_kIosDisallowOverscroll, value);
  }

  Future<bool> getBrowserReverseNavigationSwipe() async {
    return await _asyncPrefs.getBool(_kBrowserReverseNavigationSwipe) ?? false;
  }

  Future setBrowserReverseNavigationSwipe(bool value) async {
    return await _asyncPrefs.setBool(_kBrowserReverseNavigationSwipe, value);
  }

  Future<bool> getBrowserCenterEditingTextField() async {
    return await _asyncPrefs.getBool(_kBrowserCenterEditingTextField) ?? true;
  }

  Future setBrowserCenterEditingTextField(bool value) async {
    return await _asyncPrefs.setBool(_kBrowserCenterEditingTextField, value);
  }

  /// ----------------------------
  /// Methods for test browser
  /// ----------------------------
  Future<bool> getTestBrowserActive() async {
    return await _asyncPrefs.getBool(_kTestBrowserActive) ?? false;
  }

  Future setTestBrowserActive(bool value) async {
    return await _asyncPrefs.setBool(_kTestBrowserActive, value);
  }

  /// ----------------------------
  /// Methods for notifications on launch
  /// ----------------------------
  Future<bool> getRemoveNotificationsOnLaunch() async {
    return await _asyncPrefs.getBool(_kRemoveNotificationsOnLaunch) ?? true;
  }

  Future setRemoveNotificationsOnLaunch(bool value) async {
    return await _asyncPrefs.setBool(_kRemoveNotificationsOnLaunch, value);
  }

  /// ----------------------------
  /// Methods for clock
  /// ----------------------------
  Future<String> getDefaultTimeFormat() async {
    return await _asyncPrefs.getString(_kDefaultTimeFormat) ?? '24';
  }

  Future setDefaultTimeFormat(String value) async {
    return await _asyncPrefs.setString(_kDefaultTimeFormat, value);
  }

  Future<String> getDefaultTimeZone() async {
    return await _asyncPrefs.getString(_kDefaultTimeZone) ?? 'local';
  }

  Future setDefaultTimeZone(String value) async {
    return await _asyncPrefs.setString(_kDefaultTimeZone, value);
  }

  Future<String> getShowDateInClock() async {
    return await _asyncPrefs.getString(_kShowDateInClockString) ?? "dayfirst";
  }

  Future setShowDateInClock(String value) async {
    return await _asyncPrefs.setString(_kShowDateInClockString, value);
  }

  Future<bool> getShowSecondsInClock() async {
    return await _asyncPrefs.getBool(_kShowSecondsInClock) ?? true;
  }

  Future setShowSecondsInClock(bool value) async {
    return await _asyncPrefs.setBool(_kShowSecondsInClock, value);
  }

  /// ----------------------------
  /// Methods for spies source
  /// ----------------------------
  Future<String> getSpiesSource() async {
    return await _asyncPrefs.getString(_kSpiesSource) ?? 'yata';
  }

  Future setSpiesSource(String value) async {
    return await _asyncPrefs.setString(_kSpiesSource, value);
  }

  Future<bool> getAllowMixedSpiesSources() async {
    return await _asyncPrefs.getBool(_kAllowMixedSpiesSources) ?? true;
  }

  Future setAllowMixedSpiesSources(bool value) async {
    return await _asyncPrefs.setBool(_kAllowMixedSpiesSources, value);
  }

  /// ----------------------------
  /// Methods for OC Crimes NNB Source
  /// ----------------------------
  Future<String> getNaturalNerveBarSource() async {
    return await _asyncPrefs.getString(_kNaturalNerveBarSource) ?? 'yata';
  }

  Future setNaturalNerveBarSource(String value) async {
    return await _asyncPrefs.setString(_kNaturalNerveBarSource, value);
  }

  Future<int> getNaturalNerveYataTime() async {
    return await _asyncPrefs.getInt(_kNaturalNerveYataTime) ?? 0;
  }

  Future setNaturalNerveYataTime(int value) async {
    return await _asyncPrefs.setInt(_kNaturalNerveYataTime, value);
  }

  Future<String> getNaturalNerveYataModel() async {
    return await _asyncPrefs.getString(_kNaturalNerveYataModel) ?? '';
  }

  Future setNaturalNerveYataModel(String value) async {
    return await _asyncPrefs.setString(_kNaturalNerveYataModel, value);
  }

  Future<int> getNaturalNerveTornStatsTime() async {
    return await _asyncPrefs.getInt(_kNaturalNerveTornStatsTime) ?? 0;
  }

  Future setNaturalNerveTornStatsTime(int value) async {
    return await _asyncPrefs.setInt(_kNaturalNerveTornStatsTime, value);
  }

  Future<String> getNaturalNerveTornStatsModel() async {
    return await _asyncPrefs.getString(_kNaturalNerveTornStatsModel) ?? '';
  }

  Future setNaturalNerveTornStatsModel(String value) async {
    return await _asyncPrefs.setString(_kNaturalNerveTornStatsModel, value);
  }

  /// ----------------------------
  /// Methods for appBar position
  /// ----------------------------
  Future<String> getAppBarPosition() async {
    return await _asyncPrefs.getString(_kAppBarPosition) ?? 'top';
  }

  Future setAppBarPosition(String value) async {
    return await _asyncPrefs.setString(_kAppBarPosition, value);
  }

  /// ----------------------------
  /// Methods for screen rotation
  /// ----------------------------

  Future<bool> getAllowScreenRotation() async {
    return await _asyncPrefs.getBool(_kAllowScreenRotation) ?? false;
  }

  Future setAllowScreenRotation(bool value) async {
    return await _asyncPrefs.setBool(_kAllowScreenRotation, value);
  }

  /// ----------------------------
  /// Methods for iOS Link Preview
  /// ----------------------------

  Future<bool> getIosAllowLinkPreview() async {
    return await _asyncPrefs.getBool(_kIosAllowLinkPreview) ?? true;
  }

  Future setIosAllowLinkPreview(bool value) async {
    return await _asyncPrefs.setBool(_kIosAllowLinkPreview, value);
  }

  /// ----------------------------
  /// Methods for excess tabs dialog persistence
  /// ----------------------------

  Future<bool> getExcessTabsAlerted() async {
    return await _asyncPrefs.getBool(_kExcessTabsAlerted) ?? false;
  }

  Future setExcessTabsAlerted(bool value) async {
    return await _asyncPrefs.setBool(_kExcessTabsAlerted, value);
  }

  /// ----------------------------
  /// Methods for excess first tab lock
  /// ----------------------------

  Future<bool> getFirstTabLockAlerted() async {
    return await _asyncPrefs.getBool(_kFirstTabLockAlerted) ?? false;
  }

  Future setFirstTabLockAlerted(bool value) async {
    return await _asyncPrefs.setBool(_kFirstTabLockAlerted, value);
  }

  /// ----------------------------
  /// Methods for travel options
  /// ----------------------------
  Future<String> getTravelNotificationTitle() async {
    return await _asyncPrefs.getString(_kTravelNotificationTitle) ?? 'TORN TRAVEL';
  }

  Future setTravelNotificationTitle(String value) async {
    return await _asyncPrefs.setString(_kTravelNotificationTitle, value);
  }

  Future<String> getTravelNotificationBody() async {
    return await _asyncPrefs.getString(_kTravelNotificationBody) ?? 'Arriving at your destination!';
  }

  Future setTravelNotificationBody(String value) async {
    return await _asyncPrefs.setString(_kTravelNotificationBody, value);
  }

  Future<String> getTravelNotificationAhead() async {
    return await _asyncPrefs.getString(_kTravelNotificationAhead) ?? '0';
  }

  Future setTravelNotificationAhead(String value) async {
    return await _asyncPrefs.setString(_kTravelNotificationAhead, value);
  }

  Future<String> getTravelAlarmAhead() async {
    return await _asyncPrefs.getString(_kTravelAlarmAhead) ?? '0';
  }

  Future setTravelAlarmAhead(String value) async {
    return await _asyncPrefs.setString(_kTravelAlarmAhead, value);
  }

  Future<String> getTravelTimerAhead() async {
    return await _asyncPrefs.getString(_kTravelTimerAhead) ?? '0';
  }

  Future setTravelTimerAhead(String value) async {
    return await _asyncPrefs.setString(_kTravelTimerAhead, value);
  }

  Future<bool> getRemoveAirplane() async {
    return await _asyncPrefs.getBool(_kRemoveAirplane) ?? false;
  }

  Future setRemoveAirplane(bool value) async {
    return await _asyncPrefs.setBool(_kRemoveAirplane, value);
  }

  Future<bool> getRemoveForeignItemsDetails() async {
    return await _asyncPrefs.getBool(_kRemoveForeignItemsDetails) ?? false;
  }

  Future setRemoveForeignItemsDetails(bool value) async {
    return await _asyncPrefs.setBool(_kRemoveForeignItemsDetails, value);
  }

  Future<bool> getRemoveTravelQuickReturnButton() async {
    return await _asyncPrefs.getBool(_kRemoveTravelQuickReturnButton) ?? false;
  }

  Future setRemoveTravelQuickReturnButton(bool value) async {
    return await _asyncPrefs.setBool(_kRemoveTravelQuickReturnButton, value);
  }

  /// ----------------------------
  /// Methods for Profile Bars
  /// ----------------------------
  Future<String> getLifeBarOption() async {
    return await _asyncPrefs.getString(_kLifeBarOption) ?? 'ask';
  }

  Future setLifeBarOption(String value) async {
    return await _asyncPrefs.setString(_kLifeBarOption, value);
  }

  /// ----------------------------
  /// Methods for extra player information
  /// ----------------------------

  Future<bool> getExtraPlayerInformation() async {
    return await _asyncPrefs.getBool(_kExtraPlayerInformation) ?? true;
  }

  Future setExtraPlayerInformation(bool value) async {
    return await _asyncPrefs.setBool(_kExtraPlayerInformation, value);
  }

  // *************
  Future<String> getProfileStatsEnabled() async {
    return await _asyncPrefs.getString(_kProfileStatsEnabled) ?? "0";
  }

  Future setProfileStatsEnabled(String value) async {
    return await _asyncPrefs.setString(_kProfileStatsEnabled, value);
  }

  // *************
  Future<List<String>> getShareAttackOptions() async {
    return await _asyncPrefs.getStringList(_kShareAttackOptions) ?? <String>[];
  }

  Future setShareAttackOptions(List<String> value) async {
    return await _asyncPrefs.setStringList(_kShareAttackOptions, value);
  }

  // *************
  Future<int> getTSCEnabledStatus() async {
    return await _asyncPrefs.getInt(_kTSCEnabledStatus) ?? -1;
  }

  Future setTSCEnabledStatus(int value) async {
    return await _asyncPrefs.setInt(_kTSCEnabledStatus, value);
  }

  // *************
  Future<int> getYataStatsEnabledStatus() async {
    return await _asyncPrefs.getInt(_kYataStatsEnabledStatus) ?? 1;
  }

  Future setYataStatsEnabledStatus(int value) async {
    return await _asyncPrefs.setInt(_kYataStatsEnabledStatus, value);
  }

  // *************
  Future<String> getFriendlyFactions() async {
    return await _asyncPrefs.getString(_kFriendlyFactions) ?? "";
  }

  Future setFriendlyFactions(String value) async {
    return await _asyncPrefs.setString(_kFriendlyFactions, value);
  }

  // *************
  Future<bool> getNotesWidgetEnabledProfile() async {
    return await _asyncPrefs.getBool(_kNotesWidgetEnabledProfile) ?? true;
  }

  Future setNotesWidgetEnabledProfile(bool value) async {
    return await _asyncPrefs.setBool(_kNotesWidgetEnabledProfile, value);
  }

  Future setNotesWidgetEnabledProfileWhenEmpty(bool value) async {
    return await _asyncPrefs.setBool(_kNotesWidgetEnabledProfileWhenEmpty, value);
  }

  Future<bool> getNotesWidgetEnabledProfileWhenEmpty() async {
    return await _asyncPrefs.getBool(_kNotesWidgetEnabledProfileWhenEmpty) ?? true;
  }

  // *************
  Future<bool> getExtraPlayerNetworth() async {
    return await _asyncPrefs.getBool(_kExtraPlayerNetworth) ?? false;
  }

  Future setExtraPlayerNetworth(bool value) async {
    return await _asyncPrefs.setBool(_kExtraPlayerNetworth, value);
  }

  // *************
  Future<bool> getHitInMiniProfileOpensNewTab() async {
    return await _asyncPrefs.getBool(_kHitInMiniProfileOpensNewTab) ?? false;
  }

  Future setHitInMiniProfileOpensNewTab(bool value) async {
    return await _asyncPrefs.setBool(_kHitInMiniProfileOpensNewTab, value);
  }

  Future<bool> getHitInMiniProfileOpensNewTabAndChangeTab() async {
    return await _asyncPrefs.getBool(_kHitInMiniProfileOpensNewTabAndChangeTab) ?? true;
  }

  Future setHitInMiniProfileOpensNewTabAndChangeTab(bool value) async {
    return await _asyncPrefs.setBool(_kHitInMiniProfileOpensNewTabAndChangeTab, value);
  }

  /// ----------------------------
  /// Methods for foreign stocks
  /// ----------------------------
  Future<List<String>> getStockCountryFilter() async {
    return await _asyncPrefs.getStringList(_kStockCountryFilter) ?? List<String>.filled(12, '1');
  }

  Future setStockCountryFilter(List<String> value) async {
    return await _asyncPrefs.setStringList(_kStockCountryFilter, value);
  }

  Future<List<String>> getStockTypeFilter() async {
    return await _asyncPrefs.getStringList(_kStockTypeFilter) ?? List<String>.filled(4, '1');
  }

  Future setStockTypeFilter(List<String> value) async {
    return await _asyncPrefs.setStringList(_kStockTypeFilter, value);
  }

  Future<String> getStockSort() async {
    return await _asyncPrefs.getString(_kStockSort) ?? 'profit';
  }

  Future setStockSort(String value) async {
    return await _asyncPrefs.setString(_kStockSort, value);
  }

  Future<int> getStockCapacity() async {
    return await _asyncPrefs.getInt(_kStockCapacity) ?? 1;
  }

  Future setStockCapacity(int value) async {
    return await _asyncPrefs.setInt(_kStockCapacity, value);
  }

  Future<bool> getShowForeignInventory() async {
    return await _asyncPrefs.getBool(_kShowForeignInventory) ?? true;
  }

  Future setShowForeignInventory(bool value) async {
    return await _asyncPrefs.setBool(_kShowForeignInventory, value);
  }

  Future<bool> getShowArrivalTime() async {
    return await _asyncPrefs.getBool(_kShowArrivalTime) ?? true;
  }

  Future setShowArrivalTime(bool value) async {
    return await _asyncPrefs.setBool(_kShowArrivalTime, value);
  }

  Future<bool> getShowBarsCooldownAnalysis() async {
    return await _asyncPrefs.getBool(_kShowBarsCooldownAnalysis) ?? true;
  }

  Future setShowBarsCooldownAnalysis(bool value) async {
    return await _asyncPrefs.setBool(_kShowBarsCooldownAnalysis, value);
  }

  Future<String> getTravelTicket() async {
    return await _asyncPrefs.getString(_kTravelTicket) ?? "private";
  }

  Future setTravelTicket(String value) async {
    return await _asyncPrefs.setString(_kTravelTicket, value);
  }

  Future<String> getForeignStocksDataProvider() async {
    return await _asyncPrefs.getString(_kForeignStocksDataProvider) ?? "yata";
  }

  Future setForeignStocksDataProvider(String value) async {
    return await _asyncPrefs.setString(_kForeignStocksDataProvider, value);
  }

  Future<bool> getRestocksNotificationEnabled() async {
    return await _asyncPrefs.getBool(_kRestocksEnabled) ?? false;
  }

  Future setRestocksNotificationEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kRestocksEnabled, value);
  }

  Future<String> getActiveRestocks() async {
    return await _asyncPrefs.getString(_kActiveRestocks) ?? "{}";
  }

  Future setActiveRestocks(String value) async {
    return await _asyncPrefs.setString(_kActiveRestocks, value);
  }

  Future<List<String>> getHiddenForeignStocks() async {
    return await _asyncPrefs.getStringList(_kHiddenForeignStocks) ?? [];
  }

  Future setHiddenForeignStocks(List<String> value) async {
    return await _asyncPrefs.setStringList(_kHiddenForeignStocks, value);
  }

  Future<bool> getCountriesAlphabeticalFilter() async {
    return await _asyncPrefs.getBool(_kCountriesAlphabeticalFilter) ?? true;
  }

  Future setCountriesAlphabeticalFilter(bool value) async {
    return await _asyncPrefs.setBool(_kCountriesAlphabeticalFilter, value);
  }

  /// ----------------------------
  /// Methods for notification types
  /// ----------------------------
  Future<String> getTravelNotificationType() async {
    return await _asyncPrefs.getString(_kTravelNotificationType) ?? '0';
  }

  Future setTravelNotificationType(String value) async {
    return await _asyncPrefs.setString(_kTravelNotificationType, value);
  }

  Future<String> getEnergyNotificationType() async {
    return await _asyncPrefs.getString(_kEnergyNotificationType) ?? '0';
  }

  Future setEnergyNotificationType(String value) async {
    return await _asyncPrefs.setString(_kEnergyNotificationType, value);
  }

  Future<int> getEnergyNotificationValue() async {
    return await _asyncPrefs.getInt(_kEnergyNotificationValue) ?? 0;
  }

  Future setEnergyNotificationValue(int value) async {
    return await _asyncPrefs.setInt(_kEnergyNotificationValue, value);
  }

  Future setEnergyPercentageOverride(bool value) async {
    return await _asyncPrefs.setBool(_kEnergyCustomOverride, value);
  }

  Future<bool> getEnergyPercentageOverride() async {
    return await _asyncPrefs.getBool(_kEnergyCustomOverride) ?? false;
  }

  Future<String> getNerveNotificationType() async {
    return await _asyncPrefs.getString(_kNerveNotificationType) ?? '0';
  }

  Future setNerveNotificationType(String value) async {
    return await _asyncPrefs.setString(_kNerveNotificationType, value);
  }

  Future<int> getNerveNotificationValue() async {
    return await _asyncPrefs.getInt(_kNerveNotificationValue) ?? 0;
  }

  Future setNerveNotificationValue(int value) async {
    return await _asyncPrefs.setInt(_kNerveNotificationValue, value);
  }

  Future setNervePercentageOverride(bool value) async {
    return await _asyncPrefs.setBool(_kNerveCustomOverride, value);
  }

  Future<bool> getNervePercentageOverride() async {
    return await _asyncPrefs.getBool(_kNerveCustomOverride) ?? false;
  }

  Future<String> getLifeNotificationType() async {
    return await _asyncPrefs.getString(_kLifeNotificationType) ?? '0';
  }

  Future setLifeNotificationType(String value) async {
    return await _asyncPrefs.setString(_kLifeNotificationType, value);
  }

  Future<String> getDrugNotificationType() async {
    return await _asyncPrefs.getString(_kDrugNotificationType) ?? '0';
  }

  Future setDrugNotificationType(String value) async {
    return await _asyncPrefs.setString(_kDrugNotificationType, value);
  }

  Future<String> getMedicalNotificationType() async {
    return await _asyncPrefs.getString(_kMedicalNotificationType) ?? '0';
  }

  Future setMedicalNotificationType(String value) async {
    return await _asyncPrefs.setString(_kMedicalNotificationType, value);
  }

  Future<String> getBoosterNotificationType() async {
    return await _asyncPrefs.getString(_kBoosterNotificationType) ?? '0';
  }

  Future setBoosterNotificationType(String value) async {
    return await _asyncPrefs.setString(_kBoosterNotificationType, value);
  }

  Future<String> getHospitalNotificationType() async {
    return await _asyncPrefs.getString(_kHospitalNotificationType) ?? '0';
  }

  Future setHospitalNotificationType(String value) async {
    return await _asyncPrefs.setString(_kHospitalNotificationType, value);
  }

  Future<int> getHospitalNotificationAhead() async {
    return await _asyncPrefs.getInt(_kHospitalNotificationAhead) ?? 40;
  }

  Future setHospitalNotificationAhead(int value) async {
    return await _asyncPrefs.setInt(_kHospitalNotificationAhead, value);
  }

  Future<int> getHospitalAlarmAhead() async {
    return await _asyncPrefs.getInt(_kHospitalAlarmAhead) ?? 1;
  }

  Future setHospitalAlarmAhead(int value) async {
    return await _asyncPrefs.setInt(_kHospitalAlarmAhead, value);
  }

  Future<int> getHospitalTimerAhead() async {
    return await _asyncPrefs.getInt(_kHospitalTimerAhead) ?? 40;
  }

  Future setHospitalTimerAhead(int value) async {
    return await _asyncPrefs.setInt(_kHospitalTimerAhead, value);
  }

  Future<String> getJailNotificationType() async {
    return await _asyncPrefs.getString(_kJailNotificationType) ?? '0';
  }

  Future setJailNotificationType(String value) async {
    return await _asyncPrefs.setString(_kJailNotificationType, value);
  }

  Future<int> getJailNotificationAhead() async {
    return await _asyncPrefs.getInt(_kJailNotificationAhead) ?? 40;
  }

  Future setJailNotificationAhead(int value) async {
    return await _asyncPrefs.setInt(_kJailNotificationAhead, value);
  }

  Future<int> getJailAlarmAhead() async {
    return await _asyncPrefs.getInt(_kJailAlarmAhead) ?? 1;
  }

  Future setJailAlarmAhead(int value) async {
    return await _asyncPrefs.setInt(_kJailAlarmAhead, value);
  }

  Future<int> getJailTimerAhead() async {
    return await _asyncPrefs.getInt(_kJailTimerAhead) ?? 40;
  }

  Future setJailTimerAhead(int value) async {
    return await _asyncPrefs.setInt(_kJailTimerAhead, value);
  }

  // Ranked War notification
  Future<String> getRankedWarNotificationType() async {
    return await _asyncPrefs.getString(_kRankedWarNotificationType) ?? '0';
  }

  Future setRankedWarNotificationType(String value) async {
    return await _asyncPrefs.setString(_kRankedWarNotificationType, value);
  }

  Future<int> getRankedWarNotificationAhead() async {
    return await _asyncPrefs.getInt(_kRankedWarNotificationAhead) ?? 60;
  }

  Future setRankedWarNotificationAhead(int value) async {
    return await _asyncPrefs.setInt(_kRankedWarNotificationAhead, value);
  }

  Future<int> getRankedWarAlarmAhead() async {
    return await _asyncPrefs.getInt(_kRankedWarAlarmAhead) ?? 1;
  }

  Future setRankedWarAlarmAhead(int value) async {
    return await _asyncPrefs.setInt(_kRankedWarAlarmAhead, value);
  }

  Future<int> getRankedWarTimerAhead() async {
    return await _asyncPrefs.getInt(_kRankedWarTimerAhead) ?? 60;
  }

  Future setRankedWarTimerAhead(int value) async {
    return await _asyncPrefs.setInt(_kRankedWarTimerAhead, value);
  }

  //

  // Ranked War notification
  Future<String> getRaceStartNotificationType() async {
    return await _asyncPrefs.getString(_kRaceStartNotificationType) ?? '0';
  }

  Future setRaceStartNotificationType(String value) async {
    return await _asyncPrefs.setString(_kRaceStartNotificationType, value);
  }

  Future<int> getRaceStartNotificationAhead() async {
    return await _asyncPrefs.getInt(_kRaceStartNotificationAhead) ?? 60;
  }

  Future setRaceStartNotificationAhead(int value) async {
    return await _asyncPrefs.setInt(_kRaceStartNotificationAhead, value);
  }

  Future<int> getRaceStartAlarmAhead() async {
    return await _asyncPrefs.getInt(_kRaceStartAlarmAhead) ?? 1;
  }

  Future setRaceStartAlarmAhead(int value) async {
    return await _asyncPrefs.setInt(_kRaceStartAlarmAhead, value);
  }

  Future<int> getRaceStartTimerAhead() async {
    return await _asyncPrefs.getInt(_kRaceStartTimerAhead) ?? 60;
  }

  Future setRaceStartTimerAhead(int value) async {
    return await _asyncPrefs.setInt(_kRaceStartTimerAhead, value);
  }

  //

  Future<bool> getManualAlarmVibration() async {
    return await _asyncPrefs.getBool(_kManualAlarmVibration) ?? true;
  }

  Future setManualAlarmVibration(bool value) async {
    return await _asyncPrefs.setBool(_kManualAlarmVibration, value);
  }

  Future<bool> getManualAlarmSound() async {
    return await _asyncPrefs.getBool(_kManualAlarmSound) ?? true;
  }

  Future setManualAlarmSound(bool value) async {
    return await _asyncPrefs.setBool(_kManualAlarmSound, value);
  }

  Future<bool> getShowHeaderWallet() async {
    return await _asyncPrefs.getBool(_kShowHeaderWallet) ?? true;
  }

  Future setShowHeaderWallet(bool value) async {
    return await _asyncPrefs.setBool(_kShowHeaderWallet, value);
  }

  Future<bool> getShowHeaderIcons() async {
    return await _asyncPrefs.getBool(_kShowHeaderIcons) ?? true;
  }

  Future setShowHeaderIcons(bool value) async {
    return await _asyncPrefs.setBool(_kShowHeaderIcons, value);
  }

  Future<List<String>> getIconsFiltered() async {
    return await _asyncPrefs.getStringList(_kIconsFiltered) ?? <String>[];
  }

  Future setIconsFiltered(List<String> value) async {
    return await _asyncPrefs.setStringList(_kIconsFiltered, value);
  }

  Future<bool> getDedicatedTravelCard() async {
    return await _asyncPrefs.getBool(_kDedicatedTravelCard) ?? true;
  }

  Future setDedicatedTravelCard(bool value) async {
    return await _asyncPrefs.setBool(_kDedicatedTravelCard, value);
  }

  Future<bool> getDisableTravelSection() async {
    return await _asyncPrefs.getBool(_kDisableTravelSection) ?? false;
  }

  Future setDisableTravelSection(bool value) async {
    return await _asyncPrefs.setBool(_kDisableTravelSection, value);
  }

  Future<bool> getWarnAboutChains() async {
    return await _asyncPrefs.getBool(_kWarnAboutChains) ?? true;
  }

  Future setWarnAboutChains(bool value) async {
    return await _asyncPrefs.setBool(_kWarnAboutChains, value);
  }

  Future<bool> getWarnAboutExcessEnergy() async {
    return await _asyncPrefs.getBool(_kWarnAboutExcessEnergy) ?? true;
  }

  Future setWarnAboutExcessEnergy(bool value) async {
    return await _asyncPrefs.setBool(_kWarnAboutExcessEnergy, value);
  }

  Future<int> getWarnAboutExcessEnergyThreshold() async {
    return await _asyncPrefs.getInt(_kWarnAboutExcessEnergyThreshold) ?? 200;
  }

  Future setWarnAboutExcessEnergyThreshold(int value) async {
    return await _asyncPrefs.setInt(_kWarnAboutExcessEnergyThreshold, value);
  }

  // -- Travel Agency Warnings

  Future<bool> getTravelEnergyExcessWarning() async {
    return await _asyncPrefs.getBool(_kTravelEnergyExcessWarning) ?? true;
  }

  Future setTravelEnergyExcessWarning(bool value) async {
    return await _asyncPrefs.setBool(_kTravelEnergyExcessWarning, value);
  }

  Future<RangeValues> getTravelEnergyRangeWarningRange() async {
    final int min = await _asyncPrefs.getInt(_kTravelEnergyRangeWarningThresholdMin) ?? 10;
    final int max = await _asyncPrefs.getInt(_kTravelEnergyRangeWarningThresholdMax) ?? 100;
    return RangeValues(min.toDouble(), max == 110 ? 110 : max.toDouble());
  }

  Future setTravelEnergyRangeWarningRange(int min, int max) async {
    await _asyncPrefs.setInt(_kTravelEnergyRangeWarningThresholdMin, min);
    await _asyncPrefs.setInt(_kTravelEnergyRangeWarningThresholdMax, max >= 110 ? 110 : max);
  }

  Future<bool> getTravelNerveExcessWarning() async {
    return await _asyncPrefs.getBool(_kTravelNerveExcessWarning) ?? true;
  }

  Future setTravelNerveExcessWarning(bool value) async {
    return await _asyncPrefs.setBool(_kTravelNerveExcessWarning, value);
  }

  Future<int> getTravelNerveExcessWarningThreshold() async {
    return await _asyncPrefs.getInt(_kTravelNerveExcessWarningThreshold) ?? 50;
  }

  Future setTravelNerveExcessWarningThreshold(int value) async {
    return await _asyncPrefs.setInt(_kTravelNerveExcessWarningThreshold, value);
  }

  Future<bool> getTravelLifeExcessWarning() async {
    return await _asyncPrefs.getBool(_kTravelLifeExcessWarning) ?? true;
  }

  Future setTravelLifeExcessWarning(bool value) async {
    return await _asyncPrefs.setBool(_kTravelLifeExcessWarning, value);
  }

  Future<int> getTravelLifeExcessWarningThreshold() async {
    return await _asyncPrefs.getInt(_kTravelLifeExcessWarningThreshold) ?? 50;
  }

  Future setTravelLifeExcessWarningThreshold(int value) async {
    return await _asyncPrefs.setInt(_kTravelLifeExcessWarningThreshold, value);
  }

  Future<bool> getTravelDrugCooldownWarning() async {
    return await _asyncPrefs.getBool(_kTravelDrugCooldownWarning) ?? true;
  }

  Future setTravelDrugCooldownWarning(bool value) async {
    return await _asyncPrefs.setBool(_kTravelDrugCooldownWarning, value);
  }

  Future<bool> getTravelBoosterCooldownWarning() async {
    return await _asyncPrefs.getBool(_kTravelBoosterCooldownWarning) ?? true;
  }

  Future setTravelBoosterCooldownWarning(bool value) async {
    return await _asyncPrefs.setBool(_kTravelBoosterCooldownWarning, value);
  }

  Future<bool> getTravelWalletMoneyWarning() async {
    return await _asyncPrefs.getBool(_kTravelWalletMoneyWarning) ?? true;
  }

  Future setTravelWalletMoneyWarning(bool value) async {
    return await _asyncPrefs.setBool(_kTravelWalletMoneyWarning, value);
  }

  Future<int> getTravelWalletMoneyWarningThreshold() async {
    return await _asyncPrefs.getInt(_kTravelWalletMoneyWarningThreshold) ?? 50000;
  }

  Future setTravelWalletMoneyWarningThreshold(int value) async {
    return await _asyncPrefs.setInt(_kTravelWalletMoneyWarningThreshold, value);
  }

  // -- Terminal

  Future<bool> getTerminalEnabled() async {
    return await _asyncPrefs.getBool(_kTerminalEnabled) ?? false;
  }

  Future setTerminalEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kTerminalEnabled, value);
  }

  // -- Events

  Future<bool> getExpandEvents() async {
    return await _asyncPrefs.getBool(_kExpandEvents) ?? false;
  }

  Future setExpandEvents(bool value) async {
    return await _asyncPrefs.setBool(_kExpandEvents, value);
  }

  Future<int> getEventsShowNumber() async {
    return await _asyncPrefs.getInt(_kEventsShowNumber) ?? 25;
  }

  Future setEventsShowNumber(int value) async {
    return await _asyncPrefs.setInt(_kEventsShowNumber, value);
  }

  Future<int> getEventsLastRetrieved() async {
    return await _asyncPrefs.getInt(_kEventsLastRetrieved) ?? 0;
  }

  Future setEventsLastRetrieved(int value) async {
    return await _asyncPrefs.setInt(_kEventsLastRetrieved, value);
  }

  Future<List<String>> getEventsSave() async {
    return await _asyncPrefs.getStringList(_kEventsSave) ?? [];
  }

  Future setEventsSave(List<String> value) async {
    return await _asyncPrefs.setStringList(_kEventsSave, value);
  }

  // --

  Future<bool> getExpandMessages() async {
    return await _asyncPrefs.getBool(_kExpandMessages) ?? false;
  }

  Future setExpandMessages(bool value) async {
    return await _asyncPrefs.setBool(_kExpandMessages, value);
  }

  Future<int> getMessagesShowNumber() async {
    return await _asyncPrefs.getInt(_kMessagesShowNumber) ?? 25;
  }

  Future setMessagesShowNumber(int value) async {
    return await _asyncPrefs.setInt(_kMessagesShowNumber, value);
  }

  Future<bool> getExpandBasicInfo() async {
    return await _asyncPrefs.getBool(_kExpandBasicInfo) ?? false;
  }

  Future setExpandBasicInfo(bool value) async {
    return await _asyncPrefs.setBool(_kExpandBasicInfo, value);
  }

  Future<bool> getExpandNetworth() async {
    return await _asyncPrefs.getBool(_kExpandNetworth) ?? false;
  }

  Future setExpandNetworth(bool value) async {
    return await _asyncPrefs.setBool(_kExpandNetworth, value);
  }

  /// ----------------------------
  /// Methods job addiction in Profile
  /// ----------------------------
  Future<int> getJobAddictionValue() async {
    return await _asyncPrefs.getInt(_kJobAddictionValue) ?? 0;
  }

  Future setJobAdditionValue(int value) async {
    return await _asyncPrefs.setInt(_kJobAddictionValue, value);
  }

  //--

  Future<int> getJobAddictionNextCallTime() async {
    return await _asyncPrefs.getInt(_kJobAddictionNextCallTime) ?? 0;
  }

  Future setJobAddictionNextCallTime(int value) async {
    return await _asyncPrefs.setInt(_kJobAddictionNextCallTime, value);
  }

  /// ----------------------------
  /// Methods for reviving
  /// ----------------------------

  Future<bool> getUseNukeRevive() async {
    return await _asyncPrefs.getBool(_kUseNukeRevive) ?? true;
  }

  Future setUseNukeRevive(bool value) async {
    return await _asyncPrefs.setBool(_kUseNukeRevive, value);
  }

  Future<bool> getUseUhcRevive() async {
    return await _asyncPrefs.getBool(_kUseUhcRevive) ?? false;
  }

  Future setUseUhcRevive(bool value) async {
    return await _asyncPrefs.setBool(_kUseUhcRevive, value);
  }

  Future<bool> getUseHelaRevive() async {
    return await _asyncPrefs.getBool(_kUseHelaRevive) ?? false;
  }

  Future setUseHelaRevive(bool value) async {
    return await _asyncPrefs.setBool(_kUseHelaRevive, value);
  }

  Future<bool> getUseWtfRevive() async {
    return await _asyncPrefs.getBool(_kUseWtfRevive) ?? false;
  }

  Future setUseWtfRevive(bool value) async {
    return await _asyncPrefs.setBool(_kUseWtfRevive, value);
  }

  Future<bool> getUseMidnightXRevive() async {
    return await _asyncPrefs.getBool(_kUseMidnightXRevive) ?? false;
  }

  Future setUseMidnightXevive(bool value) async {
    return await _asyncPrefs.setBool(_kUseMidnightXRevive, value);
  }

  /// ---------------------------------------
  /// Methods for stats sharing configuration
  /// ---------------------------------------
  Future<bool> getStatsShareIncludeHiddenTargets() async {
    return await _asyncPrefs.getBool(_kStatsShareIncludeHiddenTargets) ?? true;
  }

  Future setStatsShareIncludeHiddenTargets(bool value) async {
    return await _asyncPrefs.setBool(_kStatsShareIncludeHiddenTargets, value);
  }

  //

  Future<bool> getStatsShareShowOnlyTotals() async {
    return await _asyncPrefs.getBool(_kStatsShareShowOnlyTotals) ?? false;
  }

  Future setStatsShareShowOnlyTotals(bool value) async {
    return await _asyncPrefs.setBool(_kStatsShareShowOnlyTotals, value);
  }

  //

  Future<bool> getStatsShareShowEstimatesIfNoSpyAvailable() async {
    return await _asyncPrefs.getBool(_kStatsShareShowEstimatesIfNoSpyAvailable) ?? true;
  }

  Future setStatsShareShowEstimatesIfNoSpyAvailable(bool value) async {
    return await _asyncPrefs.setBool(_kStatsShareShowEstimatesIfNoSpyAvailable, value);
  }

  //

  Future<bool> getStatsShareIncludeTargetsWithNoStatsAvailable() async {
    return await _asyncPrefs.getBool(_kStatsShareIncludeTargetsWithNoStatsAvailable) ?? false;
  }

  Future setStatsShareIncludeTargetsWithNoStatsAvailable(bool value) async {
    return await _asyncPrefs.setBool(_kStatsShareIncludeTargetsWithNoStatsAvailable, value);
  }

  /// ----------------------------
  /// Methods for shortcuts
  /// ----------------------------
  Future<bool> getShortcutsEnabledProfile() async {
    return await _asyncPrefs.getBool(_kEnableShortcuts) ?? true;
  }

  Future setShortcutsEnabledProfile(bool value) async {
    return await _asyncPrefs.setBool(_kEnableShortcuts, value);
  }

  Future<String> getShortcutTile() async {
    return await _asyncPrefs.getString(_kShortcutTile) ?? 'both';
  }

  Future setShortcutTile(String value) async {
    return await _asyncPrefs.setString(_kShortcutTile, value);
  }

  Future<String> getShortcutMenu() async {
    return await _asyncPrefs.getString(_kShortcutMenu) ?? 'carousel';
  }

  Future setShortcutMenu(String value) async {
    return await _asyncPrefs.setString(_kShortcutMenu, value);
  }

  Future<List<String>> getActiveShortcutsList() async {
    return await _asyncPrefs.getStringList(_kActiveShortcutsList) ?? <String>[];
  }

  Future setActiveShortcutsList(List<String> value) async {
    return await _asyncPrefs.setStringList(_kActiveShortcutsList, value);
  }

  /// ----------------------------
  /// Methods for easy crimes
  /// ----------------------------
  Future<List<String>> getActiveCrimesList() async {
    return await _asyncPrefs.getStringList(_kActiveCrimesList) ?? <String>[];
  }

  Future setActiveCrimesList(List<String> value) async {
    return await _asyncPrefs.setStringList(_kActiveCrimesList, value);
  }

  /// ----------------------------
  /// Methods for quick items
  /// ----------------------------
  Future<List<String>> getQuickItemsList() async {
    return await _asyncPrefs.getStringList(_kQuickItemsList) ?? <String>[];
  }

  Future setQuickItemsList(List<String> value) async {
    return await _asyncPrefs.setStringList(_kQuickItemsList, value);
  }

  Future<List<String>> getQuickItemsListFaction() async {
    return await _asyncPrefs.getStringList(_kQuickItemsListFaction) ?? <String>[];
  }

  Future setQuickItemsListFaction(List<String> value) async {
    return await _asyncPrefs.setStringList(_kQuickItemsListFaction, value);
  }

  Future<int> getNumberOfLoadouts() async {
    return await _asyncPrefs.getInt(_kQuickItemsLoadoutsNumber) ?? 3;
  }

  Future setNumberOfLoadouts(int value) async {
    return await _asyncPrefs.setInt(_kQuickItemsLoadoutsNumber, value);
  }

  /// ----------------------------
  /// Methods for loot
  /// ----------------------------
  Future<String> getLootTimerType() async {
    return await _asyncPrefs.getString(_kLootTimerType) ?? 'timer';
  }

  Future setLootTimerType(String value) async {
    return await _asyncPrefs.setString(_kLootTimerType, value);
  }

  Future<String> getLootNotificationType() async {
    return await _asyncPrefs.getString(_kLootNotificationType) ?? '0';
  }

  Future setLootNotificationType(String value) async {
    return await _asyncPrefs.setString(_kLootNotificationType, value);
  }

  Future<String> getLootNotificationAhead() async {
    return await _asyncPrefs.getString(_kLootNotificationAhead) ?? '0';
  }

  Future setLootNotificationAhead(String value) async {
    return await _asyncPrefs.setString(_kLootNotificationAhead, value);
  }

  Future<String> getLootAlarmAhead() async {
    return await _asyncPrefs.getString(_kLootAlarmAhead) ?? '0';
  }

  Future setLootAlarmAhead(String value) async {
    return await _asyncPrefs.setString(_kLootAlarmAhead, value);
  }

  Future<String> getLootTimerAhead() async {
    return await _asyncPrefs.getString(_kLootTimerAhead) ?? '0';
  }

  Future setLootTimerAhead(String value) async {
    return await _asyncPrefs.setString(_kLootTimerAhead, value);
  }

  Future<List<String>> getLootFiltered() async {
    return await _asyncPrefs.getStringList(_kLootFiltered) ?? <String>[];
  }

  Future setLootFiltered(List<String> value) async {
    return await _asyncPrefs.setStringList(_kLootFiltered, value);
  }

  /// ----------------------------
  /// Methods for Trades Calculator
  /// ----------------------------
  Future<bool> getTradeCalculatorEnabled() async {
    return await _asyncPrefs.getBool(_kTradeCalculatorEnabled) ?? true;
  }

  Future setTradeCalculatorEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kTradeCalculatorEnabled, value);
  }

  Future<bool> getAWHEnabled() async {
    return await _asyncPrefs.getBool(_kAWHEnabled) ?? true;
  }

  Future setAWHEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kAWHEnabled, value);
  }

  Future<bool> getTornExchangeEnabled() async {
    return await _asyncPrefs.getBool(_kTornExchangeEnabled) ?? true;
  }

  Future setTornExchangeEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kTornExchangeEnabled, value);
  }

  Future<bool> getTornExchangeProfitEnabled() async {
    return await _asyncPrefs.getBool(_kTornExchangeProfitEnabled) ?? false;
  }

  Future setTornExchangeProfitEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kTornExchangeProfitEnabled, value);
  }

  /// ----------------------------
  /// Methods for City Finder
  /// ----------------------------
  Future<bool> getCityEnabled() async {
    return await _asyncPrefs.getBool(_kCityFinderEnabled) ?? true;
  }

  Future setCityEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kCityFinderEnabled, value);
  }

  /// ----------------------------
  /// Methods for Awards
  /// ----------------------------
  Future<String> getAwardsSort() async {
    return await _asyncPrefs.getString(_kAwardsSort) ?? '';
  }

  Future setAwardsSort(String value) async {
    return await _asyncPrefs.setString(_kAwardsSort, value);
  }

  Future<bool> getShowAchievedAwards() async {
    return await _asyncPrefs.getBool(_kShowAchievedAwards) ?? true;
  }

  Future setShowAchievedAwards(bool value) async {
    return await _asyncPrefs.setBool(_kShowAchievedAwards, value);
  }

  Future<List<String?>> getHiddenAwardCategories() async {
    return await _asyncPrefs.getStringList(_kHiddenAwardCategories) ?? <String>[];
  }

  Future setHiddenAwardCategories(List<String?> value) async {
    return await _asyncPrefs.setStringList(_kHiddenAwardCategories, value as List<String>);
  }

  /// ----------------------------
  /// Methods for Items
  /// ----------------------------
  Future<String> getItemsSort() async {
    return await _asyncPrefs.getString(_kItemsSort) ?? '';
  }

  Future setItemsSort(String value) async {
    return await _asyncPrefs.setString(_kItemsSort, value);
  }

  Future<int> getOnlyOwnedItemsFilter() async {
    return await _asyncPrefs.getInt(_kOnlyOwnedItemsFilter) ?? 0;
  }

  Future setOnlyOwnedItemsFilter(int value) async {
    return await _asyncPrefs.setInt(_kOnlyOwnedItemsFilter, value);
  }

  Future<List<String>> getHiddenItemsCategories() async {
    return await _asyncPrefs.getStringList(_kHiddenItemsCategories) ?? <String>[];
  }

  Future setHiddenItemsCategories(List<String> value) async {
    return await _asyncPrefs.setStringList(_kHiddenItemsCategories, value);
  }

  Future<List<String>> getPinnedItems() async {
    return await _asyncPrefs.getStringList(_kPinnedItems) ?? <String>[];
  }

  Future setPinnedItems(List<String> value) async {
    return await _asyncPrefs.setStringList(_kPinnedItems, value);
  }

  /// ----------------------------
  /// Methods for Stakeouts
  /// ----------------------------
  Future<bool> getStakeoutsEnabled() async {
    return await _asyncPrefs.getBool(_kStakeoutsEnabled) ?? true;
  }

  Future setStakeoutsEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kStakeoutsEnabled, value);
  }

  Future<List<String>> getStakeouts() async {
    return await _asyncPrefs.getStringList(_kStakeouts) ?? [];
  }

  Future setStakeouts(List<String> value) async {
    return await _asyncPrefs.setStringList(_kStakeouts, value);
  }

  Future<int> getStakeoutsSleepTime() async {
    return await _asyncPrefs.getInt(_kStakeoutsSleepTime) ?? 0;
  }

  Future setStakeoutsSleepTime(int value) async {
    return await _asyncPrefs.setInt(_kStakeoutsSleepTime, value);
  }

  Future<int> getStakeoutsFetchDelayLimit() async {
    return await _asyncPrefs.getInt(_kStakeoutsFetchDelayLimit) ?? 60;
  }

  Future setStakeoutsFetchDelayLimit(int value) async {
    return await _asyncPrefs.setInt(_kStakeoutsFetchDelayLimit, value);
  }

  /// ----------------------------
  /// Methods for Chat Removal
  /// ----------------------------
  Future<bool> getChatRemovalEnabled() async {
    return await _asyncPrefs.getBool(_kChatRemovalEnabled) ?? true;
  }

  Future setChatRemovalEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kChatRemovalEnabled, value);
  }

  Future<bool> getChatRemovalActive() async {
    return await _asyncPrefs.getBool(_kChatRemovalActive) ?? false;
  }

  Future setChatRemovalActive(bool value) async {
    return await _asyncPrefs.setBool(_kChatRemovalActive, value);
  }

  /// ----------------------------
  /// Methods for Chat Highlight
  /// ----------------------------
  Future<bool> getHighlightChat() async {
    return await _asyncPrefs.getBool(_kHighlightChat) ?? true;
  }

  Future setHighlightChat(bool value) async {
    return await _asyncPrefs.setBool(_kHighlightChat, value);
  }

  Future<List<String>> getHighlightWordList() async {
    return await _asyncPrefs.getStringList(_kHighlightChatWordsList) ?? const [];
  }

  Future setHighlightWordList(List<String> value) async {
    return await _asyncPrefs.setStringList(_kHighlightChatWordsList, value);
  }

  Future<int> getHighlightColor() async {
    return await _asyncPrefs.getInt(_kHighlightColor) ?? 0x701397248;
  }

  Future setHighlightColor(int value) async {
    return await _asyncPrefs.setInt(_kHighlightColor, value);
  }

  /// -------------------
  /// ALTERNATIVE KEYS
  /// -------------------

  // YATA
  Future<bool> getAlternativeYataKeyEnabled() async {
    return await _asyncPrefs.getBool(_kAlternativeYataKeyEnabled) ?? false;
  }

  Future setAlternativeYataKeyEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kAlternativeYataKeyEnabled, value);
  }

  Future<String> getAlternativeYataKey() async {
    return await _asyncPrefs.getString(_kAlternativeYataKey) ?? "";
  }

  Future setAlternativeYataKey(String value) async {
    return await _asyncPrefs.setString(_kAlternativeYataKey, value);
  }

  // TORN STATS
  Future<bool> getAlternativeTornStatsKeyEnabled() async {
    return await _asyncPrefs.getBool(_kAlternativeTornStatsKeyEnabled) ?? false;
  }

  Future setAlternativeTornStatsKeyEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kAlternativeTornStatsKeyEnabled, value);
  }

  Future<String> getAlternativeTornStatsKey() async {
    return await _asyncPrefs.getString(_kAlternativeTornStatsKey) ?? "";
  }

  Future setAlternativeTornStatsKey(String value) async {
    return await _asyncPrefs.setString(_kAlternativeTornStatsKey, value);
  }

  // TORN SPIES CENTRAL
  Future<bool> getAlternativeTSCKeyEnabled() async {
    return await _asyncPrefs.getBool(_kAlternativeTSCKeyEnabled) ?? false;
  }

  Future setAlternativeTSCKeyEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kAlternativeTSCKeyEnabled, value);
  }

  Future<String> getAlternativeTSCKey() async {
    return await _asyncPrefs.getString(_kAlternativeTSCKey) ?? "";
  }

  Future setAlternativeTSCKey(String value) async {
    return await _asyncPrefs.setString(_kAlternativeTSCKey, value);
  }

  /// ---------------------
  /// TORNSTATS STATS CHART
  /// ---------------------

  Future<String> getTornStatsChartSave() async {
    return await _asyncPrefs.getString(_kTornStatsChartSave) ?? "";
  }

  Future setTornStatsChartSave(String value) async {
    return await _asyncPrefs.setString(_kTornStatsChartSave, value);
  }

  Future<int> getTornStatsChartDateTime() async {
    return await _asyncPrefs.getInt(_kTornStatsChartDateTime) ?? 0;
  }

  Future setTornStatsChartDateTime(int value) async {
    return await _asyncPrefs.setInt(_kTornStatsChartDateTime, value);
  }

  Future<bool> getTornStatsChartEnabled() async {
    return await _asyncPrefs.getBool(_kTornStatsChartEnabled) ?? true;
  }

  Future setTornStatsChartEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kTornStatsChartEnabled, value);
  }

  Future<String> getTornStatsChartType() async {
    return await _asyncPrefs.getString(_kTornStatsChartType) ?? "line";
  }

  Future setTornStatsChartType(String value) async {
    return await _asyncPrefs.setString(_kTornStatsChartType, value);
  }

  Future<bool> getTornStatsChartInCollapsedMiscCard() async {
    return await _asyncPrefs.getBool(_kTornStatsChartInCollapsedMiscCard) ?? true;
  }

  Future setTornStatsChartInCollapsedMiscCard(bool value) async {
    return await _asyncPrefs.setBool(_kTornStatsChartInCollapsedMiscCard, value);
  }

  /// -------------------
  /// TORN ATTACK CENTRAL
  /// -------------------
  Future<bool> getTACEnabled() async {
    return await _asyncPrefs.getBool(_kTACEnabled) ?? false;
  }

  Future setTACEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kTACEnabled, value);
  }

  Future<String> getTACFilters() async {
    return await _asyncPrefs.getString(_kTACFilters) ?? "";
  }

  Future setTACFilters(String value) async {
    return await _asyncPrefs.setString(_kTACFilters, value);
  }

  Future<String> getTACTargets() async {
    return await _asyncPrefs.getString(_kTACTargets) ?? "";
  }

  Future setTACTargets(String value) async {
    return await _asyncPrefs.setString(_kTACTargets, value);
  }

  /// -----------------------------
  /// METHODS FOR LISTS IN SETTINGS
  /// -----------------------------
  Future<bool> getUserScriptsEnabled() async {
    return await _asyncPrefs.getBool(_kUserScriptsEnabled) ?? true;
  }

  Future setUserScriptsEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kUserScriptsEnabled, value);
  }

  Future<bool> getUserScriptsNotifyUpdates() async {
    return await _asyncPrefs.getBool(_kUserScriptsNotifyUpdates) ?? true;
  }

  Future setUserScriptsNotifyUpdates(bool value) async {
    return await _asyncPrefs.setBool(_kUserScriptsNotifyUpdates, value);
  }

  Future<String?> getUserScriptsList() async {
    return await _asyncPrefs.getString(_kUserScriptsList);
  }

  Future setUserScriptsList(String value) async {
    return await _asyncPrefs.setString(_kUserScriptsList, value);
  }

  // --

  Future<bool> getUserScriptsSectionNeverVisited() async {
    return await _asyncPrefs.getBool(_kUserScriptsV2FirstTime) ?? true;
  }

  Future setUserScriptsSectionNeverVisited(bool value) async {
    return await _asyncPrefs.setBool(_kUserScriptsV2FirstTime, value);
  }

  // --

  Future<bool> getUserScriptsFeatInjectionTimeShown() async {
    return await _asyncPrefs.getBool(_kUserScriptsFeatInjectionTimeShown) ?? false;
  }

  Future setUserScriptsFeatInjectionTimeShown(bool value) async {
    return await _asyncPrefs.setBool(_kUserScriptsFeatInjectionTimeShown, value);
  }

  Future<List<String>> getUserScriptsForcedVersions() async {
    return await _asyncPrefs.getStringList(_kUserScriptsForcedVersions) ?? [];
  }

  Future setUserScriptsForcedVersions(List<String> value) async {
    return await _asyncPrefs.setStringList(_kUserScriptsForcedVersions, value);
  }

  /// --------------------------------
  /// METHODS FOR ORGANIZED CRIMES v2
  /// --------------------------------

  Future<bool> getPlayerInOCv2() async {
    return await _asyncPrefs.getBool(_kPlayerAlreadyInOCv2) ?? false;
  }

  Future setPlayerInOCv2(bool value) async {
    return await _asyncPrefs.setBool(_kPlayerAlreadyInOCv2, value);
  }

  /// -----------------------------
  /// METHODS FOR ORGANIZED CRIMES
  /// -----------------------------

  Future<bool> getOCrimesEnabled() async {
    return await _asyncPrefs.getBool(_kOCrimesEnabled) ?? true;
  }

  Future setOCrimesEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kOCrimesEnabled, value);
  }

  Future<int> getOCrimeDisregarded() async {
    return await _asyncPrefs.getInt(_kOCrimeDisregarded) ?? 0;
  }

  Future setOCrimeDisregarded(int value) async {
    return await _asyncPrefs.setInt(_kOCrimeDisregarded, value);
  }

  Future<int> getOCrimeLastKnown() async {
    return await _asyncPrefs.getInt(_kOCrimeLastKnown) ?? 0;
  }

  Future setOCrimeLastKnown(int value) async {
    return await _asyncPrefs.setInt(_kOCrimeLastKnown, value);
  }

  /// -----------------------------
  /// METHODS FOR VAULT SHARE
  /// -----------------------------
  Future<bool> getVaultEnabled() async {
    return await _asyncPrefs.getBool(_kVaultShareEnabled) ?? true;
  }

  Future setVaultEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kVaultShareEnabled, value);
  }

  Future<String> getVaultShareCurrent() async {
    return await _asyncPrefs.getString(_kVaultShareCurrent) ?? "";
  }

  Future setVaultShareCurrent(String value) async {
    return await _asyncPrefs.setString(_kVaultShareCurrent, value);
  }

  /// -----------------------------
  /// METHODS FOR JAIL
  /// -----------------------------
  Future<String> getJailModel() async {
    return await _asyncPrefs.getString(_kJailModel) ?? "";
  }

  Future setJailModel(String value) async {
    return await _asyncPrefs.setString(_kJailModel, value);
  }

  /// -----------------------------
  /// METHODS FOR BOUNTIES
  /// -----------------------------
  Future<String> getBountiesModel() async {
    return await _asyncPrefs.getString(_kBountiesModel) ?? "";
  }

  Future setBountiesModel(String value) async {
    return await _asyncPrefs.setString(_kBountiesModel, value);
  }

  /// -----------------------------
  /// METHODS FOR EXTRA ACCESS TO RANKED WAR
  /// -----------------------------
  Future<bool> getRankedWarsInMenu() async {
    return await _asyncPrefs.getBool(_kRankedWarsInMenu) ?? false;
  }

  Future setRankedWarsInMenu(bool value) async {
    return await _asyncPrefs.setBool(_kRankedWarsInMenu, value);
  }

  Future<bool> getRankedWarsInProfile() async {
    return await _asyncPrefs.getBool(_kRankedWarsInProfile) ?? true;
  }

  Future setRankedWarsInProfile(bool value) async {
    return await _asyncPrefs.setBool(_kRankedWarsInProfile, value);
  }

  Future<bool> getRankedWarsInProfileShowTotalHours() async {
    return await _asyncPrefs.getBool(_kRankedWarsInProfileShowTotalHours) ?? false;
  }

  Future setRankedWarsInProfileShowTotalHours(bool value) async {
    return await _asyncPrefs.setBool(_kRankedWarsInProfileShowTotalHours, value);
  }

  /// -----------------------
  /// METHODS FOR RETALIATION
  /// -----------------------
  Future<bool> getRetaliationSectionEnabled() async {
    return await _asyncPrefs.getBool(_kRetaliationSectionEnabled) ?? true;
  }

  Future setRetaliationSectionEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kRetaliationSectionEnabled, value);
  }

  Future<bool> getSingleRetaliationOpensBrowser() async {
    return await _asyncPrefs.getBool(_kSingleRetaliationOpensBrowser) ?? false;
  }

  Future setSingleRetaliationOpensBrowser(bool value) async {
    return await _asyncPrefs.setBool(_kSingleRetaliationOpensBrowser, value);
  }

  /// -----------------------------
  /// METHODS FOR DATA STOCK MARKET
  /// -----------------------------
  Future<String> getDataStockMarket() async {
    return await _asyncPrefs.getString(_kDataStockMarket) ?? "";
  }

  Future setDataStockMarket(String value) async {
    return await _asyncPrefs.setString(_kDataStockMarket, value);
  }

  Future<bool> getStockExchangeInMenu() async {
    return await _asyncPrefs.getBool(_kStockExchangeInMenu) ?? false;
  }

  Future setStockExchangeInMenu(bool value) async {
    return await _asyncPrefs.setBool(_kStockExchangeInMenu, value);
  }

  /// -----------------------------
  /// METHODS FOR WEB VIEW TABS
  /// -----------------------------
  Future<int> getWebViewLastActiveTab() async {
    return await _asyncPrefs.getInt(_kWebViewLastActiveTab) ?? 0;
  }

  Future setWebViewLastActiveTab(int value) async {
    return await _asyncPrefs.setInt(_kWebViewLastActiveTab, value);
  }

  Future<String> getWebViewSessionCookie() async {
    return await _asyncPrefs.getString(_kWebViewSessionCookie) ?? '';
  }

  Future setWebViewSessionCookie(String value) async {
    return await _asyncPrefs.setString(_kWebViewSessionCookie, value);
  }

  Future<String> getWebViewMainTab() async {
    return await _asyncPrefs.getString(_kWebViewMainTab) ?? '{"tabsSave": []}';
  }

  Future setWebViewMainTab(String value) async {
    return await _asyncPrefs.setString(_kWebViewMainTab, value);
  }

  Future<String> getWebViewSecondaryTabs() async {
    return await _asyncPrefs.getString(_kWebViewSecondaryTabs) ?? '{"tabsSave": []}';
  }

  Future setWebViewSecondaryTabs(String value) async {
    return await _asyncPrefs.setString(_kWebViewSecondaryTabs, value);
  }

  Future<bool> getUseTabsFullBrowser() async {
    return await _asyncPrefs.getBool(_kUseTabsInFullBrowser) ?? true;
  }

  Future setUseTabsFullBrowser(bool value) async {
    return await _asyncPrefs.setBool(_kUseTabsInFullBrowser, value);
  }

  Future<bool> getUseTabsBrowserDialog() async {
    return await _asyncPrefs.getBool(_kUseTabsInBrowserDialog) ?? true;
  }

  Future setUseTabsBrowserDialog(bool value) async {
    return await _asyncPrefs.setBool(_kUseTabsInBrowserDialog, value);
  }

  // -- Remove unused tabs

  Future<bool> getRemoveUnusedTabs() async {
    return await _asyncPrefs.getBool(_kRemoveUnusedTabs) ?? true;
  }

  Future setRemoveUnusedTabs(bool value) async {
    return await _asyncPrefs.setBool(_kRemoveUnusedTabs, value);
  }

  Future<bool> getRemoveUnusedTabsIncludesLocked() async {
    return await _asyncPrefs.getBool(_kRemoveUnusedTabsIncludesLocked) ?? false;
  }

  Future setRemoveUnusedTabsIncludesLocked(bool value) async {
    return await _asyncPrefs.setBool(_kRemoveUnusedTabsIncludesLocked, value);
  }

  Future<int> getRemoveUnusedTabsRangeDays() async {
    return await _asyncPrefs.getInt(_kRemoveUnusedTabsRangeDays) ?? 7;
  }

  Future setRemoveUnusedTabsRangeDays(int value) async {
    return await _asyncPrefs.setInt(_kRemoveUnusedTabsRangeDays, value);
  }

  // ---------------------

  Future<bool> getOnlyLoadTabsWhenUsed() async {
    return await _asyncPrefs.getBool(_kOnlyLoadTabsWhenUsed) ?? true;
  }

  Future setOnlyLoadTabsWhenUsed(bool value) async {
    return await _asyncPrefs.setBool(_kOnlyLoadTabsWhenUsed, value);
  }

  Future<bool> getAutomaticChangeToNewTabFromURL() async {
    return await _asyncPrefs.getBool(_kAutomaticChangeToNewTabFromURL) ?? true;
  }

  Future setAutomaticChangeToNewTabFromURL(bool value) async {
    return await _asyncPrefs.setBool(_kAutomaticChangeToNewTabFromURL, value);
  }

  Future<bool> getUseTabsHideFeature() async {
    return await _asyncPrefs.getBool(_kUseTabsHideFeature) ?? true;
  }

  Future setUseTabsHideFeature(bool value) async {
    return await _asyncPrefs.setBool(_kUseTabsHideFeature, value);
  }

  Future setTabsHideBarColor(int value) async {
    return await _asyncPrefs.setInt(_kTabsHideBarColor, value);
  }

  Future<int> getTabsHideBarColor() async {
    return await _asyncPrefs.getInt(_kTabsHideBarColor) ?? 0xFF4CAF40;
  }

  Future<bool> getShowTabLockWarnings() async {
    return await _asyncPrefs.getBool(_kShowTabLockWarnings) ?? true;
  }

  Future setShowTabLockWarnings(bool value) async {
    return await _asyncPrefs.setBool(_kShowTabLockWarnings, value);
  }

  Future<bool> getFullLockNavigationAttemptOpensNewTab() async {
    return await _asyncPrefs.getBool(_kFullLockNavigationAttemptOpensNewTab) ?? false;
  }

  Future setFullLockNavigationAttemptOpensNewTab(bool value) async {
    return await _asyncPrefs.setBool(_kFullLockNavigationAttemptOpensNewTab, value);
  }

  // -- LockedTabsNavigationExceptions
  final List<List<String>> _defaultFullLockedTabsNavigationExceptions = [
    ["https://www.torn.com/item.php", "https://www.torn.com/loader.php?sid=itemsMods"],
    ["https://www.torn.com/item.php", "https://www.torn.com/page.php?sid=ammo"],
  ];

  Future<String> getLockedTabsNavigationExceptions() async {
    return await _asyncPrefs.getString(_kFullLockedTabsNavigationExceptions) ??
        json.encode(_defaultFullLockedTabsNavigationExceptions);
  }

  Future setLockedTabsNavigationExceptions(String value) async {
    return await _asyncPrefs.setString(_kFullLockedTabsNavigationExceptions, value);
  }

  // --

  Future<bool> getUseTabsIcons() async {
    return await _asyncPrefs.getBool(_kUseTabsIcons) ?? true;
  }

  Future setUseTabsIcons(bool value) async {
    return await _asyncPrefs.setBool(_kUseTabsIcons, value);
  }

  Future<bool> getHideTabs() async {
    return await _asyncPrefs.getBool(_kHideTabs) ?? false;
  }

  Future setHideTabs(bool value) async {
    return await _asyncPrefs.setBool(_kHideTabs, value);
  }

  Future<bool> getReminderAboutHideTabFeature() async {
    return await _asyncPrefs.getBool(_kReminderAboutHideTabFeature) ?? false;
  }

  Future setReminderAboutHideTabFeature(bool value) async {
    return await _asyncPrefs.setBool(_kReminderAboutHideTabFeature, value);
  }

  // -- Quick menu tab

  Future<bool> getFullScreenExplanationShown() async {
    return await _asyncPrefs.getBool(_kFullScreenExplanationShown) ?? false;
  }

  Future setFullScreenExplanationShown(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenExplanationShown, value);
  }

  Future<bool> getFullScreenRemovesWidgets() async {
    return await _asyncPrefs.getBool(_kFullScreenRemovesWidgets) ?? true;
  }

  Future setFullScreenRemovesWidgets(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenRemovesWidgets, value);
  }

  Future<bool> getFullScreenRemovesChat() async {
    return await _asyncPrefs.getBool(_kFullScreenRemovesChat) ?? true;
  }

  Future setFullScreenRemovesChat(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenRemovesChat, value);
  }

  Future<bool> getFullScreenExtraCloseButton() async {
    return await _asyncPrefs.getBool(_kFullScreenExtraCloseButton) ?? false;
  }

  Future setFullScreenExtraCloseButton(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenExtraCloseButton, value);
  }

  Future<bool> getFullScreenExtraReloadButton() async {
    return await _asyncPrefs.getBool(_kFullScreenExtraReloadButton) ?? false;
  }

  Future setFullScreenExtraReloadButton(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenExtraReloadButton, value);
  }

  Future<bool> getFullScreenOverNotch() async {
    return await _asyncPrefs.getBool(_kFullScreenOverNotch) ?? true;
  }

  Future setFullScreenOverNotch(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenOverNotch, value);
  }

  Future<bool> getFullScreenOverBottom() async {
    return await _asyncPrefs.getBool(_kFullScreenOverBottom) ?? true;
  }

  Future setFullScreenOverBottom(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenOverBottom, value);
  }

  Future<bool> getFullScreenOverSides() async {
    return await _asyncPrefs.getBool(_kFullScreenOverSides) ?? true;
  }

  Future setFullScreenOverSides(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenOverSides, value);
  }

  //--

  Future<bool> getFullScreenByShortTap() async {
    return await _asyncPrefs.getBool(_kFullScreenByShortTap) ?? false;
  }

  Future setFullScreenByShortTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenByShortTap, value);
  }

  //--
  Future<bool> getFullScreenByLongTap() async {
    return await _asyncPrefs.getBool(_kFullScreenByLongTap) ?? true;
  }

  Future setFullScreenByLongTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenByLongTap, value);
  }

  //--

  Future<bool> getFullScreenByNotificationTap() async {
    return await _asyncPrefs.getBool(_kFullScreenByNotificationTap) ?? false;
  }

  Future setFullScreenByNotificationTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenByNotificationTap, value);
  }

  //--

  Future<bool> getFullScreenByShortChainingTap() async {
    return await _asyncPrefs.getBool(_kFullScreenByShortChainingTap) ?? false;
  }

  Future setFullScreenByShortChainingTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenByShortChainingTap, value);
  }

  Future<bool> getFullScreenByLongChainingTap() async {
    return await _asyncPrefs.getBool(_kFullScreenByLongChainingTap) ?? false;
  }

  Future setFullScreenByLongChainingTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenByLongChainingTap, value);
  }

  //--

  Future<bool> getFullScreenByDeepLinkTap() async {
    return await _asyncPrefs.getBool(_kFullScreenByDeepLinkTap) ?? false;
  }

  Future setFullScreenByDeepLinkTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenByDeepLinkTap, value);
  }

  //--

  Future<bool> getFullScreenByQuickItemTap() async {
    return await _asyncPrefs.getBool(_kFullScreenByQuickItemTap) ?? false;
  }

  Future setFullScreenByQuickItemTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenByQuickItemTap, value);
  }

  //--
  Future<bool> getFullScreenIncludesPDAButtonTap() async {
    return await _asyncPrefs.getBool(_kFullScreenIncludesPDAButtonTap) ?? false;
  }

  Future setFullScreenIncludesPDAButtonTap(bool value) async {
    return await _asyncPrefs.setBool(_kFullScreenIncludesPDAButtonTap, value);
  }

  /// --------------------------------
  /// Methods for notification actions
  /// --------------------------------

  Future<String> getLifeNotificationTapAction() async {
    return await _asyncPrefs.getString(_kLifeNotificationTapAction) ?? 'itemsOwn';
  }

  Future setLifeNotificationTapAction(String value) async {
    return await _asyncPrefs.setString(_kLifeNotificationTapAction, value);
  }

  //

  Future<String> getDrugsNotificationTapAction() async {
    return await _asyncPrefs.getString(_kDrugsNotificationTapAction) ?? 'itemsOwn';
  }

  Future setDrugsNotificationTapAction(String value) async {
    return await _asyncPrefs.setString(_kDrugsNotificationTapAction, value);
  }

  //

  Future<String> getMedicalNotificationTapAction() async {
    return await _asyncPrefs.getString(_kMedicalNotificationTapAction) ?? 'itemsOwn';
  }

  Future setMedicalNotificationTapAction(String value) async {
    return await _asyncPrefs.setString(_kMedicalNotificationTapAction, value);
  }

  //

  Future<String> getBoosterNotificationTapAction() async {
    return await _asyncPrefs.getString(_kBoosterNotificationTapAction) ?? 'itemsOwn';
  }

  Future setBoosterNotificationTapAction(String value) async {
    return await _asyncPrefs.setString(_kBoosterNotificationTapAction, value);
  }

  /// ----------------------------
  /// Methods for show cases
  /// ----------------------------
  /// tabs_general -> for tab use information in webview_stackview
  Future<List<String>> getShowCases() async {
    return await _asyncPrefs.getStringList(_kShowCases) ?? <String>[];
  }

  Future setShowCases(List<String> value) async {
    return await _asyncPrefs.setStringList(_kShowCases, value);
  }

  /// ----------------------------
  /// Methods for stats analytics
  /// ----------------------------
  Future<int> getStatsFirstLoginTimestamp() async {
    return await _asyncPrefs.getInt(_kStatsFirstLoginTimestamp) ?? 0;
  }

  Future setStatsFirstLoginTimestamp(int value) async {
    return await _asyncPrefs.setInt(_kStatsFirstLoginTimestamp, value);
  }

  Future<int> getStatsCumulatedAppUseSeconds() async {
    return await _asyncPrefs.getInt(_kStatsCumulatedAppUseSeconds) ?? 0;
  }

  Future setStatsCumulatedAppUseSeconds(int value) async {
    return await _asyncPrefs.setInt(_kStatsCumulatedAppUseSeconds, value);
  }

  /// Current valid events:
  /// `Active_15m_in_4h` active for 15 minutes or more within 4 hours of first login
  /// `Active_30m_in_24h` active for 30 minutes or more within 24 hours of first login
  /// `Active_1h_in_3d` active for 1 hour or more within 3 days of first login
  /// `Active_2h_in_5d` active for 2 hours or more within 5 days of first login
  /// `Active_4h_in_7d` active for 4 hours or more within 7 days of first login
  ///
  /// List formatting: ["15m_4h", "30m_24h", "1h_3d", "2h_5d", "4h_7d"]
  Future<List<String>> getStatsEventsAchieved() async {
    return await _asyncPrefs.getStringList(_kStatsEventsAchieved) ?? [];
  }

  Future setStatsCumulatedEventsAchieved(List<String> value) async {
    return await _asyncPrefs.setStringList(_kStatsEventsAchieved, value);
  }

  /// ----------------------------
  /// Methods for appwidget
  /// ----------------------------
  Future<bool> getAppwidgetDarkMode() async {
    return await _asyncPrefs.getBool(_kAppwidgetDarkMode) ?? false;
  }

  Future setAppwidgetDarkMode(bool value) async {
    return await _asyncPrefs.setBool(_kAppwidgetDarkMode, value);
  }

  // ---

  Future<bool> getAppwidgetRemoveShortcutsOneRowLayout() async {
    return await _asyncPrefs.getBool(_kAppwidgetRemoveShortcutsOneRowLayout) ?? false;
  }

  Future setAppwidgetRemoveShortcutsOneRowLayout(bool value) async {
    return await _asyncPrefs.setBool(_kAppwidgetRemoveShortcutsOneRowLayout, value);
  }

  // ---

  Future<bool> getAppwidgetMoneyEnabled() async {
    return await _asyncPrefs.getBool(_kAppwidgetMoneyEnabled) ?? true;
  }

  Future setAppwidgetMoneyEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kAppwidgetMoneyEnabled, value);
  }

  // ---

  Future<bool> getAppwidgetCooldownTapOpensBrowser() async {
    return await _asyncPrefs.getBool(_kAppwidgetCooldownTapOpensBrowser) ?? false;
  }

  Future setAppwidgetCooldownTapOpensBrowser(bool value) async {
    return await _asyncPrefs.setBool(_kAppwidgetCooldownTapOpensBrowser, value);
  }

  Future<String> getAppwidgetCooldownTapOpensBrowserDestination() async {
    return await _asyncPrefs.getString(_kAppwidgetCooldownTapOpensBrowserDestination) ?? "own";
  }

  Future setAppwidgetCooldownTapOpensBrowserDestination(String value) async {
    return await _asyncPrefs.setString(_kAppwidgetCooldownTapOpensBrowserDestination, value);
  }

  // ---

  Future<bool> getAppwidgetExplanationShown() async {
    return await _asyncPrefs.getBool(_kAppwidgetExplanationShown) ?? false;
  }

  Future setAppwidgetExplanationShown(bool value) async {
    return await _asyncPrefs.setBool(_kAppwidgetExplanationShown, value);
  }

  /// ----------------------------
  /// Methods for permissions
  /// ----------------------------

  Future<int> getExactPermissionDialogShownAndroid() async {
    return await _asyncPrefs.getInt(_kExactPermissionDialogShownAndroid) ?? 0;
  }

  Future setExactPermissionDialogShownAndroid(int value) async {
    return await _asyncPrefs.setInt(_kExactPermissionDialogShownAndroid, value);
  }

  /// ----------------------------
  /// Webview downloads
  /// ----------------------------

  Future<bool> getDownloadActionShare() async {
    return await _asyncPrefs.getBool(_downloadActionShare) ?? true;
  }

  Future setDownloadActionShare(bool value) async {
    return await _asyncPrefs.setBool(_downloadActionShare, value);
  }

  /// ----------------------------
  /// Methods for Api Rate
  /// ----------------------------
  Future<bool> getShowApiRateInDrawer() async {
    return await _asyncPrefs.getBool(_kShowApiRateInDrawer) ?? false;
  }

  Future setShowApiRateInDrawer(bool value) async {
    return await _asyncPrefs.setBool(_kShowApiRateInDrawer, value);
  }

  Future<bool> getDelayApiCalls() async {
    return await _asyncPrefs.getBool(_kDelayApiCalls) ?? false;
  }

  Future setDelayApiCalls(bool value) async {
    return await _asyncPrefs.setBool(_kDelayApiCalls, value);
  }

  // ---

  Future<bool> getShowApiMaxCallWarning() async {
    return await _asyncPrefs.getBool(_kShowApiMaxCallWarning) ?? false;
  }

  Future setShowApiMaxCallWarning(bool value) async {
    return await _asyncPrefs.setBool(_kShowApiMaxCallWarning, value);
  }

  /// ----------------------------
  /// Methods for Memory
  /// ----------------------------
  Future<bool> getShowMemoryInDrawer() async {
    return await _asyncPrefs.getBool(_kShowMemoryInDrawer) ?? false;
  }

  Future setShowMemoryInDrawer(bool value) async {
    return await _asyncPrefs.setBool(_kShowMemoryInDrawer, value);
  }

  // ---

  Future<bool> getShowMemoryInWebview() async {
    return await _asyncPrefs.getBool(_kShowMemoryInWebview) ?? false;
  }

  Future setShowMemoryInWebview(bool value) async {
    return await _asyncPrefs.setBool(_kShowMemoryInWebview, value);
  }

  /// ----------------------------
  /// Methods for Refresh Rate
  /// ----------------------------
  Future<bool> getHighRefreshRateEnabled() async {
    return await _asyncPrefs.getBool(_kHighRefreshRateEnabled) ?? false;
  }

  Future setHighRefreshRateEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kHighRefreshRateEnabled, value);
  }

  /// ----------------------------
  /// Methods for Refresh Rate
  /// ----------------------------
  Future<String> getSplitScreenWebview() async {
    return await _asyncPrefs.getString(_kSplitScreenWebview) ?? 'off';
  }

  Future setSplitScreenWebview(String value) async {
    return await _asyncPrefs.setString(_kSplitScreenWebview, value);
  }

  Future<bool> getSplitScreenRevertsToApp() async {
    return await _asyncPrefs.getBool(_kSplitScreenRevertsToApp) ?? true;
  }

  Future setSplitScreenRevertsToApp(bool value) async {
    return await _asyncPrefs.setBool(_kSplitScreenRevertsToApp, value);
  }

  /// ----------------------------
  /// FCM Token
  /// ----------------------------
  Future<String> getFCMToken() async {
    return await _asyncPrefs.getString(_kFCMToken) ?? "";
  }

  Future setFCMToken(String value) async {
    return await _asyncPrefs.setString(_kFCMToken, value);
  }

  /// ----------------------------
  /// Methods for Sendbird notifications
  /// ----------------------------
  Future<bool> getSendbirdNotificationsEnabled() async {
    return await _asyncPrefs.getBool(_kSendbirdnotificationsEnabled) ?? false;
  }

  Future setSendbirdNotificationsEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kSendbirdnotificationsEnabled, value);
  }

  Future<String> getSendbirdSessionToken() async {
    return await _asyncPrefs.getString(_kSendbirdSessionToken) ?? "";
  }

  Future setSendbirdSessionToken(String value) async {
    return await _asyncPrefs.setString(_kSendbirdSessionToken, value);
  }

  Future<int> getSendbirdTokenTimestamp() async {
    return await _asyncPrefs.getInt(_kSendbirdTokenTimestamp) ?? 0;
  }

  Future setSendbirdTokenTimestamp(int timestamp) async {
    return await _asyncPrefs.setInt(_kSendbirdTokenTimestamp, timestamp);
  }

  Future<bool> getSendbirdExcludeFactionMessages() async {
    return await _asyncPrefs.getBool(_kSendbirdExcludeFactionMessages) ?? false;
  }

  Future setSendbirdExcludeFactionMessages(bool value) async {
    return await _asyncPrefs.setBool(_kSendbirdExcludeFactionMessages, value);
  }

  Future<bool> getSendbirdExcludeCompanyMessages() async {
    return await _asyncPrefs.getBool(_kSendbirdExcludeCompanyMessages) ?? false;
  }

  Future setSendbirdExcludeCompanyMessages(bool value) async {
    return await _asyncPrefs.setBool(_kSendbirdExcludeCompanyMessages, value);
  }

  ///////

  Future<bool> getBringBrowserForwardOnStart() async {
    return await _asyncPrefs.getBool(_kBringBrowserForwardOnStart) ?? false;
  }

  Future setBringBrowserForwardOnStart(bool value) async {
    return await _asyncPrefs.setBool(_kBringBrowserForwardOnStart, value);
  }

  /// -----------------------------------
  /// Methods for task periodic execution
  /// -----------------------------------

  /// Stores the last execution time for a given task name
  Future setLastExecutionTime(String taskName, int timestamp) async {
    return await _asyncPrefs.setInt("$_taskPrefix$taskName", timestamp);
  }

  /// Retrieves the last execution time for a given task name
  Future<int> getLastExecutionTime(String taskName) async {
    return await _asyncPrefs.getInt("$_taskPrefix$taskName") ?? 0;
  }

  /// Removes the stored execution time for a task
  Future removeLastExecutionTime(String taskName) async {
    await _asyncPrefs.remove("$_taskPrefix$taskName");
  }

  /// -----------------------------------
  /// Methods for Torn Calendar
  /// -----------------------------------

  Future<String> getTornCalendarModel() async {
    return await _asyncPrefs.getString(_kTornCalendarModel) ?? "";
  }

  Future setTornCalendarModel(String value) async {
    return await _asyncPrefs.setString(_kTornCalendarModel, value);
  }

  Future<int> getTornCalendarLastUpdate() async {
    return await _asyncPrefs.getInt(_kTornCalendarLastUpdate) ?? 0;
  }

  Future setTornCalendarLastUpdate(int timestamp) async {
    return await _asyncPrefs.setInt(_kTornCalendarLastUpdate, timestamp);
  }

  Future<bool> getTctClockHighlightsEvents() async {
    return await _asyncPrefs.getBool(_kTctClockHighlightsEvents) ?? true;
  }

  Future setTctClockHighlightsEvents(bool value) async {
    return await _asyncPrefs.setBool(_kTctClockHighlightsEvents, value);
  }

  /// -----------------------------------
  /// Methods for Drawer Sections
  /// -----------------------------------

  Future<bool> getShowWikiInDrawer() async {
    return await _asyncPrefs.getBool(_kShowWikiInDrawer) ?? true;
  }

  Future setShowWikiInDrawer(bool value) async {
    return await _asyncPrefs.setBool(_kShowWikiInDrawer, value);
  }

  /// -----------------------------------
  /// Methods for Live Activities
  /// -----------------------------------

  String _getLaPushTokenKey(LiveActivityType activityType) {
    switch (activityType) {
      case LiveActivityType.travel:
        return _kIosLiveActivityTravelPushToken;
    }
  }

  Future<void> setLaPushToken({
    required LiveActivityType activityType,
    required String? token,
  }) async {
    final key = _getLaPushTokenKey(activityType);
    if (token == null) {
      await _asyncPrefs.remove(key);
    } else {
      await _asyncPrefs.setString(key, token);
    }
  }

  Future<String?> getLaPushToken({
    required LiveActivityType activityType,
  }) async {
    final key = _getLaPushTokenKey(activityType);
    return await _asyncPrefs.getString(key);
  }

  Future<bool> getIosLiveActivityTravelEnabled() async {
    return await _asyncPrefs.getBool(_kIosLiveActivityTravelEnabled) ?? kSdkIos >= 16.2 ? true : false;
  }

  Future setIosLiveActivityTravelEnabled(bool value) async {
    return await _asyncPrefs.setBool(_kIosLiveActivityTravelEnabled, value);
  }

  /// ----------------------------
  /// Methods for player notes
  /// ----------------------------
  Future<List<Map<String, dynamic>>> getPlayerNotes() async {
    final String? notesString = await _asyncPrefs.getString(_kPlayerNotes);
    if (notesString == null || notesString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> notesList = json.decode(notesString);
      return notesList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future setPlayerNotes(List<Map<String, dynamic>> notes) async {
    final String notesString = json.encode(notes);
    return await _asyncPrefs.setString(_kPlayerNotes, notesString);
  }

  // ---

  Future<int> getPlayerNotesSort() async {
    return await _asyncPrefs.getInt(_kPlayerNotesSort) ?? 0;
  }

  Future setPlayerNotesSort(int value) async {
    return await _asyncPrefs.setInt(_kPlayerNotesSort, value);
  }

  Future<bool> getPlayerNotesSortAscending() async {
    return await _asyncPrefs.getBool(_kPlayerNotesSortAscending) ?? true;
  }

  Future setPlayerNotesSortAscending(bool value) async {
    return await _asyncPrefs.setBool(_kPlayerNotesSortAscending, value);
  }

  /// ----------------------------
  /// Methods for NOTES migration status
  /// ----------------------------
  // TODO: remove next version when migration to PlayerNotesProvider is removed in Drawer
  Future<bool> getMigrationCompleted() async {
    return await _asyncPrefs.getBool(_kPlayerNotesMigrationCompleted) ?? false;
  }

  Future setMigrationCompleted(bool completed) async {
    return await _asyncPrefs.setBool(_kPlayerNotesMigrationCompleted, completed);
  }
}
