// Dart imports:

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

// Package imports:
import 'package:app_links/app_links.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
// Flutter imports:
import 'package:flutter/material.dart' hide Intent;
import 'package:flutter/services.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
import 'package:torn_pda/pages/alerts_windows.dart';
import 'package:torn_pda/pages/awards_page.dart';
import 'package:torn_pda/pages/chaining/ranked_wars_page.dart';
import 'package:torn_pda/pages/chaining_page.dart';
import 'package:torn_pda/pages/friends_page.dart';
import 'package:torn_pda/pages/items_page.dart';
import 'package:torn_pda/pages/loot.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/settings/userscripts_page.dart';
import 'package:torn_pda/pages/settings_page.dart';
import 'package:torn_pda/pages/stakeouts_page.dart';
import 'package:torn_pda/pages/tips_page.dart';
import 'package:torn_pda/pages/travel_page.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/periodic_execution_controller.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/appwidget/appwidget_explanation.dart';
import 'package:torn_pda/utils/appwidget/pda_widget.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/live_activities/live_activity_travel_controller.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/widgets/settings/backup_local/prefs_backup_after_import_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_local/prefs_backup_from_file_dialog.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/drawer/bugs_announcement_dialog.dart';
import 'package:torn_pda/widgets/drawer/memory_widget_drawer.dart';
import 'package:torn_pda/widgets/drawer/stats_announcement_dialog.dart';
import 'package:torn_pda/widgets/drawer/wiki_menu.dart';
import 'package:torn_pda/widgets/tct_clock.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'package:url_launcher/url_launcher.dart';

bool routeWithDrawer = true;
String routeName = "drawer";

class DrawerPage extends StatefulWidget {
  @override
  DrawerPageState createState() => DrawerPageState();
}

class DrawerPageState extends State<DrawerPage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final int _settingsPosition = 12;
  final int _aboutPosition = 13;
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
    "Wiki",
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
  final StakeoutsController _s = Get.find<StakeoutsController>();
  final ApiCallerController _apiController = Get.find<ApiCallerController>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  DateTime? _deepLinkSubTriggeredTime;
  bool _deepLinkInitOnce = false;

  // Used to avoid racing condition with browser launch from notifications (not included in the FutureBuilder), as
  // preferences take time to load
  final Completer _preferencesCompleter = Completer();
  // Used for the main UI loading (FutureBuilder)
  Future? _finishedWithPreferencesAndDialogs;

  int _activeDrawerIndex = 0;
  int _selected = 0;

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
  MethodChannel? platformAndroid = Platform.isAndroid ? const MethodChannel('tornpda.channel') : null;

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
      if (!Platform.isWindows) {
        // STARTS QUICK ACTIONS
        const QuickActions quickActions = QuickActions();

        quickActions.setShortcutItems(<ShortcutItem>[
          // NOTE: keep the same file name for both platforms
          const ShortcutItem(type: 'open_torn', localizedTitle: 'Torn Home', icon: "action_torn"),
          const ShortcutItem(type: 'open_gym', localizedTitle: 'Gym', icon: "action_gym"),
          const ShortcutItem(type: 'open_crimes', localizedTitle: 'Crimes', icon: "action_crimes"),
          const ShortcutItem(type: 'open_travel', localizedTitle: 'Travel', icon: "action_travel"),
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
      }
    });
    // ENDS QUICK ACTIONS

    _allowSectionsWithoutKey = [
      _settingsPosition,
      _aboutPosition,
    ];

    _finishedWithPreferencesAndDialogs = _loadPreferencesAndDialogs();

    // Live Activities
    if (Platform.isIOS) {
      _initialiseLiveActivitiesBridgeService();
    }

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

    if (!Platform.isWindows) {
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
    }

    // Handle notifications
    _getBackgroundNotificationSavedData();
    _removeExistingNotifications();

    // Init intent listener (for appWidget)
    if (Platform.isAndroid) {
      _initIntentListenerSubscription();
      _initIntentReceiverOnLaunch();
    }

    // Remote Config settings
    if (!Platform.isWindows) {
      remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 30),
          minimumFetchInterval: const Duration(minutes: kDebugMode ? 1 : 1440),
        ),
      );

      // Remote Config defaults
      remoteConfig.setDefaults(const {
        "tsc_enabled": true,
        "yata_stats_enabled": true,
        "prefs_backup_enabled": true,
        "tornexchange_enabled": true,
        "use_browser_cache": "user", // user, on, off
        "dynamic_appIcon_enabled": "false",
        "browser_center_editing_text_field_allowed": true,
        // Revives
        "revive_hela": "1 million or 1 Xanax",
        "revive_revive": "1 million or 1 Xanax",
        "revive_nuke": "1 million or 1 Xanax",
        "revive_uhc": "1 million or 1 Xanax",
        "revive_wtf": "1 million or 1 Xanax",
        // Torn API
        "apiV2LegacyRequests": "",
      });

      // Remote Config first fetch and live update
      _preferencesCompleter.future.whenComplete(() async {
        await remoteConfig.fetchAndActivate();
        _settingsProvider.tscEnabledStatusRemoteConfig = remoteConfig.getBool("tsc_enabled");
        _settingsProvider.yataStatsEnabledStatusRemoteConfig = remoteConfig.getBool("yata_stats_enabled");
        _settingsProvider.backupPrefsEnabledStatusRemoteConfig = remoteConfig.getBool("prefs_backup_enabled");
        _settingsProvider.tornExchangeEnabledStatusRemoteConfig = remoteConfig.getBool("tornexchange_enabled");
        _settingsProvider.webviewCacheEnabledRemoteConfig = remoteConfig.getString("use_browser_cache");
        _settingsProvider.dynamicAppIconEnabledRemoteConfig = remoteConfig.getBool("dynamic_appIcon_enabled");
        _settingsProvider.browserCenterEditingTextFieldRemoteConfigAllowed =
            remoteConfig.getBool("browser_center_editing_text_field_allowed");

        // Revives
        _settingsProvider.reviveHelaPrice = remoteConfig.getString("revive_hela");
        _settingsProvider.reviveMidnightPrice = remoteConfig.getString("revive_midnight");
        _settingsProvider.reviveNukePrice = remoteConfig.getString("revive_nuke");
        _settingsProvider.reviveUhcPrice = remoteConfig.getString("revive_uhc");
        _settingsProvider.reviveWtfPrice = remoteConfig.getString("revive_wtf");

        // Sendbird
        final sb = Get.find<SendbirdController>();
        sb.sendBirdPushAndroidRemoteConfigEnabled = remoteConfig.getBool("sendbird_android_notifications_enabled");
        sb.sendBirdPushIOSRemoteConfigEnabled = remoteConfig.getBool("sendbird_ios_notifications_enabled");

        // Torn API
        apiV2LegacyRequests = remoteConfig.getString("apiV2LegacyRequests");

        // Dynamic App Icon depends on Remote Config
        if (Platform.isIOS) {
          _setDynamicAppIcon();
        }

        remoteConfig.onConfigUpdated.listen((event) async {
          await remoteConfig.activate();

          // Ensure all platform channel communications happen on the main thread
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _settingsProvider.tscEnabledStatusRemoteConfig = remoteConfig.getBool("tsc_enabled");
            _settingsProvider.yataStatsEnabledStatusRemoteConfig = remoteConfig.getBool("yata_stats_enabled");
            _settingsProvider.backupPrefsEnabledStatusRemoteConfig = remoteConfig.getBool("prefs_backup_enabled");
            _settingsProvider.tornExchangeEnabledStatusRemoteConfig = remoteConfig.getBool("tornexchange_enabled");
            _settingsProvider.webviewCacheEnabledRemoteConfig = remoteConfig.getString("use_browser_cache");
            _settingsProvider.dynamicAppIconEnabledRemoteConfig = remoteConfig.getBool("dynamic_appIcon_enabled");
            _settingsProvider.browserCenterEditingTextFieldRemoteConfigAllowed =
                remoteConfig.getBool("browser_center_editing_text_field_allowed");
            // Revives
            _settingsProvider.reviveHelaPrice = remoteConfig.getString("revive_hela");
            _settingsProvider.reviveMidnightPrice = remoteConfig.getString("revive_midnight");
            _settingsProvider.reviveNukePrice = remoteConfig.getString("revive_nuke");
            _settingsProvider.reviveUhcPrice = remoteConfig.getString("revive_uhc");
            _settingsProvider.reviveWtfPrice = remoteConfig.getString("revive_wtf");
            // Sendbird
            sb.sendBirdPushAndroidRemoteConfigEnabled = remoteConfig.getBool("sendbird_android_notifications_enabled");
            sb.sendBirdPushIOSRemoteConfigEnabled = remoteConfig.getBool("sendbird_ios_notifications_enabled");
            // Torn API
            apiV2LegacyRequests = remoteConfig.getString("apiV2LegacyRequests");
          });
        });
      });
    }

    // Make sure the Chain Status Provider launch API requests if there's a need (chain or status active) for it
    Get.find<ChainStatusController>().initialiseProvider();

    // Initialise Sendbird notifications
    _preferencesCompleter.future.whenComplete(() async {
      // Sendbird notifications
      final sbController = Get.find<SendbirdController>();
      // After app install, this will trigger an invalid playerId until the user loads the API
      await sbController.register();
    });

    // Should bring browser forward?
    _preferencesCompleter.future.whenComplete(() async {
      final fwd = await Prefs().getBringBrowserForwardOnStart();
      if (fwd) {
        _webViewProvider.browserShowInForeground = true;
        Prefs().setBringBrowserForwardOnStart(false);
      }
    });
  }

  Future<void> _loadPreferencesAndDialogs() async {
    await _loadPreferencesAsync();

    if (mounted) {
      await _handleChangelogAndOtherDialogs();
    }

    // Depending on user preferences, launch the WebView if needed
    await _checkAndLaunchWebViewIfNeeded();
  }

  Future<void> _loadPreferencesAsync() async {
    if (appHasBeenUpdated) {
      // Will trigger an extra upload to Firebase when version changes
      _forceFireUserReload = true;
    }

    // Reconfigure notification channels in case new sounds are added (e.g. v2.4.2)
    // Deletes current channels and create new ones
    if (Platform.isAndroid) {
      final vibration = await Prefs().getVibrationPattern();
      await reconfigureNotificationChannels(mod: vibration);
    }

    await _loadInitPreferences();

    if (!_preferencesCompleter.isCompleted) {
      _preferencesCompleter.complete();
    }

    // Configure high refresh rate based on user preferences
    _preferencesCompleter.future.whenComplete(() async {
      await _configureHighRefreshRate();
    });

    // Force OC2 check when changelog is shown
    // (we also do this once a day with [_updateLastActiveTime])
    // (we shouldn't need to check the completer, as it's checked in initState, but just in case)
    _preferencesCompleter.future.whenComplete(() async {
      _settingsProvider.checkIfUserIsOnOCv2();
    });
  }

  Future<void> _handleChangelogAndOtherDialogs() async {
    try {
      if (appHasBeenUpdated || lastSavedAppCompilation.isEmpty) {
        await _showChangeLogDialog(context);
      } else {
        // Other dialogs we need to show when the dialog is not being displayed
        bool dialogWasShown = false;

        // Appwidget dialog
        if (Platform.isAndroid) {
          if (!await Prefs().getAppwidgetExplanationShown()) {
            if ((await pdaWidget_numberInstalled()).isNotEmpty) {
              if (mounted) {
                await _showAppwidgetExplanationDialog(context);
              }
              Prefs().setAppwidgetExplanationShown(true);
              dialogWasShown = true;
            }
          }
        }

        // Stats Announcement dialog
        if (mounted && !dialogWasShown) {
          bool statsShown = await _showAppStatsAnnouncementDialog();
          if (mounted && !statsShown) {
            await _showBugsAnnouncementDialog();
          }
        }

        // Other dialogs
        //...
      }
    } catch (e, s) {
      log('Error showing initial dialogs: $e', error: e, stackTrace: s);
    }
  }

  Future<void> _checkAndLaunchWebViewIfNeeded() async {
    if (!_userProvider!.basic!.userApiKeyValid!) return;

    String defaultSection = await Prefs().getDefaultSection();
    if (defaultSection == "browser" || defaultSection == "browser_full") {
      _webViewProvider.browserShowInForeground = true;

      if (defaultSection == "browser_full") {
        _webViewProvider.setCurrentUiMode(UiMode.fullScreen, context);
      }
    }
  }

  void _setDynamicAppIcon() {
    // Dynamic app icon
    _preferencesCompleter.future.whenComplete(() async {
      _settingsProvider.appIconChangeBasedOnCondition();
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
            statusBarBrightness: _webViewProvider.browserShowInForeground
                ? Brightness.dark
                : MediaQuery.orientationOf(context) == Orientation.landscape
                    ? _themeProvider!.currentTheme == AppTheme.light
                        ? Brightness.light
                        : Brightness.dark
                    : Brightness.dark),
      );
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // For Windows, just execute what's needed and return (other tasks are not compatible or make no sense)
    if (Platform.isWindows) {
      if (state == AppLifecycleState.resumed) {
        checkForScriptUpdates();
        _syncThemeWithDeviceSettings();
        Get.find<PeriodicExecutionController>().checkAndExecuteTasks();
      }
      return;
    }

    if (state == AppLifecycleState.paused) {
      // Stop stakeouts
      _s.stopTimer();
      log("Stakeouts stopped");

      // Stop stats counting
      _statsController.logCheckOut();

      // Refresh widget to have up to date info when we exit
      if ((await getInstalledHomeWidgets()).isNotEmpty) {
        startBackgroundRefresh();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Update Firebase active parameter
      _updateLastActiveTime();

      // Execute periodic tasks
      Get.find<PeriodicExecutionController>().checkAndExecuteTasks();

      // Handle notifications
      _getBackgroundNotificationSavedData();
      _removeExistingNotifications();

      // Resume stakeouts
      _s.startTimer();
      log("Stakeouts resumed");

      // Resume stats counting
      _statsController.logCheckIn();

      // App widget - reset background updater
      syncBackgroundRefreshWithWidgetInstallation();

      checkForScriptUpdates();

      _syncThemeWithDeviceSettings();
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
    } else if (intent.data!.contains("pdaWidget://hospital:status:icon:clicked")) {
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
      browserUrl = "https://www.torn.com/item.php#drugs-items";
      if (_settingsProvider.appwidgetCooldownTapOpenBrowserDestination == "faction") {
        browserUrl = "https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=drugs";
      }
    } else if (intent.data!.contains("pdaWidget://medical:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#medical-items";
      if (_settingsProvider.appwidgetCooldownTapOpenBrowserDestination == "faction") {
        browserUrl = "https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=medical";
      }
    } else if (intent.data!.contains("pdaWidget://booster:clicked")) {
      launchBrowser = true;
      browserUrl = "https://www.torn.com/item.php#boosters-items";
      if (_settingsProvider.appwidgetCooldownTapOpenBrowserDestination == "faction") {
        browserUrl = "https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=boosters";
      }
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
      final appLink = await _appLinks.getInitialLink();
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
    if (((link ?? "").contains("file://") || (link ?? "").contains("content://"))) {
      try {
        final uri = Uri.parse(link!);
        if (Platform.isIOS) {
          final bytes = await File(uri.toFilePath()).readAsBytes();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => PreferencesImportDialog(bytes: bytes),
          );
          return;
        } else if (Platform.isAndroid) {
          final file = await toFile(uri.toString());
          final bytes = await file.readAsBytes();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => PreferencesImportDialog(bytes: bytes),
          );
          return;
        }
      } catch (e) {
        log("Error reading file: $e");
      }
    }

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
        if (_deepLinkSubTriggeredTime != null && DateTime.now().difference(_deepLinkSubTriggeredTime!).inSeconds < 3) {
          logToUser(
              "Deep link triggered return\n\n "
              "${DateTime.now().difference(_deepLinkSubTriggeredTime!).inSeconds} seconds",
              duration: 3);
          return;
        }
        _deepLinkSubTriggeredTime = DateTime.now();
        _preferencesCompleter.future.whenComplete(() async {
          logToUser(
            "Deep link browser opens\n\n$url",
            duration: 3,
            backgroundcolor: Colors.blue.shade600,
            borderColor: Colors.blue.shade800,
          );

          _webViewProvider.openBrowserPreference(
            context: context,
            url: url,
            browserTapType: BrowserTapType.deeplink,
          );
        });
      }
    } catch (e) {
      logToUser("Deep link catch\n\n$e", duration: 4);
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
        if (Platform.isAndroid && _settingsProvider.removeNotificationsOnLaunch) {
          // Gets the active (already shown) notifications
          final List<ActiveNotification> activeNotifications = (await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.getActiveNotifications())!;

          for (final not in activeNotifications) {
            if (not.id == null) continue;
            // Platform channel to cancel direct Firebase notifications (we can call
            // "cancelAll()" there without affecting scheduled notifications, which is
            // a problem with the local plugin)
            if (not.id == 0) {
              await platformAndroid!.invokeMethod('cancelNotifications');
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
    // Get the save alerts
    Prefs().getDataStockMarket().then((stocks) {
      if (stocks.isNotEmpty) {
        Prefs().setDataStockMarket("");
        Future.delayed(const Duration(seconds: 1)).then((value) => _openBackgroundStockDialog(stocks));
      }
    });
  }

  Future<void> _onFirebaseBackgroundNotification(Map<String, dynamic> message) async {
    // Important: await preferences in case we need to use settings providers
    await _preferencesCompleter.future;

    // Opens new tab in broser
    bool launchBrowserWithUrl = false;
    var browserUrl = "https://www.torn.com";

    // Shows browser but does not change URL
    bool showBrowserForeground = false;

    bool travel = false;
    bool hospital = false;
    bool restocks = false;
    bool racing = false;
    bool messages = false;
    bool events = false;
    bool trades = false;
    bool nerve = false;
    bool life = false;
    bool energy = false;
    bool drugs = false;
    bool medical = false;
    bool booster = false;
    bool refills = false;
    bool stockMarket = false;
    bool assists = false;
    bool loot = false;
    bool retals = false;
    bool sendbird = false;
    bool forums = false;

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
    } else if (channel.contains("Alerts life")) {
      life = true;
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
    } else if (channel.contains("Torn chat")) {
      sendbird = true;
    } else if (channel.contains("Alerts forums")) {
      forums = true;
    }

    if (travel) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com";
    } else if (hospital) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com";
    } else if (restocks) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/travelagency.php";
    } else if (racing) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/loader.php?sid=racing";
    } else if (messages) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/messages.php";
      if (messageId != "") {
        browserUrl = "https://www.torn.com/messages.php#/p=read&ID="
            "$messageId&suffix=inbox";
      }
    } else if (events) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/events.php#/step=all";
    } else if (trades) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/trade.php";
      if (tradeId != "") {
        browserUrl = "https://www.torn.com/trade.php#step=view&ID="
            "$tradeId";
      }
    } else if (nerve) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/crimes.php";
    } else if (life) {
      if (_settingsProvider.lifeNotificationTapAction == "itemsOwn") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/item.php#medical-items';
      } else if (_settingsProvider.lifeNotificationTapAction == "itemsFaction") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=medical';
      } else if (_settingsProvider.lifeNotificationTapAction == "factionMain") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/factions.php';
      }
    } else if (energy) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/gym.php";
    } else if (drugs) {
      if (_settingsProvider.drugsNotificationTapAction == "itemsOwn") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/item.php#drugs-items';
      } else if (_settingsProvider.drugsNotificationTapAction == "itemsFaction") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=drugs';
      }
    } else if (medical) {
      if (_settingsProvider.medicalNotificationTapAction == "itemsOwn") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/item.php#medical-items';
      } else if (_settingsProvider.medicalNotificationTapAction == "itemsFaction") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=medical';
      }
    } else if (booster) {
      if (_settingsProvider.boosterNotificationTapAction == "itemsOwn") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/item.php#boosters-items';
      } else if (_settingsProvider.boosterNotificationTapAction == "itemsFaction") {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=boosters';
      }
    } else if (refills) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/points.php";
    } else if (retals) {
      if (int.parse(bulkDetails!) == -1) {
        // No-host notification
        return;
      }
      // If we have the section manually deactivated
      // Or everything is OK but we elected to open the browser with just 1 target
      // >> Open browser

      if (!_settingsProvider.retaliationSectionEnabled ||
          (int.parse(bulkDetails) == 1 && _settingsProvider.singleRetaliationOpensBrowser)) {
        launchBrowserWithUrl = true;
        browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
      } else {
        // Even if we meet above requirements, call the API and assess whether the user
        // as API permits (if he does not, open the browser anyway as he can't use the retals section)
        final attacksResult = await ApiCallsV1.getFactionAttacks();
        if (attacksResult is! FactionAttacksModel) {
          launchBrowserWithUrl = true;
          browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
        } else {
          // If we pass all checks above, redirect to the retals section
          _retalsRedirection = true;
          _callSectionFromOutside(2);
          Future.delayed(const Duration(seconds: 2)).then((_) {
            if (mounted) {
              _retalsRedirection = false;
            }
          });
        }
      }
    } else if (stockMarket) {
      // Not implemented (there is a box showing in _getBackGroundNotifications)
    } else if (assists) {
      launchBrowserWithUrl = true;
      browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";

      Color? totalColor = Colors.grey[700];
      try {
        if (bulkDetails!.isNotEmpty) {
          final bulkList = bulkDetails.split("#");
          int? otherXanax = int.tryParse(bulkList[0].split("xanax:")[1]);
          int? otherRefills = int.tryParse(bulkList[1].split("refills:")[1]);
          int? otherDrinks = int.tryParse(bulkList[2].split("drinks:")[1]);

          final own = await ApiCallsV1.getOwnPersonalStats();
          if (own is OwnPersonalStatsModel) {
            final int xanaxComparison = otherXanax! - own.personalstats!.xantaken!;
            final int refillsComparison = otherRefills! - own.personalstats!.refills!;
            final int drinksComparison = otherDrinks! - own.personalstats!.energydrinkused!;

            final int otherTotals = otherXanax + otherRefills + otherDrinks;
            final int myTotals =
                own.personalstats!.xantaken! + own.personalstats!.refills! + own.personalstats!.energydrinkused!;

            if (otherTotals < myTotals - myTotals * 0.1) {
              totalColor = Colors.green[700];
            } else if (otherTotals >= myTotals - myTotals * 0.1 && otherTotals <= myTotals + myTotals * 0.1) {
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
              refillsString = "\n- Refills (E): ${refillsComparison.abs()} LESS than you";
            } else if (refillsComparison == 0) {
              refillsString = "\n- Refills (E): SAME as you";
            } else {
              refillsString = "\n- Refills (E): ${refillsComparison.abs()} MORE than you";
            }

            String drinksString = "";
            if (drinksComparison < 0) {
              drinksString = "\n- Drinks (E): ${drinksComparison.abs()} LESS than you";
            } else if (drinksComparison == 0) {
              drinksString = "\n- Drinks (E): SAME as you";
            } else {
              drinksString = "\n- Drinks (E): ${drinksComparison.abs()} MORE than you";
            }

            if (xanaxString.isNotEmpty && refillsString.isNotEmpty && drinksString.isNotEmpty) {
              message["body"] = message["body"].replaceAll("(tap to get a comparison with you)", "");
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
        launchBrowserWithUrl = true;
        browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
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
          browserTapType: BrowserTapType.chainShort,
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
    } else if (sendbird) {
      showBrowserForeground = true;
    } else if (forums) {
      if (bulkDetails != null && bulkDetails.isNotEmpty) {
        launchBrowserWithUrl = true;
        browserUrl = bulkDetails;
      }
    }

    if (launchBrowserWithUrl) {
      _preferencesCompleter.future.whenComplete(() async {
        _webViewProvider.openBrowserPreference(
          context: context,
          url: browserUrl,
          browserTapType: BrowserTapType.notification,
        );
      });
    } else if (showBrowserForeground) {
      _preferencesCompleter.future.whenComplete(() async {
        _webViewProvider.browserShowInForeground = true;
      });
    }
  }

  // Fires if notification from local_notifications package is tapped (i.e.:
  // when the app is open). Also for manual notifications when app is open.
  Future<void> _onForegroundNotification() async {
    selectNotificationStream.stream.listen((String? payload) async {
      if (payload == null) return;

      // Opens new tab in broser
      bool launchBrowserWithUrl = false;
      var browserUrl = "https://www.torn.com";

      // Shows browser but does not change URL
      bool showBrowserForeground = false;

      // ##-88-## comes in the payload for browser notifications (triggered from user scripts)
      // We put them first to ensure they are not overridden by other conditions
      if (payload.contains("##-88-##")) {
        final parts = payload.split("##-88-##");
        if (parts[1].isNotEmpty) {
          final String urlPart = parts[1];
          final uri = Uri.tryParse(urlPart);
          if (uri == null || !uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
            launchBrowserWithUrl = false;
          } else {
            final validatedUrl = (uri.scheme == 'http') ? uri.replace(scheme: 'https').toString() : urlPart;
            browserUrl = validatedUrl;
            launchBrowserWithUrl = true;
          }
        }
      } else if (payload == 'travel') {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com';
      } else if (payload == 'restocks') {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/travelagency.php';
      } else if (payload.contains('energy')) {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/gym.php';
      } else if (payload.contains('nerve')) {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/crimes.php';
      } else if (payload.contains('life')) {
        if (_settingsProvider.lifeNotificationTapAction == "itemsOwn") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/item.php#medical-items';
        } else if (_settingsProvider.lifeNotificationTapAction == "itemsFaction") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=medical';
        } else if (_settingsProvider.lifeNotificationTapAction == "factionMain") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/factions.php';
        }
      } else if (payload.contains('drugs')) {
        if (_settingsProvider.drugsNotificationTapAction == "itemsOwn") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/item.php#drugs-items';
        } else if (_settingsProvider.drugsNotificationTapAction == "itemsFaction") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=drugs';
        }
      } else if (payload.contains('medical')) {
        if (_settingsProvider.medicalNotificationTapAction == "itemsOwn") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/item.php#medical-items';
        } else if (_settingsProvider.medicalNotificationTapAction == "itemsFaction") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=medical';
        }
      } else if (payload.contains('booster')) {
        if (_settingsProvider.boosterNotificationTapAction == "itemsOwn") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/item.php#boosters-items';
        } else if (_settingsProvider.boosterNotificationTapAction == "itemsFaction") {
          launchBrowserWithUrl = true;
          browserUrl = 'https://www.torn.com/factions.php?step=your&type=1#/tab=armoury&start=0&sub=boosters';
        }
      } else if (payload.contains('hospital')) {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com';
      } else if (payload.contains('racing') || payload.contains('race')) {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/loader.php?sid=racing';
      } else if (payload.contains("scriptupdate")) {
        setState(() {
          _webViewProvider.browserShowInForeground = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => const UserScriptsPage(),
          ),
        );
      } else if (payload.contains('400-')) {
        launchBrowserWithUrl = true;
        final npcId = payload.split('-')[1];
        browserUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
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
          url: "https://www.torn.com/loader.php?sid=attack&user2ID=${lootRangersNpcsIds[0]}",
          browserTapType: BrowserTapType.chainShort,
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

        browserUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=$lootRangersNpcsIds';
      } else if (payload.contains('tornMessageId:')) {
        launchBrowserWithUrl = true;
        final messageId = payload.split(':');
        browserUrl = "https://www.torn.com/messages.php";
        if (messageId[1] != "0") {
          browserUrl = "https://www.torn.com/messages.php#/p=read&ID="
              "${messageId[1]}&suffix=inbox";
        }
      } else if (payload.contains('events')) {
        launchBrowserWithUrl = true;
        browserUrl = "https://www.torn.com/events.php#/step=all";
      } else if (payload.contains('tornTradeId:')) {
        launchBrowserWithUrl = true;
        final tradeId = payload.split(':');
        browserUrl = "https://www.torn.com/trade.php";
        if (tradeId[1] != "0") {
          browserUrl = "https://www.torn.com/trade.php#step=view&ID=${tradeId[1]}";
        }
      } else if (payload.contains('211')) {
        launchBrowserWithUrl = true;
        browserUrl = 'https://www.torn.com/travelagency.php';
      } else if (payload.contains('refills') && (!payload.contains("Xanax"))) {
        launchBrowserWithUrl = true;
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
            (int.parse(bulkDetails) == 1 && _settingsProvider.singleRetaliationOpensBrowser)) {
          launchBrowserWithUrl = true;
          browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
        } else {
          // Even if we meet above requirements, call the API and assess whether the user
          // as API permits (if he does not, open the browser anyway as he can't use the retals section)
          final attacksResult = await ApiCallsV1.getFactionAttacks();
          if (attacksResult is! FactionAttacksModel) {
            launchBrowserWithUrl = true;
            browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
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
        launchBrowserWithUrl = true;
        final assistSplit = payload.split('###');
        final assistId = assistSplit[0].split(':');
        final assistBody = assistSplit[1].split('assistDetails:');
        final bulkDetails = assistSplit[2].split('bulkDetails:');
        browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=${assistId[1]}";

        Color? totalColor = Colors.grey[700];
        try {
          if (bulkDetails[1].isNotEmpty) {
            final bulkList = bulkDetails[1].split("#");
            int? otherXanax = int.tryParse(bulkList[0].split("xanax:")[1]);
            int? otherRefills = int.tryParse(bulkList[1].split("refills:")[1]);
            int? otherDrinks = int.tryParse(bulkList[2].split("drinks:")[1]);

            final own = await ApiCallsV1.getOwnPersonalStats();
            if (own is OwnPersonalStatsModel) {
              final int xanaxComparison = otherXanax! - own.personalstats!.xantaken!;
              final int refillsComparison = otherRefills! - own.personalstats!.refills!;
              final int drinksComparison = otherDrinks! - own.personalstats!.energydrinkused!;

              final int otherTotals = otherXanax + otherRefills + otherDrinks;
              final int myTotals =
                  own.personalstats!.xantaken! + own.personalstats!.refills! + own.personalstats!.energydrinkused!;

              if (otherTotals < myTotals - myTotals * 0.1) {
                totalColor = Colors.green[700];
              } else if (otherTotals >= myTotals - myTotals * 0.1 && otherTotals <= myTotals + myTotals * 0.1) {
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
                refillsString = "\n- Refills (E): ${refillsComparison.abs()} LESS than you";
              } else if (refillsComparison == 0) {
                refillsString = "\n- Refills (E): SAME as you";
              } else {
                refillsString = "\n- Refills (E): ${refillsComparison.abs()} MORE than you";
              }

              String drinksString = "";
              if (drinksComparison < 0) {
                drinksString = "\n- Drinks (E): ${drinksComparison.abs()} LESS than you";
              } else if (drinksComparison == 0) {
                drinksString = "\n- Drinks (E): SAME as you";
              } else {
                drinksString = "\n- Drinks (E): ${drinksComparison.abs()} MORE than you";
              }

              if (xanaxString.isNotEmpty && refillsString.isNotEmpty && drinksString.isNotEmpty) {
                assistBody[1] = assistBody[1].replaceAll("(tap to get a comparison with you)", "");
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
          launchBrowserWithUrl = true;
          browserUrl = "https://www.torn.com/loader.php?sid=attack&user2ID=$assistId";
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
            browserTapType: BrowserTapType.chainShort,
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
      } else if (payload.contains('sendbird')) {
        showBrowserForeground = true;
      } else if (payload == 'forums###') {
        launchBrowserWithUrl = true;
        browserUrl = payload.split('###')[1];
      }

      if (launchBrowserWithUrl) {
        _preferencesCompleter.future.whenComplete(() async {
          _webViewProvider.openBrowserPreference(
            context: context,
            url: browserUrl,
            browserTapType: BrowserTapType.notification,
          );
        });
      } else if (showBrowserForeground) {
        _preferencesCompleter.future.whenComplete(() async {
          _webViewProvider.browserShowInForeground = true;
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
          browserTapType: BrowserTapType.chainShort,
          url: url,
        );
      case BrowserSetting.external:
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
    }
  }

  bool changelog = false;
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
      future: _finishedWithPreferencesAndDialogs,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // This container is needed in all pages for certain devices with appbar at the bottom, otherwise the
          // safe area will be black
          return Container(
            color: _themeProvider!.currentTheme == AppTheme.light
                ? MediaQuery.orientationOf(context) == Orientation.portrait
                    ? Colors.blueGrey
                    : isStatusBarShown
                        ? _themeProvider!.statusBar
                        : _themeProvider!.canvas
                : _themeProvider!.statusBar,
            child: SafeArea(
              right: _webViewProvider.webViewSplitActive &&
                  _webViewProvider.splitScreenPosition == WebViewSplitPosition.left,
              left: _webViewProvider.webViewSplitActive &&
                  _webViewProvider.splitScreenPosition == WebViewSplitPosition.right,
              child: Scaffold(
                key: _scaffoldKey,
                body: _getPages(),
                endDrawer: _webViewProvider.webViewSplitActive &&
                        _webViewProvider.splitScreenPosition == WebViewSplitPosition.left
                    ? Drawer(
                        backgroundColor: _themeProvider!.canvas,
                        surfaceTintColor: _themeProvider!.currentTheme == AppTheme.extraDark ? Colors.black : null,
                        elevation: 2, // This avoids shadow over SafeArea
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: <Widget>[
                            _getDrawerHeader(),
                            Consumer<SettingsProvider>(builder: (context, settingsProvider, child) {
                              return _getDrawerItems(settingsProvider);
                            }),
                          ],
                        ),
                      )
                    : null,
                drawer: _webViewProvider.webViewSplitActive &&
                        _webViewProvider.splitScreenPosition == WebViewSplitPosition.left
                    ? null
                    : Drawer(
                        backgroundColor: _themeProvider!.canvas,
                        surfaceTintColor: _themeProvider!.currentTheme == AppTheme.extraDark ? Colors.black : null,
                        elevation: 2, // This avoids shadow over SafeArea
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: <Widget>[
                            _getDrawerHeader(),
                            Consumer<SettingsProvider>(builder: (context, settingsProvider, child) {
                              return _getDrawerItems(settingsProvider);
                            }),
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
    final showMemory = context.watch<SettingsProvider>().showMemoryInDrawer;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final baseHeight = isPortrait ? 280.0 : 250.0;
    return SizedBox(
      height: baseHeight + (showMemory ? 80.0 : 0.0),
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
                          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                            final int callCount = snapshot.data ?? 0;
                            final double progress = math.min(callCount / 100, 1.0);
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
                                  _themeProvider!.currentTheme == AppTheme.light ? Colors.grey[400] : Colors.grey[800],
                              progressColor: callCount >= 95 ? Colors.red[400] : Colors.green,
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, top: 1),
                              child: Text(
                                "API CALLS (60s)",
                                style: TextStyle(fontSize: 9),
                              ),
                            ),
                            if (_apiController.delayCalls)
                              StreamBuilder<Map<String, dynamic>>(
                                stream: _apiController.queueStatsStream,
                                initialData: {'queueLength': 0, 'avgTime': 0},
                                builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                                  final int queueLength = snapshot.data?['queueLength'] ?? 0;
                                  final double avgTime = snapshot.data?['avgTime'].toDouble() ?? 0;
                                  return Text(
                                    "QUEUE: $queueLength${queueLength > 0 ? ' (delay ${avgTime.ceil()} sec)' : ''}",
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: queueLength == 0 ? _themeProvider!.mainText : Colors.red,
                                        fontWeight: queueLength == 0 ? FontWeight.normal : FontWeight.bold),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            showMemory
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: MemoryBarWidgetDrawer(),
                  )
                : const SizedBox.shrink(),
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
                              _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
                          initialLabelIndex: _themeProvider!.currentTheme == AppTheme.light
                              ? 0
                              : _themeProvider!.currentTheme == AppTheme.dark
                                  ? 1
                                  : 2,
                          activeBgColor: _themeProvider!.currentTheme == AppTheme.light
                              ? [Colors.blueGrey]
                              : _themeProvider!.currentTheme == AppTheme.dark
                                  ? [Colors.blueGrey]
                                  : [Colors.blueGrey[900]!],
                          activeFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
                          inactiveBgColor: _themeProvider!.currentTheme == AppTheme.light
                              ? Colors.white
                              : _themeProvider!.currentTheme == AppTheme.dark
                                  ? Colors.grey[800]
                                  : Colors.black,
                          inactiveFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
                          totalSwitches: 3,
                          animate: true,
                          animationDuration: 500,
                          icons: [
                            FontAwesome.sun_o,
                            FontAwesome.moon_o,
                            MdiIcons.ghost,
                          ],
                          onToggle: (index) {
                            bool syncToast = false;
                            if (_settingsProvider.syncDeviceTheme) {
                              final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
                              if (brightness == Brightness.dark && index == 0 ||
                                  brightness == Brightness.light && index == 1 ||
                                  brightness == Brightness.light && index == 2) {
                                syncToast = true;
                                BotToast.showText(
                                  clickClose: true,
                                  text: "Automatic sync with your device theme is enabled: bear in mind that your "
                                      "current theme selection might be reverted!",
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.orange[800]!,
                                  duration: const Duration(seconds: 6),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                              }
                            }

                            if (index == 0) {
                              _themeProvider!.changeTheme = AppTheme.light;
                              if (_settingsProvider.syncTornWebTheme) {
                                _webViewProvider.changeTornTheme(dark: false);
                              }
                            } else if (index == 1) {
                              _themeProvider!.changeTheme = AppTheme.dark;
                              if (_settingsProvider.syncTornWebTheme) {
                                _webViewProvider.changeTornTheme(dark: true);
                              }
                            } else {
                              _themeProvider!.changeTheme = AppTheme.extraDark;
                              if (_settingsProvider.syncTornWebTheme) {
                                _webViewProvider.changeTornTheme(dark: true);
                              }
                              if (!syncToast) {
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
                            }
                            setState(() {
                              SystemChrome.setSystemUIOverlayStyle(
                                SystemUiOverlayStyle(
                                  statusBarColor: _themeProvider!.statusBar,
                                  systemNavigationBarColor: _themeProvider!.statusBar,
                                  systemNavigationBarIconBrightness: Brightness.light,
                                  statusBarIconBrightness: Brightness.light,
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  TctClock(
                    color: _themeProvider!.mainText,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getDrawerItems(SettingsProvider settingsProvider) {
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
        if (settingsProvider.disableTravelSection && _drawerItemsList[i] == "Travel") {
          continue;
        }

        if (!settingsProvider.rankedWarsInMenu && _drawerItemsList[i] == "Ranked Wars") {
          continue;
        }

        if (_drawerItemsList[i] == "Wiki") {
          if (settingsProvider.showWikiInDrawer) {
            drawerOptions.add(WikiMenu(themeProvider: _themeProvider!));
          } else {
            drawerOptions.add(const SizedBox.shrink());
          }

          continue;
        }

        if (!Platform.isWindows) {
          if (!settingsProvider.stockExchangeInMenu && _drawerItemsList[i] == "Stock Market") {
            continue;
          }
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
        return StockMarketAlertsPage(calledFromMenu: true, stockMarketInMenuCallback: _onChangeStockMarketInMenu);
      case 10:
        return Column(
          children: [
            WikiMenu(themeProvider: _themeProvider!),
          ],
        );
      case 11:
        if (Platform.isWindows) return AlertsSettingsWindows();
        return AlertsSettings(_onChangeStockMarketInMenu);
      case 12:
        return SettingsPage(
          changeUID: changeUID,
          statsController: _statsController,
        );
      case 13:
        return AboutPage(uid: _userUID);
      case 14:
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
      // Case 10 is Wiki, which is a widget with its own icon
      case 11:
        return const Icon(Icons.notifications_active);
      case 12:
        return const Icon(Icons.settings);
      case 13:
        return const Icon(Icons.info_outline);
      case 14:
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

  Future _loadInitPreferences() async {
    // Set up SettingsProvider so that user preferences are applied
    // ## Leave this first as other options below need this to be initialized ##
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await _settingsProvider.loadPreferences();

    // Set up UserScriptsProvider so that user preferences are applied
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
    await _userScriptsProvider.loadPreferencesAndScripts();

    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    // Join a stream which will receive a callback from main if applicable whenever the back button is pressed
    _willPopShouldOpenDrawer = _settingsProvider.willPopShouldOpenDrawerStream.stream;
    _willPopSubscription = _willPopShouldOpenDrawer.listen((event) {
      _openDrawer();
    });

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

      // If user wants to load the browser, change the default section to Profile
      if (defaultSection == "browser" || defaultSection == "browser_full") {
        defaultSection = "0"; // Cambiar a Profile como base
      }

      _selected = int.parse(defaultSection);
      _activeDrawerIndex = int.parse(defaultSection);

      await _initializeAndHandleFirebaseAuth();

      // Update last used time in Firebase when the app opens (we'll do the same in onResumed,
      // since some people might leave the app opened for weeks in the background)
      // Completer to ensure that we have a valid UID and avoid any race condition!!
      if (!Platform.isWindows) {
        FirestoreHelper().uidCompleter.future.whenComplete(() {
          _updateLastActiveTime();
        });
      }

      checkForScriptUpdates();
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

  Future<void> _initializeAndHandleFirebaseAuth() async {
    if (Platform.isWindows || _drawerUserChecked) {
      return;
    }

    // NOTE: we have already checked this before, but it's important!
    // (so be leave this as a reminder)
    if (_userProvider?.basic?.userApiKeyValid != true) return;

    // Case 1: Post-import user creation
    if (justImportedFromLocalBackup) {
      if (FirebaseAuth.instance.currentUser == null) {
        log(
          "Drawer: Post-import check. Firebase user is null, proceeding with new anonymous sign-in.",
          name: "Drawer AUTH",
        );

        try {
          final User newAnonUser = await (firebaseAuth.signInAnon());
          _userUID = newAnonUser.uid;
          FirestoreHelper().setUID(_userUID);
          await _updateFirebaseDetails();

          // This dialog can be shown here with no postframe callback as it is inside
          // of the Preferences Completer, so the main FutureBuilder hasn't loaded
          await showDialog(
            useRootNavigator: false,
            context: context,
            barrierDismissible: false,
            builder: (context) => const PrefsLocalAfterImportDialog(),
          );

          log(
            "Drawer: Firebase user created successfully after local import. UID: ${newAnonUser.uid}",
            name: "Drawer AUTH",
          );
        } catch (e, s) {
          log(
            "Drawer: CRITICAL - Failed to sign-in anonymously after local backup import. Error: $e",
            name: "Drawer AUTH",
          );

          await FirebaseCrashlytics.instance.recordError(e, s, reason: 'Auth Restoration: Post-import sign-in failed');
          BotToast.showText(
            clickClose: true,
            text: "A critical error occurred while creating your profile after the import.\n\n"
                "Please check your internet connection, restart the app, and reload your API key in Settings.",
            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
            contentColor: Colors.red,
            duration: const Duration(seconds: 10),
            contentPadding: const EdgeInsets.all(10),
          );
        }
      } else {
        log(
          "Drawer: WARNING - justImportedFromLocalBackup is true, but a Firebase user already exists. UID: ${FirebaseAuth.instance.currentUser!.uid}",
          name: "Drawer AUTH",
        );
        _userUID = FirebaseAuth.instance.currentUser!.uid;
        FirestoreHelper().setUID(_userUID);
      }
      justImportedFromLocalBackup = false;
      _drawerUserChecked = true;
      return;
    }

    // Case 2: Standard app launch
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      log(
        "Drawer: Session restored immediately. UID: ${user.uid}",
        name: "Drawer AUTH",
      );

      _userUID = user.uid;
      FirestoreHelper().setUID(_userUID);
      _drawerUserChecked = true;
      return;
    }

    log(
      "Drawer: No user found. Listening to authStateChanges...",
      name: "Drawer AUTH",
    );

    final stopwatch = Stopwatch()..start();
    Timer? waitingMessageTimer;

    try {
      waitingMessageTimer = Timer(const Duration(seconds: 2), () {
        BotToast.showText(
          clickClose: true,
          text: "Authentication with Firebase is taking longer than expected.\n\n"
              "Please wait, Torn PDA will try for another 15 seconds.",
          textStyle: const TextStyle(fontSize: 14, color: Colors.white),
          contentColor: Colors.orange,
          duration: const Duration(seconds: 15),
          contentPadding: const EdgeInsets.all(10),
        );
      });

      user = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 20));

      log(
        "Drawer: Session restored via authStateChanges listener after ${stopwatch.elapsedMilliseconds}ms. UID: ${user!.uid}",
        name: "Drawer AUTH",
      );

      await FirebaseCrashlytics.instance.recordError(
        Exception('Auth Restoration: Slow path success'),
        null,
        reason: 'Auth Restoration: Slow path success',
        information: ['Restoration time: ${stopwatch.elapsedMilliseconds} ms', 'Final UID: ${user.uid}'],
        fatal: false,
      );

      _userUID = user.uid;
      FirestoreHelper().setUID(_userUID);
    } on TimeoutException {
      log(
        "Drawer: Timeout reached after 20 seconds. Firebase session not restored. Informing user.",
        name: "Drawer AUTH",
      );

      final String fullApiKey = _userProvider?.basic?.userApiKey ?? 'API Key not available';

      await FirebaseCrashlytics.instance.recordError(
        Exception('Auth Restoration: Timeout after 20 seconds'),
        StackTrace.current,
        reason: 'Auth Restoration: Timeout',
        information: ['Torn API Key: $fullApiKey'], // Sending full key
        fatal: true,
      );

      BotToast.showText(
        clickClose: true,
        text: "A problem was found with your Firebase user.\n\n"
            "Please reload your API key in Settings, then kill and restart the app.",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.red,
        duration: const Duration(seconds: 8),
        contentPadding: const EdgeInsets.all(10),
      );
    } catch (e, s) {
      log(
        "Drawer: An unexpected error occurred while awaiting authStateChanges: $e",
        name: "Drawer AUTH",
      );

      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Auth Restoration: Unexpected error',
        fatal: true,
      );
    } finally {
      waitingMessageTimer?.cancel();
      stopwatch.stop();
    }

    _drawerUserChecked = true;
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

      // If the recorded check is over 2 days, upload it to FirestoreHelper(). 2 days allow for several
      // retries, even if Firebase makes inactive at 7 days (2 days here + 5 advertised)
      // Also update full user in case something is missing!
      if (duration.inDays > 2 || _forceFireUserReload) {
        await _updateFirebaseDetails();
        // This is triggered to true if the changelog activates.
        _forceFireUserReload = false;
      }

      if (duration.inDays > 1 || kDebugMode) {
        _settingsProvider.checkIfUserIsOnOCv2();
      }
    });
  }

  Future<void> _updateFirebaseDetails() async {
    // We save the key because the API call will reset it
    // Then get user's profile and update
    final savedKey = _userProvider!.basic!.userApiKey;
    final dynamic prof = await ApiCallsV1.getOwnProfileBasic();
    if (prof is OwnProfileBasic) {
      // Update profile with the two fields it does not contain
      prof
        ..userApiKey = savedKey
        ..userApiKeyValid = true;

      await FirestoreHelper().uploadUsersProfileDetail(prof, userTriggered: true);
    }

    // Uploads last active time to Firebase
    final now = DateTime.now().millisecondsSinceEpoch;
    final success = await FirestoreHelper().uploadLastActiveTimeAndTokensToFirebase(now);
    if (success) {
      _settingsProvider.updateLastUsed = now;
    }
  }

  Future<void> _showChangeLogDialog(BuildContext context) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const ChangeLog();
      },
    );
  }

  Future<void> _showAppwidgetExplanationDialog(BuildContext context) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AppwidgetExplanationDialog();
      },
    );
  }

  Future<bool> _showAppStatsAnnouncementDialog() async {
    // Version hardcoded - only allow users with version 0
    if ((await Prefs().getAppStatsAnnouncementDialogVersion()) <= 0) {
      // For version 1, user needs to have 24 hours of app use
      final int savedSeconds = await Prefs().getStatsCumulatedAppUseSeconds();
      if (savedSeconds < 86400) return false;

      // If we are still in an old dialog version, get DB to see if we can are free to show it
      try {
        int? databaseDialogAllowed =
            (await FirebaseDatabase.instance.ref().child("announcement/version").once()).snapshot.value as int?;
        if (databaseDialogAllowed == 1) {
          // If we are allowed to proceed, show the dialog
          await showDialog(
            useRootNavigator: false,
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return StatsAnnouncementDialog(themeProvider: _themeProvider);
            },
          );

          // Then update the version to the current one
          Prefs().setAppStatsAnnouncementDialogVersion(1);
          return true; // Do not show more dialogs below
        }
      } catch (e) {
        log("Error while checking if stats announcement dialog is allowed: $e");
      }
    }

    return false;
  }

  Future<bool> _showBugsAnnouncementDialog() async {
    final int savedSeconds = await Prefs().getStatsCumulatedAppUseSeconds();
    // Do not show version 0 (user scripts bugs) to new users
    // 43200 seconds = 12 hours
    if (savedSeconds < 43200) return false;
    if ((await Prefs().getBugsAnnouncementDialogVersion()) <= 0) {
      try {
        await showDialog(
          useRootNavigator: false,
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return const BugsAnnouncementDialog();
          },
        );

        // Then update the version to the current one
        Prefs().setBugsAnnouncementDialogVersion(1);
        return true; // Do not show more dialogs below
      } catch (e) {
        log("Error while checking if bugs announcement dialog is allowed: $e");
      }
    }

    return false;
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

  void _openDrawer() {
    if (routeWithDrawer) {
      if (_webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
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
      AppBadgePlus.updateBadge(0);
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
                                  style: TextStyle(fontSize: 11, color: _themeProvider!.mainText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Text(
                            update,
                            style: TextStyle(fontSize: 11, color: _themeProvider!.mainText),
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
                                  url: "https://www.torn.com/page.php?sid=stocks",
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

  void checkForScriptUpdates() {
    final int alreadyAvailableCount = _userScriptsProvider.userScriptList
        .where((s) => s.updateStatus == UserScriptUpdateStatus.updateAvailable)
        .length;

    _userScriptsProvider.checkForUpdates().then((i) async {
      // Check if we need to show a notification (only if there are any new updates)
      if (_userScriptsProvider.userScriptsNotifyUpdates && i - alreadyAvailableCount > 0) {
        const String channelTitle = 'Manual scripts';
        const String channelSubtitle = 'Manual scripts';
        const String channelDescription = 'Manual notifications for scripts';
        final String notificationTitle = 'Script Update Available';
        final String notificationSubtitle = 'You have $i script update${i == 1 ? "" : "s"} available, '
            'visit the UserScripts section to update them';
        final int notificationId = 777;
        final String notificationPayload = "scriptupdate";

        final modifier = await getNotificationChannelsModifiers();
        final androidPlatformChannelSpecifics = AndroidNotificationDetails(
          "$channelTitle ${modifier.channelIdModifier}",
          "$channelSubtitle ${modifier.channelIdModifier}",
          channelDescription: channelDescription,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          icon: 'notification_icon',
          color: Colors.grey,
          ledColor: const Color.fromARGB(255, 255, 0, 0),
          ledOnMs: 1000,
          ledOffMs: 500,
        );

        const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
          presentSound: true,
          sound: 'slow_spring_board.aiff',
        );

        final platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

        flutterLocalNotificationsPlugin.show(
          notificationId,
          notificationTitle,
          notificationSubtitle,
          platformChannelSpecifics,
          payload: notificationPayload,
        );
      }
      log("UserScripts checkForUpdates() completed with $i updates available, $alreadyAvailableCount "
          "already prompted, should notify: ${_userScriptsProvider.userScriptsNotifyUpdates}");
    });
  }

  void _syncThemeWithDeviceSettings() {
    _preferencesCompleter.future.whenComplete(() async {
      if (!_settingsProvider.syncDeviceTheme) return;

      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (brightness == Brightness.dark && _themeProvider!.currentTheme == AppTheme.light) {
        _themeProvider!.changeTheme = AppTheme.dark;
        if (_settingsProvider.syncTornWebTheme) {
          _webViewProvider.changeTornTheme(dark: true);
        }
      } else if (brightness == Brightness.light && _themeProvider!.currentTheme != AppTheme.light) {
        _themeProvider!.changeTheme = AppTheme.light;
        if (_settingsProvider.syncTornWebTheme) {
          _webViewProvider.changeTornTheme(dark: false);
        }
      }
    });
  }

  Future<void> _initialiseLiveActivitiesBridgeService() async {
    _preferencesCompleter.future.whenComplete(() async {
      if (!Platform.isIOS) return;
      if (!_settingsProvider.iosLiveActivityTravelEnabled) return;

      if (kSdkIos < 16.2) {
        // Regardless of user settings, disable Live Activities on iOS versions below 16.2
        _settingsProvider.iosLiveActivityTravelEnabled = false;
        return;
      }

      final bridgeController = Get.find<LiveActivityBridgeController>();
      final travelController = Get.find<LiveActivityTravelController>();

      bridgeController.initializeHandler();
      await travelController.activate();
    });
  }

  Future<void> _configureHighRefreshRate() async {
    try {
      await _settingsProvider.configureRefreshRate();
    } catch (e) {
      log('Error configuring refresh rate: $e');
    }
  }

  void changeUID(String uid) {
    _userUID = uid;
  }
}
