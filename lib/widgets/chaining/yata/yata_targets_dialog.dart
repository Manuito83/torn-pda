import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/pages/chaining/yata/yata_targets_distribution.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class YataTargetsDialog extends StatefulWidget {
  final List<TargetsOnlyYata> onlyYata;
  final List<TargetsOnlyLocal> onlyLocal;
  final List<TargetsBothSides> bothSides;

  YataTargetsDialog({
    @required this.bothSides,
    @required this.onlyYata,
    @required this.onlyLocal,
  });

  @override
  _YataTargetsDialogState createState() => _YataTargetsDialogState();
}

class _YataTargetsDialogState extends State<YataTargetsDialog> {
  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;

  bool _dialogInit = true;

  double _currentImportPercentage = 0;
  String _currentImportTarget = "";

  @override
  Widget build(BuildContext context) {
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
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
                  padding: EdgeInsets.only(
                    top: 45,
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  margin: EdgeInsets.only(top: 15),
                  decoration: new BoxDecoration(
                    color: _themeProvider.background,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: const Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  child: _dialogInit ? _dialogDistributionPhase() : _dialogImportingPhase()),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _themeProvider.background,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.background,
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
        SizedBox(height: 10),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 25),
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
              SizedBox(width: 10),
              OpenContainer(
                transitionDuration: Duration(milliseconds: 500),
                transitionType: ContainerTransitionType.fadeThrough,
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
                closedBuilder: (BuildContext context, VoidCallback openContainer) {
                  return SizedBox(
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
        SizedBox(height: 8),
        Divider(),
        SizedBox(height: 5),
        RaisedButton(
          child: Column(
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
          onPressed: somethingToImportFromYata
              ? () {
                  setState(() {
                    // Change dialog phase (clear most of the screen)
                    _dialogInit = false;
                    _startImport();
                  });
                }
              : null,
        ),
        SizedBox(height: 10),
        RaisedButton(
            child: Column(
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
            onPressed: somethingToExportToYata
                ? () async {
                    Navigator.of(context).pop();
                    var exportResult = await _targetsProvider.postTargetsToYata(
                      onlyLocal: widget.onlyLocal,
                      bothSides: widget.bothSides,
                    );
                    if (exportResult == "") {
                      BotToast.showText(
                        text: "There was an error exporting!",
                        textStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        contentColor: Colors.red[800],
                        duration: Duration(seconds: 5),
                        contentPadding: EdgeInsets.all(10),
                      );
                    } else {
                      BotToast.showText(
                        text: exportResult,
                        textStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        contentColor: Colors.green[800],
                        duration: Duration(seconds: 5),
                        contentPadding: EdgeInsets.all(10),
                      );
                    }
                  }
                : null),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
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
        SizedBox(height: 18),
        LinearPercentIndicator(
          alignment: MainAxisAlignment.center,
          width: 200,
          lineHeight: 16,
          progressColor: Colors.green[400],
          backgroundColor: Colors.grey[400],
          center: Text(
            "${(_currentImportPercentage * 100).toInt()}%",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
          ),
          percent: _currentImportPercentage,
        ),
        SizedBox(height: 6),
        Text(
          _currentImportTarget,
          style: TextStyle(fontSize: 13),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        )
      ],
    );
  }

  void _startImport() async {
    // We add all targets coming from YATA
    dynamic attacksFull = await _targetsProvider.getAttacksFull();
    for (var i = 0; i <= widget.onlyYata.length - 1; i++) {
      if (mounted) {
        var importResult = await _targetsProvider.addTarget(
          targetId: widget.onlyYata[i].id,
          attacksFull: attacksFull,
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
        if (widget.onlyYata.length > 70) {
          await Future.delayed(const Duration(seconds: 1), () {});
        }
      }
    }

    // Those target that we already have, only see their notes updated
    if (mounted) {
      for (var bothSidesTarget in widget.bothSides) {
        for (var localTarget in _targetsProvider.allTargets) {
          if (bothSidesTarget.id == localTarget.playerId.toString()) {
            _targetsProvider.setTargetNote(
              localTarget,
              bothSidesTarget.noteYata,
              _localColorCode(bothSidesTarget.colorYata),
            );
            break;
          }
        }
      }
    }

    // Only to look good
    if (mounted) {
      setState(() {
        _currentImportTarget = "Updating notes...";
        _currentImportPercentage = 1;
      });
      await Future.delayed(const Duration(seconds: 2), () {});
    }

    // Auto close at the end
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _localColorCode(int colorInt) {
    switch (colorInt) {
      case 0:
        return '';
        break;
      case 1:
        return 'green';
        break;
      case 2:
        return 'orange';
        break;
      case 3:
        return 'red';
        break;
    }
    return '';
  }
}
