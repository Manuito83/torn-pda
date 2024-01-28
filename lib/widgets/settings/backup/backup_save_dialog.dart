import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/settings/backup_prefs_groups.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class BackupSaveDialog extends StatefulWidget {
  final OwnProfileBasic userProfile;

  const BackupSaveDialog({
    required this.userProfile,
  });

  @override
  BackupSaveDialogState createState() => BackupSaveDialogState();
}

class BackupSaveDialogState extends State<BackupSaveDialog> with TickerProviderStateMixin {
  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  bool _uploadInProgress = false;
  late Future _serverPrefsFetched;
  String _serverError = "";
  Map<String, dynamic> _serverPrefs = {};

  final _selectedItems = <String>["shortcuts", "userscripts", "targets"];

  @override
  void initState() {
    super.initState();
    _serverPrefsFetched = Future.wait([_getOriginalServerPrefs()]);
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
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload),
                  SizedBox(width: 10),
                  Text(
                    "UPLOAD SETTINGS",
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
                        Text("SERVER ERROR", style: TextStyle(color: Colors.red)),
                        Text(_serverError, style: TextStyle(color: Colors.red)),
                      ],
                    );
                  }

                  return Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Shortcuts
                          _shorcutsMain(),
                          // Userscripts
                          _userscriptsMain(),
                          // Targets
                          _targetsMain(),
                        ],
                      ),
                    ),
                  );
                }
                return Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Text("Fetching server info..."),
                        const SizedBox(height: 25),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 40),
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
                  if (_selectedItems.isNotEmpty && _serverError.isEmpty)
                    TextButton(
                      onPressed: () async {
                        await _sendOnlineBackup();
                        Navigator.pop(context);
                      },
                      child: _uploadInProgress
                          ? Container(height: 20, width: 20, child: CircularProgressIndicator())
                          : Text("Save", style: TextStyle(color: Colors.green)),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Close"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding _userscriptsMain() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
      child: CheckboxListTile(
        checkColor: Colors.white,
        activeColor: Colors.blueGrey,
        value: _selectedItems.contains("userscripts"),
        title: const Text("User scripts"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Scripts list", style: TextStyle(fontSize: 12)),
            BackupPrefsGroups.assessIncoming(_serverPrefs, BackupPrefs.userscripts)
                ? _addExistingSubtitle()
                : Container(),
          ],
        ),
        onChanged: (value) {
          setState(() {
            _selectedItems.contains("userscripts")
                ? _selectedItems.remove("userscripts")
                : _selectedItems.add("userscripts");
          });
        },
      ),
    );
  }

  Padding _shorcutsMain() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
      child: CheckboxListTile(
        checkColor: Colors.white,
        activeColor: Colors.blueGrey,
        value: _selectedItems.contains("shortcuts"),
        title: const Text("Shortcuts"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Shortcuts list and settings", style: TextStyle(fontSize: 12)),
            BackupPrefsGroups.assessIncoming(_serverPrefs, BackupPrefs.shortcuts)
                ? _addExistingSubtitle()
                : Container(),
          ],
        ),
        onChanged: (value) {
          setState(() {
            _selectedItems.contains("shortcuts") ? _selectedItems.remove("shortcuts") : _selectedItems.add("shortcuts");
          });
        },
      ),
    );
  }

  Padding _targetsMain() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
      child: CheckboxListTile(
        checkColor: Colors.white,
        activeColor: Colors.blueGrey,
        value: _selectedItems.contains("targets"),
        title: const Text("Targets"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Targets list and notes", style: TextStyle(fontSize: 12)),
            BackupPrefsGroups.assessIncoming(_serverPrefs, BackupPrefs.targets) ? _addExistingSubtitle() : Container(),
          ],
        ),
        onChanged: (value) {
          setState(() {
            _selectedItems.contains("targets") ? _selectedItems.remove("targets") : _selectedItems.add("targets");
          });
        },
      ),
    );
  }

  Text _addExistingSubtitle() {
    return Text(
      "EXISTING SAVE (OVERWRITTE)",
      style: TextStyle(fontSize: 11, color: Colors.red),
    );
  }

  /// Gets data from prefs and sends it to the online backup
  Future<void> _sendOnlineBackup() async {
    Map<String, dynamic> prefs = {};

    String message = "";
    Color color = Colors.green;

    setState(() {
      _uploadInProgress = true;
    });

    try {
      // Shortcuts
      if (_selectedItems.contains("shortcuts")) {
        final activeShortcutsList = await Prefs().getActiveShortcutsList();
        final shortcutTile = await Prefs().getShortcutTile();
        final shortcutMenu = await Prefs().getShortcutMenu();
        prefs.addEntries([
          MapEntry("pda_activeShortcutsList", activeShortcutsList),
          MapEntry("pda_shortcutTile", shortcutTile),
          MapEntry("pda_shortcutMenu", shortcutMenu),
        ]);
      }

      // Userscripts
      if (_selectedItems.contains("userscripts")) {
        final activeUserscriptsList = await Prefs().getUserScriptsList();
        prefs.addEntries([
          MapEntry("pda_userScriptsList", activeUserscriptsList),
        ]);
      }

      // Targets
      if (_selectedItems.contains("targets")) {
        final targetsList = await Prefs().getTargetsList();
        prefs.addEntries([
          MapEntry("pda_targetsList", targetsList),
        ]);
      }

      // Send to server
      final result = await firebaseFunctions.saveUserPrefs(
        userId: widget.userProfile.playerId ?? 0,
        apiKey: widget.userProfile.userApiKey.toString(),
        prefs: prefs,
      );

      message = result["message"];
      color = result["success"] ? Colors.green : Colors.red;
    } catch (e) {
      message = "Error: $e";
      color = Colors.red;
    }

    BotToast.showText(
      text: message,
      contentColor: color,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 10),
      contentPadding: const EdgeInsets.all(10),
    );

    setState(() {
      _uploadInProgress = false;
    });
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
}
