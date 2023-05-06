// Dart imports:

// Flutter imports:
import 'dart:async';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/tabsave_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';

// Package imports:

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class TabDetails {
  bool sleepTab = false;
  bool initialised = false;
  Widget webView;
  SleepingWebView sleepingWebView;
  GlobalKey<WebViewFullState> webViewKey;
  String currentUrl = "https://www.torn.com";
  String pageTitle = "";
  bool chatRemovalActiveTab = false;
  List<String> historyBack = <String>[];
  List<String> historyForward = <String>[];
  bool isChainingBrowser = false;
}

class SleepingWebView {
  final String customUrl;
  final GlobalKey<WebViewFullState> key;
  final bool dialog;
  final bool useTabs;
  final bool chatRemovalActive;
  final bool isChainingBrowser;
  final ChainingPayload chainingPayload;

  const SleepingWebView({
    this.customUrl = 'https://www.torn.com',
    this.dialog = false,
    this.useTabs = false,
    this.chatRemovalActive = false,
    this.key,
    this.isChainingBrowser = false,
    this.chainingPayload,
  });
}

class WebViewProvider extends ChangeNotifier {
  List<TabDetails> _tabList = <TabDetails>[];
  List<TabDetails> get tabList => _tabList;

  StreamController browserHasClosedStream = StreamController.broadcast();

  bool chatRemovalEnabledGlobal = false;
  bool chatRemovalActiveGlobal = false;

  bool _useDialog = false;

  String pendingThemeSync = "";

  bool _useTabIcons = true;
  bool get useTabIcons => _useTabIcons;

  bool _hideTabs = false;
  bool get hideTabs => _hideTabs;

  bool _gymMessageActive = false;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  bool _secondaryInitialised = false;

  DateTime _lastBrowserOpenedTime;

  var _onlyLoadTabsWhenUsed = true;
  bool get onlyLoadTabsWhenUsed => _onlyLoadTabsWhenUsed;
  set onlyLoadTabsWhenUsed(bool value) {
    _onlyLoadTabsWhenUsed = value;
    Prefs().setOnlyLoadTabsWhenUsed(_onlyLoadTabsWhenUsed);
    notifyListeners();
  }

  /// [recallLastSession] should be used to open a browser session where we left it last time
  Future initialiseMain({
    @required String initUrl,
    bool dialog = false,
    bool recallLastSession = false,
    bool isChainingBrowser = false,
    ChainingPayload chainingPayload,
    bool restoreSessionCookie = false,
  }) async {
    if (restoreSessionCookie) {
      try {
        String sessionCookie = await Prefs().getWebViewSessionCookie();
        if (sessionCookie != "") {
          var cm = CookieManager.instance();

          var allCookies = await cm.getCookies(url: WebUri("https://www.torn.com"));
          log("Cookies: ${allCookies.length}");
          var repetitions = allCookies.where((element) => element.name == "PHPSESSID").length;

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

    _useDialog = dialog;

    chatRemovalEnabledGlobal = await Prefs().getChatRemovalEnabled();
    chatRemovalActiveGlobal = await Prefs().getChatRemovalActive();

    _useTabIcons = await Prefs().getUseTabsIcons();
    _hideTabs = await Prefs().getHideTabs();

    // This saves if we are using a dialog or not, so that the next session can replicate if we recall from T menu
    // Chaining browser does not count as an user preference, as it is always full
    if (!isChainingBrowser) {
      Prefs().setWebViewLastSessionUsedDialog(dialog);
    }

    // Add the main opener
    String url = initUrl;
    if (recallLastSession) {
      String savedJson = await Prefs().getWebViewMainTab();
      TabSaveModel savedMain = tabSaveModelFromJson(savedJson);
      if (savedMain.tabsSave.length > 0) {
        addTab(
          url: savedMain.tabsSave[0].url,
          pageTitle: savedMain.tabsSave[0].pageTitle,
          chatRemovalActive: savedMain.tabsSave[0].chatRemovalActive,
          historyBack: savedMain.tabsSave[0].historyBack,
          historyForward: savedMain.tabsSave[0].historyForward,
        );
      } else {
        await addTab(url: "https://www.torn.com", chatRemovalActive: chatRemovalActiveGlobal);
      }
    } else {
      await addTab(
        url: url,
        chatRemovalActive: chatRemovalActiveGlobal,
        isChainingBrowser: isChainingBrowser,
        chainingPayload: chainingPayload,
      );
    }
    _currentTab = 0;
  }

  Future initialiseSecondary({@required bool useTabs, bool recallLastSession = false}) async {
    var savedJson = await Prefs().getWebViewSecondaryTabs();
    var savedWebViews = tabSaveModelFromJson(savedJson);
    bool sleepTabsByDefault = await Prefs().getOnlyLoadTabsWhenUsed();

    _secondaryInitialised = true;

    for (var wv in savedWebViews.tabsSave) {
      if (useTabs) {
        addTab(
          tabKey: wv.tabKey,
          sleepTab: sleepTabsByDefault,
          url: wv.url,
          pageTitle: wv.pageTitle,
          chatRemovalActive: wv.chatRemovalActive,
          historyBack: wv.historyBack,
          historyForward: wv.historyForward,
        );
      } else {
        addHiddenTab(
          url: wv.url,
          pageTitle: wv.pageTitle,
          chatRemovalActive: wv.chatRemovalActive,
          historyBack: wv.historyBack,
          historyForward: wv.historyForward,
        );
      }
    }

    // Make sure we start at the first tab. We don't need to call activateTab because we have
    // still not initialised completely and the StackView is not live
    if (recallLastSession && useTabs) {
      int lastActive = await Prefs().getWebViewLastActiveTab();
      if (lastActive <= _tabList.length - 1) {
        _currentTab = lastActive;
      } else {
        _currentTab = 0;
      }

      // Awake WebView if we are recalling it
      if (_tabList[_currentTab].sleepTab) {
        _tabList[_currentTab].sleepTab = false;
        _tabList[_currentTab].webView = _buildRealWebViewFromSleeping(_tabList[_currentTab].sleepingWebView);
      }
    } else {
      _currentTab = 0;
    }
  }

  Future addTab({
    GlobalKey tabKey,
    int windowId,
    bool sleepTab = false,
    String url = "https://www.torn.com",
    String pageTitle = "",
    bool chatRemovalActive,
    List<String> historyBack,
    List<String> historyForward,
    bool isChainingBrowser = false,
    ChainingPayload chainingPayload,
  }) async {
    chatRemovalActive = chatRemovalActive ?? chatRemovalActiveGlobal;
    var key = GlobalKey<WebViewFullState>();
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
                dialog: _useDialog,
                useTabs: true,
                chatRemovalActive: chatRemovalActive,
                isChainingBrowser: isChainingBrowser,
                chainingPayload: chainingPayload,
              )
        ..sleepingWebView = sleepTab
            ? SleepingWebView(
                customUrl: url,
                key: key,
                dialog: _useDialog,
                useTabs: true,
                chatRemovalActive: chatRemovalActive,
                isChainingBrowser: isChainingBrowser,
                chainingPayload: chainingPayload,
              )
            : null
        ..pageTitle = pageTitle
        ..currentUrl = url
        ..chatRemovalActiveTab = chatRemovalActive
        ..historyBack = historyBack ?? <String>[]
        ..historyForward = historyForward ?? <String>[]
        ..isChainingBrowser = isChainingBrowser,
    );
    notifyListeners();
    _callAssessMethods();
  }

  /// If we are not using tabs, we still need to add 'hidden tabs' (that is, with the main info that needs to be
  /// saved, but without the actual webView), so that if the other browser type uses tabs, these are not lost
  /// between sessions.
  void addHiddenTab({
    String url = "https://www.torn.com",
    String pageTitle = "Torn",
    bool chatRemovalActive,
    List<String> historyBack,
    List<String> historyForward,
  }) {
    chatRemovalActive = chatRemovalActive ?? chatRemovalActiveGlobal;
    _tabList.add(
      TabDetails()
        ..currentUrl = url
        ..pageTitle = pageTitle
        ..chatRemovalActiveTab = chatRemovalActive
        ..historyBack = historyBack ?? <String>[]
        ..historyForward = historyForward ?? <String>[],
    );
    _saveTabs();
  }

  void removeTab({int position, bool calledFromTab = false}) async {
    if (calledFromTab) {
      position = _currentTab;
    }

    if (position == null || position == 0) return;

    bool wasLast = _currentTab == _tabList.length - 1 || false;

    // If we remove the current tab, we need to decrease the current tab by 1
    if (position == _currentTab) {
      _currentTab = position - 1;

      // Awake WebView if necessary
      var activated = _tabList[_currentTab];
      if (activated.sleepTab) {
        activated.sleepTab = false;
        activated.webView = _buildRealWebViewFromSleeping(activated.sleepingWebView);
      }

      _tabList[_currentTab]?.webViewKey?.currentState?.resumeWebview();
    } else if (_currentTab == _tabList.length - 1) {
      // If upon removal of any other, the last tab is active, we also decrease the current tab by 1 (-2 from length)
      _currentTab = _tabList.length - 2;
    }

    // If the tab removed was the last and therefore we activate the [now] last tab, we need to resume timers
    if (wasLast) {
      _tabList[_currentTab]?.webViewKey?.currentState?.resumeWebview();
      // Notify listeners first so that the tab changes
      notifyListeners();
      // Then wait 200 milliseconds so that the animated stack view changes its child
      await Future.delayed(Duration(milliseconds: 200));
      // As we have changed the tab, call assess methods
      _callAssessMethods();
      // Only then remove the tab and notify again below
    }

    _tabList.removeAt(position);
    notifyListeners();
    _saveTabs();
  }

  void activateTab(int newActiveTab) {
    if (_tabList.isEmpty || _tabList.length - 1 < newActiveTab) return;

    var deactivated = _tabList[_currentTab];
    deactivated?.webViewKey?.currentState?.pauseWebview();

    _currentTab = newActiveTab;
    var activated = _tabList[_currentTab];

    // Awake WebView if necessary
    if (activated.sleepTab) {
      activated.sleepTab = false;
      activated.webView = _buildRealWebViewFromSleeping(activated.sleepingWebView);
    }

    activated?.webViewKey?.currentState?.resumeWebview();

    _callAssessMethods();
    notifyListeners();
  }

  Widget _buildRealWebViewFromSleeping(SleepingWebView sleeping) {
    return WebViewFull(
      customUrl: sleeping.customUrl,
      key: sleeping.key,
      dialog: sleeping.dialog,
      useTabs: true,
      chatRemovalActive: sleeping.chatRemovalActive,
      isChainingBrowser: sleeping.isChainingBrowser,
      chainingPayload: sleeping.chainingPayload,
    );
  }

  void reorderTabs(TabDetails movedItem, int oldIndex, int newIndex) {
    _tabList.removeAt(oldIndex);
    _tabList.insert(newIndex, movedItem);
    notifyListeners();
    _saveTabs();
  }

  void reportTabLoadUrl(Key reporterKey, String newUrl) {
    var tab = getTabFromKey(reporterKey);
    // Tab initialised prevents the first URL (generic to Torn) to be inserted in the history and also forward history
    // from getting removed (first thing the webView does is to visit the generic URL)
    if (tab.initialised) {
      tab.historyForward.clear();
      // Sometimes onLoadStop triggers several times. This prevents adding an entry in the history in this cases
      // by detecting if the URL we are leaving is the same one we are going to. If it is, don't add it as it is
      // still the current page being shown
      if (tab.currentUrl != newUrl) {
        tab.historyBack.add(tab.currentUrl);
      }
    } else {
      tab.initialised = true;
    }
    tab.currentUrl = newUrl;

    notifyListeners();
    _callAssessMethods();
    _saveTabs();
  }

  void reportTabPageTitle(Key reporterKey, String pageTitle) {
    var tab = getTabFromKey(reporterKey);
    tab.pageTitle = pageTitle;

    // Pause timers for tabs that load which are not active (e.g. at the initialization, we pause all except the main)
    if (_tabList[_currentTab] != tab) {
      tab.webViewKey.currentState?.pauseWebview();
    }

    notifyListeners();
    _saveTabs();
  }

  void reportChatRemovalChange(bool active, bool global) {
    var tab = _tabList[_currentTab];
    tab.chatRemovalActiveTab = active;
    if (global) {
      chatRemovalActiveGlobal = active;
      Prefs().setChatRemovalActive(active);
    }
    _saveTabs();
    notifyListeners();
  }

  bool tryGoBack() {
    var tab = _tabList[_currentTab];
    if (tab.historyBack.length > 0) {
      var previous = tab.historyBack.elementAt(tab.historyBack.length - 1);
      tab.historyForward.add(tab.currentUrl);
      tab.historyBack.removeLast();
      // Call child method directly, otherwise the 'back' button will only work with the first webView
      tab.webViewKey.currentState?.loadFromExterior(url: previous, omitHistory: true);
      tab.currentUrl = previous;
      _saveTabs();
      return true;
    } else {
      return false;
    }
  }

  bool tryGoForward() {
    var tab = _tabList[_currentTab];
    if (tab.historyForward.length > 0) {
      var previous = tab.historyForward.elementAt(tab.historyForward.length - 1);
      tab.historyBack.add(tab.currentUrl);
      tab.historyForward.removeLast();
      // Call child method directly, otherwise the 'back' button will only work with the first webView
      tab.webViewKey.currentState?.loadFromExterior(url: previous, omitHistory: true);
      tab.currentUrl = previous;
      _saveTabs();
      return true;
    } else {
      return false;
    }
  }

  bool reviveUrl() {
    var tab = _tabList[_currentTab];
    if (tab.currentUrl != null) {
      tab.webViewKey.currentState?.loadFromExterior(url: tab.currentUrl, omitHistory: true);
      _saveTabs();
      return true;
    } else {
      return false;
    }
  }

  void loadMainTabUrl(String url) {
    if (_tabList.isEmpty) return;
    var tab = _tabList[0];
    tab.webViewKey.currentState?.loadFromExterior(url: url, omitHistory: false);
    if (_currentTab != 0) {
      activateTab(0);
    }
  }

  void loadCurrentTabUrl(String url) {
    var tab = _tabList[_currentTab];
    if (tab.currentUrl != null) {
      tab.webViewKey.currentState?.loadFromExterior(url: url, omitHistory: false);
      _saveTabs();
    }
  }

  String currentTabUrl() {
    var tab = _tabList[_currentTab];
    if (tab.currentUrl != null) {
      return tab.webViewKey.currentState?.reportCurrentUrl();
    }
    return "";
  }

  String currentTabTitle() {
    var tab = _tabList[_currentTab];
    if (tab.currentUrl != null) {
      return tab.webViewKey.currentState?.reportCurrentTitle();
    }
    return "";
  }

  void _saveTabs() {
    // Make sure we don't save just the first tab before the secondaries are saved, otherwise (as secondary take one
    // second to initialise after the main), we'll just save the main and lose the rest if the phone is too quick in
    // loading the main and reporting back URL or page title (which triggers a save)!
    if (!_secondaryInitialised) return;

    TabSaveModel saveMainModel = TabSaveModel()..tabsSave = <TabsSave>[];
    TabSaveModel saveSecondaryModel = TabSaveModel()..tabsSave = <TabsSave>[];
    for (var i = 0; i < _tabList.length; i++) {
      if (i == 0) {
        saveMainModel.tabsSave.add(
          TabsSave()
            ..url = _tabList[0].currentUrl
            ..pageTitle = _tabList[0].pageTitle
            ..chatRemovalActive = _tabList[0].chatRemovalActiveTab
            ..historyBack = _tabList[0].historyBack
            ..historyForward = _tabList[0].historyForward,
        );
      } else {
        saveSecondaryModel.tabsSave.add(
          TabsSave()
            ..url = _tabList[i].currentUrl
            ..pageTitle = _tabList[i].pageTitle
            ..chatRemovalActive = _tabList[i].chatRemovalActiveTab
            ..historyBack = _tabList[i].historyBack
            ..historyForward = _tabList[i].historyForward,
        );
      }
    }
    String mainJson = tabSaveModelToJson(saveMainModel);
    String secondaryJson = tabSaveModelToJson(saveSecondaryModel);
    Prefs().setWebViewMainTab(mainJson);
    Prefs().setWebViewSecondaryTabs(secondaryJson);
  }

  void clearOnDispose() {
    // Ensure tab number is correct before saving active session
    if (_currentTab >= _tabList.length) {
      _tabList.length == 1 ? _currentTab = 0 : _currentTab = _tabList.length - 1;
    }
    Prefs().setWebViewLastActiveTab(_currentTab);

    _tabList.clear();
    _secondaryInitialised = false;

    // It is necessary to bring this to 0 so that on opening no checks are performed in tabs that don't exist yet
    _currentTab = 0;
  }

  TabDetails getTabFromKey(Key reporterKey) {
    for (var tab in _tabList) {
      // Null check because not all webview have a key (sleeping tabs!)
      if (tab.webView?.key == reporterKey) {
        return tab;
      }
    }

    return null;
  }

  void _callAssessMethods() {
    var tab = _tabList[_currentTab];
    if (tab.currentUrl.contains("gym.php") || tab.currentUrl.contains("index.php?page=hunting")) {
      tab.webViewKey.currentState?.assessEnergyWarning();
    }
  }

  // This can be called from the WebView and ensures that several BotToasts are not shown at the start if
  // several tabs are open to the gym
  void showEnergyWarningMessage(String message, Key reporterKey) {
    for (var tab in _tabList) {
      // Null check because not all webview have a key (sleeping tabs!)
      if (tab.webView?.key == reporterKey) {
        if (!_gymMessageActive) {
          _gymMessageActive = true;
          BotToast.showText(
            crossPage: false,
            text: message,
            align: Alignment(0, 0),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.blue,
            duration: Duration(seconds: 2),
            contentPadding: EdgeInsets.all(10),
          );
          Future.delayed(Duration(seconds: 3)).then((value) => _gymMessageActive = false);
        }
      }
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

  void cancelChainingBrowser() {
    var tab = _tabList[_currentTab];
    tab.isChainingBrowser = false;
    notifyListeners();
  }

  Future openBrowserPreference({
    @required BuildContext context,
    @required String url,
    @required bool useDialog,
    bool awaitable = false,
    bool recallLastSession = false,
    // Chaining
    final bool isChainingBrowser = false,
    final ChainingPayload chainingPayload,
  }) async {
    // Checking _tabList might not be enough to ensure that the browser is closed. We might get duplicates
    // with double presses or even notifications, try to open the browser twice (creating repeated keys)
    // This ensures that a browser open request only happens once
    if (_lastBrowserOpenedTime != null && (DateTime.now().difference(_lastBrowserOpenedTime).inMilliseconds) < 1500) {
      return;
    }
    _lastBrowserOpenedTime = DateTime.now();

    var browserType = await Prefs().getDefaultBrowser();
    if (browserType == 'app') {
      // First check if the browser (whichever) is open. If it is, load the url in that browser.
      if (_tabList.isNotEmpty) {
        loadMainTabUrl(url);
      } else {
        // Otherwise, we attend to user preferences on browser type
        if (useDialog) {
          analytics.setCurrentScreen(screenName: 'browser_dialog');
          if (awaitable) {
            await openBrowserDialog(
              context,
              url,
              recallLastSession: recallLastSession,
            );
          } else {
            openBrowserDialog(
              context,
              url,
              recallLastSession: recallLastSession,
            );
          }
        } else {
          analytics.setCurrentScreen(screenName: 'browser_full');
          if (awaitable) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => WebViewStackView(
                  initUrl: url,
                  recallLastSession: recallLastSession,
                  isChainingBrowser: isChainingBrowser,
                  chainingPayload: chainingPayload,
                ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => WebViewStackView(
                  initUrl: url,
                  recallLastSession: recallLastSession,
                  isChainingBrowser: isChainingBrowser,
                  chainingPayload: chainingPayload,
                ),
              ),
            );
          }
        }
      }
    } else {
      if (!recallLastSession && await canLaunch(url)) {
        await launch(url, forceSafariVC: false);
      }
    }
  }

  void changeTornTheme({@required bool dark}) {
    if (!dark) {
      pendingThemeSync = "light";
    } else {
      pendingThemeSync = "dark";
    }
  }
}
