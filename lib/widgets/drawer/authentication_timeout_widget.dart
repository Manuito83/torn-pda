import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class AuthenticationTimeoutWidget extends StatelessWidget {
  final ThemeProvider themeProvider;
  final WebViewProvider webViewProvider;
  final VoidCallback onUnderstoodPressed;

  const AuthenticationTimeoutWidget({
    super.key,
    required this.themeProvider,
    required this.webViewProvider,
    required this.onUnderstoodPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade300, width: 2),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "We can't sync your settings",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeProvider.mainText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Your Firebase session did not restore. Try relaunching the app first, then follow the steps below to get back in sync.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: themeProvider.mainText.withValues(alpha: 0.8),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Follow these recovery steps:',
                          style: TextStyle(
                            color: themeProvider.mainText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildRecommendationItem(
                          icon: Icons.restart_alt,
                          title: '1. Kill and relaunch the app',
                          description:
                              'If you haven\'t already done it, close Torn PDA completely and open it again to retry the sync.',
                        ),
                        const SizedBox(height: 18),
                        _buildRecommendationItem(
                          icon: Icons.vpn_key_off,
                          title: '2. Remove your API key',
                          description: 'Open Settings and use the remove option to clear the existing key.',
                        ),
                        const SizedBox(height: 18),
                        _buildRecommendationItem(
                          icon: Icons.vpn_key,
                          title: '3. Re-enter the same key',
                          description: 'Paste the same API key again to re-establish the connection.',
                        ),
                        const SizedBox(height: 18),
                        _buildRecommendationItem(
                          icon: Icons.settings_suggest,
                          title: '4. Review Settings and Alerts',
                          description: 'Confirm your preferences and notification channels are configured correctly.',
                        ),
                        const SizedBox(height: 18),
                        _buildRecommendationItem(
                          icon: Icons.archive_outlined,
                          title: '5. Restore a local backup',
                          description: 'If things still look wrong, import the latest local backup you created.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onUnderstoodPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Understood',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: themeProvider.mainText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: themeProvider.mainText.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
