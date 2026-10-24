import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/utils/discreet_schedule.dart';

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
  static const String _kChatInbox = "pda_chatStatsInbox";
  static const String _kChatCounts = "pda_chatStatsCounts";
  static const String _kChatDaily = "pda_chatStatsDaily";
  static const String _kChatMode = "pda_chatStatsMode";
  static const String _kUsageBucket = "pda_usageCounts_";
  static const String _kUsageDaily = "pda_usageCountsDaily";
  static const String _kDiscreetNotifications = "pda_discreteNotifications"; // We need to accept this typo
  static const String _kDiscreetSchedule = "pda_discreetSchedule";
  static const String _kDiscreetScheduleFrom = "pda_discreetScheduleFrom";
  static const String _kDiscreetScheduleTo = "pda_discreetScheduleTo";

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
  Future<void> addChatEntry(String entry, {int max = 500}) async {
    final prefs = SharedPreferencesAsync();
    final inbox = (await prefs.getStringList(_kChatInbox)) ?? <String>[];
    if (inbox.length >= max) return;
    await prefs.setStringList(_kChatInbox, [...inbox, entry]);
  }

  Future<List<String>> takeChatEntries() async {
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

  Future<void> setDiscreetNotifications(bool value) async {
    await SharedPreferencesAsync().setBool(_kDiscreetNotifications, value);
  }

  Future<void> setDiscreetSchedule(DiscreetSchedule value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool(_kDiscreetSchedule, value.enabled);
    await prefs.setInt(_kDiscreetScheduleFrom, value.from);
    await prefs.setInt(_kDiscreetScheduleTo, value.to);
  }

  Future<bool> getDiscreetAt([DateTime? time]) async {
    final prefs = SharedPreferencesAsync();
    const fallback = DiscreetSchedule();
    return isDiscreetAt(
      always: await prefs.getBool(_kDiscreetNotifications) ?? false,
      schedule: DiscreetSchedule(
        enabled: await prefs.getBool(_kDiscreetSchedule) ?? false,
        from: await prefs.getInt(_kDiscreetScheduleFrom) ?? fallback.from,
        to: await prefs.getInt(_kDiscreetScheduleTo) ?? fallback.to,
      ),
      time: time ?? DateTime.now(),
    );
  }
}
