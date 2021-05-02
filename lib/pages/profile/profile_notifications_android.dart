// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/pages/profile/hospital_ahead_options.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/travel/travel_options_android.dart';
import 'package:torn_pda/pages/travel/travel_options_ios.dart';
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
  _ProfileNotificationsAndroidState createState() =>
      _ProfileNotificationsAndroidState();
}

class _ProfileNotificationsAndroidState
    extends State<ProfileNotificationsAndroid> {
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
  String _hospitalDropDownValue;

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
                  onTap: () =>
                      FocusScope.of(context).requestFocus(new FocusNode()),
                  child: FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context,
                        AsyncSnapshot<dynamic> snapshot) {
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
      title: Text("Notification options"),
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
    var types = <Widget>[];
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
        case ProfileNotification.hospital:
          typeString = 'Hospital';
          profileType = ProfileNotification.hospital;
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
              'This option does not apply if you are using the dedicated card for Travel in the '
              'Profile section (in that case you\'ll have direct access to all types of notification methods)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Travel timings & text"),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    if (Platform.isAndroid) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return TravelOptionsAndroid();
                          },
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return TravelOptionsIOS();
                          },
                        ),
                      );
                    }
                  },
                ),
              ],
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
                        Prefs()
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
                        Prefs()
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

      if (element == ProfileNotification.hospital) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Hospital notification timings"),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return HospitalAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(SizedBox(height: 10));
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
      case ProfileNotification.hospital:
        value = _hospitalDropDownValue;
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
            Prefs().setTravelNotificationType(value);
            setState(() {
              _travelDropDownValue = value;
            });
            break;
          case ProfileNotification.energy:
            Prefs().setEnergyNotificationType(value);
            setState(() {
              _energyDropDownValue = value;
            });
            break;
          case ProfileNotification.nerve:
            Prefs().setNerveNotificationType(value);
            setState(() {
              _nerveDropDownValue = value;
            });
            break;
          case ProfileNotification.life:
            Prefs().setLifeNotificationType(value);
            setState(() {
              _lifeDropDownValue = value;
            });
            break;
          case ProfileNotification.drugs:
            Prefs().setDrugNotificationType(value);
            setState(() {
              _drugDropDownValue = value;
            });
            break;
          case ProfileNotification.medical:
            Prefs().setMedicalNotificationType(value);
            setState(() {
              _medicalDropDownValue = value;
            });
            break;
          case ProfileNotification.booster:
            Prefs().setBoosterNotificationType(value);
            setState(() {
              _boosterDropDownValue = value;
            });
            break;
          case ProfileNotification.hospital:
            Prefs().setHospitalNotificationType(value);
            setState(() {
              _hospitalDropDownValue = value;
            });
            break;
        }
      },
    );
  }

  Future _restorePreferences() async {
    var travelType = await Prefs().getTravelNotificationType();

    var energyType = await Prefs().getEnergyNotificationType();
    var energyTrigger =
        await Prefs().getEnergyNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (energyTrigger < _energyMin || energyTrigger > widget.energyMax) {
      energyTrigger = widget.energyMax;
    }

    var nerveType = await Prefs().getNerveNotificationType();
    var nerveTrigger =
        await Prefs().getNerveNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (nerveTrigger < _nerveMin || nerveTrigger > widget.nerveMax) {
      nerveTrigger = widget.nerveMax;
    }

    var lifeType = await Prefs().getLifeNotificationType();
    var drugsType = await Prefs().getDrugNotificationType();
    var medicalType =
        await Prefs().getMedicalNotificationType();
    var hospitalType =
        await Prefs().getHospitalNotificationType();
    var boosterType =
        await Prefs().getBoosterNotificationType();

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
      _hospitalDropDownValue = hospitalType;
      _boosterDropDownValue = boosterType;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
