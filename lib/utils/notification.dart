import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torn_pda/main.dart';

Future showNotification(Map payload, int notId) async {
  showNotificationBoth(payload, notId);
}

Future showNotificationBoth(Map payload, int notId) async {

  var onTapPayload = '';
  var channelId = '';
  var channelName = '';
  var channelDescription = '';

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
      channelId = 'Alerts energy';
      channelName = 'Alerts energy';
      channelDescription = 'Automatic alerts for energy';
    } else if (title.contains("Full Nerve Bar")) {
      notificationIcon = "notification_nerve";
      notificationColor = Colors.red;
      onTapPayload += 'nerve';
      channelId = 'Alerts nerve';
      channelName = 'Alerts nerve';
      channelDescription = 'Automatic alerts for nerve';
    } else if (title.contains("Approaching")) {
      notificationIcon = "notification_travel";
      notificationColor = Colors.blue;
      onTapPayload += 'travel';
      channelId = 'Alerts travel';
      channelName = 'Alerts travel';
      channelDescription = 'Automatic alerts for travel';
    } else if (title.contains("Hospital admission") ||
        title.contains("Hospital time ending") ||
        title.contains("You are out of hospital")) {
      notificationIcon = "notification_hospital";
      notificationColor = Colors.orange[400];
      channelId = 'Alerts hospital';
      channelName = 'Alerts hospital';
      channelDescription = 'Automatic alerts for hospital';
    } else if (title.contains("Drug cooldown expired")) {
      notificationIcon = "notification_drugs";
      notificationColor = Colors.pink;
      channelId = 'Alerts drugs';
      channelName = 'Alerts drugs';
      channelDescription = 'Automatic alerts for drugs';
    } else if (title.contains("Race finished")) {
      notificationIcon = "notification_racing";
      notificationColor = Colors.orange[800];
      onTapPayload += 'racing';
      channelId = 'Alerts racing';
      channelName = 'Alerts racing';
      channelDescription = 'Automatic alerts for racing';
    } else if (title.contains("new message from") ||
        title.contains("new messages from")) {
      notificationIcon = "notification_messages";
      notificationColor = Colors.purple[700];
      // If payload comes from Firebase with a torn message (mail) id
      if (payload["data"]["tornMessageId"] != '') {
        onTapPayload += 'messageId:${payload["data"]["tornMessageId"]}';
      }
      channelId = 'Alerts messages';
      channelName = 'Alerts messages';
      channelDescription = 'Automatic alerts for messages';
    } else if (title.contains("new event!") || title.contains("new events!")) {
      notificationIcon = "notification_events";
      notificationColor = Colors.purple[700];
      onTapPayload += 'events';
      channelId = 'Alerts events';
      channelName = 'Alerts events';
      channelDescription = 'Automatic alerts for events';
    }

    var platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription,
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

    print(notId);
    await flutterLocalNotificationsPlugin.show(
      notId,
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
