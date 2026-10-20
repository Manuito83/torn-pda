class ChatShortcuts {
  ChatShortcuts._();

  static const Duration window = Duration(days: 7);
  static const Duration _debounce = Duration(minutes: 5);
  static const int _maxEntries = 300;
  static const int _count = 3;

  static int? _ms(String entry) => int.tryParse(entry.substring(entry.lastIndexOf('|') + 1));

  static String _room(String entry) => entry.substring(0, entry.lastIndexOf('|'));

  /// Entries are "roomId|epochMs"
  static List<String> record(List<String> opens, String roomId, DateTime now) {
    final last = opens.lastWhere((e) => e.contains('|') && _room(e) == roomId, orElse: () => '');
    final lastMs = last.isEmpty ? null : _ms(last);
    if (lastMs != null && now.millisecondsSinceEpoch - lastMs < _debounce.inMilliseconds) return opens;
    final cutoff = now.subtract(window).millisecondsSinceEpoch;
    final kept = [
      for (final e in opens)
        if (e.contains('|') && (_ms(e) ?? 0) >= cutoff) e,
      '$roomId|${now.millisecondsSinceEpoch}',
    ];
    return kept.length > _maxEntries ? kept.sublist(kept.length - _maxEntries) : kept;
  }

  /// Most opened, ties to the latest
  static List<String> top(List<String> opens, DateTime now) {
    final cutoff = now.subtract(window).millisecondsSinceEpoch;
    final counts = <String, int>{};
    final latest = <String, int>{};
    for (final e in opens.where((e) => e.contains('|'))) {
      final ms = _ms(e);
      if (ms == null || ms < cutoff) continue;
      counts.update(_room(e), (n) => n + 1, ifAbsent: () => 1);
      latest[_room(e)] = ms;
    }
    final rooms = counts.keys.toList()
      ..sort((a, b) => counts[a] != counts[b] ? counts[b]!.compareTo(counts[a]!) : latest[b]!.compareTo(latest[a]!));
    return rooms.take(_count).toList();
  }
}
