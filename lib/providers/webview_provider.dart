// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/tabsave_model.dart';
import 'package:torn_pda/providers/periodic_execution_controller.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_models.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/tabs_wipe_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_fab.dart';

// Package imports:

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

enum UiMode {
  window,
  fullScreen,
}

enum WebViewSplitPosition {
  right,
  left,
  off,
}

class RotatedDisposedTabDetails {
  GlobalKey<WebViewFullState>? key;
  String? currentUrl;
  int? scrollY;
  int? scrollX;

  RotatedDisposedTabDetails({this.key, this.currentUrl, this.scrollY, this.scrollX});
}

class TabDetails {
  // Unique identifier
  final String id = DateTime.now().millisecondsSinceEpoch.toString() + (DateTime.now().microsecond % 1000).toString();

  bool sleepTab = false;
  bool initialised = false;
  Widget? webView;
  SleepingWebView? sleepingWebView;
  GlobalKey<WebViewFullState>? webViewKey;
  String? currentUrl = "https://www.torn.com";
  String? pageTitle = "";
  bool chatRemovalActiveTab = false;
  List<String?> historyBack = <String?>[];
  List<String?> historyForward = <String?>[];
  bool isChainingBrowser = false;
  DateTime? lastUsedTimeDT;
  bool isLocked = false;
  bool isLockFull = false;
  String customName = "";
  bool customNameInTitle = false;
  bool customNameInTab = true;

  // Icon cache for this specific tab
  Widget? cachedIcon;
}

class SleepingWebView {
  final String? customUrl;
  final GlobalKey<WebViewFullState>? key;
  //final bool dialog;
  final bool useTabs;
  final bool chatRemovalActive;
  final bool isChainingBrowser;
  final ChainingPayload? chainingPayload;
  final bool allowDownloads;

  const SleepingWebView({
    this.customUrl = 'https://www.torn.com',
    //this.dialog = false,
    this.useTabs = false,
    this.chatRemovalActive = false,
    this.key,
    this.isChainingBrowser = false,
    this.chainingPayload,
    this.allowDownloads = true,
  });
}

class WebViewProvider extends ChangeNotifier {
  final List<TabDetails> _tabList = <TabDetails>[];
  List<TabDetails> get tabList => _tabList;

  // Track tabs that have recently changed URLs to force icon regeneration
  final Set<int> _recentlyChangedTabs = <int>{};

  int loginErrorRetrySeconds = 0;

  // Rotate tab details
  List<RotatedDisposedTabDetails> rotatedTabDetails = [];

  // Windows user data folder
  WebViewEnvironment? webViewEnvironment;

  // Controls successive toastification activations for full lock awareness, since
  // using [toastification.dismissAll()] leaves quite a long gap until next activation is possible
  DateTime? lastLockToastShown;

  /// URLs that can generate multiple back/forward history entries without actual navigation changes
  /// (e.g.: personal stats will trigger a new URL load for every change in the page, as URL params change)
  List<String> urlsWithStuckHistory = [
    "https://www.torn.com/personalstats.php?",
  ];

  // DEV TOOL REOPENING CONTROLLER (TO DEACTIVATE BUTTON)
  DateTime? _devToolsReopenTime;
  DateTime? get devToolsReopenTime => _devToolsReopenTime;
  Future<void> startDevToolsCooldown(int seconds) async {
    _devToolsReopenTime = DateTime.now().add(Duration(seconds: seconds));
    notifyListeners();
    await Future.delayed(Duration(seconds: seconds));
    _devToolsReopenTime = null;
    notifyListeners();
  }

  bool _bottomBarStyleEnabled = false;
  bool get bottomBarStyleEnabled => _bottomBarStyleEnabled;
  set bottomBarStyleEnabled(bool value) {
    _bottomBarStyleEnabled = value;
    Prefs().setBrowserBottomBarStyleEnabled(value);
    notifyListeners();
  }

  // 1 = standard, 2 = dialog
  int _bottomBarStyleType = 1;
  int get bottomBarStyleType => _bottomBarStyleType;
  set bottomBarStyleType(int value) {
    _bottomBarStyleType = value;
    Prefs().setBrowserBottomBarStyleType(value);
    notifyListeners();
  }

  bool _browserBottomBarStylePlaceTabsAtBottom = false;
  bool get browserBottomBarStylePlaceTabsAtBottom => _browserBottomBarStylePlaceTabsAtBottom;
  set browserBottomBarStylePlaceTabsAtBottom(bool value) {
    _browserBottomBarStylePlaceTabsAtBottom = value;
    Prefs().setBrowserBottomBarStylePlaceTabsAtBottom(value);
    notifyListeners();
  }

  /// Changes browser visibility
  bool _isBrowserForeground = false;
  bool get browserShowInForeground => _isBrowserForeground;
  set browserShowInForeground(bool bringToForeground) {
    // Browser should not be resumed/paused while we are in split screen
    if (webViewSplitActive) {
      return;
    }

    SendbirdController sb = Get.find<SendbirdController>();
    sb.webviewInForeground = bringToForeground;

    if (bringToForeground) {
      if (stackView is Container) {
        stackView = const WebViewStackView(
          recallLastSession: true,
        );
      }

      // Change browser visibility early to avoid issues if device returns an error
      _isBrowserForeground = bringToForeground;
      notifyListeners();

      resumeAllWebviews();
    } else {
      // Change browser visibility early to avoid issues if device returns an error
      _isBrowserForeground = bringToForeground;
      notifyListeners();

      // Signal that the browser has closed to listener (e.g.: Profile page)
      browserHasClosedStream.add(true);

      _removeAllUserScripts().then((value) {
        pauseAllWebviews();
      });

      _sleepOldTabs();
    }
  }

  /// Use to transition to split screen, ensuring that browser is also resumed
  void browserForegroundWithSplitTransition() {
    if (stackView is Container) {
      stackView = const WebViewStackView(
        recallLastSession: true,
      );
    }

    // Change browser visibility early to avoid issues if device returns an error
    _isBrowserForeground = true;
    notifyListeners();
    resumeAllWebviews();
  }

  void pdaIconActivation({
    required bool shortTap,
    required BuildContext context,
    required bool automaticLogin,
  }) {
    browserShowInForeground = true;

    if (automaticLogin && context.read<NativeUserProvider>().playerLastLoginMethod != NativeLoginType.none) {
      // When we use the PDA Icon, launch a logout check by default in case we just activated
      // the native user in Settings and are logged out
      assessLoginErrorsFromPdaIcon();
    }

    final SettingsProvider settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.fullScreenIncludesPDAButtonTap) {
      final bool prefersFullScreen = shortTap ? settings.fullScreenByShortTap : settings.fullScreenByLongTap;

      if (currentUiMode == UiMode.window && prefersFullScreen) {
        setCurrentUiMode(UiMode.fullScreen, context);
        if (settings.fullScreenRemovesChat) {
          removeAllChatsFullScreen();
        }
      } else if (currentUiMode == UiMode.fullScreen && !prefersFullScreen) {
        setCurrentUiMode(UiMode.window, context);
      }
    }

    notifyListeners();
  }

  /// Main browser widget
  Widget _stackView = Container();
  Widget get stackView => _stackView;
  set stackView(Widget value) {
    _stackView = value;
    notifyListeners();
  }

  UiMode _currentUiMode = UiMode.window;
  UiMode get currentUiMode => _currentUiMode;
  void setCurrentUiMode(UiMode value, BuildContext context) {
    _currentUiMode = value;
    if (_currentUiMode == UiMode.fullScreen) {
      final SettingsProvider settings = Provider.of<SettingsProvider>(context, listen: false);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [
          if (!settings.fullScreenOverNotch) SystemUiOverlay.top,
          if (!settings.fullScreenOverBottom) SystemUiOverlay.bottom,
        ],
      );

      // Prevent tabs from hiding in full screen
      // This also triggers proper padding calculations for webview in stackview
      hideTabs = false;
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    notifyListeners();
  }

  // SPLIT SCREEN ####
  // Main state
  bool _webViewSplitActive = false;
  bool get webViewSplitActive => _webViewSplitActive;
  set webViewSplitActive(bool value) {
    _webViewSplitActive = value;
    notifyListeners();
  }

  // If active conditions met, this is the user preference
  WebViewSplitPosition _webViewSplitPosition = WebViewSplitPosition.off;
  WebViewSplitPosition get splitScreenPosition => _webViewSplitPosition;
  set splitScreenPosition(WebViewSplitPosition value) {
    _webViewSplitPosition = value;
    switch (value) {
      case WebViewSplitPosition.off:
        Prefs().setSplitScreenWebview("off");
      case WebViewSplitPosition.left:
        Prefs().setSplitScreenWebview("left");
      case WebViewSplitPosition.right:
        Prefs().setSplitScreenWebview("right");
    }
    notifyListeners();
  }

  // Recovery after conditions are no longer met
  bool _splitScreenRevertsToApp = true;
  bool get splitScreenRevertsToApp => _splitScreenRevertsToApp;
  set splitScreenRevertsToApp(bool value) {
    _splitScreenRevertsToApp = value;
    Prefs().setSplitScreenRevertsToApp(value);
    notifyListeners();
  }

  // SPLIT SCREEN END ####

  // Vertical expanding menu (menu button)
  int verticalMenuCurrentIndex = 0;
  bool verticalMenuIsOpen = false;

  void verticalMenuOpen() {
    verticalMenuIsOpen = true;
    notifyListeners();
  }

  void verticalMenuClose() {
    verticalMenuIsOpen = false;
    notifyListeners();
  }

  StreamController browserHasClosedStream = StreamController.broadcast();

  bool chatRemovalEnabledGlobal = false;
  bool chatRemovalWhileFullScreen = false;

  bool _chatRemovalActiveGlobal = false;
  bool get chatRemovalActiveGlobal => _chatRemovalActiveGlobal;
  set chatRemovalActiveGlobal(bool value) {
    _chatRemovalActiveGlobal = value;
    notifyListeners();
  }

  String pendingThemeSync = "";

  bool _useTabIcons = true;
  bool get useTabIcons => _useTabIcons;

  bool _hideTabs = false;
  bool get hideTabs => _hideTabs;
  set hideTabs(bool value) {
    _hideTabs = value;
    notifyListeners();
  }

  bool _gymMessageActive = false;

  int currentTab = 0;

  bool _secondaryInitialised = false;

  DateTime? _lastBrowserOpenedTime;

  var _removeUnusedTabs = true;
  bool get removeUnusedTabs => _removeUnusedTabs;
  set removeUnusedTabs(bool value) {
    _removeUnusedTabs = value;
    Prefs().setRemoveUnusedTabs(_removeUnusedTabs);
    notifyListeners();
  }

  var _removeUnusedTabsIncludesLocked = true;
  bool get removeUnusedTabsIncludesLocked => _removeUnusedTabsIncludesLocked;
  set removeUnusedTabsIncludesLocked(bool value) {
    _removeUnusedTabsIncludesLocked = value;
    Prefs().setRemoveUnusedTabsIncludesLocked(_removeUnusedTabsIncludesLocked);
    notifyListeners();
  }

  var _removeUnusedTabsRangeDays = TabsWipeTimeRange.sevenDays;
  TabsWipeTimeRange get removeUnusedTabsRangeDays => _removeUnusedTabsRangeDays;
  set removeUnusedTabsRangeDays(TabsWipeTimeRange value) {
    _removeUnusedTabsRangeDays = value;
    int daysToSave = 7;
    switch (_removeUnusedTabsRangeDays) {
      // We are not including 'any' as we do in the browser wipe tabs option
      case TabsWipeTimeRange.oneDay:
        daysToSave = 1;
      case TabsWipeTimeRange.twoDays:
        daysToSave = 2;
      case TabsWipeTimeRange.threeDays:
        daysToSave = 3;
      case TabsWipeTimeRange.fiveDays:
        daysToSave = 5;
      case TabsWipeTimeRange.sevenDays:
        daysToSave = 7;
      case TabsWipeTimeRange.fifteenDays:
        daysToSave = 15;
      case TabsWipeTimeRange.oneMonth:
        daysToSave = 30;
      default:
        daysToSave = 7;
    }
    Prefs().setRemoveUnusedTabsRangeDays(daysToSave);
    notifyListeners();
  }

  var _onlyLoadTabsWhenUsed = true;
  bool get onlyLoadTabsWhenUsed => _onlyLoadTabsWhenUsed;
  set onlyLoadTabsWhenUsed(bool value) {
    _onlyLoadTabsWhenUsed = value;
    Prefs().setOnlyLoadTabsWhenUsed(_onlyLoadTabsWhenUsed);
    notifyListeners();
  }

  var _automaticChangeToNewTabFromURL = true;
  bool get automaticChangeToNewTabFromURL => _automaticChangeToNewTabFromURL;
  set automaticChangeToNewTabFromURL(bool value) {
    _automaticChangeToNewTabFromURL = value;
    Prefs().setAutomaticChangeToNewTabFromURL(_automaticChangeToNewTabFromURL);
    notifyListeners();
  }

  bool _fabEnabled = true;
  bool get fabEnabled => _fabEnabled;
  set fabEnabled(bool value) {
    _fabEnabled = value;
    Prefs().setWebviewFabEnabled(_fabEnabled);
    notifyListeners();
  }

  int _fabButtonCount = 4;
  int get fabButtonCount => _fabButtonCount;
  set fabButtonCount(int value) {
    if (value >= FabSettings.minButtons && value <= FabSettings.maxButtons) {
      _fabButtonCount = value;
      Prefs().setFabButtonCount(value);
      notifyListeners();
    }
  }

  List<WebviewFabAction> _fabButtonActions = [];
  List<WebviewFabAction> get fabButtonActions => _fabButtonActions;
  void updateFabButtonAction(int index, WebviewFabAction action) {
    if (index >= 0 && index < _fabButtonActions.length) {
      _fabButtonActions[index] = action;
      Prefs().setFabButtonActions(_fabButtonActions);
      notifyListeners();
    }
  }

  WebviewFabAction _fabDoubleTapAction = WebviewFabAction.openTabsMenu;
  WebviewFabAction get fabDoubleTapAction => _fabDoubleTapAction;
  void updateFabDoubleTapAction(WebviewFabAction action) {
    _fabDoubleTapAction = action;
    Prefs().setFabDoubleTapAction(action);
    notifyListeners();
  }

  WebviewFabAction _fabTripleTapAction = WebviewFabAction.closeCurrentTab;
  WebviewFabAction get fabTripleTapAction => _fabTripleTapAction;
  void updateFabTripleTapAction(WebviewFabAction action) {
    _fabTripleTapAction = action;
    Prefs().setFabTripleTapAction(action);
    notifyListeners();
  }

  var _fabShownNow = true;
  bool get fabShownNow => _fabShownNow;
  set fabShownNow(bool value) {
    _fabShownNow = value;
    Prefs().setWebviewFabShownNow(_fabShownNow);
    notifyListeners();
  }

  var _fabDirection = "center";
  String get fabDirection => _fabDirection;
  set fabDirection(String value) {
    _fabDirection = value;
    Prefs().setWebviewFabDirection(_fabDirection);
    notifyListeners();
  }

  var _fabSavedPositionXY = [100, 100];
  List<int> get fabSavedPositionXY => _fabSavedPositionXY;
  set fabSavedPositionXY(List<int> value) {
    _fabSavedPositionXY = value;
    Prefs().setWebviewFabPositionXY(_fabSavedPositionXY);
    notifyListeners();
  }

  var _fabOnlyFullScreen = false;
  bool get fabOnlyFullScreen => _fabOnlyFullScreen;
  set fabOnlyFullScreen(bool value) {
    _fabOnlyFullScreen = value;
    Prefs().setWebviewFabOnlyFullScreen(_fabOnlyFullScreen);
    notifyListeners();
  }

  bool _browserDoNotPauseWebview = false;
  bool get browserDoNotPauseWebview => _browserDoNotPauseWebview;
  set browserDoNotPauseWebview(bool value) {
    _browserDoNotPauseWebview = value;
    Prefs().setBrowserDoNotPauseWebviews(_browserDoNotPauseWebview);
    notifyListeners();
  }

  /// [recallLastSession] should be used to open a browser session where we left it last time
  Future<void> initialiseMain({
    required String? initUrl,
    required BuildContext context,
    bool recallLastSession = false,
    bool isChainingBrowser = false,
    ChainingPayload? chainingPayload,
    bool restoreSessionCookie = false,
  }) async {
    // Restore session cookie if requested
    if (restoreSessionCookie) {
      try {
        final String sessionCookie = await Prefs().getWebViewSessionCookie();
        if (sessionCookie.isNotEmpty) {
          final cm = CookieManager.instance();

          final allCookies = await cm.getCookies(url: WebUri("https://www.torn.com"));
          log("Cookies: ${allCookies.length}");
          final repetitions = allCookies.where((element) => element.name == "PHPSESSID").length;

          for (int i = 0; i < repetitions; i++) {
            await cm.deleteCookie(url: WebUri("https://www.torn.com"), name: "PHPSESSID");
            log("Cleared PHPSESSID: $i");
          }

          await cm.setCookie(
            url: WebUri("https://www.torn.com"),
            domain: "www.torn.com",
            name: "PHPSESSID",
            value: sessionCookie,
          );
          log("Restored PHPSESSID cookie: $sessionCookie");
        }
      } catch (e) {
        //
      }
    }

    // Load user preferences
    _bottomBarStyleEnabled = await Prefs().getBrowserBottomBarStyleEnabled();
    _bottomBarStyleType = await Prefs().getBrowserBottomBarStyleType();
    _browserBottomBarStylePlaceTabsAtBottom = await Prefs().getBrowserBottomBarStylePlaceTabsAtBottom();

    chatRemovalEnabledGlobal = await Prefs().getChatRemovalEnabled();
    chatRemovalActiveGlobal = await Prefs().getChatRemovalActive();

    _useTabIcons = await Prefs().getUseTabsIcons();
    _hideTabs = await Prefs().getHideTabs();

    // Clear temporary downloads if sharing is enabled
    await _clearTemporaryDownloadedFiles(context);

    // Add the main opener tab, restoring last session if requested
    String? url = initUrl;
    if (recallLastSession) {
      final String savedJson = await Prefs().getWebViewMainTab();
      final TabSaveModel savedMain = tabSaveModelFromJson(savedJson);
      if (savedMain.tabsSave!.isNotEmpty) {
        String? saveMain = savedMain.tabsSave![0].url;
        String? authUrl = await _assessNativeAuth(inputUrl: saveMain, context: context);
        addTab(
          url: authUrl,
          pageTitle: savedMain.tabsSave![0].pageTitle,
          chatRemovalActive: savedMain.tabsSave![0].chatRemovalActive,
          historyBack: savedMain.tabsSave![0].historyBack,
          historyForward: savedMain.tabsSave![0].historyForward,
        );
      } else {
        String? authUrl = await _assessNativeAuth(inputUrl: "https://www.torn.com", context: context);
        await addTab(url: authUrl, chatRemovalActive: chatRemovalActiveGlobal);
      }
    } else {
      String? authUrl = await _assessNativeAuth(inputUrl: url, context: context);
      await addTab(
        url: authUrl,
        chatRemovalActive: chatRemovalActiveGlobal,
        isChainingBrowser: isChainingBrowser,
        chainingPayload: chainingPayload,
      );
    }

    currentTab = 0;
  }

  Future<void> _clearTemporaryDownloadedFiles(BuildContext context) async {
    try {
      if (context.read<SettingsProvider>().downloadActionShare) {
        // Both platforms should have used this folder to store downloads if [downloadActionShare] was enabled
        // Other files (in the standard downloads folder, if [downloadActionShare] was disabled) won't be deleted
        // (which might create an increase in cache size in Android if the user can't acces the folder)
        String downloadsPath = "${(await getTemporaryDirectory()).path}/downloads/";

        await for (var entity in Directory(downloadsPath).list(recursive: true, followLinks: true)) {
          log("Deleting downloaded file: ${entity.path}");
          await File(entity.path).delete();
        }
      }
    } on MissingPlatformDirectoryException catch (_) {
      log("No temporary files folder");
    } catch (e, trace) {
      // This is to be expected if the user doesn't have access to the folder or it does not exist
      log("PDA Crash at Deleting Downloaded Files: $e $trace");
    }
  }

  Future initialiseSecondary({required bool useTabs, bool recallLastSession = false}) async {
    final savedJson = await Prefs().getWebViewSecondaryTabs();
    final savedWebViews = tabSaveModelFromJson(savedJson);
    final bool sleepTabsByDefault = await Prefs().getOnlyLoadTabsWhenUsed();

    _secondaryInitialised = true;

    for (final wv in savedWebViews.tabsSave!) {
      if (useTabs) {
        await addTab(
          tabKey: wv.tabKey,
          sleepTab: sleepTabsByDefault,
          url: wv.url,
          pageTitle: wv.pageTitle,
          chatRemovalActive: wv.chatRemovalActive,
          historyBack: wv.historyBack,
          historyForward: wv.historyForward,
          isLocked: wv.isLocked,
          isLockFull: wv.isLockFull,
          customName: wv.customName,
          customNameInTitle: wv.customNameInTitle,
          customNameInTab: wv.customNameInTab,
          lastUsedTime: wv.lastUsedTime,
        );
      } else {
        await addHiddenTab(
          url: wv.url,
          pageTitle: wv.pageTitle,
          chatRemovalActive: wv.chatRemovalActive,
          historyBack: wv.historyBack,
          historyForward: wv.historyForward,
          isLocked: wv.isLocked,
          isLockFull: wv.isLockFull,
          customName: wv.customName,
          customNameInTitle: wv.customNameInTitle,
          customNameInTab: wv.customNameInTab,
        );
      }
    }

    // Make sure we start at the first tab. We don't need to call activateTab because we have
    // still not initialised completely and the StackView is not live
    if (recallLastSession && useTabs) {
      int lastActive = await Prefs().getWebViewLastActiveTab();
      if (lastActive < 0) lastActive = 0;
      if (lastActive <= _tabList.length - 1) {
        currentTab = lastActive;
      } else {
        currentTab = 0;
      }

      // Awake WebView if we are recalling it
      if (_tabList[currentTab].sleepTab) {
        _tabList[currentTab].sleepTab = false;
        _tabList[currentTab].webView = _buildRealWebViewFromSleeping(_tabList[currentTab].sleepingWebView!);
      }
    } else {
      currentTab = 0;
    }
  }

  // TODO: old references to [windowId] can theoretically be removed since we are no longer using the windowId to open new tabs
  // (as we now use the [_openNewTabFromWindowRequest] method in WebViewFull and avoid creating new windows)
  Future addTab({
    GlobalKey? tabKey,
    int? windowId,
    bool sleepTab = false,
    String? url = "https://www.torn.com",
    String? pageTitle = "",
    bool? chatRemovalActive,
    List<String?>? historyBack,
    List<String?>? historyForward,
    bool isChainingBrowser = false,
    ChainingPayload? chainingPayload,
    bool allowDownloads = true,
    bool isLocked = false,
    bool isLockFull = false,
    String customName = "",
    bool customNameInTitle = false,
    bool customNameInTab = true,
    int lastUsedTime = 0,
  }) async {
    chatRemovalActive = chatRemovalActive ?? chatRemovalActiveGlobal;
    final key = GlobalKey<WebViewFullState>();
    _tabList.add(
      TabDetails()
        ..sleepTab = sleepTab
        ..webViewKey = key
        ..webView = sleepTab
            ? null
            : WebViewFull(
                windowId: windowId,
                customUrl: url,
                key: key,
                useTabs: true,
                chatRemovalActive: chatRemovalActive,
                isChainingBrowser: isChainingBrowser,
                chainingPayload: chainingPayload,
                allowDownloads: allowDownloads,
              )
        ..sleepingWebView = sleepTab
            ? SleepingWebView(
                customUrl: url,
                key: key,
                useTabs: true,
                chatRemovalActive: chatRemovalActive,
                isChainingBrowser: isChainingBrowser,
                chainingPayload: chainingPayload,
                allowDownloads: allowDownloads,
              )
            : null
        ..pageTitle = pageTitle
        ..currentUrl = url
        ..chatRemovalActiveTab = chatRemovalActive
        ..historyBack = historyBack ?? <String>[]
        ..historyForward = historyForward ?? <String>[]
        ..isChainingBrowser = isChainingBrowser
        ..isLocked = isLocked
        ..isLockFull = isLockFull
        ..customName = customName
        ..customNameInTitle = customNameInTitle
        ..customNameInTab = customNameInTab
        ..lastUsedTimeDT = DateTime.fromMillisecondsSinceEpoch(lastUsedTime),
    );
    notifyListeners();
    _callAssessMethods();
  }

  /// If we are not using tabs, we still need to add 'hidden tabs' (that is, with the main info that needs to be
  /// saved, but without the actual webView), so that if the other browser type uses tabs, these are not lost
  /// between sessions.
  Future addHiddenTab({
    String? url = "https://www.torn.com",
    String? pageTitle = "Torn",
    bool? chatRemovalActive,
    List<String?>? historyBack,
    List<String?>? historyForward,
    bool isLocked = false,
    bool isLockFull = false,
    String customName = "",
    bool customNameInTitle = false,
    bool customNameInTab = true,
  }) async {
    chatRemovalActive = chatRemovalActive ?? chatRemovalActiveGlobal;
    _tabList.add(
      TabDetails()
        ..currentUrl = url
        ..pageTitle = pageTitle
        ..chatRemovalActiveTab = chatRemovalActive
        ..historyBack = historyBack ?? <String>[]
        ..historyForward = historyForward ?? <String>[]
        ..isLocked = isLocked
        ..isLockFull = isLockFull
        ..customName = customName
        ..customNameInTitle = customNameInTitle
        ..customNameInTab = customNameInTab,
    );
    _saveTabs();
  }

  Future<void> removeTab({int? position, bool calledFromTab = false}) async {
    if (calledFromTab) {
      position = currentTab;
    }

    if (position == null || position == 0) return;

    final bool wasLast = currentTab == _tabList.length - 1 || false;

    // If we remove the current tab, we need to decrease the current tab by 1
    if (position == currentTab) {
      currentTab = position - 1;

      // Awake WebView if necessary
      final activated = _tabList[currentTab];
      if (activated.sleepTab) {
        activated.sleepTab = false;
        activated.webView = _buildRealWebViewFromSleeping(activated.sleepingWebView!);
      }

      _tabList[currentTab].webViewKey?.currentState?.resumeThisWebview();
    } else if (currentTab == _tabList.length - 1) {
      // If upon removal of any other, the last tab is active, we also decrease the current tab by 1 (-2 from length)
      currentTab = _tabList.length - 2;
    }

    // If the tab removed was the last and therefore we activate the [now] last tab, we need to resume timers
    if (wasLast) {
      _tabList[currentTab].webViewKey?.currentState?.resumeThisWebview();
      // Notify listeners first so that the tab changes
      notifyListeners();
      // Then wait 200 milliseconds so that the animated stack view changes its child
      await Future.delayed(const Duration(milliseconds: 200));
      // As we have changed the tab, call assess methods
      _callAssessMethods();
      // Only then remove the tab and notify again below
    }

    _tabList.removeAt(position);
    notifyListeners();
    _saveTabs();
  }

  void wipeTabs({
    required bool includeLockedTabs,
    required TabsWipeTimeRange timeRange,
  }) {
    DateTime now = DateTime.now();
    Duration thresholdDuration = timeRange.duration;
    DateTime thresholdTime = now.subtract(thresholdDuration);

    if (timeRange == TabsWipeTimeRange.any) {
      // If 'any', remove all tabs except the first and maybe locked
      _tabList.removeWhere((tab) {
        // Keep first tab
        if (tab == _tabList[0]) {
          return false;
        }

        if (!includeLockedTabs && tab.isLocked) {
          return false;
        }

        return true;
      });
    } else {
      // If other than 'any', apply time conditino
      _tabList.removeWhere((tab) {
        if (tab == _tabList[0]) {
          return false;
        }

        if (!includeLockedTabs && tab.isLocked) {
          return false;
        }

        if (tab.lastUsedTimeDT!.isBefore(thresholdTime)) {
          return true;
        }

        return false;
      });
    }

    // Default to tab 0 to avoid issues
    currentTab = 0;
    _tabList[0].webViewKey?.currentState?.resumeThisWebview();

    notifyListeners();
    _saveTabs();
  }

  void activateTab(int newActiveTab) {
    if (_tabList.isEmpty || _tabList.length - 1 < newActiveTab) return;

    // Avoid activating the same tab again (pause/resume could cause issues if call on iOS)
    if (newActiveTab == currentTab) return;

    final deactivated = _tabList[currentTab];
    deactivated.webViewKey?.currentState?.pauseThisWebview();

    currentTab = newActiveTab;
    final activated = _tabList[currentTab];

    // Log time at which time the tab is last used
    activated.lastUsedTimeDT = DateTime.now();

    // Awake WebView if necessary
    if (activated.sleepTab) {
      activated.sleepTab = false;
      activated.webView = _buildRealWebViewFromSleeping(activated.sleepingWebView!);
    }

    activated.webViewKey?.currentState?.resumeThisWebview();

    _callAssessMethods();
    notifyListeners();
    _saveCurrentActiveTabPosition();
  }

  /// Transform tabs that have not been used for a few hours in sleeping tabs to save resources
  Future<void> _sleepOldTabs() async {
    final bool sleepTabsByDefault = await Prefs().getOnlyLoadTabsWhenUsed();
    if (!sleepTabsByDefault) return;
    if (_tabList.isEmpty) return;

    final DateTime now = DateTime.now();
    for (var i = 0; i < _tabList.length; i++) {
      if (i == 0) continue;

      // Might happen when users upgrade to v3.1.0
      if (_tabList[i].lastUsedTimeDT == null) return;

      // Only sleep if 24 hours have elapsed
      final Duration timeDifference = now.difference(_tabList[i].lastUsedTimeDT!);
      if (timeDifference.inHours < 24) return;

      if (_tabList[i].webView != null && !_tabList[i].isChainingBrowser && _tabList[i] != _tabList[currentTab]) {
        final newSleeper = _tabList[i];
        newSleeper.sleepTab = true;
        newSleeper.webView = null;
        newSleeper.sleepingWebView = SleepingWebView(
          customUrl: _tabList[i].currentUrl,
          key: _tabList[i].webViewKey,
          useTabs: true,
          chatRemovalActive: _tabList[i].chatRemovalActiveTab,
        );
        log("Slept tab with ${timeDifference.inHours} hours!");
      }
    }
  }

  void updateLastTabUse() {
    final tab = _tabList[currentTab];
    // Log time at which time the tab is last used
    tab.lastUsedTimeDT = DateTime.now();
  }

  Widget _buildRealWebViewFromSleeping(SleepingWebView sleeping) {
    return WebViewFull(
      customUrl: sleeping.customUrl,
      key: sleeping.key,
      useTabs: true,
      chatRemovalActive: sleeping.chatRemovalActive,
      isChainingBrowser: sleeping.isChainingBrowser,
      chainingPayload: sleeping.chainingPayload,
      allowDownloads: sleeping.allowDownloads,
    );
  }

  void rebuildUnresponsiveWebView({required bool isChainingBrowser, required dynamic chainingPayload}) {
    final crashedTab = _tabList[currentTab];

    // Reconnect the controller and widgets with a new key
    final newKey = GlobalKey<WebViewFullState>();

    crashedTab.webView = WebViewFull(
      customUrl: crashedTab.currentUrl,
      key: newKey,
      useTabs: true,
      chatRemovalActive: crashedTab.chatRemovalActiveTab,
      isChainingBrowser: isChainingBrowser,
      chainingPayload: chainingPayload,
      allowDownloads: true,
    );

    _tabList[currentTab].webView = crashedTab.webView;
    _tabList[currentTab].webViewKey = newKey;

    _callAssessMethods();
    notifyListeners();
    _saveCurrentActiveTabPosition();
  }

  void pauseCurrentWebview() {
    if (_tabList.isEmpty) return;
    log("Pausing current webview!");
    final currentTab = _tabList[this.currentTab];
    currentTab.webViewKey?.currentState?.pauseThisWebview();
  }

  void resumeCurrentWebview() {
    if (_tabList.isEmpty) return;
    log("Resuming current webview!");
    final currentTab = _tabList[this.currentTab];
    currentTab.webViewKey?.currentState?.resumeThisWebview();
  }

  void pauseAllWebviews() {
    if (Platform.isWindows) return;
    if (browserDoNotPauseWebview) return;

    try {
      if (_tabList.isEmpty) return;
      final currentTab = _tabList[this.currentTab];
      // NOTE: IOS only stops the current active webview
      currentTab.webViewKey?.currentState?.webViewController?.pauseTimers();
    } catch (e, trace) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Pausing Webviews");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }
  }

  void resumeAllWebviews() {
    try {
      if (Platform.isWindows) return;
      if (_tabList.isEmpty) return;

      final currentTab = _tabList[this.currentTab];
      currentTab.webViewKey?.currentState?.webViewController?.resumeTimers();

      if (Platform.isAndroid) {
        // Android pauses the ones that are not in use
        var pausedAgain = 0;
        if (Platform.isAndroid) {
          for (final tab in _tabList) {
            if (tab != currentTab && !browserDoNotPauseWebview) {
              tab.webViewKey?.currentState?.pauseThisWebview();
              pausedAgain++;
            }
          }
          log("Resuming webviews${Platform.isAndroid ? ' (re-paused $pausedAgain)' : ''}!");
        }
      }
    } catch (e, trace) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Resuming Webviews");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }
  }

  void openUrlDialog() {
    if (_tabList.isEmpty) return;
    final currentTab = _tabList[this.currentTab];
    currentTab.webViewKey?.currentState?.openUrlDialog();
  }

  Future clearCacheAndTabs() async {
    if (_tabList.isEmpty) return;

    // Wait 200 milliseconds for build to finish (if we come from a tab)
    await Future.delayed(const Duration(milliseconds: 200));
    currentTab = 0;
    notifyListeners();
    // Wait 200 milliseconds so that the animated stack view changes to main tab
    await Future.delayed(const Duration(milliseconds: 200));

    Prefs().setWebViewSecondaryTabs('{"tabsSave": []}');
    // Clear session cookie
    Prefs().setWebViewSessionCookie('');

    // Awake remaining tab if necessary
    if (_tabList[0].sleepTab) {
      _tabList[currentTab].sleepTab = false;
      _tabList[currentTab].webView = _buildRealWebViewFromSleeping(_tabList[currentTab].sleepingWebView!);
    }

    _tabList[0].webViewKey?.currentState?.resumeThisWebview();
    _tabList[0].webViewKey?.currentState?.clearCacheAndReload();

    _tabList.removeRange(1, _tabList.length);

    cancelChainingBrowser();

    _saveTabs();
    notifyListeners();
  }

  void reorderTabs(TabDetails movedItem, int oldIndex, int newIndex) {
    _tabList.removeAt(oldIndex);
    _tabList.insert(newIndex, movedItem);
    notifyListeners();
    _saveTabs();
  }

  void reportTabLoadUrl(Key? reporterKey, String newUrl) {
    final tab = getTabFromKey(reporterKey)!;
    final tabIndex = _tabList.indexOf(tab);

    // Tab initialised prevents the first URL (generic to Torn) to be inserted in the history and also forward history
    // from getting removed (first thing the webView does is to visit the generic URL)
    if (tab.initialised) {
      tab.historyForward.clear();
      // Sometimes onLoadStop triggers several times. This prevents adding an entry in the history in this cases
      // by detecting if the URL we are leaving is the same one we are going to. If it is, don't add it as it is
      // still the current page being shown
      if (tab.currentUrl != newUrl) {
        addToHistoryBack(tab: tab, currentUrl: tab.currentUrl, newUrl: newUrl);
      }
    } else {
      tab.initialised = true;
    }
    tab.currentUrl = newUrl;

    // Invalidate icon cache for this tab since URL changed
    if (tabIndex >= 0 && tabIndex < _tabList.length) {
      _tabList[tabIndex].cachedIcon = null;
      _recentlyChangedTabs.add(tabIndex); // Mark as recently changed to force regeneration
    }

    notifyListeners();
    _callAssessMethods();
    _saveTabs();
  }

  void reportTabPageTitle(Key? reporterKey, String? pageTitle) {
    final tab = getTabFromKey(reporterKey)!;
    tab.pageTitle = pageTitle;

    // Pause timers for tabs that load which are not active (e.g. at the initialization, we pause all except the main)
    if (_tabList[currentTab] != tab) {
      tab.webViewKey?.currentState?.pauseThisWebview();
    }

    notifyListeners();
    _saveTabs();
  }

  void reportChatRemovalChange(bool active, bool global) {
    final tab = _tabList[currentTab];
    tab.chatRemovalActiveTab = active;
    if (global) {
      chatRemovalActiveGlobal = active;
      Prefs().setChatRemovalActive(active);
    }
    _saveTabs();
    notifyListeners();
  }

  void removeAllChatsFullScreen() {
    chatRemovalWhileFullScreen = true;
    for (final tab in _tabList) {
      tab.webViewKey?.currentState?.hideChatWhileFullScreen();
    }
  }

  void showAllChatsFullScreen() {
    chatRemovalWhileFullScreen = false;
    for (final tab in _tabList) {
      tab.webViewKey?.currentState?.showChatAfterFullScreen();
    }
  }

  Future _removeAllUserScripts() async {
    for (final tab in _tabList) {
      await tab.webViewKey?.currentState?.removeAllUserScripts();
    }
  }

  void duplicateTab(int index) {
    verticalMenuClose();
    String message = "Added duplicated tab!";
    Color messageColor = Colors.blue;
    if (tabList[index].isChainingBrowser) {
      message = "Chaining tabs can't be duplicated!";
      messageColor = Colors.orange;
    } else {
      addTab(
        url: tabList[index].currentUrl,
        pageTitle: tabList[index].pageTitle,
        sleepTab: true, // Needs sleep tab or it will crash in iOS 15.5 to 15.9
        chatRemovalActive: tabList[index].chatRemovalActiveTab,
        historyBack: tabList[index].historyBack,
        historyForward: tabList[index].historyForward,
      );
    }
    verticalMenuClose();

    BotToast.showText(
      crossPage: false,
      text: message,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: messageColor,
      duration: const Duration(seconds: 1),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  /// [forceLock] can be used to always lock (e.g.: upon a long-press)
  void toggleTabLock({required TabDetails tab, forceLock = false, isLockFull = false}) {
    final currentIndex = _tabList.indexOf(tab);
    if (currentIndex == 0) return;

    final wasLocked = tab.isLocked;

    tab.isLocked = forceLock || !tab.isLocked;
    tab.isLockFull = isLockFull;

    if (!wasLocked && tab.isLocked || wasLocked && !tab.isLocked) {
      final activeKey = _tabList[currentTab].webView?.key;
      _tabList.remove(tab);

      int insertIndex = _tabList.lastIndexWhere((t) => t.isLocked);
      insertIndex = insertIndex < 1 ? 1 : insertIndex + 1;
      _tabList.insert(insertIndex, tab);

      // Restore the active tab
      for (var i = 0; i < _tabList.length; i++) {
        if (_tabList[i].webView?.key == activeKey) {
          activateTab(i);
          break;
        }
      }

      // Handle vertical menu index
      if (verticalMenuIsOpen && verticalMenuCurrentIndex == currentIndex) {
        verticalMenuCurrentIndex = _tabList.indexOf(tab);
      }
    }

    _saveTabs();
    notifyListeners();
  }

  void setTabCustomName({
    required TabDetails tab,
    required String customName,
    required bool customNameInTitle,
    required bool customNameInTab,
  }) {
    tab.customName = customName;
    tab.customNameInTitle = customNameInTitle;
    tab.customNameInTab = customNameInTab;

    _saveTabs();
    notifyListeners();
  }

  void addToHistoryBack({required TabDetails tab, required String? currentUrl, String? newUrl}) {
    if (currentUrl == null) return;
    if (newUrl != null) {
      // Check if both currentUrl and newUrl are in the stuck list
      bool currentIsStuck = urlsWithStuckHistory.any((baseUrl) => currentUrl.startsWith(baseUrl));
      bool newIsStuck = urlsWithStuckHistory.any((baseUrl) => newUrl.startsWith(baseUrl));

      // Only add currentUrl to history if we are not within stuck URLs
      if (!(currentIsStuck && newIsStuck)) {
        tab.historyBack.add(currentUrl);
      }
    } else {
      // If newUrl is null (comes from [tryGoForward]), simply add the currentUrl to history
      tab.historyBack.add(currentUrl);
    }
    if (tab.historyBack.length > 25) {
      tab.historyBack.removeAt(0);
    }
  }

  void addToHistoryForward({required TabDetails tab, required String? url}) {
    tab.historyForward.add(url);
    if (tab.historyForward.length > 25) {
      tab.historyForward.removeAt(0);
    }
  }

  int returnBackPagesNumber() {
    if (_tabList.isNotEmpty) {
      var tab = _tabList[currentTab];
      return tab.historyBack.length;
    }
    return 0;
  }

  int returnForwardPagesNumber() {
    if (_tabList.isNotEmpty) {
      var tab = _tabList[currentTab];
      return tab.historyForward.length;
    }
    return 0;
  }

  bool tryGoBack() {
    final tab = _tabList[currentTab];
    if (tab.historyBack.isNotEmpty) {
      final previous = tab.historyBack.elementAt(tab.historyBack.length - 1);
      addToHistoryForward(tab: tab, url: tab.currentUrl);
      tab.historyBack.removeLast();
      // Call child method directly, otherwise the 'back' button will only work with the first webView
      tab.webViewKey?.currentState?.loadFromExterior(url: previous, omitHistory: true);
      tab.currentUrl = previous;
      _saveTabs();
      BotToast.showText(
        text: "Back",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
      return true;
    } else {
      BotToast.showText(
        text: "Can't go back!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
      return false;
    }
  }

  bool tryGoForward() {
    final tab = _tabList[currentTab];
    if (tab.historyForward.isNotEmpty) {
      final previous = tab.historyForward.elementAt(tab.historyForward.length - 1);

      addToHistoryBack(tab: tab, currentUrl: tab.currentUrl);

      tab.historyForward.removeLast();
      // Call child method directly, otherwise the 'back' button will only work with the first webView
      tab.webViewKey?.currentState?.loadFromExterior(url: previous, omitHistory: true);
      tab.currentUrl = previous;
      _saveTabs();
      BotToast.showText(
        text: "Forward",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
      return true;
    } else {
      BotToast.showText(
        text: "Can't go forward!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
      return false;
    }
  }

  Future<void> assessLoginErrorsFromPdaIcon() async {
    TabDetails tab;

    if (currentTab < 0) currentTab = 0;

    // This might be executed before the browser is ready, so wait for it
    if (_tabList.isEmpty) {
      final start = DateTime.now();
      while (DateTime.now().difference(start).inMilliseconds < 3000 && _tabList.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (_tabList.isNotEmpty) {
      tab = _tabList[currentTab];
      tab.webViewKey?.currentState?.assessErrorCases();
    }
  }

  bool reviveUrl() {
    final tab = _tabList[currentTab];
    if (tab.currentUrl != null) {
      tab.webViewKey?.currentState?.loadFromExterior(url: tab.currentUrl, omitHistory: true);
      _saveTabs();
      return true;
    } else {
      return false;
    }
  }

  void loadMainTabUrl(String? url) {
    if (_tabList.isEmpty) return;
    final tab = _tabList[0];
    tab.webViewKey?.currentState?.loadFromExterior(url: url, omitHistory: false);
    if (currentTab != 0) {
      activateTab(0);
    }
  }

  void convertToChainingBrowser({ChainingPayload? chainingPayload}) {
    if (_tabList.isEmpty) return;
    final tab = _tabList[0];
    tab.isChainingBrowser = true;
    tab.webViewKey?.currentState?.convertToChainingBrowser(chainingPayload: chainingPayload!);
    if (currentTab != 0) {
      activateTab(0);
    }
    _saveTabs();
  }

  void cancelChainingBrowser() {
    if (_tabList.isEmpty) return;
    final tab = _tabList[0];
    tab.isChainingBrowser = false;
    tab.webViewKey?.currentState?.cancelChainingBrowser();
    notifyListeners();
    _saveTabs();
  }

  void loadCurrentTabUrl(String? url) {
    final tab = _tabList[currentTab];
    if (tab.currentUrl != null) {
      tab.webViewKey?.currentState?.loadFromExterior(url: url, omitHistory: false);
      _saveTabs();
    }
  }

  String? currentTabUrl() {
    final tab = _tabList[currentTab];
    if (tab.currentUrl != null) {
      return tab.webViewKey?.currentState?.reportCurrentUrl();
    }
    return "";
  }

  String? currentTabTitle() {
    final tab = _tabList[currentTab];
    if (tab.currentUrl != null) {
      return tab.webViewKey?.currentState?.reportCurrentTitle();
    }
    return "";
  }

  void _saveTabs() {
    // Make sure we don't save just the first tab before the secondaries are saved, otherwise (as secondary take one
    // second to initialise after the main), we'll just save the main and lose the rest if the phone is too quick in
    // loading the main and reporting back URL or page title (which triggers a save)!
    if (!_secondaryInitialised) return;

    final TabSaveModel saveMainModel = TabSaveModel()..tabsSave = <TabsSave>[];
    final TabSaveModel saveSecondaryModel = TabSaveModel()..tabsSave = <TabsSave>[];
    for (var i = 0; i < _tabList.length; i++) {
      if (i == 0) {
        saveMainModel.tabsSave!.add(
          TabsSave()
            ..url = _tabList[0].currentUrl
            ..pageTitle = _tabList[0].pageTitle
            ..chatRemovalActive = _tabList[0].chatRemovalActiveTab
            ..historyBack = _tabList[0].historyBack
            ..historyForward = _tabList[0].historyForward,
        );
      } else {
        saveSecondaryModel.tabsSave!.add(
          TabsSave()
            ..url = _tabList[i].currentUrl
            ..pageTitle = _tabList[i].pageTitle
            ..chatRemovalActive = _tabList[i].chatRemovalActiveTab
            ..historyBack = _tabList[i].historyBack
            ..historyForward = _tabList[i].historyForward
            ..isLocked = _tabList[i].isLocked
            ..isLockFull = _tabList[i].isLockFull
            ..customName = _tabList[i].customName
            ..customNameInTitle = _tabList[i].customNameInTitle
            ..customNameInTab = _tabList[i].customNameInTab
            ..lastUsedTime = _tabList[i].lastUsedTimeDT?.millisecondsSinceEpoch ?? 0,
        );
      }
    }
    final String mainJson = tabSaveModelToJson(saveMainModel);
    final String secondaryJson = tabSaveModelToJson(saveSecondaryModel);
    Prefs().setWebViewMainTab(mainJson);
    Prefs().setWebViewSecondaryTabs(secondaryJson);
    _saveCurrentActiveTabPosition();
  }

  void _saveCurrentActiveTabPosition() {
    // Ensure tab number is correct before saving active session
    if (currentTab >= _tabList.length) {
      _tabList.length == 1 ? currentTab = 0 : currentTab = _tabList.length - 1;
    }
    Prefs().setWebViewLastActiveTab(currentTab);
  }

  void clearOnDispose() {
    _tabList.clear();
    _secondaryInitialised = false;

    // It is necessary to bring this to 0 so that on opening no checks are performed in tabs that don't exist yet
    currentTab = 0;
  }

  TabDetails? getTabFromKey(Key? reporterKey) {
    for (final tab in _tabList) {
      // Null check because not all webview have a key (sleeping tabs!)
      if (tab.webView?.key == reporterKey) {
        return tab;
      }
    }

    return null;
  }

  void _callAssessMethods() {
    final tab = _tabList[currentTab];

    // Gym and Hunting for Energy
    if (tab.currentUrl!.contains("gym.php") || tab.currentUrl!.contains("index.php?page=hunting")) {
      tab.webViewKey?.currentState?.assessGymAndHuntingEnergyWarning(tab.currentUrl.toString());
    }

    // Travel Agency for Energy, Nerve and Life
    if (tab.currentUrl!.contains("travelagency.php")) {
      tab.webViewKey?.currentState?.assessTravelAgencyEnergyNerveLifeWarning(tab.currentUrl.toString());
    }
  }

  // This can be called from the WebView and ensures that several BotToasts are not shown at the start if
  // several tabs are open to the gym
  void showEnergyWarningMessage(String message, Key? reporterKey) {
    for (final tab in _tabList) {
      // Null check because not all webview have a key (sleeping tabs!)
      if (tab.webView?.key == reporterKey) {
        if (!_gymMessageActive) {
          _gymMessageActive = true;
          BotToast.showText(
            crossPage: false,
            text: message,
            align: const Alignment(0, 0),
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.blue,
            contentPadding: const EdgeInsets.all(10),
          );
          Future.delayed(const Duration(seconds: 3)).then((value) => _gymMessageActive = false);
        }
      }
    }
  }

  void changeTextScale(int size) {
    for (final tab in _tabList) {
      tab.webViewKey?.currentState?.setBrowserTextScale(size);
    }
  }

  void changeUseTabIcons(bool useIcons) {
    _useTabIcons = useIcons;
    Prefs().setUseTabsIcons(useIcons);
    notifyListeners();
  }

  void toggleHideTabs() {
    _hideTabs = !_hideTabs;
    Prefs().setHideTabs(_hideTabs);
    notifyListeners();
  }

  Future openBrowserPreference({
    required BuildContext context,
    required String? url,
    required BrowserTapType browserTapType,
    bool recallLastSession = false,
    // Chaining
    final bool isChainingBrowser = false,
    final ChainingPayload? chainingPayload,
  }) async {
    // Checking _tabList might not be enough to ensure that the browser is closed. We might get duplicates
    // with double presses or even notifications, try to open the browser twice (creating repeated keys)
    // This ensures that a browser open request only happens once
    if (_lastBrowserOpenedTime != null && (DateTime.now().difference(_lastBrowserOpenedTime!).inMilliseconds) < 1500) {
      return;
    }
    _lastBrowserOpenedTime = DateTime.now();

    final WebViewProvider w = Provider.of<WebViewProvider>(context, listen: false);

    final UiMode uiMode = _decideBrowserScreenMode(tapType: browserTapType, context: context);
    setCurrentUiMode(uiMode, context);

    final browserType = await Prefs().getDefaultBrowser();
    if (browserType == 'app') {
      analytics?.logScreenView(screenName: 'browser_full');

      String? authUrl = await _assessNativeAuth(inputUrl: url, context: context);

      w.stackView = WebViewStackView(
        initUrl: authUrl,
        recallLastSession: recallLastSession,
        isChainingBrowser: isChainingBrowser,
        chainingPayload: chainingPayload,
      );

      loadMainTabUrl(authUrl);

      if (isChainingBrowser) {
        convertToChainingBrowser(chainingPayload: chainingPayload);
      }

      w.browserShowInForeground = true;

      if (currentUiMode == UiMode.fullScreen &&
          Provider.of<SettingsProvider>(context, listen: false).fullScreenRemovesChat) {
        removeAllChatsFullScreen();
      }
    } else {
      if (await canLaunchUrl(Uri.parse(url!))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  UiMode _decideBrowserScreenMode({required BrowserTapType tapType, required BuildContext context}) {
    final SettingsProvider settings = Provider.of<SettingsProvider>(context, listen: false);
    bool wantsFullScreen;
    switch (tapType) {
      case BrowserTapType.chainShort:
        wantsFullScreen = settings.fullScreenByShortChainingTap;
        break;
      case BrowserTapType.chainLong:
        wantsFullScreen = settings.fullScreenByLongChainingTap;
        break;
      case BrowserTapType.short:
        wantsFullScreen = settings.fullScreenByShortTap;
        break;
      case BrowserTapType.long:
        wantsFullScreen = settings.fullScreenByLongTap;
        break;
      case BrowserTapType.notification:
        wantsFullScreen = settings.fullScreenByNotificationTap;
        break;
      case BrowserTapType.deeplink:
        wantsFullScreen = settings.fullScreenByDeepLinkTap;
        break;
      case BrowserTapType.quickItem:
        wantsFullScreen = settings.fullScreenByQuickItemTap;
        break;
    }
    return wantsFullScreen ? UiMode.fullScreen : UiMode.window;
  }

  void changeTornTheme({required bool dark}) {
    if (!dark) {
      pendingThemeSync = "light";
    } else {
      pendingThemeSync = "dark";
    }
  }

  void closeWebViewFromOutside() {
    final tab = _tabList[currentTab];
    tab.webViewKey?.currentState?.closeBrowserFromOutside();
  }

  void reloadFromOutside() {
    final tab = _tabList[currentTab];
    tab.webViewKey?.currentState?.reloadFromOutside();
  }

  void passHealingChoiceFromOutside(HealingPages choice) {
    final tab = _tabList[currentTab];
    tab.webViewKey?.currentState?.openHealingPage(choice);
  }

  void passOpenCloseChainWidgetFromOutside() {
    final tab = _tabList[currentTab];
    tab.webViewKey?.currentState?.openCloseChainWidgetFromOutside();
  }

  void passNextChainAttackFromOutside() {
    final tab = _tabList[currentTab];
    tab.webViewKey?.currentState?.nextChainAttack();
  }

  /// At least used in the following cases:
  /// 1.- On main tab init: in case the user only uses the browser, it will fire after an app's launch when browser rebuilds
  /// 2.- Whenever the user launches the browser from a tap (other than the PDA icon, which does not load any URL itself)
  Future<String?> _assessNativeAuth({required String? inputUrl, required BuildContext context}) async {
    final NativeUserProvider nativeUser = context.read<NativeUserProvider>();
    final NativeAuthProvider nativeAuth = context.read<NativeAuthProvider>();

    if (nativeUser.playerLastLoginMethod == NativeLoginType.none) {
      log("No native user enabled, skipping auth!");
      return inputUrl;
    }

    try {
      final String originalInitUrl = inputUrl!;
      String authUrlToLoad;
      if (!originalInitUrl.contains("torn.com")) return inputUrl;
      // Auth redirects to attack pages might fail
      if (originalInitUrl.contains("loader.php?sid=attack&user")) return inputUrl;

      final int elapsedSinceLastAuth = DateTime.now().difference(nativeAuth.lastAuthRedirect).inHours;
      if (elapsedSinceLastAuth > 6) {
        log("Entering auth process!");

        bool error = false;

        // Tentative immediate change, so that other opening tabs don't auth as well
        nativeAuth.lastAuthRedirect = DateTime.now();
        log("Getting auth URL!");
        try {
          final TornLoginResponseContainer loginResponse = await nativeAuth.requestTornRecurrentInitData(
            context: context,
            loginData: GetInitDataModel(
              playerId: UserHelper.playerId,
              sToken: nativeUser.playerSToken,
            ),
          );

          if (loginResponse.success) {
            // Join the standard Auth URL and the original URL requested as part of the redirect parameter
            authUrlToLoad = loginResponse.authUrl + originalInitUrl;
            log("Auth URL: $authUrlToLoad");
          } else {
            error = true;
            log("Auth URL failed: ${loginResponse.message}");
          }
        } catch (e) {
          error = true;
          log("Auth URL catch: $e");
        }

        if (error) {
          // Reset time with some delay, so that rapidly opening tabs don't cause
          Future.delayed(const Duration(seconds: 2)).then((_) {
            nativeAuth.lastAuthRedirect = DateTime.fromMicrosecondsSinceEpoch(elapsedSinceLastAuth);
          });

          String errorMessage = "Authentication error, please check your username and password in Settings!";
          if (nativeAuth.authErrorsInSession >= 3) {
            nativeAuth.authErrorsInSession = 0;
            errorMessage = "Too many authentication errors, your username and password have been erased in "
                "Torn PDA settings as a precaution!";
            nativeUser.eraseUserPreferences();
          } else {
            nativeAuth.authErrorsInSession++;
          }

          BotToast.showText(
            text: errorMessage,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.red,
            duration: const Duration(seconds: 4),
            contentPadding: const EdgeInsets.all(10),
          );
        }
      }
    } catch (e) {
      //
    }

    return inputUrl;
  }

  void updatePullToRefresh(BrowserRefreshSetting? value) {
    if (_tabList.isEmpty) return;
    for (final tab in _tabList) {
      // Null check because not all webview have a key (sleeping tabs!)
      tab.webViewKey?.currentState?.updatePullToRefresh(value);
    }
  }

  /// Gets the appropriate icon color based on the current theme
  Color _getIconColor(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    return themeProvider.currentTheme == AppTheme.light ? Colors.black : Colors.white;
  }

  // Special users configuration - can be made configurable via settings in the future
  static const Map<String, Color> _specialUsers = {
    "2225097": Colors.pink, // Manuito
    "2190604": Colors.pink, // Kwack
  };

  /// Returns icons for special users
  Widget? _getSpecialUserIcon(String url, Color defaultIconColor) {
    // Check for attack pages with special users
    for (final entry in _specialUsers.entries) {
      final userId = entry.key;
      final color = entry.value;

      if (url.contains("sid=attack&user2ID=$userId") || url.contains("sid=getInAttack&user2ID=$userId")) {
        return Icon(MdiIcons.pistol, color: color);
      }
    }

    // Check for profile pages with special users
    for (final entry in _specialUsers.entries) {
      final userId = entry.key;
      final color = entry.value;

      if (url.contains("profiles.php?XID=$userId")) {
        return Icon(Icons.person, color: color);
      }
    }

    // Check for specific forum threads
    if (url.contains("https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0")) {
      return const ImageIcon(AssetImage('images/icons/home/forums.png'), color: Colors.pink);
    }

    return null;
  }

  /// Check if a user is special or get all special user IDs
  /// If [userId] is provided, returns true/false if the user is special
  /// If [userId] is null, returns the list of all special user IDs
  dynamic getSpecialUserInfo([String? userId]) {
    if (userId != null) {
      return _specialUsers.containsKey(userId);
    }
    return _specialUsers.keys.toList();
  }

  /// Helper method to get special user color (for external use)
  Color? getSpecialUserColor(String userId) {
    return _specialUsers[userId];
  }

  /// Get icon for specific tab index - uses cache and updates if necessary
  Widget getTabIcon(int index, BuildContext context) {
    // Validate index bounds
    if (index < 0 || index >= _tabList.length) {
      return Icon(Icons.error, color: _getIconColor(context));
    }

    final tab = _tabList[index];

    // Always regenerate icon for recently changed tabs (ignore cache)
    if (_recentlyChangedTabs.contains(index)) {
      tab.cachedIcon = _generateIcon(index, context);
      _recentlyChangedTabs.remove(index);
      return tab.cachedIcon!;
    }

    // If icon is not cached, generate it
    tab.cachedIcon ??= _generateIcon(index, context);

    return tab.cachedIcon!;
  }

  /// Generate icon for a specific tab (internal method)
  Widget _generateIcon(int index, BuildContext context) {
    if (index >= _tabList.length) {
      return Icon(Icons.error, color: _getIconColor(context));
    }

    final tab = _tabList[index];
    final url = tab.currentUrl!;
    final iconColor = _getIconColor(context);

    // Check special cases first (chaining browser)
    if (tab.isChainingBrowser) {
      return const Icon(MdiIcons.linkVariant, color: Colors.red);
    }

    // Check for specific user icons (special colored)
    final specialUserIcon = _getSpecialUserIcon(url, iconColor);
    if (specialUserIcon != null) {
      return specialUserIcon;
    }

    // Check standard URL patterns
    final standardIcon = _getStandardIcon(url, iconColor);
    if (standardIcon != null) {
      return standardIcon;
    }

    // Check external sites
    final externalIcon = _getExternalSiteIcon(url);
    if (externalIcon != null) {
      return externalIcon;
    }

    // Check non-Torn sites
    if (!url.contains("torn.com")) {
      return Icon(Icons.public, size: 22, color: iconColor);
    }

    // Try shortcuts provider as fallback
    return _getShortcutIcon(url, context, iconColor);
  }

  /// Returns icons for standard Torn pages
  Widget? _getStandardIcon(String url, Color iconColor) {
    final Map<String, dynamic> iconMappings = {
      // Attack pages
      "sid=attack&user2ID=": {'type': 'icon', 'icon': MdiIcons.pistol},
      "sid=getInAttack&user2ID=": {'type': 'icon', 'icon': MdiIcons.pistol},
      "sid=attackLog&ID=": {'type': 'icon', 'icon': MdiIcons.notebookOutline},

      "index.php?page=hunting": {'type': 'icon', 'icon': MdiIcons.target, 'size': 20.0},

      "messages.php": {'type': 'asset', 'path': 'images/icons/home/messages.png'},
      "sid=messages": {'type': 'asset', 'path': 'images/icons/home/messages.png'},

      "events.php": {'type': 'asset', 'path': 'images/icons/home/events.png'},
      "sid=events": {'type': 'asset', 'path': 'images/icons/home/events.png'},

      "awards.php": {'type': 'asset', 'path': 'images/icons/home/awards.png'},
      "sid=awards": {'type': 'asset', 'path': 'images/icons/home/awards.png'},
      "calendar.php": {'type': 'icon', 'icon': MdiIcons.calendar, 'size': 20.0},

      "profiles.php": {'type': 'icon', 'icon': Icons.person},

      "laptop.php": {'type': 'asset', 'path': 'images/icons/home/laptop.png'},
      "sid=laptop": {'type': 'asset', 'path': 'images/icons/home/laptop.png'},

      "personalstats.php": {'type': 'asset', 'path': 'images/icons/home/stats.png'},
      "sid=personalstats": {'type': 'asset', 'path': 'images/icons/home/stats.png'},

      "halloffame.php": {'type': 'asset', 'path': 'images/icons/home/hall_fame.png'},
      "sid=halloffame": {'type': 'asset', 'path': 'images/icons/home/hall_fame.png'},

      "friendlist.php": {'type': 'asset', 'path': 'images/icons/home/friends.png'},
      "sid=friends": {'type': 'asset', 'path': 'images/icons/home/friends.png'},

      "blacklist.php": {'type': 'asset', 'path': 'images/icons/home/enemies.png'},
      "sid=enemies": {'type': 'asset', 'path': 'images/icons/home/enemies.png'},

      "city.php": {'type': 'asset', 'path': 'images/icons/home/city.png'},
      "sid=city": {'type': 'asset', 'path': 'images/icons/home/city.png'},

      "companies.php": {'type': 'asset', 'path': 'images/icons/home/job.png'},
      "joblist.php": {'type': 'asset', 'path': 'images/icons/home/job.png'},
      "jobs.php": {'type': 'asset', 'path': 'images/icons/home/job.png'},
      "sid=jobs": {'type': 'asset', 'path': 'images/icons/home/job.png'},

      "gym.php": {'type': 'asset', 'path': 'images/icons/map/gym.png'},
      "sid=gym": {'type': 'asset', 'path': 'images/icons/map/gym.png'},

      "properties.php": {'type': 'asset', 'path': 'images/icons/map/property.png'},
      "sid=properties": {'type': 'asset', 'path': 'images/icons/map/property.png'},

      "education.php": {'type': 'asset', 'path': 'images/icons/map/education.png'},
      "sid=education": {'type': 'asset', 'path': 'images/icons/map/education.png'},

      "crimes.php": {'type': 'asset', 'path': 'images/icons/home/crimes.png'},
      "sid=crimes": {'type': 'asset', 'path': 'images/icons/home/crimes.png'},

      "loader.php?sid=missions": {'type': 'asset', 'path': 'images/icons/home/missions.png'},
      "sid=missions": {'type': 'asset', 'path': 'images/icons/home/missions.png'},

      "bounties.php": {'type': 'asset', 'path': 'images/icons/home/bounty.png'},
      "sid=bounties": {'type': 'asset', 'path': 'images/icons/home/bounty.png'},

      "newspaper.php": {'type': 'asset', 'path': 'images/icons/home/newspaper.png'},
      "sid=newspaper": {'type': 'asset', 'path': 'images/icons/home/newspaper.png'},

      "jailview.php": {'type': 'asset', 'path': 'images/icons/map/jail.png'},
      "sid=jail": {'type': 'asset', 'path': 'images/icons/map/jail.png'},

      "hospitalview.php": {'type': 'asset', 'path': 'images/icons/map/hospital.png'},
      "sid=hospital": {'type': 'asset', 'path': 'images/icons/map/hospital.png'},

      "forums.php": {'type': 'asset', 'path': 'images/icons/home/forums.png'},
      "sid=forums": {'type': 'asset', 'path': 'images/icons/home/forums.png'},

      "factions.php": {'type': 'asset', 'path': 'images/icons/home/faction.png'},
      "sid=factions": {'type': 'asset', 'path': 'images/icons/home/faction.png'},

      "trade.php": {'type': 'asset', 'path': 'images/icons/inventory/trades.png'},
      "sid=trade": {'type': 'asset', 'path': 'images/icons/inventory/trades.png'},

      "bazaar.php": {'type': 'asset', 'path': 'images/icons/inventory/bazaar.png'},
      "sid=bazaar": {'type': 'asset', 'path': 'images/icons/inventory/bazaar.png'},

      "item.php": {'type': 'asset', 'path': 'images/icons/home/items.png'},
      "sid=items": {'type': 'asset', 'path': 'images/icons/home/items.png'},

      "imarket.php": {'type': 'asset', 'path': 'images/icons/map/item_market.png'},
      "sid=imarket": {'type': 'asset', 'path': 'images/icons/map/item_market.png'},
      "sid=ItemMarket": {'type': 'asset', 'path': 'images/icons/map/item_market.png'},

      "amarket.php": {'type': 'asset', 'path': 'images/icons/map/auction_house.png'},
      "sid=amarket": {'type': 'asset', 'path': 'images/icons/map/auction_house.png'},

      "pmarket.php": {'type': 'asset', 'path': 'images/icons/map/points_market.png'},
      "sid=pmarket": {'type': 'asset', 'path': 'images/icons/map/points_market.png'},

      "casino.php": {'type': 'asset', 'path': 'images/icons/map/casino.png'},
      "sid=casino": {'type': 'asset', 'path': 'images/icons/map/casino.png'},

      "points.php": {'type': 'asset', 'path': 'images/icons/map/points_building.png'},
      "sid=points": {'type': 'asset', 'path': 'images/icons/map/points_building.png'},

      "dump.php": {'type': 'asset', 'path': 'images/icons/map/dump.png'},
      "sid=dump": {'type': 'asset', 'path': 'images/icons/map/dump.png'},

      "bank.php": {'type': 'asset', 'path': 'images/icons/map/bank.png'},
      "sid=bank": {'type': 'asset', 'path': 'images/icons/map/bank.png'},

      "page.php?sid=stocks": {'type': 'asset', 'path': 'images/icons/map/stock_exchange.png'},
      "sid=stocks": {'type': 'asset', 'path': 'images/icons/map/stock_exchange.png'},

      "travelagency.php": {'type': 'asset', 'path': 'images/icons/map/travel_agency.png'},
      "sid=travel": {'type': 'asset', 'path': 'images/icons/map/travel_agency.png'},

      "loader.php?sid=racing": {'type': 'asset', 'path': 'images/icons/map/race_track.png'},
      "sid=racing": {'type': 'asset', 'path': 'images/icons/map/race_track.png'},
    };

    // Check each URL pattern
    for (final entry in iconMappings.entries) {
      if (url.contains(entry.key)) {
        final iconData = entry.value;

        switch (iconData['type']) {
          case 'icon':
            return Icon(
              iconData['icon'],
              color: iconColor,
              size: iconData['size'],
            );
          case 'asset':
            return Image.asset(iconData['path'], color: iconColor);
          case 'imageicon':
            return ImageIcon(AssetImage(iconData['path']), color: iconColor);
        }
      }
    }

    // Special case for home page URLs that were not caught by a more specific rule
    if (url == "https://www.torn.com" || url == "https://www.torn.com/" || url == "https://www.torn.com/index.php") {
      return ImageIcon(const AssetImage('images/icons/home/home.png'), color: iconColor);
    }

    return null;
  }

  /// Returns icons for external sites
  Widget? _getExternalSiteIcon(String url) {
    final externalSites = {
      "yata.yt": 'images/icons/yata_logo.png',
      "tornstats.com/": 'images/icons/tornstats_logo.png',
      "tornexchange.com/": 'images/icons/tornexchange_logo.png',
      "arsonwarehouse.com/": 'images/icons/awh_logo2.png',
    };

    for (final entry in externalSites.entries) {
      if (url.contains(entry.key)) {
        return Image.asset(entry.value);
      }
    }

    return null;
  }

  /// Returns icon from shortcuts provider or default icon
  Widget _getShortcutIcon(String url, BuildContext context, Color iconColor) {
    // Note: some URLs are not found in shortcuts because the value from OnLoadStop in the WebView
    // differs from the standard URL in shortcuts. That's why some are handled manually above.
    final shortProvider = context.read<ShortcutsProvider>();

    for (final short in shortProvider.allShortcuts) {
      if (url.contains(short.url!)) {
        final shortcutIcon = ImageIcon(
          AssetImage(short.iconUrl!),
          color: iconColor,
        );
        // Return if the coincidence is not with the default shortcut
        if (short.name != "Home") {
          return shortcutIcon;
        }
      }
    }

    // Default fallback icon
    return ImageIcon(const AssetImage('images/icons/pda_icon.png'), color: iconColor);
  }

  Future restorePreferences() async {
    _removeUnusedTabs = await Prefs().getRemoveUnusedTabs();
    _removeUnusedTabsIncludesLocked = await Prefs().getRemoveUnusedTabsIncludesLocked();
    final daysFromSave = await Prefs().getRemoveUnusedTabsRangeDays();
    switch (daysFromSave) {
      case 1:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.oneDay;
      case 2:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.twoDays;
      case 3:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.threeDays;
      case 5:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.fiveDays;
      case 7:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.sevenDays;
      case 15:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.fifteenDays;
      case 30:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.oneMonth;
      default:
        _removeUnusedTabsRangeDays = TabsWipeTimeRange.sevenDays;
    }

    _onlyLoadTabsWhenUsed = await Prefs().getOnlyLoadTabsWhenUsed();
    _automaticChangeToNewTabFromURL = await Prefs().getAutomaticChangeToNewTabFromURL();

    _fabEnabled = await Prefs().getWebviewFabEnabled();
    _fabShownNow = await Prefs().getWebviewFabShownNow();
    _fabDirection = await Prefs().getWebviewFabDirection();
    _fabSavedPositionXY = await Prefs().getWebviewFabPositionXY();
    _fabOnlyFullScreen = await Prefs().getWebviewFabOnlyFullScreen();
    _fabButtonCount = await Prefs().getFabButtonCount();
    _fabButtonActions = await Prefs().getFabButtonActions();
    _fabDoubleTapAction = await Prefs().getFabDoubleTapAction();
    _fabTripleTapAction = await Prefs().getFabTripleTapAction();

    _browserDoNotPauseWebview = await Prefs().getBrowserDoNotPauseWebviews();

    String splitType = await Prefs().getSplitScreenWebview();
    switch (splitType) {
      case "off":
        _webViewSplitPosition = WebViewSplitPosition.off;
      case "left":
        _webViewSplitPosition = WebViewSplitPosition.left;
      case "right":
        _webViewSplitPosition = WebViewSplitPosition.right;
    }

    _splitScreenRevertsToApp = await Prefs().getSplitScreenRevertsToApp();
  }

  bool splitScreenAndBrowserLeft() {
    return webViewSplitActive && splitScreenPosition == WebViewSplitPosition.left;
  }

  void togglePeriodicUnusedTabsRemovalRequest({required bool enable}) {
    final pc = Get.find<PeriodicExecutionController>();
    if (enable) {
      pc.registerTask(
        "removeUnusedTabs",
        () => wipeTabs(
          includeLockedTabs: removeUnusedTabsIncludesLocked,
          timeRange: removeUnusedTabsRangeDays,
        ),
        intervalInHours: 24,
        executeImmediately: true,
        overwrite: true,
      );
    } else {
      pc.cancelTask("removeUnusedTabs");
    }
  }

  void assessPeriodidTabRemovalOnLaunch() {
    if (!removeUnusedTabs) return;

    final pc = Get.find<PeriodicExecutionController>();

    pc.registerTask(
      "removeUnusedTabs",
      () => wipeTabs(
        includeLockedTabs: removeUnusedTabsIncludesLocked,
        timeRange: removeUnusedTabsRangeDays,
      ),
      intervalInHours: 24,
      executeImmediately: true,
    );
  }
}
