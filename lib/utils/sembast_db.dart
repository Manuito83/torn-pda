// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class PrefsDatabase {
  static Database? _database;
  static bool _isInitialized = false;
  static final StoreRef<String, dynamic> _store = stringMapStoreFactory.store('app_preferences');

  /// Ensure the database is initialized
  static Future<Database> get database async {
    if (_database != null && _isInitialized) return _database!;

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String dbPath = '${appDocDir.path}/database/torn_pda_preferences.db';
      _database = await databaseFactoryIo.openDatabase(dbPath);
      _isInitialized = true;
      log(name: 'PrefsDB', 'Preferences database initialized at $dbPath');
      return _database!;
    } catch (e) {
      log(name: 'PrefsDB', 'CRITICAL: Failed to initialize preferences database: $e');
      rethrow;
    }
  }

  /// ========== STRING Methods ==========
  static Future<String> getString(String key, String defaultValue) async {
    try {
      final db = await database;
      final value = await _store.record(key).get(db);
      return value as String? ?? defaultValue;
    } catch (e) {
      log(name: 'PrefsDB', 'Error getting string for key "$key": $e');
      return defaultValue;
    }
  }

  static Future<void> setString(String key, String value) async {
    try {
      final db = await database;
      await _store.record(key).put(db, value);
    } catch (e) {
      log(name: 'PrefsDB', 'Error setting string for key "$key": $e');
      rethrow;
    }
  }

  /// ========== INT Methods ==========
  static Future<int> getInt(String key, int defaultValue) async {
    try {
      final db = await database;
      final value = await _store.record(key).get(db);
      return value as int? ?? defaultValue;
    } catch (e) {
      log(name: 'PrefsDB', 'Error getting int for key "$key": $e');
      return defaultValue;
    }
  }

  static Future<void> setInt(String key, int value) async {
    try {
      final db = await database;
      await _store.record(key).put(db, value);
    } catch (e) {
      log(name: 'PrefsDB', 'Error setting int for key "$key": $e');
      rethrow;
    }
  }

  /// ========== DOUBLE Methods ==========
  static Future<double> getDouble(String key, double defaultValue) async {
    try {
      final db = await database;
      final value = await _store.record(key).get(db);
      return value as double? ?? defaultValue;
    } catch (e) {
      log(name: 'PrefsDB', 'Error getting double for key "$key": $e');
      return defaultValue;
    }
  }

  static Future<void> setDouble(String key, double value) async {
    try {
      final db = await database;
      await _store.record(key).put(db, value);
    } catch (e) {
      log(name: 'PrefsDB', 'Error setting double for key "$key": $e');
      rethrow;
    }
  }

  /// ========== BOOL Methods ==========
  static Future<bool> getBool(String key, bool defaultValue) async {
    try {
      final db = await database;
      final value = await _store.record(key).get(db);
      return value as bool? ?? defaultValue;
    } catch (e) {
      log(name: 'PrefsDB', 'Error getting bool for key "$key": $e');
      return defaultValue;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    try {
      final db = await database;
      await _store.record(key).put(db, value);
    } catch (e) {
      log(name: 'PrefsDB', 'Error setting bool for key "$key": $e');
      rethrow;
    }
  }

  /// ========== STRING LIST Methods ==========
  static Future<List<String>> getStringList(String key, List<String> defaultValue) async {
    try {
      final db = await database;
      final value = await _store.record(key).get(db);
      if (value == null) return defaultValue;
      if (value is List) {
        return List<String>.from(value);
      }
      return defaultValue;
    } catch (e) {
      log(name: 'PrefsDB', 'Error getting string list for key "$key": $e');
      return defaultValue;
    }
  }

  static Future<void> setStringList(String key, List<String> value) async {
    try {
      final db = await database;
      await _store.record(key).put(db, value);
    } catch (e) {
      log(name: 'PrefsDB', 'Error setting string list for key "$key": $e');
      rethrow;
    }
  }

  /// ========== UTILITY Methods ==========

  /// Remove a specific key
  static Future<void> remove(String key) async {
    try {
      final db = await database;
      await _store.record(key).delete(db);
    } catch (e) {
      log(name: 'PrefsDB', 'Error removing key "$key": $e');
    }
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    try {
      final db = await database;
      final value = await _store.record(key).get(db);
      return value != null;
    } catch (e) {
      log(name: 'PrefsDB', 'Error checking key "$key": $e');
      return false;
    }
  }

  /// Get all keys in the database
  static Future<List<String>> getKeys() async {
    try {
      final db = await database;
      final records = await _store.find(db);
      return records.map((r) => r.key).toList();
    } catch (e) {
      log(name: 'PrefsDB', 'Error getting all keys: $e');
      return [];
    }
  }

  /// Clear all preferences (use with caution!)
  static Future<void> clear() async {
    try {
      final db = await database;
      await _store.delete(db);
      log(name: 'PrefsDB', 'All preferences cleared');
    } catch (e) {
      log(name: 'PrefsDB', 'Error clearing all preferences: $e');
      rethrow;
    }
  }

  /// Get database stats for debugging
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await database;
      final records = await _store.find(db);
      return {
        'total_keys': records.length,
        'database_path': _database?.path ?? 'unknown',
        'is_initialized': _isInitialized,
      };
    } catch (e) {
      log(name: 'PrefsDB', 'Error getting stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Close the database connection (for cleanup)
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
      log(name: 'PrefsDB', 'Preferences database closed');
    }
  }

  /// ========== BACKUP/RESTORE Methods ==========

  /// Get all preferences as a Map (for backup export)
  static Future<Map<String, dynamic>> getAll() async {
    try {
      final db = await database;
      final records = await _store.find(db);
      final Map<String, dynamic> result = {};

      for (final record in records) {
        result[record.key] = record.value;
      }

      log(name: 'PrefsDB', 'Exported ${result.length} keys for backup');
      return result;
    } catch (e) {
      log(name: 'PrefsDB', 'Error exporting all preferences: $e');
      return {};
    }
  }

  /// Restore all preferences from a Map (for backup import)
  /// Uses a transaction to ensure all-or-nothing
  static Future<void> restoreAll(Map<String, dynamic> data) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        for (final entry in data.entries) {
          await _store.record(entry.key).put(txn, entry.value);
        }
      });

      log(name: 'PrefsDB', 'Restored ${data.length} keys from backup');
    } catch (e) {
      log(name: 'PrefsDB', 'CRITICAL: Error restoring preferences: $e');
      rethrow;
    }
  }

  /// Clear all preferences (danger!)
  static Future<void> clearAll() async {
    try {
      final db = await database;
      await _store.delete(db);
      log(name: 'PrefsDB', 'All preferences cleared');
    } catch (e) {
      log(name: 'PrefsDB', 'Error clearing all preferences: $e');
      rethrow;
    }
  }
}
