import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torn_pda/main.dart';

Future showNotification(Map payload) async {
  showNotificationBoth(payload);
}

Future showNotificationBoth(Map payload) async {
  var vibrationPattern = Int64List(8);
  vibrationPattern[0] = 0;
  vibrationPattern[1] = 400;
  vibrationPattern[2] = 400;
  vibrationPattern[3] = 600;
  vibrationPattern[4] = 400;
  vibrationPattern[5] = 800;
  vibrationPattern[6] = 400;
  vibrationPattern[7] = 1000;

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    "Automatic alerts",
    "Alerts Full",
    "Automatic alerts chosen by the user",
    importance: Importance.Max,
    priority: Priority.High,
    visibility: NotificationVisibility.Public,
    autoCancel: true,
    channelShowBadge: true,
    icon: 'notification_icon',
    sound: RawResourceAndroidNotificationSound('slow_spring_board'),
    vibrationPattern: vibrationPattern,
    enableLights: true,
    ledColor: const Color.fromARGB(255, 255, 0, 0),
    ledOnMs: 1000,
    ledOffMs: 500,
    ticker: payload["notification"]["title"],
  );

  var iOSPlatformChannelSpecifics = IOSNotificationDetails(
    sound: 'slow_spring_board.aiff',
  );

  var platformChannelSpecifics = NotificationDetails(
      androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    999,
    payload["notification"]["title"],
    payload["notification"]["body"],
    platformChannelSpecifics,
  );
}
