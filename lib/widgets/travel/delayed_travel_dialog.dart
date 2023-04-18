// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';

class DelayedTravelDialog extends StatefulWidget {
  final DateTime boardingTime;
  final String country;
  final String stockCodeName;
  final String stockName;
  final int itemId;
  final int countryId;

  DelayedTravelDialog({
    @required this.boardingTime,
    @required this.country,
    @required this.stockCodeName,
    @required this.stockName,
    @required this.itemId,
    @required this.countryId,
  });

  @override
  _DelayedTravelDialogState createState() => _DelayedTravelDialogState();
}

class _DelayedTravelDialogState extends State<DelayedTravelDialog> {
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  bool _notificationActive = false;

  var _delayMinutes = 0;

  bool _alarmSound = true;
  bool _alarmVibration = true;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _restorePreferences();
    _retrievePendingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                top: 45,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              margin: EdgeInsets.only(top: 30),
              decoration: new BoxDecoration(
                color: _themeProvider.secondBackground,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                children: <Widget>[
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Departure notification",
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                          _timeDropdown(),
                        ],
                      ),
                      Text(
                        'Be aware that the restock time calculation might not be exact. You can '
                        'add extra minutes to your notification here',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 5),
                          ActionChip(
                            label: Icon(
                              Icons.chat_bubble_outline,
                              color: _notificationActive ? Colors.green : _themeProvider.mainText,
                            ),
                            onPressed: () {
                              if (_notificationActive) {
                                _cancelNotifications();
                                BotToast.showText(
                                  text: 'Notification cancelled!',
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.orange[700],
                                  duration: Duration(seconds: 5),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              } else {
                                _scheduleNotification();
                                Navigator.of(context).pop();
                                BotToast.showText(
                                  text: 'Boarding call notification set for '
                                      '${_timeFormatter(widget.boardingTime.add(Duration(minutes: _delayMinutes)))}',
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.green[700],
                                  duration: Duration(seconds: 5),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              }
                            },
                          ),
                          SizedBox(width: 5),
                          if (Platform.isAndroid)
                            ActionChip(
                              label: Icon(
                                Icons.notifications_none,
                              ),
                              onPressed: () {
                                _setAlarm();
                                BotToast.showText(
                                  text: 'Boarding call alarm set for '
                                      '${_timeFormatter(widget.boardingTime.add(Duration(minutes: _delayMinutes)))}',
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.green[700],
                                  duration: Duration(seconds: 5),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              },
                            ),
                          SizedBox(width: 5),
                          if (Platform.isAndroid)
                            ActionChip(
                              label: Icon(
                                Icons.timer,
                              ),
                              onPressed: () {
                                _setTimer();
                                BotToast.showText(
                                  text: 'Boarding call timer set for '
                                      '${_timeFormatter(widget.boardingTime.add(Duration(minutes: _delayMinutes)))}',
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.green[700],
                                  duration: Duration(seconds: 5),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              },
                            ),
                          SizedBox(width: 5),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: _themeProvider.secondBackground,
              child: CircleAvatar(
                backgroundColor: _themeProvider.mainText,
                radius: 22,
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: Icon(
                    Icons.settings,
                    color: _themeProvider.secondBackground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DropdownButton _timeDropdown() {
    return DropdownButton<int>(
      value: _delayMinutes,
      items: [
        DropdownMenuItem(
          value: 0,
          child: SizedBox(
            width: 70,
            child: Text(
              "On time",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 5,
          child: SizedBox(
            width: 70,
            child: Text(
              "+5 min",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 10,
          child: SizedBox(
            width: 70,
            child: Text(
              "+10 min",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 20,
          child: SizedBox(
            width: 70,
            child: Text(
              "+20 min",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 30,
          child: SizedBox(
            width: 70,
            child: Text(
              "+30 min",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _delayMinutes = value;
        });
      },
    );
  }

  void _scheduleNotification() async {
    String channelTitle = 'Manual flight departure';
    String channelSubtitle = 'Manual flight departure';
    String channelDescription = 'Manual notifications for delayed flight departure';
    String notificationTitle = "You flight to ${widget.country} is ready for boarding!";
    String notificationSubtitle = "Remember to bring you ${widget.stockName} import papers!";
    int notificationId = int.parse("211${widget.countryId}${widget.itemId}");

    if (_settingsProvider.discreteNotifications) {
      notificationTitle = "Scheduled";
      notificationSubtitle = "Departure";
    }

    var modifier = await getNotificationChannelsModifiers();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      "$channelTitle ${modifier.channelIdModifier}",
      "$channelSubtitle ${modifier.channelIdModifier}",
      channelDescription: channelDescription,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: 'notification_travel',
      color: Colors.grey,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    var iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: true,
      sound: 'aircraft_seatbelt.aiff',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationSubtitle,
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // DEBUG
        tz.TZDateTime.from(widget.boardingTime, tz.local).add(Duration(minutes: _delayMinutes)),
        platformChannelSpecifics,
        payload: '211',
        androidAllowWhileIdle: true, // Deliver at exact time
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future _retrievePendingNotifications() async {
    var pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (var not in pendingNotificationRequests) {
      var id = not.id.toString();
      if (id == "211${widget.countryId}${widget.itemId}") {
        setState(() {
          _notificationActive = true;
        });
      }
    }
  }

  void _cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancel(int.parse("211${widget.countryId}${widget.itemId}"));
    setState(() {
      _notificationActive = false;
    });
  }

  void _setAlarm() {
    String thisSound;
    if (_alarmSound) {
      thisSound = '';
    } else {
      thisSound = 'silent';
    }

    var alarmTime = widget.boardingTime.add(Duration(minutes: _delayMinutes));
    var hour = alarmTime.hour;
    var minute = alarmTime.minute;
    var message = 'Flight Boarding - ${widget.stockName}';

    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.VIBRATE': _alarmVibration,
        'android.intent.extra.alarm.RINGTONE': thisSound,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  void _setTimer() {
    var totalSeconds = widget.boardingTime.difference(DateTime.now()).inSeconds + _delayMinutes * 60;
    var message = 'Flight Boarding - ${widget.stockName}';

    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': totalSeconds,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  String _timeFormatter(DateTime time) {
    return TimeFormatter(
      inputTime: time,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatHour;
  }

  void _restorePreferences() async {
    _alarmSound = await Prefs().getManualAlarmSound();
    _alarmVibration = await Prefs().getManualAlarmVibration();
  }
}
