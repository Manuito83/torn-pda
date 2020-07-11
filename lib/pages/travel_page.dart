import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/travel/foreign_stock_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/webview_travel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torn_pda/models/travel_model.dart';
import 'package:android_intent/android_intent.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:animations/animations.dart';

class TravelPage extends StatefulWidget {
  TravelPage({Key key}) : super(key: key);

  @override
  _TravelPageState createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  TravelModel _travelModel = TravelModel();
  Timer _ticker;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  bool _notificationsPending = false;
  bool _alarmSound = false;
  bool _alarmVibration = true;

  String _myCurrentKey = '';
  bool _apiError = false;
  String _errorReason = '';

  var _notificationFormKey = GlobalKey<FormState>();

  String _notificationTitle;
  String _notificationBody;
  final _notificationTitleController = new TextEditingController();
  final _notificationBodyController = new TextEditingController();

  Future _finishedLoadingPreferences;

  @override
  void initState() {
    super.initState();

    // This is commented because it's handled by Firebase messaging!
    //_requestIOSPermissions();

    _finishedLoadingPreferences = _restorePreferences();

    _retrievePendingNotifications();

    _ticker = new Timer.periodic(
        Duration(seconds: 10), (Timer t) => _updateInformation());

    analytics.logEvent(
        name: 'section_changed',
        parameters: {'section': 'travel'});
  }

  // This is commented because it's handled by Firebase messaging!
  /*
  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  */

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return Scaffold(
      drawer: Drawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.dehaze),
          onPressed: () {
            final ScaffoldState scaffoldState =
                context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
        title: Text('Travel'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.textsms),
            onPressed: () {
              _notificationTitleController.text = _notificationTitle;
              _notificationBodyController.text = _notificationBody;
              _showNotificationTextDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: FutureBuilder(
            future: _finishedLoadingPreferences,
            builder:
                (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
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
      floatingActionButtonLocation: _travelModel.travelling
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FutureBuilder(
        future: _finishedLoadingPreferences,
        builder:
            (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
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
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
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
                padding: EdgeInsetsDirectional.only(bottom: 30),
                child: Text(
                  "ERROR LOADING USER",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text("Error: $_errorReason"),
            ],
          ),
        ),
      ];
    }
    // API was correct: are we travelling or not?
    if (_travelModel.travelling) {
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
          RaisedButton(
            child: Text("Go visit!"),
            onPressed: () async {
              var browserType = _settingsProvider.currentBrowser;
              switch (browserType) {
                case BrowserSetting.app:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => TornWebViewTravel(
                        webViewType: WebViewTypeTravel.generic,
                        genericTitle: '${_travelModel.destination}',
                        genericCallBack: _updateInformation,
                      ),
                    ),
                  );
                  break;
                case BrowserSetting.external:
                  var url = 'https://www.torn.com/';
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  }
                  break;
              }
            },
          ),
        ];
      } else if (_travelModel.destination != 'Torn' &&
          _travelModel.timeLeft > 0 &&
          _travelModel.timeLeft < 120) {
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
          RaisedButton(
            child: Icon(Icons.local_airport),
            onPressed: () async {
              var browserType = _settingsProvider.currentBrowser;
              switch (browserType) {
                case BrowserSetting.app:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => TornWebViewTravel(
                        webViewType: WebViewTypeTravel.generic,
                        genericTitle: '${_travelModel.destination}',
                        genericCallBack: _updateInformation,
                      ),
                    ),
                  );
                  break;
                case BrowserSetting.external:
                  var url = 'https://www.torn.com/';
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  }
                  break;
              }
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
        ).format;

        // Calculations for travel bar
        var startTime = _travelModel.departed;
        var endTime = _travelModel.timeStamp;
        var totalSeconds = endTime - startTime;
        var dateTimeArrival = _travelModel.timeArrival;
        var timeDifference = dateTimeArrival.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes =
        twoDigits(timeDifference.inMinutes.remainder(60));
        String diff =
            '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';

        return <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(top: 50, bottom: 30),
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
              LinearPercentIndicator(
                center: Text(
                  diff,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                width: 150,
                lineHeight: 18,
                progressColor: Colors.blue[200],
                backgroundColor: Colors.grey,
                percent: 1 - (_travelModel.timeLeft / totalSeconds),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(top: 20, bottom: 20),
            child: Divider(),
          ),
          Text(
            'NOTIFICATION',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
                top: 10, bottom: 15, start: 30, end: 30),
            child: Text("This will launch a standard notification "
                "20 seconds before arriving to destination."),
          ),
          _notificationNumberText(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Builder(
                builder: (ctx) => RaisedButton(
                  child: Text("Notify"),
                  onPressed: () async {
                    await _scheduleNotification().then((value) {
                      var formatter = new DateFormat('HH:mm:ss');
                      String formattedTime = formatter.format(value);
                      Scaffold.of(ctx).showSnackBar(SnackBar(
                        content: Text('Notification set for $formattedTime'),
                      ));
                    });
                  },
                ),
              ),
              Padding(padding: EdgeInsetsDirectional.only(start: 15)),
              Builder(
                builder: (ctx) => RaisedButton(
                    child: Text("Cancel"),
                    onPressed: () async {
                      await _cancelTravelNotification();
                      Scaffold.of(ctx).showSnackBar(SnackBar(
                        content: Text('Notifications cancelled!'),
                      ));
                    }),
              ),
            ],
          ),
          _conditionalAlarm(),
          _conditionalTimer(),
          SizedBox(height: 90),
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
            RaisedButton(
              child: Text("Travel Agency"),
              onPressed: () async {
                var browserType = _settingsProvider.currentBrowser;
                switch (browserType) {
                  case BrowserSetting.app:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => TornWebViewTravel(
                          webViewType: WebViewTypeTravel.travelAgency,
                          genericCallBack: _updateInformation,
                        ),
                      ),
                    );
                    break;
                  case BrowserSetting.external:
                    var url = 'https://www.torn.com/travelagency.php';
                    if (await canLaunch(url)) {
                      await launch(url, forceSafariVC: false);
                    }
                    break;
                }
              },
            ),
          ],
        )
      ];
    }
  }

  Widget _conditionalAlarm() {
    if (Platform.isAndroid) {
      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(top: 20, bottom: 20),
            child: Divider(),
          ),
          Text(
            'ALARM',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
                top: 10, bottom: 10, start: 30, end: 30),
            child: Text("This will schedule a standard Android phone alarm, "
                "rounded to the minute before arriving."),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Switch(
                value: _alarmSound,
                onChanged: (value) {
                  setState(() {
                    _alarmSound = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
              Text("Sound"),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 10, end: 10),
              ),
              Switch(
                value: _alarmVibration,
                onChanged: (value) {
                  setState(() {
                    _alarmVibration = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
              Text("Vibration"),
            ],
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 10),
          ),
          Builder(
            builder: (ctx) => RaisedButton(
                child: Text("Set Alarm"),
                onPressed: () async {
                  _setAlarm();
                  var formatter = new DateFormat('HH:mm');
                  String formatted = formatter.format(_travelModel.timeArrival);
                  Scaffold.of(ctx).showSnackBar(SnackBar(
                    content: Text('Alarm set, at $formatted local time, '
                        '${_travelModel.timeArrival.second} '
                        'seconds before arrival!'),
                  ));
                }),
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _conditionalTimer() {
    if (Platform.isAndroid) {
      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(top: 20, bottom: 20),
            child: Divider(),
          ),
          Text(
            'TIMER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
                top: 10, bottom: 15, start: 30, end: 30),
            child: Text("This will launch an Android clock timer 20 seconds "
                "before arriving to destination."),
          ),
          Builder(
            builder: (ctx) => RaisedButton(
                child: Text("Set Timer"),
                onPressed: () async {
                  _setTimer();
                  var formatter = new DateFormat('HH:mm:ss');
                  String formattedTime = formatter.format(
                      _travelModel.timeArrival.subtract(Duration(seconds: 20)));
                  Scaffold.of(ctx).showSnackBar(SnackBar(
                    content: Text('Timer set for $formattedTime'),
                  ));
                }),
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
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

  Widget _notificationNumberText() {
    if (!_notificationsPending) {
      return SizedBox.shrink();
    } else {
      return Padding(
        padding: EdgeInsetsDirectional.only(bottom: 10),
        child: Text(
          'Notification active',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Future<void> _showNotificationTextDialog(BuildContext _) {
    return showDialog<void>(
      context: _,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
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
                      color: _themeProvider.background,
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
                    child: Form(
                      key: _notificationFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text('Notification title'),
                          ),
                          TextFormField(
                            style: TextStyle(fontSize: 14),
                            controller: _notificationTitleController,
                            maxLength: 15,
                            minLines: 1,
                            maxLines: 1,
                            decoration: InputDecoration(
                              counterText: "",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Cannot be empty!";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.0),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text('Notification description'),
                          ),
                          TextFormField(
                            style: TextStyle(fontSize: 14),
                            controller: _notificationBodyController,
                            maxLength: 50,
                            minLines: 1,
                            maxLines: 2,
                            decoration: InputDecoration(
                              counterText: "",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Cannot be empty!";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              FlatButton(
                                child: Text("Change"),
                                onPressed: () async {
                                  if (_notificationFormKey.currentState
                                      .validate()) {
                                    // Get rid of dialog first, so that it can't
                                    // be pressed twice
                                    Navigator.of(context).pop();
                                    // Copy controller's text ot local variable
                                    // early and delete the global, so that text
                                    // does not appear again in case of failure
                                    _notificationTitle =
                                        _notificationTitleController.text;
                                    _notificationBody =
                                        _notificationBodyController.text;
                                    SharedPreferencesModel()
                                        .setTravelNotificationTitle(
                                            _notificationTitle);
                                    SharedPreferencesModel()
                                        .setTravelNotificationBody(
                                            _notificationBody);
                                    Scaffold.of(_).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Notification details changed!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              FlatButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _notificationTitleController.text = '';
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.mainText,
                      radius: 22,
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: Icon(
                          Icons.textsms,
                          color: _themeProvider.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateInformation() {
    DateTime now = DateTime.now();
    // We avoid calling the API unnecessarily
    if (now
        .isAfter(_travelModel.timeArrival.subtract(Duration(seconds: 120)))) {
      _fetchTornApi();
    }
    _retrievePendingNotifications();
  }

  Future<void> _fetchTornApi() async {
    var myTravel = await TornApiCaller.travel(_myCurrentKey).getTravel;
    if (myTravel is TravelModel) {
      setState(() {
        _travelModel = myTravel;
        _apiError = false;
      });
    } else if (myTravel is ApiError) {
      setState(() {
        _apiError = true;
        _errorReason = myTravel.errorReason;
      });
    }
  }

  Future<DateTime> _scheduleNotification() async {
    var scheduledNotificationDateTime =
        _travelModel.timeArrival.subtract(Duration(seconds: 20));
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
      'Travel',
      'Travel Full',
      'Urgent notifications about arriving to destination',
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
      201,
      _notificationTitle,
      _notificationBody,
      //DateTime.now().add(Duration(seconds: 10)), // DEBUG 10 SECONDS
      scheduledNotificationDateTime, // ^instead of this
      platformChannelSpecifics,
      payload: 'travel',
      androidAllowWhileIdle: true, // Deliver at exact time
    );

    _retrievePendingNotifications();
    return scheduledNotificationDateTime;
  }

  Future<void> _cancelTravelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(201);
    _retrievePendingNotifications();
  }

  Future<void> _retrievePendingNotifications() async {
    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    setState(() {
      if (pendingNotificationRequests.length > 0) {
        for (var notification in pendingNotificationRequests) {
          if (notification.payload == 'travel') {
            _notificationsPending = true;
          } else {
            _notificationsPending = false;
          }
        }
      } else {
        _notificationsPending = false;
      }
    });
  }

  void _setAlarm() {
    String thisSound;
    if (_alarmSound) {
      thisSound = '';
    } else {
      thisSound = 'silent';
    }
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.HOUR': _travelModel.timeArrival.hour,
        'android.intent.extra.alarm.MINUTES': _travelModel.timeArrival.minute,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.VIBRATE': _alarmVibration,
        'android.intent.extra.alarm.RINGTONE': thisSound,
        'android.intent.extra.alarm.MESSAGE': 'TORN PDA',
      },
    );
    intent.launch();
  }

  void _setTimer() {
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': _travelModel.timeLeft - 20,
        // 'android.intent.extra.alarm.LENGTH': 5,    // DEBUG
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': 'TORN PDA',
      },
    );
    intent.launch();
  }

  Future _restorePreferences() async {
    var userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
    _myCurrentKey = userDetails.myUser.userApiKey;
    if (_myCurrentKey != '') {
      await _fetchTornApi();
    }
    _notificationTitle =
        await SharedPreferencesModel().getTravelNotificationTitle();
    _notificationBody =
        await SharedPreferencesModel().getTravelNotificationBody();
  }

}


class FabOverrideAnimation extends FloatingActionButtonAnimator{
  @override
  Offset getOffset({Offset begin, Offset end, double progress}) {
    return Offset(end.dx,end.dy);
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