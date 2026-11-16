import 'package:torn_pda/models/chat/chat_html_text.dart';

typedef ChatNoteSave = ({ChatNote? note, bool stale});

enum ChatNoteSort { torn, name, edited, custom }

/// Plain text, or a task when [done] is set
typedef ChatNoteBlock = ({String text, int line, bool? done});

class ChatNote {
  final String id;
  final String title;
  final String text;
  final DateTime? updatedAt;
  final bool selected;

  const ChatNote({required this.id, required this.title, required this.text, this.updatedAt, this.selected = false});

  static ChatNote? fromTorn(dynamic json) {
    if (json is! Map || json['id'] == null) return null;
    final updated = json['updatedAt'];
    return ChatNote(
      id: '${json['id']}',
      title: _clean(json['title']),
      text: _clean(json['content']),
      // Seconds or milliseconds
      updatedAt: updated is num && updated > 0
          ? DateTime.fromMillisecondsSinceEpoch(updated > 1e11 ? updated.toInt() : updated.toInt() * 1000)
          : null,
      selected: json['isSelected'] == true,
    );
  }

  // Old notes keep a literal \n
  static String _clean(dynamic raw) =>
      chatHtmlUnescape('${raw ?? ''}'.replaceAll(RegExp(r'(\\r)?\\n', caseSensitive: false), '\n'));

  ChatNote copyWith({String? title, String? text, DateTime? updatedAt, bool? selected}) => ChatNote(
    id: id,
    title: title ?? this.title,
    text: text ?? this.text,
    updatedAt: updatedAt ?? this.updatedAt,
    selected: selected ?? this.selected,
  );

  String get preview => body.trim().split('\n').first;

  static final RegExp _meta = RegExp(r'^PDA (?:Folder: (.+?)(?: - (Pinned))?|(Pinned))\s*$');

  RegExpMatch? get _metaMatch {
    final cut = text.indexOf('\n');
    return _meta.firstMatch(cut < 0 ? text : text.substring(0, cut));
  }

  /// Hidden first line, synced with Torn
  ({String folder, bool pinned}) get meta {
    final match = _metaMatch;
    return (folder: _tidy(match?.group(1) ?? ''), pinned: match?.group(2) != null || match?.group(3) != null);
  }

  String get body {
    if (_metaMatch == null) return text;
    final cut = text.indexOf('\n');
    return cut < 0 ? '' : text.substring(cut + 1);
  }

  ChatNote withBody(String body) => copyWith(text: compose(meta.folder, meta.pinned, body));

  ChatNote withMeta({String? folder, bool? pinned}) =>
      copyWith(text: compose(folder ?? meta.folder, pinned ?? meta.pinned, body));

  static String compose(String folder, bool pinned, String body) {
    final path = _tidy(folder);
    final line = path.isNotEmpty ? 'PDA Folder: $path${pinned ? ' - Pinned' : ''}' : (pinned ? 'PDA Pinned' : null);
    if (line == null) return body;
    return body.isEmpty ? line : '$line\n$body';
  }

  static const int maxFolderDepth = 3;

  // Kept whole, cut when moved here
  static String _tidy(String path) => path.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).join('/');

  static String cleanFolder(String path) => _tidy(path).split('/').take(maxFolderDepth).join('/');

  /// Custom keeps [order], the rest go by name
  static List<({String name, int count})> arrangeFolders(
    List<({String name, int count})> folders,
    String path,
    ChatNoteSort sort,
    List<String> order,
  ) {
    String full(String name) => path.isEmpty ? name : '$path/$name';
    final place = {for (final (i, p) in order.indexed) p: i};
    return [...folders]..sort((a, b) {
      if (sort == ChatNoteSort.custom) {
        final byPlace = (place[full(a.name)] ?? order.length).compareTo(place[full(b.name)] ?? order.length);
        if (byPlace != 0) return byPlace;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  /// Keeps the order of folders not [shown]
  static List<String> movedFolders(List<String> shown, int from, int to, List<String> order) {
    final paths = [...shown];
    paths.insert(to.clamp(0, paths.length - 1), paths.removeAt(from));
    return [...order.where((p) => !paths.contains(p)), ...paths];
  }

  /// Notes in [path] and subfolder counts
  static ({List<({String name, int count})> folders, List<ChatNote> notes}) inside(List<ChatNote> notes, String path) {
    final counts = <String, int>{};
    final here = <ChatNote>[];
    for (final note in notes) {
      final folder = note.meta.folder;
      if (folder == path) {
        here.add(note);
        continue;
      }
      final rest = path.isEmpty ? folder : (folder.startsWith('$path/') ? folder.substring(path.length + 1) : '');
      if (rest.isEmpty) continue;
      final name = rest.split('/').first;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final names = counts.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return (folders: [for (final name in names) (name: name, count: counts[name]!)], notes: here);
  }

  static List<String> allFolders(List<ChatNote> notes) {
    final paths = <String>{};
    for (final note in notes) {
      final parts = note.meta.folder.split('/');
      for (var i = 1; i <= parts.length; i++) {
        final path = parts.take(i).join('/');
        if (path.isNotEmpty) paths.add(path);
      }
    }
    return paths.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Map<String, Object?> toCache() => {
    'id': id,
    'title': title,
    'text': text,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
    'selected': selected,
  };

  static ChatNote? fromCache(dynamic json) {
    if (json is! Map || json['id'] is! String) return null;
    final updated = json['updatedAt'];
    return ChatNote(
      id: json['id'] as String,
      title: '${json['title'] ?? ''}',
      text: '${json['text'] ?? ''}',
      updatedAt: updated is int ? DateTime.fromMillisecondsSinceEpoch(updated) : null,
      selected: json['selected'] == true,
    );
  }

  /// Pinned first, then [sort]
  static List<ChatNote> arrange(
    List<ChatNote> notes,
    ChatNoteSort sort,
    String query, {
    List<String> order = const [],
  }) {
    final wanted = query.trim().toLowerCase();
    final found = [
      for (final note in notes)
        if (wanted.isEmpty || '${note.title}\n${note.body}'.toLowerCase().contains(wanted)) note,
    ];
    final torn = {for (final (i, note) in notes.indexed) note.id: i};
    final custom = {for (final (i, id) in order.indexed) id: i};
    int place(ChatNote note) => custom[note.id] ?? order.length + torn[note.id]!;

    int compare(ChatNote a, ChatNote b) => switch (sort) {
      ChatNoteSort.torn => torn[a.id]!.compareTo(torn[b.id]!),
      ChatNoteSort.name => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      // Undated notes go last
      ChatNoteSort.edited => (b.updatedAt?.millisecondsSinceEpoch ?? 0).compareTo(
        a.updatedAt?.millisecondsSinceEpoch ?? 0,
      ),
      ChatNoteSort.custom => place(a).compareTo(place(b)),
    };
    found.sort((a, b) {
      final pin = (b.meta.pinned ? 1 : 0) - (a.meta.pinned ? 1 : 0);
      return pin != 0 ? pin : compare(a, b);
    });
    return found;
  }

  /// Never across the pinned line
  /// Keeps the order of notes not [shown]
  static List<String> moved(List<ChatNote> shown, int from, int to, {List<String> order = const []}) {
    final ids = [for (final note in shown) note.id];
    final top = shown.where((n) => n.meta.pinned).length;
    final target = shown[from].meta.pinned ? to.clamp(0, top - 1) : to.clamp(top, ids.length - 1);
    ids.insert(target, ids.removeAt(from));
    return [...order.where((id) => !ids.contains(id)), ...ids];
  }

  String get firstLine =>
      blocks(
        body,
      ).where((b) => b.done == null && b.text.trim().isNotEmpty).firstOrNull?.text.trim().split('\n').first ??
      '';

  static ({int done, int total}) tasks(String text) {
    final tasks = blocks(text).where((b) => b.done != null);
    return (done: tasks.where((b) => b.done!).length, total: tasks.length);
  }

  static final RegExp _task = RegExp(r'^\s*- \[( |x|X)\] ?(.*)$');

  static List<ChatNoteBlock> blocks(String text) {
    final blocks = <ChatNoteBlock>[];
    final plain = <String>[];
    var start = 0;
    void flush() {
      if (plain.isNotEmpty) blocks.add((text: plain.join('\n'), line: start, done: null));
      plain.clear();
    }

    final lines = text.split('\n');
    for (final (i, line) in lines.indexed) {
      final task = _task.firstMatch(line);
      if (task == null) {
        if (plain.isEmpty) start = i;
        plain.add(line);
        continue;
      }
      flush();
      blocks.add((text: task.group(2)!, line: i, done: task.group(1) != ' '));
    }
    flush();
    return blocks;
  }

  static String toggleTask(String text, int line) {
    final lines = text.split('\n');
    if (line < 0 || line >= lines.length) return text;
    final task = _task.firstMatch(lines[line]);
    if (task == null) return text;
    final done = task.group(1) != ' ';
    lines[line] = lines[line].replaceFirst(done ? RegExp(r'\[(x|X)\]') : '[ ]', done ? '[ ]' : '[x]');
    return lines.join('\n');
  }

  // After any selection, never cutting a line
  static ({String text, int cursor}) insertLine(String text, int start, int end, String line) {
    final at = end.clamp(0, text.length);
    final before = text.substring(0, at);
    final after = text.substring(at);
    final lead = before.isEmpty || before.endsWith('\n') ? '' : '\n';
    final tail = after.isEmpty || after.startsWith('\n') ? '' : '\n';
    return (text: '$before$lead$line$tail$after', cursor: at + lead.length + line.length);
  }

  static String appended(String text, String line) {
    final kept = text.trimRight();
    return kept.isEmpty ? line : '$kept\n$line';
  }
}
