import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_notepad.dart';
import 'package:torn_pda/providers/chat/chat_notepad.dart';
import 'package:torn_pda/widgets/chat/chat_note_view.dart';

import 'chat_fakes.dart';

class _NotesSource extends FakeChatSource {
  List<ChatNote>? stored = [];
  final List<ChatNote> saves = [];
  Completer<ChatNoteSave>? hold;
  Completer<List<ChatNote>?>? holdList;
  ChatNoteSave? answer;
  bool deletes = true;

  @override
  Future<List<ChatNote>?> notes() async => holdList?.future ?? stored;

  @override
  Future<ChatNoteSave> saveNote(ChatNote note, Duration age) async {
    saves.add(note);
    final held = hold;
    if (held != null) return held.future;
    return answer ?? (note: note, stale: false);
  }

  @override
  Future<bool> deleteNote(String id) async => deletes;

  @override
  Future<ChatNote?> createNote(String title, String text) async => ChatNote(id: '9', title: title, text: text);
}

const _a = ChatNote(id: '1', title: 'Loot', text: 'old');
const _b = ChatNote(id: '2', title: 'Targets', text: '');

void main() {
  group('reading Torn notes', () {
    test('undoes Torn escaping and old literal line breaks', () {
      final note = ChatNote.fromTorn({
        'id': 7,
        'title': 'Bob&#039;s list',
        'content': r'first\nsecond\r\nthird &amp; <b>',
        'updatedAt': 1763200000000,
        'isSelected': true,
      })!;
      expect(note.id, '7');
      expect(note.title, "Bob's list");
      expect(note.text, 'first\nsecond\nthird & <b>');
      expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(1763200000000));
      expect(note.selected, isTrue);
    });

    test('accepts the stamp in seconds', () {
      final note = ChatNote.fromTorn({'id': '1', 'updatedAt': 1763200000})!;
      expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(1763200000000));
    });

    test('old notes come with a zero stamp', () {
      expect(ChatNote.fromTorn({'id': '63a09b53aa470f88e237bd57', 'updatedAt': 0})!.updatedAt, isNull);
    });
  });

  group('the list', () {
    const old = ChatNote(id: '3', title: 'banking', text: 'Xanax at 830k');
    final recent = ChatNote(id: '4', title: 'Alpha', text: 'chain', updatedAt: DateTime(2026, 11));
    final older = ChatNote(id: '5', title: 'zebra', text: '', updatedAt: DateTime(2026, 10));

    test('searches title and text, any case', () {
      expect(ChatNote.arrange([old, recent, older], ChatNoteSort.torn, 'XAN'), [old]);
      expect(ChatNote.arrange([old, recent, older], ChatNoteSort.torn, 'alp'), [recent]);
    });

    test('sorts by name or by last edit, undated last', () {
      expect(ChatNote.arrange([older, old, recent], ChatNoteSort.name, ''), [recent, old, older]);
      expect(ChatNote.arrange([old, older, recent], ChatNoteSort.edited, ''), [recent, older, old]);
      expect(ChatNote.arrange([older, old, recent], ChatNoteSort.torn, ''), [older, old, recent]);
    });
  });

  group('pins and custom order', () {
    const a = ChatNote(id: 'a', title: 'A', text: '');
    const b = ChatNote(id: 'b', title: 'B', text: '');
    const c = ChatNote(id: 'c', title: 'C', text: '');
    const pinnedC = ChatNote(id: 'c', title: 'C', text: 'PDA Pinned');
    const pinnedA = ChatNote(id: 'a', title: 'A', text: 'PDA Pinned');

    test('pinned notes go first, whatever the sort', () {
      expect(ChatNote.arrange([a, b, pinnedC], ChatNoteSort.name, ''), [pinnedC, a, b]);
    });

    test('custom order keeps unsorted notes last in Torn order', () {
      expect(ChatNote.arrange([a, b, c], ChatNoteSort.custom, '', order: ['c', 'a']).map((n) => n.id), ['c', 'a', 'b']);
    });

    test('a note never moves across the pinned line', () {
      expect(ChatNote.moved([pinnedA, b, c], 2, 0), ['a', 'c', 'b']);
      expect(ChatNote.moved([pinnedA, b, c], 0, 2), ['a', 'b', 'c']);
      expect(ChatNote.moved([a, b, c], 2, 0), ['c', 'a', 'b']);
    });

    test('moving inside a folder keeps the order of the others', () {
      expect(ChatNote.moved([a, b], 1, 0, order: ['x', 'a', 'y', 'b']), ['x', 'y', 'b', 'a']);
    });
  });

  group('folder limits and order', () {
    test('folders stop at three levels, but a deeper one from the web is kept', () {
      expect(ChatNote.cleanFolder('a/b/c/d'), 'a/b/c');
      const deep = ChatNote(id: '1', title: '', text: 'PDA Folder: a/b/c/d\nx');
      expect(deep.meta.folder, 'a/b/c/d');
      expect(deep.withBody('y').text, 'PDA Folder: a/b/c/d\ny');
    });

    test('custom puts folders in the saved order, the rest by name', () {
      const folders = [(name: 'Bank', count: 1), (name: 'Raids', count: 2), (name: 'Alts', count: 1)];
      final custom = ChatNote.arrangeFolders(folders, '', ChatNoteSort.custom, ['Raids', 'Bank']);
      expect(custom.map((f) => f.name), ['Raids', 'Bank', 'Alts']);
      expect(ChatNote.arrangeFolders(folders, '', ChatNoteSort.name, ['Raids']).map((f) => f.name), [
        'Alts',
        'Bank',
        'Raids',
      ]);
    });

    test('moving a folder keeps the order of the others', () {
      expect(ChatNote.movedFolders(['A/x', 'A/y'], 1, 0, ['B', 'A/x', 'A/y']), ['B', 'A/y', 'A/x']);
    });
  });

  group('folder and pin line', () {
    test('reads folder and pin, and hides the line', () {
      const note = ChatNote(id: '1', title: 'Plan', text: 'PDA Folder: Raids / Weekly - Pinned\nhit at 20:00');
      expect(note.meta, (folder: 'Raids/Weekly', pinned: true));
      expect(note.body, 'hit at 20:00');
      expect(const ChatNote(id: '1', title: '', text: 'PDA Pinned').meta, (folder: '', pinned: true));
      expect(const ChatNote(id: '1', title: '', text: 'PDA rocks\nx').body, 'PDA rocks\nx');
      expect(const ChatNote(id: '1', title: '', text: 'PDA Folder: NotPinned').meta, (
        folder: 'NotPinned',
        pinned: false,
      ));
      expect(const ChatNote(id: '1', title: '', text: 'PDA Folder: Weekly Pinned').meta, (
        folder: 'Weekly Pinned',
        pinned: false,
      ));
    });

    test('writes it back only when there is something to keep', () {
      const note = ChatNote(id: '1', title: 'Plan', text: 'hit at 20:00');
      expect(note.withMeta(folder: 'Raids').text, 'PDA Folder: Raids\nhit at 20:00');
      expect(note.withMeta(pinned: true).text, 'PDA Pinned\nhit at 20:00');
      expect(note.withMeta(folder: 'Raids', pinned: true).withMeta(folder: '', pinned: false).text, 'hit at 20:00');
      expect(note.withMeta(folder: 'Raids').withBody('new').text, 'PDA Folder: Raids\nnew');
    });

    test('lists subfolders with their count and the notes right inside', () {
      const loose = ChatNote(id: '1', title: '', text: 'x');
      const raids = ChatNote(id: '2', title: '', text: 'PDA Folder: Raids');
      const weekly = ChatNote(id: '3', title: '', text: 'PDA Folder: Raids/Weekly');
      const banking = ChatNote(id: '4', title: '', text: 'PDA Folder: banking');
      final notes = [loose, raids, weekly, banking];
      final root = ChatNote.inside(notes, '');
      expect(root.folders, [(name: 'banking', count: 1), (name: 'Raids', count: 2)]);
      expect(root.notes, [loose]);
      final inRaids = ChatNote.inside(notes, 'Raids');
      expect(inRaids.folders, [(name: 'Weekly', count: 1)]);
      expect(inRaids.notes, [raids]);
      expect(ChatNote.allFolders(notes), ['banking', 'Raids', 'Raids/Weekly']);
    });
  });

  group('tasks', () {
    test('counts done tasks', () {
      expect(ChatNote.tasks('- [x] a\n- [ ] b\nnote\n- [X] c'), (done: 2, total: 3));
    });

    const text = 'Tonight\n- [ ] hit Bob\n- [x] bank\nthanks';

    test('split into text and tasks', () {
      expect(ChatNote.blocks(text), [
        (text: 'Tonight', line: 0, done: null),
        (text: 'hit Bob', line: 1, done: false),
        (text: 'bank', line: 2, done: true),
        (text: 'thanks', line: 3, done: null),
      ]);
    });

    test('toggle only that line', () {
      expect(ChatNote.toggleTask(text, 1), 'Tonight\n- [x] hit Bob\n- [x] bank\nthanks');
      expect(ChatNote.toggleTask(text, 2), 'Tonight\n- [ ] hit Bob\n- [ ] bank\nthanks');
      expect(ChatNote.toggleTask(text, 0), text);
    });

    test('a new line starts where the cursor is', () {
      expect(ChatNote.insertLine('', 0, 0, '- [ ] '), (text: '- [ ] ', cursor: 6));
      expect(ChatNote.insertLine('buy', 3, 3, '- [ ] '), (text: 'buy\n- [ ] ', cursor: 10));
      expect(ChatNote.insertLine('a\nb', 2, 2, 'x'), (text: 'a\nx\nb', cursor: 3));
      expect(ChatNote.insertLine('abcdef', 3, 3, 'x'), (text: 'abc\nx\ndef', cursor: 5));
      expect(ChatNote.insertLine('keep this', 0, 4, 'x'), (text: 'keep\nx\n this', cursor: 6));
    });
  });

  group('offline', () {
    test('keeps the last copy for offline', () async {
      var cache = '';
      Future<String> read() async => cache;
      Future<void> write(String value) async => cache = value;
      final source = _NotesSource()..stored = [_a, _b];
      await ChatNotepad(source, readCache: read, writeCache: write).load();

      source.stored = null;
      final later = ChatNotepad(source, readCache: read, writeCache: write);
      await later.load();
      expect(later.offline, isTrue);
      expect(later.loadFailed, isFalse);
      expect(later.notes.map((n) => n.text), ['old', '']);

      await later.load();
      expect(later.offline, isTrue);

      later.forget();
      await pumpEventQueue();
      expect(cache, isEmpty);
    });
  });

  group('saving', () {
    late _NotesSource source;
    late ChatNotepad notepad;

    setUp(() async {
      source = _NotesSource()..stored = [_a, _b];
      notepad = ChatNotepad(source, delay: const Duration(hours: 1));
      await notepad.load();
    });

    test('one save at a time, latest text wins', () async {
      source.hold = Completer();
      notepad.edit(_a.copyWith(text: 'one'));
      final first = notepad.save();
      notepad.edit(_a.copyWith(text: 'two'));
      await notepad.save();
      expect(source.saves.map((n) => n.text), ['one']);

      source.hold!.complete((note: _a.copyWith(text: 'one'), stale: false));
      source.hold = null;
      await first;
      await notepad.save();
      expect(source.saves.map((n) => n.text), ['one', 'two']);
      expect(notepad.notes.first.text, 'two');
    });

    test('an edit on another note during a save is not lost', () async {
      source.hold = Completer();
      notepad.edit(_a.copyWith(text: 'mine'));
      final first = notepad.save();
      notepad.edit(_b.copyWith(text: 'hit list'));
      source.hold!.complete((note: _a.copyWith(text: 'mine'), stale: false));
      source.hold = null;
      await first;
      await notepad.save();
      expect(source.saves.map((n) => n.text), ['mine', 'hit list']);
    });

    test('a failed save keeps the text for Retry', () async {
      source.answer = (note: null, stale: false);
      notepad.edit(_a.copyWith(text: 'keep me'));
      await notepad.save();
      expect(notepad.saveFailed, isTrue);
      expect(notepad.dirty, isTrue);

      source.answer = null;
      await notepad.save();
      expect(notepad.saveFailed, isFalse);
      expect(notepad.dirty, isFalse);
      expect(source.saves.map((n) => n.text), ['keep me', 'keep me']);
    });

    test('Keep mine after a refused save', () async {
      source.answer = (note: null, stale: true);
      source.stored = [_a.copyWith(text: 'from the web'), _b];
      notepad.edit(_a.copyWith(text: 'from the phone'));
      await notepad.save();
      expect(notepad.theirs?.text, 'from the web');

      notepad.edit(_a.copyWith(text: 'from the phone, more'));
      expect(source.saves, hasLength(1));

      source.answer = null;
      notepad.keepMine();
      await notepad.save();
      expect(notepad.theirs, isNull);
      expect(source.saves.last.text, 'from the phone, more');
    });

    test('Load that one drops our text', () async {
      source.answer = (note: null, stale: true);
      source.stored = [_a.copyWith(text: 'from the web'), _b];
      notepad.edit(_a.copyWith(text: 'from the phone'));
      await notepad.save();

      expect(notepad.useTheirs()?.text, 'from the web');
      expect(notepad.dirty, isFalse);
      expect(notepad.notes.first.text, 'from the web');
    });

    test('a note deleted elsewhere does not hold back the others', () async {
      source.answer = (note: null, stale: false);
      notepad.edit(_a.copyWith(text: 'lost'));
      await notepad.save();
      notepad.edit(_b.copyWith(text: 'kept'));

      source.answer = null;
      source.stored = [_b];
      await notepad.load();
      await pumpEventQueue();
      expect(source.saves.map((n) => n.text), ['lost', 'kept']);
      expect(notepad.dirty, isFalse);
    });

    test('reopening during a refused save still shows our text', () async {
      source.answer = (note: null, stale: true);
      source.stored = [_a.copyWith(text: 'from the web'), _b];
      notepad.edit(_a.copyWith(text: 'from the phone'));
      await notepad.save();

      await notepad.load();
      expect(notepad.notes.first.text, 'from the phone');
      expect(notepad.theirs?.text, 'from the web');
    });

    test('reopening while a save is on its way keeps the sent text', () async {
      source.hold = Completer();
      notepad.edit(_a.copyWith(text: 'sent'));
      final sending = notepad.save();

      await notepad.load();
      expect(notepad.notes.first.text, 'sent');
      source.hold!.complete((note: _a.copyWith(text: 'sent'), stale: false));
      await sending;
    });

    test('another account starts with nothing to save', () async {
      notepad.edit(_a.copyWith(text: 'old account'));
      notepad.forget();
      await notepad.save();
      expect(source.saves, isEmpty);
      expect(notepad.notes, isEmpty);
    });

    test('the old account list never lands after a switch', () async {
      source.holdList = Completer();
      final loading = notepad.load();
      notepad.forget();
      source.holdList!.complete([_a, _b]);
      await loading;
      expect(notepad.notes, isEmpty);
      expect(notepad.loading, isFalse);
    });

    test('a note deleted elsewhere clears its conflict', () async {
      source.answer = (note: null, stale: true);
      source.stored = [_a.copyWith(text: 'from the web'), _b];
      notepad.edit(_a.copyWith(text: 'from the phone'));
      await notepad.save();

      source.stored = [_b];
      await notepad.load();
      expect(notepad.theirs, isNull);
    });

    test('a failed delete keeps the unsaved edit', () async {
      source.deletes = false;
      notepad.edit(_a.copyWith(text: 'still here'));
      expect(await notepad.delete(_a.id), isFalse);
      expect(notepad.dirty, isTrue);
      await notepad.save();
      expect(source.saves.single.text, 'still here');
    });

    test('a chat line waits for a save already on its way', () async {
      source.hold = Completer();
      notepad.edit(_b.copyWith(text: 'first'));
      final other = notepad.save();
      final added = notepad.append(_a.id, 'line');
      source.hold!.complete((note: _b.copyWith(text: 'first'), stale: false));
      source.hold = null;
      await other;
      expect(await added, isTrue);
      expect(source.saves.map((n) => n.text), ['first', 'old\nline']);
    });

    test('a chat line goes at the end, or into a new note', () async {
      expect(await notepad.append(_a.id, '[14:05 TCT] Bob: hi'), isTrue);
      expect(source.saves.single.text, 'old\n[14:05 TCT] Bob: hi');

      expect(await notepad.append(null, '[14:06 TCT] Bob: bye'), isTrue);
      expect(notepad.notes.first.text, '[14:06 TCT] Bob: bye');
    });

    test('deleting a note drops its unsaved edit', () async {
      notepad.edit(_a.copyWith(text: 'gone'));
      await notepad.delete(_a.id);
      await notepad.save();
      expect(source.saves, isEmpty);
      expect(notepad.notes.map((n) => n.id), [_b.id]);
    });
  });

  testWidgets('copies the note with or without its title', (tester) async {
    final copied = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    const note = ChatNote(id: '1', title: 'Loot', text: 'PDA Pinned\nXanax 800k');
    await tester.pumpWidget(
      MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(onPressed: () => chatShareNote(context, note), child: const Text('share')),
          ),
        ),
      ),
    );
    for (final option in ['Copy only content', 'Copy with title']) {
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    expect(copied, ['Xanax 800k', 'Loot\n\nXanax 800k']);
  });
}
