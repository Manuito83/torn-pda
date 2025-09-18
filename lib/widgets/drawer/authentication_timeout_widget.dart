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
    return Column(
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
          'Connection Problem',
          style: TextStyle(
            color: themeProvider.mainText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Torn PDA encountered a problem retrieving your server information. This might be a temporary issue.',
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
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended steps:',
                style: TextStyle(
                  color: themeProvider.mainText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              _buildRecommendationItem(
                icon: Icons.refresh,
                title: '1. Force close and relaunch the app',
                description: 'This will rule out temporary connection issues',
              ),
              const SizedBox(height: 15),
              _buildRecommendationItem(
                icon: Icons.vpn_key,
                title: '2. Reset your API key',
                description: 'Go to Settings → remove your API key → re-enter it',
              ),
              const SizedBox(height: 15),
              _buildRecommendationItem(
                icon: Icons.notifications_active,
                title: '3. Reconfigure alerts',
                description: 'After resetting API key, go to Alerts to reconfigure automatic notifications',
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
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
