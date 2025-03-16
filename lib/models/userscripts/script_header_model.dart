import 'dart:math' as math;

class ScriptHeaderModel {
  /// The header entries, with the key being the header name (including the `@` symbol) and the value being a list of
  /// values. Example: `{"@name": ["My Script"], "@match": ["https://example.com/*", "https://example2.com/*"]}`.
  /// This allows for multiple values for a single header, such as multiple `@match` values.
  /// Both keys and values are not case-sensitive.
  Map<String, List<String>> header;
  VersionModel version;

  ScriptHeaderModel({required this.header, required this.version});

  /// Get the value of a header entry. If the header does not exist, returns an empty list.
  /// The key is not case-sensitive.
  List<String> getHeader(String key) {
    // Check for the key with the `@PDA-OVERRIDE-$key` format first, then the standard `@$key` format.
    // This allows developers to override headers to allow for different configurations on ViolentMonkey / TamperMonkey
    // versus PDA to handle some weird mobile quirks.
    return header["@pda-override-$key"] ?? header["@$key"] ?? [];
  }

  /// Compares the version of two script header models. Returns -1 if this model is older, 0 if they are the same, and 1
  /// if this model is newer. If the version cannot be determined, returns null.
  int compareVersion(ScriptHeaderModel otherModel) {
    return version.compareTo(otherModel.version);
  }

  bool shouldInject(Uri uri) {
    final matches = getHeader("match");
    if (matches.isEmpty) return true; // If no match headers are present, inject on all URLs
    // TODO: Proper match patterns, exclude headers, include headers
    return matches.any((match) => uri.toString().contains(match.replaceAll("*", "")));
  }

  /// Create a ScriptHeaderModel from a header map, parsing the version model from the `@version` header. Note that the
  /// version header is required, and does not support PDA overrides.
  factory ScriptHeaderModel.fromHeader(Map<String, List<String>> header) {
    final version = header["@version"]?.first;
    if (version == null) throw Exception("Invalid version number");
    return ScriptHeaderModel(header: header, version: VersionModel.parse(version));
  }

  /// Create a ScriptHeaderModel from the header text. This expects key-value pairs ONLY, such as `@name:  value` and
  /// should not include the `==UserScript==` or `==/UserScript==` lines.
  factory ScriptHeaderModel.fromHeaderText(String text) {
    final header = <String, List<String>>{};
    final matches = regex["HEADER_ROW"]!.allMatches(text);
    for (final match in matches) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        header.putIfAbsent(key.toLowerCase(), () => []).add(value.toLowerCase());
      }
    }
    return ScriptHeaderModel.fromHeader(header);
  }

  factory ScriptHeaderModel.fromScriptText(String text) {
    final headerText = regex["HEADER_TEXT"]!.firstMatch(text)?.group(1);
    if (headerText == null) throw Exception("Invalid userscript header");
    return ScriptHeaderModel.fromHeaderText(headerText);
  }

  /// These have been (somewhat) modified from the ViolentMonkey source code, available here:
  /// https://github.com/violentmonkey/violentmonkey
  static final regex = Map<String, RegExp>.unmodifiable({
    /// Get the header text from a valid userscript.
    /// Group 1 has the script header, minus the `==UserScript==` and `==/UserScript==` lines.
    "HEADER_TEXT": RegExp(r"(?:^|\n).*?\/\/[\x20\t]*==UserScript==([\s\S]*?\n).*?\/\/[\x20\t]*==\/UserScript=="),

    /// Parse the header text to seperate into key-value pairs.
    /// Group 1 is the key (`@match`), Group 2 is the value (`https://example.com/*`).
    "HEADER_ROW": RegExp(r"(?:^|\n).*?\/\/[\x20\t]*(@\S+)[\s]+(.*)"),

    /// Parse the version number from the header. Group 1 is `MAJOR.MINOR.PATCH`, Group 2 is the `VERSION` string.
    /// Example: For `1.0.0-alpha`, Group 1 is `1.0.0`, Group 2 is `alpha`.
    "VERSION": RegExp(r"^(\d+(?:\.\d+)*)(?:-([\S]+))?$")
  });
}

class VersionModel {
  final int major;
  final int minor;
  final int patch;
  final String? pre;

  VersionModel({
    required this.major,
    required this.minor,
    required this.patch,
    this.pre,
  });

  factory VersionModel.parse(String text) {
    final match = ScriptHeaderModel.regex["VERSION"]!.firstMatch(text);
    // print(match?.groups([0, 1, 2, 3, 4]));
    if (match == null) throw Exception("Could not parse version number from $text");
    final version = match.group(1);
    final pre = match.group(2);
    if (version == null) throw Exception("Could not parse version number from $text");
    final parts = version.split(".").map(int.parse).toList();
    if (parts.length != 3) throw Exception("Invalid version number: $text");
    return VersionModel(major: parts[0], minor: parts[1], patch: parts[2], pre: pre);
  }

  /// Compares two version numbers. Returns a negative number if this version is older, 0 if they are the same, and a
  /// positive number if this version is newer.
  /// TODO: Testing (see https://github.com/violentmonkey/violentmonkey/blob/6eafc3d3630926319ff9526c594ef2ea8f7ea31f/test/common/index.test.js#L38)
  int compareTo(VersionModel other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    if (other.pre == null) {
      if (pre == null) return 0;
      return -1; // A pre-release version is always older than a stable version
    } else {
      if (pre == null) return 1;
      return _comparePreRelease(pre!, other.pre!);
    }
  }

  /// Compare pre-release version strings, exactly how ViolentMonkey compares the two.
  /// https://github.com/violentmonkey/violentmonkey/blob/6eafc3d3630926319ff9526c594ef2ea8f7ea31f/src/common/util.js#L151
  static int _comparePreRelease(String pre1, String pre2) {
    final parts1 = pre1.split(".");
    final parts2 = pre2.split(".");

    final len1 = parts1.length;
    final len2 = parts2.length;

    final len = math.min(len1, len2);

    for (int i = 0; i < len; i++) {
      final a = parts1[i];
      final b = parts2[i];

      if (a == b) continue;

      final parsedA = int.tryParse(a);
      final parsedB = int.tryParse(b);

      if (parsedA != null && parsedB != null) {
        return parsedA - parsedB;
      }
      return a.compareTo(b);
    }
    return len1 - len2;
  }
}