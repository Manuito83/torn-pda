// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/models/loot/loot_rangers_model.dart';
import 'package:torn_pda/providers/webview_provider.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/loot/loot_model.dart';
import 'package:torn_pda/pages/loot/loot_notification_ios.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/loot/loot_filter_dialog.dart';
import 'package:torn_pda/widgets/loot/loot_rangers_explanation.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
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
  var _npcIds = <String>[];
  var _filterOutIds = <String>[];
  var _images = <NpcImagesModel>[];

  final databaseReference = FirebaseDatabase.instance.ref();

  bool _dbLootRangersEnabled = false;

  Map<String, LootModel> _mainLootInfo = Map<String, LootModel>();
  Map<String, int> _dbLootInfo = Map<String, int>();
  Future _getInitialLootInformation;
  bool _apiSuccess = false;

  SettingsProvider _settingsProvider;
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

  int _lootRangersTime = 0;
  List<String> _lootRangersIdOrder = <String>[];
  List<String> _lootRangersNameOrder = <String>[];

  // Payload is: 400idlevel (new: 499 for Loot Rangers)
  var _activeNotificationsIds = <int>[];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _getInitialLootInformation = _getLoot();
    _getLootRangers();
    analytics.setCurrentScreen(screenName: 'loot');
    _tickerUpdateTimes = new Timer.periodic(Duration(seconds: 1), (Timer t) => _getLoot());
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
      backgroundColor: _themeProvider.canvas,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: FutureBuilder(
          future: _getInitialLootInformation,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiSuccess) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await _getLoot();
                    _getLootRangers();
                    await Future.delayed(Duration(seconds: 1));
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        _lootRangersWidget(),
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
                        if (_lootRangersIdOrder.isNotEmpty && _dbLootRangersEnabled)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                            child: Text(
                              "NPCs sorted by ${_lootRangersTime == 0 ? 'previous ' : ''}Loot Rangers' attack order",
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: _returnNpcCards(),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              } else {
                return Column(
                  children: [
                    _lootRangersWidget(),
                    _connectError(),
                  ],
                );
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text('Loot'),
      leadingWidth: 80,
      leading: Row(
        children: [
          IconButton(
            icon: new Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
              scaffoldState.openDrawer();
            },
          ),
          PdaBrowserIcon(),
        ],
      ),
      actions: <Widget>[
        _apiSuccess
            ? IconButton(
                icon: Icon(
                  MdiIcons.filterOutline,
                  color: activeNpcsFiltered() ? Colors.orange[400] : Colors.white,
                ),
                onPressed: () {
                  showDialog(
                    useRootNavigator: false,
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
                      Prefs().setLootTimerType('dateTime');
                    } else {
                      _lootTimeType = LootTimeType.timer;
                      Prefs().setLootTimerType('timer');
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
                          lootRangersEnabled: _dbLootRangersEnabled,
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
                          lootRangersEnabled: _dbLootRangersEnabled,
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
    return _npcIds.where((element) => _filterOutIds.contains(element)).length > 0;
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
    try {
      // Final card of every NPC
      var npcBoxes = <Widget>[];

      // If Loot Rangers is active, return LR's order
      if (_lootRangersIdOrder.isNotEmpty && _dbLootRangersEnabled) {
        final sortedMap = Map<String, LootModel>();
        final originalMap = Map<String, LootModel>.of(_mainLootInfo);
        for (var id in _lootRangersIdOrder) {
          originalMap.forEach((npcId, npcDetails) {
            if (id == npcId) {
              sortedMap.addAll({npcId: npcDetails});
            }
          });
        }

        _mainLootInfo = Map.from(sortedMap);

        // Add the NPCs that might be missing in LootRangers
        originalMap.forEach((npcId, npcDetails) {
          if (!_lootRangersIdOrder.contains(npcId)) {
            _mainLootInfo.addAll({npcId: npcDetails});
          }
        });
      }

      // Loop every NPC
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
            var levelDateTime = DateTime.fromMillisecondsSinceEpoch(levelDetails.ts * 1000);
            var time = TimeFormatter(
              inputTime: levelDateTime,
              timeFormatSetting: _settingsProvider.currentTimeFormat,
              timeZoneSetting: _settingsProvider.currentTimeZone,
            ).formatHour;

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
                  color: _lootNotificationType == NotificationType.notification && isPending ? Colors.green : null,
                ),
                onTap: () async {
                  switch (_lootNotificationType) {
                    case NotificationType.notification:
                      if (isPending) {
                        setState(() {
                          isPending = false;
                        });
                        await flutterLocalNotificationsPlugin.cancel(int.parse('400$npcId$levelNumber'));
                        _activeNotificationsIds.removeWhere((element) => element == int.parse('400$npcId$levelNumber'));
                      } else {
                        setState(() {
                          isPending = true;
                        });
                        _activeNotificationsIds.add(int.parse('400$npcId$levelNumber'));

                        if (_settingsProvider.discreteNotifications) {
                          _scheduleNotification(
                            levelDateTime,
                            int.parse('400$npcId$levelNumber'),
                            '400-$npcId',
                            "L",
                            "${npcDetails.name} - $levelNumber!",
                          );
                        } else {
                          _scheduleNotification(
                            levelDateTime,
                            int.parse('400$npcId$levelNumber'),
                            '400-$npcId',
                            "${npcDetails.name} loot",
                            "Approaching level $levelNumber!",
                          );
                        }

                        BotToast.showText(
                          clickClose: true,
                          text: 'Loot level $levelNumber'
                              ' $typeString set for ${npcDetails.name}!',
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green[700],
                          duration: Duration(milliseconds: 1500),
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
                        clickClose: true,
                        text: 'Loot level $levelNumber'
                            ' $typeString set for ${npcDetails.name}!',
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: Colors.green[700],
                        duration: Duration(milliseconds: 1500),
                        contentPadding: EdgeInsets.all(10),
                      );
                      break;
                    case NotificationType.timer:
                      _setTimer(
                        levelDateTime,
                        "${npcDetails.name} level $levelNumber",
                      );
                      BotToast.showText(
                        clickClose: true,
                        text: 'Loot level $levelNumber'
                            ' $typeString set for ${npcDetails.name}!',
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: Colors.green[700],
                        duration: Duration(milliseconds: 1500),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeString,
                  style: style,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: notificationIcon,
                ),
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

          Widget knifeIcon;
          knifeIcon = Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              child: Icon(
                MdiIcons.knifeMilitary,
                color: npcDetails.levels.current >= 4 ? Colors.red : _themeProvider.mainText,
              ),
              onTap: () async {
                var url = 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
                await context.read<WebViewProvider>().openBrowserPreference(
                      context: context,
                      url: url,
                      browserTapType: BrowserTapType.short,
                    );
              },
              onLongPress: () async {
                var url = 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
                await context.read<WebViewProvider>().openBrowserPreference(
                      context: context,
                      url: url,
                      browserTapType: BrowserTapType.long,
                    );
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

          Widget thisNpcImage = _images.firstWhere((element) => element.id == npcId).image;

          npcBoxes.add(
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: cardBorderColor(), width: 1.5), borderRadius: BorderRadius.circular(4.0)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        thisNpcImage,
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
                                  '${npcDetails.name} [${npcId ?? "?"}]',
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
        }
      });

      Widget npcWidget = Column(children: npcBoxes);
      return npcWidget;
    } catch (e) {
      BotToast.showText(text: "Error loading @npcCards: $e");
      return SizedBox.shrink();
    }
  }

  Future _getLootRangers() async {
    final response = await http.get(Uri.parse("https://api.lzpt.io/loot"));
    if (response.statusCode == 200) {
      final lrJson = lootRangersFromJson(response.body);

      if (lrJson.time.clear == 0) {
        _lootRangersTime = 0;
      } else {
        _lootRangersTime = lrJson.time.clear * 1000;
      }

      _lootRangersNameOrder.clear();
      for (int i = 0; i < lrJson.order.length; i++) {
        var id = lrJson.order[i];
        lrJson.npcs.forEach((key, value) {
          // If [clear] is false, the NPC won't participate in this attack
          if (value.clear) {
            if (key.toString() == id.toString()) {
              _lootRangersNameOrder.add(value.name);
              _lootRangersIdOrder.add(key);
            }
          }
        });
      }
    }
  }

  Widget _lootRangersWidget() {
    if (_lootRangersNameOrder.isEmpty || _lootRangersIdOrder.isEmpty || !_dbLootRangersEnabled) {
      return SizedBox.shrink();
    }

    String timeString = "";
    var lrDateTime = DateTime.fromMillisecondsSinceEpoch(_lootRangersTime);
    var timeDiff = lrDateTime.difference(DateTime.now());
    var diffFormatted = _formatDuration(timeDiff);
    if (_lootTimeType == LootTimeType.timer) {
      timeString += "in $diffFormatted";
    } else {
      var time = TimeFormatter(
        inputTime: DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
        timeFormatSetting: _settingsProvider.currentTimeFormat,
        timeZoneSetting: _settingsProvider.currentTimeZone,
      ).formatHour;
      timeString += "at $time";
    }

    // Loot Rangers notification icon
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
    bool isPending = false;
    for (var id in _activeNotificationsIds) {
      if (id == int.parse('499')) {
        isPending = true;
      }
    }
    notificationIcon = InkWell(
      splashColor: Colors.transparent,
      child: Icon(
        iconData,
        size: 20,
        color: _lootNotificationType == NotificationType.notification && isPending ? Colors.green : null,
      ),
      onTap: () async {
        switch (_lootNotificationType) {
          case NotificationType.notification:
            if (isPending) {
              setState(() {
                isPending = false;
              });
              await flutterLocalNotificationsPlugin.cancel(499);
              _activeNotificationsIds.removeWhere((element) => element == 499);
            } else {
              setState(() {
                isPending = true;
              });
              _activeNotificationsIds.add(499);

              String time = TimeFormatter(
                inputTime: DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
                timeFormatSetting: _settingsProvider.currentTimeFormat,
                timeZoneSetting: _settingsProvider.currentTimeZone,
              ).formatHour;

              if (_settingsProvider.discreteNotifications) {
                _scheduleNotification(
                  DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
                  499,
                  '499-${_lootRangersIdOrder.join(",")}-${_lootRangersNameOrder.join(",")}-$time',
                  "LR",
                  "",
                );
              } else {
                _scheduleNotification(
                  DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
                  499,
                  '499-${_lootRangersIdOrder.join(",")}-${_lootRangersNameOrder.join(",")}-$time',
                  "Loot Rangers attack!",
                  "Order: ${_lootRangersNameOrder.join(", ")}",
                );
              }

              BotToast.showText(
                clickClose: true,
                text: 'Loot Rangers $typeString set!',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green[700],
                duration: Duration(milliseconds: 1500),
                contentPadding: EdgeInsets.all(10),
              );
            }
            break;
          case NotificationType.alarm:
            _setAlarm(
              DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
              "Loot Rangers",
            );
            BotToast.showText(
              clickClose: true,
              text: 'Loot Rangers $typeString set!',
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green[700],
              duration: Duration(milliseconds: 1500),
              contentPadding: EdgeInsets.all(10),
            );
            break;
          case NotificationType.timer:
            _setTimer(
              DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
              "Loot Rangers",
            );
            BotToast.showText(
              clickClose: true,
              text: 'Loot Rangers $typeString set!',
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green[700],
              duration: Duration(milliseconds: 1500),
              contentPadding: EdgeInsets.all(10),
            );
            break;
        }
      },
    );

    int minutesRemaining = DateTime.fromMicrosecondsSinceEpoch(
      _lootRangersTime * 1000,
    ).difference(DateTime.now()).inMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Loot Rangers", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 5),
              GestureDetector(
                onTap: () async {
                  await showDialog(
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) {
                      return LootRangersExplanationDialog(
                        themeProvider: _themeProvider,
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                ),
              )
            ],
          ),
          if (_lootRangersTime == 0)
            Text("Next attack not set!", style: TextStyle(color: Colors.orange[700]))
          else
            Text("Next attack $timeString"),
          if (_lootRangersTime > 0) Text("Order: ${_lootRangersNameOrder.join(", ")}"),
          if (_lootRangersTime > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    child: Icon(
                      MdiIcons.knifeMilitary,
                      size: 20,
                      color: minutesRemaining > 0 && minutesRemaining < 2 ? Colors.red : _themeProvider.mainText,
                    ),
                    onTap: () async {
                      // This is a Loot Rangers alert for one or more NPCs
                      var notes = <String>[];
                      var colors = <String>[];
                      for (var i = 0; i < _lootRangersNameOrder.length; i++) {
                        colors.add("green");
                        if (i == 0) {
                          notes.add("Attacks due to commence $timeString!");
                        } else {
                          notes.add("");
                        }
                      }

                      // Open chaining browser for Loot Rangers
                      context.read<WebViewProvider>().openBrowserPreference(
                          context: context,
                          url: "https://www.torn.com/loader.php?sid=attack&user2ID=${_lootRangersIdOrder[0]}",
                          browserTapType: BrowserTapType.chain,
                          isChainingBrowser: true,
                          chainingPayload: ChainingPayload()
                            ..attackIdList = _lootRangersIdOrder
                            ..attackNameList = _lootRangersNameOrder
                            ..attackNotesList = notes
                            ..attackNotesColorList = colors
                            ..showNotes = true
                            ..showBlankNotes = false
                            ..showOnlineFactionWarning = false);
                    },
                  ),
                ),
                SizedBox(width: 15),
                notificationIcon,
              ],
            ),
        ],
      ),
    );
  }

  Future _getLoot() async {
    try {
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

        _mainLootInfo.forEach((key, value) {
          _images.add(
            NpcImagesModel()
              ..id = key
              ..image = NpcImage(
                npcId: key,
                level: value.levels.current,
              ),
          );
        });
      } else {
        // We update Torn every 30 seconds, in case there are some changes
        _tornTicks++;
        if (_tornTicks > 40) {
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
    } catch (e) {
      BotToast.showText(text: "Error loading @getLoot: $e");
    }
  }

  Future<bool> _fetchDatabase() async {
    try {
      // Get current NPCs
      String dbNpcsResult = (await FirebaseDatabase.instance.ref().child("loot/npcs").once()).snapshot.value;
      _npcIds = dbNpcsResult.replaceAll(" ", "").split(",");

      // Get their hospital out times
      Map<dynamic, dynamic> dbHopsResult =
          (await FirebaseDatabase.instance.ref().child("loot/hospital").once()).snapshot.value;
      dbHopsResult.forEach((key, value) {
        _dbLootInfo[key.toString()] = value;
      });

      _dbLootRangersEnabled =
          (await FirebaseDatabase.instance.ref().child("loot/lootRangersActive").once()).snapshot.value;

      return true;
    } catch (e) {
      BotToast.showText(text: "Error loading @fetchDatabase: $e");
      return false;
    }
  }

  Future<bool> _updateWithTornApi(int tsNow) async {
    int apiSuccess = 0;
    try {
      for (var id in _npcIds) {
        // Get each target from our static list from Torn
        var tornTarget = await Get.find<ApiCallerController>().getTarget(playerId: id.toString());

        var newNpcLoot = LootModel();
        if (tornTarget is TargetModel) {
          apiSuccess++;
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
      BotToast.showText(text: "Error loading @updateApi: $e");
      return false;
    }
    if (apiSuccess == 0) {
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
    try {
      var lootTimeType = await Prefs().getLootTimerType();
      lootTimeType == 'timer' ? _lootTimeType = LootTimeType.timer : _lootTimeType = LootTimeType.dateTime;

      var notification = await Prefs().getLootNotificationType();
      var notificationAhead = await Prefs().getLootNotificationAhead();
      var alarmAhead = await Prefs().getLootAlarmAhead();
      var timerAhead = await Prefs().getLootTimerAhead();
      _alarmSound = await Prefs().getManualAlarmSound();
      _alarmVibration = await Prefs().getManualAlarmVibration();

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
          _lootNotificationAhead = 300;
        } else if (notificationAhead == '5') {
          _lootNotificationAhead = 360;
        }

        if (alarmAhead == '0') {
          _lootAlarmAhead = 0;
        } else if (alarmAhead == '1') {
          _lootAlarmAhead = 2;
        } else if (alarmAhead == '2') {
          _lootAlarmAhead = 4;
        } else if (alarmAhead == '3') {
          _lootAlarmAhead = 5;
        } else if (alarmAhead == '4') {
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
          _lootTimerAhead = 300;
        } else if (timerAhead == '5') {
          _lootTimerAhead = 360;
        }
      });

      _filterOutIds = await Prefs().getLootFiltered();
    } catch (e) {
      BotToast.showText(text: "Error loading @loadPreferences: $e");
    }
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
      channelDescription: channelDescription,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: 'notification_loot',
      color: Colors.grey,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'slow_spring_board.aiff',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationSubtitle,
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // DEBUG
        tz.TZDateTime.from(notificationTime, tz.local).subtract(Duration(seconds: _lootNotificationAhead)),
        platformChannelSpecifics,
        payload: notificationPayload,
        androidAllowWhileIdle: true, // Deliver at exact time
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);

    // DEBUG
    //print('Notification for $notificationTitle @ '
    //    '${tz.TZDateTime.from(notificationTime, tz.local).subtract(Duration(seconds: _lootNotificationAhead))}');
  }

  Future _retrievePendingNotifications() async {
    try {
      var pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      for (var not in pendingNotificationRequests) {
        var id = not.id.toString();
        if (id.length > 3 && id.substring(0, 3) == '400' || id.contains("499")) {
          _activeNotificationsIds.add(not.id);
        }
      }
    } catch (e) {
      BotToast.showText(text: "Error loading @retrievePendingNotifications: $e");
    }
  }

  Future _cancelPassedNotifications() async {
    try {
      var pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

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
    } catch (e) {
      BotToast.showText(text: "Error loading @cancelPassedNotifications: $e");
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
}

class NpcImagesModel {
  NpcImage image;
  String id;
}

class NpcImage extends StatelessWidget {
  final int level;
  final String npcId;

  const NpcImage({
    int level,
    String npcId,
    bool useQuickBrowser,
    Key key,
  })  : level = level,
        npcId = npcId,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget npcImage;
    var shadow = <BoxShadow>[];
    if (level >= 4) {
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

    npcImage = GestureDetector(
      child: Container(
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
              errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
                return Image.asset(
                  "images/npcs/npc_0.png",
                  height: 60,
                );
              },
            )),
      ),
      onTap: () async {
        var url = 'https://www.torn.com/profiles.php?XID=$npcId';
        await context.read<WebViewProvider>().openBrowserPreference(
              context: context,
              url: url,
              browserTapType: BrowserTapType.short,
            );
      },
      onLongPress: () async {
        var url = 'https://www.torn.com/profiles.php?XID=$npcId';
        await context.read<WebViewProvider>().openBrowserPreference(
              context: context,
              url: url,
              browserTapType: BrowserTapType.long,
            );
      },
    );

    return npcImage;
  }
}
