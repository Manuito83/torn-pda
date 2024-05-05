// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:audioplayers/audioplayers.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_functions/cloud_functions.dart';
// Useful for functions debugging
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/firebase_options.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/audio_controller.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/tac_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/utils/appwidget/pda_widget.dart';
import 'package:torn_pda/utils/http_overrides.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:workmanager/workmanager.dart';

// TODO (App release)
const String appVersion = '3.4.1';
const String androidCompilation = '415';
const String iosCompilation = '415';

// TODO (App release)
const bool pointFunctionsEmulatorToLocal = false;

// TODO (App release)
const bool enableWakelockForDebug = false;

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

bool exactAlarmsPermissionAndroid = false;

bool syncTheme = false;

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (message.data["channelId"].contains("Alerts stocks") == true) {
      // Reload isolate (as we are reading from background)
      await Prefs().reload();
      final oldData = await Prefs().getDataStockMarket();
      var newData = "";
      if (oldData.isNotEmpty) {
        newData = "$oldData\n${message.notification!.body}";
      } else {
        newData = "$oldData${message.notification!.body}";
      }
      Prefs().setDataStockMarket(newData);
    }
  } catch (e) {
    FirebaseCrashlytics.instance.log("PDA Crash at Messaging Background Handler");
    FirebaseCrashlytics.instance.recordError("PDA Error: $e", null);
  }
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // START ## Force splash screen to stay on until we get essential start-up data
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await _shouldSyncDeviceTheme(widgetsBinding);
  FlutterNativeSplash.remove();
  // END ## Release splash screen

  // Avoid screen lock when testing in real device
  if (kDebugMode && enableWakelockForDebug) {
    log("########################################################");
    log("####### WAKELOCK ENABLED FOR DEBUGGING PURPOSES #######");
    log("########################################################");
    WakelockPlus.enable();
  }

  // Initialise Workmanager for app widget
  // [isInDebugMode] sends notifications each time a task is performed
  Workmanager().initialize(pdaWidget_backgroundUpdate);

  // Flutter Local Notifications
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!;
    await androidImplementation.requestNotificationsPermission();
    exactAlarmsPermissionAndroid = await androidImplementation.canScheduleExactNotifications() ?? false;
  }

  tz.initializeTimeZones();
  const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const initializationSettingsIOS = DarwinInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      if (notificationResponse.payload != null) {
        log('Notification payload: $payload');
        selectNotificationStream.add(payload);
      }
    },
  );
  // END # Flutter Local Notifications

  // ## FIREBASE
  // Before any of the Firebase services can be used, FlutterFire needs to be initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    if (pointFunctionsEmulatorToLocal) {
      FirebaseFunctions.instanceFor(region: 'us-east4').useFunctionsEmulator('localhost', 5001);
    }
    // Only 'true' intended for debugging, otherwise leave in false
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // ! Consider disabling for public release - Enable in beta to get plugins' method channel errors in Crashlytics
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  // https://docs.flutter.dev/testing/errors#errors-not-caught-by-flutter
  /*
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return false;
  };
  */

  // Needs to register plugin for iOS
  if (Platform.isIOS) {
    DartPingIOS.register();
  }

  Get.put(AudioController(), permanent: true);
  Get.put(SpiesController(), permanent: true);
  Get.put(ApiCallerController(), permanent: true);
  Get.put(WarController(), permanent: true);

  HttpOverrides.global = MyHttpOverrides();

  // iOS settings for AudioPlayer are managed through the controller
  AudioPlayer.global.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.gainTransientMayDuck),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // UserDetailsProvider has to go first to initialize the others!
        ChangeNotifierProvider<UserDetailsProvider>(create: (context) => UserDetailsProvider()),
        ChangeNotifierProvider<TargetsProvider>(create: (context) => TargetsProvider()),
        ChangeNotifierProvider<AttacksProvider>(create: (context) => AttacksProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (context) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (context) => SettingsProvider()),
        ChangeNotifierProvider<FriendsProvider>(create: (context) => FriendsProvider()),
        ChangeNotifierProvider<UserScriptsProvider>(create: (context) => UserScriptsProvider()),
        ChangeNotifierProvider<ChainStatusProvider>(create: (context) => ChainStatusProvider()),
        ChangeNotifierProvider<CrimesProvider>(create: (context) => CrimesProvider()),
        ChangeNotifierProvider<QuickItemsProvider>(create: (context) => QuickItemsProvider()),
        ChangeNotifierProvider<QuickItemsProviderFaction>(create: (context) => QuickItemsProviderFaction()),
        ChangeNotifierProvider<TradesProvider>(create: (context) => TradesProvider()),
        ChangeNotifierProvider<ShortcutsProvider>(create: (context) => ShortcutsProvider()),
        ChangeNotifierProvider<AwardsProvider>(create: (context) => AwardsProvider()),
        ChangeNotifierProvider<TacProvider>(create: (context) => TacProvider()),
        ChangeNotifierProvider<TerminalProvider>(create: (context) => TerminalProvider("")),
        ChangeNotifierProvider<WebViewProvider>(create: (context) => WebViewProvider()),
        // Native login
        ChangeNotifierProvider<NativeAuthProvider>(create: (context) => NativeAuthProvider()),
        ChangeNotifierProvider<NativeUserProvider>(create: (context) => NativeUserProvider()),
        // ------------
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ThemeProvider _themeProvider;
  late WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);

    // Handle home widget
    if (Platform.isAndroid) {
      HomeWidget.setAppGroupId('torn_pda');
      HomeWidget.registerInteractivityCallback(pdaWidget_callback);
      pdaWidget_handleBackgroundUpdateStatus();
    }

    // Callback to force the browser back to full screen if there is a system request to revert
    // Might happen when app is on the background or when only the top is being extended
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (_webViewProvider.currentUiMode == UiMode.fullScreen && systemOverlaysAreVisible) {
        _webViewProvider.setCurrentUiMode(UiMode.fullScreen, context);
      }
    });
  }

  @override
  void didChangeMetrics() async {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final bool splitNowActive = _webViewProvider.webViewSplitActive;
      final bool splitUserEnabled = _webViewProvider.splitScreenPosition != WebViewSplitPosition.off;
      final bool screenIsWide = MediaQuery.sizeOf(context).width >= 800;

      if (!splitNowActive && splitUserEnabled && screenIsWide) {
        _webViewProvider.webViewSplitActive = true;
        _webViewProvider.browserForegroundWithSplitTransition();
      } else if (splitNowActive && (!splitUserEnabled || !screenIsWide)) {
        _webViewProvider.webViewSplitActive = false;
        if (_webViewProvider.splitScreenRevertsToApp) {
          _webViewProvider.browserShowInForeground = false;
        } else {
          _webViewProvider.browserShowInForeground = true;
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    final bool screenIsWide = MediaQuery.sizeOf(context).width >= 800;

    // https://github.com/flutter/flutter/issues/126585
    MediaQuery.viewInsetsOf(context).bottom;

    final ThemeData theme = ThemeData(
      cardColor: _themeProvider.cardColor,
      cardTheme: CardTheme(
        // Material 3 overrides
        surfaceTintColor: _themeProvider.cardSurfaceTintColor,
        color: _themeProvider.cardColor,
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        surfaceTintColor: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : null,
        color: _themeProvider.statusBar,
      ),
      primarySwatch: Colors.blueGrey,
      useMaterial3: _themeProvider.useMaterial3,
      brightness: _themeProvider.currentTheme == AppTheme.light ? Brightness.light : Brightness.dark,
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _themeProvider.statusBar,
        systemNavigationBarColor: _themeProvider.statusBar,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        // iOS
        statusBarBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Torn PDA',
      theme: theme,
      debugShowCheckedModeBanner: false,
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      home: WillPopScope(
        onWillPop: () async {
          final WebViewProvider w = Provider.of<WebViewProvider>(context, listen: false);

          if (w.browserShowInForeground) {
            // Browser is in front, delegate the call
            w.tryGoBack();
            return false;
          } else {
            // App is in front
            //_webViewProvider.willPopCallbackStream.add(true);
            final bool shouldPop = await _willPopFromApp();
            if (shouldPop) return true;
            return false;
          }
        },
        child: Consumer<WebViewProvider>(builder: (context, wProvider, child) {
          if (wProvider.splitScreenPosition == WebViewSplitPosition.right &&
              _webViewProvider.webViewSplitActive &&
              screenIsWide) {
            return Stack(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GetMaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: theme,
                        home: DrawerPage(),
                      ),
                    ),
                    Flexible(
                      child: wProvider.stackView,
                    ),
                  ],
                ),
                const AppBorder(),
              ],
            );
          } else if (wProvider.splitScreenPosition == WebViewSplitPosition.left &&
              _webViewProvider.webViewSplitActive &&
              screenIsWide) {
            return Stack(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: wProvider.stackView,
                    ),
                    Flexible(
                      child: GetMaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: theme,
                        home: DrawerPage(),
                      ),
                    ),
                  ],
                ),
                const AppBorder(),
              ],
            );
          } else {
            return Stack(
              children: [
                GetMaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  home: DrawerPage(),
                ),
                Visibility(
                  maintainState: true,
                  visible: wProvider.browserShowInForeground,
                  child: wProvider.stackView,
                ),
                const AppBorder(),
              ],
            );
          }
        }),
      ),
    );
  }

  Future<bool> _willPopFromApp() async {
    final SettingsProvider s = Provider.of<SettingsProvider>(context, listen: false);
    final appExit = s.onAppExit;
    if (appExit == 'exit') {
      return true;
    } else {
      if (routeWithDrawer) {
        // Open drawer instead
        s.willPopShouldOpenDrawer.add(true);
        return false;
      } else {
        s.willPopShouldGoBack.add(true);
        return false;
      }
    }
  }
}

class AppBorder extends StatefulWidget {
  const AppBorder({super.key});

  @override
  AppBorderState createState() => AppBorderState();
}

class AppBorderState extends State<AppBorder> {
  @override
  Widget build(BuildContext context) {
    final chainStatusProvider = Provider.of<ChainStatusProvider>(context);
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: chainStatusProvider.watcherActive ? 3 : 0,
                  color: chainStatusProvider.borderColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Retrieves and changes Prefs() data directly (as providers have not yet been started)
/// to manage device theme sync with the app directly from the splash screen
/// (so that we avoid unintended light/dark containers as providers load in Drawer)
Future<void> _shouldSyncDeviceTheme(WidgetsBinding widgetsBinding) async {
  syncTheme = await Prefs().getSyncDeviceTheme();
  if (syncTheme) {
    final brightness = widgetsBinding.platformDispatcher.platformBrightness;
    if (brightness == Brightness.dark) {
      String whatDarkToSync = await Prefs().getDarkThemeToSync();

      switch (whatDarkToSync) {
        case "dark":
          await Prefs().setAppTheme("dark");
          break;
        case "extraDark":
          await Prefs().setAppTheme("extraDark");
          break;
      }
    } else if (brightness == Brightness.light) {
      await Prefs().setAppTheme("light");
    }
  }
}
