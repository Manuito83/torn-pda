// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

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
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:toastification/toastification.dart';
// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/firebase_options.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
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
import 'package:upgrader/upgrader.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:workmanager/workmanager.dart';

// TODO (App release)
const String appVersion = '3.6.0';
const String androidCompilation = '453';
const String iosCompilation = '453';

// TODO (App release)
// Note: if using Windows and calling HTTP functions, we need to change the URL in [firebase_functions.dart]
const bool pointFunctionsEmulatorToLocal = false;

// TODO (App release)
const bool enableWakelockForDebug = false;

bool logAndShowToUser = false;

final FirebaseAnalytics? analytics = Platform.isWindows ? null : FirebaseAnalytics.instance;
final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// TODO Run [flutter run --machine] to set up
final winNotifyPlugin = WindowsNotification(
  applicationId: kDebugMode ? r"{fdf9adab-cc5d-4660-aec3-f9b7e4b3e355}\WindowsPowerShell\v1.0\powershell.exe" : null,
);

final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

bool exactAlarmsPermissionAndroid = false;

bool syncTheme = false;

Future? mainSettingsLoaded;

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
    if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Messaging Background Handler");
    if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", null);
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  if (Platform.isAndroid) Workmanager().initialize(pdaWidget_backgroundUpdate);

  // Flutter Local Notifications
  if (!Platform.isWindows) {
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
  }

  // END # Flutter Local Notifications

  // ## FIREBASE
  // Before any of the Firebase services can be used, FlutterFire needs to be initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!Platform.isWindows) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (kDebugMode) {
      if (pointFunctionsEmulatorToLocal) {
        FirebaseFunctions.instanceFor(region: 'us-east4').useFunctionsEmulator('localhost', 5001);
      }

      // Only 'true' intended for debugging, otherwise leave in false
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);

      // ! Consider disabling for public release - Enable in beta to get plugins' method channel errors in Crashlytics
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      // https://docs.flutter.dev/testing/errors#errors-not-caught-by-flutter
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return false;
      };
    }

    // Pass all uncaught errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

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

  late Future _mainBrowserPreferencesLoaded;

  late Widget _mainBrowser;

  final upgrader = Upgrader(
    debugDisplayAlways: kDebugMode ? false : false, // True for debugging if necessary
    willDisplayUpgrade: ({required display, installedVersion, versionInfo}) {
      if (display) {
        log(versionInfo.toString());
      }
    },
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _mainBrowserPreferencesLoaded = _loadMainBrowserPreferences();

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

    _mainBrowser = Consumer<WebViewProvider>(
      builder: (context, w, child) {
        return Visibility(
          maintainState: true,
          visible: w.browserShowInForeground || w.webViewSplitActive,
          child: w.stackView,
        );
      },
    );
  }

  @override
  void didChangeMetrics() async {
    // Assess the split screen condition after the device or window metrics change
    _setSplitScreenPosition();
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
        statusBarBrightness: MediaQuery.orientationOf(context) == Orientation.landscape
            ? _themeProvider.currentTheme == AppTheme.light
                ? Brightness.light
                : Brightness.dark
            : Brightness.dark,
      ),
    );

    // Inside of Navigator so that even if DrawerPage is replaced (we push another route), the
    // reference to this widget is not lost
    final homeDrawer = Navigator(
      onGenerateRoute: (_) {
        return MaterialPageRoute(
          builder: (BuildContext _) => UpgradeAlert(
            upgrader: upgrader,
            child: DrawerPage(),
          ),
        );
      },
    );

    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Torn PDA',
        navigatorKey: navigatorKey,
        theme: theme,
        debugShowCheckedModeBanner: false,
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        scrollBehavior: !Platform.isWindows
            ? null
            : const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown,
                },
              ),
        home: FutureBuilder(
          future: _mainBrowserPreferencesLoaded,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Container(color: _themeProvider.secondBackground);
            }

            return Consumer2<SettingsProvider, WebViewProvider>(builder: (context, sProvider, wProvider, child) {
              // Build standard or split-screen home
              Widget home = Stack(
                children: [
                  homeDrawer,
                  _mainBrowser,
                  const AppBorder(),
                ],
              );

              if (wProvider.splitScreenPosition == WebViewSplitPosition.right &&
                  wProvider.webViewSplitActive &&
                  screenIsWide) {
                home = Stack(
                  children: [
                    Row(
                      children: [
                        Flexible(child: homeDrawer),
                        Flexible(child: _mainBrowser),
                      ],
                    ),
                    const AppBorder(),
                  ],
                );
              } else if (wProvider.splitScreenPosition == WebViewSplitPosition.left &&
                  wProvider.webViewSplitActive &&
                  screenIsWide) {
                home = Stack(
                  children: [
                    Row(
                      children: [
                        Flexible(child: _mainBrowser),
                        Flexible(child: homeDrawer),
                      ],
                    ),
                    const AppBorder(),
                  ],
                );
              }

              return PopScope(
                // Only exit app if user allows and we are not in the browser
                canPop: sProvider.onBackButtonAppExit == "exit" && !wProvider.browserShowInForeground,
                onPopInvokedWithResult: (didPop, result) async {
                  if (didPop) return;
                  // If we can't pop, decide if we open the drawer or go backwards in the browser
                  final WebViewProvider w = Provider.of<WebViewProvider>(context, listen: false);
                  if (w.browserShowInForeground) {
                    // Browser is in front, delegate the call
                    w.tryGoBack();
                  } else {
                    _openDrawerIfPossible();
                  }
                },
                child: home,
              );
            });
          },
        ),
      ),
    );
  }

  _openDrawerIfPossible() async {
    final SettingsProvider s = Provider.of<SettingsProvider>(context, listen: false);
    if (routeWithDrawer) {
      // Open drawer instead
      s.willPopShouldOpenDrawerStream.add(true);
    } else {
      s.willPopShouldGoBackStream.add(true);
    }
  }

  void _setSplitScreenPosition() {
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

  /// This is mostly needed in case we start the app with split screen or directly with the browser as main view
  Future _loadMainBrowserPreferences() async {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    await _webViewProvider.restorePreferences();

    /// DOC
    ///
    /// Before initializing the WebView, call the WebViewEnvironment.getAvailableVersion() static method to
    /// check whether the required WebView2 Runtime is installed or not on the user system.
    ///
    /// TODO: alert users?
    ///
    /// WebView2 Runtime is ship in box with Windows 11, but it may not be installed on Windows 10 devices.
    ///
    /// If it isn't installed, the method will return null, so consider how to distribute the WebView2 Runtime.
    ///
    /// Option 1: tell user to install WebView2 Runtime from this page:
    /// https://developer.microsoft.com/en-us/microsoft-edge/webview2/?form=MA13LH
    ///
    /// Option 2: choose one of the distribution method described in detail here:
    /// https://docs.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution
    ///
    /// Also, on Windows Platform, we should create a WebViewEnvironment with a custom user data folder, as
    /// the default one is where the .exe goes (which is read-only).
    if (Platform.isWindows) {
      final localAppData = Platform.environment['APPDATA'];
      _webViewProvider.webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: '$localAppData\\com.manuito\\torn_pda\\webview_windows',
        ),
      );
    }

    // Assess the split screen condition right after launch, in case the device is already in wide screen
    // position (needed for Android & Windows). This is also needed if the screen is splitted in order to avoid
    // loading the Drawer and disposing it immediately while its prefs are being retrieved
    _setSplitScreenPosition();

    // Native user status check and auth time check
    final NativeUserProvider nativeUser = context.read<NativeUserProvider>();
    final NativeAuthProvider nativeAuth = context.read<NativeAuthProvider>();
    await nativeUser.loadPreferences();
    await nativeAuth.loadPreferences();
    if (nativeUser.isNativeUserEnabled()) {
      nativeAuth.authStatus = NativeAuthStatus.loggedIn;
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

logToUser(String? message, {int duration = 3, Color? color, Color? borderColor}) {
  log(message.toString());
  if (message == null) return;
  color ??= Colors.red.shade600;
  borderColor ??= Colors.red.shade800;
  if (logAndShowToUser) {
    toastification.showCustom(
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.bottomCenter,
      builder: (BuildContext context, ToastificationItem holder) {
        return Center(
          child: GestureDetector(
              onTap: () => toastification.dismiss(holder),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                  border: Border.all(color: borderColor!, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text("Debug Message\n", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(message.toString(), style: TextStyle(color: Colors.white)),
                  ],
                ),
              )),
        );
      },
    );
  }
}
