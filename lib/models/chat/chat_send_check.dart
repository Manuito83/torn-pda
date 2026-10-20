enum ChatKeyRisk { none, similar, own }

class ChatSendCheck {
  static const Set<String> _publicRooms = {'global', 'trade', 'poker', 'newplayers'};

  static final RegExp _candidate = RegExp(r'(?<![A-Za-z0-9])[A-Za-z0-9]{16}(?![A-Za-z0-9])');
  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'[0-9]');

  static bool isPublic(String? roomId) => _publicRooms.contains(roomId);

  static ChatKeyRisk keyRisk(String text, {String? ownKey}) {
    final key = ownKey?.trim() ?? '';
    if (key.length >= 16 && text.contains(key)) return ChatKeyRisk.own;
    for (final m in _candidate.allMatches(text)) {
      final word = m.group(0)!;
      if (_letter.hasMatch(word) && _digit.hasMatch(word)) return ChatKeyRisk.similar;
    }
    return ChatKeyRisk.none;
  }
}
