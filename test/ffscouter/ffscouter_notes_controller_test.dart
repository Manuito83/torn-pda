import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_notes_model.dart';
import 'package:torn_pda/providers/ffscouter_notes_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';

/// Tests for [FFScouterNotesController] with the notes call injected

int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

FFScouterNote _note(int target, String content, {int age = 0, String scope = "faction"}) => FFScouterNote(
  uuid: "$target-$content",
  scope: scope,
  targetType: "player",
  targetId: target,
  content: content,
  createdAt: _now - age,
);

class _FakeNotesApi {
  _FakeNotesApi(this.notes, {this.pageSize = 100});

  final List<FFScouterNote> notes;
  final int pageSize;
  int? errorCode;
  final List<({List<int>? targets, int? playerId, int page})> calls = [];

  Future<FFScouterResult<FFScouterNotesPage>> fetch({List<int>? targets, int? playerId, required int page}) async {
    calls.add((targets: targets, playerId: playerId, page: page));
    if (errorCode != null) {
      return FFScouterResult(success: false, errorCode: errorCode, errorMessage: "error $errorCode");
    }
    final ids = playerId != null ? [playerId] : targets!;
    final matching = notes.where((n) => ids.contains(n.targetId)).toList();
    final totalPages = (matching.length / pageSize).ceil();
    final pageNotes = matching.skip((page - 1) * pageSize).take(pageSize).toList();
    return FFScouterResult(
      success: true,
      data: FFScouterNotesPage(notes: pageNotes, totalPages: totalPages),
    );
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('cards asking at the same time share one call', () async {
    final api = _FakeNotesApi([_note(1, "a"), _note(3, "b")]);
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    ctrl.request(1);
    ctrl.request(2);
    ctrl.request(3);
    ctrl.request(2);
    await _settle();

    expect(api.calls.length, 1);
    expect(api.calls.single.targets, [1, 2, 3]);
    expect(ctrl.notesFor(1).single.content, "a");
    expect(ctrl.notesFor(2), isEmpty);
    expect(ctrl.notesFor(3).single.content, "b");
  });

  test('players already fetched are not asked again, including those without notes', () async {
    final api = _FakeNotesApi([_note(1, "a")]);
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    ctrl.request(1);
    ctrl.request(2);
    await _settle();
    ctrl.request(1);
    ctrl.request(2);
    await _settle();

    expect(api.calls.length, 1);
  });

  test('every page is read and notes come newest first', () async {
    final api = _FakeNotesApi([_note(1, "old", age: 500), _note(1, "new", age: 10), _note(2, "c")], pageSize: 1);
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    ctrl.request(1);
    ctrl.request(2);
    await _settle();

    expect(api.calls.map((c) => c.page), [1, 2, 3]);
    expect(ctrl.notesFor(1).map((n) => n.content), ["new", "old"]);
    expect(ctrl.notesFor(2).single.content, "c");
  });

  test('more than 205 players are split in several calls', () async {
    final api = _FakeNotesApi([]);
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    for (int id = 1; id <= 300; id++) {
      ctrl.request(id);
    }
    await _settle();

    expect(api.calls.map((c) => c.targets!.length), [205, 95]);
  });

  test('an unregistered key stops further calls', () async {
    final api = _FakeNotesApi([])..errorCode = 6;
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    ctrl.request(1);
    await _settle();
    ctrl.request(2);
    await _settle();

    expect(ctrl.keyProblem, isTrue);
    expect(api.calls.length, 1);
  });

  test('rate limits pause requests', () async {
    final api = _FakeNotesApi([])..errorCode = 20;
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    ctrl.request(1);
    await _settle();
    api.errorCode = null;
    ctrl.request(1);
    await _settle();

    expect(api.calls.length, 1);
    expect(ctrl.isLoading(1), isFalse);
  });

  test('opening a player always reads it again', () async {
    final api = _FakeNotesApi([_note(1, "a")]);
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    ctrl.request(1);
    await _settle();
    final error = await ctrl.loadPlayer(1);

    expect(error, isNull);
    expect(api.calls.length, 2);
    expect(api.calls.last.playerId, 1);
  });

  test('deleted notes are not shown', () async {
    final deleted = FFScouterNote(
      uuid: "x",
      scope: "personal",
      targetType: "player",
      targetId: 1,
      content: "gone",
      createdAt: _now,
      deletedAt: _now,
    );
    final api = _FakeNotesApi([deleted, _note(1, "kept")]);
    final ctrl = FFScouterNotesController(fetch: api.fetch, batchDelay: Duration.zero);

    await ctrl.loadPlayer(1);

    expect(ctrl.notesFor(1).single.content, "kept");
  });
}
