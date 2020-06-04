import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/api_key_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/models/profile_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  Timer _ticker;
  bool _updateRequestedByTicker = false;

  String _myCurrentKey = '';
  bool _userToLoad = false;
  bool _apiError = false;
  String _errorReason = '';
  bool _apiIsLoading = false;
  ProfileModel _userProfile;

  String _openSectionValue;
  String _openBrowserValue;

  SettingsProvider _settingsProvider;
  ApiKeyProvider _apiKeyProvider;

  var _apiKeyInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyProvider = Provider.of<ApiKeyProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _restorePreferences();
    _ticker = new Timer.periodic(
        Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: new Drawer(),
      appBar: AppBar(
        title: Text('Settings'),
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          onPressed: () {
            final ScaffoldState scaffoldState =
                context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
      ),
      body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
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
                      left: 20, top: 5, right: 20, bottom: 10),
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
                                    return AlertDialog(
                                      title: Text("Browser type"),
                                      content: Text(
                                          "Choosing the in-app browser "
                                          "offers a better experience and additional "
                                          "features, such as foreign stock uploading "
                                          "to a common database in YATA that everyone "
                                          "benefits from."
                                          "\n\n"
                                          "Please consider using it, unless you "
                                          "have issues, in which case you can select "
                                          "you mobile phone's default browser (external)."),
                                      actions: [
                                        FlatButton(
                                          child: Text("Close"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        )
                                      ],
                                    );
                                  });
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
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsetsDirectional.only(bottom: 15),
                          child: Text('TORN API Key'),
                        ),
                        SizedBox(
                          width: 300,
                          child: Form(
                            key: _formKey,
                            child: TextFormField(
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
                              onEditingComplete: () {
                                FocusScope.of(context)
                                    .requestFocus(new FocusNode());
                                if (_formKey.currentState.validate()) {
                                  _myCurrentKey = _apiKeyInputController.text;
                                  _getApiDetails();
                                }
                              },
                            ),
                          ),
                        ),
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
                                  _getApiDetails();
                                }
                              },
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(start: 10),
                            ),
                            RaisedButton(
                              child: Text("Remove"),
                              onPressed: () {
                                FocusScope.of(context)
                                    .requestFocus(new FocusNode());
                                // Removes the form error
                                _formKey.currentState.reset();
                                _apiKeyInputController.clear();
                                _myCurrentKey = '';
                                SharedPreferencesModel().setOwnId('');
                                _apiKeyProvider.setApiKey(newApiKey: '');
                                setState(() {
                                  _userToLoad = false;
                                  _apiError = false;
                                });
                              },
                            ),
                          ],
                        ),
                        _explanatoryApiText(),
                        _userDetails(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _explanatoryApiText() {
    if (_myCurrentKey == '') {
      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(30, 30, 30, 0),
        child: Column(
          children: <Widget>[
            Text(
              'Torn PDA needs your API Key to obtain your user\'s '
              'information. The key is protected in the app and will not '
              'be shared under any circunstances.',
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
      return SizedBox.shrink();
    }
  }

  Widget _userDetails() {
    if (_apiIsLoading) {
      return Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      );
    }
    if (_userToLoad) {
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: 30),
              child: Text(
                "USER LOADED",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              "${_userProfile.name} [${_userProfile.playerId}]",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: 8),
            ),
            Text("Gender: ${_userProfile.gender}"),
            Text("Level: ${_userProfile.level}"),
            Text("Life: ${_userProfile.life}"),
            Text("Status: ${_userProfile.status}"),
            Text("Last action: ${_userProfile.lastAction}"),
            Text("Rank: ${_userProfile.rank}"),
          ],
        ),
      );
    } else if (_apiError) {
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: 30),
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
    }
    return SizedBox.shrink();
  }

  DropdownButton _openSectionDropdown() {
    return DropdownButton<String>(
      value: _openSectionValue,
      items: [
        DropdownMenuItem(
          value: "0",
          child: Text(
            "Travel",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: Text(
            "Chaining",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
      onChanged: (value) {
        SharedPreferencesModel().setDefaultSection(value);
        setState(() {
          _openSectionValue = value;
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
          child: Text(
            "App",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: Text(
            "External",
            style: TextStyle(
              fontSize: 14,
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

  void _getApiDetails() async {
    if (!_updateRequestedByTicker) {
      // If it's the ticker updating, we don't want to show a
      // progress bar, but just update the text
      setState(() {
        _apiIsLoading = true;
      });
    }
    dynamic myProfile = await TornApiCaller.profile(_myCurrentKey).getProfile;
    if (myProfile is ProfileModel) {
      setState(() {
        _apiIsLoading = false;
        _userToLoad = true;
        _apiError = false;
        _userProfile = myProfile;
      });
      SharedPreferencesModel().setOwnId(myProfile.playerId.toString());
      _apiKeyProvider.setApiKey(newApiKey: _myCurrentKey);
    } else if (myProfile is ApiError) {
      setState(() {
        _apiIsLoading = false;
        _userToLoad = false;
        _apiError = true;
        _errorReason = myProfile.errorReason;
      });
      SharedPreferencesModel().setOwnId('');
      _apiKeyProvider.setApiKey(newApiKey: '');
    }
  }

  void _restorePreferences() async {
    if (_apiKeyProvider.apiKeyValid) {
      setState(() {
        _apiKeyInputController.text = _apiKeyProvider.apiKey;
        _myCurrentKey = _apiKeyProvider.apiKey;
      });
      _getApiDetails();
    }

    await _settingsProvider.loadPreferences();
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

    await SharedPreferencesModel().getDefaultSection().then((onValue) {
      setState(() {
        _openSectionValue = onValue;
      });
    });
  }

  void _timerUpdateInformation() {
    if (_myCurrentKey != '') {
      _updateRequestedByTicker = true;
      _getApiDetails();
      _updateRequestedByTicker = false;
    }
  }
}
