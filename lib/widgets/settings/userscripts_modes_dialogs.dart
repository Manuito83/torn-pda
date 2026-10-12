// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

void scriptModeShortcut(BuildContext context) {
  final provider = context.read<UserScriptsProvider>();
  if (provider.customModes.isEmpty) {
    provider.setMode(provider.activeMode?.isWar == true ? null : warModeId);
  } else {
    showScriptModePicker(context);
  }
}

Future<void> showScriptModePicker(BuildContext context) {
  final provider = context.read<UserScriptsProvider>();
  final theme = context.read<ThemeProvider>();
  final active = provider.activeMode;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.secondBackground,
      title: Text("Scripts mode", style: TextStyle(color: theme.mainText, fontSize: 16)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in provider.allModes)
              ListTile(
                dense: true,
                leading: Icon(mode.icon, color: mode.color),
                title: Text(
                  mode.name,
                  style: TextStyle(
                    color: theme.mainText,
                    fontWeight: mode.id == active?.id ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  "${provider.modeScriptCount(mode)} script${provider.modeScriptCount(mode) == 1 ? "" : "s"}",
                  style: TextStyle(color: theme.mainText, fontSize: 11),
                ),
                trailing: mode.id == active?.id ? Icon(Icons.check, color: mode.color) : null,
                onTap: () {
                  Navigator.pop(dialogContext);
                  provider.setMode(mode.id);
                },
              ),
            if (active != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.close, color: Colors.grey),
                title: Text("Exit mode", style: TextStyle(color: theme.mainText)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  provider.setMode(null);
                },
              ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.edit_note, color: Colors.grey),
              title: Text("Manage modes", style: TextStyle(color: theme.mainText)),
              onTap: () {
                Navigator.pop(dialogContext);
                showScriptModesManager(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showScriptModesManager(BuildContext context) {
  final theme = context.read<ThemeProvider>();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Consumer<UserScriptsProvider>(
      builder: (_, provider, _) => AlertDialog(
        backgroundColor: theme.secondBackground,
        title: Text("Scripts modes", style: TextStyle(color: theme.mainText, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "War mode is always available and cannot be changed. Create your own modes to run only the scripts "
                "you choose in each situation.",
                style: TextStyle(color: theme.mainText, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final mode in provider.customModes)
                Row(
                  children: [
                    Icon(mode.icon, color: mode.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(mode.name, style: TextStyle(color: theme.mainText)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () async {
                        final name = await _askModeName(dialogContext, provider, existing: mode);
                        if (name != null) provider.renameMode(mode, name);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outlined, size: 20, color: Colors.red[300]),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: dialogContext,
                          builder: (confirmContext) => AlertDialog(
                            backgroundColor: theme.secondBackground,
                            content: Text(
                              "Delete '${mode.name}'? Scripts will stay installed, but they will no longer be "
                              "selected for this mode.",
                              style: TextStyle(color: theme.mainText, fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () => Navigator.pop(confirmContext, false),
                              ),
                              TextButton(
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                onPressed: () => Navigator.pop(confirmContext, true),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) provider.deleteMode(mode);
                      },
                    ),
                  ],
                ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("New mode"),
                onPressed: () async {
                  final name = await _askModeName(dialogContext, provider);
                  if (name != null) provider.addMode(name);
                },
              ),
            ],
          ),
        ),
        actions: [TextButton(child: const Text("Close"), onPressed: () => Navigator.pop(dialogContext))],
      ),
    ),
  );
}

Future<String?> _askModeName(BuildContext context, UserScriptsProvider provider, {UserScriptMode? existing}) {
  final controller = TextEditingController(text: existing?.name);
  final theme = context.read<ThemeProvider>();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (_, setState) => AlertDialog(
        backgroundColor: theme.secondBackground,
        title: Text(
          existing == null ? "New mode" : "Rename mode",
          style: TextStyle(color: theme.mainText, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          style: TextStyle(color: theme.mainText),
          decoration: InputDecoration(hintText: "Mode name", errorText: error),
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(dialogContext)),
          TextButton(
            child: const Text("Save"),
            onPressed: () {
              final name = controller.text.trim();
              final taken = provider.allModes.any(
                (m) => m.id != existing?.id && m.name.toLowerCase() == name.toLowerCase(),
              );
              if (name.isEmpty) {
                setState(() => error = "Enter a name");
              } else if (taken) {
                setState(() => error = "This name is already used");
              } else {
                Navigator.pop(dialogContext, name);
              }
            },
          ),
        ],
      ),
    ),
  );
}
