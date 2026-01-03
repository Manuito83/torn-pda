import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/main.dart';
import 'package:torn_pda/utils/alarm_kit_service_ios.dart';
import 'package:torn_pda/utils/notification.dart';

class WebviewNotificationsHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Schedule a notification from JS parameters
  static Future<String> scheduleJsNotification({
    required String title,
    String subtitle = '',
    required int id,
    required int timestampMillis,
    bool overwriteID = false,
    bool launchNativeToast = true,
    String toastMessage = '',
    String toastColor = 'blue',
    int toastDurationSeconds = 3,
    String payload = '',
    required Function assessNotificationPermissions,
  }) async {
    final int finalId = int.parse('$webviewNotificationIdPrefix$id');
    final notificationTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

    String finalPayload = "";
    if (payload.isNotEmpty && payload.contains("##-88-##")) {
      final parts = payload.split("##-88-##");

      if (parts[1].isNotEmpty) {
        final String urlPart = parts[1];
        final uri = Uri.tryParse(urlPart);
        if (uri == null || !uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          return 'Error: Provided payload does not contain a valid URL';
        }
        final validatedUrl = (uri.scheme == 'http') ? uri.replace(scheme: 'https').toString() : urlPart;
        finalPayload = "$timestampMillis##-88-##$validatedUrl";
      } else {
        finalPayload = "$timestampMillis##-88-##";
      }
    } else {
      return 'Error: Payload error, no valid timestamp found!';
    }

    final pendingNotificationRequests = await _notificationsPlugin.pendingNotificationRequests();
    final exists = pendingNotificationRequests.any((notif) => notif.id == finalId);

    if (exists && !overwriteID) {
      return 'Error: Notification with ID $id already exists and overwriteID=false';
    }

    if (exists && overwriteID) {
      await _notificationsPlugin.cancel(finalId);
    }

    final modifier = await getNotificationChannelsModifiers();
    final androidDetails = AndroidNotificationDetails(
      'Manual webview ${modifier.channelIdModifier}',
      'Manual webview ${modifier.channelIdModifier}',
      channelDescription: 'Manual notifications from browser',
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: 'notification_icon',
      color: Colors.grey,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'aircraft_seatbelt.aiff',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (Platform.isAndroid) {
      await assessNotificationPermissions();
    }

    await _notificationsPlugin.zonedSchedule(
      finalId,
      title,
      subtitle,
      tz.TZDateTime.from(notificationTimestamp, tz.local),
      details,
      payload: finalPayload,
      androidScheduleMode: exactAlarmsPermissionAndroid
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    if (launchNativeToast) {
      String message = toastMessage;
      if (message.isEmpty) {
        message = "Notification scheduled for ${notificationTimestamp.toLocal()}";
      }
      BotToast.showText(
        clickClose: true,
        text: message,
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: toastColor.toLowerCase() == "red"
            ? Colors.red
            : toastColor.toLowerCase() == "green"
                ? Colors.green
                : Colors.blue,
        duration: Duration(seconds: toastDurationSeconds),
        contentPadding: const EdgeInsets.all(10),
      );
    }

    return 'Notification scheduled successfully with ID $id';
  }

  /// Set an alarm (Android via intent, iOS via AlarmKit)
  ///
  /// iOS only: [logicalId] to dedupe/cancel AlarmKit alarms
  static Future<String> setWebviewAlarm({
    required int timestampMillis,
    bool vibrate = true,
    bool sound = true,
    String message = 'TORN PDA Alarm',
    String? logicalId,
  }) async {
    final alarmTime = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final effectiveMessage = (Platform.isIOS && message == 'TORN PDA Alarm') ? 'Alarm' : message;

    if (Platform.isIOS) {
      final available = await AlarmKitServiceIos.isAvailable();
      if (!available) {
        return 'Error: Alarms are not available on this iOS device';
      }

      final id = logicalId ?? 'webview_alarm_$timestampMillis';
      await AlarmKitServiceIos.setAlarmWithMetadata(
        targetTime: alarmTime,
        label: effectiveMessage,
        id: id,
        context: 'Webview alarm',
        details: 'Triggers at ${alarmTime.toLocal()}',
        payload: 'webview:alarm',
        timeMillis: timestampMillis,
      );
      return 'Alarm set successfully for $alarmTime';
    }

    if (!Platform.isAndroid) {
      return 'Error: Alarms are only available on Android or iOS';
    }

    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': alarmTime.hour,
        'android.intent.extra.alarm.MINUTES': alarmTime.minute,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.VIBRATE': vibrate,
        'android.intent.extra.alarm.RINGTONE': sound ? '' : 'silent',
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );

    await intent.launch();
    return 'Alarm set successfully for $alarmTime';
  }

  /// Set an Android Timer via Intent
  static Future<String> setAndroidTimer({
    required int seconds,
    String message = 'TORN PDA Timer',
  }) async {
    if (!Platform.isAndroid) {
      return 'Error: Timers are only available on Android';
    }

    final intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: {
        'android.intent.extra.alarm.LENGTH': seconds,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );

    await intent.launch();
    return 'Timer set successfully for $seconds seconds';
  }
}
