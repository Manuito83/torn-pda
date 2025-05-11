import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/utils/shared_prefs_backup.dart';

/// Dialog that handles importing a .pda backup file
class PreferencesImportDialog extends StatelessWidget {
  final Uint8List bytes;

  const PreferencesImportDialog({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    final keyCtl = TextEditingController();

    return AlertDialog(
      title: const Text('Import preferences'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'A backup file was detected. Importing will overwrite ALL current settings',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: keyCtl,
            decoration: const InputDecoration(labelText: 'Decryption key'),
            autofocus: true,
            maxLength: 15,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final key = keyCtl.text.trim();
            if (key.isEmpty) {
              toastification.show(
                context: context,
                title: const Text('No key entered'),
                type: ToastificationType.error,
                alignment: Alignment.bottomCenter,
              );
              return;
            }

            final encoded = utf8.decode(bytes);
            try {
              // validate backup with provided key
              PrefsBackupService.decodeBackup(encoded, key);
            } catch (_) {
              toastification.show(
                context: context,
                title: const Text('Invalid key or corrupt backup', maxLines: 2),
                type: ToastificationType.error,
                alignment: Alignment.bottomCenter,
              );
              return;
            }

            // schedule import for next launch
            await PrefsBackupService.scheduleImport(encoded, key);
            toastification.show(
              context: context,
              title: const Text('Settings restore scheduled, please restart Torn PDA', maxLines: 2),
              type: ToastificationType.success,
              alignment: Alignment.bottomCenter,
            );
            Navigator.pop(context);
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}
