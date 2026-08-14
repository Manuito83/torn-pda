// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/services.dart' show rootBundle;

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import "package:http/http.dart" as http;

// Project imports:
import 'package:torn_pda/models/userscripts/script_catalog_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum ScriptCatalogSource { network, cache, bundled }

class ScriptCatalogResult {
  ScriptCatalogResult({required this.catalog, required this.source, this.error});

  final ScriptCatalog? catalog;
  final ScriptCatalogSource source;
  final String? error;

  bool get isStale => source != ScriptCatalogSource.network;
}

/// Loads the third party script catalog
class ScriptCatalogService {
  static const String catalogUrl =
      "https://raw.githubusercontent.com/Manuito83/torn-pda/master/userscripts/catalog/torntools.json";

  static const String bundledAsset = "userscripts/catalog/torntools.json";

  static const Duration _timeout = Duration(seconds: 15);

  static Future<ScriptCatalogResult> load() async {
    String? networkError;

    try {
      final response = await http.get(Uri.parse(catalogUrl)).timeout(_timeout);
      if (response.statusCode == 200) {
        final catalog = ScriptCatalog.tryParse(response.body);
        if (catalog != null) {
          // Only cache what we could actually parse
          unawaited(Prefs().setScriptCatalogCache(response.body));
          return ScriptCatalogResult(catalog: catalog, source: ScriptCatalogSource.network);
        }
        networkError = "The catalog could not be read";
      } else {
        networkError = "Server responded with error code: ${response.statusCode}";
      }
    } catch (e) {
      networkError = "$e";
    }

    final cached = await _fromCache();
    if (cached != null) {
      return ScriptCatalogResult(catalog: cached, source: ScriptCatalogSource.cache, error: networkError);
    }

    final bundled = await _fromBundle();
    return ScriptCatalogResult(catalog: bundled, source: ScriptCatalogSource.bundled, error: networkError);
  }

  static Future<ScriptCatalog?> _fromCache() async {
    try {
      final cached = await Prefs().getScriptCatalogCache();
      if (cached.isEmpty) return null;
      return ScriptCatalog.tryParse(cached);
    } catch (_) {
      return null;
    }
  }

  static Future<ScriptCatalog?> _fromBundle() async {
    try {
      return ScriptCatalog.tryParse(await rootBundle.loadString(bundledAsset));
    } catch (e, trace) {
      // Should not happen, the asset ships with the app
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA error loading bundled script catalog. Error: $e");
        FirebaseCrashlytics.instance.recordError(e, trace);
      }
      return null;
    }
  }
}
