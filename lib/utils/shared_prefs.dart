// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

// Package imports:
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/war_settings.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/widgets/webviews/webview_fab.dart';

class Prefs {
  static final Prefs _instance = Prefs._internal();
  factory Prefs() => _instance;
  Prefs._internal();

  // Migration control
  static bool _migrationInProgress = false;
  static bool _migrationCompleted = false;
  static const String _kSembastMigrationCompleted = "pda_sembast_migration_completed_v1";

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
  final String _kWarSettings = "pda_warSettings";
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
  final String _kProfileCheckAttackEnabled = "pda_profileCheckAttackEnabled";
  final String _kDefaultSection = "pda_defaultSection";

  // Foreign Stocks
  final String _kForeignStockSellingFee = "pda_foreignStockSellingFee";
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
  final String _kPreventBasketKeyboard = "pda_preventBasketKeyboard";
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
  final String _kShowShortcutEditIcon = "pda_showShortcutEditIcon";
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
  final String _kJoblessWarningEnabled = "pda_joblessWarningEnabled";
  final String _kPlayerNotesMigrationCompleted = "pda_playerNotesMigrationCompleted";

  // OC v2
  final String _kPlayerAlreadyInOCv2 = "pda_PlayerAlreadyInOCv2";

  // OC v1
  final String _kOCrimesEnabled = "pda_OCrimesEnabled";
  final String _kOCrimeDisregarded = "pda_OCrimeDisregarded";
  final String _kOCrimeLastKnown = "pda_OCrimeLastKnown";

  // Rented Properties (Misc Card)
  final String _kShowAllRentedOutProperties = "pda_showAllRentedOutProperties";

  // Loot
  final String _kLootTimerType = "pda_lootTimerType";
  final String _kLootNotificationType = "pda_lootNotificationType";
  final String _kLootNotificationAhead = "pda_lootNotificationAhead";
  final String _kLootAlarmAhead = "pda_lootAlarmAhead";
  final String _kLootTimerAhead = "pda_lootTimerAhead";
  final String _kLootFiltered = "pda_lootFiltered";

  // Android Alarm options
  final String _kManualAlarmVibration = "pda_manualAlarmVibration";
  final String _kManualAlarmSound = "pda_manualAlarmSound";

  // Cache for iOS AlarmKit alarm metadata populated by AlarmKitServiceIos
  final String _kIosAlarmMetadata = "pda_iosAlarmMetadata";

  // Browser scripts and widgets
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
  final String _kUserScriptsGlobalDisableState = "pda_userScriptsGlobalDisableState";

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
  final String _kUseWolverinesRevive = "pda_useWolverinesRevive";

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

  // Backup automation
  final String _kAutoBackupReminderEnabled = "pda_autoBackupReminderEnabled";
  final String _kAutoBackupBeforeUpdateEnabled = "pda_autoBackupBeforeUpdateEnabled";
  final String _kAutoBackupLastReminderShown = "pda_autoBackupLastReminderShown";
  final String _kAutoBackupLastLocalCreated = "pda_autoBackupLastLocalCreated";

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
  final String _kTornStatsChartRange = "pda_tornStatsChartRange";
  final String _kTornStatsChartInCollapsedMiscCard = "pda_tornStatsChartInCollapsedMiscCard";
  final String _kTornStatsChartShowBoth = "pda_tornStatsChartShowBoth";

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
  final String _kSendbirdExcludeEliminationMessages = "pda_sendbirdExcludeEliminationMessages";

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

  /// =====================================
  /// MIGRATION SharedPreferences > Sembast
  /// =====================================
  Future<void> migratePrefsToSembast() async {
    if (_migrationCompleted) return;

    if (_migrationInProgress) {
      while (_migrationInProgress) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    try {
      _migrationInProgress = true;

      final alreadyMigrated = await PrefsDatabase.getBool(_kSembastMigrationCompleted, false);
      if (alreadyMigrated) {
        _migrationCompleted = true;
        log(name: 'Prefs Migration', 'Migration already completed, skipping');
        return;
      }

      log(name: 'Prefs Migration', 'Starting migration from SharedPreferences to Sembast...');

      await _migrateFromSharedPrefs();

      await PrefsDatabase.setBool(_kSembastMigrationCompleted, true);
      _migrationCompleted = true;
      log(name: 'Prefs Migration', 'Migration completed successfully');
    } catch (e, stackTrace) {
      log(
        name: 'Prefs Migration',
        'CRITICAL ERROR during migration: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _migrationInProgress = false;
    }
  }

  /// Migrates all data from SharedPreferences to Sembast
  Future<void> _migrateFromSharedPrefs() async {
    try {
      // Check if migration already completed
      final migrationCompleted = await PrefsDatabase.getBool(_kSembastMigrationCompleted, false);
      if (migrationCompleted) {
        log(name: 'Prefs Migration', 'Migration already completed previously - skipping');
        return;
      }

      final prefs = SharedPreferencesAsync();
      final keys = await prefs.getKeys();

      log(name: 'Prefs Migration', 'Found ${keys.length} keys in SharedPreferences to migrate');

      // Skip migration for new users (no data in SharedPreferences to migrate)
      if (keys.isEmpty) {
        log(name: 'Prefs Migration', 'No keys found in SharedPreferences - skipping migration (new installation)');
        return;
      }

      int successCount = 0;
      int errorCount = 0;

      // Order matters: List MUST be checked before String
      final migrationStrategies = [
        (prefs, key) => prefs.getStringList(key),
        (prefs, key) => prefs.getString(key),
        (prefs, key) => prefs.getDouble(key),
        (prefs, key) => prefs.getInt(key),
        (prefs, key) => prefs.getBool(key),
      ];

      // Setters
      final migrationSetters = [
        (key, value) => PrefsDatabase.setStringList(key, value as List<String>),
        (key, value) => PrefsDatabase.setString(key, value as String),
        (key, value) => PrefsDatabase.setDouble(key, value as double),
        (key, value) => PrefsDatabase.setInt(key, value as int),
        (key, value) => PrefsDatabase.setBool(key, value as bool),
      ];

      for (final key in keys) {
        try {
          // Skip the migration flag itself
          if (key == _kSembastMigrationCompleted) continue;

          bool migrated = false;

          for (int i = 0; i < migrationStrategies.length; i++) {
            try {
              final value = await migrationStrategies[i](prefs, key);
              if (value != null) {
                await migrationSetters[i](key, value);
                migrated = true;
                successCount++;
                break;
              }
            } catch (_) {}
          }

          if (!migrated) {
            log(name: 'Prefs Migration', 'Warning: Could not migrate key "$key" (unknown type or null)');
            errorCount++;
          }
        } catch (e) {
          log(name: 'Prefs Migration', 'Error migrating key "$key": $e');
          errorCount++;
        }
      }

      log(name: 'Prefs Migration', 'Migration complete: $successCount succeeded, $errorCount errors');

      if (errorCount > 0) {
        log(name: 'Prefs Migration', 'WARNING: $errorCount keys could not be migrated');
      }

      await PrefsDatabase.setBool(_kSembastMigrationCompleted, true);
      log(name: 'Prefs Migration', 'Migration flag saved to Sembast');

      // Clear SharedPreferences after successful migration to free up space
      if (errorCount == 0 && successCount > 0) {
        await prefs.clear();
        log(name: 'Prefs Migration', 'SharedPreferences cleared after successful migration');
      }
    } catch (e, stackTrace) {
      log(
        name: 'Prefs Migration',
        'FATAL ERROR during migration process: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// ----------------------------
  /// Methods for app version
  /// ----------------------------

  Future<String> getAppCompilation() async {
    return await PrefsDatabase.getString(_kAppVersion, "");
  }

  Future setAppCompilation(String value) async {
    return await PrefsDatabase.setString(_kAppVersion, value);
  }

  /// -------------------------------
  /// Methods for announcement dialog
  /// -------------------------------

  Future<int> getAppStatsAnnouncementDialogVersion() async {
    return await PrefsDatabase.getInt(_kAppAnnouncementDialogVersion, 0);
  }

  Future setAppStatsAnnouncementDialogVersion(int value) async {
    await PrefsDatabase.setInt(_kAppAnnouncementDialogVersion, value);
  }

  Future<int> getBugsAnnouncementDialogVersion() async {
    return await PrefsDatabase.getInt(_kBugsAnnouncementDialogVersion, 0);
  }

  Future setBugsAnnouncementDialogVersion(int value) async {
    await PrefsDatabase.setInt(_kBugsAnnouncementDialogVersion, value);
  }

  Future<int> getPdaUpdateDialogVersion() async {
    return await PrefsDatabase.getInt(_kPdaUpdateDialogVersion, 0);
  }

  Future setPdaUpdateDialogVersion(int value) async {
    await PrefsDatabase.setInt(_kPdaUpdateDialogVersion, value);
  }

  /// ----------------------------
  /// Methods for identification
  /// ----------------------------
  Future<String> getOwnDetails() async {
    return await PrefsDatabase.getString(_kOwnDetails, "");
  }

  Future setOwnDetails(String value) async {
    return await PrefsDatabase.setString(_kOwnDetails, value);
  }

  /// ----------------------------
  /// Methods for identification
  /// ----------------------------
  Future<int> getLastAppUse() async {
    return await PrefsDatabase.getInt(_kLastAppUse, 0);
  }

  Future setLastAppUse(int value) async {
    return await PrefsDatabase.setInt(_kLastAppUse, value);
  }

  /// ----------------------------
  /// Methods for connectivity check in Drawer (RC)
  /// ----------------------------
  Future<bool> getPdaConnectivityCheckRC() async {
    return await PrefsDatabase.getBool(_kPdaConnectivityCheckRC, false);
  }

  Future setPdaConnectivityCheck(bool value) async {
    return await PrefsDatabase.setBool(_kPdaConnectivityCheckRC, value);
  }

  /// ----------------------------
  /// Methods for faction and company tracking
  /// ----------------------------
  Future<int> getLastKnownFaction() async {
    return await PrefsDatabase.getInt(_kLastKnownFaction, 0);
  }

  Future setLastKnownFaction(int value) async {
    return await PrefsDatabase.setInt(_kLastKnownFaction, value);
  }

  Future<int> getLastKnownCompany() async {
    return await PrefsDatabase.getInt(_kLastKnownCompany, 0);
  }

  Future setLastKnownCompany(int value) async {
    return await PrefsDatabase.setInt(_kLastKnownCompany, value);
  }

  /// ----------------------------
  /// Methods for native login
  /// ----------------------------
  Future<String> getNativePlayerEmail() async {
    return await PrefsDatabase.getString(_kNativePlayerEmail, '');
  }

  Future setNativePlayerEmail(String value) async {
    return await PrefsDatabase.setString(_kNativePlayerEmail, value);
  }

  Future<int> getLastAuthRedirect() async {
    return await PrefsDatabase.getInt(_kLastAuthRedirect, 0);
  }

  Future setLastAuthRedirect(int value) async {
    return await PrefsDatabase.setInt(_kLastAuthRedirect, value);
  }

  Future<bool> getTryAutomaticLogins() async {
    return await PrefsDatabase.getBool(_kTryAutomaticLogins, true);
  }

  Future setTryAutomaticLogins(bool value) async {
    return await PrefsDatabase.setBool(_kTryAutomaticLogins, value);
  }

  Future<String> getPlayerLastLoginMethod() async {
    return await PrefsDatabase.getString(_kPlayerLastLoginMethod, '');
  }

  Future setPlayerLastLoginMethod(String value) async {
    return await PrefsDatabase.setString(_kPlayerLastLoginMethod, value);
  }

  /// ----------------------------
  /// Methods for profile section order
  /// ----------------------------
  Future<List<String>> getProfileSectionOrder() async {
    return await PrefsDatabase.getStringList(_kProfileSectionOrder, <String>[]);
  }

  Future setProfileSectionOrder(List<String> value) async {
    return await PrefsDatabase.setStringList(_kProfileSectionOrder, value);
  }

  /// ------------------------------
  /// Methods for colored status card
  /// --------------------------------
  Future<bool> getColorCodedStatusCard() async {
    return await PrefsDatabase.getBool(_kColorCodedStatusCard, true);
  }

  Future setColorCodedStatusCard(bool value) async {
    return await PrefsDatabase.setBool(_kColorCodedStatusCard, value);
  }

  /// ----------------------------
  /// Methods for targets
  /// ----------------------------
  Future<List<String>> getTargetsList() async {
    return await PrefsDatabase.getStringList(_kTargetsList, <String>[]);
  }

  Future setTargetsList(List<String> value) async {
    return await PrefsDatabase.setStringList(_kTargetsList, value);
  }

  //**************
  Future<String> getTargetsSort() async {
    return await PrefsDatabase.getString(_kTargetsSort, '');
  }

  Future setTargetsSort(String value) async {
    return await PrefsDatabase.setString(_kTargetsSort, value);
  }

  //**************
  Future<List<String>> getTargetsColorFilter() async {
    return await PrefsDatabase.getStringList(_kTargetsColorFilter, []);
  }

  Future setTargetsColorFilter(List<String> value) async {
    return await PrefsDatabase.setStringList(_kTargetsColorFilter, value);
  }

  //**************
  Future<List<String>> getWarFactions() async {
    return await PrefsDatabase.getStringList(_kWarFactions, <String>[]);
  }

  Future setWarFactions(List<String> value) async {
    return await PrefsDatabase.setStringList(_kWarFactions, value);
  }

  Future<List<String>> getFilterListInWars() async {
    return await PrefsDatabase.getStringList(_kFilterListInWars, []);
  }

  Future setFilterListInWars(List<String> value) async {
    return await PrefsDatabase.setStringList(_kFilterListInWars, value);
  }

  Future<int> getOnlineFilterInWars() async {
    return await PrefsDatabase.getInt(_kOnlineFilterInWars, 0);
  }

  Future setOnlineFilterInWars(int value) async {
    return await PrefsDatabase.setInt(_kOnlineFilterInWars, value);
  }

  Future<int> getOkayRedFilterInWars() async {
    return await PrefsDatabase.getInt(_kOkayRedFilterInWars, 0);
  }

  Future setOkayRedFilterInWars(int value) async {
    return await PrefsDatabase.setInt(_kOkayRedFilterInWars, value);
  }

  Future<bool> getCountryFilterInWars() async {
    return await PrefsDatabase.getBool(_kCountryFilterInWars, false);
  }

  Future setCountryFilterInWars(bool value) async {
    return await PrefsDatabase.setBool(_kCountryFilterInWars, value);
  }

  Future<int> getTravelingFilterInWars() async {
    return await PrefsDatabase.getInt(_kTravelingFilterInWars, 0);
  }

  Future setTravelingFilterInWars(int value) async {
    return await PrefsDatabase.setInt(_kTravelingFilterInWars, value);
  }

  Future<bool> getShowChainWidgetInWars() async {
    return await PrefsDatabase.getBool(_kShowChainWidgetInWars, true);
  }

  Future setShowChainWidgetInWars(bool value) async {
    return await PrefsDatabase.setBool(_kShowChainWidgetInWars, value);
  }

  Future<String> getWarMembersSort() async {
    return await PrefsDatabase.getString(_kWarMembersSort, '');
  }

  Future setWarMembersSort(String value) async {
    return await PrefsDatabase.setString(_kWarMembersSort, value);
  }

  Future<WarSettings> getWarSettings() async {
    String jsonString = await PrefsDatabase.getString(_kWarSettings, '');
    if (jsonString.isEmpty) {
      return WarSettings();
    }
    try {
      return WarSettings.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return WarSettings();
    }
  }

  Future setWarSettings(WarSettings value) async {
    return await PrefsDatabase.setString(_kWarSettings, jsonEncode(value.toJson()));
  }

  Future<String> getRankerWarSortPerTab() async {
    return await PrefsDatabase.getString(_kRankedWarSortPerTab, 'active#progressDes-upcoming#timeAsc-finished#timeAsc');
  }

  Future setRankerWarSortPerTab(String value) async {
    return await PrefsDatabase.setString(_kRankedWarSortPerTab, value);
  }

  Future<List<String>> getYataSpies() async {
    return await PrefsDatabase.getStringList(_kYataSpies, []);
  }

  Future setYataSpies(List<String> value) async {
    return await PrefsDatabase.setStringList(_kYataSpies, value);
  }

  Future<int> getYataSpiesTime() async {
    return await PrefsDatabase.getInt(_kYataSpiesTime, 0);
  }

  Future setYataSpiesTime(int value) async {
    return await PrefsDatabase.setInt(_kYataSpiesTime, value);
  }

  Future<String> getTornStatsSpies() async {
    return await PrefsDatabase.getString(_kTornStatsSpies, "");
  }

  Future setTornStatsSpies(String value) async {
    return await PrefsDatabase.setString(_kTornStatsSpies, value);
  }

  Future<int> getTornStatsSpiesTime() async {
    return await PrefsDatabase.getInt(_kTornStatsSpiesTime, 0);
  }

  Future setTornStatsSpiesTime(int value) async {
    return await PrefsDatabase.setInt(_kTornStatsSpiesTime, value);
  }

  Future<int> getWarIntegrityCheckTime() async {
    return await PrefsDatabase.getInt(_kWarIntegrityCheckTime, 0);
  }

  Future setWarIntegrityCheckTime(int value) async {
    return await PrefsDatabase.setInt(_kWarIntegrityCheckTime, value);
  }

  //**************
  Future<int> getChainingCurrentPage() async {
    return await PrefsDatabase.getInt(_kChainingCurrentPage, 0);
  }

  Future setChainingCurrentPage(int value) async {
    return await PrefsDatabase.setInt(_kChainingCurrentPage, value);
  }

  Future<bool> getTargetSkippingAll() async {
    return await PrefsDatabase.getBool(_kTargetSkipping, true);
  }

  Future setTargetSkipping(bool value) async {
    return await PrefsDatabase.setBool(_kTargetSkipping, value);
  }

  Future<bool> getTargetSkippingFirst() async {
    return await PrefsDatabase.getBool(_kTargetSkippingFirst, false);
  }

  Future setTargetSkippingFirst(bool value) async {
    return await PrefsDatabase.setBool(_kTargetSkippingFirst, value);
  }

  Future<bool> getShowTargetsNotes() async {
    return await PrefsDatabase.getBool(_kShowTargetsNotes, true);
  }

  Future setShowTargetsNotes(bool value) async {
    return await PrefsDatabase.setBool(_kShowTargetsNotes, value);
  }

  Future<bool> getShowBlankTargetsNotes() async {
    return await PrefsDatabase.getBool(_kShowBlankTargetsNotes, false);
  }

  Future setShowBlankTargetsNotes(bool value) async {
    return await PrefsDatabase.setBool(_kShowBlankTargetsNotes, value);
  }

  Future<bool> getShowOnlineFactionWarning() async {
    return await PrefsDatabase.getBool(_kShowOnlineFactionWarning, true);
  }

  Future setShowOnlineFactionWarning(bool value) async {
    return await PrefsDatabase.setBool(_kShowOnlineFactionWarning, value);
  }

  Future<String> getChainWatcherSettings() async {
    return await PrefsDatabase.getString(_kChainWatcherSettings, '');
  }

  Future setChainWatcherSettings(String value) async {
    return await PrefsDatabase.setString(_kChainWatcherSettings, value);
  }

  Future<List<String>> getChainWatcherPanicTargets() async {
    return await PrefsDatabase.getStringList(_kChainWatcherPanicTargets, <String>[]);
  }

  Future setChainWatcherPanicTargets(List<String> value) async {
    return await PrefsDatabase.setStringList(_kChainWatcherPanicTargets, value);
  }

  Future<bool> getChainWatcherSound() async {
    return await PrefsDatabase.getBool(_kChainWatcherSound, true);
  }

  Future setChainWatcherSound(bool value) async {
    return await PrefsDatabase.setBool(_kChainWatcherSound, value);
  }

  Future<bool> getChainWatcherVibration() async {
    return await PrefsDatabase.getBool(_kChainWatcherVibration, true);
  }

  Future setChainWatcherVibration(bool value) async {
    return await PrefsDatabase.setBool(_kChainWatcherVibration, value);
  }

  Future<bool> getChainWatcherNotificationsEnabled() async {
    return await PrefsDatabase.getBool(_kChainWatcherNotifications, true);
  }

  Future setChainWatcherNotificationsEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kChainWatcherNotifications, value);
  }

  Future<bool> getYataTargetsEnabled() async {
    return await PrefsDatabase.getBool(_kYataTargetsEnabled, true);
  }

  Future setYataTargetsEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kYataTargetsEnabled, value);
  }

  Future<bool> getStatusColorWidgetEnabled() async {
    return await PrefsDatabase.getBool(_kStatusColorWidgetEnabled, true);
  }

  Future setStatusColorWidgetEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kStatusColorWidgetEnabled, value);
  }

  /// ----------------------------
  /// Methods for attacks
  /// ----------------------------
  Future<String> getAttackSort() async {
    return await PrefsDatabase.getString(_kAttacksSort, '');
  }

  Future setAttackSort(String value) async {
    return await PrefsDatabase.setString(_kAttacksSort, value);
  }

  /// ----------------------------
  /// Methods for friends
  /// ----------------------------
  Future<List<String>> getFriendsList() async {
    return await PrefsDatabase.getStringList(_kFriendsList, <String>[]);
  }

  Future setFriendsList(List<String> value) async {
    return await PrefsDatabase.setStringList(_kFriendsList, value);
  }

  //**************
  Future<String> getFriendsSort() async {
    return await PrefsDatabase.getString(_kFriendsSort, '');
  }

  Future setFriendsSort(String value) async {
    return await PrefsDatabase.setString(_kFriendsSort, value);
  }

  /// ----------------------------
  /// Methods for theme
  /// ----------------------------
  Future<String> getAppTheme() async {
    return await PrefsDatabase.getString(_kTheme, 'light');
  }

  Future setAppTheme(String value) async {
    return await PrefsDatabase.setString(_kTheme, value);
  }

  Future<bool> getUseMaterial3() async {
    return await PrefsDatabase.getBool(_kUseMaterial3Theme, false);
  }

  Future setUseMaterial3(bool value) async {
    return await PrefsDatabase.setBool(_kUseMaterial3Theme, value);
  }

  Future<bool> getAccesibilityNoTextColors() async {
    return await PrefsDatabase.getBool(_kAccesibilityNoTextColors, false);
  }

  Future setAccesibilityNoTextColors(bool value) async {
    return await PrefsDatabase.setBool(_kAccesibilityNoTextColors, value);
  }

  /// ----------------------------
  /// Methods for theme sync with web and device
  /// ----------------------------
  Future<bool> getSyncTornWebTheme() async {
    return await PrefsDatabase.getBool(_kSyncTornWebTheme, true);
  }

  Future setSyncTornWebTheme(bool value) async {
    return await PrefsDatabase.setBool(_kSyncTornWebTheme, value);
  }

  Future<bool> getSyncDeviceTheme() async {
    return await PrefsDatabase.getBool(_kSyncDeviceTheme, false);
  }

  Future setSyncDeviceTheme(bool value) async {
    return await PrefsDatabase.setBool(_kSyncDeviceTheme, value);
  }

  Future<String> getDarkThemeToSync() async {
    return await PrefsDatabase.getString(_kDarkThemeToSync, 'dark');
  }

  Future setDarkThemeToSync(String value) async {
    return await PrefsDatabase.setString(_kDarkThemeToSync, value);
  }

  /// ----------------------------
  /// Methods for dynamic app icons
  /// ----------------------------
  Future<bool> getDynamicAppIcons() async {
    return await PrefsDatabase.getBool(_kDynamicAppIcons, true);
  }

  Future setDynamicAppIcons(bool value) async {
    return await PrefsDatabase.setBool(_kDynamicAppIcons, value);
  }

  //--

  Future<String> getDynamicAppIconsManual() async {
    return await PrefsDatabase.getString(_kDynamicAppIconsManual, "off");
  }

  Future setDynamicAppIconsManual(String value) async {
    return await PrefsDatabase.setString(_kDynamicAppIconsManual, value);
  }

  /// ----------------------------
  /// Methods for vibration pattern
  /// ----------------------------
  Future<String> getVibrationPattern() async {
    return await PrefsDatabase.getString(_kVibrationPattern, 'medium');
  }

  Future setVibrationPattern(String value) async {
    return await PrefsDatabase.setString(_kVibrationPattern, value);
  }

  /// ----------------------------
  /// Methods for discreet notifications
  /// ----------------------------
  Future<bool> getDiscreetNotifications() async {
    return await PrefsDatabase.getBool(_kDiscreetNotifications, false);
  }

  Future setDiscreetNotifications(bool value) async {
    return await PrefsDatabase.setBool(_kDiscreetNotifications, value);
  }

  /// ----------------------------
  /// Methods for default launch section
  /// ----------------------------
  Future<String> getDefaultSection() async {
    return await PrefsDatabase.getString(_kDefaultSection, '0');
  }

  Future setDefaultSection(String value) async {
    return await PrefsDatabase.setString(_kDefaultSection, value);
  }

  /// ----------------------------
  /// Methods for on app exit
  /// ----------------------------
  Future<String> getOnBackButtonAppExit() async {
    return await PrefsDatabase.getString(_kOnBackButtonAppExit, 'stay');
  }

  Future setOnAppExit(String value) async {
    return await PrefsDatabase.setString(_kOnBackButtonAppExit, value);
  }

  /// ----------------------------
  /// Methods for debug messages
  /// ----------------------------
  Future<bool> getDebugMessages() async {
    return await PrefsDatabase.getBool(_kDebugMessages, false);
  }

  Future setDebugMessages(bool value) async {
    return await PrefsDatabase.setBool(_kDebugMessages, value);
  }

  /// ----------------------------
  /// Methods for default browser
  /// ----------------------------
  Future<String> getDefaultBrowser() async {
    return await PrefsDatabase.getString(_kDefaultBrowser, 'app');
  }

  Future setDefaultBrowser(String value) async {
    return await PrefsDatabase.setString(_kDefaultBrowser, value);
  }

  Future<bool> getLoadBarBrowser() async {
    return await PrefsDatabase.getBool(_kLoadBarBrowser, true);
  }

  Future setLoadBarBrowser(bool value) async {
    return await PrefsDatabase.setBool(_kLoadBarBrowser, value);
  }

  Future<String> getBrowserRefreshMethod() async {
    return await PrefsDatabase.getString(_kBrowserRefreshMethod2, "both");
  }

  Future setBrowserRefreshMethod(String value) async {
    return await PrefsDatabase.setString(_kBrowserRefreshMethod2, value);
  }

  Future<String> getBrowserShowNavArrowsAppbar() async {
    return await PrefsDatabase.getString(_kBrowserShowNavArrowsAppbar, "wide");
  }

  Future setBrowserShowNavArrowsAppbar(String value) async {
    return await PrefsDatabase.setString(_kBrowserShowNavArrowsAppbar, value);
  }

  Future<bool> getBrowserBottomBarStyleEnabled() async {
    return await PrefsDatabase.getBool(_kBrowserStyleBottomBarEnabled, false);
  }

  Future setBrowserBottomBarStyleEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kBrowserStyleBottomBarEnabled, value);
  }

  Future<int> getBrowserBottomBarStyleType() async {
    return await PrefsDatabase.getInt(_kBrowserStyleBottomBarType, 1);
  }

  Future setBrowserBottomBarStyleType(int value) async {
    return await PrefsDatabase.setInt(_kBrowserStyleBottomBarType, value);
  }

  Future<bool> getBrowserBottomBarStylePlaceTabsAtBottom() async {
    return await PrefsDatabase.getBool(_kBrowserBottomBarStylePlaceTabsAtBottom, false);
  }

  Future setBrowserBottomBarStylePlaceTabsAtBottom(bool value) async {
    return await PrefsDatabase.setBool(_kBrowserBottomBarStylePlaceTabsAtBottom, value);
  }

  Future<String> getTMenuButtonLongPressBrowser() async {
    return await PrefsDatabase.getString(_kUseQuickBrowser, "quick");
  }

  Future setTMenuButtonLongPressBrowser(String value) async {
    return await PrefsDatabase.setString(_kUseQuickBrowser, value);
  }

  Future<bool> getRestoreSessionCookie() async {
    return await PrefsDatabase.getBool(_kRestoreSessionCookie, false);
  }

  Future setRestoreSessionCookie(bool value) async {
    return await PrefsDatabase.setBool(_kRestoreSessionCookie, value);
  }

  Future<bool> getWebviewCacheEnabled() async {
    return await PrefsDatabase.getBool(_kWebviewCacheEnabled, true);
  }

  Future setWebviewCacheEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kWebviewCacheEnabled, value);
  }

  /*
  Future<bool> getClearBrowserCacheNextOpportunity() async {
    
    return await PrefsDatabase.getBool(_kClearBrowserCacheNextOpportunity, false);
  }
  
  Future setClearBrowserCacheNextOpportunity(bool value) async {
    
    return await PrefsDatabase.setBool(_kClearBrowserCacheNextOpportunity, value);
  }
  */

  Future<int> getAndroidBrowserScale() async {
    return await PrefsDatabase.getInt(_kAndroidBrowserScale, 0);
  }

  Future setAndroidBrowserScale(int value) async {
    return await PrefsDatabase.setInt(_kAndroidBrowserScale, value);
  }

  Future<int> getAndroidBrowserTextScale() async {
    return await PrefsDatabase.getInt(_kAndroidBrowserTextScale, 8);
  }

  Future setAndroidBrowserTextScale(int value) async {
    return await PrefsDatabase.setInt(_kAndroidBrowserTextScale, value);
  }

  // Settings - Browser FAB

  Future<bool> getWebviewFabEnabled() async {
    return await PrefsDatabase.getBool(_kWebviewFabEnabled, false);
  }

  Future setWebviewFabEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kWebviewFabEnabled, value);
  }

  // --

  Future<bool> getWebviewFabShownNow() async {
    return await PrefsDatabase.getBool(_kWebviewFabShownNow, true);
  }

  Future setWebviewFabShownNow(bool value) async {
    return await PrefsDatabase.setBool(_kWebviewFabShownNow, value);
  }

  // --

  Future<String> getWebviewFabDirection() async {
    return await PrefsDatabase.getString(_kWebviewFabDirection, "center");
  }

  Future setWebviewFabDirection(String value) async {
    return await PrefsDatabase.setString(_kWebviewFabDirection, value);
  }

  // --

  Future setWebviewFabPositionXY(List<int> value) async {
    // Convert list to JSON string for storage
    return await PrefsDatabase.setString(_kWebviewFabPositionXY, jsonEncode(value));
  }

  // Retrieve FAB position and decode JSON string to List<int>
  Future<List<int>> getWebviewFabPositionXY() async {
    final jsonString = await PrefsDatabase.getString(_kWebviewFabPositionXY, '');
    if (jsonString.isNotEmpty) {
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
    return await PrefsDatabase.getBool(_kWebviewFabOnlyFullScreen, false);
  }

  Future setWebviewFabOnlyFullScreen(bool value) async {
    return await PrefsDatabase.setBool(_kWebviewFabOnlyFullScreen, value);
  }

  // --

  Future setFabButtonCount(int value) async {
    return await PrefsDatabase.setInt(_kFabButtonCount, value);
  }

  Future<int> getFabButtonCount() async {
    return await PrefsDatabase.getInt(_kFabButtonCount, 4); // Default to 4 buttons
  }

// --

  Future setFabButtonActions(List<WebviewFabAction> actions) async {
    final actionIndices = actions.map((action) => action.index).toList();
    return await PrefsDatabase.setStringList(
      _kFabButtonActions,
      actionIndices.map((e) => e.toString()).toList(),
    );
  }

  Future<List<WebviewFabAction>> getFabButtonActions() async {
    final actionStrings = await PrefsDatabase.getStringList(_kFabButtonActions, []);

    if (actionStrings.isNotEmpty) {
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
    return await PrefsDatabase.setInt(_kFabDoubleTapAction, action.index);
  }

  Future<WebviewFabAction> getFabDoubleTapAction() async {
    final actionIndex = await PrefsDatabase.getInt(_kFabDoubleTapAction, -1);
    return actionIndex >= 0
        ? FabActionExtension.fromIndex(actionIndex)
        : WebviewFabAction.openTabsMenu; // Default to Open Tabs Menu
  }

// --

  Future setFabTripleTapAction(WebviewFabAction action) async {
    return await PrefsDatabase.setInt(_kFabTripleTapAction, action.index);
  }

  Future<WebviewFabAction> getFabTripleTapAction() async {
    final actionIndex = await PrefsDatabase.getInt(_kFabTripleTapAction, -1);
    return actionIndex >= 0
        ? FabActionExtension.fromIndex(actionIndex)
        : WebviewFabAction.closeCurrentTab; // Default to Close Current Tab
  }

  // FAB ENDS ###

  Future<bool> getBrowserDoNotPauseWebviews() async {
    return await PrefsDatabase.getBool(_kBrowserDoNotPauseWebviews, false);
  }

  Future setBrowserDoNotPauseWebviews(bool value) async {
    return await PrefsDatabase.setBool(_kBrowserDoNotPauseWebviews, value);
  }

  // Settings - Browser Gestures

  Future<bool> getIosBrowserPinch() async {
    return await PrefsDatabase.getBool(_kIosBrowserPinch, false);
  }

  Future setIosBrowserPinch(bool value) async {
    return await PrefsDatabase.setBool(_kIosBrowserPinch, value);
  }

  Future<bool> getIosDisallowOverscroll() async {
    return await PrefsDatabase.getBool(_kIosDisallowOverscroll, false);
  }

  Future setIosDisallowOverscroll(bool value) async {
    return await PrefsDatabase.setBool(_kIosDisallowOverscroll, value);
  }

  Future<bool> getBrowserReverseNavigationSwipe() async {
    return await PrefsDatabase.getBool(_kBrowserReverseNavigationSwipe, false);
  }

  Future setBrowserReverseNavigationSwipe(bool value) async {
    return await PrefsDatabase.setBool(_kBrowserReverseNavigationSwipe, value);
  }

  Future<bool> getBrowserCenterEditingTextField() async {
    return await PrefsDatabase.getBool(_kBrowserCenterEditingTextField, true);
  }

  Future setBrowserCenterEditingTextField(bool value) async {
    return await PrefsDatabase.setBool(_kBrowserCenterEditingTextField, value);
  }

  /// ----------------------------
  /// Methods for test browser
  /// ----------------------------
  Future<bool> getTestBrowserActive() async {
    return await PrefsDatabase.getBool(_kTestBrowserActive, false);
  }

  Future setTestBrowserActive(bool value) async {
    return await PrefsDatabase.setBool(_kTestBrowserActive, value);
  }

  /// ----------------------------
  /// Methods for notifications on launch
  /// ----------------------------
  Future<bool> getRemoveNotificationsOnLaunch() async {
    return await PrefsDatabase.getBool(_kRemoveNotificationsOnLaunch, true);
  }

  Future setRemoveNotificationsOnLaunch(bool value) async {
    return await PrefsDatabase.setBool(_kRemoveNotificationsOnLaunch, value);
  }

  /// ----------------------------
  /// Methods for clock
  /// ----------------------------
  Future<String> getDefaultTimeFormat() async {
    return await PrefsDatabase.getString(_kDefaultTimeFormat, '24');
  }

  Future setDefaultTimeFormat(String value) async {
    return await PrefsDatabase.setString(_kDefaultTimeFormat, value);
  }

  Future<String> getDefaultTimeZone() async {
    return await PrefsDatabase.getString(_kDefaultTimeZone, 'local');
  }

  Future setDefaultTimeZone(String value) async {
    return await PrefsDatabase.setString(_kDefaultTimeZone, value);
  }

  Future<String> getShowDateInClock() async {
    return await PrefsDatabase.getString(_kShowDateInClockString, "dayfirst");
  }

  Future setShowDateInClock(String value) async {
    return await PrefsDatabase.setString(_kShowDateInClockString, value);
  }

  Future<bool> getShowSecondsInClock() async {
    return await PrefsDatabase.getBool(_kShowSecondsInClock, true);
  }

  Future setShowSecondsInClock(bool value) async {
    return await PrefsDatabase.setBool(_kShowSecondsInClock, value);
  }

  /// ----------------------------
  /// Methods for spies source
  /// ----------------------------
  Future<String> getSpiesSource() async {
    return await PrefsDatabase.getString(_kSpiesSource, 'yata');
  }

  Future setSpiesSource(String value) async {
    return await PrefsDatabase.setString(_kSpiesSource, value);
  }

  Future<bool> getAllowMixedSpiesSources() async {
    return await PrefsDatabase.getBool(_kAllowMixedSpiesSources, true);
  }

  Future setAllowMixedSpiesSources(bool value) async {
    return await PrefsDatabase.setBool(_kAllowMixedSpiesSources, value);
  }

  /// ----------------------------
  /// Methods for OC Crimes NNB Source
  /// ----------------------------
  Future<String> getNaturalNerveBarSource() async {
    return await PrefsDatabase.getString(_kNaturalNerveBarSource, 'yata');
  }

  Future setNaturalNerveBarSource(String value) async {
    return await PrefsDatabase.setString(_kNaturalNerveBarSource, value);
  }

  Future<int> getNaturalNerveYataTime() async {
    return await PrefsDatabase.getInt(_kNaturalNerveYataTime, 0);
  }

  Future setNaturalNerveYataTime(int value) async {
    return await PrefsDatabase.setInt(_kNaturalNerveYataTime, value);
  }

  Future<String> getNaturalNerveYataModel() async {
    return await PrefsDatabase.getString(_kNaturalNerveYataModel, '');
  }

  Future setNaturalNerveYataModel(String value) async {
    return await PrefsDatabase.setString(_kNaturalNerveYataModel, value);
  }

  Future<int> getNaturalNerveTornStatsTime() async {
    return await PrefsDatabase.getInt(_kNaturalNerveTornStatsTime, 0);
  }

  Future setNaturalNerveTornStatsTime(int value) async {
    return await PrefsDatabase.setInt(_kNaturalNerveTornStatsTime, value);
  }

  Future<String> getNaturalNerveTornStatsModel() async {
    return await PrefsDatabase.getString(_kNaturalNerveTornStatsModel, '');
  }

  Future setNaturalNerveTornStatsModel(String value) async {
    return await PrefsDatabase.setString(_kNaturalNerveTornStatsModel, value);
  }

  /// ----------------------------
  /// Methods for appBar position
  /// ----------------------------
  Future<String> getAppBarPosition() async {
    return await PrefsDatabase.getString(_kAppBarPosition, 'top');
  }

  Future setAppBarPosition(String value) async {
    return await PrefsDatabase.setString(_kAppBarPosition, value);
  }

  /// ----------------------------
  /// Methods for screen rotation
  /// ----------------------------

  Future<bool> getAllowScreenRotation() async {
    return await PrefsDatabase.getBool(_kAllowScreenRotation, false);
  }

  Future setAllowScreenRotation(bool value) async {
    return await PrefsDatabase.setBool(_kAllowScreenRotation, value);
  }

  /// ----------------------------
  /// Methods for iOS Link Preview
  /// ----------------------------

  Future<bool> getIosAllowLinkPreview() async {
    return await PrefsDatabase.getBool(_kIosAllowLinkPreview, true);
  }

  Future setIosAllowLinkPreview(bool value) async {
    return await PrefsDatabase.setBool(_kIosAllowLinkPreview, value);
  }

  /// ----------------------------
  /// Methods for excess tabs dialog persistence
  /// ----------------------------

  Future<bool> getExcessTabsAlerted() async {
    return await PrefsDatabase.getBool(_kExcessTabsAlerted, false);
  }

  Future setExcessTabsAlerted(bool value) async {
    return await PrefsDatabase.setBool(_kExcessTabsAlerted, value);
  }

  /// ----------------------------
  /// Methods for excess first tab lock
  /// ----------------------------

  Future<bool> getFirstTabLockAlerted() async {
    return await PrefsDatabase.getBool(_kFirstTabLockAlerted, false);
  }

  Future setFirstTabLockAlerted(bool value) async {
    return await PrefsDatabase.setBool(_kFirstTabLockAlerted, value);
  }

  /// ----------------------------
  /// Methods for travel options
  /// ----------------------------
  Future<String> getTravelNotificationTitle() async {
    return await PrefsDatabase.getString(_kTravelNotificationTitle, 'TORN TRAVEL');
  }

  Future setTravelNotificationTitle(String value) async {
    return await PrefsDatabase.setString(_kTravelNotificationTitle, value);
  }

  Future<String> getTravelNotificationBody() async {
    return await PrefsDatabase.getString(_kTravelNotificationBody, 'Arriving at your destination!');
  }

  Future setTravelNotificationBody(String value) async {
    return await PrefsDatabase.setString(_kTravelNotificationBody, value);
  }

  Future<String> getTravelNotificationAhead() async {
    return await PrefsDatabase.getString(_kTravelNotificationAhead, '0');
  }

  Future setTravelNotificationAhead(String value) async {
    return await PrefsDatabase.setString(_kTravelNotificationAhead, value);
  }

  Future<String> getTravelAlarmAhead() async {
    return await PrefsDatabase.getString(_kTravelAlarmAhead, '0');
  }

  Future setTravelAlarmAhead(String value) async {
    return await PrefsDatabase.setString(_kTravelAlarmAhead, value);
  }

  Future<String> getTravelTimerAhead() async {
    return await PrefsDatabase.getString(_kTravelTimerAhead, '0');
  }

  Future setTravelTimerAhead(String value) async {
    return await PrefsDatabase.setString(_kTravelTimerAhead, value);
  }

  Future<bool> getRemoveAirplane() async {
    return await PrefsDatabase.getBool(_kRemoveAirplane, false);
  }

  Future setRemoveAirplane(bool value) async {
    return await PrefsDatabase.setBool(_kRemoveAirplane, value);
  }

  Future<bool> getRemoveForeignItemsDetails() async {
    return await PrefsDatabase.getBool(_kRemoveForeignItemsDetails, false);
  }

  Future setRemoveForeignItemsDetails(bool value) async {
    return await PrefsDatabase.setBool(_kRemoveForeignItemsDetails, value);
  }

  Future<bool> getPreventBasketKeyboard() async {
    return await PrefsDatabase.getBool(_kPreventBasketKeyboard, true);
  }

  Future setPreventBasketKeyboard(bool value) async {
    return await PrefsDatabase.setBool(_kPreventBasketKeyboard, value);
  }

  Future<bool> getRemoveTravelQuickReturnButton() async {
    return await PrefsDatabase.getBool(_kRemoveTravelQuickReturnButton, false);
  }

  Future setRemoveTravelQuickReturnButton(bool value) async {
    return await PrefsDatabase.setBool(_kRemoveTravelQuickReturnButton, value);
  }

  /// ----------------------------
  /// Methods for Profile Bars
  /// ----------------------------
  Future<String> getLifeBarOption() async {
    return await PrefsDatabase.getString(_kLifeBarOption, 'ask');
  }

  Future setLifeBarOption(String value) async {
    return await PrefsDatabase.setString(_kLifeBarOption, value);
  }

  /// ----------------------------
  /// Methods for extra player information
  /// ----------------------------

  Future<bool> getExtraPlayerInformation() async {
    return await PrefsDatabase.getBool(_kExtraPlayerInformation, true);
  }

  Future setExtraPlayerInformation(bool value) async {
    return await PrefsDatabase.setBool(_kExtraPlayerInformation, value);
  }

  // *************
  Future<String> getProfileStatsEnabled() async {
    return await PrefsDatabase.getString(_kProfileStatsEnabled, "0");
  }

  Future setProfileStatsEnabled(String value) async {
    return await PrefsDatabase.setString(_kProfileStatsEnabled, value);
  }

  // *************
  Future<List<String>> getShareAttackOptions() async {
    return await PrefsDatabase.getStringList(_kShareAttackOptions, <String>[]);
  }

  Future setShareAttackOptions(List<String> value) async {
    return await PrefsDatabase.setStringList(_kShareAttackOptions, value);
  }

  // *************
  Future<int> getTSCEnabledStatus() async {
    return await PrefsDatabase.getInt(_kTSCEnabledStatus, -1);
  }

  Future setTSCEnabledStatus(int value) async {
    return await PrefsDatabase.setInt(_kTSCEnabledStatus, value);
  }

  // *************
  Future<int> getYataStatsEnabledStatus() async {
    return await PrefsDatabase.getInt(_kYataStatsEnabledStatus, 1);
  }

  Future setYataStatsEnabledStatus(int value) async {
    return await PrefsDatabase.setInt(_kYataStatsEnabledStatus, value);
  }

  // *************
  Future<String> getFriendlyFactions() async {
    return await PrefsDatabase.getString(_kFriendlyFactions, "");
  }

  Future setFriendlyFactions(String value) async {
    return await PrefsDatabase.setString(_kFriendlyFactions, value);
  }

  // *************
  Future<bool> getNotesWidgetEnabledProfile() async {
    return await PrefsDatabase.getBool(_kNotesWidgetEnabledProfile, true);
  }

  Future setNotesWidgetEnabledProfile(bool value) async {
    return await PrefsDatabase.setBool(_kNotesWidgetEnabledProfile, value);
  }

  Future setNotesWidgetEnabledProfileWhenEmpty(bool value) async {
    return await PrefsDatabase.setBool(_kNotesWidgetEnabledProfileWhenEmpty, value);
  }

  Future<bool> getNotesWidgetEnabledProfileWhenEmpty() async {
    return await PrefsDatabase.getBool(_kNotesWidgetEnabledProfileWhenEmpty, true);
  }

  Future<bool> getJoblessWarningEnabled() async {
    return await PrefsDatabase.getBool(_kJoblessWarningEnabled, true);
  }

  Future<void> setJoblessWarningEnabled(bool value) async {
    await PrefsDatabase.setBool(_kJoblessWarningEnabled, value);
  }

  // *************
  Future<bool> getExtraPlayerNetworth() async {
    return await PrefsDatabase.getBool(_kExtraPlayerNetworth, false);
  }

  Future setExtraPlayerNetworth(bool value) async {
    return await PrefsDatabase.setBool(_kExtraPlayerNetworth, value);
  }

  // *************
  Future<bool> getHitInMiniProfileOpensNewTab() async {
    return await PrefsDatabase.getBool(_kHitInMiniProfileOpensNewTab, false);
  }

  Future setHitInMiniProfileOpensNewTab(bool value) async {
    return await PrefsDatabase.setBool(_kHitInMiniProfileOpensNewTab, value);
  }

  Future<bool> getHitInMiniProfileOpensNewTabAndChangeTab() async {
    return await PrefsDatabase.getBool(_kHitInMiniProfileOpensNewTabAndChangeTab, true);
  }

  Future setHitInMiniProfileOpensNewTabAndChangeTab(bool value) async {
    return await PrefsDatabase.setBool(_kHitInMiniProfileOpensNewTabAndChangeTab, value);
  }

  /// ----------------------------
  /// Methods for foreign stocks
  /// ----------------------------
  Future<List<String>> getStockCountryFilter() async {
    return await PrefsDatabase.getStringList(_kStockCountryFilter, List<String>.filled(12, '1'));
  }

  Future setStockCountryFilter(List<String> value) async {
    return await PrefsDatabase.setStringList(_kStockCountryFilter, value);
  }

  Future<List<String>> getStockTypeFilter() async {
    return await PrefsDatabase.getStringList(_kStockTypeFilter, List<String>.filled(5, '1'));
  }

  Future setStockTypeFilter(List<String> value) async {
    return await PrefsDatabase.setStringList(_kStockTypeFilter, value);
  }

  Future<String> getStockSort() async {
    return await PrefsDatabase.getString(_kStockSort, 'profit');
  }

  Future setStockSort(String value) async {
    return await PrefsDatabase.setString(_kStockSort, value);
  }

  Future<int> getStockCapacity() async {
    return await PrefsDatabase.getInt(_kStockCapacity, 1);
  }

  Future setStockCapacity(int value) async {
    return await PrefsDatabase.setInt(_kStockCapacity, value);
  }

  Future<bool> getShowForeignInventory() async {
    return await PrefsDatabase.getBool(_kShowForeignInventory, true);
  }

  Future setShowForeignInventory(bool value) async {
    return await PrefsDatabase.setBool(_kShowForeignInventory, value);
  }

  Future<bool> getShowArrivalTime() async {
    return await PrefsDatabase.getBool(_kShowArrivalTime, true);
  }

  Future setShowArrivalTime(bool value) async {
    return await PrefsDatabase.setBool(_kShowArrivalTime, value);
  }

  Future<bool> getShowBarsCooldownAnalysis() async {
    return await PrefsDatabase.getBool(_kShowBarsCooldownAnalysis, true);
  }

  Future setShowBarsCooldownAnalysis(bool value) async {
    return await PrefsDatabase.setBool(_kShowBarsCooldownAnalysis, value);
  }

  Future<String> getTravelTicket() async {
    return await PrefsDatabase.getString(_kTravelTicket, "private");
  }

  Future setTravelTicket(String value) async {
    return await PrefsDatabase.setString(_kTravelTicket, value);
  }

  Future<String> getForeignStocksDataProvider() async {
    return await PrefsDatabase.getString(_kForeignStocksDataProvider, "yata");
  }

  Future setForeignStocksDataProvider(String value) async {
    return await PrefsDatabase.setString(_kForeignStocksDataProvider, value);
  }

  Future<bool> getRestocksNotificationEnabled() async {
    return await PrefsDatabase.getBool(_kRestocksEnabled, false);
  }

  Future setRestocksNotificationEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kRestocksEnabled, value);
  }

  Future<String> getActiveRestocks() async {
    return await PrefsDatabase.getString(_kActiveRestocks, "{}");
  }

  Future setActiveRestocks(String value) async {
    return await PrefsDatabase.setString(_kActiveRestocks, value);
  }

  Future<List<String>> getHiddenForeignStocks() async {
    return await PrefsDatabase.getStringList(_kHiddenForeignStocks, []);
  }

  Future setHiddenForeignStocks(List<String> value) async {
    return await PrefsDatabase.setStringList(_kHiddenForeignStocks, value);
  }

  Future<bool> getCountriesAlphabeticalFilter() async {
    return await PrefsDatabase.getBool(_kCountriesAlphabeticalFilter, true);
  }

  Future setCountriesAlphabeticalFilter(bool value) async {
    return await PrefsDatabase.setBool(_kCountriesAlphabeticalFilter, value);
  }

  /// ----------------------------
  /// Methods for manual alarms (Android)
  /// ----------------------------

  /// Whether manual alarms should vibrate (set from Settings > Notifications, used by alarm intents)
  Future<bool> getManualAlarmVibration() async {
    return await PrefsDatabase.getBool(_kManualAlarmVibration, true);
  }

  Future setManualAlarmVibration(bool value) async {
    return await PrefsDatabase.setBool(_kManualAlarmVibration, value);
  }

  /// Whether manual alarms should play sound (set from Settings > Notifications, used by alarm intents)
  Future<bool> getManualAlarmSound() async {
    return await PrefsDatabase.getBool(_kManualAlarmSound, true);
  }

  Future setManualAlarmSound(bool value) async {
    return await PrefsDatabase.setBool(_kManualAlarmSound, value);
  }

  /// ----------------------------
  /// Methods for notification types
  /// ----------------------------
  Future<String> getTravelNotificationType() async {
    return await PrefsDatabase.getString(_kTravelNotificationType, '0');
  }

  Future setTravelNotificationType(String value) async {
    return await PrefsDatabase.setString(_kTravelNotificationType, value);
  }

  Future<String> getEnergyNotificationType() async {
    return await PrefsDatabase.getString(_kEnergyNotificationType, '0');
  }

  Future setEnergyNotificationType(String value) async {
    return await PrefsDatabase.setString(_kEnergyNotificationType, value);
  }

  Future<int> getEnergyNotificationValue() async {
    return await PrefsDatabase.getInt(_kEnergyNotificationValue, 0);
  }

  Future setEnergyNotificationValue(int value) async {
    return await PrefsDatabase.setInt(_kEnergyNotificationValue, value);
  }

  Future setEnergyPercentageOverride(bool value) async {
    return await PrefsDatabase.setBool(_kEnergyCustomOverride, value);
  }

  Future<bool> getEnergyPercentageOverride() async {
    return await PrefsDatabase.getBool(_kEnergyCustomOverride, false);
  }

  Future<String> getNerveNotificationType() async {
    return await PrefsDatabase.getString(_kNerveNotificationType, '0');
  }

  Future setNerveNotificationType(String value) async {
    return await PrefsDatabase.setString(_kNerveNotificationType, value);
  }

  Future<int> getNerveNotificationValue() async {
    return await PrefsDatabase.getInt(_kNerveNotificationValue, 0);
  }

  Future setNerveNotificationValue(int value) async {
    return await PrefsDatabase.setInt(_kNerveNotificationValue, value);
  }

  Future setNervePercentageOverride(bool value) async {
    return await PrefsDatabase.setBool(_kNerveCustomOverride, value);
  }

  Future<bool> getNervePercentageOverride() async {
    return await PrefsDatabase.getBool(_kNerveCustomOverride, false);
  }

  Future<String> getLifeNotificationType() async {
    return await PrefsDatabase.getString(_kLifeNotificationType, '0');
  }

  Future setLifeNotificationType(String value) async {
    return await PrefsDatabase.setString(_kLifeNotificationType, value);
  }

  Future<String> getDrugNotificationType() async {
    return await PrefsDatabase.getString(_kDrugNotificationType, '0');
  }

  Future setDrugNotificationType(String value) async {
    return await PrefsDatabase.setString(_kDrugNotificationType, value);
  }

  Future<String> getMedicalNotificationType() async {
    return await PrefsDatabase.getString(_kMedicalNotificationType, '0');
  }

  Future setMedicalNotificationType(String value) async {
    return await PrefsDatabase.setString(_kMedicalNotificationType, value);
  }

  Future<String> getBoosterNotificationType() async {
    return await PrefsDatabase.getString(_kBoosterNotificationType, '0');
  }

  Future setBoosterNotificationType(String value) async {
    return await PrefsDatabase.setString(_kBoosterNotificationType, value);
  }

  Future<String> getHospitalNotificationType() async {
    return await PrefsDatabase.getString(_kHospitalNotificationType, '0');
  }

  Future setHospitalNotificationType(String value) async {
    return await PrefsDatabase.setString(_kHospitalNotificationType, value);
  }

  Future<int> getHospitalNotificationAhead() async {
    return await PrefsDatabase.getInt(_kHospitalNotificationAhead, 40);
  }

  Future setHospitalNotificationAhead(int value) async {
    return await PrefsDatabase.setInt(_kHospitalNotificationAhead, value);
  }

  Future<int> getHospitalAlarmAhead() async {
    return await PrefsDatabase.getInt(_kHospitalAlarmAhead, 1);
  }

  Future setHospitalAlarmAhead(int value) async {
    return await PrefsDatabase.setInt(_kHospitalAlarmAhead, value);
  }

  Future<int> getHospitalTimerAhead() async {
    return await PrefsDatabase.getInt(_kHospitalTimerAhead, 40);
  }

  Future setHospitalTimerAhead(int value) async {
    return await PrefsDatabase.setInt(_kHospitalTimerAhead, value);
  }

  Future<String> getJailNotificationType() async {
    return await PrefsDatabase.getString(_kJailNotificationType, '0');
  }

  Future setJailNotificationType(String value) async {
    return await PrefsDatabase.setString(_kJailNotificationType, value);
  }

  Future<int> getJailNotificationAhead() async {
    return await PrefsDatabase.getInt(_kJailNotificationAhead, 40);
  }

  Future setJailNotificationAhead(int value) async {
    return await PrefsDatabase.setInt(_kJailNotificationAhead, value);
  }

  Future<int> getJailAlarmAhead() async {
    return await PrefsDatabase.getInt(_kJailAlarmAhead, 1);
  }

  Future setJailAlarmAhead(int value) async {
    return await PrefsDatabase.setInt(_kJailAlarmAhead, value);
  }

  Future<int> getJailTimerAhead() async {
    return await PrefsDatabase.getInt(_kJailTimerAhead, 40);
  }

  Future setJailTimerAhead(int value) async {
    return await PrefsDatabase.setInt(_kJailTimerAhead, value);
  }

  // Ranked War notification
  Future<String> getRankedWarNotificationType() async {
    return await PrefsDatabase.getString(_kRankedWarNotificationType, '0');
  }

  Future setRankedWarNotificationType(String value) async {
    return await PrefsDatabase.setString(_kRankedWarNotificationType, value);
  }

  Future<int> getRankedWarNotificationAhead() async {
    return await PrefsDatabase.getInt(_kRankedWarNotificationAhead, 60);
  }

  Future setRankedWarNotificationAhead(int value) async {
    return await PrefsDatabase.setInt(_kRankedWarNotificationAhead, value);
  }

  Future<int> getRankedWarAlarmAhead() async {
    return await PrefsDatabase.getInt(_kRankedWarAlarmAhead, 1);
  }

  Future setRankedWarAlarmAhead(int value) async {
    return await PrefsDatabase.setInt(_kRankedWarAlarmAhead, value);
  }

  Future<int> getRankedWarTimerAhead() async {
    return await PrefsDatabase.getInt(_kRankedWarTimerAhead, 60);
  }

  Future setRankedWarTimerAhead(int value) async {
    return await PrefsDatabase.setInt(_kRankedWarTimerAhead, value);
  }

  //

  // Ranked War notification
  Future<String> getRaceStartNotificationType() async {
    return await PrefsDatabase.getString(_kRaceStartNotificationType, '0');
  }

  Future setRaceStartNotificationType(String value) async {
    return await PrefsDatabase.setString(_kRaceStartNotificationType, value);
  }

  Future<int> getRaceStartNotificationAhead() async {
    return await PrefsDatabase.getInt(_kRaceStartNotificationAhead, 60);
  }

  Future setRaceStartNotificationAhead(int value) async {
    return await PrefsDatabase.setInt(_kRaceStartNotificationAhead, value);
  }

  Future<int> getRaceStartAlarmAhead() async {
    return await PrefsDatabase.getInt(_kRaceStartAlarmAhead, 1);
  }

  Future setRaceStartAlarmAhead(int value) async {
    return await PrefsDatabase.setInt(_kRaceStartAlarmAhead, value);
  }

  Future<int> getRaceStartTimerAhead() async {
    return await PrefsDatabase.getInt(_kRaceStartTimerAhead, 60);
  }

  Future setRaceStartTimerAhead(int value) async {
    return await PrefsDatabase.setInt(_kRaceStartTimerAhead, value);
  }

  //

  Future<bool> getShowHeaderWallet() async {
    return await PrefsDatabase.getBool(_kShowHeaderWallet, true);
  }

  Future setShowHeaderWallet(bool value) async {
    return await PrefsDatabase.setBool(_kShowHeaderWallet, value);
  }

  Future<bool> getShowHeaderIcons() async {
    return await PrefsDatabase.getBool(_kShowHeaderIcons, true);
  }

  Future setShowHeaderIcons(bool value) async {
    return await PrefsDatabase.setBool(_kShowHeaderIcons, value);
  }

  Future<bool> getShowShortcutEditIcon() async {
    return await PrefsDatabase.getBool(_kShowShortcutEditIcon, true);
  }

  Future setShowShortcutEditIcon(bool value) async {
    return await PrefsDatabase.setBool(_kShowShortcutEditIcon, value);
  }

  Future<List<String>> getIconsFiltered() async {
    return await PrefsDatabase.getStringList(_kIconsFiltered, <String>[]);
  }

  Future setIconsFiltered(List<String> value) async {
    return await PrefsDatabase.setStringList(_kIconsFiltered, value);
  }

  Future<bool> getDedicatedTravelCard() async {
    return await PrefsDatabase.getBool(_kDedicatedTravelCard, true);
  }

  Future setDedicatedTravelCard(bool value) async {
    return await PrefsDatabase.setBool(_kDedicatedTravelCard, value);
  }

  Future<bool> getDisableTravelSection() async {
    return await PrefsDatabase.getBool(_kDisableTravelSection, false);
  }

  Future setDisableTravelSection(bool value) async {
    return await PrefsDatabase.setBool(_kDisableTravelSection, value);
  }

  Future<bool> getWarnAboutChains() async {
    return await PrefsDatabase.getBool(_kWarnAboutChains, true);
  }

  Future setWarnAboutChains(bool value) async {
    return await PrefsDatabase.setBool(_kWarnAboutChains, value);
  }

  Future<bool> getWarnAboutExcessEnergy() async {
    return await PrefsDatabase.getBool(_kWarnAboutExcessEnergy, true);
  }

  Future setWarnAboutExcessEnergy(bool value) async {
    return await PrefsDatabase.setBool(_kWarnAboutExcessEnergy, value);
  }

  Future<int> getWarnAboutExcessEnergyThreshold() async {
    return await PrefsDatabase.getInt(_kWarnAboutExcessEnergyThreshold, 200);
  }

  Future setWarnAboutExcessEnergyThreshold(int value) async {
    return await PrefsDatabase.setInt(_kWarnAboutExcessEnergyThreshold, value);
  }

  // -- Travel Agency Warnings

  Future<bool> getTravelEnergyExcessWarning() async {
    return await PrefsDatabase.getBool(_kTravelEnergyExcessWarning, true);
  }

  Future setTravelEnergyExcessWarning(bool value) async {
    return await PrefsDatabase.setBool(_kTravelEnergyExcessWarning, value);
  }

  Future<RangeValues> getTravelEnergyRangeWarningRange() async {
    final int min = await PrefsDatabase.getInt(_kTravelEnergyRangeWarningThresholdMin, 10);
    final int max = await PrefsDatabase.getInt(_kTravelEnergyRangeWarningThresholdMax, 100);
    return RangeValues(min.toDouble(), max == 110 ? 110 : max.toDouble());
  }

  Future setTravelEnergyRangeWarningRange(int min, int max) async {
    await PrefsDatabase.setInt(_kTravelEnergyRangeWarningThresholdMin, min);

    await PrefsDatabase.setInt(_kTravelEnergyRangeWarningThresholdMax, max >= 110 ? 110 : max);
  }

  Future<bool> getTravelNerveExcessWarning() async {
    return await PrefsDatabase.getBool(_kTravelNerveExcessWarning, true);
  }

  Future setTravelNerveExcessWarning(bool value) async {
    return await PrefsDatabase.setBool(_kTravelNerveExcessWarning, value);
  }

  Future<int> getTravelNerveExcessWarningThreshold() async {
    return await PrefsDatabase.getInt(_kTravelNerveExcessWarningThreshold, 50);
  }

  Future setTravelNerveExcessWarningThreshold(int value) async {
    return await PrefsDatabase.setInt(_kTravelNerveExcessWarningThreshold, value);
  }

  Future<bool> getTravelLifeExcessWarning() async {
    return await PrefsDatabase.getBool(_kTravelLifeExcessWarning, true);
  }

  Future setTravelLifeExcessWarning(bool value) async {
    return await PrefsDatabase.setBool(_kTravelLifeExcessWarning, value);
  }

  Future<int> getTravelLifeExcessWarningThreshold() async {
    return await PrefsDatabase.getInt(_kTravelLifeExcessWarningThreshold, 50);
  }

  Future setTravelLifeExcessWarningThreshold(int value) async {
    return await PrefsDatabase.setInt(_kTravelLifeExcessWarningThreshold, value);
  }

  Future<bool> getTravelDrugCooldownWarning() async {
    return await PrefsDatabase.getBool(_kTravelDrugCooldownWarning, true);
  }

  Future setTravelDrugCooldownWarning(bool value) async {
    return await PrefsDatabase.setBool(_kTravelDrugCooldownWarning, value);
  }

  Future<bool> getTravelBoosterCooldownWarning() async {
    return await PrefsDatabase.getBool(_kTravelBoosterCooldownWarning, true);
  }

  Future setTravelBoosterCooldownWarning(bool value) async {
    return await PrefsDatabase.setBool(_kTravelBoosterCooldownWarning, value);
  }

  Future<bool> getTravelWalletMoneyWarning() async {
    return await PrefsDatabase.getBool(_kTravelWalletMoneyWarning, true);
  }

  Future setTravelWalletMoneyWarning(bool value) async {
    return await PrefsDatabase.setBool(_kTravelWalletMoneyWarning, value);
  }

  Future<int> getTravelWalletMoneyWarningThreshold() async {
    return await PrefsDatabase.getInt(_kTravelWalletMoneyWarningThreshold, 50000);
  }

  Future setTravelWalletMoneyWarningThreshold(int value) async {
    return await PrefsDatabase.setInt(_kTravelWalletMoneyWarningThreshold, value);
  }

  // -- Terminal

  Future<bool> getTerminalEnabled() async {
    return await PrefsDatabase.getBool(_kTerminalEnabled, false);
  }

  Future setTerminalEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kTerminalEnabled, value);
  }

  // -- Events

  Future<bool> getExpandEvents() async {
    return await PrefsDatabase.getBool(_kExpandEvents, false);
  }

  Future setExpandEvents(bool value) async {
    return await PrefsDatabase.setBool(_kExpandEvents, value);
  }

  Future<int> getEventsShowNumber() async {
    return await PrefsDatabase.getInt(_kEventsShowNumber, 25);
  }

  Future setEventsShowNumber(int value) async {
    return await PrefsDatabase.setInt(_kEventsShowNumber, value);
  }

  Future<int> getEventsLastRetrieved() async {
    return await PrefsDatabase.getInt(_kEventsLastRetrieved, 0);
  }

  Future setEventsLastRetrieved(int value) async {
    return await PrefsDatabase.setInt(_kEventsLastRetrieved, value);
  }

  Future<List<String>> getEventsSave() async {
    return await PrefsDatabase.getStringList(_kEventsSave, []);
  }

  Future setEventsSave(List<String> value) async {
    return await PrefsDatabase.setStringList(_kEventsSave, value);
  }

  // --

  Future<bool> getExpandMessages() async {
    return await PrefsDatabase.getBool(_kExpandMessages, false);
  }

  Future setExpandMessages(bool value) async {
    return await PrefsDatabase.setBool(_kExpandMessages, value);
  }

  Future<int> getMessagesShowNumber() async {
    return await PrefsDatabase.getInt(_kMessagesShowNumber, 25);
  }

  Future setMessagesShowNumber(int value) async {
    return await PrefsDatabase.setInt(_kMessagesShowNumber, value);
  }

  Future<bool> getExpandBasicInfo() async {
    return await PrefsDatabase.getBool(_kExpandBasicInfo, false);
  }

  Future setExpandBasicInfo(bool value) async {
    return await PrefsDatabase.setBool(_kExpandBasicInfo, value);
  }

  Future<bool> getExpandNetworth() async {
    return await PrefsDatabase.getBool(_kExpandNetworth, false);
  }

  Future setExpandNetworth(bool value) async {
    return await PrefsDatabase.setBool(_kExpandNetworth, value);
  }

  /// ----------------------------
  /// Methods job addiction in Profile
  /// ----------------------------
  Future<int> getJobAddictionValue() async {
    return await PrefsDatabase.getInt(_kJobAddictionValue, 0);
  }

  Future setJobAdditionValue(int value) async {
    return await PrefsDatabase.setInt(_kJobAddictionValue, value);
  }

  //--

  Future<int> getJobAddictionNextCallTime() async {
    return await PrefsDatabase.getInt(_kJobAddictionNextCallTime, 0);
  }

  Future setJobAddictionNextCallTime(int value) async {
    return await PrefsDatabase.setInt(_kJobAddictionNextCallTime, value);
  }

  /// ----------------------------
  /// Methods for reviving
  /// ----------------------------

  Future<bool> getUseNukeRevive() async {
    return await PrefsDatabase.getBool(_kUseNukeRevive, true);
  }

  Future setUseNukeRevive(bool value) async {
    return await PrefsDatabase.setBool(_kUseNukeRevive, value);
  }

  Future<bool> getUseUhcRevive() async {
    return await PrefsDatabase.getBool(_kUseUhcRevive, false);
  }

  Future setUseUhcRevive(bool value) async {
    return await PrefsDatabase.setBool(_kUseUhcRevive, value);
  }

  Future<bool> getUseHelaRevive() async {
    return await PrefsDatabase.getBool(_kUseHelaRevive, false);
  }

  Future setUseHelaRevive(bool value) async {
    return await PrefsDatabase.setBool(_kUseHelaRevive, value);
  }

  Future<bool> getUseWtfRevive() async {
    return await PrefsDatabase.getBool(_kUseWtfRevive, false);
  }

  Future setUseWtfRevive(bool value) async {
    return await PrefsDatabase.setBool(_kUseWtfRevive, value);
  }

  Future<bool> getUseMidnightXRevive() async {
    return await PrefsDatabase.getBool(_kUseMidnightXRevive, false);
  }

  Future setUseMidnightXevive(bool value) async {
    return await PrefsDatabase.setBool(_kUseMidnightXRevive, value);
  }

  Future<bool> getUseWolverinesRevive() async {
    return await PrefsDatabase.getBool(_kUseWolverinesRevive, false);
  }

  Future setUseWolverinesRevive(bool value) async {
    return await PrefsDatabase.setBool(_kUseWolverinesRevive, value);
  }

  /// ---------------------------------------
  /// Methods for stats sharing configuration
  /// ---------------------------------------
  Future<bool> getStatsShareIncludeHiddenTargets() async {
    return await PrefsDatabase.getBool(_kStatsShareIncludeHiddenTargets, true);
  }

  Future setStatsShareIncludeHiddenTargets(bool value) async {
    return await PrefsDatabase.setBool(_kStatsShareIncludeHiddenTargets, value);
  }

  //

  Future<bool> getStatsShareShowOnlyTotals() async {
    return await PrefsDatabase.getBool(_kStatsShareShowOnlyTotals, false);
  }

  Future setStatsShareShowOnlyTotals(bool value) async {
    return await PrefsDatabase.setBool(_kStatsShareShowOnlyTotals, value);
  }

  //

  Future<bool> getStatsShareShowEstimatesIfNoSpyAvailable() async {
    return await PrefsDatabase.getBool(_kStatsShareShowEstimatesIfNoSpyAvailable, true);
  }

  Future setStatsShareShowEstimatesIfNoSpyAvailable(bool value) async {
    return await PrefsDatabase.setBool(_kStatsShareShowEstimatesIfNoSpyAvailable, value);
  }

  //

  Future<bool> getStatsShareIncludeTargetsWithNoStatsAvailable() async {
    return await PrefsDatabase.getBool(_kStatsShareIncludeTargetsWithNoStatsAvailable, false);
  }

  Future setStatsShareIncludeTargetsWithNoStatsAvailable(bool value) async {
    return await PrefsDatabase.setBool(_kStatsShareIncludeTargetsWithNoStatsAvailable, value);
  }

  /// ----------------------------
  /// Methods for shortcuts
  /// ----------------------------
  Future<bool> getShortcutsEnabledProfile() async {
    return await PrefsDatabase.getBool(_kEnableShortcuts, true);
  }

  Future setShortcutsEnabledProfile(bool value) async {
    return await PrefsDatabase.setBool(_kEnableShortcuts, value);
  }

  Future<bool> getProfileCheckAttackEnabled() async {
    return await PrefsDatabase.getBool(_kProfileCheckAttackEnabled, true);
  }

  Future setProfileCheckAttackEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kProfileCheckAttackEnabled, value);
  }

  Future<String> getShortcutTile() async {
    return await PrefsDatabase.getString(_kShortcutTile, 'both');
  }

  Future setShortcutTile(String value) async {
    return await PrefsDatabase.setString(_kShortcutTile, value);
  }

  Future<String> getShortcutMenu() async {
    return await PrefsDatabase.getString(_kShortcutMenu, 'carousel');
  }

  Future setShortcutMenu(String value) async {
    return await PrefsDatabase.setString(_kShortcutMenu, value);
  }

  Future<List<String>> getActiveShortcutsList() async {
    return await PrefsDatabase.getStringList(_kActiveShortcutsList, <String>[]);
  }

  Future setActiveShortcutsList(List<String> value) async {
    return await PrefsDatabase.setStringList(_kActiveShortcutsList, value);
  }

  /// ----------------------------
  /// Methods for easy crimes
  /// ----------------------------
  Future<List<String>> getActiveCrimesList() async {
    return await PrefsDatabase.getStringList(_kActiveCrimesList, <String>[]);
  }

  Future setActiveCrimesList(List<String> value) async {
    return await PrefsDatabase.setStringList(_kActiveCrimesList, value);
  }

  /// ----------------------------
  /// Methods for quick items
  /// ----------------------------
  Future<List<String>> getQuickItemsList() async {
    return await PrefsDatabase.getStringList(_kQuickItemsList, <String>[]);
  }

  Future setQuickItemsList(List<String> value) async {
    return await PrefsDatabase.setStringList(_kQuickItemsList, value);
  }

  Future<List<String>> getQuickItemsListFaction() async {
    return await PrefsDatabase.getStringList(_kQuickItemsListFaction, <String>[]);
  }

  Future setQuickItemsListFaction(List<String> value) async {
    return await PrefsDatabase.setStringList(_kQuickItemsListFaction, value);
  }

  Future<int> getNumberOfLoadouts() async {
    return await PrefsDatabase.getInt(_kQuickItemsLoadoutsNumber, 3);
  }

  Future setNumberOfLoadouts(int value) async {
    return await PrefsDatabase.setInt(_kQuickItemsLoadoutsNumber, value);
  }

  /// ----------------------------
  /// Methods for loot
  /// ----------------------------
  Future<String> getLootTimerType() async {
    return await PrefsDatabase.getString(_kLootTimerType, 'timer');
  }

  Future setLootTimerType(String value) async {
    return await PrefsDatabase.setString(_kLootTimerType, value);
  }

  Future<String> getLootNotificationType() async {
    return await PrefsDatabase.getString(_kLootNotificationType, '0');
  }

  Future setLootNotificationType(String value) async {
    return await PrefsDatabase.setString(_kLootNotificationType, value);
  }

  Future<String> getLootNotificationAhead() async {
    return await PrefsDatabase.getString(_kLootNotificationAhead, '0');
  }

  Future setLootNotificationAhead(String value) async {
    return await PrefsDatabase.setString(_kLootNotificationAhead, value);
  }

  Future<String> getLootAlarmAhead() async {
    return await PrefsDatabase.getString(_kLootAlarmAhead, '0');
  }

  Future setLootAlarmAhead(String value) async {
    return await PrefsDatabase.setString(_kLootAlarmAhead, value);
  }

  Future<String> getLootTimerAhead() async {
    return await PrefsDatabase.getString(_kLootTimerAhead, '0');
  }

  Future setLootTimerAhead(String value) async {
    return await PrefsDatabase.setString(_kLootTimerAhead, value);
  }

  Future<List<String>> getLootFiltered() async {
    return await PrefsDatabase.getStringList(_kLootFiltered, <String>[]);
  }

  Future setLootFiltered(List<String> value) async {
    return await PrefsDatabase.setStringList(_kLootFiltered, value);
  }

  /// ----------------------------
  /// Methods for Trades Calculator
  /// ----------------------------
  Future<bool> getTradeCalculatorEnabled() async {
    return await PrefsDatabase.getBool(_kTradeCalculatorEnabled, true);
  }

  Future setTradeCalculatorEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kTradeCalculatorEnabled, value);
  }

  Future<bool> getAWHEnabled() async {
    return await PrefsDatabase.getBool(_kAWHEnabled, true);
  }

  Future setAWHEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kAWHEnabled, value);
  }

  Future<bool> getTornExchangeEnabled() async {
    return await PrefsDatabase.getBool(_kTornExchangeEnabled, true);
  }

  Future setTornExchangeEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kTornExchangeEnabled, value);
  }

  Future<bool> getTornExchangeProfitEnabled() async {
    return await PrefsDatabase.getBool(_kTornExchangeProfitEnabled, false);
  }

  Future setTornExchangeProfitEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kTornExchangeProfitEnabled, value);
  }

  /// ----------------------------
  /// Methods for City Finder
  /// ----------------------------
  Future<bool> getCityEnabled() async {
    return await PrefsDatabase.getBool(_kCityFinderEnabled, true);
  }

  Future setCityEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kCityFinderEnabled, value);
  }

  /// ----------------------------
  /// Methods for Awards
  /// ----------------------------
  Future<String> getAwardsSort() async {
    return await PrefsDatabase.getString(_kAwardsSort, '');
  }

  Future setAwardsSort(String value) async {
    return await PrefsDatabase.setString(_kAwardsSort, value);
  }

  Future<bool> getShowAchievedAwards() async {
    return await PrefsDatabase.getBool(_kShowAchievedAwards, true);
  }

  Future setShowAchievedAwards(bool value) async {
    return await PrefsDatabase.setBool(_kShowAchievedAwards, value);
  }

  Future<List<String?>> getHiddenAwardCategories() async {
    return await PrefsDatabase.getStringList(_kHiddenAwardCategories, <String>[]);
  }

  Future setHiddenAwardCategories(List<String?> value) async {
    return await PrefsDatabase.setStringList(_kHiddenAwardCategories, value as List<String>);
  }

  /// ----------------------------
  /// Methods for Items
  /// ----------------------------
  Future<String> getItemsSort() async {
    return await PrefsDatabase.getString(_kItemsSort, '');
  }

  Future setItemsSort(String value) async {
    return await PrefsDatabase.setString(_kItemsSort, value);
  }

  Future<int> getOnlyOwnedItemsFilter() async {
    return await PrefsDatabase.getInt(_kOnlyOwnedItemsFilter, 0);
  }

  Future setOnlyOwnedItemsFilter(int value) async {
    return await PrefsDatabase.setInt(_kOnlyOwnedItemsFilter, value);
  }

  Future<List<String>> getHiddenItemsCategories() async {
    return await PrefsDatabase.getStringList(_kHiddenItemsCategories, <String>[]);
  }

  Future setHiddenItemsCategories(List<String> value) async {
    return await PrefsDatabase.setStringList(_kHiddenItemsCategories, value);
  }

  Future<List<String>> getPinnedItems() async {
    return await PrefsDatabase.getStringList(_kPinnedItems, <String>[]);
  }

  Future setPinnedItems(List<String> value) async {
    return await PrefsDatabase.setStringList(_kPinnedItems, value);
  }

  /// ----------------------------
  /// Methods for Stakeouts
  /// ----------------------------
  Future<bool> getStakeoutsEnabled() async {
    return await PrefsDatabase.getBool(_kStakeoutsEnabled, true);
  }

  Future setStakeoutsEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kStakeoutsEnabled, value);
  }

  Future<List<String>> getStakeouts() async {
    return await PrefsDatabase.getStringList(_kStakeouts, []);
  }

  Future setStakeouts(List<String> value) async {
    return await PrefsDatabase.setStringList(_kStakeouts, value);
  }

  Future<int> getStakeoutsSleepTime() async {
    return await PrefsDatabase.getInt(_kStakeoutsSleepTime, 0);
  }

  Future setStakeoutsSleepTime(int value) async {
    return await PrefsDatabase.setInt(_kStakeoutsSleepTime, value);
  }

  Future<int> getStakeoutsFetchDelayLimit() async {
    return await PrefsDatabase.getInt(_kStakeoutsFetchDelayLimit, 60);
  }

  Future setStakeoutsFetchDelayLimit(int value) async {
    return await PrefsDatabase.setInt(_kStakeoutsFetchDelayLimit, value);
  }

  /// ----------------------------
  /// Methods for Chat Removal
  /// ----------------------------
  Future<bool> getChatRemovalEnabled() async {
    return await PrefsDatabase.getBool(_kChatRemovalEnabled, true);
  }

  Future setChatRemovalEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kChatRemovalEnabled, value);
  }

  Future<bool> getChatRemovalActive() async {
    return await PrefsDatabase.getBool(_kChatRemovalActive, false);
  }

  Future setChatRemovalActive(bool value) async {
    return await PrefsDatabase.setBool(_kChatRemovalActive, value);
  }

  /// ----------------------------
  /// Methods for Chat Highlight
  /// ----------------------------
  Future<bool> getHighlightChat() async {
    return await PrefsDatabase.getBool(_kHighlightChat, true);
  }

  Future setHighlightChat(bool value) async {
    return await PrefsDatabase.setBool(_kHighlightChat, value);
  }

  Future<List<String>> getHighlightWordList() async {
    return await PrefsDatabase.getStringList(_kHighlightChatWordsList, const []);
  }

  Future setHighlightWordList(List<String> value) async {
    return await PrefsDatabase.setStringList(_kHighlightChatWordsList, value);
  }

  Future<int> getHighlightColor() async {
    return await PrefsDatabase.getInt(_kHighlightColor, 0x701397248);
  }

  Future setHighlightColor(int value) async {
    return await PrefsDatabase.setInt(_kHighlightColor, value);
  }

  /// -------------------
  /// ALTERNATIVE KEYS
  /// -------------------

  // YATA
  Future<bool> getAlternativeYataKeyEnabled() async {
    return await PrefsDatabase.getBool(_kAlternativeYataKeyEnabled, false);
  }

  Future setAlternativeYataKeyEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kAlternativeYataKeyEnabled, value);
  }

  Future<String> getAlternativeYataKey() async {
    return await PrefsDatabase.getString(_kAlternativeYataKey, "");
  }

  Future setAlternativeYataKey(String value) async {
    return await PrefsDatabase.setString(_kAlternativeYataKey, value);
  }

  // TORN STATS
  Future<bool> getAlternativeTornStatsKeyEnabled() async {
    return await PrefsDatabase.getBool(_kAlternativeTornStatsKeyEnabled, false);
  }

  Future setAlternativeTornStatsKeyEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kAlternativeTornStatsKeyEnabled, value);
  }

  Future<String> getAlternativeTornStatsKey() async {
    return await PrefsDatabase.getString(_kAlternativeTornStatsKey, "");
  }

  Future setAlternativeTornStatsKey(String value) async {
    return await PrefsDatabase.setString(_kAlternativeTornStatsKey, value);
  }

  // TORN SPIES CENTRAL
  Future<bool> getAlternativeTSCKeyEnabled() async {
    return await PrefsDatabase.getBool(_kAlternativeTSCKeyEnabled, false);
  }

  Future setAlternativeTSCKeyEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kAlternativeTSCKeyEnabled, value);
  }

  Future<String> getAlternativeTSCKey() async {
    return await PrefsDatabase.getString(_kAlternativeTSCKey, "");
  }

  Future setAlternativeTSCKey(String value) async {
    return await PrefsDatabase.setString(_kAlternativeTSCKey, value);
  }

  /// ---------------------
  /// TORNSTATS STATS CHART
  /// ---------------------

  Future<String> getTornStatsChartSave() async {
    return await PrefsDatabase.getString(_kTornStatsChartSave, "");
  }

  Future setTornStatsChartSave(String value) async {
    return await PrefsDatabase.setString(_kTornStatsChartSave, value);
  }

  Future<int> getTornStatsChartDateTime() async {
    return await PrefsDatabase.getInt(_kTornStatsChartDateTime, 0);
  }

  Future setTornStatsChartDateTime(int value) async {
    return await PrefsDatabase.setInt(_kTornStatsChartDateTime, value);
  }

  Future<bool> getTornStatsChartEnabled() async {
    return await PrefsDatabase.getBool(_kTornStatsChartEnabled, true);
  }

  Future setTornStatsChartEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kTornStatsChartEnabled, value);
  }

  Future<String> getTornStatsChartType() async {
    return await PrefsDatabase.getString(_kTornStatsChartType, "line");
  }

  Future setTornStatsChartType(String value) async {
    return await PrefsDatabase.setString(_kTornStatsChartType, value);
  }

  Future<int> getTornStatsChartRange() async {
    return await PrefsDatabase.getInt(_kTornStatsChartRange, 0);
  }

  Future setTornStatsChartRange(int value) async {
    return await PrefsDatabase.setInt(_kTornStatsChartRange, value);
  }

  Future<bool> getTornStatsChartInCollapsedMiscCard() async {
    return await PrefsDatabase.getBool(_kTornStatsChartInCollapsedMiscCard, true);
  }

  Future setTornStatsChartInCollapsedMiscCard(bool value) async {
    return await PrefsDatabase.setBool(_kTornStatsChartInCollapsedMiscCard, value);
  }

  Future<bool> getTornStatsChartShowBoth() async {
    return await PrefsDatabase.getBool(_kTornStatsChartShowBoth, false);
  }

  Future setTornStatsChartShowBoth(bool value) async {
    return await PrefsDatabase.setBool(_kTornStatsChartShowBoth, value);
  }

  /// -------------------
  /// TORN ATTACK CENTRAL
  /// -------------------
  Future<bool> getTACEnabled() async {
    return await PrefsDatabase.getBool(_kTACEnabled, false);
  }

  Future setTACEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kTACEnabled, value);
  }

  Future<String> getTACFilters() async {
    return await PrefsDatabase.getString(_kTACFilters, "");
  }

  Future setTACFilters(String value) async {
    return await PrefsDatabase.setString(_kTACFilters, value);
  }

  Future<String> getTACTargets() async {
    return await PrefsDatabase.getString(_kTACTargets, "");
  }

  Future setTACTargets(String value) async {
    return await PrefsDatabase.setString(_kTACTargets, value);
  }

  /// -----------------------------
  /// METHODS FOR LISTS IN SETTINGS
  /// -----------------------------
  Future<bool> getUserScriptsEnabled() async {
    return await PrefsDatabase.getBool(_kUserScriptsEnabled, true);
  }

  Future setUserScriptsEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kUserScriptsEnabled, value);
  }

  Future<bool> getUserScriptsNotifyUpdates() async {
    return await PrefsDatabase.getBool(_kUserScriptsNotifyUpdates, true);
  }

  Future setUserScriptsNotifyUpdates(bool value) async {
    return await PrefsDatabase.setBool(_kUserScriptsNotifyUpdates, value);
  }

  Future<String?> getUserScriptsList() async {
    final value = await PrefsDatabase.getString(_kUserScriptsList, "");
    return value.isEmpty ? null : value;
  }

  Future setUserScriptsList(String value) async {
    return await PrefsDatabase.setString(_kUserScriptsList, value);
  }

  // --

  Future<bool> getUserScriptsSectionNeverVisited() async {
    return await PrefsDatabase.getBool(_kUserScriptsV2FirstTime, true);
  }

  Future setUserScriptsSectionNeverVisited(bool value) async {
    return await PrefsDatabase.setBool(_kUserScriptsV2FirstTime, value);
  }

  // --

  Future<bool> getUserScriptsFeatInjectionTimeShown() async {
    return await PrefsDatabase.getBool(_kUserScriptsFeatInjectionTimeShown, false);
  }

  Future setUserScriptsFeatInjectionTimeShown(bool value) async {
    return await PrefsDatabase.setBool(_kUserScriptsFeatInjectionTimeShown, value);
  }

  // --

  Future<String?> getUserScriptsGlobalDisableState() async {
    final value = await PrefsDatabase.getString(_kUserScriptsGlobalDisableState, "");
    return value.isEmpty ? null : value;
  }

  Future setUserScriptsGlobalDisableState(String value) async {
    return await PrefsDatabase.setString(_kUserScriptsGlobalDisableState, value);
  }

  Future<List<String>> getUserScriptsForcedVersions() async {
    return await PrefsDatabase.getStringList(_kUserScriptsForcedVersions, []);
  }

  Future setUserScriptsForcedVersions(List<String> value) async {
    return await PrefsDatabase.setStringList(_kUserScriptsForcedVersions, value);
  }

  /// --------------------------------
  /// METHODS FOR ORGANIZED CRIMES v2
  /// --------------------------------

  Future<bool> getPlayerInOCv2() async {
    return await PrefsDatabase.getBool(_kPlayerAlreadyInOCv2, false);
  }

  Future setPlayerInOCv2(bool value) async {
    return await PrefsDatabase.setBool(_kPlayerAlreadyInOCv2, value);
  }

  /// -----------------------------
  /// METHODS FOR ORGANIZED CRIMES
  /// -----------------------------

  Future<bool> getOCrimesEnabled() async {
    return await PrefsDatabase.getBool(_kOCrimesEnabled, true);
  }

  Future setOCrimesEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kOCrimesEnabled, value);
  }

  Future<int> getOCrimeDisregarded() async {
    return await PrefsDatabase.getInt(_kOCrimeDisregarded, 0);
  }

  Future setOCrimeDisregarded(int value) async {
    return await PrefsDatabase.setInt(_kOCrimeDisregarded, value);
  }

  Future<int> getOCrimeLastKnown() async {
    return await PrefsDatabase.getInt(_kOCrimeLastKnown, 0);
  }

  Future setOCrimeLastKnown(int value) async {
    return await PrefsDatabase.setInt(_kOCrimeLastKnown, value);
  }

  /// -----------------------------
  /// PROPERTY RENTAL (MISC CARD)
  /// -----------------------------
  Future<bool> getShowAllRentedOutProperties() async {
    return await PrefsDatabase.getBool(_kShowAllRentedOutProperties, false);
  }

  Future setShowAllRentedOutProperties(bool value) async {
    return await PrefsDatabase.setBool(_kShowAllRentedOutProperties, value);
  }

  /// -----------------------------
  /// METHODS FOR VAULT SHARE
  /// -----------------------------
  Future<bool> getVaultEnabled() async {
    return await PrefsDatabase.getBool(_kVaultShareEnabled, true);
  }

  Future setVaultEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kVaultShareEnabled, value);
  }

  Future<String> getVaultShareCurrent() async {
    return await PrefsDatabase.getString(_kVaultShareCurrent, "");
  }

  Future setVaultShareCurrent(String value) async {
    return await PrefsDatabase.setString(_kVaultShareCurrent, value);
  }

  /// -----------------------------
  /// METHODS FOR JAIL
  /// -----------------------------
  Future<String> getJailModel() async {
    return await PrefsDatabase.getString(_kJailModel, "");
  }

  Future setJailModel(String value) async {
    return await PrefsDatabase.setString(_kJailModel, value);
  }

  /// -----------------------------
  /// METHODS FOR BOUNTIES
  /// -----------------------------
  Future<String> getBountiesModel() async {
    return await PrefsDatabase.getString(_kBountiesModel, "");
  }

  Future setBountiesModel(String value) async {
    return await PrefsDatabase.setString(_kBountiesModel, value);
  }

  /// -----------------------------
  /// METHODS FOR EXTRA ACCESS TO RANKED WAR
  /// -----------------------------
  Future<bool> getRankedWarsInMenu() async {
    return await PrefsDatabase.getBool(_kRankedWarsInMenu, false);
  }

  Future setRankedWarsInMenu(bool value) async {
    return await PrefsDatabase.setBool(_kRankedWarsInMenu, value);
  }

  Future<bool> getRankedWarsInProfile() async {
    return await PrefsDatabase.getBool(_kRankedWarsInProfile, true);
  }

  Future setRankedWarsInProfile(bool value) async {
    return await PrefsDatabase.setBool(_kRankedWarsInProfile, value);
  }

  Future<bool> getRankedWarsInProfileShowTotalHours() async {
    return await PrefsDatabase.getBool(_kRankedWarsInProfileShowTotalHours, false);
  }

  Future setRankedWarsInProfileShowTotalHours(bool value) async {
    return await PrefsDatabase.setBool(_kRankedWarsInProfileShowTotalHours, value);
  }

  /// -----------------------
  /// METHODS FOR RETALIATION
  /// -----------------------
  Future<bool> getRetaliationSectionEnabled() async {
    return await PrefsDatabase.getBool(_kRetaliationSectionEnabled, true);
  }

  Future setRetaliationSectionEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kRetaliationSectionEnabled, value);
  }

  Future<bool> getSingleRetaliationOpensBrowser() async {
    return await PrefsDatabase.getBool(_kSingleRetaliationOpensBrowser, false);
  }

  Future setSingleRetaliationOpensBrowser(bool value) async {
    return await PrefsDatabase.setBool(_kSingleRetaliationOpensBrowser, value);
  }

  /// -----------------------------
  /// METHODS FOR DATA STOCK MARKET
  /// -----------------------------
  Future<String> getDataStockMarket() async {
    return await PrefsDatabase.getString(_kDataStockMarket, "");
  }

  Future setDataStockMarket(String value) async {
    return await PrefsDatabase.setString(_kDataStockMarket, value);
  }

  Future<bool> getStockExchangeInMenu() async {
    return await PrefsDatabase.getBool(_kStockExchangeInMenu, false);
  }

  Future setStockExchangeInMenu(bool value) async {
    return await PrefsDatabase.setBool(_kStockExchangeInMenu, value);
  }

  Future<int> getForeignStockSellingFee() async {
    return await PrefsDatabase.getInt(_kForeignStockSellingFee, 0);
  }

  Future setForeignStockSellingFee(int value) async {
    return await PrefsDatabase.setInt(_kForeignStockSellingFee, value);
  }

  /// -----------------------------
  /// METHODS FOR WEB VIEW TABS
  /// -----------------------------
  Future<int> getWebViewLastActiveTab() async {
    return await PrefsDatabase.getInt(_kWebViewLastActiveTab, 0);
  }

  Future setWebViewLastActiveTab(int value) async {
    return await PrefsDatabase.setInt(_kWebViewLastActiveTab, value);
  }

  Future<String> getWebViewSessionCookie() async {
    return await PrefsDatabase.getString(_kWebViewSessionCookie, '');
  }

  Future setWebViewSessionCookie(String value) async {
    return await PrefsDatabase.setString(_kWebViewSessionCookie, value);
  }

  Future<String> getWebViewMainTab() async {
    return await PrefsDatabase.getString(_kWebViewMainTab, '{"tabsSave": []}');
  }

  Future setWebViewMainTab(String value) async {
    return await PrefsDatabase.setString(_kWebViewMainTab, value);
  }

  Future<String> getWebViewSecondaryTabs() async {
    return await PrefsDatabase.getString(_kWebViewSecondaryTabs, '{"tabsSave": []}');
  }

  Future setWebViewSecondaryTabs(String value) async {
    return await PrefsDatabase.setString(_kWebViewSecondaryTabs, value);
  }

  Future<bool> getUseTabsFullBrowser() async {
    return await PrefsDatabase.getBool(_kUseTabsInFullBrowser, true);
  }

  Future setUseTabsFullBrowser(bool value) async {
    return await PrefsDatabase.setBool(_kUseTabsInFullBrowser, value);
  }

  Future<bool> getUseTabsBrowserDialog() async {
    return await PrefsDatabase.getBool(_kUseTabsInBrowserDialog, true);
  }

  Future setUseTabsBrowserDialog(bool value) async {
    return await PrefsDatabase.setBool(_kUseTabsInBrowserDialog, value);
  }

  // -- Remove unused tabs

  Future<bool> getRemoveUnusedTabs() async {
    return await PrefsDatabase.getBool(_kRemoveUnusedTabs, true);
  }

  Future setRemoveUnusedTabs(bool value) async {
    return await PrefsDatabase.setBool(_kRemoveUnusedTabs, value);
  }

  Future<bool> getRemoveUnusedTabsIncludesLocked() async {
    return await PrefsDatabase.getBool(_kRemoveUnusedTabsIncludesLocked, false);
  }

  Future setRemoveUnusedTabsIncludesLocked(bool value) async {
    return await PrefsDatabase.setBool(_kRemoveUnusedTabsIncludesLocked, value);
  }

  Future<int> getRemoveUnusedTabsRangeDays() async {
    return await PrefsDatabase.getInt(_kRemoveUnusedTabsRangeDays, 7);
  }

  Future setRemoveUnusedTabsRangeDays(int value) async {
    return await PrefsDatabase.setInt(_kRemoveUnusedTabsRangeDays, value);
  }

  // ---------------------

  Future<bool> getOnlyLoadTabsWhenUsed() async {
    return await PrefsDatabase.getBool(_kOnlyLoadTabsWhenUsed, true);
  }

  Future setOnlyLoadTabsWhenUsed(bool value) async {
    return await PrefsDatabase.setBool(_kOnlyLoadTabsWhenUsed, value);
  }

  Future<bool> getAutomaticChangeToNewTabFromURL() async {
    return await PrefsDatabase.getBool(_kAutomaticChangeToNewTabFromURL, true);
  }

  Future setAutomaticChangeToNewTabFromURL(bool value) async {
    return await PrefsDatabase.setBool(_kAutomaticChangeToNewTabFromURL, value);
  }

  Future<bool> getUseTabsHideFeature() async {
    return await PrefsDatabase.getBool(_kUseTabsHideFeature, true);
  }

  Future setUseTabsHideFeature(bool value) async {
    return await PrefsDatabase.setBool(_kUseTabsHideFeature, value);
  }

  Future setTabsHideBarColor(int value) async {
    return await PrefsDatabase.setInt(_kTabsHideBarColor, value);
  }

  Future<int> getTabsHideBarColor() async {
    return await PrefsDatabase.getInt(_kTabsHideBarColor, 0xFF4CAF40);
  }

  Future<bool> getShowTabLockWarnings() async {
    return await PrefsDatabase.getBool(_kShowTabLockWarnings, true);
  }

  Future setShowTabLockWarnings(bool value) async {
    return await PrefsDatabase.setBool(_kShowTabLockWarnings, value);
  }

  Future<bool> getFullLockNavigationAttemptOpensNewTab() async {
    return await PrefsDatabase.getBool(_kFullLockNavigationAttemptOpensNewTab, false);
  }

  Future setFullLockNavigationAttemptOpensNewTab(bool value) async {
    return await PrefsDatabase.setBool(_kFullLockNavigationAttemptOpensNewTab, value);
  }

  // -- LockedTabsNavigationExceptions
  final List<List<String>> _defaultFullLockedTabsNavigationExceptions = [
    ["https://www.torn.com/item.php", "https://www.torn.com/loader.php?sid=itemsMods"],
    ["https://www.torn.com/item.php", "https://www.torn.com/page.php?sid=ammo"],
  ];

  Future<String> getLockedTabsNavigationExceptions() async {
    return await PrefsDatabase.getString(
      _kFullLockedTabsNavigationExceptions,
      json.encode(_defaultFullLockedTabsNavigationExceptions),
    );
  }

  Future setLockedTabsNavigationExceptions(String value) async {
    return await PrefsDatabase.setString(_kFullLockedTabsNavigationExceptions, value);
  }

  // --

  Future<bool> getUseTabsIcons() async {
    return await PrefsDatabase.getBool(_kUseTabsIcons, true);
  }

  Future setUseTabsIcons(bool value) async {
    return await PrefsDatabase.setBool(_kUseTabsIcons, value);
  }

  Future<bool> getHideTabs() async {
    return await PrefsDatabase.getBool(_kHideTabs, false);
  }

  Future setHideTabs(bool value) async {
    return await PrefsDatabase.setBool(_kHideTabs, value);
  }

  Future<bool> getReminderAboutHideTabFeature() async {
    return await PrefsDatabase.getBool(_kReminderAboutHideTabFeature, false);
  }

  Future setReminderAboutHideTabFeature(bool value) async {
    return await PrefsDatabase.setBool(_kReminderAboutHideTabFeature, value);
  }

  // -- Quick menu tab

  Future<bool> getFullScreenExplanationShown() async {
    return await PrefsDatabase.getBool(_kFullScreenExplanationShown, false);
  }

  Future setFullScreenExplanationShown(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenExplanationShown, value);
  }

  Future<bool> getFullScreenRemovesWidgets() async {
    return await PrefsDatabase.getBool(_kFullScreenRemovesWidgets, true);
  }

  Future setFullScreenRemovesWidgets(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenRemovesWidgets, value);
  }

  Future<bool> getFullScreenRemovesChat() async {
    return await PrefsDatabase.getBool(_kFullScreenRemovesChat, true);
  }

  Future setFullScreenRemovesChat(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenRemovesChat, value);
  }

  Future<bool> getFullScreenExtraCloseButton() async {
    return await PrefsDatabase.getBool(_kFullScreenExtraCloseButton, false);
  }

  Future setFullScreenExtraCloseButton(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenExtraCloseButton, value);
  }

  Future<bool> getFullScreenExtraReloadButton() async {
    return await PrefsDatabase.getBool(_kFullScreenExtraReloadButton, false);
  }

  Future setFullScreenExtraReloadButton(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenExtraReloadButton, value);
  }

  Future<bool> getFullScreenOverNotch() async {
    return await PrefsDatabase.getBool(_kFullScreenOverNotch, true);
  }

  Future setFullScreenOverNotch(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenOverNotch, value);
  }

  Future<bool> getFullScreenOverBottom() async {
    return await PrefsDatabase.getBool(_kFullScreenOverBottom, true);
  }

  Future setFullScreenOverBottom(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenOverBottom, value);
  }

  Future<bool> getFullScreenOverSides() async {
    return await PrefsDatabase.getBool(_kFullScreenOverSides, true);
  }

  Future setFullScreenOverSides(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenOverSides, value);
  }

  //--

  Future<bool> getFullScreenByShortTap() async {
    return await PrefsDatabase.getBool(_kFullScreenByShortTap, false);
  }

  Future setFullScreenByShortTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenByShortTap, value);
  }

  //--
  Future<bool> getFullScreenByLongTap() async {
    return await PrefsDatabase.getBool(_kFullScreenByLongTap, true);
  }

  Future setFullScreenByLongTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenByLongTap, value);
  }

  //--

  Future<bool> getFullScreenByNotificationTap() async {
    return await PrefsDatabase.getBool(_kFullScreenByNotificationTap, false);
  }

  Future setFullScreenByNotificationTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenByNotificationTap, value);
  }

  //--

  Future<bool> getFullScreenByShortChainingTap() async {
    return await PrefsDatabase.getBool(_kFullScreenByShortChainingTap, false);
  }

  Future setFullScreenByShortChainingTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenByShortChainingTap, value);
  }

  Future<bool> getFullScreenByLongChainingTap() async {
    return await PrefsDatabase.getBool(_kFullScreenByLongChainingTap, false);
  }

  Future setFullScreenByLongChainingTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenByLongChainingTap, value);
  }

  //--

  Future<bool> getFullScreenByDeepLinkTap() async {
    return await PrefsDatabase.getBool(_kFullScreenByDeepLinkTap, false);
  }

  Future setFullScreenByDeepLinkTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenByDeepLinkTap, value);
  }

  //--

  Future<bool> getFullScreenByQuickItemTap() async {
    return await PrefsDatabase.getBool(_kFullScreenByQuickItemTap, false);
  }

  Future setFullScreenByQuickItemTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenByQuickItemTap, value);
  }

  //--
  Future<bool> getFullScreenIncludesPDAButtonTap() async {
    return await PrefsDatabase.getBool(_kFullScreenIncludesPDAButtonTap, false);
  }

  Future setFullScreenIncludesPDAButtonTap(bool value) async {
    return await PrefsDatabase.setBool(_kFullScreenIncludesPDAButtonTap, value);
  }

  /// --------------------------------
  /// Methods for notification actions
  /// --------------------------------

  Future<String> getLifeNotificationTapAction() async {
    return await PrefsDatabase.getString(_kLifeNotificationTapAction, 'itemsOwn');
  }

  Future setLifeNotificationTapAction(String value) async {
    return await PrefsDatabase.setString(_kLifeNotificationTapAction, value);
  }

  //

  Future<String> getDrugsNotificationTapAction() async {
    return await PrefsDatabase.getString(_kDrugsNotificationTapAction, 'itemsOwn');
  }

  Future setDrugsNotificationTapAction(String value) async {
    return await PrefsDatabase.setString(_kDrugsNotificationTapAction, value);
  }

  //

  Future<String> getMedicalNotificationTapAction() async {
    return await PrefsDatabase.getString(_kMedicalNotificationTapAction, 'itemsOwn');
  }

  Future setMedicalNotificationTapAction(String value) async {
    return await PrefsDatabase.setString(_kMedicalNotificationTapAction, value);
  }

  //

  Future<String> getBoosterNotificationTapAction() async {
    return await PrefsDatabase.getString(_kBoosterNotificationTapAction, 'itemsOwn');
  }

  Future setBoosterNotificationTapAction(String value) async {
    return await PrefsDatabase.setString(_kBoosterNotificationTapAction, value);
  }

  /// ----------------------------
  /// Methods for show cases
  /// ----------------------------
  /// tabs_general -> for tab use information in webview_stackview
  Future<List<String>> getShowCases() async {
    return await PrefsDatabase.getStringList(_kShowCases, <String>[]);
  }

  Future setShowCases(List<String> value) async {
    return await PrefsDatabase.setStringList(_kShowCases, value);
  }

  /// ----------------------------
  /// Methods for stats analytics
  /// ----------------------------
  Future<int> getStatsFirstLoginTimestamp() async {
    return await PrefsDatabase.getInt(_kStatsFirstLoginTimestamp, 0);
  }

  Future setStatsFirstLoginTimestamp(int value) async {
    return await PrefsDatabase.setInt(_kStatsFirstLoginTimestamp, value);
  }

  Future<int> getStatsCumulatedAppUseSeconds() async {
    return await PrefsDatabase.getInt(_kStatsCumulatedAppUseSeconds, 0);
  }

  Future setStatsCumulatedAppUseSeconds(int value) async {
    return await PrefsDatabase.setInt(_kStatsCumulatedAppUseSeconds, value);
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
    return await PrefsDatabase.getStringList(_kStatsEventsAchieved, []);
  }

  Future setStatsCumulatedEventsAchieved(List<String> value) async {
    return await PrefsDatabase.setStringList(_kStatsEventsAchieved, value);
  }

  /// ----------------------------
  /// Methods for backup automation
  /// ----------------------------
  Future<bool> getAutoBackupReminderEnabled() async {
    return await PrefsDatabase.getBool(_kAutoBackupReminderEnabled, false);
  }

  Future setAutoBackupReminderEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kAutoBackupReminderEnabled, value);
  }

  Future<bool> getAutoBackupBeforeUpdateEnabled() async {
    return await PrefsDatabase.getBool(_kAutoBackupBeforeUpdateEnabled, false);
  }

  Future setAutoBackupBeforeUpdateEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kAutoBackupBeforeUpdateEnabled, value);
  }

  Future<int> getAutoBackupLastReminderShown() async {
    return await PrefsDatabase.getInt(_kAutoBackupLastReminderShown, 0);
  }

  Future setAutoBackupLastReminderShown(int value) async {
    return await PrefsDatabase.setInt(_kAutoBackupLastReminderShown, value);
  }

  Future<int> getAutoBackupLastLocalCreated() async {
    // Default to 5 days ago to ensure existing users get backup reminders within reasonable time
    // and not right after enabling the feature
    final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch;
    return await PrefsDatabase.getInt(_kAutoBackupLastLocalCreated, fiveDaysAgo);
  }

  Future setAutoBackupLastLocalCreated(int value) async {
    return await PrefsDatabase.setInt(_kAutoBackupLastLocalCreated, value);
  }

  /// ----------------------------
  /// Methods for appwidget
  /// ----------------------------
  Future<bool> getAppwidgetDarkMode() async {
    return await PrefsDatabase.getBool(_kAppwidgetDarkMode, false);
  }

  Future setAppwidgetDarkMode(bool value) async {
    return await PrefsDatabase.setBool(_kAppwidgetDarkMode, value);
  }

  // ---

  Future<bool> getAppwidgetRemoveShortcutsOneRowLayout() async {
    return await PrefsDatabase.getBool(_kAppwidgetRemoveShortcutsOneRowLayout, false);
  }

  Future setAppwidgetRemoveShortcutsOneRowLayout(bool value) async {
    return await PrefsDatabase.setBool(_kAppwidgetRemoveShortcutsOneRowLayout, value);
  }

  // ---

  Future<bool> getAppwidgetMoneyEnabled() async {
    return await PrefsDatabase.getBool(_kAppwidgetMoneyEnabled, true);
  }

  Future setAppwidgetMoneyEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kAppwidgetMoneyEnabled, value);
  }

  // ---

  Future<bool> getAppwidgetCooldownTapOpensBrowser() async {
    return await PrefsDatabase.getBool(_kAppwidgetCooldownTapOpensBrowser, false);
  }

  Future setAppwidgetCooldownTapOpensBrowser(bool value) async {
    return await PrefsDatabase.setBool(_kAppwidgetCooldownTapOpensBrowser, value);
  }

  Future<String> getAppwidgetCooldownTapOpensBrowserDestination() async {
    return await PrefsDatabase.getString(_kAppwidgetCooldownTapOpensBrowserDestination, "own");
  }

  Future setAppwidgetCooldownTapOpensBrowserDestination(String value) async {
    return await PrefsDatabase.setString(_kAppwidgetCooldownTapOpensBrowserDestination, value);
  }

  // ---

  Future<bool> getAppwidgetExplanationShown() async {
    return await PrefsDatabase.getBool(_kAppwidgetExplanationShown, false);
  }

  Future setAppwidgetExplanationShown(bool value) async {
    return await PrefsDatabase.setBool(_kAppwidgetExplanationShown, value);
  }

  /// ----------------------------
  /// Methods for permissions
  /// ----------------------------

  Future<int> getExactPermissionDialogShownAndroid() async {
    return await PrefsDatabase.getInt(_kExactPermissionDialogShownAndroid, 0);
  }

  Future setExactPermissionDialogShownAndroid(int value) async {
    return await PrefsDatabase.setInt(_kExactPermissionDialogShownAndroid, value);
  }

  /// ----------------------------
  /// Webview downloads
  /// ----------------------------

  Future<bool> getDownloadActionShare() async {
    return await PrefsDatabase.getBool(_downloadActionShare, true);
  }

  Future setDownloadActionShare(bool value) async {
    return await PrefsDatabase.setBool(_downloadActionShare, value);
  }

  /// ----------------------------
  /// Methods for Api Rate
  /// ----------------------------
  Future<bool> getShowApiRateInDrawer() async {
    return await PrefsDatabase.getBool(_kShowApiRateInDrawer, false);
  }

  Future setShowApiRateInDrawer(bool value) async {
    return await PrefsDatabase.setBool(_kShowApiRateInDrawer, value);
  }

  Future<bool> getDelayApiCalls() async {
    return await PrefsDatabase.getBool(_kDelayApiCalls, false);
  }

  Future setDelayApiCalls(bool value) async {
    return await PrefsDatabase.setBool(_kDelayApiCalls, value);
  }

  // ---

  Future<bool> getShowApiMaxCallWarning() async {
    return await PrefsDatabase.getBool(_kShowApiMaxCallWarning, false);
  }

  Future setShowApiMaxCallWarning(bool value) async {
    return await PrefsDatabase.setBool(_kShowApiMaxCallWarning, value);
  }

  /// ----------------------------
  /// Methods for Memory
  /// ----------------------------
  Future<bool> getShowMemoryInDrawer() async {
    return await PrefsDatabase.getBool(_kShowMemoryInDrawer, false);
  }

  Future setShowMemoryInDrawer(bool value) async {
    return await PrefsDatabase.setBool(_kShowMemoryInDrawer, value);
  }

  // ---

  Future<bool> getShowMemoryInWebview() async {
    return await PrefsDatabase.getBool(_kShowMemoryInWebview, false);
  }

  Future setShowMemoryInWebview(bool value) async {
    return await PrefsDatabase.setBool(_kShowMemoryInWebview, value);
  }

  /// ----------------------------
  /// Methods for Refresh Rate
  /// ----------------------------
  Future<bool> getHighRefreshRateEnabled() async {
    return await PrefsDatabase.getBool(_kHighRefreshRateEnabled, false);
  }

  Future setHighRefreshRateEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kHighRefreshRateEnabled, value);
  }

  /// ----------------------------
  /// Methods for Refresh Rate
  /// ----------------------------
  Future<String> getSplitScreenWebview() async {
    return await PrefsDatabase.getString(_kSplitScreenWebview, 'off');
  }

  Future setSplitScreenWebview(String value) async {
    return await PrefsDatabase.setString(_kSplitScreenWebview, value);
  }

  Future<bool> getSplitScreenRevertsToApp() async {
    return await PrefsDatabase.getBool(_kSplitScreenRevertsToApp, true);
  }

  Future setSplitScreenRevertsToApp(bool value) async {
    return await PrefsDatabase.setBool(_kSplitScreenRevertsToApp, value);
  }

  /// ----------------------------
  /// FCM Token
  /// ----------------------------
  Future<String> getFCMToken() async {
    return await PrefsDatabase.getString(_kFCMToken, "");
  }

  Future setFCMToken(String value) async {
    return await PrefsDatabase.setString(_kFCMToken, value);
  }

  /// ----------------------------
  /// Methods for Sendbird notifications
  /// ----------------------------
  Future<bool> getSendbirdNotificationsEnabled() async {
    return await PrefsDatabase.getBool(_kSendbirdnotificationsEnabled, false);
  }

  Future setSendbirdNotificationsEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kSendbirdnotificationsEnabled, value);
  }

  Future<String> getSendbirdSessionToken() async {
    return await PrefsDatabase.getString(_kSendbirdSessionToken, "");
  }

  Future setSendbirdSessionToken(String value) async {
    return await PrefsDatabase.setString(_kSendbirdSessionToken, value);
  }

  Future<int> getSendbirdTokenTimestamp() async {
    return await PrefsDatabase.getInt(_kSendbirdTokenTimestamp, 0);
  }

  Future setSendbirdTokenTimestamp(int timestamp) async {
    return await PrefsDatabase.setInt(_kSendbirdTokenTimestamp, timestamp);
  }

  Future<bool> getSendbirdExcludeFactionMessages() async {
    return await PrefsDatabase.getBool(_kSendbirdExcludeFactionMessages, false);
  }

  Future setSendbirdExcludeFactionMessages(bool value) async {
    return await PrefsDatabase.setBool(_kSendbirdExcludeFactionMessages, value);
  }

  Future<bool> getSendbirdExcludeCompanyMessages() async {
    return await PrefsDatabase.getBool(_kSendbirdExcludeCompanyMessages, false);
  }

  Future setSendbirdExcludeCompanyMessages(bool value) async {
    return await PrefsDatabase.setBool(_kSendbirdExcludeCompanyMessages, value);
  }

  Future<bool> getSendbirdExcludeEliminationMessages() async {
    return await PrefsDatabase.getBool(_kSendbirdExcludeEliminationMessages, false);
  }

  Future setSendbirdExcludeEliminationMessages(bool value) async {
    return await PrefsDatabase.setBool(_kSendbirdExcludeEliminationMessages, value);
  }

  ///////

  Future<bool> getBringBrowserForwardOnStart() async {
    return await PrefsDatabase.getBool(_kBringBrowserForwardOnStart, false);
  }

  Future setBringBrowserForwardOnStart(bool value) async {
    return await PrefsDatabase.setBool(_kBringBrowserForwardOnStart, value);
  }

  /// -----------------------------------
  /// Methods for task periodic execution
  /// -----------------------------------

  /// Stores the last execution time for a given task name
  Future setLastExecutionTime(String taskName, int timestamp) async {
    return await PrefsDatabase.setInt("$_taskPrefix$taskName", timestamp);
  }

  /// Retrieves the last execution time for a given task name
  Future<int> getLastExecutionTime(String taskName) async {
    return await PrefsDatabase.getInt("$_taskPrefix$taskName", 0);
  }

  /// Removes the stored execution time for a task
  Future removeLastExecutionTime(String taskName) async {
    await PrefsDatabase.remove("$_taskPrefix$taskName");
  }

  /// -----------------------------------
  /// Methods for Torn Calendar
  /// -----------------------------------

  Future<String> getTornCalendarModel() async {
    return await PrefsDatabase.getString(_kTornCalendarModel, "");
  }

  Future setTornCalendarModel(String value) async {
    return await PrefsDatabase.setString(_kTornCalendarModel, value);
  }

  Future<int> getTornCalendarLastUpdate() async {
    return await PrefsDatabase.getInt(_kTornCalendarLastUpdate, 0);
  }

  Future setTornCalendarLastUpdate(int timestamp) async {
    return await PrefsDatabase.setInt(_kTornCalendarLastUpdate, timestamp);
  }

  Future<bool> getTctClockHighlightsEvents() async {
    return await PrefsDatabase.getBool(_kTctClockHighlightsEvents, true);
  }

  Future setTctClockHighlightsEvents(bool value) async {
    return await PrefsDatabase.setBool(_kTctClockHighlightsEvents, value);
  }

  /// -----------------------------------
  /// Methods for iOS AlarmKit metadata
  /// -----------------------------------

  /// Metadata cache keyed by AlarmKit UUIDs to rebuild iOS alarms after app restarts
  Future<Map<String, Map<String, dynamic>>> getIosAlarmMetadata() async {
    final jsonString = await PrefsDatabase.getString(_kIosAlarmMetadata, '{}');
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        final normalized = <String, Map<String, dynamic>>{};
        decoded.forEach((key, value) {
          if (value is Map) {
            normalized[key] = Map<String, dynamic>.from(value);
          }
        });
        return normalized;
      }
    } catch (e, stackTrace) {
      log('Failed to decode iOS alarm metadata: $e', name: 'Prefs.getIosAlarmMetadata', stackTrace: stackTrace);
    }
    return {};
  }

  /// Internal helper to persist the AlarmKit metadata map
  Future<void> _saveIosAlarmMetadata(Map<String, Map<String, dynamic>> metadata) async {
    await PrefsDatabase.setString(_kIosAlarmMetadata, jsonEncode(metadata));
  }

  /// Inserts or updates metadata for a specific AlarmKit UUID (called from AlarmKitServiceIos)
  Future<void> upsertIosAlarmMetadata(String uuid, Map<String, dynamic> metadata) async {
    final current = await getIosAlarmMetadata();
    current[uuid] = Map<String, dynamic>.from(metadata);
    await _saveIosAlarmMetadata(current);
  }

  /// Removes stored metadata for a given AlarmKit UUID
  Future<void> removeIosAlarmMetadata(String uuid) async {
    final current = await getIosAlarmMetadata();
    if (current.remove(uuid) != null) {
      await _saveIosAlarmMetadata(current);
    }
  }

  /// Deletes metadata entries for alarms that are no longer active (called after listAlarms)
  Future<void> compactIosAlarmMetadata(Set<String> keepIds) async {
    final current = await getIosAlarmMetadata();
    final toRemove = current.keys.where((key) => !keepIds.contains(key)).toList();
    if (toRemove.isEmpty) {
      return;
    }
    for (final key in toRemove) {
      current.remove(key);
    }
    await _saveIosAlarmMetadata(current);
  }

  /// -----------------------------------
  /// Methods for Drawer Sections
  /// -----------------------------------

  Future<bool> getShowWikiInDrawer() async {
    return await PrefsDatabase.getBool(_kShowWikiInDrawer, true);
  }

  Future setShowWikiInDrawer(bool value) async {
    return await PrefsDatabase.setBool(_kShowWikiInDrawer, value);
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
      await PrefsDatabase.remove(key);
    } else {
      await PrefsDatabase.setString(key, token);
    }
  }

  Future<String?> getLaPushToken({
    required LiveActivityType activityType,
  }) async {
    final key = _getLaPushTokenKey(activityType);
    final value = await PrefsDatabase.getString(key, "");
    return value.isEmpty ? null : value;
  }

  Future<bool> getIosLiveActivityTravelEnabled() async {
    return await PrefsDatabase.getBool(_kIosLiveActivityTravelEnabled, kSdkIos >= 16.2 ? true : false);
  }

  Future setIosLiveActivityTravelEnabled(bool value) async {
    return await PrefsDatabase.setBool(_kIosLiveActivityTravelEnabled, value);
  }

  /// ----------------------------
  /// Methods for player notes
  /// ----------------------------
  Future<List<Map<String, dynamic>>> getPlayerNotes() async {
    final String notesString = await PrefsDatabase.getString(_kPlayerNotes, "");
    if (notesString.isEmpty) {
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
    return await PrefsDatabase.setString(_kPlayerNotes, notesString);
  }

  // ---

  Future<int> getPlayerNotesSort() async {
    return await PrefsDatabase.getInt(_kPlayerNotesSort, 0);
  }

  Future setPlayerNotesSort(int value) async {
    return await PrefsDatabase.setInt(_kPlayerNotesSort, value);
  }

  Future<bool> getPlayerNotesSortAscending() async {
    return await PrefsDatabase.getBool(_kPlayerNotesSortAscending, true);
  }

  Future setPlayerNotesSortAscending(bool value) async {
    return await PrefsDatabase.setBool(_kPlayerNotesSortAscending, value);
  }

  /// ----------------------------
  /// Methods for NOTES migration status
  /// ----------------------------
  // TODO: remove next version when migration to PlayerNotesProvider is removed in Drawer
  Future<bool> getPlayerNotesMigrationCompleted() async {
    return await PrefsDatabase.getBool(_kPlayerNotesMigrationCompleted, false);
  }

  Future setPlayerNotesMigrationCompleted(bool completed) async {
    return await PrefsDatabase.setBool(_kPlayerNotesMigrationCompleted, completed);
  }
}
