import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/settings/backup_local/prefs_backup_section.dart';

class BackupReminderDialog extends StatefulWidget {
  final int daysSinceLastBackup;

  const BackupReminderDialog({
    super.key,
    required this.daysSinceLastBackup,
  });

  @override
  BackupReminderDialogState createState() => BackupReminderDialogState();
}

class BackupReminderDialogState extends State<BackupReminderDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with API Key as suggestion
    _passwordController.text = UserHelper.apiKey;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showToast(String msg, ToastificationType type) async {
    toastification.show(
      title: Text(msg, maxLines: 2),
      type: type,
      alignment: Alignment.bottomCenter,
      closeOnClick: true,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  String _getTimestamp() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}${two(d.second)}';
  }

  Future<void> _createBackup() async {
    final key = _passwordController.text.trim();
    if (key.isEmpty) {
      _showToast('Please enter an encryption key', ToastificationType.error);
      return;
    }

    setState(() {
      _isCreatingBackup = true;
    });

    try {
      final result = await PrefsBackupWidget.createBackup(
        key,
        customName: 'pda_backup_${_getTimestamp()}',
      );

      if (result != null) {
        await Prefs().setAutoBackupLastReminderShown(DateTime.now().millisecondsSinceEpoch);

        _showToast('Backup created successfully! Settings have been saved to device.', ToastificationType.success);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showToast('Backup was cancelled by user', ToastificationType.info);
      }
    } catch (e) {
      _showToast('Error creating backup: ${e.toString()}', ToastificationType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });
      }
    }
  }

  Future<void> _remindLater() async {
    // Update reminder timestamp to reset the 90-day counter
    await Prefs().setAutoBackupLastReminderShown(DateTime.now().millisecondsSinceEpoch);
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _disableReminders() async {
    await Prefs().setAutoBackupReminderEnabled(false);
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and title
              const Icon(
                Icons.save_alt,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),

              Text(
                'Backup Reminder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.mainText,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                widget.daysSinceLastBackup > 0
                    ? 'It has been ${widget.daysSinceLastBackup} days since your last local backup.\n\nWe recommend creating a backup of your settings to avoid losing your data if you need to reinstall the app for some reason.\n\nYou can also manage backups anytime in Settings → Local Backup.'
                    : 'We recommend creating a backup of your settings to avoid losing your data.\n\nThis ensures you can restore your preferences if needed.\n\nYou can also manage backups anytime in Settings → Local Backup.',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.mainText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Encryption Key',
                  hintText: 'Enter your backup password',
                  filled: true,
                  fillColor: themeProvider.secondBackground,
                ),
                maxLength: 20,
                style: TextStyle(color: themeProvider.mainText),
              ),

              const SizedBox(height: 4),

              // Info text
              Text(
                'Your API Key has been pre-filled as a suggestion. You can use any password you prefer.',
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.mainText.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingBackup ? null : _createBackup,
                      icon: _isCreatingBackup
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isCreatingBackup ? 'Creating Backup...' : 'Create Backup Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Secondary buttons row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isCreatingBackup ? null : _remindLater,
                          child: Text(
                            'Not now',
                            style: TextStyle(
                              color: themeProvider.mainText.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _isCreatingBackup ? null : _disableReminders,
                          child: Text(
                            'Disable reminders',
                            style: TextStyle(
                              color: Colors.red.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
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
