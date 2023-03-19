// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
// Package imports:
import 'package:bot_toast/bot_toast.dart';

// Useful for functions debugging
// ignore: unused_import
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:workmanager/workmanager.dart';
// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
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
const String appVersion = '2.9.6';
const String androidCompilation = '282';
const String iosCompilation = '282';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

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

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    DateTime now = DateTime.now();
    log("EXECUTED $taskName AT ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}");
    await HomeWidget.saveWidgetData(
      'title',
      'Updated from Background',
    );
    await HomeWidget.saveWidgetData(
      'message',
      '$taskName: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
          ':${now.second.toString().padLeft(2, '0')}',
    );
    await HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
    log("$taskName finished @ ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}");
    return true;
  });
}

/// Called when Doing Background Work initiated from Widget
@pragma("vm:entry-point")
void backgroundCallback(Uri data) async {
  print(data);

  if (data.host == 'titleclicked') {
    var now = DateTime.now();
    HomeWidget.saveWidgetData(
      'title',
      'Widget clicked @',
    );
    HomeWidget.saveWidgetData(
      'message',
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
          ':${now.second.toString().padLeft(2, '0')}',
    );

    //await HomeWidget.saveWidgetData<String>('title', selectedGreeting);
    await HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
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
    // ONLY FOR TESTING FUNCTIONS LOCALLY, COMMENT AFTERWARDS
    //FirebaseFunctions.instanceFor(region: 'us-east4').useFunctionsEmulator('localhost', 5001);
    // Only 'true' intended for debugging, otherwise leave in false
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // TODO: remove class?
  //HttpOverrides.global = MyHttpOverrides();
  ByteData data = await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
  SecurityContext.defaultContext.setTrustedCertificatesBytes(data.buffer.asUint8List());

  // Needs to register plugin for iOS
  if (Platform.isIOS) {
    DartPingIOS.register();
  }

  runApp(
    MultiProvider(
      providers: [
        // UserDetailsProvider has to go first to initialize the others!
        ChangeNotifierProvider<UserDetailsProvider>(create: (context) => UserDetailsProvider()),
        ChangeNotifierProvider<TargetsProvider>(create: (context) => TargetsProvider()),
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
        ChangeNotifierProvider<QuickItemsProviderFaction>(
          create: (context) => QuickItemsProviderFaction(),
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
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();

    // Handle home widget
    HomeWidget.setAppGroupId('torn_pda');
    HomeWidget.registerBackgroundCallback(backgroundCallback);

    // Home widget ***
    // Check whether the user is using a widget
    const platform = MethodChannel('tornpda.channel');
    platform.invokeMethod('widgetCount').then((value) {
      var list = value as List<int>;
      log("Installed widgets count: ${list.length}");
      // TODO: more here all other actions?
    });

    _loadWidgetData();
    _startBackgroundUpdate();
    // Home widget END ***
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    MediaQuery mq = MediaQuery(
      data: MediaQueryData.fromWindow(ui.window),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            GetMaterialApp(
              builder: BotToastInit(),
              navigatorObservers: [BotToastNavigatorObserver()],
              title: 'Torn PDA',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                cardColor: _themeProvider.cardColor,
                appBarTheme: AppBarTheme(
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  color: _themeProvider.statusBar,
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

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _themeProvider.statusBar,
        systemNavigationBarColor:
            mq.data.orientation == Orientation.landscape ? _themeProvider.canvas : _themeProvider.statusBar,
        systemNavigationBarIconBrightness: mq.data.orientation == Orientation.landscape
            ? _themeProvider.currentTheme == AppTheme.light
                ? Brightness.dark
                : Brightness.light
            : Brightness.light,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return mq;
  }

  Future<void> _loadWidgetData() async {
    try {
      HomeWidget.getWidgetData<String>('title', defaultValue: '').then((value) async {
        log(value);
        UserController _u = Get.put(UserController());
        String apiKey = _u.apiKey;
        if (apiKey.isNotEmpty) {
          var apiResponse = await TornApiCaller().getProfileExtended(limit: 3);
          if (apiResponse is OwnProfileExtended) {
            HomeWidget.saveWidgetData<String>('title', apiResponse.energy.current.toString());
            HomeWidget.updateWidget(name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda');
          }
        }
      });
    } on PlatformException catch (exception) {
      log('Error Getting Data. $exception');
    }
  }

  void _startBackgroundUpdate() async {
    await Workmanager().cancelAll();
    Workmanager().registerPeriodicTask('pdaWidget_1', 'widgetBackgroundUpdate').then((value) async {
      Future.delayed(Duration(minutes: 5)).then((value) async {
        Workmanager().registerPeriodicTask('pdaWidget_2', 'widgetBackgroundUpdate');
        Future.delayed(Duration(minutes: 5)).then((value) {
          Workmanager().registerPeriodicTask('pdaWidget_3', 'widgetBackgroundUpdate');
        });
      });
    });
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
