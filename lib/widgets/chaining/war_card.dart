// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/webviews/webview_attack.dart';
import '../notes_dialog.dart';

class WarCard extends StatefulWidget {
  final Member memberModel;
  final int totalCards;

  // Key is needed to update at least the hospital counter individually
  WarCard({
    @required this.memberModel,
    @required Key key,
    @required this.totalCards,
  }) : super(key: key);

  @override
  _WarCardState createState() => _WarCardState();
}

class _WarCardState extends State<WarCard> {
  Member _member;
  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;

  Timer _updatedTicker;
  Timer _lifeTicker;

  String _currentLifeString = "";
  String _lastUpdatedString;
  int _lastUpdatedMinutes;

  bool _addButtonActive = true;

  final WarController _w = Get.put(WarController());

  @override
  void initState() {
    super.initState();
    _updatedTicker = new Timer.periodic(Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
  }

  @override
  void dispose() {
    _updatedTicker?.cancel();
    _lifeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _member = widget.memberModel;
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
            // TODO
          },
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        child: GestureDetector(
          onTap: () {
            _startAttack();
          },
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(color: _borderColor(), width: 1.5), borderRadius: BorderRadius.circular(4.0)),
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
                            width: 95,
                            child: Text(
                              '${_member.name}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            SizedBox(width: 3),
                            _factionIcon(),
                            SizedBox(width: 3),
                            Text(
                              'L${_member.level}',
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  height: 22,
                                  width: 30,
                                  child: _addAsTargetButton(),
                                ),
                                SizedBox(width: 5),
                                SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: _refreshIcon(),
                                ),
                              ],
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
                      _returnRespectFF(_member.respectGain, _member.fairFight),
                      _returnHealth(_member),
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
                          _travelIcon(),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _returnStatusColor(_member.lastAction.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              _member.lastAction.relative == "0 minutes ago"
                                  ? 'now'
                                  : _member.lastAction.relative.replaceAll(' ago', ''),
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Icon(Icons.refresh, size: 14),
                            Text(
                              ' $_lastUpdatedString',
                              style: TextStyle(
                                color: _lastUpdatedMinutes <= 120 ? _themeProvider.mainText : Colors.deepOrangeAccent,
                                fontStyle: _lastUpdatedMinutes <= 120 ? FontStyle.normal : FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // LINE 4
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(10, 5, 15, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 30,
                              height: 20,
                              child: IconButton(
                                padding: EdgeInsets.all(0),
                                iconSize: 20,
                                icon: Icon(
                                  MdiIcons.notebookEditOutline,
                                  color: _returnTargetNoteColor(),
                                  size: 18,
                                ),
                                onPressed: () {
                                  _showNotesDialog();
                                },
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Notes: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            Flexible(
                              child: Text(
                                '${_member.personalNote}',
                                style: TextStyle(
                                  color: _returnTargetNoteColor(),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(
                          '${_w.cardsOrderedIds.indexOf(_member.memberId) + 1}'
                          '/${widget.totalCards}',
                          style: TextStyle(
                            color: Colors.brown[400],
                            fontSize: 11,
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

  Widget _refreshIcon() {
    if (_member.isUpdating) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: CircularProgressIndicator(),
      );
    } else {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 22,
        icon: Icon(Icons.refresh),
        onPressed: () async {
          _updateThisMember();
        },
      );
    }
  }

  Widget _addAsTargetButton() {
    bool existingTarget = false;

    var targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    var targetList = targetsProvider.allTargets;
    for (var tar in targetList) {
      if (tar.playerId == _member.memberId) {
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
          targetsProvider.deleteTargetById(_member.memberId.toString());
          BotToast.showText(
            text: HtmlParser.fix('Removed ${_member.name}!'),
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
                  targetId: _member.memberId.toString(),
                  attacks: await targetsProvider.getAttacks(),
                );

                if (tryAddTarget.success) {
                  BotToast.showText(
                    text: HtmlParser.fix('Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}] to your '
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
                    text: HtmlParser.fix('Error adding ${_member.memberId}. ${tryAddTarget.errorReason}'),
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

  Widget _factionIcon() {
    Color borderColor = Colors.grey;
    List<double> dashPattern = [1, 2];
    if (_member.factionLeader == _member.memberId) {
      borderColor = Colors.red[500];
      dashPattern = [1, 0];
    } else if (_member.factionColeader == _member.memberId) {
      borderColor = Colors.orange[700];
      dashPattern = [1, 0];
    }

    void showFactionToast() {
      BotToast.showText(
        text: HtmlParser.fix("${_member.name} belongs to faction "
            "${_member.factionName} as "
            "${_member.position}"),
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600],
        duration: Duration(seconds: 5),
        contentPadding: EdgeInsets.all(10),
      );
    }

    Widget factionIcon = Flexible(
      child: GestureDetector(
        onTap: () => showFactionToast(),
        child: DottedBorder(
          padding: const EdgeInsets.all(2),
          dashPattern: dashPattern,
          color: borderColor,
          child: Text(
            HtmlParser.fix(_member.factionName),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    return factionIcon;
  }

  Color _borderColor() {
    if (_member.justUpdatedWithSuccess) {
      return Colors.green;
    } else if (_member.justUpdatedWithError) {
      return Colors.red;
    } else {
      return Colors.transparent;
    }
  }

  Widget _returnRespectFF(double respect, double fairFight) {
    TextSpan respectResult;
    TextSpan fairFightResult;

    if (respect == -1) {
      respectResult = TextSpan(
        text: 'unk',
        style: TextStyle(
          color: _themeProvider.mainText,
          fontSize: 12,
        ),
      );
    } else if (respect == 0) {
      if (_member.userWonOrDefended) {
        respectResult = TextSpan(
          text: '0 (def)',
          style: TextStyle(
            color: _themeProvider.mainText,
            fontSize: 12,
          ),
        );
      } else {
        respectResult = TextSpan(
          text: 'Lost',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      }
    } else {
      respectResult = TextSpan(
        text: respect.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _themeProvider.mainText,
          fontSize: 12,
        ),
      );
    }

    if (fairFight == -1) {
      fairFightResult = TextSpan(
        text: 'unk',
        style: TextStyle(
          color: _themeProvider.mainText,
          fontSize: 12,
        ),
      );
    } else {
      var ffColor = Colors.red;
      if (fairFight >= 2.2 && fairFight < 2.8) {
        ffColor = Colors.orange;
      } else if (fairFight >= 2.8) {
        ffColor = Colors.green;
      }

      fairFightResult = TextSpan(
        text: fairFight.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: ffColor,
          fontSize: 12,
        ),
      );
    }

    return Flexible(
      child: Row(
        children: [
          Flexible(
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: 'R: ',
                    style: TextStyle(
                      color: _themeProvider.mainText,
                      fontSize: 12,
                    ),
                  ),
                  respectResult,
                ],
              ),
            ),
          ),
          respect == 0
              ? SizedBox.shrink()
              : Flexible(
                  child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: ' / FF: ',
                          style: TextStyle(
                            color: _themeProvider.mainText,
                            fontSize: 12,
                          ),
                        ),
                        fairFightResult,
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _returnHealth(Member target) {
    Color lifeBarColor = Colors.green;
    Widget hospitalWarning = SizedBox.shrink();
    String lifeText = _member.lifeCurrent == -1 ? "?" : _member.lifeCurrent.toString();

    if (_member.status.state == "Hospital") {
      // Handle if target is still in hospital
      var now = DateTime.now().millisecondsSinceEpoch / 1000.floor();
      if (_member.status.until > now) {
        var endTimeStamp = DateTime.fromMillisecondsSinceEpoch(target.status.until * 1000);
        if (_lifeTicker == null) {
          _lifeTicker = Timer.periodic(Duration(seconds: 1), (Timer t) => _refreshLifeClock(endTimeStamp));
        }
        _refreshLifeClock(endTimeStamp);
        lifeText = _currentLifeString;
        lifeBarColor = Colors.red[300];
        hospitalWarning = Icon(
          Icons.local_hospital,
          size: 20,
          color: Colors.red,
        );
      } else {
        _lifeTicker?.cancel();
        lifeText = "OUT";
        hospitalWarning = Icon(
          MdiIcons.bandage,
          size: 20,
          color: Colors.green,
        );
      }
    } else {
      _lifeTicker?.cancel();
    }

    // Found players in federal jail with a higher life than their maximum. Correct it if it's the
    // case to avoid issues with percentage bar
    double lifePercentage;
    if (_member.lifeCurrent != -1) {
      if (_member.lifeCurrent / _member.lifeMaximum > 1) {
        lifePercentage = 1;
      } else if (_member.lifeCurrent / _member.lifeMaximum > 1) {
        lifePercentage = 0;
      } else {
        lifePercentage = _member.lifeCurrent / _member.lifeMaximum;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Life ',
          style: TextStyle(fontSize: 13),
        ),
        LinearPercentIndicator(
          width: 100,
          lineHeight: 14,
          progressColor: lifeBarColor,
          center: Text(
            lifeText,
            style: TextStyle(color: Colors.black, fontSize: 12),
          ),
          percent: lifePercentage == null ? 0 : lifePercentage,
        ),
        hospitalWarning,
      ],
    );
  }

  Widget _travelIcon() {
    if (_member.status.color == "blue") {
      var destination = _member.status.description;
      var flag = '';
      if (destination.contains('Japan')) {
        flag = 'images/flags/stock/japan.png';
      } else if (destination.contains('Hawaii')) {
        flag = 'images/flags/stock/hawaii.png';
      } else if (destination.contains('China')) {
        flag = 'images/flags/stock/china.png';
      } else if (destination.contains('Argentina')) {
        flag = 'images/flags/stock/argentina.png';
      } else if (destination.contains('United Kingdom')) {
        flag = 'images/flags/stock/uk.png';
      } else if (destination.contains('Cayman')) {
        flag = 'images/flags/stock/cayman.png';
      } else if (destination.contains('South Africa')) {
        flag = 'images/flags/stock/south-africa.png';
      } else if (destination.contains('Switzerland')) {
        flag = 'images/flags/stock/switzerland.png';
      } else if (destination.contains('Mexico')) {
        flag = 'images/flags/stock/mexico.png';
      } else if (destination.contains('UAE')) {
        flag = 'images/flags/stock/uae.png';
      } else if (destination.contains('Canada')) {
        flag = 'images/flags/stock/canada.png';
      }

      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () {
            BotToast.showText(
              text: _member.status.description,
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue,
              duration: Duration(seconds: 5),
              contentPadding: EdgeInsets.all(10),
            );
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: RotatedBox(
                  quarterTurns: _member.status.description.contains('Traveling to ')
                      ? 1 // If traveling to another country
                      : _member.status.description.contains('Returning ')
                          ? 3 // If returning to Torn
                          : 0, // If staying abroad (blue but not moving)
                  child: Icon(
                    _member.status.description.contains('In ')
                        ? Icons.location_city_outlined
                        : Icons.airplanemode_active,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Image.asset(
                  flag,
                  width: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
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
    var timeDifference = DateTime.now().difference(_member.lastUpdated);
    _lastUpdatedMinutes = timeDifference.inMinutes;
    if (timeDifference.inMinutes < 1) {
      _lastUpdatedString = 'now';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      _lastUpdatedString = '1 minute ago';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      _lastUpdatedString = '${timeDifference.inMinutes} minutes ago';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      _lastUpdatedString = '1 hour ago';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      _lastUpdatedString = '${timeDifference.inHours} hours ago';
    } else if (timeDifference.inDays == 1) {
      _lastUpdatedString = '1 day ago';
    } else {
      _lastUpdatedString = '${timeDifference.inDays} days ago';
    }
  }

  Color _returnTargetNoteColor() {
    switch (_member.personalNoteColor) {
      case 'red':
        return Colors.red[600];
        break;
      case 'orange':
        return Colors.orange[600];
        break;
      case 'green':
        return Colors.green[600];
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
              memberModel: _member,
              noteType: PersonalNoteType.factionMember,
            ),
          ),
        );
      },
    );
  }

  void _updateThisMember() async {
    bool success = await _w.updateSingleMember(_member, _userProvider.basic.userApiKey);
    String message = "Updated ${_member.name}!";
    Color color = Colors.green;
    if (!success) {
      message = "Error updating ${_member.name}!";
      color = Colors.orange[700];
    }
    BotToast.showText(
      text: message,
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: color,
      duration: Duration(seconds: 3),
      contentPadding: EdgeInsets.all(10),
    );
  }

  void _updateSeveralTargets(List<String> attackedIds) async {
    BotToast.showText(
      text: '${attackedIds.length} attacked targets will auto update in a few seconds!',
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.grey[800],
      duration: Duration(seconds: 4),
      contentPadding: EdgeInsets.all(10),
    );

    await _targetsProvider.updateTargetsAfterAttacks(targetsIds: attackedIds);
  }

  void _timerUpdateInformation() {
    _returnLastUpdated();
    if (mounted) {
      setState(() {});
    }
  }

  _refreshLifeClock(DateTime timeEnd) {
    var diff = timeEnd.difference(DateTime.now());
    if (diff.inSeconds > 0) {
      Duration timeOut = Duration(seconds: diff.inSeconds);

      String timeOutMin = timeOut.inMinutes.remainder(60).toString();
      if (timeOut.inMinutes.remainder(60) < 10) {
        timeOutMin = '0$timeOutMin';
      }

      String timeOutSec = timeOut.inSeconds.remainder(60).toString();
      if (timeOut.inSeconds.remainder(60) < 10) {
        timeOutSec = '0$timeOutSec';
      }

      int timerCadence = 1;
      if (diff.inSeconds > 80) {
        timerCadence = 20;
        if (mounted) {
          setState(() {
            _currentLifeString = '${timeOut.inHours}h ${timeOutMin}m';
          });
        }
      } else if (diff.inSeconds > 59 && diff.inSeconds <= 80) {
        timerCadence = 1;
      } else {
        timerCadence = 1;
        if (mounted) {
          setState(() {
            _currentLifeString = '$timeOutSec sec';
          });
        }
      }

      if (_lifeTicker != null) {
        _lifeTicker.cancel();
        _lifeTicker = Timer.periodic(Duration(seconds: timerCadence), (Timer t) => _refreshLifeClock(timeEnd));
      }

      if (diff.inSeconds < 2) {
        // Artificially release instead of updating
        _releaseFromHospital();
      }
    }
  }

  _releaseFromHospital() async {
    await Future.delayed(const Duration(seconds: 5));
    if (_lifeTicker != null) {
      _lifeTicker.cancel();
    }
    _member.status.until = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    if (mounted) {
      setState(() {});
    }
  }

  void _startAttack() async {
    /*
    var browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        // For app browser, we are going to pass a list of attacks
        // so that we can move to the next one
        var myTargetList = List<TargetModel>.from(_targetsProvider.allTargets);
        // First, find out where we are in the list
        for (var i = 0; i < myTargetList.length; i++) {
          if (_member.playerId == myTargetList[i].playerId) {
            myTargetList.removeRange(0, i);
            break;
          }
        }
        List<String> attacksIds = <String>[];
        List<String> attacksNames = <String>[];
        List<String> attackNotes = <String>[];
        List<String> attacksNotesColor = <String>[];
        for (var tar in myTargetList) {
          attacksIds.add(tar.playerId.toString());
          attacksNames.add(tar.name);
          attackNotes.add(tar.personalNote);
          attacksNotesColor.add(tar.personalNoteColor);
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => TornWebViewAttack(
              attackIdList: attacksIds,
              attackNameList: attacksNames,
              attackNotesList: attackNotes,
              attackNotesColorList: attacksNotesColor,
              attacksCallback: _updateSeveralTargets,
              userKey: _userProvider.basic.userApiKey,
            ),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = 'https://www.torn.com/loader.php?sid='
            'attack&user2ID=${_member.playerId}';
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
    */
  }
}
