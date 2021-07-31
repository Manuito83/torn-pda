// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

class UserScriptsAddDialog extends StatefulWidget {
  final bool editExisting;
  final UserScriptModel editScript;

  UserScriptsAddDialog({@required this.editExisting, this.editScript});

  @override
  _UserScriptsAddDialogState createState() => _UserScriptsAddDialogState();
}

class _UserScriptsAddDialogState extends State<UserScriptsAddDialog> {
  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  final _addNameController = new TextEditingController();
  final _addSourceController = new TextEditingController();
  var _nameFormKey = GlobalKey<FormState>();
  var _sourceFormKey = GlobalKey<FormState>();

  UserScriptsProvider _userScriptsProvider;

  String _originalSource = "";
  String _originalName = "";

  @override
  void initState() {
    super.initState();
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    if (widget.editExisting) {
      for (var script in _userScriptsProvider.userScriptList) {
        if (script.name == widget.editScript.name) {
          _addNameController.text = script.name;
          _addSourceController.text = script.source;
          _originalSource = script.source;
          _originalName = script.name;
        }
      }
    }
  }

  @override
  Future dispose() async {
    _addNameController.dispose();
    _addSourceController.dispose();
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
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code),
                  SizedBox(width: 6),
                  Text(widget.editExisting ? "Edit existing script" : "Add new script"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _nameFormKey,
                child: TextFormField(
                  style: TextStyle(fontSize: 12),
                  controller: _addNameController,
                  maxLength: 100,
                  minLines: 1,
                  maxLines: 2,
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: "",
                    border: OutlineInputBorder(),
                    labelText: 'Script name',
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Enter a valid name!";
                    }
                    for (var script in _userScriptsProvider.userScriptList) {
                      if (script.name.toLowerCase() == value.toLowerCase()) {
                        if (!widget.editExisting) {
                          return "Script name already taken!";
                        } else {
                          // Allow to save same script, but not if it conflicts
                          // with another existing script
                          if (script.name.toLowerCase() != widget.editScript.name.toLowerCase()) {
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Form(
                  key: _sourceFormKey,
                  child: TextFormField(
                    minLines: null,
                    maxLines: null,
                    expands: true,
                    autocorrect: false,
                    style: TextStyle(fontSize: 12),
                    controller: _addSourceController,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: "",
                      border: OutlineInputBorder(),
                      labelText: 'Paste source code',
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return "Cannot be empty!";
                      }
                      _addSourceController.text = value.trim();
                      return null;
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
                    child: Text("Cancel"),
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
      ),
    );
  }

  Future<void> _addPressed(BuildContext context) async {
    if (_nameFormKey.currentState.validate() && _sourceFormKey.currentState.validate()) {
      // Get rid of dialog first, so that it can't
      // be pressed twice
      Navigator.of(context).pop();

      // Copy controller's text ot local variable
      // early and delete the global, so that text
      // does not appear again in case of failure
      var inputName = _addNameController.text;
      var inputSource = _addSourceController.text;
      _addNameController.text = _addSourceController.text = '';

      if (!widget.editExisting) {
        _userScriptsProvider.addUserScript(inputName, inputSource);
      } else {
        var sourcedChanged = false;
        if (inputSource != _originalSource || inputName != _originalName) {
          sourcedChanged = true;
        }
        _userScriptsProvider.updateUserScript(widget.editScript, inputName, inputSource, sourcedChanged);
      }
    }
  }
}
