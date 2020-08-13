import 'package:android_intent/android_intent.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class LootNotificationsAndroid extends StatefulWidget {
  final Function callback;

  LootNotificationsAndroid({
    @required this.callback,
  });

  @override
  _LootNotificationsAndroidState createState() => _LootNotificationsAndroidState();
}

class _LootNotificationsAndroidState extends State<LootNotificationsAndroid> {
  String _lootTypeDropDownValue;
  String _lootNotificationAheadDropDownValue;

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
          title: Text("Loot options"),
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
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text('Here you can specify your preferred alerting '
                                'method and launch time before the loot level is reached'),
                          ),
                          _rowsWithTypes(),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: RichText(
                              text: TextSpan(
                                text: 'Note: some Android clock applications do not work well '
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
                                    SharedPreferencesModel().setLootAlarmSound(value);
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
                                    SharedPreferencesModel().setLootAlarmVibration(value);
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

  Widget _rowsWithTypes() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text('Loot'),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20),
              ),
              Flexible(
                child: _lootDropDown(),
              ),
            ],
          ),
        ),
        if (_lootTypeDropDownValue == "0")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  child: _lootTimerDropDown(),
                ),
              ],
            ),
          )
        else
          SizedBox.shrink(),
      ],
    );
  }

  DropdownButton _lootDropDown() {
    return DropdownButton<String>(
      value: _lootTypeDropDownValue,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "Notification",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 80,
            child: Text(
              "Alarm",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "2",
          child: SizedBox(
            width: 80,
            child: Text(
              "Timer",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        SharedPreferencesModel().setLootNotificationType(value);
        setState(() {
          _lootTypeDropDownValue = value;
        });
      },
    );
  }

  DropdownButton _lootTimerDropDown() {
    return DropdownButton<String>(
      value: _lootNotificationAheadDropDownValue,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "20 seconds",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 80,
            child: Text(
              "40 seconds",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "2",
          child: SizedBox(
            width: 80,
            child: Text(
              "1 minute",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "3",
          child: SizedBox(
            width: 80,
            child: Text(
              "1.5 minutes",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "4",
          child: SizedBox(
            width: 80,
            child: Text(
              "2 minutes",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        SharedPreferencesModel().setLootNotificationAhead(value);
        setState(() {
          _lootNotificationAheadDropDownValue = value;
        });
      },
    );
  }

  Future _restorePreferences() async {
    var lootType = await SharedPreferencesModel().getLootNotificationType();
    var lootNotificationAhead = await SharedPreferencesModel().getLootNotificationAhead();
    var alarmSound = await SharedPreferencesModel().getLootAlarmSound();
    var alarmVibration = await SharedPreferencesModel().getLootAlarmVibration();

    setState(() {
      _lootTypeDropDownValue = lootType;
      _lootNotificationAheadDropDownValue = lootNotificationAhead;
      _alarmSound = alarmSound;
      _alarmVibration = alarmVibration;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
