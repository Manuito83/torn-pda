import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/map_usage.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';
import 'package:torn_pda/providers/territory_map_usage.dart';
import 'package:torn_pda/utils/territory_map/territory_map_files.dart';

const _warsInMemory = 20;
const _refreshEvery = Duration(minutes: 10);

class _WarEntry {
  WarFile? file;
  String etag = '';
  bool closed = false;
  bool missing = false;
  bool failed = false;
  bool loading = false;
}

class TerritoryWarsController extends ChangeNotifier {
  TerritoryWarsController({TerritoryMapFiles? files}) : _files = files ?? TerritoryMapFiles();

  final TerritoryMapFiles _files;

  // Oldest first, so the first key goes
  final _entries = <int, _WarEntry>{};
  int? _openId;
  Timer? _refreshTimer;

  WarFile? warFile(int id) => _entries[id]?.file;

  bool isLoading(int id) => _entries[id]?.loading ?? false;

  bool isMissing(int id) => _entries[id]?.missing ?? false;

  bool hasFailed(int id) => _entries[id]?.failed ?? false;

  // Closed and published for good
  bool isFinal(int id) => _entries[id]?.closed ?? false;

  Future<void> retry(int id) => _load(id);

  void open(int id) {
    _openId = id;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshEvery, (_) => _load(id));
    // Called from initState, not during build
    scheduleMicrotask(() => _load(id));
  }

  void close(int id) {
    if (_openId != id) return;
    _openId = null;
    pause();
  }

  void pause() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void resume() {
    final id = _openId;
    if (id != null && _refreshTimer == null) open(id);
  }

  @override
  void dispose() {
    pause();
    super.dispose();
  }

  Future<void> _load(int id) async {
    final entry = _entries.remove(id) ?? _WarEntry();
    _entries[id] = entry;
    while (_entries.length > _warsInMemory) {
      _entries.remove(_entries.keys.first);
    }
    if (entry.closed || entry.loading) return;

    entry.loading = true;
    notifyListeners();
    try {
      if (entry.file == null) {
        final saved = await _files.readCached(warFileName(id));
        if (saved != null) {
          entry.file = await _files.decodeWar(saved);
          entry.closed = true;
          return;
        }
      }
      final download = await _files.fetchWar(id, entry.etag);
      entry.missing = download == null;
      final bytes = download?.bytes;
      if (bytes != null) {
        entry.file = await _files.decodeWar(bytes);
        entry.etag = download!.etag;
        if (download.immutable) {
          await _files.writeCached(warFileName(id), bytes);
          entry.closed = true;
        }
      }
      entry.failed = false;
    } catch (e) {
      debugPrint('territory map: war $id failed: $e');
      if (!entry.failed) countMapFailure(MapFailure.wars);
      entry.failed = true;
    } finally {
      entry.loading = false;
      notifyListeners();
    }
  }
}
