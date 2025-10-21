import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/utils/sembast_db.dart';

class PrefsBackupService {
  static const String _dataKey = 'pda_pendingBackupData';
  static const String _keyKey = 'pda_pendingBackupKey';
  static const String _flagKey = 'pda_shouldRestoreBackup';

  // Metadata keys to identify backup format
  static const String _backupVersionKey = '_backup_version';
  static const String _backupTimestampKey = '_backup_timestamp';
  static const String _backupFormatSembast = 'sembast_v1';

  /// Export all prefs as an XOR‑ciphered Base64 string
  static Future<String> exportPrefs(String key) async {
    // Get all data from Sembast
    final Map<String, dynamic> allPrefsMap = await PrefsDatabase.getAll();

    // Add metadata to identify this as a Sembast backup
    allPrefsMap[_backupVersionKey] = _backupFormatSembast;
    allPrefsMap[_backupTimestampKey] = DateTime.now().millisecondsSinceEpoch;

    final bytes = utf8.encode(jsonEncode(allPrefsMap));
    final keyBytes = utf8.encode(key);
    final cipher = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );

    log(name: 'Backup', 'Exported ${allPrefsMap.length - 2} keys (+ 2 metadata) from Sembast');
    return base64Encode(cipher);
  }

  /// Decode a Base64‑XOR backup string into a Map, throws on invalid data or key
  static Map<String, dynamic> decodeBackup(String encoded, String key) {
    final cipher = base64Decode(encoded);
    final keyBytes = utf8.encode(key);
    final decoded = List<int>.generate(
      cipher.length,
      (i) => cipher[i] ^ keyBytes[i % keyBytes.length],
    );
    return jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
  }

  /// Schedule backup import on next launch by saving data and key
  static Future<void> scheduleImport(String encoded, String key) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_dataKey, encoded);
    await prefs.setString(_keyKey, key);
    await prefs.setBool(_flagKey, true);
  }

  /// If import is pending, apply it now and clear the flag, returns true if applied
  static Future<bool> importIfScheduled() async {
    final prefs = SharedPreferencesAsync();

    if (!(await prefs.getBool(_flagKey) ?? false)) return false;

    final encoded = await prefs.getString(_dataKey);
    final key = await prefs.getString(_keyKey);

    if (encoded == null || key == null) {
      await prefs.remove(_dataKey);
      await prefs.remove(_keyKey);
      await prefs.setBool(_flagKey, false);
      return false;
    }

    try {
      final map = decodeBackup(encoded, key);

      // Detect backup format
      final backupFormat = _detectBackupFormat(map);

      if (backupFormat == _BackupFormat.sembast) {
        // New Sembast backup - restore directly
        log(name: 'Backup', 'Detected Sembast backup format');
        await _restoreSembastBackup(map);
      } else {
        // Old SharedPreferences backup - migrate to Sembast
        log(name: 'Backup', 'Detected legacy SharedPreferences backup - migrating to Sembast');
        await _migrateOldBackupToSembast(map);
      }

      await prefs.remove(_dataKey);
      await prefs.remove(_keyKey);
      await prefs.setBool(_flagKey, false);

      log(name: 'Backup', 'Backup restored successfully');
      return true;
    } catch (e) {
      log(name: 'Backup', 'ERROR: Failed to restore backup: $e');
      await prefs.remove(_dataKey);
      await prefs.remove(_keyKey);
      await prefs.setBool(_flagKey, false);
      return false;
    }
  }

  /// Detect if backup is from Sembast or old SharedPreferences
  static _BackupFormat _detectBackupFormat(Map<String, dynamic> map) {
    if (map.containsKey(_backupVersionKey) && map[_backupVersionKey] == _backupFormatSembast) {
      return _BackupFormat.sembast;
    }
    return _BackupFormat.sharedPrefs;
  }

  /// Restore a Sembast backup (new format)
  static Future<void> _restoreSembastBackup(Map<String, dynamic> map) async {
    // Remove metadata keys before restoring
    final dataToRestore = Map<String, dynamic>.from(map);
    dataToRestore.remove(_backupVersionKey);
    dataToRestore.remove(_backupTimestampKey);

    // Restore to Sembast
    await PrefsDatabase.restoreAll(dataToRestore);

    log(name: 'Backup', 'Restored ${dataToRestore.length} keys from Sembast backup');
  }

  /// Migrate old SharedPreferences backup to Sembast (backwards compatibility)
  static Future<void> _migrateOldBackupToSembast(Map<String, dynamic> map) async {
    // Most types are compatible, only handle List<String> casting
    final convertedData = <String, dynamic>{};

    for (final entry in map.entries) {
      final k = entry.key;
      final v = entry.value;

      if (v is List) {
        convertedData[k] = v.cast<String>();
      } else {
        convertedData[k] = v;
      }
    }

    // Restore to Sembast
    await PrefsDatabase.restoreAll(convertedData);

    log(name: 'Backup', 'Migrated ${convertedData.length} keys from SharedPreferences backup to Sembast');
  }
}

enum _BackupFormat {
  sembast,
  sharedPrefs,
}
