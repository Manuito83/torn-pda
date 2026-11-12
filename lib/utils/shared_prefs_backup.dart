import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/backup/prefs_backup_model.dart';
import 'package:torn_pda/utils/sembast_db.dart';

enum BackupExportMode {
  private,
  shareable,
}

class OpenedBackup {
  const OpenedBackup({
    required this.prefs,
    required this.shareable,
    required this.scriptsDisabled,
    required this.apiKeyScripts,
    this.activeScripts = const [],
  });

  final Map<String, dynamic> prefs;
  final bool shareable;
  final bool scriptsDisabled;
  final List<String> apiKeyScripts;
  final List<String> activeScripts;

  bool get needsReview => scriptsDisabled || apiKeyScripts.isNotEmpty || activeScripts.isNotEmpty;
}

class PrefsBackupService {
  static const String _dataKey = 'pda_pendingBackupData';
  static const String _keyKey = 'pda_pendingBackupKey';
  static const String _flagKey = 'pda_shouldRestoreBackup';

  /// Export preferences for local backup.
  static Future<String> exportPrefs({
    String? key,
    BackupExportMode mode = BackupExportMode.private,
  }) async {
    // Get all data from Sembast
    final Map<String, dynamic> allPrefsMap = await PrefsDatabase.getAll();
    final Map<String, dynamic> backupPrefs = withoutDeviceOnlyKeys(
      mode == BackupExportMode.shareable ? shareablePrefs(allPrefsMap) : allPrefsMap,
    );

    // Add metadata to identify this as a Sembast backup
    backupPrefs[backupVersionKey] = backupFormatSembast;
    backupPrefs[backupTimestampKey] = DateTime.now().millisecondsSinceEpoch;
    backupPrefs[backupProtectionKey] =
        mode == BackupExportMode.shareable ? backupProtectionNone : backupProtectionAesGcm;
    backupPrefs[backupScopeKey] = mode.name;

    final jsonString = jsonEncode(backupPrefs);

    if (mode == BackupExportMode.shareable) {
      log(name: 'Backup', 'Exported ${backupPrefs.length - 4} shareable keys (+ 4 metadata) from Sembast');
      return jsonString;
    }

    if (key == null || isBackupPasswordTooShort(key)) {
      throw ArgumentError(backupPasswordTooShortMessage);
    }

    final encrypted = await Isolate.run(() => encryptBackup(jsonString, key));
    return encrypted;
  }

  /// Throws on a wrong key
  static Future<OpenedBackup> openBackup(String encoded, String key) async {
    if (!isEncryptedBackup(encoded)) {
      final prefs = shareablePrefs(tryDecodeBackupJson(encoded)!, forImport: true);
      return OpenedBackup(
        prefs: prefs,
        shareable: true,
        scriptsDisabled: true,
        apiKeyScripts: scriptsUsingApiKey(prefs),
      );
    }

    final decrypted = await Isolate.run(() => decryptBackup(encoded, key));

    final currentOwnDetails = await PrefsDatabase.getString('pda_ownDetails', '');
    if (isOwnBackup(decrypted, currentOwnDetails)) {
      return OpenedBackup(
        prefs: decrypted,
        shareable: false,
        scriptsDisabled: false,
        apiKeyScripts: scriptsUsingApiKey(decrypted, onlyActive: true),
        activeScripts: isFreshInstall(currentOwnDetails) ? activeScripts(decrypted) : const [],
      );
    }
    final prefs = withScriptsDisabled(decrypted)..removeWhere((key, _) => foreignExcludedKeys.contains(key));
    return OpenedBackup(prefs: prefs, shareable: false, scriptsDisabled: true, apiKeyScripts: scriptsUsingApiKey(prefs));
  }

  /// Schedule backup import on next launch
  static Future<void> scheduleImport(OpenedBackup backup) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_dataKey, jsonEncode(backup.prefs));
    await prefs.remove(_keyKey);
    await prefs.setBool(_flagKey, true);
  }

  /// If import is pending, apply it now and clear the flag, returns true if applied
  static Future<bool> importIfScheduled() async {
    final prefs = SharedPreferencesAsync();

    if (!(await prefs.getBool(_flagKey) ?? false)) return false;

    final encoded = await prefs.getString(_dataKey);
    // Only set by versions before 4.0.0
    final legacyKey = await prefs.getString(_keyKey);

    if (encoded == null) {
      await prefs.remove(_dataKey);
      await prefs.remove(_keyKey);
      await prefs.setBool(_flagKey, false);
      return false;
    }

    try {
      final map = withoutDeviceOnlyKeys(
        legacyKey == null ? tryDecodeBackupJson(encoded)! : (await openBackup(encoded, legacyKey)).prefs,
      );

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
    if (map[backupVersionKey] == backupFormatSembast) {
      return _BackupFormat.sembast;
    }
    return _BackupFormat.sharedPrefs;
  }

  /// Restore a Sembast backup (new format)
  static Future<void> _restoreSembastBackup(Map<String, dynamic> map) async {
    final dataToRestore = _removeBackupMetadata(map);

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

  static Map<String, dynamic> _removeBackupMetadata(Map<String, dynamic> map) {
    final dataToRestore = Map<String, dynamic>.from(map);
    dataToRestore.remove(backupVersionKey);
    dataToRestore.remove(backupTimestampKey);
    dataToRestore.remove(backupProtectionKey);
    dataToRestore.remove(backupScopeKey);
    return dataToRestore;
  }
}

enum _BackupFormat {
  sembast,
  sharedPrefs,
}
