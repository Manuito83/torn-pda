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
  static Future<String?> createBackup({
    String? key,
    String? customName,
    BackupExportMode mode = BackupExportMode.private,
  }) async {
    final data = await PrefsBackupService.exportPrefs(key: key, mode: mode);
    final bytes = Uint8List.fromList(utf8.encode(data));

    String timestamp() {
      final d = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}${two(d.second)}';
    }

    final defaultName = mode == BackupExportMode.shareable
        ? 'pda_settings_shareable_${timestamp()}'
        : 'pda_settings_private_${timestamp()}';

    final result = await FileSaver.instance.saveAs(
      name: customName ?? defaultName,
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
    BackupExportMode selectedMode = BackupExportMode.private;

    final choice = await showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Create local backup'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose whether this backup is only for you or safe to share with other players.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<BackupExportMode>(
                    showSelectedIcon: false,
                    multiSelectionEnabled: false,
                    segments: const [
                      ButtonSegment<BackupExportMode>(
                        value: BackupExportMode.private,
                        label: Text('Private'),
                        icon: Icon(Icons.lock),
                      ),
                      ButtonSegment<BackupExportMode>(
                        value: BackupExportMode.shareable,
                        label: Text('Shareable'),
                        icon: Icon(Icons.share),
                      ),
                    ],
                    selected: <BackupExportMode>{selectedMode},
                    onSelectionChanged: (selection) {
                      setStateDialog(() {
                        selectedMode = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedMode == BackupExportMode.private)
                    const Text(
                      'Encrypted. Keeps API keys, auth-related data and personal session state.',
                      style: TextStyle(fontSize: 12),
                    )
                  else
                    const Text(
                      'No password. Excludes API keys, native login data, Firebase tokens and browser session state.',
                      style: TextStyle(fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  if (selectedMode == BackupExportMode.private) ...[
                    const Text(
                      'You will need this key to restore the settings in the future, so make sure to remember it.',
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: keyCtl,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Encryption key',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ] else
                    Text(
                      'This backup will be saved without a password and suggested as pda_settings_shareable_...\n\n'
                      'Sensitive authentication-related data will be excluded automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: ctx.read<ThemeProvider>().mainText,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(_, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(_, 'local'),
                icon: const Icon(Icons.save),
                label: const Text('Local Save'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(_, 'other'),
                icon: const Icon(Icons.share),
                label: const Text('Other Apps'),
              ),
            ],
          );
        },
      ),
    );

    if (choice == null) return; // cancelled
    final key = keyCtl.text.trim();
    final mode = selectedMode;

    if (mode == BackupExportMode.private && key.isEmpty) {
      _showToast('No key entered', ToastificationType.error);
      return;
    }

    if (choice == 'local') {
      await _savePrefsToDisk(ctx, key: key, mode: mode);
    } else if (choice == 'other') {
      await _saveWithShareIntent(ctx, key: key, mode: mode);
    }
  }

  Future<void> _savePrefsToDisk(
    BuildContext ctx, {
    required String? key,
    required BackupExportMode mode,
  }) async {
    final result = await PrefsBackupWidget.createBackup(key: key, mode: mode);
    if (result != null) {
      _showToast('Backup saved', ToastificationType.success);
    }
  }

  Future<void> _saveWithShareIntent(
    BuildContext ctx, {
    required String? key,
    required BackupExportMode mode,
  }) async {
    final data = await PrefsBackupService.exportPrefs(key: key, mode: mode);

    // Create timestamp similar to the static method
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final timestamp = '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}${two(d.second)}';

    final dir = await getTemporaryDirectory();
    final prefix = mode == BackupExportMode.shareable ? 'pda_settings_shareable' : 'pda_settings_private';
    final file = File('${dir.path}/${prefix}_$timestamp.pda');
    await file.writeAsString(data);

    final renderObject = ctx.findRenderObject();
    final shareOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : const Rect.fromLTWH(0, 0, 1, 1);

    final shareParams = ShareParams(
      files: [XFile(file.path)],
      sharePositionOrigin: shareOrigin,
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

    final encoded = utf8.decode(file.bytes!);
    final inspection = PrefsBackupService.inspectBackup(encoded);

    String key = '';
    if (inspection.requiresKey) {
      final enteredKey = await _askKey(ctx, false);
      if (enteredKey == null || enteredKey.isEmpty) return;
      key = enteredKey;
    }

    try {
      final decoded = PrefsBackupService.decodeBackup(encoded, key);

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
              if (inspection.mode == BackupExportMode.shareable)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'This is a shareable backup. API keys, auth-related data and browser session state were excluded.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: ctx.read<ThemeProvider>().mainText,
                    ),
                  ),
                ),
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

      await PrefsBackupService.scheduleImport(encoded, key);
      _showToast('Settings restore scheduled, please restart Torn PDA', ToastificationType.success);
    } catch (_) {
      _showToast('Invalid key or corrupt file', ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Save current settings to a file and restore them on next app launch. '
          'Private backups use a key; shareable backups exclude sensitive authentication data.',
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
