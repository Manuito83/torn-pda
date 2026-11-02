import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ColorScheme;
import 'package:flutter/widgets.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_away.dart';
import 'package:torn_pda/models/chat/chat_banking.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_inbox_snapshot.dart';
import 'package:torn_pda/models/chat/chat_item_price.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/models/chat/chat_source.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_typing_report.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/app_lifecycle.dart';
import 'package:uuid/uuid.dart';

typedef ChatHeldToast = ({String text, String action, VoidCallback? onAction, VoidCallback? onClose});

class ChatController extends ChangeNotifier {
  ChatController(this._source, [ChatPrefs? prefs, this._api]) : _prefs = prefs ?? ChatPrefs() {
    _subscription = _source.events.listen(_onEvent, onError: (Object _) {});
    _prefs.addListener(_onPrefs);
  }

  static const int _maxMessagesPerRoom = 1000;
  static const int _maxAlerts = 100;
  static const int _maxDeferred = 3000;
  static const Duration _sendTimeout = Duration(seconds: 30);
  static const Duration _stallAfter = Duration(seconds: 30);
  static const Duration _sessionRetryGap = Duration(seconds: 10);
  static const Duration _startGrace = Duration(seconds: 25);
  static const Duration _countsWait = Duration(seconds: 20);
  static const Duration _openTimeout = Duration(seconds: 20);
  static const Duration _settleGrace = Duration(milliseconds: 600);
  static const Duration _settleCap = Duration(seconds: 8);
  static const Duration _peekCap = Duration(seconds: 3);
  static const Duration _saveDelay = Duration(seconds: 30);
  static const List<Duration> _unreadRetries = [Duration(seconds: 5), Duration(seconds: 15)];
  static const List<ChatRoom> _defaultRooms = [
    ChatRoom(id: 'faction', name: 'Faction'),
    ChatRoom(id: 'company', name: 'Company'),
    ChatRoom(id: 'global', name: 'Global', reportTyping: false),
    ChatRoom(id: 'trade', name: 'Trade', reportTyping: false),
  ];
  // Torn never marks these as read
  static const Set<String> _neverRead = {'global', 'trade', 'poker'};

  final ChatSource _source;
  final ChatPrefs _prefs;
  final ChatApi? _api;
  late final StreamSubscription<ChatEvent> _subscription;

  bool get available => _source.available;

  ChatConnection _connection = ChatConnection.starting;
  ChatConnection get connection => _connection;

  bool get needsLogin =>
      _connection == ChatConnection.noSession ||
      _connection == ChatConnection.needsBrowser ||
      _connection == ChatConnection.twoFactor;

  static bool _outage(ChatConnection state) =>
      state == ChatConnection.offline || state == ChatConnection.tornDown || state == ChatConnection.slowLoad;

  /// Anything keeping the chat from a session
  bool get sessionIssue => needsLogin || (!_ready && _outage(_connection));

  Timer? _graceTimer;
  ChatConnection? _held;

  Timer? _stallTimer;
  bool _stalled = false;

  /// Not connected for a while, or failed
  bool get stalled => _stalled || _loggedOut || _connection == ChatConnection.error;

  /// Never got a session, stop spinning
  bool get unreachable => !_ready && (_stalled || _connection == ChatConnection.error);

  bool _loggedOut = false;

  /// Logged out of Torn, until a login
  bool get loggedOut => _loggedOut;

  Timer? _sessionRetry;
  DateTime _sessionRetryAt = DateTime(0);

  bool _ready = false;
  bool get ready => _ready;

  /// Session still unknown
  bool get starting =>
      available && !_ready && (_connection == ChatConnection.starting || _connection == ChatConnection.connecting);

  bool _unreadKnown = false;
  bool _countsLate = false;
  Timer? _countsTimer;
  Timer? _unreadRetry;
  int _unreadFailures = 0;

  /// Bubble waits for the session and counts
  bool get loadingCounts =>
      starting || (available && _connection == ChatConnection.connected && !(_ready && (_unreadKnown || _countsLate)));

  int? _myUserId;
  int? _savedUserId;
  int? get myUserId => _myUserId ?? _savedUserId;

  /// Account from an earlier session
  void restoreUserId(int id) => _savedUserId = id;

  String? _myName;
  String? get myName => _myName;

  ChatAlertMatcher? _matcher;
  final Map<String, ChatMatch?> _matches = {};
  List<String>? _paused;

  final List<ChatAlert> _alerts = [];
  List<ChatAlert> get alerts => _alerts;
  int get unseenAlerts => _alerts.where((a) => !a.seen).length;
  bool hasUnseenAlert(String roomId) => _alerts.any((a) => !a.seen && a.message.roomId == roomId);

  final StreamController<ChatAlert> _alertStream = StreamController.broadcast();

  Stream<ChatAlert> get alertStream => _alertStream.stream;

  final StreamController<ChatAlert> _incomingStream = StreamController.broadcast();

  Stream<ChatAlert> get incomingStream => _incomingStream.stream;

  final StreamController<ChatRoom> _goneStream = StreamController.broadcast();

  /// Room Torn dropped from its list
  Stream<ChatRoom> get goneStream => _goneStream.stream;

  /// Ids in Torn's last list
  Set<String> _listed = {};

  /// Torn listed rooms but not this one
  bool isUnlisted(String roomId) => _listed.isNotEmpty && !roomId.startsWith('dm:') && !_listed.contains(roomId);

  List<ChatRoom> _rooms = _defaultRooms;
  List<ChatRoom> get rooms => _rooms;

  final Map<String, String> _emblems = {};

  void setEmblem(String roomId, String? url) {
    if (_emblems[roomId] == url) return;
    if (url == null) {
      _emblems.remove(roomId);
    } else {
      _emblems[roomId] = url;
    }
    _rooms = [for (final r in _rooms) r.id == roomId ? r.withEmblem(url) : r];
    notifyListeners();
    _scheduleSave();
  }

  // Panels open in Torn
  List<ChatRoom> _dms = const [];
  bool _dmsLoaded = false;
  bool get dmsLoaded => _dmsLoaded;
  bool isDmOpen(String roomId) => _dms.any((d) => d.id == roomId);

  List<ChatRoom> _recent = const [];
  int _recentOffset = 0;
  bool _recentHasMore = false;
  bool get recentHasMore => _recentHasMore;
  bool _loadingRecent = false;
  bool get loadingRecent => _loadingRecent;

  // Opened from search, not listed yet
  ChatRoom? _draftDm;

  // Last one on top
  final List<String> _onScreen = [];
  String? get currentRoomId => _onScreen.lastOrNull;
  bool isOnScreen(String roomId) => _onScreen.contains(roomId);

  /// Room the launcher reopens after leaving
  String? backTo;

  bool unreadOnly = false;
  bool waitingExpanded = false;

  /// Last item from the price tool
  ChatItemPrice? lastItem;

  /// Share waiting for its room's composer
  final sharePending = ValueNotifier<({String roomId, ChatShared shared, DateTime at})?>(null);

  /// Toast held on the overlay for readers
  final heldToast = ValueNotifier<ChatHeldToast?>(null);

  static const int _maxMessageParts = 400;
  final Map<Object, List<(Object, int)>> _messageParts = {};

  List<(Object, int)> messageParts(Object key, List<(Object, int)> Function() split) {
    final parts = _messageParts.remove(key) ?? List<(Object, int)>.unmodifiable(split());
    _messageParts[key] = parts;
    if (_messageParts.length > _maxMessageParts) _messageParts.remove(_messageParts.keys.first);
    return parts;
  }

  static const int _maxUserSchemes = 200;
  final Map<(int, Brightness), ColorScheme> _userSchemes = {};

  ColorScheme userSchemeFor(int userId, Brightness brightness) {
    final key = (userId, brightness);
    final scheme =
        _userSchemes.remove(key) ??
        ColorScheme.fromSeed(
          seedColor: HSVColor.fromAHSV(1, (userId * 47) % 360, 0.6, 0.8).toColor(),
          brightness: brightness,
        );
    _userSchemes[key] = scheme;
    if (_userSchemes.length > _maxUserSchemes) _userSchemes.remove(_userSchemes.keys.first);
    return scheme;
  }

  final Map<String, List<ChatMessage>> _messages = {};
  List<ChatMessage> messagesFor(String roomId) => _messages[roomId] ?? const [];

  List<ChatMessage>? _bankFor;
  Map<String, ChatBankEntry> _bank = const {};

  /// Requests by message id, oldest messages first
  Map<String, ChatBankEntry> bankStates(String roomId) {
    final messages = messagesFor(roomId);
    if (identical(messages, _bankFor)) return _bank;
    _bank = chatBankDerive(messages);
    _bankFor = messages;
    return _bank;
  }

  final Map<int, ChatPresence> _presence = {};
  final Map<int, ChatLastAction> _lastAction = {};
  ChatPresence? presenceOf(int? userId) => _presence[userId] ?? _lastAction[userId]?.presence;
  DateTime? lastSeenOf(int? userId) => _lastAction[userId]?.at;

  final Map<String, List<ChatUser>> _roster = {};
  int _presenceRevision = 0;
  int get presenceRevision => _presenceRevision;

  List<ChatUser> rosterOf(String roomId) => _roster[roomId] ?? const [];

  static const Duration _friendsCache = Duration(seconds: 25);
  List<ChatUser>? _friends;
  List<ChatUser>? get friends => _friends;
  bool _friendsFailed = false;
  bool get friendsFailed => _friendsFailed;
  bool _askingFriends = false;
  bool get loadingFriends => _askingFriends;
  DateTime _friendsAt = DateTime(0);

  Map<int, ChatUser> _blocked = {};

  /// Blocked in Torn, not ignored in PDA
  List<ChatUser> get blockedUsers => _blocked.values.toList();

  bool isBlocked(int userId) => _blocked.containsKey(userId);

  bool isHidden(ChatUser user) =>
      user.id > 0 && user.id != myUserId && (_blocked.containsKey(user.id) || _prefs.isIgnored(user.id));

  /// False when Torn refuses, nothing changes then
  Future<bool> setBlocked(ChatUser user, bool blocked) async {
    _markBlocked(user, blocked);
    final ok = blocked ? await _source.block(user.id) : await _source.unblock(user.id);
    if (!ok) _markBlocked(user, !blocked);
    return ok;
  }

  void _markBlocked(ChatUser user, bool blocked) {
    final dm = ChatRoom.dmId(user.id);
    final others = roomById(dm).blockers.where((b) => b != ChatRoom.blockedByMe);
    _setBlockers(dm, [...others, if (blocked) ChatRoom.blockedByMe]);
    _syncBlocked(user, blocked);
    notifyListeners();
  }

  void _syncBlocked(ChatUser user, bool blocked) {
    if (blocked == _blocked.containsKey(user.id)) return;
    if (blocked) {
      _blocked[user.id] = user;
    } else {
      _blocked.remove(user.id);
    }
    _visible.clear();
  }

  void _setBlockers(String roomId, List<String> blockers) {
    ChatRoom swap(ChatRoom r) => r.id == roomId ? r.withBlockers(blockers) : r;
    _rooms = _rooms.map(swap).toList();
    _dms = _dms.map(swap).toList();
    _recent = _recent.map(swap).toList();
    if (_draftDm case final draft?) _draftDm = swap(draft);
  }

  void _onBlockers(ChatBlockersEvent event) {
    _setBlockers(event.roomId, event.blockers);
    if (ChatRoom.peerIdOf(event.roomId) == null) return;
    final user = roomById(event.roomId).peer;
    // Unknown names come with the list
    if (user == null) {
      _source.loadBlocked();
    } else {
      _syncBlocked(user, event.blockers.contains(ChatRoom.blockedByMe));
    }
  }

  final Map<String, ({List<ChatMessage> all, bool faction, int minute, List<ChatMessage> shown})> _visible = {};

  List<ChatMessage> visibleMessagesFor(String roomId) {
    final all = messagesFor(roomId);
    final faction = _prefs.isFactionRoom(roomId);
    final now = DateTime.now();
    // Watch folding moves with the clock
    final minute = now.millisecondsSinceEpoch ~/ 60000;
    final cached = _visible[roomId];
    if (cached != null && identical(cached.all, all) && cached.faction == faction && cached.minute == minute) {
      return cached.shown;
    }
    final folded = faction ? {...chatJoinsFolded(all), ...chatWatchFolded(all, now)} : const <String>{};
    final shown = all.where((m) => m.isSystem || (!isHidden(m.sender) && !folded.contains(m.id))).toList();
    _visible[roomId] = (all: all, faction: faction, minute: minute, shown: shown);
    return shown;
  }

  /// Folded watch lines show as the card
  String shownIdOf(String roomId, String id) {
    final all = messagesFor(roomId);
    final now = DateTime.now();
    if (!_prefs.isFactionRoom(roomId) || !chatWatchFolded(all, now).contains(id)) return id;
    return chatWatchAnchor(all, now) ?? id;
  }

  final Map<String, (List<ChatMessage>, List<ChatMessage>)> _filtered = {};

  /// Own, system and mentions skip the filter
  List<ChatMessage> filteredMessagesFor(String roomId) {
    final all = visibleMessagesFor(roomId);
    final filter = _prefs.filterOf(roomId);
    if (!filter.isActive || roomId.startsWith('dm:')) return all;
    final cached = _filtered[roomId];
    if (cached != null && identical(cached.$1, all)) return cached.$2;
    final shown = all
        .where((m) => m.isSystem || m.sender.id == myUserId || highlightOf(m).on || !filter.hides(m.content))
        .toList();
    _filtered[roomId] = (all, shown);
    return shown;
  }

  final Map<String, (int, DateTime?)> _openUnread = {};
  final Map<String, String?> _firstUnread = {};
  final Map<String, DateTime> _seenUntil = {};

  DateTime? _pausedAt;

  /// DMs still loading after a cold start
  (DateTime, DateTime)? _lateAway;

  /// Left and back, per room
  final Map<String, (DateTime, DateTime)> _away = {};
  final Map<String, (List<ChatMessage>, int, ChatAway?)> _awayCache = {};

  /// Null once the conversation is read
  ChatAway? awayFor(String roomId) {
    final window = _away[roomId];
    if (window == null) return null;
    final list = filteredMessagesFor(roomId);
    final cached = _awayCache[roomId];
    if (cached != null && identical(cached.$1, list) && cached.$2 == _presenceRevision) return cached.$3;
    final away = ChatAway.build(
      messages: list,
      since: window.$1,
      now: window.$2,
      myUserId: myUserId,
      hasOlder: hasOlder(roomId),
      mention: (m) => matchOf(m)?.mention ?? false,
      word: (m) => matchOf(m)?.keyword != null || (!(matchOf(m)?.mention ?? false) && highlightOf(m).on),
      leaders: {
        for (final u in rosterOf(roomId))
          if (u.leader) u.id,
      },
    );
    _awayCache[roomId] = (list, _presenceRevision, away);
    return away;
  }

  void _applyLateAway(List<ChatRoom> dms) {
    final window = _lateAway;
    if (window == null) return;
    _lateAway = null;
    for (final dm in dms) {
      if (ChatAway.appliesTo(dm.id)) _away.putIfAbsent(dm.id, () => window);
    }
    _awayCache.clear();
  }

  /// Reached the end of the new messages
  void dismissAway(String roomId) {
    if (_away.remove(roomId) == null) return;
    _awayCache.remove(roomId);
    notifyListeners();
  }

  final Map<String, ChatMessage> _last = {};

  // Saved rows not yet refreshed
  final Set<String> _hydrated = {};
  Map<String, int> _savedUnread = const {};
  List<String>? _heldOrder;
  Timer? _settleTimer;
  Timer? _settleCapTimer;
  final Set<String> _awaitingPeek = {};
  Timer? _saveTimer;

  void Function(String json)? onInboxChanged;
  String? _savedJson;

  ChatMessage? lastMessageIn(String roomId) {
    final last = _last[roomId];
    if (last == null || last.isSystem || !isHidden(last.sender)) return last;
    return visibleMessagesFor(roomId).lastOrNull;
  }

  final Set<String> _loadedRooms = {};
  bool isLoaded(String roomId) => _loadedRooms.contains(roomId);

  Timer? _openTimer;
  String? _openingRoom;
  final Set<String> _openFailed = {};
  bool openFailed(String roomId) => _openFailed.contains(roomId);
  bool opening(String roomId) => _openingRoom == roomId;

  ChatRoomLoad loadOf(String roomId) {
    if (isLoaded(roomId)) return ChatRoomLoad.loaded;
    if (sessionIssue) return ChatRoomLoad.session;
    if (_connection == ChatConnection.error || unreachable) return ChatRoomLoad.unreachable;
    if (openFailed(roomId)) return ChatRoomLoad.timedOut;
    return ChatRoomLoad.loading;
  }

  /// Another room may have taken the open
  bool needsOpen(String roomId) => !isLoaded(roomId) && !openFailed(roomId) && !opening(roomId);

  final Map<String, bool> _hasOlder = {};
  bool hasOlder(String roomId) => _hasOlder[roomId] ?? false;

  bool _loadingOlder = false;
  bool get loadingOlder => _loadingOlder;

  Map<String, int> _unread = {};
  int unreadFor(String roomId) => _inSight(roomId) || _prefs.isArchived(roomId) ? 0 : _count(roomId);

  /// Torn's count, or one if marked unread
  int _count(String roomId) => switch (_unread[roomId] ?? 0) {
    0 when _prefs.markedUnread.contains(roomId) => 1,
    final n => n,
  };

  /// Row count, last known until Torn answers
  (int, bool) listUnreadFor(String roomId) {
    final (shown, more) = unreadShown(roomId);
    if (shown > 0) return (shown, more);
    final live = unreadFor(roomId);
    if (live > 0 || _unreadKnown || _neverRead.contains(roomId) || _inSight(roomId) || _prefs.isArchived(roomId)) {
      return (live, more);
    }
    return (_savedUnread[roomId] ?? 0, more);
  }

  late final ChatTypingReport _typingReport = ChatTypingReport((id, on) => _source.typing(id, on));

  bool _mayReportTyping(String roomId) {
    if (!_source.available || !_ready || _connection != ChatConnection.connected || _pausedAt != null) return false;
    final room = [..._rooms, ..._privateChats, ?_draftDm].where((r) => r.id == roomId).firstOrNull;
    return room != null && room.canWrite && room.reportTyping && _prefs.roomState(roomId) == ChatRoomState.live;
  }

  /// The player edited the box of [roomId]
  void typed(String roomId, String text) => _typingReport.typed(roomId, text, allowed: _mayReportTyping(roomId));

  void typingStopped(String roomId) => _typingReport.stop(roomId, allowed: _mayReportTyping(roomId));

  final Map<String, List<ChatUser>> _typing = {};
  final Map<String, Timer> _typingExpiry = {};
  static const Duration _typingTtl = Duration(seconds: 12);
  List<ChatUser> typingIn(String roomId) => _typing[roomId] ?? const [];

  String? _searchQuery;
  List<ChatUser>? _searchResults;
  String? get searchQuery => _searchQuery;
  List<ChatUser>? get searchResults => _searchResults;
  bool get searching => _searchQuery != null && _searchResults == null;

  bool _inboxShown = false;
  bool get inboxShown => _inboxShown;
  Timer? _syncTimer;
  final Map<String, Timer> _readTimers = {};
  final Map<String, Timer> _sendTimers = {};
  Timer? _apiTimer;
  String? _apiRoom;
  final Set<String> _asking = {};
  final Set<String> _covered = {};

  // Answers from a forgotten account are dropped
  int _generation = 0;
  bool _disposed = false;

  /// Most recent activity first
  List<ChatRoom> get conversations {
    final all = [..._rooms, ..._privateChats];
    if (_draftDm != null && !all.any((d) => d.id == _draftDm!.id)) all.add(_draftDm!);
    final order = {for (var i = 0; i < all.length; i++) all[i].id: i};
    all.sort((a, b) {
      final ta = _last[a.id]?.createdAt;
      final tb = _last[b.id]?.createdAt;
      if (ta != null && tb != null && ta != tb) return tb.compareTo(ta);
      if (ta != null && tb == null) return -1;
      if (ta == null && tb != null) return 1;
      return order[a.id]!.compareTo(order[b.id]!);
    });
    final held = _heldOrder;
    return held == null ? all : holdOrder(all, held);
  }

  void restoreInbox(ChatInboxSnapshot? saved) {
    if (saved == null || _ready || _heldOrder != null) return;
    _rooms = [for (final r in saved.rooms) if (!r.isDm) r];
    for (final r in _rooms) {
      if (r.emblemUrl case final url?) _emblems[r.id] = url;
    }
    _recent = [for (final r in saved.rooms) if (r.isDm) r];
    _last.addAll(saved.last);
    _hydrated.addAll(saved.last.keys);
    _savedUnread = saved.unread;
    _holdOrder(saved.order);
  }

  void _holdOrder(List<String> order, {List<String> waiting = const []}) {
    _heldOrder ??= order;
    _awaitingPeek
      ..clear()
      ..addAll(waiting);
    _settleTimer?.cancel();
    _settleTimer = null;
    _settleCapTimer?.cancel();
    // Otherwise the first event starts it
    _settleCapTimer = waiting.isEmpty ? null : Timer(_peekCap, _releaseOrder);
  }

  void _releaseOrder() {
    _settleTimer?.cancel();
    _settleCapTimer?.cancel();
    _settleTimer = _settleCapTimer = null;
    _awaitingPeek.clear();
    if (_heldOrder == null) return;
    _heldOrder = null;
    if (!_disposed) notifyListeners();
  }

  void _settleOrder(ChatEvent event) {
    final held = _heldOrder;
    if (held == null) return;
    _settleCapTimer ??= Timer(_settleCap, _releaseOrder);
    if (_awaitingPeek.isNotEmpty) {
      switch (event) {
        case ChatHistoryEvent():
          return _releaseOrder();
        case ChatMessageEvent(:final message):
          // Live line rises inside the held order
          _heldOrder = [message.roomId, ...held.where((r) => r != message.roomId)];
        case ChatPeekEvent():
          _awaitingPeek.remove(event.roomId);
        default:
      }
    }
    final data =
        event is ChatRoomsEvent ||
        event is ChatDmsEvent ||
        event is ChatRecentDmsEvent ||
        event is ChatUnreadEvent ||
        event is ChatPeekEvent;
    if (!data || _listed.isEmpty || !_dmsLoaded || !_unreadKnown) return;
    _settleTimer?.cancel();
    // One move after all lines arrive
    _settleTimer = _awaitingPeek.isEmpty ? Timer(_settleGrace, _releaseOrder) : null;
  }

  void _scheduleSave() {
    if (_saveTimer != null || !_canSave) return;
    _saveTimer = Timer(_saveDelay, saveInbox);
  }

  bool get _canSave =>
      onInboxChanged != null && _heldOrder == null && _ready && _unreadKnown && _dmsLoaded && myUserId != null;

  void saveInbox() {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_canSave) return;
    final rooms = conversations.where((r) => r.id != _draftDm?.id).toList();
    final json = ChatInboxSnapshot(
      owner: myUserId!,
      rooms: rooms,
      last: {
        for (final r in rooms)
          if (_last[r.id] case final m? when !m.isLocal) r.id: m,
      },
      unread: {
        for (final e in _unread.entries)
          if (e.value > 0) e.key: e.value,
      },
    ).encode();
    if (json == _savedJson) return;
    _savedJson = json;
    onInboxChanged!(json);
  }

  void _dropInbox() {
    for (final id in _hydrated) {
      _last.remove(id);
    }
    _hydrated.clear();
    _savedUnread = const {};
    _releaseOrder();
    _saveTimer?.cancel();
    _saveTimer = null;
    _savedJson = null;
    onInboxChanged?.call('');
  }

  List<ChatRoom> get _privateChats {
    final open = {for (final d in _dms) d.id: d};
    final recent = {for (final d in _recent) d.id};
    return [for (final d in _recent) open[d.id] ?? d, ..._dms.where((d) => !recent.contains(d.id))];
  }

  /// With unread messages, in inbox order
  List<ChatRoom> get unreadQueue {
    final pinned = _prefs.pinned;
    final rooms = conversations
        .where(
          (r) =>
              !_neverRead.contains(r.id) &&
              !_prefs.hiddenRooms.contains(r.id) &&
              unreadFor(r.id) > 0 &&
              countsUnread(r.id),
        )
        .toList();
    return [for (final id in pinned) ...rooms.where((r) => r.id == id), ...rooms.where((r) => !pinned.contains(r.id))];
  }

  ChatRoom roomById(String id) {
    for (final r in [..._rooms, ..._privateChats, if (_draftDm != null) _draftDm!]) {
      if (r.id == id) return r;
    }
    final dm = id.startsWith('dm:');
    final name = _senderNames[id] ?? (dm ? 'Private chat' : id);
    return ChatRoom(id: id, name: name, type: dm ? ChatRoomType.dm : ChatRoomType.official);
  }

  final Map<String, String> _senderNames = {};

  /// Title until the room's own data arrives
  void noteSender(String roomId, String name) => _senderNames[roomId] = name;

  bool countsUnread(String roomId) => _prefs.mutedUnread || !_prefs.isMuted(roomId);

  bool countsInBadge(String roomId) => !_neverRead.contains(roomId) && countsUnread(roomId);

  bool tornMarksRead(String roomId) => !_neverRead.contains(roomId);

  /// For rooms Torn never marks read
  bool newSinceVisit(String roomId) {
    if (unreadFor(roomId) <= 0) return false;
    final seen = _seenUntil[roomId];
    final last = _last[roomId]?.createdAt;
    return seen == null || (last != null && last.isAfter(seen));
  }

  /// Local for rooms Torn never marks read
  (int, bool) unreadShown(String roomId) {
    if (!_neverRead.contains(roomId)) return (unreadFor(roomId), false);
    if (_inSight(roomId) || _prefs.isArchived(roomId)) return (0, false);
    final seen = _seenUntil[roomId];
    final list = visibleMessagesFor(roomId);
    final count = list
        .where((m) => !m.isSystem && m.sender.id != myUserId && (seen == null || m.createdAt.isAfter(seen)))
        .length;
    final more = seen != null && hasOlder(roomId) && list.isNotEmpty && list.first.createdAt.isAfter(seen);
    return (count, more);
  }

  ChatMatch? matchOf(ChatMessage message) {
    if (message.isSystem || (myUserId != null && message.sender.id == myUserId)) return null;
    final matcher = _matcher ??= ChatAlertMatcher(
      name: _prefs.mentions ? _myName : null,
      keywords: [
        for (final w in _prefs.browserWords)
          if (_prefs.alertWords.contains(w)) w,
      ],
    );
    if (matcher.isEmpty) return null;
    if (_matches.length > 5000) _matches.clear();
    return _matches.putIfAbsent(message.id, () => matcher.match(message.content));
  }

  ({bool on, Color? color}) highlightOf(ChatMessage message) {
    if (matchOf(message)?.mention ?? false) return (on: true, color: null);
    final person = _prefs.personOf(message.sender.id);
    if (person.highlight && !message.isSystem) return (on: true, color: person.highlightColor);
    final browser =
        _prefs.browserHighlight && !message.isSystem && _prefs.browserMatcher.match(message.content) != null;
    return (on: browser, color: browser ? _prefs.browserColor : null);
  }

  void markAlertsSeen([String? roomId]) {
    var changed = false;
    for (final a in _alerts) {
      if (!a.seen && (roomId == null || a.message.roomId == roomId)) {
        a.seen = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  /// Room ids plus "dm" for private chats
  Map<String, int> unreadGroups() {
    final groups = <String, int>{};
    for (final id in {..._unread.keys, ..._prefs.markedUnread, ..._neverRead}) {
      final count = unreadShown(id).$1;
      if (count <= 0 || !countsUnread(id)) continue;
      final key = id.startsWith('dm:') ? 'dm' : id;
      groups[key] = (groups[key] ?? 0) + count;
    }
    return groups;
  }

  void attach() {
    _inboxShown = true;
    retrySession();
    if (_ready) _refreshInbox();
    notifyListeners();
  }

  void detach() {
    _inboxShown = false;
    saveInbox();
  }

  void retry() {
    final failed = _connection == ChatConnection.error;
    _connection = ChatConnection.connecting;
    _stallTimer?.cancel();
    _stallTimer = null;
    _stalled = false;
    _trackStall();
    notifyListeners();
    // Ready only comes with a new page
    if (!_ready || failed) {
      _source.reconnect();
      return;
    }
    _source.refreshRooms();
    if (_inboxShown) _refreshInbox();
    if ((currentRoomId ?? _peeked.lastOrNull) case final roomId?) _openRoom(roomId);
  }

  void retryRoom(String roomId) {
    _openFailed.remove(roomId);
    notifyListeners();
    if (_ready) _openRoom(roomId);
  }

  void _openRoom(String roomId) {
    _source.openRoom(roomId);
    // The source keeps one room open
    _stopOpening();
    if (isLoaded(roomId)) return;
    _openingRoom = roomId;
    _openTimer = Timer(_openTimeout, () {
      _openingRoom = null;
      if (_disposed || isLoaded(roomId)) return;
      _openFailed.add(roomId);
      notifyListeners();
    });
  }

  void _stopOpening() {
    _openTimer?.cancel();
    _openTimer = null;
    _openingRoom = null;
  }

  void _reopen() {
    final roomId = currentRoomId ?? _peeked.lastOrNull;
    if (roomId == null || !_ready || isLoaded(roomId)) return;
    _openRoom(roomId);
  }

  /// Without a session, spaced out
  void retrySession() {
    if (!sessionIssue || _sessionRetry != null) return;
    final wait = _sessionRetryGap - DateTime.now().difference(_sessionRetryAt);
    void reconnect() {
      _sessionRetry = null;
      if (!sessionIssue) return;
      _sessionRetryAt = DateTime.now();
      _source.reconnect();
    }

    wait > Duration.zero ? _sessionRetry = Timer(wait, reconnect) : reconnect();
  }

  /// Torn login, no retry gap
  void onLogin({bool accountChanged = false}) {
    _loggedOut = false;
    if (_connection == ChatConnection.connected && _ready) {
      if (accountChanged) _source.switchAccount();
      return;
    }
    _sessionRetry?.cancel();
    _sessionRetry = null;
    _sessionRetryAt = DateTime.now();
    _connection = ChatConnection.connecting;
    resetStall();
    notifyListeners();
    _source.reconnect();
  }

  /// Torn logout, keeps the account data
  void onLogout() {
    _loggedOut = true;
    _graceTimer?.cancel();
    _graceTimer = null;
    _held = null;
    _sessionRetry?.cancel();
    _sessionRetry = null;
    _stallTimer?.cancel();
    _stallTimer = null;
    _connection = ChatConnection.noSession;
    _ready = false;
    notifyListeners();
  }

  /// Errors stay hidden until the grace ends
  void _beginGrace() {
    _held = null;
    _graceTimer?.cancel();
    _graceTimer = Timer(_startGrace, () {
      _graceTimer = null;
      final held = _held;
      _held = null;
      if (held == null || _connection == ChatConnection.connected) return;
      _connection = held;
      if (needsLogin) _ready = false;
      notifyListeners();
    });
  }

  void resetStall() {
    _beginGrace();
    _stallTimer?.cancel();
    _stallTimer = null;
    _stalled = false;
    _trackStall();
  }

  void _trackStall() {
    if (_connection == ChatConnection.connected && _ready) {
      _stallTimer?.cancel();
      _stallTimer = null;
      _stalled = false;
      return;
    }
    if (_stallTimer != null) return;
    _stallTimer = Timer(_stallAfter, () {
      _stalled = true;
      notifyListeners();
    });
  }

  void openConversation(String roomId) {
    _onScreen
      ..remove(roomId)
      ..add(roomId);
    _loadingOlder = false;
    _watchPagesAsked.remove(roomId);
    _readOnSight(roomId);
    _syncApi();
    if ((_openUnread[roomId]?.$1 ?? 0) == 0) {
      final since = _neverRead.contains(roomId) ? _seenUntil[roomId] : null;
      final count = since != null || _neverRead.contains(roomId) ? 0 : _unread[roomId] ?? 0;
      if (since != null || count > 0) {
        _openUnread[roomId] = (count, since);
        _firstUnread.remove(roomId);
      }
    }
    _openFailed.remove(roomId);
    notifyListeners();
    if (!_ready) return;
    _openRoom(roomId);
    if (_foreground) _markRead(roomId);
    _refreshPresence();
    _fillWatchWindow(roomId);
  }

  final Set<String> _peeked = {};

  /// For the list, read as if opened
  void peekRoom(String roomId) {
    _peeked
      ..remove(roomId)
      ..add(roomId);
    _readOnSight(roomId);
    _openFailed.remove(roomId);
    notifyListeners();
    if (!_ready) return;
    if (_onScreen.isEmpty) _openRoom(roomId);
    if (_foreground) _markRead(roomId);
  }

  void unpeekRoom(String roomId) {
    if (!_peeked.remove(roomId)) return;
    if (messagesFor(roomId).lastOrNull case final newest?) _seenUntil[roomId] = newest.createdAt;
    if (!_ready || _onScreen.isNotEmpty) return;
    if (_peeked.lastOrNull case final other?) {
      _openRoom(other);
    } else {
      _source.closeRoom();
    }
  }

  bool _inSight(String roomId) => isOnScreen(roomId) || _peeked.contains(roomId);

  void _readOnSight(String roomId) {
    _prefs.setMarkedUnread(roomId, false);
    if (roomId.startsWith('dm:')) dismissWaiting(roomId);
    markAlertsSeen(roomId);
  }

  /// Fixed while the conversation stays open
  String? firstUnreadId(String roomId) {
    final list = messagesFor(roomId);
    String? first;
    if (_firstUnread.containsKey(roomId)) {
      first = _firstUnread[roomId];
    } else {
      final open = _openUnread[roomId];
      if (open == null || !isLoaded(roomId)) return null;
      final (count, since) = open;
      bool fromOthers(ChatMessage m) => m.state == ChatMessageState.sent && !m.isLocal && m.sender.id != myUserId;
      var start = -1;
      if (since != null) {
        start = list.indexWhere((m) => fromOthers(m) && m.createdAt.isAfter(since));
      } else {
        var seen = 0;
        for (var i = list.length - 1; i >= 0 && seen < count; i--) {
          if (!fromOthers(list[i])) continue;
          start = i;
          seen++;
        }
      }
      first = start < 0 ? null : list[start].id;
      _firstUnread[roomId] = first;
    }
    if (first == null) return null;
    final at = list.indexWhere((m) => m.id == first);
    if (at < 0) return null;
    final from = {for (final m in list.skip(at)) m.id};
    return visibleMessagesFor(roomId).where((m) => from.contains(m.id)).firstOrNull?.id;
  }

  bool canMarkRead(String roomId) => !_neverRead.contains(roomId) && _count(roomId) > 0;

  bool canMarkUnread(String roomId) => !_neverRead.contains(roomId) && _count(roomId) == 0;

  void markUnread(String roomId) {
    if (!canMarkUnread(roomId)) return;
    _prefs.setMarkedUnread(roomId, true);
    notifyListeners();
  }

  /// DMs left unanswered by the player
  List<(ChatRoom, ChatMessage)> waitingDms() {
    final hours = _prefs.waitingHours;
    if (hours <= 0) return const [];
    final now = DateTime.now();
    final waiting = <(ChatRoom, ChatMessage)>[];
    for (final room in conversations) {
      final last = lastMessageIn(room.id);
      if (!room.isDm || last == null || last.isSystem || last.sender.id == myUserId) continue;
      if (_prefs.hiddenRooms.contains(room.id) || _prefs.isArchived(room.id) || isOnScreen(room.id)) continue;
      if (!last.createdAt.isAfter(_prefs.waitingDismissed[room.id] ?? DateTime(0))) continue;
      final age = now.difference(last.createdAt);
      if (age >= Duration(hours: hours) && age < const Duration(days: 7)) waiting.add((room, last));
    }
    return waiting..sort((a, b) => a.$2.createdAt.compareTo(b.$2.createdAt));
  }

  void dismissWaiting([String? roomId]) {
    final rooms = roomId == null ? waitingDms().map((w) => w.$1.id) : [roomId];
    _prefs.dismissWaiting({
      for (final id in rooms)
        if (lastMessageIn(id) case final last?) id: last.createdAt,
    });
  }

  List<ChatRoom> get hiddenRooms => [
    for (final r in _rooms)
      if (_prefs.hiddenRooms.contains(r.id)) r,
  ];

  List<ChatRoom> get archivedDms => [
    for (final r in conversations)
      if (r.isDm && _prefs.isArchived(r.id)) r,
  ];

  void markRead(String roomId) {
    if (!canMarkRead(roomId)) return;
    _away.remove(roomId);
    _prefs.setMarkedUnread(roomId, false);
    if (roomId.startsWith('dm:')) dismissWaiting(roomId);
    _markRead(roomId);
    notifyListeners();
  }

  List<String> get readable => [
    for (final id in {..._unread.keys, ..._prefs.markedUnread})
      if (_count(id) > 0 && !_neverRead.contains(id) && !_prefs.hiddenRooms.contains(id) && !_prefs.isArchived(id)) id,
  ];

  int markAllRead() {
    final ids = readable;
    if (ids.isEmpty) return 0;
    // Read all also covers Global, Trade, hidden
    final oneCall = !_unread.entries.any((e) => e.value > 0 && !ids.contains(e.key));
    for (final id in ids) {
      _away.remove(id);
      _prefs.setMarkedUnread(id, false);
      if (oneCall) {
        _unread[id] = 0;
      } else {
        _markRead(id);
      }
    }
    if (oneCall) _source.markAllRead();
    notifyListeners();
    return ids.length;
  }

  /// Shown until Torn lists it
  void addDraftDm(ChatUser user) {
    final id = ChatRoom.dmId(user.id);
    if (!_privateChats.any((d) => d.id == id)) {
      _draftDm = ChatRoom(id: id, name: user.name, type: ChatRoomType.dm, peer: user);
    }
  }

  /// Without [roomId], the one on top
  void closeConversation([String? roomId]) {
    if (_onScreen.isEmpty) return;
    final closing = roomId ?? _onScreen.last;
    _onScreen.remove(closing);
    if (!_onScreen.contains(closing)) {
      _openUnread.remove(closing);
      _firstUnread.remove(closing);
      _away.remove(closing);
      _covered.remove(closing);
      final newest = messagesFor(closing).lastOrNull;
      if (newest != null) _seenUntil[closing] = newest.createdAt;
      if (closing.startsWith('dm:')) dismissWaiting(closing);
    }
    _readTimers.remove(closing)?.cancel();
    _syncApi();
    final below = currentRoomId;
    switch (below ?? _peeked.lastOrNull) {
      case final roomId?:
        _openRoom(roomId);
      case null:
        _source.closeRoom();
    }
    if (below != null && _foreground) _markRead(below);
    _source.refreshUnread();
    notifyListeners();
  }

  Future<void> loadMoreRecent() async {
    if (_loadingRecent || !_recentHasMore) return;
    _loadingRecent = true;
    notifyListeners();
    try {
      await _source.loadRecentDms(offset: _recentOffset);
    } finally {
      _loadingRecent = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Recent chats keep it
  void closeDm(String roomId) {
    final userId = ChatRoom.peerIdOf(roomId);
    if (userId == null) return;
    _dms = _dms.where((d) => d.id != roomId).toList();
    if (_draftDm?.id == roomId) _draftDm = null;
    notifyListeners();
    _source.closeDm(userId);
  }

  static bool matchesText(ChatMessage m, String term) =>
      m.content.toLowerCase().contains(term) || (!m.isSystem && m.sender.name.toLowerCase().contains(term));

  /// Only what is in memory, newest first
  List<(ChatRoom, List<ChatMessage>)> searchMessages(String query) {
    final term = query.trim().toLowerCase();
    if (term.length < 2) return const [];
    final groups = <(ChatRoom, List<ChatMessage>)>[];
    for (final room in conversations) {
      if (_prefs.hiddenRooms.contains(room.id)) continue;
      final loaded = visibleMessagesFor(room.id);
      final pool = loaded.isNotEmpty ? loaded : [?lastMessageIn(room.id)];
      final hits = [
        for (final m in pool.reversed)
          if (m.state == ChatMessageState.sent && m.content.toLowerCase().contains(term)) m,
      ];
      if (hits.isNotEmpty) groups.add((room, hits));
    }
    groups.sort((a, b) => b.$2.first.createdAt.compareTo(a.$2.first.createdAt));
    return groups;
  }

  /// Private chats first, then room senders
  List<(ChatUser, ChatRoom)> searchPlayers(String query) {
    final term = query.trim().toLowerCase();
    if (term.length < 2) return const [];
    final found = <int, (ChatUser, ChatRoom)>{};
    final rooms = [
      for (final room in conversations)
        if (!_prefs.hiddenRooms.contains(room.id)) room,
    ];
    for (final room in rooms.where((r) => r.isDm)) {
      final id = room.peer?.id ?? ChatRoom.peerIdOf(room.id);
      if (id == null || !room.name.toLowerCase().contains(term)) continue;
      found[id] = (room.peer ?? ChatUser(id: id, name: room.name), room);
    }
    final seen = <int, (ChatUser, ChatRoom, DateTime)>{};
    for (final room in rooms.where((r) => !r.isDm)) {
      final loaded = visibleMessagesFor(room.id);
      for (final m in loaded.isNotEmpty ? loaded : [?lastMessageIn(room.id)]) {
        final user = m.sender;
        if (m.isSystem || user.id <= 0 || user.id == myUserId || found.containsKey(user.id)) continue;
        if (!user.name.toLowerCase().contains(term)) continue;
        final known = seen[user.id];
        if (known == null || known.$3.isBefore(m.createdAt)) seen[user.id] = (user, room, m.createdAt);
      }
    }
    final recent = seen.values.toList()..sort((a, b) => b.$3.compareTo(a.$3));
    return [...found.values, for (final p in recent) (p.$1, p.$2)];
  }

  void search(String name) {
    final query = name.trim();
    _searchResults = null;
    _searchQuery = query.isEmpty ? null : query;
    notifyListeners();
    if (query.isNotEmpty) _source.search(query);
  }

  /// Only if nobody searched since
  void endSearch(String name) {
    if (_searchQuery == name.trim()) search('');
  }

  ChatMessage? _oldestSent(String roomId) =>
      messagesFor(roomId).where((m) => m.state == ChatMessageState.sent).firstOrNull;

  Future<void> loadOlder([String? room]) async {
    final roomId = room ?? currentRoomId;
    if (roomId == null) return;
    final oldest = _oldestSent(roomId);
    if (_loadingOlder || !hasOlder(roomId) || oldest == null) return;
    _loadingOlder = true;
    _olderAsked[roomId] = oldest.createdAt;
    notifyListeners();
    try {
      await _source.loadOlder(roomId, oldest.createdAt);
    } finally {
      _loadingOlder = false;
      if (!_disposed) {
        notifyListeners();
        _fillWatchWindow(roomId);
      }
    }
  }

  static const int _watchPages = 4;
  final Map<String, int> _watchPagesAsked = {};
  final Map<String, DateTime> _olderAsked = {};

  bool _watchCovered(String roomId) {
    final oldest = _oldestSent(roomId);
    return !hasOlder(roomId) || oldest == null || !oldest.createdAt.isAfter(DateTime.now().subtract(chatWatchWindow));
  }

  /// Short of the window, pages still coming
  bool watchHistoryShort(String roomId) =>
      !_watchCovered(roomId) && ((_watchPagesAsked[roomId] ?? 0) < _watchPages || _loadingOlder);

  /// One page per arrival, capped
  void _fillWatchWindow(String roomId) {
    if (!_prefs.isFactionRoom(roomId) || !isOnScreen(roomId) || _loadingOlder || _watchCovered(roomId)) return;
    final pages = _watchPagesAsked[roomId] ?? 0;
    // That page is already on its way
    if (pages >= _watchPages || _olderAsked[roomId] == _oldestSent(roomId)!.createdAt) return;
    _watchPagesAsked[roomId] = pages + 1;
    unawaited(loadOlder(roomId));
  }

  void send(String text, {String? to}) {
    final roomId = to ?? currentRoomId;
    final content = text.trim();
    if (roomId == null || content.isEmpty) return;
    typingStopped(roomId);
    final reqId = const Uuid().v4();
    final message = ChatMessage(
      id: reqId,
      reqId: reqId,
      roomId: roomId,
      sender: ChatUser(id: myUserId ?? 0, name: 'You'),
      content: content,
      createdAt: DateTime.now(),
      state: ChatMessageState.pending,
    );
    _messages[roomId] = [...messagesFor(roomId), message];
    _sendTimers[reqId] = Timer(_sendTimeout, () => _settleSend(roomId, reqId, ChatMessageState.failed));
    notifyListeners();
    _source.send(roomId, content, reqId);
    StatsController.chat.count('sent');
    StatsController.chat.count('sent_${StatsController.chat.roomKind(roomId)}');
  }

  void resend(ChatMessage failed) {
    final list = _messages[failed.roomId];
    if (list == null || !list.any((m) => m.id == failed.id && m.state == ChatMessageState.failed)) return;
    _messages[failed.roomId] = [
      for (final m in list)
        if (m.id != failed.id) m,
    ];
    send(failed.content, to: failed.roomId);
  }

  void replaceLocal(String roomId, bool Function(ChatMessage m) test, List<ChatMessage> lines) {
    final current = messagesFor(roomId);
    final list = [
      for (final m in current)
        if (!m.isLocal || !test(m)) m,
    ];
    if (lines.isEmpty && list.length == current.length) return;
    for (final line in lines) {
      final at = list.indexWhere((m) => m.createdAt.isAfter(line.createdAt));
      at < 0 ? list.add(line) : list.insert(at, line);
    }
    _messages[roomId] = list;
    notifyListeners();
  }

  void _refreshInbox() {
    _source.refreshRooms();
    _source.refreshUnread();
    _source.refreshDms(force: true);
    final ask = [
      for (final r in _rooms)
        if (r.lastMessage == null) r.id,
    ];
    if (ask.isNotEmpty) _holdOrder([for (final r in conversations) r.id], waiting: ask);
    _source.peek(ask);
    _source.loadBlocked();
  }

  void _refreshPresence() {
    final peers = {for (final id in _onScreen) ?ChatRoom.peerIdOf(id)};
    if (peers.isNotEmpty) _source.online(peers.toList());
  }

  /// Another screen on top stops the poll
  void setCovered(String roomId, bool covered) {
    if (covered ? !_covered.add(roomId) : !_covered.remove(roomId)) return;
    _syncApi();
  }

  bool hasRoster(String roomId) => _prefs.isFactionRoom(roomId) || roomId == 'company';

  Duration _pollEvery(String roomId) =>
      _prefs.isFactionRoom(roomId) ? const Duration(minutes: 1) : const Duration(seconds: 30);

  void _syncApi() {
    final roomId = currentRoomId;
    final polled = roomId != null && (ChatRoom.peerIdOf(roomId) != null || hasRoster(roomId));
    final wanted = polled && !_covered.contains(roomId) ? roomId : null;
    if (wanted == _apiRoom) return;
    _apiTimer?.cancel();
    _apiTimer = null;
    _apiRoom = wanted;
    if (wanted == null || _api == null) return;
    _askApi(wanted);
    _apiTimer = Timer.periodic(_pollEvery(wanted), (_) => _askApi(wanted));
  }

  Future<void> _askApi(String roomId) async {
    final api = _api;
    if (api == null || _asking.contains(roomId)) return;
    if (appInBackground() || ChatLinkPreviews.busy) return;
    _asking.add(roomId);
    final generation = _generation;
    try {
      final peer = ChatRoom.peerIdOf(roomId);
      if (peer != null) {
        final action = await api.lastAction(peer);
        if (action == null || _disposed || generation != _generation) return;
        _lastAction[peer] = action;
      } else {
        final roster = await api.roster(roomId);
        if (roster == null || _disposed || generation != _generation) return;
        _roster[roomId] = _byPresence(roster);
      }
      _presenceRevision++;
      notifyListeners();
    } finally {
      if (generation == _generation) _asking.remove(roomId);
    }
  }

  Future<void> refreshFriends({bool force = false}) async {
    final api = _api;
    if (api == null || _askingFriends || !_foreground) return;
    if (!force && DateTime.now().difference(_friendsAt) < _friendsCache) return;
    _askingFriends = true;
    notifyListeners();
    final generation = _generation;
    try {
      final friends = await api.friends();
      if (_disposed || generation != _generation) return;
      _friendsAt = DateTime.now();
      _friendsFailed = friends == null;
      if (friends != null) _friends = _byPresence(friends, recentFirst: true);
    } finally {
      if (generation == _generation) {
        _askingFriends = false;
        if (!_disposed) notifyListeners();
      }
    }
  }

  List<ChatUser> _byPresence(List<(ChatUser, ChatLastAction)> users, {bool recentFirst = false}) {
    int byRecent(ChatLastAction a, ChatLastAction b) =>
        !recentFirst || a.presence == ChatPresence.online || a.at == b.at
        ? 0
        : (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0));
    users.sort(
      (a, b) => a.$2.presence != b.$2.presence
          ? a.$2.presence.index.compareTo(b.$2.presence.index)
          : switch (byRecent(a.$2, b.$2)) {
              0 => a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase()),
              final order => order,
            },
    );
    for (final (user, action) in users) {
      _lastAction[user.id] = action;
    }
    return [for (final (user, _) in users) user];
  }

  void paused({DateTime? at}) {
    _pausedAt = at ?? DateTime.now();
    _prefs.setPausedAt(_pausedAt);
    saveInbox();
  }

  /// After the system killed the app
  void restorePaused() {
    final left = _prefs.pausedAt;
    if (left == null) return;
    if (DateTime.now().difference(left) >= ChatAway.minAway) _lateAway = (left, DateTime.now());
    _pausedAt = left;
    resumed();
  }

  void resumed() {
    if (sessionIssue) {
      final lost = _connection;
      _connection = ChatConnection.connecting;
      _beginGrace();
      _held = lost;
      notifyListeners();
    }
    final left = _pausedAt;
    _pausedAt = null;
    _prefs.setPausedAt(null);
    final roomId = currentRoomId;
    if (left != null && DateTime.now().difference(left) >= ChatAway.minAway) {
      final back = DateTime.now();
      for (final id in {..._onScreen, for (final r in conversations) r.id}.where(ChatAway.appliesTo)) {
        final kept = _away[id];
        _away[id] = (kept?.$1 ?? left, kept?.$2 ?? back);
      }
      _awayCache.clear();
      if (roomId != null && _ready && _connection == ChatConnection.connected) _openRoom(roomId);
    }
    if (roomId == null || (_unread[roomId] ?? 0) == 0) return;
    _markRead(roomId);
    notifyListeners();
  }

  static bool get _foreground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  bool _seen(String roomId) => (currentRoomId == roomId || _peeked.contains(roomId)) && _foreground;

  void _markRead(String roomId) {
    if (_neverRead.contains(roomId) || (_unread[roomId] ?? 0) == 0) return;
    _unread[roomId] = 0;
    _source.markRead(roomId);
  }

  void _settleSend(String roomId, String reqId, ChatMessageState state) {
    _sendTimers.remove(reqId)?.cancel();
    final list = _messages[roomId];
    if (list == null) return;
    _messages[roomId] = [
      for (final m in list)
        if (m.reqId == reqId && m.state == ChatMessageState.pending)
          ChatMessage(
            id: m.id,
            reqId: m.reqId,
            roomId: m.roomId,
            sender: m.sender,
            content: m.content,
            createdAt: m.createdAt,
            state: state,
          )
        else
          m,
    ];
    notifyListeners();
  }

  bool _frozen = false;
  bool _replaying = false;

  bool _stale = false;
  final List<ChatEvent> _deferred = [];

  /// Held events apply in order on release
  void setFrozen(bool value) {
    if (value == _frozen) return;
    _frozen = value;
    if (value) return;
    final held = [..._deferred];
    _deferred.clear();
    _replaying = true;
    held.forEach(_onEvent);
    _replaying = false;
    if (!_stale) return;
    _stale = false;
    _loadedRooms.clear();
    if (_ready) {
      _inboxShown ? _refreshInbox() : _source.refreshUnread();
      if (currentRoomId != null) {
        openConversation(currentRoomId!);
      } else {
        _peeked.toList().forEach(peekRoom);
      }
    }
    notifyListeners();
  }

  void _onEvent(ChatEvent event) {
    final flows =
        event is ChatReadyEvent ||
        event is ChatConnectionEvent ||
        event is ChatUnreadFailedEvent ||
        event is ChatPresenceEvent ||
        event is ChatBlockedEvent ||
        event is ChatSearchEvent ||
        event is ChatSendResultEvent;
    if (_frozen && !flows) {
      if (event is ChatTypingEvent || _stale) return;
      _deferred.add(event);
      if (_deferred.length > _maxDeferred) {
        _deferred.clear();
        _stale = true;
      }
      return;
    }
    switch (event) {
      case ChatReadyEvent():
        if (_myUserId != null && event.myUserId != null && event.myUserId != _myUserId) {
          _clearAccount();
          _connection = ChatConnection.connecting;
          _source.reconnect();
          break;
        }
        if (_myUserId == null && _savedUserId != null && event.myUserId != null && event.myUserId != _savedUserId) {
          _dropInbox();
          _rooms = _defaultRooms;
          _recent = const [];
        }
        _ready = true;
        _trackStall();
        _myUserId = event.myUserId ?? _myUserId;
        if (event.myName != null && event.myName != _myName) {
          _myName = event.myName;
          _resetMatcher();
        }
        // New pages start with every room live
        _paused = null;
        _syncPaused();
        _syncTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
          _reopen();
          _source.refreshUnread();
          if (_inboxShown) _source.refreshDms();
          _refreshPresence();
        });
        if (!_unreadKnown && !_countsLate) {
          _countsTimer ??= Timer(_countsWait, () {
            _countsTimer = null;
            _countsLate = true;
            notifyListeners();
          });
        }
        if (_inboxShown) _refreshInbox();
        if (currentRoomId != null) {
          openConversation(currentRoomId!);
        } else {
          _peeked.toList().forEach(peekRoom);
        }
        _source.loadBlocked();
      case ChatConnectionEvent():
        // The stopped page still says disconnected
        if (_loggedOut) break;
        final unsure = event.tentative || event.state == ChatConnection.needsBrowser;
        if (_graceTimer != null && (unsure || _outage(event.state))) {
          _held = event.state;
          if (!_ready) _connection = ChatConnection.connecting;
          _trackStall();
          break;
        }
        if (event.state == ChatConnection.connected) _held = null;
        final back = event.state == ChatConnection.connected && _connection != ChatConnection.connected;
        _connection = event.state;
        // Wiped only for another account
        if (needsLogin) _ready = false;
        _trackStall();
        if (event.reconnected && _ready) _source.refreshUnread();
        if (back && event.reconnected) _reopen();
      case ChatRoomsEvent():
        if (event.rooms.isEmpty) break;
        _prefs.noteRooms([
          for (final r in event.rooms)
            if (r.type == ChatRoomType.official) r.id,
        ]);
        _takeLast(event.rooms);
        // Contextual rooms like Travel arrive empty
        final fresh = [
          for (final r in event.rooms)
            if (_listed.isNotEmpty &&
                !_listed.contains(r.id) &&
                !_prefs.hiddenRooms.contains(r.id) &&
                _last[r.id] == null &&
                messagesFor(r.id).isEmpty)
              r.id,
        ];
        if (fresh.isNotEmpty) _source.peek(fresh);
        final gone = [
          for (final r in _rooms)
            if (_listed.contains(r.id)) r,
        ];
        _rooms = [for (final r in event.rooms) r.withEmblem(_emblems[r.id])];
        _listed = {for (final r in event.rooms) r.id};
        for (final r in gone.where((r) => !_listed.contains(r.id))) {
          _goneStream.add(r);
        }
      case ChatDmsEvent():
        _dms = event.dms;
        _dmsLoaded = true;
        _applyLateAway(event.dms);
        _takeLast(event.dms);
        if (_dms.any((d) => d.id == _draftDm?.id)) _draftDm = null;
      case ChatRecentDmsEvent():
        _mergeRecent(event);
        _dmsLoaded = true;
        _applyLateAway(event.dms);
        _takeLast(event.dms);
        if (_recent.any((d) => d.id == _draftDm?.id)) _draftDm = null;
      case ChatUnreadEvent():
        _unread = Map.of(event.counts);
        _unreadKnown = true;
        _unreadFailures = 0;
        _unreadRetry?.cancel();
        _unreadRetry = null;
        _countsTimer?.cancel();
        _countsTimer = null;
      case ChatUnreadFailedEvent():
        if (_unreadRetry != null || _unreadFailures >= _unreadRetries.length) break;
        _unreadRetry = Timer(_unreadRetries[_unreadFailures++], () {
          _unreadRetry = null;
          _source.refreshUnread();
        });
      case ChatReadEvent():
        if (event.roomId == null) {
          _source.refreshUnread();
        } else {
          _unread[event.roomId!] = event.unread ?? 0;
        }
      case ChatPeekEvent():
        _noteLast(event.roomId, event.last);
      case ChatPresenceEvent():
        _presence.addAll(event.users);
        _presenceRevision++;
      case ChatBlockedEvent():
        _blocked = {for (final u in event.users) u.id: u};
        _visible.clear();
      case ChatBlockersEvent():
        _onBlockers(event);
      case ChatSearchEvent():
        if (event.query == _searchQuery) _searchResults = event.users;
      case ChatSendResultEvent():
        _settleSend(event.roomId, event.reqId, event.ok ? ChatMessageState.sent : ChatMessageState.failed);
      case ChatHistoryEvent():
        _mergeHistory(event);
      case ChatMessageEvent():
        _addLive(event.message, event.unread);
      case ChatMessageDeletedEvent():
        final list = _messages[event.roomId];
        if (list != null) _messages[event.roomId] = list.where((m) => m.id != event.messageId).toList();
        if (_last[event.roomId]?.id == event.messageId) {
          final previous = _messages[event.roomId]?.lastOrNull;
          previous == null ? _last.remove(event.roomId) : _last[event.roomId] = previous;
        }
      case ChatTypingEvent():
        _setTyping(event.roomId, event.users);
    }
    _settleOrder(event);
    if (event is! ChatTypingEvent && event is! ChatPresenceEvent) _scheduleSave();
    notifyListeners();
  }

  void _takeLast(List<ChatRoom> rooms) {
    for (final room in rooms) {
      _noteLast(room.id, room.lastMessage);
    }
  }

  void _noteLast(String roomId, ChatMessage? last) {
    if (last == null) return;
    // First real answer replaces the saved line
    final saved = _hydrated.remove(roomId);
    if (saved || _last[roomId] == null || last.createdAt.isAfter(_last[roomId]!.createdAt)) _last[roomId] = last;
  }

  void _mergeRecent(ChatRecentDmsEvent event) {
    final ids = {for (final d in event.dms) d.id};
    final kept = _recent.where((d) => !ids.contains(d.id));
    if (event.offset > 0) {
      _recent = [...kept, ...event.dms];
      _recentOffset = event.offset + event.dms.length;
      _recentHasMore = event.hasMore;
      return;
    }
    // Keeps pages loaded with "load more"
    final morePages = _recentOffset > event.dms.length;
    _recent = [...event.dms, if (morePages) ...kept];
    if (!morePages) {
      _recentOffset = event.dms.length;
      _recentHasMore = event.hasMore;
    }
  }

  void _mergeHistory(ChatHistoryEvent event) {
    final current = messagesFor(event.roomId);
    final page = event.messages;
    final ids = page.map((m) => m.id).toSet();
    final reqIds = {for (final m in page) ?m.reqId};
    List<ChatMessage> merged;
    var olderKept = false;
    if (event.isOlderPage) {
      merged = [...page, ...current.where((m) => !ids.contains(m.id))];
    } else {
      final newest = page.isEmpty ? null : page.last.createdAt;
      // Older lines stay if this page joins
      final oldest = current.any((m) => ids.contains(m.id)) ? page.first.createdAt : null;
      // Keeps live arrivals and unconfirmed echoes
      final kept = current.where(
        (m) =>
            !ids.contains(m.id) &&
            !reqIds.contains(m.reqId) &&
            (m.isLocal ||
                m.state != ChatMessageState.sent ||
                (newest != null && m.createdAt.isAfter(newest)) ||
                (oldest != null && m.createdAt.isBefore(oldest))),
      );
      merged = [...page, ...kept];
      if (page.isNotEmpty) _last[event.roomId] = page.last;
      _hydrated.remove(event.roomId);
      olderKept = oldest != null && kept.any((m) => m.createdAt.isBefore(oldest));
    }
    if (!olderKept) _hasOlder[event.roomId] = event.hasOlder;
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _messages[event.roomId] = merged;
    _loadedRooms.add(event.roomId);
    if (opening(event.roomId)) _stopOpening();
    _openFailed.remove(event.roomId);
    _fillWatchWindow(event.roomId);
  }

  void _addLive(ChatMessage message, int? unread) {
    final roomId = message.roomId;
    final mine = myUserId != null && message.sender.id == myUserId;
    if (!mine && !message.isSystem) _prefs.setArchived(roomId, false);
    _last[roomId] = message;
    _hydrated.remove(roomId);
    if (_inSight(roomId) && !mine && !_neverRead.contains(roomId)) {
      if (_seen(roomId)) {
        _readTimers[roomId]?.cancel();
        _readTimers[roomId] = Timer(const Duration(seconds: 2), () {
          _readTimers.remove(roomId);
          if (_seen(roomId)) _source.markRead(roomId);
        });
      } else {
        // Read once it is really seen
        _unread[roomId] = unread ?? (_unread[roomId] ?? 0) + 1;
      }
    } else if (!_inSight(roomId) && unread != null && !mine) {
      _unread[roomId] = unread;
    }

    final list = messagesFor(roomId);
    if (list.any((m) => m.id == message.id)) return;
    final folds = _prefs.isFactionRoom(roomId) && chatJoinFolds(message, list);
    if (!mine && !message.isSystem && !folds) _checkAlert(message);
    if (message.reqId != null) _sendTimers.remove(message.reqId)?.cancel();
    final withoutEcho = message.reqId == null ? list : list.where((m) => m.reqId != message.reqId);
    var updated = [...withoutEcho, message];
    // Room being read keeps its loaded history
    final cap = isOnScreen(roomId) ? _maxMessagesPerRoom * 3 : _maxMessagesPerRoom;
    if (updated.length > cap) {
      updated = updated.sublist(updated.length - cap);
      _hasOlder[roomId] = true;
    }
    _messages[roomId] = updated;
    final typing = _typing[roomId];
    if (typing != null) _typing[roomId] = typing.where((u) => u.id != message.sender.id).toList();
  }

  void _checkAlert(ChatMessage message) {
    final roomId = message.roomId;
    if (_prefs.isFrozen(roomId)) return;
    final match = matchOf(message);
    if (isHidden(message.sender)) return;
    // A muted DM silences that person everywhere
    final dm = ChatRoom.dmId(message.sender.id);
    if (roomId != dm && _prefs.isMuted(dm)) return;
    if (!isOnScreen(roomId) && !_replaying) _incomingStream.add(ChatAlert(message, match));
    final level = _prefs.alertLevel(roomId);
    if (!ChatAlertMatcher.shouldAlert(level, muted: _prefs.isMuted(roomId), match: match)) return;
    final alert = ChatAlert(message, match, seen: _seen(roomId));
    if (match != null) {
      _alerts.insert(0, alert);
      if (_alerts.length > _maxAlerts) _alerts.removeLast();
    }
    if (!_seen(roomId) && !_replaying) _alertStream.add(alert);
  }

  /// Nothing from the previous account survives
  void _clearAccount() {
    _generation++;
    backTo = null;
    unreadOnly = false;
    waitingExpanded = false;
    lastItem = null;
    _userSchemes.clear();
    _messageParts.clear();
    _bankFor = null;
    _bank = const {};
    _deferred.clear();
    _stale = false;
    _ready = false;
    _myUserId = null;
    _savedUserId = null;
    _myName = null;
    _unreadKnown = false;
    _countsLate = false;
    _unreadFailures = 0;
    _countsTimer?.cancel();
    _countsTimer = null;
    _unreadRetry?.cancel();
    _unreadRetry = null;
    _resetMatcher();
    _paused = null;
    _alerts.clear();
    _rooms = _defaultRooms;
    _listed = {};
    _emblems.clear();
    _dms = const [];
    _dmsLoaded = false;
    _recent = const [];
    _recentOffset = 0;
    _recentHasMore = false;
    _draftDm = null;
    _onScreen.clear();
    _apiTimer?.cancel();
    _apiTimer = null;
    _apiRoom = null;
    _asking.clear();
    _askingFriends = false;
    _peeked.clear();
    _messages.clear();
    _visible.clear();
    _filtered.clear();
    _loadedRooms.clear();
    _openFailed.clear();
    _hasOlder.clear();
    _watchPagesAsked.clear();
    _olderAsked.clear();
    _last.clear();
    _dropInbox();
    _unread = {};
    _openUnread.clear();
    _firstUnread.clear();
    _seenUntil.clear();
    _away.clear();
    _awayCache.clear();
    _pausedAt = null;
    _lateAway = null;
    _prefs.setPausedAt(null);
    _presence.clear();
    _lastAction.clear();
    _roster.clear();
    _friends = null;
    _friendsAt = DateTime(0);
    _blocked = {};
    _searchQuery = null;
    _searchResults = null;
    _typing.clear();
    _typingReport.clear();
    for (final t in [..._typingExpiry.values, ..._readTimers.values, ..._sendTimers.values]) {
      t.cancel();
    }
    _typingExpiry.clear();
    _readTimers.clear();
    _stopOpening();
    _sendTimers.clear();
  }

  void forgetAccount() {
    _clearAccount();
    _connection = ChatConnection.connecting;
    notifyListeners();
    _source.reconnect();
  }

  void _resetMatcher() {
    _awayCache.clear();
    _matcher = null;
    _matches.clear();
  }

  void _onPrefs() {
    _resetMatcher();
    _visible.clear();
    for (final (roomId, since, end) in _prefs.takeThaws()) {
      final line = ChatMessage(
        id: 'local-thaw-$roomId-${since.millisecondsSinceEpoch}',
        roomId: roomId,
        sender: const ChatUser(id: 0, name: ''),
        content: ChatFreeze.thawText(end.difference(since)),
        createdAt: since,
        isSystem: true,
        isLocal: true,
      );
      _messages[roomId] = [...messagesFor(roomId).where((m) => m.id != line.id), line]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    _syncPaused();
    notifyListeners();
  }

  // Hidden rooms are paused too
  void _syncPaused() {
    if (!_ready) return;
    final ids = [
      for (final id in {..._prefs.frozen.keys, ..._prefs.hiddenRooms})
        if (_prefs.roomState(id) != ChatRoomState.live) id,
    ]..sort();
    final changed = !listEquals(ids, _paused) && !(_paused == null && ids.isEmpty);
    _paused = ids;
    if (changed) _source.pause(ids);
  }

  void _setTyping(String roomId, List<ChatUser> users) {
    _typing[roomId] = users.where((u) => u.id != myUserId).toList();
    _typingExpiry[roomId]?.cancel();
    // Torn can miss the "stopped typing" update
    _typingExpiry[roomId] = Timer(_typingTtl, () {
      _typing.remove(roomId);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _apiTimer?.cancel();
    _stallTimer?.cancel();
    _graceTimer?.cancel();
    _sessionRetry?.cancel();
    _subscription.cancel();
    _prefs.removeListener(_onPrefs);
    _alertStream.close();
    _incomingStream.close();
    _goneStream.close();
    _syncTimer?.cancel();
    _countsTimer?.cancel();
    _unreadRetry?.cancel();
    _settleTimer?.cancel();
    _settleCapTimer?.cancel();
    _saveTimer?.cancel();
    _openTimer?.cancel();
    for (final t in [..._typingExpiry.values, ..._sendTimers.values, ..._readTimers.values]) {
      t.cancel();
    }
    sharePending.dispose();
    heldToast.dispose();
    super.dispose();
  }
}
