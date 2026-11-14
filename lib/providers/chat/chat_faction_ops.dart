import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:torn_pda/models/chaining/retal_model.dart';
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_retal.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/profile_api_calls_controller.dart';
import 'package:torn_pda/providers/retals_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/app_lifecycle.dart';
import 'package:torn_pda/utils/chat_notifications.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';

enum ChatWatchSend { sent, watcherOn, watcherOff, tooSoon, nothing }

/// Chain and retal lines, local only
class ChatFactionOps {
  ChatFactionOps(
    this._chat,
    this._prefs, {
    this.reportDelay = const Duration(seconds: 15),
    this.launch,
    this.offer,
    this.known,
    this.watchAlarm = setChatWatchAlarm,
    this.clock = chatTctText,
  });

  static const String roomId = 'faction';
  static const String _chainOverId = 'local-chainover-';
  static const String _warOverId = 'local-warover-';
  static const Duration _lateBy = Duration(seconds: 3);
  static const Duration _offerFor = Duration(seconds: 10);
  static const int _missedKept = 20;
  static const Duration watchGap = Duration(seconds: 60);
  static const Duration retalEvery = Duration(seconds: 30);
  static const Duration _retalTabEvery = Duration(seconds: 20);

  final ChatController _chat;
  final ChatPrefs _prefs;

  ChatController get chat => _chat;
  final ChatChainAlarm alarm = ChatChainAlarm();
  final Duration reportDelay;

  /// Opens the attack page
  final Future<void> Function(int id)? launch;

  /// Asks before leaving another screen
  final void Function(ChatHitJoin join)? offer;

  /// Targets and war members
  final List<ChatHitTarget> Function()? known;

  final Future<void> Function(ChatWatcher? mine, String roomId, String until) watchAlarm;

  /// App clock for local lines
  final String Function(DateTime at) clock;

  final ValueNotifier<ChatHitJoin?> joined = ValueNotifier(null);

  /// Calls this player missed, by call message
  final Map<String, ChatHitJoin> _missed = {};
  bool sheetOpen = false;
  int _runHits = 0;
  bool _chainReporting = false;

  /// The cooldown's chain report
  final ValueNotifier<ChatReportView?> chainReport = ValueNotifier(null);
  (int, int)? _reportKey;
  DateTime? _cooldownFrom;
  bool _readingReport = false;
  Future<Map<String, dynamic>?>? _reportCall;

  /// Late answers from a forgotten account drop
  int _generation = 0;
  bool _warSeen = false;
  bool _warReporting = false;
  List<ChatRetal> _retals = const [];

  /// No faction access on this key
  final ValueNotifier<bool> retalDenied = ValueNotifier(false);
  final ValueNotifier<Set<String>> retalShared = ValueNotifier(const {});

  /// Watched retals not swiped away
  final ValueNotifier<int> retalsLive = ValueNotifier(0);
  final Set<String> _retalsGone = {};
  int? _retalOwner;
  bool _retalFetching = false;
  DateTime? _retalFetchedAt;
  int _retalTabs = 0;
  bool _retalTabDenied = false;

  /// Retals tab answer, null while checking
  final ValueNotifier<bool?> retalTabFailed = ValueNotifier(null);
  bool _ffsFirst = false;
  int _ffsOverSpyMonths = 0;
  final Set<String> _lineRooms = {};
  Timer? _timer;

  /// Chain watch by faction room
  final ValueNotifier<Map<String, ChatWatchRoom>> watch = ValueNotifier(const {});
  final Map<String, (List<ChatMessage>, DateTime?, bool)> _watchFrom = {};
  final Map<String, DateTime> _cooldownSeen = {};
  final Map<String, DateTime?> _watchSince = {};
  int? _watchOwner;
  final Map<ChatWatchKind, DateTime> _watchSentAt = {};
  bool _watcherByWatch = false;
  (String, DateTime, String)? _alarmSet;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(_loadStatsOrder().catchError((_) {}));
  }

  Future<void> _loadStatsOrder() async {
    _ffsFirst = await Prefs().getPreferFFScouterOverEstimated() && await Prefs().getFFScouterEnabledStatus() == 1;
    _ffsOverSpyMonths = await Prefs().getFfsOverrideSpyMonths();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    joined.value = null;
    _dropAlarm();
    if (Get.isRegistered<ChainStatusController>()) Get.find<ChainStatusController>().chatInView(false);
  }

  /// Next account starts clean
  void forget() {
    _generation++;
    _reportCall = null;
    _reportKey = null;
    _cooldownFrom = null;
    chainReport.value = null;
    _chainReporting = false;
    _warReporting = false;
    _readingReport = false;
    dropJoin();
    _missed.clear();
    _retalsGone.clear();
    retalShared.value = const {};
    _lineRooms.clear();
    _watchFrom.clear();
    _cooldownSeen.clear();
    _watchSince.clear();
    _watchSentAt.clear();
    _runHits = 0;
    _warSeen = false;
  }

  /// Chat only, gone when the app closes
  final ValueNotifier<ChatChain?> simulated = ValueNotifier(null);
  bool simulatedLive = false;

  /// The Testing page's chain, also while off
  ChatChain testChain = const ChatChain(hits: 120, seconds: 150, bonus: 250);
  Timer? _countdown;

  void simulate(ChatChain? chain, {bool live = false}) {
    _countdown?.cancel();
    _countdown = null;
    simulatedLive = live;
    simulated.value = chain;
    if (chain == null || chain.seconds <= 0) return;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = chain.seconds - timer.tick;
      if (left <= 0) timer.cancel();
      simulated.value = left > 0
          ? ChatChain(hits: chain.hits, seconds: left, cooldown: chain.cooldown, bonus: chain.bonus)
          : const ChatChain(hits: 0, seconds: 0);
    });
  }

  ChatChain? chainOf(ChainStatusController? c) => simulated.value ?? chatBarChain(c);

  /// First Chain Watcher level that alerts
  double? _warningOf(ChainStatusController c) {
    final levels = [
      if (c.orange1Enabled) c.orange1Max,
      if (c.orange2Enabled) c.orange2Max,
      if (c.red1Enabled) c.red1Max,
      if (c.red2Enabled) c.red2Max,
    ];
    return levels.isEmpty ? null : levels.reduce(math.max);
  }

  /// The room, or the list with its row
  @visibleForTesting
  bool get factionInView =>
      _prefs.factionRooms.any(_chat.isOnScreen) ||
      (_chat.inboxShown &&
          _chat.currentRoomId == null &&
          !_prefs.hiddenRooms.contains(roomId) &&
          _chat.conversations.any((r) => r.id == roomId));

  void _tick() {
    final chain = Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>() : null;
    chain?.chatInView(_prefs.inAppEnabled && _prefs.factionChain && factionInView && !appInBackground());
    if (!_prefs.inAppEnabled) {
      _dropAlarm();
      return;
    }
    if (chain != null) alarm.threshold = _warningOf(chain);
    if (!(chain?.watcherActive ?? false)) _watcherByWatch = false;
    if (!_prefs.testingFor(_chat.myUserId) && (_prefs.testFactionRoom != null || simulated.value != null)) {
      _prefs.setTestFactionRoom(null);
      simulate(null);
    }
    if (Get.isRegistered<ProfileApiCallsController>() && Get.isRegistered<UserController>()) {
      final factionId = UserHelper.factionId;
      watchWar(warOf(Get.find<ProfileApiCallsController>().factionRankedWar, factionId, DateTime.now()), factionId);
    }
    final now = DateTime.now();
    _watchRetals(now);
    final retals = Get.isRegistered<RetalsController>() ? Get.find<RetalsController>().retaliationList : null;
    apply(
      chain: chainOf(chain),
      realChain: chatBarChain(chain),
      chainStart: chain?.chainModel?.chain?.start ?? 0,
      reportShown: !appInBackground() && (sheetOpen || _prefs.factionRooms.any(_chat.isOnScreen)),
      retals: retals == null
          ? null
          : [
              for (final r in retals)
                if (r.retalId != null && r.name != null) _retalOf(r, now),
            ],
      now: now,
      inFront: !appInBackground(),
      factionShown: _chat.isOnScreen(joined.value?.roomId ?? roomId) || sheetOpen,
    );
  }

  List<ChatHitTarget> get knownTargets => known?.call() ?? const [];

  /// One armed at a time
  void _letGo(DateTime now, {String? keep}) {
    final old = joined.value;
    if (old == null || old.own || !old.pending || old.messageId == keep) return;
    if (now.difference(old.at) > _lateBy) return;
    _chat.send(chatJoinText(old.name, joining: false), to: old.roomId);
  }

  void join(String messageId, ChatHitCall call, int id, {String room = roomId, DateTime? now}) {
    final at = now ?? DateTime.now();
    _letGo(at, keep: messageId);
    joined.value = ChatHitJoin.arm(messageId: messageId, roomId: room, id: id, name: call.name, at: call.at, now: at);
    _chat.send(chatJoinText(call.name), to: room);
    StatsController.chat.count('hit_join');
  }

  void callHit(ChatHitTarget target, int seconds, {required String room, bool link = false, DateTime? now}) {
    final sentAt = now ?? DateTime.now();
    final text = chatHitCallText(target.name, seconds, sentAt, id: link ? target.id : null);
    _letGo(sentAt);
    _chat.send(text, to: room);
    StatsController.chat.count('hit_call');
    final sent = _chat.messagesFor(room).lastOrNull;
    joined.value = sent == null || sent.content != text
        ? null
        : ChatHitJoin.arm(
            messageId: sent.id,
            roomId: room,
            id: target.id,
            name: target.name,
            at: sentAt.add(Duration(seconds: seconds)),
            now: sentAt,
            own: true,
          );
  }

  /// Says not joining, except on own calls
  void cancelJoin() {
    final join = joined.value;
    joined.value = null;
    if (join != null && !join.own && join.pending) _chat.send(chatJoinText(join.name, joining: false), to: join.roomId);
  }

  void disarm() {
    final join = joined.value;
    if (join?.state == ChatHitJoinState.armed) joined.value = join!.copyWith(state: ChatHitJoinState.disarmed);
  }

  /// The card's Attack button
  void attackNow() {
    final join = joined.value;
    if (join == null || !join.pending || launch == null) return;
    joined.value = join.copyWith(state: ChatHitJoinState.launched);
    unawaited(launch!(join.id));
  }

  /// Attacking by hand, quietly
  void dropJoin() => joined.value = null;

  /// Live or missed join for [m]
  ChatHitJoin? joinFor(ChatMessage m) {
    final live = joined.value;
    if (live != null && live.isFor(m)) return live;
    return _missed[m.id] ?? _missed[m.reqId];
  }

  /// The toast button
  void takeOffer() {
    final join = joined.value;
    if (join == null || join.state != ChatHitJoinState.offered || launch == null) return;
    joined.value = join.copyWith(state: ChatHitJoinState.launched);
    unawaited(launch!(join.id));
  }

  List<ChatUser> joinersOf(ChatMessage call, ChatHitCall hit) =>
      chatJoinersOf(call, hit, _chat.messagesFor(call.roomId));

  /// Null keeps what is shown
  void apply({
    ChatChain? chain,
    // The faction room's own while simulating
    ChatChain? realChain,
    List<ChatRetal>? retals,
    required DateTime now,
    bool inFront = true,
    bool factionShown = true,
    int chainStart = 0,
    bool reportShown = true,
  }) {
    final rooms = _prefs.factionRooms;
    for (final gone in _lineRooms.difference(rooms)) {
      _chat.replaceLocal(
        gone,
        (m) =>
            m.id.startsWith(chatChainLinePrefix) ||
            m.id.startsWith(chatWatchLinePrefix) ||
            m.id.startsWith(chatRetalLinePrefix),
        const [],
      );
    }
    _lineRooms
      ..clear()
      ..addAll(rooms);
    for (final room in rooms) {
      _placeChainLine(room, chain, now);
    }
    _updateWatch(chain, simulated.value == null ? chain : realChain, now);
    _fireJoin(now, inFront: inFront, factionShown: factionShown);

    if (chain != null && chain.alive) {
      // A simulated run never reports
      _runHits = simulated.value == null ? chain.hits : 0;
    } else if (chain != null) {
      final over = _runHits >= 10;
      _runHits = 0;
      if (over && _prefs.factionChain) _reportChain(now);
    }
    _followReport(chain, start: chainStart, now: now, shown: reportShown);

    _retals = retals ?? _retals;
    _placeRetals(now);
  }

  void _placeRetals(DateTime now) {
    final live = {
      for (final r in _retals)
        if (r.expiry.isAfter(now)) chatRetalLineId(r): r,
    };
    _retalsGone.retainWhere(live.containsKey);
    live.removeWhere((id, _) => !_prefs.watchRetals || _retalsGone.contains(id));
    retalsLive.value = live.length;
    for (final room in _prefs.factionRooms) {
      _placeRetalLines(room, live, now);
    }
  }

  void _placeRetalLines(String room, Map<String, ChatRetal> live, DateTime now) {
    bool retalLine(ChatMessage m) => m.id.startsWith(chatRetalLinePrefix);
    final old = {for (final m in _chat.messagesFor(room).where(retalLine)) m.id: m};
    final lines = [
      for (final MapEntry(key: id, value: r) in live.entries)
        _line(
          id,
          chatRetalLine(r),
          old[id]?.createdAt ?? now,
          sender: ChatUser(id: r.id, name: r.name),
          room: room,
        ),
    ];
    if (lines.length == old.length && lines.every((l) => old[l.id]?.content == l.content)) return;
    _chat.replaceLocal(room, retalLine, lines);
  }

  /// The sheet's Retals tab asks more often
  void retalTab(bool open) {
    _retalTabs = math.max(0, _retalTabs + (open ? 1 : -1));
    if (!open || _retalTabs > 1) return;
    _retalTabDenied = false;
    retalTabFailed.value = null;
    // One in flight answers the tab
    if (!_retalFetching) _retalFetchedAt = null;
    _watchRetals(DateTime.now());
  }

  /// While faction room or Retals tab shows
  void _watchRetals(DateTime now) {
    final me = _chat.myUserId;
    if (me != _retalOwner) {
      _retalOwner = me;
      retalDenied.value = false;
    }
    if (_retalFetching || appInBackground() || ChatLinkPreviews.busy) return;
    final tab = _retalTabs > 0;
    if (tab && _retalTabDenied) return;
    if (!tab && (!_prefs.watchRetals || retalDenied.value || !_prefs.factionRooms.any(_chat.isOnScreen))) return;
    final last = _retalFetchedAt;
    if (last != null && now.difference(last) < (tab ? _retalTabEvery : retalEvery)) return;
    final retals = Get.isRegistered<RetalsController>() ? Get.find<RetalsController>() : Get.put(RetalsController());
    if (retals.sectionVisible || (tab && retals.updating)) return;
    _retalFetchedAt = now;
    unawaited(_fetchRetals(retals, tab: tab));
  }

  Future<void> _fetchRetals(RetalsController retals, {required bool tab}) async {
    _retalFetching = true;
    var error = 'failed';
    try {
      await _loadStatsOrder().catchError((_) {});
      error = await retals.retrieveQuietly();
    } catch (_) {
      // Next round tries again
    } finally {
      _retalFetching = false;
    }
    if (_retalTabs > 0) retalTabFailed.value = error.isNotEmpty;
    // No faction access, asking again won't help
    if (!error.contains('incorrect ID-entity relation')) return;
    if (tab) {
      _retalTabDenied = true;
      return;
    }
    retalDenied.value = true;
    _prefs.setWatchRetals(false);
  }

  void setRetalWatch(bool on) {
    _prefs.setWatchRetals(on);
    if (_retalTabs == 0) _retalFetchedAt = null;
    if (on) StatsController.chat.count('retal_watch');
  }

  ChatRetal _retalOf(Retal r, DateTime now) {
    final cache = Get.isRegistered<FFScouterCacheController>() ? Get.find<FFScouterCacheController>() : null;
    final ffs = _ffsFirst ? cache?.get(r.retalId!) : null;
    final spyTotal = r.statsExactTotal ?? -1;
    final spyAt = r.statsExactUpdated ?? 0;
    return ChatRetal(
      id: r.retalId!,
      name: r.name!,
      expiry: DateTime.fromMillisecondsSinceEpoch(r.retalExpiry * 1000),
      stats: chatRetalStats(
        spy: spyTotal != -1 ? math.max(spyTotal, r.statsExactTotalKnown) : r.statsExactTotalKnown,
        spyAt: spyAt > 0 ? DateTime.fromMillisecondsSinceEpoch(spyAt * 1000) : null,
        ffs: ffs?.bsEstimate == null ? null : ffs!.displayText,
        estimated: r.statsEstimated == 'unk' ? '' : r.statsEstimated,
        ffsOverSpyMonths: _ffsOverSpyMonths,
        now: now,
      ),
    );
  }

  ChatRetal? retalOf(String lineId) => _retals.where((r) => chatRetalLineId(r) == lineId).firstOrNull;

  /// Only here, until it ends
  void dismissRetal(String lineId, {DateTime? now}) {
    _retalsGone.add(lineId);
    _placeRetals(now ?? DateTime.now());
  }

  /// Once per retal, to the faction room
  bool shareRetal(String room, String lineId, {DateTime? now}) {
    final retal = retalOf(lineId);
    if (retal == null || !retal.expiry.isAfter(now ?? DateTime.now()) || retalShared.value.contains(lineId)) {
      return false;
    }
    _chat.send(chatRetalCallText(retal), to: room);
    StatsController.chat.count('retal_share');
    retalShared.value = {...retalShared.value.where((id) => _retals.any((r) => chatRetalLineId(r) == id)), lineId};
    return true;
  }

  void _placeChainLine(String room, ChatChain? chain, DateTime now) {
    bool chainLine(ChatMessage m) => m.id.startsWith(chatChainLinePrefix);
    final old = _chat.messagesFor(room).where(chainLine).firstOrNull;
    final oldAt = old == null ? null : chatChainLineAt(old.id);
    if (chain == null) {
      // No data: drop the line once stale
      if (oldAt != null && now.difference(oldAt) > const Duration(seconds: 5)) {
        _chat.replaceLocal(room, chainLine, const []);
      }
      return;
    }
    if (!_prefs.factionChain || !alarm.under(chain)) {
      _chat.replaceLocal(room, chainLine, const []);
      return;
    }
    final at = now.add(Duration(seconds: chain.seconds));
    if (oldAt != null && oldAt.difference(at).abs() <= const Duration(seconds: 2)) return;
    _chat.replaceLocal(room, chainLine, [
      _line(chatChainLineId(at), chatChainLine(chain.seconds), old?.createdAt ?? now, room: room),
    ]);
  }

  void _updateWatch(ChatChain? chain, ChatChain? real, DateTime now) {
    final me = _chat.myUserId;
    if (me != _watchOwner) {
      _watchOwner = me;
      _watcherByWatch = false;
    }
    final rooms = <String, ChatWatchRoom>{};
    final atRisk = <String, bool>{};
    for (final room in _prefs.factionRooms) {
      final roomChain = room == roomId ? real : chain;
      final cooldown = roomChain?.cooldown ?? false;
      if (cooldown) {
        _cooldownSeen[room] = now;
      } else {
        // From the last cooldown's end
        _watchSince[room] = _cooldownSeen[room];
      }
      rooms[room] = (state: _watchStateOf(room, cooldown, now), short: _chat.watchHistoryShort(room));
      atRisk[room] = roomChain != null && roomChain.running && roomChain.hits >= 10;
    }
    for (final kept in [_watchFrom, _watchSince, _cooldownSeen]) {
      kept.removeWhere((room, _) => !rooms.containsKey(room));
    }
    final old = watch.value;
    if (rooms.length != old.length || rooms.entries.any((e) => e.value != old[e.key])) watch.value = rooms;

    (String, ChatWatcher)? mine;
    for (final MapEntry(key: room, value: (:state, short: _)) in rooms.entries) {
      final notes = _prefs.factionChain
          ? chatWatchNotes(state, me, now, atRisk: atRisk[room]!, clock: clock)
          : const <ChatWatchNote>[];
      _placeWatchLines(room, notes);
      if (state.of(me) case final w? when mine == null) mine = (room, w);
    }
    _setAlarm(mine?.$2, mine?.$1);
  }

  /// Recounted when messages, chain or clock change
  ChatWatchState _watchStateOf(String room, bool cooldown, DateTime now) {
    final messages = _chat.messagesFor(room);
    final since = _watchSince[room];
    final kept = watch.value[room]?.state;
    final from = _watchFrom[room];
    final next = kept?.next;
    _watchFrom[room] = (messages, since, cooldown);
    if (kept != null &&
        from != null &&
        identical(from.$1, messages) &&
        from.$2 == since &&
        from.$3 == cooldown &&
        (next == null || now.isBefore(next))) {
      return kept;
    }
    return chatWatchStateOf(messages, now, since: since, cooldown: cooldown);
  }

  void _placeWatchLines(String room, List<ChatWatchNote> notes) {
    bool watchLine(ChatMessage m) => m.id.startsWith(chatWatchLinePrefix);
    final old = {for (final m in _chat.messagesFor(room).where(watchLine)) m.id: m};
    ChatMessage toLine(ChatWatchNote n) {
      final id = chatWatchLineId(n.kind, n.player?.id ?? 0);
      final sender = n.player ?? const ChatUser(id: 0, name: '');
      return _line(id, n.text, old[id]?.createdAt ?? n.at, sender: sender, room: room);
    }

    final lines = notes.map(toLine).toList();
    if (lines.length == old.length && lines.every((l) => old[l.id]?.content == l.content)) return;
    _chat.replaceLocal(room, watchLine, lines);
  }

  void _dropAlarm() {
    if (_alarmSet == null) return;
    _alarmSet = null;
    unawaited(watchAlarm(null, roomId, '').catchError((_) {}));
  }

  void _setAlarm(ChatWatcher? mine, String? room) {
    final key = mine == null || room == null ? null : (room, mine.until, mine.messageId);
    if (key == _alarmSet) return;
    _alarmSet = key;
    final until = mine == null ? '' : clock(mine.until);
    unawaited(watchAlarm(mine, room ?? roomId, until).catchError((_) {}));
  }

  ChatWatcher? myWatch(String room) => watch.value[room]?.state.of(_chat.myUserId);

  ChainStatusController? get _chainBar =>
      Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>() : null;

  /// One every [watchGap], nothing if unchanged
  ChatWatchSend takeWatch(String room, DateTime until, {DateTime? now}) {
    final text = chatWatchText(until);
    final mine = myWatch(room);
    if (mine != null && chatWatchText(mine.until) == text) return ChatWatchSend.nothing;
    if (!_sendWatch(room, ChatWatchKind.watching, text, now ?? DateTime.now())) return ChatWatchSend.tooSoon;
    StatsController.chat.count('watch_take');
    final bar = _chainBar;
    if (!_prefs.watchTurnsOnWatcher || bar == null || bar.watcherActive) return ChatWatchSend.sent;
    bar.activateWatcher(fromChat: true);
    _watcherByWatch = true;
    return ChatWatchSend.watcherOn;
  }

  /// Also after a cooldown closed it
  ChatWatchSend leaveWatch(String room, {DateTime? now}) {
    final state = watch.value[room]?.state;
    final me = _chat.myUserId;
    if (myWatch(room) == null && !(state?.closed.any((w) => w.user.id == me) ?? false)) return ChatWatchSend.nothing;
    if (!_sendWatch(room, ChatWatchKind.done, chatWatchLeaveText, now ?? DateTime.now())) return ChatWatchSend.tooSoon;
    final bar = _chainBar;
    final ours = _watcherByWatch;
    _watcherByWatch = false;
    // Panic needs the Watcher, both stay
    if (!ours || bar == null || !bar.watcherActive || bar.panicModeActive) return ChatWatchSend.sent;
    bar.deactivateWatcher();
    return ChatWatchSend.watcherOff;
  }

  /// Null [within] asks from now
  ChatWatchSend askRelief(String room, Duration? within, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final text = chatReliefText(within == null ? null : at.add(within));
    final open = watch.value[room]?.state.reliefs.where((r) => r.user.id == _chat.myUserId).firstOrNull;
    if (open != null && chatReliefText(open.from) == text) return ChatWatchSend.nothing;
    return _sendWatch(room, ChatWatchKind.relief, text, at) ? ChatWatchSend.sent : ChatWatchSend.tooSoon;
  }

  /// One of each kind every [watchGap]
  bool _sendWatch(String room, ChatWatchKind kind, String text, DateTime now) {
    final last = _watchSentAt[kind];
    if (last != null && now.difference(last).abs() < watchGap) return false;
    _watchSentAt[kind] = now;
    _chat.send(text, to: room);
    return true;
  }

  /// Own call on the server clock, like everyone's
  ChatHitJoin? _followOwnCall(ChatHitJoin? join) {
    if (join == null || !join.own || !join.pending) return join;
    final sent = _chat.messagesFor(join.roomId).where((m) => join.isFor(m) && m.state == ChatMessageState.sent);
    final call = sent.isEmpty ? null : chatHitCallOf(sent.last.content, sent.last.createdAt);
    if (call == null || call.at == join.at) return join;
    return joined.value = join.copyWith(at: call.at, opens: join.opens.add(call.at.difference(join.at)));
  }

  void _fireJoin(DateTime now, {required bool inFront, required bool factionShown}) {
    final join = _followOwnCall(joined.value);
    if (join == null || join.opens.isAfter(now)) return;
    if (join.state == ChatHitJoinState.disarmed && now.difference(join.at) > _lateBy) {
      joined.value = null;
      return;
    }
    final late = now.difference(join.opens);
    switch (join.state) {
      case ChatHitJoinState.armed when !inFront || launch == null || late > _lateBy:
        _miss(join);
      case ChatHitJoinState.armed when factionShown || offer == null:
        joined.value = join.copyWith(state: ChatHitJoinState.launched);
        unawaited(launch!(join.id));
      case ChatHitJoinState.armed:
        joined.value = join.copyWith(state: ChatHitJoinState.offered);
        offer!(join);
      case ChatHitJoinState.offered when late > _offerFor:
        _miss(join);
      case ChatHitJoinState.disarmed ||
          ChatHitJoinState.offered ||
          ChatHitJoinState.launched ||
          ChatHitJoinState.missed:
        return;
    }
  }

  void _miss(ChatHitJoin join) {
    final missed = join.copyWith(state: ChatHitJoinState.missed);
    _missed[join.messageId] = missed;
    if (_missed.length > _missedKept) _missed.remove(_missed.keys.first);
    joined.value = missed;
  }

  void watchWar(ChatWar? war, int factionId, [DateTime? now]) {
    if (war != null) {
      _warSeen = true;
    } else if (_warSeen) {
      _warSeen = false;
      if (_prefs.factionWar) _reportWar(factionId, now ?? DateTime.now());
    }
  }

  Future<void> _reportWar(int factionId, DateTime now) async {
    if (_warReporting) return;
    _warReporting = true;
    final gen = _generation;
    try {
      await Future.delayed(reportDelay);
      if (gen != _generation) return;
      final wars = await ChatLinkPreviews.queued(() => ChatLinkPreviews.fetchOwnWars(), () => true);
      final last = wars == null || gen != _generation ? null : chatLastWar(wars);
      if (last == null || last.$1 == _prefs.lastWarReport) return;
      if (last.$2 * 1000 < now.millisecondsSinceEpoch - 1800000) return;
      final report = await ChatLinkPreviews.queued(() => ChatLinkPreviews.fetchWarReport(last.$1), () => true);
      final line = report == null ? null : chatWarOverLine(report, _chat.myUserId, factionId);
      if (line == null || !_prefs.factionWar || gen != _generation) return;
      _prefs.setLastWarReport(last.$1);
      _put(_line('$_warOverId${last.$1}', line, DateTime.now()));
    } finally {
      if (gen == _generation) _warReporting = false;
    }
  }

  Future<void> _reportChain(DateTime endedAt) async {
    if (_chainReporting) return;
    _chainReporting = true;
    final gen = _generation;
    try {
      await Future.delayed(reportDelay);
      if (gen != _generation) return;
      final json = await _ownReport();
      if (gen != _generation) return;
      final report = _takeReport(json, DateTime.now());
      if (report == null || report.id == _prefs.lastChainReport) return;
      if (report.end <= 0 || report.end * 1000 > DateTime.now().millisecondsSinceEpoch) return;
      if (report.end * 1000 < endedAt.millisecondsSinceEpoch - 600000) return;
      final bar = Get.isRegistered<ChainStatusController>() ? chainOf(Get.find<ChainStatusController>()) : null;
      if (bar != null && bar.alive) return;
      if (!_prefs.factionChain) return;
      _prefs.setLastChainReport(report.id);
      _put(_line('$_chainOverId${report.id}', chatChainOverLine(report, _chat.myUserId), DateTime.now()));
    } finally {
      if (gen == _generation) _chainReporting = false;
    }
  }

  /// Shared with the chain over line
  Future<Map<String, dynamic>?> _ownReport() {
    final gen = _generation;
    return _reportCall ??= ChatLinkPreviews.queued(() => ChatLinkPreviews.fetchOwnChainReport(), () => true)
        .whenComplete(() {
          if (gen == _generation) _reportCall = null;
        });
  }

  /// Only while the room or sheet is shown
  void _followReport(ChatChain? chain, {required int start, required DateTime now, required bool shown}) {
    if (chain == null) return;
    if (!chain.cooldown || !_prefs.factionChain) {
      _reportKey = null;
      chainReport.value = null;
      return;
    }
    final simulating = simulated.value != null;
    final key = simulating ? (0, 0) : (start, chain.hits);
    if (key != _reportKey || chainReport.value == null) {
      _reportKey = key;
      _cooldownFrom = now;
      chainReport.value = ChatReportView(ChatReportStatus.waiting, next: now);
      if (!simulating) unawaited(_readSavedReport(key, now));
    }
    final view = chainReport.value!;
    final next = view.next;
    if (!shown || view.status == ChatReportStatus.ready || next == null || now.isBefore(next)) return;
    if (view.checking || _chainReporting || _readingReport) return;
    unawaited(checkChainReport(now: now));
  }

  /// The sheet's Check now and Retry
  Future<void> checkChainReport({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final view = chainReport.value;
    if (view == null || view.status == ChatReportStatus.ready || view.checking) return;
    final asked = view.askedAt;
    if (asked != null && at.difference(asked) < chatReportCheckGap) return;
    chainReport.value = view.checkingNow(at);
    final gen = _generation;
    final json = await _ownReport();
    if (gen == _generation) _takeReport(json, now ?? DateTime.now());
  }

  /// Returns the report whatever the sheet shows
  ChatChainReport? _takeReport(Map<String, dynamic>? json, DateTime now) {
    final report = ChatChainReport.parse(json?['chainreport']);
    final key = _reportKey;
    if (key == null || chainReport.value?.status == ChatReportStatus.ready) return report;
    final error = json?['error'];
    if (json == null || error is Map) {
      final code = error is Map && error['code'] is int ? error['code'] as int : null;
      chainReport.value = ChatReportView(
        ChatReportStatus.failed,
        next: chatReportKeyError(code) ? null : now.add(const Duration(seconds: 60)),
        reason: error is Map ? chatReportReason(code, '${error['error'] ?? ''}') : null,
        askedAt: now,
      );
      return report;
    }
    // Simulation shows the latest as is
    final simulating = simulated.value != null;
    if (report != null && (simulating || report.isFor(start: key.$1, hits: key.$2, now: now))) {
      chainReport.value = ChatReportView(ChatReportStatus.ready, report: report, askedAt: now);
      if (!simulating) unawaited(_saveReport(report));
      return report;
    }
    final wait = chatChainReportWait(now.difference(_cooldownFrom ?? now));
    chainReport.value = ChatReportView(ChatReportStatus.waiting, next: now.add(wait), askedAt: now);
    return report;
  }

  Future<File> _reportFile() async {
    final faction = Get.isRegistered<UserController>() ? UserHelper.factionId : 0;
    return File('${(await getApplicationSupportDirectory()).path}/chat_chain_report_$faction.json');
  }

  Future<void> _readSavedReport((int, int) key, DateTime now) async {
    _readingReport = true;
    final gen = _generation;
    try {
      final file = await _reportFile();
      if (!await file.exists()) return;
      final report = ChatChainReport.parse(jsonDecode(await file.readAsString()));
      if (gen != _generation || key != _reportKey || report == null) return;
      if (!report.isFor(start: key.$1, hits: key.$2, now: now)) return;
      chainReport.value = ChatReportView(ChatReportStatus.ready, report: report);
    } catch (_) {
    } finally {
      if (gen == _generation) _readingReport = false;
    }
  }

  Future<void> _saveReport(ChatChainReport report) async {
    final gen = _generation;
    try {
      final file = await _reportFile();
      if (gen == _generation) await file.writeAsString(jsonEncode(report.json), flush: true);
    } catch (_) {}
  }

  void _put(ChatMessage line) => _chat.replaceLocal(roomId, (m) => m.id == line.id, [line]);

  ChatMessage _line(
    String id,
    String text,
    DateTime at, {
    ChatUser sender = const ChatUser(id: 0, name: ''),
    String room = roomId,
  }) => ChatMessage(id: id, roomId: room, sender: sender, content: text, createdAt: at, isSystem: true, isLocal: true);
}

/// Only what the chain bar already fetched
ChatChain? chatBarChain(ChainStatusController? c) {
  if (c == null) return null;
  final chain = c.chainModel?.chain;
  if (!(c.statusActive || c.webLive) || c.modelError || chain == null) return null;
  if (c.chainStale && !c.webLive) return null;
  return ChatChain(
    hits: chain.current ?? 0,
    seconds: c.currentSecondsCounter,
    cooldown: (chain.cooldown ?? 0) > 0,
    bonus: chain.max,
  );
}
