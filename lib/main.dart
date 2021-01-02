import 'dart:async';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:timezone/data/latest.dart' as tz;

// TODO: CONFIGURE FOR APP RELEASE, include exceptions in Drawer if applicable
final String appVersion = '2.0.0';

final FirebaseAnalytics analytics = FirebaseAnalytics();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

  var initializationSettingsIOS = IOSInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  var initializationSettings = InitializationSettings(
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
  if (kDebugMode) {
    // Only 'true' intended for debugging, otherwise leave in false
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Force portrait up
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        // UserDetailsProvider has to go first to initialize the others!
        ChangeNotifierProvider<UserDetailsProvider>(
            create: (context) => UserDetailsProvider()),
        ChangeNotifierProxyProvider<UserDetailsProvider, TargetsProvider>(
          create: (context) => TargetsProvider(OwnProfileModel()),
          update: (BuildContext context, UserDetailsProvider userProvider,
                  TargetsProvider targetsProvider) =>
              TargetsProvider(userProvider.myUser),
        ),
        ChangeNotifierProxyProvider<UserDetailsProvider, AttacksProvider>(
          create: (context) => AttacksProvider(OwnProfileModel()),
          update: (BuildContext context, UserDetailsProvider userProvider,
                  AttacksProvider attacksProvider) =>
              AttacksProvider(userProvider.myUser),
        ),
        ChangeNotifierProvider<ThemeProvider>(
            create: (context) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>(
            create: (context) => SettingsProvider()),
        ChangeNotifierProxyProvider<UserDetailsProvider, FriendsProvider>(
          create: (context) => FriendsProvider(OwnProfileModel()),
          update: (BuildContext context, UserDetailsProvider userProvider,
                  FriendsProvider friendsProvider) =>
              FriendsProvider(userProvider.myUser),
        ),
        ChangeNotifierProvider<ChainStatusProvider>(
            create: (context) => ChainStatusProvider()),
        ChangeNotifierProvider<CrimesProvider>(
            create: (context) => CrimesProvider()),
        ChangeNotifierProvider<QuickItemsProvider>(
            create: (context) => QuickItemsProvider()),
        ChangeNotifierProvider<TradesProvider>(
            create: (context) => TradesProvider()),
        ChangeNotifierProvider<ShortcutsProvider>(
            create: (context) => ShortcutsProvider()),
        ChangeNotifierProvider<AwardsProvider>(
            create: (context) => AwardsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _themeProvider.currentTheme == AppTheme.light
          ? Colors.blueGrey
          : Colors.grey[900],
    ));

    return MaterialApp(
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      title: 'Torn PDA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: _themeProvider.currentTheme == AppTheme.light
            ? Brightness.light
            : Brightness.dark,
      ),
      home: DrawerPage(),
    );
  }
}
