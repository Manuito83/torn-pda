// Dart imports:

// Flutter imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
//import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/tabsave_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_models.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';

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

class TabDetails {
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
  DateTime? lastUsedTime;
  bool isLocked = false;
  bool isLockFull = false;
  String customName = "";
  bool customNameInTitle = false;
  bool customNameInTab = true;
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

  // Controls successive toastification activations for full lock awareness, since
  // using [toastification.dismissAll()] leaves quite a long gap until next activation is possible
  DateTime? lastLockToastShown;

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

  pdaIconActivation({
    required bool shortTap,
    required BuildContext context,
    required bool automaticLogin,
  }) {
    browserShowInForeground = true;

    if (automaticLogin && context.read<NativeUserProvider>().isNativeUserEnabled()) {
      // When we use the PDA Icon, launch a logout check by default in case we just activated
      // the native user in Settings and are logged out
      assessLoginErrorsFromPdaIcon();
    }

    final SettingsProvider settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.fullScreenIncludesPDAButtonTap) {
      if (shortTap) {
        if (currentUiMode == UiMode.window) {
          if (settings.fullScreenByShortTap) {
            setCurrentUiMode(UiMode.fullScreen, context);
            if (currentUiMode == UiMode.fullScreen &&
                Provider.of<SettingsProvider>(context, listen: false).fullScreenRemovesChat) {
              removeAllChatsFullScreen();
            }
          }
        } else if (currentUiMode == UiMode.fullScreen) {
          if (!settings.fullScreenByShortTap) {
            setCurrentUiMode(UiMode.window, context);
          }
        }
      } else {
        if (currentUiMode == UiMode.window) {
          if (settings.fullScreenByLongTap) {
            setCurrentUiMode(UiMode.fullScreen, context);
            if (currentUiMode == UiMode.fullScreen &&
                Provider.of<SettingsProvider>(context, listen: false).fullScreenRemovesChat) {
              removeAllChatsFullScreen();
            }
          }
        } else if (currentUiMode == UiMode.fullScreen) {
          if (!settings.fullScreenByLongTap) {
            setCurrentUiMode(UiMode.window, context);
          }
        }
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
  setCurrentUiMode(UiMode value, BuildContext context) {
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

  verticalMenuOpen() {
    verticalMenuIsOpen = true;
    notifyListeners();
  }

  verticalMenuClose() {
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

  bool _gymMessageActive = false;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  bool _secondaryInitialised = false;

  DateTime? _lastBrowserOpenedTime;

  var _onlyLoadTabsWhenUsed = true;
  bool get onlyLoadTabsWhenUsed => _onlyLoadTabsWhenUsed;
  set onlyLoadTabsWhenUsed(bool value) {
    _onlyLoadTabsWhenUsed = value;
    Prefs().setOnlyLoadTabsWhenUsed(_onlyLoadTabsWhenUsed);
    notifyListeners();
  }

  /// [recallLastSession] should be used to open a browser session where we left it last time
  Future initialiseMain({
    required String? initUrl,
    required BuildContext context,
    bool recallLastSession = false,
    bool isChainingBrowser = false,
    ChainingPayload? chainingPayload,
    bool restoreSessionCookie = false,
  }) async {
    if (restoreSessionCookie) {
      try {
        final String sessionCookie = await Prefs().getWebViewSessionCookie();
        if (sessionCookie != "") {
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

    _bottomBarStyleEnabled = await Prefs().getBrowserBottomBarStyleEnabled();
    _bottomBarStyleType = await Prefs().getBrowserBottomBarStyleType();
    _browserBottomBarStylePlaceTabsAtBottom = await Prefs().getBrowserBottomBarStylePlaceTabsAtBottom();

    chatRemovalEnabledGlobal = await Prefs().getChatRemovalEnabled();
    chatRemovalActiveGlobal = await Prefs().getChatRemovalActive();

    _useTabIcons = await Prefs().getUseTabsIcons();
    _hideTabs = await Prefs().getHideTabs();

    // If we are sharing the downloads, we need to clear the files in the cache folder (although theoretically the OS
    // should do this for us), as the user might not have access to the cache folder and can't free up space
    await _clearTemporaryDownloadedFiles(context);

    // Add the main opener
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
    _currentTab = 0;
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
        addTab(
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
        );
      } else {
        addHiddenTab(
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
      final int lastActive = await Prefs().getWebViewLastActiveTab();
      if (lastActive <= _tabList.length - 1) {
        _currentTab = lastActive;
      } else {
        _currentTab = 0;
      }

      // Awake WebView if we are recalling it
      if (_tabList[_currentTab].sleepTab) {
        _tabList[_currentTab].sleepTab = false;
        _tabList[_currentTab].webView = _buildRealWebViewFromSleeping(_tabList[_currentTab].sleepingWebView!);
      }
    } else {
      _currentTab = 0;
    }
  }

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
        ..customNameInTab = customNameInTab,
    );
    notifyListeners();
    _callAssessMethods();
  }

  /// If we are not using tabs, we still need to add 'hidden tabs' (that is, with the main info that needs to be
  /// saved, but without the actual webView), so that if the other browser type uses tabs, these are not lost
  /// between sessions.
  void addHiddenTab({
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
  }) {
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
      position = _currentTab;
    }

    if (position == null || position == 0) return;

    final bool wasLast = _currentTab == _tabList.length - 1 || false;

    // If we remove the current tab, we need to decrease the current tab by 1
    if (position == _currentTab) {
      _currentTab = position - 1;

      // Awake WebView if necessary
      final activated = _tabList[_currentTab];
      if (activated.sleepTab) {
        activated.sleepTab = false;
        activated.webView = _buildRealWebViewFromSleeping(activated.sleepingWebView!);
      }

      _tabList[_currentTab].webViewKey?.currentState?.resumeThisWebview();
    } else if (_currentTab == _tabList.length - 1) {
      // If upon removal of any other, the last tab is active, we also decrease the current tab by 1 (-2 from length)
      _currentTab = _tabList.length - 2;
    }

    // If the tab removed was the last and therefore we activate the [now] last tab, we need to resume timers
    if (wasLast) {
      _tabList[_currentTab].webViewKey?.currentState?.resumeThisWebview();
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

  Future<void> wipeTabs() async {
    _currentTab = 0;
    _tabList[0].webViewKey?.currentState?.resumeThisWebview();
    _tabList.removeRange(1, _tabList.length);
    notifyListeners();
    _saveTabs();
  }

  void activateTab(int newActiveTab) {
    if (_tabList.isEmpty || _tabList.length - 1 < newActiveTab) return;

    // Avoid activating the same tab again (pause/resume could cause issues if call on iOS)
    if (newActiveTab == _currentTab) return;

    final deactivated = _tabList[_currentTab];
    deactivated.webViewKey?.currentState?.pauseThisWebview();

    _currentTab = newActiveTab;
    final activated = _tabList[_currentTab];

    // Log time at which the tab is used
    activated.lastUsedTime = DateTime.now();

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
      if (_tabList[i].lastUsedTime == null) return;

      // Only sleep if 24 hours have elapsed
      final Duration timeDifference = now.difference(_tabList[i].lastUsedTime!);
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

  void rebuildUnresponsiveWebView({required isChainingBrowser, required chainingPayload}) {
    final crashedTab = _tabList[_currentTab];

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

    _tabList[_currentTab].webView = crashedTab.webView;
    _tabList[_currentTab].webViewKey = newKey;

    _callAssessMethods();
    notifyListeners();
    _saveCurrentActiveTabPosition();
  }

  void pauseCurrentWebview() {
    if (_tabList.isEmpty) return;
    log("Pausing current webview!");
    final currentTab = _tabList[_currentTab];
    currentTab.webViewKey?.currentState?.pauseThisWebview();
  }

  void resumeCurrentWebview() {
    if (_tabList.isEmpty) return;
    log("Resuming current webview!");
    final currentTab = _tabList[_currentTab];
    currentTab.webViewKey?.currentState?.resumeThisWebview();
  }

  void pauseAllWebviews() {
    if (Platform.isWindows) return;
    try {
      if (_tabList.isEmpty) return;
      final currentTab = _tabList[_currentTab];
      // NOTE: IOS only stops the current active webview
      currentTab.webViewKey?.currentState?.webViewController?.pauseTimers();
    } catch (e, trace) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Pausing Webviews");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }
  }

  void resumeAllWebviews() {
    try {
      if (_tabList.isEmpty) return;

      final currentTab = _tabList[_currentTab];
      currentTab.webViewKey?.currentState?.webViewController?.resumeTimers();

      if (Platform.isAndroid) {
        // Android pauses the ones that are not in use
        var pausedAgain = 0;
        if (Platform.isAndroid) {
          for (final tab in _tabList) {
            if (tab != currentTab) {
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
    final currentTab = _tabList[_currentTab];
    currentTab.webViewKey?.currentState?.openUrlDialog();
  }

  Future clearCacheAndTabs() async {
    if (_tabList.isEmpty) return;

    // Wait 200 milliseconds for build to finish (if we come from a tab)
    await Future.delayed(const Duration(milliseconds: 200));
    _currentTab = 0;
    notifyListeners();
    // Wait 200 milliseconds so that the animated stack view changes to main tab
    await Future.delayed(const Duration(milliseconds: 200));

    Prefs().setWebViewSecondaryTabs('{"tabsSave": []}');
    // Clear session cookie
    Prefs().setWebViewSessionCookie('');

    // Awake remaining tab if necessary
    if (_tabList[0].sleepTab) {
      _tabList[_currentTab].sleepTab = false;
      _tabList[_currentTab].webView = _buildRealWebViewFromSleeping(_tabList[_currentTab].sleepingWebView!);
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
    // Tab initialised prevents the first URL (generic to Torn) to be inserted in the history and also forward history
    // from getting removed (first thing the webView does is to visit the generic URL)
    if (tab.initialised) {
      tab.historyForward.clear();
      // Sometimes onLoadStop triggers several times. This prevents adding an entry in the history in this cases
      // by detecting if the URL we are leaving is the same one we are going to. If it is, don't add it as it is
      // still the current page being shown
      if (tab.currentUrl != newUrl) {
        addToHistoryBack(tab: tab, url: tab.currentUrl);
      }
    } else {
      tab.initialised = true;
    }
    tab.currentUrl = newUrl;

    notifyListeners();
    _callAssessMethods();
    _saveTabs();
  }

  void reportTabPageTitle(Key? reporterKey, String? pageTitle) {
    final tab = getTabFromKey(reporterKey)!;
    tab.pageTitle = pageTitle;

    // Pause timers for tabs that load which are not active (e.g. at the initialization, we pause all except the main)
    if (_tabList[_currentTab] != tab) {
      tab.webViewKey?.currentState?.pauseThisWebview();
    }

    notifyListeners();
    _saveTabs();
  }

  void reportChatRemovalChange(bool active, bool global) {
    final tab = _tabList[_currentTab];
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
      final activeKey = _tabList[_currentTab].webView?.key;
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

  void addToHistoryBack({required TabDetails tab, required String? url}) {
    tab.historyBack.add(url);
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

  assessLoginErrorsFromPdaIcon() async {
    TabDetails tab;

    // This might be executed before the browser is ready, so wait for it
    if (_tabList.isEmpty) {
      final start = DateTime.now();
      while (DateTime.now().difference(start).inMilliseconds < 3000 && _tabList.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (_tabList.isNotEmpty) {
      tab = _tabList[_currentTab];
      tab.webViewKey?.currentState?.assessErrorCases();
    }
  }

  bool tryGoBack() {
    final tab = _tabList[_currentTab];
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
    final tab = _tabList[_currentTab];
    if (tab.historyForward.isNotEmpty) {
      final previous = tab.historyForward.elementAt(tab.historyForward.length - 1);

      addToHistoryBack(tab: tab, url: tab.currentUrl);

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

  bool reviveUrl() {
    final tab = _tabList[_currentTab];
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
    if (_currentTab != 0) {
      activateTab(0);
    }
  }

  void convertToChainingBrowser({ChainingPayload? chainingPayload}) {
    if (_tabList.isEmpty) return;
    final tab = _tabList[0];
    tab.isChainingBrowser = true;
    tab.webViewKey?.currentState?.convertToChainingBrowser(chainingPayload: chainingPayload!);
    if (_currentTab != 0) {
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
    final tab = _tabList[_currentTab];
    if (tab.currentUrl != null) {
      tab.webViewKey?.currentState?.loadFromExterior(url: url, omitHistory: false);
      _saveTabs();
    }
  }

  String? currentTabUrl() {
    final tab = _tabList[_currentTab];
    if (tab.currentUrl != null) {
      return tab.webViewKey?.currentState?.reportCurrentUrl();
    }
    return "";
  }

  String? currentTabTitle() {
    final tab = _tabList[_currentTab];
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
            ..customNameInTab = _tabList[i].customNameInTab,
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
    if (_currentTab >= _tabList.length) {
      _tabList.length == 1 ? _currentTab = 0 : _currentTab = _tabList.length - 1;
    }
    Prefs().setWebViewLastActiveTab(_currentTab);
  }

  void clearOnDispose() {
    _tabList.clear();
    _secondaryInitialised = false;

    // It is necessary to bring this to 0 so that on opening no checks are performed in tabs that don't exist yet
    _currentTab = 0;
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
    final tab = _tabList[_currentTab];

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

    final UiMode uiMode = _decideBrowserScreenMode(tapType: browserTapType, context: context);
    setCurrentUiMode(uiMode, context);

    final browserType = await Prefs().getDefaultBrowser();
    if (browserType == 'app') {
      analytics?.logScreenView(screenName: 'browser_full');

      String? authUrl = await _assessNativeAuth(inputUrl: url, context: context);

      final WebViewProvider w = Provider.of<WebViewProvider>(context, listen: false);
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

    if (tapType == BrowserTapType.chain) {
      return UiMode.window;
    } else if (tapType == BrowserTapType.short && settings.fullScreenByShortTap) {
      return UiMode.fullScreen;
    } else if (tapType == BrowserTapType.long && settings.fullScreenByLongTap) {
      return UiMode.fullScreen;
    } else if (tapType == BrowserTapType.notification && settings.fullScreenByNotificationTap) {
      return UiMode.fullScreen;
    } else if (tapType == BrowserTapType.deeplink && settings.fullScreenByDeepLinkTap) {
      return UiMode.fullScreen;
    } else if (tapType == BrowserTapType.quickItem && settings.fullScreenByQuickItemTap) {
      return UiMode.fullScreen;
    }

    return UiMode.window;
  }

  void changeTornTheme({required bool dark}) {
    if (!dark) {
      pendingThemeSync = "light";
    } else {
      pendingThemeSync = "dark";
    }
  }

  void closeWebViewFromOutside() {
    final tab = _tabList[_currentTab];
    tab.webViewKey?.currentState?.closeBrowserFromOutside();
  }

  void reloadFromOutside() {
    final tab = _tabList[_currentTab];
    tab.webViewKey?.currentState?.reloadFromOutside();
  }

  void passHealingChoiceFromOutside(HealingPages choice) {
    final tab = _tabList[_currentTab];
    tab.webViewKey?.currentState?.openHealingPage(choice);
  }

  void passOpenCloseChainWidgetFromOutside() {
    final tab = _tabList[_currentTab];
    tab.webViewKey?.currentState?.openCloseChainWidgetFromOutside();
  }

  void passNextChainAttackFromOutside() {
    final tab = _tabList[_currentTab];
    tab.webViewKey?.currentState?.nextChainAttack();
  }

  /// At least used in the following cases:
  /// 1.- On main tab init: in case the user only uses the browser, it will fire after an app's launch when browser rebuilds
  /// 2.- Whenever the user launches the browser from a tap (other than the PDA icon, which does not load any URL itself)
  Future<String?> _assessNativeAuth({required String? inputUrl, required BuildContext context}) async {
    final NativeUserProvider nativeUser = context.read<NativeUserProvider>();
    final NativeAuthProvider nativeAuth = context.read<NativeAuthProvider>();
    final UserDetailsProvider userProvider = context.read<UserDetailsProvider>();

    if (!nativeUser.isNativeUserEnabled()) {
      log("No native user enabled, skipping auth!");
      return inputUrl;
    }

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
            playerId: userProvider.basic!.playerId,
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
    return inputUrl;
  }

  void updatePullToRefresh(BrowserRefreshSetting? value) {
    if (_tabList.isEmpty) return;
    for (final tab in _tabList) {
      // Null check because not all webview have a key (sleeping tabs!)
      tab.webViewKey?.currentState?.updatePullToRefresh(value);
    }
  }

  /// Uses the already generated shortcuts list
  Widget getIcon(int i, BuildContext context) {
    final url = tabList[i].currentUrl!;

    final themeProvider = context.read<ThemeProvider>();
    Color iconColor = themeProvider.currentTheme == AppTheme.light ? Colors.black : Colors.white;

    Widget boxWidget = ImageIcon(AssetImage('images/icons/pda_icon.png'), color: iconColor);

    // Find some icons manually first, as they might trigger errors with shortcuts
    if (tabList[i].isChainingBrowser) {
      return Icon(MdiIcons.linkVariant, color: Colors.red);
    } else if (url.contains("sid=attack&user2ID=2225097")) {
      return Icon(MdiIcons.pistol, color: Colors.pink);
    } else if (url.contains("sid=attack&user2ID=")) {
      return Icon(Icons.person, color: iconColor);
    } else if (url.contains("profiles.php?XID=2225097")) {
      return Icon(Icons.person, color: Colors.pink);
    } else if (url.contains("profiles.php")) {
      return Icon(Icons.person, color: iconColor);
    } else if (url.contains("companies.php") || url.contains("joblist.php")) {
      return ImageIcon(AssetImage('images/icons/home/job.png'), color: iconColor);
    } else if (url.contains("https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0")) {
      return ImageIcon(AssetImage('images/icons/home/forums.png'), color: Colors.pink);
    } else if (url.contains("https://www.torn.com/forums.php")) {
      return ImageIcon(AssetImage('images/icons/home/forums.png'), color: iconColor);
    } else if (url.contains("yata.yt")) {
      return Image.asset('images/icons/yata_logo.png');
    } else if (url.contains("jailview.php")) {
      return Image.asset('images/icons/map/jail.png', color: iconColor);
    } else if (url.contains("hospitalview.php")) {
      return Image.asset('images/icons/map/hospital.png', color: iconColor);
    } else if (url.contains("events.php") || url.contains("page.php?sid=events")) {
      return Image.asset('images/icons/home/events.png', color: iconColor);
    } else if (url.contains("properties.php")) {
      return Image.asset('images/icons/map/property.png', color: iconColor);
    } else if (url.contains("tornstats.com/")) {
      return Image.asset('images/icons/tornstats_logo.png');
    } else if (url.contains("tornexchange.com/")) {
      return Image.asset('images/icons/tornexchange_logo.png');
    } else if (url.contains("arsonwarehouse.com/")) {
      return Image.asset('images/icons/awh_logo2.png');
    } else if (url.contains("index.php?page=hunting")) {
      return Icon(MdiIcons.target, size: 20, color: iconColor);
    } else if (url.contains("bazaar.php")) {
      return Image.asset('images/icons/inventory/bazaar.png', color: iconColor);
    } else if (url.contains("imarket.php")) {
      return Image.asset('images/icons/map/item_market.png', color: iconColor);
    } else if (url.contains("torn.com/loader.php?sid=crimes#")) {
      return Image.asset('images/icons/home/crimes.png', color: iconColor);
    } else if (url.contains("index.php")) {
      return ImageIcon(AssetImage('images/icons/home/home.png'), color: iconColor);
    } else if (!url.contains("torn.com")) {
      return Icon(Icons.public, size: 22, color: iconColor);
    }

    // Try to find by using shortcuts list
    // Note: some are not found because the value that comes from OnLoadStop in the WebView differs from
    // the standard URL in shortcuts. That's why there are some more in the list above.
    final shortProvider = context.read<ShortcutsProvider>();
    for (final short in shortProvider.allShortcuts) {
      if (url.contains(short.url!)) {
        boxWidget = ImageIcon(
          AssetImage(short.iconUrl!),
          color: themeProvider.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        );
        // Return if the coincidence is not with the default shortcut
        if (short.name != "Home") {
          return boxWidget;
        }
      }
    }

    return boxWidget;
  }

  Future restorePreferences() async {
    _onlyLoadTabsWhenUsed = await Prefs().getOnlyLoadTabsWhenUsed();

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
}
