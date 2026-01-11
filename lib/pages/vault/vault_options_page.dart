// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class VaultOptionsPage extends StatefulWidget {
  final bool vaultDetected;
  final Function callback;

  const VaultOptionsPage({required this.vaultDetected, required this.callback});

  @override
  VaultOptionsPageState createState() => VaultOptionsPageState();
}

class VaultOptionsPageState extends State<VaultOptionsPage> {
  bool _vaultEnabled = true;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;
  Future? _preferencesLoaded;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        widget.callback();
      },
      child: Container(
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
                  color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                    child: FutureBuilder(
                      future: _preferencesLoaded,
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (!widget.vaultDetected)
                                  const Column(
                                    children: [
                                      SizedBox(height: 20),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 15),
                                        child: Text(
                                          "NOTE: Torn PDA did not detect a vault in your property, either "
                                          "because there is none, you don't have access to it or there "
                                          "no transactions listed.",
                                          style: TextStyle(color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Use vault share"),
                                      Switch(
                                        value: _vaultEnabled,
                                        onChanged: (value) {
                                          Prefs().setVaultEnabled(value);
                                          setState(() {
                                            _vaultEnabled = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Vault options", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future _restorePreferences() async {
    final vaultEnabled = await Prefs().getVaultEnabled();
    setState(() {
      _vaultEnabled = vaultEnabled;
    });
  }
}
