import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:torn_pda/drawer.dart' show pdaShortcutItems;
import 'package:torn_pda/main.dart' show registerTornChatCategories, selectNotificationStream;
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_reminder.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/models/chat/chat_shortcuts.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_events.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_push_rules.dart';
import 'package:torn_pda/providers/chat/chat_telemetry.dart';
import 'package:torn_pda/providers/chat/chat_ticker_queue.dart';
import 'package:torn_pda/providers/chat/chat_translate.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/torn-pda-native/chat/torn_chat_source.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_engine.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ChatMinimized {
  const ChatMinimized(this.roomId, {this.window = false, this.offset = 0, this.frozenAtId});

  final String roomId;
  final bool window;
  final double offset;
  final String? frozenAtId;
}

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

class NativeChat {
  NativeChat._();

  static final ChatPrefs prefs = ChatPrefs();
  static final TornChatSource _source = TornChatSource(ChatEngine.instance);
  static final ChatController controller = ChatController(_source, prefs, TornChatApi());
  static final ChatTranslator translator = ChatTranslator();
  static final ChatFactionOps _factionOps = ChatFactionOps(controller, prefs);
  static final ChatFactionEvents factionEvents = ChatFactionEvents(controller, prefs);
  static final ValueNotifier<bool> screenOpen = ValueNotifier(false);
  static final ChatTickerDemo tickerDemo = ChatTickerDemo();

  /// Pinged when a reply asks for focus
  static final ValueNotifier<int> composerFocus = ValueNotifier(0);
  static String? _focusRoom;

  /// Top route of the app navigator
  static final ValueNotifier<Route<dynamic>?> rootTop = ValueNotifier(null);
  static final NavigatorObserver rootWatch = _TopWatch(rootTop);

  /// Top route of the drawer navigator
  static final ValueNotifier<Route<dynamic>?> homeTop = ValueNotifier(null);
  static final NavigatorObserver homeWatch = _TopWatch(homeTop);

  /// Dialog on top, root or drawer
  static bool get popupOnTop {
    final root = rootTop.value;
    if (root is PopupRoute) return true;
    return homeTop.value is PopupRoute && (root == null || root.isFirst);
  }

  // Profile speed dial open, bubble hides
  static final ValueNotifier<bool> dialOpen = ValueNotifier(false);

  static final ValueNotifier<bool> drawerOpen = ValueNotifier(false);

  static const int _maxWindows = 3;
  static const int _maxMinimized = 8;

  /// Front one last
  static final ValueNotifier<List<String>> quickWindows = ValueNotifier(const []);

  /// Newest last
  static final ValueNotifier<List<ChatMinimized>> minimized = ValueNotifier(const []);
  static ChatMinimized? _resume;
  static Route<void>? _screens;

  /// Conversation pages on screen, top last
  static final List<ChatMinimized Function()> shownPages = [];

  /// The one link preview window
  static final ValueNotifier<({String url, int tap, String? fill})?> linkWindow = ValueNotifier(null);
  static int _linkTaps = 0;

  static GlobalKey<NavigatorState>? navigatorKey;

  static const String _tapPrefix = 'pdachat:';
  static const String settingsPayload = 'pdachat-settings';
  static const String alertsPayload = 'pdachat-alerts';
  static bool _emblemDone = false;
  static DateTime _emblemNext = DateTime(0);
  static int _emblemTries = 0;
  static int? _emblemFor;
  static AppLifecycleListener? _lifecycle;
  static WebViewProvider? _web;
  static String _webUrls = '';
  static NativeUserProvider? _login;
  static bool _hadLogin = false;
  static SettingsProvider? _settings;
  static String _roomKeys = '';
  static String _pushRules = '';
  static int? _owner;
  static bool _pushTap = false;

  /// Remote Config native_chat_enabled
  static final ValueNotifier<bool> remoteEnabled = ValueNotifier(true);
  static bool _started = false;

  static bool get compiled => ChatEngine.enabled && remoteEnabled.value;

  static final ValueNotifier<bool> keyValid = ValueNotifier(false);

  /// No live Torn tab for a while
  static final ValueNotifier<bool> tornTabMissing = ValueNotifier(false);
  static const int _tabGrace = 15;
  static const Duration _touchEvery = Duration(seconds: 15);
  static WebViewProvider? _tabs;
  static Timer? _tabTimer;
  static int _tabLostFor = 0;
  static DateTime _touchedAt = DateTime(0);
  static Future<void>? _opening;

  @visibleForTesting
  static bool Function(TabDetails) isLive = tabAlive;

  @visibleForTesting
  static Future<void> Function() sendTouch = _source.touch;

  /// Bubble, ticker, drawer logo and shortcuts
  static bool get usable => compiled && prefs.inAppEnabled && keyValid.value;

  static bool get listens => compiled && keyValid.value && (prefs.inAppEnabled || prefs.dmPush);

  /// Chat connection runs
  static bool get _shouldRun => listens && !controller.loggedOut;

  static bool get tickerOn =>
      prefs.ticker && usable && !screenOpen.value && quickWindows.value.isEmpty && !tornTabMissing.value;

  /// The open app alerts DMs itself
  static bool get coversDmPush =>
      compiled &&
      !tornTabMissing.value &&
      (prefs.inAppEnabled ? prefs.alertNotify : prefs.dmPush) &&
      controller.connection == ChatConnection.connected &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  static Future<void> start({NativeUserProvider? login}) async {
    ChatShareIn.start();
    if (!ChatEngine.enabled) return;
    _login ??= login;
    remoteEnabled.value = await Prefs().getNativeChatRemoteEnabled();
    if (!compiled) {
      _reportMode();
      return refreshShortcuts();
    }
    if (_started) return;
    _started = true;
    await prefs.load();
    prefs.unknownRoomSink = (id) {
      final room = id.replaceAll(RegExp('[0-9]+'), 'N');
      ChatTelemetry.event('chat_unknown_room', {'room_id': room.substring(0, math.min(room.length, 99))});
    };
    _owner = await Prefs().getNativeChatOwner();
    if (_owner! > 0) controller.restoreUserId(_owner!);
    prefs.addListener(_syncPush);
    prefs.addListener(_syncRun);
    prefs.addListener(_reportMode);
    _syncPush();
    controller.restorePaused();
    minimized.value = [
      for (final entry in prefs.windows) ChatMinimized(ChatWindowFrame.decode(entry).roomId, window: true),
    ];
    // Before the page sends its first rooms
    controller.alertStream.listen(_notify);
    controller.addListener(_askEmblem);
    controller.addListener(_watchWeb);
    controller.addListener(_watchTabs);
    controller.addListener(_watchSettings);
    controller.addListener(_watchOwner);
    controller.addListener(_watchRooms);
    controller.goneStream.listen(onRoomGone);
    ChatEngine.instance.data.where((m) => m['k'] == 'health').listen(ChatTelemetry.health);
    selectNotificationStream.stream.listen(_onNotificationTap);
    _factionOps.start();
    factionEvents.start();
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        controller.resumed();
        _reportMode();
        _checkTabs();
      },
      onPause: () {
        controller.paused();
        refreshShortcuts();
      },
    );
    _watchKey();
    _reportMode();
    _login?.addListener(_onLogin);
    refreshShortcuts();
    if (!_shouldRun) return;
    // After the drawer's first frame
    await WidgetsBinding.instance.endOfFrame;
    _syncRun();
  }

  static void _reportMode() => unawaited(ChatTelemetry.report(prefs, remote: remoteEnabled.value, loaded: _started));

  static void _watchKey() {
    if (!Get.isRegistered<UserController>()) return;
    final user = Get.find<UserController>();
    keyValid.value = user.isApiKeyValid;
    user.addListener(() => keyValid.value = user.isApiKeyValid);
    keyValid.addListener(_onKey);
  }

  static void _onKey() {
    if (!keyValid.value) {
      hideQuickWindows();
      closeLinkWindow();
    }
    _syncRun();
    refreshShortcuts();
  }

  // Every login and logout, never cold start
  static void _onLogin() {
    if (!_started) return;
    // By name, the enum moves between builds
    final none = _login?.playerLastLoginMethod.name == 'none';
    final had = _hadLogin;
    _hadLogin = !none;
    if (!none) {
      final id = _login?.playerId;
      final mine = controller.myUserId;
      controller.onLogin(accountChanged: id != null && mine != null && id != mine);
    } else if (logoutStops(controller, hadLogin: had)) {
      controller.onLogout();
    } else {
      return;
    }
    _syncRun();
  }

  /// Failed logins also say none
  @visibleForTesting
  static bool logoutStops(ChatController chat, {required bool hadLogin}) {
    if (chat.loggedOut || chat.needsLogin) return false;
    return hadLogin || chat.connection == ChatConnection.connected;
  }

  /// Starts or stops the chat engine
  static void _syncRun() {
    final engine = ChatEngine.instance;
    if (_shouldRun && !engine.active) {
      engine.start();
      controller.resetStall();
    } else if (!_shouldRun && engine.active) {
      engine.stop();
    }
    _checkTabs();
  }

  // Shortcuts follow the rooms Torn lists
  static void _watchRooms() {
    final keys = controller.rooms.map((r) => r.id).join(',');
    if (keys == _roomKeys) return;
    _roomKeys = keys;
    for (final id in {...minimized.value.map((m) => m.roomId), ...quickWindows.value}.where(controller.isUnlisted)) {
      closeQuickWindow(id);
      dropMinimized(id);
    }
    refreshShortcuts();
  }

  @visibleForTesting
  static void onRoomGone(ChatRoom room) {
    final open =
        quickWindows.value.contains(room.id) ||
        minimized.value.any((m) => m.roomId == room.id) ||
        controller.isOnScreen(room.id);
    closeQuickWindow(room.id);
    dropMinimized(room.id);
    if (open) chatToast('${room.name} chat closed: you left the ${room.id == 'poker' ? 'table' : 'room'}');
  }

  static void _watchSettings() {
    final context = navigatorKey?.currentContext;
    if (_settings != null || context == null) return;
    _settings = context.read<SettingsProvider>()..addListener(_syncBrowser);
    prefs.wordsSink = (words) => _settings!.changeHighlightWordList = words;
    _syncBrowser();
  }

  static void _syncBrowser() => prefs.syncBrowser(
    enabled: _settings!.highlightChat,
    words: _settings!.highlightWordList,
    color: _settings!.highlightColor,
  );

  // Browser Torn pages bring the session
  static void _watchWeb() {
    final context = navigatorKey?.currentContext;
    if (controller.needsLogin && _web == null && context != null) {
      _web = context.read<WebViewProvider>()..addListener(_onWeb);
      _webUrls = _tornUrls(_web!);
    } else if (!controller.needsLogin && _web != null) {
      _web!.removeListener(_onWeb);
      _web = null;
    }
  }

  static String _tornUrls(WebViewProvider web) =>
      web.tabList.map((t) => t.currentUrl ?? '').where((u) => u.contains('torn.com')).join(' ');

  static void _onWeb() {
    final web = _web;
    if (web == null) return;
    final urls = _tornUrls(web);
    if (urls == _webUrls) return;
    _webUrls = urls;
    if (!controller.loggedOut) return controller.retrySession();
    // Maybe a login in the browser
    controller.onLogin();
    _syncRun();
  }

  static void _watchTabs() {
    final context = navigatorKey?.currentContext;
    if (_tabs == null && context != null) watchTabs(context.read<WebViewProvider>());
  }

  @visibleForTesting
  static void watchTabs(WebViewProvider web) {
    _tabs?.removeListener(_checkTabs);
    _tabs = web..addListener(_checkTabs);
    _checkTabs();
  }

  @visibleForTesting
  static void resetTabs() {
    _tabs?.removeListener(_checkTabs);
    _tabs = null;
    _tabTimer?.cancel();
    _tabTimer = null;
    _tabLostFor = 0;
    tornTabMissing.value = false;
    _touchedAt = DateTime(0);
  }

  static void _checkTabs() {
    final web = _tabs;
    if (web == null) return;
    final state = WidgetsBinding.instance.lifecycleState;
    final away = state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (!_shouldRun || away) {
      _tabTimer?.cancel();
      _tabTimer = null;
      _tabLostFor = 0;
      if (!_shouldRun) tornTabMissing.value = false;
    } else if (tornTabOpen(web)) {
      _tabTimer?.cancel();
      _tabTimer = null;
      _tabLostFor = 0;
      tornTabMissing.value = false;
    } else if (_tabTimer == null) {
      _tabTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _tabLostFor++;
        _checkTabs();
      });
    } else if (_tabLostFor >= _tabGrace) {
      tornTabMissing.value = true;
    }
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

  /// Shown tabs only, both split sides
  static bool tornTabOpen(WebViewProvider web) {
    final shown = [
      web.visibleTabIndexForGroup(SplitGroup.main),
      if (web.splitBrowsersActive) web.visibleTabIndexForGroup(SplitGroup.apart),
    ];
    return shown.any(
      (i) => i != null && i < web.tabList.length && _isTorn(web.tabList[i].currentUrl) && isLive(web.tabList[i]),
    );
  }

  static void touch([DateTime? at]) {
    final now = at ?? DateTime.now();
    if (tornTabMissing.value || now.difference(_touchedAt) < _touchEvery) return;
    _touchedAt = now;
    unawaited(sendTouch());
  }

  static void _notify(ChatAlert alert) {
    final m = alert.message;
    final room = controller.roomById(m.roomId);
    // Chat off still alerts DMs
    final wanted = prefs.inAppEnabled ? prefs.alertNotify : prefs.dmPush && room.isDm;
    if (!wanted || prefs.isQuietAt(DateTime.now())) return;
    final foreground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (foreground && tornTabMissing.value) return;
    if (foreground && tickerOn && prefs.tickerShows(m.roomId, alert.match)) return;
    final title = room.isDm ? m.sender.name : '${m.sender.name} in ${room.name}';
    showNotification({
      'tornChat': true,
      'message': '${title.replaceAll(':', ' ')}: ${m.content}',
      'nativeChatTap': tapPayload(m.roomId),
      'chatTone': prefs.toneForAlert(alert).code,
    }, 677000 + m.roomId.hashCode.abs() % 1000);
  }

  // Letters only, payloads match by substring
  static String tapPayload(String roomId) =>
      _tapPrefix + roomId.codeUnits.expand((c) => [c >> 4, c & 15]).map((n) => String.fromCharCode(65 + n)).join();

  // Read fresh at tap time
  static Future<bool> tapsOpenChat() async =>
      ChatEngine.enabled && await Prefs().getNativeChatRemoteEnabled() && await Prefs().getNativeChatEnabled();

  static String dmTapPayload(int userId, [String? name]) {
    final room = ChatRoom.dmId(userId);
    if (name != null && name.isNotEmpty) controller.noteSender(room, name);
    _pushTap = true;
    return tapPayload(room);
  }

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

  static Future<void> _onNotificationTap(String? payload) async {
    final source = _pushTap ? 'push' : 'in_app_alert';
    _pushTap = false;
    if (!compiled) return;
    final reminder = ChatReminders.fromPayload(payload);
    final reminderNav = navigatorKey?.currentState;
    if (reminder != null && reminderNav != null) {
      hideQuickWindows();
      ChatTelemetry.event('chat_notification_open', {'source': 'reminder', 'target': 'inbox'});
      ChatTelemetry.count('open_notification');
      open(reminderNav, roomId: reminder.$1, messageId: reminder.$2);
      return;
    }
    final roomId = roomFromTap(payload);
    if (roomId == null || !await tapsOpenChat()) return;
    final navigator = navigatorKey?.currentState;
    final inbox = prefs.notificationTap == ChatNotificationTap.inbox && navigator != null;
    ChatTelemetry.event('chat_notification_open', {'source': source, 'target': inbox ? 'inbox' : 'window'});
    ChatTelemetry.count('open_notification');
    if (inbox) {
      hideQuickWindows();
      open(navigator, roomId: roomId);
    } else {
      openQuickWindow(roomId);
    }
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

  /// True once, for the window asked
  static bool takeComposerFocus(String roomId) {
    final mine = _focusRoom == roomId;
    if (mine) _focusRoom = null;
    return mine;
  }

  /// Over the cap, minimizes the back one
  static void openQuickWindow(String roomId, {bool reply = false}) {
    ChatTelemetry.count('open_window');
    unawaited(_backToTorn());
    _focusRoom = reply ? roomId : null;
    if (reply) composerFocus.value++;
    dropMinimized(roomId);
    final open = [...quickWindows.value.where((r) => r != roomId), roomId];
    while (open.length > _maxWindows) {
      _pushMinimized(ChatMinimized(open.removeAt(0), window: true));
    }
    quickWindows.value = open;
  }

  static void swapQuickWindow(String from, String to) {
    dropMinimized(to);
    quickWindows.value = [for (final r in quickWindows.value) r == from ? to : r];
  }

  static void focusQuickWindow(String roomId) {
    final open = quickWindows.value;
    if (!open.contains(roomId) || open.last == roomId) return;
    quickWindows.value = [...open.where((r) => r != roomId), roomId];
  }

  /// Without [roomId], all of them
  static void closeQuickWindow([String? roomId]) {
    quickWindows.value = roomId == null ? const [] : [...quickWindows.value.where((r) => r != roomId)];
  }

  /// Without [roomId], the front one
  static void minimizeQuickWindow([String? roomId]) {
    final room = roomId ?? quickWindows.value.lastOrNull;
    if (room == null || !quickWindows.value.contains(room)) return;
    _pushMinimized(ChatMinimized(room, window: true));
    closeQuickWindow(room);
  }

  static void hideQuickWindows() {
    if (quickWindows.value.isEmpty) return;
    for (final roomId in quickWindows.value) {
      _pushMinimized(ChatMinimized(roomId, window: true));
    }
    quickWindows.value = const [];
  }

  static void minimize(String roomId, {double offset = 0, String? frozenAtId}) {
    _leaveScreens();
    _pushMinimized(ChatMinimized(roomId, offset: offset, frozenAtId: frozenAtId));
  }

  static void _pushMinimized(ChatMinimized item) {
    final list = [...minimized.value.where((m) => m.roomId != item.roomId), item];
    minimized.value = list.sublist(math.max(0, list.length - _maxMinimized));
  }

  static void dropMinimized(String roomId) {
    if (!minimized.value.any((m) => m.roomId == roomId)) return;
    minimized.value = [...minimized.value.where((m) => m.roomId != roomId)];
  }

  static void popOut(String roomId) {
    _leaveScreens();
    openQuickWindow(roomId);
  }

  /// Without [item], the newest
  static void restore([ChatMinimized? item]) {
    final last = item ?? minimized.value.lastOrNull;
    final navigator = navigatorKey?.currentState;
    if (last == null) return;
    if (last.window) return openQuickWindow(last.roomId);
    if (navigator == null) return;
    _resume = last;
    open(navigator, roomId: last.roomId);
  }

  /// Once, for the page that reopens it
  static ChatMinimized? takeResume(String roomId) {
    final resume = _resume;
    _resume = null;
    return resume?.roomId == roomId ? resume : null;
  }

  static void _leaveScreens() {
    final navigator = navigatorKey?.currentState;
    final screens = _screens;
    if (navigator == null || screens == null || !screens.isActive) return;
    navigator.popUntil((route) => route == screens);
    navigator.pop();
  }

  static void expandQuickWindow([String? roomId]) {
    final room = roomId ?? quickWindows.value.lastOrNull;
    final navigator = navigatorKey?.currentState;
    if (room == null) return;
    closeQuickWindow(room);
    if (navigator != null) open(navigator, roomId: room);
  }

  static void _syncPush() {
    if (!compiled) return;
    final rules = ChatPushRules.of(prefs).encode();
    if (rules == _pushRules) return;
    _pushRules = rules;
    BackgroundPrefs().setChatPushRules(rules);
  }

  static void _watchOwner() {
    final id = controller.myUserId;
    final owner = _owner;
    if (id == null || owner == null || id == owner) return;
    _owner = id;
    Prefs().setNativeChatOwner(id);
    if (owner != 0) _wipeAccount();
  }

  /// Next account starts clean
  static void forgetAccount() {
    if (!compiled) return;
    _owner = 0;
    Prefs().setNativeChatOwner(0);
    _wipeAccount();
    // A stopped page ignores the reconnect
    controller.forgetAccount();
  }

  static void _wipeAccount() {
    prefs.forgetAccount();
    quickWindows.value = const [];
    minimized.value = const [];
    refreshShortcuts();
    cancelChatNotifications();
  }

  @visibleForTesting
  static Future<String?> Function() fetchEmblem = () async => (await ApiCallsV2.getOwnFactionBasic_v2())?.tagImage;

  static void _askEmblem() {
    if (usable) askEmblem(controller, DateTime.now());
  }

  /// Five tries a session, foreground only
  @visibleForTesting
  static void askEmblem(ChatController chat, DateTime now) {
    if (chat.myUserId != _emblemFor) {
      _emblemFor = chat.myUserId;
      _emblemDone = false;
      _emblemNext = DateTime(0);
      _emblemTries = 0;
    }
    if (_emblemDone || _emblemTries >= 5 || now.isBefore(_emblemNext)) return;
    if (!chat.ready || !chat.rooms.any((r) => r.id == 'faction')) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) return;
    // API key may still be loading
    _emblemNext = now.add(Duration(seconds: 15 << _emblemTries++));
    fetchEmblem().then((image) {
      if (image == null) return;
      _emblemDone = true;
      if (image.isEmpty) return;
      chat.setEmblem('faction', image.startsWith('http') ? image : 'https://factiontags.torn.com/$image');
    });
  }

  /// By the preview setting unless [always]
  static Future<void> openLink(String url, {bool always = false, String? fill}) async {
    if (!always && !prefs.linkWindow) return openUrl(url, newTab: prefs.linkNewTab);
    FocusManager.instance.primaryFocus?.unfocus();
    linkWindow.value = (url: url, tap: ++_linkTaps, fill: fill);
  }

  static void closeLinkWindow() => linkWindow.value = null;

  static Future<void> openUrl(
    String url, {
    BrowserTapType tap = BrowserTapType.short,
    bool newTab = false,
    bool app = false,
  }) async {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;
    closeLinkWindow();
    // Back to this conversation, not the list
    final page = screenOpen.value ? shownPages.lastOrNull?.call() : null;
    if (page != null) _pushMinimized(page);
    hideQuickWindows();
    navigator.popUntil((route) => route.isFirst);
    await _inBrowser(navigator.context, url, tap, newTab, app: app);
  }

  static Future<void> _inBrowser(
    BuildContext context,
    String url,
    BrowserTapType tap,
    bool newTab, {
    bool app = false,
  }) async {
    final web = context.read<WebViewProvider>();
    if (newTab && (app || await Prefs().getDefaultBrowser() == 'app')) {
      final cold = web.tabList.isEmpty;
      web.browserShowInForeground = true;
      // A cold browser restores its tabs first
      for (var i = 0, still = 0, count = -1; cold && i < 80 && still < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        still = web.tabList.isNotEmpty && web.tabList.length == count ? still + 1 : 0;
        count = web.tabList.length;
      }
      if (web.tabList.isNotEmpty) {
        await web.addTab(url: url, splitApart: web.splitBrowsersActive && web.focusedGroup == SplitGroup.apart);
        web.activateTab(web.tabList.length - 1);
        return;
      }
    }
    if (!context.mounted) return;
    await web.openBrowserPreference(context: context, url: url, browserTapType: tap, focusedPanel: true, forceApp: app);
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

  static Future<void> openTornBrowser({bool keepChat = false}) async {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;
    final web = navigator.context.read<WebViewProvider>();
    final index = tornTabIndex(
      [for (final tab in web.tabList) tab.currentUrl],
      [web.currentTab, ...web.tabIndexesForGroup(web.focusedGroup), for (var i = 0; i < web.tabList.length; i++) i],
      live: (i) => isLive(web.tabList[i]),
    );
    if (index == null) {
      const home = 'https://www.torn.com';
      keepChat
          ? await _inBrowser(navigator.context, home, BrowserTapType.short, true, app: true)
          : await openUrl(home, newTab: true, app: true);
      return;
    }
    if (!keepChat) {
      hideQuickWindows();
      navigator.popUntil((route) => route.isFirst);
    }
    if (index != web.currentTab) {
      web.activateTab(index);
    } else if (!isLive(web.tabList[index])) {
      web.wakeTab(index);
    }
    web.browserShowInForeground = true;
  }

  static Future<void> _backToTorn() async {
    if (!tornTabMissing.value || _opening != null) return;
    final hasTorn = _tabs?.tabList.any((t) => _isTorn(t.currentUrl)) ?? false;
    _opening = openTornBrowser(keepChat: true).whenComplete(() => _opening = null);
    chatToast(hasTorn ? 'Switched to your Torn tab for chat' : 'Opened Torn for chat');
    // Android loads a page once it shows
    for (var i = 0; i < 20 && _tabs != null && !tornTabOpen(_tabs!); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    _checkTabs();
  }

  static bool _isTorn(String? url) {
    final host = Uri.tryParse(url ?? '')?.host ?? '';
    return host == 'torn.com' || host.endsWith('.torn.com');
  }

  /// Live ones first
  static int? tornTabIndex(List<String?> urls, Iterable<int> order, {bool Function(int)? live}) {
    final torn = [
      for (final i in order)
        if (i >= 0 && i < urls.length && _isTorn(urls[i])) i,
    ];
    return torn.where((i) => live?.call(i) ?? true).firstOrNull ?? torn.firstOrNull;
  }

  /// Where Torn Authentication lives
  static void openSettings() => _openPage(settingsPayload);

  static void openAlerts() => _openPage(alertsPayload);

  static void _openPage(String payload) {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;
    hideQuickWindows();
    navigator.popUntil((route) => route.isFirst);
    selectNotificationStream.add(payload);
  }

  static Future<void> openDm(ChatUser user) async {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) return;
    hideQuickWindows();
    controller.addDraftDm(user);
    await open(navigator, roomId: ChatRoom.dmId(user.id));
  }

  static const String shortcutPrefix = 'chat:';

  /// Last published, so a relaunch keeps them
  static List<ShortcutItem> _chatShortcuts() => [
    if (usable && prefs.shortcuts)
      for (final entry in prefs.shortcutCache)
        ShortcutItem(
          type: shortcutPrefix + entry.substring(0, entry.indexOf('|')),
          localizedTitle: entry.substring(entry.indexOf('|') + 1),
          icon: 'action_torn',
        ),
  ];

  // PDA first, chats fill the rest
  static Future<void> refreshShortcuts() async {
    if (!ChatEngine.enabled) return;
    try {
      final known = {for (final r in controller.conversations) r.id: r.name};
      final cached = {
        for (final e in prefs.shortcutCache) e.substring(0, e.indexOf('|')): e.substring(e.indexOf('|') + 1),
      };
      final entries = <String>[];
      if (compiled && prefs.shortcuts && prefs.inAppEnabled) {
        for (final id in ChatShortcuts.top(prefs.opens, DateTime.now())) {
          final title = known[id] ?? (controller.isUnlisted(id) ? null : cached[id]);
          if (title != null && title.isNotEmpty && !prefs.hiddenRooms.contains(id)) entries.add('$id|$title');
        }
      }
      if (compiled) prefs.setShortcutCache(entries);
      final room = (Platform.isIOS ? 4 : 5) - pdaShortcutItems.length;
      await const QuickActions().setShortcutItems([...pdaShortcutItems, ..._chatShortcuts().take(math.max(0, room))]);
    } catch (_) {}
  }

  static void setShortcuts(bool value) {
    prefs.setShortcuts(value);
    refreshShortcuts();
  }

  static void setEnabled(bool value) {
    // Back to the default safe spot
    if (value && !prefs.inAppEnabled) prefs.setBubbleSpot(const []);
    prefs.setInAppEnabled(value);
    _syncRun();
  }

  // Off hides the chat entirely
  static Future<void> setRemoteEnabled(bool value) async {
    if (value == remoteEnabled.value) return;
    remoteEnabled.value = value;
    await Prefs().setNativeChatRemoteEnabled(value);
    if (!ChatEngine.enabled) return;
    if (value && !_started) return start();
    _pushRules = '';
    if (value) {
      _syncPush();
      _factionOps.start();
      factionEvents.start();
      _syncRun();
    } else {
      BackgroundPrefs().setChatPushRules('');
      _syncRun();
      _factionOps.stop();
      factionEvents.stop();
      closeLinkWindow();
      _leaveScreens();
    }
    _reportMode();
    refreshShortcuts();
  }

  /// Remote Config native_chat_reply_enabled
  static Future<void> setReplyEnabled(bool value) async {
    if (value == await Prefs().getNativeChatReplyEnabled()) return;
    await Prefs().setNativeChatReplyEnabled(value);
    if (Platform.isIOS) await registerTornChatCategories(reply: value);
  }

  static Future<void> open(NavigatorState navigator, {String? roomId, String? messageId}) async {
    if (!compiled) return;
    if (screenOpen.value) {
      if (roomId == null || controller.isOnScreen(roomId)) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ChatController>.value(
            value: controller,
            child: ChatTheme(
              child: ChatConversationPage(roomId: roomId, focusMessageId: messageId),
            ),
          ),
        ),
      );
      controller.closeConversation(roomId);
      return;
    }
    if (_opening != null) return;
    await _backToTorn();
    if (!prefs.inAppEnabled) setEnabled(true);
    minimized.value = [...minimized.value.where((m) => m.window && m.roomId != roomId)];
    screenOpen.value = true;
    final route = MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<ChatController>.value(
        value: controller,
        child: ChatTheme(
          child: ChatPage(initialRoomId: roomId, initialMessageId: messageId),
        ),
      ),
    );
    _screens = route;
    await navigator.push(route);
    if (_screens == route) _screens = null;
    screenOpen.value = false;
  }
}
