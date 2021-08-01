// Dart imports:

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/tabsave_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';

// Package imports:

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class TabDetails {
  bool initialised = false;
  Widget webView;
  GlobalKey<WebViewFullState> webViewKey;
  String currentUrl = "https://www.torn.com";
  String pageTitle = "";
  bool chatRemovalActiveTab = false;
  List<String> historyBack = <String>[];
  List<String> historyForward = <String>[];
}

class WebViewProvider extends ChangeNotifier {
  List<TabDetails> _tabList = <TabDetails>[];
  List<TabDetails> get tabList => _tabList;

  bool chatRemovalEnabledGlobal = false;
  bool chatRemovalActiveGlobal = false;

  bool useDialog = false;

  bool _useTabIcons = true;
  bool get useTabIcons => _useTabIcons;

  bool _gymMessageActive = false;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  Future initialise({@required String initUrl, @required bool useTabs, bool dialog = false}) async {
    useDialog = dialog;

    chatRemovalEnabledGlobal = await Prefs().getChatRemovalEnabled();
    chatRemovalActiveGlobal = await Prefs().getChatRemovalActive();

    _useTabIcons = await Prefs().getUseTabsIcons();

    // Add the main opener
    addTab(url: initUrl, chatRemovalActive: chatRemovalActiveGlobal);

    // Then add the save ones
    var savedJson = await Prefs().getWebViewTabs();
    var savedWebViews = tabSaveModelFromJson(savedJson);

    for (var wv in savedWebViews.tabsSave) {
      if (useTabs) {
        addTab(
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

    // Make sure we start at the first tab
    activateTab(0);
  }

  void addTab({
    String url = "https://www.torn.com",
    String pageTitle = "Torn",
    bool chatRemovalActive,
    List<String> historyBack,
    List<String> historyForward,
  }) {
    chatRemovalActive = chatRemovalActive ?? chatRemovalActiveGlobal;
    var key = GlobalKey<WebViewFullState>();
    _tabList.add(
      TabDetails()
        ..webViewKey = key
        ..webView = WebViewFull(
          customUrl: url,
          key: key,
          dialog: useDialog,
          useTabs: true,
          chatRemovalActive: chatRemovalActive,
        )
        ..pageTitle = pageTitle
        ..chatRemovalActiveTab = chatRemovalActive
        ..historyBack = historyBack ?? <String>[]
        ..historyForward = historyForward ?? <String>[],
    );
    notifyListeners();
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
    _savePreferences();
  }

  void removeTab(int position) {
    if (position > 0) {
      if (position == currentTab) {
        _currentTab = position - 1;
      }
      _tabList.removeAt(position);
    }

    var tab = _tabList[_currentTab];
    tab.webViewKey.currentState.resumeTimers();

    notifyListeners();
    _savePreferences();
  }

  void activateTab(int newActiveTab) {
    var deactivated = _tabList[_currentTab];
    deactivated.webViewKey.currentState?.pauseTimers();

    _currentTab = newActiveTab;
    var activated = _tabList[_currentTab];
    activated.webViewKey.currentState?.resumeTimers();

    _callAssessMethods();
    notifyListeners();
  }

  void reorderTabs(TabDetails movedItem, int oldIndex, int newIndex) {
    _tabList.removeAt(oldIndex);
    _tabList.insert(newIndex, movedItem);
    notifyListeners();
    _savePreferences();
  }

  void reportTabLoadUrl(Key reporterKey, String url) {
    var tab = getTabFromKey(reporterKey);
    // Tab initialised prevents the first URL (generic to Torn) to be inserted in the history and also forward history
    // from getting removed (first thing the webView does is to visit the generic URL)
    if (tab.initialised) {
      tab.historyForward.clear();
      tab.historyBack.add(tab.currentUrl);
    } else {
      tab.initialised = true;
    }
    tab.currentUrl = url;

    notifyListeners();
    _savePreferences();
  }

  void reportTabPageTitle(Key reporterKey, String pageTitle) {
    var tab = getTabFromKey(reporterKey);
    tab.pageTitle = pageTitle;

    // Pause timers for tabs that load which are not active (e.g. at the initialisation, we pause all except the main)
    if (_tabList[_currentTab] != tab) {
      tab.webViewKey.currentState?.pauseTimers();
    }

    notifyListeners();
    _savePreferences();
  }

  void reportChatRemovalChange(bool active, bool global) {
    var tab = _tabList[_currentTab];
    tab.chatRemovalActiveTab = active;
    if (global) {
      chatRemovalActiveGlobal = active;
      Prefs().setChatRemovalActive(active);
    }
    _savePreferences();
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
      _savePreferences();
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
      _savePreferences();
      return true;
    } else {
      return false;
    }
  }

  void loadMainTabUrl(String url) {
    if (_tabList.isEmpty) return;
    var tab = _tabList[0];
    tab.webViewKey.currentState?.loadFromExterior(url: url, omitHistory: false);
    _savePreferences();
  }

  void _savePreferences() {
    var saveModel = TabSaveModel()..tabsSave = <TabsSave>[];
    for (var i = 1; i < _tabList.length; i++) {
      saveModel.tabsSave.add(
        TabsSave()
          ..url = _tabList[i].currentUrl
          ..pageTitle = _tabList[i].pageTitle
          ..chatRemovalActive = _tabList[i].chatRemovalActiveTab
          ..historyBack = _tabList[i].historyBack
          ..historyForward = _tabList[i].historyForward,
      );
    }
    String json = tabSaveModelToJson(saveModel);
    Prefs().setWebViewTabs(json);
  }

  void clearOnDispose() {
    _tabList.clear();
  }

  TabDetails getTabFromKey(Key reporterKey) {
    for (var tab in _tabList) {
      if (tab.webView.key == reporterKey) {
        return tab;
      }
    }
    return null;
  }

  void _callAssessMethods() {
    var tab = _tabList[_currentTab];
    if (tab.currentUrl.contains("gym.php")) {
      tab.webViewKey.currentState?.assessGym();
    }
  }

  // This can be called from the WebView and ensures that several BotToasts are not shown at the start if
  // several tabs are open to the gym
  void showGymMessage(String message) {
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

  void changeUseTabIcons(bool useIcons) {
    _useTabIcons = useIcons;
    Prefs().setUseTabsIcons(useIcons);
    notifyListeners();
  }

  Future openBrowserPreference({
    @required BuildContext context,
    @required String url,
    @required bool useDialog,
  }) async {
    var browserType = await Prefs().getDefaultBrowser();
    if (browserType == 'app') {
      // First check if the browser (whichever) is open. If it is, load the url in that browser.
      if (_tabList.isNotEmpty) {
        loadMainTabUrl(url);
      } else {
        // Otherwise, we attend to user preferences on browser type
        if (useDialog) {
          await openBrowserDialog(context, url);
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => WebViewStackView(initUrl: url),
            ),
          );
        }
      }
    } else {
      if (await canLaunch(url)) {
        await launch(url, forceSafariVC: false);
      }
    }
  }
}
