import 'dart:async';
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/pages/chaining/target_details_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/webviews/webview_attack.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notes_dialog.dart';

class TargetCard extends StatefulWidget {
  final TargetModel targetModel;

  TargetCard({@required this.targetModel});

  @override
  _TargetCardState createState() => _TargetCardState();
}

class _TargetCardState extends State<TargetCard> {
  TargetModel _target;
  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;

  Timer _ticker;

  String _lastUpdated;

  @override
  void initState() {
    super.initState();
    _ticker = new Timer.periodic(Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _target = widget.targetModel;
    _returnLastUpdated();
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      actions: <Widget>[
        IconSlideAction(
            caption: 'Remove',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () {
              Provider.of<TargetsProvider>(context, listen: false).deleteTarget(_target);
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted ${_target.name}!'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.orange,
                    onPressed: () {
                      _targetsProvider.restoredDeleted();
                    },
                  ),
                ),
              );
            }),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Card(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: _borderColor(), width: 1.5),
              borderRadius: BorderRadius.circular(4.0)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // LINE 1
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
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
                          width: 95,
                          child: Text(
                            '${_target.name}',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 5),
                              OpenContainer(
                                transitionDuration: Duration(milliseconds: 500),
                                transitionType: ContainerTransitionType.fadeThrough,
                                openBuilder: (BuildContext context, VoidCallback _) {
                                  return TargetDetailsPage(target: _target);
                                },
                                closedElevation: 0,
                                closedShape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(56 / 2),
                                  ),
                                ),
                                closedColor: Colors.transparent,
                                closedBuilder: (BuildContext context, VoidCallback openContainer) {
                                  return SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 5),
                              _factionIcon(),
                            ],
                          ),
                          Text(
                            'Lvl ${_target.level}',
                          ),
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: _refreshIcon(),
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
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    _returnRespect(_target.respectGain),
                    _returnHealth(_target),
                  ],
                ),
              ),
              // LINE 3
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(17, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _returnStatusColor(_target.lastAction.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            'Action: ',
                          ),
                        ),
                        Text(
                          _target.lastAction.relative == "0 minutes ago"
                              ? 'now'
                              : _target.lastAction.relative.replaceAll(' ago', ''),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text('Updated $_lastUpdated'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // LINE 4
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                        padding: EdgeInsets.all(0),
                        iconSize: 20,
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showNotesDialog();
                        },
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(start: 8),
                        child: Row(
                          children: <Widget>[
                            Text('Notes: '),
                            Flexible(
                              child: Text(
                                '${_target.personalNote}',
                                style: TextStyle(
                                  color: _returnTargetNoteColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
      child: IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 20,
        icon: Image.asset(
          'images/icons/ic_target_account_black_48dp.png',
          color: Colors.red,
        ),
        onPressed: () async {
          var browserType = _settingsProvider.currentBrowser;
          switch (browserType) {
            case BrowserSetting.app:
              // For app browser, we are going to pass a list of attacks
              // so that we can move to the next one
              var myTargetList = List<TargetModel>.from(_targetsProvider.allTargets);
              // First, find out where we are in the list
              for (var i = 0; i < myTargetList.length; i++) {
                if (_target.playerId == myTargetList[i].playerId) {
                  myTargetList.removeRange(0, i);
                  break;
                }
              }
              List<String> attacksIds = List<String>();
              List<String> attacksNames = List<String>();
              for (var tar in myTargetList) {
                attacksIds.add(tar.playerId.toString());
                attacksNames.add(tar.name);
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => TornWebViewAttack(
                    attackIdList: attacksIds,
                    attackNameList: attacksNames,
                    attacksCallback: _updateSeveralTargets,
                    userKey: _userProvider.myUser.userApiKey,
                  ),
                ),
              );
              break;
            case BrowserSetting.external:
              var url = 'https://www.torn.com/loader.php?sid='
                  'attack&user2ID=${_target.playerId}';
              if (await canLaunch(url)) {
                await launch(url, forceSafariVC: false);
              }
              break;
          }
        },
      ),
    );
  }

  Widget _refreshIcon() {
    if (_target.isUpdating) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: CircularProgressIndicator(),
      );
    } else {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 20,
        icon: Icon(Icons.refresh),
        onPressed: () async {
          _updateThisTarget();
        },
      );
    }
  }

  Widget _factionIcon() {
    if (_target.hasFaction) {
      Color borderColor = Colors.transparent;
      Color iconColor = _themeProvider.mainText;
      if (_target.faction.factionId == _userProvider.myUser.faction.factionId) {
        borderColor = iconColor = Colors.green[500];
      }

      void showFactionToast() {
        if (_target.faction.factionId == _userProvider.myUser.faction.factionId) {
          BotToast.showText(
            text: HtmlParser.fix("${_target.name} belongs to your same faction "
                "(${_target.faction.factionName}) as "
                "${_target.faction.position}"),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
        } else {
          BotToast.showText(
            text: HtmlParser.fix("${_target.name} belongs to faction "
                "${_target.faction.factionName} as "
                "${_target.faction.position}"),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[600],
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
        }
      }

      Widget factionIcon = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              showFactionToast();
            },
            child: Padding(
              padding: EdgeInsets.all(2),
              child: ImageIcon(
                AssetImage('images/icons/faction.png'),
                size: 12,
                color: iconColor,
              ),
            ),
          ),
        ),
      );
      return factionIcon;
    } else {
      return SizedBox.shrink();
    }
  }

  Color _borderColor() {
    if (_target.justUpdatedWithSuccess) {
      return Colors.green;
    } else if (_target.justUpdatedWithError) {
      return Colors.red;
    } else {
      return Colors.transparent;
    }
  }

  Widget _returnRespect(double respect) {
    TextSpan respectResult;

    if (respect == -1) {
      respectResult = TextSpan(
        text: 'unknown',
        style: TextStyle(
          color: _themeProvider.mainText,
        ),
      );
    } else if (respect == 0) {
      if (_target.userWonOrDefended) {
        respectResult = TextSpan(
          text: '0 (defended)',
          style: TextStyle(
            color: _themeProvider.mainText,
          ),
        );
      } else {
        respectResult = TextSpan(
          text: 'Lost',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } else {
      respectResult = TextSpan(
        text: respect.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _themeProvider.mainText,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: 'Respect: ',
            style: TextStyle(
              color: _themeProvider.mainText,
            ),
          ),
          respectResult,
        ],
      ),
    );
  }

  Widget _returnHealth(TargetModel target) {
    Color lifeBarColor = Colors.green;
    Widget hospitalWarning = SizedBox.shrink();
    if (target.status.state == "Hospital") {
      lifeBarColor = Colors.red[300];
      hospitalWarning = Icon(
        Icons.local_hospital,
        size: 20,
        color: Colors.red,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Life ',
        ),
        LinearPercentIndicator(
          width: 100,
          lineHeight: 16,
          progressColor: lifeBarColor,
          center: Text(
            '${_target.life.current}',
            style: TextStyle(color: Colors.black),
          ),
          percent: (_target.life.current / _target.life.maximum),
        ),
        hospitalWarning,
      ],
    );
  }

  Color _returnStatusColor(String status) {
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

  void _returnLastUpdated() {
    var timeDifference = DateTime.now().difference(_target.lastUpdated);
    if (timeDifference.inMinutes < 1) {
      _lastUpdated = 'now';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      _lastUpdated = '1 minute ago';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      _lastUpdated = '${timeDifference.inMinutes} minutes ago';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      _lastUpdated = '1 hour ago';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      _lastUpdated = '${timeDifference.inHours} hours ago';
    } else if (timeDifference.inDays == 1) {
      _lastUpdated = '1 day ago';
    } else {
      _lastUpdated = '${timeDifference.inDays} days ago';
    }
  }

  Color _returnTargetNoteColor() {
    switch (_target.personalNoteColor) {
      case 'red':
        return Colors.red;
        break;
      case 'blue':
        return Colors.blue;
        break;
      case 'green':
        return Colors.green;
        break;
      default:
        return _themeProvider.mainText;
        break;
    }
  }

  Future<void> _showNotesDialog() {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0.0,
            backgroundColor: Colors.transparent,
            content: SingleChildScrollView(
              child: PersonalNotesDialog(
                targetModel: _target,
                noteType: PersonalNoteType.target,
              ),
            ),
          );
        });
  }

  void _updateThisTarget() async {
    bool updateWorked = await _targetsProvider.updateTarget(_target);
    if (updateWorked) {
    } else {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error updating ${_target.name}!',
          ),
        ),
      );
    }
  }

  void _updateSeveralTargets(List<String> attackedIds) async {
    await _targetsProvider.updateTargetsAfterAttacks(attackedIds);
  }

  void _timerUpdateInformation() {
    setState(() {
      _returnLastUpdated();
    });
  }
}
