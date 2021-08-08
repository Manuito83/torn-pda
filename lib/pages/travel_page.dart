// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:android_intent/android_intent.dart';
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/providers/webview_provider.dart';

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/travel/travel_model.dart';
import 'package:torn_pda/pages/travel/foreign_stock_page.dart';
import 'package:torn_pda/pages/travel/travel_options_android.dart';
import 'package:torn_pda/pages/travel/travel_options_ios.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';

class TravelPage extends StatefulWidget {
  TravelPage({Key key}) : super(key: key);

  @override
  _TravelPageState createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> with WidgetsBindingObserver {
  TravelModel _travelModel = TravelModel();
  Timer _ticker;

  int _apiRetries = 0;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  bool _notificationsPending = false;
  bool _alarmSound = false;
  bool _alarmVibration = true;

  int _travelNotificationAhead;
  int _travelAlarmAhead;
  int _travelTimerAhead;

  String _myCurrentKey = '';
  bool _apiError = true;
  String _errorReason = '';

  Future _finishedLoadingPreferences;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _finishedLoadingPreferences = _restorePreferences();
    _retrievePendingNotifications();
    _ticker = new Timer.periodic(Duration(seconds: 10), (Timer t) => _updateInformation());
    analytics.logEvent(name: 'section_changed', parameters: {'section': 'travel'});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _updateInformation();
    }
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          child: FutureBuilder(
            future: _finishedLoadingPreferences,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Column(
                  children: _travelMain(),
                );
              } else {
                return Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButtonAnimator: FabOverrideAnimation(),
      floatingActionButtonLocation: MediaQuery.of(context).orientation == Orientation.landscape
          ? FloatingActionButtonLocation.endFloat
          : _travelModel.abroad
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FutureBuilder(
        future: _finishedLoadingPreferences,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_travelModel.abroad) {
              return buildSpeedDial();
            } else {
              return OpenContainer(
                transitionDuration: Duration(seconds: 1),
                transitionType: ContainerTransitionType.fadeThrough,
                openBuilder: (BuildContext context, VoidCallback _) {
                  return ForeignStockPage(apiKey: _myCurrentKey);
                },
                closedElevation: 6.0,
                closedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(56 / 2),
                  ),
                ),
                onClosed: (ReturnFlagPressed returnFlag) async {
                  if (returnFlag.flagPressed) {
                    var url = 'https://www.torn.com/travelagency.php';
                    if (!_settingsProvider.useQuickBrowser) returnFlag.shortTap = false;
                    await context.read<WebViewProvider>().openBrowserPreference(
                          context: context,
                          url: url,
                          useDialog: returnFlag.shortTap,
                        );
                    _updateInformation();
                  }
                },
                closedColor: Colors.orange,
                closedBuilder: (BuildContext context, VoidCallback openContainer) {
                  return SizedBox(
                    height: 56,
                    width: 56,
                    child: Center(
                      child: Image.asset(
                        'images/icons/box.png',
                        width: 24,
                      ),
                    ),
                  );
                },
              );
            }
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leading: IconButton(
        icon: Icon(Icons.dehaze),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      title: Text('Travel'),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.refresh_outlined,
            color: _themeProvider.buttonText,
          ),
          onPressed: () {
            _updateInformation();
            BotToast.showText(
              text: "Refreshing",
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.grey[700],
              duration: Duration(milliseconds: 500),
              contentPadding: EdgeInsets.all(10),
            );
          },
        ),
        if (Platform.isAndroid)
          IconButton(
            icon: Icon(
              Icons.alarm_on,
              color: _themeProvider.buttonText,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return TravelOptionsAndroid(
                      callback: _callBackFromTravelOptions,
                    );
                  },
                ),
              );
            },
          )
        else if (Platform.isIOS)
          IconButton(
            icon: Icon(
              Icons.alarm_on,
              color: _themeProvider.buttonText,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return TravelOptionsIOS(
                      callback: _callBackFromTravelOptions,
                    );
                  },
                ),
              );
            },
          )
        else
          SizedBox.shrink(),
      ],
    );
  }

  SpeedDial buildSpeedDial() {
    var dials = <SpeedDialChild>[];

    var dialStocks = SpeedDialChild(
      label: 'STOCKS',
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.orange,
      backgroundColor: Colors.orange,
      onTap: () async {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (BuildContext context) => ForeignStockPage(
                  apiKey: _myCurrentKey,
                ),
              ),
            )
            .then((value) => _onStocksPageClosed(value));
      },
      child: SizedBox(
        height: 56,
        width: 56,
        child: Center(
          child: Image.asset(
            'images/icons/box.png',
            width: 24,
          ),
        ),
      ),
    );

    var dialNotificationSet = SpeedDialChild(
      child: Icon(
        Icons.chat_bubble_outline,
        color: Colors.black,
      ),
      backgroundColor: Colors.green,
      onTap: () async {
        await _scheduleNotification().then((value) {
          String formattedTime = _formatTime(value);
          BotToast.showText(
            text: "Notification set for $formattedTime",
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 3),
            contentPadding: EdgeInsets.all(10),
          );
        });
      },
      label: 'Set notification',
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.green,
    );

    var dialNotificationCancel = SpeedDialChild(
      child: Icon(
        Icons.chat_bubble_outline,
        color: Colors.black,
      ),
      backgroundColor: Colors.red,
      onTap: () async {
        await _cancelTravelNotification();
        BotToast.showText(
          text: "Notification cancelled!",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          contentColor: Colors.orange[700],
          duration: Duration(seconds: 3),
          contentPadding: EdgeInsets.all(10),
        );
      },
      label: 'Cancel notification',
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.red,
    );

    var dialAlarm = SpeedDialChild(
      child: Icon(
        Icons.notifications_none,
        color: Colors.black,
      ),
      backgroundColor: Colors.grey[400],
      onTap: () async {
        await _setAlarm().then((value) {
          String formattedTime = _formatTime(value);
          BotToast.showText(
            text: 'Alarm set for $formattedTime!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 3),
            contentPadding: EdgeInsets.all(10),
          );
        });
      },
      label: 'Set alarm',
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.grey[400],
    );

    var dialTimer = SpeedDialChild(
      child: Icon(
        Icons.timer,
        color: Colors.black,
      ),
      backgroundColor: Colors.grey[400],
      onTap: () async {
        await _setTimer().then((value) {
          String formattedTime = _formatTime(value);
          BotToast.showText(
            text: "Timer set for $formattedTime",
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 3),
            contentPadding: EdgeInsets.all(10),
          );
        });
      },
      label: 'Set timer',
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.grey[400],
    );

    // We always add stocks
    dials.add(dialStocks);

    if (_travelModel.abroad && _travelModel.timeLeft > 120) {
      if (_notificationsPending) {
        dials.add(dialNotificationCancel);
      } else {
        dials.add(dialNotificationSet);
      }

      if (Platform.isAndroid) {
        dials.add(dialAlarm);
        dials.add(dialTimer);
      }
    }

    return SpeedDial(
      direction:
          MediaQuery.of(context).orientation == Orientation.portrait ? SpeedDialDirection.Up : SpeedDialDirection.Left,
      elevation: 2,
      backgroundColor: Colors.transparent,
      overlayColor: Colors.transparent,
      child: Container(
        child: Icon(
          Icons.airplanemode_active,
          color: Colors.black,
          size: 30,
        ),
        width: 58,
        height: 58,
        decoration: new BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
      visible: true,
      curve: Curves.bounceIn,
      children: dials,
    );
  }

  _onStocksPageClosed(ReturnFlagPressed returnFlag) async {
    if (_travelModel.abroad) return;

    if (returnFlag.flagPressed) {
      var url = 'https://www.torn.com/travelagency.php';
      if (!_settingsProvider.useQuickBrowser) returnFlag.shortTap = false;
      await context.read<WebViewProvider>().openBrowserPreference(
            context: context,
            url: url,
            useDialog: returnFlag.shortTap,
          );
      _updateInformation();
    }
  }

  List<Widget> _travelMain() {
    // We detected no api key loaded in preferences
    if (_myCurrentKey == '') {
      return <Widget>[
        Text(
          'Torn API Key not found!',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Text(
            'Please go to the Settings section and configure your '
            'Torn API Key properly.',
          ),
        ),
      ];
    }
    // There is an API error and we have no user
    if (_apiError) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: 15),
                child: Text(
                  "ERROR CONTACTING TORN",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text("Error: $_errorReason"),
              SizedBox(height: 40),
              Text("You can still try to visit the website:"),
              SizedBox(height: 10),
              _travelAgencyButton(),
            ],
          ),
        ),
      ];
    }
    // API was correct: are we travelling or not?
    if (_travelModel.abroad) {
      // If we have reached another country
      if (_travelModel.destination != 'Torn' && _travelModel.timeLeft < 15) {
        return <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 60),
            child: _flagImage(),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 60),
            child: Text(
              'Arrived in ${_travelModel.destination}!',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            child: Text("Go visit!"),
            onLongPress: () async {
              await context.read<WebViewProvider>().openBrowserPreference(
                    context: context,
                    url: "https://www.torn.com",
                    useDialog: false,
                  );
              _updateInformation();
            },
            onPressed: () async {
              await context.read<WebViewProvider>().openBrowserPreference(
                    context: context,
                    url: "https://www.torn.com",
                    useDialog: _settingsProvider.useQuickBrowser,
                  );
              _updateInformation();
            },
          ),
        ];
      } else if (_travelModel.timeLeft > 0 && _travelModel.timeLeft < 120) {
        // We are about to reach another country
        return <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Image.asset(
              'images/icons/arrivals.png',
              width: 150,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 60),
            child: Text(
              'Approaching ${_travelModel.destination}!',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            child: Icon(Icons.local_airport),
            onLongPress: () async {
              await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: "https://www.torn.com",
                useDialog: false,
              );
              _updateInformation();
            },
            onPressed: () async {
              await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: "https://www.torn.com",
                useDialog: _settingsProvider.useQuickBrowser,
              );
              _updateInformation();
            },

          ),
        ];
      } else {
        // We are flying somewhere (another country or TORN)

        // Time formatting
        var formattedTime = TimeFormatter(
          inputTime: _travelModel.timeArrival,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        // Calculations for travel bar
        var startTime = _travelModel.departed;
        var endTime = _travelModel.timeStamp;
        var totalSeconds = endTime - startTime;
        var dateTimeArrival = _travelModel.timeArrival;
        var timeDifference = dateTimeArrival.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
        String diff = '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';

        return <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 30),
            child: _flagImage(),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 30),
            child: Text(
              'TRAVELLING',
              style: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Arriving in ${_travelModel.destination} at:',
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$formattedTime',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onLongPress: () async {
                  await context.read<WebViewProvider>().openBrowserPreference(
                    context: context,
                    url: "https://www.torn.com",
                    useDialog: false,
                  );
                  _updateInformation();
                },
                onTap: () async {
                  await context.read<WebViewProvider>().openBrowserPreference(
                    context: context,
                    url: "https://www.torn.com",
                    useDialog: _settingsProvider.useQuickBrowser,
                  );
                  _updateInformation();
                },
                child: LinearPercentIndicator(
                  isRTL: _travelModel.destination == "Torn" ? true : false,
                  center: Text(
                    diff,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  widgetIndicator: Opacity(
                    // Make icon transparent when about to pass over text
                    opacity:
                        _getTravelPercentage(totalSeconds) < 0.2 || _getTravelPercentage(totalSeconds) > 0.7 ? 1 : 0.3,
                    child: Padding(
                      padding: _travelModel.destination == "Torn"
                          ? const EdgeInsets.only(top: 6, right: 6)
                          : const EdgeInsets.only(top: 6, left: 10),
                      child: RotatedBox(
                        quarterTurns: _travelModel.destination == "Torn" ? 3 : 1,
                        child: Icon(
                          Icons.airplanemode_active,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                  animateFromLastPercent: true,
                  animation: true,
                  width: 200,
                  lineHeight: 18,
                  progressColor: Colors.blue[200],
                  backgroundColor: Colors.grey,
                  percent: _getTravelPercentage(totalSeconds),
                ),
              ),
            ],
          ),
        ];
      }
    } else {
      // We are in Torn, not travelling
      return <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Image.asset(
                'images/icons/airport.png',
                width: 150,
              ),
            ),
            Text(
              'NO TRAVEL DETECTED',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(top: 8, bottom: 40),
              child: Text(
                '(auto refreshing)',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            _travelAgencyButton(),
          ],
        )
      ];
    }
  }

  double _getTravelPercentage(int totalSeconds) {
    double percentage = 1 - (_travelModel.timeLeft / totalSeconds);
    if (percentage > 1) {
      return 1;
    } else if (percentage < 0) {
      return 0;
    } else {
      return percentage;
    }
  }

  ElevatedButton _travelAgencyButton() {
    return ElevatedButton(
      child: Text("Travel Agency"),
      onLongPress: () async {
        await context.read<WebViewProvider>().openBrowserPreference(
          context: context,
          url: "https://www.torn.com/travelagency.php",
          useDialog: false,
        );
        _updateInformation();
      },
      onPressed: () async {
        await context.read<WebViewProvider>().openBrowserPreference(
          context: context,
          url: "https://www.torn.com/travelagency.php",
          useDialog: _settingsProvider.useQuickBrowser,
        );
        _updateInformation();
      },
    );
  }

  Widget _flagImage() {
    String flagFile;
    switch (_travelModel.destination) {
      case "Torn":
        flagFile = 'images/flags/travel/torn.png';
        break;
      case "Argentina":
        flagFile = 'images/flags/travel/argentina.png';
        break;
      case "Canada":
        flagFile = 'images/flags/travel/canada.png';
        break;
      case "Cayman Islands":
        flagFile = 'images/flags/travel/cayman_islands.png';
        break;
      case "China":
        flagFile = 'images/flags/travel/china.png';
        break;
      case "Hawaii":
        flagFile = 'images/flags/travel/hawaii.png';
        break;
      case "Japan":
        flagFile = 'images/flags/travel/japan.png';
        break;
      case "Mexico":
        flagFile = 'images/flags/travel/mexico.png';
        break;
      case "South Africa":
        flagFile = 'images/flags/travel/south_africa.png';
        break;
      case "Switzerland":
        flagFile = 'images/flags/travel/switzerland.png';
        break;
      case "UAE":
        flagFile = 'images/flags/travel/uae.png';
        break;
      case "United Kingdom":
        flagFile = 'images/flags/travel/uk.png';
        break;
      default:
        return SizedBox.shrink();
    }
    return Image(
      image: AssetImage(flagFile),
      width: 150,
    );
  }

  void _updateInformation() {
    DateTime now = DateTime.now();
    // We avoid calling the API unnecessarily
    if (now.isAfter(_travelModel.timeArrival.subtract(Duration(seconds: 120)))) {
      _fetchTornApi();
    }
    _retrievePendingNotifications();

    // Update timeLeft so that the percentage indicator and timer set time work correctly
    if (_travelModel.timeArrival.isAfter(DateTime.now())) {
      setState(() {
        var diff = _travelModel.timeArrival.difference(DateTime.now());
        _travelModel.timeLeft = diff.inSeconds;
      });
    }
  }

  Future<void> _fetchTornApi() async {
    var myTravel = await TornApiCaller.travel(_myCurrentKey).getTravel;
    if (myTravel is TravelModel) {
      _apiRetries = 0;
      setState(() {
        _travelModel = myTravel;
        _apiError = false;
      });
    } else if (myTravel is ApiError) {
      if (!_apiError && _apiRetries < 4) {
        _apiRetries++;
      } else {
        _apiRetries = 0;
        setState(() {
          _apiError = true;
          _errorReason = myTravel.errorReason;
        });
      }
    }
  }

  Future<DateTime> _scheduleNotification() async {
    var scheduledNotificationDateTime = _travelModel.timeArrival.subtract(Duration(seconds: _travelNotificationAhead));

    var modifier = await getNotificationChannelsModifiers();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'Manual travel ${modifier.channelIdModifier} s',
      'Manual travel ${modifier.channelIdModifier} s',
      'Manual notifications for travel',
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: 'notification_travel',
      color: Colors.blue,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
      presentSound: true,
      sound: 'aircraft_seatbelt.aiff',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    var notificationTitle = await Prefs().getTravelNotificationTitle();
    var notificationSubtitle = await Prefs().getTravelNotificationBody();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      201,
      notificationTitle,
      notificationSubtitle,
      //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // DEBUG
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      platformChannelSpecifics,
      payload: 'travel',
      androidAllowWhileIdle: true, // Deliver at exact time
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // DEBUG
    //print('Notification for travel @ '
    //    '${tz.TZDateTime.from(scheduledNotificationDateTime, tz.local)}');

    _retrievePendingNotifications();
    return scheduledNotificationDateTime;
  }

  Future<void> _cancelTravelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(201);
    _retrievePendingNotifications();
  }

  Future<void> _retrievePendingNotifications() async {
    var pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    var pending = false;
    if (pendingNotificationRequests.length > 0) {
      for (var notification in pendingNotificationRequests) {
        if (notification.payload == 'travel') {
          pending = true;
          break;
        }
      }
    }

    setState(() {
      _notificationsPending = pending;
    });
  }

  Future<DateTime> _setAlarm() async {
    var alarmTime = _travelModel.timeArrival.add(Duration(minutes: -_travelAlarmAhead));
    int hour = alarmTime.hour;
    int minute = alarmTime.minute;

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
        'android.intent.extra.alarm.MESSAGE': 'TORN PDA Travel',
      },
    );
    intent.launch();

    return alarmTime;
  }

  Future<DateTime> _setTimer() async {
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': _travelModel.timeLeft - _travelTimerAhead,
        // 'android.intent.extra.alarm.LENGTH': 5,    // DEBUG
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': 'TORN PDA Travel',
      },
    );
    intent.launch();

    return DateTime.now().add(Duration(seconds: _travelModel.timeLeft - _travelTimerAhead));
  }

  Future _restorePreferences() async {
    var userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
    _myCurrentKey = userDetails.basic.userApiKey;
    if (_myCurrentKey != '') {
      await _fetchTornApi();
    }

    _alarmSound = await Prefs().getManualAlarmSound();
    _alarmVibration = await Prefs().getManualAlarmVibration();

    // Ahead timers
    var notificationAhead = await Prefs().getTravelNotificationAhead();
    var alarmAhead = await Prefs().getTravelAlarmAhead();
    var timerAhead = await Prefs().getTravelTimerAhead();

    if (notificationAhead == '0') {
      _travelNotificationAhead = 20;
    } else if (notificationAhead == '1') {
      _travelNotificationAhead = 40;
    } else if (notificationAhead == '2') {
      _travelNotificationAhead = 60;
    } else if (notificationAhead == '3') {
      _travelNotificationAhead = 120;
    } else if (notificationAhead == '4') {
      _travelNotificationAhead = 300;
    }

    if (alarmAhead == '0') {
      _travelAlarmAhead = 0;
    } else if (alarmAhead == '1') {
      _travelAlarmAhead = 1;
    } else if (alarmAhead == '2') {
      _travelAlarmAhead = 2;
    } else if (alarmAhead == '3') {
      _travelAlarmAhead = 5;
    }

    if (timerAhead == '0') {
      // Time left is recalculated each 10 seconds, so we give here 20 + 10 extra, as otherwise
      // it's too tight. Worse case scenario: the user is quick and checks the travel screen when
      // there are still 25-30 seconds to go. Best case, he still has 20 seconds to spare.
      _travelTimerAhead = 30;
    } else if (timerAhead == '1') {
      // Same as above but 40 + 5 seconds. Timer triggers between 35-45 seconds.
      _travelTimerAhead = 45;
    } else if (timerAhead == '2') {
      _travelTimerAhead = 60;
    } else if (timerAhead == '3') {
      _travelTimerAhead = 120;
    } else if (timerAhead == '4') {
      _travelTimerAhead = 300;
    }
  }

  String _formatTime(DateTime inputTime) {
    return TimeFormatter(
      inputTime: inputTime,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatHour;
  }

  _callBackFromTravelOptions() async {
    await _restorePreferences();
  }
}

class FabOverrideAnimation extends FloatingActionButtonAnimator {
  @override
  Offset getOffset({Offset begin, Offset end, double progress}) {
    return Offset(end.dx, end.dy);
  }

  @override
  Animation<double> getRotationAnimation({Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }

  @override
  Animation<double> getScaleAnimation({Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }
}
