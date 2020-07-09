import 'package:flutter/material.dart';
import 'package:torn_pda/pages/profile_page.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ProfileNotificationsIOS extends StatefulWidget {
  final Function callback;
  final int energyMax;
  final int nerveMax;

  ProfileNotificationsIOS({
    @required this.callback,
    @required this.energyMax,
    @required this.nerveMax,
  });

  @override
  _ProfileNotificationsIOSState createState() =>
      _ProfileNotificationsIOSState();
}

class _ProfileNotificationsIOSState
    extends State<ProfileNotificationsIOS> {

  double _energyValue = 20;
  double _nerveValue = 20;

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
          title: Text("Profile options"),
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
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                                'Here you can specify your preferred alerting '
                                'values for each type of event.'),
                          ),
                          _rowsWithTypes(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 20,
                            ),
                            child: Divider(),
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
    var types = List<Widget>();
    ProfileNotification.values.forEach((element) {
      if (element == ProfileNotification.energy) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Trigger'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('E${_energyValue.floor()}'),
                    Slider(
                      value: _energyValue.toDouble(),
                      min: 10,
                      max: widget.energyMax.toDouble(),
                      onChanged: (double newValue) {
                        setState(() {
                          _energyValue = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        SharedPreferencesModel()
                            .setEnergyNotificationValue(finalValue.floor());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      if (element == ProfileNotification.nerve) {
        types.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Trigger'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text('N${_nerveValue.floor()}'),
                    Slider(
                      value: _nerveValue.toDouble(),
                      min: 2,
                      max: widget.nerveMax.toDouble(),
                      onChanged: (double newValue) {
                        setState(() {
                          _nerveValue = newValue;
                        });
                      },
                      onChangeEnd: (double finalValue) {
                        SharedPreferencesModel()
                            .setNerveNotificationValue(finalValue.floor());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      children: types,
    );
  }

  Future _restorePreferences() async {
    var energyValue =
      await SharedPreferencesModel().getEnergyNotificationValue();

    var nerveValue =
      await SharedPreferencesModel().getNerveNotificationValue();

    setState(() {
      _energyValue = energyValue.toDouble();
      _nerveValue = nerveValue.toDouble();
    });

  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
