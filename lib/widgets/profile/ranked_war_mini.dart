import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';

class RankedWarMini extends StatefulWidget {
  final RankedWar? rankedWar;
  final String? playerFactionName;
  final String? playerFactionTag;

  const RankedWarMini({
    required this.rankedWar,
    required this.playerFactionName,
    required this.playerFactionTag,
    super.key,
  });

  @override
  State<RankedWarMini> createState() => RankedWarMiniState();
}

class RankedWarMiniState extends State<RankedWarMini> {
  String _timeString = "";

  WarFaction _playerFaction = WarFaction();
  WarFaction _enemyFaction = WarFaction();

  Timer? _tickerCall;

  @override
  void initState() {
    super.initState();

    widget.rankedWar!.factions!.forEach((key, value) {
      if (value.name == widget.playerFactionName) {
        _playerFaction = value;
      } else {
        _enemyFaction = value;
      }
    });

    if (widget.rankedWar!.war!.start! * 1000 > DateTime.now().millisecondsSinceEpoch) {
      _tickerCall = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        _updateTimeString();
      });
    }
  }

  @override
  void dispose() {
    _tickerCall?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final bool warInFuture = widget.rankedWar!.war!.start! * 1000 > ts;
    final bool warActive = widget.rankedWar!.war!.start! * 1000 < ts && widget.rankedWar!.war!.end == 0;
    SettingsProvider settingsProvider = context.read<SettingsProvider>();

    if (warInFuture) {
      final bool lessThan24h = widget.rankedWar!.war!.start! * 1000 - ts < 86400000;
      final dt = DateTime.fromMillisecondsSinceEpoch(widget.rankedWar!.war!.start! * 1000);
      return Container(
        decoration: lessThan24h
            ? BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: Colors.orange[700]!,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(MaterialCommunityIcons.sword_cross, color: Colors.orange[700]),
            const SizedBox(width: 5),
            Column(
              children: [
                Text(
                  _timeString,
                  style: TextStyle(
                    fontWeight: lessThan24h ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  TimeFormatter(
                    inputTime: dt,
                    timeFormatSetting: settingsProvider.currentTimeFormat,
                    timeZoneSetting: settingsProvider.currentTimeZone,
                  ).formatHourWithDaysElapsed(includeToday: true),
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (warActive) {
      final int progress = (_playerFaction.score! - _enemyFaction.score!).abs();
      final double percentage = progress * 100 / widget.rankedWar!.war!.target!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
        child: Row(
          children: [
            Icon(MaterialCommunityIcons.sword_cross, color: Colors.orange[700]),
            const SizedBox(width: 5),
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      children: [
                        if (widget.playerFactionTag!.isNotEmpty)
                          Text(
                            widget.playerFactionTag!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                            ),
                          ),
                        Text(
                          "${_playerFaction.score}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _playerFaction.score! >= _enemyFaction.score! ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      " vs ",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "${_enemyFaction.score}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _playerFaction.score! <= _enemyFaction.score! ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                LinearPercentIndicator(
                  padding: const EdgeInsets.all(0),
                  barRadius: const Radius.circular(10),
                  alignment: MainAxisAlignment.center,
                  width: 130,
                  lineHeight: 12,
                  progressColor: Colors.green[800],
                  backgroundColor: Colors.grey[800],
                  center: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(
                      '$progress/${widget.rankedWar!.war!.target}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  percent: percentage / 100 > 1.0 ? 1.0 : percentage / 100,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  _updateTimeString() {
    final dt = DateTime.fromMillisecondsSinceEpoch(widget.rankedWar!.war!.start! * 1000);
    final timeDifference = dt.difference(DateTime.now());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final String twoDigitHours = twoDigits(timeDifference.inHours.remainder(24));
    final String twoDigitMinutes = twoDigits(timeDifference.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(timeDifference.inSeconds.remainder(60));
    String diff = '${timeDifference.inDays}d ${twoDigitHours}h '
        '${twoDigitMinutes}m ${twoDigitSeconds}s';
    diff = diff.replaceAll("0d 00h ", "");
    diff = diff.replaceAll("0d ", "");
    setState(() {
      _timeString = diff;
    });
  }
}
