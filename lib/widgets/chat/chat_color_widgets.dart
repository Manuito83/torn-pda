import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_colors.dart';
import 'package:torn_pda/models/chat/chat_player_color.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

AppTheme _chatAppTheme(BuildContext context) {
  try {
    return Provider.of<ThemeProvider>(context, listen: false).currentTheme;
  } on ProviderNotFoundException {
    return Theme.of(context).brightness == Brightness.light ? AppTheme.light : AppTheme.dark;
  }
}

ChatPalette chatPalette(BuildContext context) {
  final theme = Theme.of(context);
  return NativeChat.prefs
      .colorsFor(_chatAppTheme(context).name)
      .resolve(theme.colorScheme, theme.scaffoldBackgroundColor);
}

class ChatColorPreview extends StatelessWidget {
  const ChatColorPreview({super.key, required this.palette});

  final ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget bubble(String text, {required bool mine}) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
        decoration: BoxDecoration(
          color: mine ? palette.mineBubble : palette.otherBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine)
              Text(
                'Leslie',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: NativeChat.prefs.playerColors ? ChatPlayerColor.of(4, palette.otherBubble) : palette.otherText,
                ),
              ),
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: mine ? palette.mineText : palette.otherText)),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      label: 'Preview',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(children: [bubble('Anyone up for a chain?', mine: false), bubble('On my way', mine: true)]),
      ),
    );
  }
}

/// Per app theme, applied live
class ChatColorSettings extends StatefulWidget {
  const ChatColorSettings({super.key});

  @override
  State<ChatColorSettings> createState() => _ChatColorSettingsState();
}

class _ChatColorSettingsState extends State<ChatColorSettings> {
  static const _labels = {
    ChatColorSlot.background: 'Chat background',
    ChatColorSlot.mineBubble: 'My bubbles',
    ChatColorSlot.mineText: 'My text',
    ChatColorSlot.otherBubble: 'Their bubbles',
    ChatColorSlot.otherText: 'Their text',
  };

  late AppTheme _theme = _chatAppTheme(context);

  ThemeData _target(BuildContext context) {
    final current = Theme.of(context);
    if (_theme == _chatAppTheme(context)) return current;
    final base = ThemeData(
      primarySwatch: Colors.blueGrey,
      useMaterial3: current.useMaterial3,
      brightness: _theme == AppTheme.light ? Brightness.light : Brightness.dark,
    );
    return _theme == AppTheme.light ? base : chatDarkTheme(base, extra: _theme == AppTheme.extraDark);
  }

  ChatPalette _palette(BuildContext context) {
    final target = _target(context);
    return NativeChat.prefs.colorsFor(_theme.name).resolve(target.colorScheme, target.scaffoldBackgroundColor);
  }

  void _set(ChatColorSlot slot, Color? color) {
    final prefs = NativeChat.prefs;
    prefs.setChatColors(_theme.name, prefs.colorsFor(_theme.name).withSlot(slot, color));
  }

  Future<void> _pick(ChatColorSlot slot, Color color) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_labels[slot]!, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: NativeChat.prefs.colors,
                builder: (context, _, _) => ChatColorPreview(palette: _palette(context)),
              ),
              ColorPicker(
                color: color,
                onColorChanged: (picked) => _set(slot, picked),
                width: 44,
                height: 44,
                borderRadius: 4,
                spacing: 4,
                runSpacing: 4,
                wheelDiameter: 180,
                heading: Text('Color', style: theme.textTheme.titleSmall),
                subheading: Text('Shade', style: theme.textTheme.titleSmall),
                wheelSubheading: Text('Selected color and its shades', style: theme.textTheme.titleSmall),
                showColorCode: true,
                colorCodeTextStyle: theme.textTheme.bodySmall,
                copyPasteBehavior: const ColorPickerCopyPasteBehavior(longPressMenu: true),
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.both: false,
                  ColorPickerType.primary: true,
                  ColorPickerType.accent: false,
                  ColorPickerType.bw: true,
                  ColorPickerType.custom: false,
                  ColorPickerType.wheel: true,
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final prefs = NativeChat.prefs;
    return ValueListenableBuilder(
      valueListenable: prefs.colors,
      builder: (context, _, _) {
        final theme = Theme.of(context);
        final custom = prefs.colorsFor(_theme.name);
        final palette = _palette(context);
        final pairs = [
          ('My text', ChatColorSlot.mineText, ChatColorSlot.mineBubble, palette.mineBubble, palette.mineText),
          ('Their text', ChatColorSlot.otherText, ChatColorSlot.otherBubble, palette.otherBubble, palette.otherText),
        ];
        final faint =
            custom[ChatColorSlot.background] != null &&
            ChatPlayerColor.contrast(_target(context).colorScheme.onSurface, palette.background) <
                ChatPlayerColor.minContrast;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SegmentedButton<AppTheme>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: AppTheme.light, label: Text('Light')),
                  ButtonSegment(value: AppTheme.dark, label: Text('Dark')),
                  ButtonSegment(value: AppTheme.extraDark, label: Text('Extra dark')),
                ],
                selected: {_theme},
                onSelectionChanged: (picked) => setState(() => _theme = picked.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ChatColorPreview(palette: palette),
            ),
            ExpansionTile(
              title: const Text('Custom colors'),
              shape: const Border(),
              collapsedShape: const Border(),
              children: [
                for (final slot in ChatColorSlot.values)
                  Builder(
                    builder: (context) {
                      final color = switch (slot) {
                        ChatColorSlot.background => palette.background,
                        ChatColorSlot.mineBubble => palette.mineBubble,
                        ChatColorSlot.mineText => palette.mineText,
                        ChatColorSlot.otherBubble => palette.otherBubble,
                        ChatColorSlot.otherText => palette.otherText,
                      };
                      final set = custom[slot] != null;
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                          ),
                        ),
                        title: Text(_labels[slot]!),
                        subtitle: Text(
                          set
                              ? '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
                              : 'Default',
                        ),
                        trailing: set
                            ? IconButton(
                                tooltip: 'Reset ${_labels[slot]!.toLowerCase()}',
                                icon: const Icon(Icons.restart_alt_rounded),
                                onPressed: () => _set(slot, null),
                              )
                            : null,
                        onTap: () => _pick(slot, color),
                      );
                    },
                  ),
                for (final (label, slot, bubbleSlot, bubble, text) in pairs)
                  if ((custom[slot] != null || custom[bubbleSlot] != null) &&
                      ChatPlayerColor.contrast(bubble, text) < ChatPlayerColor.minContrast)
                    Semantics(
                      container: true,
                      liveRegion: true,
                      child: ListTile(
                        leading: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                        title: Text(
                          '$label is hard to read (${ChatPlayerColor.contrast(bubble, text).toStringAsFixed(1)}:1, '
                          'aim for 4.5:1)',
                        ),
                        trailing: TextButton(
                          onPressed: () => _set(slot, ChatPlayerColor.blackOrWhite(bubble)),
                          child: Text(ChatPlayerColor.blackOrWhite(bubble) == Colors.white ? 'Use white' : 'Use black'),
                        ),
                      ),
                    ),
                if (faint)
                  ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                    title: const Text('Dates and notices may be hard to read on this background'),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: custom.isEmpty ? null : () => prefs.setChatColors(_theme.name, const ChatColors()),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
