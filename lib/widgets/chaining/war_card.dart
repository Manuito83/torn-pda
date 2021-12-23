// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/offset_animation.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';
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

  // Key is needed to update at least the hospital counter individually
  WarCard({
    @required this.memberModel,
    @required Key key,
  }) : super(key: key);

  @override
  _WarCardState createState() => _WarCardState();
}

class _WarCardState extends State<WarCard> {
  Member _member;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ChainStatusProvider _chainProvider;

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
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _chainProvider = Provider.of<ChainStatusProvider>(context, listen: false);
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
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      // Issues with Percent Indicator
      /*
      dismissal: SlidableDismissal(
        child: SlidableDrawerDismissal(),
        resizeDuration: Duration(seconds: 1),
        onDismissed: (actionType) {
          _w.hideMember(_member);
        },
        // Only dismiss left
        dismissThresholds: <SlideActionType, double>{SlideActionType.primary: 0.0},
      ),
      */
      actions: <Widget>[
        IconSlideAction(
          caption: 'Hide',
          color: Colors.blue,
          icon: Icons.delete,
          onTap: () {
            _w.hideMember(_member);
          },
        ),
      ],
      secondaryActions: <Widget>[
        _chainProvider.panicTargets.where((t) => t.name == _member.name).length == 0
            ? IconSlideAction(
                caption: 'Add to panic!',
                color: Colors.blue,
                icon: MdiIcons.alphaPCircleOutline,
                onTap: () {
                  String message = "Added ${_member.name} as a Panic Mode target!";
                  Color messageColor = Colors.green;

                  if (_chainProvider.panicTargets.length < 10) {
                    setState(() {
                      _chainProvider.addPanicTarget(
                        PanicTargetModel()
                          ..name = _member.name
                          ..level = _member.level
                          ..id = _member.memberId
                          ..factionName = _member.factionName,
                      );
                      // Convert to target with the needed fields
                    });
                  } else {
                    message = "There are already 10 targets in the Panic Mode list, remove some!";
                    messageColor = Colors.orange[700];
                  }

                  BotToast.showText(
                    clickClose: true,
                    text: message,
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: messageColor,
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                },
              )
            : IconSlideAction(
                caption: 'PANIC TARGET',
                color: Colors.blue,
                icon: MdiIcons.alphaPCircleOutline,
                onTap: () {
                  String message = "Removed ${_member.name} as a Panic Mode target!";
                  Color messageColor = Colors.green;

                  setState(() {
                    _chainProvider.removePanicTarget(
                      PanicTargetModel()
                        ..name = _member.name
                        ..level = _member.level
                        ..id = _member.memberId
                        ..factionName = _member.factionName,
                    );
                  });

                  BotToast.showText(
                    clickClose: true,
                    text: message,
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: messageColor,
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                },
              ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: _borderColor(), width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          elevation: 2,
          child: ClipPath(
            clipper: ShapeBorderClipper(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: _chainProvider.panicTargets.where((t) => t.name == _member.name).length > 0
                        ? Colors.blue
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // LINE 1
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(12, 5, 10, 0),
                    child: Row(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            GestureDetector(
                              child: Row(
                                children: [
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
                              onTap: () {
                                _startAttack();
                              },
                            ),
                          ],
                        ),
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              SizedBox(width: 3),
                              _factionName(),
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
                    padding: EdgeInsetsDirectional.fromSTEB(16, 5, 15, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        _returnRespectFF(_member.respectGain, _member.fairFight),
                        if (!_member.overrideEasyLife) _returnEasyHealth(_member) else _returnFullHealth(_member),
                      ],
                    ),
                  ),
                  // LINE 3
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(14, 5, 15, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _statsWidget(),
                        Row(
                          children: [
                            _travelIcon(),
                            _lastOnlineWidget(),
                            SizedBox(width: 5),
                            Icon(Icons.refresh, size: 12),
                            SizedBox(width: 2),
                            Text(
                              _lastUpdatedString
                                  .replaceAll("minute ago", "m")
                                  .replaceAll("minutes ago", "m")
                                  .replaceAll("hour ago", "h")
                                  .replaceAll("hours ago", "h")
                                  .replaceAll("day ago", "d")
                                  .replaceAll("days ago", "d"),
                              style: TextStyle(
                                color: _lastUpdatedMinutes <= 120 ? _themeProvider.mainText : Colors.deepOrangeAccent,
                                fontStyle: _lastUpdatedMinutes <= 120 ? FontStyle.normal : FontStyle.italic,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // LINE 4
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(8, 5, 15, 0),
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
                            '${_w.orderedCardsDetails.indexWhere((element) => element.memberId == _member.memberId) + 1}'
                            '/${_w.orderedCardsDetails.length}',
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
            clickClose: true,
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
                    clickClose: true,
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
                    clickClose: true,
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

  Widget _factionName() {
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
        clickClose: true,
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

  Widget _returnEasyHealth(Member target) {
    Color lifeBarColor = Colors.transparent;

    String lifeText = "";
    if (_member.status.state == "Hospital") {
      lifeText = "Hospital";
      lifeBarColor = Colors.red[300];
    } else if (_member.status.state == "Jail") {
      lifeText = "Jailed";
      lifeBarColor = Colors.brown[300];
    } else if (_member.status.state == "Okay") {
      lifeText = "Okay";
      lifeBarColor = Colors.green[300];
    } else if (_member.status.state == "Traveling") {
      lifeText = "Okay";
      lifeBarColor = Colors.blue[300];
    } else if (_member.status.state == "Abroad") {
      lifeText = "Okay";
      lifeBarColor = Colors.blue[300];
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: LinearPercentIndicator(
            width: 100,
            lineHeight: 14,
            progressColor: lifeBarColor,
            center: Text(
              lifeText,
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
            percent: 1,
          ),
        ),
      ],
    );
  }

  Widget _returnFullHealth(Member target) {
    Color lifeBarColor = Colors.green;
    Widget hospitalWarning = SizedBox.shrink();
    String lifeText = _member.lifeCurrent == -1 ? "?" : _member.lifeCurrent.toString();

    if (_member.status.state == "Hospital") {
      // Handle if target is still in hospital
      var now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
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
        Flexible(
          child: LinearPercentIndicator(
            width: 100,
            lineHeight: 14,
            progressColor: lifeBarColor,
            center: Text(
              lifeText,
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
            percent: lifePercentage == null ? 0 : lifePercentage,
          ),
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

      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              BotToast.showText(
                clickClose: true,
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
        ),
      );
    } else {
      return SizedBox.shrink();
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

  Widget _statsWidget() {
    void _showDetailedStatsDialog() {
      String lastUpdated = "";
      if (_member.statsExactUpdated != 0) {
        lastUpdated = readTimestamp(_member.statsExactUpdated);
      }

      Widget strWidget;
      if (_member.statsStr == -1) {
        strWidget = Text(
          "Strength: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var strDiff = "";
        Color strColor;
        var result = _userProvider.basic.strength - _member.statsStr;
        if (result == 0) {
          strDiff = "Same as you";
          strColor = Colors.orange;
        } else if (result < 0) {
          strDiff = "${formatBigNumbers(result.abs())} higher than you";
          strColor = Colors.red;
        } else {
          strDiff = "${formatBigNumbers(result.abs())} lower than you";
          strColor = Colors.green;
        }

        strWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Strength: ${formatBigNumbers(_member.statsStr)}",
              style: TextStyle(fontSize: 12),
            ),
            Text(
              strDiff,
              style: TextStyle(fontSize: 12, color: strColor),
            ),
          ],
        );
      }

      Widget spdWidget;
      if (_member.statsSpd == -1) {
        spdWidget = Text(
          "Speed: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var spdDiff = "";
        Color spdColor;
        var result = _userProvider.basic.speed - _member.statsSpd;
        if (result == 0) {
          spdDiff = "Same as you";
          spdColor = Colors.orange;
        } else if (result < 0) {
          spdDiff = "${formatBigNumbers(result.abs())} higher than you";
          spdColor = Colors.red;
        } else {
          spdDiff = "${formatBigNumbers(result.abs())} lower than you";
          spdColor = Colors.green;
        }

        spdWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Speed: ${formatBigNumbers(_member.statsSpd)}",
              style: TextStyle(fontSize: 12),
            ),
            Text(
              spdDiff,
              style: TextStyle(fontSize: 12, color: spdColor),
            ),
          ],
        );
      }

      Widget defWidget;
      if (_member.statsDef == -1) {
        defWidget = Text(
          "Defense: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var defDiff = "";
        Color defColor;
        var result = _userProvider.basic.defense - _member.statsDef;
        if (result == 0) {
          defDiff = "Same as you";
          defColor = Colors.orange;
        } else if (result < 0) {
          defDiff = "${formatBigNumbers(result.abs())} higher than you";
          defColor = Colors.red;
        } else {
          defDiff = "${formatBigNumbers(result.abs())} lower than you";
          defColor = Colors.green;
        }

        defWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Defense: ${formatBigNumbers(_member.statsDef)}",
              style: TextStyle(fontSize: 12),
            ),
            Text(
              defDiff,
              style: TextStyle(fontSize: 12, color: defColor),
            ),
          ],
        );
      }

      Widget dexWidget;
      if (_member.statsDex == -1) {
        dexWidget = Text(
          "Dexterity: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var dexDiff = "";
        Color dexColor;
        var result = _userProvider.basic.dexterity - _member.statsDex;
        if (result == 0) {
          dexDiff = "Same as you";
          dexColor = Colors.orange;
        } else if (result < 0) {
          dexDiff = "${formatBigNumbers(result.abs())} higher than you";
          dexColor = Colors.red;
        } else {
          dexDiff = "${formatBigNumbers(result.abs())} lower than you";
          dexColor = Colors.green;
        }

        dexWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dexterity: ${formatBigNumbers(_member.statsDex)}",
              style: TextStyle(fontSize: 12),
            ),
            Text(
              dexDiff,
              style: TextStyle(fontSize: 12, color: dexColor),
            ),
          ],
        );
      }

      Widget totalWidget;
      if (_member.statsExactTotal == -1) {
        totalWidget = Text(
          "TOTAL: unknown (>${formatBigNumbers(_member.statsExactTotalKnown)})",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var totalDiff = "";
        Color totalColor;
        var result = _userProvider.basic.total - _member.statsExactTotal;
        if (result == 0) {
          totalDiff = "Same as you";
          totalColor = Colors.orange;
        } else if (result < 0) {
          totalDiff = "${formatBigNumbers(result.abs())} higher than you";
          totalColor = Colors.red;
        } else {
          totalDiff = "${formatBigNumbers(result.abs())} lower than you";
          totalColor = Colors.green;
        }

        totalWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TOTAL: ${formatBigNumbers(_member.statsExactTotal)}",
              style: TextStyle(fontSize: 12),
            ),
            Text(
              totalDiff,
              style: TextStyle(fontSize: 12, color: totalColor),
            ),
          ],
        );
      }

      BotToast.showAnimationWidget(
        clickClose: false,
        allowClick: false,
        onlyOne: true,
        wrapToastAnimation: (controller, cancel, child) => Stack(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                cancel();
              },
              child: AnimatedBuilder(
                builder: (_, child) => Opacity(
                  opacity: controller.value,
                  child: child,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black26),
                  child: SizedBox.expand(),
                ),
                animation: controller,
              ),
            ),
            CustomOffsetAnimation(
              controller: controller,
              child: child,
            )
          ],
        ),
        toastBuilder: (cancelFunc) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          title: Text(_member.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_member.factionName != "0")
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    "Faction: ${_member.factionName}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              if (lastUpdated.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    "Updated: $lastUpdated",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 4, bottom: 10),
                child: strWidget,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: spdWidget,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: defWidget,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: dexWidget,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 4),
                child: totalWidget,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                cancelFunc();
              },
              child: const Text('Thanks'),
            ),
          ],
        ),
        animationDuration: Duration(milliseconds: 300),
      );
    }

    if (_member.statsExactTotalKnown != -1) {
      Color exactColor = Colors.green;
      if (_userProvider.basic.total < _member.statsExactTotalKnown - _member.statsExactTotalKnown * 0.1) {
        exactColor = Colors.red[700];
      } else if ((_userProvider.basic.total >= _member.statsExactTotalKnown - _member.statsExactTotalKnown * 0.1) &&
          (_userProvider.basic.total <= _member.statsExactTotalKnown + _member.statsExactTotalKnown * 0.1)) {
        exactColor = Colors.orange[700];
      }
      return Row(
        children: [
          Text(
            "${formatBigNumbers(_member.statsExactTotalKnown)}",
            style: TextStyle(
              fontSize: 12,
              color: exactColor,
            ),
          ),
          if (_member.statsExactTotalKnown != _member.statsExactTotal)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                "?",
                style: TextStyle(
                  fontSize: 12,
                  color: exactColor,
                ),
              ),
            ),
          SizedBox(width: 3),
          GestureDetector(
            child: Icon(
              Icons.info_outline,
              color: exactColor,
              size: 16,
            ),
            onTap: () {
              _showDetailedStatsDialog();
            },
          ),
        ],
      );
    } else if (_member.statsEstimated.isNotEmpty) {
      if (!_member.statsComparisonSuccess) {
        return Text(
          "unk stats",
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        );
      }

      // Globals
      int xanaxComparison = 0;
      Color xanaxColor = Colors.orange;
      int refillComparison = 0;
      Color refillColor = Colors.orange;
      int enhancementComparison = 0;
      Color enhancementColor = _themeProvider.mainText;
      int cansComparison = 0;
      Color cansColor = Colors.orange;
      Color sslColor = Colors.green;
      bool sslProb = true;
      int ecstasy = 0;
      int lsd = 0;

      List<Widget> additional = <Widget>[];
      // XANAX
      int otherXanax = _member.memberXanax;
      int myXanax = _member.myXanax;
      xanaxComparison = otherXanax - myXanax;
      if (xanaxComparison < -10) {
        xanaxColor = Colors.green;
      } else if (xanaxComparison > 10) {
        xanaxColor = Colors.red;
      }
      Text xanaxText = Text(
        "X",
        style: TextStyle(color: xanaxColor, fontSize: 11),
      );

      // REFILLS
      int otherRefill = _member.memberRefill;
      int myRefill = _member.myRefill;
      refillComparison = otherRefill - myRefill;
      refillColor = Colors.orange;
      if (refillComparison < -10) {
        refillColor = Colors.green;
      } else if (refillComparison > 10) {
        refillColor = Colors.red;
      }
      Text refillText = Text(
        "R",
        style: TextStyle(color: refillColor, fontSize: 11),
      );

      // ENHANCER
      int otherEnhancement = _member.memberEnhancement;
      int myEnhancement = _member.myEnhancement;
      enhancementComparison = otherEnhancement - myEnhancement;
      if (enhancementComparison < 0) {
        enhancementColor = Colors.green;
      } else if (enhancementComparison > 0) {
        enhancementColor = Colors.red;
      }
      Text enhancementText = Text(
        "E",
        style: TextStyle(color: enhancementColor, fontSize: 11),
      );

      // CANS
      int otherCans = _member.memberCans;
      int myCans = _member.myCans;
      cansComparison = otherCans - myCans;
      if (cansComparison < 0) {
        cansColor = Colors.green;
      } else if (cansComparison > 0) {
        cansColor = Colors.red;
      }
      Text cansText = Text(
        "C",
        style: TextStyle(color: cansColor, fontSize: 11),
      );

      /// SSL
      /// If (xan + esc) > 150, SSL is blank;
      /// if (esc + xan) < 150 & LSD < 50, SSL is green;
      /// if (esc + xan) < 150 & LSD > 50 & LSD < 100, SSL is yellow;
      /// if (esc + xan) < 150 & LSD > 100 SSL is red
      Widget sslWidget = SizedBox.shrink();
      sslColor = Colors.green;
      ecstasy = _member.memberEcstasy;
      lsd = _member.memberLsd;
      if (otherXanax + ecstasy > 150) {
        sslProb = false;
      } else {
        if (lsd > 50 && lsd < 50) {
          sslColor = Colors.orange;
        } else if (lsd > 100) {
          sslColor = Colors.red;
        }
        sslWidget = Text(
          "[SSL]",
          style: TextStyle(
            color: sslColor,
            fontSize: 11,
          ),
        );
      }

      additional.add(xanaxText);
      additional.add(SizedBox(width: 5));
      additional.add(refillText);
      additional.add(SizedBox(width: 5));
      additional.add(enhancementText);
      additional.add(SizedBox(width: 5));
      additional.add(cansText);
      additional.add(SizedBox(width: 5));
      additional.add(sslWidget);
      additional.add(SizedBox(width: 5));

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "(EST)",
            style: TextStyle(
              fontSize: 11,
            ),
          ),
          SizedBox(width: 5),
          Text(
            _member.statsEstimated,
            style: TextStyle(
              fontSize: 11,
            ),
          ),
          SizedBox(width: 5),
          Row(
            children: additional,
          ),
          GestureDetector(
            child: Icon(
              Icons.info_outline,
              size: 16,
            ),
            onTap: () {
              _showEstimatedDetailsDialog(
                xanaxComparison,
                xanaxColor,
                refillComparison,
                refillColor,
                enhancementComparison,
                enhancementColor,
                cansComparison,
                cansColor,
                sslColor,
                sslProb,
                _member,
              );
            },
          ),
        ],
      );
    } else {
      return Text(
        "unk stats",
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
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
    bool success = await _w.updateSingleMemberFull(_member);
    String message = "Updated ${_member.name}!";
    Color color = Colors.green;
    if (!success) {
      message = "Error updating ${_member.name}!";
      color = Colors.orange[700];
    }
    BotToast.showText(
      clickClose: true,
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
      clickClose: true,
      text: '${attackedIds.length} attacked targets will auto update in a few seconds!',
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.grey[800],
      duration: Duration(seconds: 4),
      contentPadding: EdgeInsets.all(10),
    );

    _w.updateSomeMembersAfterAttack(attackedIds);
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
    var browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        List<WarCardDetails> myTargetList = _w.orderedCardsDetails;

        // Adjust the list (remove targets above the one selected)
        myTargetList.removeRange(0, myTargetList.indexWhere((element) => element.memberId == _member.memberId));

        List<String> attacksIds = <String>[];
        List<String> attacksNames = <String>[];
        List<String> attackNotes = <String>[];
        List<String> attacksNotesColor = <String>[];
        for (var tar in myTargetList) {
          attacksIds.add(tar.memberId.toString());
          attacksNames.add(tar.name);
          attackNotes.add(tar.personalNote);
          attacksNotesColor.add(tar.personalNoteColor);
        }
        Get.to(
          TornWebViewAttack(
            attackIdList: attacksIds,
            attackNameList: attacksNames,
            attackNotesList: attackNotes,
            attackNotesColorList: attacksNotesColor,
            attacksCallback: _updateSeveralTargets,
            war: true,
            showNotes: await Prefs().getShowTargetsNotes(),
            showBlankNotes: await Prefs().getShowBlankTargetsNotes(),
            showOnlineFactionWarning: await Prefs().getShowOnlineFactionWarning(),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = 'https://www.torn.com/loader.php?sid=attack&user2ID=${_member.memberId}';
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
  }

  Widget _lastOnlineWidget() {
    return Row(
      children: [
        _member.lastAction.status == "Offline"
            ? Icon(Icons.remove_circle, size: 12, color: Colors.grey)
            : _member.lastAction.status == "Idle"
                ? Icon(Icons.adjust, size: 12, color: Colors.orange)
                : Icon(Icons.circle, size: 12, color: Colors.green),
        if (_member.lastAction.status == "Offline" || _member.lastAction.status == "Idle")
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              _member.lastAction.relative
                  .replaceAll("minute ago", "m")
                  .replaceAll("minutes ago", "m")
                  .replaceAll("hour ago", "h")
                  .replaceAll("hours ago", "h")
                  .replaceAll("day ago", "d")
                  .replaceAll("days ago", "d"),
              style: TextStyle(
                fontSize: 11,
                color: _member.lastAction.status == "Idle" ? Colors.orange : Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  void _showEstimatedDetailsDialog(
    int xanaxCompare,
    Color xanaxColor,
    int refillCompare,
    Color refillColor,
    int enhancementCompare,
    Color enhancementColor,
    int cansCompare,
    Color cansColor,
    Color sslColor,
    bool sslProb,
    Member member,
  ) {
    String xanaxRelative = "SAME as you";
    if (xanaxCompare > 0) {
      xanaxRelative = "${xanaxCompare.abs()} MORE than you";
    } else {
      xanaxRelative = "${xanaxCompare.abs()} LESS than you";
    }
    Widget xanaxWidget = Row(
      children: [
        Text(
          "> Xanax: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$xanaxRelative",
            style: TextStyle(color: xanaxColor, fontSize: 14),
          ),
        ),
      ],
    );
    ;

    String refillRelative = "SAME as you";
    if (refillCompare > 0) {
      refillRelative = "${refillCompare.abs()} MORE than you";
    } else {
      refillRelative = "${refillCompare.abs()} LESS than you";
    }
    Widget refillWidget = Row(
      children: [
        Text(
          "> (E) Refills: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$refillRelative",
            style: TextStyle(color: refillColor, fontSize: 14),
          ),
        ),
      ],
    );

    String enhancementRelative = "SAME as you";
    if (enhancementColor == Colors.white) enhancementColor = _themeProvider.mainText;
    if (enhancementCompare > 0) {
      enhancementRelative = "${enhancementCompare.abs()} MORE than you";
    } else if (enhancementCompare < 0) {
      enhancementRelative = "${enhancementCompare.abs()} LESS than you";
    }
    Widget enhancementWidget = Row(
      children: [
        Text(
          "> Enhancer(s): ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$enhancementRelative",
            style: TextStyle(color: enhancementColor, fontSize: 14),
          ),
        ),
      ],
    );

    String cansRelative = "SAME as you";
    if (cansCompare > 0) {
      cansRelative = "${cansCompare.abs()} MORE than you";
    } else if (cansCompare < 0) {
      cansRelative = "${cansCompare.abs()} LESS than you";
    }
    Widget cansWidget = Row(
      children: [
        Text(
          "> Cans: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$cansRelative",
            style: TextStyle(color: cansColor, fontSize: 14),
          ),
        ),
      ],
    );

    Widget sslWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "> SSL probability: ",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "${!sslProb ? "none" : sslColor == Colors.green ? "low" : sslColor == Colors.orange ? "med" : "high"}",
              style: TextStyle(
                color: sslColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            "[Sports Science Lab Gym]",
            style: TextStyle(fontSize: 9),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xanax: ${member.memberXanax}",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                "Ecstasy: ${member.memberEcstasy}",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                "LSD: ${member.memberLsd}",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    BotToast.showAnimationWidget(
      clickClose: false,
      allowClick: false,
      onlyOne: true,
      wrapToastAnimation: (controller, cancel, child) => Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              cancel();
            },
            child: AnimatedBuilder(
              builder: (_, child) => Opacity(
                opacity: controller.value,
                child: child,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
                child: SizedBox.expand(),
              ),
              animation: controller,
            ),
          ),
          CustomOffsetAnimation(
            controller: controller,
            child: child,
          )
        ],
      ),
      toastBuilder: (cancelFunc) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(member.name),
        backgroundColor: _themeProvider.background,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.factionName != "0")
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Faction: ${member.factionName}",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (member.lastAction.relative.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Online: ${member.lastAction.relative.replaceAll("0 minutes ago", "now")}",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: xanaxWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: refillWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: enhancementWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: cansWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: sslWidget,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              cancelFunc();
            },
            child: const Text('Thanks'),
          ),
        ],
      ),
      animationDuration: Duration(milliseconds: 300),
    );
  }
}
