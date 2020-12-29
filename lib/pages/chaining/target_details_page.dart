import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class TargetDetailsPage extends StatefulWidget {
  final TargetModel target;

  TargetDetailsPage({@required this.target});

  @override
  _TargetDetailsPageState createState() => _TargetDetailsPageState();
}

class _TargetDetailsPageState extends State<TargetDetailsPage> {
  UserDetailsProvider _userDetails;
  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? Colors.blueGrey
          : Colors.grey[900],
      child: SafeArea(
        top: _settingsProvider.appBarTop ? false : true,
        bottom: true,
        child: Scaffold(
          drawer: Drawer(),
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.target.name} [${widget.target.playerId}]',
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
                                Clipboard.setData(
                                    ClipboardData(text: widget.target.playerId.toString()));
                                BotToast.showText(
                                  text: "Your target's ID [${widget.target.playerId}] has been "
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
                    Text('${widget.target.rank}'),
                    SizedBox(height: 20),
                    Text('Level: ${widget.target.level}'),
                    Text('Gender: ${widget.target.gender}'),
                    Text('Age: ${widget.target.age} days'),
                    SizedBox(height: 20),
                    _returnLife(),
                    SizedBox(height: 5),
                    _returnLastAction(),
                    SizedBox(height: 5),
                    _returnStatus(),
                    SizedBox(height: 20),
                    Text('Awards: ${widget.target.awards} '
                        '(you have ${_userDetails.myUser.awards})'),
                    SizedBox(height: 20),
                    Text('Donator: ${widget.target.donator == 0 ? 'NO' : 'YES'}'),
                    Text('Friends/Enemies: ${widget.target.friends}'
                        '/${widget.target.enemies}'),
                    SizedBox(height: 20),
                    _returnFaction(),
                    SizedBox(height: 20),
                    _returnJob(),
                    SizedBox(height: 20),
                    _returnDiscord(),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text('${widget.target.name}'),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
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
          width: 150,
          lineHeight: 18,
          progressColor: Colors.blue,
          backgroundColor: Colors.grey,
          center: Text(
            '${widget.target.life.current}',
            style: TextStyle(color: Colors.black),
          ),
          percent: widget.target.life.current / widget.target.life.maximum > 1.0
              ? 1.0
              : widget.target.life.current / widget.target.life.maximum,
        ),
        widget.target.status.state == "Hospital"
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
          widget.target.lastAction.relative == "0 minutes ago"
              ? 'now'
              : widget.target.lastAction.relative,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _returnLastActionColor(widget.target.lastAction.status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Color _returnLastActionColor(String status) {
    switch (status) {
      case 'Online':
        return Colors.green;
        break;
      case 'Idle':
        return Colors.orange;
        break;
      default:
        return Colors.grey;
    }
  }

  Widget _returnStatus() {
    Color stateColor;
    if (widget.target.status.color == 'red') {
      stateColor = Colors.red;
    } else if (widget.target.status.color == 'green') {
      stateColor = Colors.green;
    } else if (widget.target.status.color == 'blue') {
      stateColor = Colors.blue;
    }

    Widget stateBall = Padding(
      padding: EdgeInsets.only(left: 5, right: 3, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
            color: stateColor, shape: BoxShape.circle, border: Border.all(color: Colors.black)),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Status: ${widget.target.status.state}'),
        stateBall,
      ],
    );
  }

  Widget _returnFaction() {
    if (widget.target.faction.factionId != 0) {
      return Column(
        children: <Widget>[
          Text('Faction: ${HtmlParser.fix(widget.target.faction.factionName)}'),
          Text('Position: ${widget.target.faction.position}'),
          Text('Joined: ${widget.target.faction.daysInFaction} days ago'),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _returnJob() {
    if (widget.target.job.companyId != 0) {
      return Column(
        children: <Widget>[
          Text('Company: ${HtmlParser.fix(widget.target.job.companyName)}'),
          Text('Position: ${widget.target.job.position}'),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _returnDiscord() {
    // Discord was introduced in v1.7.1 for targets, reason why we
    // perform a null check
    if (widget.target.discord == null) {
      return SizedBox.shrink();
    }

    if (widget.target.discord.discordId == "") {
      return SizedBox.shrink();
    }

    return Row(
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
                Clipboard.setData(ClipboardData(text: widget.target.discord.discordId));
                BotToast.showText(
                  text: "Your target's Discord ID (${widget.target.discord.discordId}) has been "
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
    );
  }
}
