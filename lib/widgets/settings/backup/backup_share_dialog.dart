import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/settings/backup_prefs_groups.dart';
import 'package:torn_pda/widgets/settings/backup/backup_import_widget.dart';
import 'package:torn_pda/widgets/settings/backup/backup_restore_button.dart';

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

  bool _overwritteShortcuts = true;
  bool _overwritteUserscripts = true;
  bool _overwritteTargets = true;

  late TabController _tabController;

  // Own share form settings
  final _ownSharePasswordFormKey = GlobalKey<FormState>();
  final _ownSharePasswordController = TextEditingController();
  bool _ownSharePasswordVisible = false;

  // Initial share settings (to detect unsaved changes)
  bool _savingOwnShare = false;
  bool _ownShareEnabledInit = false;
  String _ownSharePasswordInit = "";
  final _ownSelectedItemsInit = <String>["shortcuts", "userscripts", "targets"];

  // Own share settings
  bool _ownShareEnabled = false;
  final _ownSelectedItems = <String>[];

  // Import settings
  final _importPasswordController = TextEditingController();
  final _importIdController = TextEditingController();
  final _importPasswordFormKey = GlobalKey<FormState>();
  final _importIdFormKey = GlobalKey<FormState>();
  bool _importPasswordVisible = false;
  bool _importedUserSuccessfully = false;
  bool _importFetchActive = false;
  Map<String, dynamic> _importedPrefs = {};
  final _importedSelectedItems = <String>[
    "shortcuts",
    "userscripts",
    "targets",
  ];

  @override
  void initState() {
    super.initState();
    _serverPrefsFetched = Future.wait([_getOriginalServerPrefs()]);
    _tabController = TabController(vsync: this, length: 2);
  }

  @override
  void dispose() {
    _ownSharePasswordController.dispose();
    super.dispose();
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
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Padding(
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
                            setState(() {
                              _tabController.animateTo(index);
                            });
                          },
                          tabs: <Widget>[
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.settings_outlined, color: widget.themeProvider.mainText),
                                  SizedBox(width: 10),
                                  Text("CONFIGURE",
                                      style: TextStyle(color: widget.themeProvider.mainText, fontSize: 12)),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                      }

                      if (_serverError.isNotEmpty) {
                        return Column(
                          children: [
                            Text("SERVER ERROR", style: TextStyle(color: Colors.red)),
                            Text(_serverError, style: TextStyle(color: Colors.red)),
                          ],
                        );
                      }

                      double screenHeight = MediaQuery.of(context).size.height;
                      return Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: screenHeight > 500 ? 500 : screenHeight),
                          child: DefaultTabController(
                            length: 2,
                            child: TabBarView(
                              physics: NeverScrollableScrollPhysics(),
                              controller: _tabController,
                              children: [
                                // LEFT TAB
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _ownShareTab(),
                                    ],
                                  ),
                                ),
                                // RIGHT TAB
                                _importTab(),
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
                        if (_tabController.index == 0)
                          TextButton(
                            onPressed: () async {
                              if (_ownSharePasswordFormKey.currentState != null &&
                                  _ownSharePasswordFormKey.currentState!.validate()) {
                                setState(() {
                                  _savingOwnShare = true;
                                });

                                String message = "";
                                Color color = Colors.green;

                                try {
                                  final result = await firebaseFunctions.saveOwnBackupShare(
                                    apiKey: widget.userProfile.userApiKey.toString(),
                                    userId: widget.userProfile.playerId ?? 0,
                                    ownShareEnabled: _ownShareEnabled,
                                    ownSharePassword: _ownSharePasswordController.text,
                                    prefs: _ownSelectedItems,
                                  );

                                  message = result["message"];
                                  color = result["success"] ? Colors.green : Colors.red;

                                  if (result["success"]) {
                                    _updateLastSavedParamsOwnShare();
                                  }
                                } catch (e) {
                                  message = "Error: $e";
                                  color = Colors.red;
                                }

                                BotToast.showText(
                                  text: message,
                                  contentColor: color,
                                  clickClose: true,
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  duration: const Duration(seconds: 4),
                                  contentPadding: const EdgeInsets.all(10),
                                );

                                setState(() {
                                  _savingOwnShare = false;
                                });
                              }
                            },
                            child: _savingOwnShare
                                ? Container(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(),
                                  )
                                : const Text("Save"),
                          ),
                        if (_tabController.index == 1 &&
                            _importedPrefs.isNotEmpty &&
                            _importedSelectedItems.isNotEmpty &&
                            _serverError.isEmpty)
                          BackupRestoreButton(
                            ownBackup: false,
                            otherData: _importedPrefs,
                            overwritteShortcuts: _overwritteShortcuts,
                            overwritteUserscripts: _overwritteUserscripts,
                            overwritteTargets: _overwritteTargets,
                          ),
                        TextButton(
                          onPressed: () {
                            if (_ownShareEnabled != _ownShareEnabledInit ||
                                _ownSharePasswordController.text != _ownSharePasswordInit ||
                                !listEquals(_ownSelectedItems, _ownSelectedItemsInit)) {
                              BotToast.showText(
                                text: "You made changes to your own backup settings but didn't save them!",
                                contentColor: Colors.blue,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                duration: const Duration(seconds: 4),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
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
        },
      ),
    );
  }

  /// Main right tab
  Widget _importTab() {
    if (!_importedUserSuccessfully) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Text(
              "If you have been given another user's backup share password, you can import the user's settings "
              "to your own app by using this form",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 30),
            Form(
              key: _importIdFormKey,
              child: TextFormField(
                autofillHints: const [AutofillHints.username],
                style: const TextStyle(fontSize: 14),
                controller: _importIdController,
                maxLength: 10,
                decoration: InputDecoration(
                  isDense: true,
                  errorMaxLines: 2,
                  counterText: "",
                  border: const OutlineInputBorder(),
                  labelText: 'User ID',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ('Cannot be empty!');
                  }

                  if (int.tryParse(value) == null) {
                    return ('Incorrect numeric id!');
                  }

                  return null;
                },
              ),
            ),
            SizedBox(height: 10),
            Form(
              key: _importPasswordFormKey,
              child: TextFormField(
                autofillHints: const [AutofillHints.password],
                style: const TextStyle(fontSize: 14),
                controller: _importPasswordController,
                obscureText: !_importPasswordVisible,
                maxLength: 10,
                decoration: InputDecoration(
                  isDense: true,
                  errorMaxLines: 2,
                  counterText: "",
                  border: const OutlineInputBorder(),
                  labelText: 'Remote password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ownSharePasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: context.read<ThemeProvider>().currentTheme == AppTheme.light
                          ? Theme.of(context).primaryColorDark
                          : Theme.of(context).primaryColorLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _importPasswordVisible = !_importPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ('Cannot be empty!');
                  }

                  return null;
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_importFetchActive)
                    Container(width: 15, height: 15, child: const CircularProgressIndicator())
                  else
                    const Text('Fetch'),
                ],
              ),
              onPressed: _importFetchActive
                  ? null
                  : () {
                      if (_importIdFormKey.currentState!.validate() &&
                          _importPasswordFormKey.currentState!.validate()) {
                        setState(() {
                          _getImportPrefs();
                        });
                      }
                    },
            ),
          ],
        ),
      );
    }

    return BackupImportWidget(
      userProfile: widget.userProfile,
      serverPrefs: _importedPrefs,
      overwritteCallback: _onOverwritteShortcutsChanged,
      fromShareDialog: true,
    );
  }

  /// Main left tab
  Widget _ownShareTab() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Share own backup")),
              Switch(
                value: _ownShareEnabled,
                onChanged: (enabled) async {
                  setState(() {
                    _ownShareEnabled = enabled;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
          Text(
            "Enable other players to import your selected settings if they know your id and share password",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 20),
          Form(
            key: _ownSharePasswordFormKey,
            child: TextFormField(
              autofillHints: const [AutofillHints.password],
              style: const TextStyle(fontSize: 14),
              controller: _ownSharePasswordController,
              obscureText: !_ownSharePasswordVisible,
              maxLength: 15,
              decoration: InputDecoration(
                isDense: true,
                errorMaxLines: 2,
                counterText: "",
                border: const OutlineInputBorder(),
                labelText: 'Share password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _ownSharePasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: context.read<ThemeProvider>().currentTheme == AppTheme.light
                        ? Theme.of(context).primaryColorDark
                        : Theme.of(context).primaryColorLight,
                  ),
                  onPressed: () {
                    setState(() {
                      _ownSharePasswordVisible = !_ownSharePasswordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                final List<String> errors = [];

                if (value == null || value.isEmpty) {
                  return ('Cannot be empty!');
                }

                // Check password length
                if (value.length < 6) {
                  errors.add('Needs to be at least 6 characters long');
                }

                // Check for special character
                if (!RegExp(r'[@#$%.&*()_+]').hasMatch(value)) {
                  errors.add('Needs to have at least one special character (eg. @ # \$ . % & * () _ +)');
                }

                // Check for uppercase letter
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  errors.add('Needs to have at least one uppercase letter');
                }

                // Check for lowercase letter
                if (!value.contains(RegExp(r'[a-z]'))) {
                  errors.add('Needs to have at least one lowercase letter');
                }

                // Check for number
                if (!value.contains(RegExp(r'\d'))) {
                  errors.add('Needs to have at least one number');
                }

                if (errors.isNotEmpty) {
                  String errorMsg = 'There are errors with your password:\n';
                  for (String err in errors) {
                    errorMsg += '-$err\n';
                  }

                  BotToast.showText(
                    text: errorMsg,
                    clickClose: true,
                    contentColor: Colors.red,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    duration: const Duration(seconds: 6),
                    contentPadding: const EdgeInsets.all(10),
                  );

                  return 'Invalid password';
                }

                return null;
              },
            ),
          ),
          SizedBox(height: 10),
          Text(
            "CAUTION: select a password that you will share with other users with whom you want to share "
            "your settings. Ensure this is NOT your game password or API key.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 20),
          Text("Select what you want to share:"),
          Text(
            "This will be applicable only if you have any settings saved in the server",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          // Shortcuts
          _ownShorcutsMain(),
          // Userscripts
          _ownUserscriptsMain(),
          // Targets
          _ownTargetsMain(),
        ],
      ),
    );
  }

  /// Left tab shortcuts configuration
  Widget _ownShorcutsMain() {
    return CheckboxListTile(
      checkColor: Colors.white,
      activeColor: Colors.blueGrey,
      value: _ownSelectedItems.contains("shortcuts"),
      title: const Text("Shortcuts", style: TextStyle(fontSize: 14)),
      subtitle: Text("Shortcuts list and settings", style: TextStyle(fontSize: 12)),
      onChanged: (value) {
        setState(() {
          _ownSelectedItems.contains("shortcuts")
              ? _ownSelectedItems.remove("shortcuts")
              : _ownSelectedItems.add("shortcuts");
        });
      },
    );
  }

  /// Left tab user scripts configuration
  Widget _ownUserscriptsMain() {
    return CheckboxListTile(
      checkColor: Colors.white,
      activeColor: Colors.blueGrey,
      value: _ownSelectedItems.contains("userscripts"),
      title: const Text("User scripts", style: TextStyle(fontSize: 14)),
      subtitle: Text("Scripts list", style: TextStyle(fontSize: 12)),
      onChanged: (value) {
        if (value == true) {
          BotToast.showText(
            text: "Ensure no identificative information is included in your existing scripts (e.g.: API Key!)",
            clickClose: true,
            contentColor: Colors.orange[800]!,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            duration: const Duration(seconds: 5),
            contentPadding: const EdgeInsets.all(10),
          );
        }

        setState(() {
          _ownSelectedItems.contains("userscripts")
              ? _ownSelectedItems.remove("userscripts")
              : _ownSelectedItems.add("userscripts");
        });
      },
    );
  }

  /// Left tab targets configuration
  Widget _ownTargetsMain() {
    return CheckboxListTile(
      checkColor: Colors.white,
      activeColor: Colors.blueGrey,
      value: _ownSelectedItems.contains("targets"),
      title: const Text("Targets", style: TextStyle(fontSize: 14)),
      subtitle: Text("Targets list and notes", style: TextStyle(fontSize: 12)),
      onChanged: (value) {
        setState(() {
          _ownSelectedItems.contains("targets")
              ? _ownSelectedItems.remove("targets")
              : _ownSelectedItems.add("targets");
        });
      },
    );
  }

  /// Gets the local user prefs so that we can display the current selection saved in the server
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

    // Assign parameters coming from the server
    _importedPrefs = result["prefs"] ?? {};

    final configuration = result["configuration"] ?? {};

    if (configuration["ownShareEnabled"]) {
      _ownShareEnabled = true;
    }

    if (configuration["ownSharePassword"] != null) {
      _ownSharePasswordController.text = configuration["ownSharePassword"];
    }

    if (configuration["ownSharePrefs"] != null) {
      _ownSelectedItems.clear();
      _ownSelectedItems.addAll([...configuration["ownSharePrefs"]]);
    }

    // Save a copy of the init items so that we know whether we've closed the dialog without saving
    _updateLastSavedParamsOwnShare();

    setState(() {});
  }

  /// Retrieves remote import prefs with username and password
  _getImportPrefs() async {
    setState(() {
      _importFetchActive = true;
    });

    String message = "No backup found with the provided details!";
    Color msgColor = Colors.red;

    try {
      final result = await firebaseFunctions.getImportShare(
        shareId: int.parse(_importIdController.text.trim()),
        sharePassword: _importPasswordController.text.trim(),
      );

      if (result["success"]) {
        _importedPrefs = result["prefs"] ?? {};
        if (_importedPrefs.isNotEmpty) {
          _importedUserSuccessfully = true;
          message = "Found backup being shared by user ${_importIdController.text}";
          msgColor = Colors.green;
        }
      } else {
        message = result["message"];
      }
    } catch (e) {
      message = "Error: $e";
    }

    BotToast.showText(
      text: message,
      contentColor: msgColor,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 4),
      contentPadding: const EdgeInsets.all(10),
    );

    setState(() {
      _importFetchActive = false;
    });
  }

  /// Handles state changes for the import checkboxes as a callback from [BackupImportWidget]
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

  /// Last (or initial) saved local user prefs to that we can alert if changes are made but not saved
  void _updateLastSavedParamsOwnShare() {
    _ownShareEnabledInit = _ownShareEnabled;
    _ownSharePasswordInit = _ownSharePasswordController.text;
    _ownSelectedItemsInit.clear();
    _ownSelectedItemsInit.addAll([..._ownSelectedItems]);
  }
}
