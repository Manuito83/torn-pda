import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:torn_pda/models/own_profile_model.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/webview_generic.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/rendering.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  Future _apiFetched;
  bool _apiGoodData;

  OwnProfileModel _user;

  DateTime _serverTime;

  Timer _tickerCallChainApi;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  // For dial FAB
  ScrollController scrollController;
  bool dialVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    scrollController = ScrollController()
      ..addListener(() {
        setDialVisible(scrollController.position.userScrollDirection ==
            ScrollDirection.forward);
      });

    _apiFetched = _fetchApi();

    _tickerCallChainApi =
        new Timer.periodic(Duration(seconds: 30), (Timer t) => _fetchApi());
  }

  @override
  void dispose() {
    _tickerCallChainApi.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchApi();
    }
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
      floatingActionButton: buildSpeedDial(),
      body: Container(
        child: FutureBuilder(
          future: _apiFetched,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiGoodData) {
                return SingleChildScrollView(
                  child: Column(
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
                              _user.lastAction.relative[0] == '0'
                                  ? 'Online now'
                                  : 'Online ${_user.lastAction.relative}',
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
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                        child: _eventsTimeline(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
                        child: _netWorth(),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: Column(
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
                  ),
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

      // Causing player ID (jailed of hospitalised the user)
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
                              //profileName: causingId,
                              genericTitle: 'Event Profile',
                              webViewType: WebViewType.profile,
                              genericCallBack: _updateCallback,
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
    String diff = _cooldownTimeFormatted(timeEnd);
    return Flexible(child: Text('@ $timeFormatted $diff'));
  }

  Widget _medicalCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.medical));
    var formatter = new DateFormat('HH:mm');
    String timeFormatted = formatter.format(timeEnd);
    String diff = _cooldownTimeFormatted(timeEnd);
    return Flexible(child: Text('@ $timeFormatted $diff'));
  }

  Widget _boosterCounter() {
    var timeEnd = _serverTime.add(Duration(seconds: _user.cooldowns.booster));
    var formatter = new DateFormat('HH:mm');
    String timeFormatted = formatter.format(timeEnd);
    String diff = _cooldownTimeFormatted(timeEnd);
    return Flexible(child: Text('@ $timeFormatted $diff'));
  }

  String _cooldownTimeFormatted(DateTime timeEnd) {
    String diff;
    var timeDifference = timeEnd.difference(_serverTime);
    if (timeDifference.inMinutes < 1) {
      diff = 'LT , seconds away';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      diff = 'LT , in 1 minute';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      diff = 'LT , in ${timeDifference.inMinutes} minutes';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      diff = 'LT , in 1 hour';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      diff = 'LT , in ${timeDifference.inHours} hours';
    } else {
      diff = 'LT tomorrow, in ${timeDifference.inHours} hours';
    }
    return diff;
  }

  Card _eventsTimeline() {
    var timeline = List<Widget>();

    int unreadCount = 0;
    int loopCount = 1;
    int maxCount;

    if (_user.events.length > 20) {
      maxCount = 20;
    } else {
      maxCount = _user.events.length;
    }

    for (var e in _user.events.values) {
      if (e.seen == 0) {
        unreadCount++;
      }

      String message = e.event;
      RegExp expHtml = RegExp(r"<[^>]*>");
      var matches = expHtml.allMatches(message).map((m) => m[0]);
      for (var m in matches) {
        message = message.replaceAll(m, '');
      }
      message = message.replaceAll('View the details here!', '');
      message = message.replaceAll(' [view]', '.');

      Widget insideIcon = _eventsInsideIconCases(message);

      IndicatorStyle iconBubble;
      iconBubble = IndicatorStyle(
        width: 30,
        height: 30,
        drawGap: true,
        indicator: Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.grey,
              ),
            ),
            shape: BoxShape.rectangle,
          ),
          child: insideIcon,
        ),
      );

      var eventTime = DateTime.fromMillisecondsSinceEpoch(e.timestamp * 1000);

      var event = TimelineTile(
        isFirst: loopCount == 1 ? true : false,
        isLast: loopCount == maxCount ? true : false,
        alignment: TimelineAlign.manual,
        indicatorStyle: iconBubble,
        lineX: 0.25,
        rightChild: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: e.seen == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        leftChild: Container(
          child: Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Text(
              _eventsTimeFormatted(eventTime),
              style: TextStyle(
                fontSize: 11,
                fontWeight: e.seen == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      timeline.add(event);

      if (loopCount == maxCount) {
        break;
      }
      loopCount++;
    }

    var unreadString = '';
    if (unreadCount == 0) {
      unreadString = 'No unread events';
    } else if (unreadCount == 1) {
      unreadString = "1 unread event";
    } else {
      unreadString = '$unreadCount unread events';
    }

    return Card(
      child: ExpandablePanel(
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(
            'EVENTS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(30, 5, 20, 20),
          child: Text(
            unreadString,
            style: TextStyle(
              color: unreadCount == 0 ? Colors.green : Colors.red,
              fontWeight:
                  unreadCount == 0 ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: timeline,
          ),
        ),
      ),
    );
  }

  Widget _eventsInsideIconCases(String message) {
    Widget insideIcon;
    if (message.contains('revive')) {
      insideIcon = Icon(
        Icons.local_hospital,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('the director of')) {
      insideIcon = Icon(
        Icons.work,
        color: Colors.brown[300],
        size: 20,
      );
    } else if (message.contains('jail')) {
      insideIcon = Center(
        child: Image.asset(
          'images/icons/jail.png',
          width: 20,
          height: 20,
        ),
      );
    } else if (message.contains('trade')) {
      insideIcon = Icon(
        Icons.switch_camera,
        color: Colors.purple,
        size: 20,
      );
    } else if (message.contains('has given you') ||
        message.contains('You were sent') ||
        message.contains('You have been credited with') ||
        message.contains('on your doorstep')) {
      insideIcon = Icon(
        Icons.card_giftcard,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('Get out of my education') ||
        message.contains('You must have overdosed')) {
      insideIcon = Icon(
        Icons.warning,
        color: Colors.red,
        size: 20,
      );
    } else if (message.contains('purchased membership')) {
      insideIcon = Icon(
        Icons.fitness_center,
        color: Colors.black54,
        size: 20,
      );
    } else if (message.contains('You upgraded your level')) {
      insideIcon = Icon(
        Icons.file_upload,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('won') ||
        message.contains('lottery') ||
        message.contains('check has been credited to your') ||
        message.contains('withdraw your check from the bank')) {
      insideIcon = Icon(
        Icons.monetization_on,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('attacked you') ||
        message.contains('mugged you and stole') ||
        message.contains('attacked and hospitalized')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/ic_target_account_black_48dp.png',
            width: 20,
            height: 20,
            color: Colors.red,
          ),
        ),
      );
    } else if (message.contains('You and your team') ||
        message.contains('You have been selected') ||
        message.contains('canceled the')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/ic_pistol_black_48dp.png',
            width: 20,
            height: 20,
            color: Colors.blue,
          ),
        ),
      );
    } else if (message.contains('You left your faction') ||
        message.contains('Your application to') ||
        message.contains('canceled the')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/faction.png',
            width: 20,
            height: 20,
            color: Colors.black,
          ),
        ),
      );
    } else {
      insideIcon = Container(
        child: Center(
          child: Text(
            'T',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
      );
    }
    return insideIcon;
  }

  String _eventsTimeFormatted(DateTime eventTime) {
    String diff;
    var timeDifference = _serverTime.difference(eventTime);
    if (timeDifference.inMinutes < 1) {
      diff = 'Seconds ago';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      diff = '1 min ago';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      diff = '${timeDifference.inMinutes} mins ago';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      diff = '1 hr ago';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      diff = '${timeDifference.inHours} hrs ago';
    } else {
      diff = '${timeDifference.inDays} days ago';
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
    var userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    var apiResponse =
        await TornApiCaller.ownProfile(userProvider.myUser.userApiKey).getOwnProfile;

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

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      //animatedIcon: AnimatedIcons.menu_close,
      //animatedIconTheme: IconThemeData(size: 22.0),
      backgroundColor: Colors.transparent,
      overlayColor: Colors.transparent,
      child: Container(
        width: 58,
        height: 58,
        decoration: new BoxDecoration(
          border: Border.all(
            color: Colors.grey[800],
            width: 2,
          ),
          shape: BoxShape.circle,
          image: new DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage("images/icons/torn_t_logo.png"),
          ),
        ),
      ),
      visible: dialVisible,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(
            Icons.comment,
            color: Colors.black,
          ),
          backgroundColor: Colors.grey[400],
          onTap: () async {
            _openTornBrowser('events');
          },
          label: 'EVENTS',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.grey[400],
        ),
        SpeedDialChild(
          child: Icon(
            Icons.card_giftcard,
            color: Colors.black,
          ),
          backgroundColor: Colors.blue[400],
          onTap: () async {
            _openTornBrowser('items');
          },
          label: 'ITEMS',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.blue[400],
        ),
        SpeedDialChild(
          child: Center(
            child: Image.asset(
              'images/icons/ic_pistol_black_48dp.png',
              width: 25,
              height: 25,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.green[400],
          onTap: () async {
            _openTornBrowser('crimes');
          },
          label: 'CRIMES',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.green[400],
        ),
        SpeedDialChild(
          child: Icon(
            Icons.fitness_center,
            color: Colors.black,
          ),
          backgroundColor: Colors.deepOrange[400],
          onTap: () async {
            _openTornBrowser('gym');
          },
          label: 'GYM',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          labelBackgroundColor: Colors.deepOrange[400],
        ),
      ],
    );
  }

  Future _openTornBrowser(String page) async {
    var tornPage = '';
    switch (page) {
      case 'gym':
        tornPage = 'https://www.torn.com/gym.php';
        break;
      case 'crimes':
        tornPage = 'https://www.torn.com/crimes.php#/step=main';
        break;
      case 'items':
        tornPage = 'https://www.torn.com/item.php';
        break;
      case 'events':
        tornPage = 'https://www.torn.com/events.php#/step=all';
        break;
    }

    var browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => TornWebViewGeneric(
              webViewType: WebViewType.custom,
              customUrl: tornPage,
              genericTitle: 'Torn',
              genericCallBack: _updateCallback,
            ),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = tornPage;
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
  }

  void setDialVisible(bool value) {
    setState(() {
      dialVisible = value;
    });
  }

  Future _updateCallback() async {
    await Future.delayed(Duration(seconds: 10));
    _fetchApi();
  }

}
