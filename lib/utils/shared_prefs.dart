// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/widgets/webviews/webview_fab.dart';

class Prefs {
  ///
  /// Instantiation of the SharedPreferences library
  ///

  // General
  final String _kAppVersion = "pda_appVersion";
  final String _kAppAnnouncementDialogVersion = "pda_appAnnouncementDialogVersion";
  final String _kOwnDetails = "pda_ownDetails";
  final String _kLastAppUse = "pda_lastAppUse";

  // Native login
  final String _kNativePlayerEmail = "pda_nativePlayerEmail";
  final String _kLastAuthRedirect = "pda_lastAuthRedirect";
  final String _kTryAutomaticLogins = "pda_tryAutomaticLogins";

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

  // Browser gestures
  final String _kIosBrowserPinch = "pda_iosBrowserPinch";
  final String _kIosDisallowOverscroll = "pda_iosDisallowOverscroll";
  final String _kBrowserReverseNavigationSwipe = "pda_browserReverseNavigationSwipe";

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
  final String _kTSCEnabledStatus = "pda_tscEnabledStatus";
  final String _kYataStatsEnabledStatus = "pda_yataStatsEnabledStatus";

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
  // final String _kUserScriptsFirstTime = "pda_userScriptsFirstTime";
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

  // Split screen configuration
  final String _kSplitScreenWebview = "pda_splitScreenWebview";
  final String _kSplitScreenRevertsToApp = "pda_splitScreenRevertsToApp";

  // FCM token
  final String _kFCMToken = "pda_fcmToken";

  // Sendbird notifications
  final String _kSendbirdnotificationsEnabled = "pda_sendbirdNotificationsEnabled";
  final String _kSendbirdSessionToken = "pda_sendbirdSessionToken";
  final String _kSendbirdTokenTimestamp = "pda_sendbirdTimestamp";

  final String _kBringBrowserForwardOnStart = "pda_bringBrowserForwardOnStart";

  // Periodic tasks
  final String _taskPrefix = "pda_periodic_";

  // Torn Calendar
  final String _kTornCalendarModel = "pda_tornCalendarModel";
  final String _kTornCalendarLastUpdate = "pda_tornCalendarLastUpdate";
  final String _kTctClockHighlightsEvents = "pda_tctClockHighlightsEvents";

  /// SharedPreferences can be used on background events handlers.
  /// The problem is that the background handler run in a different isolate so, when we try to
  /// get a data, the shared preferences instance is empty.
  /// To avoid this, simply force a refresh
  Future reload() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
  }

  /// ----------------------------
  /// Methods for app version
  /// ----------------------------
  Future<String> getAppCompilation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAppVersion) ?? "";
  }

  Future<bool> setAppCompilation(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAppVersion, value);
  }

  /// -------------------------------
  /// Methods for announcement dialog
  /// -------------------------------

  Future<int> getAppAnnouncementDialogVersion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAppAnnouncementDialogVersion) ?? 0;
  }

  Future<bool> setAppAnnouncementDialogVersion(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kAppAnnouncementDialogVersion, value);
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

  /// ----------------------------
  /// Methods for native login
  /// ----------------------------
  Future<String> getNativePlayerEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNativePlayerEmail) ?? '';
  }

  Future<bool> setNativePlayerEmail(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kNativePlayerEmail, value);
  }

  Future<int> getLastAuthRedirect() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLastAuthRedirect) ?? 0;
  }

  Future<bool> setLastAuthRedirect(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kLastAuthRedirect, value);
  }

  Future<bool> getTryAutomaticLogins() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTryAutomaticLogins) ?? true;
  }

  Future<bool> setTryAutomaticLogins(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTryAutomaticLogins, value);
  }

  /// ----------------------------
  /// Methods for profile section order
  /// ----------------------------
  Future<List<String>> getProfileSectionOrder() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kProfileSectionOrder) ?? <String>[];
  }

  Future<bool> setProfileSectionOrder(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kProfileSectionOrder, value);
  }

  /// ------------------------------
  /// Methods for colored status card
  /// --------------------------------
  Future<bool> getColorCodedStatusCard() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kColorCodedStatusCard) ?? true;
  }

  Future<bool> setColorCodedStatusCard(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kColorCodedStatusCard, value);
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

  //**************
  Future<List<String>> getTargetsColorFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kTargetsColorFilter) ?? [];
  }

  Future<bool> setTargetsColorFilter(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kTargetsColorFilter, value);
  }

  //**************
  Future<List<String>> getWarFactions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kWarFactions) ?? <String>[];
  }

  Future<bool> setWarFactions(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kWarFactions, value);
  }

  Future<List<String>> getFilterListInWars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kFilterListInWars) ?? [];
  }

  Future<bool> setFilterListInWars(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kFilterListInWars, value);
  }

  Future<int> getOnlineFilterInWars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kOnlineFilterInWars) ?? 0;
  }

  Future<bool> setOnlineFilterInWars(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kOnlineFilterInWars, value);
  }

  Future<int> getOkayRedFilterInWars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kOkayRedFilterInWars) ?? 0;
  }

  Future<bool> setOkayRedFilterInWars(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kOkayRedFilterInWars, value);
  }

  Future<bool> getCountryFilterInWars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCountryFilterInWars) ?? false;
  }

  Future<bool> setCountryFilterInWars(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kCountryFilterInWars, value);
  }

  Future<int> getTravelingFilterInWars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTravelingFilterInWars) ?? 0;
  }

  Future<bool> setTravelingFilterInWars(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTravelingFilterInWars, value);
  }

  Future<bool> getShowChainWidgetInWars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowChainWidgetInWars) ?? true;
  }

  Future<bool> setShowChainWidgetInWars(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowChainWidgetInWars, value);
  }

  Future<String> getWarMembersSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kWarMembersSort) ?? '';
  }

  Future<bool> setWarMembersSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kWarMembersSort, value);
  }

  Future<List<String>> getYataSpies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kYataSpies) ?? [];
  }

  Future<bool> setYataSpies(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kYataSpies, value);
  }

  Future<int> getYataSpiesTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kYataSpiesTime) ?? 0;
  }

  Future<bool> setYataSpiesTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kYataSpiesTime, value);
  }

  Future<String> getTornStatsSpies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTornStatsSpies) ?? "";
  }

  Future<bool> setTornStatsSpies(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTornStatsSpies, value);
  }

  Future<int> getTornStatsSpiesTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTornStatsSpiesTime) ?? 0;
  }

  Future<bool> setTornStatsSpiesTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTornStatsSpiesTime, value);
  }

  Future<int> getWarIntegrityCheckTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWarIntegrityCheckTime) ?? 0;
  }

  Future<bool> setWarIntegrityCheckTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kWarIntegrityCheckTime, value);
  }

  //**************
  Future<int> getChainingCurrentPage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kChainingCurrentPage) ?? 0;
  }

  Future<bool> setChainingCurrentPage(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kChainingCurrentPage, value);
  }

  Future<bool> getTargetSkippingAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTargetSkipping) ?? true;
  }

  Future<bool> setTargetSkipping(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTargetSkipping, value);
  }

  Future<bool> getTargetSkippingFirst() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTargetSkippingFirst) ?? false;
  }

  Future<bool> setTargetSkippingFirst(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTargetSkippingFirst, value);
  }

  Future<bool> getShowTargetsNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTargetsNotes) ?? true;
  }

  Future<bool> setShowTargetsNotes(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowTargetsNotes, value);
  }

  Future<bool> getShowBlankTargetsNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowBlankTargetsNotes) ?? false;
  }

  Future<bool> setShowBlankTargetsNotes(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowBlankTargetsNotes, value);
  }

  Future<bool> getShowOnlineFactionWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowOnlineFactionWarning) ?? true;
  }

  Future<bool> setShowOnlineFactionWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowOnlineFactionWarning, value);
  }

  Future<String> getChainWatcherSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kChainWatcherSettings) ?? '';
  }

  Future<bool> setChainWatcherSettings(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kChainWatcherSettings, value);
  }

  Future<List<String>> getChainWatcherPanicTargets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kChainWatcherPanicTargets) ?? <String>[];
  }

  Future<bool> setChainWatcherPanicTargets(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kChainWatcherPanicTargets, value);
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

  Future<bool> getChainWatcherNotificationsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kChainWatcherNotifications) ?? true;
  }

  Future<bool> setChainWatcherNotificationsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kChainWatcherNotifications, value);
  }

  Future<bool> getYataTargetsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kYataTargetsEnabled) ?? true;
  }

  Future<bool> setYataTargetsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kYataTargetsEnabled, value);
  }

  Future<bool> getStatusColorWidgetEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStatusColorWidgetEnabled) ?? true;
  }

  Future<bool> setStatusColorWidgetEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kStatusColorWidgetEnabled, value);
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

  Future<bool> getUseMaterial3() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseMaterial3Theme) ?? false;
  }

  Future<bool> setUseMaterial3(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseMaterial3Theme, value);
  }

  /// ----------------------------
  /// Methods for theme sync with web and device
  /// ----------------------------
  Future<bool> getSyncTornWebTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSyncTornWebTheme) ?? true;
  }

  Future<bool> setSyncTornWebTheme(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kSyncTornWebTheme, value);
  }

  Future<bool> getSyncDeviceTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSyncDeviceTheme) ?? false;
  }

  Future<bool> setSyncDeviceTheme(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kSyncDeviceTheme, value);
  }

  Future<String> getDarkThemeToSync() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDarkThemeToSync) ?? 'dark';
  }

  Future<bool> setDarkThemeToSync(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDarkThemeToSync, value);
  }

  /// ----------------------------
  /// Methods for dynamic app icons
  /// ----------------------------
  Future<bool> getDynamicAppIcons() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDynamicAppIcons) ?? true;
  }

  Future<bool> setDynamicAppIcons(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kDynamicAppIcons, value);
  }

  //--

  Future<String> getDynamicAppIconsManual() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDynamicAppIconsManual) ?? "off";
  }

  Future<bool> setDynamicAppIconsManual(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDynamicAppIconsManual, value);
  }

  /// ----------------------------
  /// Methods for vibration pattern
  /// ----------------------------
  Future<String> getVibrationPattern() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kVibrationPattern) ?? 'medium';
  }

  Future<bool> setVibrationPattern(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kVibrationPattern, value);
  }

  /// ----------------------------
  /// Methods for discreet notifications
  /// ----------------------------
  Future<bool> getDiscreetNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDiscreetNotifications) ?? false;
  }

  Future<bool> setDiscreetNotifications(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kDiscreetNotifications, value);
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
  Future<String> getOnBackButtonAppExit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kOnBackButtonAppExit) ?? 'stay';
  }

  Future<bool> setOnAppExit(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kOnBackButtonAppExit, value);
  }

  /// ----------------------------
  /// Methods for debug messages
  /// ----------------------------
  Future<bool> getDebugMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDebugMessages) ?? false;
  }

  Future<bool> setDebugMessages(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kDebugMessages, value);
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

  Future<String> getBrowserRefreshMethod() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBrowserRefreshMethod2) ?? "icon";
  }

  Future<bool> setBrowserRefreshMethod(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kBrowserRefreshMethod2, value);
  }

  Future<bool> getBrowserBottomBarStyleEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBrowserStyleBottomBarEnabled) ?? false;
  }

  Future<bool> setBrowserBottomBarStyleEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kBrowserStyleBottomBarEnabled, value);
  }

  Future<int> getBrowserBottomBarStyleType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kBrowserStyleBottomBarType) ?? 1;
  }

  Future<bool> setBrowserBottomBarStyleType(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kBrowserStyleBottomBarType, value);
  }

  Future<bool> getBrowserBottomBarStylePlaceTabsAtBottom() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBrowserBottomBarStylePlaceTabsAtBottom) ?? false;
  }

  Future<bool> setBrowserBottomBarStylePlaceTabsAtBottom(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kBrowserBottomBarStylePlaceTabsAtBottom, value);
  }

  Future<String> getTMenuButtonLongPressBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUseQuickBrowser) ?? "quick";
  }

  Future<bool> setTMenuButtonLongPressBrowser(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kUseQuickBrowser, value);
  }

  Future<bool> getRestoreSessionCookie() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRestoreSessionCookie) ?? false;
  }

  Future<bool> setRestoreSessionCookie(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRestoreSessionCookie, value);
  }

  Future<bool> getWebviewCacheEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWebviewCacheEnabled) ?? true;
  }

  Future<bool> setWebviewCacheEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kWebviewCacheEnabled, value);
  }

  /*
  Future<bool> getClearBrowserCacheNextOpportunity() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kClearBrowserCacheNextOpportunity) ?? false;
  }
  
  Future<bool> setClearBrowserCacheNextOpportunity(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kClearBrowserCacheNextOpportunity, value);
  }
  */

  Future<int> getAndroidBrowserScale() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAndroidBrowserScale) ?? 0;
  }

  Future<bool> setAndroidBrowserScale(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kAndroidBrowserScale, value);
  }

  Future<int> getAndroidBrowserTextScale() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAndroidBrowserTextScale) ?? 8;
  }

  Future<bool> setAndroidBrowserTextScale(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kAndroidBrowserTextScale, value);
  }

  // Settings - Browser FAB

  Future<bool> getWebviewFabEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWebviewFabEnabled) ?? false;
  }

  Future<bool> setWebviewFabEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kWebviewFabEnabled, value);
  }

  // --

  Future<bool> getWebviewFabShownNow() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWebviewFabShownNow) ?? true;
  }

  Future<bool> setWebviewFabShownNow(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kWebviewFabShownNow, value);
  }

  // --

  Future<String> getWebviewFabDirection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kWebviewFabDirection) ?? "center";
  }

  Future<bool> setWebviewFabDirection(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kWebviewFabDirection, value);
  }

  // --

  Future<bool> setWebviewFabPositionXY(List<int> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Convert list to JSON string for storage
    return prefs.setString(_kWebviewFabPositionXY, jsonEncode(value));
  }

  // Retrieve FAB position and decode JSON string to List<int>
  Future<List<int>> getWebviewFabPositionXY() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kWebviewFabPositionXY);
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWebviewFabOnlyFullScreen) ?? false;
  }

  Future<bool> setWebviewFabOnlyFullScreen(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kWebviewFabOnlyFullScreen, value);
  }

  // --

  Future<bool> setFabButtonCount(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kFabButtonCount, value);
  }

  Future<int> getFabButtonCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kFabButtonCount) ?? 4; // Default to 4 buttons
  }

// --

  Future<bool> setFabButtonActions(List<WebviewFabAction> actions) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final actionIndices = actions.map((action) => action.index).toList();
    return prefs.setStringList(
      _kFabButtonActions,
      actionIndices.map((e) => e.toString()).toList(),
    );
  }

  Future<List<WebviewFabAction>> getFabButtonActions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final actionStrings = prefs.getStringList(_kFabButtonActions);

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

  Future<bool> setFabDoubleTapAction(WebviewFabAction action) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kFabDoubleTapAction, action.index);
  }

  Future<WebviewFabAction> getFabDoubleTapAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final actionIndex = prefs.getInt(_kFabDoubleTapAction);
    return actionIndex != null
        ? FabActionExtension.fromIndex(actionIndex)
        : WebviewFabAction.openTabsMenu; // Default to Open Tabs Menu
  }

// --

  Future<bool> setFabTripleTapAction(WebviewFabAction action) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kFabTripleTapAction, action.index);
  }

  Future<WebviewFabAction> getFabTripleTapAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final actionIndex = prefs.getInt(_kFabTripleTapAction);
    return actionIndex != null
        ? FabActionExtension.fromIndex(actionIndex)
        : WebviewFabAction.closeCurrentTab; // Default to Close Current Tab
  }

  // FAB ENDS ###

  // Settings - Browser Gestures

  Future<bool> getIosBrowserPinch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIosBrowserPinch) ?? false;
  }

  Future<bool> setIosBrowserPinch(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kIosBrowserPinch, value);
  }

  Future<bool> getIosDisallowOverscroll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIosDisallowOverscroll) ?? false;
  }

  Future<bool> setIosDisallowOverscroll(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kIosDisallowOverscroll, value);
  }

  Future<bool> getBrowserReverseNavigationSwipe() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBrowserReverseNavigationSwipe) ?? false;
  }

  Future<bool> setBrowserReverseNavigationSwipe(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kBrowserReverseNavigationSwipe, value);
  }

  /// ----------------------------
  /// Methods for test browser
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
  /// Methods for notifications on launch
  /// ----------------------------
  Future<bool> getRemoveNotificationsOnLaunch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemoveNotificationsOnLaunch) ?? true;
  }

  Future<bool> setRemoveNotificationsOnLaunch(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRemoveNotificationsOnLaunch, value);
  }

  /// ----------------------------
  /// Methods for clock
  /// ----------------------------
  Future<String> getDefaultTimeFormat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultTimeFormat) ?? '24';
  }

  Future<bool> setDefaultTimeFormat(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultTimeFormat, value);
  }

  Future<String> getDefaultTimeZone() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultTimeZone) ?? 'local';
  }

  Future<bool> setDefaultTimeZone(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDefaultTimeZone, value);
  }

  Future<String> getShowDateInClock() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShowDateInClockString) ?? "dayfirst";
  }

  Future<bool> setShowDateInClock(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kShowDateInClockString, value);
  }

  Future<bool> getShowSecondsInClock() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowSecondsInClock) ?? true;
  }

  Future<bool> setShowSecondsInClock(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowSecondsInClock, value);
  }

  /// ----------------------------
  /// Methods for spies source
  /// ----------------------------
  Future<String> getSpiesSource() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSpiesSource) ?? 'yata';
  }

  Future<bool> setSpiesSource(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kSpiesSource, value);
  }

  Future<bool> getAllowMixedSpiesSources() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAllowMixedSpiesSources) ?? true;
  }

  Future<bool> setAllowMixedSpiesSources(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAllowMixedSpiesSources, value);
  }

  /// ----------------------------
  /// Methods for OC Crimes NNB Source
  /// ----------------------------
  Future<String> getNaturalNerveBarSource() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNaturalNerveBarSource) ?? 'yata';
  }

  Future<bool> setNaturalNerveBarSource(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kNaturalNerveBarSource, value);
  }

  Future<int> getNaturalNerveYataTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kNaturalNerveYataTime) ?? 0;
  }

  Future<bool> setNaturalNerveYataTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kNaturalNerveYataTime, value);
  }

  Future<String> getNaturalNerveYataModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNaturalNerveYataModel) ?? '';
  }

  Future<bool> setNaturalNerveYataModel(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kNaturalNerveYataModel, value);
  }

  Future<int> getNaturalNerveTornStatsTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kNaturalNerveTornStatsTime) ?? 0;
  }

  Future<bool> setNaturalNerveTornStatsTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kNaturalNerveTornStatsTime, value);
  }

  Future<String> getNaturalNerveTornStatsModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNaturalNerveTornStatsModel) ?? '';
  }

  Future<bool> setNaturalNerveTornStatsModel(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kNaturalNerveTornStatsModel, value);
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
  /// Methods for screen rotation
  /// ----------------------------

  Future<bool> getAllowScreenRotation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAllowScreenRotation) ?? false;
  }

  Future<bool> setAllowScreenRotation(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAllowScreenRotation, value);
  }

  /// ----------------------------
  /// Methods for iOS Link Preview
  /// ----------------------------

  Future<bool> getIosAllowLinkPreview() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIosAllowLinkPreview) ?? true;
  }

  Future<bool> setIosAllowLinkPreview(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kIosAllowLinkPreview, value);
  }

  /// ----------------------------
  /// Methods for excess tabs dialog persistence
  /// ----------------------------

  Future<bool> getExcessTabsAlerted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kExcessTabsAlerted) ?? false;
  }

  Future<bool> setExcessTabsAlerted(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kExcessTabsAlerted, value);
  }

  /// ----------------------------
  /// Methods for excess first tab lock
  /// ----------------------------

  Future<bool> getFirstTabLockAlerted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFirstTabLockAlerted) ?? false;
  }

  Future<bool> setFirstTabLockAlerted(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFirstTabLockAlerted, value);
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
    return prefs.getString(_kTravelNotificationBody) ?? 'Arriving at your destination!';
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

  Future<bool> getRemoveAirplane() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemoveAirplane) ?? false;
  }

  Future<bool> setRemoveAirplane(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRemoveAirplane, value);
  }

  Future<bool> getRemoveTravelQuickReturnButton() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemoveTravelQuickReturnButton) ?? false;
  }

  Future<bool> setRemoveTravelQuickReturnButton(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRemoveTravelQuickReturnButton, value);
  }

  /// ----------------------------
  /// Methods for Profile Bars
  /// ----------------------------
  Future<String> getLifeBarOption() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLifeBarOption) ?? 'ask';
  }

  Future<bool> setLifeBarOption(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLifeBarOption, value);
  }

  /// ----------------------------
  /// Methods for extra player information
  /// ----------------------------

  Future<bool> getExtraPlayerInformation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kExtraPlayerInformation) ?? true;
  }

  Future<bool> setExtraPlayerInformation(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kExtraPlayerInformation, value);
  }

  // *************
  Future<String> getProfileStatsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kProfileStatsEnabled) ?? "0";
  }

  Future<bool> setProfileStatsEnabled(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kProfileStatsEnabled, value);
  }

  // *************
  Future<int> getTSCEnabledStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTSCEnabledStatus) ?? -1;
  }

  Future<bool> setTSCEnabledStatus(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTSCEnabledStatus, value);
  }

  // *************
  Future<int> getYataStatsEnabledStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kYataStatsEnabledStatus) ?? 1;
  }

  Future<bool> setYataStatsEnabledStatus(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kYataStatsEnabledStatus, value);
  }

  // *************
  Future<String> getFriendlyFactions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFriendlyFactions) ?? "";
  }

  Future<bool> setFriendlyFactions(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kFriendlyFactions, value);
  }

  // *************
  Future<bool> getExtraPlayerNetworth() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kExtraPlayerNetworth) ?? false;
  }

  Future<bool> setExtraPlayerNetworth(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kExtraPlayerNetworth, value);
  }

  // *************
  Future<bool> getHitInMiniProfileOpensNewTab() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHitInMiniProfileOpensNewTab) ?? false;
  }

  Future<bool> setHitInMiniProfileOpensNewTab(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kHitInMiniProfileOpensNewTab, value);
  }

  Future<bool> getHitInMiniProfileOpensNewTabAndChangeTab() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHitInMiniProfileOpensNewTabAndChangeTab) ?? true;
  }

  Future<bool> setHitInMiniProfileOpensNewTabAndChangeTab(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kHitInMiniProfileOpensNewTabAndChangeTab, value);
  }

  /// ----------------------------
  /// Methods for foreign stocks
  /// ----------------------------
  Future<List<String>> getStockCountryFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStockCountryFilter) ?? List<String>.filled(12, '1');
  }

  Future<bool> setStockCountryFilter(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kStockCountryFilter, value);
  }

  Future<List<String>> getStockTypeFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStockTypeFilter) ?? List<String>.filled(4, '1');
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

  Future<bool> getShowArrivalTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowArrivalTime) ?? true;
  }

  Future<bool> setShowArrivalTime(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowArrivalTime, value);
  }

  Future<bool> getShowBarsCooldownAnalysis() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowBarsCooldownAnalysis) ?? true;
  }

  Future<bool> setShowBarsCooldownAnalysis(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowBarsCooldownAnalysis, value);
  }

  Future<String> getTravelTicket() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTravelTicket) ?? "private";
  }

  Future<bool> setTravelTicket(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTravelTicket, value);
  }

  Future<String> getForeignStocksDataProvider() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kForeignStocksDataProvider) ?? "yata";
  }

  Future<bool> setForeignStocksDataProvider(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kForeignStocksDataProvider, value);
  }

  Future<bool> getRestocksNotificationEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRestocksEnabled) ?? false;
  }

  Future<bool> setRestocksNotificationEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRestocksEnabled, value);
  }

  Future<String> getActiveRestocks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActiveRestocks) ?? "{}";
  }

  Future<bool> setActiveRestocks(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kActiveRestocks, value);
  }

  Future<List<String>> getHiddenForeignStocks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHiddenForeignStocks) ?? [];
  }

  Future<bool> setHiddenForeignStocks(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kHiddenForeignStocks, value);
  }

  Future<bool> getCountriesAlphabeticalFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCountriesAlphabeticalFilter) ?? true;
  }

  Future<bool> setCountriesAlphabeticalFilter(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kCountriesAlphabeticalFilter, value);
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

  Future<String> getHospitalNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kHospitalNotificationType) ?? '0';
  }

  Future<bool> setHospitalNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kHospitalNotificationType, value);
  }

  Future<int> getHospitalNotificationAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kHospitalNotificationAhead) ?? 40;
  }

  Future<bool> setHospitalNotificationAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kHospitalNotificationAhead, value);
  }

  Future<int> getHospitalAlarmAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kHospitalAlarmAhead) ?? 1;
  }

  Future<bool> setHospitalAlarmAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kHospitalAlarmAhead, value);
  }

  Future<int> getHospitalTimerAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kHospitalTimerAhead) ?? 40;
  }

  Future<bool> setHospitalTimerAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kHospitalTimerAhead, value);
  }

  Future<String> getJailNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kJailNotificationType) ?? '0';
  }

  Future<bool> setJailNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kJailNotificationType, value);
  }

  Future<int> getJailNotificationAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kJailNotificationAhead) ?? 40;
  }

  Future<bool> setJailNotificationAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kJailNotificationAhead, value);
  }

  Future<int> getJailAlarmAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kJailAlarmAhead) ?? 1;
  }

  Future<bool> setJailAlarmAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kJailAlarmAhead, value);
  }

  Future<int> getJailTimerAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kJailTimerAhead) ?? 40;
  }

  Future<bool> setJailTimerAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kJailTimerAhead, value);
  }

  // Ranked War notification
  Future<String> getRankedWarNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRankedWarNotificationType) ?? '0';
  }

  Future<bool> setRankedWarNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kRankedWarNotificationType, value);
  }

  Future<int> getRankedWarNotificationAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRankedWarNotificationAhead) ?? 60;
  }

  Future<bool> setRankedWarNotificationAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kRankedWarNotificationAhead, value);
  }

  Future<int> getRankedWarAlarmAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRankedWarAlarmAhead) ?? 1;
  }

  Future<bool> setRankedWarAlarmAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kRankedWarAlarmAhead, value);
  }

  Future<int> getRankedWarTimerAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRankedWarTimerAhead) ?? 60;
  }

  Future<bool> setRankedWarTimerAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kRankedWarTimerAhead, value);
  }

  //

  // Ranked War notification
  Future<String> getRaceStartNotificationType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRaceStartNotificationType) ?? '0';
  }

  Future<bool> setRaceStartNotificationType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kRaceStartNotificationType, value);
  }

  Future<int> getRaceStartNotificationAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRaceStartNotificationAhead) ?? 60;
  }

  Future<bool> setRaceStartNotificationAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kRaceStartNotificationAhead, value);
  }

  Future<int> getRaceStartAlarmAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRaceStartAlarmAhead) ?? 1;
  }

  Future<bool> setRaceStartAlarmAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kRaceStartAlarmAhead, value);
  }

  Future<int> getRaceStartTimerAhead() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRaceStartTimerAhead) ?? 60;
  }

  Future<bool> setRaceStartTimerAhead(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kRaceStartTimerAhead, value);
  }

  //

  Future<bool> getManualAlarmVibration() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kManualAlarmVibration) ?? true;
  }

  Future<bool> setManualAlarmVibration(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kManualAlarmVibration, value);
  }

  Future<bool> getManualAlarmSound() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kManualAlarmSound) ?? true;
  }

  Future<bool> setManualAlarmSound(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kManualAlarmSound, value);
  }

  Future<bool> getShowHeaderWallet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowHeaderWallet) ?? true;
  }

  Future<bool> setShowHeaderWallet(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowHeaderWallet, value);
  }

  Future<bool> getShowHeaderIcons() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowHeaderIcons) ?? true;
  }

  Future<bool> setShowHeaderIcons(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowHeaderIcons, value);
  }

  Future<List<String>> getIconsFiltered() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kIconsFiltered) ?? <String>[];
  }

  Future<bool> setIconsFiltered(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kIconsFiltered, value);
  }

  Future<bool> getDedicatedTravelCard() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDedicatedTravelCard) ?? true;
  }

  Future<bool> setDedicatedTravelCard(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kDedicatedTravelCard, value);
  }

  Future<bool> getDisableTravelSection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDisableTravelSection) ?? false;
  }

  Future<bool> setDisableTravelSection(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kDisableTravelSection, value);
  }

  Future<bool> getWarnAboutChains() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWarnAboutChains) ?? true;
  }

  Future<bool> setWarnAboutChains(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kWarnAboutChains, value);
  }

  Future<bool> getWarnAboutExcessEnergy() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWarnAboutExcessEnergy) ?? true;
  }

  Future<bool> setWarnAboutExcessEnergy(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kWarnAboutExcessEnergy, value);
  }

  Future<int> getWarnAboutExcessEnergyThreshold() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWarnAboutExcessEnergyThreshold) ?? 200;
  }

  Future<bool> setWarnAboutExcessEnergyThreshold(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kWarnAboutExcessEnergyThreshold, value);
  }

  // -- Travel Agency Warnings

  Future<bool> getTravelEnergyExcessWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelEnergyExcessWarning) ?? true;
  }

  Future<bool> setTravelEnergyExcessWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelEnergyExcessWarning, value);
  }

  Future<RangeValues> getTravelEnergyRangeWarningRange() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int min = prefs.getInt(_kTravelEnergyRangeWarningThresholdMin) ?? 10;
    final int max = prefs.getInt(_kTravelEnergyRangeWarningThresholdMax) ?? 100;
    return RangeValues(min.toDouble(), max == 110 ? 110 : max.toDouble());
  }

  Future<bool> setTravelEnergyRangeWarningRange(int min, int max) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool minSet = await prefs.setInt(_kTravelEnergyRangeWarningThresholdMin, min);
    final bool maxSet = await prefs.setInt(_kTravelEnergyRangeWarningThresholdMax, max >= 110 ? 110 : max);
    return minSet && maxSet;
  }

  Future<bool> getTravelNerveExcessWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelNerveExcessWarning) ?? true;
  }

  Future<bool> setTravelNerveExcessWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelNerveExcessWarning, value);
  }

  Future<int> getTravelNerveExcessWarningThreshold() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTravelNerveExcessWarningThreshold) ?? 50;
  }

  Future<bool> setTravelNerveExcessWarningThreshold(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTravelNerveExcessWarningThreshold, value);
  }

  Future<bool> getTravelLifeExcessWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelLifeExcessWarning) ?? true;
  }

  Future<bool> setTravelLifeExcessWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelLifeExcessWarning, value);
  }

  Future<int> getTravelLifeExcessWarningThreshold() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTravelLifeExcessWarningThreshold) ?? 50;
  }

  Future<bool> setTravelLifeExcessWarningThreshold(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTravelLifeExcessWarningThreshold, value);
  }

  Future<bool> getTravelDrugCooldownWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelDrugCooldownWarning) ?? true;
  }

  Future<bool> setTravelDrugCooldownWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelDrugCooldownWarning, value);
  }

  Future<bool> getTravelBoosterCooldownWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelBoosterCooldownWarning) ?? true;
  }

  Future<bool> setTravelBoosterCooldownWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelBoosterCooldownWarning, value);
  }

  Future<bool> getTravelWalletMoneyWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTravelWalletMoneyWarning) ?? true;
  }

  Future<bool> setTravelWalletMoneyWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTravelWalletMoneyWarning, value);
  }

  Future<int> getTravelWalletMoneyWarningThreshold() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTravelWalletMoneyWarningThreshold) ?? 50000;
  }

  Future<bool> setTravelWalletMoneyWarningThreshold(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTravelWalletMoneyWarningThreshold, value);
  }

  // -- Terminal

  Future<bool> getTerminalEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTerminalEnabled) ?? false;
  }

  Future<bool> setTerminalEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTerminalEnabled, value);
  }

  // -- Events

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

  Future<int> getEventsLastRetrieved() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kEventsLastRetrieved) ?? 0;
  }

  Future<bool> setEventsLastRetrieved(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kEventsLastRetrieved, value);
  }

  Future<List<String>> getEventsSave() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kEventsSave) ?? [];
  }

  Future<bool> setEventsSave(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kEventsSave, value);
  }

  // --

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
  /// Methods job addiction in Profile
  /// ----------------------------
  Future<int> getJobAddictionValue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kJobAddictionValue) ?? 0;
  }

  Future<bool> setJobAdditionValue(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kJobAddictionValue, value);
  }

  //--

  Future<int> getJobAddictionNextCallTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kJobAddictionNextCallTime) ?? 0;
  }

  Future<bool> setJobAddictionNextCallTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kJobAddictionNextCallTime, value);
  }

  /// ----------------------------
  /// Methods for reviving
  /// ----------------------------

  Future<bool> getUseNukeRevive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseNukeRevive) ?? true;
  }

  Future<bool> setUseNukeRevive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseNukeRevive, value);
  }

  Future<bool> getUseUhcRevive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseUhcRevive) ?? false;
  }

  Future<bool> setUseUhcRevive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseUhcRevive, value);
  }

  Future<bool> getUseHelaRevive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseHelaRevive) ?? false;
  }

  Future<bool> setUseHelaRevive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseHelaRevive, value);
  }

  Future<bool> getUseWtfRevive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseWtfRevive) ?? false;
  }

  Future<bool> setUseWtfRevive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseWtfRevive, value);
  }

  Future<bool> getUseMidnightXRevive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseMidnightXRevive) ?? false;
  }

  Future<bool> setUseMidnightXevive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseMidnightXRevive, value);
  }

  /// ---------------------------------------
  /// Methods for stats sharing configuration
  /// ---------------------------------------
  Future<bool> getStatsShareIncludeHiddenTargets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStatsShareIncludeHiddenTargets) ?? true;
  }

  Future<bool> setStatsShareIncludeHiddenTargets(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kStatsShareIncludeHiddenTargets, value);
  }

  //

  Future<bool> getStatsShareShowOnlyTotals() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStatsShareShowOnlyTotals) ?? false;
  }

  Future<bool> setStatsShareShowOnlyTotals(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kStatsShareShowOnlyTotals, value);
  }

  //

  Future<bool> getStatsShareShowEstimatesIfNoSpyAvailable() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStatsShareShowEstimatesIfNoSpyAvailable) ?? true;
  }

  Future<bool> setStatsShareShowEstimatesIfNoSpyAvailable(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kStatsShareShowEstimatesIfNoSpyAvailable, value);
  }

  //

  Future<bool> getStatsShareIncludeTargetsWithNoStatsAvailable() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStatsShareIncludeTargetsWithNoStatsAvailable) ?? false;
  }

  Future<bool> setStatsShareIncludeTargetsWithNoStatsAvailable(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kStatsShareIncludeTargetsWithNoStatsAvailable, value);
  }

  /// ----------------------------
  /// Methods for shortcuts
  /// ----------------------------
  Future<bool> getShortcutsEnabledProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnableShortcuts) ?? true;
  }

  Future<bool> setShortcutsEnabledProfile(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kEnableShortcuts, value);
  }

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

  Future<List<String>> getQuickItemsListFaction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kQuickItemsListFaction) ?? <String>[];
  }

  Future<bool> setQuickItemsListFaction(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kQuickItemsListFaction, value);
  }

  Future<int> getNumberOfLoadouts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kQuickItemsLoadoutsNumber) ?? 3;
  }

  Future<bool> setNumberOfLoadouts(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kQuickItemsLoadoutsNumber, value);
  }

  /// ----------------------------
  /// Methods for loot
  /// ----------------------------
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

  Future<List<String>> getLootFiltered() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kLootFiltered) ?? <String>[];
  }

  Future<bool> setLootFiltered(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kLootFiltered, value);
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

  Future<bool> getAWHEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAWHEnabled) ?? true;
  }

  Future<bool> setAWHEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAWHEnabled, value);
  }

  Future<bool> getTornExchangeEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTornExchangeEnabled) ?? true;
  }

  Future<bool> setTornExchangeEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTornExchangeEnabled, value);
  }

  Future<bool> getTornExchangeProfitEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTornExchangeProfitEnabled) ?? false;
  }

  Future<bool> setTornExchangeProfitEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTornExchangeProfitEnabled, value);
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

  Future<List<String?>> getHiddenAwardCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHiddenAwardCategories) ?? <String>[];
  }

  Future<bool> setHiddenAwardCategories(List<String?> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kHiddenAwardCategories, value as List<String>);
  }

  /// ----------------------------
  /// Methods for Items
  /// ----------------------------
  Future<String> getItemsSort() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kItemsSort) ?? '';
  }

  Future<bool> setItemsSort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kItemsSort, value);
  }

  Future<int> getOnlyOwnedItemsFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kOnlyOwnedItemsFilter) ?? 0;
  }

  Future<bool> setOnlyOwnedItemsFilter(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kOnlyOwnedItemsFilter, value);
  }

  Future<List<String>> getHiddenItemsCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHiddenItemsCategories) ?? <String>[];
  }

  Future<bool> setHiddenItemsCategories(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kHiddenItemsCategories, value);
  }

  Future<List<String>> getPinnedItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kPinnedItems) ?? <String>[];
  }

  Future<bool> setPinnedItems(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kPinnedItems, value);
  }

  /// ----------------------------
  /// Methods for Stakeouts
  /// ----------------------------
  Future<bool> getStakeoutsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStakeoutsEnabled) ?? true;
  }

  Future<bool> setStakeoutsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kStakeoutsEnabled, value);
  }

  Future<List<String>> getStakeouts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStakeouts) ?? [];
  }

  Future<bool> setStakeouts(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kStakeouts, value);
  }

  Future<int> getStakeoutsSleepTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStakeoutsSleepTime) ?? 0;
  }

  Future<bool> setStakeoutsSleepTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kStakeoutsSleepTime, value);
  }

  Future<int> getStakeoutsFetchDelayLimit() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStakeoutsFetchDelayLimit) ?? 60;
  }

  Future<bool> setStakeoutsFetchDelayLimit(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kStakeoutsFetchDelayLimit, value);
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

  Future<List<String>> getHighlightWordList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHighlightChatWordsList) ?? const [];
  }

  Future<bool> setHighlightWordList(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kHighlightChatWordsList, value);
  }

  Future<int> getHighlightColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kHighlightColor) ?? 0x701397248;
  }

  Future<bool> setHighlightColor(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kHighlightColor, value);
  }

  /// -------------------
  /// ALTERNATIVE KEYS
  /// -------------------

  // YATA
  Future<bool> getAlternativeYataKeyEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAlternativeYataKeyEnabled) ?? false;
  }

  Future<bool> setAlternativeYataKeyEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAlternativeYataKeyEnabled, value);
  }

  Future<String> getAlternativeYataKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAlternativeYataKey) ?? "";
  }

  Future<bool> setAlternativeYataKey(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAlternativeYataKey, value);
  }

  // TORN STATS
  Future<bool> getAlternativeTornStatsKeyEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAlternativeTornStatsKeyEnabled) ?? false;
  }

  Future<bool> setAlternativeTornStatsKeyEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAlternativeTornStatsKeyEnabled, value);
  }

  Future<String> getAlternativeTornStatsKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAlternativeTornStatsKey) ?? "";
  }

  Future<bool> setAlternativeTornStatsKey(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAlternativeTornStatsKey, value);
  }

  // TORN SPIES CENTRAL
  Future<bool> getAlternativeTSCKeyEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAlternativeTSCKeyEnabled) ?? false;
  }

  Future<bool> setAlternativeTSCKeyEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAlternativeTSCKeyEnabled, value);
  }

  Future<String> getAlternativeTSCKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAlternativeTSCKey) ?? "";
  }

  Future<bool> setAlternativeTSCKey(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAlternativeTSCKey, value);
  }

  /// ---------------------
  /// TORNSTATS STATS CHART
  /// ---------------------

  Future<String> getTornStatsChartSave() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTornStatsChartSave) ?? "";
  }

  Future<bool> setTornStatsChartSave(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTornStatsChartSave, value);
  }

  Future<int> getTornStatsChartDateTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTornStatsChartDateTime) ?? 0;
  }

  Future<bool> setTornStatsChartDateTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTornStatsChartDateTime, value);
  }

  Future<bool> getTornStatsChartEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTornStatsChartEnabled) ?? true;
  }

  Future<bool> setTornStatsChartEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTornStatsChartEnabled, value);
  }

  Future<String> getTornStatsChartType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTornStatsChartType) ?? "line";
  }

  Future<bool> setTornStatsChartType(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTornStatsChartType, value);
  }

  Future<bool> getTornStatsChartInCollapsedMiscCard() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTornStatsChartInCollapsedMiscCard) ?? true;
  }

  Future<bool> setTornStatsChartInCollapsedMiscCard(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTornStatsChartInCollapsedMiscCard, value);
  }

  /// -------------------
  /// TORN ATTACK CENTRAL
  /// -------------------
  Future<bool> getTACEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTACEnabled) ?? false;
  }

  Future<bool> setTACEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTACEnabled, value);
  }

  Future<String> getTACFilters() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTACFilters) ?? "";
  }

  Future<bool> setTACFilters(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTACFilters, value);
  }

  Future<String> getTACTargets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTACTargets) ?? "";
  }

  Future<bool> setTACTargets(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTACTargets, value);
  }

  /// -----------------------------
  /// METHODS FOR LISTS IN SETTINGS
  /// -----------------------------
  Future<bool> getUserScriptsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUserScriptsEnabled) ?? true;
  }

  Future<bool> setUserScriptsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUserScriptsEnabled, value);
  }

  Future<bool> getUserScriptsNotifyUpdates() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUserScriptsNotifyUpdates) ?? true;
  }

  Future<bool> setUserScriptsNotifyUpdates(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUserScriptsNotifyUpdates, value);
  }

  Future<String?> getUserScriptsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserScriptsList);
  }

  Future<bool> setUserScriptsList(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kUserScriptsList, value);
  }

  Future<bool> getUserScriptsFirstTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUserScriptsV2FirstTime) ?? true;
  }

  Future<bool> setUserScriptsFirstTime(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUserScriptsV2FirstTime, value);
  }

  Future<bool> getUserScriptsFeatInjectionTimeShown() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUserScriptsFeatInjectionTimeShown) ?? false;
  }

  Future<bool> setUserScriptsFeatInjectionTimeShown(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUserScriptsFeatInjectionTimeShown, value);
  }

  Future<List<String>> getUserScriptsForcedVersions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kUserScriptsForcedVersions) ?? [];
  }

  Future<bool> setUserScriptsForcedVersions(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kUserScriptsForcedVersions, value);
  }

  /// --------------------------------
  /// METHODS FOR ORGANIZED CRIMES v2
  /// --------------------------------

  Future<bool> getPlayerInOCv2() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPlayerAlreadyInOCv2) ?? false;
  }

  Future<bool> setPlayerInOCv2(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kPlayerAlreadyInOCv2, value);
  }

  /// -----------------------------
  /// METHODS FOR ORGANIZED CRIMES
  /// -----------------------------

  Future<bool> getOCrimesEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOCrimesEnabled) ?? true;
  }

  Future<bool> setOCrimesEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kOCrimesEnabled, value);
  }

  Future<int> getOCrimeDisregarded() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kOCrimeDisregarded) ?? 0;
  }

  Future<bool> setOCrimeDisregarded(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kOCrimeDisregarded, value);
  }

  Future<int> getOCrimeLastKnown() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kOCrimeLastKnown) ?? 0;
  }

  Future<bool> setOCrimeLastKnown(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kOCrimeLastKnown, value);
  }

  /// -----------------------------
  /// METHODS FOR VAULT SHARE
  /// -----------------------------
  Future<bool> getVaultEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kVaultShareEnabled) ?? true;
  }

  Future<bool> setVaultEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kVaultShareEnabled, value);
  }

  Future<String> getVaultShareCurrent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kVaultShareCurrent) ?? "";
  }

  Future<bool> setVaultShareCurrent(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kVaultShareCurrent, value);
  }

  /// -----------------------------
  /// METHODS FOR JAIL
  /// -----------------------------
  Future<String> getJailModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kJailModel) ?? "";
  }

  Future<bool> setJailModel(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kJailModel, value);
  }

  /// -----------------------------
  /// METHODS FOR BOUNTIES
  /// -----------------------------
  Future<String> getBountiesModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBountiesModel) ?? "";
  }

  Future<bool> setBountiesModel(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kBountiesModel, value);
  }

  /// -----------------------------
  /// METHODS FOR EXTRA ACCESS TO RANKED WAR
  /// -----------------------------
  Future<bool> getRankedWarsInMenu() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRankedWarsInMenu) ?? false;
  }

  Future<bool> setRankedWarsInMenu(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRankedWarsInMenu, value);
  }

  Future<bool> getRankedWarsInProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRankedWarsInProfile) ?? true;
  }

  Future<bool> setRankedWarsInProfile(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRankedWarsInProfile, value);
  }

  Future<bool> getRankedWarsInProfileShowTotalHours() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRankedWarsInProfileShowTotalHours) ?? false;
  }

  Future<bool> setRankedWarsInProfileShowTotalHours(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRankedWarsInProfileShowTotalHours, value);
  }

  /// -----------------------
  /// METHODS FOR RETALIATION
  /// -----------------------
  Future<bool> getRetaliationSectionEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRetaliationSectionEnabled) ?? true;
  }

  Future<bool> setRetaliationSectionEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRetaliationSectionEnabled, value);
  }

  Future<bool> getSingleRetaliationOpensBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSingleRetaliationOpensBrowser) ?? false;
  }

  Future<bool> setSingleRetaliationOpensBrowser(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kSingleRetaliationOpensBrowser, value);
  }

  /// -----------------------------
  /// METHODS FOR DATA STOCK MARKET
  /// -----------------------------
  Future<String> getDataStockMarket() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDataStockMarket) ?? "";
  }

  Future<bool> setDataStockMarket(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDataStockMarket, value);
  }

  Future<bool> getStockExchangeInMenu() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStockExchangeInMenu) ?? false;
  }

  Future<bool> setStockExchangeInMenu(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kStockExchangeInMenu, value);
  }

  /// -----------------------------
  /// METHODS FOR WEB VIEW TABS
  /// -----------------------------
  Future<int> getWebViewLastActiveTab() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWebViewLastActiveTab) ?? 0;
  }

  Future<bool> setWebViewLastActiveTab(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kWebViewLastActiveTab, value);
  }

  Future<String> getWebViewSessionCookie() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kWebViewSessionCookie) ?? '';
  }

  Future<bool> setWebViewSessionCookie(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kWebViewSessionCookie, value);
  }

  Future<String> getWebViewMainTab() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kWebViewMainTab) ?? '{"tabsSave": []}';
  }

  Future<bool> setWebViewMainTab(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kWebViewMainTab, value);
  }

  Future<String> getWebViewSecondaryTabs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kWebViewSecondaryTabs) ?? '{"tabsSave": []}';
  }

  Future<bool> setWebViewSecondaryTabs(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kWebViewSecondaryTabs, value);
  }

  Future<bool> getUseTabsFullBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseTabsInFullBrowser) ?? true;
  }

  Future<bool> setUseTabsFullBrowser(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseTabsInFullBrowser, value);
  }

  Future<bool> getUseTabsBrowserDialog() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseTabsInBrowserDialog) ?? true;
  }

  Future<bool> setUseTabsBrowserDialog(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseTabsInBrowserDialog, value);
  }

  // -- Remove unused tabs

  Future<bool> getRemoveUnusedTabs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemoveUnusedTabs) ?? true;
  }

  Future<bool> setRemoveUnusedTabs(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRemoveUnusedTabs, value);
  }

  Future<bool> getRemoveUnusedTabsIncludesLocked() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemoveUnusedTabsIncludesLocked) ?? false;
  }

  Future<bool> setRemoveUnusedTabsIncludesLocked(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kRemoveUnusedTabsIncludesLocked, value);
  }

  Future<int> getRemoveUnusedTabsRangeDays() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRemoveUnusedTabsRangeDays) ?? 7;
  }

  Future<bool> setRemoveUnusedTabsRangeDays(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kRemoveUnusedTabsRangeDays, value);
  }

  // ---------------------

  Future<bool> getOnlyLoadTabsWhenUsed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnlyLoadTabsWhenUsed) ?? true;
  }

  Future<bool> setOnlyLoadTabsWhenUsed(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kOnlyLoadTabsWhenUsed, value);
  }

  Future<bool> getAutomaticChangeToNewTabFromURL() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutomaticChangeToNewTabFromURL) ?? true;
  }

  Future<bool> setAutomaticChangeToNewTabFromURL(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAutomaticChangeToNewTabFromURL, value);
  }

  Future<bool> getUseTabsHideFeature() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseTabsHideFeature) ?? true;
  }

  Future<bool> setUseTabsHideFeature(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseTabsHideFeature, value);
  }

  Future<bool> setTabsHideBarColor(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTabsHideBarColor, value);
  }

  Future<int> getTabsHideBarColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTabsHideBarColor) ?? 0xFF4CAF40;
  }

  Future<bool> getShowTabLockWarnings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTabLockWarnings) ?? true;
  }

  Future<bool> setShowTabLockWarnings(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowTabLockWarnings, value);
  }

  Future<bool> getFullLockNavigationAttemptOpensNewTab() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullLockNavigationAttemptOpensNewTab) ?? false;
  }

  Future<bool> setFullLockNavigationAttemptOpensNewTab(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullLockNavigationAttemptOpensNewTab, value);
  }

  // -- LockedTabsNavigationExceptions
  final List<List<String>> _defaultFullLockedTabsNavigationExceptions = [
    ["https://www.torn.com/item.php", "https://www.torn.com/loader.php?sid=itemsMods"],
    ["https://www.torn.com/item.php", "https://www.torn.com/page.php?sid=ammo"],
  ];

  Future<String> getLockedTabsNavigationExceptions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFullLockedTabsNavigationExceptions) ??
        json.encode(_defaultFullLockedTabsNavigationExceptions);
  }

  Future<bool> setLockedTabsNavigationExceptions(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kFullLockedTabsNavigationExceptions, value);
  }

  // --

  Future<bool> getUseTabsIcons() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseTabsIcons) ?? true;
  }

  Future<bool> setUseTabsIcons(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kUseTabsIcons, value);
  }

  Future<bool> getHideTabs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHideTabs) ?? false;
  }

  Future<bool> setHideTabs(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kHideTabs, value);
  }

  Future<bool> getReminderAboutHideTabFeature() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kReminderAboutHideTabFeature) ?? false;
  }

  Future<bool> setReminderAboutHideTabFeature(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kReminderAboutHideTabFeature, value);
  }

  // -- Quick menu tab

  Future<bool> getFullScreenExplanationShown() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenExplanationShown) ?? false;
  }

  Future<bool> setFullScreenExplanationShown(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenExplanationShown, value);
  }

  Future<bool> getFullScreenRemovesWidgets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenRemovesWidgets) ?? true;
  }

  Future<bool> setFullScreenRemovesWidgets(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenRemovesWidgets, value);
  }

  Future<bool> getFullScreenRemovesChat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenRemovesChat) ?? true;
  }

  Future<bool> setFullScreenRemovesChat(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenRemovesChat, value);
  }

  Future<bool> getFullScreenExtraCloseButton() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenExtraCloseButton) ?? false;
  }

  Future<bool> setFullScreenExtraCloseButton(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenExtraCloseButton, value);
  }

  Future<bool> getFullScreenExtraReloadButton() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenExtraReloadButton) ?? false;
  }

  Future<bool> setFullScreenExtraReloadButton(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenExtraReloadButton, value);
  }

  Future<bool> getFullScreenOverNotch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenOverNotch) ?? true;
  }

  Future<bool> setFullScreenOverNotch(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenOverNotch, value);
  }

  Future<bool> getFullScreenOverBottom() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenOverBottom) ?? true;
  }

  Future<bool> setFullScreenOverBottom(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenOverBottom, value);
  }

  Future<bool> getFullScreenOverSides() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenOverSides) ?? true;
  }

  Future<bool> setFullScreenOverSides(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenOverSides, value);
  }

  //--

  Future<bool> getFullScreenByShortTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenByShortTap) ?? false;
  }

  Future<bool> setFullScreenByShortTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenByShortTap, value);
  }

  //--
  Future<bool> getFullScreenByLongTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenByLongTap) ?? true;
  }

  Future<bool> setFullScreenByLongTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenByLongTap, value);
  }

  //--

  Future<bool> getFullScreenByNotificationTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenByNotificationTap) ?? false;
  }

  Future<bool> setFullScreenByNotificationTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenByNotificationTap, value);
  }

  //--

  Future<bool> getFullScreenByShortChainingTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenByShortChainingTap) ?? false;
  }

  Future<bool> setFullScreenByShortChainingTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenByShortChainingTap, value);
  }

  Future<bool> getFullScreenByLongChainingTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenByLongChainingTap) ?? false;
  }

  Future<bool> setFullScreenByLongChainingTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenByLongChainingTap, value);
  }

  //--

  Future<bool> getFullScreenByDeepLinkTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenByDeepLinkTap) ?? false;
  }

  Future<bool> setFullScreenByDeepLinkTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenByDeepLinkTap, value);
  }

  //--

  Future<bool> getFullScreenByQuickItemTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenByQuickItemTap) ?? false;
  }

  Future<bool> setFullScreenByQuickItemTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenByQuickItemTap, value);
  }

  //--
  Future<bool> getFullScreenIncludesPDAButtonTap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFullScreenIncludesPDAButtonTap) ?? false;
  }

  Future<bool> setFullScreenIncludesPDAButtonTap(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kFullScreenIncludesPDAButtonTap, value);
  }

  /// --------------------------------
  /// Methods for notification actions
  /// --------------------------------

  Future<String> getLifeNotificationTapAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLifeNotificationTapAction) ?? 'itemsOwn';
  }

  Future<bool> setLifeNotificationTapAction(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kLifeNotificationTapAction, value);
  }

  //

  Future<String> getDrugsNotificationTapAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDrugsNotificationTapAction) ?? 'itemsOwn';
  }

  Future<bool> setDrugsNotificationTapAction(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kDrugsNotificationTapAction, value);
  }

  //

  Future<String> getMedicalNotificationTapAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMedicalNotificationTapAction) ?? 'itemsOwn';
  }

  Future<bool> setMedicalNotificationTapAction(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kMedicalNotificationTapAction, value);
  }

  //

  Future<String> getBoosterNotificationTapAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBoosterNotificationTapAction) ?? 'itemsOwn';
  }

  Future<bool> setBoosterNotificationTapAction(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kBoosterNotificationTapAction, value);
  }

  /// ----------------------------
  /// Methods for show cases
  /// ----------------------------
  /// tabs_general -> for tab use information in webview_stackview
  Future<List<String>> getShowCases() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kShowCases) ?? <String>[];
  }

  Future<bool> setShowCases(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kShowCases, value);
  }

  /// ----------------------------
  /// Methods for stats analytics
  /// ----------------------------
  Future<int> getStatsFirstLoginTimestamp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStatsFirstLoginTimestamp) ?? 0;
  }

  Future<bool> setStatsFirstLoginTimestamp(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kStatsFirstLoginTimestamp, value);
  }

  Future<int> getStatsCumulatedAppUseSeconds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStatsCumulatedAppUseSeconds) ?? 0;
  }

  Future<bool> setStatsCumulatedAppUseSeconds(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kStatsCumulatedAppUseSeconds, value);
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kStatsEventsAchieved) ?? [];
  }

  Future<bool> setStatsCumulatedEventsAchieved(List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_kStatsEventsAchieved, value);
  }

  /// ----------------------------
  /// Methods for appwidget
  /// ----------------------------
  Future<bool> getAppwidgetDarkMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppwidgetDarkMode) ?? false;
  }

  Future<bool> setAppwidgetDarkMode(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAppwidgetDarkMode, value);
  }

  // ---

  Future<bool> getAppwidgetRemoveShortcutsOneRowLayout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppwidgetRemoveShortcutsOneRowLayout) ?? false;
  }

  Future<bool> setAppwidgetRemoveShortcutsOneRowLayout(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAppwidgetRemoveShortcutsOneRowLayout, value);
  }

  // ---

  Future<bool> getAppwidgetMoneyEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppwidgetMoneyEnabled) ?? true;
  }

  Future<bool> setAppwidgetMoneyEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAppwidgetMoneyEnabled, value);
  }

  // ---

  Future<bool> getAppwidgetCooldownTapOpensBrowser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppwidgetCooldownTapOpensBrowser) ?? false;
  }

  Future<bool> setAppwidgetCooldownTapOpensBrowser(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAppwidgetCooldownTapOpensBrowser, value);
  }

  Future<String> getAppwidgetCooldownTapOpensBrowserDestination() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAppwidgetCooldownTapOpensBrowserDestination) ?? "own";
  }

  Future<bool> setAppwidgetCooldownTapOpensBrowserDestination(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kAppwidgetCooldownTapOpensBrowserDestination, value);
  }

  // ---

  Future<bool> getAppwidgetExplanationShown() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppwidgetExplanationShown) ?? false;
  }

  Future<bool> setAppwidgetExplanationShown(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kAppwidgetExplanationShown, value);
  }

  /// ----------------------------
  /// Methods for permissions
  /// ----------------------------

  Future<int> getExactPermissionDialogShownAndroid() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kExactPermissionDialogShownAndroid) ?? 0;
  }

  Future<bool> setExactPermissionDialogShownAndroid(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kExactPermissionDialogShownAndroid, value);
  }

  /// ----------------------------
  /// Webview downloads
  /// ----------------------------

  Future<bool> getDownloadActionShare() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_downloadActionShare) ?? true;
  }

  Future<bool> setDownloadActionShare(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_downloadActionShare, value);
  }

  /// ----------------------------
  /// Methods for Api Rate
  /// ----------------------------
  Future<bool> getShowApiRateInDrawer() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowApiRateInDrawer) ?? false;
  }

  Future<bool> setShowApiRateInDrawer(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowApiRateInDrawer, value);
  }

  Future<bool> getDelayApiCalls() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDelayApiCalls) ?? false;
  }

  Future<bool> setDelayApiCalls(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kDelayApiCalls, value);
  }

  // ---

  Future<bool> getShowApiMaxCallWarning() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowApiMaxCallWarning) ?? false;
  }

  Future<bool> setShowApiMaxCallWarning(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kShowApiMaxCallWarning, value);
  }

  /// ----------------------------
  /// Methods for Split Screen
  /// ----------------------------
  Future<String> getSplitScreenWebview() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSplitScreenWebview) ?? 'off';
  }

  Future<bool> setSplitScreenWebview(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kSplitScreenWebview, value);
  }

  Future<bool> getSplitScreenRevertsToApp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSplitScreenRevertsToApp) ?? true;
  }

  Future<bool> setSplitScreenRevertsToApp(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kSplitScreenRevertsToApp, value);
  }

  /// ----------------------------
  /// FCM Token
  /// ----------------------------
  Future<String> getFCMToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFCMToken) ?? "";
  }

  Future<bool> setFCMToken(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kFCMToken, value);
  }

  /// ----------------------------
  /// Methods for Sendbird notifications
  /// ----------------------------
  Future<bool> getSendbirdNotificationsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSendbirdnotificationsEnabled) ?? false;
  }

  Future<bool> setSendbirdNotificationsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kSendbirdnotificationsEnabled, value);
  }

  Future<String> getSendbirdSessionToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSendbirdSessionToken) ?? "";
  }

  Future<bool> setSendbirdSessionToken(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kSendbirdSessionToken, value);
  }

  Future<int> getSendbirdTokenTimestamp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSendbirdTokenTimestamp) ?? 0;
  }

  Future<bool> setSendbirdTokenTimestamp(int timestamp) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kSendbirdTokenTimestamp, timestamp);
  }

  //

  Future<bool> getBringBrowserForwardOnStart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBringBrowserForwardOnStart) ?? false;
  }

  Future<bool> setBringBrowserForwardOnStart(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kBringBrowserForwardOnStart, value);
  }

  /// -----------------------------------
  /// Methods for task periodic execution
  /// -----------------------------------

  /// Stores the last execution time for a given task name
  Future<bool> setLastExecutionTime(String taskName, int timestamp) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt("$_taskPrefix$taskName", timestamp);
  }

  /// Retrieves the last execution time for a given task name
  Future<int> getLastExecutionTime(String taskName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("$_taskPrefix$taskName") ?? 0;
  }

  /// Removes the stored execution time for a task
  Future<bool> removeLastExecutionTime(String taskName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove("$_taskPrefix$taskName");
  }

  /// -----------------------------------
  /// Methods for Torn Calendar
  /// -----------------------------------

  Future<String> getTornCalendarModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTornCalendarModel) ?? "";
  }

  Future<bool> setTornCalendarModel(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kTornCalendarModel, value);
  }

  Future<int> getTornCalendarLastUpdate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTornCalendarLastUpdate) ?? 0;
  }

  Future<bool> setTornCalendarLastUpdate(int timestamp) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_kTornCalendarLastUpdate, timestamp);
  }

  Future<bool> getTctClockHighlightsEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTctClockHighlightsEvents) ?? true;
  }

  Future<bool> setTctClockHighlightsEvents(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kTctClockHighlightsEvents, value);
  }
}
