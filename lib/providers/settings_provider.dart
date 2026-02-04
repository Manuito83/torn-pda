// Dart imports:
// ignore_for_file: strict_top_level_inference

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:get/get.dart';
import 'package:torn_pda/config/webview_config.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';

// Project imports:
import 'package:torn_pda/models/faction/friendly_faction_model.dart';
import 'package:torn_pda/models/oc/ts_members_model.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
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

class PdaUpdateDetails {
  final int latestVersionCode;
  final String latestVersionName;
  final bool isIosUpdate;
  final bool isAndroidUpdate;
  final List<String> changelog;

  PdaUpdateDetails({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.isIosUpdate,
    required this.isAndroidUpdate,
    required this.changelog,
  });

  factory PdaUpdateDetails.fromJson(Map<String, dynamic> json) {
    return PdaUpdateDetails(
      latestVersionCode: json['latest_version_code'] ?? 0,
      latestVersionName: json['latest_version_name'] ?? '',
      isIosUpdate: json['isIosUpdate'] ?? false,
      isAndroidUpdate: json['isAndroidUpdate'] ?? false,
      changelog: List<String>.from(json['changelog'] ?? []),
    );
  }

  static PdaUpdateDetails? fromJsonString(String jsonString) {
    if (jsonString.isEmpty) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return PdaUpdateDetails.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  StreamController willPopShouldOpenDrawerStream = StreamController.broadcast();
  StreamController willPopShouldGoBackStream = StreamController.broadcast();

  final FlutterRefreshRateControl _refreshRateControl = FlutterRefreshRateControl();

  String deviceBrand = "";
  String deviceModel = "";
  String deviceSoftware = "";

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

  var _webviewCacheEnabledRemoteConfig = "user";
  String get webviewCacheEnabledRemoteConfig => _webviewCacheEnabledRemoteConfig;
  set webviewCacheEnabledRemoteConfig(String enabled) {
    _webviewCacheEnabledRemoteConfig = enabled;
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

  var _browserReverseNavigationSwipe = false;
  bool get browserReverseNavitagtionSwipe => _browserReverseNavigationSwipe;
  set browserReverseNavigationSwipe(bool value) {
    _browserReverseNavigationSwipe = value;
    Prefs().setBrowserReverseNavigationSwipe(_browserReverseNavigationSwipe);
    notifyListeners();
  }

  bool _browserCenterEditingTextField = true;
  bool get browserCenterEditingTextField => _browserCenterEditingTextField;
  set browserCenterEditingTextField(bool value) {
    _browserCenterEditingTextField = value;
    Prefs().setBrowserCenterEditingTextField(_browserCenterEditingTextField);
    notifyListeners();
  }

  bool _browserExtendHeightForKeyboard = false;
  bool get browserExtendHeightForKeyboard => _browserExtendHeightForKeyboard;
  set browserExtendHeightForKeyboard(bool value) {
    _browserExtendHeightForKeyboard = value;
    Prefs().setBrowserExtendHeightForKeyboard(_browserExtendHeightForKeyboard);
    notifyListeners();
  }

  bool _browserExtendHeightForKeyboardRemoteConfigAllowed = true;
  bool get browserExtendHeightForKeyboardRemoteConfigAllowed => _browserExtendHeightForKeyboardRemoteConfigAllowed;
  set browserExtendHeightForKeyboardRemoteConfigAllowed(bool value) {
    _browserExtendHeightForKeyboardRemoteConfigAllowed = value;
    notifyListeners();
  }

  bool _browserCenterEditingTextFieldRemoteConfigAllowed = true;
  bool get browserCenterEditingTextFieldRemoteConfigAllowed => _browserCenterEditingTextFieldRemoteConfigAllowed;
  set browserCenterEditingTextFieldRemoteConfigAllowed(bool value) {
    _browserCenterEditingTextFieldRemoteConfigAllowed = value;
    notifyListeners();
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

  var _discreetNotifications = false;
  bool get discreetNotifications => _discreetNotifications;
  set discreetNotifications(bool value) {
    _discreetNotifications = value;
    Prefs().setDiscreetNotifications(value);
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

  String _browserShowNavArrowsAppbar = "wide";
  String get browserShowNavArrowsAppbar => _browserShowNavArrowsAppbar;
  set browserShowNavArrowsAppbar(String value) {
    _browserShowNavArrowsAppbar = value;
    Prefs().setBrowserShowNavArrowsAppbar(value);
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

  var _showTabLockWarnings = true;
  bool get showTabLockWarnings => _showTabLockWarnings;
  set showTabLockWarnings(bool value) {
    _showTabLockWarnings = value;
    Prefs().setShowTabLockWarnings(_showTabLockWarnings);
    notifyListeners();
  }

  var _fullLockNavigationAttemptOpensNewTab = false;
  bool get fullLockNavigationAttemptOpensNewTab => _fullLockNavigationAttemptOpensNewTab;
  set fullLockNavigationAttemptOpensNewTab(bool value) {
    _fullLockNavigationAttemptOpensNewTab = value;
    Prefs().setFullLockNavigationAttemptOpensNewTab(_fullLockNavigationAttemptOpensNewTab);
    notifyListeners();
  }

  List<List<String>> _lockedTabsNavigationExceptions = [];
  List<List<String>> get lockedTabsNavigationExceptions => _lockedTabsNavigationExceptions;
  void addLockedTabNavigationException(String url1, String url2) {
    _lockedTabsNavigationExceptions.add([url1, url2]);
    Prefs().setLockedTabsNavigationExceptions(json.encode(_lockedTabsNavigationExceptions));
    notifyListeners();
  }

  void removeLockedTabNavigationException(int index) {
    _lockedTabsNavigationExceptions.removeAt(index);
    Prefs().setLockedTabsNavigationExceptions(json.encode(_lockedTabsNavigationExceptions));
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

  var _fullScreenByShortChainingTap = false;
  bool get fullScreenByShortChainingTap => _fullScreenByShortChainingTap;
  set fullScreenByShortChainingTap(bool value) {
    _fullScreenByShortChainingTap = value;
    Prefs().setFullScreenByShortChainingTap(_fullScreenByShortChainingTap);
    notifyListeners();
  }

  var _fullScreenByLongChainingTap = false;
  bool get fullScreenByLongChainingTap => _fullScreenByLongChainingTap;
  set fullScreenByLongChainingTap(bool value) {
    _fullScreenByLongChainingTap = value;
    Prefs().setFullScreenByLongChainingTap(_fullScreenByLongChainingTap);
    notifyListeners();
  }

  var _lifeNotificationTapAction = "ownItems";
  String get lifeNotificationTapAction => _lifeNotificationTapAction;
  set lifeNotificationTapAction(value) {
    _lifeNotificationTapAction = value;
    Prefs().setLifeNotificationTapAction(_lifeNotificationTapAction);
    notifyListeners();
  }

  var _drugsNotificationTapAction = "ownItems";
  String get drugsNotificationTapAction => _drugsNotificationTapAction;
  set drugsNotificationTapAction(value) {
    _drugsNotificationTapAction = value;
    Prefs().setDrugsNotificationTapAction(_drugsNotificationTapAction);
    notifyListeners();
  }

  var _medicalNotificationTapAction = "ownItems";
  String get medicalNotificationTapAction => _medicalNotificationTapAction;
  set medicalNotificationTapAction(value) {
    _medicalNotificationTapAction = value;
    Prefs().setMedicalNotificationTapAction(_medicalNotificationTapAction);
    notifyListeners();
  }

  var _boosterNotificationTapAction = "ownItems";
  String get boosterNotificationTapAction => _boosterNotificationTapAction;
  set boosterNotificationTapAction(value) {
    _boosterNotificationTapAction = value;
    Prefs().setBoosterNotificationTapAction(_boosterNotificationTapAction);
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

  var _removeForeignItemsDetails = false;
  bool get removeForeignItemsDetails => _removeForeignItemsDetails;
  set removeForeignItemsDetails(bool value) {
    _removeForeignItemsDetails = value;
    Prefs().setRemoveForeignItemsDetails(_removeForeignItemsDetails);
    notifyListeners();
  }

  var _preventBasketKeyboard = true;
  bool get preventBasketKeyboard => _preventBasketKeyboard;
  set preventBasketKeyboard(bool value) {
    _preventBasketKeyboard = value;
    Prefs().setPreventBasketKeyboard(_preventBasketKeyboard);
    notifyListeners();
  }

  var _removeTravelQuickReturnButton = false;
  bool get removeTravelQuickReturnButton => _removeTravelQuickReturnButton;
  set removeTravelQuickReturnButton(bool value) {
    _removeTravelQuickReturnButton = value;
    Prefs().setRemoveTravelQuickReturnButton(_removeTravelQuickReturnButton);
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

  List<String> _shareAttackOptions = [];
  List<String> get shareOptions => _shareAttackOptions;
  set shareOptions(List<String> value) {
    _shareAttackOptions = value;
    Prefs().setShareAttackOptions(_shareAttackOptions);
    notifyListeners();
  }

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

  int _yataStatsEnabledStatus = 0;
  int get yataStatsEnabledStatus => _yataStatsEnabledStatus;
  set yataStatsEnabledStatus(int value) {
    _yataStatsEnabledStatus = value;
    Prefs().setYataStatsEnabledStatus(_yataStatsEnabledStatus);
    notifyListeners();
  }

  bool _yataStatsEnabledStatusRemoteConfig = true;
  bool get yataStatsEnabledStatusRemoteConfig => _yataStatsEnabledStatusRemoteConfig;
  set yataStatsEnabledStatusRemoteConfig(bool value) {
    _yataStatsEnabledStatusRemoteConfig = value;
    notifyListeners();
  }

  bool _yataUploadEnabledRemoteConfig = true;
  bool get yataUploadEnabledRemoteConfig => _yataUploadEnabledRemoteConfig;
  set yataUploadEnabledRemoteConfig(bool value) {
    _yataUploadEnabledRemoteConfig = value;
    notifyListeners();
  }

  bool _prometheusUploadEnabledRemoteConfig = true;
  bool get prometheusUploadEnabledRemoteConfig => _prometheusUploadEnabledRemoteConfig;
  set prometheusUploadEnabledRemoteConfig(bool value) {
    _prometheusUploadEnabledRemoteConfig = value;
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

  var _notesWidgetEnabledProfile = true;
  bool get notesWidgetEnabledProfile => _notesWidgetEnabledProfile;
  set changeNotesWidgetEnabledProfile(bool value) {
    _notesWidgetEnabledProfile = value;
    Prefs().setNotesWidgetEnabledProfile(_notesWidgetEnabledProfile);
    notifyListeners();
  }

  var _notesWidgetEnabledProfileWhenEmpty = true;
  bool get notesWidgetEnabledProfileWhenEmpty => _notesWidgetEnabledProfileWhenEmpty;
  set changeNotesWidgetEnabledProfileWhenEmpty(bool value) {
    _notesWidgetEnabledProfileWhenEmpty = value;
    Prefs().setNotesWidgetEnabledProfileWhenEmpty(_notesWidgetEnabledProfileWhenEmpty);
    notifyListeners();
  }

  var _joblessWarningEnabled = true;
  bool get joblessWarningEnabled => _joblessWarningEnabled;
  set changeJoblessWarningEnabled(bool value) {
    _joblessWarningEnabled = value;
    Prefs().setJoblessWarningEnabled(_joblessWarningEnabled);
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

  var _showAllRentedOutProperties = true;
  bool get showAllRentedOutProperties => _showAllRentedOutProperties;
  set showAllRentedOutProperties(bool value) {
    _showAllRentedOutProperties = value;
    Prefs().setShowAllRentedOutProperties(_showAllRentedOutProperties);
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

  bool _playerInOCv2 = false;
  bool get playerInOCv2 => _playerInOCv2;
  set playerInOCv2(bool value) {
    _playerInOCv2 = value;
    Prefs().setPlayerInOCv2(value);
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

  var _travelEnergyExcessWarning = true;
  bool get travelEnergyExcessWarning => _travelEnergyExcessWarning;
  set travelEnergyExcessWarning(bool choice) {
    _travelEnergyExcessWarning = choice;
    Prefs().setTravelEnergyExcessWarning(_travelEnergyExcessWarning);
    notifyListeners();
  }

  RangeValues _travelEnergyRangeWarningThreshold = const RangeValues(10, 100);
  RangeValues get travelEnergyRangeWarningThreshold => _travelEnergyRangeWarningThreshold;
  set travelEnergyRangeWarningThreshold(RangeValues range) {
    _travelEnergyRangeWarningThreshold = range;
    Prefs().setTravelEnergyRangeWarningRange(
      _travelEnergyRangeWarningThreshold.start.toInt(),
      _travelEnergyRangeWarningThreshold.end >= 110 ? 110 : _travelEnergyRangeWarningThreshold.end.toInt(),
    );
    notifyListeners();
  }

  var _travelNerveExcessWarning = true;
  bool get travelNerveExcessWarning => _travelNerveExcessWarning;
  set travelNerveExcessWarning(bool choice) {
    _travelNerveExcessWarning = choice;
    Prefs().setTravelNerveExcessWarning(_travelNerveExcessWarning);
    notifyListeners();
  }

  var _travelNerveExcessWarningThreshold = 50;
  int get travelNerveExcessWarningThreshold => _travelNerveExcessWarningThreshold;
  set travelNerveExcessWarningThreshold(int choice) {
    _travelNerveExcessWarningThreshold = choice;
    Prefs().setTravelNerveExcessWarningThreshold(_travelNerveExcessWarningThreshold);
    notifyListeners();
  }

  var _travelLifeExcessWarning = true;
  bool get travelLifeExcessWarning => _travelLifeExcessWarning;
  set travelLifeExcessWarning(bool choice) {
    _travelLifeExcessWarning = choice;
    Prefs().setTravelLifeExcessWarning(_travelLifeExcessWarning);
    notifyListeners();
  }

  var _travelLifeExcessWarningThreshold = 50;
  int get travelLifeExcessWarningThreshold => _travelLifeExcessWarningThreshold;
  set travelLifeExcessWarningThreshold(int choice) {
    _travelLifeExcessWarningThreshold = choice;
    Prefs().setTravelLifeExcessWarningThreshold(_travelLifeExcessWarningThreshold);
    notifyListeners();
  }

  var _travelDrugCooldownWarning = true;
  bool get travelDrugCooldownWarning => _travelDrugCooldownWarning;
  set travelDrugCooldownWarning(bool choice) {
    _travelDrugCooldownWarning = choice;
    Prefs().setTravelDrugCooldownWarning(_travelDrugCooldownWarning);
    notifyListeners();
  }

  var _travelBoosterCooldownWarning = true;
  bool get travelBoosterCooldownWarning => _travelBoosterCooldownWarning;
  set travelBoosterCooldownWarning(bool choice) {
    _travelBoosterCooldownWarning = choice;
    Prefs().setTravelBoosterCooldownWarning(_travelBoosterCooldownWarning);
    notifyListeners();
  }

  var _travelWalletMoneyWarning = true;
  bool get travelWalletMoneyWarning => _travelWalletMoneyWarning;
  set travelWalletMoneyWarning(bool choice) {
    _travelWalletMoneyWarning = choice;
    Prefs().setTravelWalletMoneyWarning(_travelWalletMoneyWarning);
    notifyListeners();
  }

  var _travelWalletMoneyWarningThreshold = 50000;
  int get travelWalletMoneyWarningThreshold => _travelWalletMoneyWarningThreshold;
  set travelWalletMoneyWarningThreshold(int choice) {
    _travelWalletMoneyWarningThreshold = choice;
    Prefs().setTravelWalletMoneyWarningThreshold(_travelWalletMoneyWarningThreshold);
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

  var _foreignStockSellingFee = 0;
  int get foreignStockSellingFee => _foreignStockSellingFee;
  set changeForeignStockSellingFee(int value) {
    _foreignStockSellingFee = value;
    Prefs().setForeignStockSellingFee(_foreignStockSellingFee);
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

  void clearShowCases() {
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

  var _tornStatsChartRange = 0;
  int get tornStatsChartRange => _tornStatsChartRange;
  set setTornStatsChartRange(int value) {
    _tornStatsChartRange = value;
    Prefs().setTornStatsChartRange(tornStatsChartRange);
    notifyListeners();
  }

  var _tornStatsChartInCollapsedMiscCard = true;
  bool get tornStatsChartInCollapsedMiscCard => _tornStatsChartInCollapsedMiscCard;
  set setTornStatsChartInCollapsedMiscCard(bool value) {
    _tornStatsChartInCollapsedMiscCard = value;
    Prefs().setTornStatsChartInCollapsedMiscCard(tornStatsChartInCollapsedMiscCard);
    notifyListeners();
  }

  var _tornStatsChartShowBoth = false;
  bool get tornStatsChartShowBoth => _tornStatsChartShowBoth;
  set setTornStatsChartShowBoth(bool value) {
    _tornStatsChartShowBoth = value;
    Prefs().setTornStatsChartShowBoth(tornStatsChartShowBoth);
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

  var _quickItemsEnabled = true;
  bool get quickItemsEnabled => _quickItemsEnabled;
  set quickItemsEnabled(bool value) {
    _quickItemsEnabled = value;
    Prefs().setQuickItemsEnabled(value);
    notifyListeners();
  }

  var _quickItemsFactionEnabled = true;
  bool get quickItemsFactionEnabled => _quickItemsFactionEnabled;
  set quickItemsFactionEnabled(bool value) {
    _quickItemsFactionEnabled = value;
    Prefs().setQuickItemsFactionEnabled(value);
    notifyListeners();
  }

  int _lastAppUse = 0;
  int get lastAppUse => _lastAppUse;
  set updateLastUsed(int timeStamp) {
    Prefs().setLastAppUse(timeStamp);
    _lastAppUse = timeStamp;
    notifyListeners();
  }

  String _pdaUpdateDetailsRC = "";
  String get pdaUpdateDetailsRC => _pdaUpdateDetailsRC;
  set pdaUpdateDetailsRC(String value) {
    _pdaUpdateDetailsRC = value;
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

  var _dynamicAppIcons = true;
  bool get dynamicAppIcons => _dynamicAppIcons;
  set dynamicAppIcons(bool value) {
    _dynamicAppIcons = value;
    Prefs().setDynamicAppIcons(_dynamicAppIcons);
    notifyListeners();
  }

  var _dynamicAppIconsManual = "off";
  String get dynamicAppIconsManual => _dynamicAppIconsManual;
  set dynamicAppIconsManual(String value) {
    _dynamicAppIconsManual = value;
    Prefs().setDynamicAppIconsManual(_dynamicAppIconsManual);
    notifyListeners();
  }

  var _dynamicAppIconEnabledRemoteConfig = false;
  bool get dynamicAppIconEnabledRemoteConfig => _dynamicAppIconEnabledRemoteConfig;
  set dynamicAppIconEnabledRemoteConfig(bool enabled) {
    _dynamicAppIconEnabledRemoteConfig = enabled;
    notifyListeners();
  }

  var _debugMessages = false;
  bool get debugMessages => _debugMessages;
  set debugMessages(bool value) {
    _debugMessages = value;
    logAndShowToUser = value;
    Prefs().setDebugMessages(logAndShowToUser);
    notifyListeners();
  }

  var _shortcutsEnabledProfile = true;
  bool get shortcutsEnabledProfile => _shortcutsEnabledProfile;
  set shortcutsEnabledProfile(bool value) {
    _shortcutsEnabledProfile = value;
    Prefs().setShortcutsEnabledProfile(value);
    notifyListeners();
  }

  var _profileCheckAttackEnabled = true;
  bool get profileCheckAttackEnabled => _profileCheckAttackEnabled;
  set profileCheckAttackEnabled(bool value) {
    _profileCheckAttackEnabled = value;
    Prefs().setProfileCheckAttackEnabled(value);
    notifyListeners();
  }

  var _showShortcutEditIcon = true;
  bool get showShortcutEditIcon => _showShortcutEditIcon;
  set showShortcutEditIcon(bool value) {
    if (_showShortcutEditIcon == value) return;
    _showShortcutEditIcon = value;
    Prefs().setShowShortcutEditIcon(value);
    notifyListeners();
  }

  var _appwidgetDarkMode = false;
  bool get appwidgetDarkMode => _appwidgetDarkMode;
  set appwidgetDarkMode(bool value) {
    _appwidgetDarkMode = value;
    Prefs().setAppwidgetDarkMode(value);
    notifyListeners();
  }

  var _appwidgetRemoveShortcutsOneRowLayout = false;
  bool get appwidgetRemoveShortcutsOneRowLayout => _appwidgetRemoveShortcutsOneRowLayout;
  set appwidgetRemoveShortcutsOneRowLayout(bool value) {
    _appwidgetRemoveShortcutsOneRowLayout = value;
    Prefs().setAppwidgetRemoveShortcutsOneRowLayout(value);
    notifyListeners();
  }

  var _appwidgetMoneyEnabled = false;
  bool get appwidgetMoneyEnabled => _appwidgetMoneyEnabled;
  set appwidgetMoneyEnabled(bool value) {
    _appwidgetMoneyEnabled = value;
    Prefs().setAppwidgetMoneyEnabled(value);
    notifyListeners();
  }

  var _appwidgetCooldownTapOpenBrowser = false;
  bool get appwidgetCooldownTapOpenBrowser => _appwidgetCooldownTapOpenBrowser;
  set appwidgetCooldownTapOpenBrowser(bool value) {
    _appwidgetCooldownTapOpenBrowser = value;
    Prefs().setAppwidgetCooldownTapOpensBrowser(value);
    notifyListeners();
  }

  var _appwidgetCooldownTapOpenBrowserDestination = "own";
  String get appwidgetCooldownTapOpenBrowserDestination => _appwidgetCooldownTapOpenBrowserDestination;
  set appwidgetCooldownTapOpenBrowserDestination(String value) {
    _appwidgetCooldownTapOpenBrowserDestination = value;
    Prefs().setAppwidgetCooldownTapOpensBrowserDestination(value);
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

  // REVIVES
  String _reviveWolverinesPrice = "1 million or 1 Xanax each";
  String get reviveWolverinesPrice => _reviveWolverinesPrice;
  set reviveWolverinesPrice(String value) {
    _reviveWolverinesPrice = value;
    notifyListeners();
  }

  /*
  String _reviveHelaPrice = "1.8 million or 2 Xanax each";
  String get reviveHelaPrice => _reviveHelaPrice;
  set reviveHelaPrice(String value) {
    _reviveHelaPrice = value;
    notifyListeners();
  }
  */

  String _reviveMidnightPrice = "1.8 million or 2 Xanax each";
  String get reviveMidnightPrice => _reviveMidnightPrice;
  set reviveMidnightPrice(String value) {
    _reviveMidnightPrice = value;
    notifyListeners();
  }

  String _reviveNukePrice = "1.8 million or 2 Xanax each";
  String get reviveNukePrice => _reviveNukePrice;
  set reviveNukePrice(String value) {
    _reviveNukePrice = value;
    notifyListeners();
  }

  String _reviveUhcPrice = "1.8 million or 2 Xanax each";
  String get reviveUhcPrice => _reviveUhcPrice;
  set reviveUhcPrice(String value) {
    _reviveUhcPrice = value;
    notifyListeners();
  }

  String _reviveWtfPrice = "1.8 million or 2 Xanax each";
  String get reviveWtfPrice => _reviveWtfPrice;
  set reviveWtfPrice(String value) {
    _reviveWtfPrice = value;
    notifyListeners();
  }

  bool _tctClockHighlightsEvents = true;
  bool get tctClockHighlightsEvents => _tctClockHighlightsEvents;
  set tctClockHighlightsEvents(bool value) {
    _tctClockHighlightsEvents = value;
    Prefs().setTctClockHighlightsEvents(value);
    notifyListeners();
  }

  bool _showWikiInDrawer = true;
  bool get showWikiInDrawer => _showWikiInDrawer;
  set showWikiInDrawer(bool value) {
    _showWikiInDrawer = value;
    Prefs().setShowWikiInDrawer(value);
    notifyListeners();
  }

  bool _showMemoryInDrawer = false;
  bool get showMemoryInDrawer => _showMemoryInDrawer;
  set showMemoryInDrawer(bool value) {
    if (_showMemoryInDrawer == value) return;
    _showMemoryInDrawer = value;
    Prefs().setShowMemoryInDrawer(value);
    notifyListeners();
  }

  bool _showMemoryInWebview = false;
  bool get showMemoryInWebview => _showMemoryInWebview;
  set showMemoryInWebview(bool value) {
    if (_showMemoryInWebview == value) return;
    _showMemoryInWebview = value;
    Prefs().setShowMemoryInWebview(value);
    notifyListeners();
  }

  var _highRefreshRateEnabled = false;
  bool get highRefreshRateEnabled => _highRefreshRateEnabled;
  set changeHighRefreshRateEnabled(bool value) {
    _highRefreshRateEnabled = value;
    Prefs().setHighRefreshRateEnabled(_highRefreshRateEnabled);
    configureRefreshRate();
    notifyListeners();
  }

  bool _iosLiveActivitiesTravelEnabled = true;
  bool get iosLiveActivityTravelEnabled => _iosLiveActivitiesTravelEnabled;
  set iosLiveActivityTravelEnabled(bool enabled) {
    _iosLiveActivitiesTravelEnabled = enabled;
    Prefs().setIosLiveActivityTravelEnabled(enabled);
    notifyListeners();

    if (enabled) {
      if (kSdkIos >= 17.2) {
        log("Live Activities enabled by user. Requesting push-to-start token...");
        final bridgeController = Get.find<LiveActivityBridgeController>();
        // Force, so that we are using the setter also as a way to reset the token
        bridgeController.getPushToStartTokenAndSendToFirebase(force: true, activityType: LiveActivityType.travel);
      }
    } else {
      FirestoreHelper().disableLiveActivityTravel();
      Prefs().setLaPushToken(token: null, activityType: LiveActivityType.travel);
    }
  }

  bool _androidLiveActivitiesTravelEnabled = false;
  bool get androidLiveActivityTravelEnabled => _androidLiveActivitiesTravelEnabled;
  set androidLiveActivityTravelEnabled(bool enabled) {
    _androidLiveActivitiesTravelEnabled = enabled;
    Prefs().setAndroidLiveActivityTravelEnabled(enabled);
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

    _androidLiveActivitiesTravelEnabled = await Prefs().getAndroidLiveActivityTravelEnabled();

    // Gestures
    _iosBrowserPinch = await Prefs().getIosBrowserPinch();
    _iosDisallowOverscroll = await Prefs().getIosDisallowOverscroll();
    _browserReverseNavigationSwipe = await Prefs().getBrowserReverseNavigationSwipe();
    _browserCenterEditingTextField = await Prefs().getBrowserCenterEditingTextField();
    _browserExtendHeightForKeyboard = await Prefs().getBrowserExtendHeightForKeyboard();

    _loadBarBrowser = await Prefs().getLoadBarBrowser();
    _highRefreshRateEnabled = await Prefs().getHighRefreshRateEnabled();

    _useTabsFullBrowser = await Prefs().getUseTabsFullBrowser();
    _useTabsHideFeature = await Prefs().getUseTabsHideFeature();
    _tabsHideBarColor = await Prefs().getTabsHideBarColor();
    _showTabLockWarnings = await Prefs().getShowTabLockWarnings();
    _fullLockNavigationAttemptOpensNewTab = await Prefs().getFullLockNavigationAttemptOpensNewTab();

    List<dynamic> jsonList = json.decode(await Prefs().getLockedTabsNavigationExceptions());
    _lockedTabsNavigationExceptions = jsonList.map((item) => List<String>.from(item)).toList();

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
    _fullScreenByShortChainingTap = await Prefs().getFullScreenByShortChainingTap();
    _fullScreenByLongChainingTap = await Prefs().getFullScreenByLongChainingTap();
    _fullScreenByDeepLinkTap = await Prefs().getFullScreenByDeepLinkTap();
    _fullScreenByQuickItemTap = await Prefs().getFullScreenByQuickItemTap();
    _fullScreenIncludesPDAButtonTap = await Prefs().getFullScreenIncludesPDAButtonTap();

    _lifeNotificationTapAction = await Prefs().getLifeNotificationTapAction();
    _drugsNotificationTapAction = await Prefs().getDrugsNotificationTapAction();
    _medicalNotificationTapAction = await Prefs().getMedicalNotificationTapAction();
    _boosterNotificationTapAction = await Prefs().getBoosterNotificationTapAction();

    final refresh = await Prefs().getBrowserRefreshMethod();
    switch (refresh) {
      case "icon":
        _browserRefreshMethod = BrowserRefreshSetting.icon;
      case "pull":
        _browserRefreshMethod = BrowserRefreshSetting.pull;
      case "both":
        _browserRefreshMethod = BrowserRefreshSetting.both;
    }

    _browserShowNavArrowsAppbar = await Prefs().getBrowserShowNavArrowsAppbar();

    _onBackButtonAppExit = await Prefs().getOnBackButtonAppExit();

    _chatRemoveEnabled = await Prefs().getChatRemovalEnabled();

    _highlightChat = await Prefs().getHighlightChat();
    _highlightColor = await Prefs().getHighlightColor();
    _highlightWordList = await Prefs().getHighlightWordList();

    _removeAirplane = await Prefs().getRemoveAirplane();
    _removeForeignItemsDetails = await Prefs().getRemoveForeignItemsDetails();
    _preventBasketKeyboard = await Prefs().getPreventBasketKeyboard();
    _removeTravelQuickReturnButton = await Prefs().getRemoveTravelQuickReturnButton();

    _extraPlayerInformation = await Prefs().getExtraPlayerInformation();

    _shareAttackOptions = await Prefs().getShareAttackOptions();

    _tscEnabledStatus = await Prefs().getTSCEnabledStatus();
    _yataStatsEnabledStatus = await Prefs().getYataStatsEnabledStatus();

    //_profileStatsEnabled = await Prefs().getProfileStatsEnabled();

    final savedFriendlyFactions = await Prefs().getFriendlyFactions();
    if (savedFriendlyFactions.isNotEmpty) {
      final decoded = json.decode(savedFriendlyFactions);
      for (final dec in decoded) {
        _friendlyFactions.add(FriendlyFaction.fromJson(dec));
      }
    }

    _notesWidgetEnabledProfile = await Prefs().getNotesWidgetEnabledProfile();
    _notesWidgetEnabledProfileWhenEmpty = await Prefs().getNotesWidgetEnabledProfileWhenEmpty();
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

    _discreetNotifications = await Prefs().getDiscreetNotifications();

    _showDateInClock = await Prefs().getShowDateInClock();
    _showSecondsInClock = await Prefs().getShowSecondsInClock();

    final String restoredAppBar = await Prefs().getAppBarPosition();
    restoredAppBar == 'top' ? _appBarTop = true : _appBarTop = false;

    _oCrimesEnabled = await Prefs().getOCrimesEnabled();
    _oCrimeDisregarded = await Prefs().getOCrimeDisregarded();
    _oCrimeLastKnown = await Prefs().getOCrimeLastKnown();
    _playerInOCv2 = await Prefs().getPlayerInOCv2();

    _showAllRentedOutProperties = await Prefs().getShowAllRentedOutProperties();

    _allowScreenRotation = await Prefs().getAllowScreenRotation();

    _lifeBarOption = await Prefs().getLifeBarOption();

    _colorCodedStatusCard = await Prefs().getColorCodedStatusCard();

    _iosAllowLinkPreview = await Prefs().getIosAllowLinkPreview();

    _warnAboutExcessEnergy = await Prefs().getWarnAboutExcessEnergy();
    _warnAboutExcessEnergyThreshold = await Prefs().getWarnAboutExcessEnergyThreshold();
    _warnAboutChains = await Prefs().getWarnAboutChains();

    _travelEnergyExcessWarning = await Prefs().getTravelEnergyExcessWarning();
    _travelEnergyRangeWarningThreshold = await Prefs().getTravelEnergyRangeWarningRange();
    _travelNerveExcessWarning = await Prefs().getTravelNerveExcessWarning();
    _travelNerveExcessWarningThreshold = await Prefs().getTravelNerveExcessWarningThreshold();
    _travelLifeExcessWarning = await Prefs().getTravelLifeExcessWarning();
    _travelLifeExcessWarningThreshold = await Prefs().getTravelLifeExcessWarningThreshold();
    _travelDrugCooldownWarning = await Prefs().getTravelDrugCooldownWarning();
    _travelBoosterCooldownWarning = await Prefs().getTravelBoosterCooldownWarning();
    _travelWalletMoneyWarning = await Prefs().getTravelWalletMoneyWarning();
    _travelWalletMoneyWarningThreshold = await Prefs().getTravelWalletMoneyWarningThreshold();

    _terminalEnabled = await Prefs().getTerminalEnabled();

    _rankedWarsInMenu = await Prefs().getRankedWarsInMenu();
    _rankedWarsInProfile = await Prefs().getRankedWarsInProfile();
    _rankedWarsInProfileShowTotalHours = await Prefs().getRankedWarsInProfileShowTotalHours();

    _stockExchangeInMenu = await Prefs().getStockExchangeInMenu();
    _foreignStockSellingFee = await Prefs().getForeignStockSellingFee();

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
    _tornStatsChartRange = await Prefs().getTornStatsChartRange();
    _tornStatsChartInCollapsedMiscCard = await Prefs().getTornStatsChartInCollapsedMiscCard();
    _tornStatsChartShowBoth = await Prefs().getTornStatsChartShowBoth();

    _retaliationSectionEnabled = await Prefs().getRetaliationSectionEnabled();
    _singleRetaliationOpensBrowser = await Prefs().getSingleRetaliationOpensBrowser();

    _quickItemsEnabled = await Prefs().getQuickItemsEnabled();
    _quickItemsFactionEnabled = await Prefs().getQuickItemsFactionEnabled();

    _syncTornWebTheme = await Prefs().getSyncTornWebTheme();
    _syncDeviceTheme = await Prefs().getSyncDeviceTheme();
    _darkThemeToSync = await Prefs().getDarkThemeToSync();

    _dynamicAppIcons = await Prefs().getDynamicAppIcons();
    _dynamicAppIconsManual = await Prefs().getDynamicAppIconsManual();

    _debugMessages = logAndShowToUser = await Prefs().getDebugMessages();

    _shortcutsEnabledProfile = await Prefs().getShortcutsEnabledProfile();
    _profileCheckAttackEnabled = await Prefs().getProfileCheckAttackEnabled();
    _showShortcutEditIcon = await Prefs().getShowShortcutEditIcon();

    _appwidgetDarkMode = await Prefs().getAppwidgetDarkMode();
    _appwidgetRemoveShortcutsOneRowLayout = await Prefs().getAppwidgetRemoveShortcutsOneRowLayout();
    _appwidgetMoneyEnabled = await Prefs().getAppwidgetMoneyEnabled();
    _appwidgetCooldownTapOpenBrowser = await Prefs().getAppwidgetCooldownTapOpensBrowser();
    _appwidgetCooldownTapOpenBrowserDestination = await Prefs().getAppwidgetCooldownTapOpensBrowserDestination();

    _exactPermissionDialogShownAndroid = await Prefs().getExactPermissionDialogShownAndroid();

    _downloadActionShare = await Prefs().getDownloadActionShare();

    _tctClockHighlightsEvents = await Prefs().getTctClockHighlightsEvents();

    _showWikiInDrawer = await Prefs().getShowWikiInDrawer();

    await WebviewConfig().generateUserAgentForUser();

    _showMemoryInDrawer = await Prefs().getShowMemoryInDrawer();
    _showMemoryInWebview = await Prefs().getShowMemoryInWebview();

    _androidLiveActivitiesTravelEnabled = await Prefs().getAndroidLiveActivityTravelEnabled();
    _iosLiveActivitiesTravelEnabled = await Prefs().getIosLiveActivityTravelEnabled();

    _joblessWarningEnabled = await Prefs().getJoblessWarningEnabled();

    notifyListeners();
  }

  // Method to change the app icon based on a specific condition (e.g., date)
  void appIconChangeBasedOnCondition() async {
    if (!dynamicAppIconEnabledRemoteConfig) {
      // If remote config is not enabled, reset to default icon
      appIconResetDefault();
      return;
    }

    if (!dynamicAppIcons) return;

    const platform = MethodChannel('tornpda/icon');
    String? iconName;

    DateTime now = DateTime.now();

    if (_dynamicAppIconsManual == "off") {
      // Define the date ranges
      final awarenessWeekStart = DateTime(now.year, 01, 15);
      final awarenessWeekEnd = DateTime(now.year, 01, 21, 23, 59, 59);
      final stValentineStart = DateTime(now.year, 02, 13, 10, 30);
      final stValentineEnd = DateTime(now.year, 02, 15, 10, 30);
      final stPatrickStart = DateTime(now.year, 03, 16, 10, 30);
      final stPatrickEnd = DateTime(now.year, 03, 18, 10, 30);
      final easterStart = DateTime(now.year, 04, 17, 10, 30);
      final easterEnd = DateTime(now.year, 04, 24, 10, 30);
      final halloweenStart = DateTime(now.year, 10, 25);
      final halloweenEnd = DateTime(now.year, 11, 1, 23, 59, 59);
      final christmasStart = DateTime(now.year, 12, 19);
      final christmasEnd = DateTime(now.year, 12, 31, 23, 59, 59);

      // Determine the icon based on date ranges
      if (now.isAfter(awarenessWeekStart) && now.isBefore(awarenessWeekEnd)) {
        iconName = "AppIconAwareness";
      } else if (now.isAfter(stValentineStart) && now.isBefore(stValentineEnd)) {
        iconName = "AppIconStValentine";
      } else if (now.isAfter(stPatrickStart) && now.isBefore(stPatrickEnd)) {
        iconName = "AppIconStPatrick";
      } else if (now.isAfter(easterStart) && now.isBefore(easterEnd)) {
        iconName = "AppIconEaster";
      } else if (now.isAfter(halloweenStart) && now.isBefore(halloweenEnd)) {
        iconName = "AppIconHalloween";
      } else if (now.isAfter(christmasStart) && now.isBefore(christmasEnd)) {
        iconName = "AppIconChristmas";
      } else {
        iconName = null; // Default icon
      }
    } else {
      // Manual override for specific icons
      switch (_dynamicAppIconsManual) {
        case "awareness":
          iconName = "AppIconAwareness";
          break;
        case "stvalentine":
          iconName = "AppIconStValentine";
          break;
        case "stpatrick":
          iconName = "AppIconStPatrick";
          break;
        case "easter":
          iconName = "AppIconEaster";
          break;
        case "halloween":
          iconName = "AppIconHalloween";
          break;
        case "christmas":
          iconName = "AppIconChristmas";
          break;
        default:
          iconName = null; // Default icon
      }
    }

    try {
      if (iconName == null) {
        // If iconName is null, reset to default without passing arguments
        await platform.invokeMethod('changeIcon');
      } else {
        // Pass the iconName if it is not null
        await platform.invokeMethod('changeIcon', {'iconName': iconName});
      }
    } on PlatformException catch (e) {
      log("Failed to update icon: ${e.message}");
    }
  }

  // Method to reset the icon to the default
  void appIconResetDefault() async {
    const platform = MethodChannel('tornpda/icon');

    try {
      // Invoke changeIcon without arguments to reset to the default icon
      await platform.invokeMethod('changeIcon');
    } on PlatformException catch (e) {
      log("Failed to reset icon: ${e.message}");
    }
  }

  /// Determine whether the user is still using OC v1 or is already in OC v2
  /// This will be used by several client widgets to call the appropriate API
  ///
  /// 1. We only perform this check if the user is still in OC v1 in SharedPreferences
  /// 2. We call the v2 API and, if there is a crime active, we will transition to v2
  /// 3. Note that the user can manually revert back to OC v1 in Settings
  ///    If he does, he will stay in OC v1 until he manually reverts to OC2 or until
  ///    we can find a positive crime in API v2
  ///
  /// Players might want to revert to OC1 crimes if they change to an OC1 faction, for example
  /// But they might forget to change back to OC2 later when applicable, so we will keep calling the API
  void checkIfUserIsOnOCv2() async {
    bool alreadyInOC2 = await Prefs().getPlayerInOCv2();

    if (alreadyInOC2) {
      log("Player already in OC v2: no check needed");
      return;
    }

    final dynamic apiResponse = await ApiCallsV2.getUserOC2Crime_v2();
    if (apiResponse != null) {
      final crime = apiResponse as UserOrganizedCrimeResponse;

      if (crime.organizedCrime != null && crime.organizedCrime?["error"] != null) {
        if (crime.organizedCrime["error"] == "Must be migrated to organized crimes 2.0") {
          playerInOCv2 = false;
          log("Switching player to OC v1");
          return;
        }
      } else if (crime.organizedCrime != null && crime.organizedCrime?["id"] != null) {
        playerInOCv2 = true;
        log("Switching player to OC v2");
        return;
      }

      log("Can't verify if player is in OC v2, keeping OC v1");
    }
  }

  Future<void> configureRefreshRate() async {
    try {
      if (_highRefreshRateEnabled) {
        final success = await _refreshRateControl.requestHighRefreshRate();
        if (success) {
          log('High refresh rate enabled successfully');
        } else {
          log('Failed to enable high refresh rate');
        }
      } else {
        final success = await _refreshRateControl.stopHighRefreshRate();
        if (success) {
          log('High refresh rate disabled successfully');
        } else {
          log('Failed to disable high refresh rate');
        }
      }
    } catch (e) {
      log('Error configuring refresh rate: $e');
    }
  }

  Future<Map<String, dynamic>> getRefreshRateInfo() async {
    try {
      return await _refreshRateControl.getRefreshRateInfo();
    } catch (e) {
      log('Error getting refresh rate info: $e');
      return {};
    }
  }
}
