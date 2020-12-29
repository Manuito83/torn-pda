import 'package:android_intent/android_intent.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ProfileNotificationsAndroid extends StatefulWidget {
  final Function callback;
  final int energyMax;
  final int nerveMax;

  ProfileNotificationsAndroid({
    @required this.callback,
    @required this.energyMax,
    @required this.nerveMax,
  });

  @override
  _ProfileNotificationsAndroidState createState() => _ProfileNotificationsAndroidState();
}

class _ProfileNotificationsAndroidState extends State<ProfileNotificationsAndroid> {
  final _energyMin = 10.0;
  final _nerveMin = 2.0;

  int _energyDivisions;

  double _energyTrigger;
  double _nerveTrigger;

  String _travelDropDownValue;
  String _energyDropDownValue;
  String _nerveDropDownValue;
  String _lifeDropDownValue;
  String _drugDropDownValue;
  String _medicalDropDownValue;
  String _boosterDropDownValue;

  bool _alarmSound;
  bool _alarmVibration;

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
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text('Here you can specify your preferred alerting '
                                    'method for each type of event.'),
                              ),
                              _rowsWithTypes(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 20,
                                ),
                                child: Divider(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Note: some Android clock applications do not work well '
                                        'with more than 1 timer or do not allow to choose '
                                        'between sound and vibration for alarms. If you experience '
                                        'any issue, it is recommended to install ',
                                    style: DefaultTextStyle.of(context).style,
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
                                      TextSpan(
                                        text: '.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Alarm sound"),
                                    Switch(
                                      value: _alarmSound,
                                      onChanged: (value) {
                                        setState(() {
                                          _alarmSound = value;
                                        });
                                        SharedPreferencesModel().setProfileAlarmSound(value);
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Text(
                                      'Not applicable to travel',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Alarm vibration"),
                                    Switch(
                                      value: _alarmVibration,
                                      onChanged: (value) {
                                        setState(() {
                                          _alarmVibration = value;
                                        });
                                        SharedPreferencesModel().setProfileAlarmVibration(value);
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Text(
                                      'Not applicable to travel',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
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
      title: Text("Profile options"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _rowsWithTypes() {
    var types = List<Widget>();
    String typeString;
    ProfileNotification profileType;
    ProfileNotification.values.forEach((element) {
      switch (element) {
        case ProfileNotification.travel:
          typeString = 'Travel';
          profileType = ProfileNotification.travel;
          break;
        case ProfileNotification.energy:
          typeString = 'Energy';
          profileType = ProfileNotification.energy;
          break;
        case ProfileNotification.nerve:
          typeString = 'Nerve';
          profileType = ProfileNotification.nerve;
          break;
        case ProfileNotification.life:
          typeString = 'Life';
          profileType = ProfileNotification.life;
          break;
        case ProfileNotification.drugs:
          typeString = 'Drugs';
          profileType = ProfileNotification.drugs;
          break;
        case ProfileNotification.medical:
          typeString = 'Medical';
          profileType = ProfileNotification.medical;
          break;
        case ProfileNotification.booster:
          typeString = 'Booster';
          profileType = ProfileNotification.booster;
          break;
      }

      types.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(typeString),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20),
              ),
              Flexible(
                child: _typeDropDown(profileType),
              ),
            ],
          ),
        ),
      );

      if (element == ProfileNotification.travel) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              'Please note that the main configuration for travel notifications (such us the '
              'notification title, alarm sound or the alerting time before arrival) is '
              'taken from what you have selected in the Travel section',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
        types.add(SizedBox(height: 10));
      }

      if (element == ProfileNotification.energy) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Trigger'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('E${_energyTrigger.floor()}'),
                    Slider(
                      value: _energyTrigger.toDouble(),
                      min: _energyMin,
                      max: widget.energyMax.toDouble(),
                      divisions: _energyDivisions,
                      onChanged: (double newValue) {
                        setState(() {
                          _energyTrigger = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        SharedPreferencesModel().setEnergyNotificationValue(finalValue.floor());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      if (element == ProfileNotification.nerve) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Trigger'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('N${_nerveTrigger.floor()}'),
                    Slider(
                      value: _nerveTrigger.toDouble(),
                      min: _nerveMin,
                      max: widget.nerveMax.toDouble(),
                      onChanged: (double newValue) {
                        setState(() {
                          _nerveTrigger = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        SharedPreferencesModel().setNerveNotificationValue(finalValue.floor());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      children: types,
    );
  }

  DropdownButton _typeDropDown(ProfileNotification notificationType) {
    String value;
    switch (notificationType) {
      case ProfileNotification.travel:
        value = _travelDropDownValue;
        break;
      case ProfileNotification.energy:
        value = _energyDropDownValue;
        break;
      case ProfileNotification.nerve:
        value = _nerveDropDownValue;
        break;
      case ProfileNotification.life:
        value = _lifeDropDownValue;
        break;
      case ProfileNotification.drugs:
        value = _drugDropDownValue;
        break;
      case ProfileNotification.medical:
        value = _medicalDropDownValue;
        break;
      case ProfileNotification.booster:
        value = _boosterDropDownValue;
        break;
    }

    return DropdownButton<String>(
      value: value,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "Notification",
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
              "Alarm",
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
              "Timer",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        switch (notificationType) {
          case ProfileNotification.travel:
            SharedPreferencesModel().setTravelNotificationType(value);
            setState(() {
              _travelDropDownValue = value;
            });
            break;
          case ProfileNotification.energy:
            SharedPreferencesModel().setEnergyNotificationType(value);
            setState(() {
              _energyDropDownValue = value;
            });
            break;
          case ProfileNotification.nerve:
            SharedPreferencesModel().setNerveNotificationType(value);
            setState(() {
              _nerveDropDownValue = value;
            });
            break;
          case ProfileNotification.life:
            SharedPreferencesModel().setLifeNotificationType(value);
            setState(() {
              _lifeDropDownValue = value;
            });
            break;
          case ProfileNotification.drugs:
            SharedPreferencesModel().setDrugNotificationType(value);
            setState(() {
              _drugDropDownValue = value;
            });
            break;
          case ProfileNotification.medical:
            SharedPreferencesModel().setMedicalNotificationType(value);
            setState(() {
              _medicalDropDownValue = value;
            });
            break;
          case ProfileNotification.booster:
            SharedPreferencesModel().setBoosterNotificationType(value);
            setState(() {
              _boosterDropDownValue = value;
            });
            break;
        }
      },
    );
  }

  Future _restorePreferences() async {
    var travelType = await SharedPreferencesModel().getTravelNotificationType();

    var energyType = await SharedPreferencesModel().getEnergyNotificationType();
    var energyTrigger = await SharedPreferencesModel().getEnergyNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (energyTrigger < _energyMin || energyTrigger > widget.energyMax) {
      energyTrigger = widget.energyMax;
    }

    var nerveType = await SharedPreferencesModel().getNerveNotificationType();
    var nerveTrigger = await SharedPreferencesModel().getNerveNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (nerveTrigger < _nerveMin || nerveTrigger > widget.nerveMax) {
      nerveTrigger = widget.nerveMax;
    }

    var lifeType = await SharedPreferencesModel().getLifeNotificationType();
    var drugsType = await SharedPreferencesModel().getDrugNotificationType();
    var medicalType = await SharedPreferencesModel().getMedicalNotificationType();
    var boosterType = await SharedPreferencesModel().getBoosterNotificationType();

    var alarmSound = await SharedPreferencesModel().getProfileAlarmSound();
    var alarmVibration = await SharedPreferencesModel().getProfileAlarmVibration();

    setState(() {
      _travelDropDownValue = travelType;

      _energyDivisions = ((widget.energyMax - _energyMin) / 5).floor();

      _energyDropDownValue = energyType;
      _energyTrigger = energyTrigger.toDouble();

      _nerveDropDownValue = nerveType;
      _nerveTrigger = nerveTrigger.toDouble();

      _lifeDropDownValue = lifeType;
      _drugDropDownValue = drugsType;
      _medicalDropDownValue = medicalType;
      _boosterDropDownValue = boosterType;
      _alarmSound = alarmSound;
      _alarmVibration = alarmVibration;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
