// Package imports:
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/alerts/sendbird_dnd_dialog.dart';

class AlertsSettingsWindows extends StatefulWidget {
  @override
  AlertsSettingsWindowsState createState() => AlertsSettingsWindowsState();
}

class AlertsSettingsWindowsState extends State<AlertsSettingsWindows> {
  late SettingsProvider _settingsProvider;
  ThemeProvider? _themeProvider;
  late WebViewProvider _webViewProvider;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    routeWithDrawer = true;
    routeName = "alerts";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider!.canvas,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider!.canvas,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Alerts are automatic notifications that you only "
                  "need to activate once.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
              GetBuilder(
                init: SendbirdController(),
                builder: (sendbird) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: sendbird.sendBirdNotificationsEnabled,
                          title: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Text(
                                  "Torn chat messages",
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: const Text(
                            "Enable notifications for TORN chat messages",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (enabled) async {
                            sendbird.sendBirdNotificationsToggle(enabled: enabled!);
                          },
                        ),
                      ),
                      if (sendbird.sendBirdNotificationsEnabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.keyboard_arrow_right_outlined),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      "Do not disturb",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                child: Icon(Icons.more_time_outlined),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SendbirdDoNotDisturbDialog();
                                    },
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('Alerts', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
          if (scaffoldState != null) {
            if (_webViewProvider.webViewSplitActive &&
                _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
              scaffoldState.openEndDrawer();
            } else {
              scaffoldState.openDrawer();
            }
          }
        },
      ),
    );
  }
}
