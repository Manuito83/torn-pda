// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class WarAheadOptions extends StatefulWidget {
  final Function? callback;

  const WarAheadOptions({
    this.callback,
  });

  @override
  WarAheadOptionsState createState() => WarAheadOptionsState();
}

class WarAheadOptionsState extends State<WarAheadOptions> {
  int? _warNotificationAheadValue;
  int? _warAlarmAheadDropDownValue;
  int? _warTimerAheadDropDownValue;

  Future? _preferencesLoaded;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeWithDrawer = false;
    routeName = "war_ahead_options";
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "war_ahead_options") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
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
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Here you can specify your preferred notification '
                                    'trigger time before a ranked war starts'),
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
      title: const Text("War notification", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
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
                child: _warNotificationAheadDropDown(),
              ),
            ],
          ),
        ),
        if (Platform.isAndroid)
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
                            child: _warAlarmAheadDropDown(),
                          ),
                        ],
                      ),
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
                  child: _warTimerAheadDropDown(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  DropdownButton _warNotificationAheadDropDown() {
    return DropdownButton<int>(
      value: _warNotificationAheadValue,
      items: const [
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
        DropdownMenuItem(
          value: 1800,
          child: SizedBox(
            width: 80,
            child: Text(
              "30 minutes",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 3600,
          child: SizedBox(
            width: 80,
            child: Text(
              "1 hour",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 21600,
          child: SizedBox(
            width: 80,
            child: Text(
              "6 hours",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        Prefs().setRankedWarNotificationAhead(value!);
        setState(() {
          _warNotificationAheadValue = value;
        });
      },
    );
  }

  DropdownButton _warAlarmAheadDropDown() {
    return DropdownButton<int>(
      value: _warAlarmAheadDropDownValue,
      items: const [
        DropdownMenuItem(
          value: 1,
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
          value: 10,
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
        DropdownMenuItem(
          value: 30,
          child: SizedBox(
            width: 80,
            child: Text(
              "30 minutes",
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
              "1 hour",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 360,
          child: SizedBox(
            width: 80,
            child: Text(
              "6 hours",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        Prefs().setRankedWarAlarmAhead(value!);
        setState(() {
          _warAlarmAheadDropDownValue = value;
        });
      },
    );
  }

  DropdownButton _warTimerAheadDropDown() {
    return DropdownButton<int>(
      value: _warTimerAheadDropDownValue,
      items: const [
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
        DropdownMenuItem(
          value: 1800,
          child: SizedBox(
            width: 80,
            child: Text(
              "30 minutes",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 3600,
          child: SizedBox(
            width: 80,
            child: Text(
              "1 hour",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 21600,
          child: SizedBox(
            width: 80,
            child: Text(
              "6 hours",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        Prefs().setRankedWarTimerAhead(value!);
        setState(() {
          _warTimerAheadDropDownValue = value;
        });
      },
    );
  }

  Future _restorePreferences() async {
    final warNotificationAhead = await Prefs().getRankedWarNotificationAhead();
    var warAlarmAhead = await Prefs().getRankedWarAlarmAhead();
    if (warAlarmAhead == 0) warAlarmAhead = 1; // Correction from Shared Prefs
    final warTimerAhead = await Prefs().getRankedWarTimerAhead();

    setState(() {
      _warNotificationAheadValue = warNotificationAhead;
      _warAlarmAheadDropDownValue = warAlarmAhead;
      _warTimerAheadDropDownValue = warTimerAhead;
    });
  }

  _goBack() {
    if (widget.callback != null) {
      widget.callback!();
    }
    routeWithDrawer = false;
    routeName = "profile_notifications";
    Navigator.of(context).pop();
  }
}
