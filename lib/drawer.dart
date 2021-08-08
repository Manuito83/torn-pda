// Dart imports:
import 'dart:async';
import 'dart:io';
// Package imports:
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/pages/about.dart';
import 'package:torn_pda/pages/alerts.dart';
import 'package:torn_pda/pages/alerts/stockmarket_alerts_page.dart';
import 'package:torn_pda/pages/awards_page.dart';
import 'package:torn_pda/pages/chaining_page.dart';
import 'package:torn_pda/pages/friends_page.dart';
import 'package:torn_pda/pages/loot.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/settings_page.dart';
import 'package:torn_pda/pages/tips_page.dart';
import 'package:torn_pda/pages/travel_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/settings/app_exit_dialog.dart';
import 'package:torn_pda/widgets/tct_clock.dart';

import 'main.dart';

class DrawerPage extends StatefulWidget {
  @override
  _DrawerPageState createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> with WidgetsBindingObserver {
  final int _settingsPosition = 8;
  final int _aboutPosition = 9;
  var _allowSectionsWithoutKey = <int>[];

  // !! Note: if order is changed, remember to look for other pages calling [_callSectionFromOutside]
  // via callback, as it might need to be changed as well
  final _drawerItemsList = [
    "Profile",
    "Travel",
    "Chaining",
    "Loot",
    "Friends",
    "Awards",
    "Stock Market",
    "Alerts",
    "Settings",
    "About",
    "Tips"
  ];

  ThemeProvider _themeProvider;
  UserDetailsProvider _userProvider;
  SettingsProvider _settingsProvider;
  UserScriptsProvider _userScriptsProvider;
  WebViewProvider _webViewProvider;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics analytics = FirebaseAnalytics();

  Future _finishedWithPreferences;

  int _activeDrawerIndex = 0;
  int _selected = 0;

  bool _changelogIsActive = false;
  bool _forceFireUserReload = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Allows to space alerts when app is on the foreground
  DateTime _lastMessageReceived;
  String _lastBody;
  int concurrent = 0;
  // Assigns different ids to alerts when the app is on the foreground
  int notId = 900;

  // Platform channel with MainActivity.java
  static const platform = MethodChannel('tornpda.channel');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // STARTS QUICK ACTIONS
      final QuickActions quickActions = QuickActions();

      quickActions.setShortcutItems(<ShortcutItem>[
        // NOTE: keep the same file name for both platforms
        const ShortcutItem(type: 'open_torn', localizedTitle: 'Torn Home', icon: "action_torn"),
      ]);

      quickActions.initialize((String shortcutType) async {
        if (shortcutType == 'open_torn') {
          context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: "http://www.torn.com",
                useDialog: _settingsProvider.useQuickBrowser,
              );
        }
      });
    });
    // ENDS QUICK ACTIONS

    WidgetsBinding.instance.addObserver(this);
    _allowSectionsWithoutKey = [
      _settingsPosition,
      _aboutPosition,
    ];

    _webViewProvider = context.read<WebViewProvider>();

    _handleChangelog();
    _finishedWithPreferences = _loadInitPreferences();

    // This starts a stream that listens for tap on local notifications (i.e.:
    // when the app is open)
    _fireOnTapLocalNotifications();

    // Configure all notifications channels so that Firebase alerts have already
    // and assign channel where to land
    if (Platform.isAndroid) {
      configureNotificationChannels();
    }

    // Defaulted to false so that onMessage is the entry point on iOS as it happens on Android (
    // otherwise we get duplicated notifications). Choose one or the other for iOS.
    // On Android we have no option since Firebase Android SDK will block displaying any FCM
    // notification no matter what Notification Channel has been set
    // See https://firebase.flutter.dev/docs/messaging/notifications/
    if (Platform.isIOS) {
      _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    }

    _lastMessageReceived = DateTime.now();
    _lastBody = "";

    _messaging.getInitialMessage().then((RemoteMessage message) {
      if (message != null && message.data.isNotEmpty) {
        _fireLaunchResumeNotifications(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message != null && message.data.isNotEmpty) {
        _fireLaunchResumeNotifications(message.data);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // This allows for notifications other than predefined ones in functions
      if (message.data.isEmpty) {
        message.data["title"] = message.notification.title;
        message.data["body"] = message.notification.body;
      }

      // Space messages and skip repeated
      bool skip = false;
      if (DateTime.now().difference(_lastMessageReceived).inSeconds < 2) {
        if (message.data["body"] == _lastBody) {
          // Skips messages with the same body that come repeated in less than 2 seconds, which is
          // a glitch for some mobile devices with the app in the foreground!
          skip = true;
        } else {
          // Spaces out several notifications so that all of them show if
          // the app is open (otherwise only 1 of them shows)
          concurrent++;
          await Future.delayed(Duration(seconds: 8 * concurrent));
        }
      } else {
        concurrent = 0;
      }

      if (!skip) {
        _lastMessageReceived = DateTime.now();
        _lastBody = message.data["body"] as String;
        // Assigns a different id two alerts that come together (otherwise one
        // deletes the previous one)
        notId++;
        if (notId > 990) notId = 900;
        // This will eventually fire a local notification
        showNotification(message.data, notId);
      } else {
        return null;
      }
    });

    // Handle notifications
    _getBackGroundNotifications();
    _removeExistingNotifications();
  }

  @override
  void dispose() {
    selectNotificationSubject.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Update Firebase active parameter
      _updateLastActiveTime();

      // Handle notifications
      _getBackGroundNotifications();
      _removeExistingNotifications();
    }
  }

  Future<void> _removeExistingNotifications() async {
    // Get rid of iOS badge (notifications will be removed by the system)
    if (Platform.isIOS) {
      _clearBadge();
    }
    // Get rid of notifications in Android
    try {
      if (Platform.isAndroid && _settingsProvider.removeNotificationsOnLaunch) {
        // Gets the active (already shown) notifications
        final List<ActiveNotification> activeNotifications = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.getActiveNotifications();

        for (final not in activeNotifications) {
          // Platform channel to cancel direct Firebase notifications (we can call
          // "cancelAll()" there without affecting scheduled notifications, which is
          // a problem with the local plugin)
          if (not.id == 0) {
            await platform.invokeMethod('cancelNotifications');
          }
          // This cancels the Firebase alerts that have been triggered locally
          else {
            flutterLocalNotificationsPlugin.cancel(not.id);
          }
        }
      }
    } catch (e) {
      // Not supported?
    }
  }

  Future<void> _getBackGroundNotifications() async {
    // Reload isolate (as we are reading from background)
    await Prefs().reload();
    // Get the save alerts
    Prefs().getDataStockMarket().then((stocks) {
      if (stocks.isNotEmpty) {
        Prefs().setDataStockMarket("");
        Future.delayed(const Duration(seconds: 1)).then((value) => _openBackgroundStockDialog(stocks));
      }
    });
  }

  // TODO Missing bits:
  // IMPORTANT: onResume/Launch only trigger with "FLUTTER_NOTIFICATION_CLICK"
  // from Functions, but not directly from Firebase's Messaging console.
  //  - Give the option to choose different places? Like in nerve,
  //    crimes vs jail. Energy: gym vs dump vs do not open.

  Future<void> _fireLaunchResumeNotifications(Map<String, dynamic> message) async {
    bool launchBrowser = false;
    var browserUrl = '';

    bool travel = false;
    bool hospital = false;
    bool restocks = false;
    bool racing = false;
    bool messages = false;
    bool events = false;
    bool trades = false;
    bool nerve = false;
    bool energy = false;
    bool drugs = false;
    bool refills = false;
    bool stockMarket = false;

    var channel = '';
    var messageId = '';
    var tradeId = '';

    if (Platform.isIOS) {
      channel = message["channelId"] as String;
      messageId = message["tornMessageId"] as String;
      tradeId = message["tornTradeId"] as String;
    } else if (Platform.isAndroid) {
      channel = message["channelId"] as String;
      messageId = message["tornMessageId"] as String;
      tradeId = message["tornTradeId"] as String;
    }

    if (channel.contains("Alerts travel")) {
      travel = true;
    } else if (channel.contains("Alerts hospital")) {
      hospital = true;
    } else if (channel.contains("Alerts restocks")) {
      restocks = true;
    } else if (channel.contains("Alerts racing")) {
      racing = true;
    } else if (channel.contains("Alerts messages")) {
      messages = true;
    } else if (channel.contains("Alerts events")) {
      events = true;
    } else if (channel.contains("Alerts trades")) {
      trades = true;
    } else if (channel.contains("Alerts nerve")) {
      nerve = true;
    } else if (channel.contains("Alerts energy")) {
      energy = true;
    } else if (channel.contains("Alerts drugs")) {
      drugs = true;
    } else if (channel.contains("Alerts refills")) {
      refills = true;
    } else if (channel.contains("Alerts stocks")) {
      stockMarket = true;
    }

    if (travel) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com";
    } else if (hospital) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com";
    } else if (restocks) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/travelagency.php";
    } else if (racing) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/loader.php?sid=racing";
    } else if (messages) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/messages.php";
      if (messageId != "") {
        browserUrl = "https://www.torn.com/messages.php#/p=read&ID="
            "$messageId&suffix=inbox";
      }
    } else if (events) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/events.php#/step=all";
    } else if (trades) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/trade.php";
      if (tradeId != "") {
        browserUrl = "https://www.torn.com/trade.php#step=view&ID="
            "$tradeId";
      }
    } else if (nerve) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/crimes.php";
    } else if (energy) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/gym.php";
    } else if (drugs) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#drugs-items";
    } else if (refills) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/points.php";
    } else if (stockMarket) {
      // Not implemented (there is a box showing in _getBackGroundNotifications)
    }

    if (launchBrowser) {
      // iOS seems to open a blank WebView unless we allow some time onResume
      await Future.delayed(const Duration(milliseconds: 500));
      // Works best if we get SharedPrefs directly instead of SettingsProvider
      if (launchBrowser) {
        await _webViewProvider.openBrowserPreference(
          context: context,
          url: browserUrl,
          useDialog: _settingsProvider.useQuickBrowser,
        );
      }
    }
  }

  // Fires if notification from local_notifications package is tapped (i.e.:
  // when the app is open). Also for manual notifications when app is open.
  Future<void> _fireOnTapLocalNotifications() async {
    selectNotificationSubject.stream.listen((String payload) async {
      var launchBrowser = false;
      var browserUrl = '';

      if (payload == 'travel') {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com';
      } else if (payload == 'restocks') {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/travelagency.php';
      } else if (payload.contains('energy')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/gym.php';
      } else if (payload.contains('nerve')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/crimes.php';
      } else if (payload.contains('drugs')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/item.php#drugs-items';
        // Medical is only in manual notifications, payload comes from Profile
      } else if (payload.contains('medical')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/item.php#medical-items';
        // Booster is only in manual notifications, payload comes from Profile
      } else if (payload.contains('booster')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/item.php#boosters-items';
      } else if (payload.contains('hospital')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com';
      } else if (payload.contains('racing')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/loader.php?sid=racing';
      } else if (payload.contains('400-')) {
        launchBrowser = true;
        final npcId = payload.split('-')[1];
        browserUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
      } else if (payload.contains('tornMessageId:')) {
        launchBrowser = true;
        final messageId = payload.split(':');
        browserUrl = "https://www.torn.com/messages.php";
        if (messageId[1] != "0") {
          browserUrl = "https://www.torn.com/messages.php#/p=read&ID="
              "${messageId[1]}&suffix=inbox";
        }
      } else if (payload.contains('events')) {
        launchBrowser = true;
        browserUrl = "https://www.torn.com/events.php#/step=all";
      } else if (payload.contains('tornTradeId:')) {
        launchBrowser = true;
        final tradeId = payload.split(':');
        browserUrl = "https://www.torn.com/trade.php";
        if (tradeId[1] != "0") {
          browserUrl = "https://www.torn.com/trade.php#step=view&ID=${tradeId[1]}";
        }
      } else if (payload.contains('211')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/travelagency.php';
      } else if (payload.contains('refills')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/points.php';
      } else if (payload.contains('stockMarket')) {
        // Not implemented (there is a box showing in _getBackGroundNotifications)
      }

      if (launchBrowser) {
        await _webViewProvider.openBrowserPreference(
          context: context,
          url: browserUrl,
          useDialog: _settingsProvider.useQuickBrowser,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: FutureBuilder(
        future: _finishedWithPreferences,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done && !_changelogIsActive) {
            return Container(
              color: _themeProvider.currentTheme == AppTheme.light
                  ? MediaQuery.of(context).orientation == Orientation.portrait
                      ? Colors.blueGrey
                      : Colors.grey[900]
                  : Colors.grey[900],
              child: SafeArea(
                top: !_settingsProvider.appBarTop || false,
                child: Scaffold(
                  key: _scaffoldKey,
                  body: _getPages(),
                  drawer: Drawer(
                    elevation: 2, // This avoids shadow over SafeArea
                    child: Container(
                      decoration: BoxDecoration(
                          color: _themeProvider.currentTheme == AppTheme.light ? Colors.grey[100] : Colors.transparent,
                          backgroundBlendMode: BlendMode.multiply),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                          _getDrawerHeader(),
                          _getDrawerItems(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Container(
              color: Colors.black,
              child: SafeArea(
                top: _settingsProvider.appBarTop || true,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _getDrawerHeader() {
    return SizedBox(
      height: MediaQuery.of(context).orientation == Orientation.portrait ? 280 : 250,
      child: DrawerHeader(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Flexible(
              child: Image(
                image: AssetImage('images/icons/torn_pda.png'),
                fit: BoxFit.fill,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'TORN PDA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: <Widget>[
                      Text(
                        _themeProvider.currentTheme == AppTheme.light ? 'Light' : 'Dark',
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                      ),
                      Switch(
                        value: _themeProvider.currentTheme == AppTheme.dark || false,
                        onChanged: (bool value) {
                          if (value) {
                            _themeProvider.changeTheme = AppTheme.dark;
                          } else {
                            _themeProvider.changeTheme = AppTheme.light;
                          }
                          setState(() {
                            SystemChrome.setSystemUIOverlayStyle(
                              SystemUiOverlayStyle(
                                statusBarColor: _themeProvider.currentTheme == AppTheme.light ? Colors.blueGrey : Colors.grey[900],
                                statusBarBrightness: Brightness.dark,
                                statusBarIconBrightness: Brightness.light,
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const TctClock(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getDrawerItems() {
    final drawerOptions = <Widget>[];
    // If API key is not valid, we just show the Settings + About pages
    // (just don't add the other sections to the list)
    if (!_userProvider.basic.userApiKeyValid) {
      for (final position in _allowSectionsWithoutKey) {
        drawerOptions.add(
          ListTileTheme(
            selectedColor: Colors.red,
            iconColor: _themeProvider.mainText,
            child: Ink(
              color: position == _selected ? Colors.grey[300] : Colors.transparent,
              child: ListTile(
                leading: _returnDrawerIcons(drawerPosition: position),
                title: Text(
                  _drawerItemsList[position],
                  style: TextStyle(
                    fontWeight: position == _selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: position == _selected,
                onTap: () => _onSelectItem(position),
              ),
            ),
          ),
        );
      }
    } else {
      // Otherwise, if the key is valid, we loop all the sections
      for (var i = 0; i < _drawerItemsList.length; i++) {
        // For this two, it is necessary to call Settings Provider from the Drawer and pass the callbacks all the
        // way to the relevant children. Otherwise, the drawer won't update in realtime (it's not listening)
        if (_settingsProvider.disableTravelSection && _drawerItemsList[i] == "Travel") {
          continue;
        }
        if (!_settingsProvider.stockExchangeInMenu && _drawerItemsList[i] == "Stock Market") {
          continue;
        }

        // Adding divider just before SETTINGS
        if (i == _settingsPosition) {
          drawerOptions.add(const Divider());
        }
        drawerOptions.add(
          ListTileTheme(
            selectedColor: Colors.red,
            iconColor: _themeProvider.mainText,
            child: Ink(
              color: i == _selected ? Colors.grey[300] : Colors.transparent,
              child: ListTile(
                leading: _returnDrawerIcons(drawerPosition: i),
                title: Text(
                  _drawerItemsList[i],
                  style: TextStyle(
                    fontWeight: i == _selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: i == _selected,
                onTap: () => _onSelectItem(i),
              ),
            ),
          ),
        );
      }
    }
    return Column(children: drawerOptions);
  }

  Widget _getPages() {
    switch (_activeDrawerIndex) {
      case 0:
        return ProfilePage(
          callBackSection: _callSectionFromOutside,
          disableTravelSection: _onChangeDisableTravelSection,
        );
        break;
      case 1:
        return TravelPage();
        break;
      case 2:
        return ChainingPage();
        break;
      case 3:
        return LootPage();
        break;
      case 4:
        return FriendsPage();
        break;
      case 5:
        return AwardsPage();
        break;
      case 6:
        return StockMarketAlertsPage(calledFromMenu: true, stockMarketInMenuCallback: _onChangeStockMarketInMenu);
        break;
      case 7:
        return AlertsSettings(_onChangeStockMarketInMenu);
        break;
      case 8:
        return const SettingsPage();
        break;
      case 9:
        return AboutPage();
        break;
      case 10:
        return TipsPage();
        break;

      default:
        return const Text("Error");
    }
  }

  Widget _returnDrawerIcons({int drawerPosition}) {
    switch (drawerPosition) {
      case 0:
        return const Icon(Icons.person);
        break;
      case 1:
        return const Icon(Icons.local_airport);
        break;
      case 2:
        return const Icon(MdiIcons.linkVariant);
        break;
      case 3:
        return const Icon(MdiIcons.knifeMilitary);
        break;
      case 4:
        return const Icon(Icons.people);
        break;
      case 5:
        return const Icon(MdiIcons.trophy);
        break;
      case 6:
        return const Icon(MdiIcons.bankTransfer);
        break;
      case 7:
        return const Icon(Icons.notifications_active);
        break;
      case 8:
        return const Icon(Icons.settings);
        break;
      case 9:
        return const Icon(Icons.info_outline);
        break;
      case 10:
        return const Icon(Icons.question_answer_outlined);
        break;
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onSelectItem(int index) async {
/*    await analytics.logEvent(
        name: 'section_changed',
        parameters: {'section': _drawerItemsList[index]});*/

    Navigator.of(context).pop();
    setState(() {
      _selected = index;
      _activeDrawerIndex = index;
    });
  }

  Future<void> _loadInitPreferences() async {
    // Set up SettingsProvider so that user preferences are applied
    // ## Leave this first as other options below need this to be initialized ##
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await _settingsProvider.loadPreferences();

    // Change device preferences
    final allowRotation = _settingsProvider.allowScreenRotation;
    if (allowRotation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    // Set up UserScriptsProvider so that user preferences are applied
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
    await _userScriptsProvider.loadPreferences();

    // Set up UserProvider. If key is empty, redirect to the Settings page.
    // Else, open the default
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    await _userProvider.loadPreferences();

    if (!_userProvider.basic.userApiKeyValid) {
      _selected = _settingsPosition;
      _activeDrawerIndex = _settingsPosition;
    } else {
      final defaultSection = await Prefs().getDefaultSection();
      _selected = int.parse(defaultSection);
      _activeDrawerIndex = int.parse(defaultSection);

      // Firestore get auth and init
      final user = await firebaseAuth.currentUser();
      if (user == null) {
        _updateFirebaseDetails();
      } else {
        final uid = await firebaseAuth.getUID();
        firestore.setUID(uid as String);
      }

      // Update last used time in Firebase when the app opens (we'll do the same in onResumed,
      // since some people might leave the app opened for weeks in the background)
      _updateLastActiveTime();
    }
  }

  Future<void> _updateLastActiveTime() async {
    // Calculate difference between last recorded use and current time
    final now = DateTime.now().millisecondsSinceEpoch;
    final dTimeStamp = now - _settingsProvider.lastAppUse;
    final duration = Duration(milliseconds: dTimeStamp);

    // If the recorded check is over 2 days, upload it to Firestore. 2 days allow for several
    // retries, even if Firebase makes inactive at 7 days (2 days here + 5 advertised)
    // Also update full user in case something is missing!
    if (duration.inDays > 2 || _forceFireUserReload) {
      await _updateFirebaseDetails();
      // This is triggered to true if the changelog activates.
      _forceFireUserReload = false;
    }
  }

  Future<void> _updateFirebaseDetails() async {
    // We save the key because the API call will reset it
    // Then get user's profile and update
    final savedKey = _userProvider.basic.userApiKey;
    final dynamic prof = await TornApiCaller.ownBasic(savedKey).getProfileBasic;
    if (prof is OwnProfileBasic) {
      // Update profile with the two fields it does not contain
      prof
        ..userApiKey = savedKey
        ..userApiKeyValid = true;

      // Upload information to Firebase (this includes the token)
      final User mFirebaseUser = await firebaseAuth.signInAnon() as User;
      firestore.setUID(mFirebaseUser.uid);
      await firestore.uploadUsersProfileDetail(prof, userTriggered: true);
    }

    // Uploads last active time to Firebase
    final now = DateTime.now().millisecondsSinceEpoch;
    final success = await firestore.uploadLastActiveTime(now);
    if (success) {
      _settingsProvider.updateLastUsed(now);
    }
  }

  Future<void> _handleChangelog() async {
    final String savedVersion = await Prefs().getAppVersion();
    if (savedVersion != appVersion) {
      Prefs().setAppVersion(appVersion);

      // Exceptions were we don't show a changelog
      /*
      if (savedVersion == '1.6.0') {
        return;
      }
      */

      // Will trigger an extra upload to Firebase when version changes
      _forceFireUserReload = true;

      // Reconfigure notification channels in case new sounds are added (e.g. v2.4.2)
      // Deletes current channels and create new ones
      if (Platform.isAndroid) {
        final vibration = await Prefs().getVibrationPattern();
        await reconfigureNotificationChannels(mod: vibration);
      }

      _changelogIsActive = true;
      _showChangeLogDialog(context);
    }
  }

  Future<void> _showChangeLogDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChangeLog();
      },
    );

    setState(() {
      _changelogIsActive = false;
    });
  }

  void _callSectionFromOutside(int section) {
    setState(() {
      _selected = section;
      _activeDrawerIndex = section;
    });
    _getPages();
  }

  Future<bool> _willPopCallback() async {
    final appExit = _settingsProvider.onAppExit;
    if (appExit == 'exit') {
      return true;
    } else if (appExit == 'stay') {
      // Open drawer instead
      _scaffoldKey.currentState.openDrawer();
      return false;
    } else {
      String action;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return OnAppExitDialog();
        },
      ).then((choice) {
        action = choice as String;
      });
      if (action == 'exit') {
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      } else {
        // Open drawer instead
        _scaffoldKey.currentState.openDrawer();
        return false;
      }
    }
  }

  void _onChangeDisableTravelSection(bool disable) {
    setState(() {
      _settingsProvider.changeDisableTravelSection = disable;
    });
  }

  void _onChangeStockMarketInMenu(bool inMenu) {
    setState(() {
      _settingsProvider.changeStockExchangeInMenu = inMenu;
    });
  }

  void _clearBadge() {
    try {
      FlutterAppBadger.removeBadge();
    } catch (e) {
      // Not supported?
    }
  }

  Future<void> _openBackgroundStockDialog(String update) {
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
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider.background,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "STOCK MARKET UPDATE!",
                                  style: TextStyle(fontSize: 11, color: _themeProvider.mainText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Text(
                            update,
                            style: TextStyle(fontSize: 11, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text(
                                "Stock Exchange",
                              ),
                              onPressed: () async {
                                await _webViewProvider.openBrowserPreference(
                                  context: context,
                                  url: "https://www.torn.com/page.php?sid=stocks",
                                  useDialog: _settingsProvider.useQuickBrowser,
                                );
                                Navigator.of(context).pop();
                              },
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              child: const Text("Close"),
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
                      child: const SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(MdiIcons.chartLine, color: Colors.green),
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
