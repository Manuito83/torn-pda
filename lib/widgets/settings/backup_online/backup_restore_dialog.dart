import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/settings/backup_online/backup_online_prefs_groups.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_import_widget.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_restore_button.dart';

class BackupRestoreDialog extends StatefulWidget {
  final OwnProfileBasic userProfile;

  const BackupRestoreDialog({
    required this.userProfile,
  });

  @override
  BackupRestoreDialogState createState() => BackupRestoreDialogState();
}

class BackupRestoreDialogState extends State<BackupRestoreDialog> with TickerProviderStateMixin {
  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  late Future _serverPrefsFetched;
  String _serverError = "";
  Map<String, dynamic> _serverPrefs = {};

  // We begin with everything selected
  final _selectedItems = <String>[
    "shortcuts",
    "userscripts",
    "targets",
  ];

  bool _overwritteShortcuts = true;
  bool _overwritteUserscripts = true;
  bool _overwritteTargets = true;

  @override
  void initState() {
    super.initState();
    _serverPrefsFetched = _getOriginalServerPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 10),
                  Text(
                    "RESTORE SETTINGS",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            FutureBuilder(
              future: _serverPrefsFetched,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_serverError.isNotEmpty) {
                    return Column(
                      children: [
                        const Text("SERVER ERROR", style: TextStyle(color: Colors.red)),
                        Text(_serverError, style: const TextStyle(color: Colors.red)),
                      ],
                    );
                  }

                  if (_serverPrefs.isEmpty) {
                    return const Column(
                      children: [
                        Text("No online backup found!"),
                      ],
                    );
                  }

                  return Flexible(
                    child: SingleChildScrollView(
                      child: BackupImportWidget(
                        userProfile: widget.userProfile,
                        serverPrefs: _serverPrefs,
                        overwritteCallback: _onOverwritteShortcutsChanged,
                        toggleBackupSelection: _onToggleBackupSelection,
                      ),
                    ),
                  );
                }
                return const Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Text("Fetching server info..."),
                        SizedBox(height: 25),
                        CircularProgressIndicator(),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_serverPrefs.isNotEmpty && _selectedItems.isNotEmpty && _serverError.isEmpty)
                    BackupRestoreButton(
                      ownBackup: true,
                      userProfile: widget.userProfile,
                      selectedItems: _selectedItems,
                      overwritteShortcuts: _overwritteShortcuts,
                      overwritteUserscripts: _overwritteUserscripts,
                      overwritteTargets: _overwritteTargets,
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _getOriginalServerPrefs() async {
    final result = await firebaseFunctions
        .getUserPrefs(userId: widget.userProfile.playerId ?? 0, apiKey: widget.userProfile.userApiKey.toString())
        .catchError((value) {
      return <String, dynamic>{"success": false, "message": "Could not connect to server"};
    });

    if (!result["success"]) {
      setState(() {
        _serverError = result["message"];
      });
      return;
    }

    setState(() {
      _serverPrefs = result["prefs"] ?? {};
    });
  }

  void _onOverwritteShortcutsChanged(BackupPrefs pref, bool value) {
    switch (pref) {
      case BackupPrefs.shortcuts:
        setState(() {
          _overwritteShortcuts = value;
        });
        break;
      case BackupPrefs.userscripts:
        setState(() {
          _overwritteUserscripts = value;
        });
        break;
      case BackupPrefs.targets:
        setState(() {
          _overwritteTargets = value;
        });
        break;
    }
  }

  void _onToggleBackupSelection(BackupPrefs pref, bool value) {
    switch (pref) {
      case BackupPrefs.shortcuts:
        if (value) {
          setState(() {
            _selectedItems.add("shortcuts");
          });
        } else {
          setState(() {
            _selectedItems.remove("shortcuts");
          });
        }
        break;
      case BackupPrefs.userscripts:
        if (value) {
          setState(() {
            _selectedItems.add("userscripts");
          });
        } else {
          setState(() {
            _selectedItems.remove("userscripts");
          });
        }
        break;
      case BackupPrefs.targets:
        if (value) {
          setState(() {
            _selectedItems.add("targets");
          });
        } else {
          setState(() {
            _selectedItems.remove("targets");
          });
        }
        break;
    }
  }
}
