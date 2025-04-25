// Dart imports:
import 'dart:async';
import 'dart:convert';
// ignore: unused_import
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/loot/loot_model.dart';
import 'package:torn_pda/models/loot/loot_rangers_model.dart';
import 'package:torn_pda/pages/loot/loot_notification_android.dart';
import 'package:torn_pda/pages/loot/loot_notification_ios.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/loot/loot_filter_dialog.dart';
import 'package:torn_pda/widgets/loot/loot_rangers_explanation.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

enum LootTimeType {
  dateTime,
  timer,
}

class LootPage extends StatefulWidget {
  @override
  LootPageState createState() => LootPageState();
}

class LootPageState extends State<LootPage> {
  var _npcIds = <String>[];
  var _filterOutIds = <String>[];
  final _images = <NpcImagesModel>[];

  final databaseReference = FirebaseDatabase.instance.ref();

  bool? _dbLootRangersEnabled = false;

  Map<String, LootModel> _mainLootInfo = <String, LootModel>{};
  final Map<String, int> _dbLootInfo = <String, int>{};
  Future? _getInitialLootInformation;
  bool _apiSuccess = false;

  late SettingsProvider _settingsProvider;
  ThemeProvider? _themeProvider;
  late WebViewProvider _webViewProvider;

  bool _firstLoad = true;
  int _tornTicks = 0;
  late Timer _tickerUpdateTimes;

  LootTimeType? _lootTimeType;
  NotificationType? _lootNotificationType;
  late int _lootNotificationAhead;
  late int _lootAlarmAhead;
  late int _lootTimerAhead;
  late bool _alarmSound;
  bool? _alarmVibration;

  int _lootRangersTime = 0;
  String _lootRangersClearAtZeroReason = "";
  bool _lootRangersAttackOngoing = false;
  final List<String> _lootRangersIdOrder = <String>[];
  final List<String?> _lootRangersNameOrder = <String?>[];

  // Payload is: 400idlevel (new: 499 for Loot Rangers)
  final _activeNotificationsIds = <int>[];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _getInitialLootInformation = _getLoot();
    _getLootRangers();
    analytics?.logScreenView(screenName: 'loot');

    routeWithDrawer = true;
    routeName = "loot";

    _tickerUpdateTimes = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getLoot());
  }

  @override
  void dispose() {
    _tickerUpdateTimes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider!.canvas,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      endDrawer: const Drawer(),
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider!.canvas,
        child: FutureBuilder(
          future: _getInitialLootInformation,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiSuccess) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await _getLoot();
                    _getLootRangers();
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: SingleChildScrollView(
                    child: Column(
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
                          const SizedBox.shrink(),
                        if (_lootRangersIdOrder.isNotEmpty && _dbLootRangersEnabled!)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                            child: Text(
                              "NPCs sorted by ${_lootRangersTime == 0 ? 'previous ' : ''}Loot Rangers' attack order",
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: _returnNpcCards(),
                        ),
                        const SizedBox(height: 20),
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
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('Loot', style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.splitScreenAndBrowserLeft()) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) const PdaBrowserIcon(),
        ],
      ),
      actions: <Widget>[
        if (_apiSuccess)
          IconButton(
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
        else
          const SizedBox.shrink(),
        if (_apiSuccess)
          IconButton(
            icon: const Icon(
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
        else
          const SizedBox.shrink(),
        if (_apiSuccess && Platform.isAndroid)
          IconButton(
            icon: Icon(
              Icons.alarm_on,
              color: _themeProvider!.buttonText,
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
        else
          const SizedBox.shrink(),
        if (_apiSuccess && (Platform.isIOS || Platform.isWindows))
          IconButton(
            icon: Icon(
              Icons.alarm_on,
              color: _themeProvider!.buttonText,
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
        else
          const SizedBox.shrink()
      ],
    );
  }

  bool activeNpcsFiltered() {
    return _npcIds.where((element) => _filterOutIds.contains(element)).isNotEmpty;
  }

  Widget _connectError() {
    return const Padding(
      padding: EdgeInsets.all(30),
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
      final npcBoxes = <Widget>[];

      // If Loot Rangers is active, return LR's order
      if (_lootRangersIdOrder.isNotEmpty && _dbLootRangersEnabled!) {
        final sortedMap = <String, LootModel>{};
        final originalMap = Map<String, LootModel>.of(_mainLootInfo);
        for (final id in _lootRangersIdOrder) {
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
          final npcLevels = <Widget>[];
          final npcLevelsColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: npcLevels,
          );

          npcDetails.timings!.forEach((levelNumber, levelDetails) {
            // Time formatting
            final levelDateTime = DateTime.fromMillisecondsSinceEpoch(levelDetails.ts! * 1000);
            final time = TimeFormatter(
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
            if (levelNumber == npcDetails.levels!.current.toString()) {
              isCurrent = true;
            }

            String timeString = "Level $thisIndex";
            var style = const TextStyle();
            if (isPast && !isCurrent) {
              timeString += " at $time";
              style = const TextStyle(color: Colors.grey);
            } else if (isCurrent) {
              timeString += " (now)";
              style = TextStyle(
                color: _themeProvider!.getTextColor(Colors.green),
                fontWeight: FontWeight.bold,
              );
            } else {
              final timeDiff = levelDateTime.difference(DateTime.now());
              final diffFormatted = _formatDuration(timeDiff);
              if (_lootTimeType == LootTimeType.timer) {
                timeString += " in $diffFormatted";
              } else {
                timeString += " at $time";
              }
              if (timeDiff.inMinutes < 10) {
                if (npcDetails.levels!.next! >= 4) {
                  style = TextStyle(
                    color: _themeProvider!.getTextColor(Colors.orange),
                    fontWeight: FontWeight.bold,
                  );
                } else {
                  style = const TextStyle(
                    fontWeight: FontWeight.bold,
                  );
                }
              }
            }
            String? typeString;
            IconData? iconData;
            switch (_lootNotificationType!) {
              case NotificationType.notification:
                typeString = 'notification';
                iconData = Icons.chat_bubble_outline;
              case NotificationType.alarm:
                typeString = 'alarm';
                iconData = Icons.notifications_none;
              case NotificationType.timer:
                typeString = 'timer';
                iconData = Icons.timer;
            }

            Widget notificationIcon;
            if (!isPast && !isCurrent) {
              bool isPending = false;
              for (final id in _activeNotificationsIds) {
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
                  switch (_lootNotificationType!) {
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

                        if (_settingsProvider.discreetNotifications) {
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
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green[700]!,
                          duration: const Duration(milliseconds: 1500),
                          contentPadding: const EdgeInsets.all(10),
                        );
                      }
                    case NotificationType.alarm:
                      _setAlarm(
                        levelDateTime,
                        "${npcDetails.name} level $levelNumber",
                      );
                      BotToast.showText(
                        clickClose: true,
                        text: 'Loot level $levelNumber'
                            ' $typeString set for ${npcDetails.name}!',
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: Colors.green[700]!,
                        duration: const Duration(milliseconds: 1500),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    case NotificationType.timer:
                      _setTimer(
                        levelDateTime,
                        "${npcDetails.name} level $levelNumber",
                      );
                      BotToast.showText(
                        clickClose: true,
                        text: 'Loot level $levelNumber'
                            ' $typeString set for ${npcDetails.name}!',
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: Colors.green[700]!,
                        duration: const Duration(milliseconds: 1500),
                        contentPadding: const EdgeInsets.all(10),
                      );
                  }
                },
              );
            } else {
              notificationIcon = const SizedBox.shrink();
            }

            final timeRow = Row(
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
            npcLevels.add(const SizedBox(height: 8));
            thisIndex++;
          });

          Widget hospitalized;
          if (npcDetails.status == "hospitalized") {
            hospitalized = Text(
              '[HOSPITALIZED]',
              style: TextStyle(
                fontSize: 12,
                color: _themeProvider!.getTextColor(Colors.red),
                fontWeight: FontWeight.bold,
              ),
            );
          } else {
            hospitalized = const SizedBox.shrink();
          }

          Widget knifeIcon;
          knifeIcon = Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              child: Icon(
                MdiIcons.knifeMilitary,
                color: npcDetails.levels!.current! >= 4 ? Colors.red : _themeProvider!.mainText,
              ),
              onTap: () async {
                final url = 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
                await context.read<WebViewProvider>().openBrowserPreference(
                      context: context,
                      url: url,
                      browserTapType: BrowserTapType.short,
                    );
              },
              onLongPress: () async {
                final url = 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
                await context.read<WebViewProvider>().openBrowserPreference(
                      context: context,
                      url: url,
                      browserTapType: BrowserTapType.long,
                    );
              },
            ),
          );

          Color cardBorderColor() {
            if (npcDetails.levels!.current! >= 4) {
              return Colors.orange;
            } else {
              return Colors.transparent;
            }
          }

          final Widget thisNpcImage = _images.firstWhere((element) => element.id == npcId).image;

          npcBoxes.add(
            Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: cardBorderColor(), width: 1.5),
                borderRadius: BorderRadius.circular(4.0),
              ),
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
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${npcDetails.name} [$npcId]',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                hospitalized,
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
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

      final Widget npcWidget = Column(children: npcBoxes);
      return npcWidget;
    } catch (e, t) {
      logToUser("Error loading @npcCards: $e");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash @npcCards");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
      return const SizedBox.shrink();
    }
  }

  Future _getLootRangers() async {
    try {
      final response = await http.get(Uri.parse("https://api.lzpt.io/loot"));
      if (response.statusCode == 200) {
        final lrJson = lootRangersFromJson(response.body);

        // DEBUG
        //final lrJson = lootRangersFromJson(lootRangersDebug);

        if (lrJson.time!.clear == 0) {
          _lootRangersTime = 0;
          if (lrJson.time!.attack) {
            _lootRangersAttackOngoing = true;
          }
          if (lrJson.time!.reason != null) {
            _lootRangersClearAtZeroReason = lrJson.time!.reason!;
          }
        } else {
          _lootRangersTime = lrJson.time!.clear! * 1000;
          _lootRangersAttackOngoing = false;
          _lootRangersClearAtZeroReason = "";
        }

        _lootRangersNameOrder.clear();
        for (int i = 0; i < lrJson.order!.length; i++) {
          final id = lrJson.order![i];
          lrJson.npcs!.forEach((key, value) {
            // If [clear] is false, the NPC won't participate in this attack
            if (value.clear!) {
              if (key == id.toString()) {
                _lootRangersNameOrder.add(value.name);
                _lootRangersIdOrder.add(key);
              }
            }
          });
        }
      }
    } catch (e, t) {
      logToUser("Error loading @lootRangers: $e");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash @lootRangers");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", t);
      _lootRangersTime = 0;
      _lootRangersIdOrder.clear();
      _lootRangersNameOrder.clear();
    }
  }

  Widget _lootRangersWidget() {
    if (_lootRangersNameOrder.isEmpty || _lootRangersIdOrder.isEmpty || !_dbLootRangersEnabled!) {
      return const SizedBox.shrink();
    }

    String timeString = "";
    final lrDateTime = DateTime.fromMillisecondsSinceEpoch(_lootRangersTime);
    final timeDiff = lrDateTime.difference(DateTime.now());
    final diffFormatted = _formatDuration(timeDiff);
    if (_lootTimeType == LootTimeType.timer) {
      timeString += "in $diffFormatted";
    } else {
      final time = TimeFormatter(
        inputTime: DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
        timeFormatSetting: _settingsProvider.currentTimeFormat,
        timeZoneSetting: _settingsProvider.currentTimeZone,
      ).formatHour;
      timeString += "at $time";
    }

    // Loot Rangers notification icon
    String? typeString;
    IconData? iconData;
    switch (_lootNotificationType!) {
      case NotificationType.notification:
        typeString = 'notification';
        iconData = Icons.chat_bubble_outline;
      case NotificationType.alarm:
        typeString = 'alarm';
        iconData = Icons.notifications_none;
      case NotificationType.timer:
        typeString = 'timer';
        iconData = Icons.timer;
    }

    Widget notificationIcon;
    bool isPending = false;
    for (final id in _activeNotificationsIds) {
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
        switch (_lootNotificationType!) {
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

              String? time = TimeFormatter(
                inputTime: DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
                timeFormatSetting: _settingsProvider.currentTimeFormat,
                timeZoneSetting: _settingsProvider.currentTimeZone,
              ).formatHour;

              if (_settingsProvider.discreetNotifications) {
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
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green[700]!,
                duration: const Duration(milliseconds: 1500),
                contentPadding: const EdgeInsets.all(10),
              );
            }
          case NotificationType.alarm:
            _setAlarm(
              DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
              "Loot Rangers",
            );
            BotToast.showText(
              clickClose: true,
              text: 'Loot Rangers $typeString set!',
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green[700]!,
              duration: const Duration(milliseconds: 1500),
              contentPadding: const EdgeInsets.all(10),
            );
          case NotificationType.timer:
            _setTimer(
              DateTime.fromMillisecondsSinceEpoch(_lootRangersTime),
              "Loot Rangers",
            );
            BotToast.showText(
              clickClose: true,
              text: 'Loot Rangers $typeString set!',
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green[700]!,
              duration: const Duration(milliseconds: 1500),
              contentPadding: const EdgeInsets.all(10),
            );
        }
      },
    );

    final int minutesRemaining = DateTime.fromMicrosecondsSinceEpoch(
      _lootRangersTime * 1000,
    ).difference(DateTime.now()).inMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Loot Rangers", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 5),
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
                child: const Icon(
                  Icons.info_outline,
                  size: 20,
                ),
              )
            ],
          ),
          if (_lootRangersTime == 0 && !_lootRangersAttackOngoing)
            Column(
              children: [
                Text("Next attack not set!", style: TextStyle(color: _themeProvider!.getTextColor(Colors.orange[700]))),
                if (_lootRangersClearAtZeroReason.isNotEmpty)
                  Text(
                    "Looting will resume after $_lootRangersClearAtZeroReason",
                    style: TextStyle(color: _themeProvider!.getTextColor(Colors.orange[700])),
                  ),
              ],
            )
          else if (_lootRangersTime == 0 && _lootRangersAttackOngoing)
            Text("ATTACK ONGOING NOW",
                style: TextStyle(color: _themeProvider!.getTextColor(Colors.red[700]), fontWeight: FontWeight.bold))
          else
            Text("Next attack $timeString"),
          if (_lootRangersTime > 0 || (_lootRangersTime == 0 && _lootRangersAttackOngoing))
            Text("Order: ${_lootRangersNameOrder.join(", ")}"),
          if (_lootRangersTime > 0 || (_lootRangersTime == 0 && _lootRangersAttackOngoing))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    child: Icon(
                      MdiIcons.knifeMilitary,
                      size: 20,
                      color: minutesRemaining > 0 && minutesRemaining < 2 ? Colors.red : _themeProvider!.mainText,
                    ),
                    onTap: () async {
                      // This is a Loot Rangers alert for one or more NPCs
                      final notes = <String>[];
                      final colors = <String>[];
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
                            browserTapType: BrowserTapType.chainShort,
                            isChainingBrowser: true,
                            chainingPayload: ChainingPayload()
                              ..attackIdList = _lootRangersIdOrder
                              ..attackNameList = _lootRangersNameOrder
                              ..attackNotesList = notes
                              ..attackNotesColorList = colors
                              ..showNotes = true
                              ..showBlankNotes = false
                              ..showOnlineFactionWarning = false,
                          );
                    },
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 15),
                    notificationIcon,
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future _getLoot() async {
    try {
      final tsNow = (DateTime.now().millisecondsSinceEpoch / 1000).round();

      if (_firstLoad) {
        _firstLoad = false;
        // Load notifications preferences
        await _loadPreferences();
        // See if there is any pending notification (to paint the icon in green)
        await _retrievePendingNotifications();

        // Get real time database and Torn (which fills level info)
        final dbSuccess = await _fetchDatabase();
        final tornSuccess = await _updateWithTornApi(tsNow);

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
                level: value.levels!.current,
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
          for (final npc in _mainLootInfo.values) {
            // Update main timing values comparing stored TS with current time
            final timingsList = <Timing>[];
            npc.timings!.forEach((key, value) {
              value.due = value.ts! - tsNow;
              timingsList.add(
                Timing(
                  due: value.due,
                  ts: value.ts,
                ),
              );
            });
            // Make sure to advance levels if the times comes in between updates
            if (timingsList[0].due! > 0) {
              npc.levels!.current = 0;
              npc.levels!.next = 1;
            } else if (timingsList[4].due! < 0) {
              npc.levels!.current = 5;
              npc.levels!.next = 5;
            } else {
              for (var i = 0; i < 4; i++) {
                if (timingsList[i].due! < 0 && timingsList[i + 1].due! > 0) {
                  npc.levels!.current = i + 1;
                  npc.levels!.next = i + 2;
                }
              }
            }
          }
        });
      }
    } catch (e) {
      logToUser("Error loading @getLoot: $e");
    }
  }

  Future<bool> _fetchDatabase() async {
    try {
      // Get current NPCs
      String dbNpcsResult = "";
      if (!Platform.isWindows) {
        dbNpcsResult = (await FirebaseDatabase.instance.ref().child("loot/npcs").once()).snapshot.value as String;
      } else {
        dbNpcsResult = (await http.get(Uri.parse("https://torn-pda-manuito.firebaseio.com/loot/npcs.json"))).body;
      }

      _npcIds = dbNpcsResult.replaceAll(" ", "").split(",");

      // Get their hospital out times
      Map<dynamic, dynamic> dbHopsResult = {};
      if (!Platform.isWindows) {
        dbHopsResult = (await FirebaseDatabase.instance.ref().child("loot/hospital").once()).snapshot.value
            as Map<dynamic, dynamic>;
      } else {
        var response = await http.get(Uri.parse("https://torn-pda-manuito.firebaseio.com/loot/hospital.json"));
        dbHopsResult = jsonDecode(response.body) as Map<dynamic, dynamic>;
      }
      dbHopsResult.forEach((key, value) {
        _dbLootInfo[key.toString()] = value;
      });

      if (!Platform.isWindows) {
        _dbLootRangersEnabled =
            (await FirebaseDatabase.instance.ref().child("loot/lootRangersActive").once()).snapshot.value as bool?;
      } else {
        var response = await http.get(Uri.parse("https://torn-pda-manuito.firebaseio.com/loot/lootRangersActive.json"));
        _dbLootRangersEnabled = jsonDecode(response.body) as bool;
      }

      return true;
    } catch (e) {
      logToUser("Error loading @fetchDatabase: $e");
      return false;
    }
  }

  Future<bool> _updateWithTornApi(int tsNow) async {
    int apiSuccess = 0;
    try {
      for (final id in _npcIds) {
        // Get each target from our static list from Torn
        final tornTarget = await ApiCallsV1.getTarget(playerId: id);

        final newNpcLoot = LootModel();
        if (tornTarget is TargetModel) {
          apiSuccess++;
          _dbLootInfo.forEach((dbId, dbHospOut) {
            // Look for our tornTarget
            if (dbId == id) {
              newNpcLoot.name = tornTarget.name;

              // If Torn gives a more up to date hospital out value
              if (tornTarget.status!.until! - 60 > dbHospOut) {
                newNpcLoot.hospout = tornTarget.status!.until;
              } else {
                newNpcLoot.hospout = dbHospOut;
              }

              newNpcLoot.levels = Levels();
              if (tornTarget.status!.state == 'Hospital') {
                newNpcLoot.levels!.current = 0;
                newNpcLoot.levels!.next = 1;
                newNpcLoot.status = "hospitalized";
              } else {
                newNpcLoot.status = "loot";
                switch (tornTarget.status!.details) {
                  case ('Loot level I'):
                    newNpcLoot.levels!.current = 1;
                    newNpcLoot.levels!.next = 2;
                  case ('Loot level II'):
                    newNpcLoot.levels!.current = 2;
                    newNpcLoot.levels!.next = 3;
                  case ('Loot level III'):
                    newNpcLoot.levels!.current = 3;
                    newNpcLoot.levels!.next = 4;
                  case ('Loot level IV'):
                    newNpcLoot.levels!.current = 4;
                    newNpcLoot.levels!.next = 5;
                  case ('Loot level V'):
                    newNpcLoot.levels!.current = 5;
                    newNpcLoot.levels!.next = 5;
                }
              }

              // Generate updated timings from hosp out
              final newTimingMap = <String, Timing>{};
              final lootDelays = [0, 30 * 60, 90 * 60, 210 * 60, 450 * 60];
              for (var i = 0; i < lootDelays.length; i++) {
                final thisLevel = Timing(
                  due: newNpcLoot.hospout! + lootDelays[i] - tsNow,
                  ts: newNpcLoot.hospout! + lootDelays[i],
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
      logToUser("Error loading @updateApi: $e");
      return false;
    }
    if (apiSuccess == 0) {
      return false;
    }
    return true;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future _loadPreferences() async {
    try {
      final lootTimeType = await Prefs().getLootTimerType();
      lootTimeType == 'timer' ? _lootTimeType = LootTimeType.timer : _lootTimeType = LootTimeType.dateTime;

      final notification = await Prefs().getLootNotificationType();
      final notificationAhead = await Prefs().getLootNotificationAhead();
      final alarmAhead = await Prefs().getLootAlarmAhead();
      final timerAhead = await Prefs().getLootTimerAhead();
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
        } else if (notificationAhead == '6') {
          _lootNotificationAhead = 480;
        } else if (notificationAhead == '7') {
          _lootNotificationAhead = 600;
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
        } else if (alarmAhead == '5') {
          _lootAlarmAhead = 8;
        } else if (alarmAhead == '6') {
          _lootAlarmAhead = 10;
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
        } else if (timerAhead == '6') {
          _lootTimerAhead = 480;
        } else if (timerAhead == '7') {
          _lootTimerAhead = 600;
        }
      });

      _filterOutIds = await Prefs().getLootFiltered();
    } catch (e) {
      logToUser("Error loading @loadPreferences: $e");
    }
  }

  Future<void> _scheduleNotification(
    DateTime notificationTime,
    int id,
    String payload,
    String title,
    String subtitle,
  ) async {
    const String channelTitle = 'Manual loot';
    const String channelSubtitle = 'Manual loot';
    const String channelDescription = 'Manual notifications for loot';
    final String notificationTitle = title;
    final String notificationSubtitle = subtitle;
    final int notificationId = id;
    final String notificationPayload = payload;

    final modifier = await getNotificationChannelsModifiers();
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
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

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinNotificationDetails,
    );

    if (Platform.isAndroid) {
      await assessExactAlarmsPermissionsAndroid(context, _settingsProvider);
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      notificationTitle,
      notificationSubtitle,
      //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // DEBUG
      tz.TZDateTime.from(notificationTime, tz.local).subtract(Duration(seconds: _lootNotificationAhead)),
      platformChannelSpecifics,
      payload: notificationPayload,
      androidScheduleMode: exactAlarmsPermissionAndroid
          ? AndroidScheduleMode.exactAllowWhileIdle // Deliver at exact time (needs permission)
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    // DEBUG
    //print('Notification for $notificationTitle @ '
    //    '${tz.TZDateTime.from(notificationTime, tz.local).subtract(Duration(seconds: _lootNotificationAhead))}');
  }

  Future _retrievePendingNotifications() async {
    try {
      final pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      for (final not in pendingNotificationRequests) {
        final id = not.id.toString();
        if (id.length > 3 && id.substring(0, 3) == '400' || id.contains("499")) {
          _activeNotificationsIds.add(not.id);
        }
      }
    } catch (e) {
      logToUser("Error loading @retrievePendingNotifications: $e");
    }
  }

  Future _cancelPassedNotifications() async {
    try {
      final pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      // Check which notifications are still in our active list but have
      // already been issued
      final toRemove = <int>[];
      for (final active in _activeNotificationsIds) {
        var stillActive = false;
        for (final not in pendingNotificationRequests) {
          if (not.id == active) {
            stillActive = true;
          }
        }
        if (!stillActive) {
          toRemove.add(active);
        }
      }
      // Remove the expired ones from the main list
      for (final remover in toRemove) {
        _activeNotificationsIds.removeWhere((element) => element == remover);
      }
    } catch (e) {
      logToUser("Error loading @cancelPassedNotifications: $e");
    }
  }

  void _setAlarm(DateTime alarmTime, String title) {
    alarmTime = alarmTime.add(Duration(minutes: -_lootAlarmAhead));
    final int hour = alarmTime.hour;
    final int minute = alarmTime.minute;
    final String message = title;

    String thisSound;
    if (_alarmSound) {
      thisSound = '';
    } else {
      thisSound = 'silent';
    }

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

  void _setTimer(DateTime alarmTime, String title) {
    final int totalSeconds = alarmTime.difference(DateTime.now()).inSeconds;
    final String message = title;

    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': totalSeconds - _lootTimerAhead,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  Future<void> _callBackFromNotificationOptions() async {
    await _loadPreferences();
  }
}

class NpcImagesModel {
  late NpcImage image;
  String? id;
}

class NpcImage extends StatelessWidget {
  final int? level;
  final String? npcId;

  const NpcImage({
    this.level,
    this.npcId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget npcImage;
    List<BoxShadow>? shadow = <BoxShadow>[];
    if (level! >= 4) {
      shadow = [
        const BoxShadow(
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
          border: Border.all(color: Colors.grey[900]!, width: 2),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'images/npcs/npc_$npcId.png',
            height: 60,
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Image.asset(
                "images/npcs/npc_0.png",
                height: 60,
              );
            },
          ),
        ),
      ),
      onTap: () async {
        final url = 'https://www.torn.com/profiles.php?XID=$npcId';
        await context.read<WebViewProvider>().openBrowserPreference(
              context: context,
              url: url,
              browserTapType: BrowserTapType.short,
            );
      },
      onLongPress: () async {
        final url = 'https://www.torn.com/profiles.php?XID=$npcId';
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
