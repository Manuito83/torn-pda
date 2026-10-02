import 'dart:async';

import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_notes_model.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

typedef FFScouterNotesFetch =
    Future<FFScouterResult<FFScouterNotesPage>> Function({List<int>? targets, int? playerId, required int page});

class FFScouterNotesController extends GetxController {
  FFScouterNotesController({FFScouterNotesFetch? fetch, this.batchDelay = const Duration(milliseconds: 400)})
    : _fetchOverride = fetch;

  final FFScouterNotesFetch? _fetchOverride;
  final Duration batchDelay;

  static const int _ttlSeconds = 600;
  static const int _batchSize = 205;
  static const int _maxPages = 5;

  final Map<int, List<FFScouterNote>> _notes = {};
  final Map<int, int> _fetchedAt = {};
  final Set<int> _pending = {};
  final Set<int> _loading = {};
  Timer? _batchTimer;
  int _blockedUntil = 0;

  bool remoteConfigEnabled = true;

  bool _keyProblem = false;
  bool get keyProblem => _keyProblem;

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    Prefs().setFFScouterNotesEnabled(value);
    update();
  }

  bool _preferOnCards = false;
  bool get preferOnCards => _preferOnCards;
  set preferOnCards(bool value) {
    _preferOnCards = value;
    Prefs().setFFScouterNotesPreferOnCards(value);
    update();
  }

  FFScouterNotesInfo? _info;
  FFScouterNotesInfo? get info => _info;
  int _infoFetchedAt = 0;

  int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  bool get active {
    if (!_enabled || !remoteConfigEnabled || _keyProblem) return false;
    if (Get.isRegistered<FFScouterCacheController>() && !Get.find<FFScouterCacheController>().remoteConfigEnabled) {
      return false;
    }
    return true;
  }

  String get _key => Get.find<UserController>().alternativeFFScouterKey;

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  Future<void> _restore() async {
    _enabled = await Prefs().getFFScouterNotesEnabled();
    _preferOnCards = await Prefs().getFFScouterNotesPreferOnCards();
    update();
  }

  List<FFScouterNote> notesFor(int playerId) => _notes[playerId] ?? const [];

  bool isLoading(int playerId) => _loading.contains(playerId) || _pending.contains(playerId);

  bool _isFresh(int playerId) {
    final fetchedAt = _fetchedAt[playerId];
    return fetchedAt != null && _now - fetchedAt < _ttlSeconds;
  }

  Future<FFScouterResult<FFScouterNotesPage>> _fetch({List<int>? targets, int? playerId, required int page}) {
    if (_fetchOverride != null) return _fetchOverride(targets: targets, playerId: playerId, page: page);
    return FFScouterComm.getNotes(key: _key, targets: targets, playerId: playerId, page: page);
  }

  /// Queues [playerId] so that visible cards are fetched together
  void request(int playerId) {
    if (!active || _now < _blockedUntil) return;
    if (_isFresh(playerId) || _loading.contains(playerId) || _pending.contains(playerId)) return;
    _pending.add(playerId);
    _batchTimer ??= Timer(batchDelay, _fetchPending);
  }

  Future<void> _fetchPending() async {
    _batchTimer = null;
    final ids = _pending.toList();
    _pending.clear();
    _loading.addAll(ids);

    for (int i = 0; i < ids.length; i += _batchSize) {
      final chunk = ids.sublist(i, (i + _batchSize).clamp(0, ids.length));
      final error = await _load(chunk, (page) => _fetch(targets: chunk, page: page));
      if (error != null) {
        _loading.removeAll(ids.sublist(i));
        break;
      }
      _loading.removeAll(chunk);
    }
    update();
  }

  /// Fresh fetch for one player. Returns an error message, or null on success
  Future<String?> loadPlayer(int playerId) async {
    if (!active) return null;
    _loading.add(playerId);
    update();
    try {
      return await _load([playerId], (page) => _fetch(playerId: playerId, page: page));
    } finally {
      _loading.remove(playerId);
      update();
    }
  }

  Future<String?> _load(List<int> ids, Future<FFScouterResult<FFScouterNotesPage>> Function(int page) fetchPage) async {
    final found = <int, List<FFScouterNote>>{};
    int page = 1;
    int totalPages = 1;
    while (page <= totalPages && page <= _maxPages) {
      final result = await fetchPage(page);
      if (!result.success || result.data == null) return _handleError(result);
      for (final note in result.data!.notes) {
        if (note.targetType != "player" || note.deletedAt != null) continue;
        found.putIfAbsent(note.targetId, () => []).add(note);
      }
      totalPages = result.data!.totalPages;
      page++;
    }

    final now = _now;
    for (final id in ids) {
      _notes[id] = (found[id] ?? [])..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _fetchedAt[id] = now;
    }
    return null;
  }

  String _handleError(FFScouterResult result) {
    final code = result.errorCode;
    if (code == 1 || code == 2 || code == 6) {
      _keyProblem = true;
      return "Your API key is not registered with FFScouter";
    }
    if (code == 20 || code == 21) {
      final wait = result.retryAfterSeconds ?? 30;
      _blockedUntil = _now + wait;
      return "Too many requests to FFScouter, try again in $wait seconds";
    }
    return result.errorMessage ?? "Error contacting FFScouter";
  }

  Future<FFScouterNotesInfo?> loadInfo({bool force = false}) async {
    if (!active) return _info;
    if (!force && _info != null && _now - _infoFetchedAt < _ttlSeconds) return _info;
    final result = await FFScouterComm.getNotesInfo(key: _key);
    if (result.success && result.data != null) {
      _info = result.data;
      _infoFetchedAt = _now;
      update();
    } else {
      _handleError(result);
    }
    return _info;
  }

  /// Returns an error message, or null when the note was created
  Future<String?> create({required int playerId, required String scope, required String content}) async {
    final result = await FFScouterComm.createNote(key: _key, playerId: playerId, scope: scope, content: content);
    if (!result.success || result.data == null) return _handleError(result);
    final note = result.data!;
    final mine = FFScouterNote(
      uuid: note.uuid,
      scope: note.scope,
      targetType: note.targetType,
      targetId: note.targetId,
      content: note.content,
      createdAt: note.createdAt,
      authorName: note.authorName,
      canSoftDelete: true,
    );
    _notes[playerId] = [mine, ...notesFor(playerId)];
    _infoFetchedAt = 0;
    update();
    await loadPlayer(playerId);
    return null;
  }

  Future<String?> delete(FFScouterNote note) async {
    final result = await FFScouterComm.deleteNote(key: _key, uuid: note.uuid);
    if (!result.success && result.errorCode != 52) return _handleError(result);
    _notes[note.targetId] = notesFor(note.targetId).where((n) => n.uuid != note.uuid).toList();
    _infoFetchedAt = 0;
    update();
    return null;
  }

  /// Clears a key problem so that a newly registered key is tried again
  void resetKeyProblem() {
    _keyProblem = false;
    _fetchedAt.clear();
  }
}
