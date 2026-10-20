import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/diagrams/feature_diagrams.dart';

/// Scales message text over system size
class ChatTextScale extends StatelessWidget {
  const ChatTextScale({super.key, required this.child, this.scale});

  final Widget child;

  /// The chat text size when null
  final double? scale;

  @override
  Widget build(BuildContext context) {
    final scale = this.scale ?? NativeChat.prefs.textScale;
    if (scale == 1) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(1) * scale)),
      child: child,
    );
  }
}

class ChatAppearanceSettings extends StatelessWidget {
  const ChatAppearanceSettings({super.key});

  static final _now = DateTime(2026, 10, 14, 12, 30);

  ChatMessage _sample(String id, int sender, String name, String text) => ChatMessage(
    id: id,
    roomId: 'faction',
    sender: ChatUser(id: sender, name: name),
    content: text,
    createdAt: _now,
  );

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: NativeChat.prefs, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final prefs = NativeChat.prefs;
    final theme = Theme.of(context);
    final percent = '${(prefs.textScale * 100).round()}%';
    final listPercent = '${(prefs.listTextScale * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Compact mode'),
          subtitle: const Text('Messages in rows, without bubbles'),
          value: prefs.compactMode,
          onChanged: prefs.setCompactMode,
        ),
        SwitchListTile(title: const Text('Show avatars'), value: prefs.showAvatars, onChanged: prefs.setShowAvatars),
        ListTile(
          title: const Text('Preview lines'),
          subtitle: const Text('Of the last message in the chat list'),
          trailing: SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [for (final n in ChatPrefs.previewLinesOptions) ButtonSegment(value: n, label: Text('$n'))],
            selected: {prefs.previewLines},
            onSelectionChanged: (v) => prefs.setPreviewLines(v.first),
          ),
        ),
        SwitchListTile(
          title: const Text('Quick reply in the list'),
          subtitle: const Text(
            'Read and answer from the list with the arrow on each chat. Marks it read',
          ),
          value: prefs.listReply,
          onChanged: prefs.setListReply,
        ),
        ListTile(
          enabled: prefs.listReply,
          title: Text('Messages in the quick reply: ${prefs.listReplyCount}'),
          subtitle: const Text('How many of the last messages to show'),
        ),
        Slider(
          value: prefs.listReplyCount.toDouble(),
          min: ChatPrefs.minListReplyCount.toDouble(),
          max: ChatPrefs.maxListReplyCount.toDouble(),
          divisions: ChatPrefs.maxListReplyCount - ChatPrefs.minListReplyCount,
          label: '${prefs.listReplyCount}',
          onChanged: prefs.listReply ? (v) => prefs.setListReplyCount(v.round()) : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text('List text size: $listPercent', style: theme.textTheme.bodyLarge),
        ),
        Slider(
          value: prefs.listTextScale,
          min: ChatPrefs.minTextScale,
          max: ChatPrefs.maxTextScale,
          divisions: 8,
          label: listPercent,
          semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
          onChanged: prefs.setListTextScale,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Only the messages in the quick reply of the chat list',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: FeatureDiagram(scenes: [FeatureDiagramScene.chatListReply], showCaption: true),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('Chat text size: $percent', style: theme.textTheme.bodyLarge),
        ),
        Slider(
          value: prefs.textScale,
          min: ChatPrefs.minTextScale,
          max: ChatPrefs.maxTextScale,
          divisions: 8,
          label: percent,
          semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
          onChanged: prefs.setTextScale,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'On top of the system text size. Only the messages change',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Semantics(
          label: 'Preview',
          container: true,
          child: ExcludeSemantics(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: chatPalette(context).background,
              child: Column(
                children: [
                  ChatMessageBubble(
                    message: _sample('p1', 4, 'Leslie', 'Anyone up for a chain at 20:00?'),
                    isMine: false,
                    isFirstInGroup: true,
                    isLastInGroup: true,
                  ),
                  ChatMessageBubble(
                    message: _sample('p2', 1, 'You', 'Count me in'),
                    isMine: true,
                    isFirstInGroup: true,
                    isLastInGroup: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
