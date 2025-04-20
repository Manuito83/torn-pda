// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/pages/profile/hospital_ahead_options.dart';
import 'package:torn_pda/pages/profile/jail_ahead_options.dart';
import 'package:torn_pda/pages/profile/race_start_ahead_options.dart';
import 'package:torn_pda/pages/profile/war_ahead_options.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/travel/travel_options_android.dart';
import 'package:torn_pda/pages/travel/travel_options_ios.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/profile/energy_trigger_dialog.dart';

class ProfileNotificationsAndroid extends StatefulWidget {
  final Function callback;
  final int? energyMax;
  final int? nerveMax;

  const ProfileNotificationsAndroid({
    required this.callback,
    required this.energyMax,
    required this.nerveMax,
  });

  @override
  ProfileNotificationsAndroidState createState() => ProfileNotificationsAndroidState();
}

class ProfileNotificationsAndroidState extends State<ProfileNotificationsAndroid> {
  final _energyMin = 10.0;
  final _nerveMin = 2.0;

  int? _energyDivisions;

  late double _energyTrigger;
  late double _nerveTrigger;

  String? _travelDropDownValue;
  String? _energyDropDownValue;
  String? _nerveDropDownValue;
  String? _lifeDropDownValue;
  String? _drugDropDownValue;
  String? _medicalDropDownValue;
  String? _boosterDropDownValue;
  String? _hospitalDropDownValue;
  String? _jailDropDownValue;
  String? _rankedWarDropDownValue;
  String? _raceStartDropDownValue;

  Future? _preferencesLoaded;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeName = "profile_notifications";
    routeWithDrawer = false;
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "profile_notifications") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
        left: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Builder(
            builder: (BuildContext context) {
              return Container(
                color: _themeProvider.canvas,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                  child: FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Here you can specify your preferred alerting '
                                    'method for each type of event.'),
                              ),
                              _rowsWithTypes(),
                              const SizedBox(height: 50),
                            ],
                          ),
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Notification options", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  Widget _rowsWithTypes() {
    final types = <Widget>[];
    late String typeString;
    ProfileNotification profileType;
    for (final element in ProfileNotification.values) {
      switch (element) {
        case ProfileNotification.travel:
          typeString = 'Travel';
          profileType = ProfileNotification.travel;
        case ProfileNotification.energy:
          typeString = 'Energy';
          profileType = ProfileNotification.energy;
        case ProfileNotification.nerve:
          typeString = 'Nerve';
          profileType = ProfileNotification.nerve;
        case ProfileNotification.life:
          typeString = 'Life';
          profileType = ProfileNotification.life;
        case ProfileNotification.drugs:
          typeString = 'Drugs';
          profileType = ProfileNotification.drugs;
        case ProfileNotification.medical:
          typeString = 'Medical';
          profileType = ProfileNotification.medical;
        case ProfileNotification.booster:
          typeString = 'Booster';
          profileType = ProfileNotification.booster;
        case ProfileNotification.hospital:
          typeString = 'Hospital';
          profileType = ProfileNotification.hospital;
        case ProfileNotification.jail:
          typeString = 'Jail';
          profileType = ProfileNotification.jail;
        case ProfileNotification.rankedWar:
          typeString = 'Ranked War';
          profileType = ProfileNotification.rankedWar;
        case ProfileNotification.raceStart:
          typeString = 'Race Start';
          profileType = ProfileNotification.raceStart;
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
              const Padding(
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
              "Profile section (in that case you'll have direct access to all types of notification methods)",
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
                const Text("Travel timings & text"),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    if (Platform.isAndroid) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const TravelOptionsAndroid();
                          },
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const TravelOptionsIOS();
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
        types.add(const SizedBox(height: 10));
      }

      if (element == ProfileNotification.energy) {
        types.add(
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Flexible(child: Text('Trigger')),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('E${_energyTrigger.floor()}'),
                    Slider(
                      value: _energyTrigger,
                      min: _energyMin,
                      max: widget.energyMax!.toDouble(),
                      divisions: _energyDivisions,
                      onChanged: (double newValue) {
                        setState(() {
                          _energyTrigger = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        Prefs().setEnergyNotificationValue(finalValue.floor());
                      },
                    ),
                    GestureDetector(
                      child: const Icon(MdiIcons.alarmPanelOutline, size: 21),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return EnergyNerveTriggerDialog(
                              parameterCallback: (newEnergy) {
                                setState(() {
                                  _energyTrigger = newEnergy.toDouble();
                                });
                                Prefs().setEnergyNotificationValue(newEnergy.floor());
                              },
                              currentValue: _energyTrigger.toInt(),
                              minimum: _energyMin.toInt(),
                              maximun: widget.energyMax!,
                            );
                          },
                        );
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
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Flexible(child: Text('Trigger')),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('N${_nerveTrigger.floor()}'),
                    Slider(
                      value: _nerveTrigger,
                      min: _nerveMin,
                      max: widget.nerveMax!.toDouble(),
                      onChanged: (double newValue) {
                        setState(() {
                          _nerveTrigger = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        Prefs().setNerveNotificationValue(finalValue.floor());
                      },
                    ),
                    GestureDetector(
                      child: const Icon(MdiIcons.alarmPanelOutline, size: 21),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return EnergyNerveTriggerDialog(
                              parameterCallback: (newNerve) {
                                setState(() {
                                  _nerveTrigger = newNerve.toDouble();
                                });
                                Prefs().setNerveNotificationValue(newNerve.floor());
                              },
                              currentValue: _nerveTrigger.toInt(),
                              minimum: _nerveMin.toInt(),
                              maximun: widget.nerveMax!,
                            );
                          },
                        );
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
                const Text("Hospital notification timings"),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const HospitalAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(const SizedBox(height: 10));
      }

      if (element == ProfileNotification.jail) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Jail notification timings"),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const JailAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(const SizedBox(height: 10));
      }

      if (element == ProfileNotification.rankedWar) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Ranked War notification timings"),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const WarAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(const SizedBox(height: 10));
      }

      if (element == ProfileNotification.raceStart) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Race start notification timings"),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const RaceStartAheadOptions();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
        types.add(const SizedBox(height: 10));
      }
    }

    return Column(
      children: types,
    );
  }

  DropdownButton _typeDropDown(ProfileNotification notificationType) {
    String? value;
    switch (notificationType) {
      case ProfileNotification.travel:
        value = _travelDropDownValue;
      case ProfileNotification.energy:
        value = _energyDropDownValue;
      case ProfileNotification.nerve:
        value = _nerveDropDownValue;
      case ProfileNotification.life:
        value = _lifeDropDownValue;
      case ProfileNotification.drugs:
        value = _drugDropDownValue;
      case ProfileNotification.medical:
        value = _medicalDropDownValue;
      case ProfileNotification.booster:
        value = _boosterDropDownValue;
      case ProfileNotification.hospital:
        value = _hospitalDropDownValue;
      case ProfileNotification.jail:
        value = _jailDropDownValue;
      case ProfileNotification.rankedWar:
        value = _rankedWarDropDownValue;
      case ProfileNotification.raceStart:
        value = _raceStartDropDownValue;
    }

    return DropdownButton<String>(
      value: value,
      items: const [
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
            Prefs().setTravelNotificationType(value!);
            setState(() {
              _travelDropDownValue = value;
            });
          case ProfileNotification.energy:
            Prefs().setEnergyNotificationType(value!);
            setState(() {
              _energyDropDownValue = value;
            });
          case ProfileNotification.nerve:
            Prefs().setNerveNotificationType(value!);
            setState(() {
              _nerveDropDownValue = value;
            });
          case ProfileNotification.life:
            Prefs().setLifeNotificationType(value!);
            setState(() {
              _lifeDropDownValue = value;
            });
          case ProfileNotification.drugs:
            Prefs().setDrugNotificationType(value!);
            setState(() {
              _drugDropDownValue = value;
            });
          case ProfileNotification.medical:
            Prefs().setMedicalNotificationType(value!);
            setState(() {
              _medicalDropDownValue = value;
            });
          case ProfileNotification.booster:
            Prefs().setBoosterNotificationType(value!);
            setState(() {
              _boosterDropDownValue = value;
            });
          case ProfileNotification.hospital:
            Prefs().setHospitalNotificationType(value!);
            setState(() {
              _hospitalDropDownValue = value;
            });
          case ProfileNotification.jail:
            Prefs().setJailNotificationType(value!);
            setState(() {
              _jailDropDownValue = value;
            });
          case ProfileNotification.rankedWar:
            Prefs().setRankedWarNotificationType(value!);
            setState(() {
              _rankedWarDropDownValue = value;
            });
          case ProfileNotification.raceStart:
            Prefs().setRaceStartNotificationType(value!);
            setState(() {
              _raceStartDropDownValue = value;
            });
        }
      },
    );
  }

  Future _restorePreferences() async {
    final travelType = await Prefs().getTravelNotificationType();

    final energyType = await Prefs().getEnergyNotificationType();
    var energyTrigger = await Prefs().getEnergyNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (energyTrigger < _energyMin || energyTrigger > widget.energyMax!) {
      energyTrigger = widget.energyMax!;
    }

    final nerveType = await Prefs().getNerveNotificationType();
    var nerveTrigger = await Prefs().getNerveNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (nerveTrigger < _nerveMin || nerveTrigger > widget.nerveMax!) {
      nerveTrigger = widget.nerveMax!;
    }

    final lifeType = await Prefs().getLifeNotificationType();
    final drugsType = await Prefs().getDrugNotificationType();
    final medicalType = await Prefs().getMedicalNotificationType();
    final hospitalType = await Prefs().getHospitalNotificationType();
    final jailType = await Prefs().getJailNotificationType();
    final rankedWarType = await Prefs().getRankedWarNotificationType();
    final raceStartType = await Prefs().getRaceStartNotificationType();
    final boosterType = await Prefs().getBoosterNotificationType();

    setState(() {
      _travelDropDownValue = travelType;

      _energyDivisions = ((widget.energyMax! - _energyMin) / 5).floor();

      _energyDropDownValue = energyType;
      _energyTrigger = energyTrigger.toDouble();

      _nerveDropDownValue = nerveType;
      _nerveTrigger = nerveTrigger.toDouble();

      _lifeDropDownValue = lifeType;
      _drugDropDownValue = drugsType;
      _medicalDropDownValue = medicalType;
      _hospitalDropDownValue = hospitalType;
      _jailDropDownValue = jailType;
      _rankedWarDropDownValue = rankedWarType;
      _raceStartDropDownValue = raceStartType;
      _boosterDropDownValue = boosterType;
    });
  }

  _goBack() async {
    widget.callback();
    routeName = "profile_options";
    routeWithDrawer = false;
    Navigator.of(context).pop();
  }
}
