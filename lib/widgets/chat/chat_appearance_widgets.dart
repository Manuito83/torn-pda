import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_settings_widgets.dart';
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

String _percent(double scale) => '${(scale * 100).round()}%';

// Slider that the screen reader names
class ChatNamedSlider extends StatelessWidget {
  const ChatNamedSlider({
    super.key,
    required this.name,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.shown,
    this.spoken,
    this.onChanged,
  });

  final String name;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) shown;
  final String Function(double value)? spoken;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final say = spoken ?? shown;
    final step = (max - min) / divisions;
    double snap(double v) => clampDouble(min + ((v - min) / step).round() * step, min, max);
    final up = snap(value + step);
    final down = snap(value - step);
    final change = onChanged;
    return Semantics(
      container: true,
      slider: true,
      enabled: change != null,
      label: name,
      value: say(value),
      increasedValue: say(up),
      decreasedValue: say(down),
      onIncrease: change == null || up == value ? null : () => change(up),
      onDecrease: change == null || down == value ? null : () => change(down),
      child: ExcludeSemantics(
        child: Slider(value: value, min: min, max: max, divisions: divisions, label: shown(value), onChanged: change),
      ),
    );
  }
}

class ChatTextSizeSetting extends StatelessWidget {
  const ChatTextSizeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = NativeChat.prefs;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ExcludeSemantics(
              child: Text('Chat text size: ${_percent(prefs.textScale)}', style: theme.textTheme.bodyLarge),
            ),
          ),
          ChatNamedSlider(
            name: 'Chat text size',
            value: prefs.textScale,
            min: ChatPrefs.minTextScale,
            max: ChatPrefs.maxTextScale,
            divisions: 8,
            shown: _percent,
            onChanged: prefs.setTextScale,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: ChatSettingsText.hint('On top of the system text size. Only the messages change'),
          ),
        ],
      ),
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
    final listPercent = _percent(prefs.listTextScale);
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
        ChatSettingsTile(
          title: 'Preview lines',
          subtitle: 'Of the last message in the chat list',
          control: (_) => SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final n in ChatPrefs.previewLinesOptions)
                ButtonSegment(
                  value: n,
                  label: Text('$n', semanticsLabel: n == 1 ? '1 line' : '$n lines'),
                ),
            ],
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
          title: ExcludeSemantics(child: Text('Messages in the quick reply: ${prefs.listReplyCount}')),
          subtitle: const ChatSettingsText('How many of the last messages to show'),
        ),
        ChatNamedSlider(
          name: 'Messages in the quick reply',
          value: prefs.listReplyCount.toDouble(),
          min: ChatPrefs.minListReplyCount.toDouble(),
          max: ChatPrefs.maxListReplyCount.toDouble(),
          divisions: ChatPrefs.maxListReplyCount - ChatPrefs.minListReplyCount,
          shown: (v) => '${v.round()}',
          spoken: (v) => v.round() == 1 ? '1 message' : '${v.round()} messages',
          onChanged: prefs.listReply ? (v) => prefs.setListReplyCount(v.round()) : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: ExcludeSemantics(child: Text('List text size: $listPercent', style: theme.textTheme.bodyLarge)),
        ),
        ChatNamedSlider(
          name: 'List text size',
          value: prefs.listTextScale,
          min: ChatPrefs.minTextScale,
          max: ChatPrefs.maxTextScale,
          divisions: 8,
          shown: _percent,
          onChanged: prefs.setListTextScale,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: ChatSettingsText.hint('Only the messages in the quick reply of the chat list'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Semantics(
            container: true,
            child: const FeatureDiagram(scenes: [FeatureDiagramScene.chatListReply], showCaption: true),
          ),
        ),
        const ChatTextSizeSetting(),
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
