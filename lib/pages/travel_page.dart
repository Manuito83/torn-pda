// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/travel/travel_model.dart';
import 'package:torn_pda/pages/travel/foreign_stock_page.dart';
import 'package:torn_pda/pages/travel/travel_options_android.dart';
import 'package:torn_pda/pages/travel/travel_options_ios.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/travel/travel_return_widget.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  TravelPageState createState() => TravelPageState();
}

class TravelPageState extends State<TravelPage> with WidgetsBindingObserver {
  TravelModel _travelModel = TravelModel();
  Timer? _ticker;

  int _apiRetries = 0;

  late ThemeProvider _themeProvider;
  SettingsProvider? _settingsProvider;
  late WebViewProvider _webViewProvider;

  bool _notificationsPending = false;
  bool _alarmSound = false;
  bool _alarmVibration = true;

  late int _travelNotificationAhead;
  late int _travelAlarmAhead;
  late int _travelTimerAhead;

  String? _myCurrentKey = '';
  bool _apiError = true;
  String _errorReason = '';

  Future? _finishedLoadingPreferences;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _finishedLoadingPreferences = _restorePreferences();
    _retrievePendingNotifications();
    _ticker = Timer.periodic(const Duration(seconds: 10), (Timer t) => _updateInformation());
    analytics?.logScreenView(screenName: 'travel');

    routeWithDrawer = true;
    routeName = "travel";
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (Platform.isWindows) return;

    if (state == AppLifecycleState.resumed) {
      _updateInformation();
    }
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider!.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider!.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: Center(
          child: SingleChildScrollView(
            child: FutureBuilder(
              future: _finishedLoadingPreferences,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Column(
                    children: _travelMain(),
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ),
      ),
      floatingActionButtonAnimator: FabOverrideAnimation(),
      floatingActionButtonLocation: MediaQuery.orientationOf(context) == Orientation.landscape
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
                transitionDuration: const Duration(seconds: 1),
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
                onClosed: (ReturnFlagPressed? returnFlag) async {
                  if (returnFlag!.flagPressed) {
                    const url = 'https://www.torn.com/travelagency.php';
                    await context.read<WebViewProvider>().openBrowserPreference(
                          context: context,
                          url: url,
                          browserTapType: returnFlag.shortTap ? BrowserTapType.short : BrowserTapType.long,
                        );
                    _updateInformation();
                  }
                },
                closedColor: Colors.orange,
                openColor: _themeProvider.canvas,
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
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
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
      title: const Text('Travel', style: TextStyle(color: Colors.white)),
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
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.grey[700]!,
              duration: const Duration(milliseconds: 500),
              contentPadding: const EdgeInsets.all(10),
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
          const SizedBox.shrink(),
      ],
    );
  }

  SpeedDial buildSpeedDial() {
    final dials = <SpeedDialChild>[];

    final dialStocks = SpeedDialChild(
      label: 'STOCKS',
      labelStyle: const TextStyle(
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

    final dialNotificationSet = SpeedDialChild(
      child: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.black,
      ),
      backgroundColor: Colors.green,
      onTap: () async {
        await _scheduleNotification().then((value) {
          String? formattedTime = _formatTime(value);
          BotToast.showText(
            text: "Notification set for $formattedTime",
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        });
      },
      label: 'Set notification',
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.green,
    );

    final dialNotificationCancel = SpeedDialChild(
      child: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.black,
      ),
      backgroundColor: Colors.red,
      onTap: () async {
        await _cancelTravelNotification();
        BotToast.showText(
          text: "Notification cancelled!",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          contentColor: Colors.orange[700]!,
          duration: const Duration(seconds: 3),
          contentPadding: const EdgeInsets.all(10),
        );
      },
      label: 'Cancel notification',
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.red,
    );

    final dialAlarm = SpeedDialChild(
      child: const Icon(
        Icons.notifications_none,
        color: Colors.black,
      ),
      backgroundColor: Colors.grey[400],
      onTap: () async {
        await _setAlarm().then((value) {
          String? formattedTime = _formatTime(value);
          BotToast.showText(
            text: 'Alarm set for $formattedTime!',
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        });
      },
      label: 'Set alarm',
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.grey[400],
    );

    final dialTimer = SpeedDialChild(
      child: const Icon(
        Icons.timer,
        color: Colors.black,
      ),
      backgroundColor: Colors.grey[400],
      onTap: () async {
        await _setTimer().then((value) {
          String? formattedTime = _formatTime(value);
          BotToast.showText(
            text: "Timer set for $formattedTime",
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        });
      },
      label: 'Set timer',
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      labelBackgroundColor: Colors.grey[400],
    );

    // We always add stocks
    dials.add(dialStocks);

    if (_travelModel.abroad && _travelModel.timeLeft! > 120) {
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
          MediaQuery.orientationOf(context) == Orientation.portrait ? SpeedDialDirection.up : SpeedDialDirection.left,
      elevation: 2,
      backgroundColor: Colors.transparent,
      overlayColor: Colors.transparent,
      curve: Curves.bounceIn,
      children: dials,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.airplanemode_active,
          color: Colors.black,
          size: 30,
        ),
      ),
    );
  }

  Future<void> _onStocksPageClosed(ReturnFlagPressed? returnFlag) async {
    if (_travelModel.abroad) return;

    if (returnFlag!.flagPressed) {
      const url = 'https://www.torn.com/travelagency.php';

      await context.read<WebViewProvider>().openBrowserPreference(
            context: context,
            url: url,
            browserTapType: returnFlag.shortTap ? BrowserTapType.short : BrowserTapType.long,
          );
      _updateInformation();
    }
  }

  List<Widget> _travelMain() {
    // We detected no api key loaded in preferences
    if (_myCurrentKey == '') {
      return <Widget>[
        const Text(
          'Torn API Key not found!',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
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
              const Padding(
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
              const SizedBox(height: 40),
              const Text("You can still try to visit the website:"),
              const SizedBox(height: 10),
              _travelAgencyButton(),
            ],
          ),
        ),
      ];
    }
    // API was correct: are we traveling or not?
    if (_travelModel.abroad) {
      // If we have reached another country
      if (_travelModel.destination != 'Torn' && _travelModel.timeLeft! < 15) {
        return <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 60),
            child: _flagImage(),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 10),
            child: Text(
              'Arrived in ${_travelModel.destination}!',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TravelReturnWidget(
            destination: _travelModel.destination,
            settingsProvider: _settingsProvider,
            dateTimeArrival: _travelModel.timeArrival,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              child: const Text("Go visit!"),
              onPressed: () async {
                await context.read<WebViewProvider>().openBrowserPreference(
                      context: context,
                      url: "https://www.torn.com",
                      browserTapType: BrowserTapType.short,
                    );
                _updateInformation();
              },
              onLongPress: () async {
                await context.read<WebViewProvider>().openBrowserPreference(
                      context: context,
                      url: "https://www.torn.com",
                      browserTapType: BrowserTapType.long,
                    );
                _updateInformation();
              },
            ),
          ),
        ];
      } else if (_travelModel.timeLeft! > 0 && _travelModel.timeLeft! < 120) {
        // We are about to reach another country
        return <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Image.asset(
              'images/icons/arrivals.png',
              width: 150,
            ),
          ),
          Text(
            'Approaching ${_travelModel.destination}!',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 50),
            child: TravelReturnWidget(
              destination: _travelModel.destination,
              settingsProvider: _settingsProvider,
              dateTimeArrival: _travelModel.timeArrival,
            ),
          ),
          ElevatedButton(
            child: const Icon(Icons.local_airport),
            onPressed: () async {
              await context.read<WebViewProvider>().openBrowserPreference(
                    context: context,
                    url: "https://www.torn.com",
                    browserTapType: BrowserTapType.short,
                  );
              _updateInformation();
            },
            onLongPress: () async {
              await context.read<WebViewProvider>().openBrowserPreference(
                    context: context,
                    url: "https://www.torn.com",
                    browserTapType: BrowserTapType.long,
                  );
              _updateInformation();
            },
          ),
        ];
      } else {
        // We are flying somewhere (another country or TORN)

        // Time formatting
        final formattedTime = TimeFormatter(
          inputTime: _travelModel.timeArrival,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHour;

        // Calculations for travel bar
        final startTime = _travelModel.departed!;
        final endTime = _travelModel.timeStamp!;
        final totalTravelTimeSeconds = endTime - startTime;
        final dateTimeArrival = _travelModel.timeArrival!;
        final timeDifference = dateTimeArrival.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        final String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
        final String diff = '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';

        final double percentage = _getTravelPercentage(totalTravelTimeSeconds);

        return <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 30),
            child: _flagImage(),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(bottom: 30),
            child: Text(
              'TRAVELING',
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
                onTap: () async {
                  await context.read<WebViewProvider>().openBrowserPreference(
                        context: context,
                        url: "https://www.torn.com",
                        browserTapType: BrowserTapType.short,
                      );
                  _updateInformation();
                },
                onLongPress: () async {
                  await context.read<WebViewProvider>().openBrowserPreference(
                        context: context,
                        url: "https://www.torn.com",
                        browserTapType: BrowserTapType.long,
                      );
                  _updateInformation();
                },
                child: LinearPercentIndicator(
                  padding: const EdgeInsets.all(0),
                  barRadius: const Radius.circular(10),
                  isRTL: _travelModel.destination == "Torn" ? true : false,
                  center: Text(
                    diff,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  widgetIndicator: Padding(
                    padding: _travelModel.destination == "Torn"
                        ? const EdgeInsets.only(top: 7, left: 15)
                        : const EdgeInsets.only(top: 7, right: 15),
                    child: Opacity(
                      // Make icon transparent when about to pass over text
                      opacity: percentage < 0.2 || percentage > 0.7 ? 1 : 0.3,
                      child: _travelModel.destination == "Torn"
                          ? Image.asset('images/icons/plane_left.png', color: Colors.blue[900], height: 22)
                          : Image.asset('images/icons/plane_right.png', color: Colors.blue[900], height: 22),
                    ),
                  ),
                  animateFromLastPercent: true,
                  animation: true,
                  width: 180,
                  lineHeight: 18,
                  progressColor: Colors.blue[200],
                  backgroundColor: Colors.grey,
                  percent: percentage,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: TravelReturnWidget(
              destination: _travelModel.destination,
              settingsProvider: _settingsProvider,
              dateTimeArrival: _travelModel.timeArrival,
            ),
          ),
        ];
      }
    } else {
      // We are in Torn, not traveling
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
            const Text(
              'NO TRAVEL DETECTED',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(
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
    final double percentage = 1 - (_travelModel.timeLeft! / totalSeconds);
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
      child: const Text("Travel Agency"),
      onPressed: () async {
        await context.read<WebViewProvider>().openBrowserPreference(
              context: context,
              url: "https://www.torn.com/travelagency.php",
              browserTapType: BrowserTapType.short,
            );
        _updateInformation();
      },
      onLongPress: () async {
        await context.read<WebViewProvider>().openBrowserPreference(
              context: context,
              url: "https://www.torn.com/travelagency.php",
              browserTapType: BrowserTapType.long,
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
      case "Argentina":
        flagFile = 'images/flags/travel/argentina.png';
      case "Canada":
        flagFile = 'images/flags/travel/canada.png';
      case "Cayman Islands":
        flagFile = 'images/flags/travel/cayman_islands.png';
      case "China":
        flagFile = 'images/flags/travel/china.png';
      case "Hawaii":
        flagFile = 'images/flags/travel/hawaii.png';
      case "Japan":
        flagFile = 'images/flags/travel/japan.png';
      case "Mexico":
        flagFile = 'images/flags/travel/mexico.png';
      case "South Africa":
        flagFile = 'images/flags/travel/south_africa.png';
      case "Switzerland":
        flagFile = 'images/flags/travel/switzerland.png';
      case "UAE":
        flagFile = 'images/flags/travel/uae.png';
      case "United Kingdom":
        flagFile = 'images/flags/travel/uk.png';
      default:
        return const SizedBox.shrink();
    }
    return Image(
      image: AssetImage(flagFile),
      width: 150,
    );
  }

  void _updateInformation() {
    final DateTime now = DateTime.now();
    // We avoid calling the API unnecessarily
    if (now.isAfter(_travelModel.timeArrival!.subtract(const Duration(seconds: 120)))) {
      _fetchTornApi();
    }
    _retrievePendingNotifications();

    // Update timeLeft so that the percentage indicator and timer set time work correctly
    if (_travelModel.timeArrival!.isAfter(DateTime.now())) {
      setState(() {
        final diff = _travelModel.timeArrival!.difference(DateTime.now());
        _travelModel.timeLeft = diff.inSeconds;
      });
    }
  }

  Future<void> _fetchTornApi() async {
    final myTravel = await ApiCallsV1.getTravel();
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
    final scheduledNotificationDateTime =
        _travelModel.timeArrival!.subtract(Duration(seconds: _travelNotificationAhead));

    final modifier = await getNotificationChannelsModifiers();
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'Manual travel ${modifier.channelIdModifier} s',
      'Manual travel ${modifier.channelIdModifier} s',
      channelDescription: 'Manual notifications for travel',
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: 'notification_travel',
      color: Colors.blue,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: true,
      sound: 'aircraft_seatbelt.aiff',
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    var notificationTitle = await Prefs().getTravelNotificationTitle();
    var notificationSubtitle = await Prefs().getTravelNotificationBody();

    if (_settingsProvider!.discreetNotifications) {
      notificationTitle = "T";
      notificationSubtitle = " ";
    }

    if (Platform.isAndroid) {
      await assessExactAlarmsPermissionsAndroid(context, _settingsProvider!);
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      201,
      notificationTitle,
      notificationSubtitle,
      //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // DEBUG
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      platformChannelSpecifics,
      payload: 'travel',
      androidScheduleMode: exactAlarmsPermissionAndroid
          ? AndroidScheduleMode.exactAllowWhileIdle // Deliver at exact time (needs permission)
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    // DEBUG
    //print('Notification for travel @ '
    //    '${tz.TZDateTime.from(scheduledNotificationDateTime, tz.local)}');

    _retrievePendingNotifications();
    return scheduledNotificationDateTime;
  }

  Future<void> _cancelTravelNotification() async {
    if (Platform.isWindows) return;

    await flutterLocalNotificationsPlugin.cancel(201);
    _retrievePendingNotifications();
  }

  Future<void> _retrievePendingNotifications() async {
    if (Platform.isWindows) return;

    final pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    var pending = false;
    if (pendingNotificationRequests.isNotEmpty) {
      for (final notification in pendingNotificationRequests) {
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
    final alarmTime = _travelModel.timeArrival!.add(Duration(minutes: -_travelAlarmAhead));
    final int hour = alarmTime.hour;
    final int minute = alarmTime.minute;

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
        'android.intent.extra.alarm.MESSAGE': _settingsProvider!.discreetNotifications ? "T" : 'TORN PDA Travel',
      },
    );
    intent.launch();

    return alarmTime;
  }

  Future<DateTime> _setTimer() async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': _travelModel.timeLeft! - _travelTimerAhead,
        // 'android.intent.extra.alarm.LENGTH': 5,    // DEBUG
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': _settingsProvider!.discreetNotifications ? "T" : 'TORN PDA Travel',
      },
    );
    intent.launch();

    return DateTime.now().add(Duration(seconds: _travelModel.timeLeft! - _travelTimerAhead));
  }

  Future _restorePreferences() async {
    final userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
    _myCurrentKey = userDetails.basic!.userApiKey;
    if (_myCurrentKey != '') {
      await _fetchTornApi();
    }

    _alarmSound = await Prefs().getManualAlarmSound();
    _alarmVibration = await Prefs().getManualAlarmVibration();

    // Ahead timers
    final notificationAhead = await Prefs().getTravelNotificationAhead();
    final alarmAhead = await Prefs().getTravelAlarmAhead();
    final timerAhead = await Prefs().getTravelTimerAhead();

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

  String? _formatTime(DateTime inputTime) {
    return TimeFormatter(
      inputTime: inputTime,
      timeFormatSetting: _settingsProvider!.currentTimeFormat,
      timeZoneSetting: _settingsProvider!.currentTimeZone,
    ).formatHour;
  }

  Future<void> _callBackFromTravelOptions() async {
    await _restorePreferences();
  }
}

class FabOverrideAnimation extends FloatingActionButtonAnimator {
  @override
  Offset getOffset({Offset? begin, required Offset end, double? progress}) {
    return Offset(end.dx, end.dy);
  }

  @override
  Animation<double> getRotationAnimation({required Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }

  @override
  Animation<double> getScaleAnimation({required Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }
}
