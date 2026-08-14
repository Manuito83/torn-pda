// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:intl/intl.dart';

/// Catalog of third party scripts
class ScriptCatalog {
  ScriptCatalog({
    required this.schemaVersion,
    required this.enabled,
    required this.updated,
    required this.provider,
    required this.categories,
    required this.scripts,
  });

  final int schemaVersion;
  final bool enabled;
  final String updated;
  final CatalogProvider provider;
  final List<CatalogCategory> categories;
  final List<CatalogScript> scripts;

  static const int supportedSchemaVersion = 1;

  String get readableUpdated {
    final parsed = DateTime.tryParse(updated);
    if (parsed == null) return "";
    return DateFormat("d MMM yyyy").format(parsed);
  }

  /// Categories that actually hold scripts, in catalog order
  List<CatalogCategory> get populatedCategories =>
      categories.where((c) => scripts.any((s) => s.category == c.id)).toList();

  factory ScriptCatalog.fromJson(Map<String, dynamic> json) {
    final categories = (json["categories"] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CatalogCategory.fromJson)
        .toList();

    final scripts = (json["scripts"] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CatalogScript.fromJson)
        .where((s) => s.isValid)
        .toList();

    return ScriptCatalog(
      schemaVersion: json["schemaVersion"] is int ? json["schemaVersion"] : 0,
      enabled: json["enabled"] is bool ? json["enabled"] : true,
      updated: json["updated"] is String ? json["updated"] : "",
      provider: CatalogProvider.fromJson(json["provider"] as Map<String, dynamic>? ?? const {}),
      categories: categories,
      scripts: scripts,
    );
  }

  static ScriptCatalog? tryParse(String source) {
    try {
      final decoded = json.decode(source);
      if (decoded is! Map<String, dynamic>) return null;
      final catalog = ScriptCatalog.fromJson(decoded);
      // A newer schema might mean fields we can't read, so don't guess
      if (catalog.schemaVersion > supportedSchemaVersion) return null;
      if (catalog.scripts.isEmpty) return null;
      return catalog;
    } catch (_) {
      return null;
    }
  }
}

class CatalogProvider {
  CatalogProvider({required this.name, required this.author, required this.description, required this.links});

  final String name;
  final String author;
  final String description;
  final Map<String, String> links;

  String? get forum => _link("forum");
  String? get github => _link("github");
  String? get discord => _link("discord");
  String? get support => _link("support");
  String? get donate => _link("donate");

  // An empty entry means "no link", not a link to nowhere
  String? _link(String key) {
    final value = links[key];
    return (value == null || value.isEmpty) ? null : value;
  }

  factory CatalogProvider.fromJson(Map<String, dynamic> json) => CatalogProvider(
    name: json["name"] is String ? json["name"] : "",
    author: json["author"] is String ? json["author"] : "",
    description: json["description"] is String ? json["description"] : "",
    links: (json["links"] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v is String ? v : "")),
  );
}

class CatalogCategory {
  CatalogCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      CatalogCategory(id: json["id"] is String ? json["id"] : "", name: json["name"] is String ? json["name"] : "");
}

class CatalogScript {
  CatalogScript({
    required this.id,
    required this.greasyforkId,
    required this.name,
    required this.description,
    required this.category,
    required this.downloadUrl,
    required this.pageUrl,
    required this.matches,
  });

  final String id;
  final int greasyforkId;
  final String name;
  final String description;
  final String category;
  final String downloadUrl;
  final String pageUrl;
  final List<String> matches;

  bool get isValid => id.isNotEmpty && name.isNotEmpty && downloadUrl.isNotEmpty;

  static const String everywhere = "Everywhere";

  static const Map<String, String> _prettyPages = {
    "index": "Home",
    "amarket": "Auction house",
    "bigalgunshop": "Big Al's",
    "hospitalview": "Hospital",
    "jailview": "Jail",
    "joblist": "Job list",
    "displaycase": "Display case",
    "factions": "Faction",
    "companies": "Company",
    "profiles": "Profile",
    "properties": "Property",
    "bounties": "Bounties",
    "item": "Items",
    "itemmarket": "Item market",
    "userlist": "User list",
    "highlow": "High-Low",
    "oc": "Organized crimes",
  };

  bool get isGlobal {
    final where = whereItRuns;
    return where.length == 1 && where.first == everywhere;
  }

  /// Friendly page name
  List<String> get whereItRuns {
    final labels = <String>[];
    for (final match in matches) {
      final label = _labelForMatch(match);
      if (label.isNotEmpty && !labels.contains(label)) labels.add(label);
    }
    return labels.isEmpty ? const [everywhere] : labels;
  }

  static String _labelForMatch(String match) {
    final cleaned = match
        .replaceFirst(RegExp(r'^(\w+|\*)://'), '')
        .replaceFirst(RegExp(r'^\*\.'), '')
        .replaceFirst(RegExp(r'^torn\.com/?'), '')
        .replaceAll('*', '')
        .trim();

    if (cleaned.isEmpty) return "";

    final parts = cleaned.split('?');
    final path = parts.first.replaceAll(RegExp(r'(\.php)+$'), '');
    final query = parts.length > 1 ? parts[1] : "";

    String token = path;
    if (query.isNotEmpty) {
      final params = <String, String>{};
      for (final pair in query.split('&')) {
        final kv = pair.split('=');
        if (kv.length == 2 && kv[1].isNotEmpty) params[kv[0].toLowerCase()] = kv[1];
      }
      final sid = params['sid'];
      final page = params['page'];
      final type = params['type'];
      if (sid != null && sid.toLowerCase() == 'list' && type != null) {
        token = type;
      } else {
        token = sid ?? page ?? path;
      }
    }

    return _prettify(token);
  }

  static String _prettify(String token) {
    if (token.isEmpty) return "";
    final override = _prettyPages[token.toLowerCase()];
    if (override != null) return override;

    final spaced = token
        .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => ' ${m.group(1)!.toLowerCase()}')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    if (spaced.isEmpty) return "";
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  factory CatalogScript.fromJson(Map<String, dynamic> json) => CatalogScript(
    id: json["id"] is String ? json["id"] : "",
    greasyforkId: json["greasyforkId"] is int ? json["greasyforkId"] : 0,
    name: json["name"] is String ? json["name"] : "",
    description: json["description"] is String ? json["description"] : "",
    category: json["category"] is String ? json["category"] : "general",
    downloadUrl: json["downloadUrl"] is String ? json["downloadUrl"] : "",
    pageUrl: json["pageUrl"] is String ? json["pageUrl"] : "",
    matches: json["matches"] is List<dynamic> ? (json["matches"] as List<dynamic>).whereType<String>().toList() : [],
  );

  /// Greasy Fork script id taken from any of its URL, used to detect
  /// installs made before the catalog existed (or renamed by the user)
  static int? greasyforkIdFromUrl(String? url) {
    if (url == null) return null;
    final match = RegExp(r'greasyfork\.org/(?:[a-z-]+/)?scripts/(\d+)').firstMatch(url);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
