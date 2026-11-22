import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/territory_map/territory_map_files.dart';

// Open day republished every 8 min
const _refreshEvery = Duration(minutes: 8);
const _yearsEvery = Duration(hours: 1);

class TerritoryHistoryController extends ChangeNotifier {
  TerritoryHistoryController({TerritoryMapFiles? files, DateTime Function()? clock})
    : _files = files ?? TerritoryMapFiles(),
      _clock = clock ?? DateTime.now;

  final TerritoryMapFiles _files;
  final DateTime Function() _clock;
  final _prefs = Prefs();

  final _days = <String, DayChanges>{};
  final _etags = <String, String>{};
  final _missing = <String>{};
  final _askedAt = <String, DateTime>{};

  // Saved to disk, never asked again
  final _final = <String>{};
  DateTime? _since;
  DateTime? _oldestWanted;
  Timer? _refreshTimer;
  Future<void> _queue = Future.value();
  final _openPages = <Object>{};
  final _coveredPages = <Object>{};

  final _years = <int, MapHistory>{};
  final _yearEtags = <int, String>{};
  final _finalYears = <int>{};
  DateTime? _yearsAskedAt;
  Future<void>? _yearsLoad;
  int _yearsForgotten = 0;
  MapHistory? _record;
  bool _recordStale = true;
  List<DayChanges>? _sortedDays;
  Map<int, MapFaction>? _factionNames;

  bool loading = false;
  bool loadingYears = false;
  bool yearsFailed = false;
  bool failed = false;

  // Year files and days merged
  MapHistory? get record {
    if (_recordStale) _record = mergeHistory(_years.values, _days.values, DateTime.now().toUtc());
    _recordStale = false;
    return _record;
  }

  // Previous look, null the first time
  DateTime? get since => _since;

  List<DayChanges> get days => _sortedDays ??= List.unmodifiable([
    for (final day in _days.keys.toList()..sort((a, b) => b.compareTo(a))) _days[day]!,
  ]);

  bool get someDaysMissing {
    final oldest = _oldestWanted;
    return !loading && oldest != null && hasMissingDays(diaryDays(oldest, DateTime.now().toUtc()), _missing);
  }

  // Newest first
  List<MapChange> changesSince(DateTime from) => [
    for (final day in days)
      for (final change in day.changes.reversed)
        if (!change.at.isBefore(from)) change,
  ];

  Map<int, MapFaction> get factionNames => _factionNames ??= Map.unmodifiable({
    for (final year in _years.values) ...year.factions,
    for (final day in days.reversed) ...day.factions,
  });

  // Above city.php the look stays put
  Future<void> open(Object page, {bool moveLastLook = true}) async {
    _openPages.add(page);
    _startRefresh();
    final now = DateTime.now().toUtc();
    final saved = await _prefs.getTerritoryMapDiaryLastLook();
    _since = saved == 0 ? null : unixTime(saved);
    if (moveLastLook) await _prefs.setTerritoryMapDiaryLastLook(now.millisecondsSinceEpoch ~/ 1000);
    final oldest = now.subtract(const Duration(days: diaryMaxDays));
    _deleteOlderThan(changesFileName(dayKey(oldest)));
    await load(_since ?? oldest);
  }

  Future<void> _deleteOlderThan(String oldestKept) async {
    try {
      await _files.deleteCached((name) => name.startsWith('changes-') && name.compareTo(oldestKept) < 0);
    } catch (e) {
      debugPrint('territory map: old changes not deleted: $e');
    }
  }

  void close(Object page) {
    _openPages.remove(page);
    _coveredPages.remove(page);
    if (!_seen) pause();
    if (_openPages.isEmpty) _forgetYears();
  }

  // Open but behind the browser
  void cover(Object page) {
    _coveredPages.add(page);
    if (!_seen) pause();
  }

  void uncover(Object page) {
    _coveredPages.remove(page);
    resume();
  }

  bool get _seen => _openPages.any((page) => !_coveredPages.contains(page));

  void pause() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void resume() {
    if (!_seen || _refreshTimer != null) return;
    _startRefresh();
    _refresh();
  }

  void _forgetYears() {
    _yearsForgotten++;
    _years.clear();
    _yearEtags.clear();
    _finalYears.clear();
    _yearsAskedAt = null;
    _record = null;
    _changed();
  }

  void _startRefresh() => _refreshTimer ??= Timer.periodic(_refreshEvery, (_) => _refresh());

  void _refresh() {
    final oldest = _oldestWanted;
    if (oldest != null) load(oldest);
  }

  void retryDays() => _refresh();

  @override
  void dispose() {
    pause();
    super.dispose();
  }

  Future<void> load(DateTime from) {
    _want(from);
    return _queue = _queue.then((_) => _loadDays(diaryDays(from, DateTime.now().toUtc())));
  }

  void _want(DateTime from) {
    final oldest = _oldestWanted;
    if (oldest == null || from.isBefore(oldest)) _oldestWanted = from;
  }

  Future<void> _loadDays(List<String> wanted) async {
    if (wanted.every(_final.contains)) return;
    loading = true;
    failed = false;
    notifyListeners();
    for (final day in wanted) {
      try {
        await _loadDay(day, _clock().toUtc(), offline: failed);
      } catch (e) {
        debugPrint('territory map: changes $day failed: $e');
        if (!failed) countMapFailure(MapFailure.history);
        failed = true;
      }
      notifyListeners();
    }
    loading = false;
    notifyListeners();
  }

  // Offline still reads the saved days
  Future<void> _loadDay(String day, DateTime now, {required bool offline}) async {
    if (_final.contains(day)) return;
    final name = changesFileName(day);
    if (await _readSaved(day, name)) return;
    if (offline || !shouldAskDay(day, now, _askedAt[day], missing: _missing.contains(day))) return;
    final download = await _files.fetchChanges(day, _etags[day] ?? '');
    _askedAt[day] = now;
    if (download == null) {
      _setDay(day, null);
      if (!isMissingForGood(day, now)) return;
      // Empty file marks a day never published
      await _files.writeCached(name, Uint8List(0));
      _final.add(day);
      return;
    }
    final bytes = download.bytes;
    if (bytes == null) return;
    _setDay(day, await _files.decodeChanges(bytes));
    _etags[day] = download.etag;
    if (download.immutable) {
      await _files.writeCached(name, bytes);
      _final.add(day);
    }
  }

  // Unreadable file: delete and ask again
  Future<bool> _readSaved(String day, String name) async {
    final saved = await _files.readCached(name);
    if (saved == null) return false;
    try {
      _setDay(day, saved.isEmpty ? null : await _files.decodeChanges(saved));
      _final.add(day);
      return true;
    } catch (e) {
      debugPrint('territory map: saved changes $day unreadable: $e');
      await _files.deleteCached((file) => file == name);
      return false;
    }
  }

  Future<void> loadYears() {
    final asked = _yearsAskedAt;
    if (asked != null && DateTime.now().difference(asked) < _yearsEvery) return _queue;
    final forgotten = _yearsForgotten;
    return _yearsLoad ??= _queue = _queue
        .then((_) => _loadYears(DateTime.now().toUtc(), forgotten))
        .whenComplete(() => _yearsLoad = null);
  }

  Future<void> _loadYears(DateTime now, int forgotten) async {
    loadingYears = true;
    notifyListeners();
    var answered = true;
    for (final year in {now.subtract(recordYear).year, now.year}) {
      try {
        await _loadYear(year, forgotten);
      } catch (e) {
        debugPrint('territory map: history $year failed: $e');
        answered = false;
      }
    }
    if (!answered) countMapFailure(MapFailure.history);
    if (answered && forgotten == _yearsForgotten) _yearsAskedAt = DateTime.now();
    yearsFailed = !answered;
    loadingYears = false;
    _changed();
    notifyListeners();
    final current = _years[now.year];
    final through = current?.through;
    final from = through != null
        ? dayStart(through).add(const Duration(days: 1))
        : current?.generatedAt.subtract(const Duration(days: 1)) ?? now.subtract(const Duration(days: diaryMaxDays));
    _want(from);
    await _loadDays(diaryDays(from, now));
  }

  // Dropped if the last page closed meanwhile
  Future<void> _loadYear(int year, int forgotten) async {
    if (_finalYears.contains(year)) return;
    final name = historyFileName(year);
    final saved = await _files.readCached(name);
    if (saved != null) {
      try {
        final history = await _files.decodeHistory(saved);
        if (forgotten != _yearsForgotten) return;
        _years[year] = history;
        _finalYears.add(year);
        return;
      } catch (e) {
        debugPrint('territory map: saved history $year unreadable: $e');
        await _files.deleteCached((file) => file == name);
      }
    }
    final download = await _files.fetchHistory(year, _yearEtags[year] ?? '');
    final bytes = download?.bytes;
    if (download == null || bytes == null) return;
    final history = await _files.decodeHistory(bytes);
    if (forgotten != _yearsForgotten) return;
    _years[year] = history;
    _yearEtags[year] = download.etag;
    if (download.immutable) {
      await _files.writeCached(name, bytes);
      if (forgotten == _yearsForgotten) _finalYears.add(year);
    }
  }

  void _changed() {
    _recordStale = true;
    _sortedDays = null;
    _factionNames = null;
  }

  void _setDay(String day, DayChanges? changes) {
    _changed();
    if (changes == null) {
      _missing.add(day);
      _days.remove(day);
    } else {
      _missing.remove(day);
      _days[day] = changes;
    }
  }
}
