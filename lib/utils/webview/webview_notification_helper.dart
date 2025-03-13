import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/main.dart';
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
    required Function assessNotificationPermissions,
  }) async {
    final int finalId = int.parse('$webviewNotificationIdPrefix$id');
    final notificationTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

    // Check existing notifications
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

    // Schedule notification
    await _notificationsPlugin.zonedSchedule(
      finalId,
      title,
      subtitle,
      tz.TZDateTime.from(notificationTimestamp, tz.local),
      details,
      payload: timestampMillis.toString(),
      androidScheduleMode: exactAlarmsPermissionAndroid
          ? AndroidScheduleMode.exactAllowWhileIdle // Deliver at exact time (needs permission)
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

  /// Set an Android Alarm via Intent
  static Future<String> setAndroidAlarm({
    required int id,
    required int timestampMillis,
    bool vibrate = true,
    String ringtone = '',
    String message = 'TORN PDA Alarm',
  }) async {
    if (!Platform.isAndroid) {
      return 'Error: Alarms are only available on Android';
    }

    final alarmTime = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': alarmTime.hour,
        'android.intent.extra.alarm.MINUTES': alarmTime.minute,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.VIBRATE': vibrate,
        'android.intent.extra.alarm.RINGTONE': ringtone.isEmpty ? 'silent' : ringtone,
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
