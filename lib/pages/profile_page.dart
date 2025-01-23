// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
// Project imports:
import 'package:torn_pda/models/chaining/chain_model.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/company/employees_model.dart';
import 'package:torn_pda/models/education_model.dart';
import 'package:torn_pda/models/faction/faction_crimes_model.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/models/property_model.dart';
import 'package:torn_pda/pages/profile/profile_options_page.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/profile/events_timeline_fixes.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/profile/arrival_button.dart';
import 'package:torn_pda/widgets/profile/bazaar_status.dart';
import 'package:torn_pda/widgets/profile/disregard_crime_dialog.dart';
import 'package:torn_pda/widgets/profile/event_icons.dart';
import 'package:torn_pda/widgets/profile/foreign_stock_button.dart';
import 'package:torn_pda/widgets/profile/jobpoints_dialog.dart';
import 'package:torn_pda/widgets/profile/market_status.dart';
import 'package:torn_pda/widgets/profile/ranked_war_mini.dart';
import 'package:torn_pda/widgets/profile/stats_chart.dart';
import 'package:torn_pda/widgets/profile/status_icons_wrap.dart';
import 'package:torn_pda/widgets/revive/hela_revive_button.dart';
import 'package:torn_pda/widgets/revive/midnightx_revive_button.dart';
import 'package:torn_pda/widgets/revive/nuke_revive_button.dart';
import 'package:torn_pda/widgets/revive/uhc_revive_button.dart';
import 'package:torn_pda/widgets/revive/wtf_revive_button.dart';
import 'package:torn_pda/widgets/tct_clock.dart';
import 'package:torn_pda/widgets/travel/travel_return_widget.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

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
  rankedWar,
  raceStart,
}

enum NotificationType {
  notification,
  alarm,
  timer,
}

extension ProfileNotificationExtension on ProfileNotification {
  String? get string {
    switch (this) {
      case ProfileNotification.travel:
        return 'travel';
      case ProfileNotification.energy:
        return 'energy';
      case ProfileNotification.nerve:
        return 'nerve';
      case ProfileNotification.life:
        return 'life';
      case ProfileNotification.drugs:
        return 'drugs';
      case ProfileNotification.medical:
        return 'medical';
      case ProfileNotification.booster:
        return 'booster';
      default:
        return null;
    }
  }
}

class ProfilePage extends StatefulWidget {
  final Function callBackSection;
  final Function disableTravelSection;

  const ProfilePage({
    required this.callBackSection,
    required this.disableTravelSection,
  });

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  Future? _apiFetched;
  bool _apiGoodData = false;
  ApiError? _apiError = ApiError();
  int _apiRetries = 0;

  OwnProfileExtended? _user;
  List<Event> _events = <Event>[];

  late DateTime _serverTime;

  Timer? _tickerCallApi;
  late Stream _browserHasClosed;
  late StreamSubscription _browserHasClosedSubscription;

  SettingsProvider? _settingsProvider;
  ThemeProvider? _themeProvider;
  UserDetailsProvider? _userProv;
  late ChainStatusProvider _chainProvider;
  late ShortcutsProvider _shortcutsProv;
  late WebViewProvider _webViewProvider;
  final UserController _u = Get.find<UserController>();
  final WarController _w = Get.find<WarController>();

  late int _travelNotificationAhead;
  late int _travelAlarmAhead;
  late int _travelTimerAhead;

  late DateTime _travelArrivalTime;
  DateTime? _energyNotificationTime;
  DateTime? _nerveNotificationTime;
  DateTime? _lifeNotificationTime;
  DateTime? _drugsNotificationTime;
  DateTime? _medicalNotificationTime;
  DateTime? _boosterNotificationTime;
  late DateTime _hospitalReleaseTime;
  late DateTime _jailReleaseTime;
  late DateTime _rankedWarTime;
  late DateTime _raceStartTime;

  late int _hospitalNotificationAhead;
  late int _hospitalTimerAhead;
  late int _hospitalAlarmAhead;
  late int _jailNotificationAhead;
  late int _jailTimerAhead;
  late int _jailAlarmAhead;
  late int _rankedWarNotificationAhead;
  late int _rankedWarTimerAhead;
  late int _rankedWarAlarmAhead;
  late int _raceStartNotificationAhead;
  late int _raceStartTimerAhead;
  late int _raceStartAlarmAhead;

  bool _travelNotificationsPending = false;
  bool _energyNotificationsPending = false;
  bool _nerveNotificationsPending = false;
  bool _lifeNotificationsPending = false;
  bool _drugsNotificationsPending = false;
  bool _medicalNotificationsPending = false;
  bool _boosterNotificationsPending = false;
  bool _hospitalNotificationsPending = false;
  bool _jailNotificationsPending = false;
  bool _rankedWarNotificationsPending = false;
  bool _raceStartNotificationsPending = false;

  late NotificationType _travelNotificationType;
  late NotificationType _energyNotificationType;
  late NotificationType _nerveNotificationType;
  late NotificationType _lifeNotificationType;
  late NotificationType _drugsNotificationType;
  late NotificationType _medicalNotificationType;
  late NotificationType _boosterNotificationType;
  late NotificationType _hospitalNotificationType;
  late NotificationType _jailNotificationType;
  late NotificationType _rankedWarNotificationType;
  late NotificationType _raceStartNotificationType;

  int? _customEnergyTrigger;
  int? _customNerveTrigger;

  bool _customEnergyMaxOverride = false;
  bool _customNerveMaxOverride = false;

  IconData? _travelNotificationIcon;
  IconData? _energyNotificationIcon;
  IconData? _nerveNotificationIcon;
  IconData? _lifeNotificationIcon;
  IconData? _drugsNotificationIcon;
  IconData? _medicalNotificationIcon;
  IconData? _boosterNotificationIcon;
  IconData? _hospitalNotificationIcon;
  IconData? _jailNotificationIcon;
  IconData? _rankedWarNotificationIcon;
  IconData? _raceStartNotificationIcon;

  late bool _alarmSound;
  late bool _alarmVibration;

  bool _miscApiFetchedOnce = false;
  DateTime _miscTickLastTime = DateTime.now();
  OwnProfileMisc? _miscModel;
  TornEducationModel? _tornEducationModel;
  UserItemMarketResponse? _marketItemsV2;

  var _rentedProperties = 0;
  Widget _rentedPropertiesWidget = const SizedBox.shrink();
  DateTime? _rentedPropertiesLastChecked;

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

  bool _warnAboutChains = false;
  bool _showHeaderWallet = false;
  bool _showHeaderIcons = false;
  bool _dedicatedTravelCard = false;

  late ChainModel _chainModel;

  final _eventsExpController = ExpandableController();
  final _messagesExpController = ExpandableController();
  final _basicInfoExpController = ExpandableController();
  final _networthExpController = ExpandableController();

  int? _messagesShowNumber = 25;
  int? _eventsShowNumber = 25;

  final _showOne = GlobalKey();

  final _originalSectionOrder = [
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
  List<String>? _userSectionOrder = <String>[];

  var _sharedEffStrength = "";
  var _sharedEffSpeed = "";
  var _sharedEffDexterity = "";
  var _sharedEffDefense = "";
  var _sharedEffTotal = "";
  var _sharedJobPoints = "";

  StatsChartTornStats? _statsChartModel;
  Future? _statsChartDataFetched;

  RankedWar? _factionRankedWar;

  int? _companyAddiction;

  // Showcases
  final GlobalKey _showcaseProfileBars = GlobalKey();
  final GlobalKey _showcaseProfileClock = GlobalKey();
  final GlobalKey _showcasePdaBrowserButton = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _retrievePendingNotifications();

    _userProv = Provider.of<UserDetailsProvider>(context, listen: false);
    _chainProvider = context.read<ChainStatusProvider>();

    _loadPreferences().whenComplete(() {
      _apiFetched = _fetchApi();
    });

    // Initialise periodic API refresh
    _resetApiTimer();

    // Join a stream that will notify when the browser closes (a browser initiated in Profile or elsewhere)
    // So that we can 1) refresh the API, 2) start the API timer again
    _browserHasClosed = context.read<WebViewProvider>().browserHasClosedStream.stream;
    _browserHasClosedSubscription = _browserHasClosed.listen((event) {
      log("Browser has closed in Profile, resuming API calls!");
      _resetApiTimer(initCall: true);
    });

    analytics?.logScreenView(screenName: 'profile');

    routeWithDrawer = true;
    routeName = "profile`";
  }

  /// Restarts the API timer (to be executed after 20 seconds)
  /// If [initCall] is true, a call is placed also at the start
  /// (unless the browser is open)
  void _resetApiTimer({bool initCall = false}) {
    if (initCall && (!_webViewProvider.browserShowInForeground || _webViewProvider.webViewSplitActive)) {
      _apiRefreshPeriodic(forceMisc: true);
    }

    _tickerCallApi?.cancel();
    _tickerCallApi = Timer.periodic(const Duration(seconds: 20), (Timer t) {
      // Only refresh if the browser is not open!
      if (!_webViewProvider.browserShowInForeground || _webViewProvider.webViewSplitActive) {
        _apiRefreshPeriodic();
      }
    });
  }

  void _apiRefreshPeriodic({bool forceMisc = false}) {
    _fetchApi();
    _refreshEvents();

    // Fetch misc every minute
    final int secondsSinceLastMiscFetch = DateTime.now().difference(_miscTickLastTime).inSeconds;
    if (secondsSinceLastMiscFetch > 60 || forceMisc) {
      _miscTickLastTime = DateTime.now();
      _getMiscCardInfo(forcedUpdate: forceMisc);
      _getStatsChart();
      _getRankedWars();
      _getCompanyAddiction();
    }
  }

  @override
  void dispose() {
    _chainProvider.statusUpdateSource = "provider";
    _tickerCallApi?.cancel();
    _browserHasClosedSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (Platform.isWindows) return;

    if (state == AppLifecycleState.resumed) {
      _resetApiTimer(initCall: true);
    } else if (state == AppLifecycleState.paused) {
      _tickerCallApi?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _shortcutsProv = Provider.of<ShortcutsProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return ShowCaseWidget(
      builder: (_) {
        _launchShowCases(_);
        return Scaffold(
          backgroundColor: _themeProvider!.canvas,
          drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
          endDrawer: !_webViewProvider.splitScreenAndBrowserLeft() ? null : const Drawer(),
          appBar: _settingsProvider!.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider!.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          floatingActionButton: Stack(
            children: [
              buildSpeedDial(),
            ],
          ),
          body: Container(
            color: _themeProvider!.canvas,
            child: FutureBuilder(
              future: _apiFetched,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_apiGoodData) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        _resetApiTimer(initCall: true);
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            _headerIcons(),
                            Column(
                              children: _returnSections(),
                            ),
                            const SizedBox(height: 70),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return RefreshIndicator(
                      onRefresh: () async {
                        _fetchApi();
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      child: SingleChildScrollView(
                        // Physics so that page can be refreshed even with no scroll
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(height: 50),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: _shortcutsCarrousel(),
                            ),
                            const SizedBox(height: 50),
                            const Text(
                              'OOPS!',
                              style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                              child: Column(
                                children: [
                                  Text(
                                    'There was an error: ${_apiError!.errorReason}',
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_apiError!.pdaErrorDetails.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Column(
                                        children: [
                                          if (_apiError!.errorId != 9)
                                            Column(
                                              children: [
                                                const Text(
                                                  'Error details:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  _apiError!.pdaErrorDetails,
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          if (_apiError!.errorId == 9)
                                            Text(
                                              "The API has been manually disabled by the developers. "
                                              "This normally lasts just a few minutes\n\n"
                                              "Otherwise, you can head to the forums of Discord to see if there "
                                              "is any more information available.",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.red[700]),
                                            ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Torn PDA is retrying automatically. '
                                    "If you have good Internet connectivity, it might be an issue with Torn's API.",
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'You can still try to access Torn through shortcuts or the main '
                                    'menu icon below.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    );
                  }
                } else {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Fetching data...'),
                        SizedBox(height: 30),
                        Padding(
                          padding: EdgeInsets.all(8.0),
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
      },
    );
  }

  void _launchShowCases(BuildContext _) {
    Future.delayed(const Duration(seconds: 1), () async {
      final List showCases = <GlobalKey<State<StatefulWidget>>>[];
      // Show tab bar showcases
      if (!_settingsProvider!.showCases.contains("profile_bars")) {
        _settingsProvider!.addShowCase = "profile_bars";
        showCases.add(_showcaseProfileBars);
      }

      if (!_settingsProvider!.showCases.contains("profile_clock")) {
        _settingsProvider!.addShowCase = "profile_clock";
        showCases.add(_showcaseProfileClock);
      }

      if (!_settingsProvider!.showCases.contains("profile_pdaBrowserButton")) {
        _settingsProvider!.addShowCase = "profile_pdaBrowserButton";
        showCases.add(_showcasePdaBrowserButton);
      }

      if (showCases.isNotEmpty) {
        ShowCaseWidget.of(_).startShowCase(showCases as List<GlobalKey<State<StatefulWidget>>>);
      }
    });
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      title: Stack(
        children: [
          Column(
            children: [
              if (_user?.name != null && _user!.name!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    final String status = _user!.lastAction!.status == 'Offline'
                        ? 'Offline (${_user!.lastAction!.relative!.replaceAll(" ago", "")})'
                        : _user!.lastAction!.status == 'Online'
                            ? 'Online now'
                            : 'Online ${_user!.lastAction!.relative}';
                    BotToast.showText(
                      text: status,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: Colors.blue,
                      duration: const Duration(seconds: 3),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: _user!.playerId.toString()));
                    BotToast.showText(
                      text: "ID copied to the clipboard!",
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: Colors.blue,
                      contentPadding: const EdgeInsets.all(10),
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
                              child: Text(_user!.name!, style: TextStyle(color: Colors.white)),
                            ),
                            if (_user!.lastAction!.status == "Offline")
                              const Icon(Icons.remove_circle, size: 14, color: Colors.grey)
                            else
                              _user!.lastAction!.status == "Idle"
                                  ? const Icon(Icons.adjust, size: 14, color: Colors.orange)
                                  : Icon(Icons.circle, size: 14, color: Colors.green[400]),
                          ],
                        ),
                      ),
                      Text(
                        "[${_user!.playerId}] - Level ${_user!.level}",
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ],
                  ),
                )
              else
                const Text("Profile", style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.splitScreenAndBrowserLeft()) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive)
            Showcase(
              key: _showcasePdaBrowserButton,
              title: 'Direct Torn access!',
              description: '\nUse this PDA button in any section to quickly access Torn.\n\n'
                  'By using this icon, you will immediately resume your Torn browser experience, exactly as you '
                  'left it, with no new tabs reloading.\n\n'
                  'Make sure to visit the Settings and Tips section to learn how you can also configure '
                  'your taps (quick or long) to launch the browser in windowed or full screen modes!',
              showArrow: false,
              disableMovingAnimation: true,
              textColor: _themeProvider!.mainText!,
              tooltipBackgroundColor: _themeProvider!.secondBackground!,
              descTextStyle: const TextStyle(fontSize: 13),
              tooltipPadding: const EdgeInsets.all(20),
              child: PdaBrowserIcon(),
            )
          else
            Container(),
        ],
      ),
      actions: <Widget>[
        if (_apiGoodData)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _launchBrowser(url: "https://www.torn.com/calendar.php", shortTap: true);
              },
              onLongPress: () {
                _launchBrowser(url: "https://www.torn.com/calendar.php", shortTap: false);
              },
              child: Showcase(
                key: _showcaseProfileClock,
                title: 'There is a lot to explore!',
                description: '\nAlmost anything in Torn PDA can be interacted with!\n\n'
                    "Try for yourself, and don't forget to visit the Tips section for more "
                    'information!',
                showArrow: false,
                disableMovingAnimation: true,
                textColor: _themeProvider!.mainText!,
                tooltipBackgroundColor: _themeProvider!.secondBackground!,
                descTextStyle: const TextStyle(fontSize: 13),
                tooltipPadding: const EdgeInsets.all(20),
                child: const TctClock(color: Colors.white),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: _themeProvider!.buttonText,
          ),
          onPressed: () async {
            final ProfileOptionsReturn newOptions = await Navigator.push(
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
              if (newOptions.warnAboutChainsEnabled != null) {
                _warnAboutChains = newOptions.warnAboutChainsEnabled!;
              }
              if (newOptions.showHeaderWallet != null) {
                _showHeaderWallet = newOptions.showHeaderWallet!;
              }
              if (newOptions.showHeaderIcons != null) {
                _showHeaderIcons = newOptions.showHeaderIcons!;
              }
              if (newOptions.dedicatedTravelCard != null) {
                _dedicatedTravelCard = newOptions.dedicatedTravelCard!;
              }
              _eventsExpController.expanded = newOptions.expandEvents!;
              _messagesShowNumber = newOptions.messagesShowNumber;
              _eventsShowNumber = newOptions.eventsShowNumber;
              _messagesExpController.expanded = newOptions.expandMessages!;
              _basicInfoExpController.expanded = newOptions.expandBasicInfo!;
              _networthExpController.expanded = newOptions.expandNetworth!;
              _userSectionOrder = newOptions.sectionSort;
            });
            // If we reactivated faction crimes, they might take up to a minute
            // to appear unless we call them directly
            if (newOptions.oCrimesReactivated) {
              _getFactionCrimes();
            }
            if (_settingsProvider!.tornStatsChartDateTime == 0) {
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
                  thisShortcut.iconUrl!,
                  width: 16,
                  color: _themeProvider!.mainText,
                ),
              ),
              const SizedBox(height: 3),
              Flexible(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 55,
                      child: Text(
                        thisShortcut.nickname!.toUpperCase(),
                        style: const TextStyle(fontSize: 9),
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
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              thisShortcut.iconUrl!,
              width: 16,
              color: _themeProvider!.mainText,
            ),
          ),
        );
      } else {
        // Only text
        tile = Padding(
          padding: const EdgeInsets.all(2),
          child: SizedBox(
            width: 55,
            child: Center(
              child: Container(
                child: Text(
                  thisShortcut.nickname!.toUpperCase(),
                  style: const TextStyle(fontSize: 9),
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
          String? url = thisShortcut.url;
          if (thisShortcut.addPlayerId != null) {
            // Avoid null objects coming before the introduction of this replacement (v2.9.4)
            if (thisShortcut.addPlayerId!) {
              url = url!.replaceAll("##P##", _userProv!.basic!.playerId.toString());
            }
            if (thisShortcut.addFactionId!) {
              url = url!.replaceAll("##F##", _userProv!.basic!.faction!.factionId.toString());
            }
            if (thisShortcut.addCompanyId!) {
              url = url!.replaceAll("##C##", _userProv!.basic!.job!.companyId.toString());
            }
          }

          _launchBrowser(url: url, shortTap: false);
        },
        onTap: () async {
          String? url = thisShortcut.url;
          if (thisShortcut.addPlayerId != null) {
            // Avoid null objects coming before the introduction of this replacement (v2.9.4)
            if (thisShortcut.addPlayerId!) {
              url = url!.replaceAll("##P##", _userProv!.basic!.playerId.toString());
            }
            if (thisShortcut.addFactionId!) {
              url = url!.replaceAll("##F##", _userProv!.basic!.faction!.factionId.toString());
            }
            if (thisShortcut.addCompanyId!) {
              url = url!.replaceAll("##C##", _userProv!.basic!.job!.companyId.toString());
            }
          }

          _launchBrowser(url: url, shortTap: true);
        },
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: thisShortcut.color!, width: 1.5),
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
            final thisShortcut = _shortcutsProv.activeShortcuts[index];
            return shortcutTile(thisShortcut);
          },
        );
      } else {
        final wrapItems = <Widget>[];
        for (final thisShortcut in _shortcutsProv.activeShortcuts) {
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
            SizedBox(height: h, width: w, child: shortcutTile(thisShortcut)),
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
      child: _shortcutsProv.activeShortcuts.isEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
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
                      'Tap the icon to configure',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  child: IconButton(
                    icon: const Icon(Icons.switch_access_shortcut_outlined),
                    color: Colors.orange[900],
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => ShortcutsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : shortcutMenu(),
    );
  }

  Card _playerStatus() {
    Widget descriptionWidget() {
      if (_user!.status!.state == 'Okay') {
        return const SizedBox.shrink();
      } else {
        String? descriptionText = _user!.status!.description!;

        // Is there a detailed description? Add it.
        if (_user!.status!.details != '') {
          descriptionText += '- ${_user!.status!.details}';
        }

        // Causing player ID (jailed of hospitalized the user)
        final RegExp expHtml = RegExp("<[^>]*>");
        final matches = expHtml.allMatches(descriptionText).map((m) => m[0]);
        String? causingId = '';
        if (matches.isNotEmpty) {
          final RegExp expId = RegExp("(?!XID=)([0-9])+");
          final id = expId.allMatches(_user!.status!.details!).map((m) => m[0]);
          causingId = id.first;
        }

        // If there is a player causing it, add a span to click and go to the
        // profile, otherwise return just the description text
        Widget detailsWidget;
        if (_user!.status!.details != '') {
          if (causingId != '') {
            detailsWidget = GestureDetector(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: HtmlParser.fix(descriptionText),
                      style: TextStyle(color: _themeProvider!.mainText),
                    ),
                    TextSpan(
                      text: ' (',
                      style: TextStyle(color: _themeProvider!.mainText),
                    ),
                    const TextSpan(
                      text: 'profile',
                      style: TextStyle(color: Colors.blue),
                    ),
                    TextSpan(
                      text: ')',
                      style: TextStyle(color: _themeProvider!.mainText),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _launchBrowser(
                  url: 'https://www.torn.com/profiles.php?'
                      'XID=$causingId',
                  shortTap: true,
                );
              },
              onLongPress: () {
                _launchBrowser(
                  url: 'https://www.torn.com/profiles.php?'
                      'XID=$causingId',
                  shortTap: false,
                );
              },
            );
          } else {
            detailsWidget = Text(descriptionText);
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: <Widget>[
                const SizedBox(
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
          return const SizedBox.shrink();
        }
      }
    }

    bool repatriated = false;

    Color? stateColor;
    if (_user!.status!.color == 'red') {
      stateColor = Colors.red;
      if (_user!.travel!.timeLeft! > 0) {
        repatriated = true;
      }
    } else if (_user!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (_user!.status!.color == 'blue') {
      stateColor = Colors.blue;
    }

    Widget stateBall({bool forceBlue = false}) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: forceBlue ? Colors.blue : stateColor,
            shape: BoxShape.circle,
            border: Border.all(),
          ),
        ),
      );
    }

    bool warInFuture = false;
    if (_factionRankedWar != null) {
      final int ts = DateTime.now().millisecondsSinceEpoch;
      warInFuture = _factionRankedWar!.war!.start! * 1000 > ts;
    }

    return Card(
      child: Stack(
        children: [
          // Shadow layer
          if (_settingsProvider!.colorCodedStatusCard)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: _user!.status!.color! == 'green'
                          ? Colors.green
                          : _user!.status!.color! == "red"
                              ? Colors.red
                              : Colors.blue,
                      blurRadius: 4.0,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: _themeProvider!.cardColor!,
              borderRadius: BorderRadius.circular(_settingsProvider!.colorCodedStatusCard ? 5 : 0),
            ),
            //color: _themeProvider!.cardColor!,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_factionRankedWar != null && _settingsProvider!.rankedWarsInProfile)
                          Row(
                            children: [
                              GestureDetector(
                                onLongPress: () => _launchBrowser(
                                  url: 'https://www.torn.com/factions.php?step=your#/war/rank',
                                  shortTap: false,
                                ),
                                onTap: () {
                                  _launchBrowser(
                                    url: 'https://www.torn.com/factions.php?step=your#/war/rank',
                                    shortTap: true,
                                  );
                                },
                                child: RankedWarMini(
                                  rankedWar: _factionRankedWar,
                                  playerFactionName: _user!.faction!.factionName,
                                  playerFactionTag: _user!.faction!.factionTag,
                                ),
                              ),
                              if (warInFuture)
                                Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    _notificationIcon(ProfileNotification.rankedWar),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      children: <Widget>[
                        if (!repatriated)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 60,
                                      child: Text('Status: '),
                                    ),
                                    Text(_user!.status!.state!),
                                    stateBall(),
                                  ],
                                ),
                                if (_user!.status!.color == 'red' && _user!.status!.state == "Hospital")
                                  _notificationIcon(ProfileNotification.hospital),
                                if (_user!.status!.color == 'red' && _user!.status!.state == "Jail")
                                  _notificationIcon(ProfileNotification.jail),
                              ],
                            ),
                          )
                        else
                          // Traveling while in hospital (repatriation)
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 60,
                                          child: Text('Status: '),
                                        ),
                                        Text(_user!.status!.state!),
                                        stateBall(),
                                      ],
                                    ),
                                    if (_user!.status!.color == 'red' && _user!.status!.state == "Hospital")
                                      _notificationIcon(ProfileNotification.hospital),
                                    if (_user!.status!.color == 'red' && _user!.status!.state == "Jail")
                                      _notificationIcon(ProfileNotification.jail),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    children: [
                                      const SizedBox(width: 60),
                                      const Text("Travel (repatriated)"),
                                      stateBall(forceBlue: true),
                                    ],
                                  ),
                                  _notificationIcon(ProfileNotification.travel),
                                ],
                              ),
                              if (!_dedicatedTravelCard) _travelWidget(repatriated: true),
                            ],
                          ),
                        BazaarStatusCard(
                          // Careful, in this card we mixed sync with async items, so the miscModel can still be null
                          bazaarModel: _miscModel?.bazaar,
                          launchBrowser: _launchBrowser,
                        ),
                        if (_marketItemsV2?.itemmarket != null && _marketItemsV2!.itemmarket!.isNotEmpty)
                          MarketStatusCard(
                            marketModel: _marketItemsV2!,
                            launchBrowser: _launchBrowser,
                          ),
                        if (!_dedicatedTravelCard) _travelWidget(),
                        descriptionWidget(),
                        if (_user!.status!.state == 'Hospital' && _w.nukeReviveActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 13, top: 10),
                            child: NukeReviveButton(
                              themeProvider: _themeProvider,
                              user: _user,
                              webViewProvider: _webViewProvider,
                              settingsProvider: _settingsProvider,
                            ),
                          ),
                        if (_user!.status!.state == 'Hospital' && _w.uhcReviveActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 13, top: 10),
                            child: UhcReviveButton(
                              themeProvider: _themeProvider,
                              user: _user,
                              webViewProvider: _webViewProvider,
                              settingsProvider: _settingsProvider,
                            ),
                          ),
                        if (_user!.status!.state == 'Hospital' && _w.helaReviveActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 13, top: 10),
                            child: HelaReviveButton(
                              themeProvider: _themeProvider,
                              user: _user,
                              webViewProvider: _webViewProvider,
                              settingsProvider: _settingsProvider,
                            ),
                          ),
                        if (_user!.status!.state == 'Hospital' && _w.wtfReviveActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 13, top: 10),
                            child: WtfReviveButton(
                              themeProvider: _themeProvider,
                              user: _user,
                              webViewProvider: _webViewProvider,
                              settingsProvider: _settingsProvider,
                            ),
                          ),
                        if (_user!.status!.state == 'Hospital' && _w.midnightXReviveActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 13, top: 10),
                            child: MidnightXReviveButton(
                              themeProvider: _themeProvider,
                              user: _user,
                              webViewProvider: _webViewProvider,
                              settingsProvider: _settingsProvider,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getTravelPercentage(int totalSeconds) {
    final double percentage = 1 - (_user!.travel!.timeLeft! / totalSeconds);
    if (percentage > 1) {
      return 1;
    } else if (percentage < 0) {
      return 0;
    } else {
      return percentage;
    }
  }

  Widget _travelWidget({bool repatriated = false}) {
    if (_user!.status!.state == 'Traveling' || repatriated) {
      final startTime = _user!.travel!.departed!;
      final endTime = _user!.travel!.timestamp!;
      final totalTravelTimeSeconds = endTime - startTime;

      final dateTimeArrival = DateTime.fromMillisecondsSinceEpoch(_user!.travel!.timestamp! * 1000);
      final timeDifference = dateTimeArrival.difference(DateTime.now());
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      final String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
      final String diff = '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';

      final formattedTime = TimeFormatter(
        inputTime: dateTimeArrival,
        timeFormatSetting: _settingsProvider!.currentTimeFormat,
        timeZoneSetting: _settingsProvider!.currentTimeZone,
      ).formatHourWithDaysElapsed();

      final double percentage = _getTravelPercentage(totalTravelTimeSeconds);
      final String ballAssetLocation = _flagBallAsset();

      bool isChristmasPeriod() {
        final now = DateTime.now();
        final christmasStart = DateTime(now.year, 12, 19);
        final christmasEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        return now.isAfter(christmasStart) && now.isBefore(christmasEnd);
      }

      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onLongPress: () => _launchBrowser(url: 'https://www.torn.com', shortTap: false),
                      onTap: () {
                        _launchBrowser(url: 'https://www.torn.com', shortTap: true);
                      },
                      child: LinearPercentIndicator(
                        padding: const EdgeInsets.all(0),
                        barRadius: const Radius.circular(10),
                        isRTL: _user!.travel!.destination == "Torn" ? true : false,
                        center: Text(
                          diff,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        widgetIndicator: Padding(
                          padding: _user!.travel!.destination == "Torn"
                              ? const EdgeInsets.only(top: 7, left: 15)
                              : const EdgeInsets.only(top: 7, right: 15),
                          child: Opacity(
                            // Make icon transparent when about to pass over text
                            opacity: percentage < 0.2 || percentage > 0.7 ? 1 : 0.3,
                            child: _user!.travel!.destination == "Torn"
                                ? isChristmasPeriod()
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()..scale(-1.0, 1.0),
                                        child: Icon(FontAwesomeIcons.sleigh, color: Colors.blue[900], size: 22),
                                      )
                                    : Image.asset('images/icons/plane_left.png', color: Colors.blue[900], height: 22)
                                : isChristmasPeriod()
                                    ? Icon(FontAwesomeIcons.sleigh, color: Colors.blue[900], size: 22)
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
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text('Arriving in ${_user!.travel!.destination} at $formattedTime'),
                    ),
                  ],
                ),
                TravelReturnWidget(
                  destination: _user!.travel!.destination,
                  settingsProvider: _settingsProvider,
                  dateTimeArrival: dateTimeArrival,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Card _travelCard() {
    Widget header;
    bool repatriated = false;
    if (_user!.status!.state == "Traveling") {
      header = _travelWidget();
    } else if (_user!.status!.state == "Hospital" && _user!.travel!.timeLeft! > 0) {
      header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 55),
            child: Text(
              "REPATRIATED",
              style: TextStyle(
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ),
          _travelWidget(repatriated: true),
        ],
      );
      repatriated = true;
    } else if (_user!.status!.state == "Abroad") {
      header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  backgroundColor: _themeProvider!.cardColor,
                  side: const BorderSide(
                    width: 2.0,
                    color: Colors.blueGrey,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _flagImage(),
                      const SizedBox(width: 6),
                      Column(
                        children: [
                          Text(
                            "VISIT",
                            style: TextStyle(
                              fontSize: 8,
                              color: _themeProvider!.mainText,
                            ),
                          ),
                          Text(
                            _user!.travel!.destination!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              color: _themeProvider!.mainText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                onLongPress: () {
                  _launchBrowser(url: 'https://www.torn.com', shortTap: false);
                },
                onPressed: () async {
                  const url = 'https://www.torn.com';
                  _launchBrowser(url: url, shortTap: true);
                },
              ),
              const SizedBox(width: 20),
              ForeignStockButton(
                userProv: _userProv,
                settingsProv: _settingsProvider,
                launchBrowser: _launchBrowser,
                updateCallback: _updateCallback,
              ),
            ],
          ),
          TravelReturnWidget(
            destination: _user!.travel!.destination,
            settingsProvider: _settingsProvider,
            dateTimeArrival: DateTime.now(),
          ),
        ],
      );
    } else {
      Widget ocStatus = const SizedBox.shrink();
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
                  showDialog(
                    useRootNavigator: false,
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
                  backgroundColor: _themeProvider!.cardColor,
                  side: const BorderSide(
                    width: 2.0,
                    color: Colors.blueGrey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.airport,
                      size: 22,
                      color: _themeProvider!.mainText,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      children: [
                        Text(
                          "TRAVEL",
                          style: TextStyle(
                            fontSize: 8,
                            color: _themeProvider!.mainText,
                          ),
                        ),
                        Text(
                          "AGENCY",
                          style: TextStyle(
                            fontSize: 8,
                            color: _themeProvider!.mainText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onLongPress: () {
                  _launchBrowser(url: 'https://www.torn.com/travelagency.php', shortTap: false);
                },
                onPressed: () async {
                  const url = 'https://www.torn.com/travelagency.php';
                  _launchBrowser(url: url, shortTap: true);
                },
              ),
              const SizedBox(width: 20),
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

    late Widget alertsButton;
    if (Platform.isAndroid) {
      alertsButton = Row(
        children: [
          RawMaterialButton(
            onPressed: null,
            constraints: const BoxConstraints.expand(width: 32, height: 32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: _travelNotificationsPending ? Colors.green : Colors.blueGrey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: _notificationIcon(
              ProfileNotification.travel,
              size: 20,
              forcedTravelIcon: NotificationType.notification,
            ),
          ),
          const SizedBox(width: 10),
          RawMaterialButton(
            onPressed: null,
            constraints: const BoxConstraints.expand(width: 32, height: 32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                color: Colors.blueGrey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: _notificationIcon(
              ProfileNotification.travel,
              size: 20,
              forcedTravelIcon: NotificationType.alarm,
            ),
          ),
          const SizedBox(width: 10),
          RawMaterialButton(
            onPressed: null,
            constraints: const BoxConstraints.expand(width: 32, height: 32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                color: Colors.blueGrey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: _notificationIcon(
              ProfileNotification.travel,
              size: 20,
              forcedTravelIcon: NotificationType.timer,
            ),
          ),
        ],
      );
    } else if (Platform.isIOS) {
      alertsButton = RawMaterialButton(
        onPressed: null,
        constraints: const BoxConstraints.expand(width: 32, height: 32),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fillColor: _themeProvider!.navSelected,
        shape: const CircleBorder(),
        child: _notificationIcon(
          ProfileNotification.travel,
          size: 20,
        ),
      );
    }

    Widget buttonsRow;
    if (_user!.status!.state == "Traveling" || repatriated) {
      if (_user!.travel!.timeLeft! > 180) {
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
              const SizedBox(width: 20),
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
      buttonsRow = const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
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
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
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
                  if (_warnAboutChains && _chainModel.chain!.current! > 10 && _chainModel.chain!.cooldown == 0)
                    Row(
                      children: [
                        const SizedBox(width: 65),
                        Text(
                          'CHAINING (${_chainModel.chain!.current}/${_chainModel.chain!.max})',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 50,
                            child: Text('Energy'),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            key: _showOne,
                            onLongPress: () {
                              _launchBrowser(url: 'https://www.torn.com/gym.php', shortTap: false);
                            },
                            onTap: () async {
                              _launchBrowser(url: 'https://www.torn.com/gym.php', shortTap: true);
                            },
                            child: Showcase(
                              key: _showcaseProfileBars,
                              title: 'Did you know?',
                              description: '\nTap any of the bars to launch a browser '
                                  'straight to the gym, crimes or items sections!',
                              targetPadding: const EdgeInsets.all(10),
                              disableMovingAnimation: true,
                              textColor: _themeProvider!.mainText!,
                              tooltipBackgroundColor: _themeProvider!.secondBackground!,
                              descTextStyle: const TextStyle(fontSize: 13),
                              tooltipPadding: const EdgeInsets.all(20),
                              child: LinearPercentIndicator(
                                padding: const EdgeInsets.all(0),
                                barRadius: const Radius.circular(10),
                                width: 150,
                                lineHeight: 20,
                                progressColor: Colors.green,
                                backgroundColor: Colors.grey,
                                center: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(
                                    '${_user!.energy!.current}/${_user!.energy!.maximum}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                percent: _user!.energy!.current! / _user!.energy!.maximum! > 1.0
                                    ? 1.0
                                    : _user!.energy!.current! / _user!.energy!.maximum!,
                              ),
                            ),
                          ),
                          if (_warnAboutChains && _chainModel.chain!.current! > 10 && _chainModel.chain!.cooldown == 0)
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
                            const SizedBox.shrink(),
                        ],
                      ),
                      _notificationIcon(ProfileNotification.energy),
                    ],
                  ),
                  _barTime('energy'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 50,
                            child: Text('Nerve'),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onLongPress: () {
                              _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', shortTap: false);
                            },
                            onTap: () async {
                              _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', shortTap: true);
                            },
                            child: LinearPercentIndicator(
                              padding: const EdgeInsets.all(0),
                              barRadius: const Radius.circular(10),
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.redAccent,
                              backgroundColor: Colors.grey,
                              center: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  '${_user!.nerve!.current}/${_user!.nerve!.maximum}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              percent: _user!.nerve!.current! / _user!.nerve!.maximum! > 1.0
                                  ? 1.0
                                  : _user!.nerve!.current! / _user!.nerve!.maximum!,
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(
                        width: 50,
                        child: Text('Happy'),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onLongPress: () {
                          _launchBrowser(url: 'https://www.torn.com/item.php#candy-items', shortTap: false);
                        },
                        onTap: () async {
                          _launchBrowser(url: 'https://www.torn.com/item.php#candy-items', shortTap: true);
                        },
                        child: LinearPercentIndicator(
                          padding: const EdgeInsets.all(0),
                          barRadius: const Radius.circular(10),
                          width: 150,
                          lineHeight: 20,
                          progressColor: Colors.amber,
                          backgroundColor: Colors.grey,
                          center: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              '${_user!.happy!.current}/${_user!.happy!.maximum}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          percent: _user!.happy!.current! / _user!.happy!.maximum! > 1.0
                              ? 1.0
                              : _user!.happy!.current! / _user!.happy!.maximum!,
                        ),
                      ),
                    ],
                  ),
                  _barTime('happy'),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                          const SizedBox(
                            width: 50,
                            child: Text('Life'),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onLongPress: () {
                              if (_settingsProvider!.lifeBarOption == "ask") {
                                _showLifeBarDialog(context, longPress: true);
                              } else if (_settingsProvider!.lifeBarOption == "inventory") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/item.php#medical-items',
                                  shortTap: false,
                                );
                              } else if (_settingsProvider!.lifeBarOption == "faction") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical',
                                  shortTap: false,
                                );
                              }
                            },
                            onTap: () async {
                              if (_settingsProvider!.lifeBarOption == "ask") {
                                _showLifeBarDialog(context);
                              } else if (_settingsProvider!.lifeBarOption == "inventory") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/item.php#medical-items',
                                  shortTap: true,
                                );
                              } else if (_settingsProvider!.lifeBarOption == "faction") {
                                _launchBrowser(
                                  url: 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical',
                                  shortTap: true,
                                );
                              }
                            },
                            child: LinearPercentIndicator(
                              padding: const EdgeInsets.all(0),
                              barRadius: const Radius.circular(10),
                              width: 150,
                              lineHeight: 20,
                              progressColor: Colors.blue,
                              backgroundColor: Colors.grey,
                              center: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  '${_user!.life!.current}/${_user!.life!.maximum}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              percent: _user!.life!.current! / _user!.life!.maximum! > 1.0
                                  ? 1.0
                                  : _user!.life!.current! / _user!.life!.maximum!,
                            ),
                          ),
                          if (_user!.status!.state == "Hospital")
                            const Icon(
                              Icons.local_hospital,
                              size: 20,
                              color: Colors.red,
                            )
                          else
                            const SizedBox.shrink(),
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
        if (_user!.energy!.fulltime == 0 || _user!.energy!.current! > _user!.energy!.maximum!) {
          return const SizedBox.shrink();
        } else {
          final time = _serverTime.add(Duration(seconds: _user!.energy!.fulltime!));
          final timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider!.currentTimeFormat,
            timeZoneSetting: _settingsProvider!.currentTimeZone,
          ).formatHourWithDaysElapsed();
          return Row(
            children: <Widget>[
              const SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
      case "nerve":
        if (_user!.nerve!.fulltime == 0 || _user!.nerve!.current! > _user!.nerve!.maximum!) {
          return const SizedBox.shrink();
        } else {
          final time = _serverTime.add(Duration(seconds: _user!.nerve!.fulltime!));
          final timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider!.currentTimeFormat,
            timeZoneSetting: _settingsProvider!.currentTimeZone,
          ).formatHourWithDaysElapsed();
          return Row(
            children: <Widget>[
              const SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
      case "happy":
        if (_user!.happy!.fulltime == 0 || _user!.happy!.current! > _user!.happy!.maximum!) {
          return const SizedBox.shrink();
        } else {
          final time = _serverTime.add(Duration(seconds: _user!.happy!.fulltime!));
          final timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider!.currentTimeFormat,
            timeZoneSetting: _settingsProvider!.currentTimeZone,
          ).formatHourWithDaysElapsed();
          return Row(
            children: <Widget>[
              const SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
      case "life":
        if (_user!.life!.fulltime == 0 || _user!.life!.current! > _user!.life!.maximum!) {
          return const SizedBox.shrink();
        } else {
          final time = _serverTime.add(Duration(seconds: _user!.life!.fulltime!));
          final timeFormatted = TimeFormatter(
            inputTime: time,
            timeFormatSetting: _settingsProvider!.currentTimeFormat,
            timeZoneSetting: _settingsProvider!.currentTimeZone,
          ).formatHourWithDaysElapsed();
          return Row(
            children: <Widget>[
              const SizedBox(width: 65),
              Text('Full at $timeFormatted'),
            ],
          );
        }
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _notificationIcon(
    ProfileNotification profileNotification, {
    double size = 22,
    NotificationType? forcedTravelIcon,
  }) {
    int? secondsToGo = 0;
    bool percentageError = false;
    late bool notificationsPending;
    late String notificationSetString;
    late String notificationCancelString;
    late String alarmSetString;
    late String timerSetString;
    NotificationType notificationType = NotificationType.notification;
    IconData? notificationIcon;

    switch (profileNotification) {
      case ProfileNotification.travel:
        _travelArrivalTime = DateTime.fromMillisecondsSinceEpoch(_user!.travel!.timestamp! * 1000);
        final timeDifference = _travelArrivalTime.difference(DateTime.now());
        secondsToGo = timeDifference.inSeconds;
        notificationsPending = _travelNotificationsPending;

        final notificationTime = _travelArrivalTime.add(Duration(seconds: -_travelNotificationAhead));
        final formattedTimeNotification = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final alarmTime = _travelArrivalTime.add(Duration(minutes: -_travelAlarmAhead));
        final formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final timerTime = _travelArrivalTime.add(Duration(seconds: -_travelTimerAhead));
        final formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

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
            case NotificationType.alarm:
              notificationIcon = Icons.notifications_none;
            case NotificationType.timer:
              notificationIcon = Icons.timer_outlined;
          }
        }

      case ProfileNotification.energy:
        if (_user!.energy!.current! < _user!.energy!.maximum!) {
          if (_customEnergyTrigger! < _user!.energy!.maximum!) {
            final energyToGo = _customEnergyTrigger! - _user!.energy!.current!;
            final energyTicksToGo = energyToGo / _user!.energy!.increment!;
            // If there is more than 1 tick to go, we multiply ticks times
            // the interval, and decrease for the current tick consumed
            if (energyTicksToGo > 1) {
              final consumedTick = _user!.energy!.interval! - _user!.energy!.ticktime!;
              secondsToGo = (energyTicksToGo * _user!.energy!.interval! - consumedTick).floor();
            }
            // If we are in the current tick or example in the next one,
            // we just take into consideration the tick time left
            else if (energyTicksToGo > 0 && energyTicksToGo <= 1) {
              secondsToGo = _user!.energy!.ticktime;
            } else {
              // We'll offer the user the option to go with full time
              secondsToGo = _user!.energy!.fulltime;
              percentageError = true;
            }
          } else {
            secondsToGo = _user!.energy!.fulltime;
          }

          _energyNotificationTime = DateTime.now().add(Duration(seconds: secondsToGo!));
          final formattedTime = TimeFormatter(
            inputTime: _energyNotificationTime,
            timeFormatSetting: _settingsProvider!.currentTimeFormat,
            timeZoneSetting: _settingsProvider!.currentTimeZone,
          ).formatHourWithDaysElapsed();

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

      case ProfileNotification.nerve:
        if (_user!.nerve!.current! < _user!.nerve!.maximum!) {
          if (_customNerveTrigger! < _user!.nerve!.maximum!) {
            final nerveToGo = _customNerveTrigger! - _user!.nerve!.current!;
            final nerveTicksToGo = nerveToGo / _user!.nerve!.increment!;
            // If there is more than 1 tick to go, we multiply ticks times
            // the interval, and decrease for the current tick consumed
            if (nerveTicksToGo > 1) {
              final consumedTick = _user!.nerve!.interval! - _user!.nerve!.ticktime!;
              secondsToGo = (nerveTicksToGo * _user!.nerve!.interval! - consumedTick).floor();
            }
            // If we are in the current tick or example in the next one,
            // we just take into consideration the tick time left
            else if (nerveTicksToGo > 0 && nerveTicksToGo <= 1) {
              secondsToGo = _user!.nerve!.ticktime;
            } else {
              // We'll offer the user the option to go with full time
              secondsToGo = _user!.nerve!.fulltime;
              percentageError = true;
            }
          } else {
            secondsToGo = _user!.nerve!.fulltime;
          }

          _nerveNotificationTime = DateTime.now().add(Duration(seconds: secondsToGo!));
          final formattedTime = TimeFormatter(
            inputTime: _nerveNotificationTime,
            timeFormatSetting: _settingsProvider!.currentTimeFormat,
            timeZoneSetting: _settingsProvider!.currentTimeZone,
          ).formatHourWithDaysElapsed();

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

      case ProfileNotification.life:
        secondsToGo = _user!.life!.fulltime;
        notificationsPending = _lifeNotificationsPending;
        _lifeNotificationTime = DateTime.now().add(Duration(seconds: _user!.life!.fulltime!));
        final formattedTime = TimeFormatter(
          inputTime: _lifeNotificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();
        notificationSetString = 'Life notification set for $formattedTime';
        notificationCancelString = 'Life notification cancelled!';
        alarmSetString = 'Life alarm set for $formattedTime';
        timerSetString = 'Life timer set for $formattedTime';
        notificationType = _lifeNotificationType;
        notificationIcon = _lifeNotificationIcon;

      case ProfileNotification.drugs:
        secondsToGo = _user!.cooldowns!.drug;
        notificationsPending = _drugsNotificationsPending;
        _drugsNotificationTime = DateTime.now().add(Duration(seconds: _user!.cooldowns!.drug!));
        final formattedTime = TimeFormatter(
          inputTime: _drugsNotificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();
        notificationSetString = 'Drugs cooldown notification set for $formattedTime';
        notificationCancelString = 'Drugs cooldown notification cancelled!';
        alarmSetString = 'Drugs cooldown alarm set for $formattedTime';
        timerSetString = 'Drugs cooldown timer set for $formattedTime';
        notificationType = _drugsNotificationType;
        notificationIcon = _drugsNotificationIcon;

      case ProfileNotification.medical:
        secondsToGo = _user!.cooldowns!.medical;
        notificationsPending = _medicalNotificationsPending;
        _medicalNotificationTime = DateTime.now().add(Duration(seconds: _user!.cooldowns!.medical!));
        final formattedTime = TimeFormatter(
          inputTime: _medicalNotificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();
        notificationSetString = 'Medical cooldown notification set for $formattedTime';
        notificationCancelString = 'Medical cooldown notification cancelled!';
        alarmSetString = 'Medical cooldown alarm set for $formattedTime';
        timerSetString = 'Medical cooldown timer set for $formattedTime';
        notificationType = _medicalNotificationType;
        notificationIcon = _medicalNotificationIcon;

      case ProfileNotification.booster:
        secondsToGo = _user!.cooldowns!.booster;
        notificationsPending = _boosterNotificationsPending;
        _boosterNotificationTime = DateTime.now().add(Duration(seconds: _user!.cooldowns!.booster!));
        final formattedTime = TimeFormatter(
          inputTime: _boosterNotificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();
        notificationSetString = 'Booster cooldown notification set for $formattedTime';
        notificationCancelString = 'Booster cooldown notification cancelled!';
        alarmSetString = 'Booster cooldown alarm set for $formattedTime';
        timerSetString = 'Booster cooldown timer set for $formattedTime';
        notificationType = _boosterNotificationType;
        notificationIcon = _boosterNotificationIcon;

      case ProfileNotification.hospital:
        _hospitalReleaseTime = DateTime.fromMillisecondsSinceEpoch(_user!.status!.until! * 1000);
        secondsToGo = _hospitalReleaseTime.difference(DateTime.now()).inSeconds;
        notificationsPending = _hospitalNotificationsPending;

        final notificationTime = _hospitalReleaseTime.add(Duration(seconds: -_hospitalNotificationAhead));
        final formattedTime = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final alarmTime = _hospitalReleaseTime.add(Duration(seconds: -_hospitalNotificationAhead));
        final formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final timerTime = _hospitalReleaseTime.add(Duration(seconds: -_hospitalNotificationAhead));
        final formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        notificationSetString = 'Hospital release notification set for $formattedTime';
        notificationCancelString = 'Hospital release notification cancelled!';
        alarmSetString = 'Hospital release alarm set for $formattedTimeAlarm';
        timerSetString = 'Hospital release timer set for $formattedTimeTimer';
        notificationType = _hospitalNotificationType;
        notificationIcon = _hospitalNotificationIcon;

      case ProfileNotification.jail:
        _jailReleaseTime = DateTime.fromMillisecondsSinceEpoch(_user!.status!.until! * 1000);
        secondsToGo = _jailReleaseTime.difference(DateTime.now()).inSeconds;
        notificationsPending = _jailNotificationsPending;

        final notificationTime = _jailReleaseTime.add(Duration(seconds: -_jailNotificationAhead));
        final formattedTime = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final alarmTime = _jailReleaseTime.add(Duration(seconds: -_jailNotificationAhead));
        final formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final timerTime = _jailReleaseTime.add(Duration(seconds: -_jailNotificationAhead));
        final formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        notificationSetString = 'Jail release notification set for $formattedTime';
        notificationCancelString = 'Jail release notification cancelled!';
        alarmSetString = 'Jail release alarm set for $formattedTimeAlarm';
        timerSetString = 'Jail release timer set for $formattedTimeTimer';
        notificationType = _jailNotificationType;
        notificationIcon = _jailNotificationIcon;

      case ProfileNotification.rankedWar:
        _rankedWarTime = DateTime.fromMillisecondsSinceEpoch(_factionRankedWar!.war!.start! * 1000);
        secondsToGo = _rankedWarTime.difference(DateTime.now()).inSeconds;
        notificationsPending = _rankedWarNotificationsPending;

        final notificationTime = _rankedWarTime.add(Duration(seconds: -_rankedWarNotificationAhead));
        final formattedTime = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final alarmTime = _rankedWarTime.add(Duration(seconds: -_rankedWarNotificationAhead));
        final formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final timerTime = _rankedWarTime.add(Duration(seconds: -_rankedWarNotificationAhead));
        final formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        notificationSetString = 'Ranked war notification set for $formattedTime';
        notificationCancelString = 'Ranked war notification cancelled!';
        alarmSetString = 'Ranked war alarm set for $formattedTimeAlarm';
        timerSetString = 'Ranked war timer set for $formattedTimeTimer';
        notificationType = _rankedWarNotificationType;
        notificationIcon = _rankedWarNotificationIcon;

      case ProfileNotification.raceStart:
        if (_user?.icons?.icon17 != null) {
          _raceStartTime = _parseRaceTime(_user!.icons!.icon17!.toString())!;
          secondsToGo = _raceStartTime.difference(DateTime.now()).inSeconds;
        }
        notificationsPending = _raceStartNotificationsPending;

        final notificationTime = _raceStartTime.add(Duration(seconds: -_raceStartNotificationAhead));
        final formattedTime = TimeFormatter(
          inputTime: notificationTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final alarmTime = _raceStartTime.add(Duration(seconds: -_raceStartNotificationAhead));
        final formattedTimeAlarm = TimeFormatter(
          inputTime: alarmTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        final timerTime = _raceStartTime.add(Duration(seconds: -_raceStartNotificationAhead));
        final formattedTimeTimer = TimeFormatter(
          inputTime: timerTime,
          timeFormatSetting: _settingsProvider!.currentTimeFormat,
          timeZoneSetting: _settingsProvider!.currentTimeZone,
        ).formatHourWithDaysElapsed();

        notificationSetString = 'Race start notification set for $formattedTime';
        notificationCancelString = 'Race start notification cancelled!';
        alarmSetString = 'Race start alarm set for $formattedTimeAlarm';
        timerSetString = 'Race start timer set for $formattedTimeTimer';
        notificationType = _raceStartNotificationType;
        notificationIcon = _raceStartNotificationIcon;
    }

    if (secondsToGo == 0 && !percentageError) {
      return const SizedBox.shrink();
    } else {
      Color? thisColor;
      if (notificationsPending && notificationType == NotificationType.notification) {
        thisColor = Colors.green;
      } else {
        if (percentageError) {
          thisColor = Colors.red[400]!.withOpacity(0.7);
        } else {
          thisColor = _themeProvider!.mainText;
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
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: percentageError ? Colors.red : Colors.green,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );
              } else if (notificationsPending && notificationType == NotificationType.notification) {
                _cancelNotifications(profileNotification);
                BotToast.showText(
                  text: notificationCancelString,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.orange[800]!,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );
              }
            case NotificationType.alarm:
              _setAlarm(profileNotification, alarmSetString, percentageError);

            case NotificationType.timer:
              _setTimer(profileNotification);
              BotToast.showText(
                text: timerSetString,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: percentageError ? Colors.red : Colors.green,
                duration: const Duration(seconds: 5),
                contentPadding: const EdgeInsets.all(10),
              );
          }
        },
      );
    }
  }

  Card _coolDowns() {
    Widget cooldownItems;
    if (_user!.cooldowns!.drug! > 0 || _user!.cooldowns!.booster! > 0 || _user!.cooldowns!.medical! > 0) {
      cooldownItems = Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          children: <Widget>[
            if (_user!.cooldowns!.drug! > 0)
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: [
                            _drugIcon(),
                            const SizedBox(width: 10),
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
                  const SizedBox(height: 10),
                ],
              )
            else
              const SizedBox.shrink(),
            if (_user!.cooldowns!.medical! > 0)
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: [
                            _medicalIcon(),
                            const SizedBox(width: 10),
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
                  const SizedBox(height: 10),
                ],
              )
            else
              const SizedBox.shrink(),
            if (_user!.cooldowns!.booster! > 0)
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: [
                            _boosterIcon(),
                            const SizedBox(width: 10),
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
                  const SizedBox(height: 10),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      );
    } else {
      cooldownItems = const Row(
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
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                'COOLDOWNS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            cooldownItems,
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Image _drugIcon() {
    // 0-10 minutes
    if (_user!.cooldowns!.drug! > 0 && _user!.cooldowns!.drug! < 600) {
      return Image.asset('images/icons/cooldowns/drug1.png', width: 20);
    } // 10-60 minutes
    else if (_user!.cooldowns!.drug! >= 600 && _user!.cooldowns!.drug! < 3600) {
      return Image.asset('images/icons/cooldowns/drug2.png', width: 20);
    } // 1-2 hours
    else if (_user!.cooldowns!.drug! >= 3600 && _user!.cooldowns!.drug! < 7200) {
      return Image.asset('images/icons/cooldowns/drug3.png', width: 20);
    } // 2-5 hours
    else if (_user!.cooldowns!.drug! >= 7200 && _user!.cooldowns!.drug! < 18000) {
      return Image.asset('images/icons/cooldowns/drug4.png', width: 20);
    } // 5+ hours
    else {
      return Image.asset('images/icons/cooldowns/drug5.png', width: 20);
    }
  }

  Widget _medicalIcon() {
    // 0-90 minutes hours
    if (_user!.cooldowns!.medical! > 0 && _user!.cooldowns!.medical! < 5400) {
      return Image.asset('images/icons/cooldowns/medical1.png', width: 20);
    } // 90-180 minutes
    else if (_user!.cooldowns!.medical! >= 5400 && _user!.cooldowns!.medical! < 10800) {
      return Image.asset('images/icons/cooldowns/medical2.png', width: 20);
    } // 180-270 minutes
    else if (_user!.cooldowns!.medical! >= 10800 && _user!.cooldowns!.medical! < 16200) {
      return Image.asset('images/icons/cooldowns/medical3.png', width: 20);
    } // 270-360 minutes
    else if (_user!.cooldowns!.medical! >= 16200 && _user!.cooldowns!.medical! < 21600) {
      return Image.asset('images/icons/cooldowns/medical4.png', width: 20);
    } // 360+ minutes
    else {
      return Image.asset('images/icons/cooldowns/medical5.png', width: 20);
    }
  }

  Image _boosterIcon() {
    // 0-6 hours
    if (_user!.cooldowns!.booster! > 0 && _user!.cooldowns!.booster! < 21600) {
      return Image.asset('images/icons/cooldowns/booster1.png', width: 20);
    } // 6-12 hours
    else if (_user!.cooldowns!.booster! >= 21600 && _user!.cooldowns!.booster! < 43200) {
      return Image.asset('images/icons/cooldowns/booster2.png', width: 20);
    } // 12-18 hours
    else if (_user!.cooldowns!.booster! >= 43200 && _user!.cooldowns!.booster! < 64800) {
      return Image.asset('images/icons/cooldowns/booster3.png', width: 20);
    } // 18-24 hours
    else if (_user!.cooldowns!.booster! >= 64800 && _user!.cooldowns!.booster! < 86400) {
      return Image.asset('images/icons/cooldowns/booster4.png', width: 20);
    } // 24+ hours
    else {
      return Image.asset('images/icons/cooldowns/booster5.png', width: 20);
    }
  }

  Widget _drugCounter() {
    final DateTime timeEnd = _serverTime.add(Duration(seconds: _user!.cooldowns!.drug!));

    final formattedTime = TimeFormatter(
      inputTime: timeEnd,
      timeFormatSetting: _settingsProvider!.currentTimeFormat,
      timeZoneSetting: _settingsProvider!.currentTimeZone,
    ).formatHourWithDaysElapsed();
    final String diff = _timeFormatted(timeEnd, previous: formattedTime);
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Text('@ $formattedTime$diff'),
      ),
    );
  }

  Widget _medicalCounter() {
    final timeEnd = _serverTime.add(Duration(seconds: _user!.cooldowns!.medical!));
    final formattedTime = TimeFormatter(
      inputTime: timeEnd,
      timeFormatSetting: _settingsProvider!.currentTimeFormat,
      timeZoneSetting: _settingsProvider!.currentTimeZone,
    ).formatHourWithDaysElapsed();
    final String diff = _timeFormatted(timeEnd, previous: formattedTime);
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Text('@ $formattedTime$diff'),
      ),
    );
  }

  Widget _boosterCounter() {
    final timeEnd = _serverTime.add(Duration(seconds: _user!.cooldowns!.booster!));
    final formattedTime = TimeFormatter(
      inputTime: timeEnd,
      timeFormatSetting: _settingsProvider!.currentTimeFormat,
      timeZoneSetting: _settingsProvider!.currentTimeZone,
    ).formatHourWithDaysElapsed();
    final String diff = _timeFormatted(timeEnd, previous: formattedTime);
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Text('@ $formattedTime$diff'),
      ),
    );
  }

  String _timeFormatted(DateTime timeEnd, {required String previous}) {
    final timeDifference = timeEnd.difference(_serverTime);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
    String diff = '';
    if (timeDifference.inMinutes < 1) {
      diff = ', in a few seconds';
    } else if (timeDifference.inMinutes >= 1 && timeDifference.inHours < 24) {
      diff = ', in ${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
    } else {
      final dayWeek = TimeFormatter(
        inputTime: timeEnd,
        timeFormatSetting: _settingsProvider!.currentTimeFormat,
        timeZoneSetting: _settingsProvider!.currentTimeZone,
      ).formatDayWeek;
      if (previous.contains("tomorrow")) {
        diff = ', in '
            '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
      } else {
        diff = ' (${dayWeek!.replaceAll("on ", "")}), in '
            '${twoDigits(timeDifference.inHours)}h ${twoDigitMinutes}m';
      }
    }
    return diff;
  }

  Card _eventsTimeline() {
    int? maxToShow = _eventsShowNumber;

    if (_events.isEmpty) {
      return const Card(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    'EVENTS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(25, 5, 20, 20),
                  child: Text(
                    "Loading...",
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final timeline = <Widget>[];

    int? unreadCount = 0;
    if (_user!.notifications != null) {
      unreadCount = _user!.notifications!.events;
    }

    int loopCount = 1;
    int? maxCount;

    if (_events.length > maxToShow!) {
      maxCount = maxToShow;
    } else {
      maxCount = _events.length;
      maxToShow = _events.length;
    }

    for (final Event e in _events) {
      if (e.event == null) continue;

      // Determine font weight based on unread status
      final FontWeight fontWeight = unreadCount! >= loopCount ? FontWeight.bold : FontWeight.normal;

      // Adapt text
      e.event = processEventMessage(e.event!);

      // Build the message widget
      // (the events API v1 has got many issues in http links, so we need to correct them manually)
      final Widget messageWidget = buildEventMessageWidget(e.event!, fontWeight, _launchBrowser, _themeProvider!);

      final Widget insideIcon = EventIcons(
        message: e.event!,
        themeProvider: _themeProvider,
      );

      IndicatorStyle iconBubble = IndicatorStyle(
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
          ),
          child: insideIcon,
        ),
      );

      final eventTime = DateTime.fromMillisecondsSinceEpoch(e.timestamp! * 1000);

      final event = TimelineTile(
        isFirst: loopCount == 1,
        isLast: loopCount == maxCount,
        alignment: TimelineAlign.manual,
        indicatorStyle: iconBubble,
        lineXY: 0.25,
        endChild: Container(
          padding: const EdgeInsets.all(8.0),
          child: messageWidget,
        ),
        startChild: Container(
          padding: const EdgeInsets.only(right: 5.0),
          child: Text(
            _occurrenceTimeFormatted(eventTime),
            style: TextStyle(
              fontSize: 11,
              fontWeight: fontWeight,
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
            style: const TextStyle(
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
        theme: ExpandableThemeData(iconColor: _themeProvider!.mainText),
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              const Text(
                'EVENTS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onLongPress: () {
                  _launchBrowser(url: "https://www.torn.com/events.php#/step=all", shortTap: false);
                },
                onTap: () {
                  _launchBrowser(url: 'https://www.torn.com/events.php#/step=all', shortTap: true);
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Icon(Icons.open_in_new, size: 18),
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
    int? maxToShow = _messagesShowNumber;

    // Some users might an empty messages map. This is why we have the events parameters as dynamic
    // in OwnProfile Model. We need to check if it contains several elements, in which case we
    // create a map in a new variable. Otherwise, we return an empty Card.
    var messages = <String, TornMessage>{};
    if (_user!.messages.length > 0) {
      messages = Map.from(_user!.messages).map((k, v) => MapEntry<String, TornMessage>(k, TornMessage.fromJson(v)));
    } else {
      return const Card(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    'MESSAGES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(25, 5, 20, 20),
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

    final timeline = <Widget>[];

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
    int? maxCount;

    if (messages.length > maxToShow!) {
      maxCount = maxToShow;
    } else {
      maxCount = messages.length;
      maxToShow = messages.length;
    }

    for (var i = 0; i < maxToShow; i++) {
      final msg = messages.values.elementAt(i);

      if (msg.read == 0) {
        unreadRecentCount++;
      }

      // This is important, as title is dynamic (for some reason, Torn API return
      // and int if the title is only a number...
      if (msg.title is int) {
        msg.title = msg.title.toString();
      }

      final String title = msg.title;
      final Widget insideIcon = _messagesInsideIconCases(msg.type!);

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
          ),
          child: insideIcon,
        ),
      );

      final messageTime = DateTime.fromMillisecondsSinceEpoch(msg.timestamp! * 1000);

      final messageRow = TimelineTile(
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
                        msg.name ?? "Torn Staff", // Torn staff might send messages with null sender!
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontStyle: msg.name == null ? FontStyle.italic : FontStyle.normal),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (msg.read == 0)
                  GestureDetector(
                    child: Icon(Icons.markunread, color: Colors.green[600]),
                    onLongPress: () {
                      _launchBrowser(
                        url: "https://www.torn.com/messages.php#/p=read&ID="
                            "${messages.keys.elementAt(i)}&suffix=inbox",
                        shortTap: false,
                      );
                    },
                    onTap: () {
                      _launchBrowser(
                        url: "https://www.torn.com/messages.php#/p=read&ID="
                            "${messages.keys.elementAt(i)}&suffix=inbox",
                        shortTap: true,
                      );
                    },
                  )
                else
                  GestureDetector(
                    child: const Icon(Icons.mark_as_unread),
                    onLongPress: () {
                      _launchBrowser(
                        url: "https://www.torn.com/messages.php#/p=read&ID="
                            "${messages.keys.elementAt(i)}&suffix=inbox",
                        shortTap: false,
                      );
                    },
                    onTap: () {
                      _launchBrowser(
                        url: "https://www.torn.com/messages.php#/p=read&ID="
                            "${messages.keys.elementAt(i)}&suffix=inbox",
                        shortTap: true,
                      );
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
            style: const TextStyle(
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
    final lastMessageDate = DateTime.fromMillisecondsSinceEpoch(messages.values.last.timestamp! * 1000);
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
        theme: ExpandableThemeData(iconColor: _themeProvider!.mainText),
        controller: _messagesExpController,
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              const Text(
                'MESSAGES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onLongPress: () {
                  _launchBrowser(url: "https://www.torn.com/messages.php", shortTap: false);
                },
                onTap: () {
                  _launchBrowser(url: "https://www.torn.com/messages.php", shortTap: true);
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 5),
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
              const SizedBox(height: 4),
              if (unreadTotalCount > 0 && unreadTotalCount > unreadRecentCount)
                Text(
                  unreadTotalString,
                  style: const TextStyle(
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
        child: const Center(
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
    final timeDifference = _serverTime.difference(occurrenceTime);
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
    final decimalFormat = NumberFormat("#,##0", "en_US");

    // Strength modifiers
    bool strengthModified = false;
    Color strengthColor = Colors.white;
    int strengthModifier = 0;
    double strengthModifiedTotal = _miscModel!.strength!.toDouble();
    String strengthString = '';
    for (final strengthMod in _miscModel!.strengthInfo!) {
      final RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      final matches = strRaw.allMatches(strengthMod);
      if (matches.isNotEmpty) {
        strengthModified = true;
        for (final match in matches) {
          final change = match.group(2);
          if (match.group(1) == '-') {
            strengthModifier -= int.parse(change!);
          } else if (match.group(1) == '+') {
            strengthModifier += int.parse(change!);
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
    double defenseModifiedTotal = _miscModel!.defense!.toDouble();
    String defenseString = '';
    for (final defenseMod in _miscModel!.defenseInfo!) {
      final RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      final matches = strRaw.allMatches(defenseMod);
      if (matches.isNotEmpty) {
        defenseModified = true;
        for (final match in matches) {
          final change = match.group(2);
          if (match.group(1) == '-') {
            defenseModifier -= int.parse(change!);
          } else if (match.group(1) == '+') {
            defenseModifier += int.parse(change!);
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
    double speedModifiedTotal = _miscModel!.speed!.toDouble();
    String speedString = '';
    for (final speedMod in _miscModel!.speedInfo!) {
      final RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      final matches = strRaw.allMatches(speedMod);
      if (matches.isNotEmpty) {
        speedModified = true;
        for (final match in matches) {
          final change = match.group(2);
          if (match.group(1) == '-') {
            speedModifier -= int.parse(change!);
          } else if (match.group(1) == '+') {
            speedModifier += int.parse(change!);
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
    double dexModifiedTotal = _miscModel!.dexterity!.toDouble();
    String dexString = '';
    for (final dexMod in _miscModel!.dexterityInfo!) {
      final RegExp strRaw = RegExp(r"(\+|\-)([0-9]+)(%)");
      final matches = strRaw.allMatches(dexMod);
      if (matches.isNotEmpty) {
        dexModified = true;
        for (final match in matches) {
          final change = match.group(2);
          if (match.group(1) == '-') {
            dexModifier -= int.parse(change!);
          } else if (match.group(1) == '+') {
            dexModifier += int.parse(change!);
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

    final double totalEffective = strengthModifiedTotal + speedModifiedTotal + defenseModifiedTotal + dexModifiedTotal;

    final int totalEffectiveModifier = ((totalEffective - _miscModel!.total!) * 100 / _miscModel!.total!).round();

    // SKILLS
    bool skillsExist = false;
    bool crimesExist = false;

    var hunting = "";
    var racing = "";
    var reviving = "";
    var searchForCash = "";
    var bootlegging = "";
    var pickpocketing = "";
    var graffiti = "";
    var burglary = "";
    var shoplifting = "";
    var cardSkimming = "";
    var hustling = "";
    var disposal = "";
    var cracking = "";
    var forgery = "";
    var scamming = "";
    hunting = _miscModel!.hunting ?? "";
    racing = _miscModel!.racing ?? "";
    reviving = _miscModel!.reviving ?? "";
    searchForCash = _miscModel!.searchForCash ?? "";
    bootlegging = _miscModel!.bootlegging ?? "";
    pickpocketing = _miscModel!.pickpocketing ?? "";
    graffiti = _miscModel!.graffiti ?? "";
    burglary = _miscModel!.burglary ?? "";
    shoplifting = _miscModel!.shoplifting ?? "";
    cardSkimming = _miscModel!.cardSkimming ?? "";
    hustling = _miscModel!.hustling ?? "";
    disposal = _miscModel!.disposal ?? "";
    cracking = _miscModel!.cracking ?? "";
    forgery = _miscModel!.forgery ?? "";
    scamming = _miscModel!.scamming ?? "";

    if (searchForCash.isNotEmpty ||
        bootlegging.isNotEmpty ||
        pickpocketing.isNotEmpty ||
        graffiti.isNotEmpty ||
        burglary.isNotEmpty ||
        shoplifting.isNotEmpty ||
        cardSkimming.isNotEmpty ||
        hustling.isNotEmpty ||
        disposal.isNotEmpty ||
        cracking.isNotEmpty ||
        forgery.isNotEmpty ||
        scamming.isNotEmpty) {
      crimesExist = true;
    }

    if (hunting.isNotEmpty || racing.isNotEmpty || reviving.isNotEmpty || crimesExist) {
      skillsExist = true;
    }

    _sharedEffStrength = 'Strength: ${decimalFormat.format(strengthModifiedTotal)} $strengthString';
    _sharedEffDefense = 'Defense: ${decimalFormat.format(defenseModifiedTotal)} $defenseString';
    _sharedEffSpeed = 'Speed: ${decimalFormat.format(speedModifiedTotal)} $speedString';
    _sharedEffDexterity = 'Dexterity: ${decimalFormat.format(dexModifiedTotal)} $dexString';
    _sharedEffTotal = 'Total: ${decimalFormat.format(totalEffective)}';

    return Card(
      child: Builder(builder: (context) {
        return ExpandablePanel(
          theme: ExpandableThemeData(iconColor: _themeProvider!.mainText),
          controller: _basicInfoExpController,
          header: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                const Text(
                  'BASIC INFO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  child: const Icon(Icons.copy, size: 14),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        _launchBrowser(url: 'https://www.torn.com/points.php', shortTap: false);
                      },
                      onTap: () async {
                        _launchBrowser(url: 'https://www.torn.com/points.php', shortTap: true);
                      },
                      child: Icon(
                        MdiIcons.alphaPCircleOutline,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('${_miscModel!.points}'),
                  ],
                ),
                const SizedBox(height: 4),
                _jobPoints(),
                const SizedBox(height: 4),
                _companyAddictionWidget(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: SelectableText(
                        'Battle Stats (eff.): ${decimalFormat.format(totalEffective)}',
                      ),
                    ),
                    if (totalEffectiveModifier < 0)
                      Text(
                        ' ($totalEffectiveModifier%)',
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      )
                    else if (totalEffectiveModifier > 0)
                      Text(
                        ' (+$totalEffectiveModifier%)',
                        style: const TextStyle(
                          color: Colors.green,
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 2),
                SelectableText('Battle Stats: ${decimalFormat.format(_miscModel!.total)}'),
                if (_settingsProvider!.tornStatsChartEnabled && _settingsProvider!.tornStatsChartInCollapsedMiscCard)
                  FutureBuilder(
                    future: _statsChartDataFetched,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (_statsChartModel?.data != null) {
                          return Column(
                            children: [
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 200,
                                child: StatsChart(
                                  statsData: _statsChartModel,
                                  chartType: _settingsProvider!.tornStatsChartType == "line"
                                      ? TornStatsChartType.Line
                                      : TornStatsChartType.Pie,
                                  userController: _u,
                                  callbackStatsUpdate: _getStatsChart,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        }
                      }
                      return const SizedBox(height: 8);
                    },
                  )
                else
                  const SizedBox(height: 8),
                SelectableText('MAN: ${decimalFormat.format(_miscModel!.manualLabor)}'),
                SelectableText('INT: ${decimalFormat.format(_miscModel!.intelligence)}'),
                SelectableText('END: ${decimalFormat.format(_miscModel!.endurance)}'),
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
                      SelectableText('Rank: ${_user!.rank}'),
                      SelectableText('Age: ${_user!.age}'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                          _launchBrowser(url: 'https://www.torn.com/points.php', shortTap: false);
                        },
                        onTap: () async {
                          _launchBrowser(url: 'https://www.torn.com/points.php', shortTap: true);
                        },
                        child: Icon(
                          MdiIcons.alphaPCircleOutline,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 5),
                      SelectableText('${_miscModel!.points}'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _jobPoints(),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _companyAddictionWidget(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Text(
                        'EFFECTIVE STATS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        child: const Icon(Icons.copy, size: 14),
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
                          const SizedBox(
                            width: 80,
                            child: Text('Strength: '),
                          ),
                          SelectableText(decimalFormat.format(strengthModifiedTotal)),
                          if (strengthModified)
                            Text(
                              " $strengthString",
                              style: TextStyle(color: strengthColor, fontSize: 12),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Defense: '),
                          ),
                          SelectableText(decimalFormat.format(defenseModifiedTotal)),
                          if (defenseModified)
                            Text(
                              " $defenseString",
                              style: TextStyle(color: defenseColor, fontSize: 12),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Speed: '),
                          ),
                          SelectableText(decimalFormat.format(speedModifiedTotal)),
                          if (speedModified)
                            Text(
                              " $speedString",
                              style: TextStyle(color: speedColor, fontSize: 12),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Dexterity: '),
                          ),
                          SelectableText(decimalFormat.format(dexModifiedTotal)),
                          if (dexModified)
                            Text(
                              " $dexString",
                              style: TextStyle(color: dexColor, fontSize: 12),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                      SizedBox(
                        width: 50,
                        child: Divider(color: _themeProvider!.mainText, thickness: 0.5),
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'Total: ',
                            ),
                          ),
                          SelectableText(
                            decimalFormat.format(totalEffective),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Text(
                        'BATTLE STATS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        child: const Icon(Icons.copy, size: 14),
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
                          const SizedBox(
                            width: 80,
                            child: Text('Strength: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.strength)),
                          Text(
                            " (${decimalFormat.format(_miscModel!.strength! * 100 / _miscModel!.total!)}%)",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Defense: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.defense)),
                          Text(
                            " (${decimalFormat.format(_miscModel!.defense! * 100 / _miscModel!.total!)}%)",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Speed: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.speed)),
                          Text(
                            " (${decimalFormat.format(_miscModel!.speed! * 100 / _miscModel!.total!)}%)",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Dexterity: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.dexterity)),
                          Text(
                            " (${decimalFormat.format(_miscModel!.dexterity! * 100 / _miscModel!.total!)}%)",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 50,
                        child: Divider(color: _themeProvider!.mainText, thickness: 0.5),
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Total: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.total)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_settingsProvider!.tornStatsChartEnabled)
                  FutureBuilder(
                    future: _statsChartDataFetched,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (_statsChartModel?.data != null) {
                          return Column(
                            children: [
                              const SizedBox(height: 40),
                              SizedBox(
                                height: 200,
                                child: StatsChart(
                                  statsData: _statsChartModel,
                                  chartType: _settingsProvider!.tornStatsChartType == "line"
                                      ? TornStatsChartType.Line
                                      : TornStatsChartType.Pie,
                                  userController: _u,
                                  callbackStatsUpdate: _getStatsChart,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        }
                      }
                      return const SizedBox(height: 20);
                    },
                  )
                else
                  const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Text(
                        'WORK STATS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        child: const Icon(Icons.copy, size: 14),
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
                          const SizedBox(
                            width: 100,
                            child: Text('Manual labor: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.manualLabor)),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text('Intelligence: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.intelligence)),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text('Endurance: '),
                          ),
                          SelectableText(decimalFormat.format(_miscModel!.endurance)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (skillsExist)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            const Text(
                              'SKILLS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              child: const Icon(Icons.copy, size: 14),
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
                                  const SizedBox(
                                    width: 80,
                                    child: Text('Racing: '),
                                  ),
                                  SelectableText(racing),
                                ],
                              ),
                            if (reviving.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 80,
                                    child: Text('Reviving: '),
                                  ),
                                  SelectableText(reviving),
                                ],
                              ),
                            if (hunting.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 80,
                                    child: Text('Hunting: '),
                                  ),
                                  SelectableText(hunting),
                                ],
                              ),
                            if (crimesExist)
                              if (searchForCash.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                  child: Text(
                                    'CRIMES',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 130,
                                  child: Text('Search for Cash: '),
                                ),
                                SelectableText(searchForCash),
                              ],
                            ),
                            if (bootlegging.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Bootlegging: '),
                                  ),
                                  SelectableText(bootlegging),
                                ],
                              ),
                            if (graffiti.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Graffiti: '),
                                  ),
                                  SelectableText(graffiti),
                                ],
                              ),
                            if (shoplifting.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Shoplifting: '),
                                  ),
                                  SelectableText(shoplifting),
                                ],
                              ),
                            if (pickpocketing.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Pickpocketing: '),
                                  ),
                                  SelectableText(pickpocketing),
                                ],
                              ),
                            if (cardSkimming.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Card Skimming: '),
                                  ),
                                  SelectableText(cardSkimming),
                                ],
                              ),
                            if (burglary.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Burglary: '),
                                  ),
                                  SelectableText(burglary),
                                ],
                              ),
                            if (hustling.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Hustling: '),
                                  ),
                                  SelectableText(hustling),
                                ],
                              ),
                            if (disposal.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Disposal: '),
                                  ),
                                  SelectableText(disposal),
                                ],
                              ),
                            if (cracking.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Cracking: '),
                                  ),
                                  SelectableText(cracking),
                                ],
                              ),
                            if (forgery.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Forgery: '),
                                  ),
                                  SelectableText(forgery),
                                ],
                              ),
                            if (scamming.isNotEmpty)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 130,
                                    child: Text('Scamming: '),
                                  ),
                                  SelectableText(scamming),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _cashWallet({bool? dense}) {
    if (_user!.moneyOnHand != null) {
      final moneyFormat = NumberFormat("#,##0", "en_US");
      return Row(
        children: [
          GestureDetector(
            onTap: () async {
              _openWalletDialog();
            },
            child: dense!
                ? const Icon(Icons.account_balance_wallet_rounded, size: 17, color: Colors.brown)
                : Icon(
                    MdiIcons.cash100,
                    color: Colors.green,
                  ),
          ),
          const SizedBox(width: 5),
          SelectableText(
            '\$${moneyFormat.format(_user!.moneyOnHand)}',
            style: TextStyle(
              fontSize: dense ? 13 : 14,
              fontWeight: dense ? FontWeight.bold : FontWeight.normal,
              color: dense ? Colors.green : _themeProvider!.mainText,
            ),
          )
        ],
      );
    } else {
      return const SizedBox.shrink();
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

    if (_miscModel == null) {
      return const SizedBox.shrink();
    }

    // ADDICTION
    Widget addictionWidget = const SizedBox.shrink();
    if (_user!.icons.icon57 != null ||
        _user!.icons.icon58 != null ||
        _user!.icons.icon59 != null ||
        _user!.icons.icon60 != null ||
        _user!.icons.icon61 != null) {
      showMisc = true;
      addictionActive = true;
      String? addictionString;
      Color? brainColor;
      if (_user!.icons.icon57 != null) {
        addictionString = _user!.icons.icon57;
        brainColor = Colors.grey;
      } else if (_user!.icons.icon58 != null) {
        addictionString = _user!.icons.icon58;
        brainColor = Colors.brown[300];
      } else if (_user!.icons.icon59 != null) {
        addictionString = _user!.icons.icon59;
        brainColor = Colors.deepOrange[700];
      } else if (_user!.icons.icon60 != null) {
        addictionString = _user!.icons.icon60;
        brainColor = Colors.amber[900];
      } else if (_user!.icons.icon61 != null) {
        addictionString = _user!.icons.icon61;
        brainColor = Colors.red[600];
      }

      addictionWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.brain, color: brainColor),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              addictionString!,
              style: DefaultTextStyle.of(context).style,
            ),
          ),
        ],
      );
    }

    // RACING
    Widget racingWidget = const SizedBox.shrink();
    if (_user!.icons.icon17 != null || _user!.icons.icon18 != null) {
      showMisc = true;
      racingActive = true;
      String? racingString;
      Color? gaugeColor;
      DateTime? raceStartTime;

      if (_user!.icons.icon17 != null) {
        raceStartTime = _parseRaceTime(_user!.icons.icon17);
        racingString = _user!.icons.icon17.replaceAll("Racing - ", "");
        racingString = racingString!.replaceAll("0 days, 0 hours,", "");
        racingString = racingString.replaceAll("0 days,", "");
        gaugeColor = Colors.green[700];
      } else if (_user!.icons.icon18 != null) {
        racingString = _user!.icons.icon18.replaceAll("Racing - ", '');
        gaugeColor = Colors.red[700];
      }

      racingWidget = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Row(
              children: [
                Icon(MdiIcons.gauge, color: gaugeColor),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    racingString!,
                    style: DefaultTextStyle.of(context).style,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onLongPress: () {
                  _launchBrowser(url: 'https://www.torn.com/loader.php?sid=racing', shortTap: false);
                },
                onTap: () {
                  _launchBrowser(url: 'https://www.torn.com/loader.php?sid=racing', shortTap: true);
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(MdiIcons.openInApp, size: 24),
                ),
              ),
            ],
          ),
          if (raceStartTime != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onLongPress: () {
                  _launchBrowser(url: 'https://www.torn.com/loader.php?sid=racing', shortTap: false);
                },
                onTap: () {
                  _launchBrowser(url: 'https://www.torn.com/loader.php?sid=racing', shortTap: true);
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: _notificationIcon(ProfileNotification.raceStart),
                ),
              ),
            ),
        ],
      );
    }

    // FACTION CRIMES
    var factionCrimesActive = false;
    Widget factionCrimes = const SizedBox.shrink();
    if (_ocFinalStringLong.isNotEmpty) {
      factionCrimesActive = true;
      factionCrimes = Row(
        children: [
          Icon(MdiIcons.fingerprint),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _ocFinalStringLong,
              style: TextStyle(
                color: _ocComplexReady
                    ? _ocComplexPeopleNotReady == 0
                        ? Colors.green
                        : Colors.orange[700]
                    : _themeProvider!.mainText,
              ),
            ),
          ),
          if (_ocComplexReady)
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onLongPress: () {
                _launchBrowser(url: "https://www.torn.com/factions.php?step=your#/tab=crimes", shortTap: false);
              },
              onTap: () {
                _launchBrowser(url: 'https://www.torn.com/factions.php?step=your#/tab=crimes', shortTap: true);
              },
              child: Padding(
                padding: EdgeInsets.only(right: 5),
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
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _ocSimpleStringFinal,
              style: TextStyle(color: _ocSimpleReady ? Colors.orange[700] : _themeProvider!.mainText),
            ),
          ),
          if (_ocComplexReady)
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onLongPress: () {
                _launchBrowser(url: "https://www.torn.com/factions.php?step=your#/tab=crimes", shortTap: false);
              },
              onTap: () {
                _launchBrowser(url: 'https://www.torn.com/factions.php?step=your#/tab=crimes', shortTap: true);
              },
              child: Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(MdiIcons.openInApp, size: 18),
              ),
            ),
          GestureDetector(
            child: Icon(
              MdiIcons.closeCircleOutline,
              size: 16,
              color: _ocSimpleReady ? Colors.orange[700] : _themeProvider!.mainText,
            ),
            onTap: () {
              showDialog(
                useRootNavigator: false,
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
    Widget bankWidget = const SizedBox.shrink();
    if (_miscModel!.cityBank!.timeLeft! > 0) {
      showMisc = true;
      bankActive = true;
      final moneyFormat = NumberFormat("#,##0", "en_US");
      final timeExpiry = DateTime.now().add(Duration(seconds: _miscModel!.cityBank!.timeLeft!));
      final timeDifference = timeExpiry.difference(DateTime.now());
      Color? expiryColor = Colors.orange[800];
      String expiryString;
      if (timeDifference.inHours < 1) {
        expiryString = 'less than an hour';
      } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
        expiryString = 'about an hour';
      } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
        expiryString = '${timeDifference.inHours} hours';
      } else if (timeDifference.inDays == 1) {
        expiryString = '1 day and ${(_miscModel!.cityBank!.timeLeft! / 60 / 60 % 24).floor()} hours';
        expiryColor = _themeProvider!.mainText;
      } else {
        expiryString =
            '${timeDifference.inDays} days and ${(_miscModel!.cityBank!.timeLeft! / 60 / 60 % 24).floor()} hours';
        expiryColor = _themeProvider!.mainText;
      }

      bankWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.bankOutline),
          const SizedBox(width: 10),
          Flexible(
            child: RichText(
              text: TextSpan(
                text: "Your bank investment of ",
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: "\$${moneyFormat.format(_miscModel!.cityBank!.amount)}",
                    style: const TextStyle(
                      color: Colors.green,
                    ),
                  ),
                  const TextSpan(text: " will expire in "),
                  TextSpan(
                    text: expiryString,
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
    Widget educationWidget = const SizedBox.shrink();
    if (_tornEducationModel is TornEducationModel) {
      if (_miscModel!.educationTimeleft! > 0) {
        showMisc = true;
        educationActive = true;
        final timeExpiry = DateTime.now().add(Duration(seconds: _miscModel!.educationTimeleft!));
        final timeDifference = timeExpiry.difference(DateTime.now());
        Color? expiryColor = Colors.orange[800];
        String expiryString;
        if (timeDifference.inHours < 1) {
          expiryString = 'less than an hour';
        } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
          expiryString = 'about an hour';
        } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
          expiryString = '${timeDifference.inHours} hours';
        } else if (timeDifference.inDays == 1) {
          expiryString = '1 day';
          expiryColor = _themeProvider!.mainText;
        } else {
          expiryString = '${timeDifference.inDays} days';
          expiryColor = _themeProvider!.mainText;
        }

        String? courseName;
        _tornEducationModel!.education.forEach((key, value) {
          if (key == _miscModel!.educationCurrent.toString()) {
            courseName = value.name;
          }
        });

        educationWidget = Row(
          children: <Widget>[
            Icon(MdiIcons.schoolOutline),
            const SizedBox(width: 10),
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
                    const TextSpan(text: ", will end in "),
                    TextSpan(
                      text: expiryString,
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
        if (_miscModel!.educationCompleted!.length < _tornEducationModel!.education.length - 1) {
          showMisc = true;
          educationActive = true;
          educationWidget = Row(
            children: <Widget>[
              Icon(MdiIcons.schoolOutline),
              const SizedBox(width: 10),
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
    }

    // PROPERTIES
    if (_rentedProperties > 0) {
      showMisc = true;
      propertyActive = true;
    }

    // DONATOR
    Widget donatorWidget = const SizedBox.shrink();
    if (_user!.icons.icon3 != null || _user!.icons.icon4 != null) {
      showMisc = true;
      donatorActive = true;
      String? donatorString;

      if (_user!.icons.icon3 != null) {
        donatorString = _user!.icons.icon3;
      } else if (_user!.icons.icon4 != null) {
        donatorString = _user!.icons.icon4.replaceAll("Subscriber - Donator status:", "Donator:");
        donatorString = donatorString!.replaceAll("Donator status:", "Donator:");
      }

      donatorWidget = Row(
        children: <Widget>[
          Icon(MdiIcons.starOutline),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              donatorString!,
              style: DefaultTextStyle.of(context).style,
            ),
          ),
        ],
      );
    }

    if (!showMisc) {
      return const SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
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
    final moneyFormat = NumberFormat("#,##0", "en_US");

    // Total when folded
    int? total;
    for (final v in _user!.networth!.entries) {
      if (v.key == 'total') {
        total = v.value!.round();
      }
    }

    // List for all sources in column
    final moneySources = <Widget>[];
    final moneyQuantities = <Widget>[];

    final timestamp = DateTime.fromMillisecondsSinceEpoch(_user!.networth!['timestamp']!.round() * 1000);
    final formattedTimestamp = TimeFormatter(
            inputTime: timestamp,
            timeFormatSetting: _settingsProvider!.currentTimeFormat,
            timeZoneSetting: _settingsProvider!.currentTimeZone)
        .formatHourWithDaysElapsed(includeYesterday: true);

    // Loop all other sources
    for (final v in _user!.networth!.entries) {
      String source;
      if (v.key == 'total' || v.key == 'parsetime' || v.key == 'timestamp') {
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

      Widget pointsPrice = SizedBox.shrink();
      if (v.key == "points" && _miscModel != null && _miscModel!.points! > 0) {
        String price = formatBigNumbers(((v.value!.round()) / _miscModel!.points!).round());

        pointsPrice = Text(
          " @ \$$price",
          style: const TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        );
      }

      moneySources.add(
        SizedBox(
          width: 150,
          child: Row(
            children: [
              Text(source),
              pointsPrice,
            ],
          ),
        ),
      );

      moneyQuantities.add(
        Text(
          '\$${moneyFormat.format(v.value!.round())}',
          style: TextStyle(
            color: v.value! < 0 ? Colors.red : Colors.green,
          ),
        ),
      );
    }

    // Total Expanded
    Widget expandedNetworth = Padding(
      padding: const EdgeInsets.only(left: 25, top: 10, bottom: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              ...moneySources,
              SizedBox(height: 10),
              Text('Updated at: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ))
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${moneyFormat.format(total)}',
                style: TextStyle(
                  color: total! < 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              ...moneyQuantities,
              SizedBox(height: 10),
              Text(
                formattedTimestamp,
                style: TextStyle(
                  color: _themeProvider!.mainText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      child: ExpandablePanel(
        theme: ExpandableThemeData(iconColor: _themeProvider!.mainText),
        controller: _networthExpController,
        header: const Padding(
          padding: EdgeInsets.all(15.0),
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
            '\$${moneyFormat.format(total)} (updated $formattedTimestamp)',
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: total <= 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        expanded: expandedNetworth,
      ),
    );
  }

  Future<void> _fetchApi() async {
    if (!mounted) return;

    // Try to get only as many messages as strictly necessary, as per Torn recommendations
    var limit = 3;
    if (_messagesShowNumber! > limit) limit = _messagesShowNumber!;
    if (_eventsShowNumber! > limit) limit = _eventsShowNumber!;

    final apiResponse = await ApiCallsV1.getOwnProfileExtended(limit: limit);

    // Try to get the chain from the ChainStatusProvider if it's running (to save calls)
    // Otherwise, call the API
    dynamic chain;

    if (_chainProvider.chainModel is ChainModel) {
      chain = _chainProvider.chainModel;
    } else {
      chain = await ApiCallsV1.getChainStatus();
    }

    if (mounted) {
      setState(() {
        if (apiResponse is OwnProfileExtended) {
          _apiRetries = 0;
          _user = apiResponse;
          _serverTime = DateTime.fromMillisecondsSinceEpoch(_user!.serverTime! * 1000);
          _apiGoodData = true;

          // If max values have decreased or were never initialized
          if (_customEnergyTrigger! > _user!.energy!.maximum! || _customEnergyTrigger == 0) {
            _customEnergyTrigger = _user!.energy!.maximum;
            Prefs().setEnergyNotificationValue(_customEnergyTrigger!);
          }
          if (_customNerveTrigger! > _user!.nerve!.maximum! || _customNerveTrigger == 0) {
            _customNerveTrigger = _user!.nerve!.maximum;
            Prefs().setNerveNotificationValue(_customNerveTrigger!);
          }

          if (chain is ChainModel) {
            _chainModel = chain;
          } else {
            // Default to empty chain, with all parameters at 0
            _chainModel = ChainModel();
            _chainModel.chain = ChainDetails();
          }

          if (apiResponse.status != null && apiResponse.travel != null) {
            _chainProvider.statusUpdateSource = "profile";
            _chainProvider.updatePlayerStatusColor(
              apiResponse.status!.color!,
              apiResponse.status!.state!,
              apiResponse.status!.until!,
              apiResponse.travel!.timestamp!,
            );
          }

          _checkIfNotificationsAreCurrent();
        } else {
          if (_apiGoodData && _apiRetries < 8) {
            _apiRetries++;
          } else {
            _apiGoodData = false;
            _apiError = apiResponse as ApiError?;
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
    //  - (async) RankedWars
    if (_apiGoodData && !_miscApiFetchedOnce) {
      await _getMiscCardInfo();
      _statsChartDataFetched = _getStatsChart();
      _getRankedWars();
      _getCompanyAddiction();
      _refreshEvents();
    }

    _retrievePendingNotifications();
  }

  Future _getMiscCardInfo({bool forcedUpdate = false}) async {
    if (_user == null) return;

    try {
      dynamic miscApiResponse;

      // 1.- Try first with API V2
      miscApiResponse = await ApiCallsV2.getUserProfileMisc_v2();

      // 2.- Try to fall back to API V1
      if (miscApiResponse is! OwnProfileMisc) {
        miscApiResponse = await ApiCallsV1.getOwnProfileMisc();
      }

      if (miscApiResponse is! OwnProfileMisc) {
        return;
      }

      // Get Education
      var education = await ApiCallsV1.getEducation();
      if (education != null) {
        _tornEducationModel = education;
      }

      // Get Market Items V2
      var marketItems = await _getUserMarketItems();
      if (marketItems != null) {
        _marketItemsV2 = marketItems;
      }

      // Get this async
      if (_settingsProvider!.oCrimesEnabled) {
        _getFactionCrimes();
      }

      _checkProperties(miscApiResponse, forcedUpdate);

      setState(() {
        _miscModel = miscApiResponse;
        _miscApiFetchedOnce = true;
      });
    } catch (e) {
      // If something fails, we simple don't show the MISC section
    }
  }

  Future<dynamic> _getUserMarketItems() async {
    try {
      return await ApiCallsV2.getUserMarketItemsApi_v2();
    } catch (e, t) {
      log("Issue getting market items: $e, $t");
    }
  }

  Future _getStatsChart() async {
    try {
      if (!_settingsProvider!.tornStatsChartEnabled) return;

      final DateTime lastFetched = DateTime.fromMillisecondsSinceEpoch(_settingsProvider!.tornStatsChartDateTime);

      if (DateTime.now().difference(lastFetched).inHours < 26) {
        final savedChart = await Prefs().getTornStatsChartSave();
        if (savedChart.isNotEmpty) {
          setState(() {
            _statsChartModel = statsChartTornStatsFromJson(savedChart);
          });
          return;
        }
      }

      final String tornStatsURL = 'https://www.tornstats.com/api/v1/${_u.alternativeTornStatsKey}/battlestats/graph';
      final resp = await http.get(Uri.parse(tornStatsURL)).timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200) {
        final StatsChartTornStats statsJson = statsChartTornStatsFromJson(resp.body);
        if (!statsJson.message!.contains("ERROR")) {
          setState(() {
            _statsChartModel = statsJson;
          });

          Prefs().setTornStatsChartSave(resp.body);
          _settingsProvider!.setTornStatsChartDateTime = DateTime.now().millisecondsSinceEpoch;
        }
      }
    } catch (e) {
      // Returns null
    }
  }

  Future _getRankedWars() async {
    if (_user == null) return;

    // DEBUG #####
    /*
    // Create a fake ranked war to check time parameters
    if (kDebugMode) {
      RankedWar debugWar = RankedWar(
        factions: {
          _user!.faction!.factionId.toString(): WarFaction()
            ..chain = 0
            ..name = _user!.faction!.factionName
            ..score = 0,
          _user!.faction!.factionId.toString(): WarFaction()
            ..chain = 0
            ..name = _user!.faction!.factionName
            ..score = 0,
        },
        war: War(
          start: (DateTime(2024, 4, 2, 20, 0).millisecondsSinceEpoch / 1000).round(),
          end: 0,
          target: 2000,
          winner: 0,
        ),
      );
      setState(() {
        _factionRankedWar = debugWar;
      });
      return;
    }
    */
    // DEBUG ENDS #####

    try {
      if (_user!.faction!.factionId == 0) return;
      if (!_settingsProvider!.rankedWarsInProfile) return;

      final dynamic apiResponse = await ApiCallsV1.getRankedWars();
      if (apiResponse is RankedWarsModel) {
        for (final warMap in apiResponse.rankedwars!.entries) {
          if (warMap.value.factions!.keys.contains(_user!.faction!.factionId.toString())) {
            final int ts = DateTime.now().millisecondsSinceEpoch;
            final bool warInFuture = warMap.value.war!.start! * 1000 > ts;
            final bool warActive = warMap.value.war!.start! < ts && warMap.value.war!.end == 0;
            if (warInFuture || warActive) {
              setState(() {
                _factionRankedWar = warMap.value;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      // Returns null
    }
    _factionRankedWar = null;
    return;
  }

  Future _getCompanyAddiction() async {
    if (_user == null) return;

    try {
      if (_user!.job!.companyId == 0) return;

      final nextFetchTime = await Prefs().getJobAddictionNextCallTime();

      final int currentTimeMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
      final bool shouldCallApi = currentTimeMillis >= nextFetchTime;

      // If we should call the API, fetch the data and update SharedPreferences
      if (shouldCallApi || nextFetchTime == 0) {
        log("Fetching job addiction!");
        final dynamic apiResponse = await ApiCallsV1.getCompanyEmployees();
        if (apiResponse is CompanyEmployees) {
          for (final eMap in apiResponse.companyEmployees!.entries) {
            // Loop until we find the user
            if (eMap.key != _user!.playerId.toString()) continue;

            // Calculate the next allowed API call time
            final DateTime now = DateTime.now().toUtc();
            DateTime nextAllowedTime = DateTime.utc(now.year, now.month, now.day, 18, 30);
            if (now.isAfter(nextAllowedTime)) {
              nextAllowedTime = nextAllowedTime.add(const Duration(days: 1));
            }
            final int nextAllowedTimeMillis = nextAllowedTime.millisecondsSinceEpoch;

            Prefs().setJobAddictionNextCallTime(nextAllowedTimeMillis);
            Prefs().setJobAdditionValue(eMap.value.effectiveness!.addiction ?? 0);
            setState(() {
              _companyAddiction = eMap.value.effectiveness!.addiction ?? 0;
            });
            return;
          }
        }
      } else {
        final int savedAddition = await Prefs().getJobAddictionValue();
        setState(() {
          _companyAddiction = savedAddition;
        });
      }
    } catch (e) {
      _companyAddiction = null;
      return;
    }
  }

  /// To be restrictive with API calls, we will only perform a full events update if > 30 minutes from last
  /// In between, we will only update new events from X timestamp
  Future _refreshEvents() async {
    try {
      // Get the saved events from shared prefs
      List<Event> eventsSave = <Event>[];
      List<String> save = await Prefs().getEventsSave();
      for (final s in save) {
        eventsSave.add(eventFromJson(s));
      }

      // Calculate time difference from last time we obtained events
      final DateTime lastEventsTs = DateTime.fromMillisecondsSinceEpoch(await Prefs().getEventsLastRetrieved());
      final int minutesDiff = DateTime.now().difference(lastEventsTs).inMinutes;

      // If less than 30 minutes have elapse, we'll just query for new events and fill the list
      if (minutesDiff < 30 && eventsSave.isNotEmpty) {
        // Get the last saved event, find out what's the TS
        if (eventsSave.isEmpty) return;
        int? lastTs = eventsSave[0].timestamp;

        // Get new events after that and add them
        final dynamic newEventsResponse = await ApiCallsV1.getEvents(limit: 100, from: lastTs);
        if (newEventsResponse is List<Event>) {
          if (newEventsResponse.isNotEmpty) {
            for (int i = 0; i < newEventsResponse.length; i++) {
              bool repeated = false;
              for (final Event inSave in eventsSave) {
                if (newEventsResponse[i].event == inSave.event && newEventsResponse[i].timestamp == inSave.timestamp) {
                  repeated = true;
                  break;
                }
              }
              // Avoid events repetition (even adding 1 ms to lastTs didn't help)
              if (!repeated) {
                eventsSave.insert(i, newEventsResponse[i]);
              }
            }

            List<String> eventsListToSave = [];
            for (final Event e in eventsSave) {
              eventsListToSave.add(eventToJson(e));
            }
            Prefs().setEventsSave(eventsListToSave);
          }
          // Save last retrieved date as now
          Prefs().setEventsLastRetrieved(DateTime.now().millisecondsSinceEpoch);
        }

        // Refresh events (even if no additions have been made, as we might be starting
        // the app with [_events] with a null value)
        if (mounted) {
          setState(() {
            _events = List<Event>.from(eventsSave);
          });
        }
        return;
      }

      // If more than 30 minutes elapsed, we get the whole pack
      // Calculate one month ago
      log("Events save elapse more than 30 minutes, getting all events");
      final int monthAgo = ((DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch) / 1000).ceil();
      final dynamic allEventsResponse = await ApiCallsV1.getEvents(limit: 100, from: monthAgo);
      if (allEventsResponse is List<Event>) {
        // Save events and last retrieved timestamp
        List<String> eventsListToSave = [];
        for (final Event e in allEventsResponse) {
          eventsListToSave.add(eventToJson(e));
        }
        Prefs().setEventsSave(eventsListToSave);
        Prefs().setEventsLastRetrieved(DateTime.now().millisecondsSinceEpoch);

        // Refresh events
        if (mounted) {
          setState(() {
            _events = List<Event>.from(allEventsResponse);
          });
        }
      } else {
        // In case of error, return what's saved
        if (mounted) {
          setState(() {
            _events = List<Event>.from(eventsSave);
          });
        }
      }
    } catch (e, trace) {
      logToUser("PDA Error at Profile Events: $e, $trace");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Profile Events");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }
  }

  Future<void> _getFactionCrimes() async {
    try {
      if (_user == null) return;
      final factionCrimes = await ApiCallsV1.getFactionCrimes(playerId: _user!.playerId.toString());

      // OPTION 1 - Check if we have faction access
      if (factionCrimes != null && factionCrimes is FactionCrimesModel) {
        String? complexString = "";
        DateTime complexTime = DateTime.now();

        // Get main crime and time
        factionCrimes.crimes!.forEach((key, crime) {
          if (crime.initiated == 0 && complexString!.isEmpty) {
            var participantsNotReady = 0;
            for (final participant in crime.participants!) {
              // There is only one participant, but in another map
              participant.forEach((key, values) {
                if (values?.description != "Okay") {
                  participantsNotReady++;
                }
              });

              if (participant.containsKey(_userProv!.basic!.playerId.toString())) {
                complexString = crime.crimeName;
                complexTime = DateTime.fromMillisecondsSinceEpoch(crime.timeReady! * 1000);
              }
            }

            // If found our crime, assign final number of participants not ready
            if (complexString!.isNotEmpty) _ocComplexPeopleNotReady = participantsNotReady;
          }
        });

        // Calculate time and final string for widgets
        if (complexString!.isNotEmpty) {
          bool complexReady = false;
          String complexTimeString = "";
          if (complexTime.isAfter(DateTime.now())) {
            final formattedTime = TimeFormatter(
              inputTime: complexTime,
              timeFormatSetting: _settingsProvider!.currentTimeFormat,
              timeZoneSetting: _settingsProvider!.currentTimeZone,
            ).formatHourWithDaysElapsed();
            complexTimeString =
                "OC will be ready @ $formattedTime${_timeFormatted(complexTime, previous: formattedTime)}";
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

          if (!mounted) return;

          setState(() {
            _ocFinalStringLong = "$complexString $complexTimeString";
            _ocFinalStringShort = complexTimeString;
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
            final formattedTime = TimeFormatter(
              inputTime: simpleTime,
              timeFormatSetting: _settingsProvider!.currentTimeFormat,
              timeZoneSetting: _settingsProvider!.currentTimeZone,
            ).formatHourWithDaysElapsed();
            simpleString = "A faction organized crime will be ready @ "
                "$formattedTime${_timeFormatted(simpleTime, previous: formattedTime)}";
          }
        }

        // Try to find quick crimes in events
        bool foundExpired = false;
        bool foundProgress = false;
        bool error = false;

        // Try to find our crime by reviewing the last 100 events. The first one we
        // can find is the one that counts
        for (final Event e in _events) {
          if (!foundExpired && !foundProgress && !error) {
            if (e.event!.contains("You and your team") ||
                (e.event!.contains("canceled the") && e.event!.contains("that you were selected for"))) {
              foundExpired = true;
            } else if (e.event!.contains("You have been selected")) {
              final RegExp strRaw = RegExp("([0-9]+) hours");
              final matches = strRaw.allMatches(e.event!);
              if (matches.isNotEmpty) {
                for (final match in matches) {
                  final hoursString = match.group(1)!;
                  try {
                    final hours = int.parse(hoursString);
                    simpleTime = DateTime.fromMillisecondsSinceEpoch(e.timestamp! * 1000).add(Duration(hours: hours));
                    foundProgress = true;
                    simpleExists = true;
                    _settingsProvider!.changeOCrimeLastKnown = simpleTime.millisecondsSinceEpoch;
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
        }

        // If we haven't found anything in 100 events (including no cancellations), but we are still
        // ahead of the last known planned OC crime time, perhaps we run out of events (some OC
        // take place after 8 days). If that's the case, show that one anyway.
        if (!foundProgress && !foundExpired && !error) {
          final lastKnown = DateTime.fromMillisecondsSinceEpoch(_settingsProvider!.oCrimeLastKnown);
          if (DateTime.now().isBefore(lastKnown)) {
            simpleExists = true;
            simpleTime = lastKnown;
            foundProgress = true;
            calculateSimpleReadiness();
          }
        }

        // Check if we were disregarding this crime before (in which case we don't show it)
        if (foundProgress) {
          if (_settingsProvider!.oCrimeDisregarded == simpleTime.millisecondsSinceEpoch) {
            simpleExists = false;
            _ocSimpleStringFinal = "";
          }
        }

        if (!mounted) return;

        setState(() {
          _ocSimpleExists = simpleExists;
          _ocSimpleReady = simpleReady;
          _ocSimpleStringFinal = simpleString;
          _ocTime = simpleTime;
        });
      }
    } catch (e) {
      // Don't fill anything
      log(e.toString());
    }
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      animationDuration: const Duration(),
      direction:
          MediaQuery.orientationOf(context) == Orientation.portrait ? SpeedDialDirection.up : SpeedDialDirection.left,
      backgroundColor: Colors.transparent,
      overlayColor: Colors.transparent,
      curve: Curves.bounceIn,
      overlayOpacity: 0,
      children: [
        SpeedDialChild(
          onTap: () async {
            // Trying to get rid of errors switching to the browser
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/city.php', shortTap: true);
          },
          onLongPress: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/city.php', shortTap: false);
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.purple[500],
        ),
        SpeedDialChild(
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/trade.php', shortTap: true);
          },
          onLongPress: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/trade.php', shortTap: false);
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.yellow[800],
        ),
        SpeedDialChild(
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/item.php', shortTap: true);
          },
          onLongPress: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/item.php', shortTap: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.blue[400],
          label: 'ITEMS',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.blue[400],
        ),
        SpeedDialChild(
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', shortTap: true);
          },
          onLongPress: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/crimes.php#/step=main', shortTap: false);
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.deepOrange[400],
        ),
        SpeedDialChild(
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/gym.php', shortTap: true);
          },
          onLongPress: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com/gym.php', shortTap: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: const Icon(
              Icons.fitness_center,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.green[400],
          label: 'GYM',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.green[400],
        ),
        SpeedDialChild(
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com', shortTap: true);
          },
          onLongPress: () async {
            await Future.delayed(const Duration(milliseconds: 200));
            _launchBrowser(url: 'https://www.torn.com', shortTap: false);
          },
          child: Container(
            width: 100,
            height: 100,
            color: Colors.transparent,
            child: const Icon(
              Icons.home_outlined,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.grey[400],
          label: 'HOME',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.grey[400],
        ),
      ],
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[800]!,
            width: 2,
          ),
          shape: BoxShape.circle,
          image: const DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage("images/icons/torn_t_logo.png"),
          ),
        ),
      ),
    );
  }

  Future<void> _launchBrowser({required String? url, required bool? shortTap, bool recallLastSession = false}) async {
    if (url == null || shortTap == null) return;

    _webViewProvider.openBrowserPreference(
      context: context,
      url: url,
      browserTapType: shortTap ? BrowserTapType.short : BrowserTapType.long,
      recallLastSession: recallLastSession,
    );
  }

  Future _updateCallback() async {
    // Even if this implies calling the app twice, it enhances player
    // experience as the bars are updated quickly after a change
    // In turn, we only call the API every 30 seconds with the timer
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      _fetchApi();
    }
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      _fetchApi();
    }
  }

  Future<void> _scheduleNotification(ProfileNotification profileNotification) async {
    int? secondsToNotification;
    late String channelTitle;
    String? channelSubtitle;
    String? channelDescription;
    String? notificationTitle;
    String? notificationSubtitle;
    int? notificationId;
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
        notificationTitle = _settingsProvider!.discreetNotifications ? "T" : await Prefs().getTravelNotificationTitle();
        notificationSubtitle =
            _settingsProvider!.discreetNotifications ? " " : await Prefs().getTravelNotificationBody();
        notificationPayload += 'travel';
        notificationIconAndroid = "notification_travel";
        notificationIconColor = Colors.blue;
      case ProfileNotification.energy:
        notificationId = 101;
        secondsToNotification = _energyNotificationTime!.difference(DateTime.now()).inSeconds;
        channelTitle = 'Manual energy';
        channelSubtitle = 'Manual energy';
        channelDescription = 'Manual notifications for energy';
        notificationTitle = _settingsProvider!.discreetNotifications ? "E" : 'Energy bar';
        notificationSubtitle = _settingsProvider!.discreetNotifications ? "Full" : 'Here is your energy reminder!';
        final myTimeStamp = (_energyNotificationTime!.millisecondsSinceEpoch / 1000).floor();
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_energy";
        notificationIconColor = Colors.green;
      case ProfileNotification.nerve:
        notificationId = 102;
        secondsToNotification = _nerveNotificationTime!.difference(DateTime.now()).inSeconds;
        channelTitle = 'Manual nerve';
        channelSubtitle = 'Manual nerve';
        channelDescription = 'Manual notifications for nerve';
        notificationTitle = _settingsProvider!.discreetNotifications ? "N" : 'Nerve bar';
        notificationSubtitle = _settingsProvider!.discreetNotifications ? "Full" : 'Here is your nerve reminder!';
        final myTimeStamp = (_nerveNotificationTime!.millisecondsSinceEpoch / 1000).floor();
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_nerve";
        notificationIconColor = Colors.red;
      case ProfileNotification.life:
        notificationId = 103;
        secondsToNotification = _user!.life!.fulltime;
        channelTitle = 'Manual life';
        channelSubtitle = 'Manual life';
        channelDescription = 'Manual notifications for life';
        notificationTitle = _settingsProvider!.discreetNotifications ? "Lf" : 'Life bar';
        notificationSubtitle = _settingsProvider!.discreetNotifications ? "Full" : 'Here is your life reminder!';
        final myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user!.life!.fulltime!;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_life";
        notificationIconColor = Colors.red;
      case ProfileNotification.drugs:
        notificationId = 104;
        secondsToNotification = _user!.cooldowns!.drug;
        channelTitle = 'Manual drugs';
        channelSubtitle = 'Manual drugs';
        channelDescription = 'Manual notifications for drugs';
        notificationTitle = _settingsProvider!.discreetNotifications ? "D" : 'Drug Cooldown';
        notificationSubtitle =
            _settingsProvider!.discreetNotifications ? "Exp" : 'Here is your drugs cooldown reminder!';
        final myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user!.cooldowns!.drug!;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_drugs";
        notificationIconColor = Colors.green;
      case ProfileNotification.medical:
        notificationId = 105;
        secondsToNotification = _user!.cooldowns!.medical;
        channelTitle = 'Manual medical';
        channelSubtitle = 'Manual medical';
        channelDescription = 'Manual notifications for medical';
        notificationTitle = _settingsProvider!.discreetNotifications ? "Med" : 'Medical Cooldown';
        notificationSubtitle =
            _settingsProvider!.discreetNotifications ? "Exp" : 'Here is your medical cooldown reminder!';
        final myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user!.cooldowns!.medical!;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_medical";
        notificationIconColor = Colors.yellow;
      case ProfileNotification.booster:
        notificationId = 106;
        secondsToNotification = _user!.cooldowns!.booster;
        channelTitle = 'Manual booster';
        channelSubtitle = 'Manual booster';
        channelDescription = 'Manual notifications for booster';
        notificationTitle = _settingsProvider!.discreetNotifications ? "B" : 'Booster Cooldown';
        notificationSubtitle =
            _settingsProvider!.discreetNotifications ? "Exp" : 'Here is your booster cooldown reminder!';
        final myTimeStamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() + _user!.cooldowns!.booster!;
        notificationPayload += '${profileNotification.string}-$myTimeStamp';
        notificationIconAndroid = "notification_booster";
        notificationIconColor = Colors.orange;
      case ProfileNotification.hospital:
        notificationId = 107;
        secondsToNotification = _hospitalReleaseTime.difference(DateTime.now()).inSeconds - _hospitalNotificationAhead;
        channelTitle = 'Manual hospital';
        channelSubtitle = 'Manual hospital';
        channelDescription = 'Manual notifications for hospital';
        notificationTitle = _settingsProvider!.discreetNotifications ? "H" : 'Hospital release';
        notificationSubtitle =
            _settingsProvider!.discreetNotifications ? "App" : 'You are about to be released from hospital!';
        notificationPayload += 'hospital';
        notificationIconAndroid = "notification_hospital";
        notificationIconColor = Colors.yellow;
      case ProfileNotification.jail:
        notificationId = 108;
        secondsToNotification = _jailReleaseTime.difference(DateTime.now()).inSeconds - _jailNotificationAhead;
        channelTitle = 'Manual jail';
        channelSubtitle = 'Manual jail';
        channelDescription = 'Manual notifications for jail';
        notificationTitle = _settingsProvider!.discreetNotifications ? "J" : 'Jail release';
        notificationSubtitle =
            _settingsProvider!.discreetNotifications ? "App" : 'You are about to be released from jail!';
        notificationPayload += 'jail';
        notificationIconAndroid = "notification_events";
        notificationIconColor = Colors.purple;
      case ProfileNotification.rankedWar:
        notificationId = 109;
        secondsToNotification = _rankedWarTime.difference(DateTime.now()).inSeconds - _rankedWarNotificationAhead;
        channelTitle = 'Manual war';
        channelSubtitle = 'Manual war';
        channelDescription = 'Manual notifications for war';
        notificationTitle = _settingsProvider!.discreetNotifications ? "W" : 'Ranked War';
        notificationSubtitle = _settingsProvider!.discreetNotifications ? "App" : 'Ranked war is about to start!';
        notificationPayload += 'war';
        notificationIconAndroid = "notification_assists";
        notificationIconColor = Colors.red;
      case ProfileNotification.raceStart:
        notificationId = 110;
        secondsToNotification = _raceStartTime.difference(DateTime.now()).inSeconds - _raceStartNotificationAhead;
        channelTitle = 'Manual race start';
        channelSubtitle = 'Manual race start';
        channelDescription = 'Manual notifications for race start';
        notificationTitle = _settingsProvider!.discreetNotifications ? "R" : 'Race Start';
        notificationSubtitle = _settingsProvider!.discreetNotifications ? "Start" : 'Lights out and here we go!';
        notificationPayload += 'raceStart';
        notificationIconAndroid = "notification_racing";
        notificationIconColor = Colors.blue;
    }

    final modifier = await getNotificationChannelsModifiers();

    // Add s for custom sounds
    if (channelTitle.contains("travel")) {
      channelTitle = "$channelTitle ${modifier.channelIdModifier} s";
      channelSubtitle = "$channelSubtitle ${modifier.channelIdModifier} s";
    } else {
      channelTitle = "$channelTitle ${modifier.channelIdModifier}";
      channelSubtitle = "$channelSubtitle ${modifier.channelIdModifier}";
    }

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
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

    var iOSPlatformChannelSpecifics =
        const DarwinNotificationDetails(presentSound: true, sound: 'slow_spring_board.aiff');
    if (notificationId == 201) {
      iOSPlatformChannelSpecifics =
          const DarwinNotificationDetails(presentSound: true, sound: 'aircraft_seatbelt.aiff');
    }

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    if (Platform.isAndroid) {
      await assessExactAlarmsPermissionsAndroid(context, _settingsProvider!);
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      notificationTitle,
      notificationSubtitle,
      //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)), // DEBUG
      tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsToNotification!)),
      platformChannelSpecifics,
      payload: notificationPayload,
      androidScheduleMode: exactAlarmsPermissionAndroid
          ? AndroidScheduleMode.exactAllowWhileIdle // Deliver at exact time (needs permission)
          : AndroidScheduleMode.inexactAllowWhileIdle,
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
    bool war = false;
    bool raceStart = false;

    final pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    if (pendingNotificationRequests.isNotEmpty) {
      for (final notification in pendingNotificationRequests) {
        if (notification.id == 201) {
          travel = true;
        }
        if (notification.id == 101) {
          energy = true;
        }
        if (notification.id == 102) {
          nerve = true;
        }
        if (notification.id == 103) {
          life = true;
        }
        if (notification.id == 104) {
          drugs = true;
        }
        if (notification.id == 105) {
          medical = true;
        }
        if (notification.id == 106) {
          booster = true;
        }
        if (notification.id == 107) {
          hospital = true;
        }
        if (notification.id == 108) {
          jail = true;
        }
        if (notification.id == 109) {
          war = true;
        }
        if (notification.id == 201) {
          raceStart = true;
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
        _rankedWarNotificationsPending = war;
        _raceStartNotificationsPending = raceStart;
      });
    }
  }

  Future<void> _cancelNotifications(ProfileNotification profileNotification) async {
    switch (profileNotification) {
      case ProfileNotification.travel:
        await flutterLocalNotificationsPlugin.cancel(201);
      case ProfileNotification.energy:
        await flutterLocalNotificationsPlugin.cancel(101);
      case ProfileNotification.nerve:
        await flutterLocalNotificationsPlugin.cancel(102);
      case ProfileNotification.life:
        await flutterLocalNotificationsPlugin.cancel(103);
      case ProfileNotification.drugs:
        await flutterLocalNotificationsPlugin.cancel(104);
      case ProfileNotification.medical:
        await flutterLocalNotificationsPlugin.cancel(105);
      case ProfileNotification.booster:
        await flutterLocalNotificationsPlugin.cancel(106);
      case ProfileNotification.hospital:
        await flutterLocalNotificationsPlugin.cancel(107);
      case ProfileNotification.jail:
        await flutterLocalNotificationsPlugin.cancel(108);
      case ProfileNotification.rankedWar:
        await flutterLocalNotificationsPlugin.cancel(109);
      case ProfileNotification.raceStart:
        await flutterLocalNotificationsPlugin.cancel(110);
    }

    _retrievePendingNotifications();
  }

  Future<void> _checkIfNotificationsAreCurrent() async {
    final pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    if (pendingNotificationRequests.isEmpty) {
      return;
    }

    bool triggered = false;
    final updatedTypes = <String>[];
    final updatedTimes = <String>[];

    final TimeFormatSetting timePrefs = _settingsProvider!.currentTimeFormat;
    DateFormat formatter;
    switch (timePrefs) {
      case TimeFormatSetting.h24:
        formatter = DateFormat('HH:mm');
      case TimeFormatSetting.h12:
        formatter = DateFormat('hh:mm a');
    }

    for (final notification in pendingNotificationRequests) {
      // Don't take into account notifications that don't split this way
      // Using this instead of try/catch
      final splitPayload = notification.payload!.split('-');
      if (splitPayload.length < 2) {
        continue;
      }
      final stringTs = splitPayload[1];
      final oldTimeStamp = int.tryParse(stringTs);
      if (oldTimeStamp == null) {
        continue;
      }

      // ENERGY
      if (notification.payload!.contains('energy')) {
        final customTriggerRoundedUp = _customEnergyTrigger! + 4;
        if (_user!.energy!.current! >= _user!.energy!.maximum! ||
            (!_customEnergyMaxOverride && _user!.energy!.current! > customTriggerRoundedUp)) {
          _cancelNotifications(ProfileNotification.energy);
          BotToast.showText(
            text: 'Energy notification expired, removing!',
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700]!,
            duration: const Duration(seconds: 5),
            contentPadding: const EdgeInsets.all(10),
          );
          continue;
        }
        // If override and still below it, we compare with full
        if (_customEnergyMaxOverride && _customEnergyTrigger! < _user!.energy!.current!) {
          final newCalculation =
              DateTime.now().add(Duration(seconds: _user!.energy!.fulltime!)).millisecondsSinceEpoch / 1000;
          final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.energy);
            _scheduleNotification(ProfileNotification.energy);
            triggered = true;
            updatedTypes.add('energy');
            final energyCurrentSchedule = DateTime.now().add(Duration(seconds: _user!.energy!.fulltime!));
            updatedTimes.add(formatter.format(energyCurrentSchedule));
          }
        }
        // If no override, we take whatever value it is
        else {
          int? newSecondsToGo = 0;
          if (_customEnergyTrigger == _user!.energy!.maximum) {
            newSecondsToGo = _user!.energy!.fulltime;
          } else {
            final energyToGo = _customEnergyTrigger! - _user!.energy!.current!;
            final energyTicksToGo = energyToGo / _user!.energy!.increment!;
            if (energyTicksToGo > 1) {
              final consumedTick = _user!.energy!.interval! - _user!.energy!.ticktime!;
              newSecondsToGo = (energyTicksToGo * _user!.energy!.interval! - consumedTick).floor();
            } else if (energyTicksToGo > 0 && energyTicksToGo <= 1) {
              newSecondsToGo = _user!.energy!.ticktime;
            }
          }

          final newCalculation = DateTime.now().add(Duration(seconds: newSecondsToGo!)).millisecondsSinceEpoch / 1000;

          final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.energy);
            _energyNotificationTime = DateTime.now().add(Duration(seconds: newSecondsToGo));
            _scheduleNotification(ProfileNotification.energy);
            triggered = true;
            updatedTypes.add('energy');
            final energyCurrentSchedule = DateTime.now().add(Duration(seconds: newSecondsToGo));
            updatedTimes.add(formatter.format(energyCurrentSchedule));
          }
        }
        // NERVE
      } else if (notification.payload!.contains('nerve')) {
        if (_user!.nerve!.current! >= _user!.nerve!.maximum! ||
            (!_customNerveMaxOverride && _user!.nerve!.current! > _customNerveTrigger!)) {
          _cancelNotifications(ProfileNotification.nerve);
          BotToast.showText(
            text: 'Nerve notification expired, removing!',
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700]!,
            duration: const Duration(seconds: 5),
            contentPadding: const EdgeInsets.all(10),
          );
          continue;
        }
        // If override and still below it, we compare with full
        if (_customNerveMaxOverride && _customNerveTrigger! < _user!.nerve!.current!) {
          final newCalculation =
              DateTime.now().add(Duration(seconds: _user!.nerve!.fulltime!)).millisecondsSinceEpoch / 1000;
          final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.nerve);
            _scheduleNotification(ProfileNotification.nerve);
            triggered = true;
            updatedTypes.add('nerve');
            final nerveCurrentSchedule = DateTime.now().add(Duration(seconds: _user!.nerve!.fulltime!));
            updatedTimes.add(formatter.format(nerveCurrentSchedule));
          }
        }
        // If no override, we take whatever value it is
        else {
          int? newSecondsToGo = 0;
          if (_customNerveTrigger == _user!.nerve!.maximum) {
            newSecondsToGo = _user!.nerve!.fulltime;
          } else {
            final nerveToGo = _customNerveTrigger! - _user!.nerve!.current!;
            final nerveTicksToGo = nerveToGo / _user!.nerve!.increment!;
            if (nerveTicksToGo > 1) {
              final consumedTick = _user!.nerve!.interval! - _user!.nerve!.ticktime!;
              newSecondsToGo = (nerveTicksToGo * _user!.nerve!.interval! - consumedTick).floor();
            } else if (nerveTicksToGo > 0 && nerveTicksToGo <= 1) {
              newSecondsToGo = _user!.nerve!.ticktime;
            }
          }

          final newCalculation = DateTime.now().add(Duration(seconds: newSecondsToGo!)).millisecondsSinceEpoch / 1000;

          final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
          if (compareTimeStamps > 120) {
            _cancelNotifications(ProfileNotification.nerve);
            _nerveNotificationTime = DateTime.now().add(Duration(seconds: newSecondsToGo));
            _scheduleNotification(ProfileNotification.nerve);
            triggered = true;
            updatedTypes.add('nerve');
            final nerveCurrentSchedule = DateTime.now().add(Duration(seconds: newSecondsToGo));
            updatedTimes.add(formatter.format(nerveCurrentSchedule));
          }
        }
        // LIFE
      } else if (notification.payload!.contains('life')) {
        final newCalculation =
            DateTime.now().add(Duration(seconds: _user!.life!.fulltime!)).millisecondsSinceEpoch / 1000;
        final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.life);
          _scheduleNotification(ProfileNotification.life);
          triggered = true;
          updatedTypes.add('life');
          final lifeCurrentSchedule = DateTime.now().add(Duration(seconds: _user!.life!.fulltime!));
          updatedTimes.add(formatter.format(lifeCurrentSchedule));
        }
        // DRUGS
      } else if (notification.payload!.contains('drugs')) {
        final newCalculation =
            DateTime.now().add(Duration(seconds: _user!.cooldowns!.drug!)).millisecondsSinceEpoch / 1000;
        final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.drugs);
          _scheduleNotification(ProfileNotification.drugs);
          triggered = true;
          updatedTypes.add('drugs');
          final drugsCurrentSchedule = DateTime.now().add(Duration(seconds: _user!.cooldowns!.drug!));
          updatedTimes.add(formatter.format(drugsCurrentSchedule));
        }
        // MEDICAL
      } else if (notification.payload!.contains('medical')) {
        final newCalculation =
            DateTime.now().add(Duration(seconds: _user!.cooldowns!.medical!)).millisecondsSinceEpoch / 1000;
        final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.medical);
          _scheduleNotification(ProfileNotification.medical);
          triggered = true;
          updatedTypes.add('medical');
          final medicalCurrentSchedule = DateTime.now().add(Duration(seconds: _user!.cooldowns!.medical!));
          updatedTimes.add(formatter.format(medicalCurrentSchedule));
        }
        // BOOSTER
      } else if (notification.payload!.contains('booster')) {
        final newCalculation =
            DateTime.now().add(Duration(seconds: _user!.cooldowns!.booster!)).millisecondsSinceEpoch / 1000;
        final compareTimeStamps = (newCalculation - oldTimeStamp).abs().floor();
        if (compareTimeStamps > 120) {
          _cancelNotifications(ProfileNotification.booster);
          _scheduleNotification(ProfileNotification.booster);
          triggered = true;
          updatedTypes.add('booster');
          final boosterCurrentSchedule = DateTime.now().add(Duration(seconds: _user!.cooldowns!.booster!));
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
          thoseUpdated += ' for E${_customEnergyTrigger!})';
        } else if (updatedTypes[i] == 'nerve') {
          thoseUpdated += ' for N${_customNerveTrigger!})';
        } else {
          thoseUpdated += ')';
        }
        if (i < updatedTypes.length - 1) {
          thoseUpdated += ", ";
        }
      }

      BotToast.showText(
        text: 'Some notifications have been updated: $thoseUpdated',
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[700]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  void _shareMisc({String? shareType}) {
    final decimalFormat = NumberFormat("#,##0", "en_US");
    var playerString = "${_user!.name} [${_user!.playerId}]";

    String getBattle() {
      var battleString = "\n\nBATTLE STATS";
      battleString += '\nStrength: ${decimalFormat.format(_miscModel!.strength)} '
          '(${decimalFormat.format(_miscModel!.strength! * 100 / _miscModel!.total!)}%)';
      battleString += '\nDefense: ${decimalFormat.format(_miscModel!.defense)} '
          '(${decimalFormat.format(_miscModel!.defense! * 100 / _miscModel!.total!)}%)';
      battleString += '\nSpeed: ${decimalFormat.format(_miscModel!.speed)} '
          '(${decimalFormat.format(_miscModel!.speed! * 100 / _miscModel!.total!)}%)';
      battleString += '\nDexterity: ${decimalFormat.format(_miscModel!.dexterity)} '
          '(${decimalFormat.format(_miscModel!.dexterity! * 100 / _miscModel!.total!)}%)';
      battleString += '\n-------';
      battleString += '\nTotal: ${decimalFormat.format(_miscModel!.total)}';
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
      workString += '\nManual labor: ${decimalFormat.format(_miscModel!.manualLabor)}';
      workString += '\nIntelligence: ${decimalFormat.format(_miscModel!.intelligence)}';
      workString += '\nEndurance: ${decimalFormat.format(_miscModel!.endurance)}';
      return workString;
    }

    String getSkills() {
      var skillExist = false;
      var skillsString = "\n\nSKILLS";
      if (_miscModel!.hunting != null) {
        skillsString += '\nRacing: ${_miscModel!.racing}';
        skillExist = true;
      }
      if (_miscModel!.reviving != null) {
        skillsString += '\nReviving: ${_miscModel!.reviving}';
        skillExist = true;
      }
      if (_miscModel!.hunting != null) {
        skillsString += '\nHunting: ${_miscModel!.hunting}';
        skillExist = true;
      }
      if (!skillExist) skillsString = "";
      return skillsString;
    }

    String getCrimes() {
      var crimesExist = false;
      var crimesString = "\n\nCRIMES";
      if (_miscModel!.searchForCash != null) {
        crimesString += '\nSearch for Cash: ${_miscModel!.searchForCash}';
        crimesExist = true;
      }
      if (_miscModel!.bootlegging != null) {
        crimesString += '\nBootlegging: ${_miscModel!.bootlegging}';
        crimesExist = true;
      }
      if (_miscModel!.graffiti != null) {
        crimesString += '\nGraffiti: ${_miscModel!.graffiti}';
        crimesExist = true;
      }
      if (_miscModel!.shoplifting != null) {
        crimesString += '\nShoplifting: ${_miscModel!.shoplifting}';
        crimesExist = true;
      }
      if (_miscModel!.pickpocketing != null) {
        crimesString += '\nPickpocketing: ${_miscModel!.pickpocketing}';
        crimesExist = true;
      }
      if (_miscModel!.cardSkimming != null) {
        crimesString += '\nCard Skimming: ${_miscModel!.cardSkimming}';
        crimesExist = true;
      }
      if (_miscModel!.burglary != null) {
        crimesString += '\nBurglary: ${_miscModel!.burglary}';
        crimesExist = true;
      }
      if (_miscModel!.hustling != null) {
        crimesString += '\nHustling: ${_miscModel!.hustling}';
        crimesExist = true;
      }
      if (_miscModel!.disposal != null) {
        crimesString += '\nDisposal: ${_miscModel!.disposal}';
        crimesExist = true;
      }
      if (_miscModel!.cracking != null) {
        crimesString += '\nCracking: ${_miscModel!.cracking}';
        crimesExist = true;
      }
      if (_miscModel!.forgery != null) {
        crimesString += '\nForgery: ${_miscModel!.forgery}';
        crimesExist = true;
      }
      if (_miscModel!.scamming != null) {
        crimesString += '\nScamming: ${_miscModel!.scamming}';
        crimesExist = true;
      }

      if (!crimesExist) crimesString = "";
      return crimesString;
    }

    switch (shareType) {
      case "battle":
        final battle = playerString += getBattle();
        _onShare(battle);
      //print(battle);
      case "effective":
        final effective = playerString += getEffective();
        _onShare(effective);
      //print(effective);
      case "work":
        final work = playerString += getWork();
        _onShare(work);
      //print(work);
      case "skills":
        String skills = playerString += getSkills();
        skills += getCrimes();
        _onShare(skills);
      //print(skills);
      default:
        var all = playerString;
        all += "\n\nCash: ${decimalFormat.format(_user!.networth!["wallet"])}";
        all += "\nPoints: ${_miscModel!.points}";
        all += "\n$_sharedJobPoints";
        all += getBattle();
        all += getEffective();
        all += getWork();
        all += getSkills();
        all += getCrimes();
        _onShare(all);
        //print(all);
        break;
    }
  }

  void _onShare(String shareText) async {
    await Share.share(
      shareText,
      sharePositionOrigin: Rect.fromLTWH(
        0,
        0,
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height / 2,
      ),
    );
  }

  Future _loadPreferences() async {
    //SharedPreferencesModel().setProfileSectionOrder([]);

    // SECTION ORDER
    final savedUserOrder = await Prefs().getProfileSectionOrder();
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
    final travel = await Prefs().getTravelNotificationType();
    final travelNotificationAhead = await Prefs().getTravelNotificationAhead();
    final travelAlarmAhead = await Prefs().getTravelAlarmAhead();
    final travelTimerAhead = await Prefs().getTravelTimerAhead();

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

    final energy = await Prefs().getEnergyNotificationType();
    _customEnergyTrigger = await Prefs().getEnergyNotificationValue();
    _customEnergyMaxOverride = await Prefs().getEnergyPercentageOverride();

    final nerve = await Prefs().getNerveNotificationType();
    _customNerveTrigger = await Prefs().getNerveNotificationValue();
    _customNerveMaxOverride = await Prefs().getNervePercentageOverride();

    final life = await Prefs().getLifeNotificationType();
    final drugs = await Prefs().getDrugNotificationType();
    final medical = await Prefs().getMedicalNotificationType();
    final booster = await Prefs().getBoosterNotificationType();

    final hospital = await Prefs().getHospitalNotificationType();
    _hospitalNotificationAhead = await Prefs().getHospitalNotificationAhead();
    _hospitalAlarmAhead = await Prefs().getHospitalAlarmAhead();
    _hospitalTimerAhead = await Prefs().getHospitalTimerAhead();

    final jail = await Prefs().getJailNotificationType();
    _jailNotificationAhead = await Prefs().getJailNotificationAhead();
    _jailAlarmAhead = await Prefs().getJailAlarmAhead();
    _jailTimerAhead = await Prefs().getJailTimerAhead();

    final rankedWar = await Prefs().getRankedWarNotificationType();
    _rankedWarNotificationAhead = await Prefs().getRankedWarNotificationAhead();
    _rankedWarAlarmAhead = await Prefs().getRankedWarAlarmAhead();
    _rankedWarTimerAhead = await Prefs().getRankedWarTimerAhead();

    final raceStart = await Prefs().getRaceStartNotificationType();
    _raceStartNotificationAhead = await Prefs().getRaceStartNotificationAhead();
    _raceStartAlarmAhead = await Prefs().getRaceStartAlarmAhead();
    _raceStartTimerAhead = await Prefs().getRaceStartTimerAhead();

    _alarmSound = await Prefs().getManualAlarmSound();
    _alarmVibration = await Prefs().getManualAlarmVibration();

    _warnAboutChains = await Prefs().getWarnAboutChains();
    _showHeaderWallet = await Prefs().getShowHeaderWallet();
    _showHeaderIcons = await Prefs().getShowHeaderIcons();
    _dedicatedTravelCard = await Prefs().getDedicatedTravelCard();

    final expandEvents = await Prefs().getExpandEvents();
    final eventsNumber = await Prefs().getEventsShowNumber();
    final expandMessages = await Prefs().getExpandMessages();
    final messagesNumber = await Prefs().getMessagesShowNumber();
    final expandBasicInfo = await Prefs().getExpandBasicInfo();
    final expandNetworth = await Prefs().getExpandNetworth();

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
        _travelNotificationIcon = Icons.timer_outlined;
      }

      if (energy == '0') {
        _energyNotificationType = NotificationType.notification;
        _energyNotificationIcon = Icons.chat_bubble_outline;
      } else if (energy == '1') {
        _energyNotificationType = NotificationType.alarm;
        _energyNotificationIcon = Icons.notifications_none;
      } else if (energy == '2') {
        _energyNotificationType = NotificationType.timer;
        _energyNotificationIcon = Icons.timer_outlined;
      }

      if (nerve == '0') {
        _nerveNotificationType = NotificationType.notification;
        _nerveNotificationIcon = Icons.chat_bubble_outline;
      } else if (nerve == '1') {
        _nerveNotificationType = NotificationType.alarm;
        _nerveNotificationIcon = Icons.notifications_none;
      } else if (nerve == '2') {
        _nerveNotificationType = NotificationType.timer;
        _nerveNotificationIcon = Icons.timer_outlined;
      }

      if (life == '0') {
        _lifeNotificationType = NotificationType.notification;
        _lifeNotificationIcon = Icons.chat_bubble_outline;
      } else if (life == '1') {
        _lifeNotificationType = NotificationType.alarm;
        _lifeNotificationIcon = Icons.notifications_none;
      } else if (life == '2') {
        _lifeNotificationType = NotificationType.timer;
        _lifeNotificationIcon = Icons.timer_outlined;
      }

      if (drugs == '0') {
        _drugsNotificationType = NotificationType.notification;
        _drugsNotificationIcon = Icons.chat_bubble_outline;
      } else if (drugs == '1') {
        _drugsNotificationType = NotificationType.alarm;
        _drugsNotificationIcon = Icons.notifications_none;
      } else if (drugs == '2') {
        _drugsNotificationType = NotificationType.timer;
        _drugsNotificationIcon = Icons.timer_outlined;
      }

      if (medical == '0') {
        _medicalNotificationType = NotificationType.notification;
        _medicalNotificationIcon = Icons.chat_bubble_outline;
      } else if (medical == '1') {
        _medicalNotificationType = NotificationType.alarm;
        _medicalNotificationIcon = Icons.notifications_none;
      } else if (medical == '2') {
        _medicalNotificationType = NotificationType.timer;
        _medicalNotificationIcon = Icons.timer_outlined;
      }

      if (booster == '0') {
        _boosterNotificationType = NotificationType.notification;
        _boosterNotificationIcon = Icons.chat_bubble_outline;
      } else if (booster == '1') {
        _boosterNotificationType = NotificationType.alarm;
        _boosterNotificationIcon = Icons.notifications_none;
      } else if (booster == '2') {
        _boosterNotificationType = NotificationType.timer;
        _boosterNotificationIcon = Icons.timer_outlined;
      }

      if (hospital == '0') {
        _hospitalNotificationType = NotificationType.notification;
        _hospitalNotificationIcon = Icons.chat_bubble_outline;
      } else if (hospital == '1') {
        _hospitalNotificationType = NotificationType.alarm;
        _hospitalNotificationIcon = Icons.notifications_none;
      } else if (hospital == '2') {
        _hospitalNotificationType = NotificationType.timer;
        _hospitalNotificationIcon = Icons.timer_outlined;
      }

      if (jail == '0') {
        _jailNotificationType = NotificationType.notification;
        _jailNotificationIcon = Icons.chat_bubble_outline;
      } else if (jail == '1') {
        _jailNotificationType = NotificationType.alarm;
        _jailNotificationIcon = Icons.notifications_none;
      } else if (jail == '2') {
        _jailNotificationType = NotificationType.timer;
        _jailNotificationIcon = Icons.timer_outlined;
      }

      if (rankedWar == '0') {
        _rankedWarNotificationType = NotificationType.notification;
        _rankedWarNotificationIcon = Icons.chat_bubble_outline;
      } else if (rankedWar == '1') {
        _rankedWarNotificationType = NotificationType.alarm;
        _rankedWarNotificationIcon = Icons.notifications_none;
      } else if (rankedWar == '2') {
        _rankedWarNotificationType = NotificationType.timer;
        _rankedWarNotificationIcon = Icons.timer_outlined;
      }

      if (raceStart == '0') {
        _raceStartNotificationType = NotificationType.notification;
        _raceStartNotificationIcon = Icons.chat_bubble_outline;
      } else if (raceStart == '1') {
        _raceStartNotificationType = NotificationType.alarm;
        _raceStartNotificationIcon = Icons.notifications_none;
      } else if (raceStart == '2') {
        _raceStartNotificationType = NotificationType.timer;
        _raceStartNotificationIcon = Icons.timer_outlined;
      }

      _eventsExpController.expanded = expandEvents;
      _eventsShowNumber = eventsNumber;
      _messagesExpController.expanded = expandMessages;
      _messagesShowNumber = messagesNumber;
      _basicInfoExpController.expanded = expandBasicInfo;
      _networthExpController.expanded = expandNetworth;
    });
  }

  void _setAlarm(ProfileNotification profileNotification, String alarmSetString, bool percentageError) {
    bool moreThan24Hours = false;
    int? hour;
    int? minute;
    String? message;

    DateTime currentTime = DateTime.now();

    switch (profileNotification) {
      case ProfileNotification.travel:
        final alarmTime = _travelArrivalTime.add(Duration(minutes: -_travelAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA Travel';
        Duration difference = currentTime.difference(alarmTime);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.energy:
        hour = _energyNotificationTime!.hour;
        minute = _energyNotificationTime!.minute;
        message = 'Torn PDA Energy';
        Duration difference = currentTime.difference(_energyNotificationTime!);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.nerve:
        hour = _nerveNotificationTime!.hour;
        minute = _nerveNotificationTime!.minute;
        message = 'Torn PDA Nerve';
        Duration difference = currentTime.difference(_nerveNotificationTime!);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.life:
        hour = _lifeNotificationTime!.hour;
        minute = _lifeNotificationTime!.minute;
        message = 'Torn PDA Life';
        Duration difference = currentTime.difference(_lifeNotificationTime!);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.drugs:
        hour = _drugsNotificationTime!.hour;
        minute = _drugsNotificationTime!.minute;
        message = 'Torn PDA Drugs';
        Duration difference = currentTime.difference(_drugsNotificationTime!);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.medical:
        hour = _medicalNotificationTime!.hour;
        minute = _medicalNotificationTime!.minute;
        message = 'Torn PDA Medical';
        Duration difference = currentTime.difference(_medicalNotificationTime!);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.booster:
        hour = _boosterNotificationTime!.hour;
        minute = _boosterNotificationTime!.minute;
        message = 'Torn PDA Booster';
        Duration difference = currentTime.difference(_boosterNotificationTime!);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.hospital:
        final alarmTime = _hospitalReleaseTime.add(Duration(minutes: -_hospitalAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA Hospital';
        Duration difference = currentTime.difference(alarmTime);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.jail:
        final alarmTime = _jailReleaseTime.add(Duration(minutes: -_jailAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA Jail';
        Duration difference = currentTime.difference(alarmTime);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.rankedWar:
        final alarmTime = _rankedWarTime.add(Duration(minutes: -_rankedWarAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA War';
        Duration difference = currentTime.difference(alarmTime);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
      case ProfileNotification.raceStart:
        final alarmTime = _raceStartTime.add(Duration(minutes: -_raceStartAlarmAhead));
        hour = alarmTime.hour;
        minute = alarmTime.minute;
        message = 'Torn PDA Race Start';
        Duration difference = currentTime.difference(alarmTime);
        moreThan24Hours = difference.inMinutes.abs() > 1439;
    }

    if (moreThan24Hours) {
      BotToast.showText(
        text: "Alarms can't be set for a period longer than 24 hours!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
      return;
    }

    BotToast.showText(
      text: alarmSetString,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: percentageError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
    );

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

    final AndroidIntent intent = AndroidIntent(
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
    int? totalSeconds;
    String? message;

    switch (profileNotification) {
      case ProfileNotification.travel:
        totalSeconds = _travelArrivalTime.difference(DateTime.now()).inSeconds - _travelTimerAhead;
        message = 'Torn PDA Travel';
      case ProfileNotification.energy:
        totalSeconds = _energyNotificationTime!.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Energy';
      case ProfileNotification.nerve:
        totalSeconds = _nerveNotificationTime!.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Nerve';
      case ProfileNotification.life:
        totalSeconds = _lifeNotificationTime!.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Life';
      case ProfileNotification.drugs:
        totalSeconds = _drugsNotificationTime!.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Drugs';
      case ProfileNotification.medical:
        totalSeconds = _medicalNotificationTime!.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Medical';
      case ProfileNotification.booster:
        totalSeconds = _boosterNotificationTime!.difference(DateTime.now()).inSeconds;
        message = 'Torn PDA Booster';
      case ProfileNotification.hospital:
        totalSeconds = _hospitalReleaseTime.difference(DateTime.now()).inSeconds - _hospitalTimerAhead;
        message = 'Torn PDA Hospital';
      case ProfileNotification.jail:
        totalSeconds = _jailReleaseTime.difference(DateTime.now()).inSeconds - _jailTimerAhead;
        message = 'Torn PDA Jail';
      case ProfileNotification.rankedWar:
        totalSeconds = _rankedWarTime.difference(DateTime.now()).inSeconds - _rankedWarTimerAhead;
        message = 'Torn PDA War';
      case ProfileNotification.raceStart:
        totalSeconds = _raceStartTime.difference(DateTime.now()).inSeconds - _raceStartTimerAhead;
        message = 'Torn PDA Race Start';
    }

    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.LENGTH': totalSeconds,
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': message,
      },
    );
    intent.launch();
  }

  Future<void> _callBackFromNotificationOptions() async {
    await _loadPreferences();
    _checkIfNotificationsAreCurrent();
  }

  Future<void> _openWalletDialog() {
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
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/icons/home/vault.png',
                                  width: 15,
                                  height: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 15),
                                const Text("Personal vault"),
                              ],
                            ),
                            onPressed: () async {
                              const url = "https://www.torn.com/properties.php#/p=options&tab=vault";
                              Navigator.of(context).pop();
                              _launchBrowser(url: url, shortTap: true);
                            },
                            onLongPress: () async {
                              const url = "https://www.torn.com/properties.php#/p=options&tab=vault";
                              Navigator.of(context).pop();
                              _launchBrowser(url: url, shortTap: false);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/icons/faction.png',
                                  width: 15,
                                  height: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 15),
                                const Text("Faction vault"),
                              ],
                            ),
                            onPressed: () async {
                              const url = 'https://www.torn.com/factions.php?step=your#/tab=armoury';
                              Navigator.of(context).pop();
                              _launchBrowser(url: url, shortTap: true);
                            },
                            onLongPress: () async {
                              const url = "https://www.torn.com/factions.php?step=your#/tab=armoury";
                              Navigator.of(context).pop();
                              _launchBrowser(url: url, shortTap: false);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/icons/home/job.png',
                                  width: 15,
                                  height: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 15),
                                const Text("Company vault"),
                              ],
                            ),
                            onPressed: () async {
                              const url = 'https://www.torn.com/companies.php#/option=funds';
                              Navigator.of(context).pop();
                              _launchBrowser(url: url, shortTap: true);
                            },
                            onLongPress: () async {
                              const url = "https://www.torn.com/companies.php#/option=funds";
                              Navigator.of(context).pop();
                              _launchBrowser(url: url, shortTap: false);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
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
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(
                          MdiIcons.cash100,
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
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: const Row(
                              children: [
                                Icon(Icons.person),
                                SizedBox(width: 15),
                                Text("Inventory"),
                              ],
                            ),
                            onPressed: () async {
                              const url = "https://www.torn.com/item.php#medical-items";
                              if (longPress) {
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, shortTap: false);
                              } else {
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, shortTap: true);
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/icons/faction.png',
                                  width: 25,
                                  height: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 15),
                                const Text("Faction"),
                              ],
                            ),
                            onPressed: () async {
                              const url =
                                  'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical';
                              if (longPress) {
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, shortTap: false);
                              } else {
                                Navigator.of(context).pop();
                                _launchBrowser(url: url, shortTap: true);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
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
      int? currentPoints = 0;
      bool unemployed = false;

      if (_user!.job!.companyId == 0) {
        if (_user!.job!.job == "None") {
          unemployed = true;
        }

        switch (_user!.job!.job!.toLowerCase()) {
          case "army":
            currentPoints = _miscModel!.jobpoints!.jobs!.army;
          case "medical":
            currentPoints = _miscModel!.jobpoints!.jobs!.medical;
          case "casino":
            currentPoints = _miscModel!.jobpoints!.jobs!.casino;
          case "education":
            currentPoints = _miscModel!.jobpoints!.jobs!.education;
          case "law":
            currentPoints = _miscModel!.jobpoints!.jobs!.law;
          case "grocer":
            currentPoints = _miscModel!.jobpoints!.jobs!.grocer;
        }
      } else {
        _miscModel!.jobpoints!.companies!.forEach((type, details) {
          if (type == _user!.job!.companyType.toString()) {
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
              _launchBrowser(url: 'https://www.torn.com/companies.php', shortTap: false);
            },
            onTap: () async {
              _launchBrowser(url: 'https://www.torn.com/companies.php', shortTap: true);
            },
            child: Icon(
              Icons.work,
              color: Colors.brown[300],
              size: 23,
            ),
          ),
          const SizedBox(width: 6),
          SelectableText(headerString),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              return showDialog(
                useRootNavigator: false,
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return JobPointsDialog(
                    currentType: _user!.job!.companyType,
                    currentPoints: currentPoints,
                    jobpoints: _miscModel!.jobpoints,
                    job: _user!.job,
                    unemployed: unemployed,
                  );
                },
              );
            },
            child: const Icon(
              Icons.info_outline,
              size: 20,
            ),
          ),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _companyAddictionWidget() {
    try {
      if (_companyAddiction == null) return const SizedBox.shrink();

      Color? c = _themeProvider!.mainText;
      if (_companyAddiction! < -1) c = Colors.orange[700];
      if (_companyAddiction! < -12) c = Colors.red[700];

      return Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Row(
          children: [
            Image.asset(
              'images/icons/chart_down.png',
              height: 18,
              color: Colors.brown[300],
            ),
            const SizedBox(width: 9),
            const Text("Company Addiction: "),
            Text(
              "$_companyAddiction",
              style: TextStyle(color: c),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _flagImage() {
    String flagFile;
    switch (_user!.travel!.destination) {
      case "Torn":
        flagFile = 'images/flags/travel/torn.png';
      case "Argentina":
        flagFile = 'images/flags/stock/argentina.png';
      case "Canada":
        flagFile = 'images/flags/stock/canada.png';
      case "Cayman Islands":
        flagFile = 'images/flags/stock/cayman.png';
      case "China":
        flagFile = 'images/flags/stock/china.png';
      case "Hawaii":
        flagFile = 'images/flags/stock/hawaii.png';
      case "Japan":
        flagFile = 'images/flags/stock/japan.png';
      case "Mexico":
        flagFile = 'images/flags/stock/mexico.png';
      case "South Africa":
        flagFile = 'images/flags/stock/south-africa.png';
      case "Switzerland":
        flagFile = 'images/flags/stock/switzerland.png';
      case "UAE":
        flagFile = 'images/flags/stock/uae.png';
      case "United Kingdom":
        flagFile = 'images/flags/stock/uk.png';
      default:
        return const SizedBox.shrink();
    }

    return Image(
      image: AssetImage(flagFile),
      height: 30,
      width: 40,
    );
  }

  String _flagBallAsset() {
    switch (_user!.travel!.destination) {
      case "Torn":
        if (_user!.status!.description!.contains("to Torn from Argentina")) {
          return 'images/flags/ball/ball_argentina.png';
        } else if (_user!.status!.description!.contains("to Torn from Canada")) {
          return 'images/flags/ball/ball_canada.png';
        } else if (_user!.status!.description!.contains("to Torn from Cayman Islands")) {
          return 'images/flags/ball/ball_cayman.png';
        } else if (_user!.status!.description!.contains("to Torn from China")) {
          return 'images/flags/ball/ball_china.png';
        } else if (_user!.status!.description!.contains("to Torn from Hawaii")) {
          return 'images/flags/ball/ball_hawaii.png';
        } else if (_user!.status!.description!.contains("to Torn from Japan")) {
          return 'images/flags/ball/ball_japan.png';
        } else if (_user!.status!.description!.contains("to Torn from Mexico")) {
          return 'images/flags/ball/ball_mexico.png';
        } else if (_user!.status!.description!.contains("to Torn from South Africa")) {
          return 'images/flags/ball/ball_south-africa.png';
        } else if (_user!.status!.description!.contains("to Torn from Switzerland")) {
          return 'images/flags/ball/ball_switzerland.png';
        } else if (_user!.status!.description!.contains("to Torn from UAE")) {
          return 'images/flags/ball/ball_uae.png';
        } else if (_user!.status!.description!.contains("to Torn from United Kingdom")) {
          return 'images/flags/ball/ball_uk.png';
        } else {
          return '';
        }
      case "Argentina":
        return 'images/flags/ball/ball_argentina.png';
      case "Canada":
        return 'images/flags/ball/ball_canada.png';
      case "Cayman Islands":
        return 'images/flags/ball/ball_cayman.png';
      case "China":
        return 'images/flags/ball/ball_china.png';
      case "Hawaii":
        return 'images/flags/ball/ball_hawaii.png';
      case "Japan":
        return 'images/flags/ball/ball_japan.png';
      case "Mexico":
        return 'images/flags/ball/ball_mexico.png';
      case "South Africa":
        return 'images/flags/ball/ball_south-africa.png';
      case "Switzerland":
        return 'images/flags/ball/ball_switzerland.png';
      case "UAE":
        return 'images/flags/ball/ball_uae.png';
      case "United Kingdom":
        return 'images/flags/ball/ball_uk.png';
    }
    return '';
  }

  List<Widget> _returnSections() {
    final sectionSort = <Widget>[];

    for (final section in _userSectionOrder!) {
      if (section == "Shortcuts" && _settingsProvider!.shortcutsEnabledProfile) {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _shortcutsCarrousel(),
          ),
        );
      } else if (section == "Status") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _playerStatus(),
          ),
        );
      } else if (section == "Travel" && _dedicatedTravelCard) {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _travelCard(),
          ),
        );
      } else if (section == "Bars") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _basicBars(),
          ),
        );
      } else if (section == "Cooldowns") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _coolDowns(),
          ),
        );
      } else if (section == "Events") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _eventsTimeline(),
          ),
        );
      } else if (section == "Messages") {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: _messagesTimeline(),
          ),
        );
      } else if (section == "Basic Info" && _miscApiFetchedOnce) {
        sectionSort.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
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

  // Check whethere we actually need to call the API (we call every 10 minutes for properties to easy API usage)
  Future<void> _checkProperties(OwnProfileMisc miscApiResponse, bool forcedUpdate) async {
    final now = DateTime.now();

    final propertyInfoIsAbsolete =
        _rentedPropertiesLastChecked == null || now.difference(_rentedPropertiesLastChecked!).inMinutes >= 10;

    if (forcedUpdate || propertyInfoIsAbsolete) {
      _rentedPropertiesLastChecked = now;
      await _fetchAndUpdateProperties(miscApiResponse);
    }
  }

  Future<void> _fetchAndUpdateProperties(OwnProfileMisc miscApiResponse) async {
    final thisRented = <String, Map<String, String>>{};
    final propertyModel = miscApiResponse.properties!;

    final keys = [];
    final details = [];
    propertyModel.forEach((key, value) {
      if (value.status == "Currently being rented") {
        keys.add(key);
        details.add(value);
      }
    });

    int number = 0;
    await Future.forEach(keys, (dynamic element) async {
      final rentDetails = await ApiCallsV1.getProperty(propertyId: element.toString());

      if (rentDetails is PropertyModel) {
        final timeLeft = rentDetails.property!.rented!.daysLeft!;
        final daysString = timeLeft > 1 ? "$timeLeft days" : "less than a day";
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
    final propertyLines = <Widget>[];
    var currentItem = 0;
    thisRented.forEach((key, value) {
      final int numberDays = int.parse(value["time"]!);
      final Widget prop = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                const Icon(Icons.house_outlined),
                const SizedBox(width: 10),
                Flexible(
                  child: Consumer<ThemeProvider>(
                    builder: (context, tP, child) {
                      return Text(
                        value["text"]!,
                        style: TextStyle(
                          color: numberDays <= 5
                              ? numberDays <= 2
                                  ? Colors.red[500]
                                  : Colors.orange[800]
                              : tP.mainText,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onLongPress: () {
              _launchBrowser(
                url: 'https://www.torn.com/properties.php#/p=options&ID=$key&tab=customize',
                shortTap: false,
              );
            },
            onTap: () {
              _launchBrowser(
                url: 'https://www.torn.com/properties.php#/p=options&ID=$key&tab=customize',
                shortTap: true,
              );
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
        propertyLines.add(const SizedBox(height: 10));
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
    _settingsProvider!.changeOCrimeDisregarded = _ocTime.millisecondsSinceEpoch;
  }

  DateTime? _parseRaceTime(String input) {
    final raceStartRegex =
        RegExp(r"Waiting for a race to start - (\d+ days?,)? (\d+ hours?,)? (\d+) minutes and (\d+) seconds");
    final match = raceStartRegex.firstMatch(input);
    if (match != null) {
      int days = int.tryParse(match.group(1)?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
      int hours = int.tryParse(match.group(2)?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
      int minutes = int.tryParse(match.group(3) ?? '0') ?? 0;
      int seconds = int.tryParse(match.group(4) ?? '0') ?? 0;
      return DateTime.now().add(Duration(days: days, hours: hours, minutes: minutes, seconds: seconds));
    }
    return null;
  }
}
