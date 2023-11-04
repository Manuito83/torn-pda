import 'package:flutter/material.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class SpiesExactDetailsDialog extends StatelessWidget {
  const SpiesExactDetailsDialog({
    super.key,
    required this.spy,
    required this.strength,
    required this.strengthUpdate,
    required this.defense,
    required this.defenseUpdate,
    required this.speed,
    required this.speedUpdate,
    required this.dexterity,
    required this.dexterityUpdate,
    required this.total,
    required this.totalUpdate,
    required this.update,
    required this.name,
    required this.factionName,
    required this.themeProvider,
    required this.userDetailsProvider,
  });

  final SpiesController spy;
  final int strength;
  final int? strengthUpdate;
  final int defense;
  final int? defenseUpdate;
  final int speed;
  final int? speedUpdate;
  final int dexterity;
  final int? dexterityUpdate;
  final int total;
  final int? totalUpdate;
  final int update;
  final String name;
  final String factionName;
  final ThemeProvider themeProvider;
  final UserDetailsProvider userDetailsProvider;

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final oneMonthAgo = currentTime - (30.44 * 24 * 60 * 60 * 1000).round();
    final strUpdateColor =
        (strengthUpdate != null && strengthUpdate! * 1000 < oneMonthAgo) ? Colors.red : themeProvider.mainText;
    final defUpdateColor =
        (defenseUpdate != null && defenseUpdate! * 1000 < oneMonthAgo) ? Colors.red : themeProvider.mainText;
    final spdUpdateColor =
        (speedUpdate != null && speedUpdate! * 1000 < oneMonthAgo) ? Colors.red : themeProvider.mainText;
    final dexUpdateColor =
        (dexterityUpdate != null && dexterityUpdate! * 1000 < oneMonthAgo) ? Colors.red : themeProvider.mainText;
    final totalUpdateColor =
        (totalUpdate != null && totalUpdate! * 1000 < oneMonthAgo) ? Colors.red : themeProvider.mainText;
    final lastSpyUpdateColor = (update * 1000 < oneMonthAgo) ? Colors.red : themeProvider.mainText;

    Widget strWidget;
    if (strength == -1) {
      strWidget = const Text(
        "Strength: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var strDiff = "";
      Color strColor;
      final result = userDetailsProvider.basic!.strength! - strength;
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
            "Strength: ${formatBigNumbers(strength)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            strDiff,
            style: TextStyle(fontSize: 12, color: strColor),
          ),
          strengthUpdate != null
              ? Text(
                  spy.statsOld(strengthUpdate),
                  style: TextStyle(fontSize: 10, color: strUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget spdWidget;
    if (speed == -1) {
      spdWidget = const Text(
        "Speed: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var spdDiff = "";
      Color spdColor;
      final result = userDetailsProvider.basic!.speed! - speed;
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
            "Speed: ${formatBigNumbers(speed)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            spdDiff,
            style: TextStyle(fontSize: 12, color: spdColor),
          ),
          speedUpdate != null
              ? Text(
                  spy.statsOld(speedUpdate),
                  style: TextStyle(fontSize: 10, color: spdUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget defWidget;
    if (defense == -1) {
      defWidget = const Text(
        "Defense: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var defDiff = "";
      Color defColor;
      final result = userDetailsProvider.basic!.defense! - defense;
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
            "Defense: ${formatBigNumbers(defense)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            defDiff,
            style: TextStyle(fontSize: 12, color: defColor),
          ),
          defenseUpdate != null
              ? Text(
                  spy.statsOld(defenseUpdate),
                  style: TextStyle(fontSize: 10, color: defUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget dexWidget;
    if (dexterity == -1) {
      dexWidget = const Text(
        "Dexterity: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var dexDiff = "";
      Color dexColor;
      final result = userDetailsProvider.basic!.dexterity! - dexterity;
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
            "Dexterity: ${formatBigNumbers(dexterity)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            dexDiff,
            style: TextStyle(fontSize: 12, color: dexColor),
          ),
          dexterityUpdate != null
              ? Text(
                  spy.statsOld(dexterityUpdate),
                  style: TextStyle(fontSize: 10, color: dexUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget totalWidget;
    if (total == -1) {
      totalWidget = const Text(
        "TOTAL: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var totalDiff = "";
      Color totalColor;
      final result = userDetailsProvider.basic!.total! - total;
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
            "TOTAL: ${formatBigNumbers(total)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            totalDiff,
            style: TextStyle(fontSize: 12, color: totalColor),
          ),
          totalUpdate != null
              ? Text(
                  spy.statsOld(totalUpdate),
                  style: TextStyle(fontSize: 10, color: totalUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget sourceWidget = const SizedBox.shrink();
    if (spy.spiesSource != null) {
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
              spy.spiesSource == SpiesSource.yata ? 'images/icons/yata_logo.png' : 'images/icons/tornstats_logo.png',
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      title: name.isNotEmpty ? Text(name) : const Text("Spied stats"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (factionName != "0" && factionName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  "Faction: $factionName",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Text(
                    "Last spy: ",
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    spy.statsOld(update),
                    style: TextStyle(fontSize: 12, color: lastSpyUpdateColor),
                  ),
                ],
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
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Thanks'),
        ),
      ],
    );
  }
}
