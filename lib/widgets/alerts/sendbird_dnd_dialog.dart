import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';

class SendbirdDoNotDisturbDialog extends StatefulWidget {
  @override
  SendbirdDoNotDisturbDialogState createState() => SendbirdDoNotDisturbDialogState();
}

class SendbirdDoNotDisturbDialogState extends State<SendbirdDoNotDisturbDialog> {
  final SendbirdController sbController = Get.find<SendbirdController>();

  bool _enabled = false;
  TimeOfDay _startTime = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 0, minute: 0);
  String _timezone = '';

  @override
  void initState() {
    super.initState();

    _enabled = sbController.doNotDisturbEnabled;
    _startTime = sbController.startTime;
    _endTime = sbController.endTime;
    _timezone = sbController.timeZoneName;

    sbController.getDoNotDisturbSettings().then((_) {
      setState(() {
        _enabled = sbController.doNotDisturbEnabled;
        _startTime = sbController.startTime;
        _endTime = sbController.endTime;
        _timezone = sbController.timeZoneName;
      });
    });
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _saveSettings() async {
    await sbController.setDoNotDisturbSettings(
      _enabled,
      _startTime,
      _endTime,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Do Not Disturb'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Here you can specify the time intervals where you don't want to be notified about "
              "chat messages.\n\nPlease note that this setting DOES NOT apply to chat messages received while the app "
              "is in the foreground.\n",
              style: TextStyle(fontSize: 12),
            ),
            SwitchListTile(
              title: Text('Enable'),
              value: _enabled,
              onChanged: (bool value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),
            ListTile(
              title: Text('Start time'),
              subtitle: Text(_startTime.format(context)),
              onTap: _enabled ? () => _selectStartTime(context) : null,
              enabled: _enabled,
            ),
            ListTile(
              title: Text('End time'),
              subtitle: Text(_endTime.format(context)),
              onTap: _enabled ? () => _selectEndTime(context) : null,
              enabled: _enabled,
            ),
            ListTile(
              title: Text('Timezone'),
              subtitle: Text(_timezone),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: _saveSettings,
        ),
      ],
    );
  }
}
