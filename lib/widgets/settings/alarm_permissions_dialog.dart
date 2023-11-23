// Flutter imports:
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';

class AlarmPermissionsDialog extends StatefulWidget {
  @override
  AlarmPermissionsDialogState createState() => AlarmPermissionsDialogState();
}

class AlarmPermissionsDialogState extends State<AlarmPermissionsDialog> {
  late SettingsProvider _settingsProvider;

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: true);
    return AlertDialog(
      title: Text("Exact Alarm Permissions"),
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "In order for in-app notifications to work properly, Torn PDA needs permissions to schedule 'exact "
              "alarms and reminders', including when the app is in the background, completely closed or your phone "
              "is in a deep idle or sleep state.\n\n"
              "Otherwise, Torn PDA can't guarantee that these manual notifications, which are sometimes scheduled "
              "with a few seconds of margin, will pop up when you expect them (as your Android system will throttle "
              "them down).",
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            "Notification\nsettings",
            textAlign: TextAlign.center,
          ),
          onPressed: () async {
            await AppSettings.openAppSettings();
            _settingsProvider.exactPermissionDialogShownAndroid = 2;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(
            "Remind me\nnext time",
            textAlign: TextAlign.center,
          ),
          onPressed: () async {
            _settingsProvider.exactPermissionDialogShownAndroid = 1;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text("Disregard"),
          onPressed: () async {
            _settingsProvider.exactPermissionDialogShownAndroid = 2;
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
