// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class SembastDatabase {
  static Database? _database;
  static bool _isInitialized = false;
  static final StoreRef<String, dynamic> _store = stringMapStoreFactory.store('pda_data_backup');

  /// Ensure the database is initialized
  static Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String dbPath = '${appDocDir.path}/pda_data_backup.db';
      _database = await databaseFactoryIo.openDatabase(dbPath);
      _isInitialized = true;
      log(name: 'Sembast DB', 'Database initialized at $dbPath');
    } catch (e) {
      // Continue without backup
      log(name: 'Sembast DB', 'Failed to initialize database: $e');
    }
  }

  static Future<void> _saveValue(String key, dynamic value) async {
    await _ensureInitialized();

    if (_database == null) return;

    try {
      await _store.record(key).put(_database!, value);
    } catch (e) {
      log(name: 'Sembast DB', 'Failed to save $key: $e');
    }
  }

  static Future<T?> _getValue<T>(String key) async {
    await _ensureInitialized();

    if (_database == null) return null;

    try {
      final value = await _store.record(key).get(_database!);
      if (value != null) {
        return value as T;
      }
      return null;
    } catch (e) {
      log(name: 'Sembast DB', 'Failed to get $key: $e');
      return null;
    }
  }

  /// Close the database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
      log(name: 'Sembast DB', 'Database closed');
    }
  }

  /// DB DATA ######

  /// App compilation backup methods
  static Future<void> saveAppCompilation(String compilation) async {
    await _saveValue('lastSavedAppCompilation', compilation);
  }

  static Future<String?> getAppCompilation() async {
    return await _getValue<String>('lastSavedAppCompilation');
  }

  // ---
}
