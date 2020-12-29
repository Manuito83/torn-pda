import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:torn_pda/models/chaining/target_backup_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class TargetsBackupPage extends StatefulWidget {
  @override
  _TargetsBackupPageState createState() => _TargetsBackupPageState();
}

class _TargetsBackupPageState extends State<TargetsBackupPage> {
  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  TargetsBackupModel _tentativeImportModel;

  bool _importActive = false;
  int _importSuccessEvents = 0;

  final _importFormKey = GlobalKey<FormState>();
  final _importInputController = new TextEditingController();

  String _exportInfo =
      "In order to export & backup your targets, you can either copy/paste "
      "to a text file manually, or share and save it at your desired location. "
      "In any case, please keep the text original structure.";

  String _importInfo =
      "In order to import targets, please paste here the string that "
      "you exported in the past. You can make changes outside of Torn PDA, "
      "but ensure that the main structure is kept!";

  String _importChoiceString =
      "you can either add them to your current list, or replace everything "
      "(you'll lose your current targets!).\n\nChoose wisely.";

  Color _importHintStyle = Colors.black;
  String _importHintText = 'Paste here previously exported data';
  FontWeight _importHintWeight = FontWeight.normal;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _importHintStyle = _themeProvider.mainText;
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? Colors.blueGrey
          : Colors.grey[900],
      child: SafeArea(
        top: _settingsProvider.appBarTop ? false : true,
        bottom: true,
        child: Scaffold(
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Builder(builder: (BuildContext context) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(15, 30, 20, 15),
                        child: Text(
                          "HOW TO EXPORT TARGETS",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(30, 10, 30, 15),
                        child: Text(
                          _exportInfo,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        direction: Axis.horizontal,
                        children: <Widget>[
                          Padding(
                              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: RaisedButton.icon(
                                icon: Icon(Icons.share),
                                label: Text("Export"),
                                onPressed: () async {
                                  var export = _targetsProvider.exportTargets();
                                  if (export == '') {
                                    BotToast.showText(
                                      text: "No targets to export!",
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                      contentPadding: EdgeInsets.all(10),
                                    );
                                  } else {
                                    Share.share(export);
                                  }
                                },
                              )),
                          Padding(
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: RaisedButton.icon(
                              icon: Icon(Icons.content_copy),
                              label: Text("Clipboard"),
                              onPressed: () async {
                                var export = _targetsProvider.exportTargets();
                                if (export == '') {
                                  BotToast.showText(
                                    text: "No targets to export!",
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                    contentPadding: EdgeInsets.all(10),
                                  );
                                } else {
                                  Clipboard.setData(ClipboardData(text: export));
                                  BotToast.showText(
                                    text: "${_targetsProvider.getTargetNumber()} "
                                        "targets copied to clipboard!",
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                    contentPadding: EdgeInsets.all(10),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 30, 0, 30),
                        child: Divider(),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(15, 0, 20, 15),
                        child: Text(
                          "HOW TO IMPORT TARGETS",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(30, 10, 30, 15),
                        child: Text(
                          _importInfo,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _importProgressWidget(),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Form(
                          key: _importFormKey,
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _importInputController,
                                maxLines: 6,
                                style: TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  counterText: "",
                                  border: OutlineInputBorder(),
                                  hintText: _importHintText,
                                  hintStyle: TextStyle(
                                    color: _importHintStyle,
                                    fontWeight: _importHintWeight,
                                  ),
                                ),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return "Cannot be empty!";
                                  }
                                  return null;
                                },
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                child: RaisedButton.icon(
                                  icon: Icon(Icons.file_download),
                                  label: Text("Import"),
                                  onPressed: () {
                                    if (_importFormKey.currentState.validate()) {
                                      var numberImported = _importChecker();
                                      if (numberImported == 0) {
                                        BotToast.showText(
                                          text: 'No targets to import! '
                                              'Is the file structure correct?',
                                          textStyle: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          contentColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                          contentPadding: EdgeInsets.all(10),
                                        );
                                      } else {
                                        FocusScope.of(context)
                                            .requestFocus(new FocusNode());
                                        _showImportDialog();
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            })),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Import & Export"),
    );
  }

  @override
  Future dispose() async {
    _importInputController.dispose();
    super.dispose();
  }

  Widget _importProgressWidget() {
    if (!_importActive) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
      child: LinearPercentIndicator(
        alignment: MainAxisAlignment.center,
        width: 200,
        lineHeight: 16,
        progressColor: Colors.green[200],
        backgroundColor: Colors.red[200],
        center: Text(
          '$_importSuccessEvents/${_tentativeImportModel.targetBackup.length}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        percent:
            _importSuccessEvents / _tentativeImportModel.targetBackup.length,
      ),
    );
  }

  int _importChecker() {
    try {
      String inputString = _importInputController.text;
      TargetsBackupModel inputModel = targetsBackupModelFromJson(inputString);
      for (var tar in inputModel.targetBackup) {
        if (tar.notesColor.length > 10) {
          tar.notesColor = tar.notesColor.substring(0, 9);
        }
        if (tar.notesColor.length > 200) {
          tar.notesColor = tar.notesColor.substring(0, 199);
        }
        if (tar.notesColor != "red" &&
            tar.notesColor != "green" &&
            tar.notesColor != "blue") {
          tar.notesColor = "";
        }
      }
      _tentativeImportModel = inputModel;
      return _tentativeImportModel.targetBackup.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _showImportDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                top: 12,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              //margin: EdgeInsets.only(top: 30),
              decoration: new BoxDecoration(
                color: _themeProvider.background,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(15, 30, 20, 15),
                    child: Text(
                      "How would you like to import?",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 10, 30, 20),
                    child: Text(
                      "${_tentativeImportModel.targetBackup.length} "
                              "new targets were found, " +
                          _importChoiceString,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RaisedButton(
                        child: Text("Add"),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onImportPressed(replace: false);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                      ),
                      RaisedButton(
                        child: Text("Replace"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onImportPressed(replace: true);
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FlatButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel import"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void onImportPressed({bool replace}) async {
    String existing = ' to the existing list';
    if (replace) {
      existing = '';
      _targetsProvider.wipeAllTargets();
    }
    await _importTargets();
    if (mounted) {
      setState(() {
        // More readable variables makes it easier
        var total = _tentativeImportModel.targetBackup.length;
        var numWorked = _importSuccessEvents;
        _importInputController.text = "";
        if (numWorked == 0) {
          _importHintText = "Import of all $total targets failed! "
              "Probably repeated or incorrect IDs?";
          _importHintStyle = Colors.red;
          _importHintWeight = FontWeight.bold;
        } else if (numWorked == total) {
          _importHintText = "Imported $numWorked new targets$existing!";
          _importHintStyle = Colors.green;
          _importHintWeight = FontWeight.bold;
        } else {
          _importHintText = "Imported $numWorked new targets$existing, "
              "but there were ${total - _importSuccessEvents} "
              "targets that failed to import! "
              "Probably repeated or incorrect IDs?";
          _importHintStyle = Colors.red;
          _importHintWeight = FontWeight.bold;
        }
      });
    }
  }

  Future<void> _importTargets() async {
    _importActive = true; // Show import status
    _importSuccessEvents = 0;
    dynamic attacksFull = await _targetsProvider.getAttacksFull();
    for (var import in _tentativeImportModel.targetBackup) {
      var importResult = await _targetsProvider.addTarget(
        targetId: import.id.toString(),
        attacksFull: attacksFull,
        notes: import.notes,
        notesColor: import.notesColor,
      );
      if (importResult.success) {
        if (mounted) {
          setState(() {
            _importSuccessEvents++;
          });
        }
      }
      // Avoid issues with API limits
      if (_tentativeImportModel.targetBackup.length > 60) {
        await Future.delayed(const Duration(seconds: 1), () {});
      }
    }
  }
}
