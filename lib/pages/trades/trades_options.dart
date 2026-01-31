// Flutter imports:
// Package imports:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TradesOptions extends StatefulWidget {
  final int? playerId;
  final Function callback;

  const TradesOptions({
    required this.playerId,
    required this.callback,
  });

  @override
  TradesOptionsState createState() => TradesOptionsState();
}

class TradesOptionsState extends State<TradesOptions> {
  bool _tradeCalculatorEnabled = true;
  bool _awhEnabled = true;
  bool _tornExchangeEnabled = true;
  bool _tornExchangeProfitEnabled = true;

  Future? _preferencesLoaded;

  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();

    routeWithDrawer = false;
    routeName = "trades_options";
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _willPopCallback();
      },
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : _themeProvider.canvas
            : _themeProvider.canvas,
        child: SafeArea(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Use trade calculator"),
                                      Switch(
                                        value: _tradeCalculatorEnabled,
                                        onChanged: (value) {
                                          Prefs().setTradeCalculatorEnabled(value);
                                          setState(() {
                                            _tradeCalculatorEnabled = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeThumbColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'Consider deactivating the trade calculator if it impacts '
                                    'performance or you just simply would not prefer to use it',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Divider(),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Row(
                                        children: [
                                          Image(
                                            image: AssetImage('images/icons/awh_logo.png'),
                                            width: 35,
                                            color: Colors.orange,
                                            fit: BoxFit.fill,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Arson Warehouse"),
                                        ],
                                      ),
                                      awhSwitch(),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'If you are a professional trader and have your own price list in '
                                    'the Arson Warehouse, you can activate a quick access icon in the '
                                    'Trade Calculator icon here',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Divider(),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          const Image(
                                            image: AssetImage('images/icons/tornexchange_logo.png'),
                                            width: 25,
                                            fit: BoxFit.fill,
                                          ),
                                          const SizedBox(width: 10),
                                          if (_settingsProvider.tornExchangeEnabledStatusRemoteConfig)
                                            const Text("Torn Exchange")
                                          else
                                            const Column(
                                              children: [
                                                Text(
                                                  "Torn Exchange has been disabled temporarily",
                                                  style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      if (_settingsProvider.tornExchangeEnabledStatusRemoteConfig) tornExchangeSwitch(),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    15,
                                    _settingsProvider.tornExchangeEnabledStatusRemoteConfig ? 0 : 15,
                                    15,
                                    0,
                                  ),
                                  child: Text(
                                    'If you are a professional trader and have an account with Torn '
                                    'Exchange, you can activate the sync functionality here',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (_settingsProvider.tornExchangeEnabledStatusRemoteConfig && _tornExchangeEnabled)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Flexible(
                                              child: Text("Show detailed profits"),
                                            ),
                                            tornExchangeProfitSwitch(),
                                          ],
                                        ),
                                        Text(
                                          'By enabling this option, you will be shown additional white figures '
                                          'with total and individual item profits: one refers to market value profit '
                                          'and the other to Torn Exchange profit.\n\n'
                                          'In order to try to avoid Torn market price manipulations, Torn Exchange uses '
                                          'a custom formula to evaluate base price, and calculates profit as the '
                                          'difference between this base and your buying price.\n\n'
                                          'Torn PDA also shows the difference between Torn market price and your '
                                          'buying price as a more commonly understood measure of profit, '
                                          'albeit one that sometimes works poorly for infrequently traded items.',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
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
      title: const Text("Trade Calculator", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Switch awhSwitch() {
    return Switch(
      activeThumbColor: Colors.orange[900],
      activeTrackColor: Colors.orange,
      value: _awhEnabled,
      onChanged: _tradeCalculatorEnabled
          ? (activated) async {
              setState(() {
                _awhEnabled = activated;
                Prefs().setAWHEnabled(activated);
              });
            }
          : null,
    );
  }

  Switch tornExchangeSwitch() {
    return Switch(
      activeThumbColor: const Color(0xffd186cf),
      activeTrackColor: Colors.pink,
      value: _tornExchangeEnabled,
      onChanged: _tradeCalculatorEnabled
          ? (activated) async {
              setState(() {
                _tornExchangeEnabled = activated;
                Prefs().setTornExchangeEnabled(activated);
              });
            }
          : null,
    );
  }

  Switch tornExchangeProfitSwitch() {
    return Switch(
      activeThumbColor: const Color(0xffd186cf),
      activeTrackColor: Colors.pink,
      value: _tornExchangeProfitEnabled,
      onChanged: _tradeCalculatorEnabled
          ? (activated) async {
              setState(() {
                _tornExchangeProfitEnabled = activated;
                Prefs().setTornExchangeProfitEnabled(activated);
              });
            }
          : null,
    );
  }

  Future _restorePreferences() async {
    final tradeCalculatorActive = await Prefs().getTradeCalculatorEnabled();
    final awhActive = await Prefs().getAWHEnabled();
    final tornExchangeActive = await Prefs().getTornExchangeEnabled();
    final tornExchangeProfitActive = await Prefs().getTornExchangeProfitEnabled();

    setState(() {
      _tradeCalculatorEnabled = tradeCalculatorActive;
      _awhEnabled = awhActive;
      _tornExchangeEnabled = tornExchangeActive;
      _tornExchangeProfitEnabled = tornExchangeProfitActive;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
