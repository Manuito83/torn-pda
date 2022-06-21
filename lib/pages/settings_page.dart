// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:android_intent/android_intent.dart';
import 'package:device_info/device_info.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/settings/alternative_keys_page.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/other/profile_check.dart';
import 'package:vibration/vibration.dart';

// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/pages/settings/settings_browser.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/settings/browser_info_dialog.dart';

class SettingsPage extends StatefulWidget {
  final Function changeUID;

  SettingsPage({@required this.changeUID, Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  Timer _ticker;

  String _myCurrentKey = '';
  bool _userToLoad = false;
  bool _apiError = false;
  String _errorReason = '';
  String _errorDetails = '';
  bool _apiIsLoading = false;
  OwnProfileBasic _userProfile;

  Future _preferencesRestored;

  String _openSectionValue;
  String _onAppExitValue;
  String _openBrowserValue;
  String _timeFormatValue;
  String _timeZoneValue;
  String _vibrationValue;
  bool _manualAlarmSound;
  bool _manualAlarmVibration;
  bool _removeNotificationsLaunch;

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ThemeProvider _themeProvider;

  var _expandableController = ExpandableController();

  var _apiKeyInputController = TextEditingController();

  String _appBarPosition = "top";

  int _androidSdk = 0;

  double _extraMargin = 0.0;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesRestored = _restorePreferences();
    _ticker = new Timer.periodic(Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
    analytics.setCurrentScreen(screenName: 'settings');
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: new Drawer(),
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
                onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: _extraMargin),
                      _apiKeyWidget(),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BROWSER',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    "Web browser",
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.info_outline),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BrowserInfoDialog();
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
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
                              Text(
                                "Advanced browser settings",
                              ),
                              IconButton(
                                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) => SettingsBrowserPage(),
                                      ),
                                    );
                                  }),
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
                            'TIME',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                "Time format",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
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
                            Flexible(
                              child: Text(
                                "Time zone",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                            ),
                            Flexible(
                              flex: 2,
                              child: _timeZoneDropdown(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
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
                        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
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
                      SizedBox(height: 15),
                      // TODO: this is conditional now because it only affects Android.
                      // In the future it might be needed to show always the Divider and
                      // SizedBox and only hide the actual Android elements
                      if (Platform.isAndroid)
                        Column(
                          children: [
                            Divider(),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'NOTIFICATIONS',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
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
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      "Alerts vibration",
                                    ),
                                  ),
                                  Padding(
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
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Manual alarm sound"),
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
                                  Text("Manual alarm vibration"),
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
                                      text: 'Google\'s Clock application',
                                      style: TextStyle(color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          AndroidIntent intent = AndroidIntent(
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
                            SizedBox(height: 15),
                          ],
                        )
                      else
                        SizedBox.shrink(),
                      Divider(),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SPIES',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                "Spies source",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
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
                      SizedBox(height: 15),
                      Divider(),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'MISC',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                "App bar position",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
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
                            Flexible(
                              child: Text(
                                "Default launch section",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                            ),
                            Flexible(
                              child: _openSectionDropdown(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
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
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                "On app exit",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                            ),
                            Flexible(
                              child: _appExitDropdown(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Note: this will only have effect in certain devices, depending on "
                          "your configuration. Dictates how to proceed when the app detects a back button "
                          "press or swipe that would otherwise close the app. "
                          "If you choose 'ask', a dialog will be shown next time",
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
                            Text(
                              "Alternative API keys",
                            ),
                            IconButton(
                                icon: Icon(Icons.keyboard_arrow_right_outlined),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) => AlternativeKeysPage(),
                                    ),
                                  );
                                }),
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
                      SizedBox(height: 15),
                      Divider(),
                      SizedBox(height: 5),
                      Row(
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
                            Flexible(
                              child: Text(
                                "Test API",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                            ),
                            ElevatedButton(
                              child: Text("PING"),
                              onPressed: () async {
                                BotToast.showText(
                                  text: "Please wait...",
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: Colors.blue,
                                  duration: Duration(seconds: 1),
                                  contentPadding: EdgeInsets.all(10),
                                );
                                final ping = Ping('api.torn.com', count: 4);
                                ping.stream.listen((event) {
                                  if (event.summary != null || event.error != null) {
                                    String message = "";
                                    if (event.error != null) {
                                      message = "CONNECTION PROBLEM\n\n${event.error}";
                                    } else {
                                      if (event.summary.transmitted == event.summary.received) {
                                        message = "SUCCESS\n\n${event.summary}";
                                      } else {
                                        message = "CONNECTION PROBLEM\n\n${event.summary}";
                                      }
                                    }

                                    BotToast.showText(
                                      clickClose: true,
                                      text: message,
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.blue,
                                      duration: Duration(seconds: 10),
                                      contentPadding: EdgeInsets.all(10),
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
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      title: Text('Settings'),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
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
      return Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      );
    }
    if (_userToLoad) {
      _expandableController.expanded = false;
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: Card(
          child: ExpandablePanel(
            collapsed: null,
            header: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
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
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      "${_userProfile.name} [${_userProfile.playerId}]",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          _apiKeyForm(enabled: false),
                          Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: Text("Copy"),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _userProfile.userApiKey.toString()));
                                  BotToast.showText(
                                    text: "API key copied to the clipboard, be careful!",
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.blue,
                                    duration: Duration(seconds: 4),
                                    contentPadding: EdgeInsets.all(10),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: Text("Reload"),
                                  onPressed: () {
                                    FocusScope.of(context).requestFocus(new FocusNode());
                                    if (_formKey.currentState.validate()) {
                                      _myCurrentKey = _apiKeyInputController.text;
                                      _getApiDetails(userTriggered: true, reload: true);
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: Text("Remove"),
                                  onPressed: () async {
                                    FocusScope.of(context).requestFocus(new FocusNode());
                                    // Removes the form error
                                    _formKey.currentState.reset();
                                    _apiKeyInputController.clear();
                                    _myCurrentKey = '';
                                    _userProvider.removeUser();
                                    setState(() {
                                      _userToLoad = false;
                                      _apiError = false;
                                    });
                                    await FirebaseMessaging.instance.deleteToken();
                                    await firestore.deleteUserProfile();
                                    await firebaseAuth.signOut();
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
            collapsed: null,
            controller: _expandableController,
            header: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
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
                    padding: const EdgeInsets.only(left: 10),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          _apiKeyForm(enabled: true),
                          Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: Text("Load"),
                                onPressed: () {
                                  FocusScope.of(context).requestFocus(new FocusNode());
                                  if (_formKey.currentState.validate()) {
                                    _myCurrentKey = _apiKeyInputController.text;
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

  SizedBox _apiKeyForm({@required bool enabled}) {
    return SizedBox(
      width: 300,
      child: Form(
        key: _formKey,
        child: TextFormField(
          enabled: enabled,
          validator: (value) {
            if (value.isEmpty) {
              return "The API Key is empty!";
            }
            return null;
          },
          controller: _apiKeyInputController,
          maxLength: 30,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Please insert your Torn API Key',
            hintStyle: TextStyle(fontSize: 14),
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: BorderSide(
                color: Colors.amber,
                style: BorderStyle.solid,
              ),
            ),
          ),
          // This is here in case the user submits from the keyboard and not
          // hitting the "Load" button
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(new FocusNode());
            if (_formKey.currentState.validate()) {
              _myCurrentKey = _apiKeyInputController.text;
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
            Padding(
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
                  "$_errorDetails",
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
        padding: EdgeInsetsDirectional.fromSTEB(10, 30, 10, 0),
        child: Column(
          children: <Widget>[
            Text(
              'Torn PDA needs your API Key to obtain your user\'s '
              'information. The key is protected in the app and will not '
              'be shared under any circumstances.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\nYou can get your API key in the Torn website by taping your profile picture (upper right corner)"
                        " and going to Settings, API Keys. Torn PDA only needs a Limited Access key.\n",
                      ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Tap here',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  var url = 'https://www.torn.com/preferences.php#tab=api';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        useDialog: _settingsProvider.useQuickBrowser,
                                      );
                                },
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
            Text('\nIn any case, please make sure to '
                'follow Torn\'s staff recommendations on how to protect your key '
                'from any malicious use.'),
            Text('\nYou can always remove it from the '
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Gender: ${_userProfile.gender}"),
            Text("Level: ${_userProfile.level}"),
            Text("Life: ${_userProfile.life.current}"),
            Text("Status: ${_userProfile.status.description}"),
            Text("Last action: ${_userProfile.lastAction.relative}"),
            Text("Rank: ${_userProfile.rank}"),
          ],
        ),
      );
    }
  }

  DropdownButton _openSectionDropdown() {
    return DropdownButton<String>(
      value: _openSectionValue,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 60,
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
            width: 60,
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
            width: 60,
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
            width: 60,
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
            width: 60,
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
            width: 60,
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
          value: "6",
          child: SizedBox(
            width: 60,
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
        // TODO: use settings provider for this?
        Prefs().setDefaultSection(value);
        setState(() {
          _openSectionValue = value;
        });
      },
    );
  }

  DropdownButton _appExitDropdown() {
    return DropdownButton<String>(
      value: _onAppExitValue,
      items: [
        DropdownMenuItem(
          value: "ask",
          child: SizedBox(
            width: 60,
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
      items: [
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
      onChanged: (value) {
        if (value == '0') {
          _settingsProvider.changeBrowser = BrowserSetting.app;
        } else {
          _settingsProvider.changeBrowser = BrowserSetting.external;
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
      items: [
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
      items: [
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
      items: [
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
          _settingsProvider.changeShowDateInClock = value;
        });
      },
    );
  }

  DropdownButton _secondsInClockDropdown() {
    return DropdownButton<bool>(
      value: _settingsProvider.showSecondsInClock,
      items: [
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
          _settingsProvider.changeShowSecondsInClock = value;
        });
      },
    );
  }

  Widget _vibrationDropdown() {
    if (_androidSdk < 26) {
      return Text(
        'This functionality is only available in Android 8 (API 26 - Oreo) or higher, sorry!',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
        ),
      );
    }

    return DropdownButton<String>(
      value: _vibrationValue,
      items: [
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
        firestore.setVibrationPattern(value);
        Prefs().setVibrationPattern(value);
        setState(() {
          _vibrationValue = value;
        });

        if (await Vibration.hasVibrator()) {
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
      value: _settingsProvider.spiesSource,
      items: [
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
            _settingsProvider.changeSpiesSource = SpiesSource.yata;
          } else {
            _settingsProvider.changeSpiesSource = SpiesSource.tornStats;
          }
        });
      },
    );
  }

  DropdownButton _appBarPositionDropdown() {
    return DropdownButton<String>(
      value: _appBarPosition,
      items: [
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

  void _getApiDetails({@required bool userTriggered, bool reload = false}) async {
    try {
      setState(() {
        _apiIsLoading = true;
      });

      dynamic myProfile = await TornApiCaller().getProfileBasic(forcedApiKey: _myCurrentKey);
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

        // Firestore uploading, but only if "Load" pressed by user
        if (userTriggered) {
          var user = await firebaseAuth.getUID();
          // Only sign in if there is currently no user registered (to avoid duplicates)
          if (user == null || (user is User && user.uid.isEmpty)) {
            User mFirebaseUser = await firebaseAuth.signInAnon();
            firestore.setUID(mFirebaseUser.uid);
            // Returns UID to Drawer so that it can be passed to settings
            widget.changeUID(mFirebaseUser.uid);
            log("Settings: signed in with UID ${mFirebaseUser.uid}");
          } else {
            log("Settings: existing user UID ${user}");
          }

          await firestore.uploadUsersProfileDetail(myProfile, userTriggered: true);
          await firestore.uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);
          if (Platform.isAndroid) {
            firestore.setVibrationPattern(_vibrationValue);
          }
        }
      } else if (myProfile is ApiError) {
        setState(() {
          _apiIsLoading = false;
          _userToLoad = false;
          _apiError = true;
          _errorReason = myProfile.errorReason;
          _errorDetails = myProfile.errorDetails;
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
      FirebaseCrashlytics.instance.log("PDA Crash at LOAD API KEY. User $_myCurrentKey. "
          "Error: $e. Stack: $stack");
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }

  Future _restorePreferences() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _androidSdk = androidInfo.version.sdkInt;
    }

    await Prefs().getDefaultSection().then((onValue) {
      setState(() {
        _openSectionValue = onValue;
      });
    });

    if (_userProvider.basic.userApiKeyValid) {
      setState(() {
        _apiKeyInputController.text = _userProvider.basic.userApiKey;
        _myCurrentKey = _userProvider.basic.userApiKey;
        _apiIsLoading = true;
      });
      _getApiDetails(userTriggered: false);
    }

    var onAppExit = _settingsProvider.onAppExit;
    setState(() {
      switch (onAppExit) {
        case 'ask':
          _onAppExitValue = 'ask';
          break;
        case 'exit':
          _onAppExitValue = 'exit';
          break;
        case 'stay':
          _onAppExitValue = 'stay';
          break;
      }
    });

    var browser = _settingsProvider.currentBrowser;
    setState(() {
      switch (browser) {
        case BrowserSetting.app:
          _openBrowserValue = '0';
          break;
        case BrowserSetting.external:
          _openBrowserValue = '1';
          break;
      }
    });

    var timeFormat = _settingsProvider.currentTimeFormat;
    setState(() {
      switch (timeFormat) {
        case TimeFormatSetting.h24:
          _timeFormatValue = '0';
          break;
        case TimeFormatSetting.h12:
          _timeFormatValue = '1';
          break;
      }
    });

    var timeZone = _settingsProvider.currentTimeZone;
    setState(() {
      switch (timeZone) {
        case TimeZoneSetting.localTime:
          _timeZoneValue = '0';
          break;
        case TimeZoneSetting.tornTime:
          _timeZoneValue = '1';
          break;
      }
    });

    var appBarPosition = _settingsProvider.appBarTop;
    setState(() {
      appBarPosition ? _appBarPosition = 'top' : _appBarPosition = 'bottom';
    });

    var alertsVibration = await Prefs().getVibrationPattern();
    var manualAlarmSound = await Prefs().getManualAlarmSound();
    var manualAlarmVibration = await Prefs().getManualAlarmVibration();

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
}
