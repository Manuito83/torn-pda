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
  int _energyPercentage = 100;
  int _nervePercentage = 100;

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
                Text('Energy %'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text(
                        'E${(widget.energyMax * _energyPercentage / 100).floor()}'),
                    Slider(
                      value: _energyPercentage.toDouble(),
                      min: 10,
                      max: 100,
                      label: '${_energyPercentage.floor()}%',
                      divisions: 90,
                      onChanged: (double newPercentage) {
                        setState(() {
                          _energyPercentage = newPercentage.floor();
                          SharedPreferencesModel()
                              .setEnergyNotificationPercentage(
                                  newPercentage.floor());
                        });
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
                Text('Nerve %'),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                ),
                Row(
                  children: <Widget>[
                    Text(
                        'N${(widget.nerveMax * _nervePercentage / 100).floor()}'),
                    Slider(
                      value: _nervePercentage.toDouble(),
                      min: 1,
                      max: 100,
                      label: '${_nervePercentage.floor()}%',
                      divisions: 90,
                      onChanged: (double newPercentage) {
                        setState(() {
                          _nervePercentage = newPercentage.floor();
                          SharedPreferencesModel()
                              .setNerveNotificationPercentage(
                                  newPercentage.floor());
                        });
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
    var energyPercentage =
        await SharedPreferencesModel().getEnergyNotificationPercentage();
    var nervePercentage =
        await SharedPreferencesModel().getNerveNotificationPercentage();

    setState(() {
      _energyPercentage = energyPercentage;
      _nervePercentage = nervePercentage;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}
