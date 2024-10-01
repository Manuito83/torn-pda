// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/audio_controller.dart';
// Project imports:
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class ChainWidgetOptions extends StatefulWidget {
  final Function? callBackOptions;

  const ChainWidgetOptions({this.callBackOptions});

  @override
  ChainWidgetOptionsState createState() => ChainWidgetOptionsState();
}

class ChainWidgetOptionsState extends State<ChainWidgetOptions> {
  late ChainStatusProvider _chainStatusProvider;
  ThemeProvider? _themeProvider;
  late SettingsProvider _settingsProvider;

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider!.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : _themeProvider!.canvas
            : _themeProvider!.canvas,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: _themeProvider!.canvas,
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
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
                      _generalSettings(),
                      const Divider(),
                      const SizedBox(height: 5),
                      const Text("PANIC MODE", style: TextStyle(fontSize: 11)),
                      _panicMode(),
                      const Divider(),
                      const SizedBox(height: 5),
                      const Text("API FAILURE", style: TextStyle(fontSize: 11)),
                      _apiFailure(),
                      const Divider(),
                      const SizedBox(height: 5),
                      const Text("ALERT LEVELS", style: TextStyle(fontSize: 11)),
                      _greenLevel2(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 100),
                        child: Divider(),
                      ),
                      _orangeLevel1(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 100),
                        child: Divider(),
                      ),
                      _orangeLevel2(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 100),
                        child: Divider(),
                      ),
                      _redLevel1(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 100),
                        child: Divider(),
                      ),
                      _redLevel2(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Chain Watcher", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.restore),
          onPressed: () {
            _openRestoreDialog();
          },
        ),
      ],
    );
  }

  Column _generalSettings() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text("Sound alerts"),
            Switch(
              value: _chainStatusProvider.soundEnabled,
              onChanged: (value) {
                _chainStatusProvider.changeSoundEnabled = value;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text("Vibration"),
            Switch(
              value: _chainStatusProvider.vibrationEnabled,
              onChanged: (value) {
                _chainStatusProvider.changeVibrationEnabled = value;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text("Notification"),
            Switch(
              value: _chainStatusProvider.notificationsEnabled,
              onChanged: (value) {
                _chainStatusProvider.changeNotificationsEnabled = value;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Column _panicMode() {
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
              value: _chainStatusProvider.panicModeEnabled,
              onChanged: (value) {
                _chainStatusProvider.panicModeEnabled
                    ? _chainStatusProvider.disablePanicMode()
                    : _chainStatusProvider.enablePanicMode();
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        if (_chainStatusProvider.panicModeEnabled)
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
                      value: _chainStatusProvider.panicValue,
                      max: 270,
                      divisions: 27,
                      activeColor: Colors.yellow,
                      onChanged: (value) {
                        _chainStatusProvider.setPanicValue(value);
                      },
                    ),
                  ),
                  Text(
                    _printDuration(Duration(seconds: _chainStatusProvider.panicValue.toInt())),
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

  Column _apiFailure() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                const Text("API failure check"),
                SizedBox(width: 10),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: _chainStatusProvider.orange2Enabled && _chainStatusProvider.soundEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/connection.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: _chainStatusProvider.apiFailureAlert,
              onChanged: (enabled) {
                _chainStatusProvider.apiFailureAlert = enabled;
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
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
        if (_chainStatusProvider.apiFailureAlert)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Trigger panic attack"),
                  Switch(
                    value: _chainStatusProvider.apiFailurePanic,
                    onChanged: (value) {
                      _chainStatusProvider.apiFailurePanic = value;
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
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

  Widget _greenLevel2() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "Green pulse",
              style: TextStyle(
                color: _chainStatusProvider.green2Enabled ? _themeProvider!.mainText : Colors.grey,
              ),
            ),
            Switch(
              value: _chainStatusProvider.green2Enabled,
              onChanged: (value) {
                try {
                  _chainStatusProvider.green2Enabled
                      ? _chainStatusProvider.deactivateDefcon(WatchDefcon.green2)
                      : _chainStatusProvider.activateDefcon(WatchDefcon.green2);
                } catch (e) {
                  _errorReset();
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        if (_chainStatusProvider.green2Enabled)
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
                  _printDuration(Duration(seconds: _chainStatusProvider.green2Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.green2Min, _chainStatusProvider.green2Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.green[500],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        _chainStatusProvider.setDefconRange(WatchDefcon.green2, range);
                      } catch (e) {
                        _errorReset();
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: _chainStatusProvider.green2Max.toInt())),
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

  Widget _orangeLevel1() {
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
                        color: _chainStatusProvider.orange1Enabled ? _themeProvider!.mainText : Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: _chainStatusProvider.orange1Enabled && _chainStatusProvider.notificationsEnabled
                            ? _themeProvider!.mainText
                            : Colors.grey,
                      ),
                      onTap: () {
                        _chainStatusProvider.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                      },
                    ),
                    Text(
                      " + ",
                      style: TextStyle(
                        color: _chainStatusProvider.orange1Enabled ? _themeProvider!.mainText : Colors.grey,
                      ),
                    ),
                    Text(
                      " caution ",
                      style: TextStyle(
                        color: _chainStatusProvider.orange1Enabled && _chainStatusProvider.soundEnabled
                            ? _themeProvider!.mainText
                            : Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      child: Icon(
                        Icons.volume_up,
                        size: 20,
                        color: _chainStatusProvider.orange1Enabled && _chainStatusProvider.soundEnabled
                            ? _themeProvider!.mainText
                            : Colors.grey,
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
              value: _chainStatusProvider.orange1Enabled,
              onChanged: (value) {
                try {
                  _chainStatusProvider.orange1Enabled
                      ? _chainStatusProvider.deactivateDefcon(WatchDefcon.orange1)
                      : _chainStatusProvider.activateDefcon(WatchDefcon.orange1);
                } catch (e) {
                  _errorReset();
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        if (_chainStatusProvider.orange1Enabled)
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
                  _printDuration(Duration(seconds: _chainStatusProvider.orange1Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.orange1Min, _chainStatusProvider.orange1Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.orange[400],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        _chainStatusProvider.setDefconRange(WatchDefcon.orange1, range);
                      } catch (e) {
                        _errorReset();
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: _chainStatusProvider.orange1Max.toInt())),
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

  Widget _orangeLevel2() {
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
                    color: _chainStatusProvider.orange2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: _chainStatusProvider.orange2Enabled && _chainStatusProvider.notificationsEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                  onTap: () {
                    _chainStatusProvider.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                  },
                ),
                Text(
                  " + ",
                  style: TextStyle(
                    color: _chainStatusProvider.orange2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                Text(
                  " warning ",
                  style: TextStyle(
                    color: _chainStatusProvider.orange2Enabled && _chainStatusProvider.soundEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: _chainStatusProvider.orange2Enabled && _chainStatusProvider.soundEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/alert2.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: _chainStatusProvider.orange2Enabled,
              onChanged: (value) {
                try {
                  _chainStatusProvider.orange2Enabled
                      ? _chainStatusProvider.deactivateDefcon(WatchDefcon.orange2)
                      : _chainStatusProvider.activateDefcon(WatchDefcon.orange2);
                } catch (e) {
                  _errorReset();
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        if (_chainStatusProvider.orange2Enabled)
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
                  _printDuration(Duration(seconds: _chainStatusProvider.orange2Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.orange2Min, _chainStatusProvider.orange2Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.orange[800],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        _chainStatusProvider.setDefconRange(WatchDefcon.orange2, range);
                      } catch (e) {
                        _errorReset();
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: _chainStatusProvider.orange2Max.toInt())),
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

  Widget _redLevel1() {
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
                    color: _chainStatusProvider.red1Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: _chainStatusProvider.red1Enabled && _chainStatusProvider.notificationsEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                  onTap: () {
                    _chainStatusProvider.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                  },
                ),
                Text(
                  " + ",
                  style: TextStyle(
                    color: _chainStatusProvider.red1Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                Text(
                  " caution ",
                  style: TextStyle(
                    color: _chainStatusProvider.red1Enabled && _chainStatusProvider.soundEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: _chainStatusProvider.red1Enabled && _chainStatusProvider.soundEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/warning1.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: _chainStatusProvider.red1Enabled,
              onChanged: (value) {
                try {
                  _chainStatusProvider.red1Enabled
                      ? _chainStatusProvider.deactivateDefcon(WatchDefcon.red1)
                      : _chainStatusProvider.activateDefcon(WatchDefcon.red1);
                } catch (e) {
                  _errorReset();
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        if (_chainStatusProvider.red1Enabled)
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
                  _printDuration(Duration(seconds: _chainStatusProvider.red1Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.red1Min, _chainStatusProvider.red1Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.red[400],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        _chainStatusProvider.setDefconRange(WatchDefcon.red1, range);
                      } catch (e) {
                        _errorReset();
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: _chainStatusProvider.red1Max.toInt())),
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

  Widget _redLevel2() {
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
                    color: _chainStatusProvider.red2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: _chainStatusProvider.red2Enabled && _chainStatusProvider.notificationsEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                  onTap: () {
                    _chainStatusProvider.showNotification(555, "", "CHAIN ALERT!", "XX:XX time remaining!");
                  },
                ),
                Text(
                  " + ",
                  style: TextStyle(
                    color: _chainStatusProvider.red2Enabled ? _themeProvider!.mainText : Colors.grey,
                  ),
                ),
                Text(
                  " warning ",
                  style: TextStyle(
                    color: _chainStatusProvider.red2Enabled && _chainStatusProvider.soundEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                ),
                GestureDetector(
                  child: Icon(
                    Icons.volume_up,
                    size: 20,
                    color: _chainStatusProvider.red2Enabled && _chainStatusProvider.soundEnabled
                        ? _themeProvider!.mainText
                        : Colors.grey,
                  ),
                  onTap: () {
                    Get.find<AudioController>().play(file: '../sounds/alerts/warning2.wav');
                  },
                ),
              ],
            ),
            Switch(
              value: _chainStatusProvider.red2Enabled,
              onChanged: (value) {
                try {
                  _chainStatusProvider.red2Enabled
                      ? _chainStatusProvider.deactivateDefcon(WatchDefcon.red2)
                      : _chainStatusProvider.activateDefcon(WatchDefcon.red2);
                } catch (e) {
                  _errorReset();
                }
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
          ],
        ),
        if (_chainStatusProvider.red2Enabled)
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
                  _printDuration(Duration(seconds: _chainStatusProvider.red2Min.toInt())),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.red2Min, _chainStatusProvider.red2Max),
                    max: 270,
                    divisions: 27,
                    activeColor: Colors.red[800],
                    onChanged: (RangeValues range) {
                      try {
                        range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                        _chainStatusProvider.setDefconRange(WatchDefcon.red2, range);
                      } catch (e) {
                        _errorReset();
                      }
                    },
                  ),
                ),
                Text(
                  _printDuration(Duration(seconds: _chainStatusProvider.red2Max.toInt())),
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

  Future<bool> _willPopCallback() async {
    widget.callBackOptions!();
    Navigator.of(context).pop();
    return true;
  }

  void _errorReset() {
    _chainStatusProvider.resetAllDefcon();
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

  Future<void> _openRestoreDialog() {
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
                                _chainStatusProvider.resetAllDefcon();
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
                      child: SizedBox(
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
  late ChainStatusProvider _chainProvider;
  final _addIdController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _chainProvider = Provider.of<ChainStatusProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: Container(
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
                        if (_chainProvider.panicTargets.length >= 10) {
                          return "Maximum 10 targets!";
                        }

                        final n = num.tryParse(value);
                        if (_chainProvider.panicTargets.where((t) => t.id.toString() == value).isNotEmpty) {
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
              Expanded(child: panicCards()),
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

                        final dynamic target = await Get.find<ApiCallerController>().getTarget(playerId: inputId);
                        String message = "";
                        Color? messageColor = Colors.green[700];
                        if (target is TargetModel) {
                          inputId = target.faction!.factionId.toString();
                          _chainProvider.addPanicTarget(
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
      ),
    );
  }

  Widget panicCards() {
    List<Widget> panicCards = <Widget>[];
    for (final PanicTargetModel target in _chainProvider.panicTargets) {
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
                  _chainProvider.removePanicTarget(target);
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
        _chainProvider.reorderPanicTarget(oldIndex, newIndex);
      },
      children: panicCards,
    );
  }
}
