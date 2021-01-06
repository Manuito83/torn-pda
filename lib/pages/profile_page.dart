import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:android_intent/android_intent.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/education_model.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/pages/profile/profile_notifications_android.dart';
import 'package:torn_pda/pages/profile/profile_notifications_ios.dart';
import 'package:torn_pda/pages/profile/profile_options_page.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/external/nuke_revive.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/emoji_parser.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/speed_dial/speed_dial.dart';
import 'package:torn_pda/utils/speed_dial/speed_dial_child.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import '../main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';

enum ProfileNotification {
  travel,
  energy,
  nerve,
  life,
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

  ProfilePage({@required this.callBackSection});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  Future _apiFetched;
  bool _apiGoodData = false;
  String _apiError = '';
  int _apiRetries = 0;

  OwnProfileModel _user;

  DateTime _serverTime;

  Timer _oneSecTimer;
  DateTime _currentTctTime = DateTime.now().toUtc();

  Timer _tickerCallApi;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;
  UserDetailsProvider _userProvider;
  ShortcutsProvider _shortcuts;

  // For dial FAB
  ScrollController scrollController;
  bool dialVisible = true;

  bool _travelAlarmSound = false;
  bool _travelAlarmVibration = true;
  int _travelNotificationAhead;
  int _travelAlarmAhead;
  int _travelTimerAhead;
  String _travelNotificationTitle;
  String _travelNotificationBody;

  DateTime _travelNotificationTime;
  DateTime _energyNotificationTime;
  DateTime _nerveNotificationTime;
  DateTime _lifeNotificationTime;
  DateTime _drugsNotificationTime;
  DateTime _medicalNotificationTime;
  DateTime _boosterNotificationTime;

  bool _travelNotificationsPending = false;
  bool _energyNotificationsPending = false;
  bool _nerveNotificationsPending = false;
  bool _lifeNotificationsPending = false;
  bool _drugsNotificationsPending = false;
  bool _medicalNotificationsPending = false;
  bool _boosterNotificationsPending = false;

  NotificationType _travelNotificationType;
  NotificationType _energyNotificationType;
  NotificationType _nerveNotificationType;
  NotificationType _lifeNotificationType;
  NotificationType _drugsNotificationType;
  NotificationType _medicalNotificationType;
  NotificationType _boosterNotificationType;

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

  bool _alarmSound;
  bool _alarmVibration;

  bool _miscApiFetched = false;
  OwnProfileMiscModel _miscModel;
  TornEducationModel _tornEducationModel;

  bool _nukeReviveActive = false;
  bool _warnAboutChains = false;
  bool _shortcutsEnabled = false;

  ChainModel _chainModel;

  var _eventsExpController = ExpandableController();
  var _messagesExpController = ExpandableController();
  var _basicInfoExpController = ExpandableController();
  var _networthExpController = ExpandableController();

  int _messagesShowNumber = 25;
  int _eventsShowNumber = 25;

  var speedDialSetOpen = ValueNotifier<bool>(false);

  var _showOne = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _requestIOSPermissions();
    _retrievePendingNotifications();

    scrollController = ScrollController()
      ..addListener(() {
        setDialVisible(scrollController.position.userScrollDirection ==
            ScrollDirection.forward);
      });

    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _shortcuts = context.read<ShortcutsProvider>();

    _loadPreferences().whenComplete(() {
      _apiFetched = _fetchApi();
    });

    _tickerCallApi =
        new Timer.periodic(Duration(seconds: 20), (Timer t) => _fetchApi());

    _oneSecTimer = new Timer.periodic(
        Duration(seconds: 1), (Timer t) => _refreshTctClock());

    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'profile'});
  }

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

  @override
  void dispose() {
    _tickerCallApi.cancel();
    _oneSecTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _fetchApi();
      if (_apiGoodData) {
        // We get miscellaneous information when we open the app for those cases where users
        // stay with the app on the background for hours/days and only use the Profile section
        await _getMiscInformation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      drawer: new Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      floatingActionButton: buildSpeedDial(),
      body: Container(
        child: FutureBuilder(
          future: _apiFetched,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiGoodData) {
                return BubbleShowcase(
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
                          top: size.height / 2,
                          left: (size.width - 200) / 2,
                        ),
                        widget: SpeechBubble(
                          width: 200,
                          nipLocation: NipLocation.BOTTOM,
                          nipHeight: 0,
                          color: Colors.green[800],
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'NEW!\n\n'
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
                        direction: AxisDirection.down,
                        widget: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SpeechBubble(
                            nipLocation: NipLocation.TOP,
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
                          top: size.height / 2,
                          left: (size.width - 200) / 2,
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                          child: Column(
                            children: <Widget>[
                              Text(
                                '${_user.name} [${_user.playerId}]',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Level ${_user.level}',
                              ),
                              Text(
                                _user.lastAction.relative[0] == '0'
                                    ? 'Online now'
                                    : 'Online ${_user.lastAction.relative}',
                              ),
                            ],
                          ),
                        ),
                        if (_shortcutsEnabled)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                            child: _shortcutsCarrousel(),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                          child: _playerStatus(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                          child: _basicBars(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                          child: _coolDowns(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                          child: _eventsTimeline(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                          child: _messagesTimeline(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                          child: _playerStats(),
                        ),
                        _miscellaneous(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
                          child: _netWorth(),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'OOPS!',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        child: Text(
                          'There was an error: $_apiError\n\n'
                          'This will retry automatically!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text('Profile'),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        _apiGoodData ? _tctClock() : SizedBox.shrink(),
        _apiGoodData
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
                        if (Platform.isAndroid) {
                          return ProfileNotificationsAndroid(
                            energyMax: _user.energy.maximum,
                            nerveMax: _user.nerve.maximum,
                            callback: _callBackFromNotificationOptions,
                          );
                        } else {
                          return ProfileNotificationsIOS(
                            energyMax: _user.energy.maximum,
                            nerveMax: _user.nerve.maximum,
                            callback: _callBackFromNotificationOptions,
                          );
                        }
                      },
                    ),
                  );
                },
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
              MaterialPageRoute(builder: (context) => ProfileOptionsPage()),
            );
            setState(() {
              _nukeReviveActive = newOptions.nukeReviveEnabled;
              _warnAboutChains = newOptions.warnAboutChainsEnabled;
              _shortcutsEnabled = newOptions.shortcutsEnabled;
              _eventsExpController.expanded = newOptions.expandEvents;
              _messagesShowNumber = newOptions.messagesShowNumber;
              _eventsShowNumber = newOptions.eventsShowNumber;
              _messagesExpController.expanded = newOptions.expandMessages;
              _basicInfoExpController.expanded = newOptions.expandBasicInfo;
              _networthExpController.expanded = newOptions.expandNetworth;
            });
          },
        )
      ],
    );
  }

  Widget _tctClock() {
    TimeFormatSetting timePrefs = _settingsProvider.currentTimeFormat;
    DateFormat formatter;
    switch (timePrefs) {
      case TimeFormatSetting.h24:
        formatter = DateFormat('HH:mm');
        break;
      case TimeFormatSetting.h12:
        formatter = DateFormat('hh:mm a');
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(formatter.format(_currentTctTime)),
          Text('TCT'),
        ],
      ),
    );
  }

  Widget _shortcutsCarrousel() {
    // Returns Main individual tile
    Widget shortcutTile(Shortcut thisShortcut) {
      Widget tile;
      if (_shortcuts.shortcutTile == "both") {
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
      } else if (_shortcuts.shortcutTile == "icon") {
        tile = SizedBox(
          height: 18,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Image.asset(
              thisShortcut.iconUrl,
              width: 16,
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
          _openTornBrowser(thisShortcut.url);
        },
        onTap: () {
          _settingsProvider.useQuickBrowser
              ? openBrowserDialog(context, thisShortcut.url)
              : _openTornBrowser(thisShortcut.url);
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
      if (_shortcuts.shortcutMenu == "carousel") {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _shortcuts.activeShortcuts.length,
          itemBuilder: (context, index) {
            var thisShortcut = _shortcuts.activeShortcuts[index];
            return shortcutTile(thisShortcut);
          },
        );
      } else {
        var wrapItems = <Widget>[];
        for (var thisShortcut in _shortcuts.activeShortcuts) {
          double h = 60;
          double w = 70;
          if (_shortcuts.shortcutMenu == "grid") {
            if (_shortcuts.shortcutTile == "icon") {
              h = 40;
              w = 40;
            }
            if (_shortcuts.shortcutTile == "text") {
              h = 40;
              w = 70;
            }
          }
          wrapItems.add(
            Container(height: h, width: w, child: shortcutTile(thisShortcut)),
          );
        }
        return Wrap(children: wrapItems);
      }
    }

    return SizedBox(
      // We only need a SizedBox height for the listView, the wrap will expand
      height: _shortcuts.shortcutMenu == "grid"
          ? null
          : _shortcuts.shortcutTile == 'both'
              ? 60
              : 40,
      child: _shortcuts.activeShortcuts.length == 0
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
                  'TAP OPTIONS BUTTON TO CONFIGURE',
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

        // Causing player ID (jailed of hospitalised the user)
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
                _settingsProvider.useQuickBrowser
                    ? openBrowserDialog(
                        context,
                        'https://www.torn.com/profiles.php?'
                        'XID=$causingId',
                      )
                    : _openTornBrowser('https://www.torn.com/profiles.php?'
                        'XID=$causingId');
              },
              onLongPress: () {
                _openTornBrowser('https://www.torn.com/profiles.php?'
                    'XID=$causingId');
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
          decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black)),
        ),
      );
    }

    Widget traveling() {
      if (_user.status.state == 'Traveling') {
        var startTime = _user.travel.departed;
        var endTime = _user.travel.timestamp;
        var totalSeconds = endTime - startTime;

        var dateTimeArrival =
            DateTime.fromMillisecondsSinceEpoch(_user.travel.timestamp * 1000);
        var timeDifference = dateTimeArrival.difference(DateTime.now());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes =
            twoDigits(timeDifference.inMinutes.remainder(60));
        String diff =
            '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';

        var formattedTime = TimeFormatter(
          inputTime: dateTimeArrival,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: () => _openTornBrowser('home'),
                    onTap: () {
                      _settingsProvider.useQuickBrowser
                          ? openBrowserDialog(context, 'https://www.torn.com')
                          : _openTornBrowser('home');
                    },
                    child: LinearPercentIndicator(
                      isRTL: _user.travel.destination == "Torn" ? true : false,
                      center: Text(
                        diff,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      widgetIndicator: Opacity(
                        // Make icon transparent when about to pass over text
                        opacity: _getTravelPercentage(totalSeconds) < 0.2 ||
                                _getTravelPercentage(totalSeconds) > 0.7
                            ? 1
                            : 0.3,
                        child: Padding(
                          padding: _user.travel.destination == "Torn"
                              ? const EdgeInsets.only(top: 6, right: 6)
                              : const EdgeInsets.only(top: 6, left: 10),
                          child: RotatedBox(
                            quarterTurns:
                                _user.travel.destination == "Torn" ? 3 : 1,
                            child: Icon(
                              Icons.airplanemode_active,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ),
                      animateFromLastPercent: true,
                      animation: true,
                      width: 180,
                      lineHeight: 18,
                      progressColor: Colors.blue[200],
                      backgroundColor: Colors.grey,
                      percent: _getTravelPercentage(totalSeconds),
                    ),
                  ),
                  _notificationIcon(ProfileNotification.travel),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                        'Arriving in ${_user.travel.destination} at $formattedTime'),
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

    Widget nukeRevive() {
      if (_user.status.state == 'Hospital' && _nukeReviveActive) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: GestureDetector(
                  child: Image.asset('images/icons/nuke-revive.png', width: 24),
                  onTap: () {
                    _openNukeReviveDialog(context);
                  },
                ),
              ),
              SizedBox(width: 10),
              Flexible(child: Text("Request a revive")),
            ],
          ),
        );
      } else {
        return SizedBox.shrink();
      }
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
                    children: <Widget>[
                      SizedBox(
                        width: 60,
                        child: Text('Status: '),
                      ),
                      Text(_user.status.state),
                      stateBall(),
                    ],
                  ),
                  traveling(),
                  descriptionWidget(),
                  nukeRevive(),
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
                  if (_warnAboutChains &&
                      _chainModel.chain.current > 10 &&
                      _chainModel.chain.cooldown == 0)
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
                              if (_warnAboutChains &&
                                  _chainModel.chain.current > 10 &&
                                  _chainModel.chain.cooldown == 0) {
                                BotToast.showText(
                                  text: 'Caution: your faction is chaining!',
                                  align: Alignment(0, 0),
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.blue,
                                  duration: Duration(seconds: 2),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              }

                              _openTornBrowser('https://www.torn.com/gym.php');
                            },
                            onTap: () async {
                              if (_warnAboutChains &&
                                  _chainModel.chain.current > 10 &&
                                  _chainModel.chain.cooldown == 0) {
                                BotToast.showText(
                                  text: 'Caution: your faction is chaining!',
                                  align: Alignment(0, 0),
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.blue,
                                  duration: Duration(seconds: 2),
                                  contentPadding: EdgeInsets.all(10),
                                );
                              }

                              _settingsProvider.useQuickBrowser
                                  ? await openBrowserDialog(
                                      context,
                                      'https://www.torn.com/gym.php',
                                    )
                                  : _openTornBrowser(
                                      'https://www.torn.com/gym.php');
                            },
                            child: LinearPercentIndicator(
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.green,
                              backgroundColor: Colors.grey,
                              center: Text(
                                '${_user.energy.current}',
                                style: TextStyle(color: Colors.black),
                              ),
                              percent: _user.energy.current /
                                          _user.energy.maximum >
                                      1.0
                                  ? 1.0
                                  : _user.energy.current / _user.energy.maximum,
                            ),
                          ),
                          if (_warnAboutChains &&
                              _chainModel.chain.current > 10 &&
                              _chainModel.chain.cooldown == 0)
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
                              _openTornBrowser(
                                  'https://www.torn.com/crimes.php#/step=main');
                            },
                            onTap: () async {
                              _settingsProvider.useQuickBrowser
                                  ? await openBrowserDialog(
                                      context,
                                      'https://www.torn.com/crimes.php#/step=main',
                                    )
                                  : _openTornBrowser(
                                      'https://www.torn.com/crimes.php#/step=main');
                            },
                            child: LinearPercentIndicator(
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.redAccent,
                              backgroundColor: Colors.grey,
                              center: Text(
                                '${_user.nerve.current}',
                                style: TextStyle(color: Colors.black),
                              ),
                              percent: _user.nerve.current /
                                          _user.nerve.maximum >
                                      1.0
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
                          _openTornBrowser(
                              'https://www.torn.com/item.php#candy-items');
                        },
                        onTap: () async {
                          _settingsProvider.useQuickBrowser
                              ? await openBrowserDialog(
                                  context,
                                  'https://www.torn.com/item.php#candy-items',
                                )
                              : _openTornBrowser(
                                  'https://www.torn.com/item.php#candy-items');
                        },
                        child: LinearPercentIndicator(
                          width: 150,
                          lineHeight: 20,
                          progressColor: Colors.amber,
                          backgroundColor: Colors.grey,
                          center: Text(
                            '${_user.happy.current}',
                            style: TextStyle(color: Colors.black),
                          ),
                          percent:
                              _user.happy.current / _user.happy.maximum > 1.0
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
                              _openTornBrowser(
                                  'https://www.torn.com/item.php#medical-items');
                            },
                            onTap: () async {
                              _settingsProvider.useQuickBrowser
                                  ? await openBrowserDialog(
                                      context,
                                      'https://www.torn.com/item.php#medical-items',
                                    )
                                  : _openTornBrowser(
                                      'https://www.torn.com/item.php#medical-items');
                            },
                            child: LinearPercentIndicator(
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.blue,
                              backgroundColor: Colors.grey,
                              center: Text(
                                '${_user.life.current}',
                                style: TextStyle(color: Colors.black),
                              ),
                              percent:
                                  _user.life.current / _user.life.maximum > 1.0
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
        if (_user.energy.fulltime == 0 ||
            _user.energy.current > _user.energy.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.energy.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).format;
          return Row(
            children: <Widget>[
              SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
        break;
      case "nerve":
        if (_user.nerve.fulltime == 0 ||
            _user.nerve.current > _user.nerve.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.nerve.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).format;
          return Row(
            children: <Widget>[
              SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
        break;
      case "happy":
        if (_user.happy.fulltime == 0 ||
            _user.happy.current > _user.happy.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.happy.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).format;
          return Row(
            children: <Widget>[
              SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
        break;
      case "life":
        if (_user.life.fulltime == 0 ||
            _user.life.current > _user.life.maximum) {
          return SizedBox.shrink();
        } else {
          var time = _serverTime.add(Duration(seconds: _user.life.fulltime));
          var timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).format;
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

  Widget _notificationIcon(ProfileNotification profileNotification) {
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
        var timeArrival = new DateTime.fromMillisecondsSinceEpoch(
            _user.travel.timestamp * 1000);
        var timeDifference = timeArrival.difference(DateTime.now());
        secondsToGo = timeDifference.inSeconds;
        notificationsPending = _travelNotificationsPending;
        _travelNotificationTime =
            DateTime.now().add(Duration(seconds: secondsToGo));

        var formattedTimeNotification = TimeFormatter(
          inputTime: _travelNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;
        var alarmTime =
            _travelNotificationTime.add(Duration(minutes: -_travelAlarmAhead));
        var formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;
        var timerTime =
            _travelNotificationTime.add(Duration(seconds: -_travelTimerAhead));
        var formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;
        notificationSetString =
            'Travel notification set for $formattedTimeNotification';
        notificationCancelString = 'Travel notification cancelled!';
        alarmSetString = 'Travel alarm set for $formattedTimeAlarm';
        timerSetString = 'Travel timer set for $formattedTimeTimer';
        notificationType = _travelNotificationType;
        notificationIcon = _travelNotificationIcon;
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
              secondsToGo =
                  (energyTicksToGo * _user.energy.interval - consumedTick)
                      .floor();
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

          _energyNotificationTime =
              DateTime.now().add(Duration(seconds: secondsToGo));
          var formattedTime = TimeFormatter(
            inputTime: _energyNotificationTime,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).format;

          if (!percentageError) {
            _customEnergyMaxOverride = false;
            SharedPreferencesModel().setEnergyPercentageOverride(false);
            notificationSetString =
                'Energy notification set for $formattedTime (E$_customEnergyTrigger)';
            alarmSetString =
                'Energy alarm set for $formattedTime (E$_customEnergyTrigger)';
            timerSetString =
                'Energy timer set for $formattedTime (E$_customEnergyTrigger)';
          } else {
            _customEnergyMaxOverride = true;
            SharedPreferencesModel().setEnergyPercentageOverride(true);
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
              secondsToGo =
                  (nerveTicksToGo * _user.nerve.interval - consumedTick)
                      .floor();
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

          _nerveNotificationTime =
              DateTime.now().add(Duration(seconds: secondsToGo));
          var formattedTime = TimeFormatter(
            inputTime: _nerveNotificationTime,
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).format;

          if (!percentageError) {
            _customNerveMaxOverride = false;
            SharedPreferencesModel().setNervePercentageOverride(false);
            notificationSetString =
                'Nerve notification set for $formattedTime (E$_customNerveTrigger)';
            alarmSetString =
                'Nerve alarm set for $formattedTime (E$_customNerveTrigger)';
            timerSetString =
                'Nerve timer set for $formattedTime (E$_customNerveTrigger)';
          } else {
            _customNerveMaxOverride = true;
            SharedPreferencesModel().setNervePercentageOverride(true);
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
        _lifeNotificationTime =
            DateTime.now().add(Duration(seconds: _user.life.fulltime));
        var formattedTime = TimeFormatter(
          inputTime: _lifeNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;
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
        _drugsNotificationTime =
            DateTime.now().add(Duration(seconds: _user.cooldowns.drug));
        var formattedTime = TimeFormatter(
          inputTime: _drugsNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;
        notificationSetString =
            'Drugs cooldown notification set for $formattedTime';
        notificationCancelString = 'Drugs cooldown notification cancelled!';
        alarmSetString = 'Drugs cooldown alarm set for $formattedTime';
        timerSetString = 'Drugs cooldown timer set for $formattedTime';
        notificationType = _drugsNotificationType;
        notificationIcon = _drugsNotificationIcon;
        break;

      case ProfileNotification.medical:
        secondsToGo = _user.cooldowns.medical;
        notificationsPending = _medicalNotificationsPending;
        _medicalNotificationTime =
            DateTime.now().add(Duration(seconds: _user.cooldowns.medical));
        var formattedTime = TimeFormatter(
          inputTime: _medicalNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;
        notificationSetString =
            'Medical cooldown notification set for $formattedTime';
        notificationCancelString = 'Medical cooldown notification cancelled!';
        alarmSetString = 'Medical cooldown alarm set for $formattedTime';
        timerSetString = 'Medical cooldown timer set for $formattedTime';
        notificationType = _medicalNotificationType;
        notificationIcon = _medicalNotificationIcon;
        break;

      case ProfileNotification.booster:
        secondsToGo = _user.cooldowns.booster;
        notificationsPending = _boosterNotificationsPending;
        _boosterNotificationTime =
            DateTime.now().add(Duration(seconds: _user.cooldowns.booster));
        var formattedTime = TimeFormatter(
          inputTime: _boosterNotificationTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;
        notificationSetString =
            'Booster cooldown notification set for $formattedTime';
        notificationCancelString = 'Booster cooldown notification cancelled!';
        alarmSetString = 'Booster cooldown alarm set for $formattedTime';
        timerSetString = 'Booster cooldown timer set for $formattedTime';
        notificationType = _boosterNotificationType;
        notificationIcon = _boosterNotificationIcon;
        break;
    }

    if (secondsToGo == 0 && !percentageError) {
      return SizedBox.shrink();
    } else {
      Color thisColor;
      if (notificationsPending &&
          notificationType == NotificationType.notification) {
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
          size: 22,
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
              } else if (notificationsPending &&
                  notificationType == NotificationType.notification) {
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
    if (_user.cooldowns.drug > 0 ||
        _user.cooldowns.booster > 0 ||
        _user.cooldowns.medical > 0) {
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
    else if (_user.cooldowns.medical >= 21600 &&
        _user.cooldowns.medical < 43200) {
      return Image.asset('images/icons/cooldowns/medical2.png', width: 20);
    } // 12-18 hours
    else if (_user.cooldowns.medical >= 43200 &&
        _user.cooldowns.medical < 64800) {
      return Image.asset('images/icons/cooldowns/medical3.png', width: 20);
    } // 18-24 hours
    else if (_user.cooldowns.medical >= 64800 &&
        _user.cooldowns.medical < 86400) {
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
    else if (_user.cooldowns.booster >= 21600 &&
        _user.cooldowns.booster < 43200) {
      return Image.asset('images/icons/cooldowns/booster2.png', width: 20);
    } // 12-18 hours
    else if (_user.cooldowns.booster >= 43200 &&
        _user.cooldowns.booster < 64800) {
      return Image.asset('images/icons/cooldowns/booster3.png', width: 20);
    } // 18-24 hours
    else if (_user.cooldowns.booster >= 64800 &&
        _user.cooldowns.booster < 86400) {
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
    ).format;
    String diff = _cooldownTimeFormatted(timeEnd);
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
    ).format;
    String diff = _cooldownTimeFormatted(timeEnd);
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
    ).format;
    String diff = _cooldownTimeFormatted(timeEnd);
    return Flexible(
        child: Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text('@ $formattedTime$diff'),
    ));
  }

  String _cooldownTimeFormatted(DateTime timeEnd) {
    var timeDifference = timeEnd.difference(_serverTime);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
    String diff = '';
    if (timeDifference.inMinutes < 1) {
      diff = ', in a few seconds';
    } else if (timeDifference.inMinutes >= 1 && timeDifference.inHours < 24) {
      diff = ', in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
    } else {
      diff =
          ' tomorrow, in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
    }

    /*
    if (timeDifference.inMinutes < 1) {
      diff = ', seconds away';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      diff = ', in 1 minute';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      diff = ', in ${timeDifference.inMinutes} minutes';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      diff = ', in 1 hour';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      diff = ', in ${timeDifference.inHours} hours';
    } else {
      diff = ' tomorrow, in ${timeDifference.inHours} hours';
    }
    */

    return diff;
  }

  Card _eventsTimeline() {
    int maxToShow = _eventsShowNumber;

    // Some users might an empty events map. This is why we have the events parameters as dynamic
    // in OwnProfile Model. We need to check if it contains several elements, in which case we
    // create a map in a new variable. Otherwise, we return an empty Card.
    var events = Map<String, Event>();
    if (_user.events.length > 0) {
      events = Map.from(_user.events)
          .map((k, v) => MapEntry<String, Event>(k, Event.fromJson(v)));
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
      message = message.replaceAll('View the details here!', '');
      message = message.replaceAll('Please click here to continue.', '');
      message = message.replaceAll(' [view]', '.');
      message = message.replaceAll(' [View]', '');
      message = message.replaceAll(' Please click here.', '');
      message =
          message.replaceAll(' Please click here to collect your funds.', '');

      Widget insideIcon = _eventsInsideIconCases(message);

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
                  _openTornBrowser("https://www.torn.com/events.php#/step=all");
                },
                onTap: () {
                  _settingsProvider.useQuickBrowser
                      ? openBrowserDialog(
                          context, "https://www.torn.com/events.php#/step=all")
                      : _openTornBrowser(
                          "https://www.torn.com/events.php#/step=all");
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
              fontWeight:
                  unreadCount == 0 ? FontWeight.normal : FontWeight.bold,
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

  Widget _eventsInsideIconCases(String message) {
    Widget insideIcon;
    if (message.contains('revive')) {
      insideIcon = Icon(
        Icons.local_hospital,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('the director of')) {
      insideIcon = Icon(
        Icons.work,
        color: Colors.brown[300],
        size: 20,
      );
    } else if (message.contains('jail') || message.contains('arrested you')) {
      insideIcon = Center(
        child: Image.asset(
          'images/icons/jail.png',
          width: 20,
          height: 20,
        ),
      );
    } else if (message.contains('trade')) {
      insideIcon = Icon(
        Icons.switch_camera,
        color: Colors.purple,
        size: 20,
      );
    } else if (message.contains('has given you') ||
        message.contains('You were sent') ||
        message.contains('You have been credited with') ||
        message.contains('on your doorstep')) {
      insideIcon = Icon(
        Icons.card_giftcard,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('Get out of my education') ||
        message.contains('You must have overdosed')) {
      insideIcon = Icon(
        Icons.warning,
        color: Colors.red,
        size: 20,
      );
    } else if (message.contains('purchased membership')) {
      insideIcon = Icon(
        Icons.fitness_center,
        color: Colors.black54,
        size: 20,
      );
    } else if (message.contains('You upgraded your level')) {
      insideIcon = Icon(
        Icons.file_upload,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('won') ||
        message.contains('lottery') ||
        message.contains('check has been credited to your') ||
        message.contains('withdraw your check from the bank') ||
        message.contains('Your bank investment has ended') ||
        message.contains('You were given \$')) {
      insideIcon = Icon(
        Icons.monetization_on,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('attacked you') ||
        message.contains('mugged you and stole') ||
        message.contains('attacked and hospitalized')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/ic_target_account_black_48dp.png',
            width: 20,
            height: 20,
            color: Colors.red,
          ),
        ),
      );
    } else if (message.contains('You and your team') ||
        message.contains('You have been selected') ||
        message.contains('canceled the')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/ic_pistol_black_48dp.png',
            width: 20,
            height: 20,
            color: Colors.blue,
          ),
        ),
      );
    } else if (message.contains('You left your faction') ||
        message.contains('Your application to') ||
        message.contains('canceled the')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/faction.png',
            width: 20,
            height: 20,
            color: Colors.black,
          ),
        ),
      );
    } else if (message.contains('You came') ||
        message.contains('race.') ||
        message.contains('race and have received') ||
        message.contains('Your best lap was')) {
      insideIcon = Icon(
        MdiIcons.gauge,
        color: Colors.red[500],
        size: 20,
      );
    } else if (message.contains('Your bug report')) {
      insideIcon = Icon(
        MdiIcons.bug,
        color: Colors.red[500],
        size: 20,
      );
    } else if (message.contains('You can begin programming a new virus')) {
      insideIcon = Icon(
        MdiIcons.virusOutline,
        color: Colors.red[500],
        size: 20,
      );
    } else if (message.contains('from your bazaar for')) {
      insideIcon = Icon(
        MdiIcons.store,
        color: Colors.green,
        size: 20,
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

  Card _messagesTimeline() {
    int maxToShow = _messagesShowNumber;

    // Some users might an empty messages map. This is why we have the events parameters as dynamic
    // in OwnProfile Model. We need to check if it contains several elements, in which case we
    // create a map in a new variable. Otherwise, we return an empty Card.
    var messages = Map<String, TornMessage>();
    if (_user.messages.length > 0) {
      messages = Map.from(_user.messages).map(
          (k, v) => MapEntry<String, TornMessage>(k, TornMessage.fromJson(v)));
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

      String title = EmojiParser.fix(msg.title);
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

      var messageTime =
          DateTime.fromMillisecondsSinceEpoch(msg.timestamp * 1000);

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
                          _openTornBrowser(
                              "https://www.torn.com/messages.php#/p=read&ID="
                              "${messages.keys.elementAt(i)}&suffix=inbox");
                        },
                        onTap: () {
                          _settingsProvider.useQuickBrowser
                              ? openBrowserDialog(
                                  context,
                                  "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox",
                                )
                              : _openTornBrowser(
                                  "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox");
                        },
                      )
                    : GestureDetector(
                        child: Icon(Icons.mark_as_unread),
                        onLongPress: () {
                          _openTornBrowser(
                              "https://www.torn.com/messages.php#/p=read&ID="
                              "${messages.keys.elementAt(i)}&suffix=inbox");
                        },
                        onTap: () {
                          _settingsProvider.useQuickBrowser
                              ? openBrowserDialog(
                                  context,
                                  "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox",
                                )
                              : _openTornBrowser(
                                  "https://www.torn.com/messages.php#/p=read&ID="
                                  "${messages.keys.elementAt(i)}&suffix=inbox");
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
    var lastMessageDate = DateTime.fromMillisecondsSinceEpoch(
        messages.values.last.timestamp * 1000);
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
                  _openTornBrowser("https://www.torn.com/messages.php");
                },
                onTap: () {
                  _settingsProvider.useQuickBrowser
                      ? openBrowserDialog(
                          context,
                          "https://www.torn.com/messages.php",
                        )
                      : _openTornBrowser("https://www.torn.com/messages.php");
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
                  fontWeight: unreadRecentCount == 0
                      ? FontWeight.normal
                      : FontWeight.bold,
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

    double totalEffective = strengthModifiedTotal +
        speedModifiedTotal +
        defenseModifiedTotal +
        dexModifiedTotal;

    int totalEffectiveModifier =
        ((totalEffective - _miscModel.total) * 100 / _miscModel.total).round();

    return Card(
      child: ExpandablePanel(
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
            ],
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(25, 5, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cashWallet(),
              SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onLongPress: () {
                      _openTornBrowser('https://www.torn.com/points.php');
                    },
                    onTap: () async {
                      _settingsProvider.useQuickBrowser
                          ? await openBrowserDialog(
                              context,
                              'https://www.torn.com/points.php',
                            )
                          : _openTornBrowser('https://www.torn.com/points.php');
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
              SizedBox(height: 8),
              Text('Battle: ${decimalFormat.format(_miscModel.total)}'),
              SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Battle (effective): ${decimalFormat.format(totalEffective)}',
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
              SizedBox(height: 8),
              Text('MAN: ${decimalFormat.format(_miscModel.manualLabor)}'),
              Text('INT: ${decimalFormat.format(_miscModel.intelligence)}'),
              Text('END: ${decimalFormat.format(_miscModel.endurance)}'),
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
                    Text('Rank: ${_user.rank}'),
                    Text('Age: ${_user.age}'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _cashWallet(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        _openTornBrowser('https://www.torn.com/points.php');
                      },
                      onTap: () async {
                        _settingsProvider.useQuickBrowser
                            ? await openBrowserDialog(
                                context,
                                'https://www.torn.com/points.php',
                              )
                            : _openTornBrowser(
                                'https://www.torn.com/points.php');
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
                        Text(
                            'Strength: ${decimalFormat.format(_miscModel.strength)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.strength * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                            'Defense: ${decimalFormat.format(_miscModel.defense)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.defense * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                            'Speed: ${decimalFormat.format(_miscModel.speed)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.speed * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                            'Dexterity: ${decimalFormat.format(_miscModel.dexterity)}'),
                        Text(
                          " (${decimalFormat.format(_miscModel.dexterity * 100 / _miscModel.total)}%)",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 50,
                      child: Divider(
                          color: _themeProvider.mainText, thickness: 0.5),
                    ),
                    Text('Total: ${decimalFormat.format(_miscModel.total)}'),
                  ],
                ),
              ),
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
                        Text(
                            'Strength: ${decimalFormat.format(strengthModifiedTotal)}'),
                        strengthModified
                            ? Text(
                                " $strengthString",
                                style: TextStyle(
                                    color: strengthColor, fontSize: 12),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                            'Defense: ${decimalFormat.format(defenseModifiedTotal)}'),
                        defenseModified
                            ? Text(
                                " $defenseString",
                                style: TextStyle(
                                    color: defenseColor, fontSize: 12),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                            'Speed: ${decimalFormat.format(speedModifiedTotal)}'),
                        speedModified
                            ? Text(
                                " $speedString",
                                style:
                                    TextStyle(color: speedColor, fontSize: 12),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                            'Dexterity: ${decimalFormat.format(dexModifiedTotal)}'),
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
                      child: Divider(
                          color: _themeProvider.mainText, thickness: 0.5),
                    ),
                    Text(
                      'Total: ${decimalFormat.format(totalEffective)}',
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Manual labor: ${decimalFormat.format(_miscModel.manualLabor)}'),
                    Text(
                        'Intelligence: ${decimalFormat.format(_miscModel.intelligence)}'),
                    Text(
                        'Endurance: ${decimalFormat.format(_miscModel.endurance)}'),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cashWallet() {
    if (_user.networth["wallet"] != null) {
      final moneyFormat = new NumberFormat("#,##0", "en_US");
      return Row(children: [
        GestureDetector(
          onLongPress: () async {
            _openWalletDialog(context, longPress: true);
          },
          onTap: () async {
            _settingsProvider.useQuickBrowser
                ? _openWalletDialog(context, longPress: false)
                : _openWalletDialog(context, longPress: true);
          },
          child: Icon(
            MdiIcons.cashUsdOutline,
            color: Colors.green,
          ),
        ),
        SizedBox(width: 5),
        Text('\$${moneyFormat.format(_user.networth["wallet"])}')
      ]);
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
        racingString = _user.icons.icon17.replaceAll("Racing - ", '');
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
              openBrowserDialog(
                  context, 'https://www.torn.com/loader.php?sid=racing');
            },
            onTap: () {
              _settingsProvider.useQuickBrowser
                  ? _openTornBrowser("racing")
                  : openBrowserDialog(
                      context, 'https://www.torn.com/loader.php?sid=racing');
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Icon(MdiIcons.openInApp, size: 18),
            ),
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
      var timeExpiry =
          DateTime.now().add(Duration(seconds: _miscModel.cityBank.timeLeft));
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
      var timeExpiry =
          DateTime.now().add(Duration(seconds: _miscModel.educationTimeleft));
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
                text: "Your education in ",
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
                  TextSpan(text: " will end in "),
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
      if (_miscModel.educationCompleted.length <
          _tornEducationModel.education.length) {
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

    if (!showMisc) {
      return SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
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
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: addictionWidget,
                ),
                if (addictionActive && racingActive) SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: racingWidget,
                ),
                if ((addictionActive || racingActive) && bankActive)
                  SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: bankWidget,
                ),
                if ((addictionActive || racingActive || bankActive) &&
                    educationActive)
                  SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: educationWidget,
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
      } else {
        source = "${v.key[0].toUpperCase()}${v.key.substring(1)}";
      }

      moneySources.add(
        Row(
          children: <Widget>[
            SizedBox(
              height: 20,
              width: 110,
              child: Text('$source: '),
            ),
            Text(
              '\$${moneyFormat.format(v.value.round())}',
              style: TextStyle(
                color: v.value < 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: ExpandablePanel(
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
    var apiResponse =
        await TornApiCaller.ownProfile(_userProvider.myUser.userApiKey)
            .getOwnProfile;
    var apiChain = await TornApiCaller.chain(_userProvider.myUser.userApiKey)
        .getChainStatus;

    setState(() {
      if (apiResponse is OwnProfileModel) {
        _apiRetries = 0;
        _user = apiResponse;
        _serverTime =
            DateTime.fromMillisecondsSinceEpoch(_user.serverTime * 1000);
        _apiGoodData = true;

        // If max values have decreased or were never initialized
        if (_customEnergyTrigger > _user.energy.maximum ||
            _customEnergyTrigger == 0) {
          _customEnergyTrigger = _user.energy.maximum;
          SharedPreferencesModel()
              .setEnergyNotificationValue(_customEnergyTrigger);
        }
        if (_customNerveTrigger > _user.nerve.maximum ||
            _customNerveTrigger == 0) {
          _customNerveTrigger = _user.nerve.maximum;
          SharedPreferencesModel()
              .setNerveNotificationValue(_customNerveTrigger);
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
          var error = apiResponse as ApiError;
          _apiError = error.errorReason;
          _apiRetries = 0;
        }
      }
    });

    // We get education and money (with ProfileMiscModel) separately and only once per load
    // and then on onResumed
    if (_apiGoodData && !_miscApiFetched) {
      await _getMiscInformation();
    }

    _retrievePendingNotifications();
  }

  Future _getMiscInformation() async {
    _miscApiFetched = true;
    try {
      var miscApiResponse =
          await TornApiCaller.ownProfileMisc(_userProvider.myUser.userApiKey)
              .getOwnProfileMisc;
      var educationResponse =
          await TornApiCaller.education(_userProvider.myUser.userApiKey)
              .getEducation;
      if (miscApiResponse is OwnProfileMiscModel &&
          educationResponse is TornEducationModel) {
        setState(() {
          _miscModel = miscApiResponse;
          _tornEducationModel = educationResponse;
        });
      }
    } catch (e) {
      // If something fails, we simple don't show the MISC section
    }
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      //animatedIcon: AnimatedIcons.menu_close,
      //animatedIconTheme: IconThemeData(size: 22.0),
      openCloseDial: speedDialSetOpen,
      onOpen: () {
        setState(() {
          speedDialSetOpen.value = true;
        });
      },
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
            image: AssetImage("images/icons/torn_t_logo.png"),
          ),
        ),
      ),
      visible: dialVisible,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: GestureDetector(
            onTap: () async {
              _settingsProvider.useQuickBrowser
                  ? openBrowserDialog(context, 'https://www.torn.com/city.php')
                  : _openTornBrowser('city');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            onLongPress: () {
              _openTornBrowser('city');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            // Needs a container and color to allow taps on the full circle, not
            // only on the icon.
            child: Container(
              width: 100,
              height: 100,
              color: Colors.transparent,
              child: Icon(
                MdiIcons.cityVariantOutline,
                color: Colors.black,
              ),
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
          child: GestureDetector(
            onTap: () async {
              _settingsProvider.useQuickBrowser
                  ? openBrowserDialog(context, 'https://www.torn.com/trade.php')
                  : _openTornBrowser('trades');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            onLongPress: () {
              _openTornBrowser('trades');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            // Needs a container and color to allow taps on the full circle, not
            // only on the icon.
            child: Container(
              width: 100,
              height: 100,
              color: Colors.transparent,
              child: Icon(
                MdiIcons.accountSwitchOutline,
                color: Colors.black,
              ),
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
          child: GestureDetector(
            onTap: () async {
              _settingsProvider.useQuickBrowser
                  ? openBrowserDialog(context, 'https://www.torn.com/item.php')
                  : _openTornBrowser('items');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            onLongPress: () {
              _openTornBrowser('items');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            // Needs a container and color to allow taps on the full circle, not
            // only on the icon.
            child: Container(
              width: 100,
              height: 100,
              color: Colors.transparent,
              child: Icon(
                Icons.card_giftcard,
                color: Colors.black,
              ),
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
          child: GestureDetector(
            onTap: () async {
              _settingsProvider.useQuickBrowser
                  ? openBrowserDialog(
                      context, 'https://www.torn.com/crimes.php#/step=main')
                  : _openTornBrowser('crimes');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            onLongPress: () {
              _openTornBrowser('crimes');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            // Needs a container and color to allow taps on the full circle, not
            // only on the icon.
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
          child: GestureDetector(
            onTap: () async {
              _settingsProvider.useQuickBrowser
                  ? openBrowserDialog(context, 'https://www.torn.com/gym.php')
                  : _openTornBrowser('gym');

              if (_warnAboutChains &&
                  _chainModel.chain.current > 10 &&
                  _chainModel.chain.cooldown == 0) {
                BotToast.showText(
                  text: 'Caution: your faction is chaining!',
                  align: Alignment(0, 0),
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.blue,
                  duration: Duration(seconds: 2),
                  contentPadding: EdgeInsets.all(10),
                );
              }
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            onLongPress: () {
              _openTornBrowser('gym');
              if (_warnAboutChains &&
                  _chainModel.chain.current > 10 &&
                  _chainModel.chain.cooldown == 0) {
                BotToast.showText(
                  text: 'Caution: your faction is chaining!',
                  align: Alignment(0, 0),
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.blue,
                  duration: Duration(seconds: 2),
                  contentPadding: EdgeInsets.all(10),
                );
              }
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            // Needs a container and color to allow taps on the full circle, not
            // only on the icon.
            child: Container(
              width: 100,
              height: 100,
              color: Colors.transparent,
              child: Icon(
                Icons.fitness_center,
                color: Colors.black,
              ),
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
          child: GestureDetector(
            onTap: () async {
              _settingsProvider.useQuickBrowser
                  ? openBrowserDialog(context, 'https://www.torn.com')
                  : _openTornBrowser('home');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            onLongPress: () {
              _openTornBrowser('home');
              setState(() {
                speedDialSetOpen.value = false;
              });
            },
            // Needs a container and color to allow taps on the full circle, not
            // only on the icon.
            child: Container(
              width: 100,
              height: 100,
              color: Colors.transparent,
              child: Icon(
                Icons.home_outlined,
                color: Colors.black,
              ),
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

  Future _openTornBrowser(String page) async {
    var tornPage = '';
    switch (page) {
      case 'home':
        tornPage = 'https://www.torn.com';
        break;
      case 'gym':
        tornPage = 'https://www.torn.com/gym.php';
        break;
      case 'crimes':
        tornPage = 'https://www.torn.com/crimes.php#/step=main';
        break;
      case 'items':
        tornPage = 'https://www.torn.com/item.php';
        break;
      case 'events':
        tornPage = 'https://www.torn.com/events.php#/step=all';
        break;
      case 'trades':
        tornPage = 'https://www.torn.com/trade.php';
        break;
      case 'city':
        tornPage = 'https://www.torn.com/city.php';
        break;
      case 'racing':
        tornPage = 'https://www.torn.com/loader.php?sid=racing';
        break;
      default:
        tornPage = page;
        break;
    }

    var browserType = _settingsProvider.currentBrowser;

    switch (browserType) {
      case BrowserSetting.app:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => WebViewFull(
              customUrl: tornPage,
              customTitle: 'Torn',
              customCallBack: _updateCallback,
            ),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = tornPage;
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
  }

  void setDialVisible(bool value) {
    setState(() {
      dialVisible = value;
    });
  }

  Future _updateCallback() async {
    // Even if this implies colling the app twice, it enhances player
    // experience as the bars are updated quickly after a change
    // In turn, we only call the API every 30 seconds with the timer
    await Future.delayed(Duration(seconds: 10));
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
        secondsToNotification =
            _travelNotificationTime.difference(DateTime.now()).inSeconds -
                _travelNotificationAhead;
        channelTitle = 'Travel';
        channelSubtitle = 'Travel Full';
        channelDescription =
            'Urgent notifications about arriving to destination';
        notificationTitle = _travelNotificationTitle;
        notificationSubtitle = _travelNotificationBody;
        notificationPayload += 'travel';
        notificationIconAndroid = "notification_travel";
        notificationIconColor = Colors.blue;
        break;
      case ProfileNotification.energy:
        notificationId = 101;
        secondsToNotification =
            _energyNotificationTime.difference(DateTime.now()).inSeconds;
        channelTitle = 'Energy';
        channelSubtitle = 'Energy Full';
        channelDescription = 'Urgent notifications about energy';
        notificationTitle = 'Energy bar';
        notificationSubtitle = 'Here is your energy reminder!';
        var myTimeStamp =
            (_energyNotificationTime.millisecondsSinceEpoch / 1000).floor();
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_energy";
        notificationIconColor = Colors.green;
        break;
      case ProfileNotification.nerve:
        notificationId = 102;
        secondsToNotification =
            _nerveNotificationTime.difference(DateTime.now()).inSeconds;
        channelTitle = 'Nerve';
        channelSubtitle = 'Nerve Full';
        channelDescription = 'Urgent notifications about nerve';
        notificationTitle = 'Nerve bar';
        notificationSubtitle = 'Here is your nerve reminder!';
        var myTimeStamp =
            (_nerveNotificationTime.millisecondsSinceEpoch / 1000).floor();
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_nerve";
        notificationIconColor = Colors.red;
        break;
      case ProfileNotification.life:
        notificationId = 103;
        secondsToNotification = _user.life.fulltime;
        channelTitle = 'Life';
        channelSubtitle = 'Life Full';
        channelDescription = 'Urgent notifications about life';
        notificationTitle = 'Life bar';
        notificationSubtitle = 'Here is your life reminder!';
        var myTimeStamp =
            (DateTime.now().millisecondsSinceEpoch / 1000).floor() +
                _user.life.fulltime;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
      case ProfileNotification.drugs:
        notificationId = 104;
        secondsToNotification = _user.cooldowns.drug;
        channelTitle = 'Drugs';
        channelSubtitle = 'Drugs Expired';
        channelDescription = 'Urgent notifications about drugs cooldown';
        notificationTitle = 'Drug Cooldown';
        notificationSubtitle = 'Here is your drugs cooldown reminder!';
        var myTimeStamp =
            (DateTime.now().millisecondsSinceEpoch / 1000).floor() +
                _user.cooldowns.drug;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
      case ProfileNotification.medical:
        notificationId = 105;
        secondsToNotification = _user.cooldowns.medical;
        channelTitle = 'Medical';
        channelSubtitle = 'Medical Expired';
        channelDescription = 'Urgent notifications about medical cooldown';
        notificationTitle = 'Medical Cooldown';
        notificationSubtitle = 'Here is your medical cooldown reminder!';
        var myTimeStamp =
            (DateTime.now().millisecondsSinceEpoch / 1000).floor() +
                _user.cooldowns.medical;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
      case ProfileNotification.booster:
        notificationId = 106;
        secondsToNotification = _user.cooldowns.booster;
        channelTitle = 'Booster';
        channelSubtitle = 'Booster Expired';
        channelDescription = 'Urgent notifications about booster cooldown';
        notificationTitle = 'Booster Cooldown';
        notificationSubtitle = 'Here is your booster cooldown reminder!';
        var myTimeStamp =
            (DateTime.now().millisecondsSinceEpoch / 1000).floor() +
                _user.cooldowns.booster;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        break;
    }

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
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: notificationIconAndroid,
      sound: RawResourceAndroidNotificationSound('slow_spring_board'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      color: notificationIconColor,
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
      tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsToNotification)),
      platformChannelSpecifics,
      payload: notificationPayload,
      androidAllowWhileIdle: true, // Deliver at exact time
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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

    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

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
        }
      }
    }

    setState(() {
      _travelNotificationsPending = travel;
      _energyNotificationsPending = energy;
      _nerveNotificationsPending = nerve;
      _lifeNotificationsPending = life;
      _drugsNotificationsPending = drugs;
      _medicalNotificationsPending = medical;
      _boosterNotificationsPending = booster;
    });
  }

  Future<void> _cancelNotifications(
      ProfileNotification profileNotification) async {
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
    }

    _retrievePendingNotifications();
  }

  void _checkIfNotificationsAreCurrent() async {
    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    if (pendingNotificationRequests.length == 0) {
      return;
    }

    bool triggered = false;
    var updatedTypes = <String>[];
    var updatedTimes = <String>[];
    var formatter = new DateFormat('HH:mm');

    for (var notification in pendingNotificationRequests) {
      // Don't take into account other kind of notifications,
      // as they don't have the same payload with timestamp
      if (notification.id == 999 ||
          notification.payload.substring(0, 3).contains('400')) {
        continue;
      }
      var splitPayload = notification.payload.split('-');
      var oldTimeStamp = int.parse(splitPayload[1]);

      // ENERGY
      if (notification.payload.contains('energy')) {
        var customTriggerRoundedUp = (_customEnergyTrigger + 4) / 5 * 5;
        if (_user.energy.current >= _user.energy.maximum ||
            (!_customEnergyMaxOverride &&
                _user.energy.current > customTriggerRoundedUp)) {
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
        if (_customEnergyMaxOverride &&
            _customEnergyTrigger < _user.energy.current) {
          var newCalculation = DateTime.now()
                  .add(Duration(seconds: _user.energy.fulltime))
                  .millisecondsSinceEpoch /
              1000;
          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.energy);
            _scheduleNotification(ProfileNotification.energy);
            triggered = true;
            updatedTypes.add('energy');
            var energyCurrentSchedule =
                DateTime.now().add(Duration(seconds: _user.energy.fulltime));
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
              newSecondsToGo =
                  (energyTicksToGo * _user.energy.interval - consumedTick)
                      .floor();
            } else if (energyTicksToGo > 0 && energyTicksToGo <= 1) {
              newSecondsToGo = _user.energy.ticktime;
            }
          }

          var newCalculation = DateTime.now()
                  .add(Duration(seconds: newSecondsToGo))
                  .millisecondsSinceEpoch /
              1000;

          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.energy);
            _energyNotificationTime =
                DateTime.now().add(Duration(seconds: newSecondsToGo));
            _scheduleNotification(ProfileNotification.energy);
            triggered = true;
            updatedTypes.add('energy');
            var energyCurrentSchedule =
                DateTime.now().add(Duration(seconds: newSecondsToGo));
            updatedTimes.add(formatter.format(energyCurrentSchedule));
          }
        }
        // NERVE
      } else if (notification.payload.contains('nerve')) {
        if (_user.nerve.current >= _user.nerve.maximum ||
            (!_customNerveMaxOverride &&
                _user.nerve.current > _customNerveTrigger)) {
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
        if (_customNerveMaxOverride &&
            _customNerveTrigger < _user.nerve.current) {
          var newCalculation = DateTime.now()
                  .add(Duration(seconds: _user.nerve.fulltime))
                  .millisecondsSinceEpoch /
              1000;
          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.nerve);
            _scheduleNotification(ProfileNotification.nerve);
            triggered = true;
            updatedTypes.add('nerve');
            var nerveCurrentSchedule =
                DateTime.now().add(Duration(seconds: _user.nerve.fulltime));
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
              newSecondsToGo =
                  (nerveTicksToGo * _user.nerve.interval - consumedTick)
                      .floor();
            } else if (nerveTicksToGo > 0 && nerveTicksToGo <= 1) {
              newSecondsToGo = _user.nerve.ticktime;
            }
          }

          var newCalculation = DateTime.now()
                  .add(Duration(seconds: newSecondsToGo))
                  .millisecondsSinceEpoch /
              1000;

          var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.nerve);
            _nerveNotificationTime =
                DateTime.now().add(Duration(seconds: newSecondsToGo));
            _scheduleNotification(ProfileNotification.nerve);
            triggered = true;
            updatedTypes.add('nerve');
            var nerveCurrentSchedule =
                DateTime.now().add(Duration(seconds: newSecondsToGo));
            updatedTimes.add(formatter.format(nerveCurrentSchedule));
          }
        }
        // LIFE
      } else if (notification.payload.contains('life')) {
        var newCalculation = DateTime.now()
                .add(Duration(seconds: _user.life.fulltime))
                .millisecondsSinceEpoch /
            1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.life);
          _scheduleNotification(ProfileNotification.life);
          triggered = true;
          updatedTypes.add('life');
          var lifeCurrentSchedule =
              DateTime.now().add(Duration(seconds: _user.life.fulltime));
          updatedTimes.add(formatter.format(lifeCurrentSchedule));
        }
        // DRUGS
      } else if (notification.payload.contains('drugs')) {
        var newCalculation = DateTime.now()
                .add(Duration(seconds: _user.cooldowns.drug))
                .millisecondsSinceEpoch /
            1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.drugs);
          _scheduleNotification(ProfileNotification.drugs);
          triggered = true;
          updatedTypes.add('drugs');
          var drugsCurrentSchedule =
              DateTime.now().add(Duration(seconds: _user.cooldowns.drug));
          updatedTimes.add(formatter.format(drugsCurrentSchedule));
        }
        // MEDICAL
      } else if (notification.payload.contains('medical')) {
        var newCalculation = DateTime.now()
                .add(Duration(seconds: _user.cooldowns.medical))
                .millisecondsSinceEpoch /
            1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.medical);
          _scheduleNotification(ProfileNotification.medical);
          triggered = true;
          updatedTypes.add('medical');
          var medicalCurrentSchedule =
              DateTime.now().add(Duration(seconds: _user.cooldowns.medical));
          updatedTimes.add(formatter.format(medicalCurrentSchedule));
        }
        // BOOSTER
      } else if (notification.payload.contains('booster')) {
        var newCalculation = DateTime.now()
                .add(Duration(seconds: _user.cooldowns.booster))
                .millisecondsSinceEpoch /
            1000;
        var compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.booster);
          _scheduleNotification(ProfileNotification.booster);
          triggered = true;
          updatedTypes.add('booster');
          var boosterCurrentSchedule =
              DateTime.now().add(Duration(seconds: _user.cooldowns.booster));
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

  Future _loadPreferences() async {
    // TRAVEL
    var travel = await SharedPreferencesModel().getTravelNotificationType();
    _travelNotificationTitle =
        await SharedPreferencesModel().getTravelNotificationTitle();
    _travelNotificationBody =
        await SharedPreferencesModel().getTravelNotificationBody();
    _travelAlarmSound = await SharedPreferencesModel().getTravelAlarmSound();
    _travelAlarmVibration =
        await SharedPreferencesModel().getTravelAlarmVibration();
    var travelNotificationAhead =
        await SharedPreferencesModel().getTravelNotificationAhead();
    var travelAlarmAhead = await SharedPreferencesModel().getTravelAlarmAhead();
    var travelTimerAhead = await SharedPreferencesModel().getTravelTimerAhead();

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

    setState(() {
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
    });
    // TRAVEL ENDS

    var energy = await SharedPreferencesModel().getEnergyNotificationType();
    _customEnergyTrigger =
        await SharedPreferencesModel().getEnergyNotificationValue();
    _customEnergyMaxOverride =
        await SharedPreferencesModel().getEnergyPercentageOverride();

    var nerve = await SharedPreferencesModel().getNerveNotificationType();
    _customNerveTrigger =
        await SharedPreferencesModel().getNerveNotificationValue();
    _customNerveMaxOverride =
        await SharedPreferencesModel().getNervePercentageOverride();

    var life = await SharedPreferencesModel().getLifeNotificationType();
    var drugs = await SharedPreferencesModel().getDrugNotificationType();
    var medical = await SharedPreferencesModel().getMedicalNotificationType();
    var booster = await SharedPreferencesModel().getBoosterNotificationType();

    _alarmSound = await SharedPreferencesModel().getProfileAlarmSound();
    _alarmVibration = await SharedPreferencesModel().getProfileAlarmVibration();

    _nukeReviveActive = await SharedPreferencesModel().getUseNukeRevive();
    _warnAboutChains = await SharedPreferencesModel().getWarnAboutChains();
    _shortcutsEnabled = await SharedPreferencesModel().getEnableShortcuts();

    setState(() {
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
    });

    setState(() {
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
    });

    setState(() {
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
    });

    setState(() {
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
    });

    setState(() {
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
    });

    setState(() {
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
    });

    var expandEvents = await SharedPreferencesModel().getExpandEvents();
    var eventsNumber = await SharedPreferencesModel().getEventsShowNumber();
    var expandMessages = await SharedPreferencesModel().getExpandMessages();
    var messagesNumber = await SharedPreferencesModel().getMessagesShowNumber();
    var expandBasicInfo = await SharedPreferencesModel().getExpandBasicInfo();
    var expandNetworth = await SharedPreferencesModel().getExpandNetworth();
    setState(() {
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
        var alarmTime =
            _travelNotificationTime.add(Duration(minutes: -_travelAlarmAhead));
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
    }

    // Travel sound and vibration is configured from the travel section
    String thisSound;
    if (profileNotification == ProfileNotification.travel) {
      if (_travelAlarmSound) {
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
      if (_travelAlarmVibration) {
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
        totalSeconds =
            _travelNotificationTime.difference(DateTime.now()).inSeconds -
                _travelTimerAhead;
        message = 'Torn PDA Travel';
        break;
      case ProfileNotification.energy:
        totalSeconds =
            _energyNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Energy';
        break;
      case ProfileNotification.nerve:
        totalSeconds =
            _nerveNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Nerve';
        break;
      case ProfileNotification.life:
        totalSeconds =
            _lifeNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Life';
        break;
      case ProfileNotification.drugs:
        totalSeconds =
            _drugsNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Drugs';
        break;
      case ProfileNotification.medical:
        totalSeconds =
            _medicalNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Medical';
        break;
      case ProfileNotification.booster:
        totalSeconds =
            _boosterNotificationTime.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Booster';
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

  void _refreshTctClock() {
    setState(() {
      _currentTctTime = DateTime.now().toUtc();
    });
  }

  void _callBackFromNotificationOptions() async {
    await _loadPreferences();
    _checkIfNotificationsAreCurrent();
  }

  Future<void> _openNukeReviveDialog(BuildContext _) {
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
                    margin: EdgeInsets.only(top: 15),
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
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "REQUEST A REVIVE FROM NUKE",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _themeProvider.mainText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: EasyRichText(
                            "Nuke is a premium Torn reviving service consisting in more than "
                            "300 revivers. You can find more information in the forums or "
                            "in the Central Hospital Discord server.",
                            defaultStyle: TextStyle(
                                fontSize: 13, color: _themeProvider.mainText),
                            patternList: [
                              EasyRichTextPattern(
                                targetString: 'forums',
                                style: TextStyle(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    _settingsProvider.useQuickBrowser
                                        ? openBrowserDialog(context,
                                            'https://www.torn.com/forums.php#/p=threads&f=14&t=16160853&b=0&a=0')
                                        : _openTornBrowser(
                                            'https://www.torn.com/forums.php#/p=threads&f=14&t=16160853&b=0&a=0');
                                  },
                              ),
                              EasyRichTextPattern(
                                targetString: 'Central Hospital',
                                style: TextStyle(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    _settingsProvider.useQuickBrowser
                                        ? openBrowserDialog(context,
                                            'https://discord.gg/qSHjTXx')
                                        : _openTornBrowser(
                                            'https://discord.gg/qSHjTXx');
                                  },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Each revive must be paid directly to the reviver (unless under a "
                            "contract with Nuke) and costs \$1 million or 1 Xanax.",
                            style: TextStyle(
                                fontSize: 13, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Please keep in mind if you don't pay for the requested revive, "
                            "you risk getting blocked from Nuke!",
                            style: TextStyle(
                                fontSize: 13, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Text("Medic!"),
                              onPressed: () async {
                                var nuke = NukeRevive(
                                  playerId: _user.playerId.toString(),
                                  playerName: _user.name,
                                  playerFaction: _user.faction.factionName,
                                  playerLocation: _user.travel.destination,
                                );
                                nuke.callMedic().then((value) {
                                  if (value.isNotEmpty) {
                                    BotToast.showText(
                                      text: value,
                                      textStyle: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.green[800],
                                      duration: Duration(seconds: 5),
                                      contentPadding: EdgeInsets.all(10),
                                    );
                                  } else {
                                    BotToast.showText(
                                      text:
                                          'There was an error contacting Nuke, try again later '
                                          'or contact them through Central Hospital\'s Discord '
                                          'server!',
                                      textStyle: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.red[800],
                                      duration: Duration(seconds: 5),
                                      contentPadding: EdgeInsets.all(10),
                                    );
                                  }
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            FlatButton(
                              child: Text("Cancel"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
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
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Image.asset(
                          'images/icons/nuke-revive.png',
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

  Future<void> _openWalletDialog(BuildContext _, {bool longPress = false}) {
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
                      margin: EdgeInsets.only(top: 15),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: RaisedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Image.asset(
                                    'images/icons/home/vault.png',
                                    width: 15,
                                    height: 15,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 15),
                                  Text("Personal vault"),
                                ],
                              ),
                              onPressed: () async {
                                var url =
                                    "https://www.torn.com/properties.php#/p=options&tab=vault";
                                if (longPress) {
                                  Navigator.of(context).pop();
                                  await _openTornBrowser(url);
                                } else {
                                  Navigator.of(context).pop();
                                  await openBrowserDialog(context, url);
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: RaisedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Image.asset(
                                    'images/icons/faction.png',
                                    width: 15,
                                    height: 15,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 15),
                                  Text("Faction vault"),
                                ],
                              ),
                              onPressed: () async {
                                var url =
                                    'https://www.torn.com/factions.php?step=your#/tab=armoury';
                                if (longPress) {
                                  Navigator.of(context).pop();
                                  await _openTornBrowser(url);
                                } else {
                                  Navigator.of(context).pop();
                                  await openBrowserDialog(context, url);
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: RaisedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Image.asset(
                                    'images/icons/home/job.png',
                                    width: 15,
                                    height: 15,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 15),
                                  Text("Company vault"),
                                ],
                              ),
                              onPressed: () async {
                                var url =
                                    'https://www.torn.com/companies.php#/option=funds';
                                if (longPress) {
                                  Navigator.of(context).pop();
                                  await _openTornBrowser(url);
                                } else {
                                  Navigator.of(context).pop();
                                  await openBrowserDialog(context, url);
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          FlatButton(
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
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
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
}
