// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AlternativeKeysPage extends StatefulWidget {
  const AlternativeKeysPage({Key key}) : super(key: key);

  @override
  _AlternativeKeysPageState createState() => _AlternativeKeysPageState();
}

class _AlternativeKeysPageState extends State<AlternativeKeysPage> {
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  TextEditingController _yataKeyController = TextEditingController();
  TextEditingController _tornStatsKeyController = TextEditingController();

  UserController _u = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _yataKeyController.text = _u.alternativeYataKey;
    _tornStatsKeyController.text = _u.alternativeTornStatsKey;
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : _themeProvider.canvas
            : _themeProvider.canvas,
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            backgroundColor: _themeProvider.canvas,
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Container(
              color: _themeProvider.canvas,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 15),
                      _yataKey(),
                      SizedBox(height: 15),
                      Divider(),
                      SizedBox(height: 15),
                      _tornStatsKey(),
                      SizedBox(height: 15),
                      SizedBox(height: 40),
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

  Widget _yataKey() {
    return GetBuilder<UserController>(
      builder: (w) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'YATA',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Alternative key enabled"),
                  Switch(
                    value: w.alternativeYataKeyEnabled,
                    onChanged: (enabled) {
                      w.alternativeYataKeyEnabled = enabled;
                      Prefs().setAlternativeYataKeyEnabled(enabled);
                      if (!enabled) {
                        w.alternativeYataKey = w.apiKey;
                      }
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            if (w.alternativeYataKeyEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Key"),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _yataKeyController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 12),
                        maxLength: 16,
                        onChanged: (key) {
                          if (key.isEmpty) {
                            key = w.apiKey;
                          }
                          w.alternativeYataKey = key;
                          Prefs().setAlternativeYataKey(key);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tornStatsKey() {
    return GetBuilder<UserController>(
      builder: (w) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TORN STATS',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Alternative key enabled"),
                  Switch(
                    value: w.alternativeTornStatsKeyEnabled,
                    onChanged: (enabled) {
                      w.alternativeTornStatsKeyEnabled = enabled;
                      Prefs().setAlternativeTornStatsKeyEnabled(enabled);
                      if (!enabled) {
                        w.alternativeTornStatsKey = w.apiKey;
                      }
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            if (w.alternativeTornStatsKeyEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Key"),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _tornStatsKeyController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 12),
                        maxLength: 16,
                        onChanged: (key) {
                          if (key.isEmpty) {
                            key = w.apiKey;
                          }
                          w.alternativeTornStatsKey = key;
                          Prefs().setAlternativeTornStatsKey(key);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: 50,
      title: Text('Alternative API keys'),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
    );
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
