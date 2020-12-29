import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';

class OnAppExitDialog extends StatefulWidget {
  @override
  _OnAppExitDialogState createState() => _OnAppExitDialogState();
}

class _OnAppExitDialogState extends State<OnAppExitDialog> {
  SettingsProvider _settingsProvider;

  bool _remember = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return AlertDialog(
      title: Text("Exit Torn PDA?"),
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please confirm if you wish to exit Torn PDA. Mark the checkbox "
              "below to make this your default choice (it can be changed "
              "later in the Settings section)",
              style: TextStyle(fontSize: 13),
            ),
            CheckboxListTile(
              checkColor: Colors.white,
              activeColor: Colors.blueGrey,
              dense: true,
              value: _remember,
              title: Text("Remember choice"),
              onChanged: (value) {
                setState(() {
                  _remember = !_remember;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        FlatButton(
          child: Text("Exit"),
          onPressed: () {
            if (_remember) {
              _settingsProvider.changeOnAppExit = 'exit';
            }
            Navigator.of(context).pop('exit');
          },
        ),
        FlatButton(
          child: Text("Stay"),
          onPressed: () async {
            if (_remember) {
              _settingsProvider.changeOnAppExit = 'stay';
            }
            Navigator.of(context).pop('stay');
          },
        )
      ],
    );
  }
}
