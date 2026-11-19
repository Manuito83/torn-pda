import 'dart:async';

import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/models/chat/chat_notepad.dart';
import 'package:torn_pda/pages/chat/settings/chat_upload_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_notepad.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// False when Torn refused
Future<bool> chatDeleteNote(ChatNotepad notepad, ChatNote note) async {
  if (!await notepad.delete(note.id)) {
    chatToast("Torn didn't delete the note");
    return false;
  }
  final kept = NativeChat.prefs.dropNote(note.id);
  chatToast(
    'Note deleted',
    seconds: 6,
    action: 'Undo',
    onAction: () async {
      final back = await notepad.create(title: note.title, text: note.text);
      if (back == null) return chatToast("Torn didn't create the note");
      NativeChat.prefs.placeNote(back.id, kept);
    },
  );
  return true;
}

Future<void> chatMoveNote(BuildContext context, ChatNotepad notepad, ChatNote note) async {
  var typed = note.meta.folder;
  final existing = ChatNote.allFolders(notepad.notes);
  final folder = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Move to folder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: typed,
              onChanged: (v) => typed = v,
              autofocus: existing.isEmpty,
              decoration: const InputDecoration(
                hintText: 'Folder',
                helperText: 'Up to ${ChatNote.maxFolderDepth} levels, like Raids/Weekly',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final path in existing)
                  ActionChip(label: Text(path), onPressed: () => Navigator.pop(context, path)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('No folder')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, typed), child: const Text('Move')),
      ],
    ),
  );
  final latest = notepad.notes.where((n) => n.id == note.id).firstOrNull ?? note;
  if (folder == null || ChatNote.cleanFolder(folder) == latest.meta.folder) return;
  notepad.edit(latest.withMeta(folder: ChatNote.cleanFolder(folder)));
}

Future<void> chatRenameNote(BuildContext context, ChatNotepad notepad, ChatNote note) async {
  var typed = note.title;
  final title = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename'),
      content: TextFormField(
        initialValue: typed,
        autofocus: true,
        onChanged: (v) => typed = v,
        decoration: const InputDecoration(hintText: 'Title'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, typed), child: const Text('Save')),
      ],
    ),
  );
  final latest = notepad.notes.where((n) => n.id == note.id).firstOrNull ?? note;
  if (title != null && title.trim() != latest.title) notepad.edit(latest.copyWith(title: title.trim()));
}

/// [context] inside the notepad sheet
Future<void> chatShareNote(BuildContext context, ChatNote note) async {
  final text = [if (note.title.trim().isNotEmpty) note.title.trim(), note.body.trim()].join('\n\n');
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  final how = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (NativeChat.controller.available)
            ListTile(
              leading: const Icon(Icons.send_outlined),
              title: const Text('Send to chat'),
              subtitle: const Text('Pick a chat, it waits in the message box'),
              onTap: () => Navigator.pop(context, 'chat'),
            ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Copy'),
            onTap: () => Navigator.pop(context, 'copy'),
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Share'),
            subtitle: const Text('Other apps'),
            onTap: () => Navigator.pop(context, 'share'),
          ),
        ],
      ),
    ),
  );
  switch (how) {
    case 'chat' when context.mounted:
      Navigator.of(context).pop();
      await ChatShareIn.shareText(note.body);
    case 'copy':
      await Clipboard.setData(ClipboardData(text: text));
      chatToast('Note copied', seconds: 1);
    case 'share':
      await SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin));
  }
}

class ChatNoteView extends StatefulWidget {
  const ChatNoteView({super.key, required this.notepad, required this.note, required this.onBack});

  final ChatNotepad notepad;
  final ChatNote note;
  final VoidCallback onBack;

  @override
  State<ChatNoteView> createState() => _ChatNoteViewState();
}

class _ChatNoteViewState extends State<ChatNoteView> {
  late final _title = TextEditingController(text: _current.title);
  late final _text = TextEditingController(text: _current.body);
  final _textFocus = FocusNode();
  late final ChatImageUpload _uploads = context.read<ChatImageUpload?>() ?? ChatImageUpload();
  bool _applying = false;
  bool _uploading = false;
  late bool _editing = _current.body.trim().isEmpty;

  ChatNotepad get _notepad => widget.notepad;

  ChatNote get _current => _notepad.notes.where((n) => n.id == widget.note.id).firstOrNull ?? widget.note;

  @override
  void initState() {
    super.initState();
    _title.addListener(_changed);
    _text.addListener(_changed);
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _changed() {
    if (_applying) return;
    final current = _current;
    if (current.title == _title.text && current.body == _text.text) return;
    _notepad.edit(current.withBody(_text.text).copyWith(title: _title.text));
  }

  void _show(ChatNote note) {
    _applying = true;
    _title.text = note.title;
    _text.text = note.body;
    _applying = false;
  }

  void _useTheirs() {
    final note = _notepad.useTheirs();
    if (note != null) _show(note);
  }

  void _edit(bool editing) {
    if (editing && !_notepad.dirty) _show(_current);
    setState(() => _editing = editing);
    if (!editing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFocus.requestFocus();
    });
  }

  void _toggle(int line) {
    final note = _current.withBody(ChatNote.toggleTask(_current.body, line));
    _notepad.edit(note);
    _show(note);
  }

  void _insertLine(String line) {
    final value = _text.value;
    final at = value.selection.isValid ? value.selection.start : value.text.length;
    final to = value.selection.isValid ? value.selection.end : at;
    final next = ChatNote.insertLine(value.text, at, to, line);
    _text.value = TextEditingValue(
      text: next.text,
      selection: TextSelection.collapsed(offset: next.cursor),
    );
    _textFocus.requestFocus();
  }

  Future<void> _addImage({required bool fromFiles}) async {
    final prefs = NativeChat.prefs;
    final host = prefs.imageHost;
    if (host.needsCredential && prefs.credentialFor(host).isEmpty) {
      await ChatUploadSettingsPage.editCredential(context, host);
      if (!mounted || prefs.credentialFor(host).isEmpty) return;
    }
    final PlatformFile? file;
    try {
      file = await _uploads.pick(fromFiles: fromFiles);
    } catch (_) {
      chatToast('Could not open the picker');
      return;
    }
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final link = await _uploads.upload(
        host,
        file.bytes ?? Uint8List(0),
        file.name,
        prefs.credentialFor(host),
        expiration: prefs.imgbbExpiration,
      );
      if (mounted) _insertLine(link);
    } on ChatUploadError catch (e) {
      chatToast(
        e.message,
        seconds: 4,
        action: e.refusedKey ? 'Change the ${host.credentialName}' : null,
        onAction: !e.refusedKey
            ? null
            : () {
                if (mounted) ChatUploadSettingsPage.editCredential(context, host);
              },
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete() async {
    if (await chatDeleteNote(_notepad, _current) && mounted) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notepad = _notepad;
    final conflict = notepad.theirs?.id == widget.note.id;
    final readOnly = notepad.offline;
    final previews = NativeChat.prefs.notePreviews;
    final editing = !readOnly && (_editing || !previews);
    final current = _current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded), onPressed: widget.onBack),
            Expanded(
              child: editing
                  ? TextField(
                      controller: _title,
                      style: theme.textTheme.titleMedium,
                      decoration: const InputDecoration.collapsed(hintText: 'Title'),
                    )
                  : Text(
                      current.title.isEmpty ? 'Untitled' : current.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (current.body.trim().isNotEmpty)
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => chatShareNote(context, _current),
              ),
            if (previews && !readOnly)
              IconButton(
                tooltip: editing ? 'Done' : 'Edit',
                icon: Icon(editing ? Icons.check_rounded : Icons.edit_outlined),
                onPressed: () => _edit(!editing),
              ),
            if (!readOnly)
              IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(child: _status(theme, conflict: conflict)),
              if (editing) ...[
                if (_uploading)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  PopupMenuButton<bool>(
                    tooltip: 'Add an image',
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    onSelected: (fromFiles) => _addImage(fromFiles: fromFiles),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: false, child: Text('Gallery')),
                      PopupMenuItem(value: true, child: Text('Files')),
                    ],
                  ),
                IconButton(
                  tooltip: 'Add a task',
                  icon: const Icon(Icons.add_task_rounded),
                  onPressed: () => _insertLine('- [ ] '),
                ),
              ],
            ],
          ),
        ),
        if (conflict) _conflict(theme),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: editing
                ? TextField(
                    controller: _text,
                    focusNode: _textFocus,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration.collapsed(hintText: 'Write something'),
                  )
                : _reading(theme, current.body, readOnly: readOnly),
          ),
        ),
      ],
    );
  }

  Widget _reading(ThemeData theme, String text, {required bool readOnly}) {
    final color = theme.colorScheme.onSurface;
    Widget content(String text) => Semantics(
      label: text,
      child: ChatMessageText(content: text, color: color, maxCards: 30, trusted: true),
    );
    return ListView(
      children: [
        for (final block in ChatNote.blocks(text))
          if (block.done case final done?)
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: done, onChanged: readOnly ? null : (_) => _toggle(block.line)),
                  Expanded(
                    child: Padding(padding: const EdgeInsets.only(top: 12), child: content(block.text)),
                  ),
                ],
              ),
            )
          else if (block.text.trim().isEmpty)
            const SizedBox(height: 8)
          else
            content(block.text),
      ],
    );
  }

  Widget _conflict(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This note changed somewhere else', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              TextButton(onPressed: _useTheirs, child: const Text('Load that one')),
              TextButton(onPressed: _notepad.keepMine, child: const Text('Keep mine')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _status(ThemeData theme, {required bool conflict}) {
    final style = theme.textTheme.bodySmall;
    final error = style?.copyWith(color: theme.colorScheme.error);
    if (_notepad.offline) return Text('Offline copy, read only', style: error);
    if (conflict) return Text('Not saved', style: error);
    if (_notepad.saveFailed) {
      return Row(
        children: [
          Text('Not saved', style: error),
          TextButton(onPressed: _notepad.save, child: const Text('Retry')),
        ],
      );
    }
    return Text(_notepad.dirty ? 'Saving…' : 'Saved', style: style);
  }
}
