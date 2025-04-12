import 'package:flutter/material.dart';

class BugsAnnouncementDialog extends StatelessWidget {
  const BugsAnnouncementDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
            child: Image.asset(
              "images/icons/torn_pda.png",
              width: 30,
              height: 30,
              //color: _themeProvider.mainText,
            ),
          ),
          Flexible(child: const Text("Recent bugs reported with third-party user scripts")),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Over the past few months, we've received several reports regarding issues within the app "
              "(such as the Crimes page not loading, app crashes, general instability, etc.). "
              "After investigating alongside many of you, we've found that in the vast majority of cases, "
              "these problems are caused by faulty user scripts."
              "\n\nPlease remember that while Torn PDA supports third-party user scripts and we do our best "
              "to assist through our Discord server, we can't solve any issues caused "
              "by external scripts, including memory leaks or app crashes. A poorly optimized script can "
              "easily result in such problems."
              "\n\nIf you're experiencing any of these issues, a quick way to "
              "determine whether a user script is the cause is to disable all scripts, "
              "force kill the application, and then relaunch it."
              "\n\nIf the issue disappears, it's likely due to a specific script. "
              "In that case, we encourage you to reach out to the script's developer "
              "to report the problem, as we are unable to provide further support for third-party code.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Ok!"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}
