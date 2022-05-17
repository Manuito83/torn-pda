// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';
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
                children: <Widget>[
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
}
