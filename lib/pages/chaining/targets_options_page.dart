import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TargetsOptionsPage extends StatefulWidget {
  @override
  _TargetsOptionsPageState createState() => _TargetsOptionsPageState();
}

class _TargetsOptionsPageState extends State<TargetsOptionsPage> {
  // Skipping
  bool _skippingEnabled = true;

  // Chain watcher
  bool _soundAlertsEnabled = true;
  bool _vibrationAlertsEnabled = true;

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
          title: Text("Chaining Options"),
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              _willPopCallback();
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
                                Text("Skip red/blue targets"),
                                Switch(
                                  value: _skippingEnabled,
                                  onChanged: (value) {
                                    SharedPreferencesModel().setTargetSkipping(value);
                                    setState(() {
                                      _skippingEnabled = value;
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
                              'If enabled, targets that are in hospital, jail or in another '
                              'country will be skipped (max 3 at a time, to avoid delays)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CHAIN WATCHER',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Sound alerts"),
                                Switch(
                                  value: _soundAlertsEnabled,
                                  onChanged: (value) {
                                    SharedPreferencesModel().setChainWatcherSound(value);
                                    setState(() {
                                      _soundAlertsEnabled = value;
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Vibration"),
                                Switch(
                                  value: _vibrationAlertsEnabled,
                                  onChanged: (value) {
                                    SharedPreferencesModel().setChainWatcherVibration(value);
                                    setState(() {
                                      _vibrationAlertsEnabled = value;
                                    });
                                  },
                                  activeTrackColor: Colors.lightGreenAccent,
                                  activeColor: Colors.green,
                                ),
                              ],
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
    var skippingEnabled = await SharedPreferencesModel().getTargetSkipping();
    var soundEnabled = await SharedPreferencesModel().getChainWatcherSound();
    var vibrationEnabled = await SharedPreferencesModel().getChainWatcherVibration();

    setState(() {
      _skippingEnabled = skippingEnabled;
      _soundAlertsEnabled = soundEnabled;
      _vibrationAlertsEnabled = vibrationEnabled;
    });
  }

  Future<bool> _willPopCallback() async {
    var chainStatusProvider = context.read<ChainStatusProvider>();
    chainStatusProvider.loadPreferences();
    return true;
  }
}
