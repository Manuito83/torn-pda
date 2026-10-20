import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';

/// Only while the faction room is open
class ChatFactionEvents {
  ChatFactionEvents(this._chat, this._prefs, {Future<Object?> Function()? fetch, DateTime Function()? clock})
    : _fetch = fetch ?? ApiCallsV2.getOwnFactionNews_v2,
      _clock = clock ?? DateTime.now;

  static const String roomId = 'faction';
  static const Duration every = Duration(minutes: 10);

  final ChatController _chat;
  final ChatPrefs _prefs;
  final Future<Object?> Function() _fetch;
  final DateTime Function() _clock;
  List<ChatMessage> _events = const [];
  DateTime? _asked;
  DateTime? _oldest;
  bool _loading = false;
  Timer? _timer;
  int? _userId;

  void start() {
    _chat.addListener(sync);
    _prefs.addListener(sync);
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => sync());
  }

  void stop() {
    _chat.removeListener(sync);
    _prefs.removeListener(sync);
    _timer?.cancel();
    _timer = null;
  }

  void sync() {
    if (_chat.myUserId != _userId) {
      _userId = _chat.myUserId;
      _events = const [];
      _asked = null;
      _oldest = null;
    }
    if (!_prefs.inAppEnabled || !_prefs.factionEvents || _prefs.factionEventsDenied) {
      _asked = null;
      if (_events.isNotEmpty) {
        _events = const [];
        _chat.replaceLocal(roomId, isChatFactionEvent, const []);
      }
      return;
    }
    final state = WidgetsBinding.instance.lifecycleState;
    if (_chat.currentRoomId != roomId || state == AppLifecycleState.paused || state == AppLifecycleState.hidden) return;
    final now = _clock();
    if (!_loading && (_asked == null || now.difference(_asked!) >= every)) {
      _load(now);
    } else if (_events.isNotEmpty && _oldestReal() != _oldest) {
      _place();
    }
  }

  DateTime? _oldestReal() => _chat.messagesFor(roomId).where((m) => !m.isLocal).firstOrNull?.createdAt;

  Future<void> _load(DateTime now) async {
    _loading = true;
    _asked = now;
    final owner = _userId;
    try {
      final response = await _fetch();
      if (owner != _userId) return;
      if (response is ApiError) {
        if (chatFactionEventsDenied(response.errorId)) _prefs.denyFactionEvents();
        return;
      }
      if (response is! FactionNewsResponse || !_prefs.factionEvents) return;
      _events = chatFactionEvents(response.news, now: _clock(), myName: _chat.myName);
      _place();
    } finally {
      _loading = false;
    }
  }

  /// Nothing older than the history on screen
  void _place() {
    _oldest = _oldestReal();
    _chat.replaceLocal(roomId, isChatFactionEvent, [
      for (final e in _events)
        if (_oldest == null || !e.createdAt.isBefore(_oldest!)) e,
    ]);
  }
}
