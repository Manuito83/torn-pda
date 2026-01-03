// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/pages/profile/hospital_ahead_options.dart';
import 'package:torn_pda/pages/profile/jail_ahead_options.dart';
import 'package:torn_pda/pages/profile/war_ahead_options.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/travel/travel_options_android.dart';
import 'package:torn_pda/pages/travel/travel_options_ios.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/profile/energy_trigger_dialog.dart';

class ProfileNotificationsIOS extends StatefulWidget {
  final Function callback;
  final int? energyMax;
  final int? nerveMax;

  const ProfileNotificationsIOS({
    required this.callback,
    required this.energyMax,
    required this.nerveMax,
  });

  @override
  ProfileNotificationsIOSState createState() => ProfileNotificationsIOSState();
}

class ProfileNotificationsIOSState extends State<ProfileNotificationsIOS> {
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

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    routeName = "profile_notifications";
    routeWithDrawer = false;
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "profile_notifications") _goBack();
    });
  }

  @override
  void dispose() {
    _willPopSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : isStatusBarShown
                  ? _themeProvider.statusBar
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
                                    'values for each type of event.'),
                              ),
                              _rowsWithTypes(),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 20,
                                ),
                                child: Divider(),
                              ),
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
      iconTheme: const IconThemeData(color: Colors.white),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text("Travel timings & text"),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Platform.isAndroid ? const TravelOptionsAndroid() : const TravelOptionsIOS();
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

      if (element == ProfileNotification.energy) {
        types.add(
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 30),
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
            padding: const EdgeInsets.only(left: 15, right: 30),
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
    }

    return Column(
      children: types,
    );
  }

  Future _restorePreferences() async {
    var energyTrigger = await Prefs().getEnergyNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (energyTrigger < _energyMin || energyTrigger > widget.energyMax!) {
      energyTrigger = widget.energyMax!;
    }

    var nerveTrigger = await Prefs().getNerveNotificationValue();
    // In case we pass some incorrect values, we correct them here
    if (nerveTrigger < _nerveMin || nerveTrigger > widget.nerveMax!) {
      nerveTrigger = widget.nerveMax!;
    }

    final travelType = await Prefs().getTravelNotificationType();
    final energyType = await Prefs().getEnergyNotificationType();
    final nerveType = await Prefs().getNerveNotificationType();
    final lifeType = await Prefs().getLifeNotificationType();
    final drugType = await Prefs().getDrugNotificationType();
    final medicalType = await Prefs().getMedicalNotificationType();
    final boosterType = await Prefs().getBoosterNotificationType();
    final hospitalType = await Prefs().getHospitalNotificationType();
    final jailType = await Prefs().getJailNotificationType();
    final rankedWarType = await Prefs().getRankedWarNotificationType();
    final raceStartType = await Prefs().getRaceStartNotificationType();

    setState(() {
      _energyDivisions = ((widget.energyMax! - _energyMin) / 5).floor();
      _energyTrigger = energyTrigger.toDouble();
      _nerveTrigger = nerveTrigger.toDouble();

      _travelDropDownValue = travelType;
      _energyDropDownValue = energyType;
      _nerveDropDownValue = nerveType;
      _lifeDropDownValue = lifeType;
      _drugDropDownValue = drugType;
      _medicalDropDownValue = medicalType;
      _boosterDropDownValue = boosterType;
      _hospitalDropDownValue = hospitalType;
      _jailDropDownValue = jailType;
      _rankedWarDropDownValue = rankedWarType;
      _raceStartDropDownValue = raceStartType;
    });
  }

  void _goBack() async {
    widget.callback();
    routeName = "profile_options";
    routeWithDrawer = false;
    Navigator.of(context).pop();
  }

  DropdownButton<String> _typeDropDown(ProfileNotification profileType) {
    String? value;
    switch (profileType) {
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

    // Timers are not supported on iOS; normalize any legacy timer value to alarm.
    if (value == '2') {
      value = '1';
    }

    value ??= '0';

    return DropdownButton<String>(
      value: value,
      items: const [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 95,
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
            width: 95,
            child: Text(
              "Alarm",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (newValue) {
        if (newValue == null) return;

        switch (profileType) {
          case ProfileNotification.travel:
            Prefs().setTravelNotificationType(newValue);
            setState(() {
              _travelDropDownValue = newValue;
            });
          case ProfileNotification.energy:
            Prefs().setEnergyNotificationType(newValue);
            setState(() {
              _energyDropDownValue = newValue;
            });
          case ProfileNotification.nerve:
            Prefs().setNerveNotificationType(newValue);
            setState(() {
              _nerveDropDownValue = newValue;
            });
          case ProfileNotification.life:
            Prefs().setLifeNotificationType(newValue);
            setState(() {
              _lifeDropDownValue = newValue;
            });
          case ProfileNotification.drugs:
            Prefs().setDrugNotificationType(newValue);
            setState(() {
              _drugDropDownValue = newValue;
            });
          case ProfileNotification.medical:
            Prefs().setMedicalNotificationType(newValue);
            setState(() {
              _medicalDropDownValue = newValue;
            });
          case ProfileNotification.booster:
            Prefs().setBoosterNotificationType(newValue);
            setState(() {
              _boosterDropDownValue = newValue;
            });
          case ProfileNotification.hospital:
            Prefs().setHospitalNotificationType(newValue);
            setState(() {
              _hospitalDropDownValue = newValue;
            });
          case ProfileNotification.jail:
            Prefs().setJailNotificationType(newValue);
            setState(() {
              _jailDropDownValue = newValue;
            });
          case ProfileNotification.rankedWar:
            Prefs().setRankedWarNotificationType(newValue);
            setState(() {
              _rankedWarDropDownValue = newValue;
            });
          case ProfileNotification.raceStart:
            Prefs().setRaceStartNotificationType(newValue);
            setState(() {
              _raceStartDropDownValue = newValue;
            });
        }
      },
    );
  }
}
