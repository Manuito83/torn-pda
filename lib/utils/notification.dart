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

  String channel = '';
  String messageId = '';
  String tradeId = '';
  if (Platform.isAndroid) {
    channel = payload["data"]["channelId"];
    messageId = payload["data"]["tornMessageId"];
    tradeId = payload["data"]["tornTradeId"];
  } else {
    channel = payload["channelId"];
    messageId = payload["tornMessageId"];
    tradeId = payload["tornTradeId"];
  }

  String notificationIcon = "notification_icon";
  Color notificationColor = Colors.grey;

  if (channel.contains("Alerts energy")) {
    notificationIcon = "notification_energy";
    notificationColor = Colors.green;
    onTapPayload += 'energy';
    channelId = 'Alerts energy';
    channelName = 'Alerts energy';
    channelDescription = 'Automatic alerts for energy';
  } else if (channel.contains("Alerts nerve")) {
    notificationIcon = "notification_nerve";
    notificationColor = Colors.red;
    onTapPayload += 'nerve';
    channelId = 'Alerts nerve';
    channelName = 'Alerts nerve';
    channelDescription = 'Automatic alerts for nerve';
  } else if (channel.contains("Alerts travel")) {
    notificationIcon = "notification_travel";
    notificationColor = Colors.blue;
    onTapPayload += 'travel';
    channelId = 'Alerts travel';
    channelName = 'Alerts travel';
    channelDescription = 'Automatic alerts for travel';
  } else if (channel.contains("Alerts hospital")) {
    notificationIcon = "notification_hospital";
    notificationColor = Colors.orange[400];
    channelId = 'Alerts hospital';
    channelName = 'Alerts hospital';
    channelDescription = 'Automatic alerts for hospital';
  } else if (channel.contains("Alerts drugs")) {
    notificationIcon = "notification_drugs";
    notificationColor = Colors.pink;
    channelId = 'Alerts drugs';
    channelName = 'Alerts drugs';
    channelDescription = 'Automatic alerts for drugs';
  } else if (channel.contains("Alerts racing")) {
    notificationIcon = "notification_racing";
    notificationColor = Colors.orange[800];
    onTapPayload += 'racing';
    channelId = 'Alerts racing';
    channelName = 'Alerts racing';
    channelDescription = 'Automatic alerts for racing';
  } else if (channel.contains("Alerts messages")) {
    notificationIcon = "notification_messages";
    notificationColor = Colors.purple[700];
    // If payload comes from Firebase with a torn message (mail) id
    if (messageId != '') {
      onTapPayload += 'tornMessageId:$messageId}';
    } else {
      onTapPayload += 'tornMessageId:0';
    }
    channelId = 'Alerts messages';
    channelName = 'Alerts messages';
    channelDescription = 'Automatic alerts for messages';
  } else if (channel.contains("Alerts events")) {
    notificationIcon = "notification_events";
    notificationColor = Colors.purple[700];
    onTapPayload += 'events';
    channelId = 'Alerts events';
    channelName = 'Alerts events';
    channelDescription = 'Automatic alerts for events';
  } else if (channel.contains("Alerts trades")) {
    notificationIcon = "notification_trades";
    notificationColor = Colors.green[700];
    // If payload comes from Firebase with a trade id
    if (tradeId != '') {
      onTapPayload += 'tornTradeId:$tradeId';
    } else {
      onTapPayload += 'tornTradeId:0';
    }
    channelId = 'Alerts trades';
    channelName = 'Alerts trades';
    channelDescription = 'Automatic alerts for trades';
  }

  if (Platform.isAndroid) {
    var platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription,
        styleInformation: BigTextStyleInformation(''),
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        channelShowBadge: true,
        sound: RawResourceAndroidNotificationSound('slow_spring_board'),
        icon: notificationIcon,
        color: notificationColor,
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

  var vibrationPattern = Int64List(8);
  vibrationPattern[0] = 0;
  vibrationPattern[1] = 400;
  vibrationPattern[2] = 400;
  vibrationPattern[3] = 600;
  vibrationPattern[4] = 400;
  vibrationPattern[5] = 800;
  vibrationPattern[6] = 400;
  vibrationPattern[7] = 1000;

  channels.add(
    AndroidNotificationChannel(
      'Alerts travel',
      'Alerts travel',
      'Automatic alerts for travel',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual travel',
      'Manual travel',
      'Manual notifications for travel',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts energy',
      'Alerts energy',
      'Automatic alerts for energy',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual energy',
      'Manual energy',
      'Manual notifications for energy',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts nerve',
      'Alerts nerve',
      'Automatic alerts for nerve',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual nerve',
      'Manual nerve',
      'Manual notifications for nerve',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts hospital',
      'Alerts hospital',
      'Automatic alerts for hospital',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts drugs',
      'Alerts drugs',
      'Automatic alerts for drugs',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual drugs',
      'Manual drugs',
      'Manual notifications for drugs',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts racing',
      'Alerts racing',
      'Automatic alerts for racing',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts messages',
      'Alerts messages',
      'Automatic alerts for messages',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts events',
      'Alerts events',
      'Automatic alerts for events',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts trades',
      'Alerts trades',
      'Automatic alerts for trades',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual loot',
      'Manual loot',
      'Manual notifications for loot',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual life',
      'Manual life',
      'Manual notifications for life',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual medical',
      'Manual medical',
      'Manual notifications for medical',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Manual booster',
      'Manual booster',
      'Manual notifications for booster',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  channels.add(
    AndroidNotificationChannel(
      'Alerts stale user',
      'Alerts stale user',
      'Automatic alerts for inactivity',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    ),
  );

  for (var channel in channels) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
