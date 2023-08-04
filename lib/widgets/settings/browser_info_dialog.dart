// Flutter imports:
import 'package:flutter/material.dart';

class BrowserInfoDialog extends StatefulWidget {
  @override
  _BrowserInfoDialogState createState() => _BrowserInfoDialogState();
}

class _BrowserInfoDialogState extends State<BrowserInfoDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Browser type"),
      content: const SingleChildScrollView(
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
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
