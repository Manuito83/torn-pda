import 'package:android_intent/android_intent.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TravelOptions extends StatefulWidget {
  final Function callback;

  TravelOptions({
    @required this.callback,
  });

  @override
  _TravelOptionsState createState() =>
      _TravelOptionsState();
}

class _TravelOptionsState extends State<TravelOptions> {
  bool _alarmSound;
  bool _alarmVibration;

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
          title: Text("Travel options"),
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
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: RichText(
                              text: TextSpan(
                                text:
                                'Note: some Android clock applications do not work well '
                                    'with more than 1 timer or do not allow to choose '
                                    'between sound and vibration for alarms. If you experience '
                                    'any issue, it is recommended to install ',
                                style: DefaultTextStyle.of(context).style,
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Google\'s Clock application',
                                    style: TextStyle(color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        AndroidIntent intent = AndroidIntent(
                                          action: 'action_view',
                                          data: 'https://play.google.com/store'
                                              '/apps/details?id=com.google.android.deskclock',
                                        );
                                        await intent.launch();
                                      },
                                  ),
                                  TextSpan(
                                    text: '.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Alarm sound"),
                                Switch(
                                  value: _alarmSound,
                                  onChanged: (value) {
                                    setState(() {
                                      _alarmSound = value;
                                    });
                                    SharedPreferencesModel().setTravelAlarmSound(value);
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
                                Text("Alarm vibration"),
                                Switch(
                                  value: _alarmVibration,
                                  onChanged: (value) {
                                    setState(() {
                                      _alarmVibration = value;
                                    });
                                    SharedPreferencesModel().setTravelAlarmVibration(value);
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
    var alarmSound = await SharedPreferencesModel().getTravelAlarmSound();
    var alarmVibration = await SharedPreferencesModel().getTravelAlarmVibration();

    setState(() {
      _alarmSound = alarmSound;
      _alarmVibration = alarmVibration;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
