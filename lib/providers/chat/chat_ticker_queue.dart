import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';

class ChatTickerEntry {
  final ChatAlert alert;
  bool leaving = false;
  bool expanded = false;

  ChatTickerEntry(this.alert);
}

/// Captions on screen, oldest first
class ChatTickerQueue {
  final List<ChatTickerEntry> entries = [];

  /// Expanded ones sit outside the cap
  ChatTickerEntry add(ChatAlert alert, int max) {
    final entry = ChatTickerEntry(alert);
    entries.add(entry);
    final staying = entries.where((e) => !e.leaving && !e.expanded).toList();
    for (var i = 0; i < staying.length - max; i++) {
      staying[i].leaving = true;
    }
    while (entries.where((e) => !e.expanded).length > max * 2) {
      entries.remove(entries.firstWhere((e) => !e.expanded));
    }
    return entry;
  }

  /// One at a time
  void expand(ChatTickerEntry entry) {
    if (entry.leaving || !entries.contains(entry)) return;
    for (final e in entries) {
      e.expanded = e == entry;
    }
  }

  void removeRoom(String roomId) => entries.removeWhere((e) => e.alert.message.roomId == roomId);

  /// Expanded takes the edge slot
  List<ChatTickerEntry> arranged({required bool top}) {
    final pinned = entries.where((e) => e.expanded);
    final others = entries.where((e) => !e.expanded);
    return top ? [...pinned, ...others] : [...others, ...pinned];
  }
}

/// Made up captions for the preview
class ChatTickerDemo extends ChangeNotifier {
  static const Duration _gap = Duration(milliseconds: 450);

  final List<ChatAlert> _waiting = [];
  final List<Timer> _timers = [];
  final StreamController<ChatAlert> _arrived = StreamController.broadcast();
  int _pending = 0;

  /// Kept by the ticker
  int shown = 0;

  /// Fired as each one is painted
  Stream<ChatAlert> get arrived => _arrived.stream;

  bool get busy => _pending > 0 || _waiting.isNotEmpty || shown > 0;

  void launch() {
    final now = DateTime.now();
    ChatAlert sample(String id, String room, String name, String text, {ChatMatch? match}) => ChatAlert(
      ChatMessage(
        id: 'demo:$id',
        roomId: room,
        sender: ChatUser(id: 0, name: name),
        content: text,
        createdAt: now,
        isLocal: true,
      ),
      match,
      demo: true,
    );
    final samples = [
      sample('dm', 'dm:0', 'Alex', 'you around later? need a hand with a chain'),
      sample('faction', 'faction', 'Leslie', 'chain at 45, timer low, anyone free to hit?'),
      sample(
        'global',
        'global',
        'Scrooge',
        'WTB xanax, paying fair price, mail me',
        match: const ChatMatch(mention: true),
      ),
    ];
    for (final (i, alert) in samples.indexed) {
      _pending++;
      _timers.add(
        Timer(_gap * i, () {
          _pending--;
          _waiting.add(alert);
          notifyListeners();
        }),
      );
    }
    notifyListeners();
  }

  List<ChatAlert> take() {
    final out = [..._waiting];
    _waiting.clear();
    return out;
  }

  void announce(ChatAlert alert) => _arrived.add(alert);

  void setShown(int count) {
    if (count == shown) return;
    shown = count;
    notifyListeners();
  }

  static ChatRoom roomOf(String roomId) => roomId.startsWith('dm:')
      ? ChatRoom(
          id: roomId,
          name: 'Alex',
          type: ChatRoomType.dm,
          peer: const ChatUser(id: 0, name: 'Alex'),
        )
      : ChatRoom(id: roomId, name: ChatRooms.labelOf(roomId));

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _arrived.close();
    super.dispose();
  }
}
