import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/chaining_page.dart';
import 'package:torn_pda/pages/settings_page.dart';
import 'package:torn_pda/pages/travel_page.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webview_travel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class DrawerPage extends StatefulWidget {
  @override
  _DrawerPageState createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final _drawerItemsList = [
    "Travel",
    "Chaining",
    "Settings",
  ];

  ThemeProvider _themeProvider;

  Future _finishedWithPreferences;

  int _activeDrawerIndex = 0;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _handleChangelog();
    _finishedWithPreferences = _restoreSharedPreferences();
    _configureSelectNotificationSubject();
  }

  @override
  void dispose() {
    selectNotificationSubject.close();
    super.dispose();
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
                builder: (BuildContext context) => TornWebViewTravel(
                  webViewType: WebViewTypeTravel.generic,
                  genericTitle: 'Travel',
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
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
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
          return SizedBox.shrink();
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
    for (var i = 0; i < _drawerItemsList.length; i++) {
      // Adding divider just before SETTINGS
      if (i == _drawerItemsList.length - 1) {
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
    return Column(children: drawerOptions);
  }

  Widget _getPages() {
    switch (_activeDrawerIndex) {
      case 0:
        return TravelPage();
        break;
      case 1:
        return ChainingPage();
        break;
      case 2:
        return SettingsPage();
        break;
      default:
        return new Text("Error");
    }
  }

  Widget _returnDrawerIcons({int drawerPosition}) {
    switch (drawerPosition) {
      case 0:
        return Icon(Icons.local_airport);
        break;
      case 1:
        return Icon(Icons.link);
        break;
      case 2:
        return Icon(Icons.settings);
        break;
      default:
        return SizedBox.shrink();
    }
  }

  _onSelectItem(int index) {
    Navigator.of(context).pop();
    setState(() {
      _selected = index;
      _activeDrawerIndex = index;
    });
  }

  Future<void> _restoreSharedPreferences() async {
    String key = await SharedPreferencesModel().getApiKey();
    if (key == '') {
      // If key is empty, redirect to the Settings page
      _selected = 2;
      _activeDrawerIndex = 2;
    } else {
      var defaultSection = await SharedPreferencesModel().getDefaultSection();
      _selected = int.parse(defaultSection);
      _activeDrawerIndex = int.parse(defaultSection);
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
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return ChangeLog();
      },
    );
  }
}
