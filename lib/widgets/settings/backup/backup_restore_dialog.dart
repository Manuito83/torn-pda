import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/settings/backup_prefs_groups.dart';

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

  bool _restoreInProcess = false;

  late Future _serverPrefsFetched;
  String _serverError = "";
  Map<String, dynamic> _serverPrefs = {};

  // We begin with everything selected
  final _selectedItems = <String>[
    "shortcuts",
    "userscripts",
  ];

  bool _overwritteShortcuts = true;
  bool _overwritteUserscripts = true;

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
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
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
                        Text("SERVER ERROR", style: TextStyle(color: Colors.red)),
                        Text(_serverError, style: TextStyle(color: Colors.red)),
                      ],
                    );
                  }

                  if (_serverPrefs.isEmpty) {
                    return Column(
                      children: [
                        Text("No online backup found!"),
                      ],
                    );
                  }

                  return Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text("Available parameters"),
                          if (BackupPrefsGroups.assessIncoming(_serverPrefs, BackupPrefs.shortcuts)) _shorcutsMain(),
                          Divider(),
                          if (BackupPrefsGroups.assessIncoming(_serverPrefs, BackupPrefs.userscripts))
                            _userscriptsMain(),
                        ],
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 50, bottom: 50),
                  child: Column(
                    children: [
                      const Text("Fetching server info..."),
                      const SizedBox(height: 25),
                      const CircularProgressIndicator(),
                    ],
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
                    TextButton(
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

  Widget _shorcutsMain() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
          child: CheckboxListTile(
            checkColor: Colors.white,
            activeColor: Colors.blueGrey,
            value: _selectedItems.contains("shortcuts"),
            title: const Text("Shorcuts"),
            subtitle: Text("Shortcuts list and settings", style: TextStyle(fontSize: 12)),
            onChanged: (value) {
              setState(() {
                _selectedItems.contains("shortcuts")
                    ? _selectedItems.remove("shortcuts")
                    : _selectedItems.add("shortcuts");
              });
            },
          ),
        ),
        if (_selectedItems.contains("shortcuts"))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  child: Icon(Icons.info_outline),
                  onTap: () {
                    BotToast.showText(
                      text: "If enabled, your shorcuts will be erased and a new list will be built "
                          "from the server\n\nIf disabled, incoming shorcuts will be added to the "
                          "existing ones when possible (avoiding repetitions)",
                      clickClose: true,
                      contentColor: Colors.blue,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      duration: const Duration(seconds: 10),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  },
                ),
                SizedBox(width: 15),
                const Flexible(
                  child: Text(
                    "Overwritte existing",
                  ),
                ),
                SizedBox(width: 15),
                Switch(
                  value: _overwritteShortcuts,
                  onChanged: (value) async {
                    setState(() {
                      _overwritteShortcuts = value;
                    });
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _userscriptsMain() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
          child: CheckboxListTile(
            checkColor: Colors.white,
            activeColor: Colors.blueGrey,
            value: _selectedItems.contains("userscripts"),
            title: const Text("User scripts"),
            subtitle: Text("Scripts list", style: TextStyle(fontSize: 12)),
            onChanged: (value) {
              setState(() {
                _selectedItems.contains("userscripts")
                    ? _selectedItems.remove("userscripts")
                    : _selectedItems.add("userscripts");
              });
            },
          ),
        ),
        if (_selectedItems.contains("userscripts"))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  child: Icon(Icons.info_outline),
                  onTap: () {
                    BotToast.showText(
                      text: "If enabled, your user scripts will be erased and a new list will be built "
                          "from the server\n\nIf disabled, incoming user scripts will be added to the "
                          "existing ones when possible (avoiding repetitions)",
                      clickClose: true,
                      contentColor: Colors.blue,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      duration: const Duration(seconds: 10),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  },
                ),
                SizedBox(width: 15),
                const Flexible(
                  child: Text(
                    "Overwritte existing",
                  ),
                ),
                SizedBox(width: 15),
                Switch(
                  value: _overwritteUserscripts,
                  onChanged: (value) async {
                    setState(() {
                      _overwritteUserscripts = value;
                    });
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Receives data from online backup and loads it into the appropiate prefs, controllers and providers
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
          overwritte: _overwritteShortcuts,
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
          overwritte: _overwritteUserscripts,
          scriptsList: userscripts,
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

  Future _getOriginalServerPrefs() async {
    final result = await firebaseFunctions.getUserPrefs(
      userId: widget.userProfile.playerId ?? 0,
      apiKey: widget.userProfile.userApiKey.toString(),
    );

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
