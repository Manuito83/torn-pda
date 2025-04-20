// Flutter imports:
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

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
  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  final _addNameController = TextEditingController();
  final _addSourceController = TextEditingController();
  final _nameFormKey = GlobalKey<FormState>();
  final _sourceFormKey = GlobalKey<FormState>();

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

          _remoteNameController.text = script.name;
          _remoteUrlController.text = script.url ?? "";
        }
      }
    } else if (widget.defaultUrl != null) {
      _remoteUrlController.text = widget.defaultUrl!;
    }

    // Listen to changes so that "clear" button becomes active when there is text in the URL field
    _remoteUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  Future dispose() async {
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
                Row(
                  children: [
                    const Icon(MdiIcons.earth, size: 14),
                    SizedBox(width: 4),
                    const Text("Remote load/update"),
                  ],
                ),
                ElevatedButton(
                  child: Text("Configure"),
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
                Row(
                  children: [
                    const Icon(MdiIcons.lightningBoltOutline, size: 16),
                    SizedBox(width: 4),
                    const Text("Injection time"),
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
                            contentColor: Colors.orange[700]!,
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
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(widget.editExisting ? "Save" : "Add"),
                  onPressed: () async {
                    await _addPressed(context);
                  },
                ),
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addNameController.text = '';
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
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
                Container(
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
                Container(
                  width: 20,
                ),
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
                      if (_remoteUrlController.text.isEmpty) {
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
                        if (!widget.editExisting) {
                          BotToast.showText(
                            align: Alignment(0, 0),
                            clickClose: true,
                            text: message ?? (success ? "Success" : "An unknown error occurred"),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: success ? Colors.green : Colors.orange[700]!,
                            duration: const Duration(seconds: 4),
                            contentPadding: const EdgeInsets.all(10),
                          );
                        } else {
                          if (!success) {
                            log("An error occured in script ${widget.editScript!.name}: $message");
                            BotToast.showText(
                              align: Alignment(0, 0),
                              clickClose: true,
                              text: message ?? "An unknown error occurred",
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.orange[700]!,
                              duration: const Duration(seconds: 4),
                              contentPadding: const EdgeInsets.all(10),
                            );
                            widget.editScript!.updateStatus = UserScriptUpdateStatus.error;
                          } else {
                            try {
                              final String newVersion = resultModel!.version;
                              final String oldVersion = widget.editScript!.version;
                              final bool isOlderVersion = UserScriptModel.isNewerVersion(newVersion, oldVersion);
                              final String finalMessage = !success
                                  ? (message ?? "An unknown error occurred")
                                  : isOlderVersion
                                      ? "Newer version found: $newVersion\nPlease review changes and save!"
                                      : "No newer version found";
                              log(finalMessage);
                              BotToast.showText(
                                align: Alignment(0, 0),
                                clickClose: true,
                                text: finalMessage,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: success && isOlderVersion ? Colors.green : Colors.orange[700]!,
                                duration: const Duration(seconds: 4),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            } catch (e) {
                              log("An error occured in script ${widget.editScript!.name}: $e");
                              BotToast.showText(
                                align: Alignment(0, 0),
                                clickClose: true,
                                text: "An unknown error occurred whilst parsing the remote script.",
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.orange[700]!,
                                duration: const Duration(seconds: 4),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
                          }
                        }

                        setState(() {
                          if (success) {
                            model = resultModel!;
                            _remoteSourceController.text = resultModel.source;
                            _remoteNameController.text = resultModel.name;
                            final String text = resultModel.time.name;
                            _remoteRunTimeController.text = text;
                          } else {
                            _remoteSourceController.clear();
                            _remoteNameController.clear();
                            _remoteRunTimeController.clear();
                          }
                          _remoteSourceFetching = false;
                        });
                      }
                    }),
                Container(width: 20),
                ElevatedButton(
                  child: Text("Clear"),
                  onPressed: _remoteUrlController.text.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _remoteUrlController.clear();
                            _remoteSourceController.clear();
                            _remoteNameController.clear();
                            _remoteRunTimeController.clear();
                          });
                        },
                ),
              ],
            ),
          ),
          _remoteSourceFetching
              ? Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Fetching script..."),
                      Container(height: 20),
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
                          border: OutlineInputBorder(),
                          label: _remoteSourceController.text.isEmpty ? Center(child: Text("Remote source")) : null,
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
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                child: Text(widget.editExisting ? "Save" : "Load"),
                onPressed: _remoteNameController.text.isEmpty ||
                        _remoteSourceController.text.isEmpty ||
                        _remoteRunTimeController.text.isEmpty
                    ? null
                    : () {
                        if (!widget.editExisting) {
                          _userScriptsProvider
                              .addUserScriptFromURL(_remoteUrlController.text.trim())
                              .then((r) => BotToast.showText(
                                    align: Alignment(0, 0),
                                    clickClose: true,
                                    text: r.success ? "Script successfully added!" : "Error: ${r.message}",
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: r.success ? Colors.green : Colors.orange[700]!,
                                    duration: const Duration(seconds: 4),
                                    contentPadding: const EdgeInsets.all(10),
                                  ))
                              .then(Navigator.of(context).pop);
                        } else {
                          final bool couldParseHeader = _userScriptsProvider.updateUserScript(
                              widget.editScript!,
                              _remoteNameController.text,
                              UserScriptTime.values.byName(_remoteRunTimeController.text),
                              _remoteSourceController.text,
                              true,
                              true);
                          BotToast.showText(
                            align: Alignment(0, 0),
                            clickClose: true,
                            text: couldParseHeader
                                ? "Script successfully updated!"
                                : "Could not parse the header, the script will inject on all pages.",
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: couldParseHeader ? Colors.green : Colors.orange[700]!,
                            duration: const Duration(seconds: 4),
                            contentPadding: const EdgeInsets.all(10),
                          );
                          Navigator.of(context).pop();
                        }
                      },
              ),
              Container(width: 20),
              ElevatedButton(child: const Text("Cancel"), onPressed: Navigator.of(context).pop)
            ]),
          )
        ]));
  }

  Future<void> _addPressed(BuildContext context) async {
    if (_nameFormKey.currentState!.validate() && _sourceFormKey.currentState!.validate()) {
      // Get rid of dialog first, so that it can't
      // be pressed twice

      Navigator.of(context).pop();

      // Copy controller's text ot local variable
      // early and delete the global, so that text
      // does not appear again in case of failure
      final inputName = _addNameController.text;
      final inputTime = _originalTime;
      final inputSource = _addSourceController.text;
      _addNameController.text = _addSourceController.text = '';

      if (!widget.editExisting) {
        try {
          final metaMap = UserScriptModel.parseHeader(inputSource);
          _userScriptsProvider.addUserScriptByModel(
              UserScriptModel.fromMetaMap(metaMap, name: inputName, source: inputSource, time: inputTime));
        } on Exception catch (e) {
          if (e.toString().contains("No header found")) {
            BotToast.showText(
                text: "No header was found in the script, it will be injected in all pages!",
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[700]!,
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
            ));
          } else {
            BotToast.showText(
              align: Alignment(0, 0),
              clickClose: true,
              text: "Error: $e",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.orange[700]!,
              duration: const Duration(seconds: 4),
              contentPadding: const EdgeInsets.all(10),
            );
          }
        }
      } else {
        // Flag the script as edited if we've changed something now or in the past
        var sourcedChanged = true;
        if (!widget.editScript!.edited &&
            inputSource == _originalSource &&
            inputTime == _originalTime &&
            inputName == _originalName) {
          sourcedChanged = false;
        }

        bool couldParseHeader = _userScriptsProvider.updateUserScript(
            widget.editScript!, inputName, inputTime, inputSource, sourcedChanged, false);
        if (!couldParseHeader) {
          BotToast.showText(
            text: "Could not parse the header, the script will inject on all pages.",
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.orange[700]!,
            duration: const Duration(seconds: 4),
            contentPadding: const EdgeInsets.all(10),
          );
        }
      }
    }
  }
}
