// Flutter imports:
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_simple_dialog.dart';

class UserScriptsAddDialog extends StatefulWidget {
  final bool editExisting;
  final UserScriptModel? editScript;
  final int defaultPage;
  final String? defaultUrl;

  const UserScriptsAddDialog({required this.editExisting, this.editScript, this.defaultPage = 0, this.defaultUrl});

  @override
  UserScriptsAddDialogState createState() => UserScriptsAddDialogState();
}

class UserScriptsAddDialogState extends State<UserScriptsAddDialog> with TickerProviderStateMixin {
  final pdaKeyWord = "###PDA-APIKEY###";

  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  final _addNameController = TextEditingController();
  final _addSourceController = TextEditingController();
  final _nameFormKey = GlobalKey<FormState>();
  final _sourceFormKey = GlobalKey<FormState>();

  // Custom API Key handling
  bool _mainTabFirstSavePress = true;
  bool _remoteTabFirstLoadOrSavePress = true;
  bool _showCustomApiKeyButton = false;
  String _customApiKey = "";
  bool _isCurrentScriptCandidateForCustomApiKey = false;
  UserScriptModel? _fetchedRemoteModel;

  // Remote source handlingt
  final _remoteUrlController = TextEditingController();
  final _remoteUrlKey = GlobalKey<FormState>();
  final _remoteSourceFormKey = GlobalKey<FormState>();
  bool _remoteSourceFetching = false;
  final _remoteSourceController = TextEditingController();
  final _remoteNameController = TextEditingController();
  final _remoteRunTimeController = TextEditingController();

  late UserScriptsProvider _userScriptsProvider;
  late ThemeProvider _themeProvider;

  String? _originalSource = "";
  String? _originalName = "";

  UserScriptModel? model;

  UserScriptTime _originalTime = UserScriptTime.end;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    _tabController = TabController(vsync: this, length: 2);
    _tabController.animateTo(widget.defaultPage);

    if (widget.editExisting) {
      for (final script in _userScriptsProvider.userScriptList) {
        if (script.name == widget.editScript!.name) {
          _addNameController.text = script.name;
          _addSourceController.text = script.source;
          _originalSource = script.source;
          _originalName = script.name;
          _originalTime = script.time;
          _customApiKey = script.customApiKey;
          _isCurrentScriptCandidateForCustomApiKey = script.source.contains(pdaKeyWord);
          _showCustomApiKeyButton = _isCurrentScriptCandidateForCustomApiKey;

          _remoteNameController.text = script.name;
          _remoteUrlController.text = script.url ?? "";
        }
      }
    } else if (widget.defaultUrl != null) {
      _remoteUrlController.text = widget.defaultUrl!;
    }

    // Listen to source changes on the main tab
    _addSourceController.addListener(_onMainTabSourceChanged);

    // Listen to changes so that "clear" button becomes active when there is text in the URL field
    _remoteUrlController.addListener(() {
      setState(() {});
    });
  }

  void _onMainTabSourceChanged() {
    // Only main tab
    if (_tabController.index == 0) {
      final pdaLogicFound = _addSourceController.text.contains(pdaKeyWord);

      // Update state if the candidate status changes or needs to be corrected
      if (pdaLogicFound != _isCurrentScriptCandidateForCustomApiKey || pdaLogicFound != _showCustomApiKeyButton) {
        setState(() {
          _isCurrentScriptCandidateForCustomApiKey = pdaLogicFound;
          _showCustomApiKeyButton = _isCurrentScriptCandidateForCustomApiKey;
        });
      }
    }
  }

  @override
  Future dispose() async {
    _addSourceController.removeListener(_onMainTabSourceChanged);
    _addNameController.dispose();
    _addSourceController.dispose();
    _remoteUrlController.dispose();
    _remoteSourceController.dispose();
    _remoteNameController.dispose();
    _remoteRunTimeController.dispose();
    _tabController.dispose();
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
      child: DefaultTabController(
        length: 2,
        child: TabBarView(
          controller: _tabController,
          children: [
            _mainAddTab(),
            _remoteLoadTab(),
          ],
        ),
      ),
    );
  }

  Widget _mainAddTab() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.code),
                const SizedBox(width: 6),
                Text(widget.editExisting ? "Edit existing script" : "Add new script"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _nameFormKey,
              child: TextFormField(
                style: const TextStyle(fontSize: 12),
                controller: _addNameController,
                maxLength: 100,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: "",
                  border: OutlineInputBorder(),
                  labelText: 'Script name',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Enter a valid name!";
                  }
                  for (final script in _userScriptsProvider.userScriptList) {
                    if (script.name.toLowerCase() == value.toLowerCase()) {
                      if (!widget.editExisting) {
                        return "Script name already taken!";
                      } else {
                        // Allow to save same script, but not if it conflicts
                        // with another existing script
                        if (script.name.toLowerCase() != widget.editScript!.name.toLowerCase()) {
                          return "Script name already taken!";
                        }
                      }
                    }
                  }
                  _addNameController.text = value.trim();
                  return null;
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(MdiIcons.earth, size: 14),
                    SizedBox(width: 4),
                    Text("Remote load/update"),
                  ],
                ),
                ElevatedButton(
                  child: const Text("Configure"),
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 0, 10, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(MdiIcons.lightningBoltOutline, size: 16),
                    SizedBox(width: 4),
                    Text("Injection time"),
                  ],
                ),
                ToggleSwitch(
                  minHeight: 28,
                  customHeights: const [30, 30],
                  borderColor: _themeProvider.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
                  initialLabelIndex: _originalTime == UserScriptTime.start ? 0 : 1,
                  activeBgColor: _themeProvider.currentTheme == AppTheme.light
                      ? [Colors.blueGrey[400]!]
                      : _themeProvider.currentTheme == AppTheme.dark
                          ? [Colors.blueGrey]
                          : [Colors.blueGrey[700]!],
                  activeFgColor: _themeProvider.currentTheme == AppTheme.light ? Colors.black : Colors.white,
                  inactiveBgColor: _themeProvider.currentTheme == AppTheme.light
                      ? Colors.white
                      : _themeProvider.currentTheme == AppTheme.dark
                          ? Colors.grey[800]
                          : Colors.black,
                  inactiveFgColor: _themeProvider.currentTheme == AppTheme.light ? Colors.black : Colors.white,
                  borderWidth: 1,
                  cornerRadius: 5,
                  totalSwitches: 2,
                  animate: true,
                  animationDuration: 500,
                  labels: const ["START", "END"],
                  onToggle: (index) {
                    index == 0 ? _originalTime = UserScriptTime.start : _originalTime = UserScriptTime.end;
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Form(
                key: _sourceFormKey,
                child: TextFormField(
                  maxLines: null,
                  expands: true,
                  autocorrect: false,
                  style: const TextStyle(fontSize: 12),
                  controller: _addSourceController,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    isDense: true,
                    counterText: "",
                    border: OutlineInputBorder(),
                    labelText: 'Paste source code',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Cannot be empty!";
                    }
                    try {
                      // Check whether the userscript can be parsed or not. This will throw an error if not,
                      // so warn the user it will be injected in all pages.
                      UserScriptModel.parseHeader(value);
                      // If no error is thrown, approve the data
                      return null;
                    } on Exception catch (e) {
                      if (e.toString().contains("No header found")) {
                        BotToast.showText(
                            text: "No header was found in the script, it will be injected in all pages!",
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.orange[800]!,
                            duration: const Duration(seconds: 4),
                            contentPadding: const EdgeInsets.all(10));
                        return null;
                      } else {
                        // If the error is not about the header, show it to the user.
                        return e.toString();
                      }
                    } catch (e) {
                      // Should not happen, but just in case...
                      return e.toString();
                    }
                  },
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_showCustomApiKeyButton) _customApiKeyButton() else const SizedBox(),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      child: Text(widget.editExisting ? "Save" : "Add"),
                      onPressed: () async {
                        await _addPressed(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Future<void> _showCustomApiKeyDialog() async {
    final TextEditingController apiKeyController = TextEditingController(text: _customApiKey);
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom API Key'),
          content: TextField(
            controller: apiKeyController,
            decoration: const InputDecoration(hintText: "Custom script API key"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(apiKeyController.text);
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _customApiKey = result;
        // If a key is set, we don't need to confirm the save action
        if (_tabController.index == 0) {
          _mainTabFirstSavePress = false;
        } else {
          _remoteTabFirstLoadOrSavePress = false;
        }

        // Update the API key button visibility
        _showCustomApiKeyButton = true;
      });
    }
  }

  Widget _remoteLoadTab() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                    width: 20,
                    child: GestureDetector(
                      child: const Icon(MdiIcons.arrowLeft),
                      onTap: () {
                        _tabController.animateTo(0);
                      },
                    )),
                Row(
                  children: [
                    const Icon(MdiIcons.earth),
                    const SizedBox(width: 6),
                    Text(widget.editExisting ? "Remote script update" : "Remote script load"),
                  ],
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 25, 8, 8),
            child: Form(
              key: _remoteUrlKey,
              child: TextFormField(
                style: const TextStyle(fontSize: 12),
                controller: _remoteUrlController,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: "",
                  border: OutlineInputBorder(),
                  labelText: 'Remote URL',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains("https")) {
                    return "Enter a valid URL!";
                  }
                  _addNameController.text = value.trim();
                  return null;
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    child: Text(widget.editExisting ? "Check for Update" : "Fetch"),
                    onPressed: () async {
                      if (!_remoteUrlKey.currentState!.validate()) {
                        return;
                      }
                      bool success = false;
                      String? message;
                      UserScriptModel? resultModel;

                      try {
                        setState(() => _remoteSourceFetching = true);

                        final result = await UserScriptModel.fromURL(_remoteUrlController.text.trim());

                        success = result.success;
                        message = result.message;
                        resultModel = result.model;
                      } catch (e) {
                        log(e.toString());
                        message = "Fetch error: $e";
                      } finally {
                        bool fetchWasSuccessful = success && resultModel != null;
                        bool newRemoteSourceIsCandidate = false;

                        if (fetchWasSuccessful) {
                          _fetchedRemoteModel = resultModel;
                          _remoteSourceController.text = resultModel.source;
                          _remoteNameController.text = resultModel.name;
                          _remoteRunTimeController.text = resultModel.time.name;
                          newRemoteSourceIsCandidate = resultModel.source.contains(pdaKeyWord);

                          if (mounted) {
                            setState(() {
                              _isCurrentScriptCandidateForCustomApiKey = newRemoteSourceIsCandidate;
                              _showCustomApiKeyButton = newRemoteSourceIsCandidate;
                              _remoteTabFirstLoadOrSavePress = true;
                            });
                          }
                        }

                        if (!widget.editExisting) {
                          // New remote script
                          BotToast.showText(
                            align: const Alignment(0, 0),
                            clickClose: true,
                            text: message ??
                                (fetchWasSuccessful
                                    ? "Fetch successful. Review and Load."
                                    : "An unknown error occurred during fetch."),
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: fetchWasSuccessful ? Colors.green : Colors.orange[800]!,
                            duration: const Duration(seconds: 4),
                            contentPadding: const EdgeInsets.all(10),
                          );
                        } else {
                          // Editing existing script
                          if (!fetchWasSuccessful) {
                            log("An error occurred while checking for update for script ${widget.editScript!.name}: $message");
                            BotToast.showText(
                              align: const Alignment(0, 0),
                              clickClose: true,
                              text: message ?? "An unknown error occurred while checking for update.",
                              textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                              contentColor: Colors.orange[800]!,
                              duration: const Duration(seconds: 4),
                              contentPadding: const EdgeInsets.all(10),
                            );
                          } else {
                            try {
                              final String newVersion = resultModel.version;
                              final String oldVersion = widget.editScript!.version;
                              final bool isNewerVersionAvailable =
                                  UserScriptModel.isNewerVersion(newVersion, oldVersion);
                              final String finalMessage = isNewerVersionAvailable
                                  ? "Newer version found: $newVersion\nPlease review changes and save!"
                                  : "No newer version found. Current: $oldVersion";
                              log(finalMessage);
                              BotToast.showText(
                                align: const Alignment(0, 0),
                                clickClose: true,
                                text: finalMessage,
                                textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                contentColor: isNewerVersionAvailable ? Colors.green : Colors.orange[800]!,
                                duration: const Duration(seconds: 4),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            } catch (e) {
                              log("An error occurred processing remote data for script ${widget.editScript!.name}: $e");
                              BotToast.showText(
                                align: const Alignment(0, 0),
                                clickClose: true,
                                text: "An unknown error occurred whilst parsing the remote script.",
                                textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                contentColor: Colors.orange[800]!,
                                duration: const Duration(seconds: 4),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
                          }
                        }

                        if (mounted) {
                          setState(() => _remoteSourceFetching = false);
                        }
                      }
                    }),
                const SizedBox(width: 20),
                ElevatedButton(
                  child: const Text("Clear"),
                  onPressed: _remoteUrlController.text.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _remoteUrlController.clear();
                            _remoteSourceController.clear();
                            _remoteNameController.clear();
                            _remoteRunTimeController.clear();
                            _fetchedRemoteModel = null;
                            _remoteTabFirstLoadOrSavePress = true;

                            if (widget.editExisting && widget.editScript != null) {
                              // If editing, candidate status based on the source currently in the main tab editor
                              _isCurrentScriptCandidateForCustomApiKey = _addSourceController.text.contains(pdaKeyWord);
                              _showCustomApiKeyButton = _isCurrentScriptCandidateForCustomApiKey;
                              // Allow main tab to prompt again if needed by resetting its first save press flag
                              _mainTabFirstSavePress = true;
                            } else {
                              // If we were adding a new script, the main tab's source determines candidate status
                              _isCurrentScriptCandidateForCustomApiKey = _addSourceController.text.contains(pdaKeyWord);
                              _showCustomApiKeyButton = _isCurrentScriptCandidateForCustomApiKey;
                            }
                          });
                        },
                ),
              ],
            ),
          ),
          _remoteSourceFetching
              ? const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Fetching script..."),
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                    ],
                  ),
                )
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Form(
                      key: _remoteSourceFormKey,
                      child: TextFormField(
                        readOnly: true,
                        maxLines: null,
                        expands: true,
                        autocorrect: false,
                        style: const TextStyle(fontSize: 12),
                        controller: _remoteSourceController,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          isDense: true,
                          counterText: "",
                          border: const OutlineInputBorder(),
                          label:
                              _remoteSourceController.text.isEmpty ? const Center(child: Text("Remote source")) : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Cannot be empty!";
                          }
                          _remoteSourceController.text = value.trim();
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_showCustomApiKeyButton) _customApiKeyButton() else const SizedBox(),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  ElevatedButton(
                    child: Text(widget.editExisting ? "Update" : "Load"),
                    onPressed: _remoteNameController.text.isEmpty ||
                            _remoteSourceController.text.isEmpty ||
                            _remoteRunTimeController.text.isEmpty ||
                            _fetchedRemoteModel == null
                        ? null
                        : () async {
                            if (_isCurrentScriptCandidateForCustomApiKey &&
                                _remoteTabFirstLoadOrSavePress &&
                                _customApiKey.isEmpty) {
                              setState(() {
                                _remoteTabFirstLoadOrSavePress = false;
                                _showCustomApiKeyButton = true;
                              });
                              _saveScriptWithoutApiKeyWarning();
                              return;
                            }

                            Navigator.of(context).pop();

                            if (!widget.editExisting) {
                              _fetchedRemoteModel!.customApiKey = _customApiKey;
                              _userScriptsProvider.addUserScriptByModel(_fetchedRemoteModel!);
                              BotToast.showText(
                                align: const Alignment(0, 0),
                                clickClose: true,
                                text: "Script successfully added!",
                                textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                contentColor: Colors.green,
                                duration: const Duration(seconds: 4),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            } else {
                              final bool couldParseHeader = _userScriptsProvider.updateUserScript(
                                widget.editScript!,
                                _fetchedRemoteModel!.name,
                                _fetchedRemoteModel!.time,
                                _fetchedRemoteModel!.source,
                                true, // source changed (it's from remote)
                                true, // isFromRemote
                                _customApiKey,
                              );
                              BotToast.showText(
                                align: const Alignment(0, 0),
                                clickClose: true,
                                text: couldParseHeader
                                    ? "Script successfully updated!"
                                    : "Could not parse the header, the script will inject on all pages.",
                                textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                contentColor: couldParseHeader ? Colors.green : Colors.orange[800]!,
                                duration: const Duration(seconds: 4),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
                            _remoteTabFirstLoadOrSavePress = true;
                            _customApiKey = "";
                            _isCurrentScriptCandidateForCustomApiKey = false;
                            _showCustomApiKeyButton = false;
                            _fetchedRemoteModel = null;
                          },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(child: const Text("Cancel"), onPressed: Navigator.of(context).pop)
                ]),
              ),
            ],
          )
        ]));
  }

  Future<void> _addPressed(BuildContext context) async {
    if (_nameFormKey.currentState!.validate() && _sourceFormKey.currentState!.validate()) {
      final inputName = _addNameController.text;
      final inputTime = _originalTime;
      final inputSource = _addSourceController.text;

      final bool isCandidate = inputSource.contains(pdaKeyWord);

      if (isCandidate && _mainTabFirstSavePress && _customApiKey.isEmpty) {
        setState(() {
          _mainTabFirstSavePress = false;
          _isCurrentScriptCandidateForCustomApiKey = true;
          _showCustomApiKeyButton = true;
        });
        _saveScriptWithoutApiKeyWarning();
        return;
      }

      Navigator.of(context).pop();

      _addNameController.text = _addSourceController.text = '';

      if (!widget.editExisting) {
        try {
          final metaMap = UserScriptModel.parseHeader(inputSource);
          _userScriptsProvider.addUserScriptByModel(UserScriptModel.fromMetaMap(metaMap,
              name: inputName, source: inputSource, time: inputTime, customApiKey: _customApiKey));
        } on Exception catch (e) {
          if (e.toString().contains("No header found")) {
            BotToast.showText(
                text: "No header was found in the script, it will be injected in all pages!",
                textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                contentColor: Colors.orange[800]!,
                duration: const Duration(seconds: 4),
                contentPadding: const EdgeInsets.all(10));
            _userScriptsProvider.addUserScriptByModel(UserScriptModel(
              enabled: true,
              matches: const ["*"],
              name: inputName,
              version: "0.0.0",
              edited: true,
              source: inputSource,
              time: inputTime,
              updateStatus: UserScriptUpdateStatus.noRemote,
              isExample: false,
              customApiKey: _customApiKey,
            ));
          } else {
            BotToast.showText(
              align: const Alignment(0, 0),
              clickClose: true,
              text: "Error parsing script: $e",
              textStyle: const TextStyle(fontSize: 14, color: Colors.white),
              contentColor: Colors.orange[800]!,
              duration: const Duration(seconds: 4),
              contentPadding: const EdgeInsets.all(10),
            );
          }
        }
      } else {
        var sourcedChanged = true;
        if (!widget.editScript!.edited &&
            inputSource == _originalSource &&
            inputTime == _originalTime &&
            inputName == _originalName) {
          sourcedChanged = false;
        }

        bool couldParseHeader = _userScriptsProvider.updateUserScript(
          widget.editScript!,
          inputName,
          inputTime,
          inputSource,
          sourcedChanged,
          false,
          _customApiKey,
        );
        if (!couldParseHeader) {
          BotToast.showText(
            text: "Could not parse the header, the script will inject on all pages.",
            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
            contentColor: Colors.orange[800]!,
            duration: const Duration(seconds: 4),
            contentPadding: const EdgeInsets.all(10),
          );
        }
      }
      _mainTabFirstSavePress = true;
      _customApiKey = "";
      _isCurrentScriptCandidateForCustomApiKey = false;
      _showCustomApiKeyButton = false;
    }
  }

  void _saveScriptWithoutApiKeyWarning() {
    BotToast.showText(
      text: "This script uses an API key.\n\nUnless you specify a custom one for it, "
          "your Torn PDA API key will be used!"
          "\n\nPress 'Set API Key' to configure or "
          "'${widget.editExisting ? "Save Update" : "Load Script"}' again to proceed without one.",
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.orange[800]!,
      duration: const Duration(seconds: 10),
      contentPadding: const EdgeInsets.all(10),
      align: const Alignment(0, 0),
      clickClose: true,
    );
  }

  Row _customApiKeyButton() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 5.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _customApiKey.isEmpty ? Colors.yellow : Colors.green,
              foregroundColor: Colors.black,
            ),
            onPressed: _showCustomApiKeyDialog,
            child: Text(_customApiKey.isEmpty ? "Set API Key" : "Edit API Key"),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            await showDialog(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext dialogContext) {
                const String apiUrl = "https://www.torn.com/api.html";
                return AlertDialog(
                  title: const Text("About Custom API Keys"),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        const Text(
                          "This script uses a special keyword that "
                          "tells Torn PDA that it needs an API Key to function.",
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "If you don't provide an alternative API key for this script, "
                          "Torn PDA will pass its own main application API Key.",
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Usually, this is not an issue.\n\n"
                          "However, it's a good security practice to create different API keys with specific, "
                          "limited permissions based on the script's needs. "
                          "\n\nThis can help prevent unintentional information leaks or protect your game "
                          "details if a script developer were to act maliciously or if the script had a vulnerability.",
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              const TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                                text:
                                    "You can find more information about Torn API key rules, permission levels, and what data they can access on the official Torn API documentation page:\n\n",
                              ),
                              TextSpan(
                                  text: apiUrl,
                                  style: TextStyle(
                                    color: _themeProvider.mainText,
                                    decoration: TextDecoration.underline,
                                    fontSize: 16,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      openWebViewSimpleDialog(context: context, initUrl: apiUrl);
                                    }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(
            Icons.info_outline,
            size: 20,
          ),
        )
      ],
    );
  }
}
