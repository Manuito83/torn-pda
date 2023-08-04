// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class TargetDetailsPage extends StatefulWidget {
  final TargetModel? target;

  const TargetDetailsPage({required this.target});

  @override
  _TargetDetailsPageState createState() => _TargetDetailsPageState();
}

class _TargetDetailsPageState extends State<TargetDetailsPage> {
  late UserDetailsProvider _userDetails;
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userDetails = Provider.of<UserDetailsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "target_details";
    _settingsProvider.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "target_details") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
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
          drawer: const Drawer(),
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
                            '${widget.target!.name} [${widget.target!.playerId}]',
                            style: const TextStyle(
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
                                icon: const Icon(Icons.content_copy),
                                iconSize: 20,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: widget.target!.playerId.toString()));
                                  BotToast.showText(
                                    text: "Your target's ID [${widget.target!.playerId}] has been "
                                        "copied to the clipboard!",
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.green,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text('${widget.target!.rank}'),
                      const SizedBox(height: 20),
                      Text('Level: ${widget.target!.level}'),
                      Text('Gender: ${widget.target!.gender}'),
                      Text('Age: ${widget.target!.age} days'),
                      const SizedBox(height: 20),
                      _returnLife(),
                      const SizedBox(height: 5),
                      _returnLastAction(),
                      const SizedBox(height: 5),
                      _returnStatus(),
                      const SizedBox(height: 20),
                      Text('Awards: ${widget.target!.awards} '
                          '(you have ${_userDetails.basic!.awards})'),
                      const SizedBox(height: 20),
                      Text('Donator: ${widget.target!.donator == 0 ? 'NO' : 'YES'}'),
                      Text('Friends/Enemies: ${widget.target!.friends}'
                          '/${widget.target!.enemies}'),
                      const SizedBox(height: 20),
                      _returnFaction(),
                      _returnJob(),
                      _returnDiscord(),
                      _returnCompetition(),
                      const SizedBox(height: 50),
                    ],
                  ),
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
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
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
        const SizedBox(
          width: 35,
          child: Text('Life'),
        ),
        LinearPercentIndicator(
          padding: const EdgeInsets.all(0),
          barRadius: const Radius.circular(10),
          width: 150,
          lineHeight: 18,
          progressColor: Colors.blue,
          backgroundColor: Colors.grey,
          center: Text(
            '${widget.target!.life!.current}',
            style: const TextStyle(color: Colors.black),
          ),
          percent: widget.target!.life!.current! / widget.target!.life!.maximum! > 1.0
              ? 1.0
              : widget.target!.life!.current! / widget.target!.life!.maximum!,
        ),
        if (widget.target!.status!.state == "Hospital") const Icon(
                Icons.local_hospital,
                size: 20,
                color: Colors.red,
              ) else const SizedBox.shrink(),
      ],
    );
  }

  Widget _returnLastAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Last action: ',
        ),
        Text(
          widget.target!.lastAction!.relative == "0 minutes ago" ? 'now' : widget.target!.lastAction!.relative!,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _returnLastActionColor(widget.target!.lastAction!.status),
              shape: BoxShape.circle,
              border: Border.all(),
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
    if (widget.target!.status!.color == 'red') {
      stateColor = Colors.red;
    } else if (widget.target!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (widget.target!.status!.color == 'blue') {
      stateColor = Colors.blue;
    }

    final Widget stateBall = Padding(
      padding: const EdgeInsets.only(left: 5, right: 3, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle, border: Border.all()),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Status: ${widget.target!.status!.state}'),
        stateBall,
      ],
    );
  }

  Widget _returnFaction() {
    if (widget.target!.faction!.factionId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            Text('Faction: ${HtmlParser.fix(widget.target!.faction!.factionName)}'),
            Text('Position: ${widget.target!.faction!.position}'),
            Text('Joined: ${widget.target!.faction!.daysInFaction} days ago'),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnJob() {
    if (widget.target!.job!.companyId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            Text('Company: ${HtmlParser.fix(widget.target!.job!.companyName)}'),
            Text('Position: ${widget.target!.job!.job}'),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnDiscord() {
    // Discord was introduced in v1.7.1 for targets, reason why we
    // perform a null check
    if (widget.target!.discord == null) {
      return const SizedBox.shrink();
    }

    if (widget.target!.discord!.discordId == "") {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Discord ID'),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                icon: const Icon(Icons.content_copy),
                iconSize: 20,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.target!.discord!.discordId!));
                  BotToast.showText(
                    text: "Your target's Discord ID (${widget.target!.discord!.discordId}) has been "
                        "copied to the clipboard!",
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green,
                    duration: const Duration(seconds: 5),
                    contentPadding: const EdgeInsets.all(10),
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
    if (widget.target!.competition == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'COMPETITION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.target!.competition!.name != null)
            Text(
              '"${widget.target!.competition!.name}"',
            ),
          if (widget.target!.competition!.attacks != null)
            Text(
              'Attacks: ${widget.target!.competition!.attacks}',
            ),
          if (widget.target!.competition!.image != null)
            Text(
              'Image: ${widget.target!.competition!.image}',
            ),
          if (widget.target!.competition!.score != null)
            Text(
              'Score: ${widget.target!.competition!.score!.ceil()}',
            ),
          if (widget.target!.competition!.team != null)
            Text(
              'Team: ${widget.target!.competition!.team}',
            ),
          if (widget.target!.competition!.text != null)
            Text(
              'Text: ${widget.target!.competition!.text}',
            ),
          if (widget.target!.competition!.total != null)
            Text(
              'Total (accumulated): ${widget.target!.competition!.total}',
            ),
          if (widget.target!.competition!.treatsCollectedTotal != null)
            Text(
              'Treats collected: ${widget.target!.competition!.treatsCollectedTotal}',
            ),
          if (widget.target!.competition!.votes != null)
            Text(
              'Votes: ${widget.target!.competition!.votes}',
            ),
          if (widget.target!.competition!.position != null)
            Text(
              'Position: ${widget.target!.competition!.position}',
            ),
        ],
      ),
    );
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "chaining_targets";
    Navigator.of(context).pop();
  }
}
