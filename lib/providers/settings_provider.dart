// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:torn_pda/models/faction/friendly_faction_model.dart';
import 'package:torn_pda/models/oc/ts_members_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';
import 'package:torn_pda/widgets/other/profile_check.dart';

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
  var _currentBrowser = BrowserSetting.app;
  BrowserSetting get currentBrowser => _currentBrowser;
  set changeBrowser(BrowserSetting browserType) {
    _currentBrowser = browserType;

    // SHARED PREFS
    String browserSave;
    switch (_currentBrowser) {
      case BrowserSetting.app:
        browserSave = 'app';
        break;
      case BrowserSetting.external:
        browserSave = 'external';
        break;
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

  var _clearCacheNextOpportunity = false;
  bool get getClearCacheNextOpportunityAndReset {
    if (_clearCacheNextOpportunity) {
      setClearCacheNextOpportunity = false;
      return true;
    } else {
      return false;
    }
  }

  set setClearCacheNextOpportunity(bool active) {
    _clearCacheNextOpportunity = active;
    Prefs().setClearBrowserCacheNextOpportunity(_clearCacheNextOpportunity);
  }

  var _androidBrowserScale = 0;
  int get androidBrowserScale => _androidBrowserScale;
  set setAndroidBrowserScale(int scale) {
    _androidBrowserScale = scale;
    Prefs().setAndroidBrowserScale(_androidBrowserScale);
  }

  var _iosBrowserPinch = false;
  bool get iosBrowserPinch => _iosBrowserPinch;
  set setIosBrowserPinch(bool pinch) {
    _iosBrowserPinch = pinch;
    Prefs().setIosBrowserPinch(_iosBrowserPinch);
  }

  var _disableTravelSection = false;
  bool get disableTravelSection => _disableTravelSection;
  set changeDisableTravelSection(bool disable) {
    _disableTravelSection = disable;
    Prefs().setDisableTravelSection(_disableTravelSection);
    notifyListeners();
  }

  var _onAppExit = 'ask';
  String get onAppExit => _onAppExit;
  set changeOnAppExit(String choice) {
    _onAppExit = choice;
    Prefs().setOnAppExit(_onAppExit);
    notifyListeners();
  }

  var _currentTimeFormat = TimeFormatSetting.h24;
  TimeFormatSetting get currentTimeFormat => _currentTimeFormat;
  set changeTimeFormat(TimeFormatSetting timeFormatSetting) {
    _currentTimeFormat = timeFormatSetting;

    // SHARED PREFS
    String timeFormatSave;
    switch (_currentTimeFormat) {
      case TimeFormatSetting.h24:
        timeFormatSave = '24';
        break;
      case TimeFormatSetting.h12:
        timeFormatSave = '12';
        break;
    }
    Prefs().setDefaultTimeFormat(timeFormatSave);

    notifyListeners();
  }

  var _currentTimeZone = TimeZoneSetting.localTime;
  TimeZoneSetting get currentTimeZone => _currentTimeZone;
  set changeTimeZone(TimeZoneSetting timeZoneSetting) {
    _currentTimeZone = timeZoneSetting;
    // SHARED PREFS
    String timeZoneSave;
    switch (_currentTimeZone) {
      case TimeZoneSetting.localTime:
        timeZoneSave = 'local';
        break;
      case TimeZoneSetting.tornTime:
        timeZoneSave = 'torn';
        break;
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

  SpiesSource _spiesSource = SpiesSource.yata;
  SpiesSource get spiesSource => _spiesSource;
  set changeSpiesSource(SpiesSource value) {
    _spiesSource = value;
    _spiesSource == SpiesSource.yata ? Prefs().setSpiesSource('yata') : Prefs().setSpiesSource('tornstats');
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

  var _browserRefreshMethod = BrowserRefreshSetting.both;
  BrowserRefreshSetting get browserRefreshMethod => _browserRefreshMethod;
  set changeBrowserRefreshMethod(BrowserRefreshSetting value) {
    _browserRefreshMethod = value;
    switch (value) {
      case BrowserRefreshSetting.icon:
        Prefs().setBrowserRefreshMethod("icon");
        break;
      case BrowserRefreshSetting.pull:
        Prefs().setBrowserRefreshMethod("pull");
        break;
      case BrowserRefreshSetting.both:
        Prefs().setBrowserRefreshMethod("both");
        break;
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

  var _useTabsBrowserDialog = true;
  bool get useTabsBrowserDialog => _useTabsBrowserDialog;
  set changeUseTabsBrowserDialog(bool value) {
    _useTabsBrowserDialog = value;
    Prefs().setUseTabsBrowserDialog(_useTabsBrowserDialog);
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

  var _highlightColor = 0x66b74093;
  int get highlightColor => _highlightColor;
  set changeHighlightColor(int value) {
    _highlightColor = value;
    Prefs().setHighlightColor(_highlightColor);
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

  var _profileStatsEnabled = "0";
  String get profileStatsEnabled => _profileStatsEnabled;
  set changeProfileStatsEnabled(String value) {
    _profileStatsEnabled = value;
    Prefs().setProfileStatsEnabled(_profileStatsEnabled);
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

  var _useQuickBrowser = true;
  bool get useQuickBrowser => _useQuickBrowser;
  set changeUseQuickBrowser(bool value) {
    _useQuickBrowser = value;
    Prefs().setUseQuickBrowser(_useQuickBrowser);
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

  var _lifeBarOption = 'ask';
  String get lifeBarOption => _lifeBarOption;
  set changeLifeBarOption(String choice) {
    _lifeBarOption = choice;
    Prefs().setLifeBarOption(_lifeBarOption);
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

  var _stockExchangeInMenu = false;
  bool get stockExchangeInMenu => _stockExchangeInMenu;
  set changeStockExchangeInMenu(bool choice) {
    _stockExchangeInMenu = choice;
    Prefs().setStockExchangeInMenu(_stockExchangeInMenu);
    notifyListeners();
  }

  var _iconsFiltered = [];
  List<String> get iconsFiltered => _iconsFiltered;
  set changeIconsFiltered(List<String> icons) {
    _iconsFiltered = icons;
    Prefs().setIconsFiltered(_iconsFiltered);
    notifyListeners();
  }

  var _showCases = [];
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

  var _travelTicket = TravelTicket.private;
  TravelTicket get travelTicket => _travelTicket;
  set changeTravelTicket(TravelTicket ticket) {
    _travelTicket = ticket;
    String ticketString = "private";
    switch (ticket) {
      case TravelTicket.standard:
        ticketString = "standard";
        break;
      case TravelTicket.private:
        ticketString = "private";
        break;
      case TravelTicket.wlt:
        ticketString = "wlt";
        break;
      case TravelTicket.business:
        ticketString = "business";
        break;
    }
    Prefs().setTravelTicket(ticketString);
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

  var _syncTheme = true;
  bool get syncTheme => _syncTheme;
  set syncTheme(bool value) {
    _syncTheme = value;
    Prefs().setSyncTheme(_syncTheme);
    notifyListeners();
  }

  var _themeToSync = "dark";
  String get darkThemeToSyncFromWeb => _themeToSync;
  set darkThemeToSyncFromWeb(String value) {
    _themeToSync = value;
    Prefs().setThemeToSync(value);
    notifyListeners();
  }

  var _debugMessages = false;
  bool get debugMessages => _debugMessages;
  set debugMessages(bool value) {
    _debugMessages = value;
    Prefs().setDebugMessages(_debugMessages);
    notifyListeners();
  }

  var _showFavoritesInTabBar = true;
  bool get showFavoritesInTabBar => _showFavoritesInTabBar;
  set showFavoritesInTabBar(bool value) {
    _showFavoritesInTabBar = value;
    Prefs().setShowFavoritesInTabBar(_showFavoritesInTabBar);
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    _lastAppUse = await Prefs().getLastAppUse();

    String restoredBrowser = await Prefs().getDefaultBrowser();
    switch (restoredBrowser) {
      case 'app':
        _currentBrowser = BrowserSetting.app;
        break;
      case 'external':
        _currentBrowser = BrowserSetting.external;
        break;
    }

    _disableTravelSection = await Prefs().getDisableTravelSection();

    _testBrowserActive = await Prefs().getTestBrowserActive();

    _restoreSessionCookie = await Prefs().getRestoreSessionCookie();
    _clearCacheNextOpportunity = await Prefs().getClearBrowserCacheNextOpportunity();

    _androidBrowserScale = await Prefs().getAndroidBrowserScale();

    _iosBrowserPinch = await Prefs().getIosBrowserPinch();

    _loadBarBrowser = await Prefs().getLoadBarBrowser();

    _useTabsFullBrowser = await Prefs().getUseTabsFullBrowser();
    _useTabsBrowserDialog = await Prefs().getUseTabsBrowserDialog();
    _useTabsHideFeature = await Prefs().getUseTabsHideFeature();
    _tabsHideBarColor = await Prefs().getTabsHideBarColor();

    var refresh = await Prefs().getBrowserRefreshMethod();
    switch (refresh) {
      case "icon":
        _browserRefreshMethod = BrowserRefreshSetting.icon;
        break;
      case "pull":
        _browserRefreshMethod = BrowserRefreshSetting.pull;
        break;
      case "both":
        _browserRefreshMethod = BrowserRefreshSetting.both;
        break;
    }

    _onAppExit = await Prefs().getOnAppExit();

    _chatRemoveEnabled = await Prefs().getChatRemovalEnabled();

    _highlightChat = await Prefs().getHighlightChat();
    _highlightColor = await Prefs().getHighlightColor();

    _removeAirplane = await Prefs().getRemoveAirplane();

    _extraPlayerInformation = await Prefs().getExtraPlayerInformation();

    _profileStatsEnabled = await Prefs().getProfileStatsEnabled();

    var savedFriendlyFactions = await Prefs().getFriendlyFactions();
    if (savedFriendlyFactions.isNotEmpty) {
      var decoded = json.decode(savedFriendlyFactions);
      for (var dec in decoded) {
        _friendlyFactions.add(FriendlyFaction.fromJson(dec));
      }
    }

    _extraPlayerNetworth = await Prefs().getExtraPlayerNetworth();

    _useQuickBrowser = await Prefs().getUseQuickBrowser();

    _removeNotificationsOnLaunch = await Prefs().getRemoveNotificationsOnLaunch();

    String restoredTimeFormat = await Prefs().getDefaultTimeFormat();
    switch (restoredTimeFormat) {
      case '24':
        _currentTimeFormat = TimeFormatSetting.h24;
        break;
      case '12':
        _currentTimeFormat = TimeFormatSetting.h12;
        break;
    }

    String restoredTimeZone = await Prefs().getDefaultTimeZone();
    switch (restoredTimeZone) {
      case 'local':
        _currentTimeZone = TimeZoneSetting.localTime;
        break;
      case 'torn':
        _currentTimeZone = TimeZoneSetting.tornTime;
        break;
    }

    String spiesSourceSaved = await Prefs().getSpiesSource();
    if (spiesSourceSaved == "yata") {
      _spiesSource = SpiesSource.yata;
    } else {
      _spiesSource = SpiesSource.tornStats;
    }

    _discreteNotifications = await Prefs().getDiscreteNotifications();

    _showDateInClock = await Prefs().getShowDateInClock();
    _showSecondsInClock = await Prefs().getShowSecondsInClock();

    String restoredAppBar = await Prefs().getAppBarPosition();
    restoredAppBar == 'top' ? _appBarTop = true : _appBarTop = false;

    _oCrimesEnabled = await Prefs().getOCrimesEnabled();
    _oCrimeDisregarded = await Prefs().getOCrimeDisregarded();
    _oCrimeLastKnown = await Prefs().getOCrimeLastKnown();

    _allowScreenRotation = await Prefs().getAllowScreenRotation();

    _lifeBarOption = await Prefs().getLifeBarOption();

    _iosAllowLinkPreview = await Prefs().getIosAllowLinkPreview();

    _warnAboutExcessEnergy = await Prefs().getWarnAboutExcessEnergy();
    _warnAboutExcessEnergyThreshold = await Prefs().getWarnAboutExcessEnergyThreshold();
    _warnAboutChains = await Prefs().getWarnAboutChains();

    _terminalEnabled = await Prefs().getTerminalEnabled();

    _rankedWarsInMenu = await Prefs().getRankedWarsInMenu();

    _stockExchangeInMenu = await Prefs().getStockExchangeInMenu();

    _iconsFiltered = await Prefs().getIconsFiltered();

    _showCases = await Prefs().getShowCases();

    String ticket = await Prefs().getTravelTicket();
    switch (ticket) {
      case "standard":
        _travelTicket = TravelTicket.standard;
        break;
      case "private":
        _travelTicket = TravelTicket.private;
        break;
      case "wlt":
        _travelTicket = TravelTicket.wlt;
        break;
      case "business":
        _travelTicket = TravelTicket.business;
        break;
    }

    _targetSkippingAll = await Prefs().getTargetSkippingAll();
    _targetSkippingFirst = await Prefs().getTargetSkippingFirst();

    _tornStatsChartDateTime = await Prefs().getTornStatsChartDateTime();
    _tornStatsChartEnabled = await Prefs().getTornStatsChartEnabled();
    _tornStatsChartInCollapsedMiscCard = await Prefs().getTornStatsChartInCollapsedMiscCard();

    _retaliationSectionEnabled = await Prefs().getRetaliationSectionEnabled();
    _singleRetaliationOpensBrowser = await Prefs().getSingleRetaliationOpensBrowser();

    _syncTheme = await Prefs().getSyncTheme();
    _themeToSync = await Prefs().getThemeToSync();

    _debugMessages = await Prefs().getDebugMessages();

    _showFavoritesInTabBar = await Prefs().getShowFavoritesInTabBar();

    notifyListeners();
  }
}
