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
import 'package:torn_pda/pages/profile/war_ahead_options.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/pages/travel/travel_options_android.dart';
import 'package:torn_pda/pages/travel/travel_options_windows.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/profile/energy_trigger_dialog.dart';

class ProfileNotificationsWindows extends StatefulWidget {
  final Function callback;
  final int? energyMax;
  final int? nerveMax;

  const ProfileNotificationsWindows({
    required this.callback,
    required this.energyMax,
    required this.nerveMax,
  });

  @override
  ProfileNotificationsWindowsState createState() => ProfileNotificationsWindowsState();
}

class ProfileNotificationsWindowsState extends State<ProfileNotificationsWindows> {
  final _energyMin = 10.0;
  final _nerveMin = 2.0;

  int? _energyDivisions;

  late double _energyTrigger;
  late double _nerveTrigger;

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
    for (final element in ProfileNotification.values) {
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
                            return const TravelOptionsWindows();
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
            padding: const EdgeInsets.only(left: 15, right: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Flexible(child: Text('Energy')),
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
                const Flexible(child: Text('Nerve')),
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

    setState(() {
      _energyDivisions = ((widget.energyMax! - _energyMin) / 5).floor();
      _energyTrigger = energyTrigger.toDouble();
      _nerveTrigger = nerveTrigger.toDouble();
    });
  }

  _goBack() async {
    widget.callback();
    routeName = "profile_options";
    routeWithDrawer = false;
    Navigator.of(context).pop();
  }
}
