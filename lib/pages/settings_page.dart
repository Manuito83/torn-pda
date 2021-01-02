import 'dart:async';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firestore.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/settings/browser_info_dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

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
  bool _apiIsLoading = false;
  OwnProfileModel _userProfile;

  Future _preferencesRestored;

  String _openSectionValue;
  String _onAppExitValue;
  String _openBrowserValue;
  bool _loadBarBrowser;
  bool _chatRemoveEnabled;
  bool _highlightChat;
  Color _highlightColor = Color(0xff7ca900);
  bool _useQuickBrowser;
  String _timeFormatValue;
  String _timeZoneValue;

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;

  var _expandableController = ExpandableController();

  var _apiKeyInputController = TextEditingController();

  String _appBarPosition = "top";

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesRestored = _restorePreferences();
    _ticker = new Timer.periodic(
        Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'settings'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        padding: const EdgeInsets.only(
                            left: 20, top: 0, right: 20, bottom: 10),
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
                            Text("Show chat remove icon"),
                            Switch(
                              value: _chatRemoveEnabled,
                              onChanged: (value) {
                                _settingsProvider.changeChatRemoveEnabled =
                                    value;
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
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 35, 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                        padding: const EdgeInsets.only(
                            left: 20, top: 0, right: 20, bottom: 5),
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
                        padding: const EdgeInsets.only(
                            left: 20, top: 10, right: 20, bottom: 5),
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
                        padding: const EdgeInsets.only(
                            left: 20, top: 0, right: 20, bottom: 0),
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
                        padding: const EdgeInsets.only(
                            left: 20, top: 10, right: 20, bottom: 5),
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
                        padding: const EdgeInsets.only(
                            left: 20, top: 10, right: 20, bottom: 5),
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
                      SizedBox(height: 50),
                    ],
                  ),
                ));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
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
              FlatButton(
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
      title: Text('Settings'),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
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
                              RaisedButton(
                                child: Text("Reload"),
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(new FocusNode());
                                  if (_formKey.currentState.validate()) {
                                    _myCurrentKey = _apiKeyInputController.text;
                                    _getApiDetails(userTriggered: true);
                                  }
                                },
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: 10),
                              ),
                              RaisedButton(
                                child: Text("Remove"),
                                onPressed: () async {
                                  FocusScope.of(context)
                                      .requestFocus(new FocusNode());
                                  // Removes the form error
                                  _formKey.currentState.reset();
                                  _apiKeyInputController.clear();
                                  _myCurrentKey = '';
                                  _userProvider.removeUser();
                                  setState(() {
                                    _userToLoad = false;
                                    _apiError = false;
                                  });
                                  await FirebaseMessaging().deleteInstanceID();
                                  await firestore.deleteUserProfile();
                                  await firebaseAuth.signOut();
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
    } else {
      _expandableController.expanded = true;
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: Card(
          child: ExpandablePanel(
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
                              RaisedButton(
                                child: Text("Load"),
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(new FocusNode());
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
          ],
        ),
      );
    } else if (_myCurrentKey == '') {
      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(30, 30, 30, 0),
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
      ],
      onChanged: (value) {
        // TODO: use settings provider for this?
        SharedPreferencesModel().setDefaultSection(value);
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
            width: 55,
            child: Text(
              "App",
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
            width: 55,
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
        });
      },
    );
  }

  void _getApiDetails({@required bool userTriggered}) async {
    try {
      dynamic myProfile =
          await TornApiCaller.ownProfile(_myCurrentKey).getOwnProfile;
      if (myProfile is OwnProfileModel) {
        setState(() {
          _apiIsLoading = false;
          _userToLoad = true;
          _apiError = false;
          _userProfile = myProfile;
        });
        myProfile
          ..userApiKey = _myCurrentKey
          ..userApiKeyValid = true;
        _userProvider.setUserDetails(userDetails: myProfile);

        // Firestore uploading, but only if "Load" pressed by user
        if (userTriggered) {
          User mFirebaseUser = await firebaseAuth.signInAnon();
          firestore.setUID(mFirebaseUser.uid);
          await firestore.uploadUsersProfileDetail(myProfile,
              forceUpdate: true);
          await firestore
              .uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);
        }
      } else if (myProfile is ApiError) {
        setState(() {
          _apiIsLoading = false;
          _userToLoad = false;
          _apiError = true;
          _errorReason = myProfile.errorReason;
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
      FirebaseCrashlytics.instance
          .log("PDA Crash at LOAD API KEY. User $_myCurrentKey. "
              "Error: $e. Stack: $stack");
      FirebaseCrashlytics.instance.recordError(e, null);
    }
  }

  Future _restorePreferences() async {
    await SharedPreferencesModel().getDefaultSection().then((onValue) {
      setState(() {
        _openSectionValue = onValue;
      });
    });

    if (_userProvider.myUser.userApiKeyValid) {
      setState(() {
        _apiKeyInputController.text = _userProvider.myUser.userApiKey;
        _myCurrentKey = _userProvider.myUser.userApiKey;
        _apiIsLoading = true;
      });
      _getApiDetails(userTriggered: false);
    }

    await _settingsProvider.loadPreferences();

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

    setState(() {
      _loadBarBrowser = _settingsProvider.loadBarBrowser;
      _chatRemoveEnabled = _settingsProvider.chatRemoveEnabled;
      _useQuickBrowser = _settingsProvider.useQuickBrowser;
      _highlightChat = _settingsProvider.highlightChat;
      _highlightColor = Color(_settingsProvider.highlightColor);
    });
  }

  void _timerUpdateInformation() {
    if (_myCurrentKey != '') {
      _getApiDetails(userTriggered: false);
    }
  }
}
