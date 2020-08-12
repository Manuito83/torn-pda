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
  bool _tradeCalculatorEnabled = true;

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
    var tradeCalculatorActive = await SharedPreferencesModel().getTradeCalculatorEnabled();

    setState(() {
      _tradeCalculatorEnabled = tradeCalculatorActive;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
