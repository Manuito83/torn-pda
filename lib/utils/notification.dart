import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torn_pda/main.dart';

Future showNotification(Map payload) async {
  showNotificationBoth(payload);
}

Future showNotificationBoth(Map payload) async {
  var onTapPayload = '';

  var vibrationPattern = Int64List(8);
  vibrationPattern[0] = 0;
  vibrationPattern[1] = 400;
  vibrationPattern[2] = 400;
  vibrationPattern[3] = 600;
  vibrationPattern[4] = 400;
  vibrationPattern[5] = 800;
  vibrationPattern[6] = 400;
  vibrationPattern[7] = 1000;

  if (Platform.isAndroid) {
    String title = payload["notification"]["title"];
    String notificationIcon = "notification_icon";
    Color notificationColor = Colors.grey;

    if (title.contains("Full Energy Bar")) {
      notificationIcon = "notification_energy";
      notificationColor = Colors.green;
      onTapPayload += 'energy';
    } else if (title.contains("Full Nerve Bar")) {
      notificationIcon = "notification_nerve";
      notificationColor = Colors.red;
      onTapPayload += 'nerve';
    } else if (title.contains("Approaching")) {
      notificationIcon = "notification_travel";
      notificationColor = Colors.blue;
      onTapPayload += 'travel';
    } else if (title.contains("Hospital admission") ||
        title.contains("Hospital time ending") ||
        title.contains("You are out of hospital")) {
      notificationIcon = "notification_hospital";
      notificationColor = Colors.orange[400];
    } else if (title.contains("Drug cooldown expired")) {
      notificationIcon = "notification_drugs";
      notificationColor = Colors.pink;
    } else if (title.contains("Race finished")) {
      notificationIcon = "notification_racing";
      notificationColor = Colors.orange[800];
      onTapPayload += 'racing';
    } else if (title.contains("new message from") ||
        title.contains("new messages from")) {
      notificationIcon = "notification_messages";
      notificationColor = Colors.purple[700];
      // If payload comes from Firebase with a torn message (mail) id
      if (payload["data"]["tornMessageId"] != '') {
        onTapPayload += 'messageId:${payload["data"]["tornMessageId"]}';
      }
    } else if (title.contains("new event!") || title.contains("new events!")) {
      notificationIcon = "notification_events";
      notificationColor = Colors.purple[700];
      onTapPayload += 'events';
    }

    var platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        "Automatic alerts",
        "Alerts Full",
        "Automatic alerts chosen by the user",
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        channelShowBadge: true,
        icon: notificationIcon,
        color: notificationColor,
        sound: RawResourceAndroidNotificationSound('slow_spring_board'),
        vibrationPattern: vibrationPattern,
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        ticker: payload["notification"]["title"],
      ),
      iOS: null,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      payload["notification"]["title"],
      payload["notification"]["body"],
      platformChannelSpecifics,
      // Set payload to be handled by local notifications
      payload: onTapPayload,
    );
  } else if (Platform.isIOS) {
    var platformChannelSpecifics = NotificationDetails(
      android: null,
      iOS: IOSNotificationDetails(
        sound: 'slow_spring_board.aiff',
      ),
    );

    // Two kind of messages might be sent by Firebase
    try {
      await flutterLocalNotificationsPlugin.show(
        999,
        payload["aps"]["alert"]["title"],
        payload["aps"]["alert"]["body"],
        platformChannelSpecifics,
        // Set payload to be handled by local notifications
        payload: onTapPayload,
      );
    } catch (e) {
      await flutterLocalNotificationsPlugin.show(
        999,
        payload["notification"]["title"],
        payload["notification"]["body"],
        platformChannelSpecifics,
        // Set payload to be handled by local notifications
        payload: onTapPayload,
      );
    }
  }
}
