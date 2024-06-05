// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:torn_pda/models/faction/friendly_faction_model.dart';
import 'package:torn_pda/models/oc/ts_members_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';

enum BrowserSetting {
  app,
  external,
}

enum TimeFormatSetting {
  h24,
  h12,
}

enum TimeZoneSetting {
  localTime,
  tornTime,
}

enum BrowserRefreshSetting {
  icon,
  pull,
  both,
}

class SettingsProvider extends ChangeNotifier {
  StreamController willPopShouldOpenDrawerStream = StreamController.broadcast();
  StreamController willPopShouldGoBackStream = StreamController.broadcast();

  var _currentBrowser = BrowserSetting.app;
  BrowserSetting get currentBrowser => _currentBrowser;
  set changeBrowser(BrowserSetting browserType) {
    _currentBrowser = browserType;

    // SHARED PREFS
    late String browserSave;
    switch (_currentBrowser) {
      case BrowserSetting.app:
        browserSave = 'app';
      case BrowserSetting.external:
        browserSave = 'external';
    }
    Prefs().setDefaultBrowser(browserSave);

    notifyListeners();
  }

  var _testBrowserActive = false;
  bool get testBrowserActive => _testBrowserActive;
  set changeTestBrowserActive(bool active) {
    _testBrowserActive = active;
    Prefs().setTestBrowserActive(_testBrowserActive);
    notifyListeners();
  }

  var _restoreSessionCookie = false;
  bool get restoreSessionCookie => _restoreSessionCookie;
  set restoreSessionCookie(bool enabled) {
    _restoreSessionCookie = enabled;
    Prefs().setRestoreSessionCookie(_restoreSessionCookie);
    if (!enabled) {
      Prefs().setWebViewSessionCookie("");
    }
  }

  var _webviewCacheEnabled = false;
  bool get webviewCacheEnabled => _webviewCacheEnabled;
  set webviewCacheEnabled(bool enabled) {
    _webviewCacheEnabled = enabled;
    Prefs().setWebviewCacheEnabled(enabled);
    notifyListeners();
  }

  var _androidBrowserScale = 0;
  int get androidBrowserScale => _androidBrowserScale;
  set setAndroidBrowserScale(int scale) {
    _androidBrowserScale = scale;
    Prefs().setAndroidBrowserScale(_androidBrowserScale);
  }

  var _androidBrowserTextScale = 8;
  int get androidBrowserTextScale => _androidBrowserTextScale;
  set changeAndroidBrowserTextScale(int choice) {
    _androidBrowserTextScale = choice;
    Prefs().setAndroidBrowserTextScale(_androidBrowserTextScale);
    notifyListeners();
  }

  var _iosBrowserPinch = false;
  bool get iosBrowserPinch => _iosBrowserPinch;
  set setIosBrowserPinch(bool pinch) {
    _iosBrowserPinch = pinch;
    Prefs().setIosBrowserPinch(_iosBrowserPinch);
  }

  var _iosDisallowOverscroll = false;
  bool get iosDisallowOverscroll => _iosDisallowOverscroll;
  set setIosDisallowOverscroll(bool disallow) {
    _iosDisallowOverscroll = disallow;
    Prefs().setIosDisallowOverscroll(_iosDisallowOverscroll);
  }

  var _disableTravelSection = false;
  bool get disableTravelSection => _disableTravelSection;
  set changeDisableTravelSection(bool disable) {
    _disableTravelSection = disable;
    Prefs().setDisableTravelSection(_disableTravelSection);
    notifyListeners();
  }

  String? _onBackButtonAppExit = 'ask';
  String? get onBackButtonAppExit => _onBackButtonAppExit;
  set changeOnAppExit(String? choice) {
    _onBackButtonAppExit = choice;
    Prefs().setOnAppExit(_onBackButtonAppExit!);
    notifyListeners();
  }

  var _currentTimeFormat = TimeFormatSetting.h24;
  TimeFormatSetting get currentTimeFormat => _currentTimeFormat;
  set changeTimeFormat(TimeFormatSetting timeFormatSetting) {
    _currentTimeFormat = timeFormatSetting;

    // SHARED PREFS
    late String timeFormatSave;
    switch (_currentTimeFormat) {
      case TimeFormatSetting.h24:
        timeFormatSave = '24';
      case TimeFormatSetting.h12:
        timeFormatSave = '12';
    }
    Prefs().setDefaultTimeFormat(timeFormatSave);

    notifyListeners();
  }

  var _currentTimeZone = TimeZoneSetting.localTime;
  TimeZoneSetting get currentTimeZone => _currentTimeZone;
  set changeTimeZone(TimeZoneSetting timeZoneSetting) {
    _currentTimeZone = timeZoneSetting;
    // SHARED PREFS
    late String timeZoneSave;
    switch (_currentTimeZone) {
      case TimeZoneSetting.localTime:
        timeZoneSave = 'local';
      case TimeZoneSetting.tornTime:
        timeZoneSave = 'torn';
    }
    Prefs().setDefaultTimeZone(timeZoneSave);
    notifyListeners();
  }

  var _showDateInClock = "dayfirst";
  String get showDateInClock => _showDateInClock;
  set changeShowDateInClock(String value) {
    _showDateInClock = value;
    Prefs().setShowDateInClock(value);
    notifyListeners();
  }

  var _discreteNotifications = false;
  bool get discreteNotifications => _discreteNotifications;
  set discreteNotifications(bool value) {
    _discreteNotifications = value;
    Prefs().setDiscreteNotifications(value);
    notifyListeners();
  }

  var _showSecondsInClock = true;
  bool get showSecondsInClock => _showSecondsInClock;
  set changeShowSecondsInClock(bool value) {
    _showSecondsInClock = value;
    Prefs().setShowSecondsInClock(value);
    notifyListeners();
  }

  NaturalNerveBarSource _naturalNerveBarSource = NaturalNerveBarSource.yata;
  NaturalNerveBarSource get naturalNerveBarSource => _naturalNerveBarSource;
  set naturalNerveBarSource(NaturalNerveBarSource value) {
    _naturalNerveBarSource = value;
    _naturalNerveBarSource == NaturalNerveBarSource.yata
        ? Prefs().setNaturalNerveBarSource('yata')
        : Prefs().setNaturalNerveBarSource('tornstats');
    notifyListeners();
  }

  var _appBarTop = true;
  bool get appBarTop => _appBarTop;
  set changeAppBarTop(bool value) {
    _appBarTop = value;
    _appBarTop ? Prefs().setAppBarPosition('top') : Prefs().setAppBarPosition('bottom');
    notifyListeners();
  }

  var _loadBarBrowser = true;
  bool get loadBarBrowser => _loadBarBrowser;
  set changeLoadBarBrowser(bool value) {
    _loadBarBrowser = value;
    Prefs().setLoadBarBrowser(_loadBarBrowser);
    notifyListeners();
  }

  BrowserRefreshSetting? _browserRefreshMethod = BrowserRefreshSetting.both;
  BrowserRefreshSetting? get browserRefreshMethod => _browserRefreshMethod;
  set changeBrowserRefreshMethod(BrowserRefreshSetting value) {
    _browserRefreshMethod = value;
    switch (value) {
      case BrowserRefreshSetting.icon:
        Prefs().setBrowserRefreshMethod("icon");
      case BrowserRefreshSetting.pull:
        Prefs().setBrowserRefreshMethod("pull");
      case BrowserRefreshSetting.both:
        Prefs().setBrowserRefreshMethod("both");
    }
    notifyListeners();
  }

  var _useTabsFullBrowser = true;
  bool get useTabsFullBrowser => _useTabsFullBrowser;
  set changeUseTabsFullBrowser(bool value) {
    _useTabsFullBrowser = value;
    Prefs().setUseTabsFullBrowser(_useTabsFullBrowser);
    notifyListeners();
  }

  var _useTabsHideFeature = true;
  bool get useTabsHideFeature => _useTabsHideFeature;
  set changeUseTabsHideFeature(bool value) {
    _useTabsHideFeature = value;
    Prefs().setUseTabsHideFeature(_useTabsHideFeature);
    notifyListeners();
  }

  int _tabsHideBarColor = 0xFF4CAF40;
  int get tabsHideBarColor => _tabsHideBarColor;
  set changeTabsHideBarColor(int value) {
    _tabsHideBarColor = value;
    Prefs().setTabsHideBarColor(_tabsHideBarColor);
    notifyListeners();
  }

  var _fullScreenRemovesWidgets = true;
  bool get fullScreenRemovesWidgets => _fullScreenRemovesWidgets;
  set fullScreenRemovesWidgets(bool value) {
    _fullScreenRemovesWidgets = value;
    Prefs().setFullScreenRemovesWidgets(_fullScreenRemovesWidgets);
    notifyListeners();
  }

  var _fullScreenRemovesChat = true;
  bool get fullScreenRemovesChat => _fullScreenRemovesChat;
  set fullScreenRemovesChat(bool value) {
    _fullScreenRemovesChat = value;
    Prefs().setFullScreenRemovesChat(_fullScreenRemovesChat);
    notifyListeners();
  }

  var _fullScreenExtraCloseButton = false;
  bool get fullScreenExtraCloseButton => _fullScreenExtraCloseButton;
  set fullScreenExtraCloseButton(bool value) {
    _fullScreenExtraCloseButton = value;
    Prefs().setFullScreenExtraCloseButton(_fullScreenExtraCloseButton);
    notifyListeners();
  }

  var _fullScreenExtraReloadButton = false;
  bool get fullScreenExtraReloadButton => _fullScreenExtraReloadButton;
  set fullScreenExtraReloadButton(bool value) {
    _fullScreenExtraReloadButton = value;
    Prefs().setFullScreenExtraReloadButton(_fullScreenExtraReloadButton);
    notifyListeners();
  }

  var _fullScreenOverNotch = true;
  bool get fullScreenOverNotch => _fullScreenOverNotch;
  set fullScreenOverNotch(bool value) {
    _fullScreenOverNotch = value;
    Prefs().setFullScreenOverNotch(_fullScreenOverNotch);
    notifyListeners();
  }

  var _fullScreenOverBottom = true;
  bool get fullScreenOverBottom => _fullScreenOverBottom;
  set fullScreenOverBottom(bool value) {
    _fullScreenOverBottom = value;
    Prefs().setFullScreenOverBottom(_fullScreenOverBottom);
    notifyListeners();
  }

  var _fullScreenOverSides = true;
  bool get fullScreenOverSides => _fullScreenOverSides;
  set fullScreenOverSides(bool value) {
    _fullScreenOverSides = value;
    Prefs().setFullScreenOverSides(_fullScreenOverSides);
    notifyListeners();
  }

  var _fullScreenByShortTap = false;
  bool get fullScreenByShortTap => _fullScreenByShortTap;
  set fullScreenByShortTap(bool value) {
    _fullScreenByShortTap = value;
    Prefs().setFullScreenByShortTap(_fullScreenByShortTap);
    notifyListeners();
  }

  var _fullScreenByLongTap = false;
  bool get fullScreenByLongTap => _fullScreenByLongTap;
  set fullScreenByLongTap(bool value) {
    _fullScreenByLongTap = value;
    Prefs().setFullScreenByLongTap(_fullScreenByLongTap);
    notifyListeners();
  }

  var _fullScreenByNotificationTap = false;
  bool get fullScreenByNotificationTap => _fullScreenByNotificationTap;
  set fullScreenByNotificationTap(bool value) {
    _fullScreenByNotificationTap = value;
    Prefs().setFullScreenByNotificationTap(_fullScreenByNotificationTap);
    notifyListeners();
  }

  var _fullScreenByDeepLinkTap = false;
  bool get fullScreenByDeepLinkTap => _fullScreenByDeepLinkTap;
  set fullScreenByDeepLinkTap(bool value) {
    _fullScreenByDeepLinkTap = value;
    Prefs().setFullScreenByDeepLinkTap(_fullScreenByDeepLinkTap);
    notifyListeners();
  }

  var _fullScreenByQuickItemTap = false;
  bool get fullScreenByQuickItemTap => _fullScreenByQuickItemTap;
  set fullScreenByQuickItemTap(bool value) {
    _fullScreenByQuickItemTap = value;
    Prefs().setFullScreenByQuickItemTap(_fullScreenByQuickItemTap);
    notifyListeners();
  }

  var _fullScreenIncludesPDAButtonTap = false;
  bool get fullScreenIncludesPDAButtonTap => _fullScreenIncludesPDAButtonTap;
  set fullScreenIncludesPDAButtonTap(bool value) {
    _fullScreenIncludesPDAButtonTap = value;
    Prefs().setFullScreenIncludesPDAButtonTap(_fullScreenIncludesPDAButtonTap);
    notifyListeners();
  }

  var _chatRemoveEnabled = true;
  bool get chatRemoveEnabled => _chatRemoveEnabled;
  set changeChatRemoveEnabled(bool value) {
    _chatRemoveEnabled = value;
    Prefs().setChatRemovalEnabled(_chatRemoveEnabled);
    notifyListeners();
  }

  var _highlightChat = true;
  bool get highlightChat => _highlightChat;
  set changeHighlightChat(bool value) {
    _highlightChat = value;
    Prefs().setHighlightChat(_highlightChat);
    notifyListeners();
  }

  var _highlightColor = 0xFF009628;
  int get highlightColor => _highlightColor;
  set changeHighlightColor(int value) {
    _highlightColor = value;
    Prefs().setHighlightColor(_highlightColor);
    notifyListeners();
  }

  var _highlightWordList = <String>[];
  List<String> get highlightWordList => _highlightWordList;
  set changeHighlightWordList(List<String> value) {
    _highlightWordList = value;
    Prefs().setHighlightWordList(_highlightWordList);
    notifyListeners();
  }

  var _removeAirplane = false;
  bool get removeAirplane => _removeAirplane;
  set changeRemoveAirplane(bool value) {
    _removeAirplane = value;
    Prefs().setRemoveAirplane(_removeAirplane);
    notifyListeners();
  }

  var _extraPlayerInformation = false;
  bool get extraPlayerInformation => _extraPlayerInformation;
  set changeExtraPlayerInformation(bool value) {
    _extraPlayerInformation = value;
    Prefs().setExtraPlayerInformation(_extraPlayerInformation);
    notifyListeners();
  }

  /*
  Deactivated as profile stats are now always enabled to reduce settings' complexity
  */

  /*
  String? _profileStatsEnabled = "0";
  String? get profileStatsEnabled => _profileStatsEnabled;
  set changeProfileStatsEnabled(String? value) {
    _profileStatsEnabled = value;
    Prefs().setProfileStatsEnabled(_profileStatsEnabled!);
    notifyListeners();
  }
  */

  // Torn Spies Central
  // -1 == never used (will be shown in the stats dialog, as a reminder to the user that they can enable it)
  //       (if the user enables/disables it in the dialog, any subsequent change must be done from Settings)
  //  0 == disabled
  //  1 == enabled
  int _tscEnabledStatus = -1;
  int get tscEnabledStatus => _tscEnabledStatus;
  set tscEnabledStatus(int value) {
    _tscEnabledStatus = value;
    Prefs().setTSCEnabledStatus(_tscEnabledStatus);
    notifyListeners();
  }

  bool _tscEnabledStatusRemoteConfig = true;
  bool get tscEnabledStatusRemoteConfig => _tscEnabledStatusRemoteConfig;
  set tscEnabledStatusRemoteConfig(bool value) {
    _tscEnabledStatusRemoteConfig = value;
    notifyListeners();
  }

  bool _backupPrefsEnabledStatusRemoteConfig = true;
  bool get backupPrefsEnabledStatusRemoteConfig => _backupPrefsEnabledStatusRemoteConfig;
  set backupPrefsEnabledStatusRemoteConfig(bool value) {
    _backupPrefsEnabledStatusRemoteConfig = value;
    notifyListeners();
  }

  bool _tornExchangeEnabledStatusRemoteConfig = true;
  bool get tornExchangeEnabledStatusRemoteConfig => _tornExchangeEnabledStatusRemoteConfig;
  set tornExchangeEnabledStatusRemoteConfig(bool value) {
    _tornExchangeEnabledStatusRemoteConfig = value;
    notifyListeners();
  }

  var _friendlyFactions = <FriendlyFaction>[];
  List<FriendlyFaction> get friendlyFactions => _friendlyFactions;
  set setFriendlyFactions(List<FriendlyFaction> faction) {
    _friendlyFactions = faction;
    Prefs().setFriendlyFactions(json.encode(_friendlyFactions));
    notifyListeners();
  }

  var _extraPlayerNetworth = false;
  bool get extraPlayerNetworth => _extraPlayerNetworth;
  set changeExtraPlayerNetworth(bool value) {
    _extraPlayerNetworth = value;
    Prefs().setExtraPlayerNetworth(_extraPlayerNetworth);
    notifyListeners();
  }

  var _hitInMiniProfileOpensNewTab = false;
  bool get hitInMiniProfileOpensNewTab => _hitInMiniProfileOpensNewTab;
  set hitInMiniProfileOpensNewTab(bool value) {
    _hitInMiniProfileOpensNewTab = value;
    Prefs().setHitInMiniProfileOpensNewTab(_hitInMiniProfileOpensNewTab);
    notifyListeners();
  }

  var _hitInMiniProfileOpensNewTabAndChangeTab = false;
  bool get hitInMiniProfileOpensNewTabAndChangeTab => _hitInMiniProfileOpensNewTabAndChangeTab;
  set hitInMiniProfileOpensNewTabAndChangeTab(bool value) {
    _hitInMiniProfileOpensNewTabAndChangeTab = value;
    Prefs().setHitInMiniProfileOpensNewTabAndChangeTab(_hitInMiniProfileOpensNewTabAndChangeTab);
    notifyListeners();
  }

  var _removeNotificationsOnLaunch = true;
  bool get removeNotificationsOnLaunch => _removeNotificationsOnLaunch;
  set changeRemoveNotificationsOnLaunch(bool value) {
    _removeNotificationsOnLaunch = value;
    Prefs().setRemoveNotificationsOnLaunch(_removeNotificationsOnLaunch);
    notifyListeners();
  }

  var _oCrimesEnabled = true;
  bool get oCrimesEnabled => _oCrimesEnabled;
  set changeOCrimesEnabled(bool value) {
    _oCrimesEnabled = value;
    // If disabled, reset as well any crimes that was disregarded (so that it can
    // be enabled again if desired)
    if (!value) {
      _oCrimeDisregarded = 0;
      Prefs().setOCrimeDisregarded(_oCrimeDisregarded);
    }
    Prefs().setOCrimesEnabled(_oCrimesEnabled);
    notifyListeners();
  }

  var _oCrimeDisregarded = 0;
  int get oCrimeDisregarded => _oCrimeDisregarded;
  set changeOCrimeDisregarded(int value) {
    _oCrimeDisregarded = value;
    Prefs().setOCrimeDisregarded(_oCrimeDisregarded);
    notifyListeners();
  }

  var _oCrimeLastKnown = 0;
  int get oCrimeLastKnown => _oCrimeLastKnown;
  set changeOCrimeLastKnown(int value) {
    _oCrimeLastKnown = value;
    Prefs().setOCrimeLastKnown(_oCrimeLastKnown);
    notifyListeners();
  }

  var _allowScreenRotation = false;
  bool get allowScreenRotation => _allowScreenRotation;
  set changeAllowScreenRotation(bool allow) {
    _allowScreenRotation = allow;

    if (allow) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    Prefs().setAllowScreenRotation(_allowScreenRotation);
    notifyListeners();
  }

  String? _lifeBarOption = 'ask';
  String? get lifeBarOption => _lifeBarOption;
  set changeLifeBarOption(String? choice) {
    _lifeBarOption = choice;
    Prefs().setLifeBarOption(_lifeBarOption!);
    notifyListeners();
  }

  bool _colorCodedStatusCard = true;
  bool get colorCodedStatusCard => _colorCodedStatusCard;
  set colorCodedStatusCard(bool choice) {
    _colorCodedStatusCard = choice;
    Prefs().setColorCodedStatusCard(_colorCodedStatusCard);
    notifyListeners();
  }

  var _iosAllowLinkPreview = true;
  bool get iosAllowLinkPreview => _iosAllowLinkPreview;
  set changeIosAllowLinkPreview(bool choice) {
    _iosAllowLinkPreview = choice;
    Prefs().setIosAllowLinkPreview(_iosAllowLinkPreview);
    notifyListeners();
  }

  var _warnAboutExcessEnergy = true;
  bool get warnAboutExcessEnergy => _warnAboutExcessEnergy;
  set changeWarnAboutExcessEnergy(bool choice) {
    _warnAboutExcessEnergy = choice;
    Prefs().setWarnAboutExcessEnergy(_warnAboutExcessEnergy);
    notifyListeners();
  }

  var _warnAboutExcessEnergyThreshold = 200;
  int get warnAboutExcessEnergyThreshold => _warnAboutExcessEnergyThreshold;
  set changeWarnAboutExcessEnergyThreshold(int choice) {
    _warnAboutExcessEnergyThreshold = choice;
    Prefs().setWarnAboutExcessEnergyThreshold(_warnAboutExcessEnergyThreshold);
    notifyListeners();
  }

  var _warnAboutChains = true;
  bool get warnAboutChains => _warnAboutChains;
  set changeWarnAboutChains(bool choice) {
    _warnAboutChains = choice;
    Prefs().setWarnAboutChains(_warnAboutChains);
    notifyListeners();
  }

  var _terminalEnabled = false;
  bool get terminalEnabled => _terminalEnabled;
  set changeTerminalEnabled(bool choice) {
    _terminalEnabled = choice;
    Prefs().setTerminalEnabled(_terminalEnabled);
    notifyListeners();
  }

  var _rankedWarsInMenu = false;
  bool get rankedWarsInMenu => _rankedWarsInMenu;
  set changeRankedWarsInMenu(bool choice) {
    _rankedWarsInMenu = choice;
    Prefs().setRankedWarsInMenu(_rankedWarsInMenu);
    notifyListeners();
  }

  var _rankedWarsInProfile = false;
  bool get rankedWarsInProfile => _rankedWarsInProfile;
  set changeRankedWarsInProfile(bool choice) {
    _rankedWarsInProfile = choice;
    Prefs().setRankedWarsInProfile(_rankedWarsInProfile);
    notifyListeners();
  }

  var _rankedWarsInProfileShowTotalHours = false;
  bool get rankedWarsInProfileShowTotalHours => _rankedWarsInProfileShowTotalHours;
  set changeRankedWarsInProfileShowTotalHours(bool choice) {
    _rankedWarsInProfileShowTotalHours = choice;
    Prefs().setRankedWarsInProfileShowTotalHours(_rankedWarsInProfileShowTotalHours);
    notifyListeners();
  }

  var _stockExchangeInMenu = false;
  bool get stockExchangeInMenu => _stockExchangeInMenu;
  set changeStockExchangeInMenu(bool choice) {
    _stockExchangeInMenu = choice;
    Prefs().setStockExchangeInMenu(_stockExchangeInMenu);
    notifyListeners();
  }

  var _iconsFiltered = [];
  List<String> get iconsFiltered => _iconsFiltered as List<String>;
  set changeIconsFiltered(List<String> icons) {
    _iconsFiltered = icons;
    Prefs().setIconsFiltered(_iconsFiltered as List<String>);
    notifyListeners();
  }

  var _showCases = <String>[];
  List<String> get showCases => _showCases;
  set addShowCase(String showCase) {
    _showCases.add(showCase);
    Prefs().setShowCases(_showCases);
    notifyListeners();
  }

  set removeShowCase(String showCase) {
    _showCases.remove(showCase);
    Prefs().setShowCases(_showCases);
    notifyListeners();
  }

  clearShowCases() {
    _showCases.clear();
    Prefs().setShowCases([]);
    notifyListeners();
  }

  TravelTicket? _travelTicket = TravelTicket.private;
  TravelTicket? get travelTicket => _travelTicket;
  set changeTravelTicket(TravelTicket ticket) {
    _travelTicket = ticket;
    String ticketString = "private";
    switch (ticket) {
      case TravelTicket.standard:
        ticketString = "standard";
      case TravelTicket.private:
        ticketString = "private";
      case TravelTicket.wlt:
        ticketString = "wlt";
      case TravelTicket.business:
        ticketString = "business";
    }
    Prefs().setTravelTicket(ticketString);
    notifyListeners();
  }

  String _foreignStocksDataProvider = "yata";
  String get foreignStocksDataProvider => _foreignStocksDataProvider;
  set foreignStocksDataProvider(String provider) {
    _foreignStocksDataProvider = provider;
    Prefs().setForeignStocksDataProvider(provider);
    notifyListeners();
  }

  var _targetSkippingAll = true;
  bool get targetSkippingAll => _targetSkippingAll;
  set changeTargetSkippingAll(bool value) {
    _targetSkippingAll = value;
    Prefs().setTargetSkipping(targetSkippingAll);
    notifyListeners();
  }

  var _targetSkippingFirst = true;
  bool get targetSkippingFirst => _targetSkippingFirst;
  set changeTargetSkippingFirst(bool value) {
    _targetSkippingFirst = value;
    Prefs().setTargetSkipping(targetSkippingFirst);
    notifyListeners();
  }

  int _tornStatsChartDateTime = 0;
  int get tornStatsChartDateTime => _tornStatsChartDateTime;
  set setTornStatsChartDateTime(int timeStamp) {
    Prefs().setTornStatsChartDateTime(timeStamp);
    _tornStatsChartDateTime = timeStamp;
    notifyListeners();
  }

  var _tornStatsChartEnabled = true;
  bool get tornStatsChartEnabled => _tornStatsChartEnabled;
  set setTornStatsChartEnabled(bool value) {
    _tornStatsChartEnabled = value;
    Prefs().setTornStatsChartEnabled(tornStatsChartEnabled);
    notifyListeners();
  }

  var _tornStatsChartType = "line";
  String get tornStatsChartType => _tornStatsChartType;
  set setTornStatsChartType(String value) {
    _tornStatsChartType = value;
    Prefs().setTornStatsChartType(tornStatsChartType);
    notifyListeners();
  }

  var _tornStatsChartInCollapsedMiscCard = true;
  bool get tornStatsChartInCollapsedMiscCard => _tornStatsChartInCollapsedMiscCard;
  set setTornStatsChartInCollapsedMiscCard(bool value) {
    _tornStatsChartInCollapsedMiscCard = value;
    Prefs().setTornStatsChartEnabled(tornStatsChartInCollapsedMiscCard);
    notifyListeners();
  }

  var _retaliationSectionEnabled = true;
  bool get retaliationSectionEnabled => _retaliationSectionEnabled;
  set setRetaliationSectionEnabled(bool value) {
    _retaliationSectionEnabled = value;
    Prefs().setRetaliationSectionEnabled(value);
    notifyListeners();
  }

  var _singleRetaliationOpensBrowser = false;
  bool get singleRetaliationOpensBrowser => _singleRetaliationOpensBrowser;
  set setSingleRetaliationOpensBrowser(bool value) {
    _singleRetaliationOpensBrowser = value;
    Prefs().setSingleRetaliationOpensBrowser(value);
    notifyListeners();
  }

  int _lastAppUse = 0;
  int get lastAppUse => _lastAppUse;
  set updateLastUsed(int timeStamp) {
    Prefs().setLastAppUse(timeStamp);
    _lastAppUse = timeStamp;
    notifyListeners();
  }

  var _syncTornWebTheme = true;
  bool get syncTornWebTheme => _syncTornWebTheme;
  set syncTornWebTheme(bool value) {
    _syncTornWebTheme = value;
    Prefs().setSyncTornWebTheme(_syncTornWebTheme);
    notifyListeners();
  }

  var _syncDeviceTheme = false;
  bool get syncDeviceTheme => _syncDeviceTheme;
  set syncDeviceTheme(bool value) {
    _syncDeviceTheme = value;
    Prefs().setSyncDeviceTheme(_syncDeviceTheme);
    notifyListeners();
  }

  var _darkThemeToSync = "dark";
  String get darkThemeToSyncFromWeb => _darkThemeToSync;
  set darkThemeToSyncFromWeb(String value) {
    _darkThemeToSync = value;
    Prefs().setDarkThemeToSync(value);
    notifyListeners();
  }

  var _debugMessages = false;
  bool get debugMessages => _debugMessages;
  set debugMessages(bool value) {
    _debugMessages = value;
    Prefs().setDebugMessages(_debugMessages);
    notifyListeners();
  }

  var _shortcutsEnabledProfile = true;
  bool get shortcutsEnabledProfile => _shortcutsEnabledProfile;
  set shortcutsEnabledProfile(bool value) {
    _shortcutsEnabledProfile = value;
    Prefs().setShortcutsEnabledProfile(value);
    notifyListeners();
  }

  var _appwidgetDarkMode = false;
  bool get appwidgetDarkMode => _appwidgetDarkMode;
  set appwidgetDarkMode(bool value) {
    _appwidgetDarkMode = value;
    Prefs().setAppwidgetDarkMode(value);
    notifyListeners();
  }

  var _appwidgetMoneyEnabled = false;
  bool get appwidgetMoneyEnabled => _appwidgetMoneyEnabled;
  set appwidgetMoneyEnabled(bool value) {
    _appwidgetMoneyEnabled = value;
    Prefs().setAppwidgetMoneyEnabled(value);
    notifyListeners();
  }

  int _exactPermissionDialogShownAndroid = 0;
  int get exactPermissionDialogShownAndroid => _exactPermissionDialogShownAndroid;
  set exactPermissionDialogShownAndroid(int value) {
    _exactPermissionDialogShownAndroid = value;
    Prefs().setExactPermissionDialogShownAndroid(value);
  }

  bool _downloadActionShare = true;
  bool get downloadActionShare => _downloadActionShare;
  set downloadActionShare(bool value) {
    _downloadActionShare = value;
    Prefs().setDownloadActionShare(value);
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    _lastAppUse = await Prefs().getLastAppUse();

    final String restoredBrowser = await Prefs().getDefaultBrowser();
    switch (restoredBrowser) {
      case 'app':
        _currentBrowser = BrowserSetting.app;
      case 'external':
        _currentBrowser = BrowserSetting.external;
    }

    _disableTravelSection = await Prefs().getDisableTravelSection();

    _testBrowserActive = await Prefs().getTestBrowserActive();

    _restoreSessionCookie = await Prefs().getRestoreSessionCookie();
    _webviewCacheEnabled = await Prefs().getWebviewCacheEnabled();

    _androidBrowserScale = await Prefs().getAndroidBrowserScale();
    _androidBrowserTextScale = await Prefs().getAndroidBrowserTextScale();

    _iosBrowserPinch = await Prefs().getIosBrowserPinch();
    _iosDisallowOverscroll = await Prefs().getIosDisallowOverscroll();

    _loadBarBrowser = await Prefs().getLoadBarBrowser();

    _useTabsFullBrowser = await Prefs().getUseTabsFullBrowser();
    _useTabsHideFeature = await Prefs().getUseTabsHideFeature();
    _tabsHideBarColor = await Prefs().getTabsHideBarColor();
    _fullScreenRemovesWidgets = await Prefs().getFullScreenRemovesWidgets();
    _fullScreenRemovesChat = await Prefs().getFullScreenRemovesChat();
    _fullScreenExtraCloseButton = await Prefs().getFullScreenExtraCloseButton();
    _fullScreenExtraReloadButton = await Prefs().getFullScreenExtraReloadButton();
    _fullScreenOverNotch = await Prefs().getFullScreenOverNotch();
    _fullScreenOverBottom = await Prefs().getFullScreenOverBottom();
    _fullScreenOverSides = await Prefs().getFullScreenOverSides();
    _fullScreenByShortTap = await Prefs().getFullScreenByShortTap();
    _fullScreenByLongTap = await Prefs().getFullScreenByLongTap();
    _fullScreenByNotificationTap = await Prefs().getFullScreenByNotificationTap();
    _fullScreenByDeepLinkTap = await Prefs().getFullScreenByDeepLinkTap();
    _fullScreenByQuickItemTap = await Prefs().getFullScreenByQuickItemTap();
    _fullScreenIncludesPDAButtonTap = await Prefs().getFullScreenIncludesPDAButtonTap();

    final refresh = await Prefs().getBrowserRefreshMethod();
    switch (refresh) {
      case "icon":
        _browserRefreshMethod = BrowserRefreshSetting.icon;
      case "pull":
        _browserRefreshMethod = BrowserRefreshSetting.pull;
      case "both":
        _browserRefreshMethod = BrowserRefreshSetting.both;
    }

    _onBackButtonAppExit = await Prefs().getOnBackButtonAppExit();

    _chatRemoveEnabled = await Prefs().getChatRemovalEnabled();

    _highlightChat = await Prefs().getHighlightChat();
    _highlightColor = await Prefs().getHighlightColor();
    _highlightWordList = await Prefs().getHighlightWordList();

    _removeAirplane = await Prefs().getRemoveAirplane();

    _extraPlayerInformation = await Prefs().getExtraPlayerInformation();

    _tscEnabledStatus = await Prefs().getTSCEnabledStatus();

    //_profileStatsEnabled = await Prefs().getProfileStatsEnabled();

    final savedFriendlyFactions = await Prefs().getFriendlyFactions();
    if (savedFriendlyFactions.isNotEmpty) {
      final decoded = json.decode(savedFriendlyFactions);
      for (final dec in decoded) {
        _friendlyFactions.add(FriendlyFaction.fromJson(dec));
      }
    }

    _extraPlayerNetworth = await Prefs().getExtraPlayerNetworth();

    _hitInMiniProfileOpensNewTab = await Prefs().getHitInMiniProfileOpensNewTab();
    _hitInMiniProfileOpensNewTabAndChangeTab = await Prefs().getHitInMiniProfileOpensNewTabAndChangeTab();

    _removeNotificationsOnLaunch = await Prefs().getRemoveNotificationsOnLaunch();

    final String restoredTimeFormat = await Prefs().getDefaultTimeFormat();
    switch (restoredTimeFormat) {
      case '24':
        _currentTimeFormat = TimeFormatSetting.h24;
      case '12':
        _currentTimeFormat = TimeFormatSetting.h12;
    }

    final String restoredTimeZone = await Prefs().getDefaultTimeZone();
    switch (restoredTimeZone) {
      case 'local':
        _currentTimeZone = TimeZoneSetting.localTime;
      case 'torn':
        _currentTimeZone = TimeZoneSetting.tornTime;
    }

    final String naturalNerveBarSource = await Prefs().getNaturalNerveBarSource();
    if (naturalNerveBarSource == "yata") {
      _naturalNerveBarSource = NaturalNerveBarSource.yata;
    } else if (naturalNerveBarSource == "tornstats") {
      _naturalNerveBarSource = NaturalNerveBarSource.tornStats;
    } else {
      _naturalNerveBarSource = NaturalNerveBarSource.off;
    }

    _discreteNotifications = await Prefs().getDiscreteNotifications();

    _showDateInClock = await Prefs().getShowDateInClock();
    _showSecondsInClock = await Prefs().getShowSecondsInClock();

    final String restoredAppBar = await Prefs().getAppBarPosition();
    restoredAppBar == 'top' ? _appBarTop = true : _appBarTop = false;

    _oCrimesEnabled = await Prefs().getOCrimesEnabled();
    _oCrimeDisregarded = await Prefs().getOCrimeDisregarded();
    _oCrimeLastKnown = await Prefs().getOCrimeLastKnown();

    _allowScreenRotation = await Prefs().getAllowScreenRotation();

    _lifeBarOption = await Prefs().getLifeBarOption();

    _colorCodedStatusCard = await Prefs().getColorCodedStatusCard();

    _iosAllowLinkPreview = await Prefs().getIosAllowLinkPreview();

    _warnAboutExcessEnergy = await Prefs().getWarnAboutExcessEnergy();
    _warnAboutExcessEnergyThreshold = await Prefs().getWarnAboutExcessEnergyThreshold();
    _warnAboutChains = await Prefs().getWarnAboutChains();

    _terminalEnabled = await Prefs().getTerminalEnabled();

    _rankedWarsInMenu = await Prefs().getRankedWarsInMenu();
    _rankedWarsInProfile = await Prefs().getRankedWarsInProfile();
    _rankedWarsInProfileShowTotalHours = await Prefs().getRankedWarsInProfileShowTotalHours();

    _stockExchangeInMenu = await Prefs().getStockExchangeInMenu();

    _iconsFiltered = await Prefs().getIconsFiltered();

    _showCases = await Prefs().getShowCases();

    final String ticket = await Prefs().getTravelTicket();
    switch (ticket) {
      case "standard":
        _travelTicket = TravelTicket.standard;
      case "private":
        _travelTicket = TravelTicket.private;
      case "wlt":
        _travelTicket = TravelTicket.wlt;
      case "business":
        _travelTicket = TravelTicket.business;
    }

    _foreignStocksDataProvider = await Prefs().getForeignStocksDataProvider();

    _targetSkippingAll = await Prefs().getTargetSkippingAll();
    _targetSkippingFirst = await Prefs().getTargetSkippingFirst();

    _tornStatsChartDateTime = await Prefs().getTornStatsChartDateTime();
    _tornStatsChartEnabled = await Prefs().getTornStatsChartEnabled();
    _tornStatsChartType = await Prefs().getTornStatsChartType();
    _tornStatsChartInCollapsedMiscCard = await Prefs().getTornStatsChartInCollapsedMiscCard();

    _retaliationSectionEnabled = await Prefs().getRetaliationSectionEnabled();
    _singleRetaliationOpensBrowser = await Prefs().getSingleRetaliationOpensBrowser();

    _syncTornWebTheme = await Prefs().getSyncTornWebTheme();
    _syncDeviceTheme = await Prefs().getSyncDeviceTheme();
    _darkThemeToSync = await Prefs().getDarkThemeToSync();

    _debugMessages = await Prefs().getDebugMessages();

    _shortcutsEnabledProfile = await Prefs().getShortcutsEnabledProfile();

    _appwidgetDarkMode = await Prefs().getAppwidgetDarkMode();
    _appwidgetMoneyEnabled = await Prefs().getAppwidgetMoneyEnabled();

    _exactPermissionDialogShownAndroid = await Prefs().getExactPermissionDialogShownAndroid();

    _downloadActionShare = await Prefs().getDownloadActionShare();

    notifyListeners();
  }
}
