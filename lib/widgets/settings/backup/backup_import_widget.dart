import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/settings/backup_prefs_groups.dart';

class BackupImportWidget extends StatefulWidget {
  final OwnProfileBasic userProfile;
  final Map<String, dynamic> serverPrefs;
  final Function(BackupPrefs, bool) overwritteCallback;

  const BackupImportWidget({
    required this.userProfile,
    required this.serverPrefs,
    required this.overwritteCallback,
  });

  @override
  BackupImportWidgeState createState() => BackupImportWidgeState();
}

class BackupImportWidgeState extends State<BackupImportWidget> {
  // We begin with everything selected
  final _selectedItems = <String>[
    "shortcuts",
    "userscripts",
  ];

  bool _overwritteShortcuts = true;
  bool _overwritteUserscripts = true;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("Available parameters"),
      if (BackupPrefsGroups.assessIncoming(widget.serverPrefs, BackupPrefs.shortcuts)) _shorcutsMain(),
      Divider(),
      if (BackupPrefsGroups.assessIncoming(widget.serverPrefs, BackupPrefs.userscripts)) _userscriptsMain(),
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
}
