import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
//import 'package:torn_pda/providers/settings_provider.dart';

class BrowserInfoDialog extends StatefulWidget {
  @override
  _BrowserInfoDialogState createState() => _BrowserInfoDialogState();
}

class _BrowserInfoDialogState extends State<BrowserInfoDialog> {

  // TODO: remove test browser preferences if no reported issues

  //SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    //_settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Browser type"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text("Choosing the in-app browser "
                "offers a better experience and additional "
                "features, such as foreign stock uploading "
                "to a common database in YATA that everyone "
                "benefits from."
                "\n\n"
                "Please consider using it, unless you "
                "have issues, in which case you can select "
                "you mobile phone's default browser (external)."),
            /*
            Row(
              children: <Widget>[
                Text("Use test browser"),
                Consumer<SettingsProvider>(
                  builder: (context, settingsModel, child) => Switch(
                    value: settingsModel.testBrowserActive,
                    onChanged: (value) {
                      _settingsProvider.changeTestBrowserActive = value;
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
            */
          ],
        ),
      ),
      actions: [
        FlatButton(
          child: Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

}
