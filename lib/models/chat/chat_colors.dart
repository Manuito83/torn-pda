import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_player_color.dart';

enum ChatColorSlot { background, mineBubble, mineText, otherBubble, otherText }

typedef ChatPalette = ({Color background, Color mineBubble, Color mineText, Color otherBubble, Color otherText});

/// Custom chat colors for one app theme
class ChatColors {
  const ChatColors([this.slots = const {}]);

  final Map<ChatColorSlot, Color> slots;

  bool get isEmpty => slots.isEmpty;

  Color? operator [](ChatColorSlot slot) => slots[slot];

  ChatColors withSlot(ChatColorSlot slot, Color? color) {
    final next = {...slots}..remove(slot);
    if (color != null) next[slot] = color;
    return ChatColors(next);
  }

  Map<String, int> toJson() => {for (final e in slots.entries) e.key.name: e.value.toARGB32()};

  static ChatColors fromJson(Object? json) {
    if (json is! Map) return const ChatColors();
    return ChatColors({
      for (final slot in ChatColorSlot.values)
        if (json[slot.name] case final int value) slot: Color(value),
    });
  }

  /// Text left on default stays readable
  ChatPalette resolve(ColorScheme scheme, Color background) {
    Color text(ChatColorSlot slot, Color fallback, Color bubble) =>
        slots[slot] ??
        (ChatPlayerColor.contrast(fallback, bubble) >= ChatPlayerColor.minContrast
            ? fallback
            : ChatPlayerColor.blackOrWhite(bubble));
    final mineBubble =
        slots[ChatColorSlot.mineBubble] ?? ChatPlayerColor.tinted(scheme.primaryContainer, scheme.onPrimaryContainer);
    final otherBubble = slots[ChatColorSlot.otherBubble] ?? scheme.surfaceContainerHighest;
    return (
      background: slots[ChatColorSlot.background] ?? background,
      mineBubble: mineBubble,
      mineText: text(ChatColorSlot.mineText, scheme.onPrimaryContainer, mineBubble),
      otherBubble: otherBubble,
      otherText: text(ChatColorSlot.otherText, scheme.onSurface, otherBubble),
    );
  }
}
