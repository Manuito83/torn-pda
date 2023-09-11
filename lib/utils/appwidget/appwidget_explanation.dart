import 'package:flutter/material.dart';

class AppwidgetExplanationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Home widget"),
      content: const SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "You have installed your first home screen widget!\n\n"
              "Please be aware that you can change several options (such as the theme) in the Settings menu "
              "here in the main app.\n\n"
              "Also, don't forget to visit the Tips section as there are a few hints and recommendations "
              "regarding battery consumption, refresh timer restrictions and others.",
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Awesome!"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}
