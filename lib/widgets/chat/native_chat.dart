import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart' show selectNotificationStream;
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_ticker_queue.dart';
import 'package:torn_pda/providers/chat/chat_translate.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/torn-pda-native/chat/torn_chat_source.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/chat_notifications.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/torn_web.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chat/chat_hit_targets.dart';
import 'package:torn_pda/widgets/chat/chat_session.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_torn_tab.dart';
import 'package:torn_pda/widgets/chat/chat_windows.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_engine.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ChatMinimized {
  const ChatMinimized(this.roomId, {this.window = false, this.offset = 0, this.frozenAtId});

  final String roomId;
  final bool window;
  final double offset;
  final String? frozenAtId;
}

class ChatBigWindow {
  const ChatBigWindow({this.roomId, this.minimized = false, this.full = false, this.below = const {}, this.side});

  /// Null shows the list
  final String? roomId;
  final bool minimized;
  final bool full;

  /// Small windows drawn under it
  final Set<String> below;

  /// Split panel it was opened from
  final SplitSide? side;

  ChatBigWindow copyWith({bool? minimized, bool? full, Set<String>? below}) => ChatBigWindow(
    roomId: roomId,
    minimized: minimized ?? this.minimized,
    full: full ?? this.full,
    below: below ?? this.below,
    side: side,
  );

  ChatBigWindow inRoom(String? id) =>
      ChatBigWindow(roomId: id, minimized: minimized, full: full, below: below, side: side);

  /// State, room, then the frame
  static List<String> encode(ChatBigWindow? bigWindow, Rect? frame) => [
    if (bigWindow == null) 'closed' else (bigWindow.minimized ? 'min' : 'open'),
    bigWindow?.roomId ?? '',
    if (frame != null)
      for (final v in [frame.left, frame.top, frame.width, frame.height]) v.toStringAsFixed(1),
  ];

  static ({ChatBigWindow? bigWindow, Rect? frame}) decode(List<String> saved) {
    if (saved.length < 2) return (bigWindow: null, frame: null);
    final v = saved.skip(2).take(4).map(double.tryParse).toList();
    final frame = v.length == 4 && !v.contains(null) ? Rect.fromLTWH(v[0]!, v[1]!, v[2]!, v[3]!) : null;
    final bigWindow = switch (saved[0]) {
      'open' || 'min' => ChatBigWindow(roomId: saved[1].isEmpty ? null : saved[1], minimized: true),
      _ => null,
    };
    return (bigWindow: bigWindow, frame: frame);
  }
}

/// Open windows and full chat
class ChatOnScreen {
  const ChatOnScreen({this.stack = const [], this.bigFull = false, this.page = false, this.pageRoom});

  /// Back to front, with [NativeChat.bigWindowId]
  final List<String> stack;

  /// Big window filling the screen
  final bool bigFull;

  final bool page;
  final String? pageRoom;

  static const String _full = ':full';
  static const String _screen = ':screen:';

  bool get isEmpty => stack.isEmpty && !page;

  List<String> encode() => [...stack, if (bigFull) _full, if (page) '$_screen${pageRoom ?? ''}'];

  static ChatOnScreen decode(List<String> saved) {
    final room = saved.where((e) => e.startsWith(_screen)).firstOrNull?.substring(_screen.length);
    return ChatOnScreen(
      stack: [
        for (final e in saved.toSet())
          if (e == NativeChat.bigWindowId || (e.isNotEmpty && !e.startsWith(':'))) e,
      ],
      bigFull: saved.contains(_full),
      page: room != null,
      pageRoom: room == null || room.isEmpty ? null : room,
    );
  }
}

class NativeChat {
  NativeChat._();

  static final ChatPrefs prefs = ChatPrefs()..addListener(() => windows.dropBubbles());
  static final TornChatSource _source = TornChatSource(ChatEngine.instance);
  static final ChatController controller = ChatController(_source, prefs, TornChatApi(prefs));
  static final ChatTranslator translator = ChatTranslator();
  static final ChatFactionOps factionOps = ChatFactionOps(
    controller,
    prefs,
    launch: attackCalledTarget,
    offer: _offerAttack,
    known: knownHitTargets,
    clock: (at) => chatAppClock().clock(at),
  );

  static void _offerAttack(ChatHitJoin join) =>
      chatToast('Attack ${join.name} now', seconds: 10, action: 'Attack', onAction: factionOps.takeOffer);
  static final ChatFactionEvents factionEvents = ChatFactionEvents(controller, prefs);

  static final ChatWindows windows = ChatWindows(
    sessionOk: () => sessionOk(),
    unlisted: (id) => isUnlisted(id),
  );
  static ValueNotifier<bool> get screenOpen => windows.screenOpen;
  static ChatTickerDemo get tickerDemo => windows.tickerDemo;
  static ValueNotifier<Route<dynamic>?> get rootTop => windows.rootTop;
  static NavigatorObserver get rootWatch => windows.rootWatch;
  static ValueNotifier<Route<dynamic>?> get homeTop => windows.homeTop;
  static NavigatorObserver get homeWatch => windows.homeWatch;
  static bool get popupOnTop => windows.popupOnTop;
  static ValueNotifier<bool> get dialOpen => windows.dialOpen;
  static ValueNotifier<bool> get drawerOpen => windows.drawerOpen;
  static ValueNotifier<({String url, int tap, String? fill})?> get linkWindow => windows.linkWindow;
  static GlobalKey<NavigatorState>? get navigatorKey => windows.navigatorKey;
  static set navigatorKey(GlobalKey<NavigatorState>? key) => windows.navigatorKey = key;
  static GlobalKey<NavigatorState>? get sheetsKey => windows.sheetsKey;
  static set sheetsKey(GlobalKey<NavigatorState>? key) => windows.sheetsKey = key;
  static BuildContext? get sheetsContext => windows.sheetsContext;
  static Future<void> openLink(String url, {bool always = false, String? fill}) =>
      windows.openLink(url, always: always, fill: fill);
  static void closeLinkWindow() => windows.closeLinkWindow();
  static ValueNotifier<int> get composerFocus => windows.composerFocus;
  static bool takeComposerFocus(String roomId) => windows.takeComposerFocus(roomId);
  static ValueNotifier<ChatBigWindow?> get bigWindow => windows.bigWindow;
  static ValueNotifier<List<String>> get quickWindows => windows.quickWindows;
  static ValueNotifier<List<ChatMinimized>> get minimized => windows.minimized;
  static List<ChatMinimized Function()> get shownPages => windows.shownPages;
  static bool Function()? get bigWindowConversationBack => windows.bigWindowConversationBack;
  static set bigWindowConversationBack(bool Function()? back) => windows.bigWindowConversationBack = back;
  static List<String> get stackOrder => windows.stackOrder;
  static bool get bigWindowShown => windows.bigWindowShown;
  static bool get bigWindowFull => windows.bigWindowFull;
  static bool bigWindowHolds(String roomId) => windows.bigWindowHolds(roomId);
  static Iterable<String> get reopening => windows.reopening;
  static void openQuickWindow(String roomId, {bool reply = false}) => windows.openQuickWindow(roomId, reply: reply);
  static void swapQuickWindow(String from, String to) => windows.swapQuickWindow(from, to);
  static void focusQuickWindow(String roomId) => windows.focusQuickWindow(roomId);
  static void closeQuickWindow([String? roomId]) => windows.closeQuickWindow(roomId);
  static void minimizeQuickWindow([String? roomId]) => windows.minimizeQuickWindow(roomId);
  static void expandQuickWindow([String? roomId]) => windows.expandQuickWindow(roomId);
  static void hideQuickWindows() => windows.hideQuickWindows();
  static void openBigWindow({SplitSide? side}) => windows.openBigWindow(side: side);
  static void launch(NavigatorState navigator, {SplitSide? side, bool toggle = false}) =>
      windows.launch(navigator, side: side, toggle: toggle);
  static void bigWindowBack() => windows.bigWindowBack();
  static void setBigWindowRoom(String? roomId) => windows.setBigWindowRoom(roomId);
  static void focusBigWindow() => windows.focusBigWindow();
  static void minimizeBigWindow() => windows.minimizeBigWindow();
  static void restoreBigWindow() => windows.restoreBigWindow();
  static void closeBigWindow() => windows.closeBigWindow();
  static void toggleBigWindowFull() => windows.toggleBigWindowFull();
  static void popOutBigWindow() => windows.popOutBigWindow();
  static void expandBigWindow({bool saved = false}) => windows.expandBigWindow(saved: saved);
  static void minimize(String roomId, {double offset = 0, String? frozenAtId}) =>
      windows.minimize(roomId, offset: offset, frozenAtId: frozenAtId);
  static void dropMinimized(String roomId) => windows.dropMinimized(roomId);
  static void popOut(String roomId) => windows.popOut(roomId);
  static void restore([ChatMinimized? item]) => windows.restore(item);
  static ChatMinimized? takeResume(String roomId) => windows.takeResume(roomId);
  static NavigatorState? leaveForBrowser({String? backTo}) => windows.leaveForBrowser(backTo: backTo);
  static Future<void> openDm(ChatUser user) => windows.openDm(user);
  static Future<void> open(NavigatorState navigator, {String? roomId, String? messageId, bool saved = false}) =>
      windows.open(navigator, roomId: roomId, messageId: messageId, saved: saved);

  /// The big window in [stackOrder]
  static const String bigWindowId = ':bigWindow';

  static const String _tapPrefix = 'pdachat:';
  static const String settingsPayload = 'pdachat-settings';
  static const String alertsPayload = 'pdachat-alerts';
  static const String _chainingPrefix = 'pdachat-chaining:';

  static final ChatSession session = ChatSession();
  static ValueNotifier<bool> get remoteEnabled => session.remoteEnabled;
  static ValueNotifier<bool> get keyValid => session.keyValid;
  static bool get engineEnabled => session.engineEnabled;
  static bool get compiled => session.compiled;
  static bool get usable => session.usable;
  static bool get listens => session.listens;
  static Future<void> start({NativeUserProvider? login}) => session.start(login: login);
  static void forgetAccount() => session.forgetAccount();
  static String dmTapPayload(int userId, [String? name]) => session.dmTapPayload(userId, name);
  static void setEnabled(bool value) => session.setEnabled(value);
  static Future<void> setRemoteEnabled(bool value) => session.setRemoteEnabled(value);

  static final ChatTornTab tornTab = ChatTornTab(
    shown: windows.shown,
    running: () => session.shouldRun,
    onScreen: () => windows.onScreen,
    live: (tab) => isLive(tab),
    sessionOk: () => sessionOk(),
  );

  static ValueNotifier<bool> get tornTabMissing => tornTab.missing;

  static ValueNotifier<bool> get tornTabExists => tornTab.exists;

  @visibleForTesting
  static bool Function(TabDetails) isLive = tabAlive;

  @visibleForTesting
  static bool Function(TabDetails) isLoading = tabLoading;

  @visibleForTesting
  static Future<void> Function() sendTouch = _source.touch;

  @visibleForTesting
  static bool Function() sessionOk = () => controller.ready && controller.connection == ChatConnection.connected;

  @visibleForTesting
  static bool Function(String) isUnlisted = (id) => controller.isUnlisted(id);

  static bool get tickerOn =>
      prefs.ticker &&
      usable &&
      !screenOpen.value &&
      quickWindows.value.isEmpty &&
      (bigWindow.value?.minimized ?? true) &&
      !tornTabMissing.value;

  /// The open app alerts DMs itself
  static bool get coversDmPush =>
      compiled &&
      !tornTabMissing.value &&
      (prefs.inAppEnabled ? prefs.alertNotify : prefs.dmPush) &&
      controller.connection == ChatConnection.connected &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  /// The browser wiped Torn cookies
  static void recheckSession() => Timer(const Duration(seconds: 8), ChatEngine.instance.recheck);

  static String pauseKind(WebViewProvider web) {
    final shown = _shownTornTabs(web);
    if (shown.isEmpty) return 'no_tab';
    final tab = shown.first;
    final page = tab.webViewKey?.currentState;
    if (tab.sleepTab) return 'asleep';
    if (tab.needsReloadAfterRendererGone) return 'renderer_gone';
    if (page == null) return 'not_mounted';
    if (page.isParked) return 'parked';
    if (page.initialLoadPending) return 'not_loaded';
    return 'other';
  }

  /// Awake, loaded and not parked
  static bool tabAlive(TabDetails tab) {
    final page = tab.webViewKey?.currentState;
    return !tab.sleepTab &&
        !tab.needsReloadAfterRendererGone &&
        page != null &&
        !page.isParked &&
        !page.initialLoadPending;
  }

  /// Awake and mounted, maybe still loading
  static bool tabLoading(TabDetails tab) {
    final page = tab.webViewKey?.currentState;
    return !tab.sleepTab && !tab.needsReloadAfterRendererGone && page != null && !page.isParked;
  }

  /// Shown tabs only, both split sides
  static List<TabDetails> _shownTornTabs(WebViewProvider web) => [
    for (final i in [
      web.visibleTabIndexForGroup(SplitGroup.main),
      if (web.splitBrowsersActive) web.visibleTabIndexForGroup(SplitGroup.apart),
    ])
      if (i != null && i < web.tabList.length && isTornUrl(web.tabList[i].currentUrl)) web.tabList[i],
  ];

  static bool tornTabOpen(WebViewProvider web, {bool loaded = false}) {
    return _shownTornTabs(web).any((t) => isLive(t) || (!loaded && web.isTabUidOnScreen(t.id) && isLoading(t)));
  }

  /// Taps and typing only, never scrolls
  static void touch() {
    if (tornTabMissing.value) return;
    unawaited(sendTouch());
  }

  // Letters only, payloads match by substring
  static String tapPayload(String roomId) =>
      _tapPrefix + roomId.codeUnits.expand((c) => [c >> 4, c & 15]).map((n) => String.fromCharCode(65 + n)).join();

  // Read fresh at tap time
  static Future<bool> tapsOpenChat() async =>
      engineEnabled && await Prefs().getNativeChatRemoteEnabled() && await Prefs().getNativeChatEnabled();

  // Adds the DM sender when known
  static String webChatPayload(String roomId) {
    final peer = ChatRoom.peerIdOf(roomId);
    return peer != null && peer > 0 ? 'tornChat:$peer' : 'tornChat';
  }

  static String? webChatPeer(String? payload) {
    final m = RegExp(r'^tornChat:([1-9]\d{0,17})$').firstMatch(payload ?? '');
    return m?.group(1);
  }

  static String? roomFromTap(String? payload) {
    if (payload == null || !payload.startsWith(_tapPrefix)) return null;
    final letters = payload.substring(_tapPrefix.length).codeUnits.map((c) => c - 65).toList();
    if (letters.isEmpty || letters.length.isOdd || letters.any((n) => n < 0 || n > 15)) return null;
    return String.fromCharCodes([for (var i = 0; i < letters.length; i += 2) letters[i] << 4 | letters[i + 1]]);
  }

  static String get translateTarget => prefs.translateTo.isEmpty ? ChatTranslator.deviceLanguage() : prefs.translateTo;

  @visibleForTesting
  static bool? debugCanShareToFaction;

  static bool get canShareToFaction =>
      debugCanShareToFaction ??
      (compiled && controller.connection == ChatConnection.connected && UserHelper.factionId != 0);

  static bool get canShare => compiled && controller.connection == ChatConnection.connected;

  /// Leaves [text] in faction composer
  static void shareToFaction(String text) {
    ChatShareIn.offer(ChatFactionOps.roomId, ChatShared(text: text.trim()));
    final navigator = navigatorKey?.currentState;
    if (screenOpen.value && navigator != null) {
      open(navigator, roomId: ChatFactionOps.roomId);
      return;
    }
    openQuickWindow(ChatFactionOps.roomId);
  }

  static Future<void> openUrl(
    String url, {
    BrowserTapType tap = BrowserTapType.short,
    bool newTab = false,
    bool app = false,
    bool pdaIcon = false,
    int? Function()? reuse,
  }) async {
    final navigator = leaveForBrowser();
    if (navigator == null) return;
    await inBrowser(navigator.context, url, tap, newTab, app: app, pdaIcon: pdaIcon, reuse: reuse);
  }

  static Future<void> inBrowser(
    BuildContext context,
    String url,
    BrowserTapType tap,
    bool newTab, {
    bool app = false,
    bool pdaIcon = false,
    int? Function()? reuse,
  }) async {
    final web = context.read<WebViewProvider>();
    if (newTab && (app || await Prefs().getDefaultBrowser() == 'app')) {
      final cold = web.tabList.isEmpty;
      pdaIcon
          ? web.pdaIconActivation(shortTap: true, context: context, automaticLogin: false)
          : web.browserShowInForeground = true;
      if (cold) await settledTabs(web);
      final found = reuse?.call();
      if (found != null) return showTab(web, found);
      if (web.tabList.isNotEmpty) {
        await web.addTab(url: url, splitApart: web.splitBrowsersActive && web.focusedGroup == SplitGroup.apart);
        web.activateTab(web.tabList.length - 1);
        return;
      }
    }
    if (!context.mounted) return;
    await web.openBrowserPreference(context: context, url: url, browserTapType: tap, focusedPanel: true, forceApp: app);
  }

  // A cold browser restores its tabs first
  static Future<void> settledTabs(WebViewProvider web) async {
    for (var i = 0, still = 0, count = -1; i < 80 && still < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      still = web.tabList.isNotEmpty && web.tabList.length == count ? still + 1 : 0;
      count = web.tabList.length;
    }
  }

  static void showTab(WebViewProvider web, int index) {
    if (index != web.currentTab) {
      web.activateTab(index);
    } else if (!isLive(web.tabList[index])) {
      web.wakeTab(index);
    }
  }

  /// Browser side with current tab, else app
  static SplitSide? get focusedSplitSide {
    final context = navigatorKey?.currentContext;
    if (context == null) return null;
    final web = context.read<WebViewProvider>();
    if (web.splitRightSlot == null) return null;
    if (web.splitBrowsersActive) return web.slotOfGroup(web.focusedGroup);
    return web.splitAppSide;
  }

  /// Split panel of a tab
  static SplitSide? splitSideOfTab(String tabUid) {
    final context = navigatorKey?.currentContext;
    if (context == null) return null;
    final web = context.read<WebViewProvider>();
    if (web.splitRightSlot == null) return null;
    if (web.splitBrowsersActive) {
      return web.slotOfGroup(web.getTabByUid(tabUid)?.group ?? SplitGroup.main);
    }
    return switch (web.splitAppSide) {
      SplitSide.left => SplitSide.right,
      SplitSide.right => SplitSide.left,
      null => null,
    };
  }

  static Future<void> openTornBrowser({bool keepChat = false}) => tornTab.openBrowser(keepChat: keepChat);

  static int? tornTabIndex(List<String?> urls, Iterable<int> order, {bool Function(int)? live, int made = -1}) {
    final torn = [
      for (final i in order)
        if (i >= 0 && i < urls.length && isTornUrl(urls[i])) i,
    ];
    final found = torn.where((i) => live?.call(i) ?? true).firstOrNull ?? torn.firstOrNull;
    if (found != null || made < 0 || made >= urls.length) return found;
    return switch (urls[made]) {
      null || '' || 'about:blank' => made,
      _ => null,
    };
  }

  /// From the full page
  static Future<void> goToTornTab() async {
    if (navigatorKey?.currentState == null) return;
    final room = controller.currentRoomId;
    openBigWindow();
    setBigWindowRoom(room);
    await openTornBrowser(keepChat: true);
  }

  /// Where Torn Authentication lives
  static void openSettings() => _openPage(settingsPayload);

  static void openAlerts() => _openPage(alertsPayload);

  static void openChaining({required bool war}) {
    if (leaveForBrowser(backTo: ChatFactionOps.roomId) == null) return;
    selectNotificationStream.add(chainingPayload(war: war));
  }

  static String chainingPayload({required bool war}) => '$_chainingPrefix${war ? 'war' : 'targets'}';

  /// Chaining tab index, null if not ours
  static int? chainingTabOf(String payload) => switch (payload) {
    '${_chainingPrefix}targets' => 0,
    '${_chainingPrefix}war' => 2,
    _ => null,
  };

  static void _openPage(String payload) {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;
    hideQuickWindows();
    navigator.popUntil((route) => route.isFirst);
    selectNotificationStream.add(payload);
  }

  static const String shortcutPrefix = 'chat:';

  /// Null when the chat can't open it
  static String? shortcutTitle(String roomId) {
    if (!usable || prefs.hiddenRooms.contains(roomId)) return null;
    final known = controller.conversations.where((r) => r.id == roomId).firstOrNull?.name;
    if (known != null) return known;
    if (controller.isUnlisted(roomId)) return null;
    final cached = prefs.shortcutCache.where((e) => e.startsWith('$roomId|')).firstOrNull;
    return cached?.substring(roomId.length + 1);
  }

  /// Remote Config native_chat_tab_grace_seconds
  static void setTabGrace(int seconds) => tornTab.setGrace(seconds);

  /// Remote Config native_chat_reply_enabled
  static Future<void> setReplyEnabled(bool value) async {
    if (value == await BackgroundPrefs().getNativeChatReplyEnabled()) return;
    await BackgroundPrefs().setNativeChatReplyEnabled(value);
    if (Platform.isIOS) await registerTornChatCategories(reply: value);
  }
}
