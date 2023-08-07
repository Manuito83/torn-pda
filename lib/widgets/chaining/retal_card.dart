// Dart imports:
import 'dart:async';
import 'dart:math';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/retal_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/retals_controller.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/offset_animation.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class RetalCard extends StatefulWidget {
  final Retal retalModel;
  final int expiryTimeStamp;

  // Key is needed to update at least the hospital counter individually
  const RetalCard({
    required this.retalModel,
    required this.expiryTimeStamp,
    required Key key,
  }) : super(key: key);

  @override
  RetalCardState createState() => RetalCardState();
}

class RetalCardState extends State<RetalCard> {
  Retal? _retal;
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late UserDetailsProvider _userProvider;
  late ChainStatusProvider _chainProvider;
  late WebViewProvider _webViewProvider;

  Timer? _expiryTicker;
  Timer? _lifeTicker;

  String _currentLifeString = "";

  bool _addButtonActive = true;

  final RetalsController _r = Get.put(RetalsController());

  @override
  void initState() {
    super.initState();
    _webViewProvider = context.read<WebViewProvider>();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _chainProvider = Provider.of<ChainStatusProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _expiryTicker?.cancel();
    _lifeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _retal = widget.retalModel;
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
                  color: _chainProvider.panicTargets.where((t) => t.name == _retal!.name).isNotEmpty
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
                                    '${_retal!.name}',
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
                            const SizedBox(width: 3),
                            Text(
                              'L${_retal!.level}',
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  height: 22,
                                  width: 30,
                                  child: _addAsTargetButton(),
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
                      _returnRespectFF(_retal!.respectGain, _retal!.fairFight),
                      if (!_retal!.overrideEasyLife) _returnEasyHealth(_retal) else _returnFullHealth(_retal),
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
                        ],
                      ),
                    ],
                  ),
                ),
                // LINE 4
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 15, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.personWalkingArrowLoopLeft,
                        size: 12,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 5),
                        child: CurrentRetalExpiryWidget(expiryTimeStamp: widget.expiryTimeStamp),
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

  Widget _addAsTargetButton() {
    bool existingTarget = false;

    final targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    final targetList = targetsProvider.allTargets;
    for (final tar in targetList) {
      if (tar.playerId == _retal!.retalId) {
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
          targetsProvider.deleteTargetById(_retal!.retalId.toString());
          BotToast.showText(
            clickClose: true,
            text: HtmlParser.fix('Removed ${_retal!.name}!'),
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
                  targetId: _retal!.retalId.toString(),
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
                    text: HtmlParser.fix('Error adding ${_retal!.retalId}. ${tryAddTarget.errorReason}'),
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
    if (_retal!.factionLeader == _retal!.retalId) {
      borderColor = Colors.red[500];
      dashPattern = [1, 0];
    } else if (_retal!.factionColeader == _retal!.retalId) {
      borderColor = Colors.orange[700];
      dashPattern = [1, 0];
    }

    void showFactionToast() {
      BotToast.showText(
        clickClose: true,
        text: HtmlParser.fix("${_retal!.name} belongs to faction "
            "${_retal!.factionName} as "
            "${_retal!.position}"),
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
            HtmlParser.fix(_retal!.factionName),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    return factionIcon;
  }

  Color _borderColor() {
    if (_retal!.justUpdatedWithSuccess!) {
      return Colors.green;
    } else if (_retal!.justUpdatedWithError!) {
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
      if (_retal!.userWonOrDefended!) {
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

  Widget _returnEasyHealth(Retal? target) {
    Color? lifeBarColor = Colors.transparent;

    String lifeText = "";
    if (_retal!.status.state == "Hospital") {
      lifeText = "Hospital";
      lifeBarColor = Colors.red[300];
    } else if (_retal!.status.state == "Jail") {
      lifeText = "Jailed";
      lifeBarColor = Colors.brown[300];
    } else if (_retal!.status.state == "Okay") {
      lifeText = "Okay";
      lifeBarColor = Colors.green[300];
    } else if (_retal!.status.state == "Traveling") {
      lifeText = "Okay";
      lifeBarColor = Colors.blue[300];
    } else if (_retal!.status.state == "Abroad") {
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

  Widget _returnFullHealth(Retal? target) {
    Color? lifeBarColor = Colors.green;
    Widget hospitalWarning = const SizedBox.shrink();
    String lifeText = _retal!.lifeCurrent == -1 ? "?" : _retal!.lifeCurrent.toString();

    if (_retal!.status.state == "Hospital") {
      // Handle if target is still in hospital
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      if (_retal!.status.until! > now) {
        final endTimeStamp = DateTime.fromMillisecondsSinceEpoch(target!.status.until! * 1000);
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

    if (_retal!.status.state == "Traveling" || _retal!.status.state == "Abroad") {
      lifeBarColor = Colors.blue[300];
    }

    // Found players in federal jail with a higher life than their maximum. Correct it if it's the
    // case to avoid issues with percentage bar
    double? lifePercentage;
    if (_retal!.lifeCurrent != -1) {
      if (_retal!.lifeCurrent! / _retal!.lifeMaximum! > 1) {
        lifePercentage = 1;
      } else if (_retal!.lifeCurrent! / _retal!.lifeMaximum! > 1) {
        lifePercentage = 0;
      } else {
        lifePercentage = _retal!.lifeCurrent! / _retal!.lifeMaximum!;
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
    final country = countryCheck(state: _retal!.status.state, description: _retal!.status.description);

    if (_retal!.status.color == "blue" || (country != "Torn" && _retal!.status.color == "red")) {
      final destination = _retal!.status.color == "blue" ? _retal!.status.description! : country;
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
                text: _retal!.status.description!,
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
                    quarterTurns: _retal!.status.description!.contains('Traveling to ')
                        ? 1 // If traveling to another country
                        : _retal!.status.description!.contains('Returning ')
                            ? 3 // If returning to Torn
                            : 0, // If staying abroad (blue but not moving)
                    child: Icon(
                      _retal!.status.description!.contains('In ')
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

  Widget _statsWidget() {
    void _showDetailedStatsDialog() {
      String lastUpdated = "";
      if (_retal!.statsExactUpdated != 0) {
        lastUpdated = readTimestamp(_retal!.statsExactUpdated!);
      }

      Widget strWidget;
      if (_retal!.statsStr == -1) {
        strWidget = const Text(
          "Strength: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var strDiff = "";
        Color strColor;
        final result = _userProvider.basic!.strength! - _retal!.statsStr!;
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
              "Strength: ${formatBigNumbers(_retal!.statsStr!)}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              strDiff,
              style: TextStyle(fontSize: 12, color: strColor),
            ),
          ],
        );
      }

      Widget spdWidget;
      if (_retal!.statsSpd == -1) {
        spdWidget = const Text(
          "Speed: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var spdDiff = "";
        Color spdColor;
        final result = _userProvider.basic!.speed! - _retal!.statsSpd!;
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
              "Speed: ${formatBigNumbers(_retal!.statsSpd!)}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              spdDiff,
              style: TextStyle(fontSize: 12, color: spdColor),
            ),
          ],
        );
      }

      Widget defWidget;
      if (_retal!.statsDef == -1) {
        defWidget = const Text(
          "Defense: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var defDiff = "";
        Color defColor;
        final result = _userProvider.basic!.defense! - _retal!.statsDef!;
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
              "Defense: ${formatBigNumbers(_retal!.statsDef!)}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              defDiff,
              style: TextStyle(fontSize: 12, color: defColor),
            ),
          ],
        );
      }

      Widget dexWidget;
      if (_retal!.statsDex == -1) {
        dexWidget = const Text(
          "Dexterity: unknown",
          style: TextStyle(fontSize: 12),
        );
      } else {
        var dexDiff = "";
        Color dexColor;
        final result = _userProvider.basic!.dexterity! - _retal!.statsDex!;
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
              "Dexterity: ${formatBigNumbers(_retal!.statsDex!)}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              dexDiff,
              style: TextStyle(fontSize: 12, color: dexColor),
            ),
          ],
        );
      }

      Widget totalWidget;
      if (_retal!.statsExactTotal == -1) {
        totalWidget = Text(
          "TOTAL: unknown (>${formatBigNumbers(_retal!.statsExactTotalKnown)})",
          style: const TextStyle(fontSize: 12),
        );
      } else {
        var totalDiff = "";
        Color totalColor;
        final result = _userProvider.basic!.total! - _retal!.statsExactTotal!;
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
              "TOTAL: ${formatBigNumbers(_retal!.statsExactTotal!)}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              totalDiff,
              style: TextStyle(fontSize: 12, color: totalColor),
            ),
          ],
        );
      }

      Widget sourceWidget = const SizedBox.shrink();
      if (widget.retalModel.spiesSource.isNotEmpty) {
        sourceWidget = Row(
          children: [
            const Text(
              "Source: ",
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(
              height: 16,
              width: 16,
              child: Image.asset(
                widget.retalModel.spiesSource == "yata"
                    ? 'images/icons/yata_logo.png'
                    : 'images/icons/tornstats_logo.png',
              ),
            ),
          ],
        );
      }

      BotToast.showAnimationWidget(
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
                animation: controller,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black26),
                  child: SizedBox.expand(),
                ),
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
          title: Text(_retal!.name!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_retal!.factionName != "0")
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    "Faction: ${_retal!.factionName}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (lastUpdated.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    "Updated: $lastUpdated",
                    style: const TextStyle(fontSize: 12),
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
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 4),
                child: sourceWidget,
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
        animationDuration: const Duration(milliseconds: 300),
      );
    }

    if (_retal!.statsExactTotalKnown != -1) {
      Color? exactColor = Colors.green;
      if (_userProvider.basic!.total! < _retal!.statsExactTotalKnown - _retal!.statsExactTotalKnown * 0.1) {
        exactColor = Colors.red[700];
      } else if ((_userProvider.basic!.total! >= _retal!.statsExactTotalKnown - _retal!.statsExactTotalKnown * 0.1) &&
          (_userProvider.basic!.total! <= _retal!.statsExactTotalKnown + _retal!.statsExactTotalKnown * 0.1)) {
        exactColor = Colors.orange[700];
      }

      int totalToShow = 0;
      if (_retal!.statsExactTotal != -1) {
        // TornStats adds all 4 stats into total if total is unknown, but then rounds. So it might happen that the
        // total sum is actually higher than the one calculated and rounded by TS
        totalToShow = max(_retal!.statsExactTotal!, _retal!.statsExactTotalKnown);
      } else {
        totalToShow = _retal!.statsExactTotalKnown;
      }

      bool someStatUnknown = false;
      if (_retal!.statsStr == -1 || _retal!.statsDef == -1 || _retal!.statsDex == -1 || _retal!.statsSpd == -1) {
        someStatUnknown = true;
      }

      return Row(
        children: [
          Text(
            formatBigNumbers(totalToShow),
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
              _showDetailedStatsDialog();
            },
          ),
        ],
      );
    } else if (_retal!.statsEstimated.isNotEmpty) {
      if (!_retal!.statsComparisonSuccess) {
        return const Text(
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
      Color? enhancementColor = _themeProvider.mainText;
      int cansComparison = 0;
      Color cansColor = Colors.orange;
      Color sslColor = Colors.green;
      bool sslProb = true;
      int? ecstasy = 0;
      int? lsd = 0;

      List<Widget> additional = <Widget>[];
      // XANAX
      final int otherXanax = _retal!.retalXanax!;
      final int myXanax = _retal!.myXanax!;
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
      final int otherRefill = _retal!.retalRefill!;
      final int myRefill = _retal!.myRefill!;
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
      final int otherEnhancement = _retal!.retalEnhancement!;
      final int myEnhancement = _retal!.myEnhancement!;
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
      final int otherCans = _retal!.retalCans!;
      final int myCans = _retal!.myCans!;
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
      ecstasy = _retal!.retalEcstasy;
      lsd = _retal!.retalLsd;
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
            _retal!.statsEstimated,
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
                _retal!,
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
    _retal!.status.until = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startAttack() async {
    final browserType = _settingsProvider.currentBrowser;
    switch (browserType) {
      case BrowserSetting.app:
        List<RetalsCardDetails> myTargetList = _r.orderedCardsDetails;

        // Adjust the list (remove targets above the one selected)
        myTargetList.removeRange(0, myTargetList.indexWhere((element) => element.retalId == _retal!.retalId));

        List<String> attacksIds = <String>[];
        List<String?> attacksNames = <String?>[];
        List<String?> attackNotes = <String?>[];
        List<String?> attacksNotesColor = <String?>[];
        for (final tar in myTargetList) {
          attacksIds.add(tar.retalId.toString());
          attacksNames.add(tar.name);
          attackNotes.add(tar.personalNote);
          attacksNotesColor.add(tar.personalNoteColor);
        }

        final bool showNotes = await Prefs().getShowTargetsNotes();
        final bool showBlankNotes = await Prefs().getShowBlankTargetsNotes();
        final bool showOnlineFactionWarning = await Prefs().getShowOnlineFactionWarning();

        _r.browserIsOpen = true;
        await _webViewProvider.openBrowserPreference(
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
        _r.browserIsOpen = false;

      case BrowserSetting.external:
        final url = 'https://www.torn.com/loader.php?sid=attack&user2ID=${_retal!.retalId}';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
    }
  }

  Widget _lastOnlineWidget() {
    return Row(
      children: [
        if (_retal!.lastAction.status == "Offline")
          const Icon(Icons.remove_circle, size: 12, color: Colors.grey)
        else
          _retal!.lastAction.status == "Idle"
              ? const Icon(Icons.adjust, size: 12, color: Colors.orange)
              : const Icon(Icons.circle, size: 12, color: Colors.green),
        if (_retal!.lastAction.status == "Offline" || _retal!.lastAction.status == "Idle")
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              _retal!.lastAction.relative!
                  .replaceAll("minute ago", "m")
                  .replaceAll("minutes ago", "m")
                  .replaceAll("hour ago", "h")
                  .replaceAll("hours ago", "h")
                  .replaceAll("day ago", "d")
                  .replaceAll("days ago", "d"),
              style: TextStyle(
                fontSize: 11,
                color: _retal!.lastAction.status == "Idle" ? Colors.orange : Colors.grey,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              "Online",
              style: TextStyle(
                fontSize: 11,
                color: Colors.green,
              ),
            ),
          )
      ],
    );
  }

  void _showEstimatedDetailsDialog(
    int xanaxCompare,
    Color xanaxColor,
    int refillCompare,
    Color refillColor,
    int enhancementCompare,
    Color? enhancementColor,
    int cansCompare,
    Color cansColor,
    Color sslColor,
    bool sslProb,
    Retal retal,
  ) {
    String xanaxRelative = "";
    if (xanaxCompare > 0) {
      xanaxRelative = "${xanaxCompare.abs()} MORE than you";
    } else if (xanaxCompare == 0) {
      xanaxRelative = "SAME as you";
    } else {
      xanaxRelative = "${xanaxCompare.abs()} LESS than you";
    }
    final Widget xanaxWidget = Row(
      children: [
        const Text(
          "> Xanax: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            xanaxRelative,
            style: TextStyle(color: xanaxColor, fontSize: 14),
          ),
        ),
      ],
    );

    String refillRelative = "";
    if (refillCompare > 0) {
      refillRelative = "${refillCompare.abs()} MORE than you";
    } else if (refillCompare == 0) {
      refillRelative = "SAME as you";
    } else {
      refillRelative = "${refillCompare.abs()} LESS than you";
    }
    final Widget refillWidget = Row(
      children: [
        const Text(
          "> (E) Refills: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            refillRelative,
            style: TextStyle(color: refillColor, fontSize: 14),
          ),
        ),
      ],
    );

    String enhancementRelative = "";
    if (enhancementColor == Colors.white) enhancementColor = _themeProvider.mainText;
    if (enhancementCompare > 0) {
      enhancementRelative = "${enhancementCompare.abs()} MORE than you";
    } else if (enhancementCompare == 0) {
      enhancementRelative = "SAME as you";
    } else if (enhancementCompare < 0) {
      enhancementRelative = "${enhancementCompare.abs()} LESS than you";
    }
    final Widget enhancementWidget = Row(
      children: [
        const Text(
          "> Enhancer(s): ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            enhancementRelative,
            style: TextStyle(color: enhancementColor, fontSize: 14),
          ),
        ),
      ],
    );

    String cansRelative = "";
    if (cansCompare > 0) {
      cansRelative = "${cansCompare.abs()} MORE than you";
    } else if (cansCompare == 0) {
      cansRelative = "SAME as you";
    } else if (cansCompare < 0) {
      cansRelative = "${cansCompare.abs()} LESS than you";
    }
    final Widget cansWidget = Row(
      children: [
        const Text(
          "> Cans: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            cansRelative,
            style: TextStyle(color: cansColor, fontSize: 14),
          ),
        ),
      ],
    );

    final Widget sslWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "> SSL probability: ",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              !sslProb
                  ? "none"
                  : sslColor == Colors.green
                      ? "low"
                      : sslColor == Colors.orange
                          ? "med"
                          : "high",
              style: TextStyle(
                color: sslColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 12),
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
                "Xanax: ${retal.retalXanax}",
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                "Ecstasy: ${retal.retalEcstasy}",
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                "LSD: ${retal.retalLsd}",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    BotToast.showAnimationWidget(
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
              animation: controller,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
                child: SizedBox.expand(),
              ),
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
        title: Text(retal.name!),
        backgroundColor: _themeProvider.secondBackground,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (retal.factionName != "0")
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Faction: ${retal.factionName}",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (retal.lastAction.relative!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Online: ${retal.lastAction.relative!.replaceAll("0 minutes ago", "now")}",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4),
              child: xanaxWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4),
              child: refillWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4),
              child: enhancementWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4),
              child: cansWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4),
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
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}

class CurrentRetalExpiryWidget extends StatefulWidget {
  final int expiryTimeStamp;

  const CurrentRetalExpiryWidget({
    required this.expiryTimeStamp,
    super.key,
  });

  @override
  State<CurrentRetalExpiryWidget> createState() => CurrentRetalExpiryWidgetState();
}

class CurrentRetalExpiryWidgetState extends State<CurrentRetalExpiryWidget> {
  Timer? _expiryTicker;
  Widget _currentExpiryWidget = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    _timerExpiry();
    _expiryTicker = Timer.periodic(const Duration(seconds: 1), (Timer t) => _timerExpiry());
  }

  @override
  void dispose() {
    _expiryTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _currentExpiryWidget;
  }

  void _timerExpiry() {
    String diffText = "";
    Color diffColor = Colors.green;

    final dateTimeFightEnded = DateTime.fromMillisecondsSinceEpoch(widget.expiryTimeStamp * 1000);
    final timeDifference = dateTimeFightEnded.difference(DateTime.now());

    if (timeDifference.inSeconds <= 0) {
      diffText = "EXPIRED";
      diffColor = Colors.red;
    } else {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      final String twoDigitSeconds = twoDigits(timeDifference.inSeconds.remainder(60).abs());
      diffText = 'EXPIRES IN ${twoDigits(timeDifference.inMinutes.abs())}:$twoDigitSeconds';

      if (timeDifference.inSeconds < 60) {
        diffColor = Colors.orange;
      }
    }

    if (mounted) {
      setState(() {
        _currentExpiryWidget = Text(
          diffText,
          style: TextStyle(color: diffColor),
        );
      });
    }
  }
}
