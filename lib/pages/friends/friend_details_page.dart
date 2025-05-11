// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class FriendDetailsPage extends StatefulWidget {
  final FriendModel? friend;

  const FriendDetailsPage({required this.friend});

  @override
  FriendDetailsPageState createState() => FriendDetailsPageState();
}

class FriendDetailsPageState extends State<FriendDetailsPage> {
  late UserDetailsProvider _userDetails;
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userDetails = Provider.of<UserDetailsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "friend_details";
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "friend_details") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        right: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
        left: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
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
                            '${widget.friend!.name} [${widget.friend!.playerId}]',
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
                                  Clipboard.setData(ClipboardData(text: widget.friend!.playerId.toString()));
                                  BotToast.showText(
                                    text: "Your friend's ID [${widget.friend!.playerId}] has been "
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
                      Text('${widget.friend!.rank}'),
                      const SizedBox(height: 20),
                      Text('Level: ${widget.friend!.level}'),
                      Text('Gender: ${widget.friend!.gender}'),
                      Text('Age: ${widget.friend!.age} days'),
                      const SizedBox(height: 20),
                      _returnLife(),
                      const SizedBox(height: 5),
                      _returnLastAction(),
                      const SizedBox(height: 5),
                      _returnStatus(),
                      const SizedBox(height: 20),
                      Text('Awards: ${widget.friend!.awards} '
                          '(you have ${_userDetails.basic!.awards})'),
                      const SizedBox(height: 20),
                      Text('Donator: ${widget.friend!.donator == 0 ? 'NO' : 'YES'}'),
                      Text('Friends/Enemies: ${widget.friend!.friends}'
                          '/${widget.friend!.enemies}'),
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
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text('${widget.friend!.name}'),
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
            '${widget.friend!.life!.current}',
            style: const TextStyle(color: Colors.black),
          ),
          percent: widget.friend!.life!.current! / widget.friend!.life!.maximum! > 1.0
              ? 1.0
              : widget.friend!.life!.current! / widget.friend!.life!.maximum!,
        ),
        if (widget.friend!.status!.state == "Hospital")
          const Icon(
            Icons.local_hospital,
            size: 20,
            color: Colors.red,
          )
        else
          const SizedBox.shrink(),
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
          widget.friend!.lastAction!.relative == "0 minutes ago" ? 'now' : widget.friend!.lastAction!.relative!,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _returnLastActionColor(widget.friend!.lastAction!.status),
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
    if (widget.friend!.status!.color == 'red') {
      stateColor = Colors.red;
    } else if (widget.friend!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (widget.friend!.status!.color == 'blue') {
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
        Text('Status: ${widget.friend!.status!.state}'),
        stateBall,
      ],
    );
  }

  Widget _returnFaction() {
    if (widget.friend!.faction!.factionId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            Text('Faction: ${HtmlParser.fix(widget.friend!.faction!.factionName)}'),
            Text('Position: ${widget.friend!.faction!.position}'),
            Text('Joined: ${widget.friend!.faction!.daysInFaction} days ago'),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnJob() {
    if (widget.friend!.job!.companyId != 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: <Widget>[
            Text('Company: ${HtmlParser.fix(widget.friend!.job!.companyName)}'),
            Text('Position: ${widget.friend!.job!.job}'),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnDiscord() {
    if (widget.friend!.discord!.discordId != "") {
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
                    Clipboard.setData(ClipboardData(text: widget.friend!.discord!.discordId!));
                    BotToast.showText(
                      text: "Your friend's Discord ID (${widget.friend!.discord!.discordId}) has been "
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
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _returnCompetition() {
    if (widget.friend!.competition == null) {
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
          if (widget.friend!.competition!.name != null)
            Text(
              '"${widget.friend!.competition!.name}"',
            ),
          if (widget.friend!.competition!.attacks != null)
            Text(
              'Attacks: ${widget.friend!.competition!.attacks}',
            ),
          if (widget.friend!.competition!.image != null)
            Text(
              'Image: ${widget.friend!.competition!.image}',
            ),
          if (widget.friend!.competition!.score != null)
            Text(
              'Score: ${widget.friend!.competition!.score!.ceil()}',
            ),
          if (widget.friend!.competition!.team != null)
            Text(
              'Team: ${widget.friend!.competition!.team}',
            ),
          if (widget.friend!.competition!.text != null)
            Text(
              'Text: ${widget.friend!.competition!.text}',
            ),
          if (widget.friend!.competition!.total != null)
            Text(
              'Total (accumulated): ${widget.friend!.competition!.total}',
            ),
          if (widget.friend!.competition!.treatsCollectedTotal != null)
            Text(
              'Treats collected: ${widget.friend!.competition!.treatsCollectedTotal}',
            ),
          if (widget.friend!.competition!.votes != null)
            Text(
              'Votes: ${widget.friend!.competition!.votes}',
            ),
          if (widget.friend!.competition!.position != null)
            Text(
              'Position: ${widget.friend!.competition!.position}',
            ),
        ],
      ),
    );
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "friends";
    Navigator.of(context).pop();
  }
}
