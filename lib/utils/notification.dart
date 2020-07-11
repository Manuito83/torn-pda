import 'dart:io';
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

  if (Platform.isAndroid) {
    var platformChannelSpecifics = NotificationDetails(
        AndroidNotificationDetails(
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
        ),
      null,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      payload["notification"]["title"],
      payload["notification"]["body"],
      platformChannelSpecifics,
    );

  } else if (Platform.isIOS) {
    var platformChannelSpecifics = NotificationDetails(
      null,
      IOSNotificationDetails(
        sound: 'slow_spring_board.aiff',
      ),
    );

    // Two kind of messages might be sent by Firebase, depending
    // on notification and data payload
    try {
      await flutterLocalNotificationsPlugin.show(
        999,
        payload["notification"]["title"],
        payload["notification"]["body"],
        platformChannelSpecifics,
      );
    } catch (e) {
      await flutterLocalNotificationsPlugin.show(
        999,
        payload["aps"]["alert"]["title"],
        payload["aps"]["alert"]["body"],
        platformChannelSpecifics,
      );
    }
  }

}



