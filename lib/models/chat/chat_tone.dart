enum ChatSound {
  standard('Default', null),
  silent('Silent', null),
  slowSpringBoard('Spring board', 'slow_spring_board'),
  aircraftSeatbelt('Seatbelt', 'aircraft_seatbelt'),
  carStart('Car start', 'car_start'),
  keyboard('Keyboard', 'keyboard'),
  swordClash('Sword clash', 'sword_clash');

  const ChatSound(this.label, this.resource);

  final String label;
  final String? resource;

  static List<ChatSound> get audible => [
    for (final s in values)
      if (s.resource != null) s,
  ];
}

enum ChatVibration {
  standard('Default', null),
  short('Short', [0, 120]),
  double('Double', [0, 120, 100, 120]),
  long('Long', [0, 700]),
  none('None', [0]);

  const ChatVibration(this.label, this.pattern);

  final String label;
  final List<int>? pattern;
}

class ChatTone {
  const ChatTone([this.sound = ChatSound.standard, this.vibration = ChatVibration.standard]);

  static const ChatTone standard = ChatTone();

  final ChatSound sound;
  final ChatVibration vibration;

  bool get isStandard => sound == ChatSound.standard && vibration == ChatVibration.standard;

  ChatTone copyWith({ChatSound? sound, ChatVibration? vibration}) =>
      ChatTone(sound ?? this.sound, vibration ?? this.vibration);

  String get code => '${sound.name}/${vibration.name}';

  /// Default sound follows [forAll] when set
  ChatTone resolve(ChatSound? forAll, String roomId) {
    if (sound != ChatSound.standard) return this;
    final keyboardRoom = roomId.startsWith('dm:') || roomId == 'faction' || roomId == 'company';
    return ChatTone(forAll ?? (keyboardRoom ? ChatSound.keyboard : ChatSound.silent), vibration);
  }

  static ChatTone? decode(String code) {
    final parts = code.split('/');
    if (parts.length != 2) return null;
    final sound = ChatSound.values.where((s) => s.name == parts[0]);
    final vibration = ChatVibration.values.where((v) => v.name == parts[1]);
    if (sound.isEmpty || vibration.isEmpty) return null;
    return ChatTone(sound.first, vibration.first);
  }

  /// Android channel id, one per combination
  String channelId(String? globalModifier) {
    if (_legacyChannel) return 'Torn chat $globalModifier s';
    final vib = vibration == ChatVibration.standard ? globalModifier : vibration.name;
    return 'Torn chat ${sound.name} $vib';
  }

  // Old channel ids, must not change
  bool get _legacyChannel =>
      vibration == ChatVibration.standard && (sound == ChatSound.standard || sound == ChatSound.keyboard);

  String channelName(String? globalModifier) {
    if (_legacyChannel) return channelId(globalModifier);
    return 'Torn chat: ${sound.label}, ${vibration.label.toLowerCase()}';
  }
}

/// From "roomId|sound/vibration" entries
Map<String, ChatTone> decodeChatTones(Iterable<String> entries) {
  final tones = <String, ChatTone>{};
  for (final entry in entries) {
    final cut = entry.lastIndexOf('|');
    if (cut < 0) continue;
    final tone = ChatTone.decode(entry.substring(cut + 1));
    if (tone != null) tones[entry.substring(0, cut)] = tone;
  }
  return tones;
}

List<String> encodeChatTones(Map<String, ChatTone> tones) => [
  for (final e in tones.entries)
    if (!e.value.isStandard) '${e.key}|${e.value.code}',
];
