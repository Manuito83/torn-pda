import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class EstimatedStatsDialog extends StatelessWidget {
  const EstimatedStatsDialog({
    super.key,
    required this.xanaxCompare,
    required this.xanaxColor,
    required this.refillCompare,
    required this.refillColor,
    required this.enhancementCompare,
    required this.enhancementColor,
    required this.cansCompare,
    required this.cansColor,
    required this.sslColor,
    required this.sslProb,
    required this.otherXanTaken,
    required this.otherEctTaken,
    required this.otherLsdTaken,
    required this.otherName,
    required this.otherFactionName,
    required this.otherLastActionRelative,
    required this.themeProvider,
  });

  final int xanaxCompare;
  final Color xanaxColor;
  final int refillCompare;
  final Color refillColor;
  final int enhancementCompare;
  final Color? enhancementColor;
  final int cansCompare;
  final Color cansColor;
  final Color sslColor;
  final bool sslProb;
  final int otherXanTaken;
  final int otherEctTaken;
  final int otherLsdTaken;
  final String otherName;
  final String otherFactionName;
  final String otherLastActionRelative;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
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
    Color? enhColor = enhancementColor;
    if (enhColor == Colors.white) enhColor = themeProvider.mainText;
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
            style: TextStyle(color: enhColor, fontSize: 14),
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
                "Xanax: $otherXanTaken",
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                "Ecstasy: $otherEctTaken",
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                "LSD: $otherLsdTaken",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      title: Text(otherName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (otherFactionName != "0")
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Faction: $otherFactionName",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (otherLastActionRelative.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Online: ${otherLastActionRelative.replaceAll(RegExp('0 minutes ago'), "now")}",
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
