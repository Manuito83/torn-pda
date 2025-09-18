import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/connectivity/connectivity_handler.dart';

class ConnectivityUI extends StatelessWidget {
  final ThemeProvider themeProvider;
  final bool hasWaitedInitialDelay;

  const ConnectivityUI({
    super.key,
    required this.themeProvider,
    required this.hasWaitedInitialDelay,
  });

  @override
  Widget build(BuildContext context) {
    // During the first second, show basic container
    if (!hasWaitedInitialDelay) {
      return const SizedBox.shrink();
    }

    // After 1 second, check connectivity status
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityHandler.instance.hasConnection,
      builder: (context, isConnected, child) {
        if (!isConnected) {
          // No connectivity after 1 second - show the message
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                '📡',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    'No connection found, please wait!',
                    style: TextStyle(
                      color: themeProvider.mainText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Torn PDA needs Internet access to continue',
                style: TextStyle(
                  color: themeProvider.mainText.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          );
        } else {
          // Connectivity is fine, show normal loading
          return const SizedBox.shrink();
        }
      },
    );
  }
}
