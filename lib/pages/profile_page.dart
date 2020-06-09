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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/webview_generic.dart';

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

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

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
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
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
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: _apiFetched,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiGoodData) {
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                      child: Column(
                        children: <Widget>[
                          Text(
                            '${_user.name} [${_user.playerId}]',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Level ${_user.level}',
                          ),
                          Text(
                            'Online ${_user.lastAction.relative}',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                      child: _playerStatus(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                      child: _basicBars(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                      child: _coolDowns(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
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
    );
  }

  Card _playerStatus() {
    Widget descriptionWidget;
    if (_user.status.state != 'Okay') {
      // Main short description
      String descriptionText = _user.status.description;

      // Is there a detailed description?
      if (_user.status.details != '') {
        descriptionText += '- ${_user.status.details}';
      }

      // Removing the ugly HTML in the API... oh God, why?
      RegExp expHtml = RegExp(r"<[^>]*>");
      var matches = expHtml.allMatches(descriptionText).map((m) => m[0]);
      for (var m in matches) {
        descriptionText = descriptionText.replaceAll(m, '');
      }

      // Causing player ID (jailed of hospitlised the user)
      String causingId = '';
      if (matches.length > 0) {
        RegExp expId = RegExp(r"(?!XID=)([0-9])+");
        var id = expId.allMatches(_user.status.details).map((m) => m[0]);
        causingId = id.first;
      }

      // If there is a causing it, add a span to click and go to the
      // profile, otherwise return just the description text
      if (causingId != '') {
        descriptionWidget = RichText(
          text: new TextSpan(
            children: [
              new TextSpan(
                text: descriptionText,
                style: new TextStyle(color: _themeProvider.mainText),
              ),
              new TextSpan(
                text: ' (',
                style: new TextStyle(color: _themeProvider.mainText),
              ),
              new TextSpan(
                text: 'profile',
                style: new TextStyle(color: Colors.blue),
                recognizer: new TapGestureRecognizer()
                  ..onTap = () async {
                    var browserType = _settingsProvider.currentBrowser;
                    switch (browserType) {
                      case BrowserSetting.app:
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                TornWebViewGeneric(
                              profileId: causingId,
                              profileName: causingId,
                              webViewType: WebViewType.profile,
                            ),
                          ),
                        );
                        break;
                      case BrowserSetting.external:
                        var url = 'https://www.torn.com/profiles.php?'
                            'XID=$causingId';
                        if (await canLaunch(url)) {
                          await launch(url, forceSafariVC: false);
                        }
                        break;
                    }
                  },
              ),
              new TextSpan(
                text: ')',
                style: new TextStyle(color: _themeProvider.mainText),
              ),
            ],
          ),
        );
      } else {
        descriptionWidget = Text(descriptionText);
      }
    } else {
      descriptionWidget = SizedBox.shrink();
    }

    Color stateColor;
    if (_user.status.color == 'red') {
      stateColor = Colors.red;
    } else if (_user.status.color == 'green') {
      stateColor = Colors.green;
    } else if (_user.status.color == 'blue') {
      stateColor = Colors.blue;
    }

    Widget stateBall = Padding(
      padding: EdgeInsets.only(left: 8),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
            color: stateColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black)),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                'STATUS',
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
                        width: 60,
                        child: Text('Status: '),
                      ),
                      Text(_user.status.state),
                      stateBall,
                    ],
                  ),
                  _user.status.details == ''
                      ? SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 60,
                                child: Text('Details: '),
                              ),
                              Flexible(
                                child: descriptionWidget,
                              ),
                            ],
                          ),
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
    Widget cooldownItems;
    if (_user.cooldowns.drug > 0 ||
        _user.cooldowns.booster > 0 ||
        _user.cooldowns.medical > 0) {
      cooldownItems = Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          children: <Widget>[
            _user.cooldowns.drug > 0
                ? Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _drugIcon(),
                          SizedBox(width: 10),
                          _drugCounter(),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                : SizedBox.shrink(),
            _user.cooldowns.medical > 0
                ? Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _medicalIcon(),
                          SizedBox(width: 10),
                          _medicalCounter(),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                : SizedBox.shrink(),
            _user.cooldowns.booster > 0
                ? Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _boosterIcon(),
                          SizedBox(width: 10),
                          _boosterCounter(),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                : SizedBox.shrink(),
          ],
        ),
      );
    } else {
      cooldownItems = Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text("Nothing to report, well done!"),
          ),
        ],
      );
    }

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
            cooldownItems,
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Image _drugIcon() {
    // 0-10 minutes
    if (_user.cooldowns.drug > 0 && _user.cooldowns.drug < 600) {
      return Image.asset('images/icons/cooldowns/drug1.png', width: 20);
    } // 10-60 minutes
    else if (_user.cooldowns.drug >= 600 && _user.cooldowns.drug < 3600) {
      return Image.asset('images/icons/cooldowns/drug2.png', width: 20);
    } // 1-2 hours
    else if (_user.cooldowns.drug >= 3600 && _user.cooldowns.drug < 7200) {
      return Image.asset('images/icons/cooldowns/drug3.png', width: 20);
    } // 2-5 hours
    else if (_user.cooldowns.drug >= 7200 && _user.cooldowns.drug < 18000) {
      return Image.asset('images/icons/cooldowns/drug4.png', width: 20);
    } // 5+ hours
    else {
      return Image.asset('images/icons/cooldowns/drug5.png', width: 20);
    }
  }

  Image _medicalIcon() {
    // 0-6 hours
    if (_user.cooldowns.medical > 0 && _user.cooldowns.medical < 21600) {
      return Image.asset('images/icons/cooldowns/medical1.png', width: 20);
    } // 6-12 hours
    else if (_user.cooldowns.medical >= 21600 &&
        _user.cooldowns.medical < 43200) {
      return Image.asset('images/icons/cooldowns/medical2.png', width: 20);
    } // 12-18 hours
    else if (_user.cooldowns.medical >= 43200 &&
        _user.cooldowns.medical < 64800) {
      return Image.asset('images/icons/cooldowns/medical3.png', width: 20);
    } // 18-24 hours
    else if (_user.cooldowns.medical >= 64800 &&
        _user.cooldowns.medical < 86400) {
      return Image.asset('images/icons/cooldowns/medical4.png', width: 20);
    } // 24+ hours
    else {
      return Image.asset('images/icons/cooldowns/medical5.png', width: 20);
    }
  }

  Image _boosterIcon() {
    // 0-6 hours
    if (_user.cooldowns.booster > 0 && _user.cooldowns.booster < 21600) {
      return Image.asset('images/icons/cooldowns/booster1.png', width: 20);
    } // 6-12 hours
    else if (_user.cooldowns.booster >= 21600 &&
        _user.cooldowns.booster < 43200) {
      return Image.asset('images/icons/cooldowns/booster2.png', width: 20);
    } // 12-18 hours
    else if (_user.cooldowns.booster >= 43200 &&
        _user.cooldowns.booster < 64800) {
      return Image.asset('images/icons/cooldowns/booster3.png', width: 20);
    } // 18-24 hours
    else if (_user.cooldowns.booster >= 64800 &&
        _user.cooldowns.booster < 86400) {
      return Image.asset('images/icons/cooldowns/booster4.png', width: 20);
    } // 24+ hours
    else {
      return Image.asset('images/icons/cooldowns/booster5.png', width: 20);
    }
  }

  Widget _drugCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.drug));
    var formatter = new DateFormat('HH:mm');
    String timeFormatted = formatter.format(timeEnd);
    String diff = _timeDifferenceFormatted(timeEnd);
    return Flexible(child: Text('@ $timeFormatted LT, $diff'));
  }

  Widget _medicalCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.medical));
    var formatter = new DateFormat('HH:mm');
    String timeFormatted = formatter.format(timeEnd);
    String diff = _timeDifferenceFormatted(timeEnd);
    return Flexible(child: Text('@ $timeFormatted LT, $diff'));
  }

  Widget _boosterCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.booster));
    var formatter = new DateFormat('HH:mm');
    String timeFormatted = formatter.format(timeEnd);
    String diff = _timeDifferenceFormatted(timeEnd);
    return Flexible(child: Text('@ $timeFormatted LT, $diff'));
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
      diff = 'in ${timeDifference.inHours} hours (tomorrow)';
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

        // TODO:debug delete

        //_user.cooldowns.drug = 17000;
        //_user.cooldowns.booster = 98000;
      } else {
        _apiGoodData = false;
      }
    });
  }
}
