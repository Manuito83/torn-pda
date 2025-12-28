// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/travel/travel_notification_text.dart';

class TravelOptionsIOS extends StatefulWidget {
  final Function? callback;

  const TravelOptionsIOS({
    this.callback,
  });

  @override
  TravelOptionsIOSState createState() => TravelOptionsIOSState();
}

class TravelOptionsIOSState extends State<TravelOptionsIOS> {
  String? _travelNotificationAheadDropDownValue;
  String? _travelAlarmAheadDropDownValue;

  Future? _preferencesLoaded;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeName = "travel_options";
    routeWithDrawer = false;
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "travel_options") _goBack();
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
        routeWithDrawer = false;
        routeName = "profile_notifications";
        if (widget.callback != null) {
          widget.callback!();
        }
      },
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : _themeProvider.canvas
            : _themeProvider.canvas,
        child: SafeArea(
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
                                      'trigger time before arrival. Tap the text icon in the appbar '
                                      'to change the notification title and body.'),
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
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Travel notification", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(MdiIcons.commentTextOutline),
          onPressed: () {
            _showNotificationTextDialog();
          },
        ),
      ],
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
                child: _travelNotificationAheadDropDown(),
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
                child: _travelAlarmAheadDropDown(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DropdownButton _travelNotificationAheadDropDown() {
    return DropdownButton<String>(
      value: _travelNotificationAheadDropDownValue,
      items: const [
        DropdownMenuItem(
          value: "0",
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
          value: "1",
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
          value: "2",
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
          value: "3",
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
      ],
      onChanged: (value) {
        Prefs().setTravelNotificationAhead(value!);
        setState(() {
          _travelNotificationAheadDropDownValue = value;
        });
      },
    );
  }

  DropdownButton _travelAlarmAheadDropDown() {
    return DropdownButton<String>(
      value: _travelAlarmAheadDropDownValue,
      items: const [
        DropdownMenuItem(
          value: "20",
          child: SizedBox(
            width: 140,
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
          value: "40",
          child: SizedBox(
            width: 140,
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
          value: "60",
          child: SizedBox(
            width: 140,
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
          value: "120",
          child: SizedBox(
            width: 140,
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
          value: "300",
          child: SizedBox(
            width: 140,
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
          value: "600",
          child: SizedBox(
            width: 140,
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
        Prefs().setTravelAlarmAhead(value!);
        setState(() {
          _travelAlarmAheadDropDownValue = value;
        });
      },
    );
  }

  Future _restorePreferences() async {
    final travelNotificationAhead = await Prefs().getTravelNotificationAhead();
    var travelAlarmAhead = await Prefs().getTravelAlarmAhead();

    const allowedAlarmValues = <String>{"20", "40", "60", "120", "300", "600"};
    if (!allowedAlarmValues.contains(travelAlarmAhead)) {
      // Map legacy minute-based values to seconds; default to 1 minute before.
      switch (travelAlarmAhead) {
        case "0":
        case "1":
          travelAlarmAhead = "60";
          break;
        case "2":
          travelAlarmAhead = "120";
          break;
        case "3":
          travelAlarmAhead = "300";
          break;
        case "4":
          travelAlarmAhead = "600";
          break;
        default:
          // If it's any other numeric value, keep it; otherwise fallback to 1 minute.
          travelAlarmAhead = int.tryParse(travelAlarmAhead) != null ? travelAlarmAhead : "60";
      }
    }

    setState(() {
      _travelNotificationAheadDropDownValue = travelNotificationAhead;
      _travelAlarmAheadDropDownValue = travelAlarmAhead;
    });
  }

  Future _showNotificationTextDialog() async {
    final title = await Prefs().getTravelNotificationTitle();
    final body = await Prefs().getTravelNotificationBody();

    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: TravelNotificationTextDialog(
            title: title,
            body: body,
          ),
        );
      },
    );
  }

  void _goBack() {
    routeWithDrawer = false;
    routeName = "profile_notifications";
    if (widget.callback != null) {
      widget.callback!();
    }
    Navigator.of(context).pop();
  }
}
