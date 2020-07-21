import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/about.dart';
import 'package:torn_pda/pages/alerts.dart';
import 'package:torn_pda/pages/chaining_page.dart';
import 'package:torn_pda/pages/friends_page.dart';
import 'package:torn_pda/pages/loot.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/settings_page.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/pages/travel_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:torn_pda/widgets/webviews/webview_generic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class DrawerPage extends StatefulWidget {
  @override
  _DrawerPageState createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  int _settingsPosition = 6;
  int _aboutPosition = 7;
  var _allowSectionsWithoutKey = [];

  final _drawerItemsList = [
    "Profile",
    "Travel",
    "Chaining",
    "Loot",
    "Friends",
    "Alerts",
    "Settings",
    "About",
  ];

  ThemeProvider _themeProvider;
  UserDetailsProvider _userProvider;
  SettingsProvider _settingsProvider;
  final FirebaseMessaging _messaging = FirebaseMessaging();
  final FirebaseAnalytics analytics = FirebaseAnalytics();

  Future _finishedWithPreferences;

  int _activeDrawerIndex = 0;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _allowSectionsWithoutKey = [
      _settingsPosition,
      _aboutPosition,
    ];
    _handleChangelog();
    _finishedWithPreferences = _loadInitPreferences();
    _configureSelectNotificationSubject();

    _messaging.requestNotificationPermissions(IosNotificationSettings(
      sound: true,
      badge: true,
      alert: true,
      provisional: false,
    ));
    _messaging.configure(
      onResume: (message) {
        return _fireLaunchResumeNotifications(message);
      },
      onLaunch: (message) {
        return _fireLaunchResumeNotifications(message);
      },
      onMessage: (message) {
        return showNotification(message);
      },
    );
  }

  @override
  void dispose() {
    selectNotificationSubject.close();
    super.dispose();
  }

  // TODO: transfer notification functions to two separate files in utils
  Future<void> _fireLaunchResumeNotifications(Map message) async {
    bool travel = false;

    if (Platform.isIOS) {
      if (message["message"].contains("about to land")) {
        travel = true;
      }
    } else if (Platform.isAndroid) {
      if (message["data"]["message"].contains("about to land")) {
        travel = true;
      }
    }

    if (travel) {
      // iOS seems to open a blank WebView unless we allow some time onResume
      await Future.delayed(Duration(milliseconds: 500));
      // Works best if we get SharedPrefs directly instead of SettingsProvider
      var browserType = await SharedPreferencesModel().getDefaultBrowser();
      switch (browserType) {
        case 'app':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => WebViewFull(
                customTitle: 'Travel',
              ),
            ),
          );
          break;
        case 'external':
          var url = 'https://www.torn.com';
          if (await canLaunch(url)) {
            await launch(url, forceSafariVC: false);
          }
          break;
      }
    }
  }

  Future<void> _configureSelectNotificationSubject() async {
    selectNotificationSubject.stream.listen((String payload) async {
      if (payload == 'travel') {
        // Works best if we get SharedPrefs directly instead of SettingsProvider
        var browserType = await SharedPreferencesModel().getDefaultBrowser();
        switch (browserType) {
          case 'app':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => WebViewFull(
                  customTitle: 'Travel',
                ),
              ),
            );
            break;
          case 'external':
            var url = 'https://www.torn.com';
            if (await canLaunch(url)) {
              await launch(url, forceSafariVC: false);
            }
            break;
        }
      } else if (payload.contains('energy')) {
        var browserType = await SharedPreferencesModel().getDefaultBrowser();
        switch (browserType) {
          case 'app':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => TornWebViewGeneric(
                  webViewType: WebViewType.custom,
                  customUrl: 'https://www.torn.com/gym.php',
                  genericTitle: 'Torn',
                ),
              ),
            );
            break;
          case 'external':
            var url = 'https://www.torn.com/gym.php';
            if (await canLaunch(url)) {
              await launch(url, forceSafariVC: false);
            }
            break;
        }
      } else if (payload.contains('nerve')) {
        var browserType = await SharedPreferencesModel().getDefaultBrowser();
        switch (browserType) {
          case 'app':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => TornWebViewGeneric(
                  webViewType: WebViewType.custom,
                  customUrl: 'https://www.torn.com/crimes.php',
                  genericTitle: 'Torn',
                ),
              ),
            );
            break;
          case 'external':
            var url = 'https://www.torn.com/crimes.php';
            if (await canLaunch(url)) {
              await launch(url, forceSafariVC: false);
            }
            break;
        }
      } else if (payload.contains('400-')) {
        var npcId = payload.split('-')[1];
        var browserType = await SharedPreferencesModel().getDefaultBrowser();
        switch (browserType) {
          case 'app':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => TornWebViewGeneric(
                  customUrl: 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId',
                  genericTitle: 'Loot',
                  webViewType: WebViewType.custom,
                ),
              ),
            );
            break;
          case 'external':
            var url = 'https://www.torn.com/loader.php?sid=attack&user2ID=$npcId';
            if (await canLaunch(url)) {
              await launch(url, forceSafariVC: false);
            }
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: true);
    return FutureBuilder(
      future: _finishedWithPreferences,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            body: _getPages(),
            drawer: Drawer(
              elevation: 2, // This avoids shadow over SafeArea
              child: Container(
                decoration: BoxDecoration(
                    color: _themeProvider.currentTheme == AppTheme.light
                        ? Colors.grey[100]
                        : Colors.transparent,
                    backgroundBlendMode: BlendMode.multiply),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    _getDrawerHeader(),
                    _getDrawerItems(),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _getDrawerHeader() {
    return Container(
      height: 300,
      child: DrawerHeader(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                child: Image(
                  image: AssetImage('images/icons/torn_pda.png'),
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'TORN PDA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        _themeProvider.currentTheme == AppTheme.light
                            ? 'Light'
                            : 'Dark',
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20),
                    ),
                    Flexible(
                      child: Switch(
                        value: _themeProvider.currentTheme == AppTheme.dark
                            ? true
                            : false,
                        onChanged: (bool value) {
                          if (value) {
                            _themeProvider.changeTheme = AppTheme.dark;
                          } else {
                            _themeProvider.changeTheme = AppTheme.light;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getDrawerItems() {
    var drawerOptions = <Widget>[];
    // If API key is not valid, we just show the Settings + About pages
    // (just don't add the other sections to the list)
    if (!_userProvider.myUser.userApiKeyValid) {
      for (var position in _allowSectionsWithoutKey) {
        drawerOptions.add(
          ListTileTheme(
            selectedColor: Colors.red,
            iconColor: _themeProvider.mainText,
            child: Ink(
              color:
                  position == _selected ? Colors.grey[300] : Colors.transparent,
              child: ListTile(
                leading: _returnDrawerIcons(drawerPosition: position),
                title: Text(
                  _drawerItemsList[position],
                  style: TextStyle(
                    fontWeight: position == _selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: position == _selected,
                onTap: () => _onSelectItem(position),
              ),
            ),
          ),
        );
      }
    } else {
      // Otherwise, if the key is valid, we loop all the sections
      for (var i = 0; i < _drawerItemsList.length; i++) {
        // Adding divider just before SETTINGS
        if (i == _settingsPosition) {
          drawerOptions.add(Divider());
        }
        drawerOptions.add(
          ListTileTheme(
            selectedColor: Colors.red,
            iconColor: _themeProvider.mainText,
            child: Ink(
              color: i == _selected ? Colors.grey[300] : Colors.transparent,
              child: ListTile(
                leading: _returnDrawerIcons(drawerPosition: i),
                title: Text(
                  _drawerItemsList[i],
                  style: TextStyle(
                    fontWeight:
                        i == _selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: i == _selected,
                onTap: () => _onSelectItem(i),
              ),
            ),
          ),
        );
      }
    }
    return Column(children: drawerOptions);
  }

  Widget _getPages() {
    switch (_activeDrawerIndex) {
      case 0:
        return ProfilePage();
        break;
      case 1:
        return TravelPage();
        break;
      case 2:
        return ChainingPage();
        break;
      case 3:
        return LootPage();
        break;
      case 4:
        return FriendsPage();
        break;
      case 5:
        return AlertsSettings();
        break;
      case 6:
        return SettingsPage();
        break;
      case 7:
        return AboutPage();
        break;

      default:
        return new Text("Error");
    }
  }

  Widget _returnDrawerIcons({int drawerPosition}) {
    switch (drawerPosition) {
      case 0:
        return Icon(Icons.person);
        break;
      case 1:
        return Icon(Icons.local_airport);
        break;
      case 2:
        return Icon(MdiIcons.linkVariant);
        break;
      case 3:
        return Icon(MdiIcons.knifeMilitary);
        break;
      case 4:
        return Icon(Icons.people);
        break;
      case 5:
        return Icon(Icons.notifications_active);
        break;
      case 6:
        return Icon(Icons.settings);
        break;
      case 7:
        return Icon(Icons.info_outline);
        break;
      default:
        return SizedBox.shrink();
    }
  }

  _onSelectItem(int index) async {
/*    await analytics.logEvent(
        name: 'section_changed',
        parameters: {'section': _drawerItemsList[index]});*/

    Navigator.of(context).pop();
    setState(() {
      _selected = index;
      _activeDrawerIndex = index;
    });
  }

  Future<void> _loadInitPreferences() async {
    // Set up SettingsProvider so that user preferences are applied
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await _settingsProvider.loadPreferences();

    // Set up UserProvider. If key is empty, redirect to the Settings page.
    // Else, open the default
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    await _userProvider.loadPreferences();

    if (!_userProvider.myUser.userApiKeyValid) {
      _selected = _settingsPosition;
      _activeDrawerIndex = _settingsPosition;
    } else {
      var defaultSection = await SharedPreferencesModel().getDefaultSection();
      _selected = int.parse(defaultSection);
      _activeDrawerIndex = int.parse(defaultSection);

      // Firestore get auth and init
      var user = await firebaseAuth.currentUser();
      if (user == null) {
        FirebaseUser mFirebaseUser = await firebaseAuth.signInAnon();
        firestore.setUID(mFirebaseUser.uid);
        await firestore.uploadUsersProfileDetail(_userProvider.myUser);
        await firestore
            .uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);
      } else {
        var uid = await firebaseAuth.getUID();
        firestore.setUID(uid);
      }

      var now = DateTime.now().millisecondsSinceEpoch;
      var dTimeStamp = now - _settingsProvider.lastAppUse;
      var duration = Duration(milliseconds: dTimeStamp);
      _settingsProvider.updateLastUsed(now);
      if (duration.inDays > 2) firestore.uploadLastActiveTime(now);
    }
  }

  void _handleChangelog() async {
    String savedVersion = await SharedPreferencesModel().getAppVersion();
    if (savedVersion != appVersion) {
      SharedPreferencesModel().setAppVersion(appVersion);
      if (appNeedsChangelog) {
        _showChangeLogDialog(context);
      }
    }
  }

  void _showChangeLogDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChangeLog();
      },
    );
  }
}
