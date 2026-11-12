import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/models/backup/prefs_backup_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs_backup.dart';

/// Dialog that handles importing a .pda backup file
class PreferencesImportDialog extends StatefulWidget {
  final Uint8List bytes;

  const PreferencesImportDialog({super.key, required this.bytes});

  @override
  State<PreferencesImportDialog> createState() => _PreferencesImportDialogState();
}

class _PreferencesImportDialogState extends State<PreferencesImportDialog> {
  final _keyCtl = TextEditingController();
  late final String _encoded = utf8.decode(widget.bytes, allowMalformed: true);
  late final bool _encrypted = isEncryptedBackup(_encoded);
  OpenedBackup? _opened;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!_encrypted) {
      PrefsBackupService.openBackup(_encoded, '').then((opened) {
        if (mounted) setState(() => _opened = opened);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _keyCtl.dispose();
    super.dispose();
  }

  void _toast(String text, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(text, maxLines: 2),
      type: type,
      alignment: Alignment.bottomCenter,
    );
  }

  Future<void> _import() async {
    final key = _keyCtl.text.trim();
    if (_encrypted && key.isEmpty) {
      _toast('No key entered', ToastificationType.error);
      return;
    }

    setState(() => _busy = true);
    try {
      final alreadyOpened = _opened;
      final opened =
          alreadyOpened ?? await PrefsBackupService.openBackup(_encoded, key).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      // Show the warning before importing
      if (alreadyOpened == null && opened.needsReview) {
        setState(() {
          _opened = opened;
          _busy = false;
        });
        return;
      }
      await PrefsBackupService.scheduleImport(opened);
    } catch (e) {
      log(name: 'Backup', 'Import failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Invalid key or corrupt backup', ToastificationType.error);
      return;
    }

    if (!mounted) return;
    _toast('Settings restore scheduled, please restart Torn PDA', ToastificationType.success);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import preferences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A backup file was detected. Importing will overwrite ALL current settings',
              style: TextStyle(fontSize: 12),
            ),
            if (!_encrypted) ...[
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'This is a shareable backup, so no password is needed. Sensitive auth-related data is not imported.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (_opened?.needsReview == true) ImportedScriptsWarning(backup: _opened!),
            const SizedBox(height: 16),
            if (_encrypted)
              TextField(
                controller: _keyCtl,
                decoration: const InputDecoration(labelText: 'Decryption key'),
                autofocus: true,
                maxLength: 20,
                enabled: !_busy && _opened == null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _busy ? null : _import,
          child: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Import'),
        ),
      ],
    );
  }
}

class ImportedScriptsWarning extends StatelessWidget {
  const ImportedScriptsWarning({super.key, required this.backup});

  final OpenedBackup backup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backup.scriptsDisabled)
            const Text(
              'Userscripts are imported disabled - review them before enabling them.',
              style: TextStyle(fontSize: 12),
            ),
          if (backup.activeScripts.isNotEmpty)
            Text(
              'These scripts will run after restoring: ${backup.activeScripts.join(', ')}',
              style: const TextStyle(fontSize: 12),
            ),
          if (backup.apiKeyScripts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                backup.scriptsDisabled
                    ? 'These scripts use your API key: ${backup.apiKeyScripts.join(', ')}'
                    : 'These active scripts use your API key: ${backup.apiKeyScripts.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.read<ThemeProvider>().getTextColor(Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
