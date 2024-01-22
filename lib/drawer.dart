// Dart imports:

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

// Package imports:
import 'package:app_links/app_links.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
// Flutter imports:
import 'package:flutter/material.dart' hide Intent;
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:toggle_switch/toggle_switch.dart';
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/faction/faction_attacks_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/pages/about.dart';
import 'package:torn_pda/pages/alerts.dart';
import 'package:torn_pda/pages/alerts/stockmarket_alerts_page.dart';
import 'package:torn_pda/pages/awards_page.dart';
import 'package:torn_pda/pages/chaining/ranked_wars_page.dart';
import 'package:torn_pda/pages/chaining_page.dart';
import 'package:torn_pda/pages/friends_page.dart';
import 'package:torn_pda/pages/items_page.dart';
import 'package:torn_pda/pages/loot.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/settings_page.dart';
import 'package:torn_pda/pages/stakeouts_page.dart';
import 'package:torn_pda/pages/tips_page.dart';
import 'package:torn_pda/pages/travel_page.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/appwidget/appwidget_explanation.dart';
import 'package:torn_pda/utils/appwidget/pda_widget.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/drawer/announcement_dialog.dart';
import 'package:torn_pda/widgets/tct_clock.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

bool routeWithDrawer = true;
String routeName = "drawer";

class DrawerPage extends StatefulWidget {
  @override
  DrawerPageState createState() => DrawerPageState();
}

class DrawerPageState extends State<DrawerPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final int _settingsPosition = 11;
  final int _aboutPosition = 12;
  var _allowSectionsWithoutKey = <int>[];

  // !! Note: if order is changed, remember to look for other pages calling [_callSectionFromOutside]
  // via callback, as it might need to be changed as well
  final _drawerItemsList = [
    "Profile",
    "Travel",
    "Chaining",
    "Loot",
    "Friends",
    "Stakeouts",
    "Awards",
    "Items",
    "Ranked Wars",
    "Stock Market",
    "Alerts",
    "Settings",
    "About",
    "Tips"
  ];

  final StatsController _statsController = StatsController();

  ThemeProvider? _themeProvider;
  UserDetailsProvider? _userProvider;
  late SettingsProvider _settingsProvider;
  late UserScriptsProvider _userScriptsProvider;
  late WebViewProvider _webViewProvider;
  final StakeoutsController _s =
      Get.put(StakeoutsController(), permanent: true);
  final ApiCallerController _apiController = Get.find<ApiCallerController>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  DateTime? _deepLinkSubTriggeredTime;
  bool _deepLinkInitOnce = false;

  // Used to avoid racing condition with browser launch from notifications (not included in the FutureBuilder), as
  // preferences take time to load
  final Completer _preferencesCompleter = Completer();
  final Completer _changelogCompleter = Completer();
  // Used for the main UI loading (FutureBuilder)
  Future? _finishedWithPreferences;
  Future? _finishedWithChangelog;

  int _activeDrawerIndex = 0;
  int _selected = 0;

  bool _changelogIsActive = false;
  bool _forceFireUserReload = false;

  bool _retalsRedirection = false;

  String _userUID = "";
  bool _drawerUserChecked = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Allows to space alerts when app is on the foreground
  late DateTime _lastMessageReceived;
  String? _lastBody;
  int concurrent = 0;
  // Assigns different ids to alerts when the app is on the foreground
  int notId = 900;

  // Platform channel with MainActivity.java
  static const platform = MethodChannel('tornpda.channel');

  // Intent receiver subscription
  StreamSubscription? _intentListenerSub;

  // Deep links
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _deepLinkSubscription;
  late Stream _willPopShouldOpenDrawer;
  StreamSubscription? _willPopSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start stats counting
    _statsController.logCheckIn();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // STARTS QUICK ACTIONS
      const QuickActions quickActions = QuickActions();

      quickActions.setShortcutItems(<ShortcutItem>[
        // NOTE: keep the same file name for both platforms
        const ShortcutItem(
            type: 'open_torn',
            localizedTitle: 'Torn Home',
            icon: "action_torn"),
        const ShortcutItem(
            type: 'open_gym', localizedTitle: 'Gym', icon: "action_gym"),
        const ShortcutItem(
            type: 'open_crimes',
            localizedTitle: 'Crimes',
            icon: "action_crimes"),
        const ShortcutItem(
            type: 'open_travel',
            localizedTitle: 'Travel',
            icon: "action_travel"),
      ]);

      quickActions.initialize((String shortcutType) async {
        if (shortcutType == 'open_torn') {
          context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: "https://www.torn.com",
                browserTapType: BrowserTapType.quickItem,
              );
        } else if (shortcutType == 'open_gym') {
          context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: "https://www.torn.com/gym.php",
                browserTapType: BrowserTapType.quickItem,
              );
        } else if (shortcutType == 'open_crimes') {
          context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: "https://www.torn.com/crimes.php",
                browserTapType: BrowserTapType.quickItem,
              );
        } else if (shortcutType == 'open_travel') {
          context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: "https://www.torn.com/travelagency.php",
                browserTapType: BrowserTapType.quickItem,
              );
        }
      });
    });
    // ENDS QUICK ACTIONS

    _allowSectionsWithoutKey = [
      _settingsPosition,
      _aboutPosition,
    ];

    // Ensures Shared Prefs are ready for changelog data saving
    Prefs().reload().then((_) {
      _finishedWithChangelog = _handleChangelog();
      _changelogCompleter.complete(_finishedWithChangelog);

      _finishedWithPreferences = _loadInitPreferences();
      _preferencesCompleter.complete(_finishedWithPreferences);
    });

    // Deep Linking
    _deepLinksInit();

    // This starts a stream that listens for tap on local notifications (i.e.:
    // when the app is open)
    _onForegroundNotification();

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
      _messaging.setForegroundNotificationPresentationOptions();
    }

    _lastMessageReceived = DateTime.now();
    _lastBody = "";

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        _onFirebaseBackgroundNotification(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.data.isNotEmpty) {
        _onFirebaseBackgroundNotification(message.data);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // This allows for notifications other than predefined ones in functions
      if (message.data.isEmpty) {
        message.data["title"] = message.notification!.title;
        message.data["body"] = message.notification!.body;
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
        _lastBody = message.data["body"] as String?;
        // Assigns a different id two alerts that come together (otherwise one
        // deletes the previous one)
        notId++;
        if (notId > 990) notId = 900;
        // This will eventually fire a local notification
        showNotification(message.data, notId);
      } else {
        return;
      }
    });

    // Handle notifications
    _getBackgroundNotificationSavedData();
    _removeExistingNotifications();

    // Init intent listener (for appWidget)
    if (Platform.isAndroid) {
      _initIntentListenerSubscription();
      _initIntentReceiverOnLaunch();
    }

    // Remote Config settings
    remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(minutes: kDebugMode ? 1 : 1440),
    ));

    // Remote Config defaults
    remoteConfig.setDefaults(const {
      "tsc_enabled": true,
      "prefs_backup_enabled": true,
    });

    // Remote Config first fetch and live update
    _preferencesCompleter.future.whenComplete(() async {
      await remoteConfig.fetchAndActivate();
      _settingsProvider.tscEnabledStatusRemoteConfig =
          remoteConfig.getBool("tsc_enabled");
      _settingsProvider.backupPrefsEnabledStatusRemoteConfig =
          remoteConfig.getBool("prefs_backup_enabled");

      remoteConfig.onConfigUpdated.listen((event) async {
        await remoteConfig.activate();
        if (event.updatedKeys.contains("tsc_enabled")) {
          log("Remote Config tsc_enabled: ${remoteConfig.getBool("tsc_enabled")}");
          _settingsProvider.tscEnabledStatusRemoteConfig =
              remoteConfig.getBool("tsc_enabled");
          _settingsProvider.backupPrefsEnabledStatusRemoteConfig =
              remoteConfig.getBool("prefs_backup_enabled");
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    selectNotificationStream.close();
    _willPopSubscription?.cancel();
    _intentListenerSub?.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {
      // Note: orientation here is taken BEFORE the change
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: _themeProvider!.statusBar,
          systemNavigationBarColor: _themeProvider!.statusBar,
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
          // iOS
          statusBarBrightness: Brightness.dark,
        ),
      );
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      // Stop stakeouts
      _s.stopTimer();
      log("Stakeouts stopped");

      // Stop stats counting
      _statsController.logCheckOut();

      // Refresh widget to have up to date info when we exit
      if (Platform.isAndroid) {
        if ((await pdaWidget_numberInstalled()) > 0) {
          pdaWidget_startBackgroundUpdate();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Update Firebase active parameter
      _updateLastActiveTime();

      // Handle notifications
      _getBackgroundNotificationSavedData();
      _removeExistingNotifications();

      // Resume stakeouts
      _s.startTimer();
      log("Stakeouts resumed");

      // Resume stats counting
      _statsController.logCheckIn();

      // App widget - reset background updater
      if (Platform.isAndroid) {
        pdaWidget_handleBackgroundUpdateStatus();
      }

      // Check for script updates
      final int alreadyAvailableCount = _userScriptsProvider.userScriptList
          .where(
              (s) => s.updateStatus == UserScriptUpdateStatus.updateAvailable)
          .length;
      _userScriptsProvider.checkForUpdates().then((i) async {
        // Check if we need to show a notification (only if there are any new updates)
        if (i - alreadyAvailableCount > 0) {
          flutterLocalNotificationsPlugin.show(
              777,
              "Torn PDA",
              "You have $i script update${i == 1 ? "" : "s"} available, visit the UserScripts "
                  "section to update them.",
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  "torn_pda",
                  "Torn PDA",
                  importance: Importance.max,
                  priority: Priority.high,
                  showWhen: false,
                  ticker: "ticker",
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              );
        }
        log("UserScripts checkForUpdates() completed with $i updates available, "
        "$alreadyAvailableCount already prompted");
      });
    }
  }

  // ## Intent Listener (for appWidget)
  Future<void> _initIntentReceiverOnLaunch() async {
    final intent = await ReceiveIntent.getInitialIntent();
    if (!mounted || intent!.data == null) return;
    log("Intent received: ${intent.data}");
    await _assessIntent(intent);
  }

  Future<void> _initIntentListenerSubscription() async {
    _intentListenerSub = ReceiveIntent.receivedIntentStream.listen(
      (Intent? intent) async {
        if (!mounted || intent!.data == null) return;
        await _assessIntent(intent);
      },
      onError: (err) {
        log(err);
      },
    );
  }

  Future<void> _assessIntent(Intent intent) async {
    log("Intent received: ${intent.data}");

    bool launchBrowser = false;
    var browserUrl = "https://www.torn.com";
    if (intent.data!.contains("pdaWidget://energy:box:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/gym.php";
    } else if (intent.data!.contains("pdaWidget://nerve:box:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/crimes.php";
    } else if (intent.data!.contains("pdaWidget://happy:box:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#candy-items";
    } else if (intent.data!.contains("pdaWidget://life:box:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#medical-items";
    } else if (intent.data!.contains("pdaWidget://blue:status:clicked") ||
        intent.data!.contains("pdaWidget://blue:status:icon:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com";
    } else if (intent.data!
        .contains("pdaWidget://hospital:status:icon:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/hospitalview.php";
    } else if (intent.data!.contains("pdaWidget://jail:status:icon:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/jailview.php";
    } else if (intent.data!.contains("pdaWidget://messages:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/messages.php";
    } else if (intent.data!.contains("pdaWidget://events:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/events.php";
    } else if (intent.data!.contains("pdaWidget://shortcut:")) {
      final String shortcutUrl = intent.data!.split("pdaWidget://shortcut:")[1];
      launchBrowser = true;
      browserUrl = shortcutUrl;
    } else if (intent.data!.contains("pdaWidget://drug:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#drugs:items";
    } else if (intent.data!.contains("pdaWidget://medical:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#medical:items";
    } else if (intent.data!.contains("pdaWidget://booster:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#boosters:items";
    } else if (intent.data!.contains("pdaWidget://chain:box:clicked")) {
      _callSectionFromOutside(2); // Chaining
      return;
    } else if (intent.data!.contains("pdaWidget://empty:shortcuts:clicked")) {
      if (!_webViewProvider.webViewSplitActive) {
        setState(() {
          _webViewProvider.browserShowInForeground = false;
        });
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => ShortcutsPage(),
        ),
      );
      return;
    }

    if (launchBrowser) {
      _preferencesCompleter.future.whenComplete(() async {
        await _changelogCompleter.future;
        _webViewProvider.openBrowserPreference(
          context: context,
          url: browserUrl,
          browserTapType: BrowserTapType.notification,
        );
      });
    }
  }
  // ## END Intent Listener (for appWidget)

  // ## Deep links
  Future _deepLinksInit() async {
    if (_deepLinkInitOnce) return;
    _appLinks = AppLinks();
    _deepLinkInitOnce = true;

    try {
      // Check initial link if app was in cold state (terminated)
      final appLink = await _appLinks.getInitialAppLink();
      if (appLink != null) {
        log('getInitialAppLink: $appLink');
        _deepLinkHandle(appLink.toString());
      }

      // Handle link when app is in warm state (front or background)
      _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
        log('onAppLink: $uri');
        _deepLinkHandle(uri.toString());
      });
    } catch (e) {
      _deepLinkHandle(e.toString(), error: true);
    }
  }

  Future<void> _deepLinkHandle(String? link, {bool error = false}) async {
    try {
      bool showError = false;
      String? url = link;
      if (error) {
        showError = true;
      } else {
        url = url!.replaceAll("http://", "https://");
        // Double tornpda comes from href in website
        // <a href="intent://tornpda://www.cnn.com#Intent;package=com.manuito.tornpda;scheme=tornpda;end">test</a>
        url = url.replaceAll("tornpda://tornpda://", "https://");
        url = url.replaceAll("tornpda://", "https://");
        if (!url.contains("https://")) {
          showError = true;
        }
      }

      if (showError) {
        BotToast.showText(
          text: "Incorrect deep link!\n\n$url",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.orange[700]!,
          duration: const Duration(seconds: 4),
          contentPadding: const EdgeInsets.all(10),
        );
        return;
      } else {
        // Prevents double activation
        if (_deepLinkSubTriggeredTime != null &&
            DateTime.now().difference(_deepLinkSubTriggeredTime!).inSeconds <
                3) {
          if (_settingsProvider.debugMessages) {
            BotToast.showText(
              onlyOne: false,
              text: "Deep link triggered return\n\n "
                  "${DateTime.now().difference(_deepLinkSubTriggeredTime!).inSeconds} seconds",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.red[700]!,
              duration: const Duration(seconds: 3),
              contentPadding: const EdgeInsets.all(10),
            );
            await Future.delayed(Duration(seconds: 1));
          }
          return;
        }
        _deepLinkSubTriggeredTime = DateTime.now();
        _preferencesCompleter.future.whenComplete(() async {
          await _changelogCompleter.future;

          if (_settingsProvider.debugMessages) {
            BotToast.showText(
              onlyOne: false,
              text: "Deep link browser opens\n\n$url",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue[700]!,
              duration: const Duration(seconds: 3),
              contentPadding: const EdgeInsets.all(10),
            );
          }

          _webViewProvider.openBrowserPreference(
            context: context,
            url: url,
            browserTapType: BrowserTapType.deeplink,
          );
        });
      }
    } catch (e) {
      if (_settingsProvider.debugMessages) {
        BotToast.showText(
          text: "Deep link catch\n\n$e",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.orange[700]!,
          duration: const Duration(seconds: 4),
          contentPadding: const EdgeInsets.all(10),
        );
      }
    }
  }
  // ## END Deep links

  Future<void> _removeExistingNotifications() async {
    _preferencesCompleter.future.whenComplete(() async {
      // Get rid of iOS badge (notifications will be removed by the system)
      if (Platform.isIOS) {
        _clearBadge();
      }
      // Get rid of notifications in Android
      try {
        if (Platform.isAndroid &&
            _settingsProvider.removeNotificationsOnLaunch) {
          // Gets the active (already shown) notifications
          final List<ActiveNotification> activeNotifications =
              (await flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.getActiveNotifications())!;

          for (final not in activeNotifications) {
            if (not.id == null) continue;
            // Platform channel to cancel direct Firebase notifications (we can call
            // "cancelAll()" there without affecting scheduled notifications, which is
            // a problem with the local plugin)
            if (not.id == 0) {
              await platform.invokeMethod('cancelNotifications');
            }
            // This cancels the Firebase alerts that have been triggered locally
            else {
              flutterLocalNotificationsPlugin.cancel(not.id!);
            }
          }
        }
      } catch (e) {
        // Not supported?
      }
    });
  }

  Future<void> _getBackgroundNotificationSavedData() async {
    // Reload isolate (as we are reading from background)
    await Prefs().reload();
    // Get the save alerts
    Prefs().getDataStockMarket().then((stocks) {
      if (stocks.isNotEmpty) {
        Prefs().setDataStockMarket("");
        Future.delayed(const Duration(seconds: 1))
            .then((value) => _openBackgroundStockDialog(stocks));
      }
    });
  }

  Future<void> _onFirebaseBackgroundNotification(
      Map<String, dynamic> message) async {
    bool launchBrowser = false;
    var browserUrl = "https://www.torn.com";

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
    bool medical = false;
    bool booster = false;
    bool refills = false;
    bool stockMarket = false;
    bool assists = false;
    bool loot = false;
    bool retals = false;

    String? channel = '';
    String? messageId = '';
    String? tradeId = '';
    String? assistId = '';
    String? bulkDetails = '';

    if (Platform.isIOS) {
      channel = message["channelId"] as String?;
      messageId = message["tornMessageId"] as String?;
      tradeId = message["tornTradeId"] as String?;
      assistId = message["assistId"] as String?;
      bulkDetails = message["bulkDetails"] as String?;
    } else if (Platform.isAndroid) {
      channel = message["channelId"] as String?;
      messageId = message["tornMessageId"] as String?;
      tradeId = message["tornTradeId"] as String?;
      assistId = message["assistId"] as String?;
      bulkDetails = message["bulkDetails"] as String?;
    }

    if (channel!.contains("Alerts travel")) {
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
    } else if (channel.contains("Alerts medical")) {
      medical = true;
    } else if (channel.contains("Alerts booster")) {
      booster = true;
    } else if (channel.contains("Alerts refills")) {
      refills = true;
    } else if (channel.contains("Alerts stocks")) {
      stockMarket = true;
    } else if (channel.contains("Alerts assists")) {
      assists = true;
    } else if (channel.contains("Alerts loot")) {
      loot = true;
    } else if (channel.contains("Alerts retals")) {
      retals = true;
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
    } else if (medical) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#medical-items";
    } else if (booster) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#boosters-items";
    } else if (refills) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/points.php";
    } else if (retals) {
      if (int.parse(bulkDetails!) == -1) {
        // No-host notification
        return;
      }
      // If we have the section manually deactivated
      // Or everything is OK but we elected to open the browser with just 1 target
      // >> Open browser
      _preferencesCompleter.future.whenComplete(() async {
        await _changelogCompleter.future;
        if (!_settingsProvider.retaliationSectionEnabled ||
            (int.parse(bulkDetails!) == 1 &&
                _settingsProvider.singleRetaliationOpensBrowser)) {
          launchBrowser = true;
          browserUrl =
              "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
        } else {
          // Even if we meet above requirements, call the API and assess whether the user
          // as API permits (if he does not, open the browser anyway as he can't use the retals section)
          final attacksResult =
              await Get.find<ApiCallerController>().getFactionAttacks();
          if (attacksResult is! FactionAttacksModel) {
            launchBrowser = true;
            browserUrl =
                "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
          } else {
            // If we pass all checks above, redirect to the retals section
            _retalsRedirection = true;
            _callSectionFromOutside(2);
            Future.delayed(const Duration(seconds: 2)).then((value) {
              _retalsRedirection = false;
            });
          }
        }
      });
    } else if (stockMarket) {
      // Not implemented (there is a box showing in _getBackGroundNotifications)
    } else if (assists) {
      launchBrowser = true;
      browserUrl =
          "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";

      Color? totalColor = Colors.grey[700];
      try {
        if (bulkDetails!.isNotEmpty) {
          final bulkList = bulkDetails.split("#");
          int? otherXanax = int.tryParse(bulkList[0].split("xanax:")[1]);
          int? otherRefills = int.tryParse(bulkList[1].split("refills:")[1]);
          int? otherDrinks = int.tryParse(bulkList[2].split("drinks:")[1]);

          final own =
              await Get.find<ApiCallerController>().getOwnPersonalStats();
          if (own is OwnPersonalStatsModel) {
            final int xanaxComparison =
                otherXanax! - own.personalstats!.xantaken!;
            final int refillsComparison =
                otherRefills! - own.personalstats!.refills!;
            final int drinksComparison =
                otherDrinks! - own.personalstats!.energydrinkused!;

            final int otherTotals = otherXanax + otherRefills + otherDrinks;
            final int myTotals = own.personalstats!.xantaken! +
                own.personalstats!.refills! +
                own.personalstats!.energydrinkused!;

            if (otherTotals < myTotals - myTotals * 0.1) {
              totalColor = Colors.green[700];
            } else if (otherTotals >= myTotals - myTotals * 0.1 &&
                otherTotals <= myTotals + myTotals * 0.1) {
              totalColor = Colors.orange[700];
            } else {
              totalColor = Colors.red[700];
            }

            String xanaxString = "";
            if (xanaxComparison < 0) {
              xanaxString = "\n- Xanax: ${xanaxComparison.abs()} LESS than you";
            } else if (xanaxComparison == 0) {
              xanaxString = "\n- Xanax: SAME as you";
            } else {
              xanaxString = "\n- Xanax: ${xanaxComparison.abs()} MORE than you";
            }

            String refillsString = "";
            if (refillsComparison < 0) {
              refillsString =
                  "\n- Refills (E): ${refillsComparison.abs()} LESS than you";
            } else if (refillsComparison == 0) {
              refillsString = "\n- Refills (E): SAME as you";
            } else {
              refillsString =
                  "\n- Refills (E): ${refillsComparison.abs()} MORE than you";
            }

            String drinksString = "";
            if (drinksComparison < 0) {
              drinksString =
                  "\n- Drinks (E): ${drinksComparison.abs()} LESS than you";
            } else if (drinksComparison == 0) {
              drinksString = "\n- Drinks (E): SAME as you";
            } else {
              drinksString =
                  "\n- Drinks (E): ${drinksComparison.abs()} MORE than you";
            }

            if (xanaxString.isNotEmpty &&
                refillsString.isNotEmpty &&
                drinksString.isNotEmpty) {
              int? begin = message["body"].indexOf("\n- Xanax");
              int? last = message["body"].length;
              message["body"] = message["body"].replaceRange(begin, last, "");
              message["body"] += xanaxString;
              message["body"] += refillsString;
              message["body"] += drinksString;
            }
          }
        }
      } catch (e) {
        // Leave as it was
        print(e);
      }

      BotToast.showText(
        align: const Alignment(0, 0),
        clickClose: true,
        text: message["body"],
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: totalColor!,
        duration: const Duration(seconds: 10),
        contentPadding: const EdgeInsets.all(10),
      );
    } else if (loot) {
      final incomingIds = assistId!.split(",");
      if (incomingIds.length == 1 && !incomingIds[0].contains("[")) {
        // This is a standard loot alert for a single NPC
        launchBrowser = true;
        browserUrl =
            "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
      } else if (incomingIds[0].contains("[")) {
        // This is a Loot Rangers alert for one or more NPCs
        final ids = <String>[];
        final names = <String>[];
        final notes = <String>[];
        final colors = <String>[];
        for (var i = 0; i < incomingIds.length; i++) {
          final parts = incomingIds[i].split("[");
          names.add(parts[0]);
          ids.add(parts[1].replaceAll("]", ""));
          colors.add("green");
          if (i == 0) {
            notes.add("Attacks due to commence at $bulkDetails TCT!");
          } else {
            notes.add("");
          }
        }

        // Open chaining browser for Loot Rangers
        _webViewProvider.openBrowserPreference(
          context: context,
          url: "https://www.torn.com/loader.php?sid=attack&user2ID=${ids[0]}",
          browserTapType: BrowserTapType.chain,
          isChainingBrowser: true,
          chainingPayload: ChainingPayload()
            ..attackIdList = ids
            ..attackNameList = names
            ..attackNotesList = notes
            ..attackNotesColorList = colors
            ..showNotes = true
            ..showBlankNotes = false
            ..showOnlineFactionWarning = false,
        );
      }
    }

    if (launchBrowser) {
      _preferencesCompleter.future.whenComplete(() async {
        await _changelogCompleter.future;
        _webViewProvider.openBrowserPreference(
          context: context,
          url: browserUrl,
          browserTapType: BrowserTapType.notification,
        );
      });
    }
  }

  // Fires if notification from local_notifications package is tapped (i.e.:
  // when the app is open). Also for manual notifications when app is open.
  Future<void> _onForegroundNotification() async {
    selectNotificationStream.stream.listen((String? payload) async {
      var launchBrowser = false;
      var browserUrl = '';

      if (payload == 'travel') {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com';
      } else if (payload == 'restocks') {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/travelagency.php';
      } else if (payload!.contains('energy')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/gym.php';
      } else if (payload.contains('nerve')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/crimes.php';
      } else if (payload.contains('drugs')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/item.php#drugs-items';
      } else if (payload.contains('medical')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/item.php#medical-items';
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
        browserUrl =
            'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
      } else if (payload.contains('499-')) {
        // Loot Rangers payload is (split by -)
        // [0] 499
        // [1] id list
        // [2] name list
        // [3] timestamp

        final lootRangersNpcsIds = payload.split('-')[1].split(",");
        final lootRangersNpcsNames = payload.split('-')[2].split(",");
        final lootRangersTime = payload.split('-')[3];
        final timeNote = "Attacks due to commence at $lootRangersTime!";

        final notes = <String>[];
        final colors = <String>[];
        for (var i = 0; i < lootRangersNpcsIds.length; i++) {
          colors.add("green");
          if (i == 0) {
            notes.add(timeNote);
          } else {
            notes.add("");
          }
        }

        // Open chaining browser for Loot Rangers
        _webViewProvider.openBrowserPreference(
          context: context,
          url:
              "https://www.torn.com/loader.php?sid=attack&user2ID=${lootRangersNpcsIds[0]}",
          browserTapType: BrowserTapType.chain,
          isChainingBrowser: true,
          chainingPayload: ChainingPayload()
            ..attackIdList = lootRangersNpcsIds
            ..attackNameList = lootRangersNpcsNames
            ..attackNotesList = notes
            ..attackNotesColorList = colors
            ..showNotes = true
            ..showBlankNotes = false
            ..showOnlineFactionWarning = false,
        );

        browserUrl =
            'https://www.torn.com/loader.php?sid=attack&user2ID=$lootRangersNpcsIds';
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
          browserUrl =
              "https://www.torn.com/trade.php#step=view&ID=${tradeId[1]}";
        }
      } else if (payload.contains('211')) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/travelagency.php';
      } else if (payload.contains('refills') && (!payload.contains("Xanax"))) {
        launchBrowser = true;
        browserUrl = 'https://www.torn.com/points.php';
      } else if (payload.contains('retals')) {
        final assistSplit = payload.split('###');
        final assistId = assistSplit[0].split(':')[1];
        final bulkDetails = assistSplit[1].split(':')[1];

        if (int.parse(bulkDetails) == -1) {
          // No-host notification
          return;
        }

        // If we have the section manually deactivated
        // Or everything is OK but we elected to open the browser with just 1 target
        // >> Open browser
        if (!_settingsProvider.retaliationSectionEnabled ||
            (int.parse(bulkDetails) == 1 &&
                _settingsProvider.singleRetaliationOpensBrowser)) {
          launchBrowser = true;
          browserUrl =
              "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
        } else {
          // Even if we meet above requirements, call the API and assess whether the user
          // as API permits (if he does not, open the browser anyway as he can't use the retals section)
          final attacksResult =
              await Get.find<ApiCallerController>().getFactionAttacks();
          if (attacksResult is! FactionAttacksModel) {
            launchBrowser = true;
            browserUrl =
                "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
          } else {
            // If we pass all checks above, redirect to the retals section
            _retalsRedirection = true;
            _callSectionFromOutside(2);
            Future.delayed(const Duration(seconds: 2)).then((value) {
              _retalsRedirection = false;
            });
          }
        }
      } else if (payload.contains('stockMarket')) {
        // Not implemented (there is a box showing in _getBackGroundNotifications)
      } else if (payload.contains('assistId:')) {
        launchBrowser = true;
        final assistSplit = payload.split('###');
        final assistId = assistSplit[0].split(':');
        final assistBody = assistSplit[1].split('assistDetails:');
        final bulkDetails = assistSplit[2].split('bulkDetails:');
        browserUrl =
            "https://www.torn.com/loader.php?sid=attack&user2ID=${assistId[1]}";

        Color? totalColor = Colors.grey[700];
        try {
          if (bulkDetails[1].isNotEmpty) {
            final bulkList = bulkDetails[1].split("#");
            int? otherXanax = int.tryParse(bulkList[0].split("xanax:")[1]);
            int? otherRefills = int.tryParse(bulkList[1].split("refills:")[1]);
            int? otherDrinks = int.tryParse(bulkList[2].split("drinks:")[1]);

            final own =
                await Get.find<ApiCallerController>().getOwnPersonalStats();
            if (own is OwnPersonalStatsModel) {
              final int xanaxComparison =
                  otherXanax! - own.personalstats!.xantaken!;
              final int refillsComparison =
                  otherRefills! - own.personalstats!.refills!;
              final int drinksComparison =
                  otherDrinks! - own.personalstats!.energydrinkused!;

              final int otherTotals = otherXanax + otherRefills + otherDrinks;
              final int myTotals = own.personalstats!.xantaken! +
                  own.personalstats!.refills! +
                  own.personalstats!.energydrinkused!;

              if (otherTotals < myTotals - myTotals * 0.1) {
                totalColor = Colors.green[700];
              } else if (otherTotals >= myTotals - myTotals * 0.1 &&
                  otherTotals <= myTotals + myTotals * 0.1) {
                totalColor = Colors.orange[700];
              } else {
                totalColor = Colors.red[700];
              }

              String xanaxString = "";
              if (xanaxComparison < 0) {
                xanaxString =
                    "\n- Xanax: ${xanaxComparison.abs()} LESS than you";
              } else if (xanaxComparison == 0) {
                xanaxString = "\n- Xanax: SAME as you";
              } else {
                xanaxString =
                    "\n- Xanax: ${xanaxComparison.abs()} MORE than you";
              }

              String refillsString = "";
              if (refillsComparison < 0) {
                refillsString =
                    "\n- Refills (E): ${refillsComparison.abs()} LESS than you";
              } else if (refillsComparison == 0) {
                refillsString = "\n- Refills (E): SAME as you";
              } else {
                refillsString =
                    "\n- Refills (E): ${refillsComparison.abs()} MORE than you";
              }

              String drinksString = "";
              if (drinksComparison < 0) {
                drinksString =
                    "\n- Drinks (E): ${drinksComparison.abs()} LESS than you";
              } else if (drinksComparison == 0) {
                drinksString = "\n- Drinks (E): SAME as you";
              } else {
                drinksString =
                    "\n- Drinks (E): ${drinksComparison.abs()} MORE than you";
              }

              if (xanaxString.isNotEmpty &&
                  refillsString.isNotEmpty &&
                  drinksString.isNotEmpty) {
                final int begin = assistBody[1].indexOf("\n- Xanax");
                final int last = assistBody[1].length;
                assistBody[1] = assistBody[1].replaceRange(begin, last, "");
                assistBody[1] += xanaxString;
                assistBody[1] += refillsString;
                assistBody[1] += drinksString;
              }
            }
          }
        } catch (e) {
          // Leave as it was
        }

        BotToast.showText(
          align: const Alignment(0, 0),
          clickClose: true,
          text: assistBody[1],
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: totalColor!,
          duration: const Duration(seconds: 10),
          contentPadding: const EdgeInsets.all(10),
        );
      } else if (payload.contains('lootId:')) {
        final assistSplit = payload.split('###');
        final assistId = assistSplit[0].split(':');
        final bulkDetails = assistSplit[1].split('bulkDetails:');
        final incomingIds = assistId[1].split(",");
        if (incomingIds.length == 1 && !incomingIds[0].contains("[")) {
          // This is a standard loot alert for a single NPC
          launchBrowser = true;
          browserUrl =
              "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
        } else if (incomingIds[0].contains("[")) {
          // This is a Loot Rangers alert for one or more NPCs
          final ids = <String>[];
          final names = <String>[];
          final notes = <String>[];
          final colors = <String>[];
          for (var i = 0; i < incomingIds.length; i++) {
            final parts = incomingIds[i].split("[");
            names.add(parts[0]);
            ids.add(parts[1].replaceAll("]", ""));
            colors.add("green");
            if (i == 0) {
              notes.add("Attacks due to commence at ${bulkDetails[1]} TCT!");
            } else {
              notes.add("");
            }
          }

          // Open chaining browser for Loot Rangers
          _webViewProvider.openBrowserPreference(
            context: context,
            url: "https://www.torn.com/loader.php?sid=attack&user2ID=${ids[0]}",
            browserTapType: BrowserTapType.chain,
            isChainingBrowser: true,
            chainingPayload: ChainingPayload()
              ..attackIdList = ids
              ..attackNameList = names
              ..attackNotesList = notes
              ..attackNotesColorList = colors
              ..showNotes = true
              ..showBlankNotes = false
              ..showOnlineFactionWarning = false,
          );
        }
      }

      if (launchBrowser) {
        _preferencesCompleter.future.whenComplete(() async {
          await _changelogCompleter.future;
          _webViewProvider.openBrowserPreference(
            context: context,
            url: browserUrl,
            browserTapType: BrowserTapType.notification,
          );
        });
      }
    });
  }

  Future<void> _openBrowserFromToast(String url) async {
    final browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        await _webViewProvider.openBrowserPreference(
          context: context,
          browserTapType: BrowserTapType.chain,
          url: url,
        );
      case BrowserSetting.external:
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _userProvider = Provider.of<UserDetailsProvider>(context);
    // Listen actively to [_webViewProvider] even if was already assigned in [_loadInitPreferences]
    // so that the drawer is properly configured based on split/rotation preferences
    _webViewProvider = Provider.of<WebViewProvider>(context);

    _s.callbackBrowser = _openBrowserFromToast;
    return FutureBuilder(
      future: _finishedWithPreferences,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !_changelogIsActive) {
          // This container is needed in all pages for certain devices with appbar at the bottom, otherwise the
          // safe area will be black
          return Container(
            color: _themeProvider!.currentTheme == AppTheme.light
                ? MediaQuery.orientationOf(context) == Orientation.portrait
                    ? Colors.blueGrey
                    : _themeProvider!.canvas
                : _themeProvider!.canvas,
            child: SafeArea(
              right: _webViewProvider.webViewSplitActive &&
                  _webViewProvider.splitScreenPosition ==
                      WebViewSplitPosition.left,
              left: _webViewProvider.webViewSplitActive &&
                  _webViewProvider.splitScreenPosition ==
                      WebViewSplitPosition.right,
              child: Scaffold(
                key: _scaffoldKey,
                body: _getPages(),
                endDrawer: _webViewProvider.webViewSplitActive &&
                        _webViewProvider.splitScreenPosition ==
                            WebViewSplitPosition.left
                    ? Drawer(
                        backgroundColor: _themeProvider!.canvas,
                        surfaceTintColor:
                            _themeProvider!.currentTheme == AppTheme.extraDark
                                ? Colors.black
                                : null,
                        elevation: 2, // This avoids shadow over SafeArea
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: <Widget>[
                            _getDrawerHeader(),
                            _getDrawerItems(),
                          ],
                        ),
                      )
                    : null,
                drawer: _webViewProvider.webViewSplitActive &&
                        _webViewProvider.splitScreenPosition ==
                            WebViewSplitPosition.left
                    ? null
                    : Drawer(
                        backgroundColor: _themeProvider!.canvas,
                        surfaceTintColor:
                            _themeProvider!.currentTheme == AppTheme.extraDark
                                ? Colors.black
                                : null,
                        elevation: 2, // This avoids shadow over SafeArea
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
          );
        } else {
          return Container(
            color: _themeProvider!.secondBackground,
            child: const SafeArea(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _getDrawerHeader() {
    return SizedBox(
      height:
          MediaQuery.orientationOf(context) == Orientation.portrait ? 280 : 250,
      child: DrawerHeader(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Obx(
              () {
                if (_apiController.showApiRateInDrawer.isTrue) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<int>(
                          stream: _apiController.callCountStream,
                          initialData: 0,
                          builder: (BuildContext context,
                              AsyncSnapshot<int> snapshot) {
                            final int callCount = snapshot.data ?? 0;
                            final double progress =
                                math.min(callCount / 100, 1.0);
                            return LinearPercentIndicator(
                              padding: const EdgeInsets.all(0),
                              barRadius: const Radius.circular(10),
                              center: Text(
                                "$callCount",
                                style: const TextStyle(fontSize: 12),
                              ),
                              lineHeight: 14.0,
                              percent: progress,
                              backgroundColor:
                                  _themeProvider!.currentTheme == AppTheme.light
                                      ? Colors.grey[400]
                                      : Colors.grey[800],
                              progressColor: callCount >= 95
                                  ? Colors.red[400]
                                  : Colors.green,
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, top: 1),
                          child: Text(
                            "API CALLS (60s)",
                            style: TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
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
                      SizedBox(
                        height: 30,
                        child: ToggleSwitch(
                          customWidths: const [35, 35, 35],
                          iconSize: 15,
                          borderWidth: 1,
                          cornerRadius: 5,
                          borderColor:
                              _themeProvider!.currentTheme == AppTheme.light
                                  ? [Colors.blueGrey]
                                  : [Colors.grey[900]!],
                          initialLabelIndex: _themeProvider!.currentTheme ==
                                  AppTheme.light
                              ? 0
                              : _themeProvider!.currentTheme == AppTheme.dark
                                  ? 1
                                  : 2,
                          activeBgColor: _themeProvider!.currentTheme ==
                                  AppTheme.light
                              ? [Colors.blueGrey]
                              : _themeProvider!.currentTheme == AppTheme.dark
                                  ? [Colors.blueGrey]
                                  : [Colors.blueGrey[900]!],
                          activeFgColor:
                              _themeProvider!.currentTheme == AppTheme.light
                                  ? Colors.black
                                  : Colors.white,
                          inactiveBgColor: _themeProvider!.currentTheme ==
                                  AppTheme.light
                              ? Colors.white
                              : _themeProvider!.currentTheme == AppTheme.dark
                                  ? Colors.grey[800]
                                  : Colors.black,
                          inactiveFgColor:
                              _themeProvider!.currentTheme == AppTheme.light
                                  ? Colors.black
                                  : Colors.white,
                          totalSwitches: 3,
                          animate: true,
                          animationDuration: 500,
                          icons: const [
                            FontAwesome.sun_o,
                            FontAwesome.moon_o,
                            MdiIcons.ghost,
                          ],
                          onToggle: (index) {
                            if (index == 0) {
                              _themeProvider!.changeTheme = AppTheme.light;
                              if (_settingsProvider.syncTheme) {
                                _webViewProvider.changeTornTheme(dark: false);
                              }
                            } else if (index == 1) {
                              _themeProvider!.changeTheme = AppTheme.dark;
                              if (_settingsProvider.syncTheme) {
                                _webViewProvider.changeTornTheme(dark: true);
                              }
                            } else {
                              _themeProvider!.changeTheme = AppTheme.extraDark;
                              if (_settingsProvider.syncTheme) {
                                _webViewProvider.changeTornTheme(dark: true);
                              }
                              BotToast.showText(
                                text: "Spooky...!",
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                contentColor: const Color(0xFF0C0C0C),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
                            setState(() {
                              SystemChrome.setSystemUIOverlayStyle(
                                SystemUiOverlayStyle(
                                  statusBarColor: _themeProvider!.statusBar,
                                  systemNavigationBarColor:
                                      _themeProvider!.statusBar,
                                  systemNavigationBarIconBrightness:
                                      Brightness.light,
                                  statusBarIconBrightness: Brightness.light,
                                  // iOS
                                  statusBarBrightness: Brightness.dark,
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      _webViewProvider.openBrowserPreference(
                        context: context,
                        url: "https://www.torn.com/calendar.php",
                        browserTapType: BrowserTapType.short,
                      );
                    },
                    onLongPress: () {
                      _webViewProvider.openBrowserPreference(
                        context: context,
                        url: "https://www.torn.com/calendar.php",
                        browserTapType: BrowserTapType.long,
                      );
                    },
                    child: TctClock(color: _themeProvider!.mainText!),
                  ),
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
    if (!_userProvider!.basic!.userApiKeyValid!) {
      for (final position in _allowSectionsWithoutKey) {
        drawerOptions.add(
          ListTileTheme(
            selectedColor: Colors.red,
            iconColor: _themeProvider!.mainText,
            child: Ink(
              color:
                  position == _selected ? Colors.grey[300] : Colors.transparent,
              child: ListTile(
                leading: _returnDrawerIcons(drawerPosition: position),
                title: Text(
                  _drawerItemsList[position],
                  style: TextStyle(
                    fontWeight: position == _selected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
        if (_settingsProvider.disableTravelSection &&
            _drawerItemsList[i] == "Travel") {
          continue;
        }
        if (!_settingsProvider.rankedWarsInMenu &&
            _drawerItemsList[i] == "Ranked Wars") {
          continue;
        }
        if (!_settingsProvider.stockExchangeInMenu &&
            _drawerItemsList[i] == "Stock Market") {
          continue;
        }

        // Adding divider just before SETTINGS
        if (i == _settingsPosition) {
          drawerOptions.add(
            const Divider(),
          );
        }
        drawerOptions.add(
          ListTileTheme(
            selectedColor: Colors.red,
            iconColor: _themeProvider!.mainText,
            child: Ink(
              color: i == _selected ? Colors.grey[300] : Colors.transparent,
              child: ListTile(
                leading: _returnDrawerIcons(drawerPosition: i),
                title: Text(
                  _drawerItemsList[i],
                  style: TextStyle(
                    fontWeight:
                        i == _selected ? FontWeight.bold : FontWeight.normal,
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
      case 1:
        return const TravelPage();
      case 2:
        return ChainingPage(retalsRedirection: _retalsRedirection);
      case 3:
        return LootPage();
      case 4:
        return FriendsPage();
      case 5:
        return const StakeoutsPage();
      case 6:
        return AwardsPage();
      case 7:
        return const ItemsPage();
      case 8:
        return const RankedWarsPage(calledFromMenu: true);
      case 9:
        return StockMarketAlertsPage(
            calledFromMenu: true,
            stockMarketInMenuCallback: _onChangeStockMarketInMenu);
      case 10:
        return AlertsSettings(_onChangeStockMarketInMenu);
      case 11:
        return SettingsPage(
          changeUID: changeUID,
          statsController: _statsController,
        );
      case 12:
        return AboutPage(uid: _userUID);
      case 13:
        return TipsPage();

      default:
        return const Text("Error");
    }
  }

  Widget _returnDrawerIcons({int? drawerPosition}) {
    switch (drawerPosition) {
      case 0:
        return const Icon(Icons.person);
      case 1:
        return const Icon(Icons.local_airport);
      case 2:
        return const Icon(MdiIcons.linkVariant);
      case 3:
        return const Icon(MdiIcons.knifeMilitary);
      case 4:
        return const Icon(Icons.people);
      case 5:
        return const Icon(MdiIcons.cctv);
      case 6:
        return const Icon(MdiIcons.trophy);
      case 7:
        return const Icon(MdiIcons.packageVariantClosed);
      case 8:
        return const Icon(MaterialCommunityIcons.sword_cross);
      case 9:
        return const Icon(MdiIcons.bankTransfer);
      case 10:
        return const Icon(Icons.notifications_active);
      case 11:
        return const Icon(Icons.settings);
      case 12:
        return const Icon(Icons.info_outline);
      case 13:
        return const Icon(Icons.question_answer_outlined);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onSelectItem(int index) async {
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

    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    // Join a stream which will receive a callback from main if applicable whenever the back button is pressed
    _willPopShouldOpenDrawer = _settingsProvider.willPopShouldOpenDrawer.stream;
    _willPopSubscription = _willPopShouldOpenDrawer.listen((event) {
      _openDrawer();
    });

    // Set up UserScriptsProvider so that user preferences are applied
    _userScriptsProvider =
        Provider.of<UserScriptsProvider>(context, listen: false);
    await _userScriptsProvider.loadPreferences();

    // Set up UserProvider. If key is empty, redirect to the Settings page.
    // Else, open the default
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    await _userProvider!.loadPreferences();

    // User Provider was started in Main
    // If key is empty, redirect to the Settings page.
    if (!_userProvider!.basic!.userApiKeyValid!) {
      _selected = _settingsPosition;
      _activeDrawerIndex = _settingsPosition;
    } else {
      String defaultSection = await Prefs().getDefaultSection();
      if (defaultSection == "browser") {
        // If the preferred section is the Browser, we will open it as soon as the preferences are loaded
        _webViewProvider.browserShowInForeground = true;

        // Change to Profile as a base for loading the browser
        defaultSection = "0";
      }
      _selected = int.parse(defaultSection);
      _activeDrawerIndex = int.parse(defaultSection);

      // Firestore get auth and init
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        // Only execute once, otherwise we risk creating users in a row below
        if (_drawerUserChecked) return;
        _drawerUserChecked = true;

        if (user == null) {
          log("Drawer: Firebase user is null, signing in!");
          // Upload information to Firebase (this includes the token)
          final User newAnonUser = await firebaseAuth.signInAnon() as User;
          firestore.setUID(newAnonUser.uid);
          _updateFirebaseDetails();
          _userUID = newAnonUser.uid;

          // Warn user about the possibility of a new UID being regenerated
          // We should not arrive here under normal circumstances, as null users are redirected to Settings
          BotToast.showText(
            clickClose: true,
            text: "A problem was found with your user.\n\n"
                "Please visit the Alerts page and ensure that your alerts are properly setup!",
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.blue,
            duration: const Duration(seconds: 6),
            contentPadding: const EdgeInsets.all(10),
          );
        } else {
          final existingUid = user.uid;
          log("Drawer: Firebase user ID $existingUid");
          firestore.setUID(existingUid);
          _userUID = existingUid;
        }
      });

      // Native user status check and auth time check
      final NativeUserProvider nativeUser = context.read<NativeUserProvider>();
      final NativeAuthProvider nativeAuth = context.read<NativeAuthProvider>();
      await nativeUser.loadPreferences();
      await nativeAuth.loadPreferences();
      if (nativeUser.isNativeUserEnabled()) {
        nativeAuth.authStatus = NativeAuthStatus.loggedIn;
      }
      // ------------------------

      // Update last used time in Firebase when the app opens (we'll do the same in onResumed,
      // since some people might leave the app opened for weeks in the background)
      _updateLastActiveTime();

      _userScriptsProvider.checkForUpdates().then((i) async {
        if (i > 0) {
          BotToast.showText(
            clickClose: true,
            text: "There are $i new scripts available!",
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.blue,
            duration: const Duration(seconds: 6),
            contentPadding: const EdgeInsets.all(10),
          );
        }
        log("UserScripts checkForUpdates() completed with $i updates available");
      });
    }

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
  }

  Future<void> _updateLastActiveTime() async {
    _preferencesCompleter.future.whenComplete(() async {
      // Prevents update on first load
      final api = _userProvider?.basic?.userApiKey;
      if (api == null || api.isEmpty) return;

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
    });
  }

  Future<void> _updateFirebaseDetails() async {
    // We save the key because the API call will reset it
    // Then get user's profile and update
    final savedKey = _userProvider!.basic!.userApiKey;
    final dynamic prof =
        await Get.find<ApiCallerController>().getOwnProfileBasic();
    if (prof is OwnProfileBasic) {
      // Update profile with the two fields it does not contain
      prof
        ..userApiKey = savedKey
        ..userApiKeyValid = true;

      await firestore.uploadUsersProfileDetail(prof, userTriggered: true);
    }

    // Uploads last active time to Firebase
    final now = DateTime.now().millisecondsSinceEpoch;
    final success = await firestore.uploadLastActiveTime(now);
    if (success) {
      _settingsProvider.updateLastUsed = now;
    }
  }

  Future<void> _handleChangelog() async {
    final String savedCompilation = await Prefs().getAppCompilation();
    final String currentCompilation =
        Platform.isAndroid ? androidCompilation : iosCompilation;

    if (savedCompilation != currentCompilation) {
      Prefs().setAppCompilation(currentCompilation);

      // Corrections for hot-fixes
      if (savedCompilation == '291') {
        // Clear hidden foreign stocks in 291 > 292+ due to a bug with persistence
        Prefs().setHiddenForeignStocks([]);
      }

      if (appVersion == '3.2.0') {
        _settingsProvider.changeHighlightColor = 0xFF009628;
      }

      // Will trigger an extra upload to Firebase when version changes
      _forceFireUserReload = true;

      // Reconfigure notification channels in case new sounds are added (e.g. v2.4.2)
      // Deletes current channels and create new ones
      if (Platform.isAndroid) {
        final vibration = await Prefs().getVibrationPattern();
        await reconfigureNotificationChannels(mod: vibration);
      }

      _changelogIsActive = true;
      await _showChangeLogDialog(context);
    } else {
      // Other dialogs we need to show when the dialog is not being displayed

      // Appwidget dialog
      if (Platform.isAndroid) {
        if (!await Prefs().getAppwidgetExplanationShown()) {
          final int widgets = (await HomeWidget.getWidgetCount(
              name: 'HomeWidgetTornPda', iOSName: 'HomeWidgetTornPda'))!;
          if (widgets > 0) {
            await _showAppwidgetExplanationDialog(context);
            Prefs().setAppwidgetExplanationShown(true);
            return; // Do not show more dialogs below
          }
        }
      }

      // Announcement dialog
      // Version hardcoded - only allow users with version 0
      if ((await Prefs().getAppAnnouncementDialogVersion()) <= 0) {
        // For version 1, user needs to have 24 hours of app use
        final int savedSeconds = await Prefs().getStatsCumulatedAppUseSeconds();
        if (savedSeconds < 86400) return;

        // If we are still in an old dialog version, get DB to see if we can are free to show it
        try {
          int? databaseDialogAllowed = (await FirebaseDatabase.instance
                  .ref()
                  .child("announcement/version")
                  .once())
              .snapshot
              .value as int?;
          if (databaseDialogAllowed == 1) {
            // If we are allowed to proceed, show the dialog
            await showDialog(
              useRootNavigator: false,
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AnnouncementDialog(themeProvider: _themeProvider);
              },
            );

            // Then update the version to the current one
            Prefs().setAppAnnouncementDialogVersion(1);
            return; // Do not show more dialogs below
          }
        } catch (e) {
          //
        }
      }

      // Other dialogs
      //...
    }
  }

  Future<void> _showChangeLogDialog(BuildContext context) async {
    await showDialog(
      useRootNavigator: false,
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

  Future<void> _showAppwidgetExplanationDialog(BuildContext context) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AppwidgetExplanationDialog();
      },
    );
  }

  void _callSectionFromOutside(int section) {
    setState(() {
      if (!_webViewProvider.webViewSplitActive) {
        _webViewProvider.browserShowInForeground = false;
      }

      _selected = section;
      _activeDrawerIndex = section;
    });
    _getPages();
  }

  _openDrawer() {
    if (routeWithDrawer) {
      if (_webViewProvider.webViewSplitActive &&
          _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
        _scaffoldKey.currentState!.openEndDrawer();
      } else {
        _scaffoldKey.currentState!.openDrawer();
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
                      color: _themeProvider!.secondBackground,
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
                                  "STOCK MARKET UPDATE!",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _themeProvider!.mainText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Text(
                            update,
                            style: TextStyle(
                                fontSize: 11, color: _themeProvider!.mainText),
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
                                _webViewProvider.openBrowserPreference(
                                  context: context,
                                  url:
                                      "https://www.torn.com/page.php?sid=stocks",
                                  browserTapType: BrowserTapType.notification,
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
                    backgroundColor: _themeProvider!.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider!.secondBackground,
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

  void changeUID(String uid) {
    _userUID = uid;
  }
}
