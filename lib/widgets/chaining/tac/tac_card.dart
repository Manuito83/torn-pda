/*
// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/tac_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:torn_pda/models/chaining/tac/tac_target_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/webviews/webview_attack.dart';

class TacCard extends StatefulWidget {
  final TacTarget target;
  final TacProvider tacProvider;

  TacCard({@required this.target, @required this.tacProvider, @required Key key}) : super(key: key);

  @override
  _TacCardState createState() => _TacCardState();
}

class _TacCardState extends State<TacCard> {
  TacTarget _target;

  SettingsProvider _settingsProvider;

  bool _addButtonActive = true;

  final decimalFormat = new NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    _target = widget.target;
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      child: GestureDetector(
        onTap: () {
          _startAttack();
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // LINE 1
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 10, 0),
                child: Row(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _attackIcon(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${_target.username}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          SizedBox(
                            width: 85,
                            child: Text(
                              ' [${_target.id}]',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text('Level ${_target.userLevel}'),
                          SizedBox(
                            height: 22,
                            width: 30,
                            child: _returnAddTargetButton(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // LINE 2
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        _target.optimal
                            ? 'Stats (est.): ${decimalFormat.format(_target.estimatedStats)}'
                            : 'Stats (est.): ${_target.battleStats}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '${_target.rank}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text('FF: ${_target.fairfight ?? 'unk'}', style: TextStyle(fontSize: 12)),
                        Text(' / R: ${_target.respect ?? 'unk'}', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // LINE 3 (optional)
              if (_target.currentLife != null)
                _lifeBar(),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attackIcon() {
    return SizedBox(
      height: 20,
      width: 20,
      child: Image.asset(
        'images/icons/ic_target_account_black_48dp.png',
        color: Colors.red,
        width: 20,
      ),
    );
  }

  Future<void> _startAttack() async {
    var browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        // For app browser, we are going to pass a list of attacks
        // so that we can move to the next one
        var myTargetList = List<TacTarget>.from(widget.tacProvider.targetsList);
        // First, find out where we are in the list
        for (var i = 0; i < myTargetList.length; i++) {
          if (_target.id == myTargetList[i].id) {
            myTargetList.removeRange(0, i);
            break;
          }
        }
        List<String> attacksIds = <String>[];
        List<String> attacksNames = <String>[];
        List<String> attackNotes = <String>[];
        List<String> attacksNotesColor = <String>[];
        for (var tar in myTargetList) {
          attacksIds.add(tar.id.toString());
          attacksNames.add(tar.username);
          _target.optimal
              ? attackNotes.add('Stats (est.): ${decimalFormat.format(tar.estimatedStats)}')
              : attackNotes.add('Stats (est.): ${tar.battleStats}');
          attacksNotesColor.add("");
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => TornWebViewAttack(
              attackIdList: attacksIds,
              attackNameList: attacksNames,
              attackNotesList: attackNotes,
              attackNotesColorList: attacksNotesColor,
              //attacksCallback: _updateSeveralTargets,
              showOnlineFactionWarning: true,
              showNotes: true,
              showBlankNotes: true,
            ),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = 'https://www.torn.com/loader.php?sid='
            'attack&user2ID=${_target.id}';
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
  }

  Widget _returnAddTargetButton() {
    bool existingTarget = false;

    var targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    var targetList = targetsProvider.allTargets;
    for (var tar in targetList) {
      if (tar.playerId.toString() == _target.id) {
        existingTarget = true;
      }
    }

    if (existingTarget) {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 20,
        icon: Icon(
          Icons.remove_circle_outline,
          color: Colors.red,
        ),
        onPressed: () {
          targetsProvider.deleteTargetById(_target.id);
          BotToast.showText(
            text: HtmlParser.fix('Removed ${_target.username}!'),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.orange[900],
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
          // Update the button
          setState(() {});
        },
      );
    } else {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 20,
        icon: _addButtonActive
            ? Icon(
                Icons.add_circle_outline,
                color: Colors.green,
              )
            : SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
        onPressed: _addButtonActive
            ? () async {
                setState(() {
                  _addButtonActive = false;
                });

                // There is no need to pass attackFull because it's very improbable
                // that this target is in our previous attacks. Respect won't be calculated,
                // but it will be much faster
                AddTargetResult tryAddTarget = await targetsProvider.addTarget(
                  targetId: _target.id,
                  attacks: await targetsProvider.getAttacks(),
                );

                if (tryAddTarget.success) {
                  BotToast.showText(
                    text: HtmlParser.fix(
                        'Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}] to your '
                        'main targets list in Torn PDA!'),
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green[700],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                } else if (!tryAddTarget.success) {
                  BotToast.showText(
                    text: HtmlParser.fix('Error adding ${_target.id}. ${tryAddTarget.errorReason}'),
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.red[900],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                }

                // Update the button
                if (mounted) {
                  setState(() {
                    _addButtonActive = true;
                  });
                }
              }
            : null,
      );
    }
  }

  Widget _lifeBar() {
    Color lifeBarColor = Colors.green;
    Widget hospitalWarning = SizedBox.shrink();
    Widget abroadWarning = SizedBox.shrink();
    String lifeText = _target.currentLife.toString();

    if (_target.hospital != null && _target.hospital) {
        lifeBarColor = Colors.red[300];
        hospitalWarning = Icon(
          Icons.local_hospital,
          size: 20,
          color: Colors.red,
        );
    }

    if (_target.abroad != null && _target.abroad) {
      abroadWarning = Icon(
        Icons.airplanemode_active_outlined,
        size: 20,
        color: Colors.blue,
      );
    }

    // Found players in federal jail with a higher life than their maximum. Correct it if it's the
    // case to avoid issues with percentage bar
    double lifePercentage;
    if (_target.currentLife / _target.maxLife > 1) {
      lifePercentage = 1;
    } else if (_target.currentLife / _target.maxLife > 1) {
      lifePercentage = 0;
    } else {
      lifePercentage = _target.currentLife / _target.maxLife;
    }

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Life ',
            style: TextStyle(fontSize: 12),
          ),
          LinearPercentIndicator(
                    padding: null,
                              barRadius: Radius.circular(10),
            width: 100,
            lineHeight: 12,
            progressColor: lifeBarColor,
            center: Text(
              lifeText,
              style: TextStyle(color: Colors.black, fontSize: 10),
            ),
            percent: lifePercentage,
          ),
          hospitalWarning,
          abroadWarning,
        ],
      ),
    );
  }
}
*/
