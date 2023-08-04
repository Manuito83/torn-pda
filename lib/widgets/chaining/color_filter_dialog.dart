// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/targets_provider.dart';

class ColorFilterDialog extends StatefulWidget {
  @override
  _ColorFilterDialogState createState() => _ColorFilterDialogState();
}

class _ColorFilterDialogState extends State<ColorFilterDialog> {
  late TargetsProvider _targetsProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    return AlertDialog(
      title: const Text("Filter out colors"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Choose if you would like to filter OUT targets based on their note color.",
              style: TextStyle(
                fontSize: 13,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("No color"),
                  Switch(
                    value: _targetsProvider.currentColorFilterOut.contains('z'),
                    onChanged: (value) {
                      final temp = _targetsProvider.currentColorFilterOut;
                      if (value) {
                        temp.add('z');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      } else {
                        temp.remove('z');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Red"),
                  Switch(
                    value: _targetsProvider.currentColorFilterOut.contains('red'),
                    onChanged: (value) {
                      final temp = _targetsProvider.currentColorFilterOut;
                      if (value) {
                        temp.add('red');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      } else {
                        temp.remove('red');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Yellow"),
                  Switch(
                    value: _targetsProvider.currentColorFilterOut.contains('orange'),
                    onChanged: (value) {
                      final temp = _targetsProvider.currentColorFilterOut;
                      if (value) {
                        temp.add('orange');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      } else {
                        temp.remove('orange');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Green"),
                  Switch(
                    value: _targetsProvider.currentColorFilterOut.contains('green'),
                    onChanged: (value) {
                      final temp = _targetsProvider.currentColorFilterOut;
                      if (value) {
                        temp.add('green');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      } else {
                        temp.remove('green');
                        setState(() {
                          _targetsProvider.setFilterColorsOut(temp);
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: TextButton(
            child: const Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }
}
