// Flutter imports:
import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/audio_controller.dart';
// Project imports:
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class ChainWidgetOptions extends StatefulWidget {
  final Function? callBackOptions;

  const ChainWidgetOptions({this.callBackOptions});

  @override
  ChainWidgetOptionsState createState() => ChainWidgetOptionsState();
}

class ChainWidgetOptionsState extends State<ChainWidgetOptions> {
  ThemeProvider? _themeProvider;
  late SettingsProvider _settingsProvider;

  late StreamSubscription _willPopSubscription;

  @override
  initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "chain_watcher_options";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "chain_watcher_options") _goBack();
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

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.callBackOptions!();
          routeWithDrawer = true;
          routeName = "chaining_targets";
        }
      },
      child: Container(
        color: _themeProvider!.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : isStatusBarShown
                    ? _themeProvider!.statusBar
                    : _themeProvider!.canvas
            : _themeProvider!.canvas,
        child: SafeArea(
          child: GetBuilder<ChainStatusController>(builder: (chainP) {
            return Scaffold(
              backgroundColor: _themeProvider!.canvas,
              appBar: _settingsProvider.appBarTop ? buildAppBar(chainP) : null,
              bottomNavigationBar: !_settingsProvider.appBarTop
                  ? SizedBox(
                      height: AppBar().preferredSize.height,
                      child: buildAppBar(chainP),
                    )
                  : null,
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 15),
                        const Text("GENERAL SETTINGS", style: TextStyle(fontSize: 11)),
                        _generalSettings(chainP),
                        const Divider(),
                        const SizedBox(height: 5),
                        const Text("PANIC MODE", style: TextStyle(fontSize: 11)),
                        _panicMode(chainP),
                        const Divider(),
                        const SizedBox(height: 5),
                        const Text("API FAILURE", style: TextStyle(fontSize: 11)),
                        _apiFailure(chainP),
                        const Divider(),
                        const SizedBox(height: 5),
                        const Text("ALERT LEVELS", style: TextStyle(fontSize: 11)),
                        _greenLevel2(chainP),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 100),
                          child: Divider(),
                        ),
                        _orangeLevel1(chainP),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 100),
                          child: Divider(),
                        ),
                        _orangeLevel2(chainP),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 100),
                          child: Divider(),
                        ),
                        _redLevel1(chainP),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 100),
                          child: Divider(),
                        ),
                        _redLevel2(chainP),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  AppBar buildAppBar(ChainStatusController chainP) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Chain Watcher", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.restore),
          onPressed: () {
            _openRestoreDialog(chainP);
          },
        ),
      ],
    );
  }

  Column _generalSettings(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text("Sound alerts"),
            Switch(
              value: chainP.soundEnabled,
              onChanged: (value) {
                chainP.changeSoundEnabled = value;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text("Vibration"),
            Switch(
              value: chainP.vibrationEnabled,
              onChanged: (value) {
                chainP.changeVibrationEnabled = value;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text("Notification"),
            Switch(
              value: chainP.notificationsEnabled,
              onChanged: (value) {
                chainP.changeNotificationsEnabled = value;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Column _panicMode(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                const Text("Enable Panic Mode"),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    _openPanicModeInfoDialog();
                  },
                ),
              ],
            ),
            Switch(
              value: chainP.panicModeEnabled,
              onChanged: (value) {
                chainP.panicModeEnabled ? chainP.disablePanicMode() : chainP.enablePanicMode();
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        if (chainP.panicModeEnabled)
          Column(
            children: [
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.alarm,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "00:00",
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: chainP.panicValue,
                      max: 270,
                      divisions: 27,
                      activeColor: Colors.yellow,
                      onChanged: (value) {
                        chainP.setPanicValue(value);
                      },
                    ),
                  ),
                  Text(
                    _printDuration(Duration(seconds: chainP.panicValue.toInt())),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: [
                      Image.asset(
                        'images/awards/categories/crosshair.png',
                        height: 15,
                        color: _themeProvider!.mainText,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Targets",
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right_outlined),
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AddChainTargetDialog(
                            themeProvider: _themeProvider,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0, right: 20, bottom: 10),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        "You can also add targets to this list by swiping a target's card left in the Targets or "
                        "War sections.",
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
      ],
    );
  }

  Column _apiFailure(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                const Text("API failure check"),
                const SizedBox(width: 10),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: chainP.orange2Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/connection.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: chainP.apiFailureAlert,
              onChanged: (enabled) {
                chainP.apiFailureAlert = enabled;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 0, right: 20, bottom: 10),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  "In case that Torn API fails and the watcher is active, an alert will trigger",
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
        if (chainP.apiFailureAlert)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Trigger panic attack"),
                  Switch(
                    value: chainP.apiFailurePanic,
                    onChanged: (value) {
                      chainP.apiFailurePanic = value;
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0, right: 20, bottom: 10),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        "If panic mode is active, dictates if an API failure should trigger an inmediate attack",
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
      ],
    );
  }

  Widget _greenLevel2(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "Green pulse",
              style: TextStyle(
                color: chainP.green2Enabled ? _themeProvider!.mainText : Colors.grey,
              ),
            ),
            Switch(
              value: chainP.green2Enabled,
              onChanged: (value) {
                try {
                  chainP.green2Enabled
                      ? chainP.deactivateDefcon(WatchDefcon.green2)
                      : chainP.activateDefcon(WatchDefcon.green2);
                } catch (e) {
                  _errorReset(chainP);
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        if (chainP.green2Enabled)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.alarm,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _printDuration(Duration(seconds: chainP.green2Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(chainP.green2Min, chainP.green2Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.green[500],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        chainP.setDefconRange(WatchDefcon.green2, range);
                      } catch (e) {
                        _errorReset(chainP);
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: chainP.green2Max.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _orangeLevel1(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: [
                    Text(
                      "Orange pulse + ",
                      style: TextStyle(
                        color: chainP.orange1Enabled ? _themeProvider!.mainText : Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: chainP.orange1Enabled && chainP.notificationsEnabled
                            ? _themeProvider!.mainText
                            : Colors.grey,
                      ),
                      onTap: () {
                        chainP.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                      },
                    ),
                    Text(
                      " + ",
                      style: TextStyle(
                        color: chainP.orange1Enabled ? _themeProvider!.mainText : Colors.grey,
                      ),
                    ),
                    Text(
                      " caution ",
                      style: TextStyle(
                        color: chainP.orange1Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      child: Icon(
                        Icons.volume_up,
                        size: 20,
                        color: chainP.orange1Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                      ),
                      onTap: () {
                        Get.find<AudioController>().play(file: '../sounds/alerts/alert1.wav');
                      },
                    ),
                  ],
                ),
              ],
            ),
            Switch(
              value: chainP.orange1Enabled,
              onChanged: (value) {
                try {
                  chainP.orange1Enabled
                      ? chainP.deactivateDefcon(WatchDefcon.orange1)
                      : chainP.activateDefcon(WatchDefcon.orange1);
                } catch (e) {
                  _errorReset(chainP);
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        if (chainP.orange1Enabled)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.alarm,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _printDuration(Duration(seconds: chainP.orange1Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(chainP.orange1Min, chainP.orange1Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.orange[400],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        chainP.setDefconRange(WatchDefcon.orange1, range);
                      } catch (e) {
                        _errorReset(chainP);
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: chainP.orange1Max.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _orangeLevel2(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                Text(
                  "Orange pulse + ",
                  style: TextStyle(
                    color: chainP.orange2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color:
                        chainP.orange2Enabled && chainP.notificationsEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                  onTap: () {
                    chainP.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                  },
                ),
                Text(
                  " + ",
                  style: TextStyle(
                    color: chainP.orange2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                Text(
                  " warning ",
                  style: TextStyle(
                    color: chainP.orange2Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: chainP.orange2Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/alert2.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: chainP.orange2Enabled,
              onChanged: (value) {
                try {
                  chainP.orange2Enabled
                      ? chainP.deactivateDefcon(WatchDefcon.orange2)
                      : chainP.activateDefcon(WatchDefcon.orange2);
                } catch (e) {
                  _errorReset(chainP);
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        if (chainP.orange2Enabled)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.alarm,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _printDuration(Duration(seconds: chainP.orange2Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(chainP.orange2Min, chainP.orange2Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.orange[800],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        chainP.setDefconRange(WatchDefcon.orange2, range);
                      } catch (e) {
                        _errorReset(chainP);
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: chainP.orange2Max.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _redLevel1(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                Text(
                  "Red pulse + ",
                  style: TextStyle(
                    color: chainP.red1Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: chainP.red1Enabled && chainP.notificationsEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                  onTap: () {
                    chainP.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                  },
                ),
                Text(
                  " + ",
                  style: TextStyle(
                    color: chainP.red1Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                Text(
                  " caution ",
                  style: TextStyle(
                    color: chainP.red1Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: chainP.red1Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/warning1.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: chainP.red1Enabled,
              onChanged: (value) {
                try {
                  chainP.red1Enabled
                      ? chainP.deactivateDefcon(WatchDefcon.red1)
                      : chainP.activateDefcon(WatchDefcon.red1);
                } catch (e) {
                  _errorReset(chainP);
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        if (chainP.red1Enabled)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.alarm,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _printDuration(Duration(seconds: chainP.red1Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(chainP.red1Min, chainP.red1Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.red[400],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        chainP.setDefconRange(WatchDefcon.red1, range);
                      } catch (e) {
                        _errorReset(chainP);
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: chainP.red1Max.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _redLevel2(ChainStatusController chainP) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                Text(
                  "Red pulse + ",
                  style: TextStyle(
                    color: chainP.red2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: chainP.red2Enabled && chainP.notificationsEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                  onTap: () {
                    chainP.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                  },
                ),
                Text(
                  " + ",
                  style: TextStyle(
                    color: chainP.red2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                Text(
                  " warning ",
                  style: TextStyle(
                    color: chainP.red2Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: chainP.red2Enabled && chainP.soundEnabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/warning2.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: chainP.red2Enabled,
              onChanged: (value) {
                try {
                  chainP.red2Enabled
                      ? chainP.deactivateDefcon(WatchDefcon.red2)
                      : chainP.activateDefcon(WatchDefcon.red2);
                } catch (e) {
                  _errorReset(chainP);
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        if (chainP.red2Enabled)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.alarm,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _printDuration(Duration(seconds: chainP.red2Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(chainP.red2Min, chainP.red2Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.red[800],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        chainP.setDefconRange(WatchDefcon.red2, range);
                      } catch (e) {
                        _errorReset(chainP);
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: chainP.red2Max.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _goBack() async {
    widget.callBackOptions!();
    routeWithDrawer = true;
    routeName = "chaining_targets";
    Navigator.of(context).pop();
  }

  void _errorReset(ChainStatusController chainP) {
    chainP.resetAllDefcon();
    BotToast.showText(
      text: "Oops! Error encountered, all warning levels have been reset!",
      textStyle: const TextStyle(
        fontSize: 13,
        color: Colors.white,
      ),
      contentColor: Colors.red[800]!,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Future<void> _openRestoreDialog(ChainStatusController chainP) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider!.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Reset",
                            style: TextStyle(fontSize: 13, color: _themeProvider!.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            "This will reactivate and reset all warning levels to their default values.",
                            style: TextStyle(fontSize: 12, color: _themeProvider!.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Reset"),
                              onPressed: () {
                                chainP.resetAllDefcon();
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider!.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider!.secondBackground,
                      radius: 22,
                      child: const SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.restore),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPanicModeInfoDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider!.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Panic Mode",
                            style: TextStyle(fontSize: 13, color: _themeProvider!.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            "By enabling Panic Mode, a new 'P' icon will appear in the chain widget, which in turn will "
                            "allow you to toggle the Panic Mode on/off when you desire.\n\n"
                            "When Panic Mode is active, regardless of your alerts' configuration below, only the panic "
                            "alert will sound. If you have targets configured, the browser will automatically open to "
                            "the first available (non blue/red) one. Think about using easy/quick targets.\n\n"
                            "This can be specially useful when chain watching while asleep, working, etc.\n\n"
                            "Remember you need to leave Torn PDA open, "
                            "with the screen active, for the Panic Mode to work as well.\n\n"
                            "NOTE: the browser used by Panic Mode does not contain any of the features (widgets, etc.) "
                            "of the standard browser, as it is designed to load as quickly as possible.",
                            style: TextStyle(fontSize: 12, color: _themeProvider!.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Panic!"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider!.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider!.secondBackground,
                      radius: 22,
                      child: const SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(MdiIcons.alphaPCircleOutline),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AddChainTargetDialog extends StatefulWidget {
  const AddChainTargetDialog({
    super.key,
    required this.themeProvider,
  });

  final ThemeProvider? themeProvider;

  @override
  AddChainTargetDialogState createState() => AddChainTargetDialogState();
}

class AddChainTargetDialogState extends State<AddChainTargetDialog> {
  final _addIdController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: GetBuilder<ChainStatusController>(builder: (chainP) {
        return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            top: 45,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            color: widget.themeProvider!.secondBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Form(
            key: _addFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // To make the card compact
              children: <Widget>[
                const Text(
                  "Panic Mode Targets",
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: _addIdController,
                        maxLength: 10,
                        minLines: 1,
                        maxLines: 2,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          counterText: "",
                          border: OutlineInputBorder(),
                          labelText: 'Insert user ID',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Cannot be empty!";
                          }
                          if (chainP.panicTargets.length >= 10) {
                            return "Maximum 10 targets!";
                          }

                          final n = num.tryParse(value);
                          if (chainP.panicTargets.where((t) => t.id.toString() == value).isNotEmpty) {
                            return "Already in the list!";
                          }
                          if (n == null) {
                            return '$value is not a valid ID!';
                          }
                          _addIdController.text = value.trim();
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Expanded(child: panicCards(chainP)),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      child: const Text("Add"),
                      onPressed: () async {
                        if (_addFormKey.currentState!.validate()) {
                          final FocusScopeNode currentFocus = FocusScope.of(context);
                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }
                          // Copy controller's text ot local variable
                          // early and delete the global, so that text
                          // does not appear again in case of failure
                          String inputId = _addIdController.text;
                          _addIdController.text = '';

                          final dynamic target = await ApiCallsV1.getTarget(playerId: inputId);
                          String message = "";
                          Color? messageColor = Colors.green[700];
                          if (target is TargetModel) {
                            inputId = target.faction!.factionId.toString();
                            chainP.addPanicTarget(
                              PanicTargetModel()
                                ..name = target.name
                                ..level = target.level
                                ..id = target.playerId
                                ..factionName = target.faction!.factionName,
                            );
                            message = "Added ${target.name}!";
                          } else {
                            message = "Can't locate the given target!";
                            messageColor = Colors.orange[700];
                          }

                          BotToast.showText(
                            text: message,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: messageColor!,
                            duration: const Duration(seconds: 3),
                            contentPadding: const EdgeInsets.all(10),
                          );
                          return;
                        }
                      },
                    ),
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _addIdController.text = '';
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget panicCards(ChainStatusController chainP) {
    List<Widget> panicCards = <Widget>[];
    for (final PanicTargetModel target in chainP.panicTargets) {
      panicCards.add(
        Row(
          key: UniqueKey(),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(
              width: 30,
              child: Icon(
                Icons.menu,
              ),
            ),
            Flexible(
              child: Card(
                color: widget.themeProvider!.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        "${target.name} [${target.id}]",
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "${target.factionName != "None" ? '(${target.factionName}) - ' : ''}L${target.level}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 30,
              child: GestureDetector(
                onTap: () {
                  chainP.removePanicTarget(target);
                },
                child: const Icon(Icons.delete_forever_outlined),
              ),
            ),
          ],
        ),
      );
    }
    return ReorderableListView(
      onReorder: (int oldIndex, int newIndex) {
        chainP.reorderPanicTarget(oldIndex, newIndex);
      },
      children: panicCards,
    );
  }
}
