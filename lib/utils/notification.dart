import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torn_pda/main.dart';

Future showNotification(Map payload) async {
  if (Platform.isIOS)
    showNotificationOnIos(payload);
  else if (Platform.isAndroid) showNotificationOnAndroid(payload);
}

Future showNotificationOnAndroid(Map payload) async {
  var bigPictureAndroidStyle;

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    "Alerts",
    "Alerts",
    "Alerts",
    importance: Importance.Max,
    priority: Priority.High,
    visibility: NotificationVisibility.Public,
    autoCancel: true,
    channelShowBadge: true,
    styleInformation: bigPictureAndroidStyle,
    setAsGroupSummary: true,
    ticker: payload["notification"]["title"],
  );

  var platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics,
    null,
  );

  await flutterLocalNotificationsPlugin.show(
    Random().nextInt(5000),
    payload["notification"]["title"],
    payload["notification"]["body"],
    platformChannelSpecifics,
  );
}

Future showNotificationOnIos(Map payload) async {
  var platformChannelSpecifics = NotificationDetails(
    null,
    IOSNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.show(
    Random().nextInt(5000),
    payload["aps"]["alert"]["title"],
    payload["aps"]["alert"]["body"],
    platformChannelSpecifics,
  );
}
