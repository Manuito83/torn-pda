// Dart imports:
import 'dart:async';
import 'dart:math';

// Flutter imports:
import 'package:animations/animations.dart';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/pages/chaining/member_details_page.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/notes_dialog.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class WarCard extends StatefulWidget {
  final Member memberModel;

  // Key is needed to update at least the hospital counter individually
  const WarCard({
    required this.memberModel,
    super.key,
  });

  @override
  WarCardState createState() => WarCardState();
}

class WarCardState extends State<WarCard> {
  late Member _member;
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late UserDetailsProvider _userProvider;
  late ChainStatusProvider _chainProvider;
  late WebViewProvider _webViewProvider;

  Timer? _updatedTicker;
  Timer? _lifeTicker;

  String _currentLifeString = "";
  late String _lastUpdatedString;
  late int _lastUpdatedMinutes;

  bool _addButtonActive = true;

  final WarController _w = Get.find<WarController>();

  @override
  void initState() {
    super.initState();
    _member = widget.memberModel;
    _webViewProvider = context.read<WebViewProvider>();
    _updatedTicker = Timer.periodic(const Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
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
    _returnLastUpdated();
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
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
                  color: _chainProvider.panicTargets.where((t) => t.name == _member.name).isNotEmpty
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
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 10, 0),
                  child: Row(
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          GestureDetector(
                            child: Row(
                              children: [
                                _attackIcon(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                ),
                                SizedBox(
                                  width: 95,
                                  child: Text(
                                    '${_member.name}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
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
                          children: <Widget>[
                            const SizedBox(width: 3),
                            _factionName(),
                            OpenContainer(
                              transitionDuration: const Duration(milliseconds: 500),
                              transitionType: ContainerTransitionType.fadeThrough,
                              openBuilder: (BuildContext context, VoidCallback _) {
                                return MemberDetailsPage(memberId: _member.memberId.toString());
                              },
                              closedElevation: 0,
                              closedShape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(56 / 2),
                                ),
                              ),
                              openColor: _themeProvider.canvas!,
                              closedColor: Colors.transparent,
                              closedBuilder: (BuildContext context, VoidCallback openContainer) {
                                return const SizedBox(
                                  height: 22,
                                  width: 30,
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 3),
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
                                const SizedBox(width: 5),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 5, 15, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _returnRespectFF(_member.respectGain, _member.fairFight),
                      if (!_member.overrideEasyLife!) _returnEasyHealth(_member) else _returnFullHealth(_member),
                    ],
                  ),
                ),
                // LINE 3
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 5, 15, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _statsWidget(),
                      Row(
                        children: [
                          _travelIcon(),
                          _lastOnlineWidget(),
                          const SizedBox(width: 5),
                          const Icon(Icons.refresh, size: 12),
                          const SizedBox(width: 2),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 15, 0),
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
                                padding: const EdgeInsets.all(0),
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
                            const SizedBox(width: 5),
                            const Text(
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
                      const SizedBox(width: 10),
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
                const SizedBox(height: 10),
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
    if (_member.isUpdating!) {
      return const Padding(
        padding: EdgeInsets.all(4.0),
        child: CircularProgressIndicator(),
      );
    } else {
      return IconButton(
        padding: const EdgeInsets.all(0.0),
        iconSize: 22,
        icon: const Icon(Icons.refresh),
        onPressed: () async {
          _updateThisMember();
        },
      );
    }
  }

  Widget _addAsTargetButton() {
    bool existingTarget = false;

    final targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    final targetList = targetsProvider.allTargets;
    for (final tar in targetList) {
      if (tar.playerId == _member.memberId) {
        existingTarget = true;
      }
    }

    if (existingTarget) {
      return IconButton(
        padding: const EdgeInsets.all(0.0),
        iconSize: 20,
        icon: const Icon(
          Icons.remove_circle_outline,
          color: Colors.red,
        ),
        onPressed: () {
          targetsProvider.deleteTargetById(_member.memberId.toString());
          BotToast.showText(
            clickClose: true,
            text: HtmlParser.fix('Removed ${_member.name}!'),
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.orange[900]!,
            duration: const Duration(seconds: 5),
            contentPadding: const EdgeInsets.all(10),
          );
          // Update the button
          setState(() {});
        },
      );
    } else {
      return IconButton(
        padding: const EdgeInsets.all(0.0),
        iconSize: 20,
        icon: _addButtonActive
            ? const Icon(
                Icons.add_circle_outline,
                color: Colors.green,
              )
            : const SizedBox(
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
                final AddTargetResult tryAddTarget = await targetsProvider.addTarget(
                  targetId: _member.memberId.toString(),
                  attacks: await targetsProvider.getAttacks(),
                );

                if (tryAddTarget.success) {
                  BotToast.showText(
                    clickClose: true,
                    text: HtmlParser.fix('Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}] to your '
                        'main targets list in Torn PDA!'),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green[700]!,
                    duration: const Duration(seconds: 5),
                    contentPadding: const EdgeInsets.all(10),
                  );
                } else if (!tryAddTarget.success) {
                  BotToast.showText(
                    clickClose: true,
                    text: HtmlParser.fix('Error adding ${_member.memberId}. ${tryAddTarget.errorReason}'),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.red[900]!,
                    duration: const Duration(seconds: 5),
                    contentPadding: const EdgeInsets.all(10),
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
    Color? borderColor = Colors.grey;
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
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }

    final Widget factionIcon = Flexible(
      child: GestureDetector(
        onTap: () => showFactionToast(),
        child: DottedBorder(
          dashPattern: dashPattern,
          color: borderColor!,
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
    if (_member.justUpdatedWithSuccess!) {
      return Colors.green;
    } else if (_member.justUpdatedWithError!) {
      return Colors.red;
    } else {
      return Colors.transparent;
    }
  }

  Widget _returnRespectFF(double? respect, double? fairFight) {
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
      if (_member.userWonOrDefended!) {
        respectResult = TextSpan(
          text: '0 (def)',
          style: TextStyle(
            color: _themeProvider.mainText,
            fontSize: 12,
          ),
        );
      } else {
        respectResult = const TextSpan(
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
        text: respect!.toStringAsFixed(2),
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
      if (fairFight! >= 2.2 && fairFight < 2.8) {
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
          if (respect == 0)
            const SizedBox.shrink()
          else
            Flexible(
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

  Widget _returnEasyHealth(Member? target) {
    Color? lifeBarColor = Colors.transparent;

    String lifeText = "";
    if (_member.status!.state == "Hospital") {
      lifeText = "Hospital";
      lifeBarColor = Colors.red[300];
    } else if (_member.status!.state == "Jail") {
      lifeText = "Jailed";
      lifeBarColor = Colors.brown[300];
    } else if (_member.status!.state == "Okay") {
      lifeText = "Okay";
      lifeBarColor = Colors.green[300];
    } else if (_member.status!.state == "Traveling") {
      lifeText = "Okay";
      lifeBarColor = Colors.blue[300];
    } else if (_member.status!.state == "Abroad") {
      lifeText = "Okay";
      lifeBarColor = Colors.blue[300];
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: LinearPercentIndicator(
            padding: const EdgeInsets.all(0),
            barRadius: const Radius.circular(10),
            width: 100,
            lineHeight: 14,
            progressColor: lifeBarColor,
            center: Text(
              lifeText,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
            percent: 1,
          ),
        ),
      ],
    );
  }

  Widget _returnFullHealth(Member? target) {
    Color? lifeBarColor = Colors.green;
    Widget hospitalWarning = const SizedBox.shrink();
    String lifeText = _member.lifeCurrent == -1 ? "?" : _member.lifeCurrent.toString();

    if (_member.status!.state == "Hospital") {
      // Handle if target is still in hospital
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      if (_member.status!.until! > now) {
        final endTimeStamp = DateTime.fromMillisecondsSinceEpoch(target!.status!.until! * 1000);
        _lifeTicker ??= Timer.periodic(const Duration(seconds: 1), (Timer t) => _refreshLifeClock(endTimeStamp));
        _refreshLifeClock(endTimeStamp);
        lifeText = _currentLifeString;
        lifeBarColor = Colors.red[300];
        hospitalWarning = const Icon(
          Icons.local_hospital,
          size: 20,
          color: Colors.red,
        );
      } else {
        _lifeTicker?.cancel();
        lifeText = "OUT";
        hospitalWarning = const Icon(
          MdiIcons.bandage,
          size: 20,
          color: Colors.green,
        );
      }
    } else {
      _lifeTicker?.cancel();
    }

    if (_member.status!.state == "Traveling" || _member.status!.state == "Abroad") {
      lifeBarColor = Colors.blue[300];
    }

    // Found players in federal jail with a higher life than their maximum. Correct it if it's the
    // case to avoid issues with percentage bar
    double? lifePercentage;
    if (_member.lifeCurrent != -1) {
      if (_member.lifeCurrent! / _member.lifeMaximum! > 1) {
        lifePercentage = 1;
      } else if (_member.lifeCurrent! / _member.lifeMaximum! > 1) {
        lifePercentage = 0;
      } else {
        lifePercentage = _member.lifeCurrent! / _member.lifeMaximum!;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'Life ',
          style: TextStyle(fontSize: 13),
        ),
        Flexible(
          child: LinearPercentIndicator(
            padding: const EdgeInsets.all(0),
            barRadius: const Radius.circular(10),
            width: 100,
            lineHeight: 14,
            progressColor: lifeBarColor,
            center: Text(
              lifeText,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
            percent: lifePercentage ?? 0,
          ),
        ),
        hospitalWarning,
      ],
    );
  }

  Widget _travelIcon() {
    final country = countryCheck(state: _member.status!.state, description: _member.status!.description);

    if (_member.status!.color == "blue" || (country != "Torn" && _member.status!.color == "red")) {
      final destination = _member.status!.color == "blue" ? _member.status!.description! : country;
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
                text: _member.status!.description!,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.blue,
                duration: const Duration(seconds: 5),
                contentPadding: const EdgeInsets.all(10),
              );
            },
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: RotatedBox(
                    quarterTurns: _member.status!.description!.contains('Traveling to ')
                        ? 1 // If traveling to another country
                        : _member.status!.description!.contains('Returning ')
                            ? 3 // If returning to Torn
                            : 0, // If staying abroad (blue but not moving)
                    child: Icon(
                      _member.status!.description!.contains('In ')
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
      return const SizedBox.shrink();
    }
  }

  void _returnLastUpdated() {
    final timeDifference = DateTime.now().difference(_member.lastUpdated!);
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
    // Return if stats (any type) are not available
    if (!_member.statsComparisonSuccess! && _member.statsExactTotalKnown == -1) {
      return Row(
        children: [
          const Text(
            "unk stats",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          // If stats are not available, show a refresh button to get the user profile and be able to perform the
          // stats comparison and then give option to open the stats dialog
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _updateThisMember();
            },
            child: const Icon(Icons.refresh, size: 18),
          ),
        ],
      );
    }

    // Globals
    int xanaxComparison = 0;
    Color xanaxColor = Colors.orange;
    int refillComparison = 0;
    Color refillColor = Colors.orange;
    int enhancementComparison = 0;
    Color? enhancementColor = _themeProvider.mainText;
    int cansComparison = 0;
    Color cansColor = Colors.orange;
    Color sslColor = Colors.green;
    bool sslProb = true;
    int? ecstasy = 0;
    int? lsd = 0;

    List<Widget> additional = <Widget>[];
    // XANAX
    final int otherXanax = _member.memberXanax!;
    final int myXanax = _member.myXanax!;
    xanaxComparison = otherXanax - myXanax;
    if (xanaxComparison < -10) {
      xanaxColor = Colors.green;
    } else if (xanaxComparison > 10) {
      xanaxColor = Colors.red;
    }
    final Text xanaxText = Text(
      "X",
      style: TextStyle(color: xanaxColor, fontSize: 11),
    );

    // REFILLS
    final int otherRefill = _member.memberRefill!;
    final int myRefill = _member.myRefill!;
    refillComparison = otherRefill - myRefill;
    refillColor = Colors.orange;
    if (refillComparison < -10) {
      refillColor = Colors.green;
    } else if (refillComparison > 10) {
      refillColor = Colors.red;
    }
    final Text refillText = Text(
      "R",
      style: TextStyle(color: refillColor, fontSize: 11),
    );

    // ENHANCER
    final int otherEnhancement = _member.memberEnhancement!;
    final int myEnhancement = _member.myEnhancement!;
    enhancementComparison = otherEnhancement - myEnhancement;
    if (enhancementComparison < 0) {
      enhancementColor = Colors.green;
    } else if (enhancementComparison > 0) {
      enhancementColor = Colors.red;
    }
    final Text enhancementText = Text(
      "E",
      style: TextStyle(color: enhancementColor, fontSize: 11),
    );

    // CANS
    final int otherCans = _member.memberCans!;
    final int myCans = _member.myCans!;
    cansComparison = otherCans - myCans;
    if (cansComparison < 0) {
      cansColor = Colors.green;
    } else if (cansComparison > 0) {
      cansColor = Colors.red;
    }
    final Text cansText = Text(
      "C",
      style: TextStyle(color: cansColor, fontSize: 11),
    );

    /// SSL
    /// If (xan + esc) > 150, SSL is blank;
    /// if (esc + xan) < 150 & LSD < 50, SSL is green;
    /// if (esc + xan) < 150 & LSD > 50 & LSD < 100, SSL is yellow;
    /// if (esc + xan) < 150 & LSD > 100 SSL is red
    Widget sslWidget = const SizedBox.shrink();
    sslColor = Colors.green;
    ecstasy = _member.memberEcstasy;
    lsd = _member.memberLsd;
    if (otherXanax + ecstasy! > 150) {
      sslProb = false;
    } else {
      if (lsd! > 50 && lsd < 50) {
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
    additional.add(const SizedBox(width: 5));
    additional.add(refillText);
    additional.add(const SizedBox(width: 5));
    additional.add(enhancementText);
    additional.add(const SizedBox(width: 5));
    additional.add(cansText);
    additional.add(const SizedBox(width: 5));
    additional.add(sslWidget);
    additional.add(const SizedBox(width: 5));

    if (_member.statsExactTotalKnown != -1) {
      Color? exactColor = Colors.green;
      if (_userProvider.basic!.total! < _member.statsExactTotalKnown! - _member.statsExactTotalKnown! * 0.1) {
        exactColor = Colors.red[700];
      } else if ((_userProvider.basic!.total! >= _member.statsExactTotalKnown! - _member.statsExactTotalKnown! * 0.1) &&
          (_userProvider.basic!.total! <= _member.statsExactTotalKnown! + _member.statsExactTotalKnown! * 0.1)) {
        exactColor = Colors.orange[700];
      }

      int? totalToShow = 0;
      if (_member.statsExactTotal != -1) {
        // TornStats adds all 4 stats into total if total is unknown, but then rounds. So it might happen that the
        // total sum is actually higher than the one calculated and rounded by TS
        totalToShow = max(_member.statsExactTotal!, _member.statsExactTotalKnown!);
      } else {
        totalToShow = _member.statsExactTotalKnown;
      }

      bool someStatUnknown = false;
      if (_member.statsStr == -1 || _member.statsDef == -1 || _member.statsDex == -1 || _member.statsSpd == -1) {
        someStatUnknown = true;
      }

      return Row(
        children: [
          Text(
            formatBigNumbers(totalToShow!),
            style: TextStyle(
              fontSize: 12,
              color: exactColor,
            ),
          ),
          if (someStatUnknown)
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
          const SizedBox(width: 3),
          GestureDetector(
            child: Icon(
              Icons.info_outline,
              color: exactColor,
              size: 16,
            ),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  SpiesController spyController = Get.find<SpiesController>();
                  final spiesPayload = SpiesPayload(
                    spyController: spyController,
                    strength: _member.statsStr ?? -1,
                    strengthUpdate: _member.statsStrUpdated,
                    defense: _member.statsDef ?? -1,
                    defenseUpdate: _member.statsDefUpdated,
                    speed: _member.statsSpd ?? -1,
                    speedUpdate: _member.statsSpdUpdated,
                    dexterity: _member.statsDex ?? -1,
                    dexterityUpdate: _member.statsDexUpdated,
                    total: _member.statsExactTotal ?? -1,
                    totalUpdate: _member.statsExactTotalUpdated,
                    update: _member.statsExactUpdated ?? 0,
                    spySource: _member.spySource,
                    name: _member.name!,
                    factionName: _member.factionName!,
                    themeProvider: _themeProvider,
                    userDetailsProvider: _userProvider,
                  );

                  final estimatedStatsPayload = EstimatedStatsPayload(
                    xanaxCompare: xanaxComparison,
                    xanaxColor: xanaxColor,
                    refillCompare: refillComparison,
                    refillColor: refillColor,
                    enhancementCompare: enhancementComparison,
                    enhancementColor: enhancementColor,
                    cansCompare: cansComparison,
                    cansColor: cansColor,
                    sslColor: sslColor,
                    sslProb: sslProb,
                    otherXanTaken: _member.memberXanax!,
                    otherEctTaken: _member.memberEcstasy!,
                    otherLsdTaken: _member.memberEcstasy!,
                    otherName: _member.name!,
                    otherFactionName: _member.factionName!,
                    otherLastActionRelative: _member.lastAction!.relative!,
                    themeProvider: _themeProvider,
                  );

                  final tscStatsPayload = TSCStatsPayload(targetId: _member.memberId!);

                  return StatsDialog(
                    spiesPayload: spiesPayload,
                    estimatedStatsPayload: estimatedStatsPayload,
                    tscStatsPayload: _settingsProvider.tscEnabledStatus != 0 ? tscStatsPayload : null,
                  );
                },
              );
            },
          ),
        ],
      );
    } else if (_member.statsEstimated!.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "(EST)",
            style: TextStyle(
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _member.statsEstimated!,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 5),
          Row(
            children: additional,
          ),
          GestureDetector(
            child: const Icon(
              Icons.info_outline,
              size: 16,
            ),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  final estimatedStatsPayload = EstimatedStatsPayload(
                    xanaxCompare: xanaxComparison,
                    xanaxColor: xanaxColor,
                    refillCompare: refillComparison,
                    refillColor: refillColor,
                    enhancementCompare: enhancementComparison,
                    enhancementColor: enhancementColor,
                    cansCompare: cansComparison,
                    cansColor: cansColor,
                    sslColor: sslColor,
                    sslProb: sslProb,
                    otherXanTaken: _member.memberXanax!,
                    otherEctTaken: _member.memberEcstasy!,
                    otherLsdTaken: _member.memberEcstasy!,
                    otherName: _member.name!,
                    otherFactionName: _member.factionName!,
                    otherLastActionRelative: _member.lastAction!.relative!,
                    themeProvider: _themeProvider,
                  );

                  final tscStatsPayload = TSCStatsPayload(targetId: _member.memberId!);

                  return StatsDialog(
                    spiesPayload: null,
                    estimatedStatsPayload: estimatedStatsPayload,
                    tscStatsPayload: _settingsProvider.tscEnabledStatus != 0 ? tscStatsPayload : null,
                  );
                },
              );
            },
          ),
        ],
      );
    } else {
      return const Text(
        "unk stats",
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
  }

  Color? _returnTargetNoteColor() {
    switch (_member.personalNoteColor) {
      case 'red':
        return Colors.red[600];
      case 'orange':
        return Colors.orange[600];
      case 'green':
        return Colors.green[600];
      default:
        return _themeProvider.mainText;
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

  Future<void> _updateThisMember() async {
    final bool success = await _w.updateSingleMemberFull(_member);
    String message = "Updated ${_member.name}!";
    Color? color = Colors.green;
    if (!success) {
      message = "Error updating ${_member.name}!";
      color = Colors.orange[700];
    }
    BotToast.showText(
      clickClose: true,
      text: message,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: color!,
      duration: const Duration(seconds: 3),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  void _timerUpdateInformation() {
    _returnLastUpdated();
    if (mounted) {
      setState(() {});
    }
  }

  _refreshLifeClock(DateTime timeEnd) {
    final diff = timeEnd.difference(DateTime.now());
    if (diff.inSeconds > 0) {
      final Duration timeOut = Duration(seconds: diff.inSeconds);

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
        _lifeTicker!.cancel();
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
      _lifeTicker!.cancel();
    }
    _member.status!.until = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startAttack() async {
    final browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        List<WarCardDetails> myTargetList = _w.orderedCardsDetails;

        // Adjust the list (remove targets above the one selected)
        myTargetList.removeRange(0, myTargetList.indexWhere((element) => element.memberId == _member.memberId));

        List<String> attacksIds = <String>[];
        List<String?> attacksNames = <String?>[];
        List<String?> attackNotes = <String?>[];
        List<String?> attacksNotesColor = <String?>[];
        for (final tar in myTargetList) {
          attacksIds.add(tar.memberId.toString());
          attacksNames.add(tar.name);
          attackNotes.add(tar.personalNote);
          attacksNotesColor.add(tar.personalNoteColor);
        }

        final bool showNotes = await Prefs().getShowTargetsNotes();
        final bool showBlankNotes = await Prefs().getShowBlankTargetsNotes();
        final bool showOnlineFactionWarning = await Prefs().getShowOnlineFactionWarning();

        _webViewProvider.openBrowserPreference(
          context: context,
          url: 'https://www.torn.com/loader.php?sid=attack&user2ID=${attacksIds[0]}',
          browserTapType: BrowserTapType.chain,
          isChainingBrowser: true,
          chainingPayload: ChainingPayload()
            ..war = true
            ..attackIdList = attacksIds
            ..attackNameList = attacksNames
            ..attackNotesList = attackNotes
            ..attackNotesColorList = attacksNotesColor
            ..showNotes = showNotes
            ..showBlankNotes = showBlankNotes
            ..showOnlineFactionWarning = showOnlineFactionWarning,
        );

      case BrowserSetting.external:
        final url = 'https://www.torn.com/loader.php?sid=attack&user2ID=${_member.memberId}';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
    }
  }

  Widget _lastOnlineWidget() {
    return Row(
      children: [
        if (_member.lastAction!.status == "Offline")
          const Icon(Icons.remove_circle, size: 12, color: Colors.grey)
        else
          _member.lastAction!.status == "Idle"
              ? const Icon(Icons.adjust, size: 12, color: Colors.orange)
              : const Icon(Icons.circle, size: 12, color: Colors.green),
        if (_member.lastAction!.status == "Offline" || _member.lastAction!.status == "Idle")
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              _member.lastAction!.relative!
                  .replaceAll("minute ago", "m")
                  .replaceAll("minutes ago", "m")
                  .replaceAll("hour ago", "h")
                  .replaceAll("hours ago", "h")
                  .replaceAll("day ago", "d")
                  .replaceAll("days ago", "d"),
              style: TextStyle(
                fontSize: 11,
                color: _member.lastAction!.status == "Idle" ? Colors.orange : Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}
