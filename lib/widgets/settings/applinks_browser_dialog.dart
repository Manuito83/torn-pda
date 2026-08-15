// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
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
  Future<void> _openOpenByDefaultSettings() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
        data: 'package:com.manuito.tornpda',
      );
      await intent.launch();
    } catch (_) {
      await AppSettings.openAppSettings();
    }
  }

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
              "Otherwise, Torn links will keep opening in Torn PDA's in-app browser, even though you have chosen "
              "an external one here.",
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
                      await _openOpenByDefaultSettings();
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
            await _openOpenByDefaultSettings();
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
