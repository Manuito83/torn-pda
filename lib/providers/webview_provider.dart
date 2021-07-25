// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:torn_pda/models/tabsave_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// Package imports:

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_full.dart';

enum TabUrlType {
  general,
  profile,
}

class TabDetails {
  bool initialised = false;
  Widget webView;
  GlobalKey<WebViewFullState> webViewKey;
  TabUrlType tabUrlType = TabUrlType.general;
  String currentUrl = "https://www.torn.com";
  List<String> historyBack = <String>[]; // TODO: put in the model
  List<String> historyForward = <String>[];
  // TODO: chat in the model
  // TODO: long-press first icon to add tab with that page
  // TODO: long-press add icon to change from icons to text
  // TODO: dialog
}

class WebViewProvider extends ChangeNotifier {
  List<TabDetails> _tabList = <TabDetails>[];
  List<TabDetails> get tabList => _tabList;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  Future initialise({@required String initUrl}) async {
    // Add the main opener
    addTab(init: true, url: initUrl);
    // Then add the save ones
    var savedJson = await Prefs().getWebViewTabs();
    var savedWebViews = tabSaveModelFromJson(savedJson);
    for (var wv in savedWebViews.tabsSave) {
      addTab(
        init: true,
        url: wv.url,
        historyBack: wv.historyBack,
        historyForward: wv.historyForward,
      );
    }
    // Make sure we start at the first tab
    activateTab(0);
  }

  void addTab({
    bool init = false,
    String url = "https://www.torn.com",
    List<String> historyBack,
    List<String> historyForward,
  }) {
    var key = GlobalKey<WebViewFullState>();
    _tabList.add(
      TabDetails()
        ..webViewKey = key
        ..webView = WebViewFull(
          customUrl: url,
          key: key,
        )
        ..historyBack = historyBack ?? <String>[]
        ..historyForward = historyForward ?? <String>[],
    );
    // Do not notify listeners on init, as the main stack widget is not yet built
    if (!init) notifyListeners();
  }

  void removeTab(int position) {
    if (position > 0) {
      if (position == currentTab) {
        _currentTab = position - 1;
      }
      _tabList.removeAt(position);
    }
    notifyListeners();
    _savePreferences();
  }

  void activateTab(int tab) {
    _currentTab = tab;
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

    // Manage icons
    if (url.contains("profiles.php?XID")) {
      tab.tabUrlType = TabUrlType.profile;
    } else {
      tab.tabUrlType = TabUrlType.general;
    }

    notifyListeners();
    _savePreferences();
  }

  bool tryGoBack() {
    var tab = _tabList[_currentTab];
    if (tab.historyBack.length > 0) {
      var previous = tab.historyBack.elementAt(tab.historyBack.length - 1);
      tab.historyForward.add(tab.currentUrl);
      tab.historyBack.removeLast();
      // Call child method directly, otherwise the 'back' button will only work with the first webView
      tab.webViewKey.currentState.loadWithoutHistory(previous);
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
      tab.webViewKey.currentState.loadWithoutHistory(previous);
      tab.currentUrl = previous;
      _savePreferences();
      return true;
    } else {
      return false;
    }

  }

  void _savePreferences() {
    var saveModel = TabSaveModel()..tabsSave = <TabsSave>[];
    for (var i = 1; i < _tabList.length; i++) {
      saveModel.tabsSave.add(
        TabsSave()
          ..url = _tabList[i].currentUrl
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
}
