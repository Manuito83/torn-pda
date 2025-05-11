import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class SendbirdDoNotDisturbDialog extends StatefulWidget {
  @override
  SendbirdDoNotDisturbDialogState createState() => SendbirdDoNotDisturbDialogState();
}

class SendbirdDoNotDisturbDialogState extends State<SendbirdDoNotDisturbDialog> {
  final SendbirdController sbController = Get.find<SendbirdController>();

  bool _enabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 0, minute: 0);
  String _timezone = '';
  late Future<bool> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Do Not Disturb'),
      content: FutureBuilder<bool>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Fetching settings...",
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 20),
                SizedBox(height: 20, width: 20, child: CircularProgressIndicator()),
              ],
            );
          } else if (snapshot.hasError || snapshot.data == false) {
            return const Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                "Failed to load settings from the server.\n\nPlease try again later.",
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Here you can specify the time intervals where you don't want to be notified about "
                    "chat messages.\n\nPlease note that this setting DOES NOT apply to chat messages received while the app "
                    "is in the foreground.\n",
                    style: TextStyle(fontSize: 12),
                  ),
                  SwitchListTile(
                    title: const Text('Enable'),
                    value: _enabled,
                    onChanged: (bool value) {
                      setState(() {
                        _enabled = value;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('Start time'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: _enabled ? () => _selectStartTime(context) : null,
                    enabled: _enabled,
                  ),
                  ListTile(
                    title: const Text('End time'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: _enabled ? () => _selectEndTime(context) : null,
                    enabled: _enabled,
                  ),
                  ListTile(
                    title: const Text('Timezone'),
                    subtitle: Text(_timezone),
                  ),
                ],
              ),
            );
          }
        },
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FutureBuilder<bool>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            final isEnabled =
                snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data == true;
            return ElevatedButton(
              child: const Text('Save'),
              onPressed: isEnabled ? _saveSettings : null,
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay? picked;

    if (Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          TimeOfDay initialTime = _startTime;

          final isLightTheme = context.read<ThemeProvider>().currentTheme == AppTheme.light;
          final backgroundColor = isLightTheme ? Colors.white : Colors.black;
          final buttonColor = isLightTheme ? Colors.blue : Colors.lightBlueAccent;
          final textColor = isLightTheme ? Colors.black : Colors.white;
          final overlayColor = isLightTheme ? Colors.grey[200] : Colors.grey[850];

          return CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: buttonColor,
              barBackgroundColor: backgroundColor,
              textTheme: CupertinoTextThemeData(
                primaryColor: textColor,
                pickerTextStyle: TextStyle(color: textColor, fontSize: 22),
              ),
            ),
            child: Container(
              height: 250,
              color: backgroundColor,
              child: Column(
                children: [
                  Container(
                    color: overlayColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: buttonColor),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoButton(
                          child: Text(
                            'Done',
                            style: TextStyle(color: buttonColor),
                          ),
                          onPressed: () {
                            Navigator.pop(context, picked);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      minuteInterval: 1,
                      initialTimerDuration: Duration(
                        hours: initialTime.hour,
                        minutes: initialTime.minute,
                      ),
                      onTimerDurationChanged: (Duration newDuration) {
                        picked = TimeOfDay(
                          hour: newDuration.inHours,
                          minute: newDuration.inMinutes % 60,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      picked = await showTimePicker(
        context: context,
        builder: (context, child) {
          final timePicker = MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: Theme(
                data: ThemeData.from(
                  colorScheme: context.read<ThemeProvider>().currentTheme == AppTheme.light
                      ? const ColorScheme.light()
                      : const ColorScheme.dark(),
                ),
                child: child!,
              ));
          return timePicker;
        },
        initialTime: _startTime,
        initialEntryMode: TimePickerEntryMode.dial,
      );
    }

    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked!;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay? picked;

    if (Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          TimeOfDay initialTime = _endTime;

          final isLightTheme = context.read<ThemeProvider>().currentTheme == AppTheme.light;
          final backgroundColor = isLightTheme ? Colors.white : Colors.black;
          final buttonColor = isLightTheme ? Colors.blue : Colors.lightBlueAccent;
          final textColor = isLightTheme ? Colors.black : Colors.white;
          final overlayColor = isLightTheme ? Colors.grey[200] : Colors.grey[850];

          return CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: buttonColor,
              barBackgroundColor: backgroundColor,
              textTheme: CupertinoTextThemeData(
                primaryColor: textColor,
                pickerTextStyle: TextStyle(color: textColor, fontSize: 22),
              ),
            ),
            child: Container(
              height: 250,
              color: backgroundColor,
              child: Column(
                children: [
                  Container(
                    color: overlayColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: buttonColor),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoButton(
                          child: Text(
                            'Done',
                            style: TextStyle(color: buttonColor),
                          ),
                          onPressed: () {
                            Navigator.pop(context, picked);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      minuteInterval: 1,
                      initialTimerDuration: Duration(
                        hours: initialTime.hour,
                        minutes: initialTime.minute,
                      ),
                      onTimerDurationChanged: (Duration newDuration) {
                        picked = TimeOfDay(
                          hour: newDuration.inHours,
                          minute: newDuration.inMinutes % 60,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      picked = await showTimePicker(
        context: context,
        builder: (context, child) {
          final timePicker = MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: Theme(
                data: ThemeData.from(
                  colorScheme: context.read<ThemeProvider>().currentTheme == AppTheme.light
                      ? const ColorScheme.light()
                      : const ColorScheme.dark(),
                ),
                child: child!,
              ));
          return timePicker;
        },
        initialTime: _endTime,
        initialEntryMode: TimePickerEntryMode.dial,
      );
    }

    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked!;
      });
    }
  }

  Future<bool> _loadSettings() async {
    bool success = await sbController.getDoNotDisturbSettings();
    if (success) {
      setState(() {
        _enabled = sbController.doNotDisturbEnabled;
        _startTime = sbController.startTime;
        _endTime = sbController.endTime;
        _timezone = sbController.timeZoneName;
      });
    }
    return success;
  }

  void _saveSettings() async {
    bool success = await sbController.setDoNotDisturbSettings(
      _enabled,
      _startTime,
      _endTime,
    );
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save settings. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
