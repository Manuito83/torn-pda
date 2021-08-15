// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:timezone/data/latest.dart' as tz;
// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/tac_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// TODO: CONFIGURE FOR APP RELEASE, include exceptions in Drawer if applicable
const String appVersion = '2.5.0';
const String androidVersion = '126';
const String iosVersion = '136';

final FirebaseAnalytics analytics = FirebaseAnalytics();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data["channelId"].contains("Alerts stocks") == true) {
    // Reload isolate (as we are reading from background)
    await Prefs().reload();
    final oldData = await Prefs().getDataStockMarket();
    var newData = "";
    if (oldData.isNotEmpty) {
      newData = "$oldData\n${message.notification.body}";
    } else {
      newData = "$oldData${message.notification.body}";
    }
    Prefs().setDataStockMarket(newData);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const initializationSettingsIOS = IOSInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    selectNotificationSubject.add(payload);
  });

  // ## FIREBASE
  // Before any of the Firebase services can be used, FlutterFire needs to be initialized
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    // Only 'true' intended for debugging, otherwise leave in false
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        // UserDetailsProvider has to go first to initialize the others!
        ChangeNotifierProvider<UserDetailsProvider>(create: (context) => UserDetailsProvider()),
        ChangeNotifierProxyProvider<UserDetailsProvider, TargetsProvider>(
          create: (context) => TargetsProvider(OwnProfileBasic()),
          update: (BuildContext context, UserDetailsProvider userProvider, TargetsProvider targetsProvider) =>
              TargetsProvider(userProvider.basic),
        ),
        ChangeNotifierProxyProvider<UserDetailsProvider, AttacksProvider>(
          create: (context) => AttacksProvider(OwnProfileBasic()),
          update: (BuildContext context, UserDetailsProvider userProvider, AttacksProvider attacksProvider) =>
              AttacksProvider(userProvider.basic),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (context) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (context) => SettingsProvider()),
        ChangeNotifierProxyProvider<UserDetailsProvider, FriendsProvider>(
          create: (context) => FriendsProvider(OwnProfileBasic()),
          update: (BuildContext context, UserDetailsProvider userProvider, FriendsProvider friendsProvider) =>
              FriendsProvider(userProvider.basic),
        ),
        ChangeNotifierProvider<UserScriptsProvider>(
          create: (context) => UserScriptsProvider(),
        ),
        ChangeNotifierProvider<ChainStatusProvider>(
          create: (context) => ChainStatusProvider(),
        ),
        ChangeNotifierProvider<CrimesProvider>(
          create: (context) => CrimesProvider(),
        ),
        ChangeNotifierProvider<QuickItemsProvider>(
          create: (context) => QuickItemsProvider(),
        ),
        ChangeNotifierProvider<TradesProvider>(
          create: (context) => TradesProvider(),
        ),
        ChangeNotifierProvider<ShortcutsProvider>(
          create: (context) => ShortcutsProvider(),
        ),
        ChangeNotifierProvider<AwardsProvider>(
          create: (context) => AwardsProvider(),
        ),
        ChangeNotifierProvider<TacProvider>(
          create: (context) => TacProvider(),
        ),
        ChangeNotifierProvider<TerminalProvider>(
          create: (context) => TerminalProvider(""),
        ),
        ChangeNotifierProvider<WebViewProvider>(
          create: (context) => WebViewProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _themeProvider.currentTheme == AppTheme.light ? Colors.blueGrey : Colors.grey[900],
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MediaQuery(
      data: MediaQueryData.fromWindow(ui.window),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            MaterialApp(
              builder: BotToastInit(),
              navigatorObservers: [BotToastNavigatorObserver()],
              title: 'Torn PDA',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                appBarTheme: AppBarTheme(
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  color: _themeProvider.currentTheme == AppTheme.light ? Colors.blueGrey : Colors.grey[900],
                ),
                primarySwatch: Colors.blueGrey,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                brightness: _themeProvider.currentTheme == AppTheme.light ? Brightness.light : Brightness.dark,
              ),
              home: DrawerPage(),
            ),
            const AppBorder(),
          ],
        ),
      ),
    );
  }
}

// Avoid HTTP Handshake errors
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class AppBorder extends StatefulWidget {
  const AppBorder({Key key}) : super(key: key);

  @override
  _AppBorderState createState() => _AppBorderState();
}

class _AppBorderState extends State<AppBorder> {
  @override
  Widget build(BuildContext context) {
    final _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: true);
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: _chainStatusProvider.watcherActive ? 3 : 0,
                  color: _chainStatusProvider.borderColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
