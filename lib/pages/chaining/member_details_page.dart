// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class MemberDetailsPage extends StatefulWidget {
  final String memberId;

  MemberDetailsPage({required this.memberId});

  @override
  _MemberDetailsPageState createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage> {
  late UserDetailsProvider _userDetails;
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  Future? _memberFetched;
  TargetModel? _member;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
    _memberFetched = _fetchMemberDetails();

    routeWithDrawer = false;
    routeName = "member_details";
    _settingsProvider.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "member_details") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return FutureBuilder(
      future: _memberFetched,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_member != null) {
            return Container(
              color: _themeProvider.currentTheme == AppTheme.light
                  ? MediaQuery.of(context).orientation == Orientation.portrait
                      ? Colors.blueGrey
                      : Colors.grey[900]
                  : _themeProvider.currentTheme == AppTheme.dark
                      ? Colors.grey[900]
                      : Colors.black,
              child: SafeArea(
                child: Scaffold(
                  backgroundColor: _themeProvider.canvas,
                  drawer: Drawer(),
                  appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
                  bottomNavigationBar: !_settingsProvider.appBarTop
                      ? SizedBox(
                          height: AppBar().preferredSize.height,
                          child: buildAppBar(),
                        )
                      : null,
                  body: Container(
                    color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
                    child: SingleChildScrollView(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_member!.name} [${_member!.playerId}]',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: IconButton(
                                        icon: Icon(Icons.content_copy),
                                        iconSize: 20,
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: _member!.playerId.toString()));
                                          BotToast.showText(
                                            text: "Your target's ID [${_member!.playerId}] has been "
                                                "copied to the clipboard!",
                                            textStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            contentColor: Colors.green,
                                            duration: Duration(seconds: 5),
                                            contentPadding: EdgeInsets.all(10),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text('${_member!.rank}'),
                              SizedBox(height: 20),
                              Text('Level: ${_member!.level}'),
                              Text('Gender: ${_member!.gender}'),
                              Text('Age: ${_member!.age} days'),
                              SizedBox(height: 20),
                              _returnLife(),
                              SizedBox(height: 5),
                              _returnLastAction(),
                              SizedBox(height: 5),
                              _returnStatus(),
                              SizedBox(height: 20),
                              Text('Awards: ${_member!.awards} '
                                  '(you have ${_userDetails.basic!.awards})'),
                              SizedBox(height: 20),
                              Text('Donator: ${_member!.donator == 0 ? 'NO' : 'YES'}'),
                              Text('Friends/Enemies: ${_member!.friends}'
                                  '/${_member!.enemies}'),
                              SizedBox(height: 20),
                              _returnFaction(),
                              _returnJob(),
                              _returnDiscord(),
                              _returnCompetition(),
                              SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 50),
                Text(
                  'OOPS!',
                  style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        "There was a problem getting this member's profile, please try again later!",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
              ],
            );
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  Widget _returnLife() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 35,
          child: Text('Life'),
        ),
        LinearPercentIndicator(
          padding: EdgeInsets.all(0),
          barRadius: Radius.circular(10),
          width: 150,
          lineHeight: 18,
          progressColor: Colors.blue,
          backgroundColor: Colors.grey,
          center: Text(
            '${_member!.life!.current}',
            style: TextStyle(color: Colors.black),
          ),
          percent: _member!.life!.current! / _member!.life!.maximum! > 1.0
              ? 1.0
              : _member!.life!.current! / _member!.life!.maximum!,
        ),
        _member!.status!.state == "Hospital"
            ? Icon(
                Icons.local_hospital,
                size: 20,
                color: Colors.red,
              )
            : SizedBox.shrink(),
      ],
    );
  }

  Widget _returnLastAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Last action: ',
        ),
        Text(
          _member!.lastAction!.relative == "0 minutes ago" ? 'now' : _member!.lastAction!.relative!,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _returnLastActionColor(_member!.lastAction!.status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Color _returnLastActionColor(String? status) {
    switch (status) {
      case 'Online':
        return Colors.green;
      case 'Idle':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _returnStatus() {
    Color? stateColor;
    if (_member!.status!.color == 'red') {
      stateColor = Colors.red;
    } else if (_member!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (_member!.status!.color == 'blue') {
      stateColor = Colors.blue;
    }

    Widget stateBall = Padding(
      padding: EdgeInsets.only(left: 5, right: 3, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle, border: Border.all(color: Colors.black)),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Status: ${_member!.status!.state}'),
        stateBall,
      ],
    );
  }

  Widget _returnFaction() {
    if (_member!.faction!.factionId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            Text('Faction: ${HtmlParser.fix(_member!.faction!.factionName)}'),
            Text('Position: ${_member!.faction!.position}'),
            Text('Joined: ${_member!.faction!.daysInFaction} days ago'),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _returnJob() {
    if (_member!.job!.companyId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            Text('Company: ${HtmlParser.fix(_member!.job!.companyName)}'),
            Text('Position: ${_member!.job!.job}'),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _returnDiscord() {
    // Discord was introduced in v1.7.1 for targets, reason why we
    // perform a null check
    if (_member!.discord == null) {
      return SizedBox.shrink();
    }

    if (_member!.discord!.discordId == "") {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Discord ID'),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                icon: Icon(Icons.content_copy),
                iconSize: 20,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _member!.discord!.discordId!));
                  BotToast.showText(
                    text: "Your target's Discord ID (${_member!.discord!.discordId}) has been "
                        "copied to the clipboard!",
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green,
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _returnCompetition() {
    if (_member!.competition == null) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'COMPETITION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_member!.competition!.name != null)
            Text(
              '"${_member!.competition!.name}"',
            ),
          if (_member!.competition!.attacks != null)
            Text(
              'Attacks: ${_member!.competition!.attacks}',
            ),
          if (_member!.competition!.image != null)
            Text(
              'Image: ${_member!.competition!.image}',
            ),
          if (_member!.competition!.score != null)
            Text(
              'Score: ${_member!.competition!.score!.ceil()}',
            ),
          if (_member!.competition!.team != null)
            Text(
              'Team: ${_member!.competition!.team}',
            ),
          if (_member!.competition!.text != null)
            Text(
              'Text: ${_member!.competition!.text}',
            ),
          if (_member!.competition!.total != null)
            Text(
              'Total (accumulated): ${_member!.competition!.total}',
            ),
          if (_member!.competition!.treatsCollectedTotal != null)
            Text(
              'Treats collected: ${_member!.competition!.treatsCollectedTotal}',
            ),
          if (_member!.competition!.votes != null)
            Text(
              'Votes: ${_member!.competition!.votes}',
            ),
          if (_member!.competition!.position != null)
            Text(
              'Position: ${_member!.competition!.position}',
            ),
        ],
      ),
    );
  }

  Future _fetchMemberDetails() async {
    dynamic myNewTargetModel = await Get.find<ApiCallerController>().getTarget(playerId: widget.memberId);

    if (myNewTargetModel is TargetModel) {
      _member = myNewTargetModel;
      return;
    }
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "chaining_war";
    Navigator.of(context).pop();
  }
}
