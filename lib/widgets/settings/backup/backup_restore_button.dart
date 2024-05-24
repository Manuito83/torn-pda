import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/utils/firebase_functions.dart';

/// If it's [ownBackup], userProfile must not be null
/// If it's not [ownBackup], user data must come as part of [otherData]
class BackupRestoreButton extends StatefulWidget {
  final bool ownBackup;

  // For own backup
  final OwnProfileBasic? userProfile;

  // For others
  final Map<String, dynamic> otherData;

  // Overwritte parameters
  final bool overwritteShortcuts;
  final bool overwritteUserscripts;
  final bool overwritteTargets;
  final List<String> selectedItems;

  const BackupRestoreButton({
    required this.ownBackup,
    this.userProfile,
    this.otherData = const {},
    required this.selectedItems,
    required this.overwritteShortcuts,
    required this.overwritteUserscripts,
    required this.overwritteTargets,
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

              if (widget.ownBackup) {
                await _restoreOwnOnlineBackup();
              } else {
                await _getOtherOnlineBackup();
              }

              if (mounted) Navigator.pop(context);
            },
      child: _restoreInProcess
          ? SizedBox(height: 20, width: 20, child: const CircularProgressIndicator())
          : const Text("Restore", style: TextStyle(color: Colors.green)),
    );
  }

  Future<void> _restoreOwnOnlineBackup() async {
    if (widget.userProfile == null) {
      BotToast.showText(
        text: "Error getting user data: empty!",
        contentColor: Colors.red,
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        duration: const Duration(seconds: 3),
        contentPadding: const EdgeInsets.all(10),
      );
      return;
    }

    final result = await firebaseFunctions.getUserPrefs(
      userId: widget.userProfile!.playerId ?? 0,
      apiKey: widget.userProfile!.userApiKey.toString(),
    );

    // Protect against user closing the dialog while the request is being processed
    if (!mounted) return;

    if (result["success"]) {
      // Shortcuts
      final activeShortcutsList = result["prefs"]["pda_activeShortcutsList"] as List?;
      final shortcutTile = result["prefs"]["pda_shortcutTile"];
      final shortcutMenu = result["prefs"]["pda_shortcutMenu"];
      if (activeShortcutsList != null && widget.selectedItems.contains("shortcuts")) {
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
      if (userscripts != null && widget.selectedItems.contains("userscripts")) {
        final userscriptsProvider = context.read<UserScriptsProvider>();
        userscriptsProvider.restoreScriptsFromServerSave(
          overwritte: widget.overwritteUserscripts,
          scriptsList: userscripts,
        );
      }

      // Shortcuts
      final targetsBackup = result["prefs"]["pda_targetsList"] as List?;
      if (targetsBackup != null && widget.selectedItems.contains("targets")) {
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

  Future<void> _getOtherOnlineBackup() async {
    // Protect against user closing the dialog while the request is being processed
    if (!mounted) return;

    bool success = false;
    String message = "";

    try {
      if (widget.otherData.isEmpty) {
        BotToast.showText(
          text: "Error getting user data: empty!",
          contentColor: Colors.red,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          duration: const Duration(seconds: 3),
          contentPadding: const EdgeInsets.all(10),
        );
        return;
      }

      // Shortcuts
      final activeShortcutsList = widget.otherData["pda_activeShortcutsList"] as List?;
      final shortcutTile = widget.otherData["pda_shortcutTile"];
      final shortcutMenu = widget.otherData["pda_shortcutMenu"];
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
      String? userscripts = widget.otherData["pda_userScriptsList"];
      if (userscripts != null) {
        final userscriptsProvider = context.read<UserScriptsProvider>();
        userscriptsProvider.restoreScriptsFromServerSave(
          overwritte: widget.overwritteUserscripts,
          scriptsList: userscripts,
          defaultToDisabled: true,
        );
      }

      // Shortcuts
      final targetsBackup = widget.otherData["pda_targetsList"] as List?;
      if (targetsBackup != null) {
        // Restore through the provider
        final targetsList = targetsBackup.map((item) => item as String).toList();
        final targetsProvider = context.read<TargetsProvider>();
        targetsProvider.restoreTargetsFromServerSave(
          backup: targetsList,
          overwritte: widget.overwritteTargets,
        );
      }

      success = true;
      message = "Settings imported successfully!";
    } catch (e, trace) {
      message = "Error importing settings: $e";
      FirebaseCrashlytics.instance.log("PDA Crash at Importing Other User Settings");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }

    BotToast.showText(
      text: message,
      contentColor: success ? Colors.green : Colors.red,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      duration: Duration(seconds: success ? 3 : 5),
      contentPadding: const EdgeInsets.all(10),
    );
  }
}
