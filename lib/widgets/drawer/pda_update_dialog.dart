// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class PdaUpdateDialog extends StatefulWidget {
  final PdaUpdateDetails updateDetails;
  final ThemeProvider? themeProvider;

  const PdaUpdateDialog({
    super.key,
    required this.updateDetails,
    this.themeProvider,
  });

  @override
  PdaUpdateDialogState createState() => PdaUpdateDialogState();
}

class PdaUpdateDialogState extends State<PdaUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const Image(
                    image: AssetImage('images/icons/torn_pda.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Update Available!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.themeProvider?.currentTheme == AppTheme.light ? Colors.black87 : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Version info
              Text(
                widget.updateDetails.latestVersionName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Platform specific update message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Platform.isIOS ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Platform.isIOS ? Colors.blue.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Platform.isIOS ? Icons.apple : Icons.android,
                      color: Platform.isIOS ? Colors.blue.shade600 : Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Platform.isIOS ? 'A new iOS update is available!' : 'A new Android update is available!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Platform.isIOS ? Colors.blue.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Changelog section
              if (widget.updateDetails.changelog.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's New:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.themeProvider?.currentTheme == AppTheme.light ? Colors.black87 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.themeProvider?.currentTheme == AppTheme.light
                                ? Colors.grey.shade50
                                : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.themeProvider?.currentTheme == AppTheme.light
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600,
                            ),
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: widget.updateDetails.changelog.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(top: 6, right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade600,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                              color: widget.themeProvider?.currentTheme == AppTheme.light
                                                  ? Colors.black87
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // User dismissed
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Later',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true); // User wants to update
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Platform.isIOS ? Colors.blue.shade600 : Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        Platform.isIOS ? 'Open App Store' : 'Open Play Store',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
