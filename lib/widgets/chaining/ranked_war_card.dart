// Dart imports:

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

import '../../providers/targets_provider.dart';
import '../../providers/war_controller.dart';

enum RankedWarStatus {
  active,
  upcoming,
  finished,
}

class RankedWarCard extends StatefulWidget {
  final RankedWar rankedWar;
  final RankedWarStatus status;
  final String warId;

  // Key is needed to update at least the hospital counter individually
  RankedWarCard({
    @required this.rankedWar,
    @required this.status,
    @required this.warId,
    @required Key key,
  }) : super(key: key);

  @override
  _RankedWarCardState createState() => _RankedWarCardState();
}

class _RankedWarCardState extends State<RankedWarCard> {
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  WebViewProvider _webViewProvider;

  List<Faction> _factions = <Faction>[];
  List<String> _factionsIds = <String>[];

  String _titleString = "";
  String _finishedString = "";

  WarController _w = Get.put(WarController());
  bool _factionLeftAdded = false;
  bool _factionRightAdded = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _webViewProvider = context.read<WebViewProvider>();

    widget.rankedWar.factions.forEach((key, value) {
      _factions.add(value);
      _factionsIds.add(key);
    });

    _getTimeString();
    _checkFactionLeftAdded();
    _checkFactionRightAdded();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // DETAILS
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 0),
              child: Text(
                _titleString,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.brown[300],
                ),
              ),
            ),
            // FACTIONS
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_factionLeftAdded)
                    GestureDetector(
                      child: Icon(Icons.remove_circle_outline, color: Colors.red),
                      onTap: () async {
                        removeFaction(left: true);
                      },
                    )
                  else
                    GestureDetector(
                      child: Icon(Icons.add_circle_outline, color: Colors.green),
                      onTap: () async {
                        await addFaction(left: true);
                      },
                    ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _launchBrowser(factionId: _factionsIds[0], dialog: true);
                      },
                      onLongPress: () {
                        _launchBrowser(factionId: _factionsIds[0], dialog: false);
                      },
                      child: Column(
                        children: [
                          Text(
                            HtmlParser.fix(_factions[0].name),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            "Score: ${_factions[0].score}",
                            style: TextStyle(
                              fontSize: 11,
                              color: _factions[0].score > _factions[1].score
                                  ? Colors.green
                                  : _factions[0].score == _factions[1].score
                                      ? _themeProvider.mainText
                                      : Colors.red,
                            ),
                          ),
                          Text(
                            "Chain: ${_factions[0].chain}",
                            style: TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _launchBrowser(factionId: _factionsIds[1], dialog: true);
                      },
                      onLongPress: () {
                        _launchBrowser(factionId: _factionsIds[1], dialog: false);
                      },
                      child: Column(
                        children: [
                          Text(
                            HtmlParser.fix(_factions[1].name),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            "Score: ${_factions[1].score}",
                            style: TextStyle(
                              fontSize: 11,
                              color: _factions[1].score > _factions[0].score
                                  ? Colors.green
                                  : _factions[1].score == _factions[0].score
                                      ? _themeProvider.mainText
                                      : Colors.red,
                            ),
                          ),
                          Text(
                            "Chain: ${_factions[1].chain}",
                            style: TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_factionRightAdded)
                    GestureDetector(
                      child: Icon(Icons.remove_circle_outline, color: Colors.red),
                      onTap: () async {
                        removeFaction(left: false);
                      },
                    )
                  else
                    GestureDetector(
                      child: Icon(Icons.add_circle_outline, color: Colors.green),
                      onTap: () async {
                        await addFaction(left: false);
                      },
                    ),
                ],
              ),
            ),
            // PROGRESS BAR
            if (widget.status == RankedWarStatus.active)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _progressBar(),
              )
            else if (widget.status == RankedWarStatus.finished)
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _winner(),
                      Text(_finishedString,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.brown[300],
                          )),
                    ],
                  ))
            else
              SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Future<void> addFaction({bool left}) async {
    int side = left ? 0 : 1;

    final targets = context.read<TargetsProvider>().allTargets;
    final addFactionResult = await _w.addFaction(_factionsIds[side], targets);

    Color messageColor = Colors.green;
    if (addFactionResult.isEmpty || addFactionResult == "error_existing") {
      messageColor = Colors.orange[700];
    }

    int time = 5;
    String message = 'Added $addFactionResult [${_factionsIds[side]}]!'
        '\n\nUpdate members/global to get more information (life, stats).';

    if (addFactionResult.isEmpty) {
      message = 'Error adding ${_factionsIds[side]}';
      time = 3;
    } else if (addFactionResult == "error_existing") {
      message = 'Faction ${_factionsIds[side]} is already in the list!';
      time = 3;
    } else {
      setState(() {
        left ? _factionLeftAdded = true : _factionRightAdded = true;
      });
    }

    BotToast.showText(
      clickClose: true,
      text: HtmlParser.fix(message),
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: messageColor,
      duration: Duration(seconds: time),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  void removeFaction({bool left}) {
    int side = left ? 0 : 1;

    _w.removeFaction(int.parse(_factionsIds[0]));
    setState(() {
      left ? _factionLeftAdded = false : _factionRightAdded = false;
    });

    BotToast.showText(
      clickClose: true,
      text: HtmlParser.fix("Removed ${_factions[side].name} from War page!"),
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green,
      duration: Duration(seconds: 3),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Widget _progressBar() {
    int progress = (_factions[0].score - _factions[1].score).abs();
    double percentage = progress * 100 / widget.rankedWar.war.target;

    return Column(
      children: [
        Text(
          "Progress: $progress/${widget.rankedWar.war.target}",
          style: TextStyle(
            fontSize: 11,
          ),
        ),
        LinearPercentIndicator(
          padding: null,
          barRadius: Radius.circular(10),
          alignment: MainAxisAlignment.center,
          width: 150,
          lineHeight: 12,
          progressColor: Colors.green,
          backgroundColor: Colors.grey,
          center: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.black),
            ),
          ),
          percent: percentage / 100 > 1.0 ? 1.0 : percentage / 100,
        ),
      ],
    );
  }

  Widget _winner() {
    String winner = "";
    if (widget.rankedWar.war.winner.toString() == _factionsIds[0]) {
      winner = HtmlParser.fix(_factions[0].name);
    } else {
      winner = HtmlParser.fix(_factions[1].name);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Winner: ",
          style: TextStyle(
            fontSize: 11,
          ),
        ),
        Text(
          "$winner",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _launchBrowser({@required factionId, @required dialog}) {
    String url = "https://www.torn.com/factions.php?step=profile&ID=$factionId";
    _webViewProvider.openBrowserPreference(
      context: context,
      url: url,
      useDialog: dialog,
    );
  }

  void _getTimeString() {
    TimeFormatSetting timePrefs = _settingsProvider.currentTimeFormat;
    DateFormat dateFormatter;
    DateFormat hourFormatter;
    switch (timePrefs) {
      case TimeFormatSetting.h24:
        dateFormatter = DateFormat('dd MMM');
        hourFormatter = DateFormat('HH:mm');
        break;
      case TimeFormatSetting.h12:
        dateFormatter = DateFormat('MMM dd');
        hourFormatter = DateFormat('hh:mm a');
        break;
    }

    if (widget.status == RankedWarStatus.active) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(widget.rankedWar.war.start * 1000);
      _titleString += "War #${widget.warId}, started on ${dateFormatter.format(date)} @ ${hourFormatter.format(date)}";
    } else if (widget.status == RankedWarStatus.upcoming) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(widget.rankedWar.war.start * 1000);
      _titleString += "War #${widget.warId}, starts on ${dateFormatter.format(date)} @ ${hourFormatter.format(date)}";
    } else if (widget.status == RankedWarStatus.finished) {
      DateTime dateStart = DateTime.fromMillisecondsSinceEpoch(widget.rankedWar.war.start * 1000);
      DateTime dateEnd = DateTime.fromMillisecondsSinceEpoch(widget.rankedWar.war.end * 1000);
      _titleString +=
          "War #${widget.warId}, started on ${dateFormatter.format(dateStart)} @ ${hourFormatter.format(dateStart)}";
      _finishedString = "Finished on ${dateFormatter.format(dateEnd)} @ ${hourFormatter.format(dateEnd)}";
    }
  }

  _checkFactionLeftAdded() {
    for (var f in _w.factions) {
      if (f.id.toString() == _factionsIds[0]) {
        setState(() {
          _factionLeftAdded = true;
        });
      }
    }
  }

  _checkFactionRightAdded() {
    for (var f in _w.factions) {
      if (f.id.toString() == _factionsIds[1]) {
        setState(() {
          _factionRightAdded = true;
        });
      }
    }
  }
}
