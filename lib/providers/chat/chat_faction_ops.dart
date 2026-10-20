import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/profile_api_calls_controller.dart';
import 'package:torn_pda/providers/retals_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/user_helper.dart';

/// Chain and retal lines, local only
class ChatFactionOps {
  ChatFactionOps(this._chat, this._prefs, {this.reportDelay = const Duration(seconds: 15)});

  static const String roomId = 'faction';
  static const String _chainId = 'local-chain-';
  static const String _retalId = 'local-retal-';
  static const String _chainOverId = 'local-chainover-';
  static const String _warOverId = 'local-warover-';

  final ChatController _chat;
  final ChatPrefs _prefs;
  final ChatChainAlarm alarm = ChatChainAlarm();
  final Duration reportDelay;
  int _runHits = 0;
  bool _chainReporting = false;
  bool _warSeen = false;
  bool _warReporting = false;
  List<ChatRetal> _retals = const [];
  Timer? _timer;

  void start() => _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Only what the chain bar already fetched
  static ChatChain? chainOf(ChainStatusController c) {
    final chain = c.chainModel?.chain;
    if (!c.statusActive || c.modelError || chain == null) return null;
    return ChatChain(hits: chain.current ?? 0, seconds: c.currentSecondsCounter, cooldown: (chain.cooldown ?? 0) > 0);
  }

  /// First Chain Watcher level that alerts
  static double? _warningOf(ChainStatusController c) {
    final levels = [
      if (c.orange1Enabled) c.orange1Max,
      if (c.orange2Enabled) c.orange2Max,
      if (c.red1Enabled) c.red1Max,
      if (c.red2Enabled) c.red2Max,
    ];
    return levels.isEmpty ? null : levels.reduce(math.max);
  }

  static ChatWar? warOf(RankedWar? war, int factionId, DateTime now) {
    final info = war?.war;
    final factions = war?.factions;
    if (info?.start == null || factions == null || (info!.end ?? 0) != 0) return null;
    final start = DateTime.fromMillisecondsSinceEpoch(info.start! * 1000);
    final ours = factions['$factionId'];
    final other = factions.entries.where((e) => e.key != '$factionId').firstOrNull;
    final enemy = other?.value;
    if (start.isAfter(now) || ours == null || enemy == null) return null;
    return ChatWar(
      ours: ours.score ?? 0,
      theirs: enemy.score ?? 0,
      enemy: enemy.name ?? 'Enemy',
      start: start,
      target: info.target,
      enemyId: int.tryParse(other!.key),
    );
  }

  void _tick() {
    if (!_prefs.inAppEnabled) return;
    final chain = Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>() : null;
    if (chain != null) alarm.threshold = _warningOf(chain);
    if (Get.isRegistered<ProfileApiCallsController>() && Get.isRegistered<UserController>()) {
      final factionId = UserHelper.factionId;
      watchWar(warOf(Get.find<ProfileApiCallsController>().factionRankedWar, factionId, DateTime.now()), factionId);
    }
    final retals = Get.isRegistered<RetalsController>() ? Get.find<RetalsController>().retaliationList : null;
    apply(
      chain: chain == null ? null : chainOf(chain),
      retals: retals == null
          ? null
          : [
              for (final r in retals)
                if (r.retalId != null && r.name != null)
                  ChatRetal(
                    id: r.retalId!,
                    name: r.name!,
                    expiry: DateTime.fromMillisecondsSinceEpoch(r.retalExpiry * 1000),
                  ),
            ],
      now: DateTime.now(),
    );
  }

  /// Null keeps what is shown
  void apply({ChatChain? chain, List<ChatRetal>? retals, required DateTime now}) {
    if (!_prefs.factionChain || (chain != null && !chain.running)) {
      _chat.replaceLocal(roomId, (m) => m.id.startsWith(_chainId), const []);
    }
    if (_prefs.factionChain && chain != null && alarm.check(chain)) {
      _put(_line('$_chainId${now.millisecondsSinceEpoch}', chatChainLine(chain.seconds), now));
    }

    if (chain != null && chain.alive) {
      _runHits = chain.hits;
    } else if (chain != null) {
      final over = _runHits >= 10;
      _runHits = 0;
      if (over && _prefs.factionChain) _reportChain(now);
    }

    _retals = retals ?? _retals;
    final live = {
      if (_prefs.factionWar)
        for (final r in _retals)
          if (r.expiry.isAfter(now)) r.id: r,
    };
    _chat.replaceLocal(roomId, (m) => m.id.startsWith(_retalId) && !live.containsKey(m.sender.id), const []);
    for (final r in live.values) {
      final id = '$_retalId${r.id}';
      final old = _chat.messagesFor(roomId).where((m) => m.id == id).firstOrNull;
      final text = chatRetalLine(r, now);
      if (old?.content == text) continue;
      _put(_line(id, text, old?.createdAt ?? now, ChatUser(id: r.id, name: r.name)));
    }
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
    try {
      await Future.delayed(reportDelay);
      final wars = await ChatLinkPreviews.queued(() => ChatLinkPreviews.fetchOwnWars(), () => true);
      final last = wars == null ? null : chatLastWar(wars);
      if (last == null || last.$1 == _prefs.lastWarReport) return;
      if (last.$2 * 1000 < now.millisecondsSinceEpoch - 1800000) return;
      final report = await ChatLinkPreviews.queued(() => ChatLinkPreviews.fetchWarReport(last.$1), () => true);
      final line = report == null ? null : chatWarOverLine(report, _chat.myUserId, factionId);
      if (line == null || !_prefs.factionWar) return;
      _prefs.setLastWarReport(last.$1);
      _put(_line('$_warOverId${last.$1}', line, DateTime.now()));
    } finally {
      _warReporting = false;
    }
  }

  Future<void> _reportChain(DateTime endedAt) async {
    if (_chainReporting) return;
    _chainReporting = true;
    try {
      await Future.delayed(reportDelay);
      final json = await ChatLinkPreviews.queued(() => ChatLinkPreviews.fetchOwnChainReport(), () => true);
      final report = json?['chainreport'];
      if (report is! Map || report['id'] is! int || report['id'] == _prefs.lastChainReport) return;
      final end = report['end'];
      if (end is! int || end <= 0 || end * 1000 > DateTime.now().millisecondsSinceEpoch) return;
      if (end * 1000 < endedAt.millisecondsSinceEpoch - 600000) return;
      final bar = Get.isRegistered<ChainStatusController>() ? chainOf(Get.find<ChainStatusController>()) : null;
      if (bar != null && bar.alive) return;
      final line = chatChainOverLine(json!, _chat.myUserId);
      if (line == null || !_prefs.factionChain) return;
      _prefs.setLastChainReport(report['id'] as int);
      _put(_line('$_chainOverId${report['id']}', line, DateTime.now()));
    } finally {
      _chainReporting = false;
    }
  }

  void _put(ChatMessage line) => _chat.replaceLocal(roomId, (m) => m.id == line.id, [line]);

  ChatMessage _line(String id, String text, DateTime at, [ChatUser sender = const ChatUser(id: 0, name: '')]) =>
      ChatMessage(id: id, roomId: roomId, sender: sender, content: text, createdAt: at, isSystem: true, isLocal: true);
}
