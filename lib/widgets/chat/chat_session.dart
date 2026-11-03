import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart' show selectNotificationStream;
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_inbox_snapshot.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_reminder.dart';
import 'package:torn_pda/models/chat/chat_short_text.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_image_store.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_push_rules.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/torn-pda-native/chat/chat_engine.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/app_icon_menu.dart';
import 'package:torn_pda/utils/app_lifecycle.dart';
import 'package:torn_pda/utils/background_prefs.dart';
import 'package:torn_pda/utils/chat_notifications.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_torn_tab.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_windows.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Chat start-up and account state
class ChatSession {
  /// Remote Config native_chat_enabled
  final ValueNotifier<bool> remoteEnabled = ValueNotifier(true);

  final ValueNotifier<bool> keyValid = ValueNotifier(false);

  @visibleForTesting
  bool? engineOverride;

  @visibleForTesting
  Future<String?> Function() fetchEmblem = () async => (await ApiCallsV2.getOwnFactionBasic_v2())?.tagImage;

  bool _started = false;
  AppLifecycleListener? _lifecycle;
  NativeUserProvider? _login;
  bool _hadLogin = false;
  WebViewProvider? _web;
  String _webUrls = '';
  SettingsProvider? _settings;
  String _roomKeys = '';
  String _pushRules = '';
  int? _owner;
  bool _pushTap = false;
  bool _emblemDone = false;
  DateTime _emblemNext = DateTime(0);
  int _emblemTries = 0;
  int? _emblemFor;

  ChatController get _chat => NativeChat.controller;
  ChatPrefs get _prefs => NativeChat.prefs;
  ChatWindows get _windows => NativeChat.windows;
  ChatTornTab get _tornTab => NativeChat.tornTab;

  bool get engineEnabled => engineOverride ?? ChatEngine.enabled;

  bool get compiled => engineEnabled && remoteEnabled.value;

  /// Bubble, ticker, drawer logo and shortcuts
  bool get usable => compiled && _prefs.inAppEnabled && keyValid.value;

  bool get listens => compiled && keyValid.value && (_prefs.inAppEnabled || _prefs.dmPush);

  /// Chat connection runs
  bool get shouldRun => listens && !_chat.loggedOut;

  Future<void> _publishAppIconMenu() => Get.find<AppIconMenuController>().publish();

  Future<void> start({NativeUserProvider? login}) async {
    ChatShareIn.start();
    if (!engineEnabled) return;
    _login ??= login;
    remoteEnabled.value = await Prefs().getNativeChatRemoteEnabled();
    if (!compiled) {
      _reportMode();
      return _publishAppIconMenu();
    }
    if (_started) return;
    _started = true;
    await _prefs.load();
    _prefs.unknownRoomSink = StatsController.chat.unknownRoom;
    _owner = await Prefs().getNativeChatOwner();
    if (_owner! > 0) _chat.restoreUserId(_owner!);
    final saved = ChatInboxSnapshot.decode(await Prefs().getNativeChatInbox(), _owner!);
    _chat.restoreInbox(saved);
    unawaited(_warmImages(saved));
    _chat.onInboxChanged = Prefs().setNativeChatInbox;
    _prefs.addListener(_syncPush);
    _prefs.addListener(_syncRun);
    _prefs.addListener(_reportMode);
    _syncPush();
    _chat.restorePaused();
    _windows.restoreWindows();
    // Before the page sends its first rooms
    _chat.alertStream.listen(_notify);
    _chat.addListener(_askEmblem);
    _chat.addListener(_watchWeb);
    _chat.addListener(_tornTab.watchIfReady);
    _chat.addListener(_watchSettings);
    _chat.addListener(_watchOwner);
    _chat.addListener(_watchRooms);
    _chat.goneStream.listen(onRoomGone);
    ChatEngine.instance.data.where((m) => m['k'] == 'health').listen(StatsController.chat.health);
    selectNotificationStream.stream.listen(_onNotificationTap);
    NativeChat.factionOps.start();
    NativeChat.factionEvents.start();
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        _chat.resumed();
        _reportMode();
        _tornTab.check();
        _tornTab.syncFreeze();
      },
      onPause: () {
        _chat.paused();
        _publishAppIconMenu();
        _tornTab.syncFreeze();
      },
    );
    _watchKey();
    _login?.addListener(_onLogin);
    await _publishAppIconMenu();
    _reportMode();
    if (!shouldRun) return;
    // After the drawer's first frame
    await WidgetsBinding.instance.endOfFrame;
    _syncRun();
  }

  void _reportMode() => unawaited(
    StatsController.chat.report(
      _prefs,
      remote: remoteEnabled.value,
      loaded: _started,
      hideWeb: _tornTab.web?.chatRemovalActiveGlobal ?? false,
    ),
  );

  void _watchKey() {
    if (!Get.isRegistered<UserController>()) return;
    final user = Get.find<UserController>();
    keyValid.value = user.isApiKeyValid;
    user.addListener(() => keyValid.value = user.isApiKeyValid);
    keyValid.addListener(_onKey);
  }

  void _onKey() {
    if (!keyValid.value) {
      _windows.hideQuickWindows();
      _windows.closeLinkWindow();
    }
    _syncRun();
    _publishAppIconMenu();
  }

  // Every login and logout, never cold start
  void _onLogin() {
    if (!_started) return;
    // By name, the enum moves between builds
    final none = _login?.playerLastLoginMethod.name == 'none';
    final had = _hadLogin;
    _hadLogin = !none;
    if (!none) {
      final id = _login?.playerId;
      final mine = _chat.myUserId;
      final changed = id != null && mine != null && id != mine;
      if (changed) {
        NativeChat.factionOps.dropJoin();
        _prefs.setTestFactionRoom(null);
      }
      _chat.onLogin(accountChanged: changed);
    } else if (logoutStops(_chat, hadLogin: had)) {
      _chat.onLogout();
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
  void _syncRun() {
    final engine = ChatEngine.instance;
    if (shouldRun && !engine.active) {
      engine.start();
      _chat.resetStall();
    } else if (!shouldRun && engine.active) {
      engine.stop();
    }
    _tornTab.check();
  }

  // Shortcuts follow the rooms Torn lists
  void _watchRooms() {
    final keys = _chat.rooms.map((r) => r.id).join(',');
    if (keys == _roomKeys) return;
    _roomKeys = keys;
    final windows = _windows;
    for (final id in {
      ...windows.minimized.value.map((m) => m.roomId),
      ...windows.quickWindows.value,
    }.where(_chat.isUnlisted)) {
      windows.closeQuickWindow(id);
      windows.dropMinimized(id);
    }
    if (windows.bigWindow.value?.roomId case final id? when _chat.isUnlisted(id)) windows.setBigWindowRoom(null);
    _publishAppIconMenu();
  }

  @visibleForTesting
  void onRoomGone(ChatRoom room) {
    final windows = _windows;
    final open =
        windows.quickWindows.value.contains(room.id) ||
        windows.bigWindow.value?.roomId == room.id ||
        windows.minimized.value.any((m) => m.roomId == room.id) ||
        _chat.isOnScreen(room.id);
    windows.closeQuickWindow(room.id);
    windows.dropMinimized(room.id);
    if (windows.bigWindow.value?.roomId == room.id) windows.setBigWindowRoom(null);
    if (open) chatToast('${room.name} chat closed: you left the ${room.id == 'poker' ? 'table' : 'room'}');
  }

  void _watchSettings() {
    final context = NativeChat.navigatorKey?.currentContext;
    if (_settings != null || context == null) return;
    _settings = context.read<SettingsProvider>()..addListener(_syncBrowser);
    _prefs.wordsSink = (words) => _settings!.changeHighlightWordList = words;
    _syncBrowser();
  }

  void _syncBrowser() => _prefs.syncBrowser(
    enabled: _settings!.highlightChat,
    words: _settings!.highlightWordList,
    color: _settings!.highlightColor,
  );

  // Browser Torn pages bring the session
  void _watchWeb() {
    final context = NativeChat.navigatorKey?.currentContext;
    if (_chat.needsLogin && _web == null && context != null) {
      _web = context.read<WebViewProvider>()..addListener(_onWeb);
      _webUrls = _tornUrls(_web!);
    } else if (!_chat.needsLogin && _web != null) {
      _web!.removeListener(_onWeb);
      _web = null;
    }
  }

  String _tornUrls(WebViewProvider web) =>
      web.tabList.map((t) => t.currentUrl ?? '').where((u) => u.contains('torn.com')).join(' ');

  void _onWeb() {
    final web = _web;
    if (web == null) return;
    final urls = _tornUrls(web);
    if (urls == _webUrls) return;
    _webUrls = urls;
    if (!_chat.loggedOut) return _chat.retrySession();
    // Maybe a login in the browser
    _chat.onLogin();
    _syncRun();
  }

  void _notify(ChatAlert alert) {
    final m = alert.message;
    final room = _chat.roomById(m.roomId);
    // Chat off still alerts DMs
    final wanted = _prefs.inAppEnabled ? _prefs.alertNotify : _prefs.dmPush && room.isDm;
    if (!wanted || _prefs.isQuietAt(DateTime.now())) return;
    final foreground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (foreground && NativeChat.tornTabMissing.value) return;
    if (foreground && NativeChat.tickerOn && _prefs.tickerShows(m.roomId, alert.match)) return;
    final title = room.isDm ? m.sender.name : '${m.sender.name} in ${room.name}';
    showNotification({
      'tornChat': true,
      'message': '${title.replaceAll(':', ' ')}: ${chatShortText(m.content, m.createdAt, clock: chatAppClock().clock)}',
      'nativeChatTap': NativeChat.tapPayload(m.roomId),
      'chatTone': _prefs.toneForAlert(alert).code,
    }, chatAlertId(m.roomId));
  }

  String dmTapPayload(int userId, [String? name]) {
    final room = ChatRoom.dmId(userId);
    if (name != null && name.isNotEmpty) _chat.noteSender(room, name);
    _pushTap = true;
    return NativeChat.tapPayload(room);
  }

  Future<void> _onNotificationTap(String? payload) async {
    final source = _pushTap ? 'push' : 'in_app_alert';
    _pushTap = false;
    if (!compiled) return;
    final reminder = ChatReminders.fromPayload(payload);
    final reminderNav = NativeChat.navigatorKey?.currentState;
    if (reminder != null && reminderNav != null) {
      _windows.hideQuickWindows();
      StatsController.chat.notificationOpen('reminder', 'inbox');
      StatsController.chat.count('open_notification');
      _windows.open(reminderNav, roomId: reminder.$1, messageId: reminder.$2);
      return;
    }
    final roomId = NativeChat.roomFromTap(payload);
    if (roomId == null || !await NativeChat.tapsOpenChat()) return;
    final navigator = NativeChat.navigatorKey?.currentState;
    final inbox = _prefs.notificationTap == ChatNotificationTap.inbox && navigator != null;
    StatsController.chat.notificationOpen(source, inbox ? 'inbox' : 'window');
    StatsController.chat.count('open_notification');
    if (inbox) {
      _windows.hideQuickWindows();
      _windows.open(navigator, roomId: roomId);
    } else {
      _windows.openQuickWindow(roomId);
    }
  }

  void _syncPush() {
    if (!compiled) return;
    final rules = ChatPushRules.of(_prefs).encode();
    if (rules == _pushRules) return;
    _pushRules = rules;
    BackgroundPrefs().setChatPushRules(rules);
  }

  void _watchOwner() {
    final id = _chat.myUserId;
    final owner = _owner;
    if (id == null || owner == null || id == owner) return;
    _owner = id;
    Prefs().setNativeChatOwner(id);
    if (owner != 0) _wipeAccount();
  }

  /// Next account starts clean
  void forgetAccount() {
    Prefs().setNativeChatInbox('');
    if (!compiled) return;
    _owner = 0;
    Prefs().setNativeChatOwner(0);
    _forgetEmblem();
    _wipeAccount();
    // A stopped page ignores the reconnect
    _chat.forgetAccount();
  }

  void _wipeAccount() {
    unawaited(ChatImageStore.instance.clear());
    ChatImages.forget();
    _windows.dropReopen();
    _prefs.forgetAccount();
    _windows.forget();
    _chat.backTo = null;
    ChatFactionRoster.shared.clear();
    NativeChat.factionOps.forget();
    ChatLinkPreviews.forget();
    NativeChat.translator.forget();
    _chat.sharePending.value = null;
    _publishAppIconMenu();
    cancelChatNotifications();
  }

  void _forgetEmblem() {
    _emblemFor = null;
    _emblemDone = false;
    _emblemNext = DateTime(0);
    _emblemTries = 0;
  }

  void _askEmblem() {
    if (usable) askEmblem(_chat, DateTime.now());
  }

  /// Five tries a session, foreground only
  @visibleForTesting
  void askEmblem(ChatController chat, DateTime now) {
    if (chat.myUserId != _emblemFor) {
      _emblemFor = chat.myUserId;
      _emblemDone = false;
      _emblemNext = DateTime(0);
      _emblemTries = 0;
    }
    if (_emblemDone || _emblemTries >= 5 || now.isBefore(_emblemNext)) return;
    if (!chat.ready || !chat.rooms.any((r) => r.id == 'faction')) return;
    if (appInBackground()) return;
    // API key may still be loading
    _emblemNext = now.add(Duration(seconds: 15 << _emblemTries++));
    fetchEmblem().then((image) {
      if (image == null) return;
      _emblemDone = true;
      final url = image.startsWith('http') ? image : 'https://factiontags.torn.com/$image';
      chat.setEmblem('faction', image.isEmpty ? null : url);
    });
  }

  Future<void> _warmImages(ChatInboxSnapshot? saved) async {
    try {
      final store = ChatImageStore.instance;
      final urls = [
        if (saved != null) ...[
          for (final r in saved.rooms) ?r.emblemUrl,
          for (final r in saved.rooms) ?r.peer?.avatarUrl,
        ],
        ...await store.recent(),
      ];
      await store.warm(urls.take(48));
    } catch (_) {}
  }

  void setEnabled(bool value) {
    // Back to the default safe spot
    if (value && !_prefs.inAppEnabled) _prefs.setBubbleSpot(const []);
    _prefs.setInAppEnabled(value);
    _syncRun();
    _publishAppIconMenu();
  }

  // Off hides the chat entirely
  Future<void> setRemoteEnabled(bool value) async {
    if (value == remoteEnabled.value) return;
    remoteEnabled.value = value;
    await Prefs().setNativeChatRemoteEnabled(value);
    if (!engineEnabled) return;
    if (value && !_started) return start();
    _pushRules = '';
    if (value) {
      _syncPush();
      NativeChat.factionOps.start();
      NativeChat.factionEvents.start();
      _syncRun();
    } else {
      BackgroundPrefs().setChatPushRules('');
      _syncRun();
      NativeChat.factionOps.stop();
      NativeChat.factionEvents.stop();
      _windows.closeLinkWindow();
      _windows.leaveScreens();
    }
    _reportMode();
    _publishAppIconMenu();
  }
}
