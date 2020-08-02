import 'package:android_intent/android_intent.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TradesOptions extends StatefulWidget {
  final Function callback;

  TradesOptions({
    @required this.callback,
  });

  @override
  _TradesOptionsState createState() => _TradesOptionsState();
}

class _TradesOptionsState extends State<TradesOptions> {
  bool _tradeCalculatorActive = true;
  bool _tradeCalculatorRefresh = true;

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
                        children: <Widget>[
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Use trade calculator"),
                                Switch(
                                  value: _tradeCalculatorActive,
                                  onChanged: (value) {
                                    SharedPreferencesModel().setTradeCalculatorActive(value);
                                    setState(() {
                                      _tradeCalculatorActive = value;
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
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Watch for deletions"),
                                Switch(
                                  value: _tradeCalculatorRefresh,
                                  onChanged: _tradeCalculatorActive ? (value) {
                                    SharedPreferencesModel().setTradeCalculatorRefresh(value);
                                    setState(() {
                                      _tradeCalculatorRefresh = value;
                                    });
                                  } : null,
                                  activeTrackColor: Colors.lightGreenAccent,
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              'Enables auto updating the list when an item is removed by the player, '
                              'with no need to refresh manually refresh the trade. May have an '
                              'impact on performance',
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

  Future _restorePreferences() async {
    var tradeCalculatorActive = await SharedPreferencesModel().getTradeCalculatorActive();
    var tradeCalculatorRefresh = await SharedPreferencesModel().getTradeCalculatorRefresh();

    setState(() {
      _tradeCalculatorActive = tradeCalculatorActive;
      _tradeCalculatorRefresh = tradeCalculatorRefresh;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
