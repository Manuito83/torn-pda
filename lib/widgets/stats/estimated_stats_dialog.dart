import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';

class EstimatedStatsDialog extends StatelessWidget {
  const EstimatedStatsDialog({
    required this.estimatedStatsPayload,
    required this.themeProvider,
  });

  final EstimatedStatsPayload estimatedStatsPayload;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    String xanaxRelative = "";
    if (estimatedStatsPayload.xanaxCompare > 0) {
      xanaxRelative = "${estimatedStatsPayload.xanaxCompare.abs()} MORE than you";
    } else if (estimatedStatsPayload.xanaxCompare == 0) {
      xanaxRelative = "SAME as you";
    } else {
      xanaxRelative = "${estimatedStatsPayload.xanaxCompare.abs()} LESS than you";
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
            style: TextStyle(color: estimatedStatsPayload.xanaxColor, fontSize: 14),
          ),
        ),
      ],
    );

    String refillRelative = "";
    if (estimatedStatsPayload.refillCompare > 0) {
      refillRelative = "${estimatedStatsPayload.refillCompare.abs()} MORE than you";
    } else if (estimatedStatsPayload.refillCompare == 0) {
      refillRelative = "SAME as you";
    } else {
      refillRelative = "${estimatedStatsPayload.refillCompare.abs()} LESS than you";
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
            style: TextStyle(color: estimatedStatsPayload.refillColor, fontSize: 14),
          ),
        ),
      ],
    );

    String enhancementRelative = "";
    Color? enhColor = estimatedStatsPayload.enhancementColor;
    if (enhColor == Colors.white) enhColor = themeProvider.mainText;
    if (estimatedStatsPayload.enhancementCompare > 0) {
      enhancementRelative = "${estimatedStatsPayload.enhancementCompare.abs()} MORE than you";
    } else if (estimatedStatsPayload.enhancementCompare == 0) {
      enhancementRelative = "SAME as you";
    } else if (estimatedStatsPayload.enhancementCompare < 0) {
      enhancementRelative = "${estimatedStatsPayload.enhancementCompare.abs()} LESS than you";
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
            style: TextStyle(color: enhColor, fontSize: 14),
          ),
        ),
      ],
    );

    String cansRelative = "";
    if (estimatedStatsPayload.cansCompare > 0) {
      cansRelative = "${estimatedStatsPayload.cansCompare.abs()} MORE than you";
    } else if (estimatedStatsPayload.cansCompare == 0) {
      cansRelative = "SAME as you";
    } else if (estimatedStatsPayload.cansCompare < 0) {
      cansRelative = "${estimatedStatsPayload.cansCompare.abs()} LESS than you";
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
            style: TextStyle(color: estimatedStatsPayload.cansColor, fontSize: 14),
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
              !estimatedStatsPayload.sslProb
                  ? "none"
                  : estimatedStatsPayload.sslColor == Colors.green
                      ? "low"
                      : estimatedStatsPayload.sslColor == Colors.orange
                          ? "med"
                          : "high",
              style: TextStyle(
                color: estimatedStatsPayload.sslColor,
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
                "Xanax: ${estimatedStatsPayload.otherXanTaken}",
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                "Ecstasy: ${estimatedStatsPayload.otherEctTaken}",
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                "LSD: ${estimatedStatsPayload.otherLsdTaken}",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "ESTIMATED STATS",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (estimatedStatsPayload.otherFactionName != "0")
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Faction: ${estimatedStatsPayload.otherFactionName}",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (estimatedStatsPayload.otherLastActionRelative.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Online: ${estimatedStatsPayload.otherLastActionRelative.replaceAll(RegExp('0 minutes ago'), "now")}",
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
      ),
    );
  }
}
