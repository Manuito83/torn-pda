// Flutter imports:
import 'package:app_settings/app_settings.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class AppLinksBrowserDialog extends StatefulWidget {
  @override
  AppLinksBrowserDialogState createState() => AppLinksBrowserDialogState();
}

class AppLinksBrowserDialogState extends State<AppLinksBrowserDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Important! External browser and default Torn links"),
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EasyRichText(
              "Please be aware that Torn PDA will open Torn links by default, unless you change this behavior in "
              "your device's system settings.\n\n"
              "This is part of a native integration that is made possible by the Torn developers.\n\n"
              "If you prefer to use an external browser, you WILL NEED to change your device app's settings and "
              "deselect the 'open supported links' option inside of the 'open by default' section, so that Torn PDA "
              "no longer tries to open Torn links by default.\n\n"
              "Otherwise, Torn PDA won't be able to redirect to any other browser (and the in-app browser will also "
              "fail to open).",
              defaultStyle: TextStyle(
                fontSize: 13,
                color: context.read<ThemeProvider>().mainText,
              ),
              patternList: [
                EasyRichTextPattern(
                  targetString: "device app's settings",
                  style: TextStyle(
                      decoration: TextDecoration.underline, color: Colors.blue[400], fontStyle: FontStyle.italic),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await AppSettings.openAppSettings();
                    },
                ),
                const EasyRichTextPattern(
                  targetString: 'open supported links',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const EasyRichTextPattern(
                  targetString: 'open by default',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            "Open app\nsettings",
            textAlign: TextAlign.center,
          ),
          onPressed: () async {
            await AppSettings.openAppSettings();
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text("Disregard"),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
