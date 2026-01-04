// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class HospitalAheadOptions extends StatefulWidget {
  final Function? callback;

  const HospitalAheadOptions({
    this.callback,
  });

  @override
  HospitalAheadOptionsState createState() => HospitalAheadOptionsState();
}

class HospitalAheadOptionsState extends State<HospitalAheadOptions> {
  int? _hospitalNotificationAheadValue;
  int? _hospitalAlarmAheadDropDownValue;
  int? _hospitalTimerAheadDropDownValue;

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
    routeName = "hospital_ahead_options";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "hospital_ahead_options") _goBack();
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
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Here you can specify your preferred notification '
                                    'trigger time before hospital release'),
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
      title: const Text("Hospital notification", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _goBack(),
      ),
    );
  }

  Widget _rowsWithTypes() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                child: Text('Notification'),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
              ),
              Flexible(
                child: _hospitalNotificationAheadDropDown(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Alarm'),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
              ),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: _hospitalAlarmAheadDropDown(),
                        ),
                      ],
                    ),
                    if (Platform.isAndroid)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              "(alarms are set on the minute)",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (Platform.isAndroid)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Flexible(
                  child: Text('Timer'),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Flexible(
                  child: _hospitalTimerAheadDropDown(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  DropdownButton _hospitalNotificationAheadDropDown() {
    return DropdownButton<int>(
      value: _hospitalNotificationAheadValue,
      items: const [
        DropdownMenuItem(
          value: 20,
          child: SizedBox(
            width: 80,
            child: Text(
              "20 seconds",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 40,
          child: SizedBox(
            width: 80,
            child: Text(
              "40 seconds",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 60,
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
          value: 120,
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
          value: 300,
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
          value: 600,
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
        Prefs().setHospitalNotificationAhead(value!);
        setState(() {
          _hospitalNotificationAheadValue = value;
        });
      },
    );
  }

  DropdownButton _hospitalAlarmAheadDropDown() {
    final items = Platform.isIOS
        ? [
            const DropdownMenuItem(
              value: 20,
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
            const DropdownMenuItem(
              value: 40,
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
            const DropdownMenuItem(
              value: 60,
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
            const DropdownMenuItem(
              value: 120,
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
            const DropdownMenuItem(
              value: 300,
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
            const DropdownMenuItem(
              value: 600,
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
          ]
        : const [
            DropdownMenuItem(
              value: 0,
              child: SizedBox(
                width: 120,
                child: Text(
                  "Same minute",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            DropdownMenuItem(
              value: 1,
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
              value: 2,
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
              value: 5,
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
              value: 10,
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
          ];

    return DropdownButton<int>(
      value: _hospitalAlarmAheadDropDownValue,
      items: items,
      onChanged: (value) {
        Prefs().setHospitalAlarmAhead(value!);
        setState(() {
          _hospitalAlarmAheadDropDownValue = value;
        });
      },
    );
  }

  DropdownButton _hospitalTimerAheadDropDown() {
    return DropdownButton<int>(
      value: _hospitalTimerAheadDropDownValue,
      items: const [
        DropdownMenuItem(
          value: 20,
          child: SizedBox(
            width: 80,
            child: Text(
              "20 seconds",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 40,
          child: SizedBox(
            width: 80,
            child: Text(
              "40 seconds",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 60,
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
          value: 120,
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
          value: 300,
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
          value: 600,
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
        Prefs().setHospitalTimerAhead(value!);
        setState(() {
          _hospitalTimerAheadDropDownValue = value;
        });
      },
    );
  }

  Future _restorePreferences() async {
    final hospitalNotificationAhead = await Prefs().getHospitalNotificationAhead();
    final hospitalAlarmAhead = await Prefs().getHospitalAlarmAhead();
    final hospitalTimerAhead = await Prefs().getHospitalTimerAhead();

    setState(() {
      _hospitalNotificationAheadValue = hospitalNotificationAhead;
      if (Platform.isIOS) {
        final allowed = <int>{20, 40, 60, 120, 300, 600};
        if (allowed.contains(hospitalAlarmAhead)) {
          _hospitalAlarmAheadDropDownValue = hospitalAlarmAhead;
        } else {
          // Map legacy minute-based values to seconds; default to 1 minute before.
          switch (hospitalAlarmAhead) {
            case 0:
              _hospitalAlarmAheadDropDownValue = 60;
              break;
            case 1:
              _hospitalAlarmAheadDropDownValue = 60;
              break;
            case 2:
              _hospitalAlarmAheadDropDownValue = 120;
              break;
            case 5:
              _hospitalAlarmAheadDropDownValue = 300;
              break;
            case 10:
              _hospitalAlarmAheadDropDownValue = 600;
              break;
            default:
              _hospitalAlarmAheadDropDownValue = 60;
          }
        }
      } else {
        _hospitalAlarmAheadDropDownValue = hospitalAlarmAhead;
      }
      _hospitalTimerAheadDropDownValue = hospitalTimerAhead;
    });
  }

  void _goBack() {
    if (widget.callback != null) {
      widget.callback!();
    }
    routeWithDrawer = false;
    routeName = "profile_notifications";
    Navigator.of(context).pop();
  }
}
