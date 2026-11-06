// To parse this JSON data, do
//
//     final userScriptModel = userScriptModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import "package:http/http.dart" as http;
import 'package:uuid/uuid.dart';
import 'userscripts/script_header_model.dart';

UserScriptModel userScriptModelFromJson(String str) => UserScriptModel.fromJson(json.decode(str));

String userScriptModelToJson(UserScriptModel data) => json.encode(data.toJson());

enum UserScriptTime { start, end }

// Whether a script uses no storage, legacy localStorage/GM only, or the native PDA_storage API
enum ScriptStorageSupport { none, legacyOnly, pdaNative }

enum UserScriptUpdateStatus { upToDate, updateAvailable, localModified, noRemote, error, updating }

enum UserScriptSort { name, dateNewest }

const String warModeId = "war";

enum ScriptsBulkMode { none, globalDisable, scriptMode }

class UserScriptMode {
  const UserScriptMode({required this.id, required this.name});

  factory UserScriptMode.fromJson(Map<String, dynamic> json) => UserScriptMode(id: json["id"], name: json["name"]);

  static const war = UserScriptMode(id: warModeId, name: "War mode");

  final String id;
  final String name;

  bool get isWar => id == warModeId;
  IconData get icon => isWar ? MdiIcons.swordCross : Icons.tune;
  Color get color => isWar ? Colors.orange[800]! : Colors.indigo[600]!;

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

List<UserScriptMode> userScriptModesFromJson(String encoded) {
  try {
    return [for (final m in json.decode(encoded) as List) UserScriptMode.fromJson(m)];
  } catch (_) {
    return [];
  }
}

String userScriptModesToJson(List<UserScriptMode> modes) => json.encode(modes);

String bulkModeToPrefs(ScriptsBulkMode mode, String activeModeId) => switch (mode) {
      ScriptsBulkMode.none => "none",
      ScriptsBulkMode.globalDisable => "globalDisable",
      ScriptsBulkMode.scriptMode => activeModeId == warModeId ? "warMode" : "mode:$activeModeId",
    };

({ScriptsBulkMode mode, String? modeId}) bulkModeFromPrefs(String saved) {
  if (saved == "globalDisable") return (mode: ScriptsBulkMode.globalDisable, modeId: null);
  if (saved == "warMode") return (mode: ScriptsBulkMode.scriptMode, modeId: warModeId);
  if (saved.startsWith("mode:")) return (mode: ScriptsBulkMode.scriptMode, modeId: saved.substring(5));
  return (mode: ScriptsBulkMode.none, modeId: null);
}

// Registered groups not meant for url
List<String> staleScriptGroups(Iterable<String> registered, Iterable<UserScriptModel> active, String url) {
  final keep = {for (final s in active) if (s.matchesTarget(url)) s.storageId};
  return registered.where((g) => !keep.contains(g)).toList();
}

// Unchanged groups stay registered
bool needsRegistering(String? group, String source, Map<String, String> registered) =>
    group == null || registered[group] != source;

// Runs once per document, where guard holds
String oncePerDocument(String? key, String source, {String? guard}) {
  final String k = jsonEncode(key ?? 'anon');
  final String g = guard == null ? '' : '($guard)&&';
  return "if($g!(window.__pdaOnce=window.__pdaOnce||{})[$k]){window.__pdaOnce[$k]=1;\n$source\n}";
}

final _anyQuotes = RegExp(r'[“”‘’]');
final _doubleQuotes = RegExp(r'[“”]');
final _singleQuotes = RegExp(r'[‘’]');

String _normalizeQuotes(String s) => s.replaceAll(_doubleQuotes, '"').replaceAll(_singleQuotes, "'");

// Same string back when nothing changes
String adaptBody(String source, String apiKey) {
  if (!source.contains("###PDA-APIKEY###") && !source.contains(_anyQuotes)) return source;
  return _normalizeQuotes(source.replaceAll("###PDA-APIKEY###", apiKey));
}

String wrapSource(String body, String storageId) {
  // Bind PDA_storage to this script's namespace inside its own closure (sid not reachable elsewhere)
  // jsonEncode the id: it can come from imported/restored data, so never interpolate it raw into JS
  final String bind =
      'const PDA_storage = window.__pdaStorageFactory && window.__pdaStorageFactory(${jsonEncode(storageId)});';
  return "(function() {${_normalizeQuotes(bind)}$body}());";
}

class UserScriptModel {
  UserScriptModel({
    this.enabled = true,
    this.matches = const ["*"],
    required this.name,
    this.version = "0.0.0",
    this.manuallyEdited = false,
    required this.source,
    this.time = UserScriptTime.end,
    this.url,
    this.updateUrl,
    this.updateStatus = UserScriptUpdateStatus.noRemote,
    required this.isExample,
    this.customApiKey = "",
    this.customApiKeyCandidate = false,
    this.grants = const [],
    this.requires = const [],
    this.installedAt = 0,
    this.alwaysActive = false,
    Set<String>? modes,
    String? storageId,
  }) : modes = modes ?? <String>{},
       storageId = (storageId != null && storageId.isNotEmpty) ? storageId : const Uuid().v4();

  bool enabled;
  List<String> matches;
  String name;
  String version;
  bool manuallyEdited;
  String source;
  UserScriptTime time;
  String? url;

  // @updateURL, when the script offers one
  // Only holds a header, so it's much cheaper than the full source
  String? updateUrl;

  UserScriptUpdateStatus updateStatus;
  bool isExample;
  String customApiKey;
  bool customApiKeyCandidate;
  List<String> grants;
  List<String> requires;

  // 0 for those installed before this existed
  int installedAt;

  final Set<String> modes;

  // Runs in every mode
  bool alwaysActive;

  // Immutable namespace for PDA_storage; survives rename/update, wiped on delete. Quota lives in ScriptStorage.
  final String storageId;

  // Scan for the storage-support badge
  ScriptStorageSupport get storageSupport {
    if (RegExp(r'\bPDA_storage\b').hasMatch(source)) return ScriptStorageSupport.pdaNative;
    final legacy =
        RegExp(r'\blocalStorage\b').hasMatch(source) ||
        RegExp(r'\bGM[_.](set|get|delete|list)Value').hasMatch(source) ||
        grants.any((g) => g.contains('Value'));
    return legacy ? ScriptStorageSupport.legacyOnly : ScriptStorageSupport.none;
  }

  factory UserScriptModel.fromJson(Map<String, dynamic> json) {
    // First check if is old model
    if (json["exampleCode"] is int) {
      final bool enabled = json["enabled"] is bool ? json["enabled"] : true;
      final String source = json["source"] is String ? json["source"] : "";
      final List<String> matches = json["urls"] is List<dynamic> ? json["urls"].cast<String>() : tryGetMatches(source);
      final String name = json["name"] is String ? json["name"] : "Unknown";
      final String version = json["version"] is String ? json["version"] : tryGetVersion(source) ?? "0.0.0";
      final bool edited = json["edited"] is bool ? json["edited"] : false;
      final UserScriptTime time = json["time"] == "start" ? UserScriptTime.start : UserScriptTime.end;
      final bool isExample = json["isExample"] ?? (json["exampleCode"] ?? 0) > 0;
      final url = json["url"] is String
          ? json["url"]
          : tryGetUrl(json["source"]) ?? (isExample ? exampleScriptURLs[json["exampleCode"] - 1] : null);
      final updateStatus = UserScriptUpdateStatus.values.byName(
        json["updateStatus"] ?? (url is String ? "upToDate" : "noRemote"),
      );
      return UserScriptModel(
        enabled: enabled,
        matches: matches,
        name: name,
        version: version,
        manuallyEdited: edited,
        source: source,
        time: time,
        url: url,
        updateUrl: json["updateUrl"] is String ? json["updateUrl"] : null,
        updateStatus: updateStatus,
        isExample: isExample,
        grants: json["grants"] is List<dynamic> ? json["grants"].cast<String>() : [],
        requires: json["requires"] is List<dynamic> ? json["requires"].cast<String>() : [],
        installedAt: json["installedAt"] is int ? json["installedAt"] : 0,
        alwaysActive: json["alwaysActive"] is bool ? json["alwaysActive"] : false,
        modes: _modesFromJson(json),
        storageId: json["storageId"] is String ? json["storageId"] : null,
      );
    } else {
      return UserScriptModel(
        enabled: json["enabled"],
        matches: json["matches"] is List<dynamic> ? json["matches"].cast<String>() : const ["*"],
        name: json["name"],
        version: json["version"],
        manuallyEdited: json["edited"],
        source: json["source"],
        time: json["time"] == "start" ? UserScriptTime.start : UserScriptTime.end,
        url: json["url"],
        updateUrl: json["updateUrl"] is String ? json["updateUrl"] : null,
        updateStatus: UserScriptUpdateStatus.values.byName(json["updateStatus"] ?? "noRemote"),
        isExample: json["isExample"] ?? (json["exampleCode"] ?? 0) > 0,
        customApiKey: json["customApiKey"] ?? "",
        customApiKeyCandidate: json["customApiKeyCandidate"] ?? false,
        grants: json["grants"] is List<dynamic> ? json["grants"].cast<String>() : [],
        requires: json["requires"] is List<dynamic> ? json["requires"].cast<String>() : [],
        installedAt: json["installedAt"] is int ? json["installedAt"] : 0,
        alwaysActive: json["alwaysActive"] is bool ? json["alwaysActive"] : false,
        modes: _modesFromJson(json),
        storageId: json["storageId"] is String ? json["storageId"] : null,
      );
    }
  }

  // Old backups only carry the war flag
  static Set<String> _modesFromJson(Map<String, dynamic> json) => {
    if (json["modes"] is List) ...(json["modes"] as List).whereType<String>(),
    if (json["warEnabled"] == true) warModeId,
  };

  factory UserScriptModel.fromMetaMap(
    Map<String, dynamic> metaMap, {
    String? url,
    UserScriptUpdateStatus updateStatus = UserScriptUpdateStatus.noRemote,
    bool? isExample,
    String? name,
    String? source,
    UserScriptTime? time,
    String? customApiKey,
    bool? customApiKeyCandidate,
    bool? manuallyEdited,
  }) {
    if (metaMap["name"] == null) {
      throw Exception("No script name found in userscript");
    }
    if (metaMap["source"] == null) {
      // Really should not happen, but who knows...
      throw Exception("No script source found in userscript");
    }
    return UserScriptModel(
      name: name ?? metaMap["name"],
      version: metaMap["version"] ?? "0.0.0",
      source: source ?? metaMap["source"],
      matches: metaMap["matches"] ?? ["*"],
      url: url ?? metaMap["downloadURL"],
      updateUrl: metaMap["updateURL"],
      updateStatus: updateStatus,
      manuallyEdited: manuallyEdited ?? false,
      time: time ?? (metaMap["injectionTime"] == "document-start" ? UserScriptTime.start : UserScriptTime.end),
      isExample: isExample ?? false,
      customApiKey: customApiKey ?? "",
      customApiKeyCandidate: customApiKeyCandidate ?? false,
      grants: metaMap["grants"] ?? [],
      requires: metaMap["requires"] ?? [],
    );
  }

  static Future<({bool success, String message, UserScriptModel? model})> fromURL(String url, {bool? isExample}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final metaMap = UserScriptModel.parseHeader(response.body);
        return (
          success: true,
          message: "Success",
          model: UserScriptModel.fromMetaMap(
            metaMap,
            url: url,
            updateStatus: UserScriptUpdateStatus.upToDate,
            isExample: isExample ?? false,
            manuallyEdited: false, // Not manually edited if loaded from URL
          ),
        );
      } else {
        return (success: false, message: "Server responded with error code: ${response.statusCode}", model: null);
      }
    } catch (e) {
      return (success: false, message: "Error: $e", model: null);
    }
  }

  static bool isNewerVersion(String version1, String version2) {
    try {
      final v1 = VersionModel.parse(version1);
      final v2 = VersionModel.parse(version2);
      return v1.compareTo(v2) > 0;
    } catch (e) {
      // Fall back to simple string comparison if version parsing fails
      final versionRegex = RegExp(r"^(?:\d+\.)+\d+$");
      if (!versionRegex.hasMatch(version1) || !versionRegex.hasMatch(version2)) {
        // Can't compare versions if they don't match the regex, so just return true if they are different
        return version1 != version2;
      }
      final List<String> version1List = version1.split(".");
      final List<String> version2List = version2.split(".");
      for (int i = 0; i < version1List.length; i++) {
        if (version2List.length <= i || int.parse(version1List[i]) > int.parse(version2List[i])) {
          return true;
        }
      }
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
    "enabled": enabled,
    "matches": matches,
    "name": name,
    "version": version,
    "edited": manuallyEdited,
    "source": source,
    "url": url,
    "updateUrl": updateUrl,
    "updateStatus": updateStatus.name,
    "isExample": isExample,
    "time": time == UserScriptTime.start ? "start" : "end",
    "customApiKey": customApiKey,
    "customApiKeyCandidate": customApiKeyCandidate,
    "grants": grants,
    "requires": requires,
    "installedAt": installedAt,
    "modes": modes.toList(),
    "warEnabled": modes.contains(warModeId),
    "alwaysActive": alwaysActive,
    "storageId": storageId,
  };

  static Map<String, dynamic> parseHeader(String source) {
    // Thanks to [ViolentMonkey](https://github.com/violentmonkey/violentmonkey) for the following two regexes
    String? meta = RegExp(
      r"((?:^|\n)\s*\/\/\x20==UserScript==)([\s\S]*?\n)\s*\/\/\x20==\/UserScript==|$",
    ).stringMatch(source);
    if (meta == null || meta.isEmpty) {
      throw Exception("No header found in userscript.");
    }
    Iterable<RegExpMatch> metaMatches = RegExp(r"^(?:^|\n)\s*\/\/\x20(@\S+)(.*)$", multiLine: true).allMatches(meta);
    Map<String, dynamic> metaMap = {"@match": <String>[], "@grant": <String>[], "@require": <String>[]};
    for (final match in metaMatches) {
      if (match.groupCount < 2) {
        continue;
      }
      if (match.group(1) == null || match.group(2) == null) {
        continue;
      }
      final key = match.group(1)!.trim().toLowerCase();
      final value = match.group(2)!.trim();

      if (key == "@match") {
        metaMap["@match"].add(value);
      } else if (key == "@grant") {
        metaMap["@grant"].add(value);
      } else if (key == "@require") {
        metaMap["@require"].add(value);
      } else {
        metaMap[key] = value;
      }
    }
    return {
      "name": metaMap["@name"],
      "version": metaMap["@version"],
      "author": metaMap["@author"],
      "matches": (metaMap["@match"] as List<String>).isEmpty ? ["*"] : metaMap["@match"],
      "grants": metaMap["@grant"],
      "requires": metaMap["@require"],
      "injectionTime": metaMap["@run-at"] ?? "document-end",
      "downloadURL": metaMap["@downloadurl"],
      "updateURL": metaMap["@updateurl"],
      "source": source,
    };
  }

  bool matchesQuery(String query, {bool inSource = false}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    return inSource && source.toLowerCase().contains(q);
  }

  // Rebuilt when source or key changes
  String? _bodyFor;
  String? _bodyKey;
  String _body = "";

  String adaptedBody(String apiKey) {
    if (!identical(_bodyFor, source) || _bodyKey != apiKey) {
      _body = adaptBody(source, apiKey);
      _bodyFor = source;
      _bodyKey = apiKey;
    }
    return _body;
  }

  // Rebuilt when body or @match changes
  String? _startFor;
  String? _startGuard;
  String _start = "";

  String startSource(String apiKey) {
    final body = adaptedBody(apiKey);
    final guard = matchGuardJs;
    if (!identical(_startFor, body) || !identical(_startGuard, guard)) {
      _start = oncePerDocument(storageId, wrapSource(body, storageId), guard: guard);
      _startFor = body;
      _startGuard = guard;
    }
    return _start;
  }

  // Compiled @match patterns, rebuilt when matches changes
  List<String>? _compiledFor;
  List<RegExp?> _compiled = const [];

  /// Whether the script targets this url and injection time
  bool matchesTarget(String url, [UserScriptTime? time]) => matchingPattern(url, time) != null;

  /// The @match pattern that hits, if any
  String? matchingPattern(String url, [UserScriptTime? time]) {
    if (time != null && this.time != time) return null;
    _compile();
    String? withHash;
    String? noHash;
    for (var i = 0; i < _compiledFor!.length; i++) {
      final pattern = _compiledFor![i];
      if (pattern == '*') return pattern;
      // Keep hash only if pattern has one
      final target = pattern.contains('#') ? (withHash ??= _withPath(url)) : (noHash ??= _withPath(_withoutHash(url)));
      final regex = _compiled[i];
      // Non-standard pattern: old "contains" heuristic
      final hit = regex != null ? regex.hasMatch(target) : target.contains(pattern.replaceAll('*', ''));
      if (hit) return pattern;
    }
    return null;
  }

  void _compile() {
    if (listEquals(_compiledFor, matches)) return;
    _compiledFor = List.of(matches);
    _compiled = [for (final m in _compiledFor!) m == '*' ? null : _tryPatternToRegex(m)];
    _matchGuard = null;
  }

  String? _matchGuard;

  // matchesTarget in JS, null if any URL
  String? get matchGuardJs {
    _compile();
    if (_compiledFor!.contains('*')) return null;
    return _matchGuard ??= _buildMatchGuard();
  }

  String _buildMatchGuard() {
    final tests = <String>[];
    for (var i = 0; i < _compiledFor!.length; i++) {
      final pattern = _compiledFor![i];
      // Same hash rule as matchingPattern
      final target = pattern.contains('#') ? 'h' : 'u';
      final regex = _compiled[i];
      tests.add(
        regex != null
            ? "new RegExp(${jsonEncode(regex.pattern)}).test($target)"
            : "$target.indexOf(${jsonEncode(pattern.replaceAll('*', ''))})>=0",
      );
    }
    final hit = tests.isEmpty ? 'false' : tests.join('||');
    return "(function(h){var u=h.split('#')[0];return $hit;})(location.href)";
  }

  static RegExp? _tryPatternToRegex(String pattern) {
    try {
      return _patternToRegex(pattern);
    } catch (_) {
      return null;
    }
  }

  static String _withoutHash(String url) {
    final hash = url.indexOf('#');
    return hash < 0 ? url : url.substring(0, hash);
  }

  // Regex needs "/" after host
  static String _withPath(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.path.isEmpty ? '$url/' : url;
  }

  /// Converts a Tampermonkey-style @match pattern to a [RegExp].
  ///
  /// Supports standard patterns like `*://*.example.com/path/*` where:
  /// - Scheme `*` matches http or https
  /// - Host `*.example.com` matches any subdomain (including none)
  /// - `*` in the path matches any characters
  ///
  /// For backwards compatibility, patterns without a protocol get `*://`
  /// prepended, and patterns without a path get `/*` appended.
  static RegExp _patternToRegex(String pattern) {
    final fullMatch = RegExp(r'^(https?|http\*|file|\*):\/\/([^/]*)\/(.*)$').firstMatch(pattern);
    RegExpMatch? match = fullMatch;

    if (match == null) {
      // Try without a path (e.g. "https://example.com")
      final noPath = RegExp(r'^(https?|http\*|file|\*):\/\/([^/]*)$').firstMatch(pattern);
      if (noPath != null) {
        pattern = '$pattern/*';
        match = RegExp(r'^(https?|http\*|file|\*):\/\/([^/]*)\/(.*)$').firstMatch(pattern);
      }
    }

    if (match == null) {
      // Legacy pattern without protocol – prepend *://
      pattern = '*://$pattern';
      match = RegExp(r'^(https?|http\*|file|\*):\/\/([^/]*)\/(.*)$').firstMatch(pattern);
      if (match == null) {
        // Still no path component
        pattern = '$pattern/*';
        match = RegExp(r'^(https?|http\*|file|\*):\/\/([^/]*)\/(.*)$').firstMatch(pattern);
      }
    }

    if (match == null) {
      throw FormatException('Invalid @match pattern: $pattern');
    }

    final scheme = match.group(1)!;
    final host = match.group(2)!;
    final path = match.group(3)!;

    final schemeRe = scheme == '*' || scheme == 'http*' ? 'https?' : RegExp.escape(scheme);

    String hostRe = RegExp.escape(host);
    // Handle *.example.com  →  optional subdomain prefix
    if (host.startsWith('*.')) {
      hostRe = '(?:[^/]+\\.)?${RegExp.escape(host.substring(2))}';
    } else {
      hostRe = hostRe.replaceAll(r'\*', '[^/]*');
    }
    // Any port, unless the pattern has one
    if (!host.contains(':')) hostRe = '$hostRe(?::\\d+)?';

    final pathRe = RegExp.escape(path).replaceAll(r'\*', '.*');

    return RegExp('^$schemeRe://$hostRe/$pathRe\$');
  }

  void update({
    bool? enabled,
    List<String>? matches,
    String? name,
    String? version,
    bool? manuallyEdited,
    String? source,
    UserScriptTime? time,
    String? url,
    String? customApiKey,
    bool? customApiKeyCandidate,
    required UserScriptUpdateStatus updateStatus,
  }) {
    if (source != null) {
      this.source = source;
      try {
        final metaMap = UserScriptModel.parseHeader(source);
        if (metaMap["version"] != null) {
          this.version = metaMap["version"];
        }
        if (metaMap["matches"] != null) {
          this.matches = metaMap["matches"];
        }
        if (metaMap["name"] != null) {
          this.name = metaMap["name"];
        }
        if (metaMap["injectionTime"] != null) {
          this.time = metaMap["injectionTime"] == "document-start" ? UserScriptTime.start : UserScriptTime.end;
        }
        if (metaMap["downloadURL"] != null) {
          this.url = metaMap["downloadURL"];
        }
        if (metaMap["updateURL"] != null) {
          updateUrl = metaMap["updateURL"];
        }
      } catch (e) {
        // Do nothing
      }
    }
    if (enabled != null) {
      this.enabled = enabled;
    }
    if (matches != null) {
      this.matches = matches;
    }
    if (name != null) {
      this.name = name;
    }
    if (version != null) {
      this.version = version;
    }
    if (manuallyEdited != null) {
      this.manuallyEdited = manuallyEdited;
    }
    if (time != null) {
      this.time = time;
    }
    if (url != null) {
      this.url = url;
    }
    if (customApiKey != null) {
      this.customApiKey = customApiKey;
    }
    if (customApiKeyCandidate != null) {
      this.customApiKeyCandidate = customApiKeyCandidate;
    }
    this.updateStatus = updateStatus;
  }

  Future<UserScriptUpdateStatus> checkUpdateStatus() async {
    if (url == null) {
      return UserScriptUpdateStatus.noRemote;
    }

    // Try the metadata file first
    // Anything unexpected there falls back to the full source below
    final String? declared = updateUrl ?? tryGetUpdateUrl(source);
    final String? metaUrl = (declared != null && declared.isNotEmpty && declared != url) ? declared : null;
    if (metaUrl != null) {
      final String? remoteVersion = await _fetchRemoteVersion(metaUrl);
      if (remoteVersion != null) {
        return UserScriptModel.isNewerVersion(remoteVersion, version)
            ? UserScriptUpdateStatus.updateAvailable
            : UserScriptUpdateStatus.upToDate;
      }
    }

    try {
      final response = await http.get(Uri.parse(url!));
      if (response.statusCode == 200) {
        final metaMap = UserScriptModel.parseHeader(response.body);
        if (metaMap["version"] == null) {
          return UserScriptUpdateStatus.upToDate;
        }
        return UserScriptModel.isNewerVersion(metaMap["version"], version)
            ? UserScriptUpdateStatus.updateAvailable
            : UserScriptUpdateStatus.upToDate;
      }
    } catch (_) {
      return UserScriptUpdateStatus.error;
    }
    return UserScriptUpdateStatus.error;
  }

  /// Version declared in a remote header, or null if it can't be read for any reason
  static Future<String?> _fetchRemoteVersion(String from) async {
    try {
      final response = await http.get(Uri.parse(from));
      if (response.statusCode != 200) return null;
      final metaMap = UserScriptModel.parseHeader(response.body);
      final version = metaMap["version"];
      return version is String && version.isNotEmpty ? version : null;
    } catch (_) {
      return null;
    }
  }

  static List<String> tryGetMatches(String source) {
    try {
      final metaMap = parseHeader(source);
      return metaMap["matches"] ?? const ["*"];
    } catch (e) {
      return const ["*"];
    }
  }

  static String? tryGetUrl(String source) {
    try {
      final metaMap = UserScriptModel.parseHeader(source);
      return metaMap["downloadURL"];
    } catch (e) {
      return null;
    }
  }

  static String? tryGetUpdateUrl(String source) {
    try {
      final metaMap = UserScriptModel.parseHeader(source);
      return metaMap["updateURL"];
    } catch (e) {
      return null;
    }
  }

  static String? tryGetVersion(String source) {
    try {
      final metaMap = UserScriptModel.parseHeader(source);
      return metaMap["version"];
    } catch (e) {
      return null;
    }
  }

  static List<String?> exampleScriptURLs = const [
    // 1: Bazaar Auto Price
    "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Bazaar%20Auto%20Price%20(Torn%20PDA).js",
    // 2: TornCat (deprecated)
    null,
    // 3: Custom Race Presets
    "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Custom%20Race%20Presets%20(Torn%20PDA).js",
    // 4: Custom Gym Ratios
    "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Custom%20Gym%20Ratios%20(Torn%20PDA).js",
    // 5: Company Stocks Order
    "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Company%20Stock%20Order%20(Torn%20PDA).js",
    // 6: Company Activity
    "https://github.com/Manuito83/torn-pda/raw/master/userscripts/Company%20Activity%20(Torn%20PDA).js",
    // 7: Hospital Filters
    // TODO: Add remote for Hosp Filters after merge
    null,
  ];
}
