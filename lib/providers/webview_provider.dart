// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_full.dart';

class WebViewProvider extends ChangeNotifier {
  List<Widget> _webViewList = <Widget>[];
  List<Widget> get webViewList => _webViewList;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  WebViewProvider() {
    if (_webViewList.isEmpty) {
      addWebView();
    }
  }

  void addWebView() {
    _webViewList.add(
      WebViewFull(
        key: GlobalKey<WebViewFullState>(),
      ),
    );
    notifyListeners();
  }

  void removeWebView(int position) {
    if (position > 0) {
      if (position == currentTab) {
        _currentTab = position - 1;
      }
      _webViewList.removeAt(position);
    }
    notifyListeners();
  }

  void activateTab(int tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void reorderTabs(Widget movedItem, int oldIndex, int newIndex) {
    _webViewList.removeAt(oldIndex);
    _webViewList.insert(newIndex, movedItem);
    notifyListeners();
  }

  void reportUrlOpen(Key widgetKey, String url) {
      print("$widgetKey $url");
  }

}
