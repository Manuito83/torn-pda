// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_full.dart';

enum TabUrlType {
  general,
  profile,
}

class TabDetails {
  Widget webView;
  TabUrlType tabUrlType = TabUrlType.general;
}

class WebViewProvider extends ChangeNotifier {
  List<TabDetails> _tabList = <TabDetails>[];
  List<TabDetails> get tabList => _tabList;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  WebViewProvider() {
    if (_tabList.isEmpty) {
      addWebView();
    }
  }

  void addWebView() {
    _tabList.add(
      TabDetails()..webView = WebViewFull(key: GlobalKey<WebViewFullState>()),
    );
    notifyListeners();
  }

  void removeWebView(int position) {
    if (position > 0) {
      if (position == currentTab) {
        _currentTab = position - 1;
      }
      _tabList.removeAt(position);
    }
    notifyListeners();
  }

  void activateTab(int tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void reorderTabs(TabDetails movedItem, int oldIndex, int newIndex) {
    _tabList.removeAt(oldIndex);
    _tabList.insert(newIndex, movedItem);
    notifyListeners();
  }

  void reportUrlOpen(Key reporterKey, String url) {
    for (var tab in _tabList) {
      if (tab.webView.key == reporterKey) {
        if (url.contains("profiles.php?XID")) {
          tab.tabUrlType = TabUrlType.profile;
        } else {
          tab.tabUrlType = TabUrlType.general;
        }
      }
    }
    notifyListeners();
  }

}
