// Flutter imports:
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/pages/profile/icons_filter_page.dart';
import 'package:torn_pda/pages/profile/profile_notifications_android.dart';
import 'package:torn_pda/pages/profile/profile_notifications_ios.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ProfileOptionsPage extends StatefulWidget {
  const ProfileOptionsPage({
    required this.apiValid,
    required this.user,
    required this.callBackTimings,
    this.statsData,
  });

  final bool apiValid;
  final OwnProfileExtended? user;
  final Function callBackTimings;
  final StatsChartTornStats? statsData;

  @override
  ProfileOptionsPageState createState() => ProfileOptionsPageState();
}

class ProfileOptionsPageState extends State<ProfileOptionsPage> {
  bool _showHeaderWallet = true;
  bool _showHeaderIcons = true;
  bool _dedicatedTravelCard = true;
  bool _disableTravelSection = false;
  bool _expandEvents = false;
  bool _expandMessages = false;
  bool _expandBasicInfo = false;
  bool _expandNetworth = false;

  List<String>? _sectionList;

  int _messagesNumber = 25;
  int _eventsNumber = 25;

  Future? _preferencesLoaded;

  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeWithDrawer = false;
    routeName = "profile_options";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "profile_options") _goBack();
    });
  }

  @override
  void dispose() {
    _willPopSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        routeWithDrawer = true;
        routeName = "profile_page";
      },
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : _themeProvider.canvas
            : _themeProvider.canvas,
        child: SafeArea(
          right: context.read<WebViewProvider>().webViewSplitActive &&
              context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
          left: context.read<WebViewProvider>().webViewSplitActive &&
              context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
          child: Scaffold(
            backgroundColor: _themeProvider.canvas,
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Builder(
              builder: (BuildContext context) {
                return Container(
                  color: _themeProvider.canvas,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                    child: FutureBuilder(
                      future: _preferencesLoaded,
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 15),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'MANUAL NOTIFICATIONS',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        "Timings and triggers",
                                        style: TextStyle(
                                          color: widget.apiValid ? _themeProvider.mainText : Colors.grey,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_arrow_right_outlined),
                                        onPressed: widget.apiValid
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) {
                                                      if (Platform.isAndroid) {
                                                        return ProfileNotificationsAndroid(
                                                          energyMax: widget.user!.energy!.maximum,
                                                          nerveMax: widget.user!.nerve!.maximum,
                                                          callback: widget.callBackTimings,
                                                        );
                                                      } else {
                                                        return ProfileNotificationsIOS(
                                                          energyMax: widget.user!.energy!.maximum,
                                                          nerveMax: widget.user!.nerve!.maximum,
                                                          callback: widget.callBackTimings,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                );
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'HEADER',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Show wallet"),
                                      Switch(
                                        value: _showHeaderWallet,
                                        onChanged: (value) {
                                          Prefs().setShowHeaderWallet(value);
                                          setState(() {
                                            _showHeaderWallet = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'Show your current wallet cash at the top',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          const Text("Show main icons"),
                                          Switch(
                                            value: _showHeaderIcons,
                                            onChanged: (value) {
                                              Prefs().setShowHeaderIcons(value);
                                              setState(() {
                                                _showHeaderIcons = value;
                                              });
                                            },
                                            activeTrackColor: Colors.lightGreenAccent,
                                            activeThumbColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Text(
                                        'Show main game icons at the top. Bear in mind not all of them are represented '
                                        'and some information will already be shown in other tabs in the Profile section',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    if (_showHeaderIcons)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text("Filter icons"),
                                            IconButton(
                                              icon: const Icon(Icons.keyboard_arrow_right_outlined),
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (BuildContext context) {
                                                      return IconsFilterPage(
                                                        settingsProvider: _settingsProvider,
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'STATUS CARD',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Colored status card"),
                                      Switch(
                                        value: _settingsProvider.colorCodedStatusCard,
                                        onChanged: (value) {
                                          Prefs().setColorCodedStatusCard(value);
                                          setState(() {
                                            _settingsProvider.colorCodedStatusCard = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    "If active, you'll see a colored shadow under the status card depending on the "
                                    "actual player status color in Torn",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'TRAVEL',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Dedicated Travel card"),
                                      Switch(
                                        value: _dedicatedTravelCard,
                                        onChanged: (value) {
                                          Prefs().setDedicatedTravelCard(value);
                                          setState(() {
                                            _dedicatedTravelCard = value;
                                          });

                                          if (!value) {
                                            _disableTravelSection = false;
                                            Prefs().setDisableTravelSection(value);
                                          }
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    "If active, you'll get an extra card for travel information, "
                                    'access to foreign stocks and notifications (reduced version of the '
                                    "Travel section). If inactive, you'll still have basic travel information "
                                    'in the Status card',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (_dedicatedTravelCard)
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text("Disable Travel Section"),
                                            Switch(
                                              value: _disableTravelSection,
                                              onChanged: (value) {
                                                Prefs().setDisableTravelSection(value);
                                                setState(() {
                                                  _disableTravelSection = value;
                                                });
                                              },
                                              activeTrackColor: Colors.lightGreenAccent,
                                              activeThumbColor: Colors.green,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Text(
                                          "If using the dedicated travel card, you can optionally disable the app's "
                                          'Travel section entirely, as the same information is shown in both',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'RANKED WAR WIDGET',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Show next Ranked War"),
                                      Switch(
                                        value: _settingsProvider.rankedWarsInProfile,
                                        onChanged: (value) {
                                          setState(() {
                                            _settingsProvider.changeRankedWarsInProfile = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'Show a mini widget in the Status card with information regarding the approaching '
                                    'Ranked War, including notifications. When the Ranked War is active, a scoreboard '
                                    'is shown. It can be clicked to access the war in Torn.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (_settingsProvider.rankedWarsInProfile)
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text("Show total hours (hide days)"),
                                            Switch(
                                              value: _settingsProvider.rankedWarsInProfileShowTotalHours,
                                              onChanged: (value) {
                                                setState(() {
                                                  _settingsProvider.changeRankedWarsInProfileShowTotalHours = value;
                                                });
                                              },
                                              activeTrackColor: Colors.lightGreenAccent,
                                              activeThumbColor: Colors.green,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Text(
                                          'This will hide the days from the countdown to the ranked war and show '
                                          'total remaining hours instead (e.g.: you will be shown 75 hours instead of '
                                          '3 days and 2 hours)',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'BARS BEHAVIOR',
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
                                          "Life bar",
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 20),
                                      ),
                                      Flexible(
                                        flex: 2,
                                        child: _lifeBarDropdown(),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    "Choose which medical section to open when tapping on the life bar. "
                                    "If 'ask' is chosen a dialog will appear every time",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Show organized crimes"),
                                      Switch(
                                        value: _settingsProvider.oCrimesEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _settingsProvider.changeOCrimesEnabled = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'Shown in the miscellaneous card and in status when the time approaches. '
                                    'NOTE: if you have faction API access permission, the OC calculation will be exact and include '
                                    "the participants' status. Otherwise, it will be calculated based on received events",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'PROPERTIES RENTAL',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Flexible(
                                        child: Text("Show also rented out properties"),
                                      ),
                                      Switch(
                                        value: _settingsProvider.showAllRentedOutProperties,
                                        onChanged: (value) {
                                          setState(() {
                                            _settingsProvider.showAllRentedOutProperties = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'If active, you will see all the properties you rent out to other players in the '
                                    'Rented Properties section in the Miscellaneous card. If inactive, you will only '
                                    'see the properties you rent (the ones you pay rent for)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'TORNSTATS CHART',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Show stats chart"),
                                      Switch(
                                        value: _settingsProvider.tornStatsChartEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _settingsProvider.setTornStatsChartEnabled = value;
                                            if (!value) {
                                              _settingsProvider.setTornStatsChartDateTime = 0;
                                            }
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    "Show Torn Stats's stats chart in the Basic Info card. Stats are updated every "
                                    "24 hours, but you can force a manual update request by tapping the Torn Stats logo "
                                    "in the chart legend. If there is an issue, you can try to force a manual update by "
                                    "switching this option off and back to on.",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (_settingsProvider.tornStatsChartEnabled)
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Flexible(
                                              child: Text("Chart type"),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.only(left: 20),
                                            ),
                                            Flexible(
                                              child: _chartTypeDropdown(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text("Show both charts"),
                                            Switch(
                                              value: _settingsProvider.tornStatsChartShowBoth,
                                              onChanged: (value) {
                                                setState(() {
                                                  _settingsProvider.setTornStatsChartShowBoth = value;
                                                });
                                              },
                                              activeTrackColor: Colors.lightGreenAccent,
                                              activeThumbColor: Colors.green,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Flexible(
                                              child: Text("Chart range"),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.only(left: 20),
                                            ),
                                            Flexible(
                                              child: _chartRangeDropdown(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (widget.statsData != null &&
                                          widget.statsData!.data != null &&
                                          widget.statsData!.data!.isNotEmpty)
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                                child: Text(
                                                  "The available range options depend on the data provided by Torn Stats",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text("Show with card collapsed"),
                                            Switch(
                                              value: _settingsProvider.tornStatsChartInCollapsedMiscCard,
                                              onChanged: (value) {
                                                setState(() {
                                                  _settingsProvider.setTornStatsChartInCollapsedMiscCard = value;
                                                });
                                              },
                                              activeTrackColor: Colors.lightGreenAccent,
                                              activeThumbColor: Colors.green,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Text(
                                          "Show stats chart also when the Basic Info card is collapsed (it will be "
                                          "always available with the card expanded",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'EXPANDABLE PANELS',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'Choose whether you want to automatically expand '
                                    'or collapse certain sections. You can always '
                                    'toggle manually by tapping',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Expand events"),
                                      Switch(
                                        value: _expandEvents,
                                        onChanged: (value) {
                                          Prefs().setExpandEvents(value);
                                          setState(() {
                                            _expandEvents = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Flexible(
                                        child: Text("Events to show"),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 20),
                                      ),
                                      Flexible(
                                        child: _eventsNumberDropdown(),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Expand messages"),
                                      Switch(
                                        value: _expandMessages,
                                        onChanged: (value) {
                                          Prefs().setExpandMessages(value);
                                          setState(() {
                                            _expandMessages = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Flexible(
                                        child: Text("Messages to show"),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 20),
                                      ),
                                      Flexible(
                                        child: _messagesNumberDropdown(),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Expand basic info"),
                                      Switch(
                                        value: _expandBasicInfo,
                                        onChanged: (value) {
                                          Prefs().setExpandBasicInfo(value);
                                          setState(() {
                                            _expandBasicInfo = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Expand networth"),
                                      Switch(
                                        value: _expandNetworth,
                                        onChanged: (value) {
                                          Prefs().setExpandNetworth(value);
                                          setState(() {
                                            _expandNetworth = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Show jobless warning"),
                                      Switch(
                                        value: _settingsProvider.joblessWarningEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _settingsProvider.changeJoblessWarningEnabled = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    "If active, a warning will be shown in the Misc card if you don't have a job",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 5),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'CARDS ORDER',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: SizedBox(
                                    height: _sectionList!.length * 40.0 + 40,
                                    child: ReorderableListView(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      onReorder: (int oldIndex, int newIndex) {
                                        if (oldIndex < newIndex) {
                                          // removing the item at oldIndex will shorten the list by 1
                                          newIndex -= 1;
                                        }
                                        final oldItem = _sectionList![oldIndex];
                                        setState(() {
                                          _sectionList!.removeAt(oldIndex);
                                          _sectionList!.insert(newIndex, oldItem);
                                        });
                                        Prefs().setProfileSectionOrder(_sectionList!);
                                      },
                                      children: _currentSectionSort(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'Drag card names to sort them accordingly in the '
                                    'Profile section',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 50),
                              ],
                            ),
                          );
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Profile Options", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  DropdownButton _chartTypeDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.tornStatsChartType,
      items: const [
        DropdownMenuItem(
          value: "line",
          child: SizedBox(
            width: 60,
            child: Text(
              "Line",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "pie",
          child: SizedBox(
            width: 60,
            child: Text(
              "Pie",
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
          _settingsProvider.setTornStatsChartType = value!;
        });
      },
    );
  }

  DropdownButton _chartRangeDropdown() {
    List<DropdownMenuItem<int>> items = [];
    bool disabled = false;

    DropdownMenuItem<int> buildItem(int value, String text) {
      return DropdownMenuItem(
        value: value,
        child: SizedBox(
          width: 80,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (widget.statsData != null && widget.statsData!.data != null && widget.statsData!.data!.isNotEmpty) {
      var data = widget.statsData!.data!;
      int minTs = data.first.timestamp!;
      int maxTs = data.last.timestamp!;
      for (var d in data) {
        if (d.timestamp! < minTs) minTs = d.timestamp!;
        if (d.timestamp! > maxTs) maxTs = d.timestamp!;
      }

      final durationSeconds = maxTs - minTs;
      final durationDays = durationSeconds / (60 * 60 * 24);
      final durationMonths = durationDays / 30;

      if (durationMonths <= 3) {
        items.add(buildItem(3, "3 Months"));
        disabled = true;
      } else {
        items.add(buildItem(3, "3 Months"));
        if (durationMonths > 5) {
          items.add(buildItem(6, "6 Months"));
        }
        if (durationMonths > 11) {
          items.add(buildItem(12, "1 Year"));
        }
        if (durationMonths > 23) {
          items.add(buildItem(24, "2 Years"));
        }
        if (durationMonths > 25) {
          items.add(buildItem(0, "All Time"));
        }
      }

      items.sort((a, b) {
        if (a.value == 0) return 1;
        if (b.value == 0) return -1;
        return a.value!.compareTo(b.value!);
      });
    } else {
      items.add(buildItem(3, "3 Months"));
      items.add(buildItem(6, "6 Months"));
      items.add(buildItem(12, "1 Year"));
      items.add(buildItem(24, "2 Years"));
      items.add(buildItem(0, "All Time"));
      items.sort((a, b) {
        if (a.value == 0) return 1;
        if (b.value == 0) return -1;
        return a.value!.compareTo(b.value!);
      });
    }

    int currentValue = _settingsProvider.tornStatsChartRange;

    // If the saved value is not available in the current items (e.g. because we have less data
    // than the saved range), we select the best available option for display purposes
    // ... in this case, we do NOT update Prefs, so if more data becomes available later,
    // the user's original preference will be respected
    if (!items.any((item) => item.value == currentValue)) {
      // Select the maximum available range (last item in the sorted list)
      currentValue = items.last.value!;
    }

    return DropdownButton<int>(
      value: currentValue,
      items: items,
      onChanged: disabled
          ? null
          : (value) {
              setState(() {
                _settingsProvider.setTornStatsChartRange = value!;
              });
            },
    );
  }

  DropdownButton _eventsNumberDropdown() {
    return DropdownButton<String>(
      value: _eventsNumber.toString(),
      items: const [
        DropdownMenuItem(
          value: "3",
          child: SizedBox(
            width: 40,
            child: Text(
              "3",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "10",
          child: SizedBox(
            width: 40,
            child: Text(
              "10",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "25",
          child: SizedBox(
            width: 40,
            child: Text(
              "25",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "50",
          child: SizedBox(
            width: 40,
            child: Text(
              "50",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "75",
          child: SizedBox(
            width: 40,
            child: Text(
              "75",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "100",
          child: SizedBox(
            width: 40,
            child: Text(
              "100",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        Prefs().setEventsShowNumber(int.parse(value!));
        setState(() {
          _eventsNumber = int.parse(value);
        });
      },
    );
  }

  DropdownButton _messagesNumberDropdown() {
    return DropdownButton<String>(
      value: _messagesNumber.toString(),
      items: const [
        DropdownMenuItem(
          value: "3",
          child: SizedBox(
            width: 40,
            child: Text(
              "3",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "10",
          child: SizedBox(
            width: 40,
            child: Text(
              "10",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "25",
          child: SizedBox(
            width: 40,
            child: Text(
              "25",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "50",
          child: SizedBox(
            width: 40,
            child: Text(
              "50",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "75",
          child: SizedBox(
            width: 40,
            child: Text(
              "75",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "100",
          child: SizedBox(
            width: 40,
            child: Text(
              "100",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        Prefs().setMessagesShowNumber(int.parse(value!));
        setState(() {
          _messagesNumber = int.parse(value);
        });
      },
    );
  }

  Future _restorePreferences() async {
    final headerWallet = await Prefs().getShowHeaderWallet();
    final headerIcons = await Prefs().getShowHeaderIcons();
    final dedTravel = await Prefs().getDedicatedTravelCard();
    final disableTravel = await Prefs().getDisableTravelSection();
    final expandEvents = await Prefs().getExpandEvents();
    final eventsNumber = await Prefs().getEventsShowNumber();
    final expandMessages = await Prefs().getExpandMessages();
    final messagesNumber = await Prefs().getMessagesShowNumber();
    final expandBasicInfo = await Prefs().getExpandBasicInfo();
    final expandNetworth = await Prefs().getExpandNetworth();
    final sectionList = await Prefs().getProfileSectionOrder();

    setState(() {
      _showHeaderWallet = headerWallet;
      _showHeaderIcons = headerIcons;
      _dedicatedTravelCard = dedTravel;
      _disableTravelSection = disableTravel;
      _expandEvents = expandEvents;
      _eventsNumber = eventsNumber;
      _expandMessages = expandMessages;
      _messagesNumber = messagesNumber;
      _expandBasicInfo = expandBasicInfo;
      _expandNetworth = expandNetworth;
      _sectionList = sectionList;
    });
  }

  void _goBack() {
    Navigator.of(context).pop();
    routeWithDrawer = true;
  }

  List<Widget> _currentSectionSort() {
    final myList = <Widget>[];
    for (final section in _sectionList!) {
      myList.add(
        SizedBox(
          height: 40,
          key: UniqueKey(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      section,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                    const Icon(Icons.menu, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return myList;
  }

  DropdownButton _lifeBarDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.lifeBarOption,
      items: const [
        DropdownMenuItem(
          value: "ask",
          child: SizedBox(
            width: 80,
            child: Text(
              "Ask",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "inventory",
          child: SizedBox(
            width: 80,
            child: Text(
              "Inventory",
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
            width: 80,
            child: Text(
              "Faction",
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
          _settingsProvider.changeLifeBarOption = value;
        });
      },
    );
  }
}
