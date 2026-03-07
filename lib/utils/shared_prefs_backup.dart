import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/utils/sembast_db.dart';

enum BackupExportMode {
  private,
  shareable,
}

class BackupInspection {
  const BackupInspection({
    required this.requiresKey,
    required this.mode,
  });

  final bool requiresKey;
  final BackupExportMode mode;
}

class PrefsBackupService {
  static const String _dataKey = 'pda_pendingBackupData';
  static const String _keyKey = 'pda_pendingBackupKey';
  static const String _flagKey = 'pda_shouldRestoreBackup';

  // Metadata keys to identify backup format
  static const String _backupVersionKey = '_backup_version';
  static const String _backupTimestampKey = '_backup_timestamp';
  static const String _backupFormatSembast = 'sembast_v1';
  static const String _backupProtectionKey = '_backup_protection';
  static const String _backupScopeKey = '_backup_scope';
  static const String _backupProtectionXor = 'xor';
  static const String _backupProtectionNone = 'none';

  static const Set<String> _shareableExcludedKeys = {
    '_local_user_model_snapshot',
    'pda_ownDetails',
    'pda_nativePlayerEmail',
    'pda_lastAuthRedirect',
    'pda_tryAutomaticLogins',
    'pda_playerLastLoginMethod',
    'pda_nativeLoginKeychainMigrated',
    'pda_alternativeYataKeyEnabled',
    'pda_alternativeYataKey',
    'pda_alternativeTornStatsKeyEnabled',
    'pda_alternativeTornStatsKey',
    'pda_alternativeTSCKeyEnabled',
    'pda_alternativeTSCKey',
    'pda_alternativeFFScouterKeyEnabled',
    'pda_alternativeFFScouterKey',
    'pda_webViewSessionCookie',
    'pda_webViewLastActiveTab',
    'pda_webViewMainTab',
    'pda_webViewTabs',
    'pda_fcmToken',
    'pda_sendbirdSessionToken',
    'pda_sendbirdTimestamp',
    'pda_iosLiveActivityTravelPushToken',
    'pda_iosLiveActivityRacingPushToken',
  };

  /// Export preferences for local backup.
  static Future<String> exportPrefs({
    String? key,
    BackupExportMode mode = BackupExportMode.private,
  }) async {
    // Get all data from Sembast
    final Map<String, dynamic> allPrefsMap = await PrefsDatabase.getAll();
    final Map<String, dynamic> backupPrefs = mode == BackupExportMode.shareable
        ? _sanitizePrefsForShareable(allPrefsMap)
        : Map<String, dynamic>.from(allPrefsMap);

    // Add metadata to identify this as a Sembast backup
    backupPrefs[_backupVersionKey] = _backupFormatSembast;
    backupPrefs[_backupTimestampKey] = DateTime.now().millisecondsSinceEpoch;
    backupPrefs[_backupProtectionKey] =
        mode == BackupExportMode.shareable ? _backupProtectionNone : _backupProtectionXor;
    backupPrefs[_backupScopeKey] = mode.name;

    final jsonString = jsonEncode(backupPrefs);

    if (mode == BackupExportMode.shareable) {
      log(name: 'Backup', 'Exported ${backupPrefs.length - 4} shareable keys (+ 4 metadata) from Sembast');
      return jsonString;
    }

    if (key == null || key.isEmpty) {
      throw ArgumentError('An encryption key is required for private backups');
    }

    final bytes = utf8.encode(jsonString);
    final keyBytes = utf8.encode(key);
    final cipher = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );

    log(name: 'Backup', 'Exported ${backupPrefs.length - 4} private keys (+ 4 metadata) from Sembast');
    return base64Encode(cipher);
  }

  static BackupInspection inspectBackup(String encoded) {
    final decodedJson = _tryDecodeRawJson(encoded);
    if (decodedJson != null) {
      final protection = decodedJson[_backupProtectionKey];
      final scope = decodedJson[_backupScopeKey];
      return BackupInspection(
        requiresKey: protection != _backupProtectionNone,
        mode: scope == BackupExportMode.shareable.name ? BackupExportMode.shareable : BackupExportMode.private,
      );
    }

    return const BackupInspection(
      requiresKey: true,
      mode: BackupExportMode.private,
    );
  }

  /// Decode a backup string into a Map, throws on invalid data or key.
  static Map<String, dynamic> decodeBackup(String encoded, [String? key]) {
    final decodedJson = _tryDecodeRawJson(encoded);
    if (decodedJson != null) {
      return decodedJson;
    }

    if (key == null || key.isEmpty) {
      throw const FormatException('Missing decryption key');
    }

    final cipher = base64Decode(encoded);
    final keyBytes = utf8.encode(key);
    final decoded = List<int>.generate(
      cipher.length,
      (i) => cipher[i] ^ keyBytes[i % keyBytes.length],
    );
    return jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
  }

  /// Schedule backup import on next launch by saving data and key
  static Future<void> scheduleImport(String encoded, [String? key]) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_dataKey, encoded);
    await prefs.setString(_keyKey, key ?? '');
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

  static Map<String, dynamic> _sanitizePrefsForShareable(Map<String, dynamic> allPrefsMap) {
    final sanitized = Map<String, dynamic>.from(allPrefsMap)
      ..removeWhere((key, _) => _shareableExcludedKeys.contains(key));

    final userScriptsRaw = sanitized['pda_userScriptsList'];
    if (userScriptsRaw is String && userScriptsRaw.isNotEmpty) {
      sanitized['pda_userScriptsList'] = _sanitizeUserScripts(userScriptsRaw);
    }

    return sanitized;
  }

  static String _sanitizeUserScripts(String rawValue) {
    try {
      String jsonString = rawValue;
      bool encodeBackToBase64 = false;

      if (rawValue.startsWith('PDA_B64:')) {
        final decodedBytes = base64Decode(rawValue.substring(8));
        jsonString = utf8.decode(decodedBytes);
        encodeBackToBase64 = true;
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return rawValue;

      final sanitizedList = decoded.map((entry) {
        if (entry is! Map) return entry;
        final mutable = Map<String, dynamic>.from(entry);
        mutable['customApiKey'] = '';
        return mutable;
      }).toList();

      final sanitizedJson = jsonEncode(sanitizedList);
      if (!encodeBackToBase64) {
        return sanitizedJson;
      }

      return 'PDA_B64:${base64Encode(utf8.encode(sanitizedJson))}';
    } catch (_) {
      return rawValue;
    }
  }

  static Map<String, dynamic>? _tryDecodeRawJson(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Map<String, dynamic> _removeBackupMetadata(Map<String, dynamic> map) {
    final dataToRestore = Map<String, dynamic>.from(map);
    dataToRestore.remove(_backupVersionKey);
    dataToRestore.remove(_backupTimestampKey);
    dataToRestore.remove(_backupProtectionKey);
    dataToRestore.remove(_backupScopeKey);
    return dataToRestore;
  }
}

enum _BackupFormat {
  sembast,
  sharedPrefs,
}
