// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:torn_pda/models/faction/friendly_faction_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

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
  int lastAppUse;

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

  var _clearCacheNextOpportunity = false;
  bool get clearCacheNextOpportunity {
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

  void updateLastUsed(int timeStamp) {
    Prefs().setLastAppUse(timeStamp);
    lastAppUse = timeStamp;
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    lastAppUse = await Prefs().getLastAppUse();

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

    _clearCacheNextOpportunity = await Prefs().getClearBrowserCacheNextOpportunity();

    _loadBarBrowser = await Prefs().getLoadBarBrowser();

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

    String restoredAppBar = await Prefs().getAppBarPosition();
    restoredAppBar == 'top' ? _appBarTop = true : _appBarTop = false;

    _oCrimesEnabled = await Prefs().getOCrimesEnabled();
    _oCrimeDisregarded = await Prefs().getOCrimeDisregarded();
    _oCrimeLastKnown = await Prefs().getOCrimeLastKnown();

    _allowScreenRotation = await Prefs().getAllowScreenRotation();

    _lifeBarOption = await Prefs().getLifeBarOption();

    _iosAllowLinkPreview = await Prefs().getIosAllowLinkPreview();

    notifyListeners();
  }
}
