// Flutter imports:
// Package imports:
import 'dart:developer';

import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/pages/chaining/yata/yata_targets_distribution.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart' show PlayerNoteColor;
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class YataTargetsDialog extends StatefulWidget {
  final List<TargetsOnlyYata> onlyYata;
  final List<TargetsOnlyLocal> onlyLocal;
  final List<TargetsBothSides> bothSides;

  const YataTargetsDialog({
    required this.bothSides,
    required this.onlyYata,
    required this.onlyLocal,
  });

  @override
  YataTargetsDialogState createState() => YataTargetsDialogState();
}

class YataTargetsDialogState extends State<YataTargetsDialog> {
  late TargetsProvider _targetsProvider;
  late ThemeProvider _themeProvider;

  bool _dialogInit = true;

  double _currentImportPercentage = 0;
  String? _currentImportTarget = "";

  bool _isCancelled = false;

  @override
  Widget build(BuildContext context) {
    _targetsProvider = Provider.of<TargetsProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: _themeProvider.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: _dialogInit ? _dialogDistributionPhase() : _dialogImportingPhase(),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _themeProvider.secondBackground,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.secondBackground,
                  radius: 22,
                  child: SizedBox(
                    height: 34,
                    width: 34,
                    child: Image.asset(
                      'images/icons/yata_logo.png',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogDistributionPhase() {
    bool somethingToImportFromYata = true;
    bool somethingToExportToYata = true;
    if (widget.onlyLocal.isEmpty && widget.bothSides.isEmpty) {
      somethingToExportToYata = false;
    }
    if (widget.onlyYata.isEmpty && widget.bothSides.isEmpty) {
      somethingToImportFromYata = false;
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // To make the card compact
      children: <Widget>[
        Flexible(
          child: Text(
            "TARGETS DISTRIBUTION",
            style: TextStyle(fontSize: 11, color: _themeProvider.mainText),
          ),
        ),
        const SizedBox(height: 10),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 25),
              Column(
                children: [
                  Text(
                    "${widget.onlyYata.length} only in YATA",
                    style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                  ),
                  Text(
                    "${widget.bothSides.length} common targets",
                    style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                  ),
                  Text(
                    "${widget.onlyLocal.length} only in Torn PDA",
                    style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              OpenContainer(
                transitionDuration: const Duration(milliseconds: 300),
                transitionType: ContainerTransitionType.fade,
                openBuilder: (BuildContext context, VoidCallback _) {
                  return YataTargetsDistribution(
                    bothSides: widget.bothSides,
                    onlyYata: widget.onlyYata,
                    onlyLocal: widget.onlyLocal,
                  );
                },
                closedElevation: 0,
                closedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(56 / 2),
                  ),
                ),
                closedColor: Colors.transparent,
                openColor: _themeProvider.canvas,
                closedBuilder: (BuildContext context, VoidCallback openContainer) {
                  return const SizedBox(
                    width: 20,
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: somethingToImportFromYata
              ? () {
                  setState(() {
                    // Change dialog phase (clear most of the screen)
                    _dialogInit = false;
                    _startImport();
                  });
                }
              : null,
          child: const Column(
            children: [
              Text(
                "IMPORT",
                style: TextStyle(fontSize: 11),
              ),
              Text(
                "FROM YATA",
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: somethingToExportToYata
              ? () async {
                  Navigator.of(context).pop();
                  final exportResult = await _targetsProvider.postTargetsToYata(
                    onlyLocal: widget.onlyLocal,
                    bothSides: widget.bothSides,
                  );
                  if (exportResult == "") {
                    BotToast.showText(
                      text: "There was an error exporting!",
                      textStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      contentColor: Colors.red[800]!,
                      duration: const Duration(seconds: 5),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  } else {
                    BotToast.showText(
                      text: exportResult,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      contentColor: Colors.green[800]!,
                      duration: const Duration(seconds: 5),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  }
                }
              : null,
          child: const Column(
            children: [
              Text(
                "EXPORT",
                style: TextStyle(fontSize: 11),
              ),
              Text(
                "TO YATA",
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                _isCancelled = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        )
      ],
    );
  }

  Widget _dialogImportingPhase() {
    return Column(
      mainAxisSize: MainAxisSize.min, // To make the card compact
      children: <Widget>[
        Flexible(
          child: Text(
            "IMPORTING TARGETS",
            style: TextStyle(fontSize: 11, color: _themeProvider.mainText),
          ),
        ),
        const SizedBox(height: 18),
        LinearPercentIndicator(
          padding: const EdgeInsets.all(0),
          barRadius: const Radius.circular(10),
          alignment: MainAxisAlignment.center,
          width: 200,
          lineHeight: 16,
          progressColor: Colors.green[400],
          backgroundColor: Colors.grey[400],
          center: Text(
            "${(_currentImportPercentage * 100).toInt()}%",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
          ),
          percent: _currentImportPercentage,
        ),
        const SizedBox(height: 6),
        Text(
          _currentImportTarget!,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        )
      ],
    );
  }

  Future<void> _startImport() async {
    try {
      // We add all targets coming from YATA
      final dynamic attacks = await _targetsProvider.getAttacks();
      for (var i = 0; i <= widget.onlyYata.length - 1; i++) {
        if (_isCancelled || !mounted) {
          log("Cancelled import, returning!");
          return;
        }

        final importResult = await _targetsProvider.addTarget(
          targetId: widget.onlyYata[i].id,
          attacks: attacks,
          notes: widget.onlyYata[i].noteYata,
          notesColor: _localColorCode(widget.onlyYata[i].colorYata),
        );

        if (importResult.success) {
          if (mounted) {
            setState(() {
              _currentImportTarget = widget.onlyYata[i].name;
              _currentImportPercentage = i / widget.onlyYata.length;
            });
          }
        }
        // Avoid issues with API limits
        if (widget.onlyYata.length > 60) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // Those target that we already have, only see their notes updated
      for (final bothSidesTarget in widget.bothSides) {
        final notesController = Get.find<PlayerNotesController>();
        await notesController.setPlayerNote(
          playerId: bothSidesTarget.id.toString(),
          note: bothSidesTarget.noteYata ?? '',
          color: _localColorCode(bothSidesTarget.colorYata),
        );
      }

      // Only to look good
      setState(() {
        _currentImportTarget = "Updating notes...";
        _currentImportPercentage = 1;
      });
      await Future.delayed(const Duration(seconds: 2), () {});

      // Auto close at the end
      Navigator.of(context).pop();
    } catch (e) {
      BotToast.showText(
        text: "There was an error importing!\n\n$e",
        textStyle: const TextStyle(
          fontSize: 13,
          color: Colors.white,
        ),
        contentColor: Colors.red[800]!,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  String _localColorCode(int? colorInt) {
    switch (colorInt) {
      case 0:
        return PlayerNoteColor.none;
      case 1:
        return 'green';
      case 2:
        return 'orange';
      case 3:
        return 'red';
    }
    return '';
  }
}
