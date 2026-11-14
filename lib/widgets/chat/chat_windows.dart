import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/webview/split_layout.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_ticker_queue.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_screen_route.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class _TopWatch extends NavigatorObserver {
  _TopWatch(this._out);

  final ValueNotifier<Route<dynamic>?> _out;
  Route<dynamic>? _top;

  void _set(Route<dynamic>? route) {
    _top = route;
    scheduleMicrotask(() => _out.value = _top);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route == _top) _set(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == _top) _set(newRoute);
  }
}

/// Chat windows and navigation state
class ChatWindows {
  ChatWindows({required bool Function() sessionOk, required bool Function(String) unlisted})
    : _sessionOk = sessionOk,
      _unlisted = unlisted;

  final bool Function() _sessionOk;
  final bool Function(String) _unlisted;

  final ValueNotifier<bool> screenOpen = ValueNotifier(false);
  final ChatTickerDemo tickerDemo = ChatTickerDemo();

  /// Pinged when a reply asks for focus
  final ValueNotifier<int> composerFocus = ValueNotifier(0);
  String? _focusRoom;

  /// Top route of the app navigator
  final ValueNotifier<Route<dynamic>?> rootTop = ValueNotifier(null);
  late final NavigatorObserver rootWatch = _TopWatch(rootTop);

  /// Top route of the drawer navigator
  final ValueNotifier<Route<dynamic>?> homeTop = ValueNotifier(null);
  late final NavigatorObserver homeWatch = _TopWatch(homeTop);

  /// Dialog on top, root or drawer
  bool get popupOnTop {
    final root = rootTop.value;
    if (root is PopupRoute) return true;
    return homeTop.value is PopupRoute && (root == null || root.isFirst);
  }

  // Profile speed dial open, bubble hides
  final ValueNotifier<bool> dialOpen = ValueNotifier(false);

  final ValueNotifier<bool> drawerOpen = ValueNotifier(false);

  static const int _maxWindows = 3;
  static const int _maxMinimized = 8;

  final ValueNotifier<ChatBigWindow?> bigWindow = ValueNotifier(null);

  /// Front one last
  final ValueNotifier<List<String>> quickWindows = ValueNotifier(const []);

  /// Newest last
  final ValueNotifier<List<ChatMinimized>> minimized = ValueNotifier(const []);
  ChatMinimized? _resume;
  Route<void>? _screens;

  /// Conversation pages on screen, top last
  final List<ChatMinimized Function()> shownPages = [];

  /// The one link preview window
  final ValueNotifier<({String url, int tap, String? fill})?> linkWindow = ValueNotifier(null);
  int _linkTaps = 0;

  GlobalKey<NavigatorState>? navigatorKey;

  /// Overlay navigator, above the windows
  GlobalKey<NavigatorState>? sheetsKey;
  BuildContext? get sheetsContext => sheetsKey?.currentState?.overlay?.context;

  late final Listenable shown = Listenable.merge([screenOpen, quickWindows, bigWindow]);

  ({ChatOnScreen shown, String? bigRoom})? _reopen;
  Timer? _reopenTimer;
  // Kept until the player changes something
  bool _saveHeld = false;

  static const Duration _reopenWait = Duration(seconds: 20);

  /// Conversation's Back, true when used
  bool Function()? bigWindowConversationBack;

  ChatPrefs get _prefs => NativeChat.prefs;
  ChatController get _controller => NativeChat.controller;

  bool get onScreen => screenOpen.value || quickWindows.value.isNotEmpty || bigWindowShown;

  /// True once, for the window asked
  bool takeComposerFocus(String roomId) {
    final mine = _focusRoom == roomId;
    if (mine) _focusRoom = null;
    return mine;
  }

  /// Over the cap, the back one goes
  void openQuickWindow(String roomId, {bool reply = false}) {
    StatsController.chat.count('open_window');
    _focusRoom = reply ? roomId : null;
    if (reply) composerFocus.value++;
    _leaveBigWindow(roomId);
    dropMinimized(roomId);
    final open = [...quickWindows.value.where((r) => r != roomId), roomId];
    while (open.length > _maxWindows) {
      _pushMinimized(ChatMinimized(open.removeAt(0), window: true));
    }
    quickWindows.value = open;
  }

  void swapQuickWindow(String from, String to) {
    _leaveBigWindow(to);
    final now = bigWindow.value;
    if (now != null && now.below.contains(from)) bigWindow.value = now.copyWith(below: {...now.below}..remove(from));
    dropMinimized(to);
    quickWindows.value = [for (final r in quickWindows.value) r == from ? to : r];
  }

  void focusQuickWindow(String roomId) {
    final open = quickWindows.value;
    if (!open.contains(roomId)) return;
    final now = bigWindow.value;
    if (now != null && now.below.contains(roomId)) {
      bigWindow.value = now.copyWith(below: {...now.below}..remove(roomId));
    }
    if (open.last != roomId) quickWindows.value = [...open.where((r) => r != roomId), roomId];
  }

  /// Back to front, bigWindow as [NativeChat.bigWindowId]
  List<String> get stackOrder {
    final now = bigWindow.value;
    final open = quickWindows.value;
    if (now == null || now.minimized) return open;
    return [...open.where(now.below.contains), NativeChat.bigWindowId, ...open.where((r) => !now.below.contains(r))];
  }

  bool get bigWindowShown => bigWindow.value?.minimized == false;

  bool get bigWindowFull => bigWindowShown && bigWindow.value!.full;

  bool bigWindowHolds(String roomId) => bigWindowShown && bigWindow.value?.roomId == roomId;

  void _leaveBigWindow(String roomId) {
    final now = bigWindow.value;
    if (now == null || (now.roomId != roomId && !now.below.contains(roomId))) return;
    bigWindow.value = ChatBigWindow(
      roomId: now.roomId == roomId ? null : now.roomId,
      minimized: now.minimized,
      full: now.full,
      below: {...now.below}..remove(roomId),
      side: now.side,
    );
  }

  void openBigWindow({SplitSide? side}) {
    leaveScreens();
    final now = bigWindow.value;
    bigWindow.value = ChatBigWindow(
      roomId: now?.roomId,
      full: now?.full ?? false,
      below: {...quickWindows.value},
      side: side,
    );
  }

  /// False when it closed
  bool toggleBigWindow({SplitSide? side}) {
    final now = bigWindow.value;
    final sameSide = now?.side == null || side == null || now?.side == side;
    if (now != null && !now.minimized && sameSide) {
      if (quickWindows.value.every(now.below.contains)) {
        closeBigWindow();
        return false;
      }
      focusBigWindow();
      return true;
    }
    openBigWindow(side: side);
    return true;
  }

  /// Tap on the chat button
  void launch(NavigatorState navigator, {SplitSide? side, bool toggle = false}) {
    final room = _controller.backTo;
    if (_prefs.launcherTap == ChatLauncherTap.full) {
      open(navigator, roomId: room);
      return;
    }
    if (!toggle) {
      openBigWindow(side: side);
    } else if (!toggleBigWindow(side: side)) {
      return;
    }
    if (room != null) setBigWindowRoom(room);
    StatsController.chat.count('open_big_window');
  }

  void bigWindowBack() {
    if (bigWindowConversationBack?.call() ?? false) return;
    bigWindow.value?.roomId == null ? minimizeBigWindow() : setBigWindowRoom(null);
  }

  void setBigWindowRoom(String? roomId) {
    final now = bigWindow.value;
    if (now == null || now.roomId == roomId) return;
    if (roomId != null) _freeRoom(roomId);
    bigWindow.value = now.inRoom(roomId);
  }

  // Kept as a bubble if drafted
  void _freeRoom(String roomId) {
    if (!quickWindows.value.contains(roomId)) return;
    _prefs.draftFor(roomId).isEmpty ? closeQuickWindow(roomId) : minimizeQuickWindow(roomId);
  }

  void focusBigWindow() {
    final now = bigWindow.value;
    if (now == null || quickWindows.value.every(now.below.contains)) return;
    bigWindow.value = now.copyWith(below: {...quickWindows.value});
  }

  void minimizeBigWindow() {
    final now = bigWindow.value;
    if (now == null || now.minimized) return;
    if (!_prefs.canMinimize) return closeBigWindow();
    bigWindow.value = now.copyWith(minimized: true);
  }

  void restoreBigWindow() {
    final now = bigWindow.value;
    if (now == null || !now.minimized) return;
    leaveScreens();
    bigWindow.value = now.copyWith(minimized: false, below: {...quickWindows.value});
  }

  void closeBigWindow() => bigWindow.value = null;

  void toggleBigWindowFull() {
    final now = bigWindow.value;
    if (now != null) bigWindow.value = now.copyWith(full: !now.full);
  }

  void popOutBigWindow() {
    final room = bigWindow.value?.roomId;
    if (room != null) openQuickWindow(room);
  }

  void expandBigWindow({bool saved = false}) {
    final room = bigWindow.value?.roomId;
    closeBigWindow();
    unawaited(_openOnceClosed(room, saved: saved));
  }

  // Closing window holds the room until disposed
  Future<void> _openOnceClosed(String? roomId, {bool saved = false}) async {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (navigator.mounted) await open(navigator, roomId: roomId, saved: saved);
  }

  // Back as a bubble, never a room
  @visibleForTesting
  void loadBigWindow() => bigWindow.value = ChatBigWindow.decode(_prefs.bigWindow).bigWindow;

  /// Bubbles now, open ones when ready
  void restoreWindows() {
    shown.removeListener(_onShownChanged);
    _controller.removeListener(saveOnScreen);
    if (_prefs.canMinimize) {
      minimized.value = [
        for (final entry in _prefs.windows) ChatMinimized(ChatWindowFrame.decode(entry).roomId, window: true),
      ];
      loadBigWindow();
    }
    _saveHeld = false;
    _armReopen();
    shown.addListener(_onShownChanged);
    _controller.addListener(saveOnScreen);
  }

  void _onShownChanged() {
    if (onScreen) _controller.backTo = null;
    _saveHeld = false;
    saveOnScreen();
  }

  Iterable<String> get reopening => _reopen?.shown.stack.where((id) => id != NativeChat.bigWindowId) ?? const [];

  @visibleForTesting
  void saveOnScreen() {
    if (_reopen != null || _saveHeld) return;
    final now = ChatOnScreen(
      stack: stackOrder,
      bigFull: bigWindowFull,
      page: screenOpen.value,
      pageRoom: screenOpen.value ? shownPages.lastOrNull?.call().roomId : null,
    ).encode();
    if (!listEquals(now, _prefs.onScreen)) _prefs.setOnScreen(now);
  }

  void _armReopen() {
    dropReopen();
    if (!_prefs.reopenChats) return;
    final shown = ChatOnScreen.decode(_prefs.onScreen);
    if (shown.isEmpty) return;
    _reopen = (shown: shown, bigRoom: ChatBigWindow.decode(_prefs.bigWindow).bigWindow?.roomId);
    _reopenTimer = Timer(_reopenWait, () {
      dropReopen();
      _saveHeld = true;
    });
    _controller.addListener(tryReopen);
    rootTop.addListener(tryReopen);
    homeTop.addListener(tryReopen);
    tryReopen();
  }

  void dropReopen() {
    _reopen = null;
    _reopenTimer?.cancel();
    _reopenTimer = null;
    _controller.removeListener(tryReopen);
    rootTop.removeListener(tryReopen);
    homeTop.removeListener(tryReopen);
  }

  @visibleForTesting
  void tryReopen() {
    final pending = _reopen;
    if (pending == null || !NativeChat.usable || !_sessionOk()) return;
    final shown = pending.shown;
    final navigator = navigatorKey?.currentState;
    final page = shown.page && !screenOpen.value;
    // The full chat waits for dialogs
    if (page && (navigator == null || popupOnTop || !(rootTop.value?.isFirst ?? true))) return;
    dropReopen();
    // Asked from a notification, it wins
    if (screenOpen.value) return;
    final rooms = [
      for (final id in shown.stack)
        if (id != NativeChat.bigWindowId && !_unlisted(id)) id,
    ];
    final asked = quickWindows.value;
    for (final id in rooms) {
      _leaveBigWindow(id);
      dropMinimized(id);
    }
    final windows = [...rooms.where((id) => !asked.contains(id)), ...asked];
    while (windows.length > _maxWindows) {
      _pushMinimized(ChatMinimized(windows.removeAt(0), window: true));
    }
    quickWindows.value = windows;
    if (shown.stack.contains(NativeChat.bigWindowId) && !bigWindowShown) {
      final room = bigWindow.value == null ? pending.bigRoom : bigWindow.value!.roomId;
      final keep = room != null && !windows.contains(room) && !_unlisted(room);
      bigWindow.value = ChatBigWindow(
        roomId: keep ? room : null,
        full: shown.bigFull,
        below: {...shown.stack.takeWhile((id) => id != NativeChat.bigWindowId).where(windows.contains)},
      );
    }
    if (page) {
      final room = shown.pageRoom;
      unawaited(open(navigator!, roomId: room == null || _unlisted(room) ? null : room));
    }
  }

  /// Without [roomId], all of them
  void closeQuickWindow([String? roomId]) {
    quickWindows.value = roomId == null ? const [] : [...quickWindows.value.where((r) => r != roomId)];
  }

  /// Without [roomId], the front one
  void minimizeQuickWindow([String? roomId]) {
    final room = roomId ?? quickWindows.value.lastOrNull;
    if (room == null || !quickWindows.value.contains(room)) return;
    _pushMinimized(ChatMinimized(room, window: true));
    closeQuickWindow(room);
  }

  void hideQuickWindows() {
    minimizeBigWindow();
    if (quickWindows.value.isEmpty) return;
    for (final roomId in quickWindows.value) {
      _pushMinimized(ChatMinimized(roomId, window: true));
    }
    quickWindows.value = const [];
  }

  void minimize(String roomId, {double offset = 0, String? frozenAtId}) {
    leaveScreens();
    _pushMinimized(ChatMinimized(roomId, offset: offset, frozenAtId: frozenAtId));
  }

  // Switched off, the bubbles close
  void dropBubbles() {
    if (_prefs.canMinimize) return;
    if (minimized.value.isNotEmpty) minimized.value = const [];
    if (bigWindow.value?.minimized ?? false) closeBigWindow();
  }

  void _pushMinimized(ChatMinimized item) {
    if (!_prefs.canMinimize) return;
    final list = [...minimized.value.where((m) => m.roomId != item.roomId), item];
    minimized.value = list.sublist(math.max(0, list.length - _maxMinimized));
  }

  void dropMinimized(String roomId) {
    if (!minimized.value.any((m) => m.roomId == roomId)) return;
    minimized.value = [...minimized.value.where((m) => m.roomId != roomId)];
  }

  void popOut(String roomId) {
    leaveScreens();
    openQuickWindow(roomId);
  }

  /// Without [item], the newest
  void restore([ChatMinimized? item]) {
    final last = item ?? minimized.value.lastOrNull;
    final navigator = navigatorKey?.currentState;
    if (last == null) return;
    if (last.window) return openQuickWindow(last.roomId);
    if (navigator == null) return;
    _resume = last;
    open(navigator, roomId: last.roomId);
  }

  /// Once, for the page that reopens it
  ChatMinimized? takeResume(String roomId) {
    final resume = _resume;
    _resume = null;
    return resume?.roomId == roomId ? resume : null;
  }

  void leaveScreens() {
    final navigator = navigatorKey?.currentState;
    final screens = _screens;
    if (navigator == null || screens == null || !screens.isActive) return;
    navigator.popUntil((route) => route == screens);
    navigator.pop();
  }

  void expandQuickWindow([String? roomId]) {
    final room = roomId ?? quickWindows.value.lastOrNull;
    if (room == null) return;
    closeQuickWindow(room);
    unawaited(_openOnceClosed(room));
  }

  /// Next account starts clean
  void forget() {
    quickWindows.value = const [];
    minimized.value = const [];
    bigWindow.value = null;
  }

  /// By the preview setting unless [always]
  Future<void> openLink(String url, {bool always = false, String? fill}) async {
    if (!always && !_prefs.linkWindow) return NativeChat.openUrl(url, newTab: _prefs.linkNewTab);
    FocusManager.instance.primaryFocus?.unfocus();
    linkWindow.value = (url: url, tap: ++_linkTaps, fill: fill);
  }

  void closeLinkWindow() => linkWindow.value = null;

  /// Chat to bubbles, app on its first route
  NavigatorState? leaveForBrowser({String? backTo}) {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return null;
    closeLinkWindow();
    // Back to this conversation, not the list
    final page = screenOpen.value ? shownPages.lastOrNull?.call() : null;
    if (page != null) _pushMinimized(page);
    hideQuickWindows();
    navigator.popUntil((route) => route.isFirst);
    _controller.backTo = backTo;
    return navigator;
  }

  Future<void> openDm(ChatUser user) async {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;
    final roomId = ChatRoom.dmId(user.id);
    closeQuickWindow(roomId);
    hideQuickWindows();
    _controller.addDraftDm(user);
    await _openOnceClosed(roomId);
  }

  Future<void> open(NavigatorState navigator, {String? roomId, String? messageId, bool saved = false}) async {
    if (!NativeChat.compiled) return;
    if (screenOpen.value) {
      if (roomId == null || _controller.isOnScreen(roomId)) return;
      await navigator.push(
        ChatScreenRoute(
          chat: _controller,
          page: ChatConversationPage(roomId: roomId, focusMessageId: messageId),
        ),
      );
      _controller.closeConversation(roomId);
      return;
    }
    if (!_prefs.inAppEnabled) NativeChat.setEnabled(true);
    minimized.value = [...minimized.value.where((m) => m.window && m.roomId != roomId)];
    minimizeBigWindow();
    screenOpen.value = true;
    final route = ChatScreenRoute<void>(
      chat: _controller,
      page: ChatPage(initialRoomId: roomId, initialMessageId: messageId, openSaved: saved),
    );
    _screens = route;
    await navigator.push(route);
    if (_screens == route) _screens = null;
    screenOpen.value = false;
  }
}
