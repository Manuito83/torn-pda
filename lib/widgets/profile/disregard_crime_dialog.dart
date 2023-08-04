// Flutter imports:
import 'package:flutter/material.dart';

class DisregardCrimeDialog extends StatefulWidget {
  final Function disregardCallback;

  const DisregardCrimeDialog({required this.disregardCallback});

  @override
  _DisregardCrimeDialogState createState() => _DisregardCrimeDialogState();
}

class _DisregardCrimeDialogState extends State<DisregardCrimeDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Disregard crime"),
      content: const SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "Because you have no faction API access permissions, the OC crimes calculation "
              "is based on events. If you have deleted events or, for any other reason, the calculation is "
              "incorrect, you can disregard this crime advisory so that it does not show again.\n\n"
              "If you wish to cancel OC advisories altogether, please deselect Faction Crimes in the "
              "profile options page.",
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Disregard crime"),
          onPressed: () {
            widget.disregardCallback();
            Navigator.of(context).pop();
          },
        ),
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
