class ChatEmoji {
  ChatEmoji._();

  static const int maxFavorites = 12;
  static const int _shownMostUsed = 6;
  static const int maxTracked = 60;

  static const Map<String, List<String>> categories = {
    'Faces': [
      '😀',
      '😁',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '😉',
      '😍',
      '😘',
      '😋',
      '😎',
      '🤔',
      '😐',
      '🙄',
      '😏',
      '😴',
      '😢',
      '😭',
      '😤',
      '😡',
      '🤬',
      '😱',
      '😅',
      '🥳',
      '🤯',
      '🥶',
      '🤢',
    ],
    'Hands': ['👍', '👎', '👏', '🙌', '🙏', '🤝', '💪', '👊', '✌️', '🤞', '👌', '👋', '☝️', '👀', '🤷', '🤦'],
    'Hearts': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💔', '💯', '🔥', '✨', '⭐', '🎉', '🎁'],
    'Symbols': ['✅', '❌', '⚠️', '❓', '❗', '➡️', '⬆️', '⬇️', '🔔', '⏰', '🚫', '💬', '📌', '🔒', '🔗'],
    'Torn': [
      '💰',
      '💸',
      '💵',
      '💎',
      '🏆',
      '⚔️',
      '🔫',
      '💣',
      '🛡️',
      '💊',
      '🏥',
      '✈️',
      '🌴',
      '🚗',
      '🏠',
      '👑',
      '🍺',
      '🎲',
    ],
  };

  static const List<String> defaultFavorites = ['👍', '😂', '🙏', '👀', '🔥', '💰'];

  static final List<String> all = [for (final list in categories.values) ...list];

  static Map<String, int> decodeCounts(List<String> raw) {
    final counts = <String, int>{};
    for (final entry in raw) {
      final split = entry.lastIndexOf('|');
      final n = split > 0 ? int.tryParse(entry.substring(split + 1)) : null;
      if (n != null && n > 0) counts[entry.substring(0, split)] = n;
    }
    return counts;
  }

  static List<String> encodeCounts(Map<String, int> counts) => [for (final e in counts.entries) '${e.key}|${e.value}'];

  // Emojis in a message, with repeats
  static List<String> found(String text) {
    final result = <String>[];
    for (final emoji in all) {
      var from = 0;
      while ((from = text.indexOf(emoji, from)) >= 0) {
        result.add(emoji);
        from += emoji.length;
      }
    }
    return result;
  }

  static Map<String, int> addUses(Map<String, int> counts, Iterable<String> emojis) {
    final next = {...counts};
    for (final emoji in emojis) {
      next[emoji] = (next[emoji] ?? 0) + 1;
    }
    if (next.length <= maxTracked) return next;
    final keep = next.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in keep.take(maxTracked)) e.key: e.value};
  }

  static List<String> row(List<String> favorites, Map<String, int> counts) {
    if (favorites.isNotEmpty) return favorites;
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in top.take(_shownMostUsed)) e.key];
  }
}
