import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/utils/firebase_functions.dart';

class BackupRestoreButton extends StatefulWidget {
  final OwnProfileBasic userProfile;
  final bool overwritteShortcuts;
  final bool overwritteUserscripts;
  final bool overwritteTargets;
  final bool fromShareDialog;

  const BackupRestoreButton({
    required this.userProfile,
    required this.overwritteShortcuts,
    required this.overwritteUserscripts,
    required this.overwritteTargets,
    this.fromShareDialog = false,
  });

  @override
  BackupRestoreButtonState createState() => BackupRestoreButtonState();
}

class BackupRestoreButtonState extends State<BackupRestoreButton> with TickerProviderStateMixin {
  bool _restoreInProcess = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _restoreInProcess
          ? null
          : () async {
              setState(() {
                _restoreInProcess = true;
              });

              await _restoreOnlineBackup();
              if (mounted) Navigator.pop(context);
            },
      child: _restoreInProcess
          ? SizedBox(height: 20, width: 20, child: const CircularProgressIndicator())
          : const Text("Restore", style: TextStyle(color: Colors.green)),
    );
  }

  Future<void> _restoreOnlineBackup() async {
    //final SharedPreferences prefs = await SharedPreferences.getInstance();

    final result = await firebaseFunctions.getUserPrefs(
      userId: widget.userProfile.playerId ?? 0,
      apiKey: widget.userProfile.userApiKey.toString(),
    );

    // Protect against user closing the dialog while the request is being processed
    if (!mounted) return;

    if (result["success"]) {
      // Shortcuts
      final activeShortcutsList = result["prefs"]["pda_activeShortcutsList"] as List?;
      final shortcutTile = result["prefs"]["pda_shortcutTile"];
      final shortcutMenu = result["prefs"]["pda_shortcutMenu"];
      if (activeShortcutsList != null) {
        // Restore through the provider
        final shortcutsList = activeShortcutsList.map((item) => item as String).toList();
        final shortcutsProvider = context.read<ShortcutsProvider>();
        shortcutsProvider.restoreShortcutsFromServerSave(
          overwritte: widget.overwritteShortcuts,
          shortcutsList: shortcutsList,
          shortcutTile: shortcutTile,
          shortcutMenu: shortcutMenu,
        );
      }

      // User scripts
      String? userscripts = result["prefs"]["pda_userScriptsList"];
      if (userscripts != null) {
        final userscriptsProvider = context.read<UserScriptsProvider>();
        userscriptsProvider.restoreScriptsFromServerSave(
          overwritte: widget.overwritteUserscripts,
          scriptsList: userscripts,
          defaultToDisabled: widget.fromShareDialog,
        );
      }

      // Shortcuts
      final targetsBackup = result["prefs"]["pda_targetsList"] as List?;
      if (targetsBackup != null) {
        // Restore through the provider
        final targetsList = targetsBackup.map((item) => item as String).toList();
        final targetsProvider = context.read<TargetsProvider>();
        targetsProvider.restoreTargetsFromServerSave(
          backup: targetsList,
          overwritte: widget.overwritteTargets,
        );
      }
    }

    BotToast.showText(
      text: result["message"],
      contentColor: result["success"] ? Colors.green : Colors.red,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 10),
      contentPadding: const EdgeInsets.all(10),
    );
  }
}
