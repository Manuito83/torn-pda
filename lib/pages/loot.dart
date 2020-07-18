import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent/android_intent.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/loot/loot_model.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/webview_generic.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'loot/loot_notification_android.dart';

enum LootTimeType {
  dateTime,
  timer,
}

class LootPage extends StatefulWidget {
  @override
  _LootPageState createState() => _LootPageState();
}

class _LootPageState extends State<LootPage> {
  final _npcIds = [4, 15, 19];

  Map<String, LootModel> _lootMap;
  Future _getLootInfoFromYata;
  bool _apiSuccess = false;

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ThemeProvider _themeProvider;

  bool _firstLoad = true;
  int _tornTicks = 0;
  int _yataTicks = 0;
  Timer _tickerUpdateTimes;

  LootTimeType _lootTimeType;
  NotificationType _lootNotificationType;
  bool _alarmSound;
  bool _alarmVibration;

  // Payload is: 400idlevel
  var _activeNotificationsIds = List<int>();

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);

    _getLootInfoFromYata = _updateTimes();

    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'loot'});

    _tickerUpdateTimes =
        new Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTimes());
  }

  @override
  void dispose() {
    _tickerUpdateTimes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: Text('Loot'),
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          onPressed: () {
            final ScaffoldState scaffoldState =
                context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
        actions: <Widget>[
          _apiSuccess
              ? IconButton(
                  icon: Icon(
                    MdiIcons.timerSandEmpty,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_lootTimeType == LootTimeType.timer) {
                        _lootTimeType = LootTimeType.dateTime;
                        SharedPreferencesModel().setLootTimerType('dateTime');
                      } else {
                        _lootTimeType = LootTimeType.timer;
                        SharedPreferencesModel().setLootTimerType('timer');
                      }
                    });
                  },
                )
              : SizedBox.shrink(),
          _apiSuccess && Platform.isAndroid
              ? IconButton(
                  icon: Icon(
                    Icons.alarm_on,
                    color: _themeProvider.buttonText,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return LootNotificationsAndroid(
                            callback: _callBackFromNotificationOptions,
                          );
                        },
                      ),
                    );
                  },
                )
              : SizedBox.shrink()
        ],
      ),
      body: FutureBuilder(
          future: _getLootInfoFromYata,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiSuccess) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: _returnNpcCards(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15, top: 5),
                        child: Text(
                          Platform.isAndroid
                              ? 'Notifications and timers are activated with 20 '
                              'seconds to spare. Alarms are rounded to the minute.'
                              : 'Notifications are activated with 20 seconds to spare.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15, top: 5),
                        child: Text(
                          'Loot times calculation thanks to YATA.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              } else {
                return _connectError();
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Widget _connectError() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'There was an error contacting with Yata!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Please try again later.',
          ),
          SizedBox(height: 20),
          Text('If this problem reoccurs, please let us know!'),
        ],
      ),
    );
  }

  Widget _returnNpcCards() {
    // Final card of every NPC
    var npcBoxes = List<Widget>();

    // Loop every NPC
    var npcModels = List<LootModel>();

    _lootMap.forEach((npcId, npcDetails) {
      // Get npcLevels in a column and format them
      int thisIndex = 1;
      var npcLevels = List<Widget>();
      var npcLevelsColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: npcLevels,
      );

      npcDetails.timings.forEach((levelNumber, levelDetails) {
        // Time formatting
        var levelDateTime =
            DateTime.fromMillisecondsSinceEpoch(levelDetails.ts * 1000);
        var time = TimeFormatter(
          inputTime: levelDateTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;

        // Text string styling
        bool isPast = false;
        if (DateTime.now().isAfter(levelDateTime)) {
          isPast = true;
        }
        bool isCurrent = false;
        if (levelNumber == npcDetails.levels.current.toString()) {
          isCurrent = true;
        }

        String timeString = "Level $thisIndex";
        var style = TextStyle();
        if (isPast && !isCurrent) {
          timeString += " at $time";
          style = TextStyle(color: Colors.grey);
        } else if (isCurrent) {
          timeString += " (now)";
          style = TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          );
        } else {
          var timeDiff = levelDateTime.difference(DateTime.now());
          var diffFormatted = _formatDuration(timeDiff);
          if (_lootTimeType == LootTimeType.timer) {
            timeString += " in $diffFormatted";
          } else {
            timeString += " at $time";
          }
          if (timeDiff.inMinutes < 10) {
            if (npcDetails.levels.next >= 4) {
              style = TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              );
            } else {
              style = TextStyle(
                fontWeight: FontWeight.bold,
              );
            }
          }
        }

        String typeString;
        IconData iconData;
        switch (_lootNotificationType) {
          case NotificationType.notification:
            typeString = 'notification';
            iconData = Icons.chat_bubble_outline;
            break;
          case NotificationType.alarm:
            typeString = 'alarm';
            iconData = Icons.notifications_none;
            break;
          case NotificationType.timer:
            typeString = 'timer';
            iconData = Icons.timer;
            break;
        }

        Widget notificationIcon;
        if (!isPast && !isCurrent) {
          bool isPending = false;
          for (var id in _activeNotificationsIds) {
            if (id == int.parse('400$npcId$levelNumber')) {
              isPending = true;
            }
          }
          notificationIcon = InkWell(
            splashColor: Colors.transparent,
            child: Icon(
              iconData,
              size: 20,
              color: _lootNotificationType == NotificationType.notification &&
                      isPending
                  ? Colors.green
                  : null,
            ),
            onTap: () async {
              switch (_lootNotificationType) {
                case NotificationType.notification:
                  if (isPending) {
                    setState(() {
                      isPending = false;
                    });
                    await flutterLocalNotificationsPlugin
                        .cancel(int.parse('400$npcId$levelNumber'));
                    _activeNotificationsIds.removeWhere((element) =>
                        element == int.parse('400$npcId$levelNumber'));
                  } else {
                    setState(() {
                      isPending = true;
                    });
                    _activeNotificationsIds
                        .add(int.parse('400$npcId$levelNumber'));
                    _scheduleNotification(
                      levelDateTime,
                      int.parse('400$npcId$levelNumber'),
                      '400-$npcId',
                      "${npcDetails.name} loot",
                      "Level $levelNumber in 20 seconds!",
                    );
                    BotToast.showText(
                      text: 'Loot level $levelNumber'
                          ' $typeString set for ${npcDetails.name}!',
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: Colors.green[700],
                      duration: Duration(seconds: 5),
                      contentPadding: EdgeInsets.all(10),
                    );
                  }
                  break;
                case NotificationType.alarm:
                  _setAlarm(
                    levelDateTime,
                    "${npcDetails.name} level $levelNumber",
                  );
                  BotToast.showText(
                    text: 'Loot level $levelNumber'
                        ' $typeString set for ${npcDetails.name}!',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green[700],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                  break;
                case NotificationType.timer:
                  _setTimer(
                    levelDateTime,
                    "${npcDetails.name} level $levelNumber",
                  );
                  BotToast.showText(
                    text: 'Loot level $levelNumber'
                        ' $typeString set for ${npcDetails.name}!',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green[700],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                  break;
              }
            },
          );
        } else {
          notificationIcon = SizedBox.shrink();
        }

        var timeRow = Row(
          children: [
            SizedBox(
              width: 165,
              child: Text(
                timeString,
                style: style,
              ),
            ),
            SizedBox(width: 15),
            notificationIcon,
          ],
        );

        npcLevels.add(timeRow);
        npcLevels.add(SizedBox(height: 8));
        thisIndex++;
      });

      Widget hospitalized;
      if (npcDetails.status == "hospitalized") {
        hospitalized = Text(
          '[HOSPITALIZED]',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        hospitalized = SizedBox.shrink();
      }

      Widget npcImage;
      var shadow = List<BoxShadow>();
      if (npcDetails.levels.current >= 4) {
        shadow = [
          BoxShadow(
            color: Colors.red,
            blurRadius: 8.0,
            spreadRadius: 2.0,
          )
        ];
      } else {
        shadow = null;
      }
      if (npcId == '4' || npcId == '15' || npcId == '19') {
        npcImage = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey[900], width: 2),
            boxShadow: shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image(
              image: AssetImage('images/npcs/npc_$npcId.png'),
              height: 60,
            ),
          ),
        );
      } else {
        npcImage = Icon(Icons.person);
      }

      Widget knifeIcon;
      knifeIcon = IconButton(
        icon: Icon(
          MdiIcons.knifeMilitary,
          color: npcDetails.levels.current >= 4
              ? Colors.red
              : _themeProvider.mainText,
        ),
        onPressed: () async {
          var browserType = _settingsProvider.currentBrowser;
          switch (browserType) {
            case BrowserSetting.app:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => TornWebViewGeneric(
                    customUrl:
                        'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId',
                    genericTitle: npcDetails.name,
                    webViewType: WebViewType.custom,
                  ),
                ),
              );
              break;
            case BrowserSetting.external:
              var url =
                  'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
              if (await canLaunch(url)) {
                await launch(url, forceSafariVC: false);
              }
              break;
          }
        },
      );

      Color cardBorderColor() {
        if (npcDetails.levels.current >= 4) {
          return Colors.orange;
        } else {
          return Colors.transparent;
        }
      }

      npcBoxes.add(
        Card(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: cardBorderColor(), width: 1.5),
              borderRadius: BorderRadius.circular(4.0)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    npcImage,
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: knifeIcon,
                    ),
                  ],
                ),
                SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              '${npcDetails.name}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            hospitalized,
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      npcLevelsColumn,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      npcModels.add(npcDetails);
    });

    Widget npcWidget = Column(children: npcBoxes);
    return npcWidget;
  }

  Future _updateTimes() async {
    var tsNow = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    // On start, get both API and compare if Torn has more up to date info
    if (_firstLoad) {
      _firstLoad = false;
      await _loadPreferences();
      await _retrievePendingNotifications();
      // Fill in YATA information
      await _fetchYataApi();
      // Get Torn API so that we can compare
      await _fetchCompareTornApi(tsNow);
    }
    // If it's not the first execution, fetch YATA every 5 minutes and Torn
    // every 30 seconds
    else {
      _yataTicks++;
      _tornTicks++;

      if (_yataTicks >= 300) {
        await _fetchYataApi();
        _yataTicks = 0;
      }
      if (_tornTicks > 30) {
        await _cancelPassedNotifications();
        await _fetchCompareTornApi(tsNow);
        _tornTicks = 0;
      }
    }

    // We need to ensure that we keep all times updated
    if (mounted) {
      setState(() {
        for (var npc in _lootMap.values) {
          // Update main timing values comparing stored TS with current time
          var timingsList = List<Timing>();
          npc.timings.forEach((key, value) {
            value.due = value.ts - tsNow;
            timingsList.add(Timing(
              due: value.due,
              ts: value.ts,
              pro: value.pro,
            ));
          });
          // Make sure to advance levels if the times comes in between updates
          if (timingsList[0].due > 0) {
            npc.levels.current = 0;
            npc.levels.next = 1;
          } else if (timingsList[4].due < 0) {
            npc.levels.current = 5;
            npc.levels.next = 5;
          } else {
            for (var i = 0; i < 4; i++) {
              if (timingsList[i].due < 0 && timingsList[i + 1].due > 0) {
                npc.levels.current = i + 1;
                npc.levels.next = i + 2;
              }
            }
          }
        }
      });
    }
  }

  Future _fetchYataApi() async {
    try {
      // Database API
      String url = 'https://yata.alwaysdata.net/loot/timings/';
      final response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        _lootMap = lootModelFromJson(response.body);
        _lootMap.length >= 1 ? _apiSuccess = true : _apiSuccess = false;
      } else {
        _apiSuccess = false;
      }
    } catch (e) {
      _apiSuccess = false;
    }
  }

  Future _fetchCompareTornApi(int tsNow) async {
    // Get Torn API so that we can compare
    for (var id in _npcIds) {
      var tornTarget = await TornApiCaller.target(
        _userProvider.myUser.userApiKey,
        id.toString(),
      ).getTarget;
      // If the tornTarget is in hospital as per Torn, we might need to
      // correct times that come from YATA
      if (tornTarget is TargetModel) {
        _lootMap.forEach((key, value) {
          // Look for our tornTarget
          if (key == id.toString()) {
            if (tornTarget.status.state == 'Hospital') {
              // If Torn gives a more up to date hospital out value
              if (tornTarget.status.until - 60 > value.hospout) {
                value.hospout = tornTarget.status.until;
                value.levels.current = 0;
                value.levels.next = 1;
                value.status = "hospitalized";
                value.update = tsNow;
                // Generate updated timings
                var newTimingMap = Map<String, Timing>();
                var lootDelays = [0, 30 * 60, 90 * 60, 210 * 60, 450 * 60];
                for (var i = 0; i < lootDelays.length; i++) {
                  var thisLevel = Timing(
                    due: value.hospout + lootDelays[i] - tsNow,
                    ts: value.hospout + lootDelays[i],
                    pro: 0,
                  );
                  newTimingMap.addAll({(i + 1).toString(): thisLevel});
                }
                value.timings = newTimingMap;
              }
            } else {
              value.status = "loot";
            }
          }
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future _loadPreferences() async {
    var lootTimeType = await SharedPreferencesModel().getLootTimerType();
    lootTimeType == 'timer'
        ? _lootTimeType = LootTimeType.timer
        : _lootTimeType = LootTimeType.dateTime;

    var notification = await SharedPreferencesModel().getLootNotificationType();
    _alarmSound = await SharedPreferencesModel().getLootAlarmSound();
    _alarmVibration = await SharedPreferencesModel().getLootAlarmVibration();
    setState(() {
      if (notification == '0') {
        _lootNotificationType = NotificationType.notification;
      } else if (notification == '1') {
        _lootNotificationType = NotificationType.alarm;
      } else if (notification == '2') {
        _lootNotificationType = NotificationType.timer;
      }
    });
  }

  void _scheduleNotification(
    DateTime notificationTime,
    int id,
    String payload,
    String title,
    String subtitle,
  ) async {
    String channelTitle = 'Loot';
    String channelSubtitle = 'NPC Loot';
    String channelDescription = 'Notifications about NPC loot';
    String notificationTitle = title;
    String notificationSubtitle = subtitle;
    int notificationId = id;
    String notificationPayload = payload;

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
      channelTitle,
      channelSubtitle,
      channelDescription,
      importance: Importance.Max,
      priority: Priority.High,
      visibility: NotificationVisibility.Public,
      icon: 'notification_icon',
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      //color: const Color.fromARGB(255, 255, 0, 0),
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
      sound: 'slow_spring_board.aiff',
    );

    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      notificationId,
      notificationTitle,
      notificationSubtitle,
      //DateTime.now().add(Duration(seconds: 10)), // DEBUG 10 SECONDS
      notificationTime.subtract(Duration(seconds: 20)),
      platformChannelSpecifics,
      payload: notificationPayload,
      androidAllowWhileIdle: true, // Deliver at exact time
    );
  }

  Future _retrievePendingNotifications() async {
    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (var not in pendingNotificationRequests) {
      var id = not.id.toString();
      if (id.length > 3 && id.substring(0, 3) == '400') {
        _activeNotificationsIds.add(not.id);
      }
    }
  }

  Future _cancelPassedNotifications() async {
    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    // Check which notifications are still in our active list but have
    // already been issued
    var toRemove = List<int>();
    for (var active in _activeNotificationsIds) {
      var stillActive = false;
      for (var not in pendingNotificationRequests) {
        if (not.id == active) {
          stillActive = true;
        }
      }
      if (!stillActive) {
        toRemove.add(active);
      }
    }
    // Remove the expired ones from the main list
    for (var remover in toRemove) {
      _activeNotificationsIds.removeWhere((element) => element == remover);
    }
  }

  void _setAlarm(DateTime alarmTime, String title) {
    int hour = alarmTime.hour;
    int minute = alarmTime.minute;
    String message = title;

    String thisSound;
    if (_alarmSound) {
      thisSound = '';
    } else {
      thisSound = 'silent';
    }

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

  void _setTimer(DateTime alarmTime, String title) {
    int totalSeconds = alarmTime.difference(DateTime.now()).inSeconds;
    String message = title;

    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': totalSeconds - 20,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  void _callBackFromNotificationOptions() async {
    await _loadPreferences();
  }
}
