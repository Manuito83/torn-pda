import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/models/faction/friendly_faction_model.dart';

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
    SharedPreferencesModel().setDefaultBrowser(browserSave);

    notifyListeners();
  }

  var _testBrowserActive = false;
  bool get testBrowserActive => _testBrowserActive;
  set changeTestBrowserActive(bool active) {
    _testBrowserActive = active;
    SharedPreferencesModel().setTestBrowserActive(_testBrowserActive);
    notifyListeners();
  }

  var _disableTravelSection = false;
  bool get disableTravelSection => _disableTravelSection;
  set changeDisableTravelSection(bool disable) {
    _disableTravelSection = disable;
    SharedPreferencesModel().setDisableTravelSection(_disableTravelSection);
    notifyListeners();
  }

  var _onAppExit = 'ask';
  String get onAppExit => _onAppExit;
  set changeOnAppExit(String choice) {
    _onAppExit = choice;
    SharedPreferencesModel().setOnAppExit(_onAppExit);
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
    SharedPreferencesModel().setDefaultTimeFormat(timeFormatSave);

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
    SharedPreferencesModel().setDefaultTimeZone(timeZoneSave);

    notifyListeners();
  }

  var _appBarTop = true;
  bool get appBarTop => _appBarTop;
  set changeAppBarTop(bool value) {
    _appBarTop = value;

    _appBarTop
        ? SharedPreferencesModel().setAppBarPosition('top')
        : SharedPreferencesModel().setAppBarPosition('bottom');

    notifyListeners();
  }

  var _loadBarBrowser = true;
  bool get loadBarBrowser => _loadBarBrowser;
  set changeLoadBarBrowser(bool value) {
    _loadBarBrowser = value;
    SharedPreferencesModel().setLoadBarBrowser(_loadBarBrowser);
    notifyListeners();
  }

  var _chatRemoveEnabled = true;
  bool get chatRemoveEnabled => _chatRemoveEnabled;
  set changeChatRemoveEnabled(bool value) {
    _chatRemoveEnabled = value;
    SharedPreferencesModel().setChatRemovalEnabled(_chatRemoveEnabled);
    notifyListeners();
  }

  var _highlightChat = true;
  bool get highlightChat => _highlightChat;
  set changeHighlightChat(bool value) {
    _highlightChat = value;
    SharedPreferencesModel().setHighlightChat(_highlightChat);
    notifyListeners();
  }

  var _highlightColor = 0x66b74093;
  int get highlightColor => _highlightColor;
  set changeHighlightColor(int value) {
    _highlightColor = value;
    SharedPreferencesModel().setHighlightColor(_highlightColor);
    notifyListeners();
  }

  var _removeAirplane = false;
  bool get removeAirplane => _removeAirplane;
  set changeRemoveAirplane(bool value) {
    _removeAirplane = value;
    SharedPreferencesModel().setRemoveAirplane(_removeAirplane);
    notifyListeners();
  }

  var _extraPlayerInformation = false;
  bool get extraPlayerInformation => _extraPlayerInformation;
  set changeExtraPlayerInformation(bool value) {
    _extraPlayerInformation = value;
    SharedPreferencesModel().setExtraPlayerInformation(_extraPlayerInformation);
    notifyListeners();
  }

  var _friendlyFactions = <FriendlyFaction>[];
  List<FriendlyFaction> get friendlyFactions => _friendlyFactions;
  set setFriendlyFactions(List<FriendlyFaction> faction) {
    _friendlyFactions = faction;
    SharedPreferencesModel().setFriendlyFactions(json.encode(_friendlyFactions));
    notifyListeners();
  }

  var _useQuickBrowser = true;
  bool get useQuickBrowser => _useQuickBrowser;
  set changeUseQuickBrowser(bool value) {
    _useQuickBrowser = value;
    SharedPreferencesModel().setUseQuickBrowser(_useQuickBrowser);
    notifyListeners();
  }

  var _removeNotificationsOnLaunch = true;
  bool get removeNotificationsOnLaunch => _removeNotificationsOnLaunch;
  set changeRemoveNotificationsOnLaunch(bool value) {
    _removeNotificationsOnLaunch = value;
    SharedPreferencesModel().setRemoveNotificationsOnLaunch(_removeNotificationsOnLaunch);
    notifyListeners();
  }

  void updateLastUsed(int timeStamp) {
    SharedPreferencesModel().setLastAppUse(timeStamp);
    lastAppUse = timeStamp;
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    lastAppUse = await SharedPreferencesModel().getLastAppUse();

    String restoredBrowser = await SharedPreferencesModel().getDefaultBrowser();
    switch (restoredBrowser) {
      case 'app':
        _currentBrowser = BrowserSetting.app;
        break;
      case 'external':
        _currentBrowser = BrowserSetting.external;
        break;
    }

    _disableTravelSection = await SharedPreferencesModel().getDisableTravelSection();

    _testBrowserActive = await SharedPreferencesModel().getTestBrowserActive();

    _loadBarBrowser = await SharedPreferencesModel().getLoadBarBrowser();

    _onAppExit = await SharedPreferencesModel().getOnAppExit();

    _chatRemoveEnabled = await SharedPreferencesModel().getChatRemovalEnabled();

    _highlightChat = await SharedPreferencesModel().getHighlightChat();
    _highlightColor = await SharedPreferencesModel().getHighlightColor();

    _removeAirplane = await SharedPreferencesModel().getRemoveAirplane();

    _extraPlayerInformation = await SharedPreferencesModel().getExtraPlayerInformation();

    var savedFriendlyFactions = await SharedPreferencesModel().getFriendlyFactions();
    var decoded = json.decode(savedFriendlyFactions);
    for (var dec in decoded) {
      _friendlyFactions.add(FriendlyFaction.fromJson(dec));
    }

    _useQuickBrowser = await SharedPreferencesModel().getUseQuickBrowser();

    _removeNotificationsOnLaunch = await SharedPreferencesModel().getRemoveNotificationsOnLaunch();

    String restoredTimeFormat = await SharedPreferencesModel().getDefaultTimeFormat();
    switch (restoredTimeFormat) {
      case '24':
        _currentTimeFormat = TimeFormatSetting.h24;
        break;
      case '12':
        _currentTimeFormat = TimeFormatSetting.h12;
        break;
    }

    String restoredTimeZone = await SharedPreferencesModel().getDefaultTimeZone();
    switch (restoredTimeZone) {
      case 'local':
        _currentTimeZone = TimeZoneSetting.localTime;
        break;
      case 'torn':
        _currentTimeZone = TimeZoneSetting.tornTime;
        break;
    }

    String restoredAppBar = await SharedPreferencesModel().getAppBarPosition();
    restoredAppBar == 'top' ? _appBarTop = true : _appBarTop = false;

    notifyListeners();
  }
}
