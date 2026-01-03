import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AlarmKitServiceIos {
  static const MethodChannel _channel = MethodChannel('tornpda/alarm');
  static bool debugQuickAlarm = true;
  static int debugLeadSeconds = 20;

  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;

    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;
    final parts = iosInfo.systemVersion.split('.');
    if (parts.isNotEmpty) {
      final major = int.tryParse(parts.first);
      if (major != null && major >= 26) {
        return true;
      }
    }
    return false;
  }

  /// Sets an alarm that triggers at the specified time
  /// [targetTime] - The DateTime when the alarm should fire
  /// [label] - Optional label for the alarm alert
  /// [id] - Optional unique ID string (e.g. "loot", "energy"). If provided, overwrites existing alarm with same ID.
  static Future<void> setAlarm({
    required DateTime targetTime,
    String? label,
    String? id,
    Map<String, dynamic>? metadata,
  }) async {
    if (debugQuickAlarm && kDebugMode) {
      final now = DateTime.now().add(Duration(seconds: debugLeadSeconds));
      log('⏰ Quick mode active (debugQuickAlarm=$debugQuickAlarm kReleaseMode=$kReleaseMode kDebugMode=$kDebugMode) target was ${targetTime.toIso8601String()} now=${now.toIso8601String()}',
          name: 'AlarmKit');
      Map<String, dynamic>? adjustedMetadata;
      if (metadata != null) {
        adjustedMetadata = Map<String, dynamic>.from(metadata);
        adjustedMetadata['timeMillis'] = now.millisecondsSinceEpoch;
      }
      log('⏰ Debug alarm set for ${now.toIso8601String()} (+${debugLeadSeconds}s)', name: 'AlarmKit');

      final response = await _channel.invokeMapMethod<String, dynamic>('setAlarm', {
        'milliseconds': now.millisecondsSinceEpoch,
        'label': label,
        'id': id,
        'metadata': adjustedMetadata,
      });
      _logDebug(response);
      await _persistAlarmMetadata(response, adjustedMetadata);
      return;
    }

    final response = await _channel.invokeMapMethod<String, dynamic>('setAlarm', {
      'milliseconds': targetTime.millisecondsSinceEpoch,
      'label': label,
      'id': id,
      'metadata': metadata,
    });
    _logDebug(response);
    await _persistAlarmMetadata(response, metadata);
  }

  /// Convenience wrapper that builds metadata before scheduling an alarm
  static Future<void> setAlarmWithMetadata({
    required DateTime targetTime,
    required String id,
    String? label,
    String? context,
    String? details,
    String? payload,
    int? timeMillis,
    Map<String, dynamic>? extraMetadata,
  }) async {
    final metadata = buildMetadata(
      alarmId: id,
      label: label,
      context: context,
      details: details,
      payload: payload,
      timeMillis: timeMillis ?? targetTime.millisecondsSinceEpoch,
      extra: extraMetadata,
    );
    await setAlarm(
      targetTime: targetTime,
      label: label,
      id: id,
      metadata: metadata,
    );
  }

  static void _logDebug(Map<String, dynamic>? response) {
    final debug = response?['debug'];
    if (debug is String && debug.isNotEmpty) {
      log('⏰ $debug', name: 'AlarmKit');
    }
  }

  static Future<void> _persistAlarmMetadata(Map<String, dynamic>? response, Map<String, dynamic>? metadata) async {
    if (metadata == null || metadata.isEmpty) return;
    final uuid = response?['uuid'];
    if (uuid is String) {
      await Prefs().upsertIosAlarmMetadata(uuid, metadata);
    }
  }

  /// Builds a metadata map with common fields used across the app.
  static Map<String, dynamic> buildMetadata({
    required String alarmId,
    String? label,
    String? context,
    String? details,
    String? payload,
    int? timeMillis,
    Map<String, dynamic>? extra,
  }) {
    final metadata = <String, dynamic>{'alarmId': alarmId};
    if (label != null) metadata['label'] = label;
    if (context != null) metadata['context'] = context;
    if (details != null) metadata['details'] = details;
    if (payload != null) metadata['payload'] = payload;
    if (timeMillis != null) metadata['timeMillis'] = timeMillis;
    if (extra != null) metadata.addAll(extra);
    return metadata;
  }

  static Future<List<Map<String, dynamic>>> listAlarms() async {
    try {
      final result = await _channel.invokeMethod('listAlarms');
      if (result is List) {
        final alarms = result.cast<Map<Object?, Object?>>().map((e) => e.cast<String, dynamic>()).toList();
        final storedMetadata = await Prefs().getIosAlarmMetadata();
        final activeIds = <String>{};
        final enrichedAlarms = <Map<String, dynamic>>[];

        for (var alarm in alarms) {
          final normalizedAlarm = Map<String, dynamic>.from(alarm);
          if (normalizedAlarm.containsKey('debug')) {
            log('⏰ ${normalizedAlarm['debug']}', name: 'AlarmKit');
          }
          final id = normalizedAlarm['id'];
          if (id is String) {
            activeIds.add(id);
            final metadata = storedMetadata[id];
            if (metadata != null) {
              normalizedAlarm['metadata'] = Map<String, dynamic>.from(metadata);
            }
          }
          enrichedAlarms.add(normalizedAlarm);
        }

        await Prefs().compactIosAlarmMetadata(activeIds);
        return enrichedAlarms;
      }
    } catch (e) {
      log('⏰ Error listing alarms: $e', name: 'AlarmKit');
    }
    return [];
  }

  static Future<void> cancelAlarm(String id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
      await Prefs().removeIosAlarmMetadata(id);
    } catch (e) {
      log('⏰ Error canceling alarm: $e', name: 'AlarmKit');
    }
  }

  /// Registers a callback to receive payloads forwarded from the native AlarmKit intent.
  static void registerAlarmTapHandler(void Function(String payload) onPayload) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'handleAlarmTap' || call.method == 'handleLootTap') {
        final args = call.arguments as Map?;
        final payload = args?['payload'] as String?;
        final debug = args?['debug'] as String?;
        if (debug != null) {
          log('⏰ $debug', name: 'AlarmKit');
        }
        if (payload != null) {
          onPayload(payload);
        }
      } else if (call.method == 'handleAlarmDebug' || call.method == 'handleLootTapDebug') {
        final args = call.arguments as Map?;
        final message = args?['message'] as String?;
        if (message != null) {
          log('⏰ $message', name: 'AlarmKit');
        }
      }
      return null;
    });
  }

  static Future<void> cancelAllAlarms() async {
    final alarms = await listAlarms();
    for (final alarm in alarms) {
      final id = alarm['id'];
      if (id is String) {
        await cancelAlarm(id);
      }
    }
  }

  /// Returns the logical identifier for an AlarmKit entry, preferring metadata.alarmId when present
  static String? logicalIdFromAlarm(Map<String, dynamic> alarm) {
    final metadata = (alarm['metadata'] as Map?)?.cast<String, dynamic>();
    final logicalId = metadata?['alarmId'];
    if (logicalId is String && logicalId.isNotEmpty) {
      return logicalId;
    }
    final id = alarm['id'];
    if (id is String && id.isNotEmpty) {
      return id;
    }
    return null;
  }

  /// Lightweight display info for UI when metadata is missing; tries to derive from logical ID patterns
  static AlarmDisplayInfo displayInfoFromAlarm(Map<String, dynamic> alarm) {
    final metadata = (alarm['metadata'] as Map?)?.cast<String, dynamic>();
    final logicalId = logicalIdFromAlarm(alarm);

    // Prefer explicit metadata for label/details
    final metaLabel = metadata?['context'] as String? ?? metadata?['label'] as String?;
    final metaDetails = metadata?['details'] as String?;
    if (metaLabel != null || metaDetails != null) {
      return AlarmDisplayInfo(label: metaLabel ?? 'Alarm', details: metaDetails);
    }

    if (logicalId != null) {
      final lootMatch = RegExp(r'^loot_alarm_(.+)_(\d+)$').firstMatch(logicalId);
      if (lootMatch != null) {
        final npcId = lootMatch.group(1);
        final level = lootMatch.group(2);
        final label = 'Loot level $level';
        final details = npcId != null ? 'Loot alarm for NPC $npcId' : null;
        return AlarmDisplayInfo(label: label, details: details);
      }
      return AlarmDisplayInfo(label: logicalId, details: null);
    }

    return const AlarmDisplayInfo(label: 'Alarm', details: null);
  }

  /// Returns the logical IDs of all active alarms (metadata.alarmId if present, otherwise id)
  static Future<Set<String>> listLogicalIds() async {
    final alarms = await listAlarms();
    final ids = <String>{};
    for (final alarm in alarms) {
      final logicalId = logicalIdFromAlarm(alarm);
      if (logicalId != null) {
        ids.add(logicalId);
      }
    }
    return ids;
  }

  /// Descriptor for Profile alarms (logical ID + context + payload) keyed by profile notification string
  static AlarmKitProfileDescriptor profileDescriptor(String notificationKey) {
    switch (notificationKey) {
      case 'travel':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_travel',
          context: 'Travel alarm',
          payload: 'travel',
        );
      case 'energy':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_energy',
          context: 'Energy alarm',
          payload: 'profile:energy',
        );
      case 'nerve':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_nerve',
          context: 'Nerve alarm',
          payload: 'profile:nerve',
        );
      case 'life':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_life',
          context: 'Life alarm',
          payload: 'profile:life',
        );
      case 'drugs':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_drugs',
          context: 'Drugs cooldown alarm',
          payload: 'profile:drugs',
        );
      case 'medical':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_medical',
          context: 'Medical cooldown alarm',
          payload: 'profile:medical',
        );
      case 'booster':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_booster',
          context: 'Booster cooldown alarm',
          payload: 'profile:booster',
        );
      case 'hospital':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_hospital',
          context: 'Hospital release alarm',
          payload: 'profile:hospital',
        );
      case 'jail':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_jail',
          context: 'Jail release alarm',
          payload: 'profile:jail',
        );
      case 'rankedWar':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_ranked_war',
          context: 'Ranked war alarm',
          payload: 'profile:rankedWar',
        );
      case 'raceStart':
        return const AlarmKitProfileDescriptor(
          alarmId: 'profile_race_start',
          context: 'Race start alarm',
          payload: 'profile:raceStart',
        );
      default:
        return AlarmKitProfileDescriptor(
          alarmId: 'profile_$notificationKey',
          context: 'Alarm',
          payload: 'profile:$notificationKey',
        );
    }
  }
}

class AlarmDisplayInfo {
  final String label;
  final String? details;

  const AlarmDisplayInfo({required this.label, this.details});
}

class AlarmKitProfileDescriptor {
  final String alarmId;
  final String context;
  final String payload;

  const AlarmKitProfileDescriptor({
    required this.alarmId,
    required this.context,
    required this.payload,
  });
}
