import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
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
                child: _dialogInit ? _dialogDistributionPhase() : _dialogImportingPhase()
              ),
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
          onPressed: () {
            setState(() {
              // Change dialog phase (clear most of the screen)
              _dialogInit = false;
              _startImport();
            });
          },
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
          onPressed: () async {
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
          },
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

  void _startImport() {
    if (mounted) {


    }
  }

}

