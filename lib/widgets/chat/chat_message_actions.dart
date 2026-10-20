import 'package:flutter/material.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

typedef ChatMessageAction = (String id, IconData icon, String label, VoidCallback? onTap);

const Map<String, (IconData, String)> chatMessageActionLooks = {
  'reply': (Icons.reply_rounded, 'Reply'),
  'copy': (Icons.copy_rounded, 'Copy'),
  'forward': (Icons.forward_rounded, 'Forward'),
  'smiley': (Icons.add_reaction_outlined, 'Reply with an emoji'),
  'pin': (Icons.push_pin_outlined, 'Pin'),
  'save': (Icons.bookmark_add_outlined, 'Save'),
  'translate': (Icons.translate_rounded, 'Translate'),
  'share': (Icons.share_rounded, 'Share'),
  'remind': (Icons.alarm_add_rounded, 'Remind me'),
};

class ChatMessageActions extends StatelessWidget {
  const ChatMessageActions({
    super.key,
    required this.actions,
    required this.alignment,
    this.padding = EdgeInsets.zero,
    this.emojiOpen = false,
    this.emojis,
    this.onEmoji,
    this.onMoreEmojis,
  });

  final List<ChatMessageAction> actions;
  final Alignment alignment;
  final EdgeInsets padding;

  final bool emojiOpen;

  /// Null hides the emoji row
  final List<String>? emojis;
  final ValueChanged<String>? onEmoji;
  final VoidCallback? onMoreEmojis;

  @override
  Widget build(BuildContext context) {
    final palette = chatPalette(context);
    final ink = palette.otherText;
    ButtonStyle style(bool on) => IconButton.styleFrom(
      fixedSize: const Size(36, 36),
      minimumSize: const Size(36, 36),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: ink,
      backgroundColor: on ? ink.withValues(alpha: 0.14) : null,
    );
    Widget pill(List<Widget> children) => Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Material(
          color: palette.otherBubble,
          elevation: 2,
          shape: StadiumBorder(side: BorderSide(color: ink.withValues(alpha: 0.12))),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill([
            for (final (id, icon, label, onTap) in actions)
              IconButton(
                tooltip: label,
                iconSize: 18,
                isSelected: id == 'smiley' && emojiOpen,
                style: style(id == 'smiley' && emojiOpen),
                onPressed: onTap,
                icon: Icon(icon),
              ),
          ]),
          if (emojis case final emojis?)
            pill([
              for (final emoji in emojis)
                IconButton(
                  tooltip: 'Reply with $emoji',
                  style: style(false),
                  onPressed: () => onEmoji?.call(emoji),
                  icon: Text(emoji, style: const TextStyle(fontSize: 20, height: 1)),
                ),
              IconButton(
                tooltip: 'More emojis',
                iconSize: 18,
                style: style(false),
                onPressed: onMoreEmojis,
                icon: const Icon(Icons.add_rounded),
              ),
            ]),
        ],
      ),
    );
  }
}

class ChatMessageActionsEditor extends StatelessWidget {
  const ChatMessageActionsEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = NativeChat.prefs;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => Material(
        type: MaterialType.transparency,
        child: ReorderableListView(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: prefs.moveMessageAction,
          children: [
            for (final (i, id) in prefs.messageActionOrder.indexed)
              SwitchListTile(
                key: ValueKey(id),
                secondary: ReorderableDragStartListener(
                  index: i,
                  child: Semantics(
                    label: 'Drag to reorder ${chatMessageActionLooks[id]!.$2}',
                    child: const SizedBox(width: 48, height: 48, child: Icon(Icons.drag_handle_rounded)),
                  ),
                ),
                title: Row(
                  children: [
                    Icon(chatMessageActionLooks[id]!.$1, size: 18),
                    const SizedBox(width: 8),
                    Text(chatMessageActionLooks[id]!.$2),
                  ],
                ),
                value: !prefs.messageActionHidden.contains(id),
                onChanged: (on) => prefs.setMessageActionShown(id, on),
              ),
          ],
        ),
      ),
    );
  }
}
