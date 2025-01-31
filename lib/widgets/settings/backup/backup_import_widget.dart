import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/settings/backup_prefs_groups.dart';

/// If [fromShareDialog] is true, import settings won't be filled by default, and we'll also give an extra
/// warning in case that user scripts are selected
class BackupImportWidget extends StatefulWidget {
  final OwnProfileBasic userProfile;
  final Map<String, dynamic> serverPrefs;
  final Function(BackupPrefs, bool) overwritteCallback;
  final Function(BackupPrefs, bool) toggleBackupSelection;
  final bool fromShareDialog;

  const BackupImportWidget({
    required this.userProfile,
    required this.serverPrefs,
    required this.overwritteCallback,
    required this.toggleBackupSelection,
    this.fromShareDialog = false,
  });

  @override
  BackupImportWidgeState createState() => BackupImportWidgeState();
}

class BackupImportWidgeState extends State<BackupImportWidget> {
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
    if (widget.fromShareDialog) {
      _selectedItems.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("Available parameters"),
      if (BackupPrefsGroups.assessIncoming(widget.serverPrefs, BackupPrefs.shortcuts))
        Column(
          children: [
            _shorcutsMain(),
          ],
        ),
      if (BackupPrefsGroups.assessIncoming(widget.serverPrefs, BackupPrefs.userscripts))
        Column(
          children: [
            Divider(),
            _userscriptsMain(),
          ],
        ),
      if (BackupPrefsGroups.assessIncoming(widget.serverPrefs, BackupPrefs.targets))
        Column(
          children: [
            Divider(),
            _targetsMain(),
          ],
        ),
    ]);
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
                final bool shouldEnable = !_selectedItems.contains("shortcuts");
                setState(() {
                  shouldEnable ? _selectedItems.add("shortcuts") : _selectedItems.remove("shortcuts");
                });
                widget.toggleBackupSelection(BackupPrefs.shortcuts, shouldEnable);
              }),
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
                    "Overwrite existing",
                  ),
                ),
                SizedBox(width: 15),
                Switch(
                  value: _overwritteShortcuts,
                  onChanged: (value) async {
                    setState(() {
                      _overwritteShortcuts = value;
                    });
                    widget.overwritteCallback(BackupPrefs.shortcuts, value);
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
              if (widget.fromShareDialog && value == true) {
                BotToast.showText(
                  text: "Plase ensure that you carefully review incoming user scripts and ensure that you trust the "
                      "source.\n\nBy default, user scripts from other players will be imported as disabled",
                  clickClose: true,
                  contentColor: Colors.orange[800]!,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  duration: const Duration(seconds: 8),
                  contentPadding: const EdgeInsets.all(10),
                );
              }
              final bool shouldEnable = !_selectedItems.contains("userscripts");
              setState(() {
                shouldEnable ? _selectedItems.add("userscripts") : _selectedItems.remove("userscripts");
              });
              widget.toggleBackupSelection(BackupPrefs.userscripts, shouldEnable);
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
                    "Overwrite existing",
                  ),
                ),
                SizedBox(width: 15),
                Switch(
                  value: _overwritteUserscripts,
                  onChanged: (value) async {
                    setState(() {
                      _overwritteUserscripts = value;
                    });
                    widget.overwritteCallback(BackupPrefs.userscripts, value);
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

  Widget _targetsMain() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
          child: CheckboxListTile(
            checkColor: Colors.white,
            activeColor: Colors.blueGrey,
            value: _selectedItems.contains("targets"),
            title: const Text("Targets"),
            subtitle: Text("Targets list and notes", style: TextStyle(fontSize: 12)),
            onChanged: (value) {
              final bool shouldEnable = !_selectedItems.contains("targets");
              setState(() {
                shouldEnable ? _selectedItems.add("targets") : _selectedItems.remove("targets");
              });
              widget.toggleBackupSelection(BackupPrefs.targets, shouldEnable);
            },
          ),
        ),
        if (_selectedItems.contains("targets"))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  child: Icon(Icons.info_outline),
                  onTap: () {
                    BotToast.showText(
                      text: "If enabled, your targets will be erased and a new list will be built "
                          "from the server\n\nIf disabled, incoming targets will be added to the "
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
                    "Overwrite existing",
                  ),
                ),
                SizedBox(width: 15),
                Switch(
                  value: _overwritteTargets,
                  onChanged: (value) async {
                    setState(() {
                      _overwritteTargets = value;
                    });
                    widget.overwritteCallback(BackupPrefs.targets, value);
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
}
