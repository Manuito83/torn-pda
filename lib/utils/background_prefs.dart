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
  static const String _kTornChatDmPush = "pda_tornChatDmPush";
  static const String _kChatPushRules = "pda_nativeChatPushRules";
  static const String _kVibrationPattern = "pda_vibrationPattern";
  static const String _kChatInbox = "pda_chatTelemetryInbox";
  static const String _kChatCounts = "pda_chatTelemetryCounts";
  static const String _kChatDaily = "pda_chatTelemetryDaily";
  static const String _kChatMode = "pda_chatTelemetryMode";
  static const String _kUsageBucket = "pda_usageCounts_";
  static const String _kUsageDaily = "pda_usageCountsDaily";

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

  Future<bool> getTornChatDmPush() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getBool(_kTornChatDmPush)) ?? true;
  }

  Future<String> getVibrationPattern() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString(_kVibrationPattern)) ?? "medium";
  }

  Future<String> getChatPushRules() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString(_kChatPushRules)) ?? "";
  }

  /// Written from the main isolate only
  Future<void> setChatPushRules(String value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_kChatPushRules, value);
  }

  /// Any isolate, drained by the main one
  Future<void> addChatTelemetry(String entry, {int max = 500}) async {
    final prefs = SharedPreferencesAsync();
    final inbox = (await prefs.getStringList(_kChatInbox)) ?? <String>[];
    if (inbox.length >= max) return;
    await prefs.setStringList(_kChatInbox, [...inbox, entry]);
  }

  Future<List<String>> takeChatTelemetry() async {
    final prefs = SharedPreferencesAsync();
    final inbox = (await prefs.getStringList(_kChatInbox)) ?? <String>[];
    if (inbox.isNotEmpty) await prefs.remove(_kChatInbox);
    return inbox;
  }

  /// Written from the main isolate only
  Future<String> getChatCounts() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString(_kChatCounts)) ?? "";
  }

  Future<void> setChatCounts(String value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_kChatCounts, value);
  }

  Future<int> getChatDaily() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getInt(_kChatDaily)) ?? 0;
  }

  Future<void> setChatDaily(int value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt(_kChatDaily, value);
  }

  Future<String> getChatMode() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString(_kChatMode)) ?? "";
  }

  Future<void> setChatMode(String value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_kChatMode, value);
  }

  Future<String> getUsageBucket(String bucket) async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getString('$_kUsageBucket$bucket')) ?? "";
  }

  Future<void> setUsageBucket(String bucket, String value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('$_kUsageBucket$bucket', value);
  }

  Future<List<String>> getUsageBuckets() async {
    final prefs = SharedPreferencesAsync();
    final keys = await prefs.getKeys();
    return [for (final key in keys) if (key.startsWith(_kUsageBucket)) key.substring(_kUsageBucket.length)];
  }

  Future<String> takeUsageBucket(String bucket) async {
    final prefs = SharedPreferencesAsync();
    final value = (await prefs.getString('$_kUsageBucket$bucket')) ?? "";
    await prefs.remove('$_kUsageBucket$bucket');
    return value;
  }

  /// Written from the main isolate only
  Future<int> getUsageDaily() async {
    final prefs = SharedPreferencesAsync();
    return (await prefs.getInt(_kUsageDaily)) ?? 0;
  }

  Future<void> setUsageDaily(int value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt(_kUsageDaily, value);
  }
}
