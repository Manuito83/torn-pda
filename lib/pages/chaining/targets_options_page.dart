// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TargetsOptionsReturn {
  bool yataEnabled;
  bool tacEnabled;
}

class TargetsOptionsPage extends StatefulWidget {
  @override
  _TargetsOptionsPageState createState() => _TargetsOptionsPageState();
}

class _TargetsOptionsPageState extends State<TargetsOptionsPage> {
  // Skipping
  bool _skippingEnabled = true;

  // Targets notes while chaining
  bool _showTargetsNotes = true;
  bool _showOnlineFactionWarning = true;

  // Chain watcher
  bool _soundAlertsEnabled = true;
  bool _vibrationAlertsEnabled = true;
  bool _watcherNotificationsEnabled = true;

  // Yata import
  bool _yataTargetsEnabled = true;

  // TAC
  bool _tacEnabled = true;

  Future _preferencesLoaded;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : Colors.grey[900]
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                  child: FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CHAINING',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Show targets notes"),
                                    Switch(
                                      value: _showTargetsNotes,
                                      onChanged: (value) {
                                        Prefs().setShowTargetsNotes(value);
                                        setState(() {
                                          _showTargetsNotes = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If enabled, you will be shown the note you have saved for every '
                                  'target and its color as you progress with the chain. For TAC targets this '
                                  'will show the estimated stats.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              if (_showTargetsNotes)
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text("Last online & faction warning"),
                                          Switch(
                                            value: _showOnlineFactionWarning,
                                            onChanged: (value) {
                                              Prefs().setShowOnlineFactionWarning(value);
                                              setState(() {
                                                _showOnlineFactionWarning = value;
                                              });
                                            },
                                            activeTrackColor: Colors.lightGreenAccent,
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Text(
                                        'If enabled, in addition to the target\'s note (if any) you\'ll be shown if the '
                                        'target has been online in the last 7 days. If so, a faction check will also be performed. '
                                        'This is to avoid attacking active targets, if desired. Applies to standard targets and TAC.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                  ],
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Skip red/blue targets"),
                                    Switch(
                                      value: _skippingEnabled,
                                      onChanged: (value) {
                                        Prefs().setTargetSkipping(value);
                                        setState(() {
                                          _skippingEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If enabled, targets that are in hospital, jail or in another '
                                  'country will be skipped (max 3 at a time, to avoid delays)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CHAIN WATCHER',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Sound alerts"),
                                    Switch(
                                      value: _soundAlertsEnabled,
                                      onChanged: (value) {
                                        Prefs().setChainWatcherSound(value);
                                        setState(() {
                                          _soundAlertsEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Vibration"),
                                    Switch(
                                      value: _vibrationAlertsEnabled,
                                      onChanged: (value) {
                                        Prefs().setChainWatcherVibration(value);
                                        setState(() {
                                          _vibrationAlertsEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Notification"),
                                    Switch(
                                      value: _watcherNotificationsEnabled,
                                      onChanged: (value) {
                                        Prefs().setChainWatcherNotificationsEnabled(value);
                                        setState(() {
                                          _watcherNotificationsEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'YATA',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Show YATA icon"),
                                    Switch(
                                      value: _yataTargetsEnabled,
                                      onChanged: (value) {
                                        Prefs().setYataTargetsEnabled(value);
                                        setState(() {
                                          _yataTargetsEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If enabled, you\'ll have access to a \'Y\' icon in the top bar from '
                                  'where you can import and export to YATA. Please note that deletions '
                                  'are not propagated between YATA and Torn PDA, but notes are '
                                  'overwritten in either direction.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Torn Attack Central',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Show TAC tab"),
                                    Switch(
                                      value: _tacEnabled,
                                      onChanged: (value) {
                                        Prefs().setTACEnabled(value);
                                        setState(() {
                                          _tacEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If enabled, you\'ll have access to TAC through a third '
                                  'bottom tab in the Chaining section.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 50),
                            ],
                          ),
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
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
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Chaining Options"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
    );
  }

  Future _restorePreferences() async {
    var showTargetsNotes = await Prefs().getShowTargetsNotes();
    var showOnlineFactionWarning = await Prefs().getShowOnlineFactionWarning();
    var skippingEnabled = await Prefs().getTargetSkipping();
    var soundEnabled = await Prefs().getChainWatcherSound();
    var vibrationEnabled = await Prefs().getChainWatcherVibration();
    var yataEnabled = await Prefs().getYataTargetsEnabled();
    var tacEnabled = await Prefs().getTACEnabled();
    var notifications = await Prefs().getChainWatcherNotificationsEnabled();

    setState(() {
      _showTargetsNotes = showTargetsNotes;
      _showOnlineFactionWarning = showOnlineFactionWarning;
      _skippingEnabled = skippingEnabled;
      _soundAlertsEnabled = soundEnabled;
      _vibrationAlertsEnabled = vibrationEnabled;
      _yataTargetsEnabled = yataEnabled;
      _tacEnabled = tacEnabled;
      _watcherNotificationsEnabled = notifications;
    });
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop(
      TargetsOptionsReturn()
        ..yataEnabled = _yataTargetsEnabled
        ..tacEnabled = _tacEnabled,
    );
    return true;
  }
}
