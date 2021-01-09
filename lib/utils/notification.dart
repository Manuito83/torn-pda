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

  if (Platform.isAndroid) {
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
        notId,
        payload["notification"]["title"],
        payload["notification"]["body"],
        platformChannelSpecifics,
        // Set payload to be handled by local notifications
        payload: onTapPayload,
      );
    } catch (e) {
      // Probably not in use anymore as of 2021
      await flutterLocalNotificationsPlugin.show(
        notId,
        payload["aps"]["alert"]["title"],
        payload["aps"]["alert"]["body"],
        platformChannelSpecifics,
        // Set payload to be handled by local notifications
        payload: onTapPayload,
      );
    }
  }
}

Future configureNotificationChannels() async {
  List<AndroidNotificationChannel> channels = [];

  channels.add(
    AndroidNotificationChannel(
      'Alerts travel',
      'Alerts travel',
      'Automatic alerts for travel',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual travel',
      'Manual travel',
      'Manual notifications for travel',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts energy',
      'Alerts energy',
      'Automatic alerts for energy',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual energy',
      'Manual energy',
      'Manual notifications for energy',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts nerve',
      'Alerts nerve',
      'Automatic alerts for nerve',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual nerve',
      'Manual nerve',
      'Manual notifications for nerve',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts hospital',
      'Alerts hospital',
      'Automatic alerts for hospital',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts drugs',
      'Alerts drugs',
      'Automatic alerts for drugs',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual drugs',
      'Manual drugs',
      'Manual notifications for drugs',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts racing',
      'Alerts racing',
      'Automatic alerts for racing',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts messages',
      'Alerts messages',
      'Automatic alerts for messages',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts events',
      'Alerts events',
      'Automatic alerts for events',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual loot',
      'Manual loot',
      'Manual notifications for loot',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual life',
      'Manual life',
      'Manual notifications for life',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual medical',
      'Manual medical',
      'Manual notifications for medical',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual booster',
      'Manual booster',
      'Manual notifications for booster',
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts stale user',
      'Alerts stale user',
      'Automatic alerts for inactivity',
    ),
  );

  for (var channel in channels) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
