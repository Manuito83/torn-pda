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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/oc/ts_members_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/pages/settings/alternative_keys_page.dart';
import 'package:torn_pda/pages/settings/settings_browser.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_login_widget.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/appwidget/pda_widget.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/alerts/discreet_info.dart';
import 'package:torn_pda/widgets/settings/applinks_browser_dialog.dart';
import 'package:torn_pda/widgets/settings/backup/backup_delete_dialog.dart';
import 'package:torn_pda/widgets/settings/backup/backup_restore_dialog.dart';
import 'package:torn_pda/widgets/settings/backup/backup_save_dialog.dart';
import 'package:torn_pda/widgets/settings/backup/backup_share_dialog.dart';
import 'package:torn_pda/widgets/settings/browser_info_dialog.dart';
import 'package:torn_pda/widgets/settings/reviving_services_dialog.dart';
import 'package:torn_pda/widgets/spies/spies_management_dialog.dart';
import 'package:torn_pda/widgets/stats/tsc_info.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
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

  String? _myCurrentKey = '';
  bool _userToLoad = false;
  bool _apiError = false;
  String _errorReason = '';
  String _errorDetails = '';
  bool _apiIsLoading = false;
  late OwnProfileBasic _userProfile;

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
  late UserDetailsProvider _userProvider;
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

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    _preferencesRestored = _restorePreferences();
    _ticker = Timer.periodic(const Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
    analytics?.logScreenView(screenName: 'settings');

    routeWithDrawer = true;
    routeName = "settings";
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      endDrawer: !_webViewProvider.splitScreenAndBrowserLeft() ? null : const Drawer(),
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
                      _apiKeyWidget(),
                      const SizedBox(height: 15),
                      if (_userToLoad)
                        const Column(
                          children: [
                            NativeLoginWidget(),
                            SizedBox(height: 15),
                          ],
                        ),
                      _browserSection(context),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _shortcutsSection(context),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _timeSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _notificationsSection(context),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      if (Platform.isAndroid)
                        Column(
                          children: [
                            _appWidgetSection(context),
                            const SizedBox(height: 15),
                            const Divider(),
                            const SizedBox(height: 5),
                          ],
                        ),
                      _spiesSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _statsSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _ocSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _revivingServicesSection(context),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _screenConfigurationSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _themeSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      if (Platform.isIOS)
                        Column(
                          children: [
                            _appIconSection(),
                            const SizedBox(height: 15),
                            const Divider(),
                            const SizedBox(height: 5),
                          ],
                        ),
                      _miscSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _externalPartnersSection(context),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      _apiRateSection(),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      // Cloud functions are not supported on Windows
                      Column(
                        children: [
                          _saveSettingsSection(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 5),
                        ],
                      ),
                      _troubleshootingSection(),
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

  Column _browserSection(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'BROWSER',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Flexible(
                    child: Text(
                      "Web browser",
                    ),
                  ),
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
              Flexible(
                child: _openBrowserDropdown(),
              ),
            ],
          ),
        ),
        if (_openBrowserValue == "0")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  "Advanced browser settings",
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => SettingsBrowserPage(userDetailsProvider: _userProvider),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Column _timeSection() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TIME',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Time format",
                ),
              ),
              Flexible(
                child: _timeFormatDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Time zone",
                ),
              ),
              Flexible(
                flex: 2,
                child: _timeZoneDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Show date in clock",
                ),
              ),
              Flexible(
                flex: 2,
                child: _dateInClockDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Add an extra row for the date wherever the TCT clock is shown. You can also specify '
                  'the desired format (day/month or month/day)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Seconds in clock",
                ),
              ),
              Flexible(
                flex: 2,
                child: _secondsInClockDropdown(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column _spiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SPIES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Spies source",
                ),
              ),
              Flexible(
                flex: 2,
                child: _spiesSourceDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Choose the source of spied stats. This affects the stats shown when you visit a profile '
            'in the browser, as well as those shown in the War section (Chaining)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        GetBuilder<SpiesController>(
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
              spiesUpdateColor = (lastUpdatedTs < oneMonthAgo) ? Colors.red : context.read<ThemeProvider>().mainText!;
            }

            return Padding(
              padding: const EdgeInsets.only(top: 15, left: 40),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(MdiIcons.accountMultipleOutline, size: 18),
                      ),
                      Text(
                        "${s.spiesSource == SpiesSource.yata ? 'YATA' : 'Torn Stats'} database: "
                        "${s.spiesSource == SpiesSource.yata ? s.yataSpies.length : s.tornStatsSpies.spies.length} spies",
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(MdiIcons.clockOutline, size: 18),
                      ),
                      Text(
                        lastUpdated,
                        style: TextStyle(color: spiesUpdateColor),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Manage spies",
                ),
              ),
              IconButton(
                icon: Icon(MdiIcons.incognito),
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
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        "Allow mixed sources",
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _spyController.allowMixedSpiesSources,
                onChanged: (enabled) async {
                  setState(() {
                    _spyController.allowMixedSpiesSources = enabled;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "If enabled, if a target's spy information cannot be found in the preferred spies source, it will also "
            "be taken from the other source if available. When switching from one source to the other, the spy "
            "information is preserved unless the new active source also contains a spy for a target",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        "Delete spies",
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                child: const Icon(Icons.delete_outlined),
                onPressed: () async {
                  _spyController.deleteSpies();

                  BotToast.showText(
                    text: "Spies deleted!",
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.blue,
                    duration: const Duration(seconds: 1),
                    contentPadding: const EdgeInsets.all(10),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Deletes all the spies information available in the local database if case you would prefer not to use '
            'spies information or if there is a problem with the information and stats downloaded',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _statsSection() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'STATS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        if (_settingsProvider.tscEnabledStatusRemoteConfig)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Row(
                        children: [
                          const Flexible(
                            child: Text(
                              "Use Torn Spies Central",
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            child: Icon(Icons.info_outline, size: 18),
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
                          )
                        ],
                      ),
                    ),
                    Switch(
                      value: _settingsProvider.tscEnabledStatus == 1 ? true : false,
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
                            setState(() {
                              // Force switch update as we are not listening the provider
                            });
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Enable Torn Spies Central estimations in the sections where spied or estimated stats are shown (e.g.: '
                  'war targets cards, retal cards or profile widget)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Row(
              children: [
                Text(
                  "TSC temporarily deactivated",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        if (_settingsProvider.yataStatsEnabledStatusRemoteConfig)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Row(
                        children: [
                          const Flexible(
                            child: Text(
                              "Use YATA stats estimates",
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _settingsProvider.yataStatsEnabledStatus == 1 ? true : false,
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Enable YATA stats estimations in the sections where spied or estimated stats are shown (e.g.: '
                  'war targets cards, retal cards or profile widget)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Row(
              children: [
                Text(
                  "YATA stats temporarily deactivated",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Column _ocSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ORGANIZED CRIMES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Nerve bar source",
                ),
              ),
              Flexible(
                flex: 2,
                child: _naturalNerveBarSourceDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Choose the source of the Natural Nerve Bar (NNB) that will be shown for each '
            'member of your faction available to plan an organized crime',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _apiRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'API CALL RATE',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Display API call rate",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Enables a small progress bar on top of Torn PDA's logo in the main drawer menu, with real-time count "
            "of the number of API calls performed in the last minute",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Warn max. call rate",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "If enabled, a quick message will be shown when approaching (95 calls in 60 seconds) the maximum "
            "API call rate. This message will be then inhibited for 30 seconds",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Delay API calls",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Artificially delay API calls above 95 in 60 seconds to avoid hitting the max API rate. If enabled, the "
            "current queue information will be shown in the main drawer menu API bar. NOTE: this option cannot take "
            "into account API calls generated outside of Torn PDA",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _saveSettingsSection() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ONLINE BACKUP',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        if (!_settingsProvider.backupPrefsEnabledStatusRemoteConfig)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
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
        if (_settingsProvider.backupPrefsEnabledStatusRemoteConfig)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Upload settings",
                      ),
                    ),
                    ElevatedButton(
                      child: const Icon(Icons.upload),
                      onPressed: () {
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) {
                            return BackupSaveDialog(userProfile: _userProfile);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "This will allow you to backup your main app settings (e.g.: scripts, shortcuts, etc.) locally so"
                  "that you can later restore them if needed or share them across different devices",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Restore settings",
                      ),
                    ),
                    ElevatedButton(
                      child: const Icon(Icons.download),
                      onPressed: () {
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) {
                            return BackupRestoreDialog(userProfile: _userProfile);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "This will download your saved settings and restore them in the app. Please be aware that this will "
                  "overwritte your current preferences",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Share settings",
                      ),
                    ),
                    ElevatedButton(
                      child: const Icon(Icons.share),
                      onPressed: () {
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) {
                            return BackupShareDialog(
                              userProfile: _userProfile,
                              themeProvider: _themeProvider,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "This will allow you to share your settings and receive settings from other players with the use "
                  "of the player ID and a password",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Clear backup",
                      ),
                    ),
                    ElevatedButton(
                      child: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) {
                            return BackupDeleteDialog(userProfile: _userProfile);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "In case there is something wrong with your online backup when trying to restore it, or you want to "
                  "clear it for any other reason, this will delete the online saved data",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Column _troubleshootingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TROUBLESHOOTING',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Test API",
                ),
              ),
              ElevatedButton(
                child: const Text("PING"),
                onPressed: () async {
                  BotToast.showText(
                    text: "Please wait...",
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
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
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "In case that you are facing connection problems, this will ping Torn's API and show whether "
            "it is reachable from your device. If it isn't, it might be because of your DNS servers (you "
            "can try switching from WiFi to data)",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Enable debug messages",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Enable specific debug messages for app failure testing. This is an advanced feature that might create '
            'additional error messages: avoid using it unless you have been requested to do so',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Reset tutorials",
                ),
              ),
              ElevatedButton(
                child: const Text("CLEAR"),
                onPressed: () async {
                  _settingsProvider.clearShowCases();
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "This will clear all the app's tutorial pop-ups in case that you want to review them again. Be aware that "
            "some of them (e.g.: those in the browser) will require an app restart to complete reset.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _externalPartnersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'EXTERNAL PARTNERS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                "Alternative API keys",
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Use this section to configure alternative API keys for the external partners that "
            "Torn PDA connects with. CAUTION: ensure this other keys are working correctly, as Torn PDA "
            "won't be able to check for errors and certain sections might stop working",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _shortcutsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SHORTCUTS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
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
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Enable configurable shortcuts in the Profile section to quickly access your favorite sections in Torn',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_settingsProvider.shortcutsEnabledProfile)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Profile shortcuts menu",
                      ),
                    ),
                    Flexible(
                      child: _shortcutMenuDropdown(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Profile tile type",
                      ),
                    ),
                    Flexible(
                      child: _shortcutTileDropdown(),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Column _screenConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SCREEN CONFIGURATION',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Allow auto rotation",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'If enabled, the interface will rotate from portrait to landscape if the device is rotated. '
            'Be aware that landscape might not be comfortable in narrow mobile devices (e.g. some dialogs will need '
            'to be manually scrolled and some elements might look too big)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Split screen",
                ),
              ),
              Flexible(
                flex: 2,
                child: _splitScreenDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'If enabled, the device screen will be splitted to show the main app the the browser at the same time. '
            'A minimum width (800 dpi) is needed for this to be allowed',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Split reverts to",
                ),
              ),
              Flexible(
                flex: 2,
                child: _splitScreenRevertionDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'When the split screen condition is no longer active (e.g.: if the device is rotated and the width is '
            'loweer than 800 dpi), this option dictates whether the webview or the app should remain in the foreground',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _themeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'THEME',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text(
            "Please note that the main theme selector switch is located in the drawer menu of Torn PDA. Here you "
            "will be able to select other theming options",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Use Material theme",
                ),
              ),
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
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Sync app with device theme",
                ),
              ),
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
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Sync app and web themes",
                ),
              ),
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
        if (_settingsProvider.syncTornWebTheme)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Dark theme equivalent",
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: _themeToSyncDropdown(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Specifies which of the two dark themes is activated in the app when the web or your device themes "
                  "(depending on the options above) are switched to dark",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Column _appIconSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'APP ICON',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Dynamic app icons",
                ),
              ),
              Switch(
                value: !_settingsProvider.dynamicAppIconEnabledRemoteConfig ? false : _settingsProvider.dynamicAppIcons,
                onChanged: !_settingsProvider.dynamicAppIconEnabledRemoteConfig
                    ? null
                    : (enabled) async {
                        setState(() {
                          _settingsProvider.dynamicAppIcons = enabled;
                        });

                        if (enabled) {
                          // Set an alternate icon
                          _settingsProvider.appIconChangeBasedOnCondition();
                        } else {
                          // Reset to the default icon
                          _settingsProvider.appIconResetDefault();
                        }
                      },
                activeTrackColor:
                    _settingsProvider.dynamicAppIconEnabledRemoteConfig ? Colors.lightGreenAccent : Colors.grey[700],
                activeColor: _settingsProvider.dynamicAppIconEnabledRemoteConfig ? Colors.green : Colors.grey[700],
                inactiveThumbColor: _settingsProvider.dynamicAppIconEnabledRemoteConfig ? null : Colors.grey[800],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        if (!_settingsProvider.dynamicAppIconEnabledRemoteConfig ? false : _settingsProvider.dynamicAppIcons)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Flexible(
                  child: Text(
                    "Override icon",
                  ),
                ),
                Flexible(
                  child: _manualAppIconDropdown(),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "By using this option, you can manually trigger (some) app icons even if the conditions "
                "are not met",
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
      ],
    );
  }

  Column _miscSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MISC',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Show status color counter",
                ),
              ),
              Switch(
                value: context.read<ChainStatusProvider>().statusColorWidgetEnabled,
                onChanged: (value) {
                  setState(() {
                    context.read<ChainStatusProvider>().statusColorWidgetEnabled = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Shows a player status counter attached to the Torn PDA icon in the main app sections and in the browser '
            'three-dotted icon, whenever the player is hospitalised, jailed or traveling',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "App bar position",
                ),
              ),
              Flexible(
                flex: 2,
                child: _appBarPositionDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Note: this will affect other quick access items such as '
            'the quick crimes bar in the browser',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Default launch section",
                ),
              ),
              Flexible(
                child: _openSectionDropdown(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Back button exits app",
                ),
              ),
              Flexible(
                child: _backButtonAppExitDropdown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "This will only have effect in certain devices, depending on "
            "your configuration. Dictates how to proceed when the app detects a back button "
            "press or swipe that would otherwise close the app. Note: while in the browser, the back button will "
            "always trigger backwards navigation",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _revivingServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'REVIVING SERVICES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                "Choose reviving providers",
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Choose which reviving services you might want to use. "
            "If enabled, when you are in hospital you'll have the option to call "
            "one of their revivers from several places (e.g. Profile and Chaining sections).",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _notificationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NOTIFICATIONS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        "Discreet notifications",
                      ),
                    ),
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
                    FirestoreHelper().toggleDiscreet(value);
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        if (Platform.isAndroid)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Remove notifications on launch",
                      ),
                    ),
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'This will remove all Torn PDA notifications from your notifications bar '
                  'when you launch the app. Deactivate it if you would prefer to keep them '
                  'and erase them later manually',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Alerts vibration",
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 20),
                    ),
                    Flexible(
                      flex: 2,
                      child: _vibrationDropdown(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'This vibration applies to the automatic alerts only, with the '
                  'app in use or in the background',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  text: TextSpan(
                    text: 'Applies to manually activated alarms in all sections '
                        '(Travel, Loot, Profile, etc.). '
                        'Some Android clock applications do not work well '
                        'with more than 1 timer or do not allow to choose '
                        'between sound and vibration for alarms. If you experience '
                        'any issue, it is recommended to install ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Google's Clock application",
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const AndroidIntent intent = AndroidIntent(
                              action: 'action_view',
                              data: 'https://play.google.com/store'
                                  '/apps/details?id=com.google.android.deskclock',
                            );
                            await intent.launch();
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
      ],
    );
  }

  Column _appWidgetSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HOME SCREEN WIDGET',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Dark mode",
                ),
              ),
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
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Remove shortcuts from short layout",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'By default, the short, one-row layout, accomodates a couple of shortcuts by sacrificing the chaining '
            'information and moving the reload icon to the top. By enabling this, this particular layout will not '
            'include shortcuts in order to make more space for the chaining bar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Show wallet money",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'This is only applicable for the tall widget layout',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text(
                  "Cooldown tap launches browser",
                ),
              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'If enabled, a tap on any of the cooldown icons will launch the app and browser to your personal '
            'or faction items. Otherwise, you will be shown the cooldown time remaining. NOTE: you might have '
            'to try a couple of times after switching this option for the widget to update properly',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_settingsProvider.appwidgetCooldownTapOpenBrowser) _appWidgetCooldownTapDestinationSelector(),
      ],
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      title: const Text('Settings', style: TextStyle(color: Colors.white)),
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
          if (!_webViewProvider.webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _expandableController.dispose();
    _apiKeyInputController.dispose();
    super.dispose();
  }

  Widget _apiKeyWidget() {
    if (_apiIsLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      );
    }
    if (_userToLoad) {
      _expandableController.expanded = false;
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Card(
          child: ExpandablePanel(
            collapsed: Container(),
            header: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Text(
                        "TORN API USER LOADED",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      "${_userProfile.name} [${_userProfile.playerId}]",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _apiKeyForm(enabled: false),
                          const Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: const Text(
                                  "Copy",
                                  style: TextStyle(fontSize: 13),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _userProfile.userApiKey.toString()));
                                  BotToast.showText(
                                    text: "API key copied to the clipboard, be careful!",
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.blue,
                                    duration: const Duration(seconds: 4),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: const Text(
                                    "Reload",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  onPressed: () {
                                    FocusScope.of(context).requestFocus(FocusNode());
                                    if (_formKey.currentState!.validate()) {
                                      _myCurrentKey = _apiKeyInputController.text.trim();
                                      _getApiDetails(userTriggered: true);
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    FocusScope.of(context).requestFocus(FocusNode());
                                    // Removes the form error
                                    _formKey.currentState!.reset();
                                    _apiKeyInputController.clear();
                                    _myCurrentKey = '';
                                    _userProvider.removeUser();
                                    setState(() {
                                      _userToLoad = false;
                                      _apiError = false;
                                    });
                                    if (!Platform.isWindows) await FirebaseMessaging.instance.deleteToken();
                                    if (!Platform.isWindows) await FirestoreHelper().deleteUserProfile();
                                    if (!Platform.isWindows) await firebaseAuth.signOut();
                                    widget.changeUID("");
                                  },
                                ),
                              ),
                            ],
                          ),
                          _bottomExplanatory(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      _expandableController.expanded = true;
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: Card(
          child: ExpandablePanel(
            collapsed: Container(),
            controller: _expandableController,
            header: const Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "NO USER LOADED",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      "(expand for details)",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _apiKeyForm(enabled: true),
                          const Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: const Text("Load"),
                                onPressed: () {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                  if (_formKey.currentState!.validate()) {
                                    _myCurrentKey = _apiKeyInputController.text.trim();
                                    _getApiDetails(userTriggered: true);
                                  }
                                },
                              ),
                            ],
                          ),
                          _bottomExplanatory(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  SizedBox _apiKeyForm({required bool enabled}) {
    return SizedBox(
      width: 300,
      child: Form(
        key: _formKey,
        child: TextFormField(
          enabled: enabled,
          validator: (value) {
            if (value!.isEmpty) {
              return "The API Key is empty!";
            }
            return null;
          },
          controller: _apiKeyInputController,
          maxLength: 30,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Please insert your Torn API Key',
            hintStyle: const TextStyle(fontSize: 14),
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: const BorderSide(
                color: Colors.amber,
              ),
            ),
          ),
          // This is here in case the user submits from the keyboard and not
          // hitting the "Load" button
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(FocusNode());
            if (_formKey.currentState!.validate()) {
              _myCurrentKey = _apiKeyInputController.text.trim();
              _getApiDetails(userTriggered: true);
            }
          },
        ),
      ),
    );
  }

  Widget _bottomExplanatory() {
    if (_apiError) {
      return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsetsDirectional.only(bottom: 15),
              child: Text(
                "ERROR LOADING USER",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text("Error: $_errorReason"),
            if (_errorDetails.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _errorDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (_myCurrentKey == '') {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 30, 10, 0),
        child: Column(
          children: <Widget>[
            const Text(
              "Torn PDA needs your API Key to obtain your user's "
              'information. The key is protected in the app and will not '
              'be shared under any circumstances.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "\nYou can get your API key in the Torn website by tapping your profile picture (upper right corner)"
                        " and going to Settings, API Keys. Torn PDA only needs a Limited Access key.\n",
                      ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/preferences.php#tab=api';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/preferences.php#tab=api';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: const Text(
                                  'Tap here',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' to be redirected',
                              style: DefaultTextStyle.of(context).style,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Text('\nIn any case, please make sure to '
                "follow Torn's staff recommendations on how to protect your key "
                'from any malicious use.'),
            const Text('\nYou can always remove it from the '
                'app or reset it in your Torn preferences page.'),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: <Widget>[
            Text(
              "${_userProfile.name} [${_userProfile.playerId}]",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Gender: ${_userProfile.gender}"),
            Text("Level: ${_userProfile.level}"),
            Text("Life: ${_userProfile.life!.current}"),
            Text("Status: ${_userProfile.status!.description}"),
            Text("Last action: ${_userProfile.lastAction!.relative}"),
            Text("Rank: ${_userProfile.rank}"),
          ],
        ),
      );
    }
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

        if ((await Vibration.hasVibrator())!) {
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

  Future<void> _getApiDetails({required bool userTriggered}) async {
    try {
      setState(() {
        _apiIsLoading = true;
      });

      final dynamic myProfile = await ApiCallsV1.getOwnProfileBasic(forcedApiKey: _myCurrentKey);
      if (myProfile is OwnProfileBasic) {
        myProfile
          ..userApiKey = _myCurrentKey
          ..userApiKeyValid = true;
        _userProvider.setUserDetails(userDetails: myProfile);

        setState(() {
          _apiIsLoading = false;
          _userToLoad = true;
          _apiError = false;
          _userProfile = myProfile;
        });

        final uc = Get.find<UserController>();
        if (uc.playerId == 0 && myProfile.playerId != null) {
          uc.playerId = myProfile.playerId!;
          uc.apiKey = myProfile.userApiKey;
        }

        // Firestore uploading, but only if "Load" pressed by user
        if (userTriggered) {
          if (!Platform.isWindows) {
            // See note in [firebase_auth.dart]
            final user = await firebaseAuth.getUID();
            // Only sign in if there is currently no user registered (to avoid duplicates)
            if (user == null || (user is User && user.uid.isEmpty)) {
              final User mFirebaseUser = await (firebaseAuth.signInAnon());
              await FirestoreHelper().setUID(mFirebaseUser.uid);
              // Returns UID to Drawer so that it can be passed to settings
              widget.changeUID(mFirebaseUser.uid);
              log("Settings: signed in with UID ${mFirebaseUser.uid}");
            } else {
              log("Settings: existing user UID $user");
            }

            await FirestoreHelper().uploadUsersProfileDetail(myProfile, userTriggered: true);
            await FirestoreHelper().uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);
            if (Platform.isAndroid) {
              FirestoreHelper().setVibrationPattern(_vibrationValue);
            }

            // Sendbird notifications
            final sbController = Get.find<SendbirdController>();
            if (sbController.sendBirdNotificationsEnabled) {
              sbController.register();
            }
          } else {
            log("Windows: skipping Firestore sign up!");
          }

          // Signal stat counter initialization
          widget.statsController.logFirstLoginEver();

          // Update the home widget if it's installed
          if (Platform.isAndroid) {
            if ((await pdaWidget_numberInstalled()).isNotEmpty) {
              pdaWidget_fetchData();
            }
          }
        }
      } else if (myProfile is ApiError) {
        setState(() {
          _apiIsLoading = false;
          _userToLoad = false;
          _apiError = true;
          _errorReason = myProfile.errorReason;
          _errorDetails = myProfile.pdaErrorDetails;
          _expandableController.expanded = true;
        });
        // We'll only remove the user if the key is invalid, otherwise we
        // risk removing it if we access the Settings page with no internet
        // connectivity
        if (myProfile.errorId == 2) {
          _userProvider.removeUser();
        }
      }
    } catch (e, stack) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA Crash at LOAD API KEY. User $_myCurrentKey. "
            "Error: $e. Stack: $stack");
        FirebaseCrashlytics.instance.recordError(e, null);
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

    if (_userProvider.basic!.userApiKeyValid!) {
      setState(() {
        _apiKeyInputController.text = _userProvider.basic!.userApiKey!;
        _myCurrentKey = _userProvider.basic!.userApiKey;
        _apiIsLoading = true;
      });
      _getApiDetails(userTriggered: false);
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

  void _timerUpdateInformation() {
    if (_myCurrentKey != '') {
      _getApiDetails(userTriggered: false);
    }
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
          Flexible(
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_right_outlined),
                Flexible(
                  child: const Padding(
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
}
