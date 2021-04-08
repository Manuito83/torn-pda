import 'dart:async';
import 'dart:io';
import 'package:torn_pda/utils/notification.dart';
import 'package:android_intent/android_intent.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/loot/loot_model.dart';
import 'package:torn_pda/pages/loot/loot_notification_ios.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'loot/loot_notification_android.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:torn_pda/widgets/loot/loot_filter_dialog.dart';

enum LootTimeType {
  dateTime,
  timer,
}

class LootPage extends StatefulWidget {
  @override
  _LootPageState createState() => _LootPageState();
}

class _LootPageState extends State<LootPage> {
  var _npcIds = <String>[];
  var _filterOutIds = <String>[];

  final databaseReference = FirebaseDatabase.instance.reference();

  Map<String, LootModel> _mainLootInfo = Map<String, LootModel>();
  Map<String, int> _dbLootInfo = Map<String, int>();
  Future _getInitialLootInformation;
  bool _apiSuccess = false;

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ThemeProvider _themeProvider;

  bool _firstLoad = true;
  int _tornTicks = 0;
  Timer _tickerUpdateTimes;

  LootTimeType _lootTimeType;
  NotificationType _lootNotificationType;
  int _lootNotificationAhead;
  int _lootAlarmAhead;
  int _lootTimerAhead;
  bool _alarmSound;
  bool _alarmVibration;

  // Payload is: 400idlevel
  var _activeNotificationsIds = <int>[];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _getInitialLootInformation = _getLoot();
    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'loot'});
    _tickerUpdateTimes =
        new Timer.periodic(Duration(seconds: 1), (Timer t) => _getLoot());
  }

  @override
  void dispose() {
    _tickerUpdateTimes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: FutureBuilder(
        future: _getInitialLootInformation,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_apiSuccess) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (activeNpcsFiltered())
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                        child: Text(
                          "Some NPCs are filtered out",
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: _returnNpcCards(),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            } else {
              return _connectError();
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
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
                  MdiIcons.filterOutline,
                  color:
                      activeNpcsFiltered() ? Colors.orange[400] : Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return LootFilterDialog(
                        allNpcs: _mainLootInfo,
                        filteredNpcs: _filterOutIds,
                      );
                    },
                  );
                },
              )
            : SizedBox.shrink(),
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
            : SizedBox.shrink(),
        _apiSuccess && Platform.isIOS
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
                        return LootNotificationsIOS(
                          callback: _callBackFromNotificationOptions,
                        );
                      },
                    ),
                  );
                },
              )
            : SizedBox.shrink()
      ],
    );
  }

  bool activeNpcsFiltered() {
    return _npcIds.where((element) => _filterOutIds.contains(element)).length >
        0;
  }

  Widget _connectError() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'There was an error contacting the database, please try again later!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text('If this problem reoccurs, please let us know!'),
        ],
      ),
    );
  }

  Widget _returnNpcCards() {
    // Final card of every NPC
    var npcBoxes = <Widget>[];

    // Loop every NPC
    var npcModels = <LootModel>[];

    _mainLootInfo.forEach((npcId, npcDetails) {
      if (!_filterOutIds.contains(npcId)) {
        // Get npcLevels in a column and format them
        int thisIndex = 1;
        var npcLevels = <Widget>[];
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
                        "Approaching level $levelNumber!",
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
        var shadow = <BoxShadow>[];
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

        npcImage = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey[900], width: 2),
            boxShadow: shadow,
          ),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'images/npcs/npc_$npcId.png',
                height: 60,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace stackTrace) {
                  return Image.asset(
                    "images/npcs/npc_0.png",
                    height: 60,
                  );
                },
              )),
        );

        Widget knifeIcon;
        knifeIcon = Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            child: Icon(
              MdiIcons.knifeMilitary,
              color: npcDetails.levels.current >= 4
                  ? Colors.red
                  : _themeProvider.mainText,
            ),
            onTap: () async {
              var url =
                  'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
              if (_settingsProvider.currentBrowser == BrowserSetting.external) {
                if (await canLaunch(url)) {
                  await launch(url, forceSafariVC: false);
                }
              } else {
                _settingsProvider.useQuickBrowser
                    ? openBrowserDialog(context, url)
                    : _openTornBrowser(url);
              }
            },
            onLongPress: () {
              _openTornBrowser(
                  'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId');
            },
          ),
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
      }
    });

    Widget npcWidget = Column(children: npcBoxes);
    return npcWidget;
  }

  Future _getLoot() async {
    var tsNow = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    if (_firstLoad) {
      _firstLoad = false;
      // Load notifications preferences
      await _loadPreferences();
      // See if there is any pending notification (to paint the icon in green)
      await _retrievePendingNotifications();

      // Get real time database and Torn (which fills level info)
      var dbSuccess = await _fetchDatabase();
      var tornSuccess = await _updateWithTornApi(tsNow);

      if (dbSuccess && tornSuccess) {
        _apiSuccess = true;
      } else {
        _apiSuccess = false;
      }
    } else {
      // We update Torn every 30 seconds, in case there are some changes
      _tornTicks++;
      if (_tornTicks > 30) {
        await _cancelPassedNotifications();
        await _updateWithTornApi(tsNow);
        _tornTicks = 0;
      }
    }

    // We need to ensure that we keep all times updated
    if (mounted) {
      setState(() {
        for (var npc in _mainLootInfo.values) {
          // Update main timing values comparing stored TS with current time
          var timingsList = <Timing>[];
          npc.timings.forEach((key, value) {
            value.due = value.ts - tsNow;
            timingsList.add(Timing(
              due: value.due,
              ts: value.ts,
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

  Future<bool> _fetchDatabase() async {
    try {
      // Get current NPCs
      String dbNpcsResult = (await FirebaseDatabase.instance
              .reference()
              .child("loot/npcs")
              .once())
          .value;
      _npcIds = dbNpcsResult.replaceAll(" ", "").split(",");

      // Get their hospital out times
      Map<dynamic, dynamic> dbHopsResult = (await FirebaseDatabase.instance
              .reference()
              .child("loot/hospital")
              .once())
          .value;
      dbHopsResult.forEach((key, value) {
        _dbLootInfo[key.toString()] = value;
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _updateWithTornApi(int tsNow) async {
    try {
      for (var id in _npcIds) {
        // Get each target from our static list from Torn
        var tornTarget = await TornApiCaller.target(
          _userProvider.basic.userApiKey,
          id.toString(),
        ).getTarget;

        var newNpcLoot = LootModel();
        if (tornTarget is TargetModel) {
          _dbLootInfo.forEach((dbId, dbHospOut) {
            // Look for our tornTarget
            if (dbId == id) {
              newNpcLoot.name = tornTarget.name;

              // If Torn gives a more up to date hospital out value
              if (tornTarget.status.until - 60 > dbHospOut) {
                newNpcLoot.hospout = tornTarget.status.until;
              } else {
                newNpcLoot.hospout = dbHospOut;
              }

              newNpcLoot.levels = Levels();
              if (tornTarget.status.state == 'Hospital') {
                newNpcLoot.levels.current = 0;
                newNpcLoot.levels.next = 1;
                newNpcLoot.status = "hospitalized";
              } else {
                newNpcLoot.status = "loot";
                switch (tornTarget.status.details) {
                  case ('Loot level I'):
                    newNpcLoot.levels.current = 1;
                    newNpcLoot.levels.next = 2;
                    break;
                  case ('Loot level II'):
                    newNpcLoot.levels.current = 2;
                    newNpcLoot.levels.next = 3;
                    break;
                  case ('Loot level III'):
                    newNpcLoot.levels.current = 3;
                    newNpcLoot.levels.next = 4;
                    break;
                  case ('Loot level IV'):
                    newNpcLoot.levels.current = 4;
                    newNpcLoot.levels.next = 5;
                    break;
                  case ('Loot level V'):
                    newNpcLoot.levels.current = 5;
                    newNpcLoot.levels.next = 5;
                    break;
                }
              }

              // Generate updated timings from hosp out
              var newTimingMap = Map<String, Timing>();
              var lootDelays = [0, 30 * 60, 90 * 60, 210 * 60, 450 * 60];
              for (var i = 0; i < lootDelays.length; i++) {
                var thisLevel = Timing(
                  due: newNpcLoot.hospout + lootDelays[i] - tsNow,
                  ts: newNpcLoot.hospout + lootDelays[i],
                );
                newTimingMap.addAll({(i + 1).toString(): thisLevel});
              }
              newNpcLoot.timings = newTimingMap;

              _mainLootInfo.addAll({dbId: newNpcLoot});
            }
          });
        }
      }
    } catch (e) {
      return false;
    }
    return true;
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
    var notificationAhead =
        await SharedPreferencesModel().getLootNotificationAhead();
    var alarmAhead = await SharedPreferencesModel().getLootAlarmAhead();
    var timerAhead = await SharedPreferencesModel().getLootTimerAhead();
    _alarmSound = await SharedPreferencesModel().getManualAlarmSound();
    _alarmVibration = await SharedPreferencesModel().getManualAlarmVibration();

    setState(() {
      if (notification == '0') {
        _lootNotificationType = NotificationType.notification;
      } else if (notification == '1') {
        _lootNotificationType = NotificationType.alarm;
      } else if (notification == '2') {
        _lootNotificationType = NotificationType.timer;
      }

      if (notificationAhead == '0') {
        _lootNotificationAhead = 30;
      } else if (notificationAhead == '1') {
        _lootNotificationAhead = 60;
      } else if (notificationAhead == '2') {
        _lootNotificationAhead = 120;
      } else if (notificationAhead == '3') {
        _lootNotificationAhead = 240;
      } else if (notificationAhead == '4') {
        _lootNotificationAhead = 360;
      }

      if (alarmAhead == '0') {
        _lootAlarmAhead = 0;
      } else if (alarmAhead == '1') {
        _lootAlarmAhead = 2;
      } else if (alarmAhead == '2') {
        _lootAlarmAhead = 4;
      } else if (alarmAhead == '3') {
        _lootAlarmAhead = 6;
      }

      if (timerAhead == '0') {
        _lootTimerAhead = 30;
      } else if (timerAhead == '1') {
        _lootTimerAhead = 60;
      } else if (timerAhead == '2') {
        _lootTimerAhead = 120;
      } else if (timerAhead == '3') {
        _lootTimerAhead = 240;
      } else if (timerAhead == '4') {
        _lootTimerAhead = 360;
      }
    });

    _filterOutIds = await SharedPreferencesModel().getLootFiltered();
  }

  void _scheduleNotification(
    DateTime notificationTime,
    int id,
    String payload,
    String title,
    String subtitle,
  ) async {
    String channelTitle = 'Manual loot';
    String channelSubtitle = 'Manual loot';
    String channelDescription = 'Manual notifications for loot';
    String notificationTitle = title;
    String notificationSubtitle = subtitle;
    int notificationId = id;
    String notificationPayload = payload;

    var modifier = await getNotificationChannelsModifiers();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      "$channelTitle ${modifier.channelIdModifier}",
      "$channelSubtitle ${modifier.channelIdModifier}",
      channelDescription,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: 'notification_loot',
      color: Colors.grey,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
      sound: 'slow_spring_board.aiff',
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
        tz.TZDateTime.from(notificationTime, tz.local)
            .subtract(Duration(seconds: _lootNotificationAhead)),
        platformChannelSpecifics,
        payload: notificationPayload,
        androidAllowWhileIdle: true, // Deliver at exact time
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);

    // DEBUG
    //print('Notification for $notificationTitle @ '
    //    '${tz.TZDateTime.from(notificationTime, tz.local).subtract(Duration(seconds: _lootNotificationAhead))}');
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
    var toRemove = <int>[];
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
    alarmTime = alarmTime.add(Duration(minutes: -_lootAlarmAhead));
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
        'android.intent.extra.alarm.LENGTH': totalSeconds - _lootTimerAhead,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  void _callBackFromNotificationOptions() async {
    await _loadPreferences();
  }

  Future _openTornBrowser(String page) async {
    var browserType = _settingsProvider.currentBrowser;

    switch (browserType) {
      case BrowserSetting.app:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => WebViewFull(
              customUrl: page,
              customTitle: 'Torn',
            ),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = page;
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
  }
}
