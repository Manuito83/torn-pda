// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:android_intent/android_intent.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/profile/arrival_button.dart';
import 'package:torn_pda/widgets/profile/bazaar_status.dart';
import 'package:torn_pda/widgets/profile/foreign_stock_button.dart';
import 'package:torn_pda/widgets/profile/stats_chart.dart';
import 'package:torn_pda/widgets/profile/status_icons_wrap.dart';
import 'package:torn_pda/widgets/revive/nuke_revive_button.dart';
import 'package:torn_pda/widgets/revive/uhc_revive_button.dart';
import 'package:torn_pda/widgets/tct_clock.dart';
import 'package:torn_pda/widgets/travel/travel_return_widget.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/education_model.dart';
import 'package:torn_pda/models/faction/faction_crimes_model.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/models/property_model.dart';
import 'package:torn_pda/pages/profile/profile_options_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/profile/disregard_crime_dialog.dart';
import 'package:torn_pda/widgets/profile/event_icons.dart';
import 'package:torn_pda/widgets/profile/jobpoints_dialog.dart';
import '../main.dart';

enum ProfileNotification {
  travel,
  energy,
  nerve,
  life,
  hospital,
  jail,
  drugs,
  medical,
  booster,
}

enum NotificationType {
  notification,
  alarm,
  timer,
}

extension ProfileNotificationExtension on ProfileNotification {
  String get string {
    switch (this) {
      case ProfileNotification.travel:
        return 'travel';
        break;
      case ProfileNotification.energy:
        return 'energy';
        break;
      case ProfileNotification.nerve:
        return 'nerve';
        break;
      case ProfileNotification.life:
        return 'life';
        break;
      case ProfileNotification.drugs:
        return 'drugs';
        break;
      case ProfileNotification.medical:
        return 'medical';
        break;
      case ProfileNotification.booster:
        return 'booster';
        break;
      default:
        return null;
    }
  }
}

class ProfilePage extends StatefulWidget {
  final Function callBackSection;
  final Function disableTravelSection;

  ProfilePage({
    @required this.callBackSection,
    @required this.disableTravelSection,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  Future _apiFetched;
  bool _apiGoodData = false;
  ApiError _apiError = ApiError();
  int _apiRetries = 0;

  OwnProfileExtended _user;

  DateTime _serverTime;

  Timer _tickerCallApi;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;
  UserDetailsProvider _userProv;
  ShortcutsProvider _shortcutsProv;
  WebViewProvider _webViewProvider;
  UserController _u = Get.put(UserController());

  int _travelNotificationAhead;
  int _travelAlarmAhead;
  int _travelTimerAhead;

  DateTime _travelArrivalTime;
  DateTime _energyNotificationTime;
  DateTime _nerveNotificationTime;
  DateTime _lifeNotificationTime;
  DateTime _drugsNotificationTime;
  DateTime _medicalNotificationTime;
  DateTime _boosterNotificationTime;
  DateTime _hospitalReleaseTime;
  DateTime _jailReleaseTime;

  int _hospitalNotificationAhead;
  int _hospitalTimerAhead;
  int _hospitalAlarmAhead;
  int _jailNotificationAhead;
  int _jailTimerAhead;
  int _jailAlarmAhead;

  bool _travelNotificationsPending = false;
  bool _energyNotificationsPending = false;
  bool _nerveNotificationsPending = false;
  bool _lifeNotificationsPending = false;
  bool _drugsNotificationsPending = false;
  bool _medicalNotificationsPending = false;
  bool _boosterNotificationsPending = false;
  bool _hospitalNotificationsPending = false;
  bool _jailNotificationsPending = false;

  NotificationType _travelNotificationType;
  NotificationType _energyNotificationType;
  NotificationType _nerveNotificationType;
  NotificationType _lifeNotificationType;
  NotificationType _drugsNotificationType;
  NotificationType _medicalNotificationType;
  NotificationType _boosterNotificationType;
  NotificationType _hospitalNotificationType;
  NotificationType _jailNotificationType;

  int _customEnergyTrigger;
  int _customNerveTrigger;

  bool _customEnergyMaxOverride = false;
  bool _customNerveMaxOverride = false;

  IconData _travelNotificationIcon;
  IconData _energyNotificationIcon;
  IconData _nerveNotificationIcon;
  IconData _lifeNotificationIcon;
  IconData _drugsNotificationIcon;
  IconData _medicalNotificationIcon;
  IconData _boosterNotificationIcon;
  IconData _hospitalNotificationIcon;
  IconData _jailNotificationIcon;

  bool _alarmSound;
  bool _alarmVibration;

  bool _miscApiFetchedOnce = false;
  var _miscTick = 0;
  OwnProfileMisc _miscModel;
  TornEducationModel _tornEducationModel;

  var _rentedPropertiesTick = 0;
  var _rentedProperties = 0;
  Widget _rentedPropertiesWidget = SizedBox.shrink();

  // We will first try to get the full crimes if we have AA access, in which case
  // we consider it as Complex. Otherwise, with events, it will be Simple.
  DateTime _ocTime = DateTime.now();
  // Simple OC
  bool _ocSimpleExists = false;
  String _ocSimpleStringFinal = "";
  bool _ocSimpleReady = false;
  // Complex OC
  String _ocFinalStringLong = "";
  String _ocFinalStringShort = "";
  int _ocComplexPeopleNotReady = 0;
  bool _ocComplexReady = false;

  bool _nukeReviveActive = false;
  bool _uhcReviveActive = false;
  bool _warnAboutChains = false;
  bool _shortcutsEnabled = false;
  bool _showHeaderWallet = false;
  bool _showHeaderIcons = false;
  bool _dedicatedTravelCard = false;

  ChainModel _chainModel;

  var _eventsExpController = ExpandableController();
  var _messagesExpController = ExpandableController();
  var _basicInfoExpController = ExpandableController();
  var _networthExpController = ExpandableController();

  int _messagesShowNumber = 25;
  int _eventsShowNumber = 25;

  var _showOne = GlobalKey();

  var _originalSectionOrder = [
    "Shortcuts",
    "Status",
    "Travel",
    "Bars",
    "Cooldowns",
    "Events",
    "Messages",
    "Basic Info",
    "Misc",
    "Networth",
  ];
  var _userSectionOrder = <String>[];

  var _sharedEffStrength = "";
  var _sharedEffSpeed = "";
  var _sharedEffDexterity = "";
  var _sharedEffDefense = "";
  var _sharedEffTotal = "";
  var _sharedJobPoints = "";

  StatsChartTornStats _statsChartModel;
  Future _statsChartDataFetched;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _webViewProvider = context.read<WebViewProvider>();

    _requestIOSPermissions();
    _retrievePendingNotifications();

    _userProv = Provider.of<UserDetailsProvider>(context, listen: false);

    _loadPreferences().whenComplete(() {
      _apiFetched = _fetchApi();
    });

    _startApiTimer();

    analytics.setCurrentScreen(screenName: 'profile');
  }

  void _startApiTimer() {
    _tickerCallApi?.cancel();
    _tickerCallApi = new Timer.periodic(Duration(seconds: 20), (Timer t) {
      _fetchApi();

      // Fetch misc every minute
      if (_miscTick < 2) {
        _miscTick++;
      } else {
        _getMiscCardInfo();
        _miscTick = 0;
      }
    });
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  @override
  void dispose() {
    _tickerCallApi?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _fetchApi();
      _startApiTimer();
      if (_apiGoodData) {
        // We get miscellaneous information when we open the app for those cases where users
        // stay with the app on the background for hours/days and only use the Profile section
        _getMiscCardInfo();
        _getStatsChart();
      }
    } else if (state == AppLifecycleState.paused) {
      _tickerCallApi?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _shortcutsProv = Provider.of<ShortcutsProvider>(context, listen: true);
    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: new Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      floatingActionButton: Stack(
        children: [
          buildSpeedDial(),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: 56,
              height: 56,
            ),
            onLongPress: () async {
              bool lastSessionWasDialog = await Prefs().getWebViewLastSessionUsedDialog();
              _launchBrowser(url: "", dialogRequested: lastSessionWasDialog, recallLastSession: true);
            },
          ),
        ],
      ),
      body: Container(
        color: _themeProvider.canvas,
        child: FutureBuilder(
          future: _apiFetched,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiGoodData) {
                return RefreshIndicator(
                  onRefresh: () async {
                    _fetchApi();
                    _getMiscCardInfo();
                    _miscTick = 0;
                    await Future.delayed(Duration(seconds: 1));
                  },
                  child: BubbleShowcase(
                    // KEEP THIS UNIQUE
                    bubbleShowcaseId: 'profile_showcase',
                    // WILL SHOW IF VERSION CHANGED
                    bubbleShowcaseVersion: 3,
                    showCloseButton: false,
                    doNotReopenOnClose: true,
                    bubbleSlides: [
                      AbsoluteBubbleSlide(
                        positionCalculator: (size) => Position(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          left: 0,
                        ),
                        child: AbsoluteBubbleSlideChild(
                          positionCalculator: (size) => Position(
                            bottom: MediaQuery.of(context).size.height / 2 - 100,
                            left: (size.width) / 2 - 200,
                          ),
                          widget: SpeechBubble(
                            width: 200,
                            nipLocation: NipLocation.BOTTOM,
                            nipHeight: 0,
                            color: Colors.green[800],
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'Did you know?\n\n'
                                'Most links in Torn PDA will open a quick browser with a SHORT TAP and '
                                'a full browser with a LONG PRESS. You decide.\n\n'
                                'You can deactivate this feature in the Settings section.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      RelativeBubbleSlide(
                        shape: Rectangle(spreadRadius: 10),
                        widgetKey: _showOne,
                        child: RelativeBubbleSlideChild(
                          direction: AxisDirection.up,
                          widget: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SpeechBubble(
                              nipLocation: NipLocation.BOTTOM,
                              color: Colors.blue,
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Text(
                                  'Did you know?\n\n'
                                  'Tap any of the bars to launch a browser '
                                  'straight to the gym, crimes or items sections!',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AbsoluteBubbleSlide(
                        positionCalculator: (size) => Position(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          left: 0,
                        ),
                        child: AbsoluteBubbleSlideChild(
                          positionCalculator: (size) => Position(
                            bottom: MediaQuery.of(context).size.height / 2 - 100,
                            left: (size.width) / 2 - 200,
                          ),
                          widget: SpeechBubble(
                            width: 200,
                            nipLocation: NipLocation.BOTTOM,
                            nipHeight: 0,
                            color: Colors.blue,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'There are many other places where you can tap to '
                                'navigate to Torn (e.g. the points or cash icons below)\n\n'
                                'Don\'t forget to visit the TIPS section (see main menu) for other tips '
                                'and tricks!',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _headerIcons(),
                          Column(
                            children: _returnSections(),
                          ),
                          SizedBox(height: 70),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    _fetchApi();
                    await Future.delayed(Duration(seconds: 1));
                  },
                  child: SingleChildScrollView(
                    // Physics so that page can be refreshed even with no scroll
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _shortcutsCarrousel(),
                        ),
                        SizedBox(height: 50),
                        Text(
                          'OOPS!',
                          style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          child: Column(
                            children: [
                              Text(
                                'There was an error: ${_apiError.errorReason}',
                                textAlign: TextAlign.center,
                              ),
                              if (_apiError.errorDetails.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Error details:',
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        _apiError.errorDetails,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 20),
                              Text(
                                'Torn PDA is retrying automatically. '
                                'If you have good Internet connectivity, it might be an issue with Torn\'s API.',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'You can still try to access Torn through shortcuts or the main '
                                'menu icon below.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                );
              }
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Fetching data...'),
                    SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              );
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
      title: Column(
        children: [
          if (_user?.name != null && _user.name.isNotEmpty)
            GestureDetector(
              onTap: () {
                String status = _user.lastAction.status == 'Offline'
                    ? 'Offline (${_user.lastAction.relative.replaceAll(" ago", "")})'
                    : _user.lastAction.status == 'Online'
                        ? 'Online now'
                        : 'Online ${_user.lastAction.relative}';
                BotToast.showText(
                  text: status,
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.blue,
                  duration: Duration(seconds: 3),
                  contentPadding: EdgeInsets.all(10),
                );
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: _user.playerId.toString()));
                BotToast.showText(
                  text: "ID copied to the clipboard!",
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.blue,
                  duration: Duration(seconds: 2),
                  contentPadding: EdgeInsets.all(10),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Text(_user.name),
                        ),
                        _user.lastAction.status == "Offline"
                            ? Icon(Icons.remove_circle, size: 14, color: Colors.grey)
                            : _user.lastAction.status == "Idle"
                                ? Icon(Icons.adjust, size: 14, color: Colors.orange)
                                : Icon(Icons.circle, size: 14, color: Colors.green[400]),
                      ],
                    ),
                  ),
                  Text(
                    "[${_user.playerId}] - Level ${_user.level}",
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          else
            Text("Profile"),
        ],
      ),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        _apiGoodData
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    _launchBrowser(url: "https://www.torn.com/calendar.php", dialogRequested: true);
                  },
                  onLongPress: () {
                    _launchBrowser(url: "https://www.torn.com/calendar.php", dialogRequested: false);
                  },
                  child: const TctClock(),
                ),
              )
            : SizedBox.shrink(),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: _themeProvider.buttonText,
          ),
          onPressed: () async {
            ProfileOptionsReturn newOptions = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileOptionsPage(
                  callBackTimings: _callBackFromNotificationOptions,
                  user: _user,
                  apiValid: _apiGoodData,
                ),
              ),
            );
            widget.disableTravelSection(newOptions.disableTravelSection);
            setState(() {
              _nukeReviveActive = newOptions.nukeReviveEnabled;
              _uhcReviveActive = newOptions.uhcReviveEnabled;
              _warnAboutChains = newOptions.warnAboutChainsEnabled;
              _shortcutsEnabled = newOptions.shortcutsEnabled;
              _showHeaderWallet = newOptions.showHeaderWallet;
              _showHeaderIcons = newOptions.showHeaderIcons;
              _dedicatedTravelCard = newOptions.dedicatedTravelCard;
              _eventsExpController.expanded = newOptions.expandEvents;
              _messagesShowNumber = newOptions.messagesShowNumber;
              _eventsShowNumber = newOptions.eventsShowNumber;
              _messagesExpController.expanded = newOptions.expandMessages;
              _basicInfoExpController.expanded = newOptions.expandBasicInfo;
              _networthExpController.expanded = newOptions.expandNetworth;
              _userSectionOrder = newOptions.sectionSort;
            });
            // If we reactivated faction crimes, they might take up to a minute
            // to appear unless we call them directly
            if (newOptions.oCrimesReactivated) {
              _getFactionCrimes();
            }
            if (_settingsProvider.tornStatsChartDateTime == 0) {
              _getStatsChart();
            }
          },
        )
      ],
    );
  }

  Padding _headerIcons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (_showHeaderWallet)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _cashWallet(dense: true),
                ],
              ),
            ),
          if (_showHeaderIcons)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: StatusIconsWrap(
                user: _user,
                openBrowser: _launchBrowser,
                settingsProvider: _settingsProvider,
              ),
            ),
        ],
      ),
    );
  }

  Widget _shortcutsCarrousel() {
    // Returns Main individual tile
    Widget shortcutTile(Shortcut thisShortcut) {
      Widget tile;
      if (_shortcutsProv.shortcutTile == "both") {
        tile = Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 18,
                child: Image.asset(
                  thisShortcut.iconUrl,
                  width: 16,
                  color: _themeProvider.mainText,
                ),
              ),
              SizedBox(height: 3),
              Flexible(
                child: Container(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 55,
                      child: Text(
                        thisShortcut.nickname.toUpperCase(),
                        style: TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (_shortcutsProv.shortcutTile == "icon") {
        tile = SizedBox(
          height: 18,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Image.asset(
              thisShortcut.iconUrl,
              width: 16,
              color: _themeProvider.mainText,
            ),
          ),
        );
      } else {
        // Only text
        tile = Padding(
          padding: EdgeInsets.all(2),
          child: SizedBox(
            width: 55,
            child: Center(
              child: Container(
                child: Text(
                  thisShortcut.nickname.toUpperCase(),
                  style: TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ),
        );
      }

      return InkWell(
        onLongPress: () {
          _launchBrowser(url: thisShortcut.url, dialogRequested: false);
        },
        onTap: () async {
          _launchBrowser(url: thisShortcut.url, dialogRequested: true);
        },
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: thisShortcut.color, width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          elevation: 2,
          child: tile,
        ),
      );
    }

    // Main menu, returns either slidable list or wrap (grid)
    Widget shortcutMenu() {
      if (_shortcutsProv.shortcutMenu == "carousel") {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _shortcutsProv.activeShortcuts.length,
          itemBuilder: (context, index) {
            var thisShortcut = _shortcutsProv.activeShortcuts[index];
            return shortcutTile(thisShortcut);
          },
        );
      } else {
        var wrapItems = <Widget>[];
        for (var thisShortcut in _shortcutsProv.activeShortcuts) {
          double h = 60;
          double w = 70;
          if (_shortcutsProv.shortcutMenu == "grid") {
            if (_shortcutsProv.shortcutTile == "icon") {
              h = 40;
              w = 40;
            }
            if (_shortcutsProv.shortcutTile == "text") {
              h = 40;
              w = 70;
            }
          }
          wrapItems.add(
            Container(height: h, width: w, child: shortcutTile(thisShortcut)),
          );
        }
        return Wrap(alignment: WrapAlignment.center, children: wrapItems);
      }
    }

    return SizedBox(
      // We only need a SizedBox height for the listView, the wrap will expand
      height: _shortcutsProv.shortcutMenu == "grid"
          ? null
          : _shortcutsProv.shortcutTile == 'both'
              ? 60
              : 40,
      child: _shortcutsProv.activeShortcuts.length == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No shortcuts configured, add some!',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Tap the settings icon to configure',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
              ],
            )
          : shortcutMenu(),
    );
  }

  Card _playerStatus() {
    Widget descriptionWidget() {
      if (_user.status.state == 'Okay') {
        return SizedBox.shrink();
      } else {
        String descriptionText = _user.status.description;

        // Is there a detailed description? Add it.
        if (_user.status.details != '') {
          descriptionText += '- ${_user.status.details}';
        }

        // Causing player ID (jailed of hospitalized the user)
        RegExp expHtml = RegExp(r"<[^>]*>");
        var matches = expHtml.allMatches(descriptionText).map((m) => m[0]);
        String causingId = '';
        if (matches.length > 0) {
          RegExp expId = RegExp(r"(?!XID=)([0-9])+");
          var id = expId.allMatches(_user.status.details).map((m) => m[0]);
          causingId = id.first;
        }

        // If there is a player causing it, add a span to click and go to the
        // profile, otherwise return just the description text
        Widget detailsWidget;
        if (_user.status.details != '') {
          if (causingId != '') {
            detailsWidget = GestureDetector(
              child: RichText(
                text: new TextSpan(
                  children: [
                    new TextSpan(
                      text: HtmlParser.fix(descriptionText),
                      style: new TextStyle(color: _themeProvider.mainText),
                    ),
                    new TextSpan(
                      text: ' (',
                      style: new TextStyle(color: _themeProvider.mainText),
                    ),
                    new TextSpan(
                      text: 'profile',
                      style: new TextStyle(color: Colors.blue),
                    ),
                    new TextSpan(
                      text: ')',
                      style: new TextStyle(color: _themeProvider.mainText),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _launchBrowser(
                    url: 'https://www.torn.com/profiles.php?'
                        'XID=$causingId',
                    dialogRequested: true);
              },
              onLongPress: () {
                _launchBrowser(
                    url: 'https://www.torn.com/profiles.php?'
                        'XID=$causingId',
                    dialogRequested: false);
              },
            );
          } else {
            detailsWidget = Text(descriptionText);
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 60,
                  child: Text('Details: '),
                ),
                Flexible(
                  child: detailsWidget,
                ),
              ],
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      }
    }

    Color stateColor;
    if (_user.status.color == 'red') {
      stateColor = Colors.red;
    } else if (_user.status.color == 'green') {
      stateColor = Colors.green;
    } else if (_user.status.color == 'blue') {
      stateColor = Colors.blue;
    }

    Widget stateBall() {
      return Padding(
        padding: EdgeInsets.only(left: 8),
        child: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle, border: Border.all(color: Colors.black)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text('Status: '),
                          ),
                          Text(_user.status.state),
                          stateBall(),
                        ],
                      ),
                      if (_user.status.color == 'red' && _user.status.state == "Hospital")
                        _notificationIcon(ProfileNotification.hospital),
                      if (_user.status.color == 'red' && _user.status.state == "Jail")
                        _notificationIcon(ProfileNotification.hospital),
                    ],
                  ),
                  BazaarStatusCard(
                    // Careful, in this card we mixed sync with async items, so the miscModel can still be null
                    bazaarModel: _miscModel?.bazaar,
                    launchBrowser: _launchBrowser,
                  ),
                  if (!_dedicatedTravelCard) _travelWidget(),
                  descriptionWidget(),
                  if (_user.status.state == 'Hospital' && _nukeReviveActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 13, top: 10),
                      child: NukeReviveButton(
                        themeProvider: _themeProvider,
                        user: _user,
                        webViewProvider: _webViewProvider,
                        settingsProvider: _settingsProvider,
                      ),
                    ),
                  if (_user.status.state == 'Hospital' && _uhcReviveActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 13, top: 10),
                      child: UhcReviveButton(
                        themeProvider: _themeProvider,
                        user: _user,
                        webViewProvider: _webViewProvider,
                        settingsProvider: _settingsProvider,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  double _getTravelPercentage(int totalSeconds) {
    double percentage = 1 - (_user.travel.timeLeft / totalSeconds);
    if (percentage > 1) {
      return 1;
    } else if (percentage < 0) {
      return 0;
    } else {
      return percentage;
    }
  }

  Widget _travelWidget() {
    if (_user.status.state == 'Traveling') {
      var startTime = _user.travel.departed;
      var endTime = _user.travel.timestamp;
      var totalTravelTimeSeconds = endTime - startTime;

      var dateTimeArrival = DateTime.fromMillisecondsSinceEpoch(_user.travel.timestamp * 1000);
      var timeDifference = dateTimeArrival.difference(DateTime.now());
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
      String diff = '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';

      var formattedTime = TimeFormatter(
        inputTime: dateTimeArrival,
        timeFormatSetting: _settingsProvider.currentTimeFormat,
        timeZoneSetting: _settingsProvider.currentTimeZone,
      ).formatHour;

      double percentage = _getTravelPercentage(totalTravelTimeSeconds);
      String ballAssetLocation = _flagBallAsset();

      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () => _launchBrowser(url: 'https://www.torn.com', dialogRequested: false),
                      onTap: () {
                        _launchBrowser(url: 'https://www.torn.com', dialogRequested: true);
                      },
                      child: LinearPercentIndicator(
                        padding: null,
                        barRadius: Radius.circular(10),
                        isRTL: _user.travel.destination == "Torn" ? true : false,
                        center: Text(
                          diff,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        widgetIndicator: Padding(
                          padding: _user.travel.destination == "Torn"
                              ? const EdgeInsets.only(top: 7, left: 15)
                              : const EdgeInsets.only(top: 7, right: 15),
                          child: Opacity(
                            // Make icon transparent when about to pass over text
                            opacity: percentage < 0.2 || percentage > 0.7 ? 1 : 0.3,
                            child: _user.travel.destination == "Torn"
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
                    if (ballAssetLocation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Image.asset(ballAssetLocation, height: 22),
                      ),
                  ],
                ),
                if (!_dedicatedTravelCard) _notificationIcon(ProfileNotification.travel),
              ],
            ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text('Arriving in ${_user.travel.destination} at $formattedTime'),
                    ),
                  ],
                ),
                TravelReturnWidget(
                  destination: _user.travel.destination,
                  settingsProvider: _settingsProvider,
                  dateTimeArrival: dateTimeArrival,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Card _travelCard() {
    Widget header;
    if (_user.status.state == "Traveling") {
      header = _travelWidget();
    } else if (_user.status.state == "Abroad") {
      header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  primary: _themeProvider.cardColor,
                  side: BorderSide(
                    width: 2.0,
                    color: Colors.blueGrey,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _flagImage(),
                      SizedBox(width: 6),
                      Column(
                        children: [
                          Text(
                            "VISIT",
                            style: TextStyle(
                              fontSize: 8,
                              color: _themeProvider.mainText,
                            ),
                          ),
                          Text(
                            _user.travel.destination.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              color: _themeProvider.mainText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                onLongPress: () {
                  _launchBrowser(url: 'https://www.torn.com', dialogRequested: false);
                },
                onPressed: () async {
                  var url = 'https://www.torn.com';
                  _launchBrowser(url: url, dialogRequested: true);
                },
              ),
              SizedBox(width: 20),
              ForeignStockButton(
                userProv: _userProv,
                settingsProv: _settingsProvider,
                launchBrowser: _launchBrowser,
                updateCallback: _updateCallback,
              ),
            ],
          ),
          TravelReturnWidget(
            destination: _user.travel.destination,
            settingsProvider: _settingsProvider,
            dateTimeArrival: DateTime.now(),
          ),
        ],
      );
    } else {
      Widget ocStatus = SizedBox.shrink();
      if ((_ocFinalStringShort.isNotEmpty || _ocSimpleExists) && _ocTime.difference(DateTime.now()).inHours < 10) {
        if (!_ocSimpleExists) {
          ocStatus = Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              _ocFinalStringShort,
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
              ),
            ),
          );
        } else if (_ocSimpleExists) {
          ocStatus = Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _ocSimpleStringFinal,
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                child: Icon(
                  MdiIcons.closeCircleOutline,
                  size: 16,
                  color: Colors.orange[800],
                ),
                onTap: () {
                  return showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return DisregardCrimeDialog(
                        disregardCallback: _disregardCrimeCallback,
                      );
                    },
                  );
                },
              ),
            ],
          );
        }
      }

      header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  primary: _themeProvider.cardColor,
                  side: BorderSide(
                    width: 2.0,
                    color: Colors.blueGrey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.airport,
                      size: 22,
                      color: _themeProvider.mainText,
                    ),
                    SizedBox(width: 6),
                    Column(
                      children: [
                        Text(
                          "TRAVEL",
                          style: TextStyle(
                            fontSize: 8,
                            color: _themeProvider.mainText,
                          ),
                        ),
                        Text(
                          "AGENCY",
                          style: TextStyle(
                            fontSize: 8,
                            color: _themeProvider.mainText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onLongPress: () {
                  _launchBrowser(url: 'https://www.torn.com/travelagency.php', dialogRequested: false);
                },
                onPressed: () async {
                  var url = 'https://www.torn.com/travelagency.php';
                  _launchBrowser(url: url, dialogRequested: true);
                },
              ),
              SizedBox(width: 20),
              ForeignStockButton(
                userProv: _userProv,
                settingsProv: _settingsProvider,
                launchBrowser: _launchBrowser,
                updateCallback: _updateCallback,
              ),
            ],
          ),
          ocStatus,
        ],
      );
    }

    Widget alertsButton;
    if (Platform.isAndroid) {
      alertsButton = Row(
        children: [
          RawMaterialButton(
            onPressed: null,
            elevation: 2.0,
            constraints: BoxConstraints.expand(width: 32, height: 32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            child: _notificationIcon(
              ProfileNotification.travel,
              size: 20,
              forcedTravelIcon: NotificationType.notification,
            ),
            padding: EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: _travelNotificationsPending ? Colors.green : Colors.blueGrey,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          SizedBox(width: 10),
          RawMaterialButton(
            onPressed: null,
            elevation: 2.0,
            constraints: BoxConstraints.expand(width: 32, height: 32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            child: _notificationIcon(
              ProfileNotification.travel,
              size: 20,
              forcedTravelIcon: NotificationType.alarm,
            ),
            padding: EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.blueGrey,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          SizedBox(width: 10),
          RawMaterialButton(
            onPressed: null,
            elevation: 2.0,
            constraints: BoxConstraints.expand(width: 32, height: 32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            child: _notificationIcon(
              ProfileNotification.travel,
              size: 20,
              forcedTravelIcon: NotificationType.timer,
            ),
            padding: EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.blueGrey,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ],
      );
    } else if (Platform.isIOS) {
      alertsButton = RawMaterialButton(
        onPressed: null,
        elevation: 2.0,
        constraints: BoxConstraints.expand(width: 32, height: 32),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fillColor: _themeProvider.navSelected,
        child: _notificationIcon(
          ProfileNotification.travel,
          size: 20,
        ),
        padding: EdgeInsets.all(0),
        shape: CircleBorder(),
      );
    }

    Widget buttonsRow;
    if (_user.status.state == "Traveling") {
      if (_user.travel.timeLeft > 180) {
        buttonsRow = Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            children: [
              ForeignStockButton(
                userProv: _userProv,
                settingsProv: _settingsProvider,
                launchBrowser: _launchBrowser,
                updateCallback: _updateCallback,
              ),
              SizedBox(width: 20),
              alertsButton,
            ],
          ),
        );
      } else {
        buttonsRow = Padding(
          padding: const EdgeInsets.only(top: 14),
          child: ArrivalButton(
            themeProvider: _themeProvider,
            user: _user,
            settingsProv: _settingsProvider,
            userProv: _userProv,
            launchBrowser: _launchBrowser,
            updateCallback: _updateCallback,
          ),
        );
      }
    } else {
      buttonsRow = SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'TRAVEL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            header,
            buttonsRow,
          ],
        ),
      ),
    );
  }

  Card _basicBars() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'BARS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  if (_warnAboutChains && _chainModel.chain.current > 10 && _chainModel.chain.cooldown == 0)
                    Row(
                      children: [
                        SizedBox(width: 65),
                        Text(
                          'CHAINING (${_chainModel.chain.current}/${_chainModel.chain.max})',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox.shrink(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 50,
                            child: Text('Energy'),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            key: _showOne,
                            onLongPress: () {
                              _launchBrowser(url: 'https://www.torn.com/gym.php', dialogRequested: false);
                            },
                            onTap: () async {
                              _launchBrowser(url: 'https://www.torn.com/gym.php', dialogRequested: true);
                            },
                            child: LinearPercentIndicator(
                              padding: null,
                              barRadius: Radius.circular(10),
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.green,
                              backgroundColor: Colors.grey,
                              center: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  '${_user.energy.current}/${_user.energy.maximum}',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              percent: _user.energy.current / _user.energy.maximum > 1.0
                                  ? 1.0
                                  : _user.energy.current / _user.energy.maximum,
                            ),
                          ),
                          if (_warnAboutChains && _chainModel.chain.current > 10 && _chainModel.chain.cooldown == 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: GestureDetector(
                                onTap: () {
                                  // Open chaining section
                                  widget.callBackSection(2);
                                },
                                child: Icon(
                                  MdiIcons.linkVariant,
                                  color: Colors.blue,
                                  size: 22,
                                ),
                              ),
                            )
                          else
                            SizedBox.shrink(),
                        ],
                      ),
                      _notificationIcon(ProfileNotification.energy),
                    ],
                  ),
                  _barTime('energy'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 50,
                            child: Text('Nerve'),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onLongPress: () {
                              _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', dialogRequested: false);
                            },
                            onTap: () async {
                              _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', dialogRequested: true);
                            },
                            child: LinearPercentIndicator(
                              padding: null,
                              barRadius: Radius.circular(10),
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.redAccent,
                              backgroundColor: Colors.grey,
                              center: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  '${_user.nerve.current}/${_user.nerve.maximum}',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              percent: _user.nerve.current / _user.nerve.maximum > 1.0
                                  ? 1.0
                                  : _user.nerve.current / _user.nerve.maximum,
                            ),
                          ),
                        ],
                      ),
                      _notificationIcon(ProfileNotification.nerve),
                    ],
                  ),
                  _barTime('nerve'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 50,
                        child: Text('Happy'),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onLongPress: () {
                          _launchBrowser(url: 'https://www.torn.com/item.php#candy-items', dialogRequested: false);
                        },
                        onTap: () async {
                          _launchBrowser(url: 'https://www.torn.com/item.php#candy-items', dialogRequested: true);
                        },
                        child: LinearPercentIndicator(
                          padding: null,
                          barRadius: Radius.circular(10),
                          width: 150,
                          lineHeight: 20,
                          progressColor: Colors.amber,
                          backgroundColor: Colors.grey,
                          center: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              '${_user.happy.current}/${_user.happy.maximum}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          percent: _user.happy.current / _user.happy.maximum > 1.0
                              ? 1.0
                              : _user.happy.current / _user.happy.maximum,
                        ),
                      ),
                    ],
                  ),
                  _barTime('happy'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(
                            width: 50,
                            child: Text('Life'),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onLongPress: () {
                              if (_settingsProvider.lifeBarOption == "ask") {
                                _showLifeBarDialog(context, longPress: true);
                              } else if (_settingsProvider.lifeBarOption == "inventory") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/item.php#medical-items',
                                  dialogRequested: false,
                                );
                              } else if (_settingsProvider.lifeBarOption == "faction") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical',
                                  dialogRequested: false,
                                );
                              }
                            },
                            onTap: () async {
                              if (_settingsProvider.lifeBarOption == "ask") {
                                _showLifeBarDialog(context, longPress: false);
                              } else if (_settingsProvider.lifeBarOption == "inventory") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/item.php#medical-items',
                                  dialogRequested: true,
                                );
                              } else if (_settingsProvider.lifeBarOption == "faction") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical',
                                  dialogRequested: true,
                                );
                              }
                            },
                            child: LinearPercentIndicator(
                              padding: null,
                              barRadius: Radius.circular(10),
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.blue,
                              backgroundColor: Colors.grey,
                              center: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  '${_user.life.current}/${_user.life.maximum}',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              percent: _user.life.current / _user.life.maximum > 1.0
                                  ? 1.0
                                  : _user.life.current / _user.life.maximum,
                            ),
                          ),
                          _user.status.state == "Hospital"
                              ? Icon(
                                  Icons.local_hospital,
                                  size: 20,
                                  color: Colors.red,
                                )
                              : SizedBox.shrink(),
                        ],
                      ),
                      _notificationIcon(ProfileNotification.life),
                    ],
                  ),
                  _barTime('life'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barTime(String type) {
    switch (type) {
      case "energy":
        if (_user.energy.fulltime == 0 || _user.energy.current > _user.energy.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.energy.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).formatHour;
          return Row(
            children: <Widget>[
              SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
        break;
      case "nerve":
        if (_user.nerve.fulltime == 0 || _user.nerve.current > _user.nerve.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.nerve.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).formatHour;
          return Row(
            children: <Widget>[
              SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
        break;
      case "happy":
        if (_user.happy.fulltime == 0 || _user.happy.current > _user.happy.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.happy.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).formatHour;
          return Row(
            children: <Widget>[
              SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
        break;
      case "life":
        if (_user.life.fulltime == 0 || _user.life.current > _user.life.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.life.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).formatHour;
          return Row(
            children: <Widget>[
              SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
        break;
      default:
        return SizedBox.shrink();
    }
  }

  Widget _notificationIcon(
    ProfileNotification profileNotification, {
    double size = 22,
    NotificationType forcedTravelIcon,
  }) {
    int secondsToGo = 0;
    bool percentageError = false;
    bool notificationsPending;
    String notificationSetString;
    String notificationCancelString;
    String alarmSetString;
    String timerSetString;
    NotificationType notificationType;
    IconData notificationIcon;

    switch (profileNotification) {
      case ProfileNotification.travel:
        _travelArrivalTime = new DateTime.fromMillisecondsSinceEpoch(_user.travel.timestamp * 1000);
        var timeDifference = _travelArrivalTime.difference(DateTime.now());
        secondsToGo = timeDifference.inSeconds;
        notificationsPending = _travelNotificationsPending;

        var notificationTime = _travelArrivalTime.add(Duration(seconds: -_travelNotificationAhead));
        var formattedTimeNotification = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        var alarmTime = _travelArrivalTime.add(Duration(minutes: -_travelAlarmAhead));
        var formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        var timerTime = _travelArrivalTime.add(Duration(seconds: -_travelTimerAhead));
        var formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        notificationSetString = 'Travel notification set for $formattedTimeNotification';
        notificationCancelString = 'Travel notification cancelled!';
        alarmSetString = 'Travel alarm set for $formattedTimeAlarm';
        timerSetString = 'Travel timer set for $formattedTimeTimer';

        if (forcedTravelIcon == null) {
          notificationType = _travelNotificationType;
          notificationIcon = _travelNotificationIcon;
        } else {
          notificationType = forcedTravelIcon;
          switch (forcedTravelIcon) {
            case NotificationType.notification:
              notificationIcon = Icons.chat_bubble_outline;
              break;
            case NotificationType.alarm:
              notificationIcon = Icons.notifications_none;
              break;
            case NotificationType.timer:
              notificationIcon = Icons.timer;
              break;
          }
        }

        break;

      case ProfileNotification.energy:
        if (_user.energy.current < _user.energy.maximum) {
          if (_customEnergyTrigger < _user.energy.maximum) {
            var energyToGo = _customEnergyTrigger - _user.energy.current;
            var energyTicksToGo = energyToGo / _user.energy.increment;
            // If there is more than 1 tick to go, we multiply ticks times
            // the interval, and decrease for the current tick consumed
            if (energyTicksToGo > 1) {
              var consumedTick = _user.energy.interval - _user.energy.ticktime;
              secondsToGo = (energyTicksToGo * _user.energy.interval - consumedTick).floor();
            }
            // If we are in the current tick or example in the next one,
            // we just take into consideration the tick time left
            else if (energyTicksToGo > 0 && energyTicksToGo <= 1) {
              secondsToGo = _user.energy.ticktime;
            } else {
              // We'll offer the user the option to go with full time
              secondsToGo = _user.energy.fulltime;
              percentageError = true;
            }
          } else {
            secondsToGo = _user.energy.fulltime;
          }

          _energyNotificationTime = DateTime.now().add(Duration(seconds: secondsToGo));
          var formattedTime = TimeFormatter(
            inputTime: _energyNotificationTime,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).formatHour;

          if (!percentageError) {
            _customEnergyMaxOverride = false;
            Prefs().setEnergyPercentageOverride(false);
            notificationSetString = 'Energy notification set for $formattedTime (E$_customEnergyTrigger)';
            alarmSetString = 'Energy alarm set for $formattedTime (E$_customEnergyTrigger)';
            timerSetString = 'Energy timer set for $formattedTime (E$_customEnergyTrigger)';
          } else {
            _customEnergyMaxOverride = true;
            Prefs().setEnergyPercentageOverride(true);
            notificationSetString = 'You are already above your chosen value '
                '(E$_customEnergyTrigger), notification set for full energy at $formattedTime';
            alarmSetString = 'You are already above your chosen value '
                '(E$_customEnergyTrigger), alarm set for full energy at $formattedTime';
            timerSetString = 'You are already above your chosen value '
                '(E$_customEnergyTrigger), timer set for full energy at $formattedTime';
          }

          notificationCancelString = 'Energy notification cancelled!';
          notificationType = _energyNotificationType;
          notificationIcon = _energyNotificationIcon;
          notificationsPending = _energyNotificationsPending;
        }
        break;

      case ProfileNotification.nerve:
        if (_user.nerve.current < _user.nerve.maximum) {
          if (_customNerveTrigger < _user.nerve.maximum) {
            var nerveToGo = _customNerveTrigger - _user.nerve.current;
            var nerveTicksToGo = nerveToGo / _user.nerve.increment;
            // If there is more than 1 tick to go, we multiply ticks times
            // the interval, and decrease for the current tick consumed
            if (nerveTicksToGo > 1) {
              var consumedTick = _user.nerve.interval - _user.nerve.ticktime;
              secondsToGo = (nerveTicksToGo * _user.nerve.interval - consumedTick).floor();
            }
            // If we are in the current tick or example in the next one,
            // we just take into consideration the tick time left
            else if (nerveTicksToGo > 0 && nerveTicksToGo <= 1) {
              secondsToGo = _user.nerve.ticktime;
            } else {
              // We'll offer the user the option to go with full time
              secondsToGo = _user.nerve.fulltime;
              percentageError = true;
            }
          } else {
            secondsToGo = _user.nerve.fulltime;
          }

          _nerveNotificationTime = DateTime.now().add(Duration(seconds: secondsToGo));
          var formattedTime = TimeFormatter(
            inputTime: _nerveNotificationTime,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).formatHour;

          if (!percentageError) {
            _customNerveMaxOverride = false;
            Prefs().setNervePercentageOverride(false);
            notificationSetString = 'Nerve notification set for $formattedTime (N$_customNerveTrigger)';
            alarmSetString = 'Nerve alarm set for $formattedTime (N$_customNerveTrigger)';
            timerSetString = 'Nerve timer set for $formattedTime (N$_customNerveTrigger)';
          } else {
            _customNerveMaxOverride = true;
            Prefs().setNervePercentageOverride(true);
            notificationSetString = 'You are already above your chosen value '
                '(N$_customNerveTrigger), notification set for full nerve at $formattedTime';
            alarmSetString = 'You are already above your chosen value '
                '(N$_customNerveTrigger), alarm set for full nerve at $formattedTime';
            timerSetString = 'You are already above your chosen value '
                '(N$_customNerveTrigger), timer set for full nerve at $formattedTime';
          }

          notificationCancelString = 'Nerve notification cancelled!';
          notificationType = _nerveNotificationType;
          notificationIcon = _nerveNotificationIcon;
          notificationsPending = _nerveNotificationsPending;
        }
        break;

      case ProfileNotification.life:
        secondsToGo = _user.life.fulltime;
        notificationsPending = _lifeNotificationsPending;
        _lifeNotificationTime = DateTime.now().add(Duration(seconds: _user.life.fulltime));
        var formattedTime = TimeFormatter(
          inputTime: _lifeNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;
        notificationSetString = 'Life notification set for $formattedTime';
        notificationCancelString = 'Life notification cancelled!';
        alarmSetString = 'Life alarm set for $formattedTime';
        timerSetString = 'Life timer set for $formattedTime';
        notificationType = _lifeNotificationType;
        notificationIcon = _lifeNotificationIcon;
        break;

      case ProfileNotification.drugs:
        secondsToGo = _user.cooldowns.drug;
        notificationsPending = _drugsNotificationsPending;
        _drugsNotificationTime = DateTime.now().add(Duration(seconds: _user.cooldowns.drug));
        var formattedTime = TimeFormatter(
          inputTime: _drugsNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;
        notificationSetString = 'Drugs cooldown notification set for $formattedTime';
        notificationCancelString = 'Drugs cooldown notification cancelled!';
        alarmSetString = 'Drugs cooldown alarm set for $formattedTime';
        timerSetString = 'Drugs cooldown timer set for $formattedTime';
        notificationType = _drugsNotificationType;
        notificationIcon = _drugsNotificationIcon;
        break;

      case ProfileNotification.medical:
        secondsToGo = _user.cooldowns.medical;
        notificationsPending = _medicalNotificationsPending;
        _medicalNotificationTime = DateTime.now().add(Duration(seconds: _user.cooldowns.medical));
        var formattedTime = TimeFormatter(
          inputTime: _medicalNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;
        notificationSetString = 'Medical cooldown notification set for $formattedTime';
        notificationCancelString = 'Medical cooldown notification cancelled!';
        alarmSetString = 'Medical cooldown alarm set for $formattedTime';
        timerSetString = 'Medical cooldown timer set for $formattedTime';
        notificationType = _medicalNotificationType;
        notificationIcon = _medicalNotificationIcon;
        break;

      case ProfileNotification.booster:
        secondsToGo = _user.cooldowns.booster;
        notificationsPending = _boosterNotificationsPending;
        _boosterNotificationTime = DateTime.now().add(Duration(seconds: _user.cooldowns.booster));
        var formattedTime = TimeFormatter(
          inputTime: _boosterNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;
        notificationSetString = 'Booster cooldown notification set for $formattedTime';
        notificationCancelString = 'Booster cooldown notification cancelled!';
        alarmSetString = 'Booster cooldown alarm set for $formattedTime';
        timerSetString = 'Booster cooldown timer set for $formattedTime';
        notificationType = _boosterNotificationType;
        notificationIcon = _boosterNotificationIcon;
        break;

      case ProfileNotification.hospital:
        _hospitalReleaseTime = DateTime.fromMillisecondsSinceEpoch(_user.status.until * 1000);
        secondsToGo = _hospitalReleaseTime.difference(DateTime.now()).inSeconds;
        notificationsPending = _hospitalNotificationsPending;

        var notificationTime = _hospitalReleaseTime.add(Duration(seconds: -_hospitalNotificationAhead));
        var formattedTime = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        var alarmTime = _hospitalReleaseTime.add(Duration(seconds: -_hospitalNotificationAhead));
        var formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        var timerTime = _hospitalReleaseTime.add(Duration(seconds: -_hospitalNotificationAhead));
        var formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        notificationSetString = 'Hospital release notification set for $formattedTime';
        notificationCancelString = 'Hospital release notification cancelled!';
        alarmSetString = 'Hospital release alarm set for $formattedTimeAlarm';
        timerSetString = 'Hospital release timer set for $formattedTimeTimer';
        notificationType = _hospitalNotificationType;
        notificationIcon = _hospitalNotificationIcon;
        break;

      case ProfileNotification.jail:
        _jailReleaseTime = DateTime.fromMillisecondsSinceEpoch(_user.status.until * 1000);
        secondsToGo = _jailReleaseTime.difference(DateTime.now()).inSeconds;
        notificationsPending = _jailNotificationsPending;

        var notificationTime = _jailReleaseTime.add(Duration(seconds: -_jailNotificationAhead));
        var formattedTime = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        var alarmTime = _jailReleaseTime.add(Duration(seconds: -_jailNotificationAhead));
        var formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        var timerTime = _jailReleaseTime.add(Duration(seconds: -_jailNotificationAhead));
        var formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).formatHour;

        notificationSetString = 'Jail release notification set for $formattedTime';
        notificationCancelString = 'Jail release notification cancelled!';
        alarmSetString = 'Jail release alarm set for $formattedTimeAlarm';
        timerSetString = 'Jail release timer set for $formattedTimeTimer';
        notificationType = _jailNotificationType;
        notificationIcon = _jailNotificationIcon;
        break;
    }

    if (secondsToGo == 0 && !percentageError) {
      return SizedBox.shrink();
    } else {
      Color thisColor;
      if (notificationsPending && notificationType == NotificationType.notification) {
        thisColor = Colors.green;
      } else {
        if (percentageError) {
          thisColor = Colors.red[400].withOpacity(0.7);
        } else {
          thisColor = _themeProvider.mainText;
        }
      }

      return InkWell(
        splashColor: Colors.transparent,
        child: Icon(
          notificationIcon,
          size: size,
          color: thisColor,
        ),
        onTap: () {
          switch (notificationType) {
            case NotificationType.notification:
              if (!notificationsPending) {
                _scheduleNotification(profileNotification);
                BotToast.showText(
                  text: notificationSetString,
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: percentageError ? Colors.red : Colors.green,
                  duration: Duration(seconds: 5),
                  contentPadding: EdgeInsets.all(10),
                );
              } else if (notificationsPending && notificationType == NotificationType.notification) {
                _cancelNotifications(profileNotification);
                BotToast.showText(
                  text: notificationCancelString,
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.orange[800],
                  duration: Duration(seconds: 5),
                  contentPadding: EdgeInsets.all(10),
                );
              }
              break;
            case NotificationType.alarm:
              _setAlarm(profileNotification);
              BotToast.showText(
                text: alarmSetString,
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: percentageError ? Colors.red : Colors.green,
                duration: Duration(seconds: 5),
                contentPadding: EdgeInsets.all(10),
              );
              break;
            case NotificationType.timer:
              _setTimer(profileNotification);
              BotToast.showText(
                text: timerSetString,
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: percentageError ? Colors.red : Colors.green,
                duration: Duration(seconds: 5),
                contentPadding: EdgeInsets.all(10),
              );
              break;
          }
        },
      );
    }
  }

  Card _coolDowns() {
    Widget cooldownItems;
    if (_user.cooldowns.drug > 0 || _user.cooldowns.booster > 0 || _user.cooldowns.medical > 0) {
      cooldownItems = Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          children: <Widget>[
            _user.cooldowns.drug > 0
                ? Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: [
                                _drugIcon(),
                                SizedBox(width: 10),
                                _drugCounter(),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _notificationIcon(ProfileNotification.drugs),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                : SizedBox.shrink(),
            _user.cooldowns.medical > 0
                ? Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: [
                                _medicalIcon(),
                                SizedBox(width: 10),
                                _medicalCounter(),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _notificationIcon(ProfileNotification.medical),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                : SizedBox.shrink(),
            _user.cooldowns.booster > 0
                ? Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: [
                                _boosterIcon(),
                                SizedBox(width: 10),
                                _boosterCounter(),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _notificationIcon(ProfileNotification.booster),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                : SizedBox.shrink(),
          ],
        ),
      );
    } else {
      cooldownItems = Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text("Nothing to report, well done!"),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'COOLDOWNS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            cooldownItems,
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Image _drugIcon() {
    // 0-10 minutes
    if (_user.cooldowns.drug > 0 && _user.cooldowns.drug < 600) {
      return Image.asset('images/icons/cooldowns/drug1.png', width: 20);
    } // 10-60 minutes
    else if (_user.cooldowns.drug >= 600 && _user.cooldowns.drug < 3600) {
      return Image.asset('images/icons/cooldowns/drug2.png', width: 20);
    } // 1-2 hours
    else if (_user.cooldowns.drug >= 3600 && _user.cooldowns.drug < 7200) {
      return Image.asset('images/icons/cooldowns/drug3.png', width: 20);
    } // 2-5 hours
    else if (_user.cooldowns.drug >= 7200 && _user.cooldowns.drug < 18000) {
      return Image.asset('images/icons/cooldowns/drug4.png', width: 20);
    } // 5+ hours
    else {
      return Image.asset('images/icons/cooldowns/drug5.png', width: 20);
    }
  }

  Image _medicalIcon() {
    // 0-6 hours
    if (_user.cooldowns.medical > 0 && _user.cooldowns.medical < 21600) {
      return Image.asset('images/icons/cooldowns/medical1.png', width: 20);
    } // 6-12 hours
    else if (_user.cooldowns.medical >= 21600 && _user.cooldowns.medical < 43200) {
      return Image.asset('images/icons/cooldowns/medical2.png', width: 20);
    } // 12-18 hours
    else if (_user.cooldowns.medical >= 43200 && _user.cooldowns.medical < 64800) {
      return Image.asset('images/icons/cooldowns/medical3.png', width: 20);
    } // 18-24 hours
    else if (_user.cooldowns.medical >= 64800 && _user.cooldowns.medical < 86400) {
      return Image.asset('images/icons/cooldowns/medical4.png', width: 20);
    } // 24+ hours
    else {
      return Image.asset('images/icons/cooldowns/medical5.png', width: 20);
    }
  }

  Image _boosterIcon() {
    // 0-6 hours
    if (_user.cooldowns.booster > 0 && _user.cooldowns.booster < 21600) {
      return Image.asset('images/icons/cooldowns/booster1.png', width: 20);
    } // 6-12 hours
    else if (_user.cooldowns.booster >= 21600 && _user.cooldowns.booster < 43200) {
      return Image.asset('images/icons/cooldowns/booster2.png', width: 20);
    } // 12-18 hours
    else if (_user.cooldowns.booster >= 43200 && _user.cooldowns.booster < 64800) {
      return Image.asset('images/icons/cooldowns/booster3.png', width: 20);
    } // 18-24 hours
    else if (_user.cooldowns.booster >= 64800 && _user.cooldowns.booster < 86400) {
      return Image.asset('images/icons/cooldowns/booster4.png', width: 20);
    } // 24+ hours
    else {
      return Image.asset('images/icons/cooldowns/booster5.png', width: 20);
    }
  }

  Widget _drugCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.drug));
    var formattedTime = TimeFormatter(
      inputTime: timeEnd,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatHour;
    String diff = _timeFormatted(timeEnd);
    return Flexible(
        child: Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text('@ $formattedTime$diff'),
    ));
  }

  Widget _medicalCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.medical));
    var formattedTime = TimeFormatter(
      inputTime: timeEnd,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatHour;
    String diff = _timeFormatted(timeEnd);
    return Flexible(
        child: Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text('@ $formattedTime$diff'),
    ));
  }

  Widget _boosterCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.booster));
    var formattedTime = TimeFormatter(
      inputTime: timeEnd,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatHour;
    String diff = _timeFormatted(timeEnd);
    return Flexible(
        child: Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text('@ $formattedTime$diff'),
    ));
  }

  String _timeFormatted(DateTime timeEnd) {
    var timeDifference = timeEnd.difference(_serverTime);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
    String diff = '';
    if (timeDifference.inMinutes < 1) {
      diff = ', in a few seconds';
    } else if (timeDifference.inMinutes >= 1 && timeDifference.inHours < 24) {
      diff = ', in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
    } else {
      var dayWeek = TimeFormatter(
        inputTime: timeEnd,
        timeFormatSetting: _settingsProvider.currentTimeFormat,
        timeZoneSetting: _settingsProvider.currentTimeZone,
      ).formatDayWeek;
      diff = ' $dayWeek, in '
          '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
    }
    return diff;
  }

  Card _eventsTimeline() {
    int maxToShow = _eventsShowNumber;

    // Some users might an empty events map. This is why we have the events parameters as dynamic
    // in OwnProfile Model. We need to check if it contains several elements, in which case we
    // create a map in a new variable. Otherwise, we return an empty Card.
    var events = Map<String, Event>();
    if (_user.events.length > 0) {
      events = Map.from(_user.events).map((k, v) => MapEntry<String, Event>(k, Event.fromJson(v)));
    } else {
      return Card(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    'EVENTS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
                  child: Text(
                    "You have no events",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    var timeline = <Widget>[];

    int unreadCount = 0;
    int loopCount = 1;
    int maxCount;

    if (events.length > maxToShow) {
      maxCount = maxToShow;
    } else {
      maxCount = events.length;
      maxToShow = events.length;
    }

    for (var e in events.values) {
      if (e.seen == 0) {
        unreadCount++;
      }

      String message = HtmlParser.fix(e.event);
      message = message;
      message = message.replaceAll('View the details here!', '');
      message = message.replaceAll('Please click here to continue.', '');
      message = message.replaceAll(' [view]', '.');
      message = message.replaceAll(' [View]', '');
      message = message.replaceAll(' Please click here.', '');
      message = message.replaceAll(' Please click here to collect your funds.', '');

      Widget insideIcon = EventIcons(
        message: message,
        themeProvider: _themeProvider,
      );

      IndicatorStyle iconBubble;
      iconBubble = IndicatorStyle(
        width: 30,
        height: 30,
        drawGap: true,
        indicator: Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.grey,
              ),
            ),
            shape: BoxShape.rectangle,
          ),
          child: insideIcon,
        ),
      );

      var eventTime = DateTime.fromMillisecondsSinceEpoch(e.timestamp * 1000);

      var event = TimelineTile(
        isFirst: loopCount == 1 ? true : false,
        isLast: loopCount == maxCount ? true : false,
        alignment: TimelineAlign.manual,
        indicatorStyle: iconBubble,
        lineXY: 0.25,
        endChild: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: e.seen == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        startChild: Container(
          child: Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Text(
              _occurrenceTimeFormatted(eventTime),
              style: TextStyle(
                fontSize: 11,
                fontWeight: e.seen == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      timeline.add(event);

      if (loopCount == maxCount) {
        break;
      }
      loopCount++;
    }

    timeline.add(
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Center(
          child: Text(
            "(Showing last $maxToShow events)",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );

    var unreadString = '';
    if (unreadCount == 0) {
      unreadString = 'No unread events';
    } else if (unreadCount == 1) {
      unreadString = "1 unread event";
    } else {
      unreadString = '$unreadCount unread events';
    }

    return Card(
      child: ExpandablePanel(
        controller: _eventsExpController,
        theme: ExpandableThemeData(iconColor: _themeProvider.mainText),
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Text(
                'EVENTS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onLongPress: () {
                  _launchBrowser(url: "https://www.torn.com/events.php#/step=all", dialogRequested: false);
                },
                onTap: () {
                  _launchBrowser(url: 'https://www.torn.com/events.php#/step=all', dialogRequested: true);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(MdiIcons.openInApp, size: 18),
                ),
              ),
            ],
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
          child: Text(
            unreadString,
            style: TextStyle(
              color: unreadCount == 0 ? Colors.green : Colors.red,
              fontWeight: unreadCount == 0 ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: timeline,
          ),
        ),
      ),
    );
  }

  Card _messagesTimeline() {
    int maxToShow = _messagesShowNumber;

    // Some users might an empty messages map. This is why we have the events parameters as dynamic
    // in OwnProfile Model. We need to check if it contains several elements, in which case we
    // create a map in a new variable. Otherwise, we return an empty Card.
    var messages = Map<String, TornMessage>();
    if (_user.messages.length > 0) {
      messages = Map.from(_user.messages).map((k, v) => MapEntry<String, TornMessage>(k, TornMessage.fromJson(v)));
    } else {
      return Card(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    'MESSAGES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
                  child: Text(
                    "You have no unread messages",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    var timeline = <Widget>[];

    // Get total of unread messages
    int unreadTotalCount = 0;
    messages.forEach((key, value) {
      if (value.read == 0) {
        unreadTotalCount++;
      }
    });

    // Get unread within limits (only recent)
    int unreadRecentCount = 0;
    int loopCount = 1;
    int maxCount;

    if (messages.length > maxToShow) {
      maxCount = maxToShow;
    } else {
      maxCount = messages.length;
      maxToShow = messages.length;
    }

    for (var i = 0; i < maxToShow; i++) {
      var msg = messages.values.elementAt(i);

      if (msg.read == 0) {
        unreadRecentCount++;
      }

      // This is important, as title is dynamic (for some reason, Torn API return
      // and int if the title is only a number...
      if (msg.title is int) {
        msg.title = msg.title.toString();
      }

      String title = msg.title;
      Widget insideIcon = _messagesInsideIconCases(msg.type);

      IndicatorStyle iconBubble;
      iconBubble = IndicatorStyle(
        width: 30,
        height: 30,
        drawGap: true,
        indicator: Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.grey,
              ),
            ),
            shape: BoxShape.rectangle,
          ),
          child: insideIcon,
        ),
      );

      var messageTime = DateTime.fromMillisecondsSinceEpoch(msg.timestamp * 1000);

      var messageRow = TimelineTile(
        isFirst: loopCount == 1 ? true : false,
        isLast: loopCount == maxCount ? true : false,
        alignment: TimelineAlign.manual,
        indicatorStyle: iconBubble,
        lineXY: 0.25,
        endChild: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                msg.read == 0
                    ? GestureDetector(
                        child: Icon(Icons.markunread, color: Colors.green[600]),
                        onLongPress: () {
                          _launchBrowser(
                              url: "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox",
                              dialogRequested: false);
                        },
                        onTap: () {
                          _launchBrowser(
                              url: "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox",
                              dialogRequested: true);
                        },
                      )
                    : GestureDetector(
                        child: Icon(Icons.mark_as_unread),
                        onLongPress: () {
                          _launchBrowser(
                              url: "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox",
                              dialogRequested: false);
                        },
                        onTap: () {
                          _launchBrowser(
                              url: "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox",
                              dialogRequested: true);
                        },
                      ),
              ],
            ),
          ),
        ),
        startChild: Container(
          child: Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Text(
              _occurrenceTimeFormatted(messageTime),
              style: TextStyle(
                fontSize: 11,
                fontWeight: msg.seen == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      timeline.add(messageRow);

      if (loopCount == maxCount) {
        break;
      }
      loopCount++;
    }

    timeline.add(
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Center(
          child: Text(
            "(Showing last $maxToShow messages)",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );

    var unreadRecentString = '';
    if (unreadRecentCount == 0) {
      unreadRecentString = 'No unread messages (recent)';
    } else if (unreadRecentCount == 1) {
      unreadRecentString = "1 unread message (recent)";
    } else {
      unreadRecentString = '$unreadRecentCount unread messages (recent)';
    }

    var unreadTotalString = '';
    var lastMessageDate = DateTime.fromMillisecondsSinceEpoch(messages.values.last.timestamp * 1000);
    if (unreadTotalCount == 0) {
      unreadTotalString = 'No unread messages '
          '(since ${_occurrenceTimeFormatted(lastMessageDate)})';
    } else if (unreadTotalCount == 1) {
      unreadTotalString = '1 unread message '
          '(since ${_occurrenceTimeFormatted(lastMessageDate)})';
    } else {
      unreadTotalString = '$unreadTotalCount unread messages '
          '(since ${_occurrenceTimeFormatted(lastMessageDate)})';
    }

    return Card(
      child: ExpandablePanel(
        theme: ExpandableThemeData(iconColor: _themeProvider.mainText),
        controller: _messagesExpController,
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Text(
                'MESSAGES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onLongPress: () {
                  _launchBrowser(url: "https://www.torn.com/messages.php", dialogRequested: false);
                },
                onTap: () {
                  _launchBrowser(url: "https://www.torn.com/messages.php", dialogRequested: true);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(MdiIcons.openInApp, size: 18),
                ),
              ),
            ],
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unreadRecentString,
                style: TextStyle(
                  color: unreadRecentCount == 0 ? Colors.green : Colors.red,
                  fontWeight: unreadRecentCount == 0 ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              if (unreadTotalCount > 0 && unreadTotalCount > unreadRecentCount)
                Text(
                  '$unreadTotalString',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: timeline,
          ),
        ),
      ),
    );
  }

  Widget _messagesInsideIconCases(String type) {
    Widget insideIcon;
    if (type.contains('Company newsletter')) {
      insideIcon = Icon(
        Icons.work,
        color: Colors.brown[300],
        size: 20,
      );
    } else if (type.contains('Faction newsletter')) {
      insideIcon = Center(
        child: Image.asset(
          'images/icons/faction.png',
          color: Colors.deepOrange[700],
          width: 14,
          height: 14,
        ),
      );
    } else if (type.contains('User message')) {
      insideIcon = Center(
        child: Icon(
          MdiIcons.accountDetails,
          color: Colors.blueGrey[500],
          size: 20,
        ),
      );
    } else {
      insideIcon = Container(
        child: Center(
          child: Text(
            'T',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
      );
    }
    return insideIcon;
  }

  String _occurrenceTimeFormatted(DateTime occurrenceTime) {
    String diff;
    var timeDifference = _serverTime.difference(occurrenceTime);
    if (timeDifference.inMinutes < 1) {
      diff = 'Seconds ago';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      diff = '1 min ago';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      diff = '${timeDifference.inMinutes} mins ago';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      diff = '1 hr ago';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      diff = '${timeDifference.inHours} hrs ago';
    } else {
      diff = '${timeDifference.inDays} days ago';
    }
    return diff;
  }

  Card _playerStats() {
    // Currency configuration
    final decimalFormat = new NumberFormat("#,##0", "en_US");

    // Strength modifiers
    bool strengthModified = false;
    Color strengthColor = Colors.white;
    int strengthModifier = 0;
    double strengthModifiedTotal = _miscModel.strength.toDouble();
    String strengthString = '';
    for (var strengthMod in _miscModel.strengthInfo) {
      RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      var matches = strRaw.allMatches(strengthMod);
      if (matches.length > 0) {
        strengthModified = true;
        for (var match in matches) {
          var change = match.group(2);
          if (match.group(1) == '-') {
            strengthModifier -= int.parse(change);
          } else if (match.group(1) == '+') {
            strengthModifier += int.parse(change);
          }
        }
      }
    }
    if (strengthModified) {
      strengthModifiedTotal += strengthModifiedTotal * strengthModifier / 100;
      if (strengthModifier < 0) {
        strengthString = "($strengthModifier%)";
        strengthColor = Colors.red;
      } else {
        strengthString = "(+$strengthModifier%)";
        strengthColor = Colors.green;
      }
    }

    // Defense modifiers
    bool defenseModified = false;
    Color defenseColor = Colors.white;
    int defenseModifier = 0;
    double defenseModifiedTotal = _miscModel.defense.toDouble();
    String defenseString = '';
    for (var defenseMod in _miscModel.defenseInfo) {
      RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      var matches = strRaw.allMatches(defenseMod);
      if (matches.length > 0) {
        defenseModified = true;
        for (var match in matches) {
          var change = match.group(2);
          if (match.group(1) == '-') {
            defenseModifier -= int.parse(change);
          } else if (match.group(1) == '+') {
            defenseModifier += int.parse(change);
          }
        }
      }
    }
    if (defenseModified) {
      defenseModifiedTotal += defenseModifiedTotal * defenseModifier / 100;
      if (defenseModifier < 0) {
        defenseString = "($defenseModifier%)";
        defenseColor = Colors.red;
      } else {
        defenseString = "(+$defenseModifier%)";
        defenseColor = Colors.green;
      }
    }

    // Speed modifiers
    bool speedModified = false;
    Color speedColor = Colors.white;
    int speedModifier = 0;
    double speedModifiedTotal = _miscModel.speed.toDouble();
    String speedString = '';
    for (var speedMod in _miscModel.speedInfo) {
      RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      var matches = strRaw.allMatches(speedMod);
      if (matches.length > 0) {
        speedModified = true;
        for (var match in matches) {
          var change = match.group(2);
          if (match.group(1) == '-') {
            speedModifier -= int.parse(change);
          } else if (match.group(1) == '+') {
            speedModifier += int.parse(change);
          }
        }
      }
    }
    if (speedModified) {
      speedModifiedTotal += speedModifiedTotal * speedModifier / 100;
      if (speedModifier < 0) {
        speedString = "($speedModifier%)";
        speedColor = Colors.red;
      } else {
        speedString = "(+$speedModifier%)";
        speedColor = Colors.green;
      }
    }

    // Dex modifiers
    bool dexModified = false;
    Color dexColor = Colors.white;
    int dexModifier = 0;
    double dexModifiedTotal = _miscModel.dexterity.toDouble();
    String dexString = '';
    for (var dexMod in _miscModel.dexterityInfo) {
      RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      var matches = strRaw.allMatches(dexMod);
      if (matches.length > 0) {
        dexModified = true;
        for (var match in matches) {
          var change = match.group(2);
          if (match.group(1) == '-') {
            dexModifier -= int.parse(change);
          } else if (match.group(1) == '+') {
            dexModifier += int.parse(change);
          }
        }
      }
    }
    if (dexModified) {
      dexModifiedTotal += dexModifiedTotal * dexModifier / 100;
      if (dexModifier < 0) {
        dexString = "($dexModifier%)";
        dexColor = Colors.red;
      } else {
        dexString = "(+$dexModifier%)";
        dexColor = Colors.green;
      }
    }

    double totalEffective = strengthModifiedTotal + speedModifiedTotal + defenseModifiedTotal + dexModifiedTotal;

    int totalEffectiveModifier = ((totalEffective - _miscModel.total) * 100 / _miscModel.total).round();

    // SKILLS
    bool skillsExist = false;
    var hunting = "";
    var racing = "";
    var reviving = "";
    hunting = _miscModel.hunting ?? "";
    racing = _miscModel.racing ?? "";
    reviving = _miscModel.reviving ?? "";
    if (hunting.isNotEmpty || racing.isNotEmpty || reviving.isNotEmpty) {
      skillsExist = true;
    }

    _sharedEffStrength = 'Strength: ${decimalFormat.format(strengthModifiedTotal)} $strengthString';
    _sharedEffDefense = 'Defense: ${decimalFormat.format(defenseModifiedTotal)} $defenseString';
    _sharedEffSpeed = 'Speed: ${decimalFormat.format(speedModifiedTotal)} $speedString';
    _sharedEffDexterity = 'Dexterity: ${decimalFormat.format(dexModifiedTotal)} $dexString';
    _sharedEffTotal = 'Total: ${decimalFormat.format(totalEffective)}';

    return Card(
      child: ExpandablePanel(
        theme: ExpandableThemeData(iconColor: _themeProvider.mainText),
        controller: _basicInfoExpController,
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Text(
                'BASIC INFO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 5),
              GestureDetector(
                child: Icon(Icons.copy, size: 14),
                onTap: () {
                  _shareMisc();
                },
              ),
            ],
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cashWallet(dense: false),
              SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onLongPress: () {
                      _launchBrowser(url: 'https://www.torn.com/points.php', dialogRequested: false);
                    },
                    onTap: () async {
                      _launchBrowser(url: 'https://www.torn.com/points.php', dialogRequested: true);
                    },
                    child: Icon(
                      MdiIcons.alphaPCircleOutline,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text('${_miscModel.points}'),
                ],
              ),
              SizedBox(height: 4),
              _jobPoints(),
              SizedBox(height: 8),
              SelectableText('Battle Stats: ${decimalFormat.format(_miscModel.total)}'),
              SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: SelectableText(
                      'Battle Stats (effective): ${decimalFormat.format(totalEffective)}',
                    ),
                  ),
                  if (totalEffectiveModifier < 0)
                    Text(
                      ' ($totalEffectiveModifier%)',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    )
                  else if (totalEffectiveModifier > 0)
                    Text(
                      ' (+$totalEffectiveModifier%)',
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    )
                ],
              ),
              if (_settingsProvider.tornStatsChartEnabled && _settingsProvider.tornStatsChartInCollapsedMiscCard)
                FutureBuilder(
                  future: _statsChartDataFetched,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (_statsChartModel?.data != null) {
                        return Column(
                          children: [
                            SizedBox(height: 20),
                            SizedBox(
                              height: 200,
                              child: StatsChart(
                                statsData: _statsChartModel,
                              ),
                            ),
                            SizedBox(height: 40),
                          ],
                        );
                      }
                    }
                    return SizedBox(height: 8);
                  },
                )
              else
                SizedBox(height: 8),
              SelectableText('MAN: ${decimalFormat.format(_miscModel.manualLabor)}'),
              SelectableText('INT: ${decimalFormat.format(_miscModel.intelligence)}'),
              SelectableText('END: ${decimalFormat.format(_miscModel.endurance)}'),
            ],
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText('Rank: ${_user.rank}'),
                    SelectableText('Age: ${_user.age}'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _cashWallet(dense: false),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        _launchBrowser(url: 'https://www.torn.com/points.php', dialogRequested: false);
                      },
                      onTap: () async {
                        _launchBrowser(url: 'https://www.torn.com/points.php', dialogRequested: true);
                      },
                      child: Icon(
                        MdiIcons.alphaPCircleOutline,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(width: 5),
                    SelectableText('${_miscModel.points}'),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _jobPoints(),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Text(
                      'BATTLE STATS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    GestureDetector(
                      child: Icon(Icons.copy, size: 14),
                      onTap: () {
                        _shareMisc(shareType: "battle");
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Strength: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.strength)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.strength * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Defense: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.defense)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.defense * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Speed: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.speed)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.speed * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Dexterity: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.dexterity)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.dexterity * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 50,
                      child: Divider(color: _themeProvider.mainText, thickness: 0.5),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Total: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.total)}'),
                      ],
                    ),
                  ],
                ),
              ),
              if (_settingsProvider.tornStatsChartEnabled)
                FutureBuilder(
                  future: _statsChartDataFetched,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (_statsChartModel?.data != null) {
                        return Column(
                          children: [
                            SizedBox(height: 40),
                            SizedBox(
                              height: 200,
                              child: StatsChart(
                                statsData: _statsChartModel,
                              ),
                            ),
                            SizedBox(height: 40),
                          ],
                        );
                      }
                    }
                    return SizedBox(height: 20);
                  },
                )
              else
                SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Text(
                      'EFFECTIVE STATS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    GestureDetector(
                      child: Icon(Icons.copy, size: 14),
                      onTap: () {
                        _shareMisc(shareType: "effective");
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Strength: '),
                        ),
                        SelectableText('${decimalFormat.format(strengthModifiedTotal)}'),
                        strengthModified
                            ? Text(
                                " $strengthString",
                                style: TextStyle(color: strengthColor, fontSize: 12),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Defense: '),
                        ),
                        SelectableText('${decimalFormat.format(defenseModifiedTotal)}'),
                        defenseModified
                            ? Text(
                                " $defenseString",
                                style: TextStyle(color: defenseColor, fontSize: 12),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Speed: '),
                        ),
                        SelectableText('${decimalFormat.format(speedModifiedTotal)}'),
                        speedModified
                            ? Text(
                                " $speedString",
                                style: TextStyle(color: speedColor, fontSize: 12),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Dexterity: '),
                        ),
                        SelectableText('${decimalFormat.format(dexModifiedTotal)}'),
                        dexModified
                            ? Text(
                                " $dexString",
                                style: TextStyle(color: dexColor, fontSize: 12),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    SizedBox(
                      width: 50,
                      child: Divider(color: _themeProvider.mainText, thickness: 0.5),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Total: ',
                          ),
                        ),
                        SelectableText(
                          '${decimalFormat.format(totalEffective)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Text(
                      'WORK STATS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    GestureDetector(
                      child: Icon(Icons.copy, size: 14),
                      onTap: () {
                        _shareMisc(shareType: "work");
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text('Manual labor: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.manualLabor)}'),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text('Intelligence: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.intelligence)}'),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text('Endurance: '),
                        ),
                        SelectableText('${decimalFormat.format(_miscModel.endurance)}'),
                      ],
                    ),
                  ],
                ),
              ),
              if (skillsExist)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Text(
                            'SKILLS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          GestureDetector(
                            child: Icon(Icons.copy, size: 14),
                            onTap: () {
                              _shareMisc(shareType: "skills");
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (racing.isNotEmpty)
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text('Racing: '),
                                ),
                                SelectableText('$racing'),
                              ],
                            ),
                          if (reviving.isNotEmpty)
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text('Reviving: '),
                                ),
                                SelectableText('$reviving'),
                              ],
                            ),
                          if (hunting.isNotEmpty)
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text('Hunting: '),
                                ),
                                SelectableText('$hunting'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cashWallet({bool dense}) {
    if (_user.networth["wallet"] != null) {
      final moneyFormat = new NumberFormat("#,##0", "en_US");
      return Row(
        children: [
          GestureDetector(
            onTap: () async {
              _openWalletDialog();
            },
            child: dense
                ? Icon(Icons.account_balance_wallet_rounded, size: 17, color: Colors.brown)
                : Icon(
                    MdiIcons.cashUsdOutline,
                    color: Colors.green,
                  ),
          ),
          SizedBox(width: 5),
          SelectableText(
            '\$${moneyFormat.format(_user.networth["wallet"])}',
            style: TextStyle(
              fontSize: dense ? 13 : 14,
              fontWeight: dense ? FontWeight.bold : FontWeight.normal,
              color: dense ? Colors.green : _themeProvider.mainText,
            ),
          )
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _miscellaneous() {
    bool showMisc = false;
    bool addictionActive = false;
    bool racingActive = false;
    bool bankActive = false;
    bool educationActive = false;
    bool propertyActive = false;
    bool donatorActive = false;

    // DEBUG ******************************
    //_user.icons.icon57 = "Test addiction -" + " long string " * 6;
    //_user.icons.icon17 = "Test racing -" + " long string " * 6;
    //_miscModel.cityBank.timeLeft = 6000;
    //_miscModel.educationTimeleft = 6000;
    // DEBUG ******************************

    if (_miscModel == null || _tornEducationModel == null) {
      return SizedBox.shrink();
    }

    // ADDICTION
    Widget addictionWidget = SizedBox.shrink();
    if (_user.icons.icon57 != null ||
        _user.icons.icon58 != null ||
        _user.icons.icon59 != null ||
        _user.icons.icon60 != null ||
        _user.icons.icon61 != null) {
      showMisc = true;
      addictionActive = true;
      String addictionString;
      Color brainColor;
      if (_user.icons.icon57 != null) {
        addictionString = _user.icons.icon57;
        brainColor = Colors.grey;
      } else if (_user.icons.icon58 != null) {
        addictionString = _user.icons.icon58;
        brainColor = Colors.brown[300];
      } else if (_user.icons.icon59 != null) {
        addictionString = _user.icons.icon59;
        brainColor = Colors.deepOrange[700];
      } else if (_user.icons.icon60 != null) {
        addictionString = _user.icons.icon60;
        brainColor = Colors.amber[900];
      } else if (_user.icons.icon61 != null) {
        addictionString = _user.icons.icon61;
        brainColor = Colors.red[600];
      }

      addictionWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.brain, color: brainColor),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              addictionString,
              style: DefaultTextStyle.of(context).style,
            ),
          ),
        ],
      );
    }

    // RACING
    Widget racingWidget = SizedBox.shrink();
    if (_user.icons.icon17 != null || _user.icons.icon18 != null) {
      showMisc = true;
      racingActive = true;
      String racingString;
      Color gaugeColor;
      if (_user.icons.icon17 != null) {
        racingString = _user.icons.icon17.replaceAll("Racing - ", "");
        racingString = racingString.replaceAll("0 days, 0 hours,", "");
        racingString = racingString.replaceAll("0 days,", "");
        gaugeColor = Colors.green[700];
      } else if (_user.icons.icon18 != null) {
        racingString = _user.icons.icon18.replaceAll("Racing - ", '');
        gaugeColor = Colors.red[700];
      }

      racingWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.gauge, color: gaugeColor),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              racingString,
              style: DefaultTextStyle.of(context).style,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onLongPress: () {
              _launchBrowser(url: 'https://www.torn.com/loader.php?sid=racing', dialogRequested: false);
            },
            onTap: () {
              _launchBrowser(url: 'https://www.torn.com/loader.php?sid=racing', dialogRequested: true);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Icon(MdiIcons.openInApp, size: 18),
            ),
          ),
        ],
      );
    }

    // FACTION CRIMES
    var factionCrimesActive = false;
    Widget factionCrimes = SizedBox.shrink();
    if (_ocFinalStringLong.isNotEmpty) {
      factionCrimesActive = true;
      factionCrimes = Row(
        children: [
          Icon(MdiIcons.fingerprint),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              _ocFinalStringLong,
              style: TextStyle(
                color: _ocComplexReady
                    ? _ocComplexPeopleNotReady == 0
                        ? Colors.green
                        : Colors.orange[700]
                    : _themeProvider.mainText,
              ),
            ),
          ),
          if (_ocComplexReady)
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onLongPress: () {
                _launchBrowser(url: "https://www.torn.com/factions.php?step=your#/tab=crimes", dialogRequested: false);
              },
              onTap: () {
                _launchBrowser(url: 'https://www.torn.com/factions.php?step=your#/tab=crimes', dialogRequested: true);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(MdiIcons.openInApp, size: 18),
              ),
            ),
        ],
      );
    } else if (_ocSimpleExists) {
      factionCrimesActive = true;
      factionCrimes = Row(
        children: [
          Icon(MdiIcons.fingerprint),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              _ocSimpleStringFinal,
              style: TextStyle(color: _ocSimpleReady ? Colors.orange[700] : _themeProvider.mainText),
            ),
          ),
          if (_ocComplexReady)
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onLongPress: () {
                _launchBrowser(url: "https://www.torn.com/factions.php?step=your#/tab=crimes", dialogRequested: false);
              },
              onTap: () {
                _launchBrowser(url: 'https://www.torn.com/factions.php?step=your#/tab=crimes', dialogRequested: true);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(MdiIcons.openInApp, size: 18),
              ),
            ),
          GestureDetector(
            child: Icon(
              MdiIcons.closeCircleOutline,
              size: 16,
              color: _ocSimpleReady ? Colors.orange[700] : _themeProvider.mainText,
            ),
            onTap: () {
              return showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return DisregardCrimeDialog(
                    disregardCallback: _disregardCrimeCallback,
                  );
                },
              );
            },
          ),
        ],
      );
    }

    // BANK
    Widget bankWidget = SizedBox.shrink();
    if (_miscModel.cityBank.timeLeft > 0) {
      showMisc = true;
      bankActive = true;
      final moneyFormat = new NumberFormat("#,##0", "en_US");
      var timeExpiry = DateTime.now().add(Duration(seconds: _miscModel.cityBank.timeLeft));
      var timeDifference = timeExpiry.difference(DateTime.now());
      Color expiryColor = Colors.orange[800];
      String expiryString;
      if (timeDifference.inHours < 1) {
        expiryString = 'less than an hour';
      } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
        expiryString = 'about an hour';
      } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
        expiryString = '${timeDifference.inHours} hours';
      } else if (timeDifference.inDays == 1) {
        expiryString = '1 day and ${(_miscModel.cityBank.timeLeft / 60 / 60 % 24).floor()} hours';
        expiryColor = _themeProvider.mainText;
      } else {
        expiryString =
            '${timeDifference.inDays} days and ${(_miscModel.cityBank.timeLeft / 60 / 60 % 24).floor()} hours';
        expiryColor = _themeProvider.mainText;
      }

      bankWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.bankOutline),
          SizedBox(width: 10),
          Flexible(
            child: RichText(
              text: TextSpan(
                text: "Your bank investment of ",
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: "\$${moneyFormat.format(_miscModel.cityBank.amount)}",
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  ),
                  TextSpan(text: " will expire in "),
                  TextSpan(
                    text: "$expiryString",
                    style: TextStyle(color: expiryColor),
                  ),
                ],
              ),
            ),
          )
        ],
      );
    }

    // EDUCATION
    Widget educationWidget = SizedBox.shrink();
    if (_miscModel.educationTimeleft > 0) {
      showMisc = true;
      educationActive = true;
      var timeExpiry = DateTime.now().add(Duration(seconds: _miscModel.educationTimeleft));
      var timeDifference = timeExpiry.difference(DateTime.now());
      Color expiryColor = Colors.orange[800];
      String expiryString;
      if (timeDifference.inHours < 1) {
        expiryString = 'less than an hour';
      } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
        expiryString = 'about an hour';
      } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
        expiryString = '${timeDifference.inHours} hours';
      } else if (timeDifference.inDays == 1) {
        expiryString = '1 day';
        expiryColor = _themeProvider.mainText;
      } else {
        expiryString = '${timeDifference.inDays} days';
        expiryColor = _themeProvider.mainText;
      }

      String courseName;
      _tornEducationModel.education.forEach((key, value) {
        if (key == _miscModel.educationCurrent.toString()) {
          courseName = value.name;
        }
      });

      educationWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.schoolOutline),
          SizedBox(width: 10),
          Flexible(
            child: RichText(
              text: TextSpan(
                text: "Your course: ",
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: "$courseName",
                    /*
                    style: TextStyle(
                      color: Colors.green,
                    ),
                    */
                  ),
                  TextSpan(text: ", will end in "),
                  TextSpan(
                    text: "$expiryString",
                    style: TextStyle(color: expiryColor),
                  ),
                ],
              ),
            ),
          )
        ],
      );
    }
    // There is no education on going... why? All done, or forgotten?
    else {
      // If the number of courses studied and available are not the same, we have forgotten
      // NOTE: decreased by one because the Dual Wield Melee Course is not offered any more
      if (_miscModel.educationCompleted.length < _tornEducationModel.education.length - 1) {
        showMisc = true;
        educationActive = true;
        educationWidget = Row(
          children: <Widget>[
            Icon(MdiIcons.schoolOutline),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "You are not enrolled in any education course!",
                style: TextStyle(color: Colors.red[500]),
              ),
            )
          ],
        );
      }
    }

    // PROPERTIES
    if (_rentedProperties > 0) {
      showMisc = true;
      propertyActive = true;
    }

    // DONATOR
    Widget donatorWidget = SizedBox.shrink();
    if (_user.icons.icon3 != null || _user.icons.icon4 != null) {
      showMisc = true;
      donatorActive = true;
      String donatorString;

      if (_user.icons.icon3 != null) {
        donatorString = _user.icons.icon3;
      } else if (_user.icons.icon4 != null) {
        donatorString = _user.icons.icon4.replaceAll("Subscriber - Donator status:", "Donator:");
        donatorString = donatorString.replaceAll("Donator status:", "Donator:");
      }

      donatorWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.starOutline),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              donatorString,
              style: DefaultTextStyle.of(context).style,
            ),
          ),
        ],
      );
    }

    if (!showMisc) {
      return SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    'MISC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (addictionActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                    child: addictionWidget,
                  ),
                if (racingActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                    child: racingWidget,
                  ),
                if (factionCrimesActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                    child: factionCrimes,
                  ),
                if (bankActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                    child: bankWidget,
                  ),
                if (educationActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                    child: educationWidget,
                  ),
                if (propertyActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                    child: _rentedPropertiesWidget,
                  ),
                if (donatorActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                    child: donatorWidget,
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Card _netWorth() {
    // Currency configuration
    final moneyFormat = new NumberFormat("#,##0", "en_US");

    // Total when folded
    int total;
    for (var v in _user.networth.entries) {
      if (v.key == 'total') {
        total = v.value.round();
      }
    }

    // List for all sources in column
    var moneySources = <Widget>[];

    // Total Expanded
    moneySources.add(
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 110,
              child: Text(
                'Total: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '\$${moneyFormat.format(total)}',
              style: TextStyle(
                color: total < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    // Loop all other sources
    for (var v in _user.networth.entries) {
      String source;
      if (v.key == 'total' || v.key == 'parsetime') {
        continue;
      } else if (v.key == 'piggybank') {
        source = 'Piggy Bank';
      } else if (v.key == 'displaycase') {
        source = 'Display Case';
      } else if (v.key == 'stockmarket') {
        source = 'Stock Market';
      } else if (v.key == 'auctionhouse') {
        source = 'Auction House';
      } else if (v.key == 'unpaidfees') {
        source = 'Unpaid Fees';
      } else if (v.key == 'itemmarket') {
        source = 'Items Market';
      } else if (v.key == 'enlistedcars') {
        source = 'Enlisted Cars';
      } else {
        source = "${v.key[0].toUpperCase()}${v.key.substring(1)}";
      }

      moneySources.add(
        Row(
          children: <Widget>[
            SizedBox(
              width: 110,
              child: Text('$source: '),
            ),
            Text(
              '\$${moneyFormat.format(v.value.round())}',
              style: TextStyle(
                color: v.value < 0 ? Colors.red : Colors.green,
              ),
            ),
            if (v.key == "points" && _miscModel != null && _miscModel.points > 0)
              Text(
                "  (@\$${moneyFormat.format((v.value.round()) / _miscModel.points)})",
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      );
    }

    return Card(
      child: ExpandablePanel(
        theme: ExpandableThemeData(iconColor: _themeProvider.mainText),
        controller: _networthExpController,
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(
            'NETWORTH',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
          child: Text(
            '\$${moneyFormat.format(total)}',
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: total <= 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: moneySources,
          ),
        ),
      ),
    );
  }

  Future<void> _fetchApi() async {
    // Try to get only as many messages as strictly necessary, as per Torn recommendations
    var limit = 3;
    if (_messagesShowNumber > limit) limit = _messagesShowNumber;
    if (_eventsShowNumber > limit) limit = _eventsShowNumber;

    var apiResponse = await TornApiCaller().getProfileExtended(limit: limit);
    var apiChain = await TornApiCaller().getChainStatus();

    if (mounted) {
      setState(() {
        if (apiResponse is OwnProfileExtended) {
          _apiRetries = 0;
          _user = apiResponse;
          _serverTime = DateTime.fromMillisecondsSinceEpoch(_user.serverTime * 1000);
          _apiGoodData = true;

          // If max values have decreased or were never initialized
          if (_customEnergyTrigger > _user.energy.maximum || _customEnergyTrigger == 0) {
            _customEnergyTrigger = _user.energy.maximum;
            Prefs().setEnergyNotificationValue(_customEnergyTrigger);
          }
          if (_customNerveTrigger > _user.nerve.maximum || _customNerveTrigger == 0) {
            _customNerveTrigger = _user.nerve.maximum;
            Prefs().setNerveNotificationValue(_customNerveTrigger);
          }

          if (apiChain is ChainModel) {
            _chainModel = apiChain;
          } else {
            // Default to empty chain, with all parameters at 0
            _chainModel = ChainModel();
            _chainModel.chain = ChainDetails();
          }

          _checkIfNotificationsAreCurrent();
        } else {
          if (_apiGoodData && _apiRetries < 8) {
            _apiRetries++;
          } else {
            _apiGoodData = false;
            _apiError = apiResponse as ApiError;
            _apiRetries = 0;
          }
        }
      });
    }

    // We get other kind of information separately once per minute and onResumed
    // As part of MiscCardInfo()
    //  - (sync) Education, money and skills with miscInfo call
    //  - (async) OC Crimes (both types) with AA call or from events
    //  - (async) Bazaar
    if (_apiGoodData && !_miscApiFetchedOnce) {
      await _getMiscCardInfo();
      _statsChartDataFetched = _getStatsChart();
    }

    _retrievePendingNotifications();
  }

  Future _getMiscCardInfo() async {
    try {
      var miscApiResponse = await TornApiCaller().getProfileMisc();

      if (_tornEducationModel == null) {
        _tornEducationModel = await TornApiCaller().getEducation();
      }

      // The ones that are inside this condition, show in the MISC card (which
      // is disabled if the MISC API call is not successful
      if (miscApiResponse is OwnProfileMisc && _tornEducationModel is TornEducationModel) {
        // Get this async
        if (_settingsProvider.oCrimesEnabled) {
          _getFactionCrimes();
        }

        // Assess properties async, but wait some more time
        if (_rentedPropertiesTick == 0) {
          _checkProperties(miscApiResponse);
        } else if (_rentedPropertiesTick > 30) {
          _checkProperties(miscApiResponse);
          _rentedPropertiesTick = 0;
        }
        _rentedPropertiesTick++;

        setState(() {
          _miscModel = miscApiResponse;
          _miscApiFetchedOnce = true;
        });
      }
    } catch (e) {
      // If something fails, we simple don't show the MISC section
    }
  }

  Future _getStatsChart() async {
    try {
      if (!_settingsProvider.tornStatsChartEnabled) return;

      DateTime lastFetched = DateTime.fromMillisecondsSinceEpoch(_settingsProvider.tornStatsChartDateTime);

      if (DateTime.now().difference(lastFetched).inHours < 26) {
        var savedChart = await Prefs().getTornStatsChartSave();
        if (savedChart.isNotEmpty) {
          setState(() {
            _statsChartModel = statsChartTornStatsFromJson(savedChart);
          });
          return;
        }
      }

      String tornStatsURL = 'https://www.tornstats.com/api/v1/${_u.alternativeTornStatsKey}/battlestats/graph';
      var resp = await http.get(Uri.parse(tornStatsURL)).timeout(Duration(seconds: 2));
      if (resp.statusCode == 200) {
        StatsChartTornStats statsJson = statsChartTornStatsFromJson(resp.body);
        if (statsJson != null && !statsJson.message.contains("ERROR")) {
          setState(() {
            _statsChartModel = statsJson;
          });

          Prefs().setTornStatsChartSave(resp.body);
          _settingsProvider.setTornStatsChartDateTime = DateTime.now().millisecondsSinceEpoch;
        }
      }
    } catch (e) {
      // Returns null
    }
  }

  Future<void> _getFactionCrimes() async {
    try {
      var factionCrimes = await TornApiCaller().getFactionCrimes();

      // OPTION 1 - Check if we have faction access
      if (factionCrimes != null && factionCrimes is FactionCrimesModel) {
        String complexString = "";
        DateTime complexTime = DateTime.now();

        // Get main crime and time
        factionCrimes.crimes.forEach((key, crime) {
          if (crime.initiated == 0 && complexString.isEmpty) {
            var participantsNotReady = 0;
            crime.participants.forEach((participant) {
              // There is only one participant, but in another map
              participant.forEach((key, values) {
                if (values.description != "Okay") {
                  participantsNotReady++;
                }
              });

              if (participant.containsKey(_userProv.basic.playerId.toString())) {
                complexString = crime.crimeName;
                complexTime = DateTime.fromMillisecondsSinceEpoch(crime.timeReady * 1000);
              }
            });

            // If found our crime, assign final number of participants not ready
            if (complexString.isNotEmpty) _ocComplexPeopleNotReady = participantsNotReady;
          }
        });

        // Calculate time and final string for widgets
        if (complexString.isNotEmpty) {
          bool complexReady = false;
          String complexTimeString = "";
          if (complexTime.isAfter(DateTime.now())) {
            var formattedTime = TimeFormatter(
              inputTime: complexTime,
              timeFormatSetting: _settingsProvider.currentTimeFormat,
              timeZoneSetting: _settingsProvider.currentTimeZone,
            ).formatHour;
            complexTimeString = "OC will be ready @ $formattedTime${_timeFormatted(complexTime)}";
          } else {
            complexReady = true;
            if (_ocComplexPeopleNotReady == 0) {
              complexTimeString = "OC and all participants are ready!";
            } else if (_ocComplexPeopleNotReady == 1) {
              complexTimeString = "OC is ready, but 1 participant is not!";
            } else {
              complexTimeString = "OC is ready, but $_ocComplexPeopleNotReady participants are not!";
            }
          }

          setState(() {
            _ocFinalStringLong = "$complexString $complexTimeString";
            _ocFinalStringShort = "$complexTimeString";
            _ocComplexReady = complexReady;
            _ocTime = complexTime;
          });

          return;
        }
      }

      // OPTION 2 - Could indicate that we have no AA access, so we are looking for events!
      if (factionCrimes == null || factionCrimes is ApiError || _ocFinalStringLong.isEmpty) {
        bool simpleExists = false;
        DateTime simpleTime = DateTime.now();
        String simpleString = "";
        bool simpleReady = false;

        void calculateSimpleReadiness() {
          if (simpleTime.isBefore(DateTime.now())) {
            simpleReady = true;
            simpleString = "A faction organized crime might be ready!";
          } else {
            var formattedTime = TimeFormatter(
              inputTime: simpleTime,
              timeFormatSetting: _settingsProvider.currentTimeFormat,
              timeZoneSetting: _settingsProvider.currentTimeZone,
            ).formatHour;
            simpleString = "A faction organized crime will be ready @ "
                "$formattedTime${_timeFormatted(simpleTime)}";
          }
        }

        // Try to find quick crimes in events
        var events = Map<String, Event>();
        if (_user.events.length > 0) {
          events = Map.from(_user.events).map((k, v) => MapEntry<String, Event>(k, Event.fromJson(v)));
        }

        bool foundExpired = false;
        bool foundProgress = false;
        bool error = false;

        // Try to find our crime by reviewing the last 100 events. The first one we
        // can find is the one that counts
        events.forEach((key, value) {
          if (!foundExpired && !foundProgress && !error) {
            if (value.event.contains("You and your team") ||
                (value.event.contains("canceled the") && value.event.contains("that you were selected for"))) {
              foundExpired = true;
            } else if (value.event.contains("You have been selected")) {
              RegExp strRaw = RegExp(r"([0-9]+) hours");
              var matches = strRaw.allMatches(value.event);
              if (matches.length > 0) {
                for (var match in matches) {
                  var hoursString = match.group(1);
                  try {
                    var hours = int.parse(hoursString);
                    simpleTime =
                        DateTime.fromMillisecondsSinceEpoch(value.timestamp * 1000).add(Duration(hours: hours));
                    foundProgress = true;
                    simpleExists = true;
                    _settingsProvider.changeOCrimeLastKnown = simpleTime.millisecondsSinceEpoch;
                    calculateSimpleReadiness();
                  } catch (e) {
                    foundExpired = false;
                    foundProgress = false;
                    error = true;
                  }
                }
              }
            }
          }
        });

        // If we haven't found anything in 100 events (including no cancellations), but we are still
        // ahead of the last known planned OC crime time, perhaps we run out of events (some OC
        // take place after 8 days). If that's the case, show that one anyway.
        if (!foundProgress && !foundExpired && !error) {
          var lastKnown = DateTime.fromMillisecondsSinceEpoch(_settingsProvider.oCrimeLastKnown);
          if (DateTime.now().isBefore(lastKnown)) {
            simpleExists = true;
            simpleTime = lastKnown;
            foundProgress = true;
            calculateSimpleReadiness();
          }
        }

        // Check if we were disregarding this crime before (in which case we don't show it)
        if (foundProgress) {
          if (_settingsProvider.oCrimeDisregarded == simpleTime.millisecondsSinceEpoch) {
            simpleExists = false;
            _ocSimpleStringFinal = "";
          }
        }

        setState(() {
          _ocSimpleExists = simpleExists;
          _ocSimpleReady = simpleReady;
          _ocSimpleStringFinal = simpleString;
          _ocTime = simpleTime;
        });
      }
    } catch (e) {
      // Don't fill anything
    }
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      animationDuration: Duration(milliseconds: 150),
      direction:
          MediaQuery.of(context).orientation == Orientation.portrait ? SpeedDialDirection.up : SpeedDialDirection.left,
      backgroundColor: Colors.transparent,
      overlayColor: Colors.transparent,
      child: Container(
        width: 58,
        height: 58,
        decoration: new BoxDecoration(
          border: Border.all(
            color: Colors.grey[800],
            width: 2,
          ),
          shape: BoxShape.circle,
          image: new DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage("images/icons/torn_t_logo_restore.png"),
          ),
        ),
      ),
      visible: true,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          onTap: () {
            _launchBrowser(url: 'https://www.torn.com/city.php', dialogRequested: true);
          },
          onLongPress: () {
            _launchBrowser(url: 'https://www.torn.com/city.php', dialogRequested: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: Icon(
              MdiIcons.cityVariantOutline,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.purple[500],
          label: 'CITY',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.purple[500],
        ),
        SpeedDialChild(
          onTap: () {
            _launchBrowser(url: 'https://www.torn.com/trade.php', dialogRequested: true);
          },
          onLongPress: () async {
            _launchBrowser(url: 'https://www.torn.com/trade.php', dialogRequested: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: Icon(
              MdiIcons.accountSwitchOutline,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.yellow[800],
          label: 'TRADES',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.yellow[800],
        ),
        SpeedDialChild(
          onTap: () {
            _launchBrowser(url: 'https://www.torn.com/item.php', dialogRequested: true);
          },
          onLongPress: () {
            _launchBrowser(url: 'https://www.torn.com/item.php', dialogRequested: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: Icon(
              Icons.card_giftcard,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.blue[400],
          label: 'ITEMS',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.blue[400],
        ),
        SpeedDialChild(
          onTap: () {
            _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', dialogRequested: true);
          },
          onLongPress: () {
            _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', dialogRequested: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: Center(
              child: Image.asset(
                'images/icons/ic_pistol_black_48dp.png',
                width: 25,
                height: 25,
                color: Colors.black,
              ),
            ),
          ),
          backgroundColor: Colors.deepOrange[400],
          label: 'CRIMES',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.deepOrange[400],
        ),
        SpeedDialChild(
          onTap: () {
            _launchBrowser(url: 'https://www.torn.com/gym.php', dialogRequested: true);
          },
          onLongPress: () {
            _launchBrowser(url: 'https://www.torn.com/gym.php', dialogRequested: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: Icon(
              Icons.fitness_center,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.green[400],
          label: 'GYM',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.green[400],
        ),
        SpeedDialChild(
          onTap: () async {
            _launchBrowser(url: 'https://www.torn.com', dialogRequested: true);
          },
          onLongPress: () {
            _launchBrowser(url: 'https://www.torn.com', dialogRequested: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: Icon(
              Icons.home_outlined,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.grey[400],
          label: 'HOME',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.grey[400],
        ),
      ],
    );
  }

  void _launchBrowser({@required String url, @required bool dialogRequested, bool recallLastSession = false}) async {
    if (!_settingsProvider.useQuickBrowser) dialogRequested = false;
    _webViewProvider.openBrowserPreference(
      context: context,
      url: url,
      useDialog: dialogRequested,
      recallLastSession: recallLastSession,
    );
  }

  Future _updateCallback() async {
    // Even if this implies calling the app twice, it enhances player
    // experience as the bars are updated quickly after a change
    // In turn, we only call the API every 30 seconds with the timer
    await Future.delayed(Duration(seconds: 5));
    if (mounted) {
      _fetchApi();
    }
    await Future.delayed(Duration(seconds: 10));
    if (mounted) {
      _fetchApi();
    }
  }

  void _scheduleNotification(ProfileNotification profileNotification) async {
    int secondsToNotification;
    String channelTitle;
    String channelSubtitle;
    String channelDescription;
    String notificationTitle;
    String notificationSubtitle;
    int notificationId;
    String notificationIconAndroid = "notification_icon";
    Color notificationIconColor = Colors.grey;

    // We will add the timestamp to the payload
    String notificationPayload = '';

    switch (profileNotification) {
      case ProfileNotification.travel:
        notificationId = 201;
        secondsToNotification = _travelArrivalTime.difference(DateTime.now()).inSeconds - _travelNotificationAhead;
        channelTitle = 'Manual travel';
        channelSubtitle = 'Manual travel';
        channelDescription = 'Manual notifications for travel';
        notificationTitle = await Prefs().getTravelNotificationTitle();
        notificationSubtitle = await Prefs().getTravelNotificationBody();
        notificationPayload += 'travel';
        notificationIconAndroid = "notification_travel";
        notificationIconColor = Colors.blue;
        break;
      case ProfileNotification.energy:
        notificationId = 101;
        secondsToNotification = _energyNotificationTime.difference(DateTime.now()).inSeconds;
        channelTitle = 'Manual energy';
        channelSubtitle = 'Manual energy';
        channelDescription = 'Manual notifications for energy';
        notificationTitle = 'Energy bar';
        notificationSubtitle = 'Here is your energy reminder!';
        var myTimeStamp = (_energyNotificationTime.millisecondsSinceEpoch / 1000).floor();
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_energy";
        notificationIconColor = Colors.green;
        break;
      case ProfileNotification.nerve:
        notificationId = 102;
        secondsToNotification = _nerveNotificationTime.difference(DateTime.now()).inSeconds;
        channelTitle = 'Manual nerve';
        channelSubtitle = 'Manual nerve';
        channelDescription = 'Manual notifications for nerve';
        notificationTitle = 'Nerve bar';
        notificationSubtitle = 'Here is your nerve reminder!';
        var myTimeStamp = (_nerveNotificationTime.millisecondsSinceEpoch / 1000).floor();
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_nerve";
        notificationIconColor = Colors.red;
        break;
      case ProfileNotification.life:
        notificationId = 103;
        secondsToNotification = _user.life.fulltime;
        channelTitle = 'Manual life';
        channelSubtitle = 'Manual life';
        channelDescription = 'Manual notifications for life';
        notificationTitle = 'Life bar';
        notificationSubtitle = 'Here is your life reminder!';
        var myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user.life.fulltime;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
      case ProfileNotification.drugs:
        notificationId = 104;
        secondsToNotification = _user.cooldowns.drug;
        channelTitle = 'Manual drugs';
        channelSubtitle = 'Manual drugs';
        channelDescription = 'Manual notifications for drugs';
        notificationTitle = 'Drug Cooldown';
        notificationSubtitle = 'Here is your drugs cooldown reminder!';
        var myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user.cooldowns.drug;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
      case ProfileNotification.medical:
        notificationId = 105;
        secondsToNotification = _user.cooldowns.medical;
        channelTitle = 'Manual medical';
        channelSubtitle = 'Manual medical';
        channelDescription = 'Manual notifications for medical';
        notificationTitle = 'Medical Cooldown';
        notificationSubtitle = 'Here is your medical cooldown reminder!';
        var myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user.cooldowns.medical;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
      case ProfileNotification.booster:
        notificationId = 106;
        secondsToNotification = _user.cooldowns.booster;
        channelTitle = 'Manual booster';
        channelSubtitle = 'Manual booster';
        channelDescription = 'Manual notifications for booster';
        notificationTitle = 'Booster Cooldown';
        notificationSubtitle = 'Here is your booster cooldown reminder!';
        var myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user.cooldowns.booster;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
      case ProfileNotification.hospital:
        notificationId = 107;
        secondsToNotification = _hospitalReleaseTime.difference(DateTime.now()).inSeconds - _hospitalNotificationAhead;
        channelTitle = 'Manual hospital';
        channelSubtitle = 'Manual hospital';
        channelDescription = 'Manual notifications for hospital';
        notificationTitle = 'Hospital release';
        notificationSubtitle = 'You are about to be released from hospital!';
        notificationPayload += 'hospital';
        break;
      case ProfileNotification.jail:
        notificationId = 108;
        secondsToNotification = _jailReleaseTime.difference(DateTime.now()).inSeconds - _jailNotificationAhead;
        channelTitle = 'Manual jail';
        channelSubtitle = 'Manual jail';
        channelDescription = 'Manual notifications for jail';
        notificationTitle = 'Jail release';
        notificationSubtitle = 'You are about to be released from jail!';
        notificationPayload += 'jail';
        break;
    }

    var modifier = await getNotificationChannelsModifiers();

    // Add s for custom sounds
    if (channelTitle.contains("travel")) {
      channelTitle = "$channelTitle ${modifier.channelIdModifier} s";
      channelSubtitle = "$channelSubtitle ${modifier.channelIdModifier} s";
    } else {
      channelTitle = "$channelTitle ${modifier.channelIdModifier}";
      channelSubtitle = "$channelSubtitle ${modifier.channelIdModifier}";
    }

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelTitle,
      channelSubtitle,
      channelDescription: channelDescription,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: notificationIconAndroid,
      color: notificationIconColor,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(presentSound: true, sound: 'slow_spring_board.aiff');
    if (notificationId == 201) {
      iOSPlatformChannelSpecifics = IOSNotificationDetails(presentSound: true, sound: 'aircraft_seatbelt.aiff');
    }

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      notificationTitle,
      notificationSubtitle,
      //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)), // DEBUG
      tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsToNotification)),
      platformChannelSpecifics,
      payload: notificationPayload,
      androidAllowWhileIdle: true, // Deliver at exact time
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // DEBUG
    //print('Notification $notificationTitle @ '
    //    '${tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsToNotification))}');

    _retrievePendingNotifications();
  }

  Future<void> _retrievePendingNotifications() async {
    bool travel = false;
    bool energy = false;
    bool nerve = false;
    bool life = false;
    bool drugs = false;
    bool medical = false;
    bool booster = false;
    bool hospital = false;
    bool jail = false;

    var pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    if (pendingNotificationRequests.length > 0) {
      for (var notification in pendingNotificationRequests) {
        if (notification.payload.contains('travel')) {
          travel = true;
        } else if (notification.payload.contains('energy')) {
          energy = true;
        } else if (notification.payload.contains('nerve')) {
          nerve = true;
        } else if (notification.payload.contains('life')) {
          life = true;
        } else if (notification.payload.contains('drugs')) {
          drugs = true;
        } else if (notification.payload.contains('medical')) {
          medical = true;
        } else if (notification.payload.contains('booster')) {
          booster = true;
        } else if (notification.payload.contains('hospital')) {
          hospital = true;
        } else if (notification.payload.contains('jail')) {
          jail = true;
        }
      }
    }

    if (mounted) {
      setState(() {
        _travelNotificationsPending = travel;
        _energyNotificationsPending = energy;
        _nerveNotificationsPending = nerve;
        _lifeNotificationsPending = life;
        _drugsNotificationsPending = drugs;
        _medicalNotificationsPending = medical;
        _boosterNotificationsPending = booster;
        _hospitalNotificationsPending = hospital;
        _jailNotificationsPending = jail;
      });
    }
  }

  Future<void> _cancelNotifications(ProfileNotification profileNotification) async {
    switch (profileNotification) {
      case ProfileNotification.travel:
        await flutterLocalNotificationsPlugin.cancel(201);
        break;
      case ProfileNotification.energy:
        await flutterLocalNotificationsPlugin.cancel(101);
        break;
      case ProfileNotification.nerve:
        await flutterLocalNotificationsPlugin.cancel(102);
        break;
      case ProfileNotification.life:
        await flutterLocalNotificationsPlugin.cancel(103);
        break;
      case ProfileNotification.drugs:
        await flutterLocalNotificationsPlugin.cancel(104);
        break;
      case ProfileNotification.medical:
        await flutterLocalNotificationsPlugin.cancel(105);
        break;
      case ProfileNotification.booster:
        await flutterLocalNotificationsPlugin.cancel(106);
        break;
      case ProfileNotification.hospital:
        await flutterLocalNotificationsPlugin.cancel(107);
        break;
      case ProfileNotification.jail:
        await flutterLocalNotificationsPlugin.cancel(108);
        break;
    }

    _retrievePendingNotifications();
  }

  void _checkIfNotificationsAreCurrent() async {
    var pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    if (pendingNotificationRequests.length == 0) {
      return;
    }

    bool triggered = false;
    var updatedTypes = <String>[];
    var updatedTimes = <String>[];
    var formatter = new DateFormat('HH:mm');

    for (var notification in pendingNotificationRequests) {
      // Don't take into account notifications that don't split this way
      // Using this instead of try/catch
      var splitPayload = notification.payload.split('-');
      if (splitPayload.length < 2) {
        continue;
      }
      var oldTimeStamp = int.parse(splitPayload[1]);

      // ENERGY
      if (notification.payload.contains('energy')) {
        var customTriggerRoundedUp = _customEnergyTrigger + 4;
        if (_user.energy.current >= _user.energy.maximum ||
            (!_customEnergyMaxOverride && _user.energy.current > customTriggerRoundedUp)) {
          _cancelNotifications(ProfileNotification.energy);
          BotToast.showText(
            text: 'Energy notification expired, removing!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700],
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
          continue;
        }
        // If override and still below it, we compare with full
        if (_customEnergyMaxOverride && _customEnergyTrigger < _user.energy.current) {
          var newCalculation =
              DateTime.now().add(Duration(seconds: _user.energy.fulltime)).millisecondsSinceEpoch / 1000;
          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.energy);
            _scheduleNotification(ProfileNotification.energy);
            triggered = true;
            updatedTypes.add('energy');
            var energyCurrentSchedule = DateTime.now().add(Duration(seconds: _user.energy.fulltime));
            updatedTimes.add(formatter.format(energyCurrentSchedule));
          }
        }
        // If no override, we take whatever value it is
        else {
          var newSecondsToGo = 0;
          if (_customEnergyTrigger == _user.energy.maximum) {
            newSecondsToGo = _user.energy.fulltime;
          } else {
            var energyToGo = _customEnergyTrigger - _user.energy.current;
            var energyTicksToGo = energyToGo / _user.energy.increment;
            if (energyTicksToGo > 1) {
              var consumedTick = _user.energy.interval - _user.energy.ticktime;
              newSecondsToGo = (energyTicksToGo * _user.energy.interval - consumedTick).floor();
            } else if (energyTicksToGo > 0 && energyTicksToGo <= 1) {
              newSecondsToGo = _user.energy.ticktime;
            }
          }

          var newCalculation = DateTime.now().add(Duration(seconds: newSecondsToGo)).millisecondsSinceEpoch / 1000;

          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.energy);
            _energyNotificationTime = DateTime.now().add(Duration(seconds: newSecondsToGo));
            _scheduleNotification(ProfileNotification.energy);
            triggered = true;
            updatedTypes.add('energy');
            var energyCurrentSchedule = DateTime.now().add(Duration(seconds: newSecondsToGo));
            updatedTimes.add(formatter.format(energyCurrentSchedule));
          }
        }
        // NERVE
      } else if (notification.payload.contains('nerve')) {
        if (_user.nerve.current >= _user.nerve.maximum ||
            (!_customNerveMaxOverride && _user.nerve.current > _customNerveTrigger)) {
          _cancelNotifications(ProfileNotification.nerve);
          BotToast.showText(
            text: 'Nerve notification expired, removing!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700],
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
          continue;
        }
        // If override and still below it, we compare with full
        if (_customNerveMaxOverride && _customNerveTrigger < _user.nerve.current) {
          var newCalculation =
              DateTime.now().add(Duration(seconds: _user.nerve.fulltime)).millisecondsSinceEpoch / 1000;
          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.nerve);
            _scheduleNotification(ProfileNotification.nerve);
            triggered = true;
            updatedTypes.add('nerve');
            var nerveCurrentSchedule = DateTime.now().add(Duration(seconds: _user.nerve.fulltime));
            updatedTimes.add(formatter.format(nerveCurrentSchedule));
          }
        }
        // If no override, we take whatever value it is
        else {
          var newSecondsToGo = 0;
          if (_customNerveTrigger == _user.nerve.maximum) {
            newSecondsToGo = _user.nerve.fulltime;
          } else {
            var nerveToGo = _customNerveTrigger - _user.nerve.current;
            var nerveTicksToGo = nerveToGo / _user.nerve.increment;
            if (nerveTicksToGo > 1) {
              var consumedTick = _user.nerve.interval - _user.nerve.ticktime;
              newSecondsToGo = (nerveTicksToGo * _user.nerve.interval - consumedTick).floor();
            } else if (nerveTicksToGo > 0 && nerveTicksToGo <= 1) {
              newSecondsToGo = _user.nerve.ticktime;
            }
          }

          var newCalculation = DateTime.now().add(Duration(seconds: newSecondsToGo)).millisecondsSinceEpoch / 1000;

          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.nerve);
            _nerveNotificationTime = DateTime.now().add(Duration(seconds: newSecondsToGo));
            _scheduleNotification(ProfileNotification.nerve);
            triggered = true;
            updatedTypes.add('nerve');
            var nerveCurrentSchedule = DateTime.now().add(Duration(seconds: newSecondsToGo));
            updatedTimes.add(formatter.format(nerveCurrentSchedule));
          }
        }
        // LIFE
      } else if (notification.payload.contains('life')) {
        var newCalculation = DateTime.now().add(Duration(seconds: _user.life.fulltime)).millisecondsSinceEpoch / 1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.life);
          _scheduleNotification(ProfileNotification.life);
          triggered = true;
          updatedTypes.add('life');
          var lifeCurrentSchedule = DateTime.now().add(Duration(seconds: _user.life.fulltime));
          updatedTimes.add(formatter.format(lifeCurrentSchedule));
        }
        // DRUGS
      } else if (notification.payload.contains('drugs')) {
        var newCalculation = DateTime.now().add(Duration(seconds: _user.cooldowns.drug)).millisecondsSinceEpoch / 1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.drugs);
          _scheduleNotification(ProfileNotification.drugs);
          triggered = true;
          updatedTypes.add('drugs');
          var drugsCurrentSchedule = DateTime.now().add(Duration(seconds: _user.cooldowns.drug));
          updatedTimes.add(formatter.format(drugsCurrentSchedule));
        }
        // MEDICAL
      } else if (notification.payload.contains('medical')) {
        var newCalculation =
            DateTime.now().add(Duration(seconds: _user.cooldowns.medical)).millisecondsSinceEpoch / 1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.medical);
          _scheduleNotification(ProfileNotification.medical);
          triggered = true;
          updatedTypes.add('medical');
          var medicalCurrentSchedule = DateTime.now().add(Duration(seconds: _user.cooldowns.medical));
          updatedTimes.add(formatter.format(medicalCurrentSchedule));
        }
        // BOOSTER
      } else if (notification.payload.contains('booster')) {
        var newCalculation =
            DateTime.now().add(Duration(seconds: _user.cooldowns.booster)).millisecondsSinceEpoch / 1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.booster);
          _scheduleNotification(ProfileNotification.booster);
          triggered = true;
          updatedTypes.add('booster');
          var boosterCurrentSchedule = DateTime.now().add(Duration(seconds: _user.cooldowns.booster));
          updatedTimes.add(formatter.format(boosterCurrentSchedule));
        }
      }
    }

    if (triggered) {
      String thoseUpdated = '';
      for (var i = 0; i < updatedTypes.length; i++) {
        thoseUpdated += updatedTypes[i];
        thoseUpdated += ' (at ${updatedTimes[i]}';
        if (updatedTypes[i] == 'energy') {
          thoseUpdated += ' for E${_customEnergyTrigger.floor()})';
        } else if (updatedTypes[i] == 'nerve') {
          thoseUpdated += ' for N${_customNerveTrigger.floor()})';
        } else {
          thoseUpdated += ')';
        }
        if (i < updatedTypes.length - 1) {
          thoseUpdated += ", ";
        }
      }

      BotToast.showText(
        text: 'Some notifications have been updated: $thoseUpdated',
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[700],
        duration: Duration(seconds: 5),
        contentPadding: EdgeInsets.all(10),
      );
    }
  }

  void _shareMisc({String shareType}) {
    final decimalFormat = new NumberFormat("#,##0", "en_US");
    var playerString = "${_user.name} [${_user.playerId}]";

    String getBattle() {
      var battleString = "\n\nBATTLE STATS";
      battleString += '\nStrength: ${decimalFormat.format(_miscModel.strength)} '
          '(${decimalFormat.format(_miscModel.strength * 100 / _miscModel.total)}%)';
      battleString += '\nDefense: ${decimalFormat.format(_miscModel.defense)} '
          '(${decimalFormat.format(_miscModel.defense * 100 / _miscModel.total)}%)';
      battleString += '\nSpeed: ${decimalFormat.format(_miscModel.speed)} '
          '(${decimalFormat.format(_miscModel.speed * 100 / _miscModel.total)}%)';
      battleString += '\nDexterity: ${decimalFormat.format(_miscModel.dexterity)} '
          '(${decimalFormat.format(_miscModel.dexterity * 100 / _miscModel.total)}%)';
      battleString += '\n-------';
      battleString += '\nTotal: ${decimalFormat.format(_miscModel.total)}';
      return battleString;
    }

    String getEffective() {
      var effectiveString = "\n\nEFFECTIVE STATS";
      effectiveString += '\n$_sharedEffStrength';
      effectiveString += '\n$_sharedEffDefense';
      effectiveString += '\n$_sharedEffSpeed';
      effectiveString += '\n$_sharedEffDexterity';
      effectiveString += '\n-------';
      effectiveString += '\n$_sharedEffTotal';
      return effectiveString;
    }

    String getWork() {
      var workString = "\n\nWORK STATS";
      workString += '\nManual labor: ${decimalFormat.format(_miscModel.manualLabor)}';
      workString += '\nIntelligence: ${decimalFormat.format(_miscModel.intelligence)}';
      workString += '\nEndurance: ${decimalFormat.format(_miscModel.endurance)}';
      return workString;
    }

    String getSkills() {
      var skillExist = false;
      var skillsString = "\n\nSKILLS";
      if (_miscModel.hunting != null) {
        skillsString += '\nRacing: ${_miscModel.racing}';
        skillExist = true;
      }
      if (_miscModel.reviving != null) {
        skillsString += '\nReviving: ${_miscModel.reviving}';
        skillExist = true;
      }
      if (_miscModel.hunting != null) {
        skillsString += '\nHunting: ${_miscModel.hunting}';
        skillExist = true;
      }
      if (!skillExist) skillsString = "";
      return skillsString;
    }

    switch (shareType) {
      case "battle":
        var battle = playerString += getBattle();
        Share.share(battle);
        //print(battle);
        break;
      case "effective":
        var effective = playerString += getEffective();
        Share.share(effective);
        //print(effective);
        break;
      case "work":
        var work = playerString += getWork();
        Share.share(work);
        //print(work);
        break;
      case "skills":
        var skills = playerString += getSkills();
        Share.share(skills);
        //print(skills);
        break;
      default:
        var all = playerString;
        all += "\n\nCash: ${decimalFormat.format(_user.networth["wallet"])}";
        all += "\nPoints: ${_miscModel.points}";
        all += "\n$_sharedJobPoints";
        all += getBattle();
        all += getEffective();
        all += getWork();
        all += getSkills();
        Share.share(all);
        //print(all);
        break;
    }
  }

  Future _loadPreferences() async {
    //SharedPreferencesModel().setProfileSectionOrder([]);

    // SECTION ORDER
    var savedUserOrder = await Prefs().getProfileSectionOrder();
    // Ensures that new sections are added as high as possible
    bool sectionsModified = false;
    for (var i = 0; i < _originalSectionOrder.length; i++) {
      if (!savedUserOrder.contains(_originalSectionOrder[i])) {
        savedUserOrder.insert(i, _originalSectionOrder[i]);
        sectionsModified = true;
      }
    }
    if (sectionsModified) {
      Prefs().setProfileSectionOrder(savedUserOrder);
    }

    // TRAVEL
    var travel = await Prefs().getTravelNotificationType();
    var travelNotificationAhead = await Prefs().getTravelNotificationAhead();
    var travelAlarmAhead = await Prefs().getTravelAlarmAhead();
    var travelTimerAhead = await Prefs().getTravelTimerAhead();

    if (travelNotificationAhead == '0') {
      _travelNotificationAhead = 20;
    } else if (travelNotificationAhead == '1') {
      _travelNotificationAhead = 40;
    } else if (travelNotificationAhead == '2') {
      _travelNotificationAhead = 60;
    } else if (travelNotificationAhead == '3') {
      _travelNotificationAhead = 120;
    } else if (travelNotificationAhead == '4') {
      _travelNotificationAhead = 300;
    }

    if (travelAlarmAhead == '0') {
      _travelAlarmAhead = 0;
    } else if (travelAlarmAhead == '1') {
      _travelAlarmAhead = 1;
    } else if (travelAlarmAhead == '2') {
      _travelAlarmAhead = 2;
    } else if (travelAlarmAhead == '3') {
      _travelAlarmAhead = 5;
    }

    if (travelTimerAhead == '0') {
      // Time left is recalculated each 10 seconds, so we give here 20 + 10 extra, as otherwise
      // it's too tight. Worse case scenario: the user is quick and checks the travel screen when
      // there are still 25-30 seconds to go. Best case, he still has 20 seconds to spare.
      _travelTimerAhead = 30;
    } else if (travelTimerAhead == '1') {
      // Same as above but 40 + 5 seconds. Timer triggers between 35-45 seconds.
      _travelTimerAhead = 45;
    } else if (travelTimerAhead == '2') {
      _travelTimerAhead = 60;
    } else if (travelTimerAhead == '3') {
      _travelTimerAhead = 120;
    } else if (travelTimerAhead == '4') {
      _travelTimerAhead = 300;
    }
    // TRAVEL ENDS

    var energy = await Prefs().getEnergyNotificationType();
    _customEnergyTrigger = await Prefs().getEnergyNotificationValue();
    _customEnergyMaxOverride = await Prefs().getEnergyPercentageOverride();

    var nerve = await Prefs().getNerveNotificationType();
    _customNerveTrigger = await Prefs().getNerveNotificationValue();
    _customNerveMaxOverride = await Prefs().getNervePercentageOverride();

    var life = await Prefs().getLifeNotificationType();
    var drugs = await Prefs().getDrugNotificationType();
    var medical = await Prefs().getMedicalNotificationType();
    var booster = await Prefs().getBoosterNotificationType();

    var hospital = await Prefs().getHospitalNotificationType();
    _hospitalNotificationAhead = await Prefs().getHospitalNotificationAhead();
    _hospitalAlarmAhead = await Prefs().getHospitalAlarmAhead();
    _hospitalTimerAhead = await Prefs().getHospitalTimerAhead();

    var jail = await Prefs().getJailNotificationType();
    _jailNotificationAhead = await Prefs().getJailNotificationAhead();
    _jailAlarmAhead = await Prefs().getJailAlarmAhead();
    _jailTimerAhead = await Prefs().getJailTimerAhead();

    _alarmSound = await Prefs().getManualAlarmSound();
    _alarmVibration = await Prefs().getManualAlarmVibration();

    _nukeReviveActive = await Prefs().getUseNukeRevive();
    _uhcReviveActive = await Prefs().getUseUhcRevive();
    _warnAboutChains = await Prefs().getWarnAboutChains();
    _shortcutsEnabled = await Prefs().getEnableShortcuts();
    _showHeaderWallet = await Prefs().getShowHeaderWallet();
    _showHeaderIcons = await Prefs().getShowHeaderIcons();
    _dedicatedTravelCard = await Prefs().getDedicatedTravelCard();

    var expandEvents = await Prefs().getExpandEvents();
    var eventsNumber = await Prefs().getEventsShowNumber();
    var expandMessages = await Prefs().getExpandMessages();
    var messagesNumber = await Prefs().getMessagesShowNumber();
    var expandBasicInfo = await Prefs().getExpandBasicInfo();
    var expandNetworth = await Prefs().getExpandNetworth();

    setState(() {
      _userSectionOrder = savedUserOrder;

      if (travel == '0') {
        _travelNotificationType = NotificationType.notification;
        _travelNotificationIcon = Icons.chat_bubble_outline;
      } else if (travel == '1') {
        _travelNotificationType = NotificationType.alarm;
        _travelNotificationIcon = Icons.notifications_none;
      } else if (travel == '2') {
        _travelNotificationType = NotificationType.timer;
        _travelNotificationIcon = Icons.timer;
      }

      if (energy == '0') {
        _energyNotificationType = NotificationType.notification;
        _energyNotificationIcon = Icons.chat_bubble_outline;
      } else if (energy == '1') {
        _energyNotificationType = NotificationType.alarm;
        _energyNotificationIcon = Icons.notifications_none;
      } else if (energy == '2') {
        _energyNotificationType = NotificationType.timer;
        _energyNotificationIcon = Icons.timer;
      }

      if (nerve == '0') {
        _nerveNotificationType = NotificationType.notification;
        _nerveNotificationIcon = Icons.chat_bubble_outline;
      } else if (nerve == '1') {
        _nerveNotificationType = NotificationType.alarm;
        _nerveNotificationIcon = Icons.notifications_none;
      } else if (nerve == '2') {
        _nerveNotificationType = NotificationType.timer;
        _nerveNotificationIcon = Icons.timer;
      }

      if (life == '0') {
        _lifeNotificationType = NotificationType.notification;
        _lifeNotificationIcon = Icons.chat_bubble_outline;
      } else if (life == '1') {
        _lifeNotificationType = NotificationType.alarm;
        _lifeNotificationIcon = Icons.notifications_none;
      } else if (life == '2') {
        _lifeNotificationType = NotificationType.timer;
        _lifeNotificationIcon = Icons.timer;
      }

      if (drugs == '0') {
        _drugsNotificationType = NotificationType.notification;
        _drugsNotificationIcon = Icons.chat_bubble_outline;
      } else if (drugs == '1') {
        _drugsNotificationType = NotificationType.alarm;
        _drugsNotificationIcon = Icons.notifications_none;
      } else if (drugs == '2') {
        _drugsNotificationType = NotificationType.timer;
        _drugsNotificationIcon = Icons.timer;
      }

      if (medical == '0') {
        _medicalNotificationType = NotificationType.notification;
        _medicalNotificationIcon = Icons.chat_bubble_outline;
      } else if (medical == '1') {
        _medicalNotificationType = NotificationType.alarm;
        _medicalNotificationIcon = Icons.notifications_none;
      } else if (medical == '2') {
        _medicalNotificationType = NotificationType.timer;
        _medicalNotificationIcon = Icons.timer;
      }

      if (booster == '0') {
        _boosterNotificationType = NotificationType.notification;
        _boosterNotificationIcon = Icons.chat_bubble_outline;
      } else if (booster == '1') {
        _boosterNotificationType = NotificationType.alarm;
        _boosterNotificationIcon = Icons.notifications_none;
      } else if (booster == '2') {
        _boosterNotificationType = NotificationType.timer;
        _boosterNotificationIcon = Icons.timer;
      }

      if (hospital == '0') {
        _hospitalNotificationType = NotificationType.notification;
        _hospitalNotificationIcon = Icons.chat_bubble_outline;
      } else if (hospital == '1') {
        _hospitalNotificationType = NotificationType.alarm;
        _hospitalNotificationIcon = Icons.notifications_none;
      } else if (hospital == '2') {
        _hospitalNotificationType = NotificationType.timer;
        _hospitalNotificationIcon = Icons.timer;
      }

      if (jail == '0') {
        _jailNotificationType = NotificationType.notification;
        _jailNotificationIcon = Icons.chat_bubble_outline;
      } else if (jail == '1') {
        _jailNotificationType = NotificationType.alarm;
        _jailNotificationIcon = Icons.notifications_none;
      } else if (jail == '2') {
        _jailNotificationType = NotificationType.timer;
        _jailNotificationIcon = Icons.timer;
      }

      _eventsExpController.expanded = expandEvents;
      _eventsShowNumber = eventsNumber;
      _messagesExpController.expanded = expandMessages;
      _messagesShowNumber = messagesNumber;
      _basicInfoExpController.expanded = expandBasicInfo;
      _networthExpController.expanded = expandNetworth;
    });
  }

  void _setAlarm(ProfileNotification profileNotification) {
    int hour;
    int minute;
    String message;

    switch (profileNotification) {
      case ProfileNotification.travel:
        var alarmTime = _travelArrivalTime.add(Duration(minutes: -_travelAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA Travel';
        break;
      case ProfileNotification.energy:
        hour = _energyNotificationTime.hour;
        minute = _energyNotificationTime.minute;
        message = 'Torn PDA Energy';
        break;
      case ProfileNotification.nerve:
        hour = _nerveNotificationTime.hour;
        minute = _nerveNotificationTime.minute;
        message = 'Torn PDA Nerve';
        break;
      case ProfileNotification.life:
        hour = _lifeNotificationTime.hour;
        minute = _lifeNotificationTime.minute;
        message = 'Torn PDA Life';
        break;
      case ProfileNotification.drugs:
        hour = _drugsNotificationTime.hour;
        minute = _drugsNotificationTime.minute;
        message = 'Torn PDA Drugs';
        break;
      case ProfileNotification.medical:
        hour = _medicalNotificationTime.hour;
        minute = _medicalNotificationTime.minute;
        message = 'Torn PDA Medical';
        break;
      case ProfileNotification.booster:
        hour = _boosterNotificationTime.hour;
        minute = _boosterNotificationTime.minute;
        message = 'Torn PDA Booster';
        break;
      case ProfileNotification.hospital:
        var alarmTime = _hospitalReleaseTime.add(Duration(minutes: -_hospitalAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA Hospital';
        break;
      case ProfileNotification.jail:
        var alarmTime = _jailReleaseTime.add(Duration(minutes: -_jailAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA Jail';
        break;
    }

    // Travel sound and vibration is configured from the travel section
    String thisSound;
    if (profileNotification == ProfileNotification.travel) {
      if (_alarmSound) {
        thisSound = '';
      } else {
        thisSound = 'silent';
      }
    } else {
      if (_alarmSound) {
        thisSound = '';
      } else {
        thisSound = 'silent';
      }
    }

    bool alarmVibration;
    if (profileNotification == ProfileNotification.travel) {
      if (_alarmVibration) {
        alarmVibration = true;
      } else {
        alarmVibration = false;
      }
    } else {
      if (_alarmVibration) {
        alarmVibration = true;
      } else {
        alarmVibration = false;
      }
    }

    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.VIBRATE': alarmVibration,
        'android.intent.extra.alarm.RINGTONE': thisSound,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  void _setTimer(ProfileNotification profileNotification) {
    int totalSeconds;
    String message;

    switch (profileNotification) {
      case ProfileNotification.travel:
        totalSeconds = _travelArrivalTime.difference(DateTime.now()).inSeconds - _travelTimerAhead;
        message = 'Torn PDA Travel';
        break;
      case ProfileNotification.energy:
        totalSeconds = _energyNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Energy';
        break;
      case ProfileNotification.nerve:
        totalSeconds = _nerveNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Nerve';
        break;
      case ProfileNotification.life:
        totalSeconds = _lifeNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Life';
        break;
      case ProfileNotification.drugs:
        totalSeconds = _drugsNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Drugs';
        break;
      case ProfileNotification.medical:
        totalSeconds = _medicalNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Medical';
        break;
      case ProfileNotification.booster:
        totalSeconds = _boosterNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Booster';
        break;
      case ProfileNotification.hospital:
        totalSeconds = _hospitalReleaseTime.difference(DateTime.now()).inSeconds - _hospitalTimerAhead;
        message = 'Torn PDA Hospital';
        break;
      case ProfileNotification.jail:
        totalSeconds = _jailReleaseTime.difference(DateTime.now()).inSeconds - _jailTimerAhead;
        message = 'Torn PDA Jail';
        break;
    }

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

  void _callBackFromNotificationOptions() async {
    await _loadPreferences();
    _checkIfNotificationsAreCurrent();
  }

  Future<void> _openWalletDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
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
                      margin: EdgeInsets.only(top: 15),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: ElevatedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Image.asset(
                                    'images/icons/home/vault.png',
                                    width: 15,
                                    height: 15,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 15),
                                  Text("Personal vault"),
                                ],
                              ),
                              onPressed: () async {
                                var url = "https://www.torn.com/properties.php#/p=options&tab=vault";
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, dialogRequested: true);
                              },
                              onLongPress: () async {
                                var url = "https://www.torn.com/properties.php#/p=options&tab=vault";
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, dialogRequested: false);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: ElevatedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Image.asset(
                                    'images/icons/faction.png',
                                    width: 15,
                                    height: 15,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 15),
                                  Text("Faction vault"),
                                ],
                              ),
                              onPressed: () async {
                                var url = 'https://www.torn.com/factions.php?step=your#/tab=armoury';
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, dialogRequested: true);
                              },
                              onLongPress: () async {
                                var url = "https://www.torn.com/factions.php?step=your#/tab=armoury";
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, dialogRequested: false);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: ElevatedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Image.asset(
                                    'images/icons/home/job.png',
                                    width: 15,
                                    height: 15,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 15),
                                  Text("Company vault"),
                                ],
                              ),
                              onPressed: () async {
                                var url = 'https://www.torn.com/companies.php#/option=funds';
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, dialogRequested: true);
                              },
                              onLongPress: () async {
                                var url = "https://www.torn.com/companies.php#/option=funds";
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, dialogRequested: false);
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      )),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(
                          MdiIcons.cashUsdOutline,
                          color: Colors.green,
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

  Future<void> _showLifeBarDialog(BuildContext _, {bool longPress = false}) {
    return showDialog<void>(
      context: _,
      barrierDismissible: true,
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
                      margin: EdgeInsets.only(top: 15),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: ElevatedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(Icons.person),
                                  SizedBox(width: 15),
                                  Text("Inventory"),
                                ],
                              ),
                              onPressed: () async {
                                var url = "https://www.torn.com/item.php#medical-items";
                                if (longPress) {
                                  Navigator.of(context).pop();
                                  _launchBrowser(url: url, dialogRequested: false);
                                } else {
                                  Navigator.of(context).pop();
                                  _launchBrowser(url: url, dialogRequested: true);
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: ElevatedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Image.asset(
                                    'images/icons/faction.png',
                                    width: 25,
                                    height: 15,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 15),
                                  Text("Faction"),
                                ],
                              ),
                              onPressed: () async {
                                var url =
                                    'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical';
                                if (longPress) {
                                  Navigator.of(context).pop();
                                  _launchBrowser(url: url, dialogRequested: false);
                                } else {
                                  Navigator.of(context).pop();
                                  _launchBrowser(url: url, dialogRequested: true);
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      )),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(
                          MdiIcons.hospitalBox,
                          color: Colors.red,
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

  Widget _jobPoints() {
    try {
      int currentPoints = 0;
      bool unemployed = false;

      if (_user.job.companyId == 0) {
        if (_user.job.position == "None") {
          unemployed = true;
        }

        switch (_user.job.position.toLowerCase()) {
          case "army":
            currentPoints = _miscModel.jobpoints.jobs.army;
            break;
          case "medical":
            currentPoints = _miscModel.jobpoints.jobs.medical;
            break;
          case "casino":
            currentPoints = _miscModel.jobpoints.jobs.casino;
            break;
          case "education":
            currentPoints = _miscModel.jobpoints.jobs.education;
            break;
          case "law":
            currentPoints = _miscModel.jobpoints.jobs.law;
            break;
          case "grocer":
            currentPoints = _miscModel.jobpoints.jobs.grocer;
            break;
        }
      } else {
        _miscModel.jobpoints.companies.forEach((type, details) {
          if (type == _user.job.companyType.toString()) {
            currentPoints = details.jobpoints;
          }
        });
      }

      String headerString = "$currentPoints job points";
      if (unemployed) {
        headerString = "Unemployed";
      }

      _sharedJobPoints = headerString;

      return Row(
        children: [
          GestureDetector(
            onLongPress: () {
              _launchBrowser(url: 'https://www.torn.com/companies.php', dialogRequested: false);
            },
            onTap: () async {
              _launchBrowser(url: 'https://www.torn.com/companies.php', dialogRequested: true);
            },
            child: Icon(
              Icons.work,
              color: Colors.brown[300],
              size: 23,
            ),
          ),
          SizedBox(width: 6),
          SelectableText(headerString),
          SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              return showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return JobPointsDialog(
                    currentType: _user.job.companyType,
                    currentPoints: currentPoints,
                    jobpoints: _miscModel.jobpoints,
                    job: _user.job,
                    unemployed: unemployed,
                  );
                },
              );
            },
            child: Icon(
              Icons.info_outline,
              size: 20,
            ),
          ),
        ],
      );
    } catch (e) {
      return SizedBox.shrink();
    }
  }

  Widget _flagImage() {
    String flagFile;
    switch (_user.travel.destination) {
      case "Torn":
        flagFile = 'images/flags/travel/torn.png';
        break;
      case "Argentina":
        flagFile = 'images/flags/stock/argentina.png';
        break;
      case "Canada":
        flagFile = 'images/flags/stock/canada.png';
        break;
      case "Cayman Islands":
        flagFile = 'images/flags/stock/cayman.png';
        break;
      case "China":
        flagFile = 'images/flags/stock/china.png';
        break;
      case "Hawaii":
        flagFile = 'images/flags/stock/hawaii.png';
        break;
      case "Japan":
        flagFile = 'images/flags/stock/japan.png';
        break;
      case "Mexico":
        flagFile = 'images/flags/stock/mexico.png';
        break;
      case "South Africa":
        flagFile = 'images/flags/stock/south-africa.png';
        break;
      case "Switzerland":
        flagFile = 'images/flags/stock/switzerland.png';
        break;
      case "UAE":
        flagFile = 'images/flags/stock/uae.png';
        break;
      case "United Kingdom":
        flagFile = 'images/flags/stock/uk.png';
        break;
      default:
        return SizedBox.shrink();
    }

    return Image(
      image: AssetImage(flagFile),
      height: 30,
      width: 40,
    );
  }

  String _flagBallAsset() {
    switch (_user.travel.destination) {
      case "Torn":
        if (_user.status.description.contains("to Torn from Argentina"))
          return 'images/flags/ball/ball_argentina.png';
        else if (_user.status.description.contains("to Torn from Canada"))
          return 'images/flags/ball/ball_canada.png';
        else if (_user.status.description.contains("to Torn from Cayman Islands"))
          return 'images/flags/ball/ball_cayman.png';
        else if (_user.status.description.contains("to Torn from China"))
          return 'images/flags/ball/ball_china.png';
        else if (_user.status.description.contains("to Torn from Hawaii"))
          return 'images/flags/ball/ball_hawaii.png';
        else if (_user.status.description.contains("to Torn from Japan"))
          return 'images/flags/ball/ball_japan.png';
        else if (_user.status.description.contains("to Torn from Mexico"))
          return 'images/flags/ball/ball_mexico.png';
        else if (_user.status.description.contains("to Torn from South Africa"))
          return 'images/flags/ball/ball_south-africa.png';
        else if (_user.status.description.contains("to Torn from Switzerland"))
          return 'images/flags/ball/ball_switzerland.png';
        else if (_user.status.description.contains("to Torn from UAE"))
          return 'images/flags/ball/ball_uae.png';
        else if (_user.status.description.contains("to Torn from United Kingdom"))
          return 'images/flags/ball/ball_uk.png';
        else
          return '';
        break;
      case "Argentina":
        return 'images/flags/ball/ball_argentina.png';
        break;
      case "Canada":
        return 'images/flags/ball/ball_canada.png';
        break;
      case "Cayman Islands":
        return 'images/flags/ball/ball_cayman.png';
        break;
      case "China":
        return 'images/flags/ball/ball_china.png';
        break;
      case "Hawaii":
        return 'images/flags/ball/ball_hawaii.png';
        break;
      case "Japan":
        return 'images/flags/ball/ball_japan.png';
        break;
      case "Mexico":
        return 'images/flags/ball/ball_mexico.png';
        break;
      case "South Africa":
        return 'images/flags/ball/ball_south-africa.png';
        break;
      case "Switzerland":
        return 'images/flags/ball/ball_switzerland.png';
        break;
      case "UAE":
        return 'images/flags/ball/ball_uae.png';
        break;
      case "United Kingdom":
        return 'images/flags/ball/ball_uk.png';
        break;
    }
    return '';
  }

  List<Widget> _returnSections() {
    var sectionSort = <Widget>[];

    for (var section in _userSectionOrder) {
      if (section == "Shortcuts" && _shortcutsEnabled) {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _shortcutsCarrousel(),
          ),
        );
      } else if (section == "Status") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _playerStatus(),
          ),
        );
      } else if (section == "Travel" && _dedicatedTravelCard) {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _travelCard(),
          ),
        );
      } else if (section == "Bars") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _basicBars(),
          ),
        );
      } else if (section == "Cooldowns") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _coolDowns(),
          ),
        );
      } else if (section == "Events") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _eventsTimeline(),
          ),
        );
      } else if (section == "Messages") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _messagesTimeline(),
          ),
        );
      } else if (section == "Basic Info" && _miscApiFetchedOnce) {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _playerStats(),
          ),
        );
      } else if (section == "Misc") {
        sectionSort.add(
          _miscellaneous(),
        );
      } else if (section == "Networth") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _netWorth(),
          ),
        );
      }
    }
    return sectionSort;
  }

  void _checkProperties(OwnProfileMisc miscApiResponse) async {
    // Get the properties we are renting into a map
    var thisRented = Map<String, Map<String, String>>();
    var propertyModel = miscApiResponse.properties;

    var keys = [];
    var details = [];
    propertyModel.forEach((key, value) {
      if (value.status == "Currently being rented") {
        keys.add(key);
        details.add(value);
      }
    });

    int number = 0;
    await Future.forEach(keys, (element) async {
      var rentDetails = await TornApiCaller().getProperty(propertyId: element.toString());

      if (rentDetails is PropertyModel) {
        var timeLeft = rentDetails.property.rented.daysLeft;
        var daysString = timeLeft > 1 ? "$timeLeft days" : "less than a day";
        // Was 7, now shows always
        if (timeLeft > 0) {
          thisRented.addAll({
            element: {
              "time": timeLeft.toString(),
              "text": "Your ${details[number].property.toLowerCase()}'s "
                  "rent will end in $daysString!",
            }
          });
        }
      }
      number++;
    });

    // Convert to a widget
    var propertyLines = <Widget>[];
    var currentItem = 0;
    thisRented.forEach((key, value) {
      int numberDays = int.parse(value["time"]);
      Widget prop = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Icon(Icons.house_outlined),
                SizedBox(width: 10),
                Flexible(
                    child: Text(
                  value["text"],
                  style: TextStyle(
                    color: numberDays <= 5
                        ? numberDays <= 2
                            ? Colors.red[500]
                            : Colors.orange[800]
                        : _themeProvider.mainText,
                  ),
                )),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onLongPress: () {
              _launchBrowser(
                  url: 'https://www.torn.com/properties.php#/p=options&ID=$key&tab=customize', dialogRequested: false);
            },
            onTap: () {
              _launchBrowser(
                  url: 'https://www.torn.com/properties.php#/p=options&ID=$key&tab=customize', dialogRequested: true);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Icon(MdiIcons.openInApp, size: 18),
            ),
          ),
        ],
      );

      // Add the property
      propertyLines.add(prop);

      // Add some space if we have more properties
      if (currentItem + 1 < thisRented.length) {
        propertyLines.add(SizedBox(height: 10));
      }
      currentItem++;
    });

    // Pass to global widget
    if (mounted) {
      setState(() {
        _rentedProperties = currentItem;
        _rentedPropertiesWidget = Column(children: propertyLines);
      });
    }
  }

  void _disregardCrimeCallback() {
    // We first remove the crime from the current screen
    setState(() {
      _ocSimpleExists = false;
      _ocSimpleStringFinal = "";
    });
    // Afterwards, ensure that it does not show again if it's the same one
    _settingsProvider.changeOCrimeDisregarded = _ocTime.millisecondsSinceEpoch;
  }
}
