// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class ChainWidgetOptions extends StatefulWidget {
  @override
  _ChainWidgetOptionsState createState() => _ChainWidgetOptionsState();
}

class _ChainWidgetOptionsState extends State<ChainWidgetOptions> {
  ChainStatusProvider _chainStatusProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light ? Colors.blueGrey : Colors.grey[900],
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
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 15),
                      _panicMode(),
                      Divider(),
                      _greenLevel2(),
                      Divider(),
                      _orangeLevel1(),
                      Divider(),
                      _orangeLevel2(),
                      Divider(),
                      _redLevel1(),
                      Divider(),
                      _redLevel2(),
                      SizedBox(height: 50),
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
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text("Chain Watcher"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.restore),
          onPressed: () {
            // TODO DIALOG
            //_chainStatusProvider.resetAllDefcon();
          },
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
                Text("Enable Panic Mode"),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    // TODO
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: [
                  Image.asset(
                    'images/awards/categories/crosshair.png',
                    height: 15,
                    color: _themeProvider.mainText,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Targets",
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.keyboard_arrow_right_outlined),
                onPressed: () {
                  // TODO
                },
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
            Text("Green pulse"),
            Switch(
              value: _chainStatusProvider.green2Enabled,
              onChanged: (value) {
                _chainStatusProvider.green2Enabled
                    ? _chainStatusProvider.deactivateDefcon(WatchDefcon.green2)
                    : _chainStatusProvider.activateDefcon(WatchDefcon.green2);
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
                Icon(
                  Icons.alarm,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.green2Min.toInt()))}",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.green2Min, _chainStatusProvider.green2Max),
                    max: 270,
                    divisions: 27,
                    onChanged: (RangeValues range) {
                      range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                      _chainStatusProvider.setDefconRange(WatchDefcon.green2, range);
                    },
                  ),
                ),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.green2Max.toInt()))}",
                  style: TextStyle(
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
            Text("Orange pulse"),
            Switch(
              value: _chainStatusProvider.orange1Enabled,
              onChanged: (value) {
                // TODO: add try/catch everywhere
                _chainStatusProvider.orange1Enabled
                    ? _chainStatusProvider.deactivateDefcon(WatchDefcon.orange1)
                    : _chainStatusProvider.activateDefcon(WatchDefcon.orange1);
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
                Icon(
                  Icons.alarm,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.orange1Min.toInt()))}",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.orange1Min, _chainStatusProvider.orange1Max),
                    max: 270,
                    divisions: 27,
                    onChanged: (RangeValues range) {
                      range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                      _chainStatusProvider.setDefconRange(WatchDefcon.orange1, range);
                    },
                  ),
                ),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.orange1Max.toInt()))}",
                  style: TextStyle(
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
            Text("Orange pulse + sound"),
            Switch(
              value: _chainStatusProvider.orange2Enabled,
              onChanged: (value) {
                _chainStatusProvider.orange2Enabled
                    ? _chainStatusProvider.deactivateDefcon(WatchDefcon.orange2)
                    : _chainStatusProvider.activateDefcon(WatchDefcon.orange2);
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
                Icon(
                  Icons.alarm,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.orange2Min.toInt()))}",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.orange2Min, _chainStatusProvider.orange2Max),
                    max: 270,
                    divisions: 27,
                    onChanged: (RangeValues range) {
                      range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                      _chainStatusProvider.setDefconRange(WatchDefcon.orange2, range);
                    },
                  ),
                ),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.orange2Max.toInt()))}",
                  style: TextStyle(
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
            Text("Red pulse"),
            Switch(
              value: _chainStatusProvider.red1Enabled,
              onChanged: (value) {
                _chainStatusProvider.red1Enabled
                    ? _chainStatusProvider.deactivateDefcon(WatchDefcon.red1)
                    : _chainStatusProvider.activateDefcon(WatchDefcon.red1);
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
                Icon(
                  Icons.alarm,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.red1Min.toInt()))}",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.red1Min, _chainStatusProvider.red1Max),
                    max: 270,
                    divisions: 27,
                    onChanged: (RangeValues range) {
                      range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                      _chainStatusProvider.setDefconRange(WatchDefcon.red1, range);
                    },
                  ),
                ),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.red1Max.toInt()))}",
                  style: TextStyle(
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
            Text("Red pulse + sound"),
            Switch(
              value: _chainStatusProvider.red2Enabled,
              onChanged: (value) {
                _chainStatusProvider.red2Enabled
                    ? _chainStatusProvider.deactivateDefcon(WatchDefcon.red2)
                    : _chainStatusProvider.activateDefcon(WatchDefcon.red2);
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
                Icon(
                  Icons.alarm,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.red2Min.toInt()))}",
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_chainStatusProvider.red2Min, _chainStatusProvider.red2Max),
                    max: 270,
                    divisions: 27,
                    onChanged: (RangeValues range) {
                      range = RangeValues(range.start.roundToDouble(), range.end.roundToDouble());
                      _chainStatusProvider.setDefconRange(WatchDefcon.red2, range);
                    },
                  ),
                ),
                Text(
                  "${_printDuration(Duration(seconds: _chainStatusProvider.red2Max.toInt()))}",
                  style: TextStyle(
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
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
