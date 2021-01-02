import 'package:flutter/material.dart';

class BrowserExplanationDialog extends StatefulWidget {
  @override
  _BrowserExplanationDialogState createState() =>
      _BrowserExplanationDialogState();
}

class _BrowserExplanationDialogState extends State<BrowserExplanationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Quick & Full browsers"),
      content: Text(
        "There are two ways of using the 'in-app' browser in Torn PDA: 'quick' and 'full' browser.\n\n"
        "By default, a short tap in buttons, bars or icons will open the 'quick browser', which loads faster "
        "and allows to accomplish actions quicker. However, the options bar and its icons are only visible in the "
        "'full browser' version, which can be opened with a long-press in the same places.\n\n"
        "This also applies, for example, for the main 'T' menu in the Profile section. After expanding it, you can "
        "short tap or long-press to use the quick or full browsers.\n\n"
        "In the Settings section you can disable the quick browser if you prefer to always use the full one.",
        style: TextStyle(fontSize: 13),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FlatButton(
            child: Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}
