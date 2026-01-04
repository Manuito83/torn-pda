/*
  Main idea from Lorenzo Pichilli's Flutter Browser example
*/

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/dev_tools/dev_tools_network.dart';
import 'package:torn_pda/widgets/webviews/dev_tools/dev_tools_scripts.dart';
import 'package:torn_pda/widgets/webviews/dev_tools/dev_tools_storage.dart';
import 'package:torn_pda/widgets/webviews/dev_tools/dev_tools_terminal.dart'; // Asegúrate de que esta ruta sea correcta

class DevToolsMainPage extends StatefulWidget {
  final InAppWebViewController? webViewController;
  final Key? webviewKey;
  final int initialIndex;

  const DevToolsMainPage({
    super.key,
    required this.webViewController,
    required this.webviewKey,
    this.initialIndex = 0,
  });

  @override
  State<DevToolsMainPage> createState() => _DevToolsMainPageState();
}

class _DevToolsMainPageState extends State<DevToolsMainPage> with SingleTickerProviderStateMixin {
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
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
          appBar: _settingsProvider.appBarTop ? buildAppBar(context) : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height + kTextTabBarHeight,
                  child: buildAppBar(context),
                )
              : null,
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              DevToolsTerminalTab(
                webViewController: widget.webViewController,
                webviewKey: widget.webviewKey,
              ),
              DevToolsNetworkTab(webViewController: widget.webViewController),
              DevToolsStorageTab(webViewController: widget.webViewController),
              DevToolsScriptsTab(webViewController: widget.webViewController),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Dev Tools", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        indicatorColor: Colors.lightGreenAccent,
        onTap: (value) {
          FocusScope.of(context).unfocus();
        },
        tabs: const [
          Tab(
            icon: Icon(Icons.code),
            text: "Terminal",
          ),
          Tab(
            icon: Icon(Icons.network_check),
            text: "Network",
          ),
          Tab(
            icon: Icon(Icons.storage),
            text: "Storage",
          ),
          Tab(
            icon: Icon(Icons.javascript),
            text: "Scripts",
          ),
        ],
      ),
      actions: [
        PopupMenuButton<int>(
          icon: const Icon(Icons.timer_outlined),
          tooltip: "Interact with WebView",
          onSelected: (int seconds) async {
            final currentIndex = _tabController.index;

            await Future.delayed(const Duration(milliseconds: 300));

            final webViewProvider = context.read<WebViewProvider>();
            webViewProvider.startDevToolsCooldown(seconds);

            if (mounted) {
              Navigator.of(context).pop([seconds, currentIndex]);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
            const PopupMenuItem<int>(
              value: 5,
              child: Text('Show browser for 5 seconds'),
            ),
            const PopupMenuItem<int>(
              value: 15,
              child: Text('Show browser for 15 seconds'),
            ),
            const PopupMenuItem<int>(
              value: 30,
              child: Text('Show browser for 30 seconds'),
            ),
            const PopupMenuItem<int>(
              value: 60,
              child: Text('Show browser for 60 seconds'),
            ),
          ],
        ),
      ],
    );
  }
}
