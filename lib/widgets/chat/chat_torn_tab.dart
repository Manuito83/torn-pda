import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_engine.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/app_lifecycle.dart';
import 'package:torn_pda/utils/torn_web.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

/// Torn tab state for the chat
class ChatTornTab {
  ChatTornTab({
    required Listenable shown,
    required bool Function() running,
    required bool Function() onScreen,
    required bool Function(TabDetails) live,
    required bool Function() sessionOk,
  }) : _shown = shown,
       _running = running,
       _onScreen = onScreen,
       _live = live,
       _sessionOk = sessionOk {
    missing.addListener(syncFreeze);
  }

  /// No live Torn tab for a while
  final ValueNotifier<bool> missing = ValueNotifier(false);

  /// Awake or not
  final ValueNotifier<bool> exists = ValueNotifier(false);

  final Listenable _shown;
  final bool Function() _running;
  final bool Function() _onScreen;
  final bool Function(TabDetails) _live;
  final bool Function() _sessionOk;

  static const int _settle = 2;
  int _grace = 30;
  WebViewProvider? _web;
  Future<void>? _restore;
  bool _restoreTried = false;
  // Waiting for the restored Torn tab to load
  bool _holding = false;
  Timer? _timer;
  int _lostFor = 0;
  bool _hadLive = false;
  bool _pauseReported = false;
  bool _opening = false;
  String? _madeTab;

  WebViewProvider? get web => _web;

  void setGrace(int seconds) => _grace = seconds;

  void watchIfReady() {
    final context = NativeChat.navigatorKey?.currentContext;
    if (_web == null && context != null) watch(context.read<WebViewProvider>());
  }

  @visibleForTesting
  void watch(WebViewProvider web) {
    _web?.removeListener(check);
    _web = web..addListener(check);
    _shown
      ..removeListener(_onChatShown)
      ..addListener(_onChatShown);
    check();
  }

  void _onChatShown() {
    check();
    final web = _web;
    if (web == null || !_running() || !_onScreen()) return;
    // Cold restore lifts the pause
    if (web.tabList.isNotEmpty || _restoreTried) _reportPause(web);
    unawaited(restoreBehind(web));
  }

  void _reportPause(WebViewProvider web) {
    if (!missing.value || _pauseReported) return;
    _pauseReported = true;
    StatsController.chat.health({'fact': 'paused', 'kind': NativeChat.pauseKind(web), 'cold': !_hadLive});
  }

  /// Cold browser: saved tabs come back asleep, hidden
  Future<void> restoreBehind(WebViewProvider web) {
    if (web.tabList.isNotEmpty || _restoreTried) return _restore ?? Future.value();
    _restoreTried = true;
    return _restore = _restoreHidden(web).whenComplete(() => _restore = null);
  }

  Future<void> _restoreHidden(WebViewProvider web) async {
    _holding = true;
    _lostFor = 0;
    missing.value = false;
    // Out of the notifier that called
    await Future<void>.microtask(() {});
    await web.restoreBehind();
    final index = NativeChat.tornTabIndex(
      [for (final tab in web.tabList) tab.webViewKey == null ? null : tab.currentUrl],
      [web.currentTab, for (var i = 0; i < web.tabList.length; i++) i],
    );
    if (index == null) {
      _holding = false;
      _lostFor = _settle;
      chatToast('No Torn tab to reopen');
      return check();
    }
    if (isTornUrl(web.tabList[index].currentUrl)) web.allowHiddenLoad(index);
    final current = index == web.currentTab;
    current ? web.wakeTab(index) : web.activateTab(index);
    chatToast(current ? 'Torn opened in the background' : 'Switched to your Torn tab in the background');
    check();
  }

  @visibleForTesting
  void reset() {
    _web?.removeListener(check);
    _web = null;
    _shown.removeListener(_onChatShown);
    _restore = null;
    _restoreTried = false;
    _holding = false;
    _timer?.cancel();
    _timer = null;
    _lostFor = 0;
    _hadLive = false;
    _pauseReported = false;
    missing.value = false;
    exists.value = false;
  }

  // Background keeps its alerts
  void syncFreeze() => NativeChat.controller.setFrozen(missing.value && !appInBackground());

  void check() {
    final web = _web;
    if (web == null) return;
    exists.value =
        NativeChat.tornTabIndex(
          [for (final tab in web.tabList) tab.currentUrl],
          [for (var i = 0; i < web.tabList.length; i++) i],
          made: web.tabList.indexWhere((tab) => tab.id == _madeTab),
        ) !=
        null;
    final open = NativeChat.tornTabOpen(web);
    ChatEngine.instance.scene(shown: _onScreen(), tabLive: open && !appInBackground());
    if (!_running() || appInBackground()) {
      _timer?.cancel();
      _timer = null;
      _lostFor = 0;
      _holding = false;
      if (!_running()) {
        _hadLive = false;
        missing.value = false;
      }
    } else if (open) {
      _timer?.cancel();
      _timer = null;
      _lostFor = 0;
      _holding = false;
      _hadLive = true;
      missing.value = false;
    } else {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        _lostFor++;
        check();
      });
      // Never live: no margin
      final settled = !_hadLive && !_holding && _lostFor >= _settle && _sessionOk();
      if (settled || _lostFor >= _grace) {
        missing.value = true;
        if (_onScreen()) _reportPause(web);
      }
    }
    if (!missing.value) _pauseReported = false;
  }

  int? _find(WebViewProvider web) {
    final made = web.tabList.indexWhere((tab) => tab.id == _madeTab);
    final index = NativeChat.tornTabIndex(
      [for (final tab in web.tabList) tab.currentUrl],
      [web.currentTab, ...web.tabIndexesForGroup(web.focusedGroup), for (var i = 0; i < web.tabList.length; i++) i],
      live: (i) => _live(web.tabList[i]),
      made: made,
    );
    if (index != made) _madeTab = null;
    return index;
  }

  Future<void> openBrowser({bool keepChat = false}) async {
    final navigator = NativeChat.navigatorKey?.currentState;
    if (navigator == null || _opening) return;
    _opening = true;
    try {
      final web = navigator.context.read<WebViewProvider>();
      if (web.tabList.isEmpty) {
        await restoreBehind(web);
        if (web.tabList.isEmpty) await NativeChat.settledTabs(web);
      }
      final index = _find(web);
      navigator.popUntil((route) => route.isFirst);
      if (keepChat) chatToast(index == null ? 'Opening a Torn tab' : 'Switching to your Torn tab');
      if (index == null) {
        const home = 'https://www.torn.com';
        final before = web.tabList.length;
        keepChat
            ? await NativeChat.inBrowser(
                navigator.context,
                home,
                BrowserTapType.short,
                true,
                app: true,
                pdaIcon: true,
                reuse: () => _find(web),
              )
            : await NativeChat.openUrl(home, newTab: true, app: true, pdaIcon: true, reuse: () => _find(web));
        if (web.tabList.length > before) _madeTab = web.tabList.last.id;
        return;
      }
      if (!keepChat) NativeChat.hideQuickWindows();
      NativeChat.showTab(web, index);
      web.browserShowInForeground = true;
    } finally {
      _opening = false;
    }
  }
}
