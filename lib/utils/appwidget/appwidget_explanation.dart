import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppwidgetExplanationDialog extends StatefulWidget {
  const AppwidgetExplanationDialog({super.key});

  @override
  State<AppwidgetExplanationDialog> createState() => _AppwidgetExplanationDialogState();
}

class _AppwidgetExplanationDialogState extends State<AppwidgetExplanationDialog> with WidgetsBindingObserver {
  static const platform = MethodChannel('tornpda.channel');
  Future<bool?>? _batteryOptimizationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _batteryOptimizationFuture = _checkBatteryOptimization();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      setState(() {
        _batteryOptimizationFuture = _checkBatteryOptimization();
      });
    }
  }

  Future<bool?> _checkBatteryOptimization() async {
    try {
      final bool isRestricted = await platform.invokeMethod('checkBatteryOptimization');
      return isRestricted;
    } catch (e) {
      debugPrint("Error checking battery optimization: $e");
      return null; // Return null if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Home Widget"),
      content: SingleChildScrollView(
        child: Platform.isIOS ? _iosExplanation() : _androidExplanation(),
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

  Widget _iosExplanation() {
    return const Text(
      "You have added the Torn PDA widget!\n\n"
      "How it stays up to date:\n\n"
      "- iOS decides how often widgets refresh, usually every 15 to 30 minutes while the widget is on screen. "
      "Low Power Mode can delay it further.\n\n"
      "- Between refreshes, your bars keep filling on their own and timers (hospital, travel, chain) count down live.\n\n"
      "- If you spend energy or nerve in Torn PDA, the widget catches up as soon as you leave the app.\n\n"
      "- If you play from another device, it catches up on its next refresh. On iOS 26 or later, Torn PDA can also "
      "ask iOS to refresh it when something changes, but iOS has the final word.\n\n"
      "- Tap the refresh icon to update right away. The time next to it shows when the data was fetched.\n\n"
      "Long press the widget and choose Edit Widget to show your shortcuts, your money or pick the lock screen bar. "
      "You can also add your shortcuts to Control Center.",
      style: TextStyle(fontSize: 13),
    );
  }

  Widget _androidExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "You have installed your first home screen widget!\n\n"
          "Please be aware that you can change several options (such as the theme) in the Settings menu "
          "here in the main app.\n\n"
          "Also, don't forget to visit the Tips section as there are a few hints and recommendations "
          "regarding battery consumption, refresh timer restrictions and others.",
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        FutureBuilder<bool?>(
          future: _batteryOptimizationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || snapshot.data == null) {
              return const SizedBox();
            } else {
              final isRestricted = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRestricted ? Icons.warning : Icons.check_circle,
                        color: isRestricted ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isRestricted
                              ? "Background batery restrictions in place:\n\n"
                                  "It's recommended to change the background batery restrictions for Torn PDA "
                                  "to 'unrestricted' for optimal home widget performance"
                              : "Battery optimization is properly configured",
                          style: TextStyle(
                            fontSize: 13,
                            color: isRestricted ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isRestricted)
                    ElevatedButton(
                      onPressed: () {
                        try {
                          platform.invokeMethod('openBatterySettings');
                        } catch (e) {
                          debugPrint("Error opening battery settings: $e");
                        }
                      },
                      child: const Text("Battery Settings"),
                    ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}
