// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:synchronized/synchronized.dart';

/// Disk-backed KV store for the userscript PDA_storage API, one namespace per script
class ScriptStorage {
  static const int defaultQuotaBytes = 10 * 1024 * 1024;
  static const int maxQuotaBytes = 50 * 1024 * 1024;
  static const int globalCapBytes = 250 * 1024 * 1024;

  static Database? _db;
  static final Lock _initLock = Lock();

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    return _initLock.synchronized(() async {
      if (_db != null) return _db!;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final dir = await getApplicationDocumentsDirectory();
      final dbDir = Directory('${dir.path}/database');
      if (!await dbDir.exists()) await dbDir.create(recursive: true);
      final path = '${dbDir.path}/torn_pda_script_storage.db';
      try {
        _db = await databaseFactory.openDatabase(path, options: _openOptions());
      } catch (_) {
        // Corrupt/unreadable DB: this store is a disposable cache, so recreate it rather than fail forever
        await databaseFactory.deleteDatabase(path);
        _db = await databaseFactory.openDatabase(path, options: _openOptions());
      }
      return _db!;
    });
  }

  static OpenDatabaseOptions _openOptions() => OpenDatabaseOptions(
        // Bump `version` and add ALTER/migration SQL in onUpgrade when the schema changes
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE script_storage ('
            'sid TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL, bytes INTEGER NOT NULL, '
            'PRIMARY KEY (sid, key))',
          );
          await db.execute('CREATE INDEX idx_sid ON script_storage(sid)');
          await db.execute('CREATE TABLE script_quota (sid TEXT PRIMARY KEY, quota INTEGER NOT NULL)');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Schema is at v1. Future structural changes go here, guarded by oldVersion.
        },
        // App downgrade meeting a newer schema: wipe and recreate (cache data, safe to drop)
        onDowngrade: onDatabaseDowngradeDelete,
      );

  /// Entry point for the PDA_storage JS handler
  /// Returns {ok, value?, error?, used?, quota?}
  static Future<Map<String, dynamic>> handle(String sid, String method, Map<String, dynamic> p) async {
    if (sid.isEmpty) return {'ok': false, 'error': 'NoNamespace'};
    try {
      switch (method) {
        case 'get':
          return _ok(await _get(sid, p['key'] as String, p['def']));
        case 'getMany':
          return _ok(await _getMany(sid, (p['keys'] as List).cast<String>()));
        case 'loadAll':
          return _ok(await _loadAll(sid));
        case 'list':
          return _ok(await _list(sid));
        case 'usage':
          return _ok(await _usage(sid));
        case 'set':
          return await _set(sid, p['key'] as String, p['value']);
        case 'setMany':
          return await _setMany(sid, Map<String, dynamic>.from(p['obj'] as Map));
        case 'delete':
          await _delete(sid, p['key'] as String);
          return _ok(null);
        default:
          return {'ok': false, 'error': 'UnknownMethod'};
      }
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  static Map<String, dynamic> _ok(dynamic value) => {'ok': true, 'value': value};

  static int _sizeOf(String key, String encodedValue) => utf8.encode(key).length + utf8.encode(encodedValue).length;

  static Future<dynamic> _get(String sid, String key, dynamic def) async {
    final db = await _database;
    final rows = await db.query(
      'script_storage',
      columns: ['value'],
      where: 'sid = ? AND key = ?',
      whereArgs: [sid, key],
    );
    if (rows.isEmpty) return def;
    return jsonDecode(rows.first['value'] as String);
  }

  static Future<Map<String, dynamic>> _getMany(String sid, List<String> keys) async {
    final out = <String, dynamic>{};
    for (final k in keys) {
      out[k] = await _get(sid, k, null);
    }
    return out;
  }

  static Future<Map<String, dynamic>> _loadAll(String sid) async {
    final db = await _database;
    final rows = await db.query('script_storage', columns: ['key', 'value'], where: 'sid = ?', whereArgs: [sid]);
    return {for (final r in rows) r['key'] as String: jsonDecode(r['value'] as String)};
  }

  static Future<List<String>> _list(String sid) async {
    final db = await _database;
    final rows = await db.query('script_storage', columns: ['key'], where: 'sid = ?', whereArgs: [sid]);
    return [for (final r in rows) r['key'] as String];
  }

  static Future<Map<String, dynamic>> _usage(String sid) async {
    final db = await _database;
    return {'used': await _namespaceBytes(db, sid), 'quota': await _effectiveQuota(db, sid)};
  }

  static Future<Map<String, dynamic>> _set(String sid, String key, dynamic value) async {
    final db = await _database;
    final encoded = jsonEncode(value);
    final newBytes = _sizeOf(key, encoded);
    final oldBytes = await _entryBytes(db, sid, key);

    final quota = await _effectiveQuota(db, sid);
    final nsAfter = await _namespaceBytes(db, sid) - oldBytes + newBytes;
    if (nsAfter > quota) return {'ok': false, 'error': 'QuotaExceeded', 'used': nsAfter, 'quota': quota};

    final globalAfter = await _globalBytes(db) - oldBytes + newBytes;
    if (globalAfter > globalCapBytes) {
      return {'ok': false, 'error': 'GlobalQuotaExceeded', 'used': globalAfter, 'quota': globalCapBytes};
    }

    await db.insert('script_storage', {
      'sid': sid,
      'key': key,
      'value': encoded,
      'bytes': newBytes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return _ok(null);
  }

  static Future<Map<String, dynamic>> _setMany(String sid, Map<String, dynamic> obj) async {
    final db = await _database;
    final encoded = {for (final e in obj.entries) e.key: jsonEncode(e.value)};
    final newBytes = {for (final e in encoded.entries) e.key: _sizeOf(e.key, e.value)};

    int oldSum = 0;
    for (final k in obj.keys) {
      oldSum += await _entryBytes(db, sid, k);
    }
    final delta = newBytes.values.fold<int>(0, (a, b) => a + b) - oldSum;

    final quota = await _effectiveQuota(db, sid);
    if (await _namespaceBytes(db, sid) + delta > quota) {
      return {'ok': false, 'error': 'QuotaExceeded', 'used': await _namespaceBytes(db, sid) + delta, 'quota': quota};
    }
    if (await _globalBytes(db) + delta > globalCapBytes) {
      return {'ok': false, 'error': 'GlobalQuotaExceeded', 'quota': globalCapBytes};
    }

    final batch = db.batch();
    for (final k in obj.keys) {
      batch.insert('script_storage', {
        'sid': sid,
        'key': k,
        'value': encoded[k],
        'bytes': newBytes[k],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return _ok(null);
  }

  static Future<void> _delete(String sid, String key) async {
    final db = await _database;
    await db.delete('script_storage', where: 'sid = ? AND key = ?', whereArgs: [sid, key]);
  }

  static Future<int> _entryBytes(Database db, String sid, String key) async {
    final r = await db.rawQuery('SELECT bytes FROM script_storage WHERE sid = ? AND key = ?', [sid, key]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  static Future<int> _namespaceBytes(Database db, String sid) async {
    final r = await db.rawQuery('SELECT COALESCE(SUM(bytes), 0) FROM script_storage WHERE sid = ?', [sid]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  static Future<int> _globalBytes(Database db) async {
    final r = await db.rawQuery('SELECT COALESCE(SUM(bytes), 0) FROM script_storage');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  static Future<int> _effectiveQuota(Database db, String sid) async {
    final r = await db.rawQuery('SELECT quota FROM script_quota WHERE sid = ?', [sid]);
    final override = Sqflite.firstIntValue(r) ?? 0;
    return override > 0 ? override : defaultQuotaBytes;
  }

  // ---- App-side management (lifecycle, DevTools) ----

  static Future<void> deleteNamespace(String sid) async {
    final db = await _database;
    await db.delete('script_storage', where: 'sid = ?', whereArgs: [sid]);
    await db.delete('script_quota', where: 'sid = ?', whereArgs: [sid]);
  }

  static Future<void> deleteKey(String sid, String key) => _delete(sid, key);

  static Future<void> deleteAll() async {
    final db = await _database;
    await db.delete('script_storage');
    await db.delete('script_quota');
  }

  /// Drop namespaces whose script is no longer installed (orphans left by a crash/uninstall).
  static Future<void> gc(Set<String> installedSids) async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT DISTINCT sid FROM script_storage');
    for (final r in rows) {
      final sid = r['sid'] as String;
      if (!installedSids.contains(sid)) await deleteNamespace(sid);
    }
  }

  static Future<void> setQuota(String sid, int bytes) async {
    final db = await _database;
    final clamped = bytes <= 0 ? 0 : (bytes > maxQuotaBytes ? maxQuotaBytes : bytes);
    if (clamped == 0) {
      await db.delete('script_quota', where: 'sid = ?', whereArgs: [sid]);
    } else {
      await db.insert('script_quota', {'sid': sid, 'quota': clamped}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<int> namespaceUsage(String sid) async => _namespaceBytes(await _database, sid);
  static Future<int> effectiveQuota(String sid) async => _effectiveQuota(await _database, sid);
  static Future<int> globalUsage() async => _globalBytes(await _database);

  /// Raw per-script quota override in bytes, or 0 when the global default applies.
  static Future<int> quotaOverride(String sid) async {
    final db = await _database;
    final r = await db.rawQuery('SELECT quota FROM script_quota WHERE sid = ?', [sid]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Per-namespace summary for the DevTools storage panel. quota=0 means the global default applies.
  static Future<List<Map<String, dynamic>>> namespaces() async {
    final db = await _database;
    return db.rawQuery(
      'SELECT d.sid AS sid, COUNT(*) AS count, COALESCE(SUM(d.bytes), 0) AS used, '
      'COALESCE(q.quota, 0) AS quota '
      'FROM script_storage d LEFT JOIN script_quota q ON q.sid = d.sid '
      'GROUP BY d.sid ORDER BY used DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> entries(String sid) async {
    final db = await _database;
    return db.query('script_storage', columns: ['key', 'value', 'bytes'], where: 'sid = ?', whereArgs: [sid]);
  }
}
