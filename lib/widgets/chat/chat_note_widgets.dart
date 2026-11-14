import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Tap edits, links still open
class ChatNoteLine extends StatefulWidget {
  const ChatNoteLine({super.key, required this.id, required this.name, this.maxLines = 1});

  final int id;
  final String name;
  final int maxLines;

  @override
  State<ChatNoteLine> createState() => _ChatNoteLineState();
}

class _ChatNoteLineState extends State<ChatNoteLine> {
  final List<TapGestureRecognizer> _taps = [];

  void _disposeTaps() {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _disposeTaps();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) {
        final note = NativeChat.prefs.playerNoteFor(widget.id);
        if (note.isEmpty) return const SizedBox.shrink();
        _disposeTaps();
        final theme = Theme.of(context);
        final link = theme.colorScheme.primary;
        final spans = <TextSpan>[];
        for (final part in ChatLink.split(note)) {
          if (part is! ChatLink) {
            spans.add(TextSpan(text: part as String));
            continue;
          }
          final tap = TapGestureRecognizer()..onTap = () => openChatLink(context, part);
          _taps.add(tap);
          spans.add(
            TextSpan(
              text: part.label ?? part.raw,
              recognizer: tap,
              style: TextStyle(color: link, decoration: TextDecoration.underline, decorationColor: link),
            ),
          );
        }
        return Semantics(
          button: true,
          label: 'Chat note: $note. Edit',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => showChatNoteEditor(context, widget.id, widget.name),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Chat note: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...spans,
                ],
              ),
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
            ),
          ),
        );
      },
    );
  }
}

class ChatPlayerNotes extends StatelessWidget {
  const ChatPlayerNotes({super.key, required this.id, required this.name});

  final int id;
  final String name;

  @override
  Widget build(BuildContext context) {
    final notes = Get.isRegistered<PlayerNotesController>() ? Get.find<PlayerNotesController>() : null;
    final player = notes?.getNoteForPlayer('$id')?.note.trim() ?? '';
    return ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) {
        final chat = NativeChat.prefs.playerNoteFor(id);
        if (player.isEmpty && chat.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final bold = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600);
        return Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (player.isNotEmpty)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Player note: ', style: bold),
                      TextSpan(text: player),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              if (chat.isNotEmpty) ChatNoteLine(id: id, name: name, maxLines: 3),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showChatNoteEditor(BuildContext context, int id, String name) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ChatNoteDialog(id: id, name: name),
  );
}

class _ChatNoteDialog extends StatefulWidget {
  const _ChatNoteDialog({required this.id, required this.name});

  final int id;
  final String name;

  @override
  State<_ChatNoteDialog> createState() => _ChatNoteDialogState();
}

class _ChatNoteDialogState extends State<_ChatNoteDialog> {
  late final TextEditingController _text = TextEditingController(text: NativeChat.prefs.playerNoteFor(widget.id));

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save(String value) {
    NativeChat.prefs.setPlayerNote(widget.id, value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chat note: ${widget.name}'),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        maxLength: ChatPrefs.playerNoteMax,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(helperText: 'Only visible in chat'),
      ),
      actions: [
        if (NativeChat.prefs.playerNoteFor(widget.id).isNotEmpty)
          TextButton(onPressed: () => _save(''), child: const Text('Delete')),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => _save(_text.text), child: const Text('Save')),
      ],
    );
  }
}
