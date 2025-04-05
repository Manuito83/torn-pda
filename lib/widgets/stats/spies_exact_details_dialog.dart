import 'package:flutter/material.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';

class SpiesExactDetailsDialog extends StatelessWidget {
  final SpiesPayload spiesPayload;
  final ThemeProvider themeProvider;

  const SpiesExactDetailsDialog({
    Key? key,
    required this.spiesPayload,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final oneMonthAgo = currentTime - (30.44 * 24 * 60 * 60 * 1000).round();
    final strUpdateColor = (spiesPayload.strengthUpdate != null && spiesPayload.strengthUpdate! * 1000 < oneMonthAgo)
        ? Colors.red
        : themeProvider.mainText;
    final defUpdateColor = (spiesPayload.defenseUpdate != null && spiesPayload.defenseUpdate! * 1000 < oneMonthAgo)
        ? Colors.red
        : themeProvider.mainText;
    final spdUpdateColor = (spiesPayload.speedUpdate != null && spiesPayload.speedUpdate! * 1000 < oneMonthAgo)
        ? Colors.red
        : themeProvider.mainText;
    final dexUpdateColor = (spiesPayload.dexterityUpdate != null && spiesPayload.dexterityUpdate! * 1000 < oneMonthAgo)
        ? Colors.red
        : themeProvider.mainText;
    final totalUpdateColor = (spiesPayload.totalUpdate != null && spiesPayload.totalUpdate! * 1000 < oneMonthAgo)
        ? Colors.red
        : themeProvider.mainText;

    Color lastSpyUpdateColor = themeProvider.mainText;
    if (spiesPayload.update != null) {
      lastSpyUpdateColor = (spiesPayload.update! * 1000 < oneMonthAgo) ? Colors.red : themeProvider.mainText;
    }

    Widget strWidget;
    if (spiesPayload.strength == null || spiesPayload.strength == -1) {
      strWidget = const Text(
        "Strength: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var strDiff = "";
      Color strColor;
      final result = spiesPayload.userDetailsProvider.basic!.strength! - spiesPayload.strength!;
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
            "Strength: ${formatBigNumbers(spiesPayload.strength!)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            strDiff,
            style: TextStyle(fontSize: 12, color: strColor),
          ),
          spiesPayload.strengthUpdate != null
              ? Text(
                  spiesPayload.spyController.statsOld(spiesPayload.strengthUpdate),
                  style: TextStyle(fontSize: 10, color: strUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget spdWidget;
    if (spiesPayload.speed == null || spiesPayload.speed == -1) {
      spdWidget = const Text(
        "Speed: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var spdDiff = "";
      Color spdColor;
      final result = spiesPayload.userDetailsProvider.basic!.speed! - spiesPayload.speed!;
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
            "Speed: ${formatBigNumbers(spiesPayload.speed!)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            spdDiff,
            style: TextStyle(fontSize: 12, color: spdColor),
          ),
          spiesPayload.speedUpdate != null
              ? Text(
                  spiesPayload.spyController.statsOld(spiesPayload.speedUpdate),
                  style: TextStyle(fontSize: 10, color: spdUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget defWidget;
    if (spiesPayload.defense == null || spiesPayload.defense == -1) {
      defWidget = const Text(
        "Defense: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var defDiff = "";
      Color defColor;
      final result = spiesPayload.userDetailsProvider.basic!.defense! - spiesPayload.defense!;
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
            "Defense: ${formatBigNumbers(spiesPayload.defense!)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            defDiff,
            style: TextStyle(fontSize: 12, color: defColor),
          ),
          spiesPayload.defenseUpdate != null
              ? Text(
                  spiesPayload.spyController.statsOld(spiesPayload.defenseUpdate),
                  style: TextStyle(fontSize: 10, color: defUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget dexWidget;
    if (spiesPayload.dexterity == null || spiesPayload.dexterity == -1) {
      dexWidget = const Text(
        "Dexterity: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var dexDiff = "";
      Color dexColor;
      final result = spiesPayload.userDetailsProvider.basic!.dexterity! - spiesPayload.dexterity!;
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
            "Dexterity: ${formatBigNumbers(spiesPayload.dexterity!)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            dexDiff,
            style: TextStyle(fontSize: 12, color: dexColor),
          ),
          spiesPayload.dexterityUpdate != null
              ? Text(
                  spiesPayload.spyController.statsOld(spiesPayload.dexterityUpdate),
                  style: TextStyle(fontSize: 10, color: dexUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget totalWidget;
    if (spiesPayload.total == null || spiesPayload.total == -1) {
      totalWidget = const Text(
        "TOTAL: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var totalDiff = "";
      Color totalColor;
      final result = spiesPayload.userDetailsProvider.basic!.total! - spiesPayload.total!;
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
            "TOTAL: ${formatBigNumbers(spiesPayload.total!)}",
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            totalDiff,
            style: TextStyle(fontSize: 12, color: totalColor),
          ),
          spiesPayload.totalUpdate != null
              ? Text(
                  spiesPayload.spyController.statsOld(spiesPayload.totalUpdate),
                  style: TextStyle(fontSize: 10, color: totalUpdateColor),
                )
              : SizedBox.shrink(),
        ],
      );
    }

    Widget sourceWidget = const SizedBox.shrink();
    if (spiesPayload.spyController.spiesSource != null) {
      sourceWidget = Row(
        children: [
          const Text(
            "Source: ",
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(
            height: 18,
            width: 18,
            child: Image.asset(
              spiesPayload.spySource == SpiesSource.yata
                  ? 'images/icons/yata_logo.png'
                  : 'images/icons/tornstats_logo.png',
            ),
          ),
          if (spiesPayload.spySource != spiesPayload.spyController.spiesSource)
            Text(
              "(mixed source)",
              style: TextStyle(fontSize: 12),
            ),
        ],
      );
    }

    String faction = spiesPayload.factionName ?? "";
    return Container(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "SPIED STATS",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (faction != "0" && faction.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    "Faction: ${spiesPayload.factionName}",
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
                      spiesPayload.spyController.statsOld(spiesPayload.update),
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
      ),
    );
  }
}
