import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_person.dart';
import 'package:torn_pda/models/chat/chat_player_color.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> showChatPersonSettings(BuildContext context, ChatUser user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ChatPersonSheet(user: user),
  );
}

class _ChatPersonSheet extends StatefulWidget {
  const _ChatPersonSheet({required this.user});

  final ChatUser user;

  @override
  State<_ChatPersonSheet> createState() => _ChatPersonSheetState();
}

class _ChatPersonSheetState extends State<_ChatPersonSheet> {
  late final TextEditingController _nickname = TextEditingController(
    text: NativeChat.prefs.personOf(widget.user.id).nickname,
  );

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _save(ChatPersonStyle style) =>
      NativeChat.prefs.setPerson(widget.user.id, style.copyWith(name: widget.user.name));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = widget.user;
    return ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) {
        final prefs = NativeChat.prefs;
        final style = prefs.personOf(user.id);
        final label = theme.textTheme.titleSmall;
        final bubble = style.highlight
            ? style.highlightColor ?? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest;
        final text = style.highlight
            ? style.highlightColor == null
                  ? scheme.onTertiaryContainer
                  : ThemeData.estimateBrightnessForColor(bubble) == Brightness.dark
                  ? Colors.white
                  : Colors.black
            : scheme.onSurface;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: ChatAvatar(user: user, size: 40),
                    title: Text('Customize ${user.name}'),
                    subtitle: const Text('Only you see this, only in Torn PDA'),
                    trailing: style.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () {
                              _nickname.clear();
                              prefs.setPerson(user.id, ChatPersonStyle.none);
                            },
                            child: const Text('Reset'),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Semantics(
                      label: 'Preview',
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                        decoration: BoxDecoration(color: bubble, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prefs.displayName(user.id, user.name),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: style.nameColor != null
                                    ? ChatPlayerColor.tinted(style.nameColor!, bubble)
                                    : style.highlight
                                    ? text
                                    : prefs.playerColors
                                    ? ChatPlayerColor.of(user.id, bubble)
                                    : ChatPlayerColor.tinted(chatUserScheme(context, user.id).primary, bubble),
                              ),
                            ),
                            Text('How their messages look', style: theme.textTheme.bodyMedium?.copyWith(color: text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text('Name color', style: label),
                  ),
                  _Swatches(
                    options: ChatPersonStyle.nameColors,
                    unset: 'Automatic',
                    selected: style.nameColor,
                    onPick: (c) => _save(style.copyWith(nameColor: () => c)),
                  ),
                  SwitchListTile(
                    title: const Text('Highlight their messages'),
                    subtitle: const Text('Colored bubble in every room and in your private chat'),
                    value: style.highlight,
                    onChanged: (v) => _save(style.copyWith(highlight: v)),
                  ),
                  if (style.highlight)
                    _Swatches(
                      options: ChatPersonStyle.highlightColors,
                      unset: 'Same as mentions',
                      selected: style.highlightColor,
                      onPick: (c) => _save(style.copyWith(highlightColor: () => c)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _nickname,
                      maxLength: ChatPersonStyle.nicknameMax,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => _save(prefs.personOf(user.id).copyWith(nickname: v)),
                      decoration: InputDecoration(
                        labelText: 'Nickname',
                        hintText: user.name,
                        helperText: 'Shown instead of their name, only to you',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.options, required this.unset, required this.selected, required this.onPick});

  final List<(String, Color)> options;
  final String unset;
  final Color? selected;
  final ValueChanged<Color?> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget swatch(String name, Color? color) {
      final on = color?.toARGB32() == selected?.toARGB32();
      return Semantics(
        button: true,
        selected: on,
        label: name,
        child: Tooltip(
          message: name,
          excludeFromSemantics: true,
          child: InkResponse(
            radius: 24,
            onTap: () {
              HapticFeedback.selectionClick();
              onPick(color);
            },
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color ?? scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? scheme.primary : scheme.outlineVariant, width: on ? 3 : 1),
                  ),
                  child: color == null
                      ? Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.onSurfaceVariant)
                      : on
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(children: [swatch(unset, null), for (final (name, color) in options) swatch(name, color)]),
    );
  }
}
