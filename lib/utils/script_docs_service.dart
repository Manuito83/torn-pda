// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/services.dart' show rootBundle;

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import "package:http/http.dart" as http;

enum ScriptDocFormat { markdown, javascript, native }

class ScriptDocEntry {
  const ScriptDocEntry({
    required this.title,
    required this.subtitle,
    required this.path,
    required this.group,
    this.format = ScriptDocFormat.markdown,
  });

  final String title;
  final String subtitle;
  final String path;
  final String group;
  final ScriptDocFormat format;
}

class ScriptDocsService {
  static const String _rawBase = "https://raw.githubusercontent.com/Manuito83/torn-pda/master/";

  static const String _blobBase = "https://github.com/Manuito83/torn-pda/blob/master/";

  static const Duration _timeout = Duration(seconds: 12);

  static const String groupGuide = "Guide";
  static const String groupScripting = "Writing scripts";
  static const String groupHandlers = "Talking to the app";
  static const String groupHelpers = "Helper scripts";

  static const List<ScriptDocEntry> entries = [
    ScriptDocEntry(
      title: "Using scripts in Torn PDA",
      subtitle: "Adding scripts, updates, injection times and troubleshooting",
      path: "",
      group: groupGuide,
      format: ScriptDocFormat.native,
    ),
    ScriptDocEntry(
      title: "Native script storage",
      subtitle: "PDA_storage, a per script store that survives a cache wipe",
      path: "userscripts/TornPDA_Storage.md",
      group: groupScripting,
    ),
    ScriptDocEntry(
      title: "GM compatibility",
      subtitle: "Supported GM APIs, headers and grants",
      path: "docs/userscripts/gm-compatibility.md",
      group: groupScripting,
    ),
    ScriptDocEntry(
      title: "Handlers overview",
      subtitle: "How JavaScript talks to the native side of the app",
      path: "docs/webview/webview-handlers.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "HTTP requests",
      subtitle: "GET and POST calls that bypass Torn's content security policy",
      path: "docs/webview/http-handlers.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Evaluate JavaScript",
      subtitle: "Run code fetched at runtime, where eval is blocked",
      path: "docs/webview/evaluate-js-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Notifications",
      subtitle: "Native notifications, alarms and timers from a script",
      path: "docs/webview/notification-handlers.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Toast messages",
      subtitle: "Short native messages on top of the page",
      path: "docs/webview/toast-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Copy to clipboard",
      subtitle: "Write text to the device clipboard",
      path: "docs/webview/copy-to-clipboard-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Share a file",
      subtitle: "Hand a generated file to the device share sheet",
      path: "docs/webview/share-file-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Reload the page",
      subtitle: "Trigger a native reload of the current tab",
      path: "docs/webview/reload-page-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Tab state",
      subtitle: "Read and react to the state of the browser tabs",
      path: "docs/webview/tab-state-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Detecting Torn PDA",
      subtitle: "Tell whether your script is running inside the app",
      path: "docs/webview/torn-pda-check-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "Android intents",
      subtitle: "Fire an Android intent from a script",
      path: "docs/webview/pda-intent-handler.md",
      group: groupHandlers,
    ),
    ScriptDocEntry(
      title: "GMforPDA",
      subtitle: "Self updating GM handler, overrides the built-in one",
      path: "userscripts/GMforPDA.user.js",
      group: groupHelpers,
      format: ScriptDocFormat.javascript,
    ),
    ScriptDocEntry(
      title: "TornPDA_API",
      subtitle: "Helper for GET and POST calls through the app",
      path: "userscripts/TornPDA_API.js",
      group: groupHelpers,
      format: ScriptDocFormat.javascript,
    ),
    ScriptDocEntry(
      title: "TornPDA_EvaluateJavascript",
      subtitle: "Helper to evaluate code from the app",
      path: "userscripts/TornPDA_EvaluateJavascript.js",
      group: groupHelpers,
      format: ScriptDocFormat.javascript,
    ),
    ScriptDocEntry(
      title: "TornPDA_Ready",
      subtitle: "Wait until the app is ready before running",
      path: "userscripts/TornPDA_Ready.js",
      group: groupHelpers,
      format: ScriptDocFormat.javascript,
    ),
  ];

  static List<String> get devGroups => const [groupScripting, groupHandlers, groupHelpers];

  static ScriptDocEntry get guide => entries.firstWhere((e) => e.group == groupGuide);

  static const String devDocsUrl = "https://github.com/Manuito83/torn-pda/blob/master/docs/README.md";

  static List<ScriptDocEntry> entriesIn(String group) => entries.where((e) => e.group == group).toList();

  static ScriptDocEntry? entryForPath(String path) {
    for (final entry in entries) {
      if (entry.path == path) return entry;
    }
    return null;
  }

  static String githubUrlFor(String path) => "$_blobBase$path";

  static Future<String?> bundled(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e, trace) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA error loading bundled doc '$path'. Error: $e");
        FirebaseCrashlytics.instance.recordError(e, trace);
      }
      return null;
    }
  }

  static Future<String?> remote(String path) async {
    try {
      final response = await http.get(Uri.parse("$_rawBase$path")).timeout(_timeout);
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) return response.body;
    } catch (_) {}
    return null;
  }

  static String resolveRelative(String fromPath, String href) {
    if (href.startsWith("http")) return href;

    final base = fromPath.contains("/") ? fromPath.substring(0, fromPath.lastIndexOf("/")) : "";
    final segments = <String>[...base.split("/").where((s) => s.isNotEmpty)];

    for (final segment in href.split("?").first.split("#").first.split("/")) {
      if (segment.isEmpty || segment == ".") continue;
      if (segment == "..") {
        if (segments.isNotEmpty) segments.removeLast();
        continue;
      }
      segments.add(segment);
    }

    return segments.join("/");
  }

  static String absoluteUrlFor(String fromPath, String href) {
    if (href.startsWith("http")) return href;
    return "$_rawBase${resolveRelative(fromPath, href)}";
  }
}
