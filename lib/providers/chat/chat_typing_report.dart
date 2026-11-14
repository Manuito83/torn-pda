/// Typing notices, throttled per room
class ChatTypingReport {
  ChatTypingReport(this._send, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const Duration _gap = Duration(seconds: 3);

  final void Function(String roomId, bool typing) _send;
  final DateTime Function() _now;
  final Map<String, DateTime> _sentAt = {};
  final Set<String> _started = {};

  void typed(String roomId, String text, {required bool allowed}) {
    if (text.isEmpty) return stop(roomId, allowed: allowed);
    if (!allowed) return;
    final last = _sentAt[roomId];
    final now = _now();
    if (last != null && now.difference(last) < _gap) return;
    _sentAt[roomId] = now;
    _started.add(roomId);
    _send(roomId, true);
  }

  /// Only answers a start that went out
  void stop(String roomId, {required bool allowed}) {
    if (!_started.remove(roomId) || !allowed) return;
    _send(roomId, false);
  }

  void clear() {
    _sentAt.clear();
    _started.clear();
  }
}

/// Row text while others type
String? chatTypingLine(List<String> names, {required bool isDm}) {
  if (names.isEmpty) return null;
  if (isDm) return 'typing…';
  return switch (names.length) {
    1 => '${names[0]} is typing…',
    2 => '${names[0]} and ${names[1]} are typing…',
    final n => '${names[0]}, ${names[1]} and ${n - 2} more are typing…',
  };
}
