import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/own_profile_model.dart';
import 'package:torn_pda/providers/api_key_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future _apiFetched;
  bool _apiGoodData;

  OwnProfileModel _user;

  DateTime _now;

  Timer _tickerCallChainApi;

  @override
  void initState() {
    super.initState();
    _apiFetched = _fetchApi();

    _tickerCallChainApi =
        new Timer.periodic(Duration(seconds: 60), (Timer t) => _fetchApi());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: new Drawer(),
      appBar: AppBar(
        title: Text('Profile'),
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          onPressed: () {
            final ScaffoldState scaffoldState =
                context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: FutureBuilder(
            future: _apiFetched,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_apiGoodData) {
                  return Column(
                    children: <Widget>[
                      _basicBars(),
                    ],
                  );
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'OPS!',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        child: Text(
                          'There was an error getting the information, please '
                          'try again later!',
                        ),
                      ),
                    ],
                  );
                }
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Fetching data...'),
                      SizedBox(height: 30),
                      CircularProgressIndicator(),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _basicBars() {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 50,
                    child: Text('Energy'),
                  ),
                  SizedBox(width: 10),
                  LinearPercentIndicator(
                    width: 150,
                    lineHeight: 20,
                    progressColor: Colors.green,
                    backgroundColor: Colors.grey,
                    center: Text(
                      '${_user.energy.current}',
                      style: TextStyle(color: Colors.black),
                    ),
                    percent: _user.energy.current / _user.energy.maximum > 1.0
                        ? 1.0
                        : _user.energy.current / _user.energy.maximum,
                  ),
                ],
              ),
              _user.energy.fulltime == 0 ||
                      _user.energy.current > _user.energy.maximum
                  ? SizedBox.shrink()
                  : _barTime('energy'),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 50,
                    child: Text('Nerve'),
                  ),
                  SizedBox(width: 10),
                  LinearPercentIndicator(
                    width: 150,
                    lineHeight: 20,
                    progressColor: Colors.redAccent,
                    backgroundColor: Colors.grey,
                    center: Text(
                      '${_user.nerve.current}',
                      style: TextStyle(color: Colors.black),
                    ),
                    percent: _user.nerve.current / _user.nerve.maximum > 1.0
                        ? 1.0
                        : _user.nerve.current / _user.nerve.maximum,
                  ),
                ],
              ),
              _user.nerve.fulltime == 0 ||
                      _user.nerve.current >= _user.nerve.maximum
                  ? SizedBox.shrink()
                  : _barTime('nerve'),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 50,
                    child: Text('Happy'),
                  ),
                  SizedBox(width: 10),
                  LinearPercentIndicator(
                    width: 150,
                    lineHeight: 20,
                    progressColor: Colors.amber,
                    backgroundColor: Colors.grey,
                    center: Text(
                      '${_user.happy.current}',
                      style: TextStyle(color: Colors.black),
                    ),
                    percent: _user.happy.current / _user.happy.maximum > 1.0
                        ? 1.0
                        : _user.happy.current / _user.happy.maximum,
                  ),
                ],
              ),
              _user.happy.fulltime == 0 ||
                      _user.happy.current > _user.happy.maximum
                  ? SizedBox.shrink()
                  : _barTime('happy'),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 50,
                    child: Text('Life'),
                  ),
                  SizedBox(width: 10),
                  LinearPercentIndicator(
                    width: 150,
                    lineHeight: 20,
                    progressColor: Colors.blue,
                    backgroundColor: Colors.grey,
                    center: Text(
                      '${_user.life.current}',
                      style: TextStyle(color: Colors.black),
                    ),
                    percent: _user.life.current / _user.life.maximum > 1.0
                        ? 1.0
                        : _user.life.current / _user.life.maximum,
                  ),
                  _user.status.state == "Hospital"
                      ? Icon(
                    Icons.local_hospital,
                    size: 20,
                    color: Colors.red,
                  )
                      : SizedBox.shrink(),
                ],
              ),
              _user.life.fulltime == 0 ||
                      _user.life.current > _user.life.maximum
                  ? SizedBox.shrink()
                  : _barTime('life'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barTime(String type) {
    var time;
    switch (type) {
      case "energy":
        time = _now.add(Duration(seconds: _user.energy.fulltime));
        break;
      case "nerve":
        time = _now.add(Duration(seconds: _user.nerve.fulltime));
        break;
      case "happy":
        time = _now.add(Duration(seconds: _user.happy.fulltime));
        break;
      case "life":
        time = _now.add(Duration(seconds: _user.life.fulltime));
        break;
    }

    var formatter = new DateFormat('HH:ss');
    String timeFormatted = formatter.format(time);

    return Row(
      children: <Widget>[
        SizedBox(width: 65),
        Text('Full at $timeFormatted LT'),
      ],
    );
  }

  Future<void> _fetchApi() async {
    var apiKeyProvider = Provider.of<ApiKeyProvider>(context, listen: false);
    var apiResponse =
        await TornApiCaller.ownProfile(apiKeyProvider.apiKey).getOwnProfile;

    setState(() {
      if (apiResponse is OwnProfileModel) {
        _now = DateTime.now();
        _user = apiResponse;
        _apiGoodData = true;
      } else {
        _apiGoodData = false;
      }
    });
  }
}
