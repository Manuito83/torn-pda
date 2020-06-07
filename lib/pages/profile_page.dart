import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  DateTime _serverTime;

  Timer _tickerCallChainApi;

  @override
  void initState() {
    super.initState();
    _apiFetched = _fetchApi();

    _tickerCallChainApi =
        new Timer.periodic(Duration(seconds: 60), (Timer t) => _fetchApi());
  }

  @override
  void dispose() {
    _tickerCallChainApi.cancel();
    super.dispose();
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 5),
                        child: _basicBars(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                        child: _coolDowns(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                        child: _netWorth(),
                      ),
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
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

  Card _basicBars() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'BARS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
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
                        percent:
                            _user.energy.current / _user.energy.maximum > 1.0
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
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
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
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
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
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _barTime(String type) {
    var time;
    switch (type) {
      case "energy":
        time = _serverTime.add(Duration(seconds: _user.energy.fulltime));
        break;
      case "nerve":
        time = _serverTime.add(Duration(seconds: _user.nerve.fulltime));
        break;
      case "happy":
        time = _serverTime.add(Duration(seconds: _user.happy.fulltime));
        break;
      case "life":
        time = _serverTime.add(Duration(seconds: _user.life.fulltime));
        break;
    }

    var formatter = new DateFormat('HH:mm');
    String timeFormatted = formatter.format(time);

    return Row(
      children: <Widget>[
        SizedBox(width: 65),
        Text('Full at $timeFormatted LT'),
      ],
    );
  }

  Card _coolDowns() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'COOLDOWNS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.poll),
                      SizedBox(width: 10),
                      _drugCounter(),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Icon(Icons.poll),
                      SizedBox(width: 10),
                      Text('quacki'),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Icon(Icons.poll),
                      SizedBox(width: 10),
                      Text('quacki'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _drugCounter() {
    // TODO:debug delete
    _user.cooldowns.drug = 76;

    if (_user.cooldowns.drug == 0) {
      return Text(
        '0',
        style: TextStyle(color: Colors.green),
      );
    } else {
      var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.drug));
      var formatter = new DateFormat('HH:mm');
      String timeFormatted = formatter.format(timeEnd);
      String diff = _timeDifferenceFormatted(timeEnd);

      return Text('@ $timeFormatted LT, $diff');
    }
  }

  String _timeDifferenceFormatted(DateTime timeEnd) {
    String diff;
    var timeDifference = timeEnd.difference(_serverTime);
    if (timeDifference.inMinutes < 1) {
      diff = 'seconds away';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      diff = 'in 1 minute';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      diff = 'in ${timeDifference.inMinutes} minutes';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      diff = 'in 1 hour';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      diff = 'in ${timeDifference.inHours} hours';
    } else {
      diff = 'tomorrow';
    }
    return diff;
  }

  Card _netWorth() {
    // Currency configuration
    final moneyFormat = new NumberFormat("#,##0", "en_US");

    // Total when folded
    int total;
    for (var v in _user.networth.entries) {
      if (v.key == 'total') {
        total = v.value.round();
      }
    }

    // List for all sources in column
    var moneySources = List<Widget>();

    // Total Expanded
    moneySources.add(
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 110,
              child: Text(
                'Total: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '\$${moneyFormat.format(total)}',
              style: TextStyle(
                color: total < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    // Loop all other sources
    for (var v in _user.networth.entries) {
      String source;
      if (v.key == 'total' || v.key == 'parsetime') {
        continue;
      } else if (v.key == 'piggybank') {
        source = 'Piggy Bank';
      } else if (v.key == 'displaycase') {
        source = 'Display Case';
      } else if (v.key == 'stockmarket') {
        source = 'Stock Market';
      } else if (v.key == 'auctionhouse') {
        source = 'Auction House';
      } else if (v.key == 'unpaidfees') {
        source = 'Unpaid Fees';
      } else {
        source = "${v.key[0].toUpperCase()}${v.key.substring(1)}";
      }

      moneySources.add(
        Row(
          children: <Widget>[
            SizedBox(
              height: 20,
              width: 110,
              child: Text('$source: '),
            ),
            Text(
              '\$${moneyFormat.format(v.value.round())}',
              style: TextStyle(
                color: v.value < 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: ExpandablePanel(
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(
            'NETWORTH',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(30, 5, 20, 20),
          child: Text(
            '\$${moneyFormat.format(total)}',
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.droidSerif(
              textStyle: TextStyle(
                fontSize: 16,
                color: total <= 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: moneySources,
          ),
        ),
      ),
    );
  }

  Future<void> _fetchApi() async {
    var apiKeyProvider = Provider.of<ApiKeyProvider>(context, listen: false);
    var apiResponse =
        await TornApiCaller.ownProfile(apiKeyProvider.apiKey).getOwnProfile;

    setState(() {
      if (apiResponse is OwnProfileModel) {
        _user = apiResponse;
        _serverTime =
            DateTime.fromMillisecondsSinceEpoch(_user.serverTime * 1000);
        _apiGoodData = true;
      } else {
        _apiGoodData = false;
      }
    });
  }
}
