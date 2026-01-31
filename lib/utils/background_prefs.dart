import 'package:shared_preferences/shared_preferences.dart';

/// Background-safe preferences access.
///
/// Contract: only keys listed here are safe to read from background isolates.
class BackgroundPrefs {
  static final BackgroundPrefs _instance = BackgroundPrefs._internal();
  factory BackgroundPrefs() => _instance;
  BackgroundPrefs._internal();

  static const String _kOwnDetails = "pda_ownDetails";
  static const String _kDefaultTimeFormat = "pda_defaultTimeFormat";
  static const String _kDefaultTimeZone = "pda_defaultTimeZone";
  static const String _kActiveShortcutsList = "pda_activeShortcutsList";

  Future<String> getOwnDetails() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString(_kOwnDetails)) ?? "";
  }

  Future<String> getDefaultTimeFormat() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString(_kDefaultTimeFormat)) ?? "24";
  }

  Future<String> getDefaultTimeZone() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString(_kDefaultTimeZone)) ?? "local";
  }

  Future<List<String>> getActiveShortcutsList() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getStringList(_kActiveShortcutsList)) ?? <String>[];
  }
}
