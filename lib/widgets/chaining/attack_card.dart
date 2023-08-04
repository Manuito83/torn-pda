// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/chaining/attack_model.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class AttackCard extends StatefulWidget {
  final Attack attackModel;

  const AttackCard({required this.attackModel});

  @override
  _AttackCardState createState() => _AttackCardState();
}

class _AttackCardState extends State<AttackCard> {
  late Attack _attack;
  late ThemeProvider _themeProvider;
  late UserDetailsProvider _userProvider;

  bool _addButtonActive = true;

  @override
  Widget build(BuildContext context) {
    _attack = widget.attackModel;
    _themeProvider = Provider.of<ThemeProvider>(context);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
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
              padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
              child: Row(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                        width: _attack.targetName!.isNotEmpty ? 20 : 0,
                        child: _attack.targetName!.isNotEmpty
                            ? GestureDetector(
                                child: const Icon(
                                  Icons.remove_red_eye,
                                  size: 20,
                                ),
                                onTap: () async {
                                  final url = 'https://www.torn.com/profiles.php?XID=${_attack.targetId}';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () async {
                                  final url = 'https://www.torn.com/profiles.php?XID=${_attack.targetId}';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                      ),
                      SizedBox(
                        width: _attack.targetName!.isNotEmpty ? 70 : 175,
                        child: Text(
                          _attack.targetName!.isNotEmpty ? '${_attack.targetName}' : "anonymous",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: _attack.targetName!.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            fontStyle: _attack.targetName!.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        SizedBox(
                          width: _attack.targetName!.isNotEmpty ? 85 : 0,
                          child: Text(
                            _attack.targetName!.isNotEmpty ? ' [${_attack.targetId}]' : "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _returnTargetLevel(),
                        Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: _factionIcon(),
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: _attack.targetName!.isNotEmpty ? _returnAddTargetButton() : const SizedBox.shrink(),
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
              padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(_returnDateFormatted()),
                  _returnRespect(),
                ],
              ),
            ),
            // LINE 3
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: [
                      const Text('Last results: '),
                      _returnLastResults(),
                    ],
                  ),
                  _returnFairFight(),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _returnAddTargetButton() {
    bool existingTarget = false;

    final targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    final targetList = targetsProvider.allTargets;
    for (final tar in targetList) {
      if (tar.playerId.toString() == _attack.targetId) {
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
          targetsProvider.deleteTargetById(_attack.targetId);
          BotToast.showText(
            text: HtmlParser.fix('Removed ${_attack.targetName}!'),
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
        onPressed: () async {
          setState(() {
            _addButtonActive = false;
          });

          final AddTargetResult tryAddTarget = await targetsProvider.addTarget(
            targetId: _attack.targetId,
            attacks: await targetsProvider.getAttacks(),
          );
          if (tryAddTarget.success) {
            BotToast.showText(
              text: HtmlParser.fix('Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}]'),
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green[700]!,
              duration: const Duration(seconds: 5),
              contentPadding: const EdgeInsets.all(10),
            );
            // Update the button
            if (mounted) {
              setState(() {
                _addButtonActive = true;
              });
            }
          } else if (!tryAddTarget.success) {
            BotToast.showText(
              text: HtmlParser.fix('Error adding ${_attack.targetId}. ${tryAddTarget.errorReason}'),
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.red[900]!,
              duration: const Duration(seconds: 5),
              contentPadding: const EdgeInsets.all(10),
            );
          }
        },
      );
    }
  }

  Widget _returnTargetLevel() {
    if (_attack.attackInitiated) {
      if (_attack.attackWon) {
        return Text('Level ${_attack.targetLevel}');
      } else {
        return const Text('[lost]',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red,
            ),);
      }
    } else {
      if (_attack.attackWon) {
        return const Text('[lost]',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red,
            ),);
      } else {
        return const Text(
          '[defended]',
          style: TextStyle(fontSize: 13),
        );
      }
    }
  }

  String _returnDateFormatted() {
    final date = DateTime.fromMillisecondsSinceEpoch(_attack.timestampEnded! * 1000);
    final formatter = DateFormat('dd MMMM HH:mm');
    return formatter.format(date);
  }

  Widget _returnRespect() {
    dynamic respect = _attack.respectGain;
    if (respect is String) {
      respect = double.parse(respect);
    }

    TextSpan respectSpan;
    if ((_attack.attackInitiated && !_attack.attackWon) || (!_attack.attackInitiated && _attack.attackWon)) {
      // If we attacked and lost, or someone attacked us and won
      // we just show '0' but in red to indicate that we lost
      respectSpan = const TextSpan(
        text: '0',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (_attack.attackInitiated && _attack.attackWon) {
      // If we attacked and won, we show the actual respect
      respectSpan = TextSpan(
        text: respect.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _themeProvider.mainText,
        ),
      );
    } else {
      // Else (if someone attacked and lost (we defended successfully), we
      // don't gain any respect at all
      respectSpan = TextSpan(
        text: '0',
        style: TextStyle(
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
          respectSpan,
        ],
      ),
    );
  }

  Widget _returnFairFight() {
    dynamic ff = _attack.modifiers!.fairFight;
    if (ff is String) {
      ff = double.parse(ff);
    }

    var ffColor = Colors.red;
    if (ff >= 2.2 && ff < 2.8) {
      ffColor = Colors.orange;
    } else if (ff >= 2.8) {
      ffColor = Colors.green;
    }

    TextSpan ffSpan;
    ffSpan = TextSpan(
      text: ff.toString(),
      style: TextStyle(
        color: ffColor,
        fontWeight: FontWeight.bold,
      ),
    );

    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: 'Fair Fight: ',
            style: TextStyle(
              color: _themeProvider.mainText,
            ),
          ),
          ffSpan,
        ],
      ),
    );
  }

  Widget _returnLastResults() {
    final results = <Widget>[];

    final Widget firstResult = Padding(
      padding: const EdgeInsets.only(left: 3, right: 8, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
            color: _attack.attackSeriesGreen[0] ? Colors.green : Colors.red,
            shape: BoxShape.circle,
            border: Border.all(),),
      ),
    );

    results.add(firstResult);

    if (_attack.attackSeriesGreen.length > 1) {
      for (var i = 1; i < _attack.attackSeriesGreen.length; i++) {
        if (i == 10) {
          break;
        }

        final Widget anotherResult = Padding(
          padding: const EdgeInsets.only(right: 5, top: 2),
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
                color: _attack.attackSeriesGreen[i] ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(),),
          ),
        );

        results.add(anotherResult);
      }
    }

    return Row(children: results);
  }

  Widget _factionIcon() {
    String? factionName = "";
    int? factionId = 0;
    if (_attack.attackInitiated) {
      if (_attack.defenderFactionname != null && _attack.defenderFactionname != "") {
        factionName = _attack.defenderFactionname;
        factionId = _attack.defenderFaction;
      } else {
        return const SizedBox.shrink();
      }
    } else {
      if (_attack.attackerFactionname != null && _attack.attackerFactionname != "") {
        factionName = _attack.attackerFactionname;
        factionId = _attack.attackerFaction;
      } else {
        return const SizedBox.shrink();
      }
    }

    Color? borderColor = Colors.transparent;
    Color? iconColor = _themeProvider.mainText;
    if (factionId == _userProvider.basic!.faction!.factionId) {
      borderColor = iconColor = Colors.green[500];
    }

    void showFactionToast() {
      if (factionId == _userProvider.basic!.faction!.factionId) {
        BotToast.showText(
          text: HtmlParser.fix("${_attack.targetName} belongs to your same faction ($factionName)"),
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.green,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      } else {
        BotToast.showText(
          text: HtmlParser.fix("${_attack.targetName} belongs to faction $factionName"),
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      }
    }

    final Widget factionIcon = Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor!,
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
            padding: const EdgeInsets.all(2),
            child: ImageIcon(
              const AssetImage('images/icons/faction.png'),
              size: 12,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
    return factionIcon;
  }
}
