import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:torn_pda/pages/settings/friendly_factions.dart';
import 'package:torn_pda/pages/settings/userscripts_page.dart';

class SettingsBrowserPage extends StatefulWidget {
  const SettingsBrowserPage({Key key}) : super(key: key);

  @override
  _SettingsBrowserPageState createState() => _SettingsBrowserPageState();
}

class _SettingsBrowserPageState extends State<SettingsBrowserPage> {
  Timer _ticker;

  Future _preferencesRestored;

  bool _loadBarBrowser;
  bool _refreshIconBrowser;
  bool _chatRemoveEnabled;
  bool _highlightChat;
  Color _highlightColor = Color(0xff7ca900);
  bool _removeAirplane;
  bool _useQuickBrowser;
  bool _extraPlayerInformation;
  bool _userScriptsEnabled;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserScriptsProvider _userScriptsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider =
        Provider.of<UserScriptsProvider>(context, listen: false);
    _preferencesRestored = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? Colors.blueGrey
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            drawer: new Drawer(),
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: FutureBuilder(
              future: _preferencesRestored,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        FocusScope.of(context).requestFocus(new FocusNode()),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 15),
                          _general(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _userScripts(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _chat(context),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _travel(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _profile(),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _maintenance(),
                          SizedBox(height: 40),
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
        ),
      ),
    );
  }

  Column _profile() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PLAYER PROFILES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Extra player information"),
                  Switch(
                    value: _extraPlayerInformation,
                    onChanged: (value) {
                      _settingsProvider.changeExtraPlayerInformation = value;
                      setState(() {
                        _extraPlayerInformation = value;
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
                'Add additional player information when visiting a profile or attacking '
                'someone (e.g. same faction, friendly faction, friends) and estimated stats',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_extraPlayerInformation)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Friendly factions",
                        ),
                        IconButton(
                            icon: Icon(Icons.keyboard_arrow_right_outlined),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      FriendlyFactionsPage(),
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'You will see a note if you are visiting the profile of a '
                      'friendly faction\'s player, or a warning if you are about to attack, ',
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
        ),
      ],
    );
  }

  Column _userScripts() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'USER SCRIPTS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Enable custom user scripts"),
                  Switch(
                    value: _userScriptsEnabled,
                    onChanged: (value) {
                      _userScriptsProvider.setUserScriptsEnabled = value;
                      setState(() {
                        _userScriptsEnabled = value;
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
                'You can load custom user scripts in the browser (this feature does not currently '
                'work when using the browser for chaining)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_userScriptsEnabled)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Manage scripts",
                        ),
                        IconButton(
                          icon: Icon(Icons.keyboard_arrow_right_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    UserScriptsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Column _maintenance() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MAINTENANCE',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Browser cache"),
                  ElevatedButton(
                    child: Text("Clear"),
                    onPressed: () async {
                      var headlessWebView = new HeadlessInAppWebView(
                        initialUrlRequest: URLRequest(
                          url: Uri.parse("https://flutter.dev/"),
                        ),
                        onWebViewCreated: (controller) async {
                          await controller.clearCache();
                        },
                      );
                      await headlessWebView.run();
                      await headlessWebView.dispose();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Note: this will clear your browser\'s cache. It can be '
                'useful in case of errors (sections not loading correctly, etc.). '
                'You\'ll be logged-out from Torn and all other sites',
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

  Column _travel() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TRAVEL',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Remove airplane"),
              Switch(
                value: _removeAirplane,
                onChanged: (value) {
                  _settingsProvider.changeRemoveAirplane = value;
                  setState(() {
                    _removeAirplane = value;
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
                'Removes airplane and cloud animation when travelling',
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

  Column _chat(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CHAT',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Show chat remove icon"),
              Switch(
                value: _chatRemoveEnabled,
                onChanged: (value) {
                  _settingsProvider.changeChatRemoveEnabled = value;
                  setState(() {
                    _chatRemoveEnabled = value;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Highlight own name in chat"),
              Switch(
                value: _highlightChat,
                onChanged: (value) {
                  _settingsProvider.changeHighlightChat = value;
                  setState(() {
                    _highlightChat = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        if (_highlightChat)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  _showColorPicker(context);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 35, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Choose highlight color"),
                      Container(
                        width: 25,
                        height: 25,
                        color: _highlightColor,
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'The sender\'s name will appear darker '
                  'to improve readability',
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
          SizedBox.shrink(),
      ],
    );
  }

  Column _general() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GENERAL',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Show load bar"),
              Switch(
                value: _loadBarBrowser,
                onChanged: (value) {
                  _settingsProvider.changeLoadBarBrowser = value;
                  setState(() {
                    _loadBarBrowser = value;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Show refresh icon"),
              Switch(
                value: _refreshIconBrowser,
                onChanged: (value) {
                  _settingsProvider.changeRefreshIconBrowser = value;
                  setState(() {
                    _refreshIconBrowser = value;
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
            'The browser has pull to refresh functionality (not applicable to the chaining browser). '
            'However, you can get an extra refresh icon if it\'s useful for certain situations (e.g. '
            'jail or hospital refresh)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Use quick browser"),
              Switch(
                value: _useQuickBrowser,
                onChanged: (value) {
                  _settingsProvider.changeUseQuickBrowser = value;
                  setState(() {
                    _useQuickBrowser = value;
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
            'Note: this will allow you to open the quick browser in most '
            'places by using a short tap (and long tap for full browser). '
            'This does not apply to the chaining browser and a few other '
            'specific links',
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

  void _showColorPicker(BuildContext context) {
    var pickerColor = _highlightColor;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pick a color!'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: _highlightColor,
                //enableAlpha: false,
                onColorChanged: (color) {
                  _settingsProvider.changeHighlightColor = color.value;
                  setState(() {
                    pickerColor = color;
                  });
                },
                showLabel: true,
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Got it'),
                onPressed: () {
                  setState(() => _highlightColor = pickerColor);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      toolbarHeight: 50,
      title: Text('Browser settings'),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future _restorePreferences() async {
    setState(() {
      _loadBarBrowser = _settingsProvider.loadBarBrowser;
      _refreshIconBrowser = _settingsProvider.refreshIconBrowser;
      _chatRemoveEnabled = _settingsProvider.chatRemoveEnabled;
      _useQuickBrowser = _settingsProvider.useQuickBrowser;
      _highlightChat = _settingsProvider.highlightChat;
      _highlightColor = Color(_settingsProvider.highlightColor);
      _removeAirplane = _settingsProvider.removeAirplane;
      _extraPlayerInformation = _settingsProvider.extraPlayerInformation;
      _userScriptsEnabled = _userScriptsProvider.userScriptsEnabled;
    });
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
