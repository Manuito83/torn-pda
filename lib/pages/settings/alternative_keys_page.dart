// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AlternativeKeysPage extends StatefulWidget {
  const AlternativeKeysPage({super.key});

  @override
  AlternativeKeysPageState createState() => AlternativeKeysPageState();
}

class AlternativeKeysPageState extends State<AlternativeKeysPage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;

  final TextEditingController _yataKeyController = TextEditingController();
  final TextEditingController _tornStatsKeyController = TextEditingController();
  final TextEditingController _tscKeyController = TextEditingController();

  final UserController _u = Get.find<UserController>();

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _yataKeyController.text = _u.alternativeYataKey;
    _tornStatsKeyController.text = _u.alternativeTornStatsKey;
    _tscKeyController.text = _u.alternativeTSCKey;

    routeWithDrawer = false;
    routeName = "alternative_keys";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "alternative_keys") _goBack();
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
          body: Container(
            color: _themeProvider.canvas,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 15),
                    _yataKey(),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 15),
                    _tornStatsKey(),
                    const SizedBox(height: 15),
                    const SizedBox(height: 40),
                    /*
                    _tscKey(),
                    const SizedBox(height: 15),
                    const SizedBox(height: 40),
                    */
                  ],
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
            const Row(
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
                  const Text("Alternative key enabled"),
                  Switch(
                    value: w.alternativeYataKeyEnabled,
                    onChanged: (enabled) {
                      w.alternativeYataKeyEnabled = enabled;
                      Prefs().setAlternativeYataKeyEnabled(enabled);
                      if (!enabled) {
                        w.alternativeYataKey = w.apiKey!;
                      }
                      w.update(); // Notify GetBuilder observers
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
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
                    const Text("Key"),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _yataKeyController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        maxLength: 16,
                        onChanged: (key) {
                          if (key.isEmpty) {
                            key = w.apiKey!;
                          }
                          w.alternativeYataKey = key;
                          Prefs().setAlternativeYataKey(key);
                          w.update(); // Notify GetBuilder observers
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
            const Row(
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
                  const Text("Alternative key enabled"),
                  Switch(
                    value: w.alternativeTornStatsKeyEnabled,
                    onChanged: (enabled) {
                      w.alternativeTornStatsKeyEnabled = enabled;
                      Prefs().setAlternativeTornStatsKeyEnabled(enabled);
                      if (!enabled) {
                        w.alternativeTornStatsKey = w.apiKey!;
                      }
                      w.update(); // Notify GetBuilder observers
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
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
                    const Text("Key"),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _tornStatsKeyController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        maxLength: 19,
                        onChanged: (key) {
                          if (key.isEmpty) {
                            key = w.apiKey!;
                          }
                          w.alternativeTornStatsKey = key;
                          Prefs().setAlternativeTornStatsKey(key);
                          w.update(); // Notify GetBuilder observers
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

  // ignore: unused_element
  Widget _tscKey() {
    return GetBuilder<UserController>(
      builder: (w) {
        return Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TORN SPIES CENTRAL',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Alternative key enabled"),
                  Switch(
                    value: w.alternativeTSCKeyEnabled,
                    onChanged: (enabled) {
                      w.alternativeTSCKeyEnabled = enabled;
                      Prefs().setAlternativeTSCKeyEnabled(enabled);
                      if (!enabled) {
                        w.alternativeTSCKey = w.apiKey!;
                      }
                      w.update(); // Notify GetBuilder observers
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
            if (w.alternativeTSCKeyEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text("Key"),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _tscKeyController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        maxLength: 19,
                        onChanged: (key) {
                          if (key.isEmpty) {
                            key = w.apiKey!;
                          }
                          w.alternativeTSCKey = key;
                          Prefs().setAlternativeTSCKey(key);
                          w.update(); // Notify GetBuilder observers
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
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: 50,
      title: const Text('Alternative API keys', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  void _goBack() {
    routeWithDrawer = true;
    routeName = "settings";
    Navigator.of(context).pop();
  }
}
