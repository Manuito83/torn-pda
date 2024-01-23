import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/settings/backup_prefs_groups.dart';
import 'package:torn_pda/widgets/settings/backup/backup_import_widget.dart';
import 'package:torn_pda/widgets/settings/backup/backup_restore_button.dart';
import 'package:torn_pda/widgets/settings/backup/backup_restore_dialog.dart';

class BackupShareDialog extends StatefulWidget {
  final OwnProfileBasic userProfile;
  final ThemeProvider themeProvider;

  const BackupShareDialog({
    required this.userProfile,
    required this.themeProvider,
  });

  @override
  BackupShareDialogState createState() => BackupShareDialogState();
}

class BackupShareDialogState extends State<BackupShareDialog> with TickerProviderStateMixin {
  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  late Future _serverPrefsFetched;
  String _serverError = "";
  Map<String, dynamic> _serverPrefs = {};

  final _selectedItems = <String>[
    "shortcuts",
    "userscripts",
  ];

  bool _overwritteShortcuts = true;
  bool _overwritteUserscripts = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _serverPrefsFetched = Future.wait([_getOriginalServerPrefs()]);
    _tabController = TabController(vsync: this, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "SHARE SETTINGS",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      TabBar(
                        controller: _tabController,
                        onTap: (int index) {
                          _tabController.animateTo(index);
                        },
                        tabs: <Widget>[
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.settings_outlined, color: widget.themeProvider.mainText),
                                SizedBox(width: 10),
                                Text("CONFIGURE", style: TextStyle(color: widget.themeProvider.mainText, fontSize: 12)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download, color: widget.themeProvider.mainText),
                                SizedBox(width: 10),
                                Text("IMPORT", style: TextStyle(color: widget.themeProvider.mainText, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FutureBuilder(
                  future: _serverPrefsFetched,
                  builder: (context, snapshot) {
                    double screenHeight = MediaQuery.of(context).size.height;
                    return Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: screenHeight > 400 ? 400 : screenHeight),
                        child: DefaultTabController(
                          length: 2,
                          child: TabBarView(
                            physics: NeverScrollableScrollPhysics(),
                            controller: _tabController,
                            children: [
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // TODO
                                    Container(child: Text("test" * 500)),
                                  ],
                                ),
                              ),
                              BackupImportWidget(
                                userProfile: widget.userProfile,
                                serverPrefs: _serverPrefs,
                                overwritteCallback: _onOverwritteShortcutsChanged,
                              ),
                            ],
                          ),
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
                          userProfile: widget.userProfile,
                          overwritteShortcuts: _overwritteShortcuts,
                          overwritteUserscripts: _overwritteUserscripts,
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
          );
        },
      ),
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

    _serverPrefs = result["prefs"] ?? {};
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
    }
  }
}
