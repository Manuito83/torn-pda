import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/shared_prefs_backup.dart';

/// Local backup / restore section for app settings
class PrefsBackupWidget extends StatefulWidget {
  const PrefsBackupWidget({super.key});

  @override
  PrefsBackupWidgetState createState() => PrefsBackupWidgetState();

  // Static method for creating backups from outside the widget
  static Future<String?> createBackup(String key, {String? customName}) async {
    final data = await PrefsBackupService.exportPrefs(key);
    final bytes = Uint8List.fromList(utf8.encode(data));

    String timestamp() {
      final d = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}${two(d.second)}';
    }

    final result = await FileSaver.instance.saveAs(
      name: customName ?? 'prefs_backup_${timestamp()}',
      bytes: bytes,
      fileExtension: 'pda',
      mimeType: MimeType.custom,
      customMimeType: "application/octet-stream",
    );

    if (result != null) {
      // Update backup timestamp
      await Prefs().setAutoBackupLastLocalCreated(DateTime.now().millisecondsSinceEpoch);
    }

    return result;
  }
}

class PrefsBackupWidgetState extends State<PrefsBackupWidget> {
  bool _autoBackupReminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final reminderEnabled = await Prefs().getAutoBackupReminderEnabled();

    if (mounted) {
      setState(() {
        _autoBackupReminderEnabled = reminderEnabled;
      });
    }
  }

  Future<void> _updateBackupTimestamp() async {
    // Update last backup timestamp whenever a manual backup is created
    await Prefs().setAutoBackupLastLocalCreated(DateTime.now().millisecondsSinceEpoch);
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

  Future<String?> _askKey(BuildContext ctx, bool encrypt) {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(encrypt ? 'Enter encryption key' : 'Enter decryption key'),
            if (encrypt)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    const Text(
                      'You will need this key to restore the settings in the future, so make sure to remember!',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      '\nWARNING: if configured, your API Key, alternative API keys for external providers, email address, etc.,'
                      ' will be included in the backup\n\nDO NOT SHARE IT WITH OTHERS!',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: ctx.read<ThemeProvider>().getTextColor(Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Text(
                      '\nIMPORTANT: certain settting will not be restored. This applies fundamentally to the following:\n\n'
                      '  - Alerts (automatic notifications)\n'
                      '  - Native login credentials\n\n'
                      'Make sure to reconfigure them manually after restoring the settings.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: ctx.read<ThemeProvider>().getTextColor(Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
          ],
        ),
        content: TextField(controller: ctl, autofocus: true, maxLength: 20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(_, ctl.text), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext ctx) async {
    final keyCtl = TextEditingController();
    final warnColor = ctx.read<ThemeProvider>().getTextColor(Colors.red);

    final choice = await showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter encryption key'),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  const Text(
                    'You will need this key to restore the settings in the future, so make sure to remember!',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '\nWARNING: if configured, your API Key, alternative API keys for external providers, email address, etc.,'
                    ' will be included in the backup\n\nDO NOT SHARE IT WITH OTHERS!',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: warnColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: TextField(
          controller: keyCtl,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: 'Encryption key',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(_, 'local'),
                  icon: const Icon(Icons.save),
                  label: const Text('Local Save'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(_, 'other'),
                  icon: const Icon(Icons.share),
                  label: const Text('Other Apps'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(_, null),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (choice == null) return; // cancelled
    final key = keyCtl.text.trim();
    if (key.isEmpty) {
      _showToast('No key entered', ToastificationType.error);
      return;
    }

    if (choice == 'local') {
      await _savePrefsToDisk(ctx, key);
    } else if (choice == 'other') {
      await _saveWithShareIntent(ctx, key);
    }
  }

  Future<void> _savePrefsToDisk(BuildContext ctx, String key) async {
    final result = await PrefsBackupWidget.createBackup(key);
    if (result != null) {
      _showToast('Backup saved', ToastificationType.success);
    }
  }

  Future<void> _saveWithShareIntent(BuildContext ctx, String key) async {
    final data = await PrefsBackupService.exportPrefs(key);

    // Create timestamp similar to the static method
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final timestamp = '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}${two(d.second)}';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pda_prefs_backup_$timestamp.pda');
    await file.writeAsString(data);

    final shareParams = ShareParams(
      text: 'PDA Preferences Backup',
      files: [XFile(file.path)],
    );
    final res = await SharePlus.instance.share(shareParams);

    if (res.status == ShareResultStatus.success) {
      await _updateBackupTimestamp(); // Update backup timestamp
      _showToast('Backup saved', ToastificationType.success);
    }
  }

  Future<void> _load(BuildContext ctx) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (!file.name.toLowerCase().endsWith('.pda')) {
      _showToast('Select a .pda file', ToastificationType.error);
      return;
    }

    final key = await _askKey(ctx, false);
    if (key == null || key.isEmpty) return;

    try {
      final decoded = _decodeBackup(file.bytes!, key);

      // Get current keys from Sembast
      final currentKeys = await PrefsDatabase.getKeys();
      final matched = currentKeys.toSet().intersection(decoded.keys.toSet()).length;
      final backupKeys = decoded.keys.length;

      if (matched == 0) {
        _showToast('No matching preferences found in backup!', ToastificationType.error);
        return;
      }

      final confirm = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Confirm restore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Identified $backupKeys saved preferences in this file.'
                  '\n\nRestore on next launch?'),
              Text(
                '\nNote: restart app to apply changes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ctx.read<ThemeProvider>().getTextColor(Colors.red),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('OK')),
          ],
        ),
      );
      if (confirm != true) return;

      await PrefsBackupService.scheduleImport(utf8.decode(file.bytes!), key);
      _showToast('Settings restore scheduled, please restart Torn PDA', ToastificationType.success);
    } catch (_) {
      _showToast('Invalid key or corrupt file', ToastificationType.error);
    }
  }

  Map<String, dynamic> _decodeBackup(Uint8List bytes, String key) {
    final cipher = base64Decode(utf8.decode(bytes));
    final keyBytes = utf8.encode(key);
    final plain = List<int>.generate(cipher.length, (i) => cipher[i] ^ keyBytes[i % keyBytes.length]);
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Save current settings to a file and restore them on next app launch. '
          'A key is required for loading backups.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 15),

        // Manual backup/restore buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(child: Text('Save settings')),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () => _save(context),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(child: Text('Restore settings')),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restore'),
              onPressed: () => _load(context),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Backup reminder switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup reminders'),
                  Text(
                    'Remind to create backups every 90 days',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: _autoBackupReminderEnabled,
              onChanged: (value) async {
                await Prefs().setAutoBackupReminderEnabled(value);
                setState(() {
                  _autoBackupReminderEnabled = value;
                });
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
}
