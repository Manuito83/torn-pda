import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
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
  bool _tornTraderEnabled = true;

  Future _preferencesLoaded;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Trade Calculator"),
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              widget.callback();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
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
                                    SharedPreferencesModel().setTradeCalculatorEnabled(value);
                                    setState(() {
                                      _tradeCalculatorEnabled = value;
                                      if (!value) {
                                        _tornTraderEnabled = false;
                                        // TODO: sharedprefs for torntrader
                                      }
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
                                      image: AssetImage('images/icons/torntrader_logo.png'),
                                      width: 20,
                                      color: ttColor,
                                      fit: BoxFit.fill,
                                    ),
                                    SizedBox(width: 10),
                                    Text("Torn Trader sync"),
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
            );
          },
        ),
      ),
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
                  SharedPreferencesModel().setTornTraderEnabled(activated);
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
                  SharedPreferencesModel().setTornTraderEnabled(activated);
                });
              }
            }
          : null,
    );
  }

  Future _restorePreferences() async {
    var tradeCalculatorActive = await SharedPreferencesModel().getTradeCalculatorEnabled();
    var tornTraderActive = await SharedPreferencesModel().getTornTraderEnabled();

    setState(() {
      _tradeCalculatorEnabled = tradeCalculatorActive;
      _tornTraderEnabled = tornTraderActive;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
