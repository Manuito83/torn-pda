import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/utils/userscript_examples.dart';

class UserScriptsRevertDialog extends StatefulWidget {
  @override
  _UserScriptsRevertDialogState createState() =>
      _UserScriptsRevertDialogState();
}

class _UserScriptsRevertDialogState extends State<UserScriptsRevertDialog> {
  ThemeProvider _themeProvider;
  UserScriptsProvider _userScriptsProvider;

  bool _onlyRestoreNew = true;
  int _missingScripts = 0;

  @override
  void initState() {
    super.initState();
    _userScriptsProvider =
        Provider.of<UserScriptsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    // Get number missing example scripts
    var exampleScripts =
        List<UserScriptModel>.from(ScriptsExamples.getScriptsExamples());
    _missingScripts = exampleScripts.length;
    int overwrite = 0;
    for (var existing in _userScriptsProvider.userScriptList) {
      for (var example in exampleScripts) {
        if (existing.exampleCode == example.exampleCode) {
          _missingScripts--;
          overwrite++;
        }
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: EdgeInsets.only(top: 15),
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
                    SizedBox(height: 10),
                    Flexible(
                      child: Text(
                        "This will restore the example scripts than come with Torn PDA by default!",
                        style: TextStyle(
                            fontSize: 12, color: _themeProvider.mainText),
                      ),
                    ),
                    SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _onlyRestoreNew
                                    ? "Only add example scripts that are not in the list "
                                        "(you are missing $_missingScripts example "
                                        "${_missingScripts == 1 ? "script" : "scripts"})"
                                    : "This will add all missing example scripts and overwrite any "
                                        "changes in they are already in your list "
                                        "(found $overwrite)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _onlyRestoreNew
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                            ),
                            Switch(
                              value: _onlyRestoreNew,
                              onChanged: (value) {
                                setState(() {
                                  _onlyRestoreNew = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text("Do it!"),
                          onPressed: () {
                            _userScriptsProvider
                                .restoreExamples(_onlyRestoreNew);
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text("Better not!"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _themeProvider.background,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.background,
                  radius: 22,
                  child: SizedBox(
                    height: 34,
                    width: 34,
                    child: Icon(MdiIcons.restore),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
