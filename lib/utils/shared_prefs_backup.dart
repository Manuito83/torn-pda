import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsBackupService {
  static const String _dataKey = 'pda_pendingBackupData';
  static const String _keyKey = 'pda_pendingBackupKey';
  static const String _flagKey = 'pda_shouldRestoreBackup';

  /// Export all prefs as an XOR‑ciphered Base64 string
  static Future<String> exportPrefs(String key) async {
    final prefs = SharedPreferencesAsync();
    final Map<String, Object?> allPrefsMap = await prefs.getAll();

    final bytes = utf8.encode(jsonEncode(allPrefsMap));
    final keyBytes = utf8.encode(key);
    final cipher = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );
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
      for (final entry in map.entries) {
        final k = entry.key;
        final v = entry.value;
        if (v is int) await prefs.setInt(k, v);
        if (v is bool) await prefs.setBool(k, v);
        if (v is double) await prefs.setDouble(k, v);
        if (v is String) await prefs.setString(k, v);
        if (v is List) await prefs.setStringList(k, v.cast<String>());
      }

      await prefs.remove(_dataKey);
      await prefs.remove(_keyKey);
      await prefs.setBool(_flagKey, false);
      return true;
    } catch (_) {
      await prefs.remove(_dataKey);
      await prefs.remove(_keyKey);
      await prefs.setBool(_flagKey, false);
      return false;
    }
  }
}
