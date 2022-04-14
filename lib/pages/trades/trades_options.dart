// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/external/torntrader_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TradesOptions extends StatefulWidget {
  final int playerId;
  final Function callback;

  TradesOptions({
    @required this.playerId,
    @required this.callback,
  });

  @override
  _TradesOptionsState createState() => _TradesOptionsState();
}

class _TradesOptionsState extends State<TradesOptions> {
  static const ttColor = Color(0xffd186cf);

  bool _tradeCalculatorEnabled = true;
  bool _awhEnabled = true;
  bool _tornTraderEnabled = true;

  Future _preferencesLoaded;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
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
            body: Builder(
              builder: (BuildContext context) {
                return Container(
                  color: _themeProvider.canvas,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                    child: FutureBuilder(
                      future: _preferencesLoaded,
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text("Use trade calculator"),
                                      Switch(
                                        value: _tradeCalculatorEnabled,
                                        onChanged: (value) {
                                          Prefs().setTradeCalculatorEnabled(value);
                                          setState(() {
                                            _tradeCalculatorEnabled = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeColor: Colors.green,
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
                                SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Row(
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
                                SizedBox(height: 20),
                                /*
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Row(
                                        children: [
                                          SizedBox(width: 8),
                                          Image(
                                            image: AssetImage('images/icons/torntrader_logo.png'),
                                            width: 25,
                                            color: ttColor,
                                            fit: BoxFit.fill,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Torn Trader"),
                                        ],
                                      ),
                                      tornTraderSwitch(),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'If you are a professional trader and have an account with Torn '
                                    'Trader, you can activate the sync functionality here',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                */
                                SizedBox(height: 50),
                              ],
                            ),
                          );
                        } else {
                          return Center(
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
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text("Trade Calculator"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Switch awhSwitch() {
    return Switch(
      activeColor: Colors.orange[900],
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

  Switch tornTraderSwitch() {
    return Switch(
      activeColor: ttColor,
      activeTrackColor: Colors.pink,
      value: _tornTraderEnabled,
      onChanged: _tradeCalculatorEnabled
          ? (activated) async {
              if (activated) {
                var auth = await TornTraderComm.checkIfUserExists(
                  widget.playerId,
                );

                if (auth.error) {
                  BotToast.showText(
                    text: 'There was an issue contacting Torn Trader, please try again later!',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.orange[800],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                  return;
                }

                if (auth.allowed) {
                  Prefs().setTornTraderEnabled(activated);
                  setState(() {
                    _tornTraderEnabled = true;
                  });
                  BotToast.showText(
                    text: 'User ${widget.playerId} synced successfully!',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green[500],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                } else {
                  BotToast.showText(
                    text: 'No user found, please visit torntrader.com and sign up to use '
                        'this functionality!',
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.orange[800],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                }
              } else {
                setState(() {
                  _tornTraderEnabled = false;
                  Prefs().setTornTraderEnabled(activated);
                });
              }
            }
          : null,
    );
  }

  Future _restorePreferences() async {
    var tradeCalculatorActive = await Prefs().getTradeCalculatorEnabled();
    var awhActive = await Prefs().getAWHEnabled();
    var tornTraderActive = await Prefs().getTornTraderEnabled();

    setState(() {
      _tradeCalculatorEnabled = tradeCalculatorActive;
      _awhEnabled = awhActive;
      _tornTraderEnabled = tornTraderActive;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
