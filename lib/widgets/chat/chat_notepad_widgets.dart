import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_notepad.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/providers/chat/chat_notepad.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/widgets/chat/chat_note_view.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> showChatNotepad(BuildContext context, {String query = ''}) {
  StatsController.chat.count('notepad');
  final notepad = NativeChat.notepad;
  unawaited(notepad.load());
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _NotepadSheet(notepad: notepad, query: query),
  ).whenComplete(notepad.save);
}

Future<void> showChatAddToNote(BuildContext context, ChatMessage message) async {
  final notepad = NativeChat.notepad;
  unawaited(notepad.load());
  final picked = await showModalBottomSheet<({ChatNote? note})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AddToNoteSheet(notepad: notepad),
  );
  if (picked == null) return;
  StatsController.chat.count('add_to_note');
  final ok = await notepad.append(picked.note?.id, ChatShared.outgoing([message]));
  final title = picked.note?.title;
  chatToast(
    !ok
        ? "Torn didn't save the note"
        : title == null
        ? 'Added to a new note'
        : 'Added to ${title.isEmpty ? 'the note' : title}',
  );
}

class _NotepadSheet extends StatefulWidget {
  const _NotepadSheet({required this.notepad, required this.query});

  final ChatNotepad notepad;
  final String query;

  @override
  State<_NotepadSheet> createState() => _NotepadSheetState();
}

class _NotepadSheetState extends State<_NotepadSheet> {
  late final _search = TextEditingController(text: widget.query);
  ChatNote? _open;
  bool _creating = false;
  String _folder = '';

  // Shown until its first note
  String? _newFolder;

  ChatNotepad get _notepad => widget.notepad;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _show(ChatNote note) {
    if (!_notepad.offline) _notepad.open(note);
    setState(() => _open = note);
  }

  Future<void> _create() async {
    _search.clear();
    setState(() => _creating = true);
    final note = await _notepad.create(text: ChatNote.compose(_folder, false, ''));
    if (!mounted) return;
    setState(() => _creating = false);
    if (note == null) {
      chatToast("Torn didn't create the note");
    } else {
      _show(note);
    }
  }

  Future<void> _createFolder() async {
    var typed = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New folder'),
        content: TextFormField(
          autofocus: true,
          onChanged: (v) => typed = v,
          onFieldSubmitted: (v) => Navigator.pop(context, v),
          decoration: InputDecoration(
            hintText: 'Name',
            helperText: _folder.isEmpty
                ? 'Up to ${ChatNote.maxFolderDepth} levels, like Raids/Weekly'
                : 'Inside $_folder',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, typed), child: const Text('Create')),
        ],
      ),
    );
    final path = ChatNote.cleanFolder(_folder.isEmpty ? name ?? '' : '$_folder/${name ?? ''}');
    if (name == null || path.isEmpty || path == _folder || !mounted) return;
    _search.clear();
    setState(() => _folder = _newFolder = path);
  }

  void _reorder(List<({String name, int count})> folders, List<ChatNote> notes, int from, int to) {
    final prefs = NativeChat.prefs;
    final count = folders.length;
    if (from < count) {
      final paths = [for (final f in folders) _folder.isEmpty ? f.name : '$_folder/${f.name}'];
      prefs.setFolderOrder(ChatNote.movedFolders(paths, from, to.clamp(0, count - 1), prefs.folderOrder));
      return;
    }
    final moved = ChatNote.moved(notes, from - count, (to - count).clamp(0, notes.length - 1), order: prefs.noteOrder);
    prefs.setNoteOrder(moved);
  }

  void _pin(ChatNote note) => _notepad.edit(note.withMeta(pinned: !note.meta.pinned));

  Widget _folderTile(({String name, int count}) folder, {int? drag}) {
    final path = _folder.isEmpty ? folder.name : '$_folder/${folder.name}';
    return MergeSemantics(
      key: ValueKey('folder:$path'),
      child: Semantics(
        label: '${folder.name} folder, ${folder.count} ${folder.count == 1 ? 'note' : 'notes'}',
        excludeSemantics: true,
        button: true,
        onTap: () => setState(() => _folder = path),
        child: ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(folder.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: drag == null
              ? Text('${folder.count}')
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${folder.count}'),
                    ReorderableDragStartListener(
                      index: drag,
                      child: const SizedBox(width: 40, height: 40, child: Icon(Icons.drag_handle_rounded)),
                    ),
                  ],
                ),
          onTap: () => setState(() => _folder = path),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ChatNote note, {int? drag, bool showFolder = false}) {
    final theme = Theme.of(context);
    final pinned = note.meta.pinned;
    final at = note.updatedAt;
    final tasks = ChatNote.tasks(note.body);
    final detail = [
      if (showFolder && note.meta.folder.isNotEmpty) note.meta.folder,
      if (tasks.total > 0) '${tasks.done}/${tasks.total} done',
      if (note.firstLine.isNotEmpty) note.firstLine,
    ].join(' - ');
    final tile = ListTile(
      leading: pinned ? const Icon(Icons.push_pin_rounded, size: 18, semanticLabel: 'Pinned') : null,
      minLeadingWidth: 18,
      title: Text(note.title.isEmpty ? 'Untitled' : note.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: detail.isEmpty ? null : Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: drag != null
          ? ReorderableDragStartListener(
              index: drag,
              child: Semantics(
                label: 'Drag to reorder',
                child: const SizedBox(width: 40, height: 40, child: Icon(Icons.drag_handle_rounded)),
              ),
            )
          : at == null
          ? null
          : Text(ChatLastAction.ago(at, DateTime.now()) ?? 'now', style: theme.textTheme.bodySmall),
      onTap: _notepad.loading ? null : () => _show(note),
      onLongPress: _notepad.offline ? null : () => _menu(context, note),
    );
    if (_notepad.offline) return KeyedSubtree(key: ValueKey(note.id), child: tile);
    SlidableAction action(IconData icon, String label, Color color, VoidCallback onPressed) => SlidableAction(
      onPressed: (_) => onPressed(),
      icon: icon,
      label: label,
      backgroundColor: color,
      foregroundColor: Colors.white,
    );
    return Slidable(
      key: ValueKey(note.id),
      groupTag: 'notes',
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.44,
        children: [
          action(
            pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            pinned ? 'Unpin' : 'Pin',
            Colors.blueGrey.shade500,
            () => _pin(note),
          ),
          action(
            Icons.edit_rounded,
            'Rename',
            Colors.lightBlue.shade700,
            () => chatRenameNote(context, _notepad, note),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [action(Icons.delete_rounded, 'Delete', Colors.red.shade700, () => chatDeleteNote(_notepad, note))],
      ),
      child: tile,
    );
  }

  Future<void> _menu(BuildContext context, ChatNote note) async {
    final pinned = note.meta.pinned;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
              title: Text(pinned ? 'Unpin' : 'Pin to the top'),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move to folder'),
              onTap: () => Navigator.pop(context, 'move'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_rounded),
              title: const Text('Duplicate'),
              onTap: () => Navigator.pop(context, 'duplicate'),
            ),
            if (note.body.trim().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'pin':
        _pin(note);
      case 'move':
        await chatMoveNote(context, _notepad, note);
      case 'rename':
        await chatRenameNote(context, _notepad, note);
      case 'duplicate':
        if (await _notepad.duplicate(note) == null) chatToast("Torn didn't create the note");
      case 'share':
        await chatShareNote(context, note);
      case 'delete':
        await chatDeleteNote(_notepad, note);
    }
  }

  void _back() {
    _notepad.save();
    setState(() => _open = null);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final open = _open;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.75,
        child: ListenableBuilder(
          listenable: Listenable.merge([_notepad, NativeChat.prefs]),
          builder: (context, _) => open == null
              ? _list(context)
              : ChatNoteView(key: ValueKey(open.id), notepad: _notepad, note: open, onBack: _back),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    final searching = _search.text.trim().isNotEmpty;
    final canCreate = !(_creating || _notepad.loading || _notepad.loadFailed || _notepad.offline);
    final newColor = canCreate ? theme.colorScheme.primary : theme.disabledColor;
    // Empty folder climbs to nearest
    final existing = ChatNote.allFolders(_notepad.notes);
    final fresh = _newFolder;
    if (fresh != null && existing.contains(fresh)) _newFolder = null;
    bool kept(String path) => fresh != null && (fresh == path || fresh.startsWith('$path/'));
    while (_folder.isNotEmpty && !existing.contains(_folder) && !kept(_folder)) {
      final cut = _folder.lastIndexOf('/');
      _folder = cut < 0 ? '' : _folder.substring(0, cut);
    }
    final here = ChatNote.inside(_notepad.notes, _folder);
    final folders = searching
        ? const <({String name, int count})>[]
        : ChatNote.arrangeFolders(here.folders, _folder, prefs.noteSort, prefs.folderOrder);
    final notes = ChatNote.arrange(
      searching ? _notepad.notes : here.notes,
      prefs.noteSort,
      _search.text,
      order: prefs.noteOrder,
    );
    final Widget body;
    if (_notepad.loading && _notepad.notes.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_notepad.loadFailed && _notepad.notes.isEmpty) {
      body = _Message(
        text: "Couldn't load your notes",
        action: TextButton(onPressed: _notepad.load, child: const Text('Retry')),
      );
    } else if (_notepad.notes.isEmpty) {
      body = const _Message(text: 'No notes yet');
    } else if (notes.isEmpty && folders.isEmpty) {
      body = _Message(text: searching ? 'No notes match' : 'Empty folder - New adds a note here');
    } else {
      final dragging = prefs.noteSort == ChatNoteSort.custom && !searching && !_notepad.offline;
      body = SlidableAutoCloseBehavior(
        child: dragging
            ? ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: folders.length + notes.length,
                onReorderItem: (from, to) => _reorder(folders, notes, from, to),
                itemBuilder: (context, i) => i < folders.length
                    ? _folderTile(folders[i], drag: i)
                    : _tile(context, notes[i - folders.length], drag: i),
              )
            : ListView(
                children: [
                  for (final folder in folders) _folderTile(folder),
                  for (final note in notes) _tile(context, note, showFolder: searching),
                ],
              ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              if (_folder.isNotEmpty && !searching)
                IconButton(
                  tooltip: 'Up a folder',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() {
                    final cut = _folder.lastIndexOf('/');
                    _folder = cut < 0 ? '' : _folder.substring(0, cut);
                  }),
                ),
              Expanded(
                child: Text(
                  _folder.isEmpty || searching ? 'Notepad' : _folder,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_notepad.loading && _notepad.notes.isNotEmpty)
                const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              PopupMenuButton<ChatNoteSort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort_rounded),
                initialValue: prefs.noteSort,
                onSelected: prefs.setNoteSort,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: ChatNoteSort.torn, child: Text("Torn's order")),
                  PopupMenuItem(value: ChatNoteSort.name, child: Text('Name')),
                  PopupMenuItem(value: ChatNoteSort.edited, child: Text('Last edited')),
                  PopupMenuItem(value: ChatNoteSort.custom, child: Text('Custom, drag to order')),
                ],
              ),
              PopupMenuButton<bool>(
                tooltip: 'New note or folder',
                enabled: canCreate,
                onSelected: (folder) => folder ? _createFolder() : _create(),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: false, child: Text('Note')),
                  if (_folder.isEmpty || _folder.split('/').length < ChatNote.maxFolderDepth)
                    const PopupMenuItem(value: true, child: Text('Folder')),
                ],
                child: Semantics(
                  button: true,
                  enabled: canCreate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: newColor),
                        const SizedBox(width: 4),
                        Text('New', style: theme.textTheme.labelLarge?.copyWith(color: newColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search notes',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _search.clear,
                    ),
            ),
          ),
        ),
        if (_notepad.offline)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Torn can't be reached - last copy, read only",
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
                TextButton(onPressed: _notepad.load, child: const Text('Retry')),
              ],
            ),
          ),
        Expanded(child: body),
      ],
    );
  }
}

class _AddToNoteSheet extends StatelessWidget {
  const _AddToNoteSheet({required this.notepad});

  final ChatNotepad notepad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
      child: ListenableBuilder(
        listenable: notepad,
        builder: (context, _) {
          final prefs = NativeChat.prefs;
          final notes = ChatNote.arrange(notepad.notes, prefs.noteSort, '', order: prefs.noteOrder);
          final usable = !notepad.offline && !notepad.loadFailed;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('Add to note', style: theme.textTheme.titleMedium),
              ),
              if (!usable)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("Torn can't be reached, try again later", style: theme.textTheme.bodyMedium),
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('New note'),
                  onTap: () => Navigator.of(context).pop((note: null)),
                ),
                if (notepad.loading && notes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final note in notes)
                        ListTile(
                          leading: const Icon(Icons.sticky_note_2_outlined),
                          title: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: note.meta.folder.isEmpty && note.preview.isEmpty
                              ? null
                              : Text(
                                  [
                                    if (note.meta.folder.isNotEmpty) note.meta.folder,
                                    if (note.preview.isNotEmpty) note.preview,
                                  ].join(' - '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: notepad.loading ? null : () => Navigator.of(context).pop((note: note)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ?action,
        ],
      ),
    );
  }
}
