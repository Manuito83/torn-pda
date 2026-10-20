// Package imports:
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

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
          child: const Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Alerts are automatic notifications that you only "
                  "need to activate once.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('Alerts', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
          if (scaffoldState != null) {
            if (_webViewProvider.splitAppSide == SplitSide.right) {
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
