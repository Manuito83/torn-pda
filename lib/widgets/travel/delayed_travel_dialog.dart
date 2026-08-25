// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/alarm_kit_service_ios.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';

class DelayedTravelDialog extends StatefulWidget {
  final DateTime boardingTime;
  final String? country;
  final String stockCodeName;
  final String? stockName;
  final int? itemId;
  final int countryId;

  const DelayedTravelDialog({
    required this.boardingTime,
    required this.country,
    required this.stockCodeName,
    required this.stockName,
    required this.itemId,
    required this.countryId,
  });

  @override
  DelayedTravelDialogState createState() => DelayedTravelDialogState();
}

class DelayedTravelDialogState extends State<DelayedTravelDialog> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;

  bool _notificationActive = false;
  bool _alarmKitActive = false;
  bool _inAppAlarmActive = false;

  int? _delayMinutes = 0;

  bool _alarmSound = true;
  bool _alarmVibration = true;

  String get _alarmKitId => 'delayed_travel_${widget.countryId}_${widget.itemId}';

  int get _notificationId => int.parse("211${widget.countryId}${widget.itemId}");

  int get _inAppAlarmId => int.parse("212${widget.countryId}${widget.itemId}");

  DateTime get _targetTime => widget.boardingTime.add(Duration(minutes: _delayMinutes!));

  // SET_ALARM carries no date (fires at the next matching hour) and SET_TIMER is capped at 86400 seconds
  bool get _systemClockSupportsTarget => _targetTime.difference(DateTime.now()).inSeconds < 86400;

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
              padding: const EdgeInsets.only(top: 45, bottom: 16, left: 16, right: 16),
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                color: _themeProvider.secondBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10.0, offset: Offset(0.0, 10.0))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                children: <Widget>[
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Departure notification", style: TextStyle(fontSize: 13)),
                          _timeDropdown(),
                        ],
                      ),
                      Text(
                        'Be aware that the restock time calculation might not be exact. You can '
                        'shift your notification earlier or later here',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                      if (Platform.isAndroid && !_systemClockSupportsTarget)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Android's clock cannot schedule more than 24 hours ahead, so this alarm will be "
                            "activated by Torn PDA instead and the system timer is not available",
                            style: TextStyle(color: Colors.orange[700], fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 5),
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
                                  textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                  contentColor: Colors.orange[700]!,
                                  duration: const Duration(seconds: 5),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                              } else {
                                _scheduleNotification();
                                Navigator.of(context).pop();
                                BotToast.showText(
                                  text: 'Boarding call notification set for ${_timeFormatter(_targetTime)}',
                                  textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                  contentColor: Colors.green[700]!,
                                  duration: const Duration(seconds: 5),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 5),
                          if (Platform.isIOS)
                            ActionChip(
                              label: Icon(
                                Icons.notifications_none,
                                color: _alarmKitActive ? Colors.green : _themeProvider.mainText,
                              ),
                              onPressed: () async {
                                if (_alarmKitActive) {
                                  await _cancelAlarmIOS();
                                  BotToast.showText(
                                    text: 'Boarding call alarm cancelled!',
                                    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                    contentColor: Colors.orange[700]!,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                } else {
                                  await _scheduleAlarmIOS();
                                  BotToast.showText(
                                    text: 'Boarding call alarm set for ${_timeFormatter(_targetTime)}',
                                    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                    contentColor: Colors.green[700]!,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                }
                              },
                            ),
                          if (Platform.isIOS) const SizedBox(width: 5),
                          if (Platform.isAndroid)
                            ActionChip(
                              label: Icon(Icons.notifications_none, color: _inAppAlarmActive ? Colors.green : null),
                              onPressed: () async {
                                if (_systemClockSupportsTarget) {
                                  // The delay dropdown can move the target back under 24h after scheduling
                                  if (_inAppAlarmActive) await _cancelInAppAlarm();
                                  _setAlarm();
                                  BotToast.showText(
                                    text: 'Boarding call alarm set for ${_timeFormatter(_targetTime)}',
                                    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                    contentColor: Colors.green[700]!,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                  return;
                                }

                                if (_inAppAlarmActive) {
                                  await _cancelInAppAlarm();
                                  BotToast.showText(
                                    text: 'Boarding call alarm cancelled!',
                                    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                    contentColor: Colors.orange[700]!,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                  return;
                                }

                                await _scheduleInAppAlarm();
                                BotToast.showText(
                                  text:
                                      'Boarding call alarm set for ${_timeFormatter(_targetTime)}, '
                                      'it will be activated by Torn PDA',
                                  textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                  contentColor: Colors.green[700]!,
                                  duration: const Duration(seconds: 5),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                              },
                            ),
                          const SizedBox(width: 5),
                          if (Platform.isAndroid)
                            ActionChip(
                              label: Icon(Icons.timer, color: _systemClockSupportsTarget ? null : Colors.grey),
                              onPressed: () {
                                if (!_systemClockSupportsTarget) {
                                  _showSystemClockLimitToast();
                                  return;
                                }
                                _setTimer();
                                BotToast.showText(
                                  text: 'Boarding call timer set for ${_timeFormatter(_targetTime)}',
                                  textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                  contentColor: Colors.green[700]!,
                                  duration: const Duration(seconds: 5),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                              },
                            ),
                          const SizedBox(width: 5),
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
                          child: const Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
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
                  child: Icon(Icons.settings, color: _themeProvider.secondBackground),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Anticipate or delay the notification
  // Options resulting in a time less than 5 minutes ahead are filtered out
  static const List<int> _allDelayOptions = [-30, -20, -10, -5, 0, 5, 10, 20, 30];

  String _delayLabel(int value) {
    if (value == 0) return "On time";
    return value > 0 ? "+$value min" : "$value min";
  }

  List<int> _validDelayOptions() {
    final cutoff = DateTime.now().add(const Duration(minutes: 5));
    final valid = _allDelayOptions.where((v) => widget.boardingTime.add(Duration(minutes: v)).isAfter(cutoff)).toList();
    // Fallback to the largest delay if everything is too close
    return valid.isEmpty ? [_allDelayOptions.last] : valid;
  }

  DropdownButton _timeDropdown() {
    final validValues = _validDelayOptions();
    if (!validValues.contains(_delayMinutes)) {
      _delayMinutes = validValues.first;
    }
    return DropdownButton<int>(
      value: _delayMinutes,
      items: validValues
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: SizedBox(
                width: 70,
                child: Text(_delayLabel(v), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14)),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _delayMinutes = value;
        });
      },
    );
  }

  Future<void> _scheduleNotification() async {
    const String channelTitle = 'Manual flight departure';
    const String channelSubtitle = 'Manual flight departure';
    const String channelDescription = 'Manual notifications for delayed flight departure';
    String notificationTitle = "Your flight to ${widget.country} is ready for boarding!";
    String notificationSubtitle = "Remember to bring your ${widget.stockName} import papers!";
    final int notificationId = _notificationId;

    if (_settingsProvider.discreetNotifications) {
      notificationTitle = "Scheduled";
      notificationSubtitle = "Departure";
    }

    final modifier = await getNotificationChannelsModifiers();
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      "$channelTitle ${modifier.channelIdModifier}",
      "$channelSubtitle ${modifier.channelIdModifier}",
      channelDescription: channelDescription,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      icon: 'notification_travel',
      color: Colors.grey,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(presentSound: true, sound: 'aircraft_seatbelt.aiff');

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    if (Platform.isAndroid) {
      await assessExactAlarmsPermissionsAndroid(context, _settingsProvider);
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      notificationTitle,
      notificationSubtitle,
      //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // DEBUG
      tz.TZDateTime.from(_targetTime, tz.local),
      platformChannelSpecifics,
      payload: '211',
      androidScheduleMode: exactAlarmsPermissionAndroid
          ? AndroidScheduleMode
                .exactAllowWhileIdle // Deliver at exact time (needs permission)
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Used when the target is beyond what the system clock can hold
  Future<void> _scheduleInAppAlarm() async {
    String notificationTitle = "Your flight to ${widget.country} is ready for boarding!";
    String notificationSubtitle = "Remember to bring your ${widget.stockName} import papers!";

    if (_settingsProvider.discreetNotifications) {
      notificationTitle = "Scheduled";
      notificationSubtitle = "Departure";
    }

    await assessExactAlarmsPermissionsAndroid(context, _settingsProvider);

    await scheduleAlarmGradeNotificationAndroid(
      notificationId: _inAppAlarmId,
      channelName: 'Manual flight departure alarm',
      channelDescription: 'Manual alarms for delayed flight departure',
      title: notificationTitle,
      body: notificationSubtitle,
      targetTime: _targetTime,
      payload: '211',
      sound: 'aircraft_seatbelt',
      playSound: _alarmSound,
      vibrate: _alarmVibration,
      icon: 'notification_travel',
    );

    setState(() {
      _inAppAlarmActive = true;
    });
  }

  Future<void> _cancelInAppAlarm() async {
    await flutterLocalNotificationsPlugin.cancel(_inAppAlarmId);
    setState(() {
      _inAppAlarmActive = false;
    });
  }

  Future<void> _scheduleAlarmIOS() async {
    if (!Platform.isIOS) return;
    final available = await AlarmKitServiceIos.isAvailable();
    if (!available) {
      BotToast.showText(
        text: 'Alarms are not available on this iOS device!',
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange[700]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
      return;
    }

    final targetTime = _targetTime;

    await AlarmKitServiceIos.setAlarmWithMetadata(
      targetTime: targetTime,
      label: _settingsProvider.discreetNotifications ? 'Fl' : widget.stockName,
      id: _alarmKitId,
      context: 'Boarding alarm',
      details: '${widget.country}: ${widget.stockName}',
      // Use same payload as notification taps so Drawer handler matches
      payload: '211',
      timeMillis: targetTime.millisecondsSinceEpoch,
    );
    await _refreshAlarmKitState();
  }

  Future _retrievePendingNotifications() async {
    final pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (final not in pendingNotificationRequests) {
      if (not.id == _notificationId) {
        setState(() {
          _notificationActive = true;
        });
      } else if (not.id == _inAppAlarmId) {
        setState(() {
          _inAppAlarmActive = true;
        });
      }
    }

    await _refreshAlarmKitState();
  }

  Future<void> _cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancel(_notificationId);
    setState(() {
      _notificationActive = false;
    });
  }

  Future<void> _refreshAlarmKitState() async {
    if (!Platform.isIOS) return;
    final available = await AlarmKitServiceIos.isAvailable();
    if (!available) return;
    final active = (await AlarmKitServiceIos.listLogicalIds()).contains(_alarmKitId);
    if (mounted) {
      setState(() {
        _alarmKitActive = active;
      });
    }
  }

  Future<void> _cancelAlarmIOS() async {
    if (!Platform.isIOS) return;
    await AlarmKitServiceIos.cancelAlarm(_alarmKitId);
    await _refreshAlarmKitState();
  }

  void _setAlarm() {
    String thisSound;
    if (_alarmSound) {
      thisSound = '';
    } else {
      thisSound = 'silent';
    }

    final alarmTime = _targetTime;
    final hour = alarmTime.hour;
    final minute = alarmTime.minute;
    final message = _settingsProvider.discreetNotifications ? "Fl" : 'Flight Boarding - ${widget.stockName}';

    final AndroidIntent intent = AndroidIntent(
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
    final totalSeconds = _targetTime.difference(DateTime.now()).inSeconds;
    final message = _settingsProvider.discreetNotifications ? "Fl" : 'Flight Boarding - ${widget.stockName}';

    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': totalSeconds,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  void _showSystemClockLimitToast() {
    BotToast.showText(
      text: "Android's timer cannot be set for more than 24 hours, use the alarm or the notification instead!",
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.orange[700]!,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  String? _timeFormatter(DateTime time) {
    return TimeFormatter(
      inputTime: time,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatHour;
  }

  Future<void> _restorePreferences() async {
    _alarmSound = await Prefs().getManualAlarmSound();
    _alarmVibration = await Prefs().getManualAlarmVibration();
  }
}
