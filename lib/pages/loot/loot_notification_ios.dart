// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/alarm_kit_service_ios.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class LootNotificationsIOS extends StatefulWidget {
  final Function callback;
  final bool? lootRangersEnabled;

  const LootNotificationsIOS({
    required this.callback,
    required this.lootRangersEnabled,
  });

  @override
  LootNotificationsIOSState createState() => LootNotificationsIOSState();
}

class LootNotificationsIOSState extends State<LootNotificationsIOS> {
  String? _lootNotificationAheadDropDownValue;
  String? _lootAlarmAheadDropDownValue;
  String? _lootTypeDropDownValue;
  bool _isAlarmKitAvailable = false;

  Future? _preferencesLoaded;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeWithDrawer = false;
    routeName = "loot_notification";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "loot_notification") _goBack();
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
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : isStatusBarShown
                  ? _themeProvider.statusBar
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
              String message = 'Here you can specify your preferred alerting '
                  'method and launch time before the loot level is reached';

              if (widget.lootRangersEnabled!) {
                message += ' (also applies to Loot Rangers, if available)';
              }

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
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(message),
                              ),
                              _rowsWithTypes(),
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
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Loot options", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _rowsWithTypes() {
    return Column(
      children: <Widget>[
        if (_isAlarmKitAvailable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Flexible(
                  child: Text('Alert type'),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Flexible(
                  child: _lootTypeDropDown(),
                ),
              ],
            ),
          ),
        if (_isAlarmKitAvailable) const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text('Loot'),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
              ),
              Flexible(
                child: _lootTypeDropDownValue == '1' ? _lootAlarmAheadDropDown() : _lootTimerDropDown(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DropdownButton _lootTypeDropDown() {
    return DropdownButton<String>(
      value: _lootTypeDropDownValue,
      items: const [
        DropdownMenuItem(
          value: "0",
          child: Text("Notification"),
        ),
        DropdownMenuItem(
          value: "1",
          child: Text("Alarm"),
        ),
      ],
      onChanged: (value) {
        Prefs().setLootNotificationType(value!);
        setState(() {
          _lootTypeDropDownValue = value;
        });
      },
    );
  }

  DropdownButton _lootAlarmAheadDropDown() {
    return DropdownButton<String>(
      value: _lootAlarmAheadDropDownValue,
      items: const [
        DropdownMenuItem(
          value: "s20",
          child: SizedBox(
            width: 120,
            child: Text(
              "20 seconds before",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "s40",
          child: SizedBox(
            width: 120,
            child: Text(
              "40 seconds before",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 120,
            child: Text(
              "1 minute before",
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
            width: 120,
            child: Text(
              "2 minutes before",
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
            width: 120,
            child: Text(
              "4 minutes before",
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
            width: 120,
            child: Text(
              "5 minutes before",
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
            width: 120,
            child: Text(
              "6 minutes before",
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
            width: 120,
            child: Text(
              "8 minutes before",
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
            width: 120,
            child: Text(
              "10 minutes before",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          Prefs().setLootAlarmAhead(value);
          setState(() {
            _lootAlarmAheadDropDownValue = value;
          });
        }
      },
    );
  }

  DropdownButton _lootTimerDropDown() {
    return DropdownButton<String>(
      value: _lootNotificationAheadDropDownValue,
      items: const [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "30 seconds",
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
              "1 minute",
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
              "2 minutes",
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
              "4 minutes",
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
              "5 minutes",
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
              "6 minutes",
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
              "8 minutes",
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
              "10 minutes",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          Prefs().setLootNotificationAhead(value);
          Prefs().setLootTimerAhead(value);
          setState(() {
            _lootNotificationAheadDropDownValue = value;
          });
        }
      },
    );
  }

  Future _restorePreferences() async {
    _isAlarmKitAvailable = await AlarmKitServiceIos.isAvailable();
    final lootNotificationAhead = await Prefs().getLootNotificationAhead();
    final lootAlarmAhead = await Prefs().getLootAlarmAhead();
    final lootType = await Prefs().getLootNotificationType();

    const notifAllowed = {"0", "1", "2", "3", "4", "5", "6", "7"};
    const alarmAllowed = {"s20", "s40", "0", "1", "2", "3", "4", "5", "6"};

    setState(() {
      _lootNotificationAheadDropDownValue = notifAllowed.contains(lootNotificationAhead) ? lootNotificationAhead : "7";
      _lootAlarmAheadDropDownValue = alarmAllowed.contains(lootAlarmAhead) ? lootAlarmAhead : "6";
      _lootTypeDropDownValue = lootType;
    });
  }

  void _goBack() {
    widget.callback();
    routeWithDrawer = true;
    routeName = "loot";
    Navigator.of(context).pop();
  }
}
