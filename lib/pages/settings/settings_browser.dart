import 'dart:async';
import 'package:flutter/material.dart';
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

  bool _highlightChat;
  Color _highlightColor = Color(0xff7ca900);

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
                    value: _settingsProvider.extraPlayerInformation,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeExtraPlayerInformation = value;
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
            if (_settingsProvider.extraPlayerInformation)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Show players' stats",
                        ),
                        _profileStatsDropdown(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            "If 'always' is selected, you will be shown either spied stats (supported by YATA) or estimated stats "
                            "(which might be inaccurate) if the former can't be found. Alternatively, select only spied stats or hide all stats entirely.",
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
                ],
              ),
            if (_settingsProvider.extraPlayerInformation)
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
                    value: _userScriptsProvider.userScriptsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _userScriptsProvider.setUserScriptsEnabled = value;
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
            if (_userScriptsProvider.userScriptsEnabled)
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
                      _settingsProvider.setClearCacheNextOpportunity = true;
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
                value: _settingsProvider.removeAirplane,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeRemoveAirplane = value;
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
                value: _settingsProvider.chatRemoveEnabled,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeChatRemoveEnabled = value;
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
                value: _settingsProvider.highlightChat,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeHighlightChat = value;
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
                value: _settingsProvider.loadBarBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeLoadBarBrowser = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Refresh method"),
              _refreshMethodDropdown(),
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
        */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Use quick browser"),
              Switch(
                value: _settingsProvider.useQuickBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseQuickBrowser = value;
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

  Widget _refreshMethodDropdown() {
    return DropdownButton<BrowserRefreshSetting>(
      value: _settingsProvider.browserRefreshMethod,
      items: [
        DropdownMenuItem(
          value: BrowserRefreshSetting.icon,
          child: SizedBox(
            width: 100,
            child: Text(
              "Icon",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.pull,
          child: SizedBox(
            width: 100,
            child: Text(
              "Pull to refresh",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.both,
          child: SizedBox(
            width: 100,
            child: Text(
              "Both",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeBrowserRefreshMethod = value;
        });
      },
    );
  }

  DropdownButton _profileStatsDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.profileStatsEnabled,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "All stats",
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
              "Spied only",
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
          _settingsProvider.changeProfileStatsEnabled = value;
        });
      },
    );
  }

  Future _restorePreferences() async {
    setState(() {
      _highlightChat = _settingsProvider.highlightChat;
      _highlightColor = Color(_settingsProvider.highlightColor);
    });
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
