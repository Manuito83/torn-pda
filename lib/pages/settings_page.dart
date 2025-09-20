// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dart_ping/dart_ping.dart';
// Package imports:
import 'package:device_info_plus/device_info_plus.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/oc/ts_members_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/pages/settings/alternative_keys_page.dart';
import 'package:torn_pda/widgets/player_notes_list_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_local/prefs_backup_section.dart';
import 'package:torn_pda/pages/settings/settings_browser.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_login_widget.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/appwidget/pda_widget.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/alerts/discreet_info.dart';
import 'package:torn_pda/widgets/settings/api_auth_widget.dart';
import 'package:torn_pda/widgets/settings/api_error_history_dialog.dart';
import 'package:torn_pda/widgets/settings/applinks_browser_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_delete_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_restore_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_save_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_share_dialog.dart';
import 'package:torn_pda/widgets/settings/browser_info_dialog.dart';
import 'package:torn_pda/widgets/settings/reviving_services_dialog.dart';
import 'package:torn_pda/widgets/spies/spies_management_dialog.dart';
import 'package:torn_pda/widgets/stats/tsc_info.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:vibration/vibration.dart';

class SettingsPage extends StatefulWidget {
  final Function changeUID;
  final StatsController statsController;

  const SettingsPage({
    required this.changeUID,
    required this.statsController,
    super.key,
  });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  Timer? _ticker;

  bool _apiError = false;
  String _errorReason = '';
  String _errorDetails = '';
  bool _apiIsLoading = false;
  OwnProfileBasic? _userProfile;

  Future? _preferencesRestored;

  String? _openSectionValue;
  String? _onAppExitValue;
  String? _openBrowserValue;
  String? _timeFormatValue;
  String? _timeZoneValue;
  String? _vibrationValue;
  late bool _manualAlarmSound;
  late bool _manualAlarmVibration;
  late bool _removeNotificationsLaunch;

  late SettingsProvider _settingsProvider;

  late ThemeProvider _themeProvider;
  late ShortcutsProvider _shortcutsProvider;
  late WebViewProvider _webViewProvider;
  final ApiCallerController _apiController = Get.find<ApiCallerController>();
  final SpiesController _spyController = Get.find<SpiesController>();

  final _expandableController = ExpandableController();

  final _apiKeyInputController = TextEditingController();

  String? _appBarPosition = "top";

  int _androidSdk = 0;

  double _extraMargin = 0.0;

  final _apiFormKey = GlobalKey<FormState>();

  // Refresh rate control
  Map<String, dynamic> _refreshRateInfo = {};
  bool _isUpdatingRefreshRate = false;

  // SEARCH ##########
  bool _isSearching = false;
  String _searchText = '';
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<Widget> buildFilteredSections() {
    List<Widget> sections = [
      _browserSection(),
      _shortcutsSection(),
      _timeSection(),
      _notificationsSection(),
      if (Platform.isAndroid) _appWidgetSection(),
      _spiesSection(),
      _statsSection(),
      _ocSection(),
      _revivingServicesSection(),
      _screenConfigurationSection(),
      _themeSection(),
      if (Platform.isIOS) _appIconSection(),
      _miscSection(),
      _externalPartnersSection(),
      _apiRateSection(),
      _saveSettingsOnlineSection(),
      _saveSettingsLocalSection(),
      _troubleshootingSection(),
    ];

    // Filter out empty sections
    sections = sections.where((widget) => widget is! SizedBox).toList();

    if (sections.isEmpty) return sections;

    // If only one section is visible, return it without any divider
    if (sections.length == 1) return sections;

    List<Widget> finalSections = [];
    for (int i = 0; i < sections.length; i++) {
      if (i > 0) {
        finalSections.add(
          const Column(
            children: [
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
            ],
          ),
        );
      }

      finalSections.add(sections[i]);
    }
    return finalSections;
  }
  // SEARCH ENDS ##########

  @override
  void initState() {
    super.initState();

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    _preferencesRestored = _restorePreferences();
    _loadRefreshRateInfo();
    analytics?.logScreenView(screenName: 'settings');

    routeWithDrawer = true;
    routeName = "settings";
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      leadingWidth: _isSearching ? 56 : (_webViewProvider.webViewSplitActive ? 50 : 88),
      leading: !_isSearching
          ? Row(
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
                if (!_webViewProvider.webViewSplitActive) const PdaBrowserIcon(),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchText = '';
                  FocusScope.of(context).unfocus();
                });
              },
            ),
      title: _isSearching
          ? Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Search settings...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (text) {
                  setState(() {
                    _searchText = text;
                  });
                },
              ),
            )
          : const Text('Settings', style: TextStyle(color: Colors.white)),
      actions: _isSearching
          ? [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  });
                },
              ),
            ],
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _expandableController.dispose();
    _apiKeyInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: FutureBuilder(
          future: _preferencesRestored,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: _extraMargin),
                      if (!_isSearching)
                        ApiKeySectionWidget(
                          apiIsLoading: _apiIsLoading,
                          userProfile: _userProfile,
                          apiError: _apiError,
                          errorReason: _errorReason,
                          errorDetails: _errorDetails,
                          formKey: _formKey,
                          apiFormKey: _apiFormKey,
                          apiKeyInputController: _apiKeyInputController,
                          expandableController: _expandableController,
                          getApiDetails: _getApiDetails,
                          changeUID: (value) => widget.changeUID(value),
                          setStateOnParent: () => setState(() {}),
                          changeApiError: (val) => setState(() => _apiError = val),
                          changeUserProfile: (val) => setState(() => _userProfile = val),
                        ),
                      //if (_userProfile != null && !_isSearching)
                      const Column(
                        children: [
                          NativeLoginWidget(),
                          SizedBox(height: 15),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...buildFilteredSections(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _browserSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Web browser",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(child: Text("Web browser")),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        useRootNavigator: false,
                        context: context,
                        builder: (BuildContext context) {
                          return BrowserInfoDialog();
                        },
                      );
                    },
                  ),
                ],
              ),
              Flexible(child: _openBrowserDropdown()),
            ],
          ),
        ),
      ),
      if (_openBrowserValue == "0")
        SearchableRow(
          label: "Advanced browser settings",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Advanced browser settings"),
                IconButton(
                  icon: const Icon(MdiIcons.web),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => const SettingsBrowserPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    ];
    return buildSectionWithRows(
      title: "BROWSER",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _shortcutsSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Configure shortcuts",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Configure shortcuts"),
              IconButton(
                icon: const Icon(Icons.switch_access_shortcut_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => ShortcutsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Use Profile section shortcuts",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Use Profile section shortcuts"),
                  Switch(
                    value: _settingsProvider.shortcutsEnabledProfile,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.shortcutsEnabledProfile = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Enable configurable shortcuts in the Profile section to quickly access your favorite sections in Torn',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      if (_settingsProvider.shortcutsEnabledProfile)
        SearchableRow(
          label: "Profile shortcuts menu",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text("Profile shortcuts menu")),
                Flexible(child: _shortcutMenuDropdown()),
              ],
            ),
          ),
        ),
      if (_settingsProvider.shortcutsEnabledProfile)
        SearchableRow(
          label: "Profile tile type",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text("Profile tile type")),
                Flexible(child: _shortcutTileDropdown()),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: "SHORTCUTS",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _timeSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Time format",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Time format")),
              Flexible(child: _timeFormatDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Time zone",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Time zone")),
              Flexible(flex: 2, child: _timeZoneDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Show date in clock",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Show date in clock")),
                  Flexible(flex: 2, child: _dateInClockDropdown()),
                ],
              ),
              Text(
                'Add an extra row for the date wherever the TCT clock is shown. You can also specify the desired format (day/month or month/day)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Seconds in clock",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Seconds in clock")),
              Flexible(flex: 2, child: _secondsInClockDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Highlight events",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Highlight events")),
                  Switch(
                    value: _settingsProvider.tctClockHighlightsEvents,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.tctClockHighlightsEvents = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'If enabled, the TCT Clock will be highlighted whenever there is an event or competition active in Torn',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: 'TIME',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _notificationsSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Discreet local notifications",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Text("Discreet local notifications"),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) {
                            return DiscreetInfo();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settingsProvider.discreetNotifications,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.discreetNotifications = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      if (Platform.isAndroid)
        SearchableRow(
          label: "Remove notifications on launch",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Remove notifications on launch")),
                    Switch(
                      value: _removeNotificationsLaunch,
                      onChanged: (value) {
                        _settingsProvider.changeRemoveNotificationsOnLaunch = value;
                        setState(() {
                          _removeNotificationsLaunch = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'This will remove all Torn PDA notifications from your notifications bar when you launch the app. Deactivate it if you prefer to clear them manually.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                )
              ],
            ),
          ),
        ),
      if (Platform.isAndroid)
        SearchableRow(
          label: "Alerts vibration",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Alerts vibration")),
                    Flexible(flex: 2, child: _vibrationDropdown()),
                  ],
                ),
                Text(
                  'This vibration applies to automatic alerts while the app is active or in the background.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      if (Platform.isAndroid)
        SearchableRow(
          label: "Manual alarm sound",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Manual alarm sound"),
                Switch(
                  value: _manualAlarmSound,
                  onChanged: (value) {
                    setState(() {
                      _manualAlarmSound = value;
                    });
                    Prefs().setManualAlarmSound(value);
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      if (Platform.isAndroid)
        SearchableRow(
          label: "Manual alarm vibration",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Manual alarm vibration"),
                    Switch(
                      value: _manualAlarmVibration,
                      onChanged: (value) {
                        setState(() {
                          _manualAlarmVibration = value;
                        });
                        Prefs().setManualAlarmVibration(value);
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    text:
                        'Applies to manually activated alarms in all sections (Travel, Loot, Profile, etc.). Some Android clock apps have issues with multiple timers or distinguishing between sound and vibration. If you experience issues, consider installing ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Google's Clock application",
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const AndroidIntent intent = AndroidIntent(
                              action: 'action_view',
                              data: 'https://play.google.com/store/apps/details?id=com.google.android.deskclock',
                            );
                            await intent.launch();
                          },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
    ];
    return buildSectionWithRows(
      title: "NOTIFICATIONS",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _appWidgetSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Dark mode",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Dark mode")),
              Switch(
                value: _settingsProvider.appwidgetDarkMode,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.appwidgetDarkMode = value;
                    HomeWidget.saveWidgetData<bool>('darkMode', value);
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Remove shortcuts from short layout",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Remove shortcuts from short layout")),
                  Switch(
                    value: _settingsProvider.appwidgetRemoveShortcutsOneRowLayout,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.appwidgetRemoveShortcutsOneRowLayout = value;
                        HomeWidget.saveWidgetData<bool>('removeShortcutsOneRowLayout', value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'By default, the short, one-row layout accommodates a couple of shortcuts by sacrificing chaining information and moving the reload icon to the top. Enabling this option removes shortcuts to free up space for the chaining bar',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Show wallet money",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Show wallet money")),
                  Switch(
                    value: _settingsProvider.appwidgetMoneyEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.appwidgetMoneyEnabled = value;
                        HomeWidget.saveWidgetData<bool>('money_enabled', value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'This is only applicable for the tall widget layout',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Cooldown tap launches browser",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Cooldown tap launches browser")),
                  Switch(
                    value: _settingsProvider.appwidgetCooldownTapOpenBrowser,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.appwidgetCooldownTapOpenBrowser = value;
                        HomeWidget.saveWidgetData<bool>('cooldown_tap_opens_browser', value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'If enabled, a tap on any cooldown icon will launch the app and browser to your personal or faction items. Otherwise, the remaining cooldown time is displayed. NOTE: you may need to try a couple of times after switching for the widget to update properly.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.appwidgetCooldownTapOpenBrowser)
        SearchableRow(
          label: "Cooldown tap destination",
          searchText: _searchText,
          child: _appWidgetCooldownTapDestinationSelector(),
        ),
    ];
    return buildSectionWithRows(
      title: "HOME SCREEN WIDGET",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _spiesSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Spies source",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Spies source")),
                  Flexible(flex: 2, child: _spiesSourceDropdown()),
                ],
              ),
              Text(
                'Choose the source of spied stats. This affects the stats shown when you visit a profile in the browser, as well as those shown in the War section (Chaining)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Spies",
        searchText: _searchText,
        child: GetBuilder<SpiesController>(
          builder: (s) {
            String lastUpdated = "Never updated";
            int lastUpdatedTs = 0;
            if (_spyController.spiesSource == SpiesSource.yata && _spyController.yataSpiesTime != null) {
              lastUpdatedTs = _spyController.yataSpiesTime!.millisecondsSinceEpoch;
              if (lastUpdatedTs > 0) {
                lastUpdated = _spyController.statsOld((lastUpdatedTs / 1000).round());
              }
            } else if (_spyController.spiesSource == SpiesSource.tornStats &&
                _spyController.tornStatsSpiesTime != null) {
              lastUpdatedTs = _spyController.tornStatsSpiesTime!.millisecondsSinceEpoch;
              if (lastUpdatedTs > 0) {
                lastUpdated = _spyController.statsOld((lastUpdatedTs / 1000).round());
              }
            }
            Color spiesUpdateColor = Colors.blue;
            if (lastUpdatedTs > 0) {
              final currentTime = DateTime.now().millisecondsSinceEpoch;
              final oneMonthAgo = currentTime - (30.44 * 24 * 60 * 60 * 1000).round();
              spiesUpdateColor = (lastUpdatedTs < oneMonthAgo) ? Colors.red : context.read<ThemeProvider>().mainText;
            }
            return Padding(
              padding: const EdgeInsets.only(top: 15, left: 40),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(MdiIcons.accountMultipleOutline, size: 18),
                      ),
                      Text(
                        "${s.spiesSource == SpiesSource.yata ? 'YATA' : 'Torn Stats'} database: ${s.spiesSource == SpiesSource.yata ? s.yataSpies.length : s.tornStatsSpies.spies.length} spies",
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(MdiIcons.clockOutline, size: 18),
                      ),
                      Text(lastUpdated, style: TextStyle(color: spiesUpdateColor)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      SearchableRow(
        label: "Manage spies",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Manage spies")),
              IconButton(
                icon: const Icon(MdiIcons.incognito),
                onPressed: () {
                  showDialog(
                    barrierDismissible: false,
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) {
                      return SpiesManagementDialog();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Allow mixed sources",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Allow mixed sources")),
                  Switch(
                    value: _spyController.allowMixedSpiesSources,
                    onChanged: (enabled) {
                      setState(() {
                        _spyController.allowMixedSpiesSources = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Whilst enabled, if a target's spy info cannot be found in the preferred source, it will also be taken from the other source if available. Switching sources preserves info unless the new source also contains a spy for the target.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Delete spies",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Delete spies")),
                  ElevatedButton(
                    child: const Icon(Icons.delete_outlined),
                    onPressed: () async {
                      _spyController.deleteSpies();
                      BotToast.showText(
                        text: "Spies deleted!",
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                        contentColor: Colors.blue,
                        duration: const Duration(seconds: 1),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    },
                  ),
                ],
              ),
              Text(
                'Deletes all spies information from the local database if you prefer not to use spies info or if there is an issue with the downloaded stats.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: "SPIES",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _statsSection() {
    List<SearchableRow> rows = [];

    // TSC Block
    if (_settingsProvider.tscEnabledStatusRemoteConfig) {
      rows.add(
        SearchableRow(
          label: "Use Torn Spies Central",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Flexible(child: Text("Use Torn Spies Central")),
                          const SizedBox(width: 8),
                          GestureDetector(
                            child: const Icon(Icons.info_outline, size: 18),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return TSCInfoDialog(
                                    settingsProvider: _settingsProvider,
                                    themeProvider: _themeProvider,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _settingsProvider.tscEnabledStatus == 1,
                      onChanged: (enabled) async {
                        if (_settingsProvider.tscEnabledStatus != 1) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return TSCInfoDialog(
                                settingsProvider: _settingsProvider,
                                themeProvider: _themeProvider,
                              );
                            },
                          );
                          if (_settingsProvider.tscEnabledStatus == 1) {
                            setState(() {}); // Force update
                          }
                        } else {
                          setState(() {
                            _settingsProvider.tscEnabledStatus = 0;
                          });
                        }
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'Enable Torn Spies Central estimations in sections where spied or estimated stats are shown (e.g.: war targets cards, retal cards or profile widget)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      rows.add(
        SearchableRow(
          label: "Use Torn Spies Central",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Text(
              "TSC temporarily deactivated",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    // YATA Block
    if (_settingsProvider.yataStatsEnabledStatusRemoteConfig) {
      rows.add(
        SearchableRow(
          label: "Use YATA stats estimates",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Row(
                        children: [
                          Flexible(child: Text("Use YATA stats estimates")),
                        ],
                      ),
                    ),
                    Switch(
                      value: _settingsProvider.yataStatsEnabledStatus == 1,
                      onChanged: (enabled) async {
                        setState(() {
                          _settingsProvider.yataStatsEnabledStatus = enabled ? 1 : 0;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'Enable YATA stats estimations in sections where spied or estimated stats are shown (e.g.: war targets cards, retal cards or profile widget)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      rows.add(
        SearchableRow(
          label: "Use YATA stats estimates",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Text(
              "YATA stats temporarily deactivated",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    // Player Notes Manager
    rows.add(
      SearchableRow(
        label: "Player Notes",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Player notes database',
                      style: TextStyle(
                        color: _themeProvider.mainText,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const PlayerNotesListDialog(),
                      );
                    },
                    child: const Text('Manage Notes'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'View and edit all your player notes, including those from targets, friends, stakeouts, and war members.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return buildSectionWithRows(
      title: "STATS and PLAYER NOTES",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _ocSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Nerve bar source",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Nerve bar source")),
                  Flexible(flex: 2, child: _naturalNerveBarSourceDropdown()),
                ],
              ),
              Text(
                'Choose the source of the Natural Nerve Bar (NNB) that will be shown for each member of your faction available to plan an organized crime',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Organized Crimes v2 in use",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Row(
                      children: [Flexible(child: Text("Organized Crimes v2 in use"))],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.playerInOCv2,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.playerInOCv2 = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Torn PDA will try to identify if your faction has changed to OC v2. If you would like to remain in OC v1 (e.g.: if you join an OC1 faction), revert back by using this toggle',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "ORGANIZED CRIMES",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _revivingServicesSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Choose reviving providers",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Choose reviving providers"),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right_outlined),
                    onPressed: () {
                      showDialog(
                        useRootNavigator: false,
                        context: context,
                        builder: (BuildContext context) {
                          return RevivingServicesDialog();
                        },
                      );
                    },
                  ),
                ],
              ),
              Text(
                "Choose which reviving services you might want to use. If enabled, when you are in hospital you'll have the option to call one of their revivers from several places (e.g., Profile and Chaining sections).",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "REVIVING SERVICES",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _screenConfigurationSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Allow auto rotation",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Allow auto rotation")),
                  Switch(
                    value: _settingsProvider.allowScreenRotation,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeAllowScreenRotation = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'If enabled, the interface will rotate from portrait to landscape if the device is rotated. Be aware that landscape might not be comfortable on narrow mobile devices.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Split screen",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Split screen")),
                  Flexible(flex: 2, child: _splitScreenDropdown()),
                ],
              ),
              Text(
                'If enabled, the device screen will be split to show the main app and the browser simultaneously. A minimum width of 800 dpi is required.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Split reverts to",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Split reverts to")),
                  Flexible(flex: 2, child: _splitScreenRevertionDropdown()),
                ],
              ),
              Text(
                'When split screen is no longer active (e.g., device rotated to a width lower than 800 dpi), this option determines whether the webview or the app remains in the foreground.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "High refresh rate",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("High refresh rate"),
                        if (_refreshRateInfo.isNotEmpty)
                          Text(
                            'Current: ${_refreshRateInfo['currentRefreshRate']?.round().toString() ?? 'Unknown'} Hz',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (_refreshRateInfo.isNotEmpty && _refreshRateInfo['maximumFramesPerSecond'] != null)
                          Text(
                            'Max: ${_refreshRateInfo['maximumFramesPerSecond']?.toString() ?? 'Unknown'} Hz',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _isUpdatingRefreshRate
                      ? const SizedBox(
                          width: 48,
                          height: 28,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      : Switch(
                          value: _settingsProvider.highRefreshRateEnabled,
                          onChanged: (value) {
                            setState(() {
                              _settingsProvider.changeHighRefreshRateEnabled = value;
                            });
                            _updateRefreshRateAfterChange();
                          },
                          activeTrackColor: Colors.lightGreenAccent,
                          activeColor: Colors.green,
                        ),
                ],
              ),
              Text(
                'Enables the highest available refresh rate on supported devices (e.g., 90Hz, 120Hz). '
                'May increase battery consumption and device heat but provides smoother animations.'
                '\n\nNOTE: it might be necessary to restart the app after disabling this feature.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "SCREEN CONFIGURATION",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _themeSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Theme description",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text(
            "Please note that the main theme selector switch is located in the drawer menu of Torn PDA. Here you will be able to select other theming options",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
      SearchableRow(
        label: "Use Material theme",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Use Material theme")),
              Switch(
                value: _themeProvider.useMaterial3,
                onChanged: (enabled) async {
                  _themeProvider.useMaterial3 = enabled;
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Sync app with device theme",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Sync app with device theme")),
              Switch(
                value: _settingsProvider.syncDeviceTheme,
                onChanged: (enabled) async {
                  setState(() {
                    _settingsProvider.syncDeviceTheme = enabled;
                    if (enabled) {
                      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
                      if (brightness == Brightness.dark && _themeProvider.currentTheme == AppTheme.light) {
                        _themeProvider.changeTheme = AppTheme.dark;
                      } else if (brightness == Brightness.light && _themeProvider.currentTheme != AppTheme.light) {
                        _themeProvider.changeTheme = AppTheme.light;
                      }
                    }
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Sync app and web themes",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Sync app and web themes")),
              Switch(
                value: _settingsProvider.syncTornWebTheme,
                onChanged: (enabled) async {
                  setState(() {
                    _settingsProvider.syncTornWebTheme = enabled;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.syncTornWebTheme)
        SearchableRow(
          label: "Dark theme equivalent",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Dark theme equivalent")),
                    Flexible(flex: 2, child: _themeToSyncDropdown()),
                  ],
                ),
                Text(
                  "Specifies which dark theme is activated when the web or device switches to dark mode",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: "Accesible text colors",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Accesible text colors")),
                  Switch(
                    value: _themeProvider.accesibilityNoTextColors,
                    onChanged: (enabled) async {
                      _themeProvider.accesibilityNoTextColors = enabled;
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Replaces colored texts with the default color for improved accessibility; applies only to the app, not the web.",
                style: TextStyle(
                  color: _themeProvider.mainText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "THEME",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _appIconSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Dynamic app icons",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Dynamic app icons")),
                  Switch(
                    value: !_settingsProvider.dynamicAppIconEnabledRemoteConfig
                        ? false
                        : _settingsProvider.dynamicAppIcons,
                    onChanged: !_settingsProvider.dynamicAppIconEnabledRemoteConfig
                        ? null
                        : (enabled) async {
                            setState(() {
                              _settingsProvider.dynamicAppIcons = enabled;
                            });
                            if (enabled) {
                              _settingsProvider.appIconChangeBasedOnCondition();
                            } else {
                              _settingsProvider.appIconResetDefault();
                            }
                          },
                    activeTrackColor: _settingsProvider.dynamicAppIconEnabledRemoteConfig
                        ? Colors.lightGreenAccent
                        : Colors.grey[700],
                    activeColor: _settingsProvider.dynamicAppIconEnabledRemoteConfig ? Colors.green : Colors.grey[700],
                    inactiveThumbColor: !_settingsProvider.dynamicAppIconEnabledRemoteConfig ? Colors.grey[800] : null,
                  ),
                ],
              ),
              Text(
                "Allows Torn PDA to change the main app icon based on certain conditions",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!_settingsProvider.dynamicAppIconEnabledRemoteConfig)
                Text(
                  "Deactivated remotely for the time being",
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.dynamicAppIconEnabledRemoteConfig && _settingsProvider.dynamicAppIcons)
        SearchableRow(
          label: "Override icon",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Override icon")),
                    Flexible(child: _manualAppIconDropdown()),
                  ],
                ),
                Text(
                  "By using this option, you can manually trigger (some) app icons even if the conditions are not met",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (!_settingsProvider.dynamicAppIconEnabledRemoteConfig)
                  Text(
                    "Deactivated remotely for the time being",
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: "APP ICON",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _miscSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Show status color counter",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Show status color counter")),
                  Switch(
                    value: Get.find<ChainStatusController>().statusColorWidgetEnabled,
                    onChanged: (value) {
                      setState(() {
                        Get.find<ChainStatusController>().statusColorWidgetEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Shows a player status counter attached to the Torn PDA icon in the main app sections and in the browser three-dotted icon, whenever the player is hospitalised, jailed or traveling',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "App bar position",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("App bar position")),
                  Flexible(flex: 2, child: _appBarPositionDropdown()),
                ],
              ),
              Text(
                'Note: this will affect other quick access items such as the quick crimes bar in the browser',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Default launch section",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Default launch section")),
              Flexible(child: _openSectionDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Back button exits app",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Back button exits app")),
                  Flexible(child: _backButtonAppExitDropdown()),
                ],
              ),
              Text(
                "This will only have effect on certain devices, depending on your configuration. Dictates how to proceed when the app detects a back button press or swipe that would otherwise close the app. Note: in the browser, the back button always triggers backwards navigation",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Show Wiki",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Show Wiki")),
                  Switch(
                    value: _settingsProvider.showWikiInDrawer,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.showWikiInDrawer = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "If enabled, you will have quick access to the Torn wiki from the app drawer menu",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "MISC",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _externalPartnersSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Alternative API keys",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Alternative API keys"),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => const AlternativeKeysPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Text(
                "Use this section to configure alternative API keys for the external partners that Torn PDA connects with. CAUTION: ensure these other keys are working correctly, as Torn PDA is unable to check for errors and certain sections may stop working",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: "EXTERNAL PARTNERS",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _apiRateSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Display API call rate",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Display API call rate")),
                  Switch(
                    value: _apiController.showApiRateInDrawer.value,
                    onChanged: (enabled) async {
                      setState(() {
                        _apiController.showApiRateInDrawer = RxBool(enabled);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Enables a small progress bar on top of Torn PDA's logo in the main drawer menu, with real-time count of the number of API calls performed in the last minute",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Warn max. call rate",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Warn max. call rate")),
                  Switch(
                    value: _apiController.showApiMaxCallWarning,
                    onChanged: (enabled) async {
                      setState(() {
                        _apiController.showApiMaxCallWarning = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "If enabled, a quick message will be shown when approaching (95 calls in 60 seconds) the maximum API call rate. This message will be then inhibited for 30 seconds",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Delay API calls",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Delay API calls")),
                  Switch(
                    value: _apiController.delayCalls,
                    onChanged: (enabled) async {
                      setState(() {
                        _apiController.delayCalls = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Artificially delay API calls above 95 in 60 seconds to avoid hitting the max API rate. If enabled, the current queue information will be shown in the main drawer menu API bar. NOTE: this option cannot take into account API calls generated outside of Torn PDA",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "API CALL RATE",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _saveSettingsOnlineSection() {
    List<SearchableRow> rows = [
      if (!_settingsProvider.backupPrefsEnabledStatusRemoteConfig)
        SearchableRow(
          label: "Backup",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Online backup is temporarily disabled, please check in game or Discord for more information",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.backupPrefsEnabledStatusRemoteConfig) ...[
        SearchableRow(
          label: "Upload settings",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Upload settings")),
                    ElevatedButton(
                      child: const Icon(Icons.upload),
                      onPressed: _userProfile == null
                          ? null
                          : () {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupSaveDialog(userProfile: _userProfile!);
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  "This will allow you to backup your main app settings (e.g.: scripts, shortcuts, etc.) locally so that you can later restore them if needed or share them across different devices",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
          ),
        ),
        SearchableRow(
          label: "Restore settings",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Restore settings")),
                    ElevatedButton(
                      child: const Icon(Icons.download),
                      onPressed: _userProfile == null
                          ? null
                          : () {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupRestoreDialog(userProfile: _userProfile!);
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  "This will download your saved settings and restore them in the app. Please be aware that this will overwrite your current preferences",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
          ),
        ),
        SearchableRow(
          label: "Share settings",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Share settings")),
                    ElevatedButton(
                      child: const Icon(Icons.share),
                      onPressed: _userProfile == null
                          ? null
                          : () {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupShareDialog(
                                    userProfile: _userProfile!,
                                    themeProvider: _themeProvider,
                                  );
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  "This will allow you to share your settings and receive settings from other players using the player ID and a password",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
          ),
        ),
        SearchableRow(
          label: "Clear backup",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(child: Text("Clear backup")),
                    ElevatedButton(
                      child: const Icon(Icons.delete_outline),
                      onPressed: _userProfile == null
                          ? null
                          : () async {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupDeleteDialog(userProfile: _userProfile!);
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  "In case there is an issue with your online backup when restoring or if you simply want to clear it, this will delete the online saved data",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ];
    return buildSectionWithRows(
      title: "ONLINE BACKUP",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _saveSettingsLocalSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Save settings locally",
        searchText: _searchText,
        child: const Padding(
          padding: EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: PrefsBackupWidget(),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "LOCAL BACKUP",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _troubleshootingSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Memory menu",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.memory),
                        SizedBox(width: 5),
                        Flexible(child: Text("Show memory in drawer menu")),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.showMemoryInDrawer,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.showMemoryInDrawer = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'This will show a small memory usage bar on below the Torn PDA\'s logo in the main drawer menu, with real-time count of the app\'s memory usage',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Memory browser",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.memory),
                        SizedBox(width: 5),
                        Flexible(child: Text("Show memory in browser")),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.showMemoryInWebview,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.showMemoryInWebview = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "This will show an icon in the browser's appbar with which you can toggle real-time information of the app's memory usage where the page title normally goes",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_webViewProvider.bottomBarStyleEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "NOTE: this option only works in the 'default' browser style. If have currently selected a different style!",
                    style: TextStyle(
                      color: _themeProvider.getTextColor(Colors.red),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Test API",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Test API")),
                  ElevatedButton(
                    child: const Text("PING"),
                    onPressed: () async {
                      BotToast.showText(
                        text: "Please wait...",
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                        contentColor: Colors.blue,
                        duration: const Duration(seconds: 1),
                        contentPadding: const EdgeInsets.all(10),
                      );
                      final ping = Ping('api.torn.com', count: 4);
                      ping.stream.listen((event) {
                        if (event.summary != null || event.error != null) {
                          String message = "";
                          if (event.error != null) {
                            message = "CONNECTION PROBLEM\n\n${event.error}";
                          } else {
                            if (event.summary!.transmitted == event.summary!.received) {
                              message = "SUCCESS\n\n${event.summary}";
                            } else {
                              message = "CONNECTION PROBLEM\n\n${event.summary}";
                            }
                          }
                          BotToast.showText(
                            clickClose: true,
                            text: message,
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.blue,
                            duration: const Duration(seconds: 10),
                            contentPadding: const EdgeInsets.all(10),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              Text(
                "In case you are facing connection problems, this will ping Torn's API and show whether it is reachable from your device. If it isn't, it might be due to your DNS servers (try switching from WiFi to mobile data).",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "API Error Log",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("API Error Log")),
                  ElevatedButton.icon(
                    label: const Text("View"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ApiErrorDialog(),
                      );
                    },
                  ),
                ],
              ),
              Text(
                "If you ever need to inspect recent API failures (v1 or v2), open the error history here.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Enable debug messages",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Enable debug messages")),
                  Switch(
                    value: _settingsProvider.debugMessages,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.debugMessages = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Enable specific debug messages for app failure testing. This is an advanced feature that may generate extra error messages; do not use unless requested.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Reset tutorials",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Reset tutorials")),
                  ElevatedButton(
                    child: const Text("CLEAR"),
                    onPressed: () async {
                      _settingsProvider.clearShowCases();
                    },
                  ),
                ],
              ),
              Text(
                "This will clear all the app's tutorial pop-ups so you can review them again. Note that some tutorials (e.g., those in the browser) require an app restart to fully reset.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: "TROUBLESHOOTING",
      rows: rows,
      searchText: _searchText,
    );
  }

  DropdownButton _splitScreenDropdown() {
    return DropdownButton<WebViewSplitPosition>(
      value: _webViewProvider.splitScreenPosition,
      items: const [
        DropdownMenuItem(
          value: WebViewSplitPosition.off,
          child: SizedBox(
            width: 120,
            child: Text(
              "Off",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        DropdownMenuItem(
          value: WebViewSplitPosition.left,
          child: SizedBox(
            width: 120,
            child: Text(
              "Browser left",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: WebViewSplitPosition.right,
          child: SizedBox(
            width: 120,
            child: Text(
              "Browser right",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _webViewProvider.splitScreenPosition = value!;
          if (value == WebViewSplitPosition.off) {
            _webViewProvider.browserShowInForeground = false;
          } else {
            if (MediaQuery.sizeOf(context).width > 800) {
              _webViewProvider.webViewSplitActive = true;

              // Force stackview convertion from Container if it still hasn't happened
              _webViewProvider.browserForegroundWithSplitTransition();
            }
          }
        });
      },
    );
  }

  DropdownButton _manualAppIconDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.dynamicAppIconsManual,
      items: const [
        DropdownMenuItem(
          value: "off",
          child: SizedBox(
            width: 120,
            child: Text(
              "Off",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "awareness",
          child: SizedBox(
            width: 120,
            child: Text(
              "Awareness",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "halloween",
          child: SizedBox(
            width: 120,
            child: Text(
              "Halloween",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "christmas",
          child: SizedBox(
            width: 120,
            child: Text(
              "Christmas",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "stvalentine",
          child: SizedBox(
            width: 120,
            child: Text(
              "Valentine's Day",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "stpatrick",
          child: SizedBox(
            width: 120,
            child: Text(
              "St. Patrick's Day",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "easter",
          child: SizedBox(
            width: 120,
            child: Text(
              "Easter Egg Hunt",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _settingsProvider.dynamicAppIconsManual = value;
          _settingsProvider.appIconChangeBasedOnCondition();
        });
      },
    );
  }

  DropdownButton _splitScreenRevertionDropdown() {
    return DropdownButton<bool>(
      value: _webViewProvider.splitScreenRevertsToApp,
      items: const [
        DropdownMenuItem(
          value: true,
          child: SizedBox(
            width: 80,
            child: Text(
              "App",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        DropdownMenuItem(
          value: false,
          child: SizedBox(
            width: 80,
            child: Text(
              "Browser",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _webViewProvider.splitScreenRevertsToApp = value!;
        });
      },
    );
  }

  DropdownButton _openSectionDropdown() {
    return DropdownButton<String>(
      value: _openSectionValue,
      items: const [
        DropdownMenuItem(
          value: "browser",
          child: SizedBox(
            width: 80,
            child: Text(
              "Browser",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "browser_full",
          child: SizedBox(
            width: 80,
            child: Text(
              "Browser (full screen)",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "Profile",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 80,
            child: Text(
              "Travel",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "2",
          child: SizedBox(
            width: 80,
            child: Text(
              "Chaining",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "3",
          child: SizedBox(
            width: 80,
            child: Text(
              "Loot",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "4",
          child: SizedBox(
            width: 80,
            child: Text(
              "Friends",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "5",
          child: SizedBox(
            width: 80,
            child: Text(
              "Stakeouts",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "6",
          child: SizedBox(
            width: 80,
            child: Text(
              "Awards",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "7",
          child: SizedBox(
            width: 80,
            child: Text(
              "Items",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        Prefs().setDefaultSection(value!);
        setState(() {
          _openSectionValue = value;
        });
      },
    );
  }

  DropdownButton _backButtonAppExitDropdown() {
    return DropdownButton<String>(
      value: _onAppExitValue,
      items: const [
        DropdownMenuItem(
          value: "stay",
          child: SizedBox(
            width: 60,
            child: Text(
              "Stay",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "exit",
          child: SizedBox(
            width: 60,
            child: Text(
              "Exit",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        _settingsProvider.changeOnAppExit = value;
        setState(() {
          _onAppExitValue = value;
        });
      },
    );
  }

  DropdownButton _openBrowserDropdown() {
    return DropdownButton<String>(
      value: _openBrowserValue,
      items: const [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 65,
            child: Text(
              "In-App",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 65,
            child: Text(
              "External",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) async {
        if (value == '0') {
          _settingsProvider.changeBrowser = BrowserSetting.app;
        } else {
          _settingsProvider.changeBrowser = BrowserSetting.external;

          if (Platform.isAndroid) {
            await showDialog(
              useRootNavigator: false,
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AppLinksBrowserDialog();
              },
            );
          }
        }
        setState(() {
          _openBrowserValue = value;
        });
      },
    );
  }

  DropdownButton _timeFormatDropdown() {
    return DropdownButton<String>(
      value: _timeFormatValue,
      items: const [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 60,
            child: Text(
              "24 hours",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 60,
            child: Text(
              "12 hours",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == '0') {
          _settingsProvider.changeTimeFormat = TimeFormatSetting.h24;
        } else {
          _settingsProvider.changeTimeFormat = TimeFormatSetting.h12;
        }
        setState(() {
          _timeFormatValue = value;
        });
      },
    );
  }

  DropdownButton _timeZoneDropdown() {
    return DropdownButton<String>(
      value: _timeZoneValue,
      items: const [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 135,
            child: Text(
              "Local Time (LT)",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 135,
            child: Text(
              "Torn City Time (TCT)",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == '0') {
          _settingsProvider.changeTimeZone = TimeZoneSetting.localTime;
        } else {
          _settingsProvider.changeTimeZone = TimeZoneSetting.tornTime;
        }
        setState(() {
          _timeZoneValue = value;
        });
      },
    );
  }

  DropdownButton _dateInClockDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.showDateInClock,
      items: const [
        DropdownMenuItem(
          value: "off",
          child: SizedBox(
            width: 80,
            child: Text(
              "Off",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "dayfirst",
          child: SizedBox(
            width: 80,
            child: Text(
              "On (d/m)",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "monthfirst",
          child: SizedBox(
            width: 80,
            child: Text(
              "On (m/d)",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeShowDateInClock = value!;
        });
      },
    );
  }

  DropdownButton _secondsInClockDropdown() {
    return DropdownButton<bool>(
      value: _settingsProvider.showSecondsInClock,
      items: const [
        DropdownMenuItem(
          value: true,
          child: SizedBox(
            width: 60,
            child: Text(
              "Show",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: false,
          child: SizedBox(
            width: 60,
            child: Text(
              "Hide",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeShowSecondsInClock = value!;
        });
      },
    );
  }

  Widget _vibrationDropdown() {
    if (_androidSdk < 26) {
      return const Text(
        'This functionality is only available in Android 8 (API 26 - Oreo) or higher, sorry!',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
        ),
      );
    }

    return DropdownButton<String>(
      value: _vibrationValue,
      items: const [
        DropdownMenuItem(
          value: "no-vib",
          child: SizedBox(
            width: 80,
            child: Text(
              "Off",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "short",
          child: SizedBox(
            width: 80,
            child: Text(
              "Short",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "medium",
          child: SizedBox(
            width: 80,
            child: Text(
              "Medium",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "long",
          child: SizedBox(
            width: 80,
            child: Text(
              "Long",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) async {
        // Deletes current channels and create new ones
        reconfigureNotificationChannels(mod: value);
        // Update channel preferences
        FirestoreHelper().setVibrationPattern(value);
        Prefs().setVibrationPattern(value!);
        setState(() {
          _vibrationValue = value;
        });

        if ((await Vibration.hasVibrator())) {
          if (value == 'short') {
            Vibration.vibrate(pattern: [0, 400]);
          } else if (value == 'medium') {
            Vibration.vibrate(pattern: [0, 400, 400, 400, 400]);
          } else if (value == 'long') {
            Vibration.vibrate(pattern: [0, 400, 400, 600, 400, 800, 400, 1000]);
          }
        }
      },
    );
  }

  DropdownButton _spiesSourceDropdown() {
    return DropdownButton<SpiesSource>(
      value: _spyController.spiesSource,
      items: const [
        DropdownMenuItem(
          value: SpiesSource.yata,
          child: SizedBox(
            width: 85,
            child: Text(
              "YATA",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: SpiesSource.tornStats,
          child: SizedBox(
            width: 85,
            child: Text(
              "Torn Stats",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          if (value == SpiesSource.yata) {
            _spyController.spiesSource = SpiesSource.yata;
          } else {
            _spyController.spiesSource = SpiesSource.tornStats;
          }
        });
      },
    );
  }

  DropdownButton _naturalNerveBarSourceDropdown() {
    return DropdownButton<NaturalNerveBarSource>(
      value: _settingsProvider.naturalNerveBarSource,
      items: const [
        DropdownMenuItem(
          value: NaturalNerveBarSource.off,
          child: SizedBox(
            width: 85,
            child: Text(
              "Disabled",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: NaturalNerveBarSource.yata,
          child: SizedBox(
            width: 85,
            child: Text(
              "YATA",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: NaturalNerveBarSource.tornStats,
          child: SizedBox(
            width: 85,
            child: Text(
              "Torn Stats",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          if (value == NaturalNerveBarSource.yata) {
            _settingsProvider.naturalNerveBarSource = NaturalNerveBarSource.yata;
          } else if (value == NaturalNerveBarSource.tornStats) {
            _settingsProvider.naturalNerveBarSource = NaturalNerveBarSource.tornStats;
          } else {
            _settingsProvider.naturalNerveBarSource = NaturalNerveBarSource.off;
          }
        });
      },
    );
  }

  DropdownButton _themeToSyncDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.darkThemeToSyncFromWeb,
      items: const [
        DropdownMenuItem(
          value: "dark",
          child: SizedBox(
            width: 100,
            child: Text(
              "Dark",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "extraDark",
          child: SizedBox(
            width: 100,
            child: Text(
              "Extra Dark",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _settingsProvider.darkThemeToSyncFromWeb = value;
        });
      },
    );
  }

  DropdownButton _appBarPositionDropdown() {
    return DropdownButton<String>(
      value: _appBarPosition,
      items: const [
        DropdownMenuItem(
          value: "top",
          child: SizedBox(
            width: 58,
            child: Text(
              "Top",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "bottom",
          child: SizedBox(
            width: 58,
            child: Text(
              "Bottom",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == "top") {
          _settingsProvider.changeAppBarTop = true;
        } else {
          _settingsProvider.changeAppBarTop = false;
        }
        setState(() {
          _appBarPosition = value;
          if (value == "bottom") {
            _extraMargin = 50;
          }
        });
      },
    );
  }

  Future<void> _getApiDetails({required bool userTriggered, required String currentKey}) async {
    int errorPlayerId = 0;
    dynamic firebaseErrorUser;

    try {
      setState(() {
        _apiIsLoading = true;
      });

      final dynamic myProfile = await ApiCallsV1.getOwnProfileBasic(forcedApiKey: currentKey);
      if (myProfile is OwnProfileBasic) {
        myProfile
          ..userApiKey = currentKey
          ..userApiKeyValid = true;
        UserHelper.setUserDetails(userDetails: myProfile);

        setState(() {
          _apiIsLoading = false;
          _apiError = false;
          _userProfile = myProfile;
        });

        final uc = Get.find<UserController>();
        if (uc.playerId == 0 && myProfile.playerId != null) {
          uc.playerId = myProfile.playerId!;
          uc.apiKey = myProfile.userApiKey;
          uc.playerName = myProfile.name!;
          uc.factionId = myProfile.faction?.factionId ?? 0;
          uc.companyId = myProfile.job?.companyId ?? 0;
        }

        errorPlayerId = uc.playerId;

        // Firestore uploading, but only if "Load" pressed by user
        if (userTriggered) {
          setState(() {
            _expandableController.expanded = false;
          });

          if (!Platform.isWindows) {
            // See note in [firebase_auth.dart]
            final firebaseUser = firebaseErrorUser = await firebaseAuth.getUID();
            // Only sign in if there is currently no user registered (to avoid duplicates)
            if (firebaseUser == null || (firebaseUser is User && firebaseUser.uid.isEmpty)) {
              final User? newFirebaseUser = await (firebaseAuth.signInAnon());

              if (newFirebaseUser == null) {
                throw Exception("Firebase anonymous sign-in failed");
              }

              await FirestoreHelper().setUID(newFirebaseUser.uid);
              // Returns UID to Drawer so that it can be passed to settings
              widget.changeUID(newFirebaseUser.uid);
              log("Settings: signed in with UID ${newFirebaseUser.uid}");
            } else {
              log("Settings: existing user UID ${firebaseUser.uid}");
            }

            await FirestoreHelper().uploadUsersProfileDetail(myProfile, userTriggered: true);
            await FirestoreHelper().uploadLastActiveTimeAndTokensToFirebase(DateTime.now().millisecondsSinceEpoch);
            if (Platform.isAndroid) {
              FirestoreHelper().setVibrationPattern(_vibrationValue);
            }

            // Sendbird notifications
            final sbController = Get.find<SendbirdController>();
            sbController.register();
          } else {
            log("Windows: skipping Firestore sign up!");
          }

          // Signal stat counter initialization
          widget.statsController.logFirstLoginEver();

          // Update the home widget if it's installed
          if (Platform.isAndroid) {
            if ((await pdaWidget_numberInstalled()).isNotEmpty) {
              fetchAndPersistWidgetData();
            }
          }
        }
      } else if (myProfile is ApiError) {
        setState(() {
          _apiIsLoading = false;
          _userProfile = null;
          _apiError = true;
          _errorReason = myProfile.errorReason;
          _errorDetails = myProfile.pdaErrorDetails;
          _expandableController.expanded = true;
        });
        // We'll only remove the user if the key is invalid, otherwise we
        // risk removing it if we access the Settings page with no internet
        // connectivity
        if (myProfile.errorId == 2) {
          UserHelper.removeUser();
        }
      }
    } catch (e, stack) {
      if (!Platform.isWindows) {
        String currentKey = _apiKeyInputController.text.trim();
        FirebaseCrashlytics.instance.log("PDA Crash at LOAD API KEY. User $currentKey. "
            "Error: $e. Stack: $stack");
        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          information: ['API Key: $currentKey', 'ID: $errorPlayerId', 'Firebase User UID: ${firebaseErrorUser.uid}'],
        );
      }
    }
  }

  Future _restorePreferences() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _androidSdk = androidInfo.version.sdkInt;
    }

    await Prefs().getDefaultSection().then((onValue) {
      setState(() {
        _openSectionValue = onValue;
      });
    });

    if (UserHelper.isApiKeyValid) {
      String savedKey = UserHelper.apiKey;
      setState(() {
        _apiKeyInputController.text = UserHelper.apiKey;
        _apiIsLoading = true;
      });
      _getApiDetails(userTriggered: false, currentKey: savedKey);
    }

    final onAppExit = _settingsProvider.onBackButtonAppExit;
    setState(() {
      switch (onAppExit) {
        case 'exit':
          _onAppExitValue = 'exit';
        case 'stay':
          _onAppExitValue = 'stay';
      }
    });

    final browser = _settingsProvider.currentBrowser;
    setState(() {
      switch (browser) {
        case BrowserSetting.app:
          _openBrowserValue = '0';
        case BrowserSetting.external:
          _openBrowserValue = '1';
      }
    });

    final timeFormat = _settingsProvider.currentTimeFormat;
    setState(() {
      switch (timeFormat) {
        case TimeFormatSetting.h24:
          _timeFormatValue = '0';
        case TimeFormatSetting.h12:
          _timeFormatValue = '1';
      }
    });

    final timeZone = _settingsProvider.currentTimeZone;
    setState(() {
      switch (timeZone) {
        case TimeZoneSetting.localTime:
          _timeZoneValue = '0';
        case TimeZoneSetting.tornTime:
          _timeZoneValue = '1';
      }
    });

    final appBarPosition = _settingsProvider.appBarTop;
    setState(() {
      appBarPosition ? _appBarPosition = 'top' : _appBarPosition = 'bottom';
    });

    final alertsVibration = await Prefs().getVibrationPattern();
    final manualAlarmSound = await Prefs().getManualAlarmSound();
    final manualAlarmVibration = await Prefs().getManualAlarmVibration();

    setState(() {
      _removeNotificationsLaunch = _settingsProvider.removeNotificationsOnLaunch;
      _vibrationValue = alertsVibration;
      _manualAlarmSound = manualAlarmSound;
      _manualAlarmVibration = manualAlarmVibration;
    });
  }

  DropdownButton _shortcutTileDropdown() {
    return DropdownButton<String>(
      value: _shortcutsProvider.shortcutTile,
      items: const [
        DropdownMenuItem(
          value: "both",
          child: SizedBox(
            width: 90,
            child: Text(
              "Icon and text",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "icon",
          child: SizedBox(
            width: 90,
            child: Text(
              "Only icon",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "text",
          child: SizedBox(
            width: 90,
            child: Text(
              "Only text",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _shortcutsProvider.changeShortcutTile(value!);
        });
      },
    );
  }

  DropdownButton _shortcutMenuDropdown() {
    return DropdownButton<String>(
      value: _shortcutsProvider.shortcutMenu,
      items: const [
        DropdownMenuItem(
          value: "carousel",
          child: SizedBox(
            width: 67,
            child: Text(
              "Carousel",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "grid",
          child: SizedBox(
            width: 67,
            child: Text(
              "Grid",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _shortcutsProvider.changeShortcutMenu(value!);
        });
      },
    );
  }

  Widget _appWidgetCooldownTapDestinationSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Flexible(
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_right_outlined),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      "Cooldown tap opens",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _settingsProvider.appwidgetCooldownTapOpenBrowserDestination,
            items: const [
              DropdownMenuItem(
                value: "own",
                child: SizedBox(
                  width: 110,
                  child: Text(
                    "Own items",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              DropdownMenuItem(
                value: "faction",
                child: SizedBox(
                  width: 110,
                  child: Text(
                    "Faction items",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) async {
              setState(() {
                _settingsProvider.appwidgetCooldownTapOpenBrowserDestination = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadRefreshRateInfo() async {
    try {
      final info = await _settingsProvider.getRefreshRateInfo();
      if (mounted) {
        setState(() {
          _refreshRateInfo = info;
        });
      }
    } catch (e) {
      log('Error loading refresh rate info: $e');
    }
  }

  Future<void> _updateRefreshRateAfterChange() async {
    setState(() {
      _isUpdatingRefreshRate = true;
    });

    // Wait for the settings to take effect
    await Future.delayed(const Duration(milliseconds: 1000));
    await _loadRefreshRateInfo();

    if (mounted) {
      setState(() {
        _isUpdatingRefreshRate = false;
      });
    }
  }
}

class SearchableRow extends StatelessWidget {
  // [filterable] allows certain rows (such as explanatory text)
  // to be excluded from filtering, so they only show when there's no active query
  final String label;
  final bool filterable;
  final Widget child;
  final String searchText;

  const SearchableRow({
    super.key,
    required this.label,
    required this.child,
    required this.searchText,
    this.filterable = true,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

Widget buildSectionWithRows({
  required String title,
  required List<SearchableRow> rows,
  required String searchText,
}) {
  // "showAll" forces all rows to be visible if the section title matches the search text
  // This ensures a search for the section name displays all rows in that section.
  bool showAll = searchText.isNotEmpty && title.toLowerCase().contains(searchText.toLowerCase());

  // For each filterable row, we show it if there's no search query,
  // or if its label contains the search text, or if showAll is true
  List<bool> isVisible = List.filled(rows.length, false);
  for (int i = 0; i < rows.length; i++) {
    SearchableRow row = rows[i];
    if (row.filterable) {
      isVisible[i] = searchText.isEmpty || row.label.toLowerCase().contains(searchText.toLowerCase()) || showAll;
    } else {
      isVisible[i] = searchText.isEmpty || (i > 0 && isVisible[i - 1]);
    }
  }

  List<Widget> visibleWidgets = [];
  for (int i = 0; i < rows.length; i++) {
    if (isVisible[i]) {
      visibleWidgets.add(rows[i].child);
    }
  }

  if (visibleWidgets.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section title is always displayed when the section has visible content
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10)),
        ],
      ),
      ...visibleWidgets,
    ],
  );
}
