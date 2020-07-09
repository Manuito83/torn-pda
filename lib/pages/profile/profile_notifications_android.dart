import 'package:android_intent/android_intent.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/pages/profile_page.dart';
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
  _ProfileNotificationsAndroidState createState() =>
      _ProfileNotificationsAndroidState();
}

class _ProfileNotificationsAndroidState
    extends State<ProfileNotificationsAndroid> {
  String _energyDropDownValue;
  String _nerveDropDownValue;
  String _lifeDropDownValue;
  String _drugDropDownValue;
  String _medicalDropDownValue;
  String _boosterDropDownValue;

  bool _alarmSound;
  bool _alarmVibration;

  double _energyValue = 20;
  double _nerveValue = 20;

  Future _preferencesLoaded;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Profile options"),
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              widget.callback();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
              child: FutureBuilder(
                future: _preferencesLoaded,
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                                'Here you can specify your preferred alerting '
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
                                text:
                                    'Note: some Android clock applications do not work well '
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
                                    SharedPreferencesModel()
                                        .setProfileAlarmSound(value);
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
                                Text("Alarm vibration"),
                                Switch(
                                  value: _alarmVibration,
                                  onChanged: (value) {
                                    setState(() {
                                      _alarmVibration = value;
                                    });
                                    SharedPreferencesModel()
                                        .setProfileAlarmVibration(value);
                                  },
                                  activeTrackColor: Colors.lightGreenAccent,
                                  activeColor: Colors.green,
                                ),
                              ],
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
    );
  }

  Widget _rowsWithTypes() {
    var types = List<Widget>();
    String typeString;
    ProfileNotification profileType;
    ProfileNotification.values.forEach((element) {
      switch (element) {
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
                    Text('E${_energyValue.floor()}'),
                    Slider(
                      value: _energyValue.toDouble(),
                      min: 10,
                      max: widget.energyMax.toDouble(),
                      onChanged: (double newValue) {
                        setState(() {
                          _energyValue = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        SharedPreferencesModel()
                            .setEnergyNotificationValue(finalValue.floor());
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
                    Text('N${_nerveValue.floor()}'),
                    Slider(
                      value: _nerveValue.toDouble(),
                      min: 2,
                      max: widget.nerveMax.toDouble(),
                      onChanged: (double newValue) {
                        setState(() {
                          _nerveValue = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        SharedPreferencesModel()
                            .setNerveNotificationValue(finalValue.floor());
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
    var energy = await SharedPreferencesModel().getEnergyNotificationType();
    var energyValue =
        await SharedPreferencesModel().getEnergyNotificationValue();

    var nerve = await SharedPreferencesModel().getNerveNotificationType();
    var nerveValue =
    await SharedPreferencesModel().getNerveNotificationValue();

    var life = await SharedPreferencesModel().getLifeNotificationType();
    var drugs = await SharedPreferencesModel().getDrugNotificationType();
    var medical = await SharedPreferencesModel().getMedicalNotificationType();
    var booster = await SharedPreferencesModel().getBoosterNotificationType();
    var alarmSound = await SharedPreferencesModel().getProfileAlarmSound();
    var alarmVibration =
        await SharedPreferencesModel().getProfileAlarmVibration();

    setState(() {
      _energyDropDownValue = energy;
      _energyValue = energyValue.toDouble();

      _nerveDropDownValue = nerve;
      _nerveValue = nerveValue.toDouble();

      _lifeDropDownValue = life;
      _drugDropDownValue = drugs;
      _medicalDropDownValue = medical;
      _boosterDropDownValue = booster;
      _alarmSound = alarmSound;
      _alarmVibration = alarmVibration;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
