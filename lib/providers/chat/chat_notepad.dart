import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/chat/chat_notepad.dart';
import 'package:torn_pda/models/chat/chat_source.dart';

typedef _Edit = ({ChatNote note, DateTime at});

class ChatNotepad extends ChangeNotifier {
  ChatNotepad(this._source, {this.delay = const Duration(milliseconds: 1500), this.readCache, this.writeCache});

  final ChatSource _source;
  final Duration delay;
  final Future<String> Function()? readCache;
  final Future<void> Function(String)? writeCache;

  List<ChatNote> notes = const [];
  bool loading = false;
  bool loadFailed = false;
  bool saveFailed = false;

  /// Last copy shown, read only
  bool offline = false;

  /// Torn's copy after it refused ours
  ChatNote? theirs;
  ChatNote? _mine;

  final Map<String, _Edit> _pending = {};
  _Edit? _sending;
  Completer<void>? _saved;
  Timer? _timer;

  // Bumped when the account changes
  int _account = 0;

  bool get dirty => _pending.isNotEmpty || _sending != null;

  Future<void> load() async {
    if (loading) return;
    final account = _account;
    loading = true;
    loadFailed = false;
    notifyListeners();
    final list = await _source.notes();
    if (account != _account) return;
    final cached = list == null && notes.isEmpty ? await _cached() : const <ChatNote>[];
    if (account != _account) return;
    loading = false;
    offline = list == null && (offline || cached.isNotEmpty);
    loadFailed = list == null && !offline;
    if (offline) notes = cached;
    if (list != null) {
      final ids = {for (final note in list) note.id};
      _pending.removeWhere((id, _) => !ids.contains(id));
      if (theirs != null && !ids.contains(theirs!.id)) {
        theirs = null;
        _mine = null;
      }
      notes = [for (final note in list) _local(note.id) ?? note];
      _store();
    }
    notifyListeners();
    if (_pending.isNotEmpty) unawaited(save());
  }

  Future<List<ChatNote>> _cached() async {
    try {
      final raw = jsonDecode(await readCache?.call() ?? '');
      return raw is List ? raw.map(ChatNote.fromCache).whereType<ChatNote>().toList() : const [];
    } catch (_) {
      return const [];
    }
  }

  void _store() => unawaited(writeCache?.call(jsonEncode([for (final note in notes) note.toCache()])));

  ChatNote? _local(String id) {
    final sending = _sending?.note;
    final mine = _mine;
    return _pending[id]?.note ?? (mine?.id == id ? mine : null) ?? (sending?.id == id ? sending : null);
  }

  Future<ChatNote?> create({String title = 'Note', String text = ''}) async {
    final account = _account;
    final note = await _source.createNote(title, text);
    if (note == null || account != _account) return null;
    notes = [note, ...notes.where((n) => n.id != note.id)];
    _store();
    notifyListeners();
    return note;
  }

  /// A new note when [id] is null
  Future<bool> append(String? id, String line) async {
    if (id == null) return await create(title: 'From chat', text: line) != null;
    final note = notes.where((n) => n.id == id).firstOrNull;
    if (note == null) return false;
    edit(note.copyWith(text: ChatNote.appended(note.text, line)));
    // Others may be ahead in the queue
    while (_pending.containsKey(id) && !saveFailed && theirs?.id != id) {
      await (_sending == null ? save() : _saved!.future);
    }
    return !_pending.containsKey(id) && theirs?.id != id;
  }

  Future<ChatNote?> duplicate(ChatNote note) =>
      create(title: '${note.title} (copy)', text: note.withMeta(pinned: false).text);

  void open(ChatNote note) {
    notes = [for (final n in notes) n.copyWith(selected: n.id == note.id)];
    notifyListeners();
    unawaited(_source.selectNote(note.id));
  }

  void edit(ChatNote note) {
    _replace(note);
    if (theirs?.id == note.id) {
      _mine = note;
    } else {
      _pending[note.id] = (note: note, at: DateTime.now());
      saveFailed = false;
      _schedule();
    }
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(delay, save);
  }

  Future<void> save() async {
    _timer?.cancel();
    if (_sending != null || _pending.isEmpty) return;
    final account = _account;
    final id = _pending.keys.first;
    final edit = _pending.remove(id)!;
    _sending = edit;
    final saved = _saved = Completer<void>();
    saveFailed = false;
    notifyListeners();
    final result = await _source.saveNote(edit.note, DateTime.now().difference(edit.at));
    if (account != _account) return saved.complete();
    if (result.stale) {
      await _loadTheirs(edit);
      if (account != _account) return saved.complete();
    } else if (result.note == null) {
      _pending.putIfAbsent(id, () => edit);
      saveFailed = true;
    } else if (!_pending.containsKey(id)) {
      _replace(result.note!.copyWith(selected: edit.note.selected));
      _store();
    }
    _sending = null;
    saved.complete();
    notifyListeners();
    if (_pending.isNotEmpty && !saveFailed) _schedule();
  }

  Future<void> _loadTheirs(_Edit edit) async {
    final account = _account;
    final list = await _source.notes();
    if (account != _account) return;
    if (list == null) {
      _pending.putIfAbsent(edit.note.id, () => edit);
      saveFailed = true;
      return;
    }
    final found = list.where((n) => n.id == edit.note.id).firstOrNull;
    final mine = _pending.remove(edit.note.id)?.note ?? edit.note;
    if (found == null) return;
    _mine = mine;
    theirs = found;
  }

  void keepMine() {
    final mine = _mine;
    theirs = null;
    _mine = null;
    if (mine != null) edit(mine);
  }

  ChatNote? useTheirs() {
    final note = theirs;
    theirs = null;
    _mine = null;
    if (note != null) _replace(note);
    notifyListeners();
    return note;
  }

  Future<bool> delete(String id) async {
    final account = _account;
    final unsaved = _pending.remove(id);
    final ok = await _source.deleteNote(id);
    if (account != _account) return ok;
    if (ok) {
      notes = notes.where((n) => n.id != id).toList();
      _store();
      if (theirs?.id == id) {
        theirs = null;
        _mine = null;
      }
    } else if (unsaved != null) {
      _pending.putIfAbsent(id, () => unsaved);
      _schedule();
    }
    notifyListeners();
    return ok;
  }

  void forget() {
    _account++;
    _timer?.cancel();
    _pending.clear();
    _sending = null;
    notes = const [];
    theirs = null;
    _mine = null;
    loading = false;
    loadFailed = false;
    saveFailed = false;
    offline = false;
    unawaited(writeCache?.call(''));
    notifyListeners();
  }

  void _replace(ChatNote note) {
    notes = [for (final n in notes) n.id == note.id ? note : n];
  }
}
